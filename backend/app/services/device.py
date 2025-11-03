from typing import Optional, List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, and_
from sqlalchemy.orm import joinedload
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
            .options(joinedload(Device.certificates))
            .filter(Device.id == device_id)
        )
        return result.scalar_one_or_none()

    async def get_by_device_id(self, device_id: str) -> Optional[Device]:
        """通过设备ID获取设备"""
        result = await self.db.execute(
            select(Device)
            .options(joinedload(Device.certificates))
            .filter(Device.device_id == device_id)
        )
        return result.scalar_one_or_none()

    async def get_multi(self, skip: int = 0, limit: int = 100) -> List[Device]:
        """获取多个设备"""
        result = await self.db.execute(
            select(Device)
            .options(joinedload(Device.certificates))
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
        
        self.db.add(device)
        await self.db.commit()
        await self.db.refresh(device)
        return device

    async def add_certificate(self, device: Device, cert_in: DeviceCertificateCreate) -> DeviceCertificate:
        """添加设备证书"""
        cert = DeviceCertificate(
            device_id=device.id,
            **cert_in.model_dump()
        )
        self.db.add(cert)
        await self.db.commit()
        await self.db.refresh(cert)
        return cert

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