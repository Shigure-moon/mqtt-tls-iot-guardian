from datetime import datetime
from sqlalchemy import Column, String, JSON, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
import uuid
from app.core.database import Base

class Device(Base):
    __tablename__ = "devices"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    device_id = Column(String(100), unique=True, index=True, nullable=False)
    name = Column(String(100), nullable=False)
    type = Column(String(50), nullable=False)
    description = Column(String)
    status = Column(String(20), default="inactive")
    attributes = Column(JSON)
    last_online_at = Column(DateTime(timezone=True))
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow)
    updated_at = Column(DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow)

class DeviceCertificate(Base):
    __tablename__ = "device_certificates"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    device_id = Column(UUID(as_uuid=True), ForeignKey("devices.id", ondelete="CASCADE"))
    certificate = Column(String, nullable=False)
    private_key = Column(String)
    certificate_type = Column(String(20), nullable=False)
    serial_number = Column(String(100), unique=True, nullable=False)
    issued_at = Column(DateTime(timezone=True), nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=False)
    revoked_at = Column(DateTime(timezone=True))
    revoke_reason = Column(String(100))
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow)

    device = relationship("Device", backref="certificates")

class DeviceLog(Base):
    __tablename__ = "device_logs"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    device_id = Column(UUID(as_uuid=True), ForeignKey("devices.id", ondelete="CASCADE"))
    log_type = Column(String(50), nullable=False)
    message = Column(String, nullable=False)
    log_metadata = Column(JSON)
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow)

    device = relationship("Device", backref="logs")