from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.api.api_v1.api import api_router
from app.core.events import startup_handler, shutdown_handler
from app.core.database import check_pool_health, close_pool
import logging

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description=settings.DESCRIPTION,
    openapi_url=f"{settings.API_V1_STR}/openapi.json"
)

# CORS设置
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 注册路由
app.include_router(api_router, prefix=settings.API_V1_STR)

# 启动和关闭事件
@app.on_event("startup")
async def startup_event():
    """应用启动时的处理"""
    logger.info("Starting up application...")
    # 验证连接池健康
    if await check_pool_health():
        logger.info("Database connection pool is healthy")
    else:
        logger.warning("Database connection pool health check failed")
    # 调用原有启动处理器
    await startup_handler()

@app.on_event("shutdown")
async def shutdown_event():
    """应用关闭时的处理"""
    logger.info("Shutting down application...")
    # 关闭连接池
    await close_pool()
    # 调用原有关闭处理器
    await shutdown_handler()

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=settings.API_PORT,
        reload=settings.DEBUG,
        log_level="debug" if settings.DEBUG else "info"
    )