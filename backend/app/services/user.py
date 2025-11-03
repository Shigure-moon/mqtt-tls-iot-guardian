from typing import Optional, List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update
from app.models.user import User, Role, UserRole
from app.schemas.user import UserCreate, UserUpdate
from app.core.security import get_password_hash, verify_password

class UserService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_id(self, user_id: str) -> Optional[User]:
        """通过ID获取用户"""
        result = await self.db.execute(select(User).filter(User.id == user_id))
        return result.scalar_one_or_none()

    async def get_by_email(self, email: str) -> Optional[User]:
        """通过邮箱获取用户"""
        result = await self.db.execute(select(User).filter(User.email == email))
        return result.scalar_one_or_none()

    async def get_by_username(self, username: str) -> Optional[User]:
        """通过用户名获取用户"""
        result = await self.db.execute(select(User).filter(User.username == username))
        return result.scalar_one_or_none()

    async def create(self, user_in: UserCreate) -> User:
        """创建新用户"""
        user = User(
            username=user_in.username,
            email=user_in.email,
            hashed_password=get_password_hash(user_in.password),
            full_name=user_in.full_name,
            mobile=user_in.mobile
        )
        self.db.add(user)
        await self.db.commit()
        await self.db.refresh(user)
        return user

    async def update(self, user: User, user_in: UserUpdate) -> User:
        """更新用户信息"""
        update_data = user_in.model_dump(exclude_unset=True)
        if update_data.get("password"):
            update_data["hashed_password"] = get_password_hash(update_data.pop("password"))
        
        for field, value in update_data.items():
            setattr(user, field, value)
        
        self.db.add(user)
        await self.db.commit()
        await self.db.refresh(user)
        return user

    async def authenticate(self, username: str, password: str) -> Optional[User]:
        """用户认证"""
        user = await self.get_by_username(username)
        if not user:
            return None
        if not verify_password(password, user.hashed_password):
            return None
        return user

    async def is_active(self, user: User) -> bool:
        """检查用户是否激活"""
        return user.is_active

    async def is_admin(self, user: User) -> bool:
        """检查用户是否是管理员"""
        return user.is_admin

    async def get_roles(self, user: User) -> List[Role]:
        """获取用户角色"""
        result = await self.db.execute(
            select(Role)
            .join(UserRole)
            .filter(UserRole.user_id == user.id)
        )
        return result.scalars().all()

    async def add_role(self, user: User, role: Role) -> None:
        """添加用户角色"""
        user_role = UserRole(user_id=user.id, role_id=role.id)
        self.db.add(user_role)
        await self.db.commit()