from datetime import datetime
from typing import Dict, Any, Optional, List
from pydantic import BaseModel, Field, validator, UUID4
from enum import Enum

class MetricType(str, Enum):
    SYSTEM = "system"
    PERFORMANCE = "performance"
    SECURITY = "security"
    NETWORK = "network"
    CUSTOM = "custom"

class AlertCondition(str, Enum):
    GT = "gt"   # 大于
    LT = "lt"   # 小于
    GTE = "gte" # 大于等于
    LTE = "lte" # 小于等于
    EQ = "eq"   # 等于
    NEQ = "neq" # 不等于

class AlertSeverity(str, Enum):
    CRITICAL = "critical"
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"

class AlertStatus(str, Enum):
    ACTIVE = "active"
    ACKNOWLEDGED = "acknowledged"
    RESOLVED = "resolved"

# 设备指标相关模式
class DeviceMetricsBase(BaseModel):
    device_id: UUID4  # 使用UUID4类型
    metric_type: str  # 使用字符串而不是枚举，以支持任意指标类型
    metrics: Dict[str, Any]

class DeviceMetricsCreate(DeviceMetricsBase):
    pass

class DeviceMetrics(DeviceMetricsBase):
    id: str
    timestamp: datetime

    class Config:
        from_attributes = True

# 告警规则相关模式
class AlertRuleBase(BaseModel):
    name: str
    description: Optional[str] = None
    device_id: Optional[UUID4] = None
    metric_type: MetricType
    metric_name: str
    condition: AlertCondition
    threshold: float
    severity: AlertSeverity
    message: str = Field(..., description="支持 {value} 和 {threshold} 占位符")
    enabled: bool = True
    priority: int = Field(default=0, ge=0, le=100)

    @validator("message")
    def validate_message_template(cls, v):
        if "{value}" not in v or "{threshold}" not in v:
            raise ValueError("消息模板必须包含 {value} 和 {threshold} 占位符")
        return v

class AlertRuleCreate(AlertRuleBase):
    pass

class AlertRuleUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    condition: Optional[AlertCondition] = None
    threshold: Optional[float] = None
    severity: Optional[AlertSeverity] = None
    message: Optional[str] = None
    enabled: Optional[bool] = None
    priority: Optional[int] = Field(None, ge=0, le=100)

    @validator("message")
    def validate_message_template(cls, v):
        if v is not None and ("{value}" not in v or "{threshold}" not in v):
            raise ValueError("消息模板必须包含 {value} 和 {threshold} 占位符")
        return v

class AlertRule(AlertRuleBase):
    id: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

# 监控告警相关模式
class MonitoringAlertBase(BaseModel):
    device_id: UUID4
    rule_id: str
    metrics_id: str
    severity: AlertSeverity
    message: str
    status: AlertStatus

class MonitoringAlert(MonitoringAlertBase):
    id: str
    created_at: datetime
    acknowledged_at: Optional[datetime] = None
    acknowledged_by: Optional[UUID4] = None
    resolved_at: Optional[datetime] = None
    resolved_by: Optional[UUID4] = None

    class Config:
        from_attributes = True

# 系统状态相关模式
class AlertSeverityDistribution(BaseModel):
    critical: int = 0
    high: int = 0
    medium: int = 0
    low: int = 0

class SystemStatus(BaseModel):
    online_devices: int
    total_active_alerts: int
    alert_severity_distribution: AlertSeverityDistribution
    system_metrics: Optional[Dict[str, Any]] = None
    last_update: Optional[datetime] = None

# API响应模式
class MonitoringStatsResponse(BaseModel):
    total_metrics: int
    metrics_24h: int
    active_rules: int
    alerts_summary: AlertSeverityDistribution
    recent_alerts: List[MonitoringAlert]

class DeviceStatusResponse(BaseModel):
    device_id: str
    online: bool
    last_seen: Optional[datetime]
    current_metrics: Optional[Dict[str, Any]]
    active_alerts: List[MonitoringAlert]
    alert_rules: List[AlertRule]