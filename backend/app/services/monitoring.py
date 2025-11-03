from typing import List, Optional, Dict, Any
from datetime import datetime, timedelta
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, or_, desc, func

from app.models.monitoring import (
    DeviceMetrics as DeviceMetricsModel,
    AlertRule as AlertRuleModel,
    MonitoringAlert as MonitoringAlertModel
)
from app.schemas.monitoring import (
    DeviceMetricsCreate,
    AlertRuleCreate,
    AlertRuleUpdate,
    SystemStatus
)

class MonitoringService:
    def __init__(self, db: AsyncSession):
        self.db = db

    # 设备指标管理
    async def create_metrics(
        self, metrics_in: DeviceMetricsCreate
    ) -> DeviceMetricsModel:
        """创建设备指标记录"""
        metrics = DeviceMetricsModel(**metrics_in.model_dump())
        self.db.add(metrics)
        await self.db.commit()
        await self.db.refresh(metrics)

        # 触发告警检查
        await self._check_alert_rules(metrics)
        
        return metrics

    async def get_device_metrics(
        self,
        device_id: str,
        start_time: datetime,
        end_time: datetime,
        metric_type: Optional[str] = None,
        limit: int = 100
    ) -> List[DeviceMetricsModel]:
        """获取设备指标历史数据"""
        query = (
            select(DeviceMetricsModel)
            .filter(DeviceMetricsModel.device_id == device_id)
            .filter(DeviceMetricsModel.timestamp >= start_time)
            .filter(DeviceMetricsModel.timestamp <= end_time)
        )
        
        if metric_type:
            query = query.filter(DeviceMetricsModel.metric_type == metric_type)
        
        query = query.order_by(desc(DeviceMetricsModel.timestamp)).limit(limit)
        result = await self.db.execute(query)
        return result.scalars().all()

    # 告警规则管理
    async def create_alert_rule(
        self, rule_in: AlertRuleCreate
    ) -> AlertRuleModel:
        """创建告警规则"""
        rule = AlertRuleModel(**rule_in.model_dump())
        self.db.add(rule)
        await self.db.commit()
        await self.db.refresh(rule)
        return rule

    async def get_alert_rule(
        self, rule_id: str
    ) -> Optional[AlertRuleModel]:
        """获取告警规则"""
        result = await self.db.execute(
            select(AlertRuleModel).filter(AlertRuleModel.id == rule_id)
        )
        return result.scalar_one_or_none()

    async def get_alert_rules(
        self,
        device_id: Optional[str] = None,
        enabled: Optional[bool] = None
    ) -> List[AlertRuleModel]:
        """获取告警规则列表"""
        query = select(AlertRuleModel)
        if device_id:
            query = query.filter(AlertRuleModel.device_id == device_id)
        if enabled is not None:
            query = query.filter(AlertRuleModel.enabled == enabled)
        
        query = query.order_by(AlertRuleModel.priority.desc())
        result = await self.db.execute(query)
        return result.scalars().all()

    async def update_alert_rule(
        self,
        rule: AlertRuleModel,
        rule_in: AlertRuleUpdate
    ) -> AlertRuleModel:
        """更新告警规则"""
        update_data = rule_in.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(rule, field, value)
        
        await self.db.commit()
        await self.db.refresh(rule)
        return rule

    async def delete_alert_rule(self, rule: AlertRuleModel) -> None:
        """删除告警规则"""
        await self.db.delete(rule)
        await self.db.commit()

    # 告警管理
    async def get_alert(
        self, alert_id: str
    ) -> Optional[MonitoringAlertModel]:
        """获取告警"""
        result = await self.db.execute(
            select(MonitoringAlertModel)
            .filter(MonitoringAlertModel.id == alert_id)
        )
        return result.scalar_one_or_none()

    async def get_alerts(
        self,
        device_id: Optional[str] = None,
        start_time: Optional[datetime] = None,
        end_time: Optional[datetime] = None,
        severity: Optional[str] = None,
        status: Optional[str] = None,
        limit: int = 100
    ) -> List[MonitoringAlertModel]:
        """获取告警列表"""
        query = select(MonitoringAlertModel)
        
        if device_id:
            query = query.filter(MonitoringAlertModel.device_id == device_id)
        if start_time:
            query = query.filter(MonitoringAlertModel.created_at >= start_time)
        if end_time:
            query = query.filter(MonitoringAlertModel.created_at <= end_time)
        if severity:
            query = query.filter(MonitoringAlertModel.severity == severity)
        if status:
            query = query.filter(MonitoringAlertModel.status == status)
        
        query = query.order_by(desc(MonitoringAlertModel.created_at)).limit(limit)
        result = await self.db.execute(query)
        return result.scalars().all()

    async def acknowledge_alert(
        self, alert: MonitoringAlertModel,
        user_id: str
    ) -> MonitoringAlertModel:
        """确认告警"""
        alert.status = "acknowledged"
        alert.acknowledged_by = user_id
        alert.acknowledged_at = datetime.utcnow()
        
        await self.db.commit()
        await self.db.refresh(alert)
        return alert

    # 系统状态管理
    async def get_system_status(self) -> SystemStatus:
        """获取系统整体状态"""
        # 计算设备在线状态
        now = datetime.utcnow()
        threshold = now - timedelta(minutes=5)  # 5分钟内有数据视为在线
        
        online_devices = await self.db.execute(
            select(func.count(DeviceMetricsModel.device_id.distinct()))
            .filter(DeviceMetricsModel.timestamp >= threshold)
        )
        online_count = online_devices.scalar() or 0

        # 获取未确认的告警统计
        unacknowledged_alerts = await self.db.execute(
            select(MonitoringAlertModel)
            .filter(MonitoringAlertModel.status == "active")
        )
        alerts = unacknowledged_alerts.scalars().all()
        
        # 按严重程度统计告警
        alert_counts = {
            "critical": 0,
            "high": 0,
            "medium": 0,
            "low": 0
        }
        for alert in alerts:
            alert_counts[alert.severity] = alert_counts.get(alert.severity, 0) + 1

        # 获取最近的系统性能指标
        system_metrics = await self.db.execute(
            select(DeviceMetricsModel)
            .filter(DeviceMetricsModel.metric_type == "system")
            .order_by(desc(DeviceMetricsModel.timestamp))
            .limit(1)
        )
        latest_metrics = system_metrics.scalar_one_or_none()

        return SystemStatus(
            online_devices=online_count,
            total_active_alerts=len(alerts),
            alert_severity_distribution=alert_counts,
            system_metrics=latest_metrics.metrics if latest_metrics else None,
            last_update=latest_metrics.timestamp if latest_metrics else None
        )

    # 内部方法
    async def _check_alert_rules(self, metrics: DeviceMetricsModel) -> None:
        """检查指标是否触发告警规则"""
        rules = await self.get_alert_rules(
            device_id=metrics.device_id,
            enabled=True
        )

        for rule in rules:
            if self._evaluate_alert_condition(metrics, rule):
                await self._create_alert(metrics, rule)

    def _evaluate_alert_condition(
        self, metrics: DeviceMetricsModel,
        rule: AlertRuleModel
    ) -> bool:
        """评估告警条件"""
        try:
            metric_value = metrics.metrics.get(rule.metric_name)
            if metric_value is None:
                return False

            threshold = rule.threshold
            condition = rule.condition

            if condition == "gt":
                return metric_value > threshold
            elif condition == "gte":
                return metric_value >= threshold
            elif condition == "lt":
                return metric_value < threshold
            elif condition == "lte":
                return metric_value <= threshold
            elif condition == "eq":
                return metric_value == threshold
            elif condition == "neq":
                return metric_value != threshold
            else:
                return False
        except Exception:
            return False

    async def _create_alert(
        self, metrics: DeviceMetricsModel,
        rule: AlertRuleModel
    ) -> None:
        """创建告警"""
        alert = MonitoringAlertModel(
            device_id=metrics.device_id,
            rule_id=rule.id,
            severity=rule.severity,
            message=rule.message.format(
                value=metrics.metrics.get(rule.metric_name),
                threshold=rule.threshold
            ),
            metrics_id=metrics.id,
            status="active"
        )
        
        self.db.add(alert)
        await self.db.commit()