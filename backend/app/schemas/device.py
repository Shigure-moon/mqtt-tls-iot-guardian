from typing import Optional, Dict, Any
from pydantic import BaseModel, UUID4
from datetime import datetime

class DeviceBase(BaseModel):
    device_id: str
    name: str
    type: str
    description: Optional[str] = None
    attributes: Optional[Dict[str, Any]] = None

class DeviceCreate(DeviceBase):
    pass

class DeviceUpdate(DeviceBase):
    status: Optional[str] = None
    name: Optional[str] = None
    type: Optional[str] = None

class Device(DeviceBase):
    id: UUID4
    status: str
    last_online_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class DeviceCertificateBase(BaseModel):
    certificate_type: str
    serial_number: str

class DeviceCertificateCreate(DeviceCertificateBase):
    certificate: str
    private_key: Optional[str] = None
    issued_at: datetime
    expires_at: datetime

class DeviceCertificate(DeviceCertificateBase):
    id: UUID4
    device_id: UUID4
    certificate: str
    issued_at: datetime
    expires_at: datetime
    revoked_at: Optional[datetime] = None
    revoke_reason: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True

class DeviceLogBase(BaseModel):
    log_type: str
    message: str
    metadata: Optional[Dict[str, Any]] = None

class DeviceLogCreate(DeviceLogBase):
    pass

class DeviceLog(DeviceLogBase):
    id: UUID4
    device_id: UUID4
    created_at: datetime

    class Config:
        from_attributes = True

class DeviceStats(BaseModel):
    total_messages: int
    online_duration: int
    last_seen: Optional[datetime]
    error_count: int

class FirmwareGenerateRequest(BaseModel):
    wifi_ssid: str
    wifi_password: str
    mqtt_server: str
    ca_cert: Optional[str] = None

class FirmwareResponse(BaseModel):
    device_id: str
    firmware_code: str
    message: str