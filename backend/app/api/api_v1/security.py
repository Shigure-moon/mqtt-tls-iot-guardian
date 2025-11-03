from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import datetime
from app.api.api_v1.auth import get_current_active_user
from app.core.database import get_db
from app.schemas.security import (
    SecurityEvent, SecurityEventCreate,
    AccessControlPolicy, AccessControlPolicyCreate, AccessControlPolicyUpdate,
    SecurityAuditLog, SecurityAuditLogCreate,
    BlacklistedIP, BlacklistedIPCreate,
    SecurityStats
)
from app.services.security import SecurityService
from app.schemas.user import User

router = APIRouter()

# 安全事件管理
@router.post("/events", response_model=SecurityEvent)
async def create_security_event(
    event_in: SecurityEventCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
) -> SecurityEvent:
    """创建安全事件"""
    security_service = SecurityService(db)
    event = await security_service.create_event(event_in)
    return event

@router.get("/events", response_model=List[SecurityEvent])
async def get_security_events(
    skip: int = 0,
    limit: int = 100,
    severity: Optional[str] = None,
    handled: Optional[bool] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
) -> List[SecurityEvent]:
    """获取安全事件列表"""
    security_service = SecurityService(db)
    events = await security_service.get_events(
        skip=skip, limit=limit,
        severity=severity, handled=handled
    )
    return events

@router.post("/events/{event_id}/handle")
async def handle_security_event(
    event_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """处理安全事件"""
    security_service = SecurityService(db)
    event = await security_service.get_event(event_id)
    if not event:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="事件不存在"
        )
    
    await security_service.handle_event(event, str(current_user.id))
    return {"message": "事件已处理"}

# 访问控制策略管理
@router.post("/policies", response_model=AccessControlPolicy)
async def create_access_policy(
    policy_in: AccessControlPolicyCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
) -> AccessControlPolicy:
    """创建访问控制策略"""
    security_service = SecurityService(db)
    policy = await security_service.create_policy(policy_in)
    return policy

@router.get("/policies", response_model=List[AccessControlPolicy])
async def get_device_policies(
    device_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
) -> List[AccessControlPolicy]:
    """获取设备的访问控制策略"""
    security_service = SecurityService(db)
    policies = await security_service.get_device_policies(device_id)
    return policies

@router.put("/policies/{policy_id}", response_model=AccessControlPolicy)
async def update_access_policy(
    policy_id: str,
    policy_in: AccessControlPolicyUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
) -> AccessControlPolicy:
    """更新访问控制策略"""
    security_service = SecurityService(db)
    policy = await security_service.get_policy(policy_id)
    if not policy:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="策略不存在"
        )
    
    policy = await security_service.update_policy(policy, policy_in)
    return policy

@router.delete("/policies/{policy_id}")
async def delete_access_policy(
    policy_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """删除访问控制策略"""
    security_service = SecurityService(db)
    policy = await security_service.get_policy(policy_id)
    if not policy:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="策略不存在"
        )
    
    await security_service.delete_policy(policy)
    return {"message": "策略已删除"}

# 审计日志管理
@router.post("/audit-logs", response_model=SecurityAuditLog)
async def create_audit_log(
    log_in: SecurityAuditLogCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
) -> SecurityAuditLog:
    """创建审计日志"""
    security_service = SecurityService(db)
    log = await security_service.create_audit_log(log_in)
    return log

@router.get("/audit-logs", response_model=List[SecurityAuditLog])
async def get_audit_logs(
    skip: int = 0,
    limit: int = 100,
    log_type: Optional[str] = None,
    start_time: Optional[datetime] = None,
    end_time: Optional[datetime] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
) -> List[SecurityAuditLog]:
    """获取审计日志"""
    import logging
    logger = logging.getLogger(__name__)
    
    try:
        security_service = SecurityService(db)
        logs = await security_service.get_audit_logs(
            skip=skip, limit=limit,
            log_type=log_type,
            start_time=start_time,
            end_time=end_time
        )
        
        # 将SQLAlchemy模型转换为Pydantic schema
        result = []
        for log in logs:
            try:
                if hasattr(log, '__table__'):  # 检查是否是SQLAlchemy模型
                    # 使用model_validate或手动转换
                    try:
                        result.append(SecurityAuditLog.model_validate(log))
                    except Exception:
                        # 如果自动转换失败，手动构建
                        log_dict = {
                            'id': log.id,
                            'log_type': log.log_type,
                            'action': log.action,
                            'status': log.status if hasattr(log, 'status') else 'success',
                            'target_type': log.target_type,
                            'target_id': log.target_id,
                            'details': log.details,
                            'ip_address': str(log.ip_address) if log.ip_address else None,
                            'user_agent': log.user_agent,
                            'created_at': log.created_at
                        }
                        # 添加actor相关字段
                        if hasattr(log, 'actor_id'):
                            log_dict['actor_id'] = log.actor_id
                        if hasattr(log, 'actor_type'):
                            log_dict['actor_type'] = log.actor_type
                        
                        result.append(SecurityAuditLog(**log_dict))
                else:
                    result.append(log)
            except Exception as e:
                logger.warning(f"Error converting audit log: {e}, log: {log}")
                continue
        
        return result
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting audit logs: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"获取审计日志失败: {str(e)}"
        )

# IP黑名单管理
@router.post("/blacklist", response_model=BlacklistedIP)
async def add_to_blacklist(
    blacklist_in: BlacklistedIPCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
) -> BlacklistedIP:
    """添加IP到黑名单"""
    security_service = SecurityService(db)
    blacklist = await security_service.add_to_blacklist(blacklist_in)
    return blacklist

@router.delete("/blacklist/{ip}")
async def remove_from_blacklist(
    ip: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """从黑名单中移除IP"""
    security_service = SecurityService(db)
    await security_service.remove_from_blacklist(ip)
    return {"message": "IP已从黑名单中移除"}

@router.get("/blacklist/check/{ip}")
async def check_ip_blacklist(
    ip: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """检查IP是否在黑名单中"""
    security_service = SecurityService(db)
    is_blacklisted = await security_service.is_ip_blacklisted(ip)
    return {"ip": ip, "is_blacklisted": is_blacklisted}

# 安全统计
@router.get("/stats", response_model=SecurityStats)
async def get_security_stats(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
) -> SecurityStats:
    """获取安全统计信息"""
    import logging
    logger = logging.getLogger(__name__)
    
    try:
        security_service = SecurityService(db)
        stats = await security_service.get_security_stats()
        
        # 将SQLAlchemy模型转换为Pydantic schema
        recent_events = []
        events_list = stats.get("recent_events", [])
        
        if events_list:
            try:
                from app.schemas.security import SecurityEvent
                for event in events_list:
                    try:
                        # 如果是SQLAlchemy模型，转换为schema
                        if hasattr(event, '__table__'):  # 检查是否是SQLAlchemy模型
                            # 处理source_ip可能为None的情况
                            event_dict = {
                                'id': event.id,
                                'event_type': event.event_type,
                                'severity': event.severity,
                                'source_ip': str(event.source_ip) if event.source_ip else None,
                                'device_id': event.device_id,
                                'description': event.description,
                                'raw_data': event.raw_data,
                                'handled': event.handled,
                                'handler_id': event.handler_id,
                                'handled_at': event.handled_at,
                                'created_at': event.created_at
                            }
                            recent_events.append(SecurityEvent(**event_dict))
                        else:
                            recent_events.append(event)
                    except Exception as conv_error:
                        logger.warning(f"Error converting security event: {conv_error}, event: {event}")
                        continue
            except Exception as import_error:
                logger.error(f"Error importing SecurityEvent schema: {import_error}")
        
        # 构造符合SecurityStats schema的响应
        return SecurityStats(
            total_events=stats.get("total_events", 0),
            severity_distribution=stats.get("severity_distribution", {}),
            recent_events=recent_events,
            top_threats=[],  # TODO: 实现top_threats逻辑
            active_blacklist_count=stats.get("active_blacklist_count", 0)
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting security stats: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"获取安全统计信息失败: {str(e)}"
        )