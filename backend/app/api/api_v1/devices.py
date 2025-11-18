from typing import List, Optional, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, status, Response, Query
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel
from app.api.api_v1.auth import get_current_active_user
from app.core.database import get_db
from app.core.config import settings
from app.schemas.device import (
    Device, DeviceCreate, DeviceUpdate,
    DeviceCertificate, DeviceCertificateCreate,
    DeviceLog, DeviceLogCreate, DeviceStats,
    FirmwareGenerateRequest, FirmwareResponse
)
from app.services.device import DeviceService
from app.schemas.user import User
from app.services.firmware import FirmwareService
from app.services.certificate import CertificateService
from app.core.events import get_mqtt_client
import json
import logging

logger = logging.getLogger(__name__)

router = APIRouter()

@router.post("", response_model=Device)
async def create_device(
    device_in: DeviceCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
) -> Device:
    """创建新设备（自动生成证书）"""
    device_service = DeviceService(db)
    
    # 检查设备ID是否已存在
    if await device_service.get_by_device_id(device_in.device_id):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="设备ID已存在"
        )
    
    device = await device_service.create(device_in)
    
    # 自动为新设备生成客户端证书
    try:
        # 检查CA证书是否存在
        ca_cert = CertificateService.get_ca_certificate()
        if ca_cert:
            # 生成客户端证书（默认有效期365天）
            client_key, client_cert, serial_number = CertificateService.generate_client_certificate(
                device_id=device.device_id,
                common_name=device_in.name or device_in.device_id,
                validity_days=365
            )
            
            # 保存证书到数据库
            from datetime import datetime, timedelta
            cert_in = DeviceCertificateCreate(
                certificate=client_cert,
                private_key=client_key,
                certificate_type="client",
                serial_number=serial_number,
                issued_at=datetime.utcnow(),
                expires_at=datetime.utcnow() + timedelta(days=365)
            )
            
            await device_service.add_certificate(device, cert_in)
        else:
            # CA证书不存在，记录警告但不阻止设备创建
            import logging
            logger = logging.getLogger(__name__)
            logger.warning(f"CA证书不存在，无法为设备 {device.device_id} 自动生成证书")
    except Exception as e:
        # 证书生成失败，记录错误但不阻止设备创建
        import logging
        logger = logging.getLogger(__name__)
        logger.error(f"为设备 {device.device_id} 自动生成证书失败: {e}", exc_info=True)
    
    # 自动为新设备创建加密密钥（加密保存到数据库）
    try:
        from app.services.encryption_key_service import EncryptionKeyService
        key_service = EncryptionKeyService(db)
        await key_service.create_key_for_device(str(device.id), str(current_user.id))
        logger.info(f"为设备 {device.device_id} 自动创建加密密钥成功")
    except Exception as e:
        # 密钥创建失败，记录错误但不阻止设备创建
        import logging
        logger = logging.getLogger(__name__)
        logger.warning(f"为设备 {device.device_id} 自动创建加密密钥失败: {e}")
    
    return device

@router.get("", response_model=List[Device])
async def get_devices(
    skip: int = 0,
    limit: int = 100,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
) -> List[Device]:
    """获取设备列表"""
    device_service = DeviceService(db)
    devices = await device_service.get_multi(skip=skip, limit=limit)
    return devices

@router.get("/{device_id}", response_model=Device)
async def get_device(
    device_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
) -> Device:
    """获取设备详情"""
    try:
        device_service = DeviceService(db)
        device = await device_service.get_by_id(device_id)
        if not device:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="设备不存在"
            )
        return device
    except HTTPException:
        raise
    except Exception as e:
        import logging
        logger = logging.getLogger(__name__)
        logger.error(f"Error getting device {device_id}: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"获取设备信息失败: {str(e)}"
        )

@router.put("/{device_id}", response_model=Device)
async def update_device(
    device_id: str,
    device_in: DeviceUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
) -> Device:
    """更新设备信息"""
    device_service = DeviceService(db)
    device = await device_service.get_by_id(device_id)
    if not device:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="设备不存在"
        )
    
    device = await device_service.update(device, device_in)
    return device

@router.delete("/{device_id}")
async def delete_device(
    device_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """删除设备"""
    device_service = DeviceService(db)
    device = await device_service.get_by_id(device_id)
    if not device:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="设备不存在"
        )
    
    await device_service.delete(device)
    return {"message": "设备已删除"}

@router.get("/{device_id}/certificates", response_model=List[DeviceCertificate])
async def get_device_certificates(
    device_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
) -> List[DeviceCertificate]:
    """获取设备证书列表"""
    device_service = DeviceService(db)
    device = await device_service.get_by_id(device_id)
    if not device:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="设备不存在"
        )
    
    # 获取设备的所有证书
    from app.models.device import DeviceCertificate
    from sqlalchemy import select
    result = await db.execute(
        select(DeviceCertificate)
        .filter(DeviceCertificate.device_id == device.id)
        .order_by(DeviceCertificate.created_at.desc())
    )
    certificates = result.scalars().all()
    
    # 转换为Pydantic模型并解密证书数据
    from app.core.encryption import decrypt_certificate_data
    result = []
    for cert in certificates:
        cert_dict = {
            'id': cert.id,
            'device_id': cert.device_id,
            'certificate_type': cert.certificate_type,
            'serial_number': cert.serial_number,
            'certificate': decrypt_certificate_data(cert.certificate),
            'private_key': decrypt_certificate_data(cert.private_key) if cert.private_key else None,
            'issued_at': cert.issued_at,
            'expires_at': cert.expires_at,
            'revoked_at': cert.revoked_at,
            'revoke_reason': cert.revoke_reason,
            'created_at': cert.created_at
        }
        result.append(DeviceCertificate(**cert_dict))
    return result

@router.post("/{device_id}/certificates", response_model=DeviceCertificate)
async def create_device_certificate(
    device_id: str,
    cert_in: DeviceCertificateCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
) -> DeviceCertificate:
    """创建设备证书"""
    device_service = DeviceService(db)
    device = await device_service.get_by_id(device_id)
    if not device:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="设备不存在"
        )
    
    cert = await device_service.add_certificate(device, cert_in)
    
    # 返回时需要解密证书数据（因为存储时已加密）
    from app.core.encryption import decrypt_certificate_data
    cert_dict = {
        'id': cert.id,
        'device_id': cert.device_id,
        'certificate_type': cert.certificate_type,
        'serial_number': cert.serial_number,
        'certificate': decrypt_certificate_data(cert.certificate),
        'private_key': decrypt_certificate_data(cert.private_key) if cert.private_key else None,
        'issued_at': cert.issued_at,
        'expires_at': cert.expires_at,
        'revoked_at': cert.revoked_at,
        'revoke_reason': cert.revoke_reason,
        'created_at': cert.created_at
    }
    return DeviceCertificate(**cert_dict)

@router.get("/{device_id}/certificates/{cert_id}", response_model=DeviceCertificate)
async def get_device_certificate(
    device_id: str,
    cert_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
) -> DeviceCertificate:
    """获取设备证书详情"""
    device_service = DeviceService(db)
    device = await device_service.get_by_id(device_id)
    if not device:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="设备不存在"
        )
    
    from app.models.device import DeviceCertificate
    from sqlalchemy import select
    result = await db.execute(
        select(DeviceCertificate)
        .filter(DeviceCertificate.id == cert_id)
        .filter(DeviceCertificate.device_id == device.id)
    )
    cert = result.scalar_one_or_none()
    if not cert:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="证书不存在"
        )
    
    # 解密证书数据
    from app.core.encryption import decrypt_certificate_data
    cert_dict = {
        'id': cert.id,
        'device_id': cert.device_id,
        'certificate_type': cert.certificate_type,
        'serial_number': cert.serial_number,
        'certificate': decrypt_certificate_data(cert.certificate),
        'private_key': decrypt_certificate_data(cert.private_key) if cert.private_key else None,
        'issued_at': cert.issued_at,
        'expires_at': cert.expires_at,
        'revoked_at': cert.revoked_at,
        'revoke_reason': cert.revoke_reason,
        'created_at': cert.created_at
    }
    return DeviceCertificate(**cert_dict)

@router.post("/{device_id}/certificates/{cert_id}/renew", response_model=DeviceCertificate)
async def renew_device_certificate(
    device_id: str,
    cert_id: str,
    validity_days: int = Query(365, ge=1, le=3650, description="证书有效期（天）"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
) -> DeviceCertificate:
    """续约设备证书（生成新证书）"""
    device_service = DeviceService(db)
    device = await device_service.get_by_id(device_id)
    if not device:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="设备不存在"
        )
    
    # 获取原证书信息
    from app.models.device import DeviceCertificate
    from sqlalchemy import select
    result = await db.execute(
        select(DeviceCertificate)
        .filter(DeviceCertificate.id == cert_id)
        .filter(DeviceCertificate.device_id == device.id)
    )
    old_cert = result.scalar_one_or_none()
    if not old_cert:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="证书不存在"
        )
    
    # 检查证书是否已吊销
    if old_cert.revoked_at:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="已吊销的证书无法续约，请生成新证书"
        )
    
    try:
        # 生成新证书（使用相同的common_name）
        # 从旧证书中提取common_name（如果可能），否则使用设备名称
        common_name = device.name or device.device_id
        
        client_key, client_cert, serial_number = CertificateService.generate_client_certificate(
            device_id=device.device_id,
            common_name=common_name,
            validity_days=validity_days
        )
        
        # 保存新证书到数据库
        from datetime import datetime, timedelta
        cert_in = DeviceCertificateCreate(
            certificate=client_cert,
            private_key=client_key,
            certificate_type=old_cert.certificate_type,
            serial_number=serial_number,
            issued_at=datetime.utcnow(),
            expires_at=datetime.utcnow() + timedelta(days=validity_days)
        )
        
        new_cert = await device_service.add_certificate(device, cert_in)
        
        # 返回时需要解密证书数据
        from app.core.encryption import decrypt_certificate_data
        cert_dict = {
            'id': new_cert.id,
            'device_id': new_cert.device_id,
            'certificate_type': new_cert.certificate_type,
            'serial_number': new_cert.serial_number,
            'certificate': decrypt_certificate_data(new_cert.certificate),
            'private_key': decrypt_certificate_data(new_cert.private_key) if new_cert.private_key else None,
            'issued_at': new_cert.issued_at,
            'expires_at': new_cert.expires_at,
            'revoked_at': new_cert.revoked_at,
            'revoke_reason': new_cert.revoke_reason,
            'created_at': new_cert.created_at
        }
        return DeviceCertificate(**cert_dict)
    except HTTPException:
        raise
    except Exception as e:
        import logging
        logger = logging.getLogger(__name__)
        logger.error(f"Error renewing certificate: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"续约证书失败: {str(e)}"
        )

@router.post("/{device_id}/certificates/{cert_id}/revoke")
async def revoke_device_certificate(
    device_id: str,
    cert_id: str,
    reason: str = Query(..., description="吊销原因"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """吊销设备证书"""
    import logging
    logger = logging.getLogger(__name__)
    
    device_service = DeviceService(db)
    device = await device_service.get_by_id(device_id)
    if not device:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="设备不存在"
        )
    
    from app.models.device import DeviceCertificate
    from sqlalchemy import select
    result = await db.execute(
        select(DeviceCertificate)
        .filter(DeviceCertificate.id == cert_id)
        .filter(DeviceCertificate.device_id == device.id)
    )
    cert = result.scalar_one_or_none()
    if not cert:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="证书不存在"
        )
    
    if cert.revoked_at:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="证书已被吊销"
        )
    
    try:
        await device_service.revoke_certificate(cert, reason)
        logger.info(f"Certificate {cert_id} revoked for device {device_id}")
        return {"message": "证书已成功吊销"}
    except Exception as e:
        logger.error(f"Error revoking certificate: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"吊销证书失败: {str(e)}"
        )

@router.post("/{device_id}/logs", response_model=DeviceLog)
async def add_device_log(
    device_id: str,
    log_in: DeviceLogCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
) -> DeviceLog:
    """添加设备日志"""
    device_service = DeviceService(db)
    device = await device_service.get_by_id(device_id)
    if not device:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="设备不存在"
        )
    
    log = await device_service.add_log(device, log_in)
    return log

@router.get("/{device_id}/logs", response_model=List[DeviceLog])
async def get_device_logs(
    device_id: str,
    skip: int = 0,
    limit: int = 100,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
) -> List[DeviceLog]:
    """获取设备日志"""
    device_service = DeviceService(db)
    device = await device_service.get_by_id(device_id)
    if not device:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="设备不存在"
        )
    
    logs = await device_service.get_device_logs(device, skip=skip, limit=limit)
    return logs

@router.get("/{device_id}/stats", response_model=DeviceStats)
async def get_device_stats(
    device_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
) -> DeviceStats:
    """获取设备统计信息"""
    device_service = DeviceService(db)
    device = await device_service.get_by_id(device_id)
    if not device:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="设备不存在"
        )
    
    # TODO: 实现设备统计信息逻辑
    return DeviceStats(
        total_messages=0,
        online_duration=0,
        last_seen=device.last_online_at,
        error_count=0
    )

@router.post("/{device_id}/firmware/generate", response_model=FirmwareResponse)
async def generate_device_firmware(
    device_id: str,
    firmware_config: FirmwareGenerateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
) -> FirmwareResponse:
    """生成设备烧录代码"""
    device_service = DeviceService(db)
    device = await device_service.get_by_device_id(device_id)
    if not device:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="设备不存在"
        )
    
    # 获取CA证书（如果需要TLS）
    ca_cert = None
    if firmware_config.ca_cert:
        ca_cert = firmware_config.ca_cert
    else:
        # 如果没有提供，尝试从服务获取
        try:
            ca_cert_data = CertificateService.get_ca_certificate()
            if ca_cert_data:
                ca_cert = ca_cert_data
        except Exception as e:
            # 如果获取失败，使用默认提示
            pass
    
    # 生成固件代码（支持从模板生成）
    firmware_code = await FirmwareService.generate_firmware_code(
        device_id=device.device_id,
        device_name=device.name,
        device_type=device.type,
        wifi_ssid=firmware_config.wifi_ssid,
        wifi_password=firmware_config.wifi_password,
        mqtt_server=firmware_config.mqtt_server,
        ca_cert=ca_cert,
        template_id=getattr(firmware_config, 'template_id', None),
        db=db
    )
    
    # 保存到文件（可选）
    firmware_file = FirmwareService.save_firmware_to_file(
        device_id=device.device_id,
        firmware_code=firmware_code
    )
    
    return FirmwareResponse(
        device_id=device.device_id,
        firmware_code=firmware_code,
        message=f"固件代码已生成并保存到 {firmware_file}"
    )

# 设备命令请求模型
class DeviceCommandRequest(BaseModel):
    command: str
    topic: Optional[str] = None
    payload: Optional[Dict[str, Any]] = None
    qos: int = 1

class DeviceCommandResponse(BaseModel):
    success: bool
    message: str
    topic: str
    command: str

@router.post("/{device_id}/command", response_model=DeviceCommandResponse)
async def send_device_command(
    device_id: str,
    command_request: DeviceCommandRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
) -> DeviceCommandResponse:
    """向设备发送MQTT控制命令"""
    try:
        # 验证设备是否存在
        # device_id可能是UUID或device_id字符串，需要兼容两种格式
        device_service = DeviceService(db)
        device = None
        
        # 先尝试作为UUID查找
        try:
            from uuid import UUID
            device_uuid = UUID(device_id)
            device = await device_service.get_by_id(str(device_uuid))
        except (ValueError, TypeError):
            # 如果不是UUID，尝试作为device_id查找
            device = await device_service.get_by_device_id(device_id)
        
        if not device:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="设备不存在"
            )
        
        # 使用设备的device_id（字符串）作为MQTT主题的设备标识
        actual_device_id = device.device_id
        
        # 获取MQTT客户端实例
        mqtt = get_mqtt_client()
        
        # 检查MQTT客户端是否可用
        if mqtt is None:
            logger.error("MQTT client is None, MQTT service not initialized")
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="MQTT服务未初始化，请检查后端日志和MQTT配置"
            )
        
        # 检查MQTT连接状态
        # 注意：paho-mqtt的is_connected()可能在某些情况下不准确
        # 如果MQTT客户端能够接收消息，说明连接是正常的
        # 我们直接尝试发布消息，如果失败再报错
        try:
            is_connected = mqtt.is_connected()
            logger.debug(f"MQTT is_connected() returned: {is_connected}")
        except Exception as e:
            logger.error(f"Error checking MQTT connection status: {e}")
            is_connected = False
        
        # 即使is_connected()返回False，如果MQTT客户端存在且能接收消息，我们也尝试发布
        # 因为paho-mqtt在某些情况下is_connected()可能不准确
        if not is_connected:
            logger.warning(f"MQTT is_connected() returned False, but will attempt to publish anyway")
            logger.warning(f"MQTT broker: {settings.MQTT_BROKER_HOST}:{settings.MQTT_BROKER_PORT}")
            # 不立即抛出错误，而是尝试发布消息，如果发布失败再报错
        
        # 构建MQTT主题（默认使用 devices/{actual_device_id}/control）
        topic = command_request.topic or f"devices/{actual_device_id}/control"
        
        # 构建消息负载
        message_payload: Dict[str, Any] = {
            "command": command_request.command,
            "device_id": actual_device_id,
            "timestamp": None  # 将在下面设置
        }
        
        # 如果有额外的payload，合并进去
        if command_request.payload:
            message_payload.update(command_request.payload)
        
        # 添加时间戳
        from datetime import datetime
        message_payload["timestamp"] = datetime.utcnow().isoformat()
        
        # 转换为JSON字符串
        payload_str = json.dumps(message_payload)
        
        # 发布MQTT消息
        try:
            result = mqtt.publish(topic, payload_str, qos=command_request.qos)
            logger.debug(f"MQTT publish result: rc={result.rc}, mid={result.mid if hasattr(result, 'mid') else 'N/A'}")
        except Exception as e:
            logger.error(f"MQTT publish failed with exception: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail=f"MQTT发布消息失败: {str(e)}"
            )
        
        if result.rc == 0:
            logger.info(f"设备命令已发送: device_id={actual_device_id}, command={command_request.command}, topic={topic}")
            return DeviceCommandResponse(
                success=True,
                message="命令已成功发送到设备",
                topic=topic,
                command=command_request.command
            )
        else:
            logger.error(f"MQTT发布失败: device_id={actual_device_id}, rc={result.rc}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"发送命令失败，MQTT返回码: {result.rc}"
            )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"发送设备命令失败: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"发送设备命令失败: {str(e)}"
        )

@router.get("/{device_id}/firmware/download")
async def download_device_firmware(
    device_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
) -> Response:
    """下载设备烧录代码文件"""
    device_service = DeviceService(db)
    device = await device_service.get_by_device_id(device_id)
    if not device:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="设备不存在"
        )
    
    # 尝试从文件加载
    firmware_code = FirmwareService.load_firmware_from_file(device_id=device.device_id)
    
    if not firmware_code:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="固件文件不存在，请先生成固件代码"
        )
    
    # 返回文件内容
    return Response(
        content=firmware_code,
        media_type="text/plain",
        headers={
            "Content-Disposition": f"attachment; filename={device.device_id}.ino"
        }
    )