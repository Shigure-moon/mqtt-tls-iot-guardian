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
from app.schemas.threat import (
    ThreatResponseRequest, ThreatResponse,
    DeviceIsolationRequest, CertificateRevocationRequest
)
from app.services.threat_response import ThreatResponseService
from app.core.config import settings
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
                        # 如果是SQLAlchemy模型，使用from_attributes直接转换
                        if hasattr(event, '__table__'):  # 检查是否是SQLAlchemy模型
                            # 使用Pydantic的model_validate，它会自动使用from_attributes=True
                            # 处理source_ip（INET类型）可能需要特殊处理
                            try:
                                recent_events.append(SecurityEvent.model_validate(event, from_attributes=True))
                            except Exception as validate_error:
                                # 如果自动转换失败，尝试手动处理source_ip
                                logger.debug(f"Auto validation failed, trying manual conversion: {validate_error}")
                                event_dict = {
                                    'id': event.id,
                                    'event_type': event.event_type,
                                    'severity': event.severity,
                                    'source_ip': str(event.source_ip) if event.source_ip else None,
                                    'device_id': event.device_id,
                                    'description': event.description,
                                    'raw_data': event.raw_data or {},
                                    'handled': event.handled,
                                    'handler_id': event.handler_id,
                                    'handled_at': event.handled_at,
                                    'created_at': event.created_at
                                }
                                recent_events.append(SecurityEvent(**event_dict))
                        else:
                            # 如果已经是字典或其他格式，直接使用
                            recent_events.append(event)
                    except Exception as conv_error:
                        logger.warning(f"Error converting security event: {conv_error}, event: {event}", exc_info=True)
                        continue
            except Exception as import_error:
                logger.error(f"Error importing SecurityEvent schema: {import_error}", exc_info=True)
        
        # 计算top_threats（最常见的威胁类型）
        top_threats = []
        try:
            from sqlalchemy import func, select
            from app.models.security import SecurityEvent
            
            # 获取最常见的威胁类型（按event_type分组）
            threat_query = await db.execute(
                select(
                    SecurityEvent.event_type,
                    func.count(SecurityEvent.id).label('count')
                )
                .group_by(SecurityEvent.event_type)
                .order_by(func.count(SecurityEvent.id).desc())
                .limit(5)
            )
            threat_results = threat_query.all()
            
            for row in threat_results:
                # Row对象可以通过属性名访问（使用label的名称）
                try:
                    event_type = row.event_type
                    count = row.count
                except AttributeError:
                    # 如果属性访问失败，尝试索引访问
                    event_type = row[0]
                    count = row[1]
                top_threats.append({
                    'event_type': str(event_type) if event_type else 'unknown',
                    'count': int(count) if count is not None else 0
                })
        except Exception as e:
            logger.warning(f"Error calculating top threats: {e}", exc_info=True)
            top_threats = []
        
        # 构造符合SecurityStats schema的响应
        return SecurityStats(
            total_events=stats.get("total_events", 0),
            severity_distribution=stats.get("severity_distribution", {}),
            recent_events=recent_events,
            top_threats=top_threats,
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

# 威胁响应相关API
@router.post("/threats/respond", response_model=ThreatResponse)
async def respond_to_threat(
    threat_data: ThreatResponseRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
) -> ThreatResponse:
    """响应威胁事件（由LLM-IDS-Agent或CyberSentinal调用）"""
    try:
        threat_service = ThreatResponseService(db)
        event = await threat_service.handle_threat_event(
            source=threat_data.source,
            threat_data=threat_data
        )
        
        actions_taken = event.raw_data.get("actions_taken", []) if event.raw_data else []
        
        return ThreatResponse(
            success=True,
            message="威胁事件已处理",
            event_id=event.id,
            actions_taken=actions_taken
        )
    except Exception as e:
        logger.error(f"处理威胁事件失败: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"处理威胁事件失败: {str(e)}"
        )

@router.post("/threats/isolate-device")
async def isolate_device(
    request: DeviceIsolationRequest,
    db: AsyncSession = Depends(get_db)
):
    """隔离设备（内部API，需要API密钥认证）"""
    try:
        threat_service = ThreatResponseService(db)
        success = await threat_service.isolate_device(
            device_id=request.device_id,
            reason=request.reason,
            duration_minutes=request.duration_minutes
        )
        
        if success:
            return {"success": True, "message": f"设备 {request.device_id} 已隔离"}
        else:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="设备不存在"
            )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"隔离设备失败: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"隔离设备失败: {str(e)}"
        )

@router.post("/threats/revoke-certificate")
async def revoke_device_certificate(
    request: CertificateRevocationRequest,
    db: AsyncSession = Depends(get_db)
):
    """吊销设备证书（内部API）"""
    try:
        threat_service = ThreatResponseService(db)
        success = await threat_service.revoke_certificate(
            device_id=request.device_id,
            reason=request.reason
        )
        
        if success:
            return {"success": True, "message": f"设备 {request.device_id} 的证书已吊销"}
        else:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="设备不存在或没有有效证书"
            )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"吊销证书失败: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"吊销证书失败: {str(e)}"
        )