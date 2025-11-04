# ESP8266 首次加密烧录指南

本指南将帮助您完成ESP8266设备的首次加密固件烧录。

## 前置要求

1. **设备已注册**
   - 确保设备已在系统中注册
   - 记录设备ID（如：`encrypted-test-001`）

2. **硬件准备**
   - ESP8266开发板（NodeMCU / Wemos D1 Mini / ESP8266-12E等）
   - USB数据线（用于连接电脑）
   - 至少4MB Flash存储空间

3. **软件准备**
   - Python 3.7+（用于运行烧录工具）
   - esptool.py（ESP8266烧录工具）
   ```bash
   pip install esptool
   ```

## 步骤1：申请烧录文件

1. 在设备详情页面，点击 **"申请烧录文件"** 按钮

2. 填写WiFi配置信息：
   - **WiFi SSID**: 输入您的WiFi网络名称
   - **WiFi密码**: 输入WiFi密码
   - **使用加密**: 建议保持开启（默认启用XOR掩码加密）

3. 点击 **"提交申请"**

4. 系统将自动：
   - 为设备生成加密密钥（如果还没有）
   - 生成固件源代码
   - 编译固件为二进制文件
   - 使用XOR掩码加密固件

5. 等待构建完成（通常需要1-2分钟）

## 步骤2：下载加密固件

1. 构建完成后，在设备详情页面会显示：
   - 构建状态：已完成
   - 固件大小
   - 构建时间
   - OTA配置信息

2. 点击 **"下载加密固件"** 按钮

3. 固件文件将下载为：`{device_id}_masked.bin`

## 步骤3：烧录到ESP8266

### 方法1：使用esptool.py（推荐）

```bash
# 1. 找到ESP8266的串口号（Linux/Mac通常是 /dev/ttyUSB0 或 /dev/ttyACM0）
# Windows通常是 COM3, COM4 等

# 2. 检查串口是否被占用
lsof /dev/ttyUSB0  # 如果显示有进程占用，先关闭它们（如Arduino IDE、串口监视器等）

# 3. 擦除Flash（首次烧录建议先擦除）
esptool --port /dev/ttyUSB0 erase-flash

# 4. 烧录加密固件
esptool --port /dev/ttyUSB0 write-flash \
  --flash-mode dio \
  --flash-freq 40m \
  --flash-size 4MB \
  0x0 {device_id}_masked.bin

# 示例（设备ID为 encrypted-test-001）:
esptool --port /dev/ttyUSB0 write-flash \
  --flash-mode dio \
  --flash-freq 40m \
  --flash-size 4MB \
  0x0 encrypted-test-001_masked.bin
```

### 方法2：使用Arduino IDE

1. 打开Arduino IDE
2. 选择 **工具** → **开发板** → 选择您的ESP8266型号
3. 选择 **工具** → **端口** → 选择ESP8266连接的端口
4. 选择 **工具** → **Flash Size** → **4MB (FS:2MB OTA:~1019KB)**
5. 使用 **工具** → **烧录引导程序** 或直接编译上传

### 方法3：使用ESP8266 Flash Download Tool（Windows）

1. 下载ESP8266 Flash Download Tool
2. 配置参数：
   - **SPI SPEED**: 40MHz
   - **SPI MODE**: DIO
   - **FLASH SIZE**: 32Mbit (4MB)
3. 添加固件文件：
   - **地址**: 0x00000
   - **文件**: 选择下载的 `{device_id}_masked.bin`
4. 点击 **START** 开始烧录

## 步骤4：验证烧录

1. **查看串口输出**
   ```bash
   # Linux/Mac
   screen /dev/ttyUSB0 115200
   
   # Windows (使用PuTTY或Arduino IDE串口监视器)
   # 波特率: 115200
   ```

2. **预期输出**：
   ```
   ==========================================
   Mqtt-tls-iot-guardian-ESP8266
   ==========================================
   Device ID: encrypted-test-001
   ==========================================
   
   [WiFi] Connecting to YourWiFiName
   WiFi: Connected! IP address: 192.168.1.100
   [MQTT] Connecting to your-mqtt-server:8883
   MQTT: Connected!
   ```

3. **检查设备状态**
   - 在Web界面中，设备状态应该显示为 **在线**
   - 设备应该开始发送心跳和传感器数据

## 步骤5：OTA配置（可选）

如果设备需要支持OTA更新，可以：

1. 查看设备详情页面中的 **OTA配置**
2. 复制OTA配置JSON
3. 在设备端代码中配置OTA功能（如果固件支持）

## 常见问题

### Q1: 烧录失败，提示"端口被占用"或"Device or resource busy"

**解决方案**：
1. **检查串口占用**：
   ```bash
   lsof /dev/ttyUSB0  # 查看占用进程
   kill <PID>         # 终止占用进程
   ```
2. **关闭可能占用串口的程序**：
   - Arduino IDE 的串口监视器
   - screen/minicom 会话
   - 其他串口工具
3. **检查USB连接**：
   - 重新插拔USB线
   - 尝试不同的USB端口
4. **权限问题**（如果仍有问题）：
   ```bash
   sudo usermod -a -G dialout $USER
   # 然后重新登录
   ```

### Q2: 烧录失败，提示"无法连接到设备"

**解决方案**：
- 检查USB线是否连接正常
- 确认串口号是否正确（可能是 /dev/ttyUSB1 或其他）
- 尝试按住ESP8266的BOOT按钮，然后重新连接USB
- 检查驱动是否正确安装（CH340/CP2102等）

### Q3: 设备无法连接WiFi

**解决方案**：
- 检查WiFi SSID和密码是否正确
- 确认WiFi网络在2.4GHz频段（ESP8266不支持5GHz）
- 检查WiFi信号强度

### Q4: 设备无法连接MQTT服务器

**解决方案**：
- 检查MQTT服务器地址和端口是否正确
- 确认服务器证书已正确配置
- 检查防火墙设置

### Q5: 需要重新烧录（密钥已变更）

如果密钥已重新生成，旧的加密固件将无法使用。需要：
1. 重新申请烧录文件（会使用新密钥）
2. 下载新的加密固件
3. 重新烧录到设备

## 安全提示

1. **密钥管理**
   - 加密密钥仅管理员可见
   - 密钥变更会导致旧固件失效
   - 请妥善保管密钥信息

2. **固件安全**
   - 加密固件使用XOR掩码保护
   - 未加密的固件文件不应公开
   - 定期更新固件以修复安全漏洞

3. **网络安全**
   - 使用HTTPS/TLS加密通信
   - 配置MQTT over TLS
   - 定期更新证书

## 下一步

烧录完成后，您可以：
- 监控设备状态
- 查看传感器数据
- 通过MQTT发送控制命令
- 使用OTA功能更新固件

## 技术支持

如遇到问题，请：
1. 查看串口日志
2. 检查设备详情页面的错误信息
3. 联系系统管理员

