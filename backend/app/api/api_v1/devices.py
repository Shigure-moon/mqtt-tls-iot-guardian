from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.api.api_v1.auth import get_current_active_user
from app.core.database import get_db
from app.schemas.device import (
    Device, DeviceCreate, DeviceUpdate,
    DeviceCertificate, DeviceCertificateCreate,
    DeviceLog, DeviceLogCreate, DeviceStats
)
from app.services.device import DeviceService
from app.schemas.user import User

router = APIRouter()

@router.post("", response_model=Device)
async def create_device(
    device_in: DeviceCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
) -> Device:
    """创建新设备"""
    device_service = DeviceService(db)
    
    # 检查设备ID是否已存在
    if await device_service.get_by_device_id(device_in.device_id):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="设备ID已存在"
        )
    
    device = await device_service.create(device_in)
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
    device_service = DeviceService(db)
    device = await device_service.get_by_id(device_id)
    if not device:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="设备不存在"
        )
    return device

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
    return cert

@router.post("/{device_id}/certificates/{cert_id}/revoke")
async def revoke_device_certificate(
    device_id: str,
    cert_id: str,
    reason: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """吊销设备证书"""
    device_service = DeviceService(db)
    device = await device_service.get_by_id(device_id)
    if not device:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="设备不存在"
        )
    
    # TODO: 实现证书吊销逻辑
    return {"message": "证书已吊销"}

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