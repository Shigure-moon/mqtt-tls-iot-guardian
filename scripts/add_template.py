#!/usr/bin/env python3
"""
添加固件模板到数据库
使用shili_encrypted.ino作为模板
"""
import sys
import json
import os
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
from app.core.database import get_db
from app.services.template import TemplateService
from app.schemas.template import DeviceTemplateCreate
from app.services.certificate import CertificateService
from sqlalchemy.ext.asyncio import AsyncSession


async def add_template():
    """添加模板到数据库"""
    # 读取模板文件
    template_file = Path(__file__).parent.parent / "shili_encrypted" / "shili_encrypted.ino"
    
    if not template_file.exists():
        print(f"错误: 模板文件不存在: {template_file}")
        return
    
    # 读取模板内容
    template_code = template_file.read_text(encoding='utf-8')
    
    # 替换硬编码值为占位符
    import re
    
    # 替换设备ID定义
    template_code = re.sub(r'#define DEVICE_ID\s+"esp8266"', '#define DEVICE_ID "{device_id}"', template_code)
    template_code = re.sub(r'#define DEVICE_NAME\s+"esp8266"', '#define DEVICE_NAME "{device_name}"', template_code)
    
    # 替换WiFi配置
    template_code = re.sub(r'const char\*\s+ssid\s*=\s*"huawei9930"', 'const char* ssid = "{wifi_ssid}"', template_code)
    template_code = re.sub(r'const char\*\s+password\s*=\s*"993056494a\."', 'const char* password = "{wifi_password}"', template_code)
    
    # 替换MQTT配置
    template_code = re.sub(r'const char\*\s+mqtt_server\s*=\s*"10\.42\.0\.1"', 'const char* mqtt_server = "{mqtt_server}"', template_code)
    template_code = re.sub(r'const char\*\s+mqtt_user\s*=\s*"admin"', 'const char* mqtt_user = "{mqtt_username}"', template_code)
    template_code = re.sub(r'const char\*\s+mqtt_pass\s*=\s*"admin"', 'const char* mqtt_pass = "{mqtt_password}"', template_code)
    
    # 获取CA证书并替换为占位符
    # 匹配CA证书部分（从-----BEGIN CERTIFICATE-----到-----END CERTIFICATE-----）
    ca_cert_pattern = r'-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----'
    template_code = re.sub(ca_cert_pattern, '{ca_cert}', template_code, flags=re.DOTALL)
    
    # 所需库列表
    required_libraries = [
        "ESP8266WiFi",
        "WiFiClientSecureBearSSL", 
        "PubSubClient",
        "ArduinoJson",
        "Adafruit_GFX",
        "Adafruit_ILI9341"
    ]
    
    # 创建模板
    template_data = DeviceTemplateCreate(
        name="ESP8266-ILI9341",
        version="v1",
        device_type="ESP8266",
        description="ESP8266设备固件模板，支持ILI9341屏幕显示、MQTT over TLS通信、传感器数据采集和心跳上报",
        template_code=template_code,
        required_libraries=json.dumps(required_libraries, ensure_ascii=False),
        is_active=True
    )
    
    # 获取数据库会话
    async for db in get_db():
        template_service = TemplateService(db)
        
        # 检查模板是否已存在（按名称）
        from sqlalchemy import select
        from app.models.template import DeviceTemplate
        
        result = await db.execute(
            select(DeviceTemplate).filter(
                DeviceTemplate.name == "ESP8266-ILI9341"
            )
        )
        existing = result.scalar_one_or_none()
        
        if existing:
            print(f"模板 'ESP8266-ILI9341' 已存在（版本: {getattr(existing, 'version', 'N/A')}）")
            print("如需添加新版本，请使用不同的版本号或名称")
            return
        
        # 创建模板
        template = await template_service.create(template_data, created_by=None)
        
        print(f"✅ 模板已成功创建！")
        print(f"   模板ID: {template.id}")
        print(f"   名称: {template.name}")
        print(f"   版本: {template.version}")
        print(f"   设备类型: {template.device_type}")
        print(f"   所需库: {', '.join(required_libraries)}")
        break  # 只执行一次


if __name__ == "__main__":
    asyncio.run(add_template())

