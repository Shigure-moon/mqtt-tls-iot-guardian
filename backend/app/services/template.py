"""
设备模板服务
"""
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from datetime import datetime
from app.models.template import DeviceTemplate
from app.schemas.template import DeviceTemplateCreate, DeviceTemplateUpdate
from app.core.encryption import encrypt_certificate_data, decrypt_certificate_data


class TemplateService:
    """设备模板服务"""
    
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def create(self, template_in: DeviceTemplateCreate, created_by: Optional[str] = None) -> DeviceTemplate:
        """创建模板（加密存储代码）"""
        # 加密模板代码
        encrypted_code = encrypt_certificate_data(template_in.template_code)
        
        template = DeviceTemplate(
            name=template_in.name,
            version=template_in.version,
            device_type=template_in.device_type,
            description=template_in.description,
            template_code=encrypted_code,
            required_libraries=template_in.required_libraries,
            is_active=template_in.is_active,
            created_by=created_by
        )
        self.db.add(template)
        await self.db.commit()
        await self.db.refresh(template)
        return template
    
    async def get_by_id(self, template_id: str) -> Optional[DeviceTemplate]:
        """根据ID获取模板"""
        result = await self.db.execute(
            select(DeviceTemplate).filter(DeviceTemplate.id == template_id)
        )
        return result.scalar_one_or_none()
    
    async def get_by_name(self, name: str) -> Optional[DeviceTemplate]:
        """根据名称获取模板"""
        result = await self.db.execute(
            select(DeviceTemplate).filter(DeviceTemplate.name == name)
        )
        return result.scalar_one_or_none()
    
    async def get_by_device_type(self, device_type: str) -> List[DeviceTemplate]:
        """根据设备类型获取模板列表"""
        try:
            result = await self.db.execute(
                select(DeviceTemplate)
                .filter(DeviceTemplate.device_type == device_type)
                .filter(DeviceTemplate.is_active == True)
                .order_by(DeviceTemplate.created_at.desc())
            )
            return result.scalars().all()
        except Exception as e:
            import logging
            logger = logging.getLogger(__name__)
            logger.error(f"Error getting templates by device type: {e}", exc_info=True)
            # 如果表不存在，返回空列表而不是抛出异常
            if "does not exist" in str(e) or "relation" in str(e).lower():
                logger.warning("Device templates table does not exist yet, returning empty list")
                return []
            raise
    
    async def get_all(self, skip: int = 0, limit: int = 100) -> List[DeviceTemplate]:
        """获取所有模板"""
        try:
            result = await self.db.execute(
                select(DeviceTemplate)
                .order_by(DeviceTemplate.created_at.desc())
                .offset(skip)
                .limit(limit)
            )
            return result.scalars().all()
        except Exception as e:
            import logging
            logger = logging.getLogger(__name__)
            logger.error(f"Error getting templates: {e}", exc_info=True)
            # 如果表不存在，返回空列表而不是抛出异常
            if "does not exist" in str(e) or "relation" in str(e).lower():
                logger.warning("Device templates table does not exist yet, returning empty list")
                return []
            raise
    
    async def update(self, template: DeviceTemplate, template_in: DeviceTemplateUpdate) -> DeviceTemplate:
        """更新模板"""
        update_data = template_in.model_dump(exclude_unset=True)
        
        # 如果更新了模板代码，需要加密
        if 'template_code' in update_data and update_data['template_code']:
            update_data['template_code'] = encrypt_certificate_data(update_data['template_code'])
        
        for field, value in update_data.items():
            setattr(template, field, value)
        
        template.updated_at = datetime.utcnow()
        self.db.add(template)
        await self.db.commit()
        await self.db.refresh(template)
        return template
    
    async def delete(self, template: DeviceTemplate) -> None:
        """删除模板"""
        await self.db.delete(template)
        await self.db.commit()
    
    def decrypt_template_code(self, template: DeviceTemplate) -> str:
        """解密模板代码"""
        try:
            return decrypt_certificate_data(template.template_code)
        except Exception as e:
            import logging
            logger = logging.getLogger(__name__)
            logger.error(f"Error decrypting template code: {e}", exc_info=True)
            # 如果解密失败，可能是未加密的旧数据，直接返回
            return template.template_code

