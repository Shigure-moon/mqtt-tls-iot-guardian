#!/usr/bin/env python3
"""
测试远程固件构建和加密上传
验证：
1. 远程库安装（Arduino CLI）
2. 固件编译
3. 固件加密
4. OTA上传（可选）
"""
import sys
import json
import os
import time
from pathlib import Path

# 加载环境变量
from dotenv import load_dotenv
backend_dir = Path(__file__).parent.parent / "backend"
env_file = backend_dir / ".env"
if env_file.exists():
    load_dotenv(env_file)

# 添加backend目录到Python路径
if str(backend_dir) not in sys.path:
    sys.path.insert(0, str(backend_dir))

import asyncio
import aiohttp
from typing import Optional

# 配置
API_BASE_URL = os.getenv("API_BASE_URL", "http://localhost:8000")
API_PREFIX = "/api/v1"
TEST_USERNAME = os.getenv("TEST_USERNAME", "admin")
TEST_PASSWORD = os.getenv("TEST_PASSWORD", "admin123")
TEST_DEVICE_ID = "test-esp8266-001"
TEST_WIFI_SSID = "huawei9930"
TEST_WIFI_PASSWORD = "993056494a."


class FirmwareBuildTester:
    """固件构建测试器"""
    
    def __init__(self):
        self.base_url = f"{API_BASE_URL}{API_PREFIX}"
        self.token: Optional[str] = None
        self.session: Optional[aiohttp.ClientSession] = None
    
    async def __aenter__(self):
        timeout = aiohttp.ClientTimeout(total=300)  # 5分钟超时
        self.session = aiohttp.ClientSession(timeout=timeout)
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if self.session:
            await self.session.close()
    
    async def login(self) -> bool:
        """登录获取token"""
        print("\n" + "="*60)
        print("1. 登录获取认证token")
        print("="*60)
        
        try:
            async with self.session.post(
                f"{self.base_url}/auth/login",
                data={
                    "username": TEST_USERNAME,
                    "password": TEST_PASSWORD
                }
            ) as response:
                if response.status != 200:
                    text = await response.text()
                    print(f"❌ 登录失败: HTTP {response.status} - {text}")
                    return False
                data = await response.json()
                self.token = data.get("access_token")
                print(f"✅ 登录成功")
                print(f"   Token: {self.token[:20]}...")
                return True
        except Exception as e:
            print(f"❌ 登录失败: {e}")
            return False
    
    async def get_or_create_device(self) -> bool:
        """获取或创建设备"""
        print("\n" + "="*60)
        print("2. 检查/创建设备")
        print("="*60)
        
        headers = {"Authorization": f"Bearer {self.token}"}
        
        try:
            # 检查设备是否存在
            async with self.session.get(
                f"{self.base_url}/devices",
                headers=headers,
                params={"device_id": TEST_DEVICE_ID}
            ) as response:
                if response.status != 200:
                    text = await response.text()
                    print(f"❌ 获取设备列表失败: HTTP {response.status} - {text}")
                    return False
                
                devices = await response.json()
                device = None
                if isinstance(devices, list):
                    device = next((d for d in devices if d.get("device_id") == TEST_DEVICE_ID), None)
            
            if device:
                print(f"✅ 设备已存在: {TEST_DEVICE_ID}")
                print(f"   设备ID: {device.get('id')}")
                print(f"   设备名称: {device.get('name')}")
                return True
            else:
                # 创建设备
                print(f"📝 创建设备: {TEST_DEVICE_ID}")
                async with self.session.post(
                    f"{self.base_url}/devices",
                    headers=headers,
                    json={
                        "device_id": TEST_DEVICE_ID,
                        "name": "测试ESP8266设备",
                        "type": "ESP8266",
                        "description": "用于测试远程固件构建的设备"
                    }
                ) as response:
                    if response.status != 200:
                        text = await response.text()
                        print(f"❌ 创建设备失败: HTTP {response.status} - {text}")
                        return False
                    device = await response.json()
                    print(f"✅ 设备创建成功")
                    print(f"   设备ID: {device.get('id')}")
                    return True
        except Exception as e:
            print(f"❌ 设备操作失败: {e}")
            import traceback
            traceback.print_exc()
            return False
    
    async def get_template(self) -> Optional[str]:
        """获取可用的模板"""
        print("\n" + "="*60)
        print("3. 获取固件模板")
        print("="*60)
        
        headers = {"Authorization": f"Bearer {self.token}"}
        
        try:
            # 获取ESP8266模板列表
            async with self.session.get(
                f"{self.base_url}/templates/public/device-types/ESP8266/list",
                headers=headers
            ) as response:
                if response.status == 200:
                    templates = await response.json()
                    if templates:
                        template = templates[0]  # 使用第一个模板
                        print(f"✅ 找到模板: {template.get('name')} (版本: {template.get('version')})")
                        print(f"   模板ID: {template.get('id')}")
                        print(f"   描述: {template.get('description', 'N/A')}")
                        return template.get('id')
                    else:
                        print("⚠️  未找到可用模板，将使用默认模板")
                        return None
                else:
                    print(f"⚠️  获取模板失败: HTTP {response.status}，将使用默认模板")
                    return None
        except Exception as e:
            print(f"⚠️  获取模板失败: {e}，将使用默认模板")
            return None
    
    async def build_encrypted_firmware(self, template_id: Optional[str] = None) -> Optional[dict]:
        """构建加密固件"""
        print("\n" + "="*60)
        print("4. 构建加密固件（包含远程库安装、编译、加密）")
        print("="*60)
        
        headers = {"Authorization": f"Bearer {self.token}"}
        
        # 构建请求数据
        build_data = {
            "device_id": TEST_DEVICE_ID,
            "wifi_ssid": TEST_WIFI_SSID,
            "wifi_password": TEST_WIFI_PASSWORD,
            "mqtt_server": "10.42.0.1",
            "use_encryption": True,
            "template_id": template_id  # 如果提供了模板ID
        }
        
        print(f"📦 开始构建固件...")
        print(f"   设备ID: {TEST_DEVICE_ID}")
        print(f"   WiFi SSID: {TEST_WIFI_SSID}")
        print(f"   MQTT服务器: 10.42.0.1")
        print(f"   使用模板: {template_id or '默认模板'}")
        print(f"   远程库安装: 自动")
        print(f"   编译: 自动")
        print(f"   加密: 是")
        
        try:
            # 调用构建API（使用正确的端点）
            async with self.session.post(
                f"{self.base_url}/firmware/build/{TEST_DEVICE_ID}",
                headers=headers,
                json=build_data
            ) as response:
                if response.status != 200:
                    text = await response.text()
                    print(f"\n❌ 固件构建失败: HTTP {response.status}")
                    print(f"   错误详情: {text[:500]}")
                    return None
                result = await response.json()
            
            print(f"\n✅ 固件构建成功！")
            print(f"   状态: {result.get('status')}")
            print(f"   固件代码: {result.get('firmware_code_path', 'N/A')}")
            print(f"   编译输出: {result.get('firmware_bin_path', 'N/A')}")
            print(f"   加密固件: {result.get('encrypted_firmware_path', 'N/A')}")
            
            if result.get('xor_key_hex'):
                print(f"   加密密钥: {result.get('xor_key_hex')[:32]}...")
            
            # 显示构建日志摘要
            build_log = result.get('build_log', '')
            if build_log:
                lines = build_log.split('\n')
                important_lines = [l for l in lines if any(keyword in l.lower() for keyword in 
                    ['installing', 'installed', 'compiling', 'linking', 'success', 'error', 'warning', 'library', 'arduino-cli'])]
                if important_lines:
                    print(f"\n📋 构建日志摘要:")
                    for line in important_lines[-15:]:  # 显示最后15行重要日志
                        if line.strip():
                            print(f"   {line[:100]}")
            
            # 检查编译状态
            if not result.get('firmware_bin_path'):
                print(f"\n⚠️  注意: 固件未编译（可能arduino-cli未安装或编译失败）")
                print(f"   已生成加密固件，但可能基于.ino文件而非编译后的.bin文件")
            
            return result
        except Exception as e:
            print(f"\n❌ 固件构建失败: {e}")
            import traceback
            traceback.print_exc()
            return None
    
    async def push_ota_update(self, firmware_build_id: Optional[str] = None) -> bool:
        """推送OTA更新"""
        print("\n" + "="*60)
        print("5. 推送OTA更新（可选）")
        print("="*60)
        
        headers = {"Authorization": f"Bearer {self.token}"}
        
        try:
            ota_data = {
                "firmware_build_id": firmware_build_id
            }
            
            print(f"📤 推送OTA更新到设备: {TEST_DEVICE_ID}")
            async with self.session.post(
                f"{self.base_url}/firmware/ota-update/{TEST_DEVICE_ID}",
                headers=headers,
                json=ota_data
            ) as response:
                if response.status != 200:
                    text = await response.text()
                    print(f"⚠️  OTA推送失败: HTTP {response.status} - {text}")
                    return False
                result = await response.json()
            
            print(f"✅ OTA更新已推送")
            print(f"   任务ID: {result.get('id')}")
            print(f"   状态: {result.get('status')}")
            print(f"   固件URL: {result.get('firmware_url', 'N/A')}")
            
            return True
        except Exception as e:
            print(f"⚠️  OTA推送失败: {e}")
            print(f"   这可能是正常的，如果设备未连接或OTA功能未启用")
            return False
    
    async def check_ota_status(self) -> bool:
        """检查OTA更新状态"""
        print("\n" + "="*60)
        print("6. 检查OTA更新状态")
        print("="*60)
        
        headers = {"Authorization": f"Bearer {self.token}"}
        
        try:
            async with self.session.get(
                f"{self.base_url}/firmware/ota-update/{TEST_DEVICE_ID}/status",
                headers=headers
            ) as response:
                if response.status == 404:
                    print("ℹ️  暂无OTA更新任务")
                    return True
                
                if response.status != 200:
                    text = await response.text()
                    print(f"⚠️  检查OTA状态失败: HTTP {response.status} - {text}")
                    return False
                
                result = await response.json()
            
            print(f"📊 OTA更新状态:")
            print(f"   状态: {result.get('status')}")
            print(f"   进度: {result.get('progress', 'N/A')}")
            if result.get('error_message'):
                print(f"   错误: {result.get('error_message')}")
            
            return True
        except Exception as e:
            print(f"⚠️  检查OTA状态失败: {e}")
            return False


async def main():
    """主测试流程"""
    print("\n" + "="*60)
    print("远程固件构建和加密上传测试")
    print("="*60)
    print(f"API地址: {API_BASE_URL}")
    print(f"测试设备: {TEST_DEVICE_ID}")
    print("="*60)
    
    async with FirmwareBuildTester() as tester:
        # 1. 登录
        if not await tester.login():
            print("\n❌ 测试终止：登录失败")
            return
        
        # 2. 检查/创建设备
        if not await tester.get_or_create_device():
            print("\n❌ 测试终止：设备操作失败")
            return
        
        # 3. 获取模板
        template_id = await tester.get_template()
        
        # 4. 构建加密固件
        build_result = await tester.build_encrypted_firmware(template_id)
        
        if not build_result:
            print("\n❌ 测试终止：固件构建失败")
            return
        
        # 5. 可选：推送OTA更新
        firmware_build_id = build_result.get('firmware_build_id')
        if firmware_build_id:
            await tester.push_ota_update(firmware_build_id)
            await asyncio.sleep(2)  # 等待一下
            await tester.check_ota_status()
        
        print("\n" + "="*60)
        print("✅ 测试完成！")
        print("="*60)
        print("\n生成的文件:")
        if build_result.get('firmware_code_path'):
            print(f"  - 固件代码: {build_result.get('firmware_code_path')}")
        if build_result.get('firmware_bin_path'):
            print(f"  - 编译输出: {build_result.get('firmware_bin_path')}")
        if build_result.get('encrypted_firmware_path'):
            print(f"  - 加密固件: {build_result.get('encrypted_firmware_path')}")
        print("\n提示:")
        print("  - 检查后端日志以查看远程库安装过程")
        print("  - 检查编译日志以确认编译成功")
        print("  - 加密固件可用于OTA更新或手动烧录")


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n\n⚠️  测试被用户中断")
    except Exception as e:
        print(f"\n\n❌ 测试异常: {e}")
        import traceback
        traceback.print_exc()

