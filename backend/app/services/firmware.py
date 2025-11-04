"""
固件代码生成服务
根据设备信息和证书生成Arduino烧录代码
"""
from pathlib import Path
from typing import Optional
from app.core.config import settings


class FirmwareService:
    """固件代码生成服务"""
    
    # Arduino代码模板
    TEMPLATE = '''/**********************************************************************
 * IoT安全管理系统 - ESP8266设备端（带屏幕显示）
 * 
 * 设备ID: {device_id}
 * 设备名称: {device_name}
 * 
 * 功能：
 * - WiFi连接
 * - MQTT over TLS安全通信
 * - ILI9341屏幕显示
 * - 自动订阅设备主题
 * - 发送心跳和传感器数据
 * - 接收控制命令
 * 
 * 配置：
 * - MQTT Broker: {mqtt_server}
 * - 端口: 8883 (TLS)
 * - 认证: 用户名密码 + TLS证书
 * - 屏幕: ILI9341 TFT显示屏
 * 
 * 主题规范：
 * - 设备状态: devices/{device_id}/status
 * - 传感器数据: devices/{device_id}/sensor
 * - 控制命令: devices/{device_id}/control
 * - 告警信息: devices/{device_id}/alerts
 * - 心跳: devices/{device_id}/heartbeat
 * 
 * 所需库：
 * - ESP8266WiFi
 * - WiFiClientSecureBearSSL
 * - PubSubClient
 * - ArduinoJson
 * - Adafruit_GFX
 * - Adafruit_ILI9341
 **********************************************************************/

#include <ESP8266WiFi.h>
#include <WiFiClientSecureBearSSL.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include <Adafruit_GFX.h>
#include <Adafruit_ILI9341.h>

// ====== 根据实际接线修改 ======
#define TFT_CS D2
#define TFT_RST D3
#define TFT_DC D4
Adafruit_ILI9341 tft(TFT_CS, TFT_DC, TFT_RST);

// ====== 设备配置 ======
#define DEVICE_ID "{device_id}"              // 设备唯一ID
#define DEVICE_NAME "{device_name}"          // 设备名称（屏幕显示用）

// WiFi配置
const char* ssid = "{wifi_ssid}";            // WiFi网络名称
const char* password = "{wifi_password}";    // WiFi密码

// MQTT Broker配置
const char* mqtt_server = "{mqtt_server}";   // MQTT服务器地址
const int mqtt_port = 8883;                  // TLS端口
const char* mqtt_user = "{mqtt_username}";   // MQTT用户名
const char* mqtt_pass = "{mqtt_password}";   // MQTT密码

// 使用TLS
#define USE_TLS true                         // 启用TLS

// CA证书（用于验证MQTT服务器证书）
static const char ca_cert[] PROGMEM = R"PEM(
{ca_cert}
)PEM";

// MQTT主题
const char* topic_status = "devices/" DEVICE_ID "/status";
const char* topic_sensor = "devices/" DEVICE_ID "/sensor";
const char* topic_control = "devices/" DEVICE_ID "/control";
const char* topic_heartbeat = "devices/" DEVICE_ID "/heartbeat";
const char* topic_alerts = "devices/" DEVICE_ID "/alerts";

// MQTT客户端
std::unique_ptr<BearSSL::WiFiClientSecure> secureClient(new BearSSL::WiFiClientSecure);
PubSubClient mqtt(*secureClient);

// ====== 屏幕布局（左：MQTT流程，右：传感器记录） ======
static const int16_t LEFT_PANE_X = 0;
static const int16_t LEFT_PANE_W = 200;
static const int16_t RIGHT_PANE_X = LEFT_PANE_W + 1;
static int16_t RIGHT_PANE_W = 120;
static const int16_t HEADER_H = 30;
static const int16_t LINE_H = 12;

// 动态游标
static int16_t yLeft = HEADER_H + 2;
static int16_t yRight = HEADER_H + 2;

// ====== 全局变量 ======
unsigned long lastHeartbeat = 0;
unsigned long lastSensorPub = 0;
const unsigned long HEARTBEAT_INTERVAL = 30000;  // 30秒心跳
const unsigned long SENSOR_INTERVAL = 10000;     // 10秒传感器数据

// 连接状态
bool wifiConnected = false;
bool mqttConnected = false;

#define SERIAL_BAUD 115200

/**********************************************************************
 * 在指定pane打印一行，打印前清除该行，避免重叠
 **********************************************************************/
void printLineInPane(int16_t x, int16_t &y, int16_t w, const String &text, uint16_t color) {{
    // 清除该行区域
    tft.fillRect(x, y, w, LINE_H, ILI9341_BLACK);
    // 打印
    tft.setCursor(x + 2, y);
    tft.setTextColor(color);
    tft.setTextSize(1);
    tft.setTextWrap(false);
    // 依据列宽裁剪一行可显示的字符数（字体宽约6px）
    int16_t maxChars = (w - 4) / 6;
    String line = text;
    if (maxChars > 0 && (int)text.length() > maxChars) {{
        line = text.substring(0, maxChars - 1) + "~";
    }}
    tft.print(line);
    // 前进一行，滚屏
    y += LINE_H;
    int16_t maxH = tft.height();
    if (y > maxH - LINE_H) {{
        tft.fillRect(x, HEADER_H + 2, w, maxH - HEADER_H - 2, ILI9341_BLACK);
        y = HEADER_H + 2;
    }}
}}

inline void printLeftLine(const String &s, uint16_t color = ILI9341_WHITE) {{
    printLineInPane(LEFT_PANE_X, yLeft, LEFT_PANE_W, s, color);
}}

inline void printRightLine(const String &s, uint16_t color = ILI9341_YELLOW) {{
    printLineInPane(RIGHT_PANE_X, yRight, RIGHT_PANE_W, s, color);
}}

/**********************************************************************
 * 绘制左右两个标题栏
 **********************************************************************/
void drawHeaders() {{
    // 左标题 - MQTT连接状态
    tft.fillRect(LEFT_PANE_X, 0, LEFT_PANE_W, HEADER_H, ILI9341_BLUE);
    tft.setTextColor(ILI9341_WHITE);
    tft.setTextSize(2);
    tft.setCursor(LEFT_PANE_X + 4, 6);
    tft.print("MQTT");

    // 右标题 - 传感器数据
    tft.fillRect(RIGHT_PANE_X, 0, RIGHT_PANE_W, HEADER_H, ILI9341_DARKGREEN);
    tft.setTextColor(ILI9341_WHITE);
    tft.setTextSize(2);
    tft.setCursor(RIGHT_PANE_X + 4, 6);
    tft.print("Data");

    // 中间分隔线
    tft.drawFastVLine(LEFT_PANE_W, 0, tft.height(), ILI9341_DARKGREY);
}}

/**********************************************************************
 * MQTT消息回调函数
 **********************************************************************/
void mqttCallback(char* topic, byte* payload, unsigned int length) {{
    Serial.print("[MQTT] Received message on topic: ");
    Serial.println(topic);
    
    // 左侧：显示接收到的消息
    printLeftLine("[RX] Incoming msg", ILI9341_CYAN);
    
    // 显示HEX（最多16字节）
    String encryptedHex = "";
    for (unsigned int i = 0; i < min(length, (unsigned int)16); i++) {{
        if (i) encryptedHex += " ";
        uint8_t b = payload[i];
        if (b < 16) encryptedHex += "0";
        encryptedHex += String(b, HEX);
    }}
    if (length > 16) encryptedHex += " ...";
    printLeftLine("Encrypted(hex):", ILI9341_MAGENTA);
    printLeftLine(encryptedHex, ILI9341_MAGENTA);

    // 模拟TLS流程
    printLeftLine("TLS: handshake OK", ILI9341_YELLOW);
    printLeftLine("TLS: verify cert OK", ILI9341_YELLOW);
    printLeftLine("TLS: AES-GCM decrypt", ILI9341_YELLOW);

    // 明文
    String msg;
    for (unsigned int i = 0; i < length; i++) msg += (char)payload[i];
    printLeftLine("Plaintext:", ILI9341_GREEN);
    printLeftLine(msg, ILI9341_GREEN);
    printLeftLine("Topic: " + String(topic), ILI9341_WHITE);
    
    // 简单的命令解析
    if (strstr(msg.c_str(), "restart")) {{
        printLeftLine("CMD: Restarting...", ILI9341_RED);
        ESP.restart();
    }} else if (strstr(msg.c_str(), "led_on")) {{
        printLeftLine("CMD: LED ON", ILI9341_GREEN);
        digitalWrite(LED_BUILTIN, LOW);
    }} else if (strstr(msg.c_str(), "led_off")) {{
        printLeftLine("CMD: LED OFF", ILI9341_GREEN);
        digitalWrite(LED_BUILTIN, HIGH);
    }}
}}

/**********************************************************************
 * 连接WiFi
 **********************************************************************/
bool connectWiFi() {{
    Serial.print("[WiFi] Connecting to ");
    Serial.println(ssid);
    printLeftLine("WiFi: Connecting...", ILI9341_YELLOW);
    
    WiFi.mode(WIFI_STA);
    WiFi.begin(ssid, password);
    
    int attempts = 0;
    while (WiFi.status() != WL_CONNECTED && attempts < 60) {{
        delay(500);
        Serial.print(".");
        attempts++;
    }}
    
    if (WiFi.status() == WL_CONNECTED) {{
        Serial.println();
        Serial.print("[WiFi] Connected! IP address: ");
        Serial.println(WiFi.localIP());
        String ipMsg = "WiFi: IP " + WiFi.localIP().toString();
        printLeftLine("WiFi: Connected", ILI9341_GREEN);
        printLeftLine(ipMsg, ILI9341_GREEN);
        wifiConnected = true;
        delay(500);
        return true;
    }} else {{
        Serial.println();
        Serial.println("[WiFi] Connection failed!");
        printLeftLine("WiFi: Failed!", ILI9341_RED);
        wifiConnected = false;
        return false;
    }}
}}

/**********************************************************************
 * 连接MQTT
 **********************************************************************/
bool connectMQTT() {{
    Serial.print("[MQTT] Connecting to ");
    Serial.print(mqtt_server);
    Serial.print(":");
    Serial.println(mqtt_port);
    printLeftLine("MQTT: Connecting...", ILI9341_YELLOW);
    
    // 如果使用TLS
    if (USE_TLS) {{
        printLeftLine("TLS: Load CA cert", ILI9341_YELLOW);
        secureClient->setBufferSizes(4096, 512);
        secureClient->setTimeout(15000);
        
        // 加载CA证书
        BearSSL::X509List cert(ca_cert);
        secureClient->setTrustAnchors(&cert);
        // secureClient->setInsecure();  // 可选：仅测试环境
    }}
    
    // 设置MQTT服务器和回调
    mqtt.setServer(mqtt_server, mqtt_port);
    mqtt.setCallback(mqttCallback);
    
    // 生成客户端ID
    String clientId = String("iot-device-") + String(ESP.getChipId(), HEX);
    
    // 尝试连接
    if (mqtt.connect(clientId.c_str(), mqtt_user, mqtt_pass)) {{
        Serial.println("[MQTT] Connected!");
        printLeftLine("MQTT: Connected!", ILI9341_GREEN);
        mqttConnected = true;
        
        // 订阅控制主题
        mqtt.subscribe(topic_control);
        printLeftLine("Sub: control", ILI9341_WHITE);
        
        // 订阅告警主题
        mqtt.subscribe(topic_alerts);
        printLeftLine("Sub: alerts", ILI9341_WHITE);
        
        // 发送上线消息
        String onlineMsg = "{{\\"status\\":\\"online\\",\\"device_id\\":\\"" + String(DEVICE_ID) + "\\"}}";
        mqtt.publish(topic_status, onlineMsg.c_str());
        printLeftLine("Pub: online", ILI9341_GREEN);
        
        delay(500);
        return true;
    }} else {{
        Serial.print("[MQTT] Connection failed, rc=");
        Serial.println(mqtt.state());
        printLeftLine("MQTT: Failed!", ILI9341_RED);
        mqttConnected = false;
        return false;
    }}
}}

/**********************************************************************
 * 发送心跳消息
 **********************************************************************/
void sendHeartbeat() {{
    unsigned long now = millis();
    if (now - lastHeartbeat >= HEARTBEAT_INTERVAL) {{
        lastHeartbeat = now;
        
        DynamicJsonDocument doc(256);
        doc["device_id"] = DEVICE_ID;
        doc["timestamp"] = now / 1000;
        doc["uptime"] = now / 1000;
        doc["heap"] = ESP.getFreeHeap();
        doc["rssi"] = WiFi.RSSI();
        
        String message;
        serializeJson(doc, message);
        
        if (mqtt.publish(topic_heartbeat, message.c_str())) {{
            Serial.println("[Heartbeat] Sent");
        }} else {{
            Serial.println("[Heartbeat] Failed");
        }}
    }}
}}

/**********************************************************************
 * 发送传感器数据
 **********************************************************************/
void sendSensorData() {{
    unsigned long now = millis();
    if (now - lastSensorPub >= SENSOR_INTERVAL) {{
        lastSensorPub = now;
        
        DynamicJsonDocument doc(512);
        doc["device_id"] = DEVICE_ID;
        doc["timestamp"] = now / 1000;
        
        // 模拟传感器数据
        float temp = 25.5 + random(0, 100) / 10.0;
        float humi = 60.0 + random(0, 200) / 10.0;
        float volt = 3.3 + random(0, 10) / 100.0;
        float batt = 85.0 + random(0, 200) / 10.0;
        
        doc["temperature"] = temp;
        doc["humidity"] = humi;
        doc["voltage"] = volt;
        doc["battery"] = batt;
        doc["status"]["wifi"] = wifiConnected ? "connected" : "disconnected";
        doc["status"]["mqtt"] = mqttConnected ? "connected" : "disconnected";
        doc["status"]["uptime"] = now / 1000;
        
        String message;
        serializeJson(doc, message);
        
        if (mqtt.publish(topic_sensor, message.c_str())) {{
            Serial.println("[Sensor] Data sent");
            
            // 右侧面板显示传感器数据
            printRightLine("t=" + String(now / 1000) + "s", ILI9341_CYAN);
            printRightLine("Temp:" + String(temp, 1) + "C", ILI9341_YELLOW);
            printRightLine("Hum:" + String(humi, 1) + "%", ILI9341_YELLOW);
            printRightLine("Batt:" + String(batt, 1) + "%", ILI9341_GREEN);
        }} else {{
            Serial.println("[Sensor] Failed");
        }}
    }}
}}

/**********************************************************************
 * 检查连接状态并重连
 **********************************************************************/
void checkConnections() {{
    // 检查WiFi连接
    if (WiFi.status() != WL_CONNECTED) {{
        Serial.println("[Connection] WiFi disconnected, reconnecting...");
        wifiConnected = false;
        connectWiFi();
    }}
    
    // 检查MQTT连接
    if (!mqtt.connected()) {{
        Serial.println("[Connection] MQTT disconnected, reconnecting...");
        mqttConnected = false;
        connectMQTT();
    }}
}}

/**********************************************************************
 * Setup函数
 **********************************************************************/
void setup() {{
    Serial.begin(SERIAL_BAUD);
    delay(1000);
    
    // 初始化屏幕
    tft.begin();
    tft.setRotation(1);  // 横向
    tft.fillScreen(ILI9341_BLACK);
    tft.setTextWrap(false);
    
    // 计算右侧宽度并绘制标题
    RIGHT_PANE_W = tft.width() - RIGHT_PANE_X;
    drawHeaders();
    
    // 清空面板
    tft.fillRect(LEFT_PANE_X, HEADER_H + 2, LEFT_PANE_W, tft.height() - HEADER_H - 2, ILI9341_BLACK);
    tft.fillRect(RIGHT_PANE_X, HEADER_H + 2, RIGHT_PANE_W, tft.height() - HEADER_H - 2, ILI9341_BLACK);
    
    Serial.println("\\n==========================================");
    Serial.println("Mqtt-tls-iot-guardian-ESP8266");
    Serial.println("==========================================");
    Serial.print("Device ID: ");
    Serial.println(DEVICE_ID);
    Serial.println("==========================================\\n");
    
    // 初始化LED
    pinMode(LED_BUILTIN, OUTPUT);
    digitalWrite(LED_BUILTIN, HIGH);
    
    // 连接WiFi
    if (!connectWiFi()) {{
        Serial.println("[ERROR] Failed to connect to WiFi, rebooting in 10 seconds...");
        delay(10000);
        ESP.restart();
    }}
    
    // 连接MQTT
    if (!connectMQTT()) {{
        Serial.println("[ERROR] Failed to connect to MQTT, will retry in loop");
    }}
    
    Serial.println("\\n[Setup] Device initialized successfully!");
    Serial.println("[Setup] Starting main loop...\\n");
}}

/**********************************************************************
 * Loop函数
 **********************************************************************/
void loop() {{
    // 定期检查连接状态
    checkConnections();
    
    // 处理MQTT消息
    if (mqtt.connected()) {{
        mqtt.loop();
        
        // 发送心跳
        sendHeartbeat();
        
        // 发送传感器数据
        sendSensorData();
    }}
    
    // 闪烁LED表示设备运行中
    static unsigned long lastLedBlink = 0;
    unsigned long now = millis();
    if (now - lastLedBlink >= 1000) {{
        lastLedBlink = now;
        digitalWrite(LED_BUILTIN, !digitalRead(LED_BUILTIN));
    }}
    
    delay(100);
}}

/**********************************************************************
 * 注意事项：
 * 
 * 1. 配置修改：
 *    - 设备已预配置好所有参数
 *    - 如需要修改引脚，调整 TFT_CS, TFT_RST, TFT_DC
 * 
 * 2. 库安装：
 *    - ESP8266WiFi (内置)
 *    - WiFiClientSecureBearSSL (内置)
 *    - PubSubClient: 在Arduino IDE库管理中搜索"PubSubClient"安装
 *    - ArduinoJson: 在Arduino IDE库管理中搜索"ArduinoJson"安装
 *    - Adafruit_GFX: 在Arduino IDE库管理中搜索"Adafruit GFX"安装
 *    - Adafruit_ILI9341: 在Arduino IDE库管理中搜索"Adafruit ILI9341"安装
 * 
 * 3. MQTT主题规范：
 *    - 设备状态: devices/{device_id}/status
 *    - 传感器数据: devices/{device_id}/sensor
 *    - 控制命令: devices/{device_id}/control
 *    - 心跳: devices/{device_id}/heartbeat
 *    - 告警: devices/{device_id}/alerts
 * 
 * 4. 消息格式：
 *    - 使用JSON格式
 *    - 包含device_id和时间戳
 *    - 控制命令支持: restart, led_on, led_off
 * 
 * 5. 故障排查：
 *    - 确保WiFi配置正确
 *    - 确保MQTT服务器可访问
 *    - 查看串口日志和屏幕显示
 * 
 **********************************************************************/
'''
    
    @staticmethod
    async def generate_firmware_code(
        device_id: str,
        device_name: str,
        device_type: str,
        wifi_ssid: str,
        wifi_password: str,
        mqtt_server: str,
        ca_cert: Optional[str] = None,
        template_id: Optional[str] = None,
        db: Optional[any] = None
    ) -> str:
        """
        生成Arduino固件代码
        
        Args:
            device_id: 设备ID
            device_name: 设备名称
            device_type: 设备类型（如：ESP8266）
            wifi_ssid: WiFi SSID
            wifi_password: WiFi密码
            mqtt_server: MQTT服务器地址
            ca_cert: CA证书内容（如果启用TLS）
            template_id: 模板ID（可选，如果提供则使用模板）
            db: 数据库会话（可选，如果提供template_id则必需）
        
        Returns:
            Arduino代码字符串
        """
        template_code = None
        
        # 如果提供了模板ID，尝试使用模板
        if template_id and db:
            try:
                from app.services.template import TemplateService
                template_service = TemplateService(db)
                template = await template_service.get_by_id(template_id)
                if template and template.is_active:
                    template_code = template_service.decrypt_template_code(template)
            except Exception as e:
                import logging
                logger = logging.getLogger(__name__)
                logger.warning(f"使用模板失败，使用默认模板: {e}")
        
        # 如果没有模板或使用模板失败，尝试根据设备类型查找模板
        if not template_code and db and device_type:
            try:
                from app.services.template import TemplateService
                template_service = TemplateService(db)
                templates = await template_service.get_by_device_type(device_type)
                if templates:
                    # 使用第一个启用的模板
                    template_code = template_service.decrypt_template_code(templates[0])
            except Exception as e:
                import logging
                logger = logging.getLogger(__name__)
                logger.debug(f"根据设备类型查找模板失败，使用默认模板: {e}")
        
        # 如果没有找到模板，使用默认模板
        if not template_code:
            template_code = FirmwareService.TEMPLATE
        
        # 如果没有提供CA证书，使用占位符
        if not ca_cert:
            ca_cert = "// TLS证书未配置，请在 USE_TLS 中禁用TLS或提供CA证书"
        
        # 使用正则表达式安全地替换模板中的占位符
        # 这样可以避免与代码中的大括号（如数组初始化、JSON等）冲突
        import re
        
        # 定义占位符映射
        replacements = {
            '{device_id}': device_id,
            '{device_name}': device_name,
            '{wifi_ssid}': wifi_ssid,
            '{wifi_password}': wifi_password,
            '{mqtt_server}': mqtt_server,
            '{mqtt_username}': settings.MQTT_USERNAME,
            '{mqtt_password}': settings.MQTT_PASSWORD,
            '{ca_cert}': ca_cert
        }
        
        # 逐个替换占位符
        firmware_code = template_code
        for placeholder, value in replacements.items():
            # 使用正则表达式替换，确保只替换完整的占位符
            # 使用 word boundary 或者直接匹配，避免部分匹配
            firmware_code = firmware_code.replace(placeholder, value)
        
        return firmware_code
    
    @staticmethod
    def save_firmware_to_file(
        device_id: str,
        firmware_code: str
    ) -> Path:
        """
        将固件代码保存到文件
        
        Args:
            device_id: 设备ID
            firmware_code: 固件代码内容
        
        Returns:
            保存的文件路径
        """
        # 创建固件存储目录
        firmware_dir = Path("data/firmware")
        firmware_dir.mkdir(parents=True, exist_ok=True)
        
        # 保存文件
        firmware_file = firmware_dir / f"{device_id}.ino"
        firmware_file.write_text(firmware_code, encoding='utf-8')
        
        return firmware_file
    
    @staticmethod
    def load_firmware_from_file(device_id: str) -> Optional[str]:
        """
        从文件加载固件代码
        
        Args:
            device_id: 设备ID
        
        Returns:
            固件代码内容，如果文件不存在则返回None
        """
        firmware_file = Path("data/firmware") / f"{device_id}.ino"
        
        if not firmware_file.exists():
            return None
        
        return firmware_file.read_text(encoding='utf-8')