"""
设备模板Schema
"""
from typing import Optional, List
from pydantic import BaseModel, Field
from datetime import datetime
from uuid import UUID as UUIDType


class DeviceTemplateBase(BaseModel):
    name: str = Field(..., description="模板名称", max_length=100)
    version: str = Field("v1", description="版本号", max_length=20)
    device_type: str = Field(..., description="设备类型", max_length=50)
    description: Optional[str] = Field(None, description="模板描述", max_length=500)
    template_code: str = Field(..., description="模板代码")
    required_libraries: Optional[str] = Field(None, description="所需库列表（JSON格式）")
    is_active: bool = Field(True, description="是否启用")


class DeviceTemplateCreate(DeviceTemplateBase):
    pass


class DeviceTemplateUpdate(BaseModel):
    name: Optional[str] = Field(None, max_length=100)
    version: Optional[str] = Field(None, max_length=20)
    device_type: Optional[str] = Field(None, max_length=50)
    description: Optional[str] = Field(None, max_length=500)
    template_code: Optional[str] = None
    required_libraries: Optional[str] = None
    is_active: Optional[bool] = None


class DeviceTemplate(DeviceTemplateBase):
    id: UUIDType
    created_at: datetime
    updated_at: datetime
    created_by: Optional[UUIDType] = None

    class Config:
        from_attributes = True

