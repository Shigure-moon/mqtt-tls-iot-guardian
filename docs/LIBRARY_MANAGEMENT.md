# Arduino库文件管理方案

## 概述

本文档说明如何在IoT安全管理系统中使用本地Arduino库文件编译固件，生成bin文件用于烧录或OTA推送。

## 目录结构

```
mqtt-tls-iot-guardian/
├── libraries/                    # 本地Arduino库文件目录
│   ├── PubSubClient/             # MQTT客户端库
│   ├── ArduinoJson/              # JSON处理库
│   ├── Adafruit_GFX_Library/     # Adafruit图形库
│   ├── Adafruit_ILI9341/         # ILI9341显示屏库
│   └── ...                       # 其他依赖库
├── backend/
│   ├── app/
│   │   └── services/
│   │       ├── library_manager.py      # 库文件管理服务（新建）
│   │       └── firmware_build.py       # 固件编译服务（扩展）
│   └── data/
│       └── firmware/             # 编译输出目录
└── docs/
    └── LIBRARY_MANAGEMENT.md     # 本文档
```

## 库文件管理方案

### 方案一：使用本地库文件（推荐）

**优点**：
- 版本可控，不依赖网络
- 编译速度快
- 可以自定义库文件

**实现方式**：
1. 将库文件放在 `libraries/` 目录
2. 使用 `arduino-cli` 的 `--library` 参数指定库路径
3. 编译时自动包含所有依赖库

### 方案二：使用arduino-cli库管理器

**优点**：
- 自动管理依赖
- 版本更新方便

**缺点**：
- 需要网络连接
- 首次安装较慢

**实现方式**：
```bash
arduino-cli lib install "PubSubClient"
arduino-cli lib install "ArduinoJson"
```

## 编译流程

### 1. 前端调用编译API

```typescript
// 前端调用示例
const response = await axios.post(`/api/v1/firmware/compile/${deviceId}`, {
  template_id: "template-uuid",
  template_version: "v1",
  use_local_libraries: true,  // 使用本地库文件
  libraries_path: "/path/to/libraries"  // 可选，默认使用项目libraries目录
});
```

### 2. 后端处理流程

1. **获取模板代码**（如果指定了template_id）
2. **替换占位符**（设备信息、WiFi配置等）
3. **准备库文件**（从libraries目录复制或链接）
4. **调用arduino-cli编译**
5. **生成bin文件**
6. **加密处理**（如果启用）
7. **返回bin文件路径或直接推送到OTA**

## 库文件依赖管理

### 模板中定义所需库

在模板的 `required_libraries` 字段中存储JSON格式的库列表：

```json
{
  "libraries": [
    {
      "name": "PubSubClient",
      "version": "2.8.0",
      "path": "libraries/PubSubClient"
    },
    {
      "name": "ArduinoJson",
      "version": "6.21.0",
      "path": "libraries/ArduinoJson"
    },
    {
      "name": "Adafruit_GFX_Library",
      "version": "1.11.9",
      "path": "libraries/Adafruit_GFX_Library"
    },
    {
      "name": "Adafruit_ILI9341",
      "version": "1.6.0",
      "path": "libraries/Adafruit_ILI9341"
    }
  ]
}
```

### 自动检测库依赖

从.ino文件中解析 `#include` 语句，自动检测所需库：

```cpp
#include <PubSubClient.h>      // 需要 PubSubClient 库
#include <ArduinoJson.h>       // 需要 ArduinoJson 库
#include <Adafruit_GFX.h>      // 需要 Adafruit_GFX_Library
#include <Adafruit_ILI9341.h>  // 需要 Adafruit_ILI9341
```

## arduino-cli编译配置

### ESP8266编译命令

```bash
arduino-cli compile \
  --fqbn esp8266:esp8266:nodemcuv2 \
  --library libraries/PubSubClient \
  --library libraries/ArduinoJson \
  --library libraries/Adafruit_GFX_Library \
  --library libraries/Adafruit_ILI9341 \
  --build-path data/firmware/build \
  --output-dir data/firmware/output \
  device_code_directory
```

### 编译参数说明

- `--fqbn`: 板型标识（ESP8266 NodeMCU）
- `--library`: 指定库路径（可多次使用）
- `--build-path`: 编译中间文件目录
- `--output-dir`: 输出bin文件目录

## 生成bin文件

### 编译输出

arduino-cli编译后会在输出目录生成：
- `firmware.bin`: 主程序固件
- `boot_app0.bin`: Bootloader（可选）
- `partitions.bin`: 分区表（可选）

### 合并bin文件（ESP8266）

对于ESP8266，通常只需要 `firmware.bin`，可以直接使用。

### 加密处理

编译后的bin文件可以：
1. **直接使用**：用于首次烧录
2. **XOR加密**：用于加密烧录
3. **OTA推送**：直接推送到设备

## API端点设计

### 1. 编译固件（生成bin文件）

```http
POST /api/v1/firmware/compile/{device_id}
Content-Type: application/json

{
  "template_id": "uuid",
  "template_version": "v1",
  "wifi_ssid": "MyWiFi",
  "wifi_password": "password",
  "use_local_libraries": true,
  "libraries_path": null,  // 可选，默认使用项目libraries目录
  "compile_options": {
    "fqbn": "esp8266:esp8266:nodemcuv2",
    "flash_size": "4MB",
    "upload_speed": "115200"
  }
}
```

**响应**：
```json
{
  "status": "completed",
  "firmware_code_path": "/path/to/device.ino",
  "firmware_bin_path": "/path/to/firmware.bin",
  "build_log": "...",
  "file_size": 123456,
  "sha256": "..."
}
```

### 2. 直接生成加密bin文件（用于OTA）

```http
POST /api/v1/firmware/build/{device_id}
Content-Type: application/json

{
  "template_id": "uuid",
  "template_version": "v1",
  "use_local_libraries": true,
  "use_encryption": true,
  "auto_ota": false  // 是否自动推送到OTA
}
```

### 3. 获取编译状态

```http
GET /api/v1/firmware/compile/{device_id}/status
```

## 使用示例

### 前端调用流程

```typescript
// 1. 选择模板版本
const templates = await getTemplatesByDeviceType("ESP8266");
const v1Template = templates.find(t => t.version === "v1");

// 2. 编译固件
const buildResult = await compileFirmware(deviceId, {
  template_id: v1Template.id,
  template_version: "v1",
  wifi_ssid: "MyWiFi",
  wifi_password: "password",
  use_local_libraries: true
});

// 3. 下载bin文件或直接OTA推送
if (buildResult.status === "completed") {
  // 选项A：下载bin文件
  await downloadFirmware(buildResult.firmware_bin_path);
  
  // 选项B：直接OTA推送
  await pushOTAUpdate(deviceId, {
    firmware_url: buildResult.firmware_bin_path,
    firmware_version: "v1.0.0"
  });
}
```

## 注意事项

### 1. 库文件版本兼容性

- 确保库文件版本与模板兼容
- 建议在模板中指定所需库的版本号

### 2. 编译环境

- 需要安装 `arduino-cli`
- 需要安装ESP8266开发板支持包
- 需要足够的磁盘空间（编译会产生临时文件）

### 3. 权限管理

- 编译功能需要适当权限
- bin文件下载需要认证
- OTA推送需要设备管理权限

### 4. 性能优化

- 编译是CPU密集型操作，建议异步处理
- 可以缓存编译结果
- 支持增量编译（如果库文件未变化）

## 故障排查

### 编译失败

1. **检查arduino-cli是否安装**
   ```bash
   arduino-cli version
   ```

2. **检查ESP8266板型支持**
   ```bash
   arduino-cli core list
   arduino-cli core install esp8266:esp8266
   ```

3. **检查库文件路径**
   ```bash
   ls -la libraries/
   ```

4. **查看编译日志**
   - 检查API响应的 `build_log` 字段
   - 查看后端日志

### 库文件缺失

1. 确保所有依赖库都在 `libraries/` 目录
2. 检查库文件结构是否正确
3. 验证 `library.properties` 文件是否存在

## 总结

通过使用本地库文件，可以实现：
1. ✅ **版本控制**：每个模板指定所需库版本
2. ✅ **快速编译**：无需下载，直接使用本地库
3. ✅ **bin文件生成**：自动编译生成可烧录的bin文件
4. ✅ **OTA推送**：编译后直接推送到设备
5. ✅ **前端调用**：通过API完全自动化流程

