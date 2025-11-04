#!/usr/bin/env python3
"""
测试固件加密烧录API接口
"""
import requests
import json
import sys
import os
from pathlib import Path

# API基础URL
BASE_URL = "http://localhost:8000/api/v1"

# 测试用的设备ID
TEST_DEVICE_ID = "test-esp8266-001"

def get_auth_token():
    """获取认证token"""
    login_url = f"{BASE_URL}/auth/login"
    login_data = {
        "username": "admin",
        "password": "admin123"  # 默认密码，根据实际情况修改
    }
    
    try:
        response = requests.post(login_url, data=login_data)
        if response.status_code == 200:
            data = response.json()
            return data.get("access_token")
        else:
            print(f"登录失败: {response.status_code} - {response.text}")
            return None
    except Exception as e:
        print(f"登录错误: {e}")
        return None

def test_ota_config(device_id, token):
    """测试获取OTA配置"""
    print(f"\n[测试] 获取OTA配置 - {device_id}")
    url = f"{BASE_URL}/firmware/ota-config/{device_id}"
    headers = {"Authorization": f"Bearer {token}"}
    
    try:
        response = requests.get(url, headers=headers, params={
            "use_https": True,
            "use_xor_mask": True
        })
        print(f"状态码: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print("✓ OTA配置获取成功:")
            print(json.dumps(data, indent=2, ensure_ascii=False))
            return True
        else:
            print(f"✗ 失败: {response.text}")
            return False
    except Exception as e:
        print(f"✗ 错误: {e}")
        return False

def test_generate_key(device_id, token):
    """测试生成XOR密钥"""
    print(f"\n[测试] 生成XOR密钥 - {device_id}")
    url = f"{BASE_URL}/firmware/generate-key/{device_id}"
    headers = {"Authorization": f"Bearer {token}"}
    
    try:
        response = requests.post(url, headers=headers)
        print(f"状态码: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print("✓ XOR密钥生成成功:")
            print(json.dumps(data, indent=2, ensure_ascii=False))
            return data.get("key_hex")
        else:
            print(f"✗ 失败: {response.text}")
            return None
    except Exception as e:
        print(f"✗ 错误: {e}")
        return None

def test_get_key(device_id, token):
    """测试获取XOR密钥"""
    print(f"\n[测试] 获取XOR密钥 - {device_id}")
    url = f"{BASE_URL}/firmware/xor-key/{device_id}"
    headers = {"Authorization": f"Bearer {token}"}
    
    try:
        response = requests.get(url, headers=headers)
        print(f"状态码: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print("✓ XOR密钥获取成功:")
            print(json.dumps(data, indent=2, ensure_ascii=False))
            return True
        else:
            print(f"✗ 失败: {response.text}")
            return False
    except Exception as e:
        print(f"✗ 错误: {e}")
        return False

def test_encrypt_firmware(device_id, token, firmware_path=None):
    """测试加密固件"""
    print(f"\n[测试] 加密固件 - {device_id}")
    url = f"{BASE_URL}/firmware/encrypt/{device_id}?use_xor_mask=true"
    headers = {"Authorization": f"Bearer {token}"}
    
    # 如果没有提供固件文件，创建一个测试文件
    if firmware_path is None:
        firmware_path = Path("test_firmware.bin")
        if not firmware_path.exists():
            print(f"创建测试固件文件: {firmware_path}")
            # 创建一个1KB的测试固件
            firmware_path.write_bytes(b'\x00' * 1024)
    
    if not Path(firmware_path).exists():
        print(f"✗ 固件文件不存在: {firmware_path}")
        return False
    
    try:
        with open(firmware_path, 'rb') as f:
            files = {'firmware_file': (Path(firmware_path).name, f, 'application/octet-stream')}
            response = requests.post(url, headers=headers, files=files)
        
        print(f"状态码: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print("✓ 固件加密成功:")
            print(json.dumps(data, indent=2, ensure_ascii=False))
            return True
        else:
            print(f"✗ 失败: {response.text}")
            return False
    except Exception as e:
        print(f"✗ 错误: {e}")
        import traceback
        traceback.print_exc()
        return False

def main():
    print("=" * 60)
    print("固件加密烧录API测试")
    print("=" * 60)
    
    # 1. 登录获取token
    print("\n[步骤1] 登录获取认证token...")
    token = get_auth_token()
    if not token:
        print("✗ 无法获取认证token，请检查用户名密码")
        sys.exit(1)
    print("✓ 登录成功")
    
    # 2. 测试获取OTA配置
    if not test_ota_config(TEST_DEVICE_ID, token):
        print("\n⚠ 注意: 设备可能不存在，但这不影响OTA配置API的测试")
    
    # 3. 测试生成XOR密钥
    key_hex = test_generate_key(TEST_DEVICE_ID, token)
    
    # 4. 测试获取XOR密钥
    if key_hex:
        test_get_key(TEST_DEVICE_ID, token)
    
    # 5. 测试加密固件
    test_encrypt_firmware(TEST_DEVICE_ID, token)
    
    print("\n" + "=" * 60)
    print("测试完成")
    print("=" * 60)

if __name__ == "__main__":
    main()

