"""
加密密钥管理服务
处理XOR密钥的加密存储和访问控制
"""
import hashlib
import logging
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.firmware_encryption import DeviceEncryptionKey
from app.services.firmware_encryption import FirmwareEncryptionService
from app.core.encryption import encrypt_certificate_data, decrypt_certificate_data

logger = logging.getLogger(__name__)


class EncryptionKeyService:
    """加密密钥管理服务"""
    
    def __init__(self, db: AsyncSession):
        self.db = db
        self.encryption_service = FirmwareEncryptionService()
    
    async def create_key_for_device(self, device_id: str, user_id: Optional[str] = None, force: bool = False) -> Optional[str]:
        """
        为设备创建加密密钥（加密后存储到数据库）
        
        Args:
            device_id: 设备ID（UUID字符串）
            user_id: 创建者用户ID（可选）
            force: 是否强制覆盖现有密钥（默认False）
            
        Returns:
            密钥的十六进制字符串（仅用于返回，不存储明文）
        """
        try:
            # 检查是否已存在密钥
            existing = await self.get_key_for_device(device_id, decrypt=False)
            if existing:
                if not force:
                    logger.warning(f"设备 {device_id} 已存在加密密钥")
                    return None
                else:
                    # 如果force=True，先撤销现有密钥
                    logger.info(f"强制重新生成密钥，先撤销设备 {device_id} 的现有密钥")
                    await self.revoke_key(device_id)
            
            # 生成新的XOR密钥
            key_bytes = self.encryption_service.generate_xor_key()
            key_hex = key_bytes.hex()
            key_hash = hashlib.sha256(key_bytes).hexdigest()
            
            # 加密密钥
            key_encrypted = encrypt_certificate_data(key_hex)
            
            # 保存到数据库
            encryption_key = DeviceEncryptionKey(
                device_id=device_id,
                key_encrypted=key_encrypted,
                key_hash=key_hash,
                created_by=user_id,
                is_active=True
            )
            self.db.add(encryption_key)
            await self.db.commit()
            await self.db.refresh(encryption_key)
            
            logger.info(f"为设备 {device_id} 创建加密密钥成功")
            return key_hex
            
        except Exception as e:
            logger.error(f"创建加密密钥失败: {e}", exc_info=True)
            await self.db.rollback()
            return None
    
    async def get_key_for_device(
        self,
        device_id: str,
        decrypt: bool = True,
        require_admin: bool = True
    ) -> Optional[str]:
        """
        获取设备的加密密钥
        
        Args:
            device_id: 设备ID
            decrypt: 是否解密密钥（True时返回明文，False时返回加密的）
            require_admin: 是否需要管理员权限（默认True，只有管理员可以查看密钥）
            
        Returns:
            密钥的十六进制字符串（如果decrypt=True），或加密的密钥（如果decrypt=False）
            如果require_admin=True但用户不是管理员，返回None
        """
        try:
            result = await self.db.execute(
                select(DeviceEncryptionKey)
                .filter(DeviceEncryptionKey.device_id == device_id)
                .filter(DeviceEncryptionKey.is_active == True)
            )
            encryption_key = result.scalar_one_or_none()
            
            if not encryption_key:
                return None
            
            if decrypt:
                # 解密密钥
                try:
                    key_hex = decrypt_certificate_data(encryption_key.key_encrypted)
                    return key_hex
                except Exception as e:
                    logger.error(f"解密密钥失败: {e}", exc_info=True)
                    return None
            else:
                # 返回加密的密钥（用于验证）
                return encryption_key.key_encrypted
                
        except Exception as e:
            logger.error(f"获取加密密钥失败: {e}", exc_info=True)
            return None
    
    async def verify_key(self, device_id: str, key_hex: str) -> bool:
        """
        验证密钥是否正确
        
        Args:
            device_id: 设备ID
            key_hex: 密钥的十六进制字符串
            
        Returns:
            是否匹配
        """
        try:
            key_bytes = bytes.fromhex(key_hex)
            key_hash = hashlib.sha256(key_bytes).hexdigest()
            
            result = await self.db.execute(
                select(DeviceEncryptionKey)
                .filter(DeviceEncryptionKey.device_id == device_id)
                .filter(DeviceEncryptionKey.is_active == True)
            )
            encryption_key = result.scalar_one_or_none()
            
            if not encryption_key:
                return False
            
            return encryption_key.key_hash == key_hash
            
        except Exception as e:
            logger.error(f"验证密钥失败: {e}", exc_info=True)
            return False
    
    async def revoke_key(self, device_id: str) -> bool:
        """
        撤销设备的加密密钥
        
        Args:
            device_id: 设备ID
            
        Returns:
            是否成功
        """
        try:
            result = await self.db.execute(
                select(DeviceEncryptionKey)
                .filter(DeviceEncryptionKey.device_id == device_id)
            )
            encryption_key = result.scalar_one_or_none()
            
            if not encryption_key:
                return False
            
            encryption_key.is_active = False
            await self.db.commit()
            
            logger.info(f"设备 {device_id} 的加密密钥已撤销")
            return True
            
        except Exception as e:
            logger.error(f"撤销密钥失败: {e}", exc_info=True)
            await self.db.rollback()
            return False

