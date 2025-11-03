from fastapi import APIRouter
from app.api.api_v1 import auth, devices, security, monitoring

from . import users

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["认证管理"])
api_router.include_router(users.router, prefix="/users", tags=["用户管理"])
api_router.include_router(devices.router, prefix="/devices", tags=["设备管理"])
api_router.include_router(security.router, prefix="/security", tags=["安全管理"])
api_router.include_router(monitoring.router, prefix="/monitoring", tags=["监控管理"])