#!/usr/bin/env python3
"""
初始化证书
生成CA证书和MQTT服务器证书
"""
import sys
from pathlib import Path

# 添加backend目录到Python路径
backend_dir = Path(__file__).parent.parent
if str(backend_dir) not in sys.path:
    sys.path.insert(0, str(backend_dir))

from app.services.certificate import CertificateService
from app.core.config import settings
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def init_certificates():
    """初始化证书"""
    try:
        logger.info("正在生成CA证书...")
        ca_key, ca_cert = CertificateService.generate_ca_certificate()
        logger.info("CA证书生成成功！")
        
        logger.info("正在生成MQTT服务器证书...")
        # 获取MQTT服务器IP
        mqtt_host = settings.MQTT_BROKER_HOST
        logger.info(f"MQTT服务器地址: {mqtt_host}")
        
        # 为IP地址生成服务器证书
        server_key, server_cert = CertificateService.generate_server_certificate(
            common_name=mqtt_host,
            alt_names=[mqtt_host],  # 添加IP到SAN
            validity_days=365
        )
        logger.info("MQTT服务器证书生成成功！")
        
        # 保存证书到文件
        cert_dir = Path("data/certs")
        cert_dir.mkdir(parents=True, exist_ok=True)
        
        # 保存CA证书
        ca_cert_path = cert_dir / "ca.crt"
        with open(ca_cert_path, "w") as f:
            f.write(ca_cert)
        logger.info(f"CA证书已保存到: {ca_cert_path}")
        
        # 保存CA私钥
        ca_key_path = cert_dir / "ca.key"
        with open(ca_key_path, "w") as f:
            f.write(ca_key)
        logger.info(f"CA私钥已保存到: {ca_key_path}")
        
        # 保存服务器证书
        server_cert_path = cert_dir / "server.crt"
        with open(server_cert_path, "w") as f:
            f.write(server_cert)
        logger.info(f"服务器证书已保存到: {server_cert_path}")
        
        # 保存服务器私钥
        server_key_path = cert_dir / "server.key"
        with open(server_key_path, "w") as f:
            f.write(server_key)
        logger.info(f"服务器私钥已保存到: {server_key_path}")
        
        logger.info("\n证书初始化完成！")
        logger.info("现在可以配置MQTT服务器使用这些证书。")
        
    except Exception as e:
        logger.error(f"证书初始化失败: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    init_certificates()

