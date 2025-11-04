"""
OTA更新服务
处理OTA推送和状态跟踪
"""
import json
import logging
from datetime import datetime
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from uuid import UUID

from app.models.firmware_encryption import OTAUpdateTask, FirmwareBuild
from app.core.events import mqtt
from app.core.config import settings

logger = logging.getLogger(__name__)


class OTAUpdateService:
    """OTA更新服务"""
    
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def create_update_task(
        self,
        device_id: UUID,
        firmware_build_id: Optional[UUID] = None,
        firmware_url: Optional[str] = None,
        firmware_version: Optional[str] = None,
        user_id: Optional[UUID] = None
    ) -> OTAUpdateTask:
        """
        创建OTA更新任务
        
        Args:
            device_id: 设备ID
            firmware_build_id: 固件构建ID（如果提供）
            firmware_url: 固件URL（如果未提供build_id）
            firmware_version: 固件版本号
            user_id: 创建者ID
            
        Returns:
            OTA更新任务
        """
        # 如果提供了build_id，从构建记录获取URL和哈希
        firmware_hash = None
        if firmware_build_id:
            result = await self.db.execute(
                select(FirmwareBuild).where(FirmwareBuild.id == firmware_build_id)
            )
            build = result.scalar_one_or_none()
            if build:
                firmware_url = firmware_url or f"/api/v1/firmware/download/{device_id}"
                firmware_hash = build.encrypted_firmware_hash or build.firmware_hash
        
        if not firmware_url:
            raise ValueError("必须提供firmware_url或firmware_build_id")
        
        # 创建更新任务
        task = OTAUpdateTask(
            device_id=device_id,
            firmware_build_id=firmware_build_id,
            firmware_url=firmware_url,
            firmware_version=firmware_version,
            firmware_hash=firmware_hash,
            status="pending",
            progress="0%",
            created_by=user_id
        )
        
        self.db.add(task)
        await self.db.commit()
        await self.db.refresh(task)
        
        return task
    
    async def push_update_to_device(
        self,
        task_id: UUID,
        device_id: str
    ) -> bool:
        """
        通过MQTT推送OTA更新指令到设备
        
        Args:
            task_id: 更新任务ID
            device_id: 设备ID
            
        Returns:
            是否成功推送
        """
        if not mqtt or not mqtt.is_connected():
            logger.error("MQTT客户端未连接，无法推送OTA更新")
            return False
        
        # 获取任务信息
        result = await self.db.execute(
            select(OTAUpdateTask).where(OTAUpdateTask.id == task_id)
        )
        task = result.scalar_one_or_none()
        
        if not task:
            logger.error(f"OTA更新任务 {task_id} 不存在")
            return False
        
        # 构建OTA更新消息
        # 获取服务器地址（从URL中提取或使用配置）
        firmware_url = task.firmware_url
        if not firmware_url.startswith('http'):
            # 如果是相对路径，构建完整URL
            api_host = getattr(settings, 'API_HOST', 'localhost')
            api_port = getattr(settings, 'API_PORT', 8000)
            protocol = "https" if getattr(settings, 'USE_HTTPS', False) else "http"
            port_part = f":{api_port}" if ((protocol == "https" and api_port != 443) or (protocol == "http" and api_port != 80)) else ""
            base_url = f"{protocol}://{api_host}{port_part}"
            firmware_url = f"{base_url}{task.firmware_url}"
        
        update_message = {
            "type": "ota_update",
            "firmware_url": firmware_url,
            "firmware_version": task.firmware_version,
            "firmware_hash": task.firmware_hash,
            "task_id": str(task_id),
            "timestamp": datetime.utcnow().isoformat()
        }
        
        # 发布到设备的控制主题
        topic = f"devices/{device_id}/control"
        payload = json.dumps(update_message)
        
        try:
            result = mqtt.publish(topic, payload, qos=1)
            if result.rc == 0:
                # 更新任务状态
                task.status = "sent"
                task.started_at = datetime.utcnow()
                task.progress = "0%"
                await self.db.commit()
                logger.info(f"OTA更新指令已推送到设备 {device_id}，主题: {topic}")
                return True
            else:
                logger.error(f"MQTT发布失败，返回码: {result.rc}")
                task.status = "failed"
                task.error_message = f"MQTT发布失败: {result.rc}"
                await self.db.commit()
                return False
        except Exception as e:
            logger.error(f"推送OTA更新失败: {e}", exc_info=True)
            task.status = "failed"
            task.error_message = str(e)
            await self.db.commit()
            return False
    
    async def update_task_status(
        self,
        task_id: UUID,
        status: str,
        progress: Optional[str] = None,
        error_message: Optional[str] = None
    ) -> bool:
        """
        更新OTA任务状态（通常由设备上报）
        
        Args:
            task_id: 任务ID
            status: 新状态
            progress: 进度（可选）
            error_message: 错误信息（可选）
            
        Returns:
            是否成功更新
        """
        result = await self.db.execute(
            select(OTAUpdateTask).where(OTAUpdateTask.id == task_id)
        )
        task = result.scalar_one_or_none()
        
        if not task:
            logger.warning(f"OTA更新任务 {task_id} 不存在")
            return False
        
        task.status = status
        if progress:
            task.progress = progress
        if error_message:
            task.error_message = error_message
        
        if status == "completed":
            task.completed_at = datetime.utcnow()
        elif status in ["sent", "downloading", "installing"] and not task.started_at:
            task.started_at = datetime.utcnow()
        
        await self.db.commit()
        logger.info(f"OTA更新任务 {task_id} 状态已更新: {status}")
        return True
    
    async def get_task_by_id(self, task_id: UUID) -> Optional[OTAUpdateTask]:
        """获取任务信息"""
        result = await self.db.execute(
            select(OTAUpdateTask).where(OTAUpdateTask.id == task_id)
        )
        return result.scalar_one_or_none()
    
    async def get_latest_task(self, device_id: UUID) -> Optional[OTAUpdateTask]:
        """获取设备最新的OTA更新任务"""
        result = await self.db.execute(
            select(OTAUpdateTask)
            .where(OTAUpdateTask.device_id == device_id)
            .order_by(OTAUpdateTask.created_at.desc())
            .limit(1)
        )
        return result.scalar_one_or_none()
    
    async def get_device_tasks(self, device_id: UUID, limit: int = 10) -> list[OTAUpdateTask]:
        """获取设备的所有OTA更新任务"""
        result = await self.db.execute(
            select(OTAUpdateTask)
            .where(OTAUpdateTask.device_id == device_id)
            .order_by(OTAUpdateTask.created_at.desc())
            .limit(limit)
        )
        return list(result.scalars().all())

