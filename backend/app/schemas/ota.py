"""
OTA更新相关Schema
"""
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from uuid import UUID


class OTAUpdateRequest(BaseModel):
    """OTA更新请求"""
    firmware_build_id: Optional[UUID] = None  # 固件构建ID（如果提供则使用该构建）
    firmware_url: Optional[str] = None  # 固件URL（如果未提供build_id，则使用此URL）
    firmware_version: Optional[str] = None  # 固件版本号


class OTAUpdateResponse(BaseModel):
    """OTA更新响应"""
    id: UUID
    device_id: str
    firmware_url: str
    firmware_version: Optional[str] = None
    status: str
    progress: str
    error_message: Optional[str] = None
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class OTAUpdateStatusResponse(BaseModel):
    """OTA更新状态响应"""
    status: str
    progress: str
    error_message: Optional[str] = None
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None

