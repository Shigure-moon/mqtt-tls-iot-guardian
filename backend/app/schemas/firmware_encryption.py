"""
固件加密相关Pydantic schemas
"""
from typing import Optional
from pydantic import BaseModel, Field
from datetime import datetime


class FirmwareBuildRequest(BaseModel):
    """固件构建请求"""
    wifi_ssid: str = Field(..., description="WiFi SSID")
    wifi_password: str = Field(..., description="WiFi密码")
    use_encryption: bool = Field(default=True, description="是否使用加密")
    template_id: Optional[str] = Field(None, description="模板ID（可选）")


class FirmwareBuildResponse(BaseModel):
    """固件构建响应"""
    build_id: str = Field(..., description="构建ID")
    device_id: str = Field(..., description="设备ID")
    status: str = Field(..., description="构建状态：pending, building, completed, failed")
    firmware_code_path: Optional[str] = Field(None, description="固件代码路径")
    firmware_bin_path: Optional[str] = Field(None, description="固件二进制路径")
    encrypted_firmware_path: Optional[str] = Field(None, description="加密固件路径")
    firmware_size: Optional[str] = Field(None, description="固件大小")
    firmware_hash: Optional[str] = Field(None, description="固件哈希")
    error_message: Optional[str] = Field(None, description="错误信息")
    created_at: datetime = Field(..., description="创建时间")


class EncryptedFirmwareDownloadResponse(BaseModel):
    """加密固件下载响应"""
    device_id: str = Field(..., description="设备ID")
    firmware_path: str = Field(..., description="固件文件路径")
    firmware_size: int = Field(..., description="固件大小（字节）")
    firmware_hash: str = Field(..., description="固件SHA256哈希")
    use_encryption: bool = Field(..., description="是否加密")
    # 注意：不包含密钥信息，只有管理员可以查看密钥

