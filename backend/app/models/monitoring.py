from datetime import datetime
from typing import Dict, Any, Optional
from sqlalchemy import Column, String, Float, Boolean, DateTime, Integer, JSON, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base
from app.core.id import generate_id

class DeviceMetrics(Base):
    """设备指标数据模型"""
    __tablename__ = "device_metrics"

    id = Column(String, primary_key=True, default=generate_id)
    device_id = Column(String, ForeignKey("devices.id"), nullable=False)
    metric_type = Column(String, nullable=False)  # system, performance, security 等
    metrics = Column(JSON, nullable=False)  # 存储具体的指标数据
    timestamp = Column(DateTime, nullable=False, default=datetime.utcnow)

    # 关联
    device = relationship("Device", back_populates="metrics")
    alerts = relationship("MonitoringAlert", back_populates="metrics")

class AlertRule(Base):
    """告警规则模型"""
    __tablename__ = "alert_rules"

    id = Column(String, primary_key=True, default=generate_id)
    name = Column(String, nullable=False)
    description = Column(String)
    device_id = Column(String, ForeignKey("devices.id"))
    metric_type = Column(String, nullable=False)
    metric_name = Column(String, nullable=False)
    condition = Column(String, nullable=False)  # gt, lt, gte, lte, eq, neq
    threshold = Column(Float, nullable=False)
    severity = Column(String, nullable=False)  # critical, high, medium, low
    message = Column(String, nullable=False)  # 告警消息模板
    enabled = Column(Boolean, default=True)
    priority = Column(Integer, default=0)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    updated_at = Column(DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)

    # 关联
    device = relationship("Device", back_populates="alert_rules")
    alerts = relationship("MonitoringAlert", back_populates="rule")

class MonitoringAlert(Base):
    """监控告警模型"""
    __tablename__ = "monitoring_alerts"

    id = Column(String, primary_key=True, default=generate_id)
    device_id = Column(String, ForeignKey("devices.id"), nullable=False)
    rule_id = Column(String, ForeignKey("alert_rules.id"), nullable=False)
    metrics_id = Column(String, ForeignKey("device_metrics.id"), nullable=False)
    severity = Column(String, nullable=False)  # critical, high, medium, low
    message = Column(String, nullable=False)
    status = Column(String, nullable=False)  # active, acknowledged, resolved
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    acknowledged_at = Column(DateTime)
    acknowledged_by = Column(String, ForeignKey("users.id"))
    resolved_at = Column(DateTime)
    resolved_by = Column(String, ForeignKey("users.id"))

    # 关联
    device = relationship("Device", back_populates="alerts")
    rule = relationship("AlertRule", back_populates="alerts")
    metrics = relationship("DeviceMetrics", back_populates="alerts")
    acknowledger = relationship("User", foreign_keys=[acknowledged_by])
    resolver = relationship("User", foreign_keys=[resolved_by])