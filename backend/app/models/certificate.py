from datetime import datetime
from sqlalchemy import Column, String, DateTime, ForeignKey, Boolean
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
import uuid
from app.core.database import Base

# 延迟导入User模型以避免循环导入
from typing import TYPE_CHECKING
if TYPE_CHECKING:
    from app.models.user import User


class ServerCertificate(Base):
    """服务器证书模型"""
    __tablename__ = "server_certificates"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    certificate = Column(String, nullable=False)  # 加密存储
    private_key = Column(String, nullable=False)  # 加密存储
    common_name = Column(String(255), nullable=False)  # 证书的CN
    serial_number = Column(String(100), unique=True, nullable=False)
    issued_at = Column(DateTime(timezone=True), nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=False)
    revoked_at = Column(DateTime(timezone=True))
    revoke_reason = Column(String(100))
    created_by = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"))  # 创建者
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow)
    updated_at = Column(DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow)
    is_active = Column(Boolean, default=True)  # 是否激活

    # 使用字符串引用避免循环导入
    creator = relationship("User", foreign_keys=[created_by], backref="server_certificates")

