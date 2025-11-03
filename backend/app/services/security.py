from typing import Optional, List, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, or_, desc, func
from app.models.security import (
    SecurityEvent, AccessControlPolicy,
    SecurityAuditLog, BlacklistedIP
)
from app.schemas.security import (
    SecurityEventCreate, AccessControlPolicyCreate,
    AccessControlPolicyUpdate, SecurityAuditLogCreate,
    BlacklistedIPCreate
)
from datetime import datetime, timedelta

class SecurityService:
    def __init__(self, db: AsyncSession):
        self.db = db

    # 安全事件管理
    async def create_event(self, event_in: SecurityEventCreate) -> SecurityEvent:
        """创建安全事件"""
        event = SecurityEvent(**event_in.model_dump())
        self.db.add(event)
        await self.db.commit()
        await self.db.refresh(event)
        return event

    async def get_event(self, event_id: str) -> Optional[SecurityEvent]:
        """获取安全事件"""
        result = await self.db.execute(
            select(SecurityEvent).filter(SecurityEvent.id == event_id)
        )
        return result.scalar_one_or_none()

    async def get_events(
        self,
        skip: int = 0,
        limit: int = 100,
        severity: Optional[str] = None,
        handled: Optional[bool] = None
    ) -> List[SecurityEvent]:
        """获取安全事件列表"""
        query = select(SecurityEvent)
        if severity:
            query = query.filter(SecurityEvent.severity == severity)
        if handled is not None:
            query = query.filter(SecurityEvent.handled == handled)
        query = query.order_by(desc(SecurityEvent.created_at)).offset(skip).limit(limit)
        result = await self.db.execute(query)
        return result.scalars().all()

    async def handle_event(
        self, event: SecurityEvent, handler_id: str
    ) -> SecurityEvent:
        """处理安全事件"""
        event.handled = True
        event.handler_id = handler_id
        event.handled_at = datetime.utcnow()
        self.db.add(event)
        await self.db.commit()
        await self.db.refresh(event)
        return event

    # 访问控制策略管理
    async def create_policy(
        self, policy_in: AccessControlPolicyCreate
    ) -> AccessControlPolicy:
        """创建访问控制策略"""
        policy = AccessControlPolicy(**policy_in.model_dump())
        self.db.add(policy)
        await self.db.commit()
        await self.db.refresh(policy)
        return policy

    async def update_policy(
        self, policy: AccessControlPolicy,
        policy_in: AccessControlPolicyUpdate
    ) -> AccessControlPolicy:
        """更新访问控制策略"""
        update_data = policy_in.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(policy, field, value)
        self.db.add(policy)
        await self.db.commit()
        await self.db.refresh(policy)
        return policy

    async def get_policy(self, policy_id: str) -> Optional[AccessControlPolicy]:
        """获取访问控制策略"""
        result = await self.db.execute(
            select(AccessControlPolicy).filter(AccessControlPolicy.id == policy_id)
        )
        return result.scalar_one_or_none()

    async def get_device_policies(
        self, device_id: str
    ) -> List[AccessControlPolicy]:
        """获取设备的访问控制策略"""
        result = await self.db.execute(
            select(AccessControlPolicy)
            .filter(AccessControlPolicy.device_id == device_id)
            .order_by(AccessControlPolicy.priority.desc())
        )
        return result.scalars().all()

    async def delete_policy(self, policy: AccessControlPolicy) -> None:
        """删除访问控制策略"""
        await self.db.delete(policy)
        await self.db.commit()

    # 审计日志管理
    async def create_audit_log(
        self, log_in: SecurityAuditLogCreate
    ) -> SecurityAuditLog:
        """创建审计日志"""
        log = SecurityAuditLog(**log_in.model_dump())
        self.db.add(log)
        await self.db.commit()
        await self.db.refresh(log)
        return log

    async def get_audit_logs(
        self,
        skip: int = 0,
        limit: int = 100,
        log_type: Optional[str] = None,
        start_time: Optional[datetime] = None,
        end_time: Optional[datetime] = None
    ) -> List[SecurityAuditLog]:
        """获取审计日志"""
        query = select(SecurityAuditLog)
        if log_type:
            query = query.filter(SecurityAuditLog.log_type == log_type)
        if start_time:
            query = query.filter(SecurityAuditLog.created_at >= start_time)
        if end_time:
            query = query.filter(SecurityAuditLog.created_at <= end_time)
        query = query.order_by(desc(SecurityAuditLog.created_at)).offset(skip).limit(limit)
        result = await self.db.execute(query)
        return result.scalars().all()

    # IP黑名单管理
    async def add_to_blacklist(
        self, blacklist_in: BlacklistedIPCreate
    ) -> BlacklistedIP:
        """添加IP到黑名单"""
        blacklist = BlacklistedIP(**blacklist_in.model_dump())
        self.db.add(blacklist)
        await self.db.commit()
        await self.db.refresh(blacklist)
        return blacklist

    async def remove_from_blacklist(self, ip: str) -> None:
        """从黑名单中移除IP"""
        result = await self.db.execute(
            select(BlacklistedIP).filter(BlacklistedIP.ip_address == ip)
        )
        blacklist = result.scalar_one_or_none()
        if blacklist:
            await self.db.delete(blacklist)
            await self.db.commit()

    async def is_ip_blacklisted(self, ip: str) -> bool:
        """检查IP是否在黑名单中"""
        result = await self.db.execute(
            select(BlacklistedIP).filter(
                and_(
                    BlacklistedIP.ip_address == ip,
                    or_(
                        BlacklistedIP.expiry_at.is_(None),
                        BlacklistedIP.expiry_at > datetime.utcnow()
                    )
                )
            )
        )
        return result.scalar_one_or_none() is not None

    # 安全统计
    async def get_security_stats(self) -> Dict[str, Any]:
        """获取安全统计信息"""
        # 获取事件总数和未处理事件数
        total_events_query = await self.db.execute(select(SecurityEvent))
        total_events = total_events_query.scalars().all()
        total_count = len(total_events)
        unhandled_count = len([e for e in total_events if not e.handled])

        # 获取严重程度分布
        severity_dist = {}
        for severity in ["low", "medium", "high", "critical"]:
            count = await self.db.execute(
                select(SecurityEvent).filter(SecurityEvent.severity == severity)
            )
            severity_dist[severity] = len(count.scalars().all())

        # 获取24小时内的事件数量
        recent_events_query = await self.db.execute(
            select(SecurityEvent)
            .filter(SecurityEvent.created_at >= datetime.utcnow() - timedelta(days=1))
        )
        recent_events_count = len(recent_events_query.scalars().all())

        # 获取最近5个事件
        recent_events = await self.db.execute(
            select(SecurityEvent)
            .order_by(desc(SecurityEvent.created_at))
            .limit(5)
        )

        # 获取活跃黑名单数量和即将过期的黑名单数量
        active_blacklist = await self.db.execute(
            select(BlacklistedIP).filter(
                or_(
                    BlacklistedIP.expiry_at.is_(None),
                    BlacklistedIP.expiry_at > datetime.utcnow()
                )
            )
        )
        expiring_soon = await self.db.execute(
            select(BlacklistedIP).filter(
                and_(
                    BlacklistedIP.expiry_at.isnot(None),
                    BlacklistedIP.expiry_at <= datetime.utcnow() + timedelta(days=7),
                    BlacklistedIP.expiry_at > datetime.utcnow()
                )
            )
        )

        # 获取审计日志统计
        audit_logs_query = await self.db.execute(
            select(SecurityAuditLog)
            .filter(SecurityAuditLog.created_at >= datetime.utcnow() - timedelta(days=7))
        )
        audit_logs = audit_logs_query.scalars().all()
        audit_log_types = {}
        for log in audit_logs:
            audit_log_types[log.log_type] = audit_log_types.get(log.log_type, 0) + 1

        return {
            "total_events": total_count,
            "unhandled_events": unhandled_count,
            "severity_distribution": severity_dist,
            "recent_events": recent_events.scalars().all(),
            "recent_24h_events": recent_events_count,
            "active_blacklist_count": len(active_blacklist.scalars().all()),
            "expiring_blacklist_count": len(expiring_soon.scalars().all()),
            "audit_log_types_7d": audit_log_types
        }