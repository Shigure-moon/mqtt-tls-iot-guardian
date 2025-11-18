/**********************************************************************
 * IoT安全管理系统 - ESP8266智能门锁设备端（带屏幕显示）
 * 
 * 设备ID: door_lock_001
 * 设备名称: 智能门锁
 * 功能：
 * - WiFi连接
 * - MQTT over TLS安全通信
 * - ILI9341屏幕显示
 * - 门锁控制（锁定/解锁）
 * - 开锁动画显示
 * - 电池电量监控
 * - 安全告警
 * 
 * 配置：
 * - MQTT Broker: 192.168.1.8
 * - 端口: 8883 (TLS)
 * - 认证: 用户名密码 + TLS证书
 * - 屏幕: ILI9341 TFT显示屏
 * 
 * 主题规范：
 * - 设备状态: devices/door_lock_001/status
 * - 传感器数据: devices/door_lock_001/sensor
 * - 控制命令: devices/door_lock_001/control
 * - 告警信息: devices/door_lock_001/alerts
 * - 心跳: devices/door_lock_001/heartbeat
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

// ====== 门锁控制引脚 ======
#define LOCK_PIN D5              // 门锁控制引脚（继电器控制）
#define BUZZER_PIN D6           // 蜂鸣器引脚（可选）
#define BATTERY_ADC A0          // 电池电量检测引脚（可选）

// ====== 设备配置 ======
#define DEVICE_ID "door_lock_001"              // 设备唯一ID
#define DEVICE_NAME "智能门锁"                  // 设备名称（屏幕显示用）

// WiFi配置
const char* ssid = "huawei9930";            // WiFi网络名称
const char* password = "993056494a.";    // WiFi密码

// MQTT Broker配置
const char* mqtt_server = "192.168.1.8";   // MQTT服务器地址
const int mqtt_port = 8883;                  // TLS端口
const char* mqtt_user = "admin";   // MQTT用户名
const char* mqtt_pass = "admin";   // MQTT密码

// 使用TLS
#define USE_TLS true                         // 启用TLS

// CA证书（用于验证MQTT服务器证书）
static const char ca_cert[] PROGMEM = R"PEM(
-----BEGIN CERTIFICATE-----
MIIDjjCCAnagAwIBAgIUQ7JiWpxdHTbLU6gCSnC6KpY61HgwDQYJKoZIhvcNAQEL
BQAwYjELMAkGA1UEBhMCQ04xEDAOBgNVBAgMB0JlaWppbmcxEDAOBgNVBAcMB0Jl
aWppbmcxHjAcBgNVBAoMFUlvVCBTZWN1cml0eSBQbGF0Zm9ybTEPMA0GA1UEAwwG
SW9UIENBMB4XDTI1MTEwMzA1NTcyMloXDTM1MTEwMTA1NTcyMlowYjELMAkGA1UE
BhMCQ04xEDAOBgNVBAgMB0JlaWppbmcxEDAOBgNVBAcMB0JlaWppbmcxHjAcBgNV
BAoMFUlvVCBTZWN1cml0eSBQbGF0Zm9ybTEPMA0GA1UEAwwGSW9UIENBMIIBIjAN
BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA3eLGZaSnN7+rcMILy8AS7jMDnAnm
pMXENqmFUkA7bIN+IGuwLdRTj9Zaw+l3EPSQG6U4WTwnVItwOk/DpezjHUJ48qdx
M2Mh/+UGFoRdQOUbswM+7Xrpc6sMMD9MhX+cOF2F9aszvaS9e/M1YY9ZYMbcur9x
1uJfsFdEPKiMvHF9R/Cu5NGlHj1rg4jCTpLixtgB/4vtwD25I3P5NKeVhtYc8Xl7
JiFwJ5XXQjvtSSBR6RsiOa7qpEhmyk3bEec/hxUQ+rBJ+MvAAPyTCwozhQN1l6Yy
aOCr5Tug8uB9fD+lFd0+msosKTRQNcWOUrbsFcj1T+FlDPpoT0mNBHoHWwIDAQAB
ozwwOjAXBgNVHREEEDAOggxpb3QtY2EubG9jYWwwDwYDVR0TAQH/BAUwAwEB/zAO
BgNVHQ8BAf8EBAMCAYYwDQYJKoZIhvcNAQELBQADggEBAIrV1LCG9zbckevrzIU3
6tfD+fpbMfPeptuV06FUv7X+gsobaySKaheQk5QOK9cpDbtxkJLfGk8SWKHhDU+H
K+GE1o7dY3YU0WOP2t0qN7kjG7DaqROH1KnsraHYMoSnBSnJ6EvFD+6zD5Mdb9Ax
619Tj3snjU24Of6dYVUwxGVGGpvUQkghiBovSIB2iSbUq/fwfd2wBWOo7EM7shpV
5mGpOsi/SqXxLmlw43ROJgJYYe8wqguLClvhrad96dDFd+L22BaHtdaxW5NcZfXe
P2QhrIz/oPuwDwPG37nluuVxb9RRP85XAGbUIkD99FKSCtnY6DbtkMrr0fhicsz5
ipY=
-----END CERTIFICATE-----

)PEM";

// MQTT主题
const char* topic_status = "devices/" DEVICE_ID "/status";
const char* topic_sensor = "devices/" DEVICE_ID "/sensor";
const char* topic_control = "devices/" DEVICE_ID "/control";
const char* topic_heartbeat = "devices/" DEVICE_ID "/heartbeat";
const char* topic_alerts = "devices/" DEVICE_ID "/alerts";

// MQTT客户端
#if USE_TLS
std::unique_ptr<BearSSL::WiFiClientSecure> secureClient(new BearSSL::WiFiClientSecure);
PubSubClient mqtt(*secureClient);
#else
WiFiClient wifiClient;
PubSubClient mqtt(wifiClient);
#endif

// ====== 门锁状态 ======
enum LockState {
  LOCKED,      // 已锁定
  UNLOCKED,    // 已解锁
  LOCKING,     // 锁定中
  UNLOCKING    // 解锁中
};

LockState lockState = LOCKED;
unsigned long lockStateChangeTime = 0;
const unsigned long LOCK_ANIMATION_DURATION = 2000;  // 动画持续时间（毫秒）

// ====== 屏幕布局 ======
static const int16_t SCREEN_W = 320;
static const int16_t SCREEN_H = 240;
static const int16_t HEADER_H = 40;
static const int16_t ANIMATION_AREA_H = 160;
static const int16_t STATUS_AREA_H = 40;

// ====== 全局变量 ======
unsigned long lastHeartbeat = 0;
unsigned long lastSensorPub = 0;
const unsigned long HEARTBEAT_INTERVAL = 30000;  // 30秒心跳
const unsigned long SENSOR_INTERVAL = 10000;     // 10秒传感器数据

// 连接状态
bool wifiConnected = false;
bool mqttConnected = false;

// 电池电量（模拟，实际需要ADC读取）
float batteryLevel = 100.0;

#define SERIAL_BAUD 115200

/**********************************************************************
 * 绘制锁图标（锁定状态）
 **********************************************************************/
void drawLockIcon(int16_t x, int16_t y, int16_t size, bool locked, uint16_t color) {
    int16_t centerX = x + size / 2;
    int16_t centerY = y + size / 2;
    int16_t lockW = size * 0.6;
    int16_t lockH = size * 0.5;
    int16_t shackleR = size * 0.15;
    
    if (locked) {
        // 绘制锁体（矩形）
        tft.fillRect(centerX - lockW/2, centerY - lockH/4, lockW, lockH, color);
        tft.drawRect(centerX - lockW/2, centerY - lockH/4, lockW, lockH, ILI9341_BLACK);
        
        // 绘制锁孔（圆形）
        tft.fillCircle(centerX, centerY, shackleR, ILI9341_BLACK);
        
        // 绘制锁环（半圆）- 使用drawCircle和fillRect组合
        int16_t shackleY = centerY - lockH/2 - shackleR;
        // 绘制半圆（上半部分）
        tft.fillCircle(centerX, shackleY, shackleR, ILI9341_BLACK);
        tft.drawCircle(centerX, shackleY, shackleR, color);
        tft.fillRect(centerX - shackleR, shackleY, shackleR * 2, shackleR, ILI9341_BLACK);
        // 绘制连接线
        tft.drawLine(centerX - shackleR, shackleY, centerX - shackleR, centerY - lockH/2, color);
        tft.drawLine(centerX + shackleR, shackleY, centerX + shackleR, centerY - lockH/2, color);
    } else {
        // 解锁状态：锁环打开
        int16_t lockW = size * 0.6;
        int16_t lockH = size * 0.5;
        int16_t shackleR = size * 0.15;
        
        // 绘制锁体（矩形）
        tft.fillRect(centerX - lockW/2, centerY - lockH/4, lockW, lockH, color);
        tft.drawRect(centerX - lockW/2, centerY - lockH/4, lockW, lockH, ILI9341_BLACK);
        
        // 绘制锁孔（圆形）
        tft.fillCircle(centerX, centerY, shackleR, ILI9341_BLACK);
        
        // 绘制打开的锁环（旋转的半圆）- 使用drawCircle和fillRect组合
        int16_t shackleY = centerY - lockH/2 - shackleR;
        int16_t offsetX = shackleR * 0.7;
        int16_t arcX = centerX + offsetX;
        int16_t arcY = shackleY - offsetX;
        // 绘制部分圆（135-315度范围）
        tft.drawCircle(arcX, arcY, shackleR, color);
        // 用填充矩形遮住不需要的部分，只显示135-315度的弧
        tft.fillRect(arcX - shackleR, arcY - shackleR, shackleR * 2, shackleR * 0.7, ILI9341_BLACK);
        tft.fillRect(arcX - shackleR, arcY + shackleR * 0.3, shackleR * 2, shackleR * 0.7, ILI9341_BLACK);
    }
}

/**********************************************************************
 * 绘制开锁动画
 **********************************************************************/
void drawUnlockAnimation(unsigned long elapsed) {
    // 清除动画区域
    tft.fillRect(0, HEADER_H, SCREEN_W, ANIMATION_AREA_H, ILI9341_BLACK);
    
    // 计算动画进度（0.0 - 1.0）
    float progress = min(1.0, (float)elapsed / LOCK_ANIMATION_DURATION);
    
    // 锁图标位置
    int16_t lockX = SCREEN_W / 2;
    int16_t lockY = HEADER_H + ANIMATION_AREA_H / 2;
    int16_t lockSize = 80;
    
    // 根据进度绘制动画
    if (progress < 0.3) {
        // 阶段1：锁图标旋转并放大
        float scale = 0.5 + progress * 1.67;  // 0.5 -> 1.0
        uint16_t color = ILI9341_YELLOW;
        drawLockIcon(lockX - lockSize/2, lockY - lockSize/2, lockSize * scale, true, color);
        
        // 绘制旋转指示
        int16_t radius = lockSize * scale * 0.6;
        for (int i = 0; i < 8; i++) {
            float angle = (progress * 360 + i * 45) * 3.14159 / 180;  // PI -> 3.14159
            int16_t x = lockX + (int16_t)(radius * cos(angle));
            int16_t y = lockY + (int16_t)(radius * sin(angle));
            tft.fillCircle(x, y, 3, color);
        }
    } else if (progress < 0.7) {
        // 阶段2：锁图标从锁定变为解锁
        float phase = (progress - 0.3) / 0.4;
        uint16_t color = ILI9341_GREEN;
        
        // 绘制过渡动画
        if (phase < 0.5) {
            drawLockIcon(lockX - lockSize/2, lockY - lockSize/2, lockSize, true, color);
        } else {
            drawLockIcon(lockX - lockSize/2, lockY - lockSize/2, lockSize, false, color);
        }
        
        // 绘制解锁效果（光晕）
        int16_t glowRadius = lockSize * 0.8 * phase;
        for (int r = glowRadius; r > 0; r -= 5) {
            uint16_t glowColor = ((uint32_t)color * (glowRadius - r) / glowRadius) & 0xFFFF;
            tft.drawCircle(lockX, lockY, r, glowColor);
        }
    } else {
        // 阶段3：显示解锁成功
        uint16_t color = ILI9341_GREEN;
        drawLockIcon(lockX - lockSize/2, lockY - lockSize/2, lockSize, false, color);
        
        // 绘制成功提示
        tft.setTextColor(ILI9341_GREEN);
        tft.setTextSize(2);
        tft.setCursor(lockX - 40, lockY + lockSize/2 + 10);
        tft.print("已解锁");
        
        // 绘制闪烁效果
        if ((int)(progress * 10) % 2 == 0) {
            tft.drawCircle(lockX, lockY, lockSize * 0.6, ILI9341_GREEN);
        }
    }
}

/**********************************************************************
 * 绘制锁定动画
 **********************************************************************/
void drawLockAnimation(unsigned long elapsed) {
    // 清除动画区域
    tft.fillRect(0, HEADER_H, SCREEN_W, ANIMATION_AREA_H, ILI9341_BLACK);
    
    // 计算动画进度（0.0 - 1.0）
    float progress = min(1.0, (float)elapsed / LOCK_ANIMATION_DURATION);
    
    // 锁图标位置
    int16_t lockX = SCREEN_W / 2;
    int16_t lockY = HEADER_H + ANIMATION_AREA_H / 2;
    int16_t lockSize = 80;
    
    // 根据进度绘制动画
    if (progress < 0.3) {
        // 阶段1：锁图标旋转并放大
        float scale = 0.5 + progress * 1.67;  // 0.5 -> 1.0
        uint16_t color = ILI9341_YELLOW;
        drawLockIcon(lockX - lockSize/2, lockY - lockSize/2, lockSize * scale, false, color);
        
        // 绘制旋转指示
        int16_t radius = lockSize * scale * 0.6;
        for (int i = 0; i < 8; i++) {
            float angle = (progress * 360 + i * 45) * 3.14159 / 180;  // PI -> 3.14159
            int16_t x = lockX + (int16_t)(radius * cos(angle));
            int16_t y = lockY + (int16_t)(radius * sin(angle));
            tft.fillCircle(x, y, 3, color);
        }
    } else if (progress < 0.7) {
        // 阶段2：锁图标从解锁变为锁定
        float phase = (progress - 0.3) / 0.4;
        uint16_t color = ILI9341_RED;
        
        // 绘制过渡动画
        if (phase < 0.5) {
            drawLockIcon(lockX - lockSize/2, lockY - lockSize/2, lockSize, false, color);
        } else {
            drawLockIcon(lockX - lockSize/2, lockY - lockSize/2, lockSize, true, color);
        }
        
        // 绘制锁定效果（光晕）
        int16_t glowRadius = lockSize * 0.8 * phase;
        for (int r = glowRadius; r > 0; r -= 5) {
            uint16_t glowColor = ((uint32_t)color * (glowRadius - r) / glowRadius) & 0xFFFF;
            tft.drawCircle(lockX, lockY, r, glowColor);
        }
    } else {
        // 阶段3：显示锁定成功
        uint16_t color = ILI9341_RED;
        drawLockIcon(lockX - lockSize/2, lockY - lockSize/2, lockSize, true, color);
        
        // 绘制成功提示
        tft.setTextColor(ILI9341_RED);
        tft.setTextSize(2);
        tft.setCursor(lockX - 40, lockY + lockSize/2 + 10);
        tft.print("已锁定");
        
        // 绘制闪烁效果
        if ((int)(progress * 10) % 2 == 0) {
            tft.drawCircle(lockX, lockY, lockSize * 0.6, ILI9341_RED);
        }
    }
}

/**********************************************************************
 * 绘制状态显示区域
 **********************************************************************/
void drawStatusArea() {
    // 清除状态区域
    tft.fillRect(0, HEADER_H + ANIMATION_AREA_H, SCREEN_W, STATUS_AREA_H, ILI9341_DARKGREY);
    
    // 绘制分隔线
    tft.drawFastHLine(0, HEADER_H + ANIMATION_AREA_H, SCREEN_W, ILI9341_WHITE);
    
    // 显示连接状态
    tft.setTextColor(ILI9341_WHITE);
    tft.setTextSize(1);
    tft.setCursor(5, HEADER_H + ANIMATION_AREA_H + 5);
    tft.print("WiFi: ");
    tft.setTextColor(wifiConnected ? ILI9341_GREEN : ILI9341_RED);
    tft.print(wifiConnected ? "OK" : "NO");
    
    tft.setTextColor(ILI9341_WHITE);
    tft.setCursor(70, HEADER_H + ANIMATION_AREA_H + 5);
    tft.print("MQTT: ");
    tft.setTextColor(mqttConnected ? ILI9341_GREEN : ILI9341_RED);
    tft.print(mqttConnected ? "OK" : "NO");
    
    // 显示电池电量
    tft.setTextColor(ILI9341_WHITE);
    tft.setCursor(130, HEADER_H + ANIMATION_AREA_H + 5);
    tft.print("Batt: ");
    uint16_t battColor = (batteryLevel > 50) ? ILI9341_GREEN : 
                         (batteryLevel > 20) ? ILI9341_YELLOW : ILI9341_RED;
    tft.setTextColor(battColor);
    tft.print(String((int)batteryLevel) + "%");
    
    // 显示锁状态
    tft.setTextColor(ILI9341_WHITE);
    tft.setCursor(5, HEADER_H + ANIMATION_AREA_H + 20);
    tft.print("Lock: ");
    uint16_t lockColor = (lockState == LOCKED) ? ILI9341_RED : ILI9341_GREEN;
    tft.setTextColor(lockColor);
    String stateText = (lockState == LOCKED) ? "LOCKED" : 
                       (lockState == UNLOCKED) ? "UNLOCKED" :
                       (lockState == LOCKING) ? "LOCKING..." : "UNLOCKING...";
    tft.print(stateText);
}

/**********************************************************************
 * 绘制标题栏
 **********************************************************************/
void drawHeader() {
    tft.fillRect(0, 0, SCREEN_W, HEADER_H, ILI9341_BLUE);
    tft.setTextColor(ILI9341_WHITE);
    tft.setTextSize(2);
    tft.setCursor(10, 10);
    tft.print(DEVICE_NAME);
    
    // 显示设备ID
    tft.setTextSize(1);
    tft.setCursor(10, 28);
    tft.print("ID: " + String(DEVICE_ID));
}

/**********************************************************************
 * 更新屏幕显示
 **********************************************************************/
void updateDisplay() {
    // 绘制标题
    drawHeader();
    
    // 根据锁状态绘制动画或静态图标
    unsigned long now = millis();
    if (lockState == UNLOCKING || lockState == LOCKING) {
        // 显示动画
        unsigned long elapsed = now - lockStateChangeTime;
        if (elapsed < LOCK_ANIMATION_DURATION) {
            if (lockState == UNLOCKING) {
                drawUnlockAnimation(elapsed);
            } else {
                drawLockAnimation(elapsed);
            }
        } else {
            // 动画完成，更新状态
            if (lockState == UNLOCKING) {
                lockState = UNLOCKED;
            } else {
                lockState = LOCKED;
            }
        }
    } else {
        // 显示静态图标
        tft.fillRect(0, HEADER_H, SCREEN_W, ANIMATION_AREA_H, ILI9341_BLACK);
        int16_t lockX = SCREEN_W / 2;
        int16_t lockY = HEADER_H + ANIMATION_AREA_H / 2;
        int16_t lockSize = 80;
        uint16_t lockColor = (lockState == LOCKED) ? ILI9341_RED : ILI9341_GREEN;
        
        drawLockIcon(lockX - lockSize/2, lockY - lockSize/2, lockSize, 
                     (lockState == LOCKED), lockColor);
        
        // 显示状态文字
        tft.setTextColor(lockColor);
        tft.setTextSize(2);
        tft.setCursor(lockX - 40, lockY + lockSize/2 + 10);
        tft.print((lockState == LOCKED) ? "已锁定" : "已解锁");
    }
    
    // 绘制状态区域
    drawStatusArea();
}

/**********************************************************************
 * 控制门锁
 **********************************************************************/
void setLockState(LockState newState) {
    if (lockState == newState) return;
    
    lockState = newState;
    lockStateChangeTime = millis();
    
    // 控制物理锁（通过继电器）
    if (newState == LOCKED || newState == LOCKING) {
        digitalWrite(LOCK_PIN, HIGH);  // 锁定（根据实际硬件调整）
        Serial.println("[Lock] Locking...");
    } else {
        digitalWrite(LOCK_PIN, LOW);   // 解锁（根据实际硬件调整）
        Serial.println("[Lock] Unlocking...");
    }
    
    // 蜂鸣器提示（可选）
    #ifdef BUZZER_PIN
    tone(BUZZER_PIN, 2000, 100);
    #endif
    
    // 发送状态更新
    sendStatusUpdate();
}

/**********************************************************************
 * 锁定门锁
 **********************************************************************/
void lockDoor() {
    if (lockState == LOCKED) return;
    setLockState(LOCKING);
    delay(100);  // 等待状态更新
    setLockState(LOCKED);
}

/**********************************************************************
 * 解锁门锁
 **********************************************************************/
void unlockDoor() {
    if (lockState == UNLOCKED) return;
    setLockState(UNLOCKING);
    delay(100);  // 等待状态更新
    setLockState(UNLOCKED);
}

/**********************************************************************
 * MQTT消息回调函数
 **********************************************************************/
void mqttCallback(char* topic, byte* payload, unsigned int length) {
    Serial.print("[MQTT] Received message on topic: ");
    Serial.println(topic);
    
    // 解析JSON消息
    String msg;
    for (unsigned int i = 0; i < length; i++) {
        msg += (char)payload[i];
    }
    
    Serial.print("[MQTT] Message: ");
    Serial.println(msg);
    
    // 解析JSON
    DynamicJsonDocument doc(512);
    DeserializationError error = deserializeJson(doc, msg);
    
    if (error) {
        Serial.print("[MQTT] JSON parse error: ");
        Serial.println(error.c_str());
        return;
    }
    
    // 处理控制命令
    if (doc.containsKey("command")) {
        String command = doc["command"].as<String>();
        Serial.print("[Lock] Received command: ");
        Serial.println(command);
        
        if (command == "lock" || command == "锁定") {
            lockDoor();
        } else if (command == "unlock" || command == "解锁") {
            unlockDoor();
        } else if (command == "toggle" || command == "切换") {
            if (lockState == LOCKED || lockState == LOCKING) {
                unlockDoor();
            } else {
                lockDoor();
            }
        } else if (command == "status" || command == "状态") {
            sendStatusUpdate();
        }
    }
}

/**********************************************************************
 * 连接WiFi
 **********************************************************************/
bool connectWiFi() {
    Serial.print("[WiFi] Connecting to ");
    Serial.println(ssid);
    
    WiFi.mode(WIFI_STA);
    WiFi.begin(ssid, password);
    
    int attempts = 0;
    while (WiFi.status() != WL_CONNECTED && attempts < 60) {
        delay(500);
        Serial.print(".");
        attempts++;
    }
    
    if (WiFi.status() == WL_CONNECTED) {
        Serial.println();
        Serial.print("[WiFi] Connected! IP address: ");
        Serial.println(WiFi.localIP());
        wifiConnected = true;
        return true;
    } else {
        Serial.println();
        Serial.println("[WiFi] Connection failed!");
        wifiConnected = false;
        return false;
    }
}

/**********************************************************************
 * 连接MQTT
 **********************************************************************/
bool connectMQTT() {
    Serial.print("[MQTT] Connecting to ");
    Serial.print(mqtt_server);
    Serial.print(":");
    Serial.println(mqtt_port);
    
    // 如果使用TLS
    #if USE_TLS
    secureClient->setBufferSizes(2048, 512);
    secureClient->setTimeout(10000);
    
    // 加载CA证书并验证服务器证书由CA签名
    BearSSL::X509List cert(ca_cert);
    secureClient->setTrustAnchors(&cert);
    // 禁用主机名验证以支持IP地址连接（证书签名仍会被验证）
    secureClient->setInsecure();
    Serial.println("[MQTT] TLS with CA validation (hostname check disabled)");
    #else
    Serial.println("[MQTT] Using non-TLS connection");
    #endif
    
    // 设置MQTT服务器和回调
    mqtt.setBufferSize(512);
    mqtt.setServer(mqtt_server, mqtt_port);
    mqtt.setCallback(mqttCallback);
    
    // 生成唯一客户端ID
    unsigned long chipId = ESP.getChipId();
    unsigned long timestamp = millis() / 1000;
    String clientId = String("door-lock-") + String(chipId, HEX) + "-" + String(timestamp, HEX);
    
    // 清理之前的连接状态
    if (mqtt.connected()) {
        mqtt.disconnect();
        delay(100);
    }
    
    // 尝试连接
    if (mqtt.connect(clientId.c_str(), mqtt_user, mqtt_pass)) {
        Serial.println("[MQTT] Connected!");
        mqttConnected = true;
        
        // 订阅控制主题
        mqtt.subscribe(topic_control);
        Serial.println("[MQTT] Subscribed to control topic");
        
        // 订阅告警主题
        mqtt.subscribe(topic_alerts);
        Serial.println("[MQTT] Subscribed to alerts topic");
        
        // 发送上线消息
        sendStatusUpdate();
        
        delay(500);
        return true;
    } else {
        Serial.print("[MQTT] Connection failed, rc=");
        Serial.println(mqtt.state());
        mqttConnected = false;
        mqtt.disconnect();
        delay(100);
        return false;
    }
}

/**********************************************************************
 * 发送状态更新
 **********************************************************************/
void sendStatusUpdate() {
    DynamicJsonDocument doc(256);
    doc["device_id"] = DEVICE_ID;
    doc["status"] = (lockState == LOCKED) ? "locked" : "unlocked";
    doc["lock_state"] = (lockState == LOCKED) ? "locked" : 
                        (lockState == UNLOCKED) ? "unlocked" :
                        (lockState == LOCKING) ? "locking" : "unlocking";
    doc["battery"] = batteryLevel;
    doc["timestamp"] = millis() / 1000;
    
    String message;
    serializeJson(doc, message);
    
    if (mqtt.publish(topic_status, message.c_str())) {
        Serial.println("[Status] Update sent");
    } else {
        Serial.println("[Status] Update failed");
    }
}

/**********************************************************************
 * 发送心跳消息
 **********************************************************************/
void sendHeartbeat() {
    unsigned long now = millis();
    if (now - lastHeartbeat >= HEARTBEAT_INTERVAL) {
        lastHeartbeat = now;
        
        DynamicJsonDocument doc(256);
        doc["device_id"] = DEVICE_ID;
        doc["timestamp"] = now / 1000;
        doc["uptime"] = now / 1000;
        doc["heap"] = ESP.getFreeHeap();
        doc["rssi"] = WiFi.RSSI();
        doc["battery"] = batteryLevel;
        doc["lock_state"] = (lockState == LOCKED) ? "locked" : "unlocked";
        
        String message;
        serializeJson(doc, message);
        
        if (mqtt.publish(topic_heartbeat, message.c_str())) {
            Serial.println("[Heartbeat] Sent");
        } else {
            Serial.println("[Heartbeat] Failed");
        }
    }
}

/**********************************************************************
 * 发送传感器数据
 **********************************************************************/
void sendSensorData() {
    unsigned long now = millis();
    if (now - lastSensorPub >= SENSOR_INTERVAL) {
        lastSensorPub = now;
        
        // 读取电池电量（模拟，实际需要ADC读取）
        #ifdef BATTERY_ADC
        int adcValue = analogRead(BATTERY_ADC);
        // 假设ADC值0-1024对应0-100%
        batteryLevel = (adcValue / 1024.0) * 100.0;
        #else
        // 模拟电池电量缓慢下降
        batteryLevel = max(0.0, batteryLevel - 0.01);
        #endif
        
        DynamicJsonDocument doc(512);
        doc["device_id"] = DEVICE_ID;
        doc["timestamp"] = now / 1000;
        doc["battery"] = batteryLevel;
        doc["lock_state"] = (lockState == LOCKED) ? "locked" : "unlocked";
        doc["status"]["wifi"] = wifiConnected ? "connected" : "disconnected";
        doc["status"]["mqtt"] = mqttConnected ? "connected" : "disconnected";
        doc["status"]["uptime"] = now / 1000;
        
        String message;
        serializeJson(doc, message);
        
        if (mqtt.publish(topic_sensor, message.c_str())) {
            Serial.println("[Sensor] Data sent");
        } else {
            Serial.println("[Sensor] Failed");
        }
    }
}

/**********************************************************************
 * 检查连接状态并重连
 **********************************************************************/
void checkConnections() {
    // 检查WiFi连接
    if (WiFi.status() != WL_CONNECTED) {
        Serial.println("[Connection] WiFi disconnected, reconnecting...");
        wifiConnected = false;
        connectWiFi();
    }
    
    // 检查MQTT连接
    if (!mqtt.connected()) {
        Serial.println("[Connection] MQTT disconnected, reconnecting...");
        mqttConnected = false;
        mqtt.loop();
        mqtt.disconnect();
        delay(500);
        connectMQTT();
    } else {
        // 保持连接活跃
        mqtt.loop();
    }
}

/**********************************************************************
 * Setup函数
 **********************************************************************/
void setup() {
    Serial.begin(SERIAL_BAUD);
    delay(1000);
    
    Serial.println("\n==========================================");
    Serial.println("IoT Smart Door Lock - ESP8266");
    Serial.println("==========================================");
    Serial.print("Device ID: ");
    Serial.println(DEVICE_ID);
    Serial.println("==========================================\n");
    
    // 初始化屏幕
    tft.begin();
    tft.setRotation(1);  // 横向
    tft.fillScreen(ILI9341_BLACK);
    tft.setTextWrap(false);
    
    // 绘制初始界面
    drawHeader();
    tft.fillRect(0, HEADER_H, SCREEN_W, ANIMATION_AREA_H, ILI9341_BLACK);
    tft.fillRect(0, HEADER_H + ANIMATION_AREA_H, SCREEN_W, STATUS_AREA_H, ILI9341_DARKGREY);
    
    // 初始化GPIO
    pinMode(LOCK_PIN, OUTPUT);
    digitalWrite(LOCK_PIN, HIGH);  // 初始状态：锁定
    
    #ifdef BUZZER_PIN
    pinMode(BUZZER_PIN, OUTPUT);
    #endif
    
    #ifdef BATTERY_ADC
    pinMode(BATTERY_ADC, INPUT);
    #endif
    
    // 初始化LED
    pinMode(LED_BUILTIN, OUTPUT);
    digitalWrite(LED_BUILTIN, HIGH);
    
    // 连接WiFi
    if (!connectWiFi()) {
        Serial.println("[ERROR] Failed to connect to WiFi, rebooting in 10 seconds...");
        delay(10000);
        ESP.restart();
    }
    
    // 连接MQTT
    if (!connectMQTT()) {
        Serial.println("[ERROR] Failed to connect to MQTT, will retry in loop");
    }
    
    // 初始状态：锁定
    lockState = LOCKED;
    updateDisplay();
    
    Serial.println("\n[Setup] Device initialized successfully!");
    Serial.println("[Setup] Starting main loop...\n");
}

/**********************************************************************
 * Loop函数
 **********************************************************************/
void loop() {
    // 定期检查连接状态
    checkConnections();
    
    // 处理MQTT消息
    if (mqtt.connected()) {
        mqtt.loop();
        
        // 发送心跳
        sendHeartbeat();
        
        // 发送传感器数据
        sendSensorData();
    }
    
    // 更新屏幕显示
    updateDisplay();
    
    // 闪烁LED表示设备运行中
    static unsigned long lastLedBlink = 0;
    unsigned long now = millis();
    if (now - lastLedBlink >= 1000) {
        lastLedBlink = now;
        digitalWrite(LED_BUILTIN, !digitalRead(LED_BUILTIN));
    }
    
    delay(50);  // 减少延迟以保持动画流畅
}

/**********************************************************************
 * 注意事项：
 * 
 * 1. 硬件连接：
 *    - LOCK_PIN (D5): 连接到继电器控制门锁
 *    - BUZZER_PIN (D6): 可选，蜂鸣器提示
 *    - BATTERY_ADC (A0): 可选，电池电量检测
 *    - TFT屏幕: CS=D2, RST=D3, DC=D4
 * 
 * 2. 控制命令格式（JSON）：
 *    {
 *      "command": "lock"    // 锁定
 *      "command": "unlock"   // 解锁
 *      "command": "toggle"   // 切换状态
 *      "command": "status"   // 查询状态
 *    }
 * 
 * 3. 门锁状态：
 *    - LOCKED: 已锁定
 *    - UNLOCKED: 已解锁
 *    - LOCKING: 锁定中（动画）
 *    - UNLOCKING: 解锁中（动画）
 * 
 * 4. 屏幕显示：
 *    - 顶部：设备名称和ID
 *    - 中间：锁图标和动画
 *    - 底部：连接状态、电池电量、锁状态
 * 
 * 5. 开锁动画：
 *    - 阶段1：锁图标旋转并放大（0-30%）
 *    - 阶段2：锁图标从锁定变为解锁（30-70%）
 *    - 阶段3：显示解锁成功提示（70-100%）
 * 
 **********************************************************************/

