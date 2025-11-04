"""
固件加密服务
提供XOR掩码和HTTPS OTA相关功能
"""
import os
import secrets
import hashlib
from typing import Optional, Tuple
from pathlib import Path
import logging

logger = logging.getLogger(__name__)


class FirmwareEncryptionService:
    """固件加密服务"""
    
    # XOR密钥长度（16字节 = 128位）
    XOR_KEY_LENGTH = 16
    
    def __init__(self, firmware_dir: Optional[str] = None):
        """
        初始化固件加密服务
        
        Args:
            firmware_dir: 固件存储目录，默认为 data/firmware
        """
        if firmware_dir is None:
            # 从项目根目录计算
            project_root = Path(__file__).parent.parent.parent.parent
            firmware_dir = project_root / "data" / "firmware"
        
        self.firmware_dir = Path(firmware_dir)
        self.firmware_dir.mkdir(parents=True, exist_ok=True)
        
        # 密钥存储目录
        self.key_dir = self.firmware_dir / "keys"
        self.key_dir.mkdir(parents=True, exist_ok=True)
    
    def generate_xor_key(self) -> bytes:
        """
        生成随机XOR掩码密钥
        
        Returns:
            16字节的随机密钥
        """
        return secrets.token_bytes(self.XOR_KEY_LENGTH)
    
    def save_xor_key(self, key: bytes, device_id: str) -> str:
        """
        保存XOR密钥到文件
        
        Args:
            key: 密钥字节
            device_id: 设备ID
            
        Returns:
            密钥文件路径
        """
        key_file = self.key_dir / f"{device_id}_key.txt"
        with open(key_file, 'w') as f:
            f.write(key.hex())
        logger.info(f"XOR密钥已保存到: {key_file}")
        return str(key_file)
    
    def load_xor_key(self, device_id: str) -> Optional[bytes]:
        """
        加载设备XOR密钥
        
        Args:
            device_id: 设备ID
            
        Returns:
            密钥字节，如果不存在则返回None
        """
        key_file = self.key_dir / f"{device_id}_key.txt"
        if not key_file.exists():
            return None
        
        try:
            with open(key_file, 'r') as f:
                key_hex = f.read().strip()
                return bytes.fromhex(key_hex)
        except Exception as e:
            logger.error(f"加载密钥失败: {e}")
            return None
    
    def apply_xor_mask(self, firmware_path: str, key: bytes, output_path: Optional[str] = None) -> str:
        """
        对固件应用XOR掩码
        
        Args:
            firmware_path: 原始固件路径
            key: XOR密钥
            output_path: 输出路径，如果为None则自动生成
            
        Returns:
            掩码后的固件路径
        """
        firmware_path = Path(firmware_path)
        
        if output_path is None:
            output_path = firmware_path.parent / f"{firmware_path.stem}_masked{firmware_path.suffix}"
        else:
            output_path = Path(output_path)
        
        # 读取原始固件
        with open(firmware_path, 'rb') as f:
            firmware_data = bytearray(f.read())
        
        # 应用XOR掩码
        for i in range(len(firmware_data)):
            firmware_data[i] ^= key[i % len(key)]
        
        # 写入掩码后的固件
        output_path.parent.mkdir(parents=True, exist_ok=True)
        with open(output_path, 'wb') as f:
            f.write(firmware_data)
        
        logger.info(f"XOR掩码已应用，输出: {output_path}")
        return str(output_path)
    
    def get_certificate_fingerprint(self, cert_path: str) -> str:
        """
        获取证书的SHA256指纹（用于HTTPS OTA验证）
        
        Args:
            cert_path: 证书文件路径
            
        Returns:
            证书指纹（冒号分隔的十六进制字符串）
        """
        try:
            from cryptography import x509
            from cryptography.hazmat.backends import default_backend
            from cryptography.hazmat.primitives import hashes
            
            with open(cert_path, 'rb') as f:
                cert_data = f.read()
            
            cert = x509.load_pem_x509_certificate(cert_data, default_backend())
            # 使用hashes.SHA256()实例，不是hashlib.sha256()
            fingerprint = cert.fingerprint(hashes.SHA256())
            
            # 转换为冒号分隔的格式
            fingerprint_str = ':'.join(f'{b:02X}' for b in fingerprint)
            return fingerprint_str
        except ImportError:
            # 如果没有cryptography库，使用OpenSSL命令
            import subprocess
            try:
                result = subprocess.run(
                    ['openssl', 'x509', '-fingerprint', '-sha256', '-noout', '-in', cert_path],
                    capture_output=True,
                    text=True,
                    check=True
                )
                # 提取指纹：SHA256 Fingerprint=AA:BB:CC:...
                fingerprint_line = result.stdout.strip()
                fingerprint_str = fingerprint_line.split('=')[1]
                return fingerprint_str
            except (subprocess.CalledProcessError, FileNotFoundError):
                logger.error("无法获取证书指纹：需要cryptography库或openssl命令")
                raise
    
    def generate_encrypted_firmware(
        self,
        firmware_path: str,
        device_id: str,
        use_xor_mask: bool = True
    ) -> Tuple[str, Optional[str], Optional[str]]:
        """
        生成加密固件
        
        Args:
            firmware_path: 原始固件路径
            device_id: 设备ID
            use_xor_mask: 是否使用XOR掩码
            
        Returns:
            (加密后固件路径, XOR密钥文件路径, 密钥十六进制字符串)
        """
        firmware_path = Path(firmware_path)
        if not firmware_path.exists():
            raise FileNotFoundError(f"固件文件不存在: {firmware_path}")
        
        output_path = firmware_path
        key_file = None
        key_hex = None
        
        if use_xor_mask:
            # 生成或加载密钥
            key = self.load_xor_key(device_id)
            if key is None:
                key = self.generate_xor_key()
                key_file = self.save_xor_key(key, device_id)
                key_hex = key.hex()
            else:
                key_hex = key.hex()
            
            # 应用XOR掩码
            output_path = self.firmware_dir / f"{device_id}_masked.bin"
            self.apply_xor_mask(str(firmware_path), key, str(output_path))
        
        return str(output_path), key_file, key_hex
    
    def get_firmware_info(self, firmware_path: str) -> dict:
        """
        获取固件信息
        
        Args:
            firmware_path: 固件路径
            
        Returns:
            固件信息字典
        """
        firmware_path = Path(firmware_path)
        if not firmware_path.exists():
            raise FileNotFoundError(f"固件文件不存在: {firmware_path}")
        
        with open(firmware_path, 'rb') as f:
            data = f.read()
        
        return {
            'size': len(data),
            'sha256': hashlib.sha256(data).hexdigest(),
            'path': str(firmware_path),
            'name': firmware_path.name
        }

