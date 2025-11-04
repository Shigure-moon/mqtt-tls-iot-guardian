#!/bin/bash
# 重新生成服务器证书，包含10.42.0.1 IP地址

set -e

echo "=========================================="
echo "重新生成服务器证书（包含10.42.0.1）"
echo "=========================================="
echo ""

# 获取当前IP地址
CURRENT_IP=$(ip addr show | grep "inet 10.42" | awk '{print $2}' | cut -d'/' -f1)
if [ -z "$CURRENT_IP" ]; then
    CURRENT_IP="10.42.0.1"
fi

echo "检测到的IP地址: $CURRENT_IP"
echo ""

# 进入backend目录
cd "$(dirname "$0")/../backend" || exit 1

# 激活conda环境（如果需要）
if command -v conda &> /dev/null; then
    eval "$(conda shell.bash hook)"
    conda activate iot-security 2>/dev/null || echo "conda环境未激活，继续..."
fi

# 运行Python脚本生成新证书
python3 << EOF
import sys
sys.path.insert(0, '.')

from app.services.certificate import CertificateService
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

try:
    # 生成包含多个IP地址的服务器证书
    server_key, server_cert = CertificateService.generate_server_certificate(
        common_name="$CURRENT_IP",
        alt_names=["10.42.0.1", "192.168.1.8", "localhost", "127.0.0.1"],
        validity_days=365
    )
    
    # 保存证书
    from pathlib import Path
    cert_dir = Path("../data/certs")
    cert_dir.mkdir(parents=True, exist_ok=True)
    
    (cert_dir / "server.key").write_text(server_key)
    (cert_dir / "server.crt").write_text(server_cert)
    
    print(f"\n✅ 服务器证书已生成并保存到: {cert_dir}")
    print(f"   证书CN: $CURRENT_IP")
    print(f"   SAN包含: 10.42.0.1, 192.168.1.8, localhost, 127.0.0.1")
    print("\n⚠️  注意: 需要配置EMQX使用新证书，并重启EMQX服务")
    
except Exception as e:
    print(f"\n❌ 生成证书失败: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
EOF

echo ""
echo "=========================================="
echo "证书生成完成"
echo "=========================================="

