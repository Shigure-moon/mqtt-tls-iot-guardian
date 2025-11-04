# 加密烧录API测试报告

## 测试时间
2025-11-04

## 测试环境
- 服务器IP: 192.168.1.8 (MQTT Broker)
- 设备IP范围: 10.42.0.x
- 测试设备ID: encrypted-test-001

## 测试结果

### ✅ 1. 设备创建
- **状态**: 成功
- **设备ID**: encrypted-test-001
- **设备类型**: ESP8266

### ✅ 2. 服务器证书生成
- **状态**: 成功
- **包含IP地址**: 
  - 192.168.1.8 (主IP)
  - 10.42.0.1
  - 10.42.0.247 (设备IP)
  - 127.0.0.1
  - localhost
- **证书指纹**: `34:EB:44:3B:DB:9A:94:0B:99:69:DB:22:1B:00:BE:2E:60:50:29:78:AA:82:C7:EB:7A:70:14:60:4C:45:E6:A3`

### ✅ 3. XOR密钥生成
- **状态**: 成功
- **密钥**: `1bf7b5d48ead4b3623f2e3c12c317bf6`
- **密钥文件**: `data/firmware/keys/encrypted-test-001_key.txt`

### ✅ 4. 固件加密
- **状态**: 成功
- **原始大小**: 1024 字节
- **加密后路径**: `data/firmware/encrypted-test-001_masked.bin`
- **使用XOR掩码**: 是

### ✅ 5. OTA配置获取
- **状态**: 成功
- **服务器地址**: 192.168.1.8:443
- **使用HTTPS**: 是
- **证书指纹**: 已包含

## API端点测试结果

| API端点 | 状态 | 说明 |
|---------|------|------|
| `POST /firmware/generate-key/{device_id}` | ✅ | XOR密钥生成成功 |
| `GET /firmware/xor-key/{device_id}` | ✅ | XOR密钥获取成功 |
| `POST /firmware/encrypt/{device_id}` | ✅ | 固件加密成功 |
| `GET /firmware/ota-config/{device_id}` | ✅ | OTA配置获取成功 |
| `POST /certificates/server/generate` | ✅ | 服务器证书生成成功（包含新IP） |

## 使用说明

### 1. 获取XOR密钥
```bash
curl -X GET "http://localhost:8000/api/v1/firmware/xor-key/encrypted-test-001" \
  -H "Authorization: Bearer <admin_token>"
```

### 2. 加密固件
```bash
curl -X POST "http://localhost:8000/api/v1/firmware/encrypt/encrypted-test-001?use_xor_mask=true" \
  -H "Authorization: Bearer <token>" \
  -F "firmware_file=@firmware.bin"
```

### 3. 获取OTA配置
```bash
curl -X GET "http://localhost:8000/api/v1/firmware/ota-config/encrypted-test-001?use_https=true" \
  -H "Authorization: Bearer <token>"
```

### 4. 使用命令行工具应用掩码
```bash
python backend/scripts/firmware_mask.py \
  -f firmware.bin \
  -k $(cat data/firmware/keys/encrypted-test-001_key.txt) \
  -o firmware_masked.bin
```

## MQTT连接问题解决

### 问题
- 错误码: `rc=-2` (Connect failed)
- 原因: 服务器证书不包含新的IP地址范围

### 解决方案
1. ✅ 重新生成服务器证书，包含所有需要的IP地址
2. ✅ 证书已包含: 192.168.1.8, 10.42.0.1, 10.42.0.247等
3. ✅ 更新Mosquitto配置使用新证书

### 下一步
1. 重启Mosquitto服务以加载新证书
2. 测试设备MQTT连接（应该可以成功连接）
3. 使用证书指纹配置HTTPS OTA更新

## 证书指纹使用

设备端配置示例（Arduino）：
```cpp
// 证书指纹（从OTA配置获取）
const char* cert_fingerprint = "34:EB:44:3B:DB:9A:94:0B:99:69:DB:22:1B:00:BE:2E:60:50:29:78:AA:82:C7:EB:7A:70:14:60:4C:45:E6:A3";

// 配置WiFi安全客户端
wifiSecure.setFingerprint(cert_fingerprint);
```

## 注意事项

1. **服务器证书更新后**，需要重启Mosquitto服务
2. **XOR密钥**应妥善保管，丢失后无法解密固件
3. **证书指纹**用于HTTPS OTA验证，确保固件来源可信
4. **固件大小**限制在1MB以内（ESP8266 OTA分区限制）

