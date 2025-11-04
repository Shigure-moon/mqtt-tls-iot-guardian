"""
OTA (Over-The-Air) 更新服务
提供HTTPS OTA固件下发功能
"""
import os
import logging
from pathlib import Path
from typing import Optional, Dict
from fastapi import HTTPException, status
from app.core.config import settings

logger = logging.getLogger(__name__)


class OTAService:
    """OTA更新服务"""
    
    def __init__(self, firmware_dir: Optional[str] = None):
        """
        初始化OTA服务
        
        Args:
            firmware_dir: 固件存储目录
        """
        if firmware_dir is None:
            project_root = Path(__file__).parent.parent.parent.parent
            firmware_dir = project_root / "data" / "firmware"
        
        self.firmware_dir = Path(firmware_dir)
        self.firmware_dir.mkdir(parents=True, exist_ok=True)
    
    def get_firmware_url(self, device_id: str, encrypted: bool = False, server_host: Optional[str] = None, server_port: Optional[int] = None, use_https: bool = True) -> str:
        """
        获取固件下载URL
        
        Args:
            device_id: 设备ID
            encrypted: 是否为加密固件
            server_host: 服务器地址（如果提供则使用，否则从配置读取）
            server_port: 服务器端口（如果提供则使用）
            use_https: 是否使用HTTPS
            
        Returns:
            固件URL
        """
        # 优先使用传入的服务器地址
        if server_host:
            protocol = "https" if use_https else "http"
            port_part = f":{server_port}" if server_port and ((use_https and server_port != 443) or (not use_https and server_port != 80)) else ""
            base_url = f"{protocol}://{server_host}{port_part}"
        else:
            # 从配置读取，如果没有则使用默认值
            base_url = getattr(settings, 'FIRMWARE_BASE_URL', None)
            if not base_url:
                # 尝试从其他配置推断
                api_host = getattr(settings, 'API_HOST', 'localhost')
                api_port = getattr(settings, 'API_PORT', 8000)
                protocol = "https" if use_https else "http"
                port_part = f":{api_port}" if ((use_https and api_port != 443) or (not use_https and api_port != 80)) else ""
                base_url = f"{protocol}://{api_host}{port_part}"
        
        return f"{base_url}/api/v1/firmware/download/{device_id}"
    
    def get_certificate_fingerprint(self, device_id: str) -> Optional[str]:
        """
        获取设备证书指纹（用于HTTPS OTA验证）
        
        Args:
            device_id: 设备ID
            
        Returns:
            证书指纹字符串，如果不存在则返回None
        """
        from app.services.firmware_encryption import FirmwareEncryptionService
        
        # 优先从服务器证书获取指纹（如果存在）
        try:
            from app.services.certificate import SERVER_CERT_PATH
            if SERVER_CERT_PATH and os.path.exists(SERVER_CERT_PATH):
                encryption_service = FirmwareEncryptionService()
                return encryption_service.get_certificate_fingerprint(str(SERVER_CERT_PATH))
        except Exception as e:
            logger.debug(f"从服务器证书获取指纹失败: {e}")
        
        # 如果服务器证书不存在，尝试从CA证书获取指纹
        try:
            from app.services.certificate import CA_CERT_PATH
            if CA_CERT_PATH and os.path.exists(CA_CERT_PATH):
                encryption_service = FirmwareEncryptionService()
                return encryption_service.get_certificate_fingerprint(str(CA_CERT_PATH))
        except Exception as e:
            logger.warning(f"获取证书指纹失败: {e}")
        
        return None
    
    def generate_ota_config(
        self,
        device_id: str,
        ssid: str,
        password: str,
        server_host: str,
        server_port: int = 443,
        use_https: bool = True,
        use_xor_mask: bool = True
    ) -> Dict[str, any]:
        """
        生成OTA配置信息
        
        Args:
            device_id: 设备ID
            ssid: WiFi SSID
            password: WiFi密码
            server_host: 服务器地址
            server_port: 服务器端口
            use_https: 是否使用HTTPS
            use_xor_mask: 是否使用XOR掩码
            
        Returns:
            OTA配置字典
        """
        config = {
            'device_id': device_id,
            'wifi': {
                'ssid': ssid,
                'password': password
            },
            'server': {
                'host': server_host,
                'port': server_port,
                'use_https': use_https
            },
            'firmware': {
                'url': self.get_firmware_url(device_id, use_xor_mask, server_host, server_port, use_https),
                'use_encryption': use_xor_mask
            }
        }
        
        # 如果使用HTTPS，添加证书指纹
        if use_https:
            fingerprint = self.get_certificate_fingerprint(device_id)
            if fingerprint:
                config['server']['certificate_fingerprint'] = fingerprint
        
        return config
    
    def validate_firmware_size(self, firmware_path: str, max_size_mb: float = 1.0) -> bool:
        """
        验证固件大小（ESP8266 OTA分区限制）
        
        Args:
            firmware_path: 固件路径
            max_size_mb: 最大大小（MB），默认1MB
            
        Returns:
            是否在限制范围内
        """
        firmware_path = Path(firmware_path)
        if not firmware_path.exists():
            return False
        
        size_mb = firmware_path.stat().st_size / (1024 * 1024)
        return size_mb <= max_size_mb

