"""
固件加密相关数据库模型
"""
from datetime import datetime
from sqlalchemy import Column, String, DateTime, ForeignKey, Boolean, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from typing import TYPE_CHECKING
import uuid
from app.core.database import Base

if TYPE_CHECKING:
    from app.models.device import Device
    from app.models.user import User


class DeviceEncryptionKey(Base):
    """设备加密密钥（XOR密钥）"""
    __tablename__ = "device_encryption_keys"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    device_id = Column(UUID(as_uuid=True), ForeignKey("devices.id", ondelete="CASCADE"), nullable=False, unique=True)
    key_encrypted = Column(Text, nullable=False)  # 加密后的密钥（Base64编码）
    key_hash = Column(String(64), nullable=False)  # 密钥的SHA256哈希（用于验证）
    created_by = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"))  # 创建者
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow)
    updated_at = Column(DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow)
    is_active = Column(Boolean, default=True)  # 是否激活

    # 关系（使用字符串引用避免循环导入）
    device = relationship("Device", backref="encryption_key")
    creator = relationship("User", foreign_keys=[created_by])


class FirmwareBuild(Base):
    """固件构建记录"""
    __tablename__ = "firmware_builds"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    device_id = Column(UUID(as_uuid=True), ForeignKey("devices.id", ondelete="CASCADE"), nullable=False)
    firmware_path = Column(String(512), nullable=False)  # 固件文件路径
    firmware_hash = Column(String(64), nullable=False)  # 固件SHA256哈希
    firmware_size = Column(String(20), nullable=False)  # 固件大小（字节）
    encrypted_firmware_path = Column(String(512))  # 加密后的固件路径
    encrypted_firmware_hash = Column(String(64))  # 加密后固件的哈希
    build_type = Column(String(20), default="encrypted")  # 构建类型：encrypted, plain
    encryption_key_id = Column(UUID(as_uuid=True), ForeignKey("device_encryption_keys.id", ondelete="SET NULL"))
    status = Column(String(20), default="pending")  # 状态：pending, building, completed, failed
    error_message = Column(Text)  # 错误信息
    created_by = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"))
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow)
    updated_at = Column(DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow)

    # 关系（使用字符串引用避免循环导入）
    device = relationship("Device", backref="firmware_builds")
    encryption_key = relationship("DeviceEncryptionKey", foreign_keys=[encryption_key_id])
    creator = relationship("User", foreign_keys=[created_by])


class OTAUpdateTask(Base):
    """OTA更新任务"""
    __tablename__ = "ota_update_tasks"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    device_id = Column(UUID(as_uuid=True), ForeignKey("devices.id", ondelete="CASCADE"), nullable=False)
    firmware_build_id = Column(UUID(as_uuid=True), ForeignKey("firmware_builds.id", ondelete="SET NULL"))
    firmware_url = Column(String(512), nullable=False)  # 固件下载URL
    firmware_version = Column(String(50))  # 固件版本号
    firmware_hash = Column(String(64))  # 固件哈希值
    status = Column(String(20), default="pending")  # 状态：pending, sent, downloading, installing, completed, failed, cancelled
    progress = Column(String(20), default="0%")  # 更新进度
    error_message = Column(Text)  # 错误信息
    started_at = Column(DateTime(timezone=True))  # 开始时间
    completed_at = Column(DateTime(timezone=True))  # 完成时间
    created_by = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"))
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow)
    updated_at = Column(DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow)

    # 关系
    device = relationship("Device", backref="ota_updates")
    firmware_build = relationship("FirmwareBuild", foreign_keys=[firmware_build_id])
    creator = relationship("User", foreign_keys=[created_by])

