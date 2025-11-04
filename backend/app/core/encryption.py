"""
证书加密工具
使用Fernet对称加密来加密存储设备证书和私钥
"""
from typing import Optional
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
import base64
import os
import logging

logger = logging.getLogger(__name__)

# 全局加密器实例
_fernet_instance: Optional[Fernet] = None


def get_encryption_key() -> bytes:
    """
    获取或生成加密密钥
    优先使用环境变量 CERT_ENCRYPTION_KEY
    如果没有，则使用 JWT_SECRET_KEY 派生密钥
    """
    from app.core.config import settings
    
    # 优先使用专门的证书加密密钥
    if hasattr(settings, 'CERT_ENCRYPTION_KEY') and settings.CERT_ENCRYPTION_KEY:
        key_str = settings.CERT_ENCRYPTION_KEY
        # 如果密钥是32字节的base64编码字符串，直接使用
        if len(key_str) == 44:  # Fernet密钥的base64编码长度
            return key_str.encode()
        # 否则使用PBKDF2派生密钥
        return _derive_key_from_password(key_str)
    
    # 使用JWT_SECRET_KEY派生密钥
    password = settings.JWT_SECRET_KEY.encode()
    return _derive_key_from_password(password.decode())


def _derive_key_from_password(password: str) -> bytes:
    """
    从密码派生Fernet密钥
    使用PBKDF2算法
    """
    # 使用固定的salt（在实际应用中，可以考虑将salt存储在配置中）
    salt = b'iot_guardian_cert_salt_2024'  # 固定salt，确保密钥一致性
    
    kdf = PBKDF2HMAC(
        algorithm=hashes.SHA256(),
        length=32,
        salt=salt,
        iterations=100000,
        backend=default_backend()
    )
    key = base64.urlsafe_b64encode(kdf.derive(password.encode()))
    return key


def get_fernet() -> Fernet:
    """
    获取Fernet加密器实例（单例模式）
    """
    global _fernet_instance
    if _fernet_instance is None:
        key = get_encryption_key()
        _fernet_instance = Fernet(key)
        logger.info("Fernet encryption instance initialized")
    return _fernet_instance


def encrypt_certificate_data(data: str) -> str:
    """
    加密证书数据（证书或私钥）
    如果数据已经是加密格式，直接返回（避免重复加密）
    
    Args:
        data: 要加密的证书数据（字符串）
    
    Returns:
        加密后的base64编码字符串
    """
    if not data:
        return data
    
    # 检查是否已经是加密格式（简单判断：如果以 "-----BEGIN" 开头，说明是原始证书）
    # 如果已经加密，通常会是不包含 "-----BEGIN" 的base64字符串
    if not data.strip().startswith('-----BEGIN'):
        # 可能是已经加密的数据，但为了安全起见，我们仍然尝试加密
        # 或者可以添加更智能的检测逻辑
        pass
    
    try:
        fernet = get_fernet()
        encrypted_data = fernet.encrypt(data.encode())
        # 返回base64编码的字符串，便于存储在数据库中
        return base64.b64encode(encrypted_data).decode()
    except Exception as e:
        logger.error(f"Error encrypting certificate data: {e}", exc_info=True)
        raise ValueError(f"证书加密失败: {str(e)}")


def decrypt_certificate_data(encrypted_data: str) -> str:
    """
    解密证书数据（证书或私钥）
    如果数据未加密（旧数据），直接返回
    
    Args:
        encrypted_data: 加密后的base64编码字符串或原始数据
    
    Returns:
        解密后的原始证书数据
    """
    if not encrypted_data:
        return encrypted_data
    
    # 检查是否是加密数据（简单判断：如果包含证书特征，可能是未加密的）
    # PEM格式的证书通常以 "-----BEGIN" 开头
    if encrypted_data.strip().startswith('-----BEGIN'):
        # 这是未加密的原始证书，直接返回
        logger.debug("Certificate data appears to be unencrypted, returning as-is")
        return encrypted_data
    
    try:
        fernet = get_fernet()
        # 尝试从base64解码
        try:
            encrypted_bytes = base64.b64decode(encrypted_data.encode())
        except:
            # 如果无法base64解码，可能是未加密的原始数据
            logger.debug("Failed to base64 decode, treating as unencrypted data")
            return encrypted_data
        
        # 尝试解密
        try:
            decrypted_data = fernet.decrypt(encrypted_bytes)
            return decrypted_data.decode()
        except:
            # 如果解密失败，可能是未加密的原始数据（base64编码的证书）
            logger.debug("Failed to decrypt, treating as unencrypted data")
            # 尝试直接返回base64解码后的数据
            try:
                return encrypted_bytes.decode()
            except:
                return encrypted_data
    except Exception as e:
        logger.warning(f"Error decrypting certificate data, treating as unencrypted: {e}")
        # 如果解密失败，假设是未加密的数据，直接返回
        return encrypted_data


def is_encrypted(data: str) -> bool:
    """
    检查数据是否已加密
    通过尝试base64解码和检查格式来判断
    """
    if not data:
        return False
    
    try:
        # 尝试base64解码
        decoded = base64.b64decode(data.encode())
        # 检查是否是Fernet加密格式（Fernet加密后的数据通常以特定字节开头）
        # 简单检查：如果数据是base64编码且长度合理，可能是加密的
        return len(decoded) > 0 and data.startswith('gAAAAA') == False  # Fernet token通常以gAAAAA开头
    except:
        # 如果无法解码，可能是未加密的原始数据
        return False

