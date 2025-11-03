from typing import Optional, Dict, Any, List
from pydantic import BaseModel, UUID4, IPvAnyAddress
from datetime import datetime

class SecurityEventBase(BaseModel):
    event_type: str
    severity: str
    source_ip: Optional[IPvAnyAddress] = None
    device_id: Optional[UUID4] = None
    description: str
    raw_data: Optional[Dict[str, Any]] = None

class SecurityEventCreate(SecurityEventBase):
    pass

class SecurityEvent(SecurityEventBase):
    id: UUID4
    handled: bool
    handler_id: Optional[UUID4] = None
    handled_at: Optional[datetime] = None
    created_at: datetime

    class Config:
        from_attributes = True

class AccessControlPolicyBase(BaseModel):
    name: str
    description: Optional[str] = None
    device_id: UUID4
    topic_pattern: str
    action: str
    effect: str
    conditions: Optional[Dict[str, Any]] = None
    priority: int = 0
    enabled: bool = True

class AccessControlPolicyCreate(AccessControlPolicyBase):
    pass

class AccessControlPolicyUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    topic_pattern: Optional[str] = None
    action: Optional[str] = None
    effect: Optional[str] = None
    conditions: Optional[Dict[str, Any]] = None
    priority: Optional[int] = None
    enabled: Optional[bool] = None

class AccessControlPolicy(AccessControlPolicyBase):
    id: UUID4
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class SecurityAuditLogBase(BaseModel):
    log_type: str
    actor_id: Optional[UUID4] = None
    actor_type: Optional[str] = None
    target_id: Optional[UUID4] = None
    target_type: Optional[str] = None
    action: str
    status: str
    ip_address: Optional[IPvAnyAddress] = None
    user_agent: Optional[str] = None
    details: Optional[Dict[str, Any]] = None

class SecurityAuditLogCreate(SecurityAuditLogBase):
    pass

class SecurityAuditLog(SecurityAuditLogBase):
    id: UUID4
    created_at: datetime

    class Config:
        from_attributes = True

class BlacklistedIPBase(BaseModel):
    ip_address: IPvAnyAddress
    reason: Optional[str] = None
    expiry_at: Optional[datetime] = None

class BlacklistedIPCreate(BlacklistedIPBase):
    pass

class BlacklistedIP(BlacklistedIPBase):
    id: UUID4
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class SecurityStats(BaseModel):
    total_events: int
    severity_distribution: Dict[str, int]
    recent_events: List[SecurityEvent]
    top_threats: List[Dict[str, Any]]
    active_blacklist_count: int