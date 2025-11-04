# 加密烧录API测试完整报告

## 测试时间
2025-11-04

## 测试环境
- **服务器IP**: 192.168.1.8 (MQTT Broker端口8883)
- **设备IP范围**: 10.42.0.x (新IP范围)
- **测试设备ID**: encrypted-test-001
- **设备类型**: ESP8266

## 测试结果总结

### ✅ 所有API端点测试通过

| API端点 | 方法 | 状态 | 说明 |
|---------|------|------|------|
| `/firmware/generate-key/{device_id}` | POST | ✅ | XOR密钥生成成功 |
| `/firmware/xor-key/{device_id}` | GET | ✅ | XOR密钥获取成功 |
| `/firmware/encrypt/{device_id}` | POST | ✅ | 固件加密成功 |
| `/firmware/ota-config/{device_id}` | GET | ✅ | OTA配置获取成功（包含证书指纹） |
| `/certificates/server/generate` | POST | ✅ | 服务器证书生成成功（包含新IP） |

## 详细测试结果

### 1. 设备创建 ✅
- **设备ID**: encrypted-test-001
- **设备名称**: 加密烧录测试设备
- **设备类型**: ESP8266

### 2. 服务器证书生成 ✅
- **状态**: 成功
- **Common Name**: 192.168.1.8
- **包含的IP地址**:
  - 192.168.1.8 (主服务器IP)
  - 10.42.0.1 (新IP范围起始)
  - 10.42.0.247 (设备IP)
  - 127.0.0.1 (本地回环)
  - localhost (域名)
- **证书指纹**: `87:EB:E4:F0:43:52:17:36:E8:A4:BC:BC:7D:A5:C2:F8:8B:87:E6:7D:05:9D:C4:29:FE:40:25:C9:57:01:F4:1F`

### 3. XOR密钥生成 ✅
- **密钥**: `1bf7b5d48ead4b3623f2e3c12c317bf6`
- **密钥长度**: 16字节 (128位)
- **密钥文件**: `data/firmware/keys/encrypted-test-001_key.txt`

### 4. 固件加密 ✅
- **原始固件大小**: 1024 字节
- **加密后路径**: `data/firmware/encrypted-test-001_masked.bin`
- **加密方式**: XOR掩码
- **密钥**: `1bf7b5d48ead4b3623f2e3c12c317bf6`

### 5. OTA配置获取 ✅
**完整配置**:
```json
{
  "device_id": "encrypted-test-001",
  "wifi": {
    "ssid": "YourWiFi",
    "password": "password"
  },
  "server": {
    "host": "192.168.1.8",
    "port": 443,
    "use_https": true,
    "certificate_fingerprint": "87:EB:E4:F0:43:52:17:36:E8:A4:BC:BC:7D:A5:C2:F8:8B:87:E6:7D:05:9D:C4:29:FE:40:25:C9:57:01:F4:1F"
  },
  "firmware": {
    "url": "https://your-server.com/firmware/encrypted-test-001_masked.bin",
    "use_encryption": true
  }
}
```

## API使用示例

### 1. 生成XOR密钥
```bash
curl -X POST "http://localhost:8000/api/v1/firmware/generate-key/encrypted-test-001" \
  -H "Authorization: Bearer <admin_token>"
```

**响应**:
```json
{
  "device_id": "encrypted-test-001",
  "key_hex": "1bf7b5d48ead4b3623f2e3c12c317bf6",
  "key_file": "/home/shigure/mqtt-tls-iot-guardian/data/firmware/keys/encrypted-test-001_key.txt",
  "message": "XOR密钥已生成并保存"
}
```

### 2. 加密固件
```bash
curl -X POST "http://localhost:8000/api/v1/firmware/encrypt/encrypted-test-001?use_xor_mask=true" \
  -H "Authorization: Bearer <token>" \
  -F "firmware_file=@firmware.bin"
```

**响应**:
```json
{
  "device_id": "encrypted-test-001",
  "encrypted_firmware_path": "/home/shigure/mqtt-tls-iot-guardian/data/firmware/encrypted-test-001_masked.bin",
  "firmware_info": {
    "size": 1024,
    "sha256": "...",
    "path": "...",
    "name": "encrypted-test-001_masked.bin"
  },
  "xor_key_file": "/home/shigure/mqtt-tls-iot-guardian/data/firmware/keys/encrypted-test-001_key.txt",
  "xor_key_hex": "1bf7b5d48ead4b3623f2e3c12c317bf6",
  "use_encryption": true
}
```

### 3. 获取OTA配置
```bash
curl -X GET "http://localhost:8000/api/v1/firmware/ota-config/encrypted-test-001?use_https=true&use_xor_mask=true&server_host=192.168.1.8" \
  -H "Authorization: Bearer <token>"
```

### 4. 获取XOR密钥（仅管理员）
```bash
curl -X GET "http://localhost:8000/api/v1/firmware/xor-key/encrypted-test-001" \
  -H "Authorization: Bearer <admin_token>"
```

## 命令行工具使用

### 应用XOR掩码
```bash
python backend/scripts/firmware_mask.py \
  -f firmware.bin \
  -k 1bf7b5d48ead4b3623f2e3c12c317bf6 \
  -o firmware_masked.bin
```

### 从密钥文件读取
```bash
python backend/scripts/firmware_mask.py \
  -f firmware.bin \
  -k $(cat data/firmware/keys/encrypted-test-001_key.txt) \
  -o firmware_masked.bin
```

### 移除掩码（解密）
```bash
python backend/scripts/firmware_mask.py \
  -f firmware_masked.bin \
  -k 1bf7b5d48ead4b3623f2e3c12c317bf6 \
  --decrypt
```

## MQTT连接问题解决

### 问题
- **错误码**: `rc=-2` (Connect failed)
- **原因**: 服务器证书不包含新的IP地址范围 (10.42.0.x)

### 解决方案
1. ✅ 重新生成服务器证书，包含所有需要的IP地址
2. ✅ 证书已包含: 192.168.1.8, 10.42.0.1, 10.42.0.247等
3. ⚠️ **需要重启Mosquitto服务**以加载新证书

### 下一步操作
```bash
# 1. 重启Mosquitto服务（如果使用systemd）
sudo systemctl restart mosquitto

# 或如果使用手动启动
# 停止当前Mosquitto进程
sudo pkill mosquitto

# 重新启动（使用新的证书）
mosquitto -c /path/to/mosquitto.conf
```

## 设备端配置

### Arduino代码中的证书指纹配置
```cpp
// 证书指纹（从OTA配置获取）
const char* cert_fingerprint = "87:EB:E4:F0:43:52:17:36:E8:A4:BC:BC:7D:A5:C2:F8:8B:87:E6:7D:05:9D:C4:29:FE:40:25:C9:57:01:F4:1F";

// XOR密钥（从key.txt文件获取）
const uint8_t XOR_KEY[16] = {
    0x1B, 0xF7, 0xB5, 0xD4, 0x8E, 0xAD, 0x4B, 0x36,
    0x23, 0xF2, 0xE3, 0xC1, 0x2C, 0x31, 0x7B, 0xF6
};

// OTA服务器配置
const char* ota_host = "192.168.1.8";
const int   ota_port = 443;
const char* ota_path = "/firmware/encrypted-test-001_masked.bin";

// 配置WiFi安全客户端
wifiSecure.setFingerprint(cert_fingerprint);
```

## 测试脚本

运行完整测试流程：
```bash
cd backend
python3 scripts/test_encrypted_firmware.py
```

## 注意事项

1. **服务器证书更新后**，必须重启Mosquitto服务才能生效
2. **XOR密钥**应妥善保管，丢失后无法解密固件
3. **证书指纹**用于HTTPS OTA验证，确保固件来源可信
4. **固件大小**限制在1MB以内（ESP8266 OTA分区限制）
5. **MQTT连接**：确保设备IP在证书的IP地址列表中

## 总结

✅ **所有加密烧录API接口测试通过**
✅ **服务器证书已包含新IP地址范围**
✅ **XOR密钥生成和加密功能正常**
✅ **OTA配置包含证书指纹**

**下一步**：
1. 重启Mosquitto服务加载新证书
2. 测试设备MQTT连接（应该可以成功）
3. 使用加密固件和OTA配置进行设备烧录

