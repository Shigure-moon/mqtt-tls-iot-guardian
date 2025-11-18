from typing import Optional, List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, and_
from datetime import datetime, timedelta
import logging

from app.models.security import SecurityEvent, BlacklistedIP
from app.models.device import Device, DeviceCertificate
from app.schemas.security import SecurityEventCreate
from app.schemas.threat import ThreatResponseRequest, ThreatResponse
from app.services.security import SecurityService
from app.services.device import DeviceService

logger = logging.getLogger(__name__)

class ThreatResponseService:
    """威胁响应服务"""
    
    def __init__(self, db: AsyncSession):
        self.db = db
        self.security_service = SecurityService(db)
        self.device_service = DeviceService(db)
    
    async def handle_threat_event(
        self,
        source: str,  # "llm_ids_agent" 或 "cybersentinal"
        threat_data: ThreatResponseRequest
    ) -> SecurityEvent:
        """处理威胁事件"""
        try:
            # 1. 创建安全事件记录
            raw_data_dict = {
                "source": source,
                "threat_score": threat_data.threat_score,
            }
            if threat_data.raw_data:
                raw_data_dict.update(threat_data.raw_data)
            
            event_data = {
                "event_type": threat_data.threat_type,
                "severity": threat_data.severity,
                "source_ip": threat_data.source_ip,
                "device_id": threat_data.device_id,
                "description": f"[{source.upper()}] {threat_data.description}",
                "raw_data": raw_data_dict
            }
            
            # 创建安全事件
            event_create = SecurityEventCreate(**event_data)
            event = await self.security_service.create_event(event_create)
            
            # 设置threat_source字段（如果模型支持）
            if hasattr(event, 'threat_source'):
                event.threat_source = source
                await self.db.commit()
                await self.db.refresh(event)
            
            logger.info(f"创建安全事件: {event.id}, 来源: {source}, 类型: {threat_data.threat_type}")
            
            # 2. 根据威胁等级执行响应动作
            actions_taken = []
            
            if threat_data.severity in ["high", "critical"]:
                # 高严重性威胁：自动隔离设备
                if threat_data.device_id:
                    try:
                        await self.isolate_device(threat_data.device_id, f"自动隔离: {threat_data.description}")
                        actions_taken.append("device_isolation")
                    except Exception as e:
                        logger.error(f"隔离设备失败: {e}")
                
                # 添加到IP黑名单
                if threat_data.source_ip:
                    try:
                        await self.add_ip_to_blacklist(threat_data.source_ip, f"威胁来源: {threat_data.description}")
                        actions_taken.append("ip_blacklist")
                    except Exception as e:
                        logger.error(f"添加IP到黑名单失败: {e}")
            
            elif threat_data.severity == "medium":
                # 中等严重性：记录事件，可能需要人工审核
                actions_taken.append("event_logged")
            
            # 3. 更新事件记录响应动作
            if actions_taken:
                event.raw_data = event.raw_data or {}
                event.raw_data["actions_taken"] = actions_taken
                await self.db.commit()
                await self.db.refresh(event)
            
            return event
            
        except Exception as e:
            logger.error(f"处理威胁事件失败: {e}", exc_info=True)
            raise
    
    async def isolate_device(self, device_id: str, reason: str, duration_minutes: Optional[int] = None) -> bool:
        """隔离设备"""
        try:
            # 查找设备（支持UUID或device_id字符串）
            device = None
            try:
                from uuid import UUID
                uuid_obj = UUID(device_id)
                device = await self.device_service.get_by_id(str(uuid_obj))
            except ValueError:
                # 如果不是UUID，尝试作为device_id查找
                device = await self.device_service.get_by_device_id(device_id)
            
            if not device:
                logger.warning(f"设备不存在: {device_id}")
                return False
            
            # 更新设备状态为isolated
            device.status = "isolated"
            device.updated_at = datetime.utcnow()
            
            # 添加到黑名单（如果设备有IP地址）
            if hasattr(device, 'ip_address') and device.ip_address:
                await self.add_ip_to_blacklist(str(device.ip_address), f"设备隔离: {reason}")
            
            await self.db.commit()
            await self.db.refresh(device)
            
            logger.info(f"设备已隔离: {device_id}, 原因: {reason}")
            return True
            
        except Exception as e:
            logger.error(f"隔离设备失败: {e}", exc_info=True)
            await self.db.rollback()
            raise
    
    async def revoke_certificate(self, device_id: str, reason: str) -> bool:
        """吊销设备证书"""
        try:
            # 查找设备
            device = None
            try:
                from uuid import UUID
                uuid_obj = UUID(device_id)
                device = await self.device_service.get_by_id(str(uuid_obj))
            except ValueError:
                device = await self.device_service.get_by_device_id(device_id)
            
            if not device:
                logger.warning(f"设备不存在: {device_id}")
                return False
            
            # 查找设备的所有有效证书
            result = await self.db.execute(
                select(DeviceCertificate)
                .filter(
                    and_(
                        DeviceCertificate.device_id == device.id,
                        DeviceCertificate.revoked_at.is_(None)
                    )
                )
            )
            certificates = result.scalars().all()
            
            if not certificates:
                logger.warning(f"设备没有有效证书: {device_id}")
                return False
            
            # 吊销所有有效证书
            revoked_count = 0
            for cert in certificates:
                cert.revoked_at = datetime.utcnow()
                cert.revoke_reason = reason
                revoked_count += 1
            
            # 更新设备状态
            device.status = "certificate_revoked"
            device.updated_at = datetime.utcnow()
            
            await self.db.commit()
            
            logger.info(f"已吊销设备证书: {device_id}, 证书数量: {revoked_count}, 原因: {reason}")
            return True
            
        except Exception as e:
            logger.error(f"吊销证书失败: {e}", exc_info=True)
            await self.db.rollback()
            raise
    
    async def add_ip_to_blacklist(self, ip_address: str, reason: str, expiry_minutes: Optional[int] = None) -> bool:
        """添加IP到黑名单"""
        try:
            from app.schemas.security import BlacklistedIPCreate
            
            # 检查是否已在黑名单中
            is_blacklisted = await self.security_service.is_ip_blacklisted(ip_address)
            if is_blacklisted:
                logger.info(f"IP已在黑名单中: {ip_address}")
                return True
            
            # 计算过期时间
            expiry_at = None
            if expiry_minutes:
                expiry_at = datetime.utcnow() + timedelta(minutes=expiry_minutes)
            
            blacklist_create = BlacklistedIPCreate(
                ip_address=ip_address,
                reason=reason,
                expiry_at=expiry_at
            )
            
            await self.security_service.add_to_blacklist(blacklist_create)
            logger.info(f"IP已添加到黑名单: {ip_address}, 原因: {reason}")
            return True
            
        except Exception as e:
            logger.error(f"添加IP到黑名单失败: {e}", exc_info=True)
            raise

