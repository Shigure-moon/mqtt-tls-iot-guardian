from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import declarative_base
from sqlalchemy import text
from app.core.config import settings
from fastapi import HTTPException
import logging

logger = logging.getLogger(__name__)

# 创建异步引擎
# 注意：PostgreSQL异步需要 postgresql+asyncpg:// 协议
# 配置连接池参数以支持并发请求
engine = create_async_engine(
    settings.DATABASE_URL_ASYNC,
    echo=settings.DEBUG,
    future=True,
    # 连接池配置
    pool_size=settings.DB_POOL_SIZE,  # 连接池大小
    max_overflow=settings.DB_MAX_OVERFLOW,  # 最大溢出连接数
    pool_timeout=settings.DB_POOL_TIMEOUT,  # 获取连接的超时时间
    pool_recycle=settings.DB_POOL_RECYCLE,  # 连接回收时间
    pool_pre_ping=settings.DB_POOL_PRE_PING,  # 连接前验证连接是否有效
    # 连接参数
    connect_args={
        "server_settings": {
            "application_name": "iot_guardian_backend",
            "tcp_keepalives_idle": "600",
            "tcp_keepalives_interval": "30",
            "tcp_keepalives_count": "3",
        },
        "command_timeout": 60,  # 命令超时时间
    },
)

# 创建异步会话类 - 请求级会话工厂
# 每个请求都会创建一个新的会话
AsyncSessionLocal = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,  # 提交后不使对象过期
    autocommit=False,
    autoflush=False,
)

# 创建Base类
Base = declarative_base()

# 获取异步数据库会话 - 请求级依赖注入
# 这是FastAPI的标准模式：每个请求都会创建一个新的会话
async def get_db():
    """
    获取数据库会话（请求级依赖）
    每个HTTP请求都会创建一个新的数据库会话
    请求结束后自动关闭会话并返回连接池
    """
    async with AsyncSessionLocal() as session:
        try:
            # 验证连接是否有效（如果启用了pool_pre_ping，这里通常不需要）
            # 但为了安全起见，我们可以确保连接是活跃的
            yield session
            # 请求成功，提交事务
            await session.commit()
        except HTTPException:
            # HTTPException是预期的业务异常，不应该回滚或记录为数据库错误
            # 直接向上传播，让FastAPI处理
            raise
        except Exception as e:
            # 发生错误，回滚事务
            await session.rollback()
            logger.error(f"Database session error: {e}", exc_info=True)
            raise
        finally:
            # 确保会话已关闭（async with 会自动处理，但显式调用更清晰）
            await session.close()

# 为了向后兼容，保留同步SessionLocal（用于初始化脚本）
from sqlalchemy import create_engine as create_sync_engine
from sqlalchemy.orm import sessionmaker as create_sessionmaker

# 同步引擎（用于Alembic迁移等脚本）
sync_engine = create_sync_engine(
    settings.DATABASE_URL,
    echo=settings.DEBUG,
    future=True,
    pool_size=settings.DB_POOL_SIZE,
    max_overflow=settings.DB_MAX_OVERFLOW,
    pool_timeout=settings.DB_POOL_TIMEOUT,
    pool_recycle=settings.DB_POOL_RECYCLE,
    pool_pre_ping=settings.DB_POOL_PRE_PING,
)

SessionLocal = create_sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=sync_engine
)

# 连接池健康检查函数
async def check_pool_health():
    """检查连接池健康状态"""
    try:
        async with AsyncSessionLocal() as session:
            # 执行简单查询验证连接
            await session.execute(text("SELECT 1"))
            await session.commit()
            return True
    except Exception as e:
        logger.error(f"Database pool health check failed: {e}")
        return False

# 关闭所有连接池（用于优雅关闭）
async def close_pool():
    """关闭数据库连接池"""
    try:
        await engine.dispose()
        logger.info("Database connection pool closed")
    except Exception as e:
        logger.error(f"Error closing database pool: {e}")