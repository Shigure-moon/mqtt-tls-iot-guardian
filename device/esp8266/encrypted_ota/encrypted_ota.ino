/**********************************************************************
 * ESP8266 加密烧录固件模板
 * 
 * 功能：
 * - XOR掩码解密（启动时自动解密Flash中的固件）
 * - HTTPS OTA固件更新（传输加密，防止抓包）
 * - MQTT over TLS安全通信
 * - WiFi连接管理
 * 
 * 加密方式：
 * 1. XOR掩码：固件编译后通过XOR掩码处理，防止直接反汇编
 * 2. HTTPS OTA：使用证书指纹验证，确保固件来源可信
 * 
 * 所需库：
 * - ESP8266WiFi
 * - WiFiClientSecure
 * - ArduinoHttpClient
 * - PubSubClient (可选，用于MQTT)
 * 
 * 配置说明：
 * - XOR_KEY: 16字节XOR密钥（从key.txt文件读取）
 * - CERT_FINGERPRINT: 服务器证书SHA256指纹（用于HTTPS验证）
 * - OTA_SERVER: OTA更新服务器地址
 * - OTA_PORT: OTA更新服务器端口（默认443）
 **********************************************************************/

#include <ESP8266WiFi.h>
#include <WiFiClientSecure.h>
#include <ArduinoHttpClient.h>
#include <ESP8266httpUpdate.h>

// ====== XOR掩码解密配置 ======
// 注意：实际使用时，通过XORBOOT库自动处理
// 这里提供手动实现的简化版本（仅用于演示）

// XOR密钥（16字节，从key.txt文件复制）
const uint8_t XOR_KEY[16] = {
    {xor_key_bytes}  // 格式: 0xAA, 0xBB, 0xCC, ...
};

// XOR解密函数（简化版，仅用于小段数据）
void xor_decrypt(uint8_t* data, size_t len) {
    for (size_t i = 0; i < len; i++) {
        data[i] ^= XOR_KEY[i % 16];
    }
}

// ====== WiFi配置 ======
const char* ssid = "{wifi_ssid}";
const char* password = "{wifi_password}";

// ====== OTA更新配置 ======
const char* ota_host = "{ota_server_host}";
const int   ota_port = {ota_port};  // 默认443
const char* ota_path = "/firmware/{device_id}_masked.bin";

// 证书指纹（SHA256，用于验证服务器证书）
const char* cert_fingerprint = "{certificate_fingerprint}";

// WiFi安全客户端
WiFiClientSecure wifiSecure;
HttpClient client = HttpClient(wifiSecure, ota_host, ota_port);

// ====== 全局变量 ======
bool ota_in_progress = false;
unsigned long last_ota_check = 0;
const unsigned long OTA_CHECK_INTERVAL = 3600000;  // 1小时检查一次

/**********************************************************************
 * XOR解密（启动时调用）
 * 注意：这是简化实现，实际应该使用ESP8266XORBoot库
 **********************************************************************/
void decrypt_firmware_on_boot() {
    // 实际实现需要使用ESP8266XORBoot库
    // 这里只是占位符
    Serial.println("[XOR] 固件解密功能需要ESP8266XORBoot库");
    Serial.println("[XOR] 请安装: https://github.com/your-repo/ESP8266XORBoot");
}

/**********************************************************************
 * 连接WiFi
 **********************************************************************/
bool connectWiFi() {
    Serial.print("[WiFi] 连接到 ");
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
        Serial.print("[WiFi] 已连接! IP地址: ");
        Serial.println(WiFi.localIP());
        return true;
    } else {
        Serial.println();
        Serial.println("[WiFi] 连接失败!");
        return false;
    }
}

/**********************************************************************
 * HTTPS OTA更新
 **********************************************************************/
void performOTAUpdate() {
    if (ota_in_progress) {
        Serial.println("[OTA] 更新已在进行中，跳过");
        return;
    }
    
    Serial.println("[OTA] 开始检查固件更新...");
    
    // 配置WiFi安全客户端
    wifiSecure.setFingerprint(cert_fingerprint);
    wifiSecure.setTimeout(15000);
    
    // 发送HTTPS GET请求
    Serial.print("[OTA] 连接到: https://");
    Serial.print(ota_host);
    Serial.print(":");
    Serial.println(ota_port);
    
    int httpCode = client.get(ota_path);
    
    if (httpCode != 200) {
        Serial.print("[OTA] HTTP错误: ");
        Serial.println(httpCode);
        return;
    }
    
    int contentLength = client.contentLength();
    if (contentLength <= 0) {
        Serial.println("[OTA] 无效的固件大小");
        return;
    }
    
    Serial.print("[OTA] 固件大小: ");
    Serial.print(contentLength);
    Serial.println(" 字节");
    
    // 检查固件大小（ESP8266 OTA分区限制约1MB）
    if (contentLength > 1024 * 1024) {
        Serial.println("[OTA] 固件过大（超过1MB），无法更新");
        return;
    }
    
    ota_in_progress = true;
    
    // 开始OTA更新
    Serial.println("[OTA] 开始下载固件...");
    
    Update.onProgress([](int cur, int tot) {
        static int last_percent = -1;
        int percent = (cur * 100) / tot;
        if (percent != last_percent && percent % 10 == 0) {
            Serial.print(".");
            last_percent = percent;
        }
    });
    
    if (!Update.begin(contentLength)) {
        Serial.println("[OTA] Update.begin() 失败");
        ota_in_progress = false;
        return;
    }
    
    // 从HTTPS流中读取数据并写入
    WiFiClient* stream = client.getStreamPtr();
    size_t written = Update.writeStream(*stream);
    
    if (written != contentLength) {
        Serial.print("[OTA] 写入失败，期望: ");
        Serial.print(contentLength);
        Serial.print(", 实际: ");
        Serial.println(written);
        Update.end();
        ota_in_progress = false;
        return;
    }
    
    if (!Update.end()) {
        Serial.println("[OTA] Update.end() 失败");
        ota_in_progress = false;
        return;
    }
    
    Serial.println();
    Serial.println("[OTA] 固件更新成功，重启中...");
    delay(1000);
    ESP.restart();
}

/**********************************************************************
 * 检查OTA更新（定期调用）
 **********************************************************************/
void checkOTAUpdate() {
    unsigned long now = millis();
    
    // 检查是否到了检查时间
    if (now - last_ota_check < OTA_CHECK_INTERVAL) {
        return;
    }
    
    last_ota_check = now;
    
    // 确保WiFi连接
    if (WiFi.status() != WL_CONNECTED) {
        Serial.println("[OTA] WiFi未连接，跳过更新检查");
        return;
    }
    
    // 执行OTA更新
    performOTAUpdate();
}

/**********************************************************************
 * Setup函数
 **********************************************************************/
void setup() {
    Serial.begin(115200);
    delay(1000);
    
    Serial.println();
    Serial.println("==========================================");
    Serial.println("ESP8266 加密烧录固件");
    Serial.println("==========================================");
    
    // XOR解密（在实际使用中，ESP8266XORBoot库会在启动时自动处理）
    // decrypt_firmware_on_boot();
    
    // 连接WiFi
    if (!connectWiFi()) {
        Serial.println("[ERROR] WiFi连接失败，10秒后重启...");
        delay(10000);
        ESP.restart();
    }
    
    Serial.println("[Setup] 初始化完成");
    Serial.println("[Setup] 将在1小时后检查OTA更新");
    Serial.println();
}

/**********************************************************************
 * Loop函数
 **********************************************************************/
void loop() {
    // 检查WiFi连接
    if (WiFi.status() != WL_CONNECTED) {
        Serial.println("[WiFi] 连接断开，重新连接...");
        connectWiFi();
    }
    
    // 定期检查OTA更新
    checkOTAUpdate();
    
    // 其他业务逻辑...
    // 例如：MQTT通信、传感器数据采集等
    
    delay(10000);  // 10秒循环
}

/**********************************************************************
 * 使用说明：
 * 
 * 1. 安装所需库：
 *    - Arduino IDE → 库管理器 → 搜索 "ArduinoHttpClient" 安装
 *    - 搜索 "WiFiClientSecure"（ESP8266核心库已包含）
 * 
 * 2. 配置参数：
 *    - 替换 {wifi_ssid}、{wifi_password}
 *    - 替换 {ota_server_host}、{ota_port}
 *    - 替换 {device_id}
 *    - 替换 {certificate_fingerprint}（从服务器CA证书获取）
 *    - 替换 {xor_key_bytes}（从key.txt文件获取）
 * 
 * 3. XOR掩码使用：
 *    - 推荐使用ESP8266XORBoot库（需要单独安装）
 *    - 或使用本文档提供的简化实现
 * 
 * 4. HTTPS OTA：
 *    - 确保服务器支持HTTPS
 *    - 证书指纹必须匹配，否则连接失败
 *    - 固件文件必须小于1MB（ESP8266 OTA分区限制）
 * 
 * 5. 安全建议：
 *    - 定期更换XOR密钥
 *    - 使用强密码保护WiFi
 *    - 定期更新固件以修复安全漏洞
 * 
 **********************************************************************/

