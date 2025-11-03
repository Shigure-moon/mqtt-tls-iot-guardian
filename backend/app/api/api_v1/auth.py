from typing import Optional
from fastapi import Depends, APIRouter, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.core.security import create_access_token, create_refresh_token
from app.services.user import UserService
from app.schemas.user import User, Token, UserCreate
from jose import JWTError, jwt
from app.core.config import settings
from datetime import timedelta

router = APIRouter()
oauth2_scheme = OAuth2PasswordBearer(tokenUrl=f"{settings.API_V1_STR}/auth/login")


async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
) -> User:
    """获取当前用户"""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="无法验证凭据",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(
            token,
            settings.JWT_SECRET_KEY,
            algorithms=[settings.JWT_ALGORITHM]
        )
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
    except JWTError as e:
        raise credentials_exception
    
    try:
        user_service = UserService(db)
        user = await user_service.get_by_username(username=username)
        if user is None:
            raise credentials_exception
        
        # Convert SQLAlchemy model to Pydantic schema
        # FastAPI can handle this automatically, but we need explicit conversion for dependencies
        try:
            # Pydantic v2: model_validate with from_attributes mode
            return User.model_validate(user)
        except Exception as convert_error:
            # If Pydantic v2 fails, try manual conversion or Pydantic v1
            try:
                if hasattr(User, 'from_orm'):
                    return User.from_orm(user)
            except:
                pass
            
            # Last resort: manual conversion
            import logging
            logger = logging.getLogger(__name__)
            logger.error(f"User conversion error: {convert_error}, user: {user.id}, {user.username}")
            # Return a User schema manually constructed
            return User(
                id=user.id,
                username=user.username,
                email=user.email,
                full_name=user.full_name,
                mobile=user.mobile,
                is_active=user.is_active,
                is_admin=user.is_admin,
                created_at=user.created_at,
                updated_at=user.updated_at
            )
    except HTTPException:
        raise
    except Exception as e:
        # Log the actual error for debugging
        import logging
        logger = logging.getLogger(__name__)
        logger.error(f"Error getting current user: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"用户认证失败: {str(e)}"
        )

async def get_current_active_user(
    current_user: User = Depends(get_current_user)
) -> User:
    """获取当前活跃用户"""
    if not current_user.is_active:
        raise HTTPException(status_code=400, detail="用户未激活")
    return current_user

async def get_current_admin_user(
    current_user: User = Depends(get_current_active_user)
) -> User:
    """获取当前管理员用户"""
    if not current_user.is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="权限不足"
        )
    return current_user

@router.post("/login", response_model=Token)
async def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: AsyncSession = Depends(get_db)
) -> Token:
    """用户登录"""
    import logging
    logger = logging.getLogger(__name__)
    
    try:
        logger.debug(f"Login attempt for username: {form_data.username}")
        user_service = UserService(db)
        
        # 验证用户
        user = await user_service.authenticate(form_data.username, form_data.password)
        if not user:
            logger.warning(f"Authentication failed for username: {form_data.username}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="用户名或密码错误",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        # 检查用户是否激活
        is_active = await user_service.is_active(user)
        if not is_active:
            logger.warning(f"Inactive user attempted login: {form_data.username}")
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="用户未激活"
            )
        
        # 创建访问令牌和刷新令牌
        try:
            access_token = create_access_token(user.username)
            refresh_token = create_refresh_token(user.username)
            logger.info(f"Login successful for username: {form_data.username}")
        except Exception as token_error:
            logger.error(f"Token creation error: {token_error}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="令牌创建失败"
            )
        
        return Token(
            access_token=access_token,
            refresh_token=refresh_token
        )
    except HTTPException:
        raise
    except Exception as e:
        # Log the actual error for debugging
        logger.error(f"Login error: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"登录失败: {str(e)}"
        )

@router.post("/refresh", response_model=Token)
async def refresh_token(
    current_user: User = Depends(get_current_user)
) -> Token:
    """刷新令牌"""
    access_token = create_access_token(current_user.username)
    refresh_token = create_refresh_token(current_user.username)
    
    return Token(
        access_token=access_token,
        refresh_token=refresh_token
    )

@router.post("/register", response_model=User)
async def register(
    user_data: UserCreate,
    db: AsyncSession = Depends(get_db)
) -> User:
    """用户注册"""
    user_service = UserService(db)
    
    # 检查用户名是否已存在
    if await user_service.get_by_username(user_data.username):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="用户名已存在"
        )
    
    # 检查邮箱是否已存在
    if await user_service.get_by_email(user_data.email):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="邮箱已被注册"
        )
    
    # 创建新用户
    user = await user_service.create(user_data)
    return user