# 固件加密烧录模块文档

## 概述

本模块实现了ESP8266设备的加密烧录功能，包括：
1. **XOR掩码加密**：防止固件被直接反汇编
2. **HTTPS OTA更新**：传输加密，防止抓包获取固件

## 功能特性

### 1. XOR掩码加密
- 生成16字节（128位）随机密钥
- 对固件二进制文件进行XOR掩码处理
- 密钥独立存储，每个设备使用不同密钥
- 支持密钥的生成、保存和加载

### 2. HTTPS OTA更新
- 使用HTTPS协议传输固件
- 证书指纹验证，确保固件来源可信
- 自动检查并更新固件
- 支持固件大小验证（ESP8266限制1MB）

## API接口

### 1. 加密固件
```http
POST /api/v1/firmware/encrypt/{device_id}?use_xor_mask=true
Content-Type: multipart/form-data

firmware_file: <固件文件>
```

**响应：**
```json
{
  "device_id": "esp8266-001",
  "encrypted_firmware_path": "data/firmware/esp8266-001_masked.bin",
  "firmware_info": {
    "size": 524288,
    "sha256": "...",
    "path": "...",
    "name": "esp8266-001_masked.bin"
  },
  "xor_key_file": "data/firmware/keys/esp8266-001_key.txt",
  "xor_key_hex": "aabbccdd...",
  "use_encryption": true
}
```

### 2. 获取OTA配置
```http
GET /api/v1/firmware/ota-config/{device_id}?use_https=true&use_xor_mask=true
```

**响应：**
```json
{
  "device_id": "esp8266-001",
  "wifi": {
    "ssid": "YourWiFi",
    "password": "password"
  },
  "server": {
    "host": "192.168.1.100",
    "port": 443,
    "use_https": true,
    "certificate_fingerprint": "AA:BB:CC:DD:..."
  },
  "firmware": {
    "url": "https://192.168.1.100/firmware/esp8266-001_masked.bin",
    "use_encryption": true
  }
}
```

### 3. 获取XOR密钥（仅超级管理员）
```http
GET /api/v1/firmware/xor-key/{device_id}
```

### 4. 生成XOR密钥（仅超级管理员）
```http
POST /api/v1/firmware/generate-key/{device_id}
```

## 使用流程

### 方案一：HTTPS OTA（推荐用于现场升级）

1. **生成CA证书和服务器证书**
   ```bash
   # 生成CA证书
   openssl req -newkey rsa:2048 -nodes -keyout ca.key -x509 -days 3650 -out ca.crt
   
   # 获取证书指纹
   openssl x509 -fingerprint -sha256 -noout -in ca.crt
   ```

2. **生成加密固件**
   ```bash
   # 通过API上传固件并加密
   curl -X POST "http://localhost:8000/api/v1/firmware/encrypt/esp8266-001" \
     -H "Authorization: Bearer <token>" \
     -F "firmware_file=@firmware.bin" \
     -F "use_xor_mask=true"
   ```

3. **配置设备OTA**
   - 在设备固件中配置证书指纹
   - 配置OTA服务器地址
   - 设备启动后自动检查更新

### 方案二：XOR掩码（推荐用于批量生产）

1. **生成XOR密钥**
   ```bash
   # 使用API生成
   curl -X POST "http://localhost:8000/api/v1/firmware/generate-key/esp8266-001" \
     -H "Authorization: Bearer <admin_token>"
   ```

2. **应用掩码**
   ```bash
   # 使用Python脚本
   python backend/scripts/firmware_mask.py \
     -f firmware.bin \
     -k $(cat data/firmware/keys/esp8266-001_key.txt) \
     -o firmware_masked.bin
   ```

3. **烧录固件**
   - 将掩码后的固件通过串口或OTA烧录到设备
   - 设备启动时使用ESP8266XORBoot库自动解密

### 方案三：组合使用（最安全）

1. 先应用XOR掩码
2. 再通过HTTPS OTA下发掩码后的固件
3. 设备启动时先解密XOR，再正常运行

## 设备端实现

### ESP8266加密烧录模板

参考 `device/esp8266/encrypted_ota/encrypted_ota.ino` 模板文件。

**关键配置：**
```cpp
// XOR密钥（从key.txt复制）
const uint8_t XOR_KEY[16] = {0xAA, 0xBB, ...};

// 证书指纹（从CA证书获取）
const char* cert_fingerprint = "AA:BB:CC:DD:...";

// OTA服务器配置
const char* ota_host = "192.168.1.100";
const int   ota_port = 443;
```

### 依赖库

1. **ArduinoHttpClient** - HTTPS客户端
   - Arduino IDE → 库管理器 → 搜索安装

2. **ESP8266XORBoot**（可选）- XOR解密库
   - 需要单独安装
   - 或使用模板中的简化实现

## 命令行工具

### 固件掩码脚本

```bash
# 应用掩码
python backend/scripts/firmware_mask.py \
  -f firmware.bin \
  -k "AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD" \
  -o firmware_masked.bin

# 从密钥文件读取
python backend/scripts/firmware_mask.py \
  -f firmware.bin \
  -k $(cat data/firmware/keys/device_key.txt)

# 移除掩码（解密）
python backend/scripts/firmware_mask.py \
  -f firmware_masked.bin \
  -k "..." \
  --decrypt
```

## 安全注意事项

1. **XOR掩码不是真加密**
   - 只是增加逆向成本
   - 如需真加密，使用ESP32-C3的硬件AES

2. **密钥管理**
   - 密钥文件存放在 `data/firmware/keys/`
   - 仅超级管理员可访问密钥
   - 建议定期更换密钥

3. **证书管理**
   - 使用自签名证书时，确保设备时间正确
   - 证书过期会导致OTA更新失败

4. **固件大小限制**
   - ESP8266 OTA分区约1MB
   - 超过限制的固件无法更新

## 常见问题

### Q: XOR解密失败？
A: 确保密钥正确，且设备固件已应用对应密钥的掩码。

### Q: HTTPS OTA连接失败？
A: 
- 检查证书指纹是否正确
- 检查设备时间是否正确
- 检查服务器是否支持HTTPS

### Q: 固件更新失败？
A:
- 检查固件大小是否超过1MB
- 检查OTA分区是否足够
- 检查网络连接是否正常

## 参考资料

- [ESP8266 OTA文档](https://arduino-esp8266.readthedocs.io/en/latest/ota_updates/readme.html)
- [ArduinoHttpClient文档](https://github.com/arduino-libraries/ArduinoHttpClient)
- [OpenSSL证书管理](https://www.openssl.org/docs/)

