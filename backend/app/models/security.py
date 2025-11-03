from datetime import datetime
from sqlalchemy import Column, String, JSON, DateTime, ForeignKey, Boolean, Integer
from sqlalchemy.dialects.postgresql import UUID, INET
from sqlalchemy.orm import relationship
import uuid
from app.core.database import Base

class SecurityEvent(Base):
    __tablename__ = "security_events"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    event_type = Column(String(50), nullable=False)
    severity = Column(String(20), nullable=False)
    source_ip = Column(INET)
    device_id = Column(UUID(as_uuid=True), ForeignKey("devices.id", ondelete="SET NULL"))
    description = Column(String, nullable=False)
    raw_data = Column(JSON)
    handled = Column(Boolean, default=False)
    handler_id = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    handled_at = Column(DateTime(timezone=True))
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow)

    device = relationship("Device", backref="security_events")
    handler = relationship("User", backref="handled_events")

class AccessControlPolicy(Base):
    __tablename__ = "access_control_policies"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(100), nullable=False)
    description = Column(String)
    device_id = Column(UUID(as_uuid=True), ForeignKey("devices.id", ondelete="CASCADE"))
    topic_pattern = Column(String(255), nullable=False)
    action = Column(String(20), nullable=False)  # publish, subscribe
    effect = Column(String(10), nullable=False)  # allow, deny
    conditions = Column(JSON)  # 如时间范围、IP范围等
    priority = Column(Integer, default=0)
    enabled = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow)
    updated_at = Column(DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow)

    device = relationship("Device", backref="access_policies")

class SecurityAuditLog(Base):
    __tablename__ = "security_audit_logs"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    log_type = Column(String(50), nullable=False)
    actor_id = Column(UUID(as_uuid=True))
    actor_type = Column(String(20))  # user, device, system
    target_id = Column(UUID(as_uuid=True))
    target_type = Column(String(20))
    action = Column(String(50), nullable=False)
    status = Column(String(20), nullable=False)  # success, failure, error
    ip_address = Column(INET)
    user_agent = Column(String)
    details = Column(JSON)
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow)

class BlacklistedIP(Base):
    __tablename__ = "blacklisted_ips"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    ip_address = Column(INET, nullable=False, unique=True)
    reason = Column(String)
    expiry_at = Column(DateTime(timezone=True))
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow)
    updated_at = Column(DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow)