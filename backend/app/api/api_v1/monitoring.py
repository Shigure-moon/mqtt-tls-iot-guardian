from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import datetime, timedelta

from app.api.api_v1.auth import get_current_active_user
from app.core.database import get_db
from app.schemas.user import User
from app.schemas.monitoring import (
    DeviceMetrics,
    DeviceMetricsCreate,
    AlertRule,
    AlertRuleCreate,
    AlertRuleUpdate,
    MonitoringAlert,
    SystemStatus
)
from app.services.monitoring import MonitoringService

router = APIRouter()

# 设备指标管理
@router.post("/metrics", response_model=DeviceMetrics)
async def create_device_metrics(
    metrics_in: DeviceMetricsCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
) -> DeviceMetrics:
    """创建设备指标记录"""
    monitoring_service = MonitoringService(db)
    metrics = await monitoring_service.create_metrics(metrics_in)
    return metrics

@router.get("/metrics/{device_id}", response_model=List[DeviceMetrics])
async def get_device_metrics(
    device_id: str,
    start_time: Optional[datetime] = None,
    end_time: Optional[datetime] = None,
    metric_type: Optional[str] = None,
    limit: int = Query(100, gt=0, le=1000),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
) -> List[DeviceMetrics]:
    """获取设备指标历史数据"""
    try:
        # 转换为无时区的时间
        def remove_timezone(dt: datetime) -> datetime:
            if dt.tzinfo is not None:
                return dt.replace(tzinfo=None)
            return dt
        
        start = start_time if start_time is None else remove_timezone(start_time)
        end = end_time if end_time is None else remove_timezone(end_time)
        
        monitoring_service = MonitoringService(db)
        metrics = await monitoring_service.get_device_metrics(
            device_id=device_id,
            start_time=start or datetime.utcnow() - timedelta(hours=24),
            end_time=end or datetime.utcnow(),
            metric_type=metric_type,
            limit=limit
        )
        return metrics
    except Exception as e:
        import logging
        logger = logging.getLogger(__name__)
        logger.error(f"Error getting device metrics: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"获取设备指标失败: {str(e)}"
        )

# 告警规则管理
@router.post("/alert-rules", response_model=AlertRule)
async def create_alert_rule(
    rule_in: AlertRuleCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
) -> AlertRule:
    """创建告警规则"""
    monitoring_service = MonitoringService(db)
    rule = await monitoring_service.create_alert_rule(rule_in)
    return rule

@router.get("/alert-rules", response_model=List[AlertRule])
async def get_alert_rules(
    device_id: Optional[str] = None,
    enabled: Optional[bool] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
) -> List[AlertRule]:
    """获取告警规则列表"""
    monitoring_service = MonitoringService(db)
    rules = await monitoring_service.get_alert_rules(
        device_id=device_id,
        enabled=enabled
    )
    return rules

@router.put("/alert-rules/{rule_id}", response_model=AlertRule)
async def update_alert_rule(
    rule_id: str,
    rule_in: AlertRuleUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
) -> AlertRule:
    """更新告警规则"""
    monitoring_service = MonitoringService(db)
    rule = await monitoring_service.get_alert_rule(rule_id)
    if not rule:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="告警规则不存在"
        )
    
    updated_rule = await monitoring_service.update_alert_rule(rule, rule_in)
    return updated_rule

@router.delete("/alert-rules/{rule_id}")
async def delete_alert_rule(
    rule_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """删除告警规则"""
    monitoring_service = MonitoringService(db)
    rule = await monitoring_service.get_alert_rule(rule_id)
    if not rule:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="告警规则不存在"
        )
    
    await monitoring_service.delete_alert_rule(rule)
    return {"message": "告警规则已删除"}

# 告警管理
@router.get("/alerts", response_model=List[MonitoringAlert])
async def get_alerts(
    device_id: Optional[str] = None,
    start_time: Optional[datetime] = None,
    end_time: Optional[datetime] = None,
    severity: Optional[str] = None,
    status: Optional[str] = None,
    limit: int = Query(100, gt=0, le=1000),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
) -> List[MonitoringAlert]:
    """获取告警列表"""
    monitoring_service = MonitoringService(db)
    alerts = await monitoring_service.get_alerts(
        device_id=device_id,
        start_time=start_time,
        end_time=end_time,
        severity=severity,
        status=status,
        limit=limit
    )
    return alerts

@router.post("/alerts/{alert_id}/acknowledge")
async def acknowledge_alert(
    alert_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """确认告警"""
    monitoring_service = MonitoringService(db)
    alert = await monitoring_service.get_alert(alert_id)
    if not alert:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="告警不存在"
        )
    
    await monitoring_service.acknowledge_alert(alert, str(current_user.id))
    return {"message": "告警已确认"}

@router.get("/status", response_model=SystemStatus)
async def get_system_status(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
) -> SystemStatus:
    """获取系统整体状态"""
    monitoring_service = MonitoringService(db)
    status = await monitoring_service.get_system_status()
    return status