"""
模板管理API
只有超级管理员可以访问
"""
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from sqlalchemy.ext.asyncio import AsyncSession
from app.api.api_v1.auth import get_current_super_admin_user, get_current_active_user
from app.core.database import get_db
from app.schemas.template import (
    DeviceTemplate,
    DeviceTemplateCreate,
    DeviceTemplateUpdate
)
from app.schemas.user import User
from app.services.template import TemplateService

router = APIRouter()


@router.post("", response_model=DeviceTemplate)
async def create_template(
    template_in: DeviceTemplateCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_super_admin_user)
) -> DeviceTemplate:
    """创建模板（超级管理员）"""
    template_service = TemplateService(db)
    
    # 检查模板名称是否已存在
    existing = await template_service.get_by_name(template_in.name)
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="模板名称已存在"
        )
    
    template = await template_service.create(
        template_in,
        created_by=current_user.id
    )
    
    # 解密模板代码返回（前端需要看到原始代码）
    decrypted_code = template_service.decrypt_template_code(template)
    template_dict = {
        'id': template.id,
        'name': template.name,
        'device_type': template.device_type,
        'description': template.description,
        'template_code': decrypted_code,
        'is_active': template.is_active,
        'created_at': template.created_at,
        'updated_at': template.updated_at,
        'created_by': template.created_by
    }
    return DeviceTemplate(**template_dict)


@router.post("/upload", response_model=DeviceTemplate)
async def upload_template(
    name: str,
    device_type: str,
    description: Optional[str] = None,
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_super_admin_user)
) -> DeviceTemplate:
    """上传模板文件（超级管理员）"""
    # 读取文件内容
    content = await file.read()
    template_code = content.decode('utf-8')
    
    template_in = DeviceTemplateCreate(
        name=name,
        device_type=device_type,
        description=description,
        template_code=template_code,
        is_active=True
    )
    
    template_service = TemplateService(db)
    
    # 检查模板名称是否已存在
    existing = await template_service.get_by_name(name)
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="模板名称已存在"
        )
    
    template = await template_service.create(
        template_in,
        created_by=current_user.id
    )
    
    # 解密模板代码返回
    decrypted_code = template_service.decrypt_template_code(template)
    template_dict = {
        'id': template.id,
        'name': template.name,
        'device_type': template.device_type,
        'description': template.description,
        'template_code': decrypted_code,
        'is_active': template.is_active,
        'created_at': template.created_at,
        'updated_at': template.updated_at,
        'created_by': template.created_by
    }
    return DeviceTemplate(**template_dict)


@router.get("", response_model=List[DeviceTemplate])
async def get_templates(
    skip: int = 0,
    limit: int = 100,
    device_type: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_super_admin_user)
) -> List[DeviceTemplate]:
    """获取模板列表（超级管理员）"""
    template_service = TemplateService(db)
    
    if device_type:
        templates = await template_service.get_by_device_type(device_type)
    else:
        templates = await template_service.get_all(skip=skip, limit=limit)
    
    # 解密所有模板代码
    result = []
    try:
        for template in templates:
            try:
                decrypted_code = template_service.decrypt_template_code(template)
                template_dict = {
                    'id': template.id,
                    'name': template.name,
                    'device_type': template.device_type,
                    'description': template.description,
                    'template_code': decrypted_code,
                    'is_active': template.is_active,
                    'created_at': template.created_at,
                    'updated_at': template.updated_at,
                    'created_by': template.created_by
                }
                result.append(DeviceTemplate(**template_dict))
            except Exception as e:
                import logging
                logger = logging.getLogger(__name__)
                logger.error(f"Error decrypting template {template.id}: {e}", exc_info=True)
                # 如果解密失败，仍然返回模板但使用空代码
                template_dict = {
                    'id': template.id,
                    'name': template.name,
                    'device_type': template.device_type,
                    'description': template.description,
                    'template_code': '',  # 解密失败时使用空字符串
                    'is_active': template.is_active,
                    'created_at': template.created_at,
                    'updated_at': template.updated_at,
                    'created_by': template.created_by
                }
                result.append(DeviceTemplate(**template_dict))
    except Exception as e:
        import logging
        logger = logging.getLogger(__name__)
        logger.error(f"Error processing templates: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"获取模板列表失败: {str(e)}"
        )
    
    return result


@router.get("/{template_id}", response_model=DeviceTemplate)
async def get_template(
    template_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_super_admin_user)
) -> DeviceTemplate:
    """获取模板详情（超级管理员）"""
    template_service = TemplateService(db)
    template = await template_service.get_by_id(template_id)
    
    if not template:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="模板不存在"
        )
    
    # 解密模板代码
    decrypted_code = template_service.decrypt_template_code(template)
    template_dict = {
        'id': template.id,
        'name': template.name,
        'device_type': template.device_type,
        'description': template.description,
        'template_code': decrypted_code,
        'is_active': template.is_active,
        'created_at': template.created_at,
        'updated_at': template.updated_at,
        'created_by': template.created_by
    }
    return DeviceTemplate(**template_dict)


@router.put("/{template_id}", response_model=DeviceTemplate)
async def update_template(
    template_id: str,
    template_in: DeviceTemplateUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_super_admin_user)
) -> DeviceTemplate:
    """更新模板（超级管理员）"""
    template_service = TemplateService(db)
    template = await template_service.get_by_id(template_id)
    
    if not template:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="模板不存在"
        )
    
    # 如果更新了名称，检查是否冲突
    if template_in.name and template_in.name != template.name:
        existing = await template_service.get_by_name(template_in.name)
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="模板名称已存在"
            )
    
    updated_template = await template_service.update(template, template_in)
    
    # 解密模板代码返回
    decrypted_code = template_service.decrypt_template_code(updated_template)
    template_dict = {
        'id': updated_template.id,
        'name': updated_template.name,
        'device_type': updated_template.device_type,
        'description': updated_template.description,
        'template_code': decrypted_code,
        'is_active': updated_template.is_active,
        'created_at': updated_template.created_at,
        'updated_at': updated_template.updated_at,
        'created_by': updated_template.created_by
    }
    return DeviceTemplate(**template_dict)


@router.delete("/{template_id}")
async def delete_template(
    template_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_super_admin_user)
):
    """删除模板（超级管理员）"""
    template_service = TemplateService(db)
    template = await template_service.get_by_id(template_id)
    
    if not template:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="模板不存在"
        )
    
    await template_service.delete(template)
    return {"message": "模板已删除"}


@router.get("/device-types/{device_type}/list", response_model=List[DeviceTemplate])
async def get_templates_by_device_type(
    device_type: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_super_admin_user)
) -> List[DeviceTemplate]:
    """根据设备类型获取可用模板列表（超级管理员）"""
    template_service = TemplateService(db)
    templates = await template_service.get_by_device_type(device_type)
    
    # 只返回基本信息，不返回模板代码（保护知识产权）
    result = []
    for template in templates:
        template_dict = {
            'id': template.id,
            'name': template.name,
            'device_type': template.device_type,
            'description': template.description,
            'template_code': '',  # 不返回代码内容
            'is_active': template.is_active,
            'created_at': template.created_at,
            'updated_at': template.updated_at,
            'created_by': template.created_by
        }
        result.append(DeviceTemplate(**template_dict))
    
    return result


@router.get("/public/device-types/{device_type}/list")
async def get_public_templates_by_device_type(
    device_type: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    根据设备类型获取可用模板列表（普通用户可用，仅返回名称和版本）
    用于申请烧录文件时选择模板
    """
    from app.schemas.template import DeviceTemplate
    template_service = TemplateService(db)
    templates = await template_service.get_by_device_type(device_type)
    
    # 只返回启用的模板，且只返回名称和版本信息
    result = []
    for template in templates:
        if template.is_active:  # 只返回启用的模板
            template_dict = {
                'id': str(template.id),
                'name': template.name,
                'version': getattr(template, 'version', 'v1'),  # 支持版本字段
                'device_type': template.device_type,
                'description': template.description,
                'is_active': template.is_active,
            }
            result.append(template_dict)
    
    return result

