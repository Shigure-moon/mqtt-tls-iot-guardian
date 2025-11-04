"""
设备模板模型
用于存储不同设备型号的固件代码模板
"""
from datetime import datetime
from sqlalchemy import Column, String, Text, DateTime, Boolean, Index
from sqlalchemy.dialects.postgresql import UUID
import uuid
from app.core.database import Base


class DeviceTemplate(Base):
    __tablename__ = "device_templates"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(100), nullable=False, index=True)  # 模板名称（如：ESP8266-ILI9341-v1）
    version = Column(String(20), nullable=False, default="v1", index=True)  # 版本号（如：v1, v2）
    device_type = Column(String(50), nullable=False, index=True)  # 设备类型（如：ESP8266）
    description = Column(String(500))  # 模板描述
    template_code = Column(Text, nullable=False)  # 加密存储的模板代码
    required_libraries = Column(Text)  # 所需库列表（JSON格式）
    is_active = Column(Boolean, default=True)  # 是否启用
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow)
    updated_at = Column(DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow)
    created_by = Column(UUID(as_uuid=True))  # 创建者ID
    
    # 唯一约束：同一名称和版本的组合必须唯一
    __table_args__ = (
        Index('ix_device_templates_name_version', 'name', 'version', unique=True),
    )

