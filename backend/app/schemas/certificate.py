"""
证书管理相关的Pydantic schemas
"""
from typing import Optional
from pydantic import BaseModel, Field
from datetime import datetime

class CACertificateResponse(BaseModel):
    """CA证书响应"""
    ca_key: str = Field(..., description="CA私钥(PEM格式)")
    ca_cert: str = Field(..., description="CA证书(PEM格式)")
    message: str = Field(default="CA证书已生成", description="消息")

class ServerCertificateRequest(BaseModel):
    """服务器证书请求"""
    common_name: str = Field(default="mosquitto-broker", description="服务器Common Name")
    alt_names: Optional[list] = Field(default=None, description="额外的主机名列表")
    validity_days: int = Field(default=365, gt=0, le=3650, description="证书有效期（天）")

class ServerCertificateResponse(BaseModel):
    """服务器证书响应"""
    server_key: str = Field(..., description="服务器私钥(PEM格式)")
    server_cert: str = Field(..., description="服务器证书(PEM格式)")
    message: str = Field(default="服务器证书已生成", description="消息")

class ClientCertificateRequest(BaseModel):
    """客户端证书请求"""
    device_id: str = Field(..., description="设备ID")
    common_name: Optional[str] = Field(default=None, description="Common Name，默认使用device_id")
    validity_days: int = Field(default=365, gt=0, le=3650, description="证书有效期（天）")

class ClientCertificateResponse(BaseModel):
    """客户端证书响应"""
    client_key: str = Field(..., description="客户端私钥(PEM格式)")
    client_cert: str = Field(..., description="客户端证书(PEM格式)")
    ca_cert: str = Field(..., description="CA证书(PEM格式)")
    serial_number: str = Field(..., description="证书序列号")
    message: str = Field(default="客户端证书已生成", description="消息")

class CertificateVerificationRequest(BaseModel):
    """证书验证请求"""
    certificate: str = Field(..., description="证书PEM格式字符串")

class CertificateVerificationResponse(BaseModel):
    """证书验证响应"""
    is_valid: bool = Field(..., description="是否有效")
    error_message: Optional[str] = Field(None, description="错误信息")

class CACertificateDownloadResponse(BaseModel):
    """CA证书下载响应"""
    ca_cert: str = Field(..., description="CA证书(PEM格式)")

class CertificateRevokeRequest(BaseModel):
    """证书吊销请求"""
    serial_number: str = Field(..., description="证书序列号")
    reason: Optional[str] = Field(None, description="吊销原因")

class CertificateRevokeResponse(BaseModel):
    """证书吊销响应"""
    success: bool = Field(..., description="是否成功")
    message: str = Field(..., description="消息")

