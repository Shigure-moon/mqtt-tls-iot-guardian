"""
模型导入文件
确保所有模型在应用启动时被正确导入和注册
"""
# 导入所有模型，确保 SQLAlchemy 可以正确解析关系
from app.models import device
from app.models import user
from app.models import monitoring
from app.models import security
from app.models import template
from app.models import certificate
from app.models import firmware_encryption

__all__ = [
    "device",
    "user",
    "monitoring",
    "security",
    "template",
    "certificate",
    "firmware_encryption",
]

