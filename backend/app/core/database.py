from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import declarative_base
from app.core.config import settings

# 创建异步引擎
# 注意：PostgreSQL异步需要 postgresql+asyncpg:// 协议
engine = create_async_engine(
    f"postgresql+asyncpg://{settings.DB_USER}:{settings.DB_PASSWORD}@{settings.DB_HOST}:{settings.DB_PORT}/{settings.DB_NAME}",
    echo=settings.DEBUG,
    future=True
)

# 创建异步会话类
AsyncSessionLocal = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False
)

# 创建Base类
Base = declarative_base()

# 获取异步数据库会话
async def get_db():
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise

# 为了向后兼容，保留同步SessionLocal（用于初始化脚本）
from sqlalchemy import create_engine as create_sync_engine
from sqlalchemy.orm import sessionmaker as create_sessionmaker

sync_engine = create_sync_engine(
    f"postgresql://{settings.DB_USER}:{settings.DB_PASSWORD}@{settings.DB_HOST}:{settings.DB_PORT}/{settings.DB_NAME}",
    echo=settings.DEBUG,
    future=True
)

SessionLocal = create_sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=sync_engine
)