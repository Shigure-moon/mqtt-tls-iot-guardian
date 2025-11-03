from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.api.api_v1.auth import get_current_active_user, get_current_admin_user
from app.core.database import get_db
from app.schemas.user import (
    User, UserCreate, UserUpdate, UserResponse,
    UserWithPermissions
)
from app.services.user import UserService

router = APIRouter()

@router.post("", response_model=UserResponse)
async def create_user(
    user_in: UserCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_admin_user)
) -> User:
    """创建新用户（仅管理员）"""
    user_service = UserService(db)
    
    # 检查用户名是否已存在
    if await user_service.get_by_username(username=user_in.username):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="用户名已存在"
        )
    
    # 检查邮箱是否已存在
    if await user_service.get_by_email(email=user_in.email):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="邮箱已被使用"
        )
    
    user = await user_service.create(user_in)
    return user

@router.get("/me", response_model=UserWithPermissions)
async def read_user_me(
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
) -> User:
    """获取当前用户信息"""
    user_service = UserService(db)
    roles = await user_service.get_user_roles(current_user)
    current_user.roles = [role.name for role in roles]
    return current_user

@router.put("/me", response_model=UserResponse)
async def update_user_me(
    user_in: UserUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
) -> User:
    """更新当前用户信息"""
    user_service = UserService(db)
    
    # 如果要更新邮箱，检查新邮箱是否已被使用
    if user_in.email and user_in.email != current_user.email:
        if await user_service.get_by_email(email=user_in.email):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="邮箱已被使用"
            )
    
    user = await user_service.update(current_user, user_in)
    return user

@router.get("/{user_id}", response_model=UserResponse)
async def read_user_by_id(
    user_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_admin_user)
) -> User:
    """通过ID获取用户信息（仅管理员）"""
    user_service = UserService(db)
    user = await user_service.get_by_id(user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="用户不存在"
        )
    return user

@router.put("/{user_id}", response_model=UserResponse)
async def update_user(
    user_id: str,
    user_in: UserUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_admin_user)
) -> User:
    """更新用户信息（仅管理员）"""
    user_service = UserService(db)
    user = await user_service.get_by_id(user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="用户不存在"
        )
    
    # 如果要更新邮箱，检查新邮箱是否已被使用
    if user_in.email and user_in.email != user.email:
        if await user_service.get_by_email(email=user_in.email):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="邮箱已被使用"
            )
    
    user = await user_service.update(user, user_in)
    return user

@router.delete("/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_user(
    user_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_admin_user)
):
    """删除用户（仅管理员）"""
    user_service = UserService(db)
    user = await user_service.get_by_id(user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="用户不存在"
        )
    
    # 不能删除自己
    if user.id == current_user.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="不能删除自己的账号"
        )
    
    await user_service.delete(user)