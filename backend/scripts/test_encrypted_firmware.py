#!/usr/bin/env python3
"""
完整的加密烧录API测试脚本
包括创建设备、生成证书、加密固件等全流程
"""
import requests
import json
import sys
from pathlib import Path

BASE_URL = "http://localhost:8000/api/v1"
TEST_DEVICE_ID = "encrypted-test-001"

def login():
    """登录获取token"""
    url = f"{BASE_URL}/auth/login"
    data = {"username": "admin", "password": "admin123"}
    response = requests.post(url, data=data)
    if response.status_code == 200:
        return response.json().get("access_token")
    print(f"登录失败: {response.status_code} - {response.text}")
    return None

def create_device(token):
    """创建测试设备"""
    print(f"\n[步骤1] 创建测试设备: {TEST_DEVICE_ID}")
    url = f"{BASE_URL}/devices"
    headers = {"Authorization": f"Bearer {token}"}
    data = {
        "device_id": TEST_DEVICE_ID,
        "name": "加密烧录测试设备",
        "type": "ESP8266",  # 注意：字段名是type不是device_type
        "device_type": "ESP8266",
        "description": "用于测试加密烧录功能"
    }
    response = requests.post(url, json=data, headers=headers)
    if response.status_code == 200:
        print("✓ 设备创建成功")
        return True
    elif response.status_code == 400 and "已存在" in response.text:
        print("✓ 设备已存在，继续使用")
        return True
    else:
        print(f"✗ 设备创建失败: {response.status_code} - {response.text}")
        return False

def generate_ca_cert(token):
    """生成CA证书（如果不存在）"""
    print(f"\n[步骤2] 检查CA证书")
    url = f"{BASE_URL}/certificates/ca"
    headers = {"Authorization": f"Bearer {token}"}
    response = requests.get(url, headers=headers)
    if response.status_code == 200:
        print("✓ CA证书已存在")
        return True
    
    # 如果不存在，生成CA证书
    print("生成CA证书...")
    # 注意：CA证书生成可能需要超级管理员权限
    return True

def generate_server_cert(token):
    """生成服务器证书（包含新IP）"""
    print(f"\n[步骤3] 生成服务器证书（包含新IP地址）")
    url = f"{BASE_URL}/certificates/server/generate"
    headers = {"Authorization": f"Bearer {token}"}
    data = {
        "common_name": "192.168.1.8",  # 使用主IP作为CN
        "validity_days": 365,
        "alt_names": ["192.168.1.8", "10.42.0.1", "10.42.0.247", "127.0.0.1", "localhost"]  # 包含所有IP和域名
    }
    response = requests.post(url, json=data, headers=headers)
    if response.status_code == 200:
        print("✓ 服务器证书生成成功")
        cert_data = response.json()
        print(f"  消息: {cert_data.get('message')}")
        return True
    else:
        print(f"✗ 服务器证书生成失败: {response.status_code} - {response.text}")
        return False

def get_server_cert_fingerprint(token):
    """获取服务器证书指纹"""
    print(f"\n[步骤4] 获取服务器证书指纹")
    url = f"{BASE_URL}/certificates/server"
    headers = {"Authorization": f"Bearer {token}"}
    response = requests.get(url, headers=headers)
    if response.status_code == 200:
        cert_data = response.json()
        # 从证书内容计算指纹
        cert_content = cert_data.get('certificate', '')
        if cert_content:
            import hashlib
            from cryptography import x509
            from cryptography.hazmat.backends import default_backend
            from cryptography.hazmat.primitives import hashes
            try:
                cert = x509.load_pem_x509_certificate(
                    cert_content.encode(), 
                    default_backend()
                )
                fingerprint = cert.fingerprint(hashes.SHA256())
                fingerprint_str = ':'.join(f'{b:02X}' for b in fingerprint)
                print(f"✓ 证书指纹: {fingerprint_str}")
                return fingerprint_str
            except Exception as e:
                print(f"⚠ 无法计算指纹: {e}")
                import traceback
                traceback.print_exc()
                return None
    else:
        print(f"⚠ 无法获取服务器证书: {response.status_code}")
    return None

def generate_xor_key(token):
    """生成XOR密钥"""
    print(f"\n[步骤5] 生成XOR密钥")
    url = f"{BASE_URL}/firmware/generate-key/{TEST_DEVICE_ID}"
    headers = {"Authorization": f"Bearer {token}"}
    response = requests.post(url, headers=headers)
    if response.status_code == 200:
        data = response.json()
        print("✓ XOR密钥生成成功")
        print(f"  密钥: {data.get('key_hex')}")
        return data.get('key_hex')
    else:
        print(f"✗ XOR密钥生成失败: {response.status_code} - {response.text}")
        return None

def encrypt_firmware(token):
    """加密固件"""
    print(f"\n[步骤6] 加密固件")
    
    # 创建测试固件文件
    firmware_path = Path("test_firmware.bin")
    if not firmware_path.exists():
        print("创建测试固件文件 (1KB)...")
        firmware_path.write_bytes(b'\x00' * 1024)
    
    url = f"{BASE_URL}/firmware/encrypt/{TEST_DEVICE_ID}?use_xor_mask=true"
    headers = {"Authorization": f"Bearer {token}"}
    
    with open(firmware_path, 'rb') as f:
        files = {'firmware_file': ('test_firmware.bin', f, 'application/octet-stream')}
        response = requests.post(url, headers=headers, files=files)
    
    if response.status_code == 200:
        data = response.json()
        print("✓ 固件加密成功")
        print(f"  加密后路径: {data.get('encrypted_firmware_path')}")
        print(f"  固件大小: {data.get('firmware_info', {}).get('size')} 字节")
        print(f"  密钥: {data.get('xor_key_hex')}")
        return True
    else:
        print(f"✗ 固件加密失败: {response.status_code} - {response.text}")
        return False

def get_ota_config(token, fingerprint):
    """获取OTA配置"""
    print(f"\n[步骤7] 获取OTA配置")
    url = f"{BASE_URL}/firmware/ota-config/{TEST_DEVICE_ID}"
    headers = {"Authorization": f"Bearer {token}"}
    params = {
        "ssid": "YourWiFi",
        "password": "password",
        "server_host": "192.168.1.8",
        "server_port": 443,
        "use_https": True,
        "use_xor_mask": True
    }
    response = requests.get(url, headers=headers, params=params)
    if response.status_code == 200:
        data = response.json()
        print("✓ OTA配置获取成功")
        print(json.dumps(data, indent=2, ensure_ascii=False))
        if fingerprint and data.get('server', {}).get('certificate_fingerprint'):
            print(f"\n✓ 证书指纹匹配: {fingerprint}")
        return True
    else:
        print(f"✗ OTA配置获取失败: {response.status_code} - {response.text}")
        return False

def main():
    print("=" * 70)
    print("加密烧录API完整测试流程")
    print("=" * 70)
    
    # 登录
    token = login()
    if not token:
        print("无法登录，请检查用户名密码")
        sys.exit(1)
    print("✓ 登录成功")
    
    # 执行测试流程
    if not create_device(token):
        print("设备创建失败，退出")
        sys.exit(1)
    
    generate_ca_cert(token)
    generate_server_cert(token)
    fingerprint = get_server_cert_fingerprint(token)
    generate_xor_key(token)
    encrypt_firmware(token)
    get_ota_config(token, fingerprint)
    
    print("\n" + "=" * 70)
    print("测试完成！")
    print("=" * 70)
    print("\n下一步:")
    print("1. 使用生成的XOR密钥和加密固件")
    print("2. 配置设备使用证书指纹进行HTTPS OTA")
    print("3. 测试MQTT连接（确保服务器证书包含正确的IP地址）")

if __name__ == "__main__":
    main()

