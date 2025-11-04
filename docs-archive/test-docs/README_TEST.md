# 测试脚本使用说明

## 远程固件构建和加密上传测试

### 快速开始

```bash
cd /home/shigure/mqtt-tls-iot-guardian
python3 scripts/test_remote_firmware_build.py
```

### 测试流程

脚本会自动执行以下步骤：

1. **登录认证** - 使用admin/admin123登录
2. **设备管理** - 检查或创建测试设备 `test-esp8266-001`
3. **模板获取** - 从数据库获取ESP8266模板
4. **固件构建** - 完整流程：
   - 生成固件代码（从模板）
   - 解析所需库（从#include语句）
   - 远程安装库（Arduino CLI）
   - 编译固件（Arduino CLI）
   - 加密固件（XOR掩码）
5. **OTA推送** - 可选：推送OTA更新

### 配置

编辑脚本中的配置变量：

```python
API_BASE_URL = "http://localhost:8000"  # API地址
TEST_USERNAME = "admin"                  # 用户名
TEST_PASSWORD = "admin123"              # 密码
TEST_DEVICE_ID = "test-esp8266-001"     # 测试设备ID
TEST_WIFI_SSID = "huawei9930"           # WiFi SSID
TEST_WIFI_PASSWORD = "993056494a."      # WiFi密码
```

### 预期输出

```
✅ 登录成功
✅ 设备已存在/创建成功
✅ 找到模板: ESP8266-ILI9341 (版本: v1)
✅ 固件构建成功！
   状态: completed
   固件代码: /path/to/test-esp8266-001.ino
   编译输出: /path/to/test-esp8266-001.bin (如果Arduino CLI可用)
   加密固件: /path/to/test-esp8266-001_masked.bin
```

### 注意事项

1. **Arduino CLI** - 如果未安装，编译步骤会跳过，但仍会生成加密固件
2. **库安装** - 首次运行可能需要一些时间下载库
3. **编译** - 编译可能需要几分钟时间
4. **OTA推送** - 需要设备在线才能接收更新

### 故障排查

参见 `docs/FIRMWARE_BUILD_TEST_GUIDE.md` 获取详细的故障排查指南。

