# Arduino CLI 远程库管理指南

## 概述

系统现在完全使用 **Arduino CLI** 进行远程库管理，不再依赖本地 `libraries` 目录。所有库都会从 Arduino Library Manager 自动下载和安装。

## 工作原理

### 1. 自动库检测

编译固件时，系统会：
1. 从 `.ino` 文件中解析 `#include` 语句
2. 提取所需的库名称（排除标准库和内置库）
3. 使用 Arduino CLI 检查库是否已安装
4. 如果未安装，自动从远程安装

### 2. 库安装流程

```python
# 伪代码示例
1. 解析代码中的 #include 语句
   → 提取: PubSubClient, ArduinoJson, Adafruit_GFX, Adafruit_ILI9341

2. 检查每个库是否已安装
   arduino-cli lib list --format json

3. 安装缺失的库
   arduino-cli lib install PubSubClient
   arduino-cli lib install ArduinoJson
   arduino-cli lib install Adafruit_GFX
   arduino-cli lib install Adafruit_ILI9341

4. 编译固件（Arduino CLI 自动使用已安装的库）
   arduino-cli compile --fqbn esp8266:esp8266:nodemcuv2 ...
```

## 优势

### ✅ 无需本地库管理
- 不再需要维护 `libraries` 目录
- 不需要手动下载和更新库文件
- 减少项目体积和版本控制负担

### ✅ 自动版本管理
- Arduino CLI 自动管理库版本
- 可以指定特定版本（如果需要）
- 自动处理依赖关系

### ✅ 跨平台兼容
- 使用标准 Arduino Library Manager
- 所有平台使用相同的库源
- 确保编译一致性

## 配置要求

### 1. 安装 Arduino CLI

```bash
# Ubuntu/Debian
sudo snap install arduino-cli

# 或使用官方安装脚本
curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh

# 验证安装
arduino-cli version
```

### 2. 初始化 Arduino CLI

```bash
# 创建配置文件（如果不存在）
arduino-cli config init

# 添加 ESP8266 开发板支持
arduino-cli core update-index
arduino-cli core install esp8266:esp8266
```

## 库管理命令

### 查看已安装的库

```bash
arduino-cli lib list
```

### 搜索库

```bash
arduino-cli lib search PubSubClient
```

### 安装库

```bash
# 安装最新版本
arduino-cli lib install PubSubClient

# 安装特定版本
arduino-cli lib install "PubSubClient@2.8.0"
```

### 更新库

```bash
arduino-cli lib upgrade
```

### 卸载库

```bash
arduino-cli lib uninstall PubSubClient
```

## 代码中的库解析

### 支持的库声明格式

系统会自动识别以下格式的 `#include` 语句：

```cpp
// ✅ 标准库格式（会被识别）
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include <Adafruit_GFX.h>
#include <Adafruit_ILI9341.h>

// ❌ 标准库和内置库（会被忽略）
#include <ESP8266WiFi.h>           // 内置库
#include <WiFiClientSecureBearSSL.h>  // 内置库
#include <Arduino.h>               // 标准库
#include <Wire.h>                  // 标准库
#include <SPI.h>                   // 标准库
```

### 自动解析的库

系统会自动从模板代码中提取以下库：

- `PubSubClient` - MQTT 客户端库
- `ArduinoJson` - JSON 处理库
- `Adafruit_GFX` - 图形库
- `Adafruit_ILI9341` - ILI9341 显示屏库
- `Adafruit_BusIO` - I2C/SPI 总线库
- 其他非标准库

## 编译流程

### 完整流程

1. **生成固件代码**
   ```python
   firmware_code = generate_firmware_code(...)
   ```

2. **保存为 .ino 文件**
   ```python
   firmware_file = save_to_file(firmware_code, "device.ino")
   ```

3. **解析所需库**
   ```python
   libraries = parse_required_libraries(firmware_code)
   # 返回: ['PubSubClient', 'ArduinoJson', 'Adafruit_GFX', 'Adafruit_ILI9341']
   ```

4. **安装库（如果缺失）**
   ```python
   for lib in libraries:
       if not is_installed(lib):
           install_library(lib)
   ```

5. **编译固件**
   ```bash
   arduino-cli compile \
     --fqbn esp8266:esp8266:nodemcuv2 \
     --build-path ./build \
     ./firmware_dir
   ```

## 故障排查

### 问题1：库安装失败

**症状**：编译时提示找不到库

**解决方案**：
```bash
# 手动安装库
arduino-cli lib install <library_name>

# 检查库是否已安装
arduino-cli lib list | grep <library_name>
```

### 问题2：库版本不兼容

**症状**：编译错误，API不匹配

**解决方案**：
```bash
# 升级所有库
arduino-cli lib upgrade

# 或安装特定版本
arduino-cli lib install "LibraryName@1.2.3"
```

### 问题3：Arduino CLI 未找到

**症状**：`未找到arduino-cli`

**解决方案**：
```bash
# 检查安装
which arduino-cli

# 如果未安装，参考上面的安装步骤
```

### 问题4：库解析错误

**症状**：系统无法识别所需的库

**解决方案**：
- 确保使用 `#include <LibraryName.h>` 格式
- 检查库名是否正确（区分大小写）
- 查看编译日志，确认库是否被正确识别

## 迁移指南

### 从本地库迁移到远程库

如果您之前使用本地 `libraries` 目录：

1. **删除本地库目录**（可选）
   ```bash
   rm -rf libraries/
   ```

2. **更新 .gitignore**（如果库目录已加入版本控制）
   ```gitignore
   # 不再需要
   # libraries/
   ```

3. **确保 Arduino CLI 已安装**
   ```bash
   arduino-cli version
   ```

4. **首次编译会自动安装库**
   - 系统会在编译前自动检测并安装所需的库
   - 无需手动操作

## 最佳实践

### 1. 库版本管理

虽然系统会自动安装最新版本，但建议：
- 在模板中记录所需库的版本
- 使用 `required_libraries` 字段指定版本（如果支持）

### 2. 定期更新库

```bash
# 更新所有库
arduino-cli lib upgrade

# 查看更新日志
arduino-cli lib list --updatable
```

### 3. 清理未使用的库

```bash
# 查看已安装的库
arduino-cli lib list

# 手动卸载不需要的库
arduino-cli lib uninstall <library_name>
```

## 总结

✅ **已移除**：
- 本地 `libraries` 目录依赖
- `LibraryManager` 类的本地库管理功能
- 编译时的 `--library` 路径参数

✅ **新功能**：
- 自动从代码解析所需库
- 使用 Arduino CLI 远程安装库
- 自动检查库是否已安装
- 编译时自动使用已安装的库

✅ **优势**：
- 简化项目结构
- 自动版本管理
- 更好的跨平台兼容性
- 减少维护负担

