"""
固件加密烧录API
提供HTTPS OTA和XOR掩码功能
"""
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from sqlalchemy.ext.asyncio import AsyncSession
from app.api.api_v1.auth import get_current_active_user, get_current_super_admin_user
from app.core.database import get_db
from app.schemas.user import User
from app.services.firmware_encryption import FirmwareEncryptionService
from app.services.ota_service import OTAService
from app.services.ota_update_service import OTAUpdateService
from app.services.device import DeviceService
from app.services.encryption_key_service import EncryptionKeyService
from app.services.firmware_build import FirmwareBuildService
from app.services.certificate import CertificateService
from app.schemas.ota import OTAUpdateRequest, OTAUpdateResponse, OTAUpdateStatusResponse
from typing import Optional, List
import logging
from fastapi.responses import FileResponse
from uuid import UUID

logger = logging.getLogger(__name__)

router = APIRouter()


@router.post("/encrypt/{device_id}")
async def encrypt_firmware(
    device_id: str,
    use_xor_mask: bool = True,
    firmware_file: Optional[UploadFile] = File(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    加密固件（应用XOR掩码）
    
    Args:
        device_id: 设备ID
        use_xor_mask: 是否使用XOR掩码
        firmware_file: 固件文件（可选，如果不提供则使用已生成的固件）
        db: 数据库会话
        current_user: 当前用户
    """
    try:
        # 验证设备是否存在
        device_service = DeviceService(db)
        device = await device_service.get_by_device_id(device_id)
        if not device:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="设备不存在"
            )
        
        encryption_service = FirmwareEncryptionService()
        
        # 如果提供了固件文件，先保存
        firmware_path = None
        if firmware_file:
            from pathlib import Path
            firmware_dir = Path("data/firmware")
            firmware_dir.mkdir(parents=True, exist_ok=True)
            
            firmware_path = firmware_dir / f"{device_id}_original.bin"
            with open(firmware_path, 'wb') as f:
                content = await firmware_file.read()
                f.write(content)
        else:
            # 尝试查找已存在的固件
            from pathlib import Path
            firmware_dir = Path("data/firmware")
            firmware_path = firmware_dir / f"{device_id}.bin"
            if not firmware_path.exists():
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="未找到固件文件，请先上传或生成固件"
                )
        
        # 生成加密固件
        encrypted_path, key_file, key_hex = encryption_service.generate_encrypted_firmware(
            str(firmware_path),
            device_id,
            use_xor_mask=use_xor_mask
        )
        
        # 获取固件信息
        firmware_info = encryption_service.get_firmware_info(encrypted_path)
        
        return {
            "device_id": device_id,
            "encrypted_firmware_path": encrypted_path,
            "firmware_info": firmware_info,
            "xor_key_file": key_file,
            "xor_key_hex": key_hex,
            "use_encryption": use_xor_mask
        }
    
    except FileNotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"加密固件失败: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"加密固件失败: {str(e)}"
        )


@router.get("/ota-config/{device_id}")
async def get_ota_config(
    device_id: str,
    ssid: Optional[str] = None,
    password: Optional[str] = None,
    server_host: Optional[str] = None,
    server_port: int = 443,
    use_https: bool = True,
    use_xor_mask: bool = True,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    获取OTA配置信息
    
    Args:
        device_id: 设备ID
        ssid: WiFi SSID（如果提供则包含在配置中）
        password: WiFi密码（如果提供则包含在配置中）
        server_host: 服务器地址（如果提供则使用，否则从配置读取）
        server_port: 服务器端口
        use_https: 是否使用HTTPS
        use_xor_mask: 是否使用XOR掩码
        db: 数据库会话
        current_user: 当前用户
    """
    try:
        # 验证设备是否存在
        device_service = DeviceService(db)
        device = await device_service.get_by_device_id(device_id)
        if not device:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="设备不存在"
            )
        
        ota_service = OTAService()
        
        # 如果没有提供服务器地址，使用默认值
        if not server_host:
            from app.core.config import settings
            server_host = getattr(settings, 'FIRMWARE_SERVER_HOST', 'localhost')
        
        config = ota_service.generate_ota_config(
            device_id=device_id,
            ssid=ssid or "",
            password=password or "",
            server_host=server_host,
            server_port=server_port,
            use_https=use_https,
            use_xor_mask=use_xor_mask
        )
        
        # 确保证书指纹已包含
        if use_https and not config.get('server', {}).get('certificate_fingerprint'):
            fingerprint = ota_service.get_certificate_fingerprint(device_id)
            if fingerprint:
                config['server']['certificate_fingerprint'] = fingerprint
        
        return config
    
    except Exception as e:
        logger.error(f"获取OTA配置失败: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"获取OTA配置失败: {str(e)}"
        )


@router.get("/xor-key/{device_id}")
async def get_xor_key(
    device_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_super_admin_user)
):
    """
    获取设备的XOR密钥（仅超级管理员）
    
    Args:
        device_id: 设备ID
        db: 数据库会话
        current_user: 当前用户（必须是超级管理员）
    """
    try:
        encryption_service = FirmwareEncryptionService()
        key = encryption_service.load_xor_key(device_id)
        
        if not key:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="未找到该设备的XOR密钥"
            )
        
        return {
            "device_id": device_id,
            "key_hex": key.hex(),
            "key_length": len(key)
        }
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"获取XOR密钥失败: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"获取XOR密钥失败: {str(e)}"
        )


@router.post("/generate-key/{device_id}")
async def generate_xor_key(
    device_id: str,
    force: bool = False,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_super_admin_user)
):
    """
    为设备生成新的XOR密钥（仅超级管理员）
    密钥会加密保存到数据库
    
    Args:
        device_id: 设备ID
        force: 是否强制重新生成（如果密钥已存在，设置为True可以覆盖）
        db: 数据库会话
        current_user: 当前用户（必须是超级管理员）
    """
    try:
        # 验证设备是否存在
        device_service = DeviceService(db)
        device = await device_service.get_by_device_id(device_id)
        if not device:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="设备不存在"
            )
        
        # 使用加密密钥服务生成并保存密钥
        key_service = EncryptionKeyService(db)
        key_hex = await key_service.create_key_for_device(str(device.id), str(current_user.id), force=force)
        
        if not key_hex:
            error_msg = "密钥已存在（如需重新生成，请设置force=true）" if not force else "密钥创建失败"
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=error_msg
            )
        
        return {
            "device_id": device_id,
            "key_hex": key_hex,  # 仅管理员可见
            "message": "XOR密钥已生成并加密保存到数据库"
        }
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"生成XOR密钥失败: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"生成XOR密钥失败: {str(e)}"
        )


@router.post("/build/{device_id}")
async def build_encrypted_firmware(
    device_id: str,
    build_req: dict,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    申请加密烧录文件（普通用户可用）
    生成加密固件二进制文件，不返回密钥信息
    
    Args:
        device_id: 设备ID
        build_req: 构建请求（包含WiFi配置等）
        db: 数据库会话
        current_user: 当前用户
    """
    try:
        from app.core.config import settings
        
        # 验证设备是否存在
        device_service = DeviceService(db)
        device = await device_service.get_by_device_id(device_id)
        if not device:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="设备不存在"
            )
        
        # 解析请求参数
        wifi_ssid = build_req.get("wifi_ssid", "")
        wifi_password = build_req.get("wifi_password", "")
        use_encryption = build_req.get("use_encryption", True)
        template_id = build_req.get("template_id")
        
        # 获取CA证书（确保使用最新的CA证书，与服务器证书同步）
        ca_cert = CertificateService.get_ca_certificate()
        if not ca_cert:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="CA证书不存在，无法生成固件。请先在'安全管理'中生成CA证书。"
            )
        
        logger.info(f"使用CA证书生成固件，设备ID: {device_id}, 模板ID: {template_id}")
        
        # 获取或创建加密密钥（如果使用加密）
        if use_encryption:
            try:
                key_service = EncryptionKeyService(db)
                # 检查密钥是否已存在
                existing_key = await key_service.get_key_for_device(str(device.id), decrypt=False, require_admin=False)
                if not existing_key:
                    # 如果密钥不存在，创建新密钥
                    logger.info(f"为设备 {device_id} 创建新的加密密钥")
                    await key_service.create_key_for_device(str(device.id), str(current_user.id))
                else:
                    logger.info(f"设备 {device_id} 已存在加密密钥")
            except Exception as e:
                logger.warning(f"处理加密密钥时出错（继续构建固件）: {e}")
                # 即使密钥处理失败，也继续构建固件（可能不使用加密）
        
        # 构建加密固件
        build_service = FirmwareBuildService()
        result = await build_service.build_encrypted_firmware(
            device_id=device.device_id,
            device_name=device.name,
            device_type=device.type,
            wifi_ssid=wifi_ssid,
            wifi_password=wifi_password,
            mqtt_server=getattr(settings, 'MQTT_BROKER_HOST', 'localhost'),
            ca_cert=ca_cert,
            use_encryption=use_encryption,
            template_id=template_id,
            db=db
        )
        
        if result["status"] == "failed":
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"固件构建失败: {', '.join(result.get('errors', []))}"
            )
        
        # 返回结果（不包含密钥信息）
        return {
            "device_id": device_id,
            "status": result["status"],
            "firmware_code_path": result.get("firmware_code_path"),
            "firmware_bin_path": result.get("firmware_bin_path"),
            "encrypted_firmware_path": result.get("encrypted_firmware_path"),
            "message": "加密固件构建成功，请联系管理员获取密钥" if use_encryption else "固件构建成功"
        }
    
    except HTTPException:
        raise
    except Exception as e:
        import traceback
        error_trace = traceback.format_exc()
        logger.error(f"构建加密固件失败: {e}\n{error_trace}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"构建加密固件失败: {str(e)}"
        )


@router.get("/status/{device_id}")
async def get_firmware_status(
    device_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    获取加密固件构建状态（普通用户可用）
    
    Args:
        device_id: 设备ID
        db: 数据库会话
        current_user: 当前用户
        
    Returns:
        固件状态信息
    """
    try:
        # 验证设备是否存在
        device_service = DeviceService(db)
        device = await device_service.get_by_device_id(device_id)
        if not device:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="设备不存在"
            )
        
        # 查找加密固件文件
        from pathlib import Path
        import os
        from datetime import datetime
        
        # 使用与构建服务相同的路径解析逻辑
        project_root = Path(__file__).parent.parent.parent.parent.parent
        firmware_dir = project_root / "data" / "firmware"
        encrypted_firmware = firmware_dir / f"{device_id}_masked.bin"
        
        # 检查文件是否存在
        if encrypted_firmware.exists():
            # 获取文件信息
            file_stat = encrypted_firmware.stat()
            file_size = file_stat.st_size
            file_mtime = datetime.fromtimestamp(file_stat.st_mtime)
            
            # 格式化文件大小
            if file_size < 1024:
                size_str = f"{file_size} B"
            elif file_size < 1024 * 1024:
                size_str = f"{file_size / 1024:.2f} KB"
            else:
                size_str = f"{file_size / (1024 * 1024):.2f} MB"
            
            return {
                "status": "completed",
                "device_id": device_id,
                "firmware_path": str(encrypted_firmware),
                "firmware_size": size_str,
                "firmware_size_bytes": file_size,
                "created_at": file_mtime.isoformat(),
                "exists": True
            }
        else:
            # 检查是否有构建中的文件（.ino或.bin文件）
            firmware_code = firmware_dir / f"{device_id}.ino"
            firmware_bin = firmware_dir / f"{device_id}.bin"
            
            if firmware_code.exists() or firmware_bin.exists():
                return {
                    "status": "pending",
                    "device_id": device_id,
                    "exists": False,
                    "message": "固件代码已生成，但加密固件尚未生成"
                }
            else:
                return {
                    "status": "not_found",
                    "device_id": device_id,
                    "exists": False,
                    "message": "暂无加密固件文件，请先构建固件"
                }
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"获取固件状态失败: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"获取固件状态失败: {str(e)}"
        )


@router.get("/download/{device_id}")
async def download_encrypted_firmware(
    device_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    下载加密固件文件（普通用户可用）
    不返回密钥信息
    
    Args:
        device_id: 设备ID
        db: 数据库会话
        current_user: 当前用户
    """
    try:
        # 验证设备是否存在
        device_service = DeviceService(db)
        device = await device_service.get_by_device_id(device_id)
        if not device:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="设备不存在"
            )
        
        # 查找加密固件文件
        from pathlib import Path
        # 使用与构建服务相同的路径解析逻辑
        project_root = Path(__file__).parent.parent.parent.parent.parent
        firmware_dir = project_root / "data" / "firmware"
        encrypted_firmware = firmware_dir / f"{device_id}_masked.bin"
        
        if not encrypted_firmware.exists():
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="加密固件文件不存在，请先构建固件"
            )
        
        # 返回文件
        return FileResponse(
            path=str(encrypted_firmware),
            filename=f"{device_id}_encrypted.bin",
            media_type="application/octet-stream"
        )
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"下载加密固件失败: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"下载加密固件失败: {str(e)}"
        )


@router.post("/ota-update/{device_id}", response_model=OTAUpdateResponse)
async def create_ota_update(
    device_id: str,
    request: OTAUpdateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    创建OTA更新任务并推送到设备
    """
    try:
        device_service = DeviceService(db)
        device = await device_service.get_by_device_id(device_id)
        
        if not device:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="设备不存在"
            )
        
        # 检查是否有可用的固件构建
        if request.firmware_build_id:
            # 验证构建是否存在
            from app.models.firmware_encryption import FirmwareBuild
            from sqlalchemy import select
            
            result = await db.execute(
                select(FirmwareBuild).where(FirmwareBuild.id == request.firmware_build_id)
            )
            build = result.scalar_one_or_none()
            if not build or build.device_id != device.id:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="固件构建不存在或不属于该设备"
                )
            if build.status != "completed":
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="固件构建尚未完成"
                )
        
        # 如果没有提供URL和build_id，使用默认的下载URL
        if not request.firmware_url and not request.firmware_build_id:
            request.firmware_url = f"/api/v1/firmware/download/{device_id}"
        
        # 创建OTA更新任务
        ota_service = OTAUpdateService(db)
        task = await ota_service.create_update_task(
            device_id=device.id,
            firmware_build_id=request.firmware_build_id,
            firmware_url=request.firmware_url,
            firmware_version=request.firmware_version,
            user_id=current_user.id
        )
        
        # 推送更新到设备
        success = await ota_service.push_update_to_device(task.id, device_id)
        
        if not success:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="无法推送OTA更新，MQTT连接可能不可用"
            )
        
        return OTAUpdateResponse(
            id=task.id,
            device_id=device_id,
            firmware_url=task.firmware_url,
            firmware_version=task.firmware_version,
            status=task.status,
            progress=task.progress,
            error_message=task.error_message,
            started_at=task.started_at,
            completed_at=task.completed_at,
            created_at=task.created_at,
            updated_at=task.updated_at
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"创建OTA更新任务失败: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"创建OTA更新任务失败: {str(e)}"
        )


@router.get("/ota-update/{device_id}/status", response_model=OTAUpdateStatusResponse)
async def get_ota_update_status(
    device_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    获取设备最新的OTA更新状态
    """
    try:
        device_service = DeviceService(db)
        device = await device_service.get_by_device_id(device_id)
        
        if not device:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="设备不存在"
            )
        
        try:
            ota_service = OTAUpdateService(db)
            task = await ota_service.get_latest_task(device.id)
        except Exception as db_error:
            # 如果是因为表不存在或其他数据库错误，返回404而不是500
            logger.warning(f"查询OTA更新任务失败（可能是表不存在）: {db_error}")
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="该设备没有OTA更新任务"
            )
        
        if not task:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="该设备没有OTA更新任务"
            )
        
        return OTAUpdateStatusResponse(
            status=task.status,
            progress=task.progress,
            error_message=task.error_message,
            started_at=task.started_at,
            completed_at=task.completed_at
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"获取OTA更新状态失败: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"获取OTA更新状态失败: {str(e)}"
        )


@router.get("/ota-update/{device_id}/tasks", response_model=List[OTAUpdateResponse])
async def get_ota_update_tasks(
    device_id: str,
    limit: int = 10,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    获取设备的所有OTA更新任务
    """
    try:
        device_service = DeviceService(db)
        device = await device_service.get_by_device_id(device_id)
        
        if not device:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="设备不存在"
            )
        
        ota_service = OTAUpdateService(db)
        tasks = await ota_service.get_device_tasks(device.id, limit)
        
        return [
            OTAUpdateResponse(
                id=task.id,
                device_id=device_id,
                firmware_url=task.firmware_url,
                firmware_version=task.firmware_version,
                status=task.status,
                progress=task.progress,
                error_message=task.error_message,
                started_at=task.started_at,
                completed_at=task.completed_at,
                created_at=task.created_at,
                updated_at=task.updated_at
            )
            for task in tasks
        ]
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"获取OTA更新任务列表失败: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"获取OTA更新任务列表失败: {str(e)}"
        )


@router.post("/ota-update/{task_id}/status")
async def update_ota_task_status(
    task_id: UUID,
    status: str,
    progress: Optional[str] = None,
    error_message: Optional[str] = None,
    db: AsyncSession = Depends(get_db)
):
    """
    更新OTA任务状态（通常由设备上报，不需要认证）
    注意：此端点应该添加设备认证机制，这里简化处理
    """
    try:
        ota_service = OTAUpdateService(db)
        success = await ota_service.update_task_status(
            task_id=task_id,
            status=status,
            progress=progress,
            error_message=error_message
        )
        
        if not success:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="OTA更新任务不存在"
            )
        
        return {"message": "状态已更新", "success": True}
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"更新OTA任务状态失败: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"更新OTA任务状态失败: {str(e)}"
        )

