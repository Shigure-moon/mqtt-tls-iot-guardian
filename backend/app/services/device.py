from typing import Optional, List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, and_
from app.models.device import Device, DeviceCertificate, DeviceLog
from app.schemas.device import DeviceCreate, DeviceUpdate, DeviceCertificateCreate, DeviceLogCreate
from datetime import datetime

class DeviceService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_id(self, device_id: str) -> Optional[Device]:
        """通过ID获取设备"""
        result = await self.db.execute(
            select(Device)
            .filter(Device.id == device_id)
        )
        return result.scalar_one_or_none()

    async def get_by_device_id(self, device_id: str) -> Optional[Device]:
        """通过设备ID获取设备"""
        result = await self.db.execute(
            select(Device)
            .filter(Device.device_id == device_id)
        )
        return result.scalar_one_or_none()

    async def get_multi(self, skip: int = 0, limit: int = 100) -> List[Device]:
        """获取多个设备"""
        result = await self.db.execute(
            select(Device)
            .offset(skip)
            .limit(limit)
        )
        return result.scalars().all()

    async def create(self, device_in: DeviceCreate) -> Device:
        """创建新设备"""
        device = Device(**device_in.model_dump())
        self.db.add(device)
        await self.db.commit()
        await self.db.refresh(device)
        return device

    async def update(self, device: Device, device_in: DeviceUpdate) -> Device:
        """更新设备信息"""
        update_data = device_in.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(device, field, value)
        
        self.db.add(device)
        await self.db.commit()
        await self.db.refresh(device)
        return device

    async def delete(self, device: Device) -> None:
        """删除设备"""
        await self.db.delete(device)
        await self.db.commit()

    async def update_status(self, device: Device, status: str) -> Device:
        """更新设备状态"""
        device.status = status
        if status == "online":
            device.last_online_at = datetime.utcnow()
        # 注意：当状态变为offline时，不更新last_online_at，保留最后在线时间
        
        self.db.add(device)
        await self.db.commit()
        await self.db.refresh(device)
        return device

    async def add_certificate(self, device: Device, cert_in: DeviceCertificateCreate) -> DeviceCertificate:
        """添加设备证书（加密存储）"""
        from app.core.encryption import encrypt_certificate_data
        
        # 加密证书和私钥
        encrypted_cert = encrypt_certificate_data(cert_in.certificate)
        encrypted_private_key = None
        if cert_in.private_key:
            encrypted_private_key = encrypt_certificate_data(cert_in.private_key)
        
        # 检查序列号是否已存在（如果存在，记录警告但继续）
        from sqlalchemy import select
        existing = await self.db.execute(
            select(DeviceCertificate)
            .filter(DeviceCertificate.serial_number == cert_in.serial_number)
        )
        if existing.scalar_one_or_none():
            import logging
            logger = logging.getLogger(__name__)
            logger.warning(f"证书序列号 {cert_in.serial_number} 已存在，但继续创建新证书")
            # 注意：如果数据库有唯一约束，这里会抛出异常
        
        # 创建证书对象，使用加密后的数据
        cert = DeviceCertificate(
            device_id=device.id,
            certificate=encrypted_cert,
            private_key=encrypted_private_key,
            certificate_type=cert_in.certificate_type,
            serial_number=cert_in.serial_number,
            issued_at=cert_in.issued_at,
            expires_at=cert_in.expires_at
        )
        self.db.add(cert)
        try:
            await self.db.commit()
            await self.db.refresh(cert)
            return cert
        except Exception as e:
            await self.db.rollback()
            import logging
            logger = logging.getLogger(__name__)
            logger.error(f"保存证书到数据库失败: {e}", exc_info=True)
            # 检查是否是唯一约束冲突
            error_str = str(e).lower()
            if 'unique' in error_str or 'duplicate' in error_str:
                raise ValueError(f"证书序列号 {cert_in.serial_number} 已存在，请重新生成证书")
            raise

    async def revoke_certificate(self, cert: DeviceCertificate, reason: str) -> DeviceCertificate:
        """吊销设备证书"""
        cert.revoked_at = datetime.utcnow()
        cert.revoke_reason = reason
        self.db.add(cert)
        await self.db.commit()
        await self.db.refresh(cert)
        return cert

    async def add_log(self, device: Device, log_in: DeviceLogCreate) -> DeviceLog:
        """添加设备日志"""
        log = DeviceLog(
            device_id=device.id,
            **log_in.model_dump()
        )
        self.db.add(log)
        await self.db.commit()
        await self.db.refresh(log)
        return log

    async def get_device_logs(
        self, device: Device, skip: int = 0, limit: int = 100
    ) -> List[DeviceLog]:
        """获取设备日志"""
        result = await self.db.execute(
            select(DeviceLog)
            .filter(DeviceLog.device_id == device.id)
            .order_by(DeviceLog.created_at.desc())
            .offset(skip)
            .limit(limit)
        )
        return result.scalars().all()