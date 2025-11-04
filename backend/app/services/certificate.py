"""
证书管理服务
支持CA证书、服务器证书和客户端证书的生成和管理
"""
import os
import ipaddress
from datetime import datetime, timedelta
from pathlib import Path
from typing import Optional, Tuple
from cryptography import x509
from cryptography.x509.oid import NameOID, ExtendedKeyUsageOID
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.backends import default_backend
import uuid

from app.core.config import settings

# 证书存储目录
# 使用绝对路径，基于项目根目录
# 方法：从backend目录向上找到项目根目录（包含data目录的目录）
import os
import logging

logger = logging.getLogger(__name__)

# 获取backend目录（当前文件所在目录的父目录的父目录）
try:
    _file_path = Path(__file__).resolve()
    # backend/app/services/certificate.py -> backend
    BACKEND_DIR = _file_path.parent.parent.parent
except NameError:
    # 如果__file__不存在，使用当前工作目录
    BACKEND_DIR = Path.cwd()

# 项目根目录：backend的父目录
PROJECT_ROOT = BACKEND_DIR.parent

# 尝试多个可能的证书目录位置
possible_cert_dirs = [
    PROJECT_ROOT / "data" / "certs",  # 项目根目录/data/certs
    BACKEND_DIR / "data" / "certs",   # backend/data/certs（向后兼容）
    Path("/home/shigure/mqtt-tls-iot-guardian/data/certs"),  # 硬编码路径（备用）
]

CERT_DIR = None
for cert_dir in possible_cert_dirs:
    if cert_dir.exists() or cert_dir.parent.exists():
        CERT_DIR = cert_dir
        break

# 如果都找不到，使用项目根目录下的data/certs
if CERT_DIR is None:
    CERT_DIR = PROJECT_ROOT / "data" / "certs"

# 创建目录，确保有写权限
try:
    CERT_DIR.mkdir(parents=True, exist_ok=True)
    # 确保目录有写权限
    if not os.access(CERT_DIR, os.W_OK):
        logger.warning(f"证书目录 {CERT_DIR} 没有写权限，尝试修复权限...")
        # 尝试修复权限（如果可能）
        try:
            import stat
            current_mode = os.stat(CERT_DIR).st_mode
            os.chmod(CERT_DIR, current_mode | stat.S_IWUSR | stat.S_IWGRP)
            logger.info(f"已修复证书目录权限: {CERT_DIR}")
        except PermissionError:
            logger.warning(f"无法修复证书目录权限，请手动设置: sudo chmod 755 {CERT_DIR}")
            # 尝试使用backend/data/certs作为备用
            backup_cert_dir = BACKEND_DIR / "data" / "certs"
            if backup_cert_dir.exists() or backup_cert_dir.parent.exists():
                backup_cert_dir.mkdir(parents=True, exist_ok=True)
                if os.access(backup_cert_dir, os.W_OK):
                    logger.info(f"使用备用证书目录: {backup_cert_dir}")
                    CERT_DIR = backup_cert_dir
except Exception as e:
    logger.error(f"创建证书目录失败: {e}")
    # 使用backend/data/certs作为备用
    CERT_DIR = BACKEND_DIR / "data" / "certs"
    CERT_DIR.mkdir(parents=True, exist_ok=True)
    logger.info(f"使用备用证书目录: {CERT_DIR}")

# 定义证书文件路径（在CERT_DIR确定后）
CA_KEY_PATH = CERT_DIR / "ca.key"
CA_CERT_PATH = CERT_DIR / "ca.crt"
SERVER_KEY_PATH = CERT_DIR / "server.key"
SERVER_CERT_PATH = CERT_DIR / "server.crt"
SERVER_CSR_PATH = CERT_DIR / "server.csr"


class CertificateService:
    """证书管理服务"""
    
    @staticmethod
    def _load_or_create_ca_key():
        """加载或创建CA私钥"""
        if CA_KEY_PATH.exists():
            with open(CA_KEY_PATH, "rb") as f:
                return serialization.load_pem_private_key(
                    f.read(), 
                    password=None, 
                    backend=default_backend()
                )
        else:
            private_key = rsa.generate_private_key(
                public_exponent=65537,
                key_size=2048,
                backend=default_backend()
            )
            with open(CA_KEY_PATH, "wb") as f:
                f.write(private_key.private_bytes(
                    encoding=serialization.Encoding.PEM,
                    format=serialization.PrivateFormat.TraditionalOpenSSL,
                    encryption_algorithm=serialization.NoEncryption()
                ))
            return private_key
    
    @staticmethod
    def _load_or_create_ca_cert():
        """加载或创建CA证书"""
        import logging
        logger = logging.getLogger(__name__)
        
        if CA_CERT_PATH.exists():
            try:
                with open(CA_CERT_PATH, "rb") as f:
                    return x509.load_pem_x509_certificate(f.read(), default_backend())
            except Exception as e:
                logger.error(f"加载CA证书失败: {e}", exc_info=True)
                raise ValueError(f"无法加载CA证书: {str(e)}")
        else:
            # 创建自签名CA证书
            ca_key = CertificateService._load_or_create_ca_key()
            
            subject = issuer = x509.Name([
                x509.NameAttribute(NameOID.COUNTRY_NAME, "CN"),
                x509.NameAttribute(NameOID.STATE_OR_PROVINCE_NAME, "Beijing"),
                x509.NameAttribute(NameOID.LOCALITY_NAME, "Beijing"),
                x509.NameAttribute(NameOID.ORGANIZATION_NAME, "IoT Security Platform"),
                x509.NameAttribute(NameOID.COMMON_NAME, "IoT CA"),
            ])
            
            ca_cert = x509.CertificateBuilder().subject_name(
                subject
            ).issuer_name(
                issuer
            ).public_key(
                ca_key.public_key()
            ).serial_number(
                x509.random_serial_number()
            ).not_valid_before(
                datetime.utcnow()
            ).not_valid_after(
                datetime.utcnow() + timedelta(days=365*10)  # 10年有效期
            ).add_extension(
                x509.SubjectAlternativeName([
                    x509.DNSName("iot-ca.local"),
                ]),
                critical=False,
            ).add_extension(
                x509.BasicConstraints(ca=True, path_length=None),
                critical=True,
            ).add_extension(
                x509.KeyUsage(
                    key_cert_sign=True,
                    crl_sign=True,
                    digital_signature=True,
                    key_encipherment=False,
                    content_commitment=False,
                    data_encipherment=False,
                    key_agreement=False,
                    encipher_only=False,
                    decipher_only=False
                ),
                critical=True,
            ).sign(ca_key, hashes.SHA256(), default_backend())
            
            with open(CA_CERT_PATH, "wb") as f:
                f.write(ca_cert.public_bytes(serialization.Encoding.PEM))
            
            return ca_cert
    
    @staticmethod
    def generate_ca_certificate() -> Tuple[str, str]:
        """
        生成CA证书
        返回: (ca_key_pem, ca_cert_pem)
        """
        ca_key = CertificateService._load_or_create_ca_key()
        ca_cert = CertificateService._load_or_create_ca_cert()
        
        ca_key_pem = ca_key.private_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PrivateFormat.TraditionalOpenSSL,
            encryption_algorithm=serialization.NoEncryption()
        ).decode('utf-8')
        
        ca_cert_pem = ca_cert.public_bytes(serialization.Encoding.PEM).decode('utf-8')
        
        return ca_key_pem, ca_cert_pem
    
    @staticmethod
    def generate_server_certificate(
        common_name: str = "mosquitto-broker",
        alt_names: Optional[list] = None,
        validity_days: int = 365
    ) -> Tuple[str, str]:
        """
        生成服务器证书
        
        Args:
            common_name: 服务器的Common Name
            alt_names: 额外的主机名列表（如IP地址、域名）
            validity_days: 证书有效期（天）
        
        返回: (server_key_pem, server_cert_pem)
        """
        import logging
        logger = logging.getLogger(__name__)
        
        try:
            # 加载CA证书和私钥
            ca_key = CertificateService._load_or_create_ca_key()
            ca_cert = CertificateService._load_or_create_ca_cert()
        except Exception as e:
            logger.error(f"加载CA证书失败: {e}", exc_info=True)
            raise ValueError(f"无法加载CA证书，请先生成CA证书: {str(e)}")
        
        # 生成服务器私钥
        server_key = rsa.generate_private_key(
            public_exponent=65537,
            key_size=2048,
            backend=default_backend()
        )
        
        # 构建主题
        subject = x509.Name([
            x509.NameAttribute(NameOID.COUNTRY_NAME, "CN"),
            x509.NameAttribute(NameOID.STATE_OR_PROVINCE_NAME, "Beijing"),
            x509.NameAttribute(NameOID.LOCALITY_NAME, "Beijing"),
            x509.NameAttribute(NameOID.ORGANIZATION_NAME, "IoT Security Platform"),
            x509.NameAttribute(NameOID.COMMON_NAME, common_name),
        ])
        
        # 构建服务器证书
        builder = x509.CertificateBuilder()
        builder = builder.subject_name(subject)
        builder = builder.issuer_name(ca_cert.subject)
        builder = builder.public_key(server_key.public_key())
        builder = builder.serial_number(x509.random_serial_number())
        builder = builder.not_valid_before(datetime.utcnow())
        builder = builder.not_valid_after(
            datetime.utcnow() + timedelta(days=validity_days)
        )
        
        # 添加SAN扩展
        san_list = []
        # 尝试判断common_name是IP还是域名
        try:
            ip_addr = ipaddress.ip_address(common_name)
            san_list.append(x509.IPAddress(ip_addr))
        except ValueError:
            san_list.append(x509.DNSName(common_name))
        
        if alt_names:
            for alt_name in alt_names:
                try:
                    ip_addr = ipaddress.ip_address(alt_name)
                    san_list.append(x509.IPAddress(ip_addr))
                except ValueError:
                    san_list.append(x509.DNSName(alt_name))
        
        builder = builder.add_extension(
            x509.SubjectAlternativeName(san_list),
            critical=False,
        )
        
        # 添加扩展密钥用法
        builder = builder.add_extension(
            x509.ExtendedKeyUsage([
                ExtendedKeyUsageOID.SERVER_AUTH,
            ]),
            critical=True,
        )
        
        # 添加密钥用法
        builder = builder.add_extension(
            x509.KeyUsage(
                key_cert_sign=False,
                crl_sign=False,
                digital_signature=True,
                key_encipherment=True,
                content_commitment=False,
                data_encipherment=True,
                key_agreement=False,
                encipher_only=False,
                decipher_only=False
            ),
            critical=True,
        )
        
        # 添加基本约束
        builder = builder.add_extension(
            x509.BasicConstraints(ca=False, path_length=None),
            critical=True,
        )
        
        # 签名
        server_cert = builder.sign(ca_key, hashes.SHA256(), default_backend())
        
        # 转换为PEM格式
        server_key_pem = server_key.private_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PrivateFormat.TraditionalOpenSSL,
            encryption_algorithm=serialization.NoEncryption()
        ).decode('utf-8')
        
        server_cert_pem = server_cert.public_bytes(serialization.Encoding.PEM).decode('utf-8')
        
        # 保存到文件
        try:
            with open(SERVER_KEY_PATH, "w") as f:
                f.write(server_key_pem)
            
            with open(SERVER_CERT_PATH, "w") as f:
                f.write(server_cert_pem)
            logger.info(f"服务器证书已保存到: {SERVER_CERT_PATH}")
        except Exception as e:
            logger.error(f"保存服务器证书文件失败: {e}，路径: {SERVER_CERT_PATH}", exc_info=True)
            # 即使保存失败，也返回证书内容
            # 这样用户仍可以使用证书，只是没有保存到文件
        
        return server_key_pem, server_cert_pem
    
    @staticmethod
    def generate_client_certificate(
        device_id: str,
        common_name: Optional[str] = None,
        validity_days: int = 365
    ) -> Tuple[str, str, str]:
        """
        生成客户端证书
        
        Args:
            device_id: 设备ID
            common_name: Common Name，默认使用device_id
            validity_days: 证书有效期（天）
        
        返回: (client_key_pem, client_cert_pem, serial_number)
        """
        if common_name is None:
            common_name = f"device-{device_id}"
        
        # 加载CA证书和私钥
        ca_key = CertificateService._load_or_create_ca_key()
        ca_cert = CertificateService._load_or_create_ca_cert()
        
        # 生成客户端私钥
        client_key = rsa.generate_private_key(
            public_exponent=65537,
            key_size=2048,
            backend=default_backend()
        )
        
        # 构建主题
        subject = x509.Name([
            x509.NameAttribute(NameOID.COUNTRY_NAME, "CN"),
            x509.NameAttribute(NameOID.STATE_OR_PROVINCE_NAME, "Beijing"),
            x509.NameAttribute(NameOID.LOCALITY_NAME, "Beijing"),
            x509.NameAttribute(NameOID.ORGANIZATION_NAME, "IoT Security Platform"),
            x509.NameAttribute(NameOID.COMMON_NAME, common_name),
        ])
        
        # 生成序列号
        serial_number = str(uuid.uuid4())
        
        # 构建客户端证书
        builder = x509.CertificateBuilder()
        builder = builder.subject_name(subject)
        builder = builder.issuer_name(ca_cert.subject)
        builder = builder.public_key(client_key.public_key())
        builder = builder.serial_number(int(serial_number.replace('-', '')[:18], 16))  # 转换UUID为证书序列号
        builder = builder.not_valid_before(datetime.utcnow())
        builder = builder.not_valid_after(
            datetime.utcnow() + timedelta(days=validity_days)
        )
        
        # 添加SAN扩展
        builder = builder.add_extension(
            x509.SubjectAlternativeName([
                x509.DNSName(common_name),
                x509.DNSName(f"device-{device_id}"),
            ]),
            critical=False,
        )
        
        # 添加扩展密钥用法
        builder = builder.add_extension(
            x509.ExtendedKeyUsage([
                ExtendedKeyUsageOID.CLIENT_AUTH,
            ]),
            critical=True,
        )
        
        # 添加密钥用法
        builder = builder.add_extension(
            x509.KeyUsage(
                key_cert_sign=False,
                crl_sign=False,
                digital_signature=True,
                key_encipherment=True,
                content_commitment=False,
                data_encipherment=True,
                key_agreement=False,
                encipher_only=False,
                decipher_only=False
            ),
            critical=True,
        )
        
        # 添加基本约束
        builder = builder.add_extension(
            x509.BasicConstraints(ca=False, path_length=None),
            critical=True,
        )
        
        # 签名
        client_cert = builder.sign(ca_key, hashes.SHA256(), default_backend())
        
        # 转换为PEM格式
        client_key_pem = client_key.private_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PrivateFormat.TraditionalOpenSSL,
            encryption_algorithm=serialization.NoEncryption()
        ).decode('utf-8')
        
        client_cert_pem = client_cert.public_bytes(serialization.Encoding.PEM).decode('utf-8')
        
        return client_key_pem, client_cert_pem, serial_number
    
    @staticmethod
    def revoke_certificate(serial_number: str, reason: Optional[str] = None) -> bool:
        """
        吊销证书
        
        Args:
            serial_number: 证书序列号
            reason: 吊销原因
        
        返回: 是否成功
        """
        # TODO: 实现CRL（证书吊销列表）功能
        # 这里只是简单标记
        return True
    
    @staticmethod
    def verify_certificate(cert_pem: str) -> Tuple[bool, Optional[str]]:
        """
        验证证书有效性
        
        Args:
            cert_pem: 证书PEM格式字符串
        
        返回: (是否有效, 错误信息)
        """
        try:
            cert = x509.load_pem_x509_certificate(
                cert_pem.encode('utf-8'), 
                default_backend()
            )
            
            ca_cert = CertificateService._load_or_create_ca_cert()
            
            # 检查有效期（使用UTC感知的datetime）
            from datetime import timezone
            now = datetime.now(timezone.utc)
            if cert.not_valid_after_utc < now:
                return False, "证书已过期"
            
            if cert.not_valid_before_utc > now:
                return False, "证书尚未生效"
            
            # 验证签名
            # 这里简化处理，实际应该验证完整的证书链
            return True, None
            
        except Exception as e:
            return False, str(e)
    
    @staticmethod
    def get_ca_certificate() -> Optional[str]:
        """
        获取CA证书
        
        返回: CA证书PEM格式字符串
        """
        if CA_CERT_PATH.exists():
            with open(CA_CERT_PATH, "r") as f:
                return f.read()
        return None

