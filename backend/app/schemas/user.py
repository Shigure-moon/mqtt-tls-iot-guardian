from typing import Optional, List
from pydantic import BaseModel, EmailStr, UUID4
from datetime import datetime

class UserBase(BaseModel):
    username: str
    email: EmailStr
    full_name: Optional[str] = None
    mobile: Optional[str] = None

class UserCreate(UserBase):
    password: str

class UserUpdate(UserBase):
    password: Optional[str] = None
    is_active: Optional[bool] = None

class UserInDBBase(UserBase):
    id: UUID4
    is_active: bool
    is_admin: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class User(UserInDBBase):
    pass

class UserInDB(UserInDBBase):
    hashed_password: str

class UserResponse(UserInDBBase):
    last_login_at: Optional[datetime] = None

class UserWithPermissions(UserResponse):
    roles: List[str] = []
    permissions: List[str] = []

class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"

class TokenPayload(BaseModel):
    sub: str
    exp: int
    type: str

class RoleBase(BaseModel):
    name: str
    description: Optional[str] = None

class RoleCreate(RoleBase):
    pass

class RoleUpdate(RoleBase):
    pass

class Role(RoleBase):
    id: UUID4
    created_at: datetime

    class Config:
        from_attributes = True