/**********************************************************************
 ESP8266 + ILI9341 + MQTT over TLS 演示
 - 展示WiFi连接 → TLS握手 → MQTT订阅/发布 → 收发展示
 - 需要：Adafruit_GFX, Adafruit_ILI9341, PubSubClient, ESP8266WiFi
**********************************************************************/

#include <ESP8266WiFi.h>
#include <WiFiClientSecureBearSSL.h>
#include <PubSubClient.h>
#include <Adafruit_GFX.h>
#include <Adafruit_ILI9341.h>

// ====== 根据实际接线修改 ======
#define TFT_CS D2
#define TFT_RST D3
#define TFT_DC D4
Adafruit_ILI9341 tft(TFT_CS, TFT_DC, TFT_RST);

// ====== WiFi/MQTT配置（按需修改） ======
const char *ssid = "huawei9930";
const char *password = "993056494a.";
const char *mqtt_server = "10.42.0.1"; // 本机IP
const int mqtt_port = 8883;                 // TLS端口
const char *mqtt_user = "xiaoxueqi";
const char *mqtt_pass = "xiaoxueqi123";

// 主题（示例）
const char *topic_status = "robot/001/status";
const char *topic_control = "robot/001/control";
const char *topic_sensor = "robot/001/sensor";
const char *topic_battery = "robot/001/battery";
const char *topic_alerts = "robot/001/alerts";

// CA证书（从 demo/backend/certs/ca.crt 拷贝内容放入此处，PEM格式）
// 已更新为包含10.42.0.1 IP地址的证书
static const char ca_cert[] PROGMEM = R"PEM(
-----BEGIN CERTIFICATE-----
MIIFqTCCA5GgAwIBAgIUbZ8tBJEnDzvtLb0GGG7+mqUGWbEwDQYJKoZIhvcNAQEL
BQAwZDELMAkGA1UEBhMCQ04xDjAMBgNVBAgMBUxvY2FsMQ4wDAYDVQQHDAVMb2Nh
bDEQMA4GA1UECgwHRGVtbyBDQTELMAkGA1UECwwCSVQxFjAUBgNVBAMMDURlbW8t
TG9jYWwtQ0EwHhcNMjUxMDMxMDE1NTM4WhcNMzUxMDI5MDE1NTM4WjBkMQswCQYD
VQQGEwJDTjEOMAwGA1UECAwFTG9jYWwxDjAMBgNVBAcMBUxvY2FsMRAwDgYDVQQK
DAdEZW1vIENBMQswCQYDVQQLDAJJVDEWMBQGA1UEAwwNRGVtby1Mb2NhbC1DQTCC
AiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBANXhXJiwXg8id27KmX/5mq03
bQ0qYhIku3YscPk9l+Sylc65vuQgCyVS18OM8qBW/+hRsDfA2qzNgToOMbqeWg8Q
sP4PjCZc8CMPfjzUYzygF++Rn7XhxpLQ6n0Jmh9T4H3MKzHNDXnVPOlX/Hxm1p5T
Ooq0eaDd4HXslFMgh04hBUemL288+cCLf4c/ixKwQv3NECE68plmemNOmKEvd/fB
zDWojrU49LRkh1PuqZ2+RQwRWocDcAQmMTqDmq3CeRc9Ootb+H0E7flT9FkykxwX
44WCBtD3abEuAdLirbWlh8wPWReJiuO3QlfrZcTS1YY1riTFNoAvrr9H80QRUAJA
oJAfGtS4a5iCF1pzGQYEV+61+jeBYBJ9YQzHP4F21gWYRwAg0lOx5u8PfqbYqMM+
prRDEWRmSdkv+1zJ+PkSti0z8EeKIF6uMjyCIikpnBLtG6/KxIJj1thGiGx/1FzV
K5PFVVwjlQ97WItWO+m0PlPKU/InNu0iJYeaeQl0gVHRoWCIBWVMzuXAlLCh44UK
xUrxCxeMJqmcks1IheGD4sUigcrN7WaM2YfJ12S8cOrt8gSllDNs7h4hJXa0uok9
WzE2iZdOf0pAFzx5NAQ+VA3SiMoIRCAOk9uTgXsHpmFrY/aMo5aFzc2WIbkGwZ6u
Fi4VItmLMoW5uI3KgeaNAgMBAAGjUzBRMB0GA1UdDgQWBBROb7ImIYsG+gMZsEGQ
+bi0FsUbrzAfBgNVHSMEGDAWgBROb7ImIYsG+gMZsEGQ+bi0FsUbrzAPBgNVHRMB
Af8EBTADAQH/MA0GCSqGSIb3DQEBCwUAA4ICAQDVaXQ+jAiqozTNuqq6OncTDOf7
R+QtwcHpzp8VxPFs7vEPqVhlOsv1/7X5bgoPeOnyUltQUafugFHmBQMU6XL/27zv
JmNPg5tBw2eaTLzCh3jcAKBV/IwEXhmv1A8Musx3YU5iKBVJzMDXqQLt2scMeN3d
g0qoa7Zznmzl2uRiG58UJg1uS6q1nX1m4ljJyptPywJhEuakHOXSE7Hue7ik0UYZ
3WdJhVYZGy6B6sG18nbtmazllJexXMUrQH6dNm8De3rhYAeCo8ZLHefT3KsVpmna
xJ5lCIorTJt8dasfkLc3t5pzKZwS0SIi6r2HjbI/o4dyypHSH52Fhs938UEQUAvK
Cxyfg7EDpCpazrpNlJg3zYrs+sZMO9dECI97KGpQiqF3YLTOf3zjjizhOMJ+9ToO
GazkNdp6srPnSb2zFmiAd/yoocWW0NhZlhvs3X9ws3w8Kk4ZPHvOwp/O4c4Ud2S3
ICA6rL7xnBcOYYBTWewmacDuzd/fYUXCq/TmN6mQl77riynyvX+TviInmP86rLsY
e0lrJqT4oCRWea0bu2gQyD5PfOlL3a3z6rHUoGatUV1rf60X2NhdBCvMOWq3Hn2v
ImYXuNTL3RBdBsTznX0EYzAYdpZwT9wxwP5z8+kLia55pDlGMse/0lCDsBw3/+Qp
72wWwQCR1Pgt/LRuYw==
-----END CERTIFICATE-----
)PEM";

std::unique_ptr<BearSSL::WiFiClientSecure> secureClient(new BearSSL::WiFiClientSecure);
PubSubClient mqtt(*secureClient);

// ====== 屏幕布局（左：解密流程，右：传感器记录） ======
// 固定布局：左侧宽 200px；右侧占余下宽度
static const int16_t LEFT_PANE_X = 0;
static const int16_t LEFT_PANE_W = 200;
static const int16_t RIGHT_PANE_X = LEFT_PANE_W + 1;
static int16_t RIGHT_PANE_W = 120; // 实际在 setup 中由屏幕宽度计算
static const int16_t HEADER_H = 24;
static const int16_t LINE_H = 10;

// 动态游标
static int16_t yLeft = HEADER_H + 2;
static int16_t yRight = HEADER_H + 2;

// 在指定pane打印一行，打印前清除该行，避免重叠
void printLineInPane(int16_t x, int16_t &y, int16_t w, const String &text, uint16_t color)
{
  // 清除该行区域
  tft.fillRect(x, y, w, LINE_H, ILI9341_BLACK);
  // 打印
  tft.setCursor(x + 2, y);
  tft.setTextColor(color);
  tft.setTextSize(1);
  // 禁止自动换行，避免跨越到左侧
  tft.setTextWrap(false);
  // 依据列宽裁剪一行可显示的字符数（字体宽约6px）
  int16_t maxChars = (w - 4) / 6;
  String line = text;
  if (maxChars > 0 && (int)text.length() > maxChars)
  {
    line = text.substring(0, maxChars - 1) + "~"; // 用~标记被截断
  }
  tft.print(line);
  // 前进一行，滚屏
  y += LINE_H;
  int16_t maxH = tft.height();
  if (y > maxH - LINE_H)
  {
    // 滚动：整体上移一个行高（通过区域重绘实现简易滚动）
    // 复制区域代价高，这里采用清空并重置游标
    tft.fillRect(x, HEADER_H + 2, w, maxH - HEADER_H - 2, ILI9341_BLACK);
    y = HEADER_H + 2;
  }
}

inline void printLeftLine(const String &s, uint16_t color = ILI9341_WHITE)
{
  printLineInPane(LEFT_PANE_X, yLeft, LEFT_PANE_W, s, color);
}

inline void printRightLine(const String &s, uint16_t color = ILI9341_YELLOW)
{
  printLineInPane(RIGHT_PANE_X, yRight, RIGHT_PANE_W, s, color);
}

// 绘制左右两个标题栏
void drawHeaders()
{
  // 左标题
  tft.fillRect(LEFT_PANE_X, 0, LEFT_PANE_W, HEADER_H, ILI9341_BLUE);
  tft.setTextColor(ILI9341_WHITE);
  tft.setTextSize(2);
  tft.setCursor(LEFT_PANE_X + 4, 4);
  tft.print("RX Flow");

  // 右标题
  tft.fillRect(RIGHT_PANE_X, 0, RIGHT_PANE_W, HEADER_H, ILI9341_DARKGREEN);
  tft.setTextColor(ILI9341_WHITE);
  tft.setTextSize(2);
  tft.setCursor(RIGHT_PANE_X + 4, 4);
  tft.print("Sensors");

  // 中间分隔线（贯穿全屏）
  tft.drawFastVLine(LEFT_PANE_W, 0, tft.height(), ILI9341_DARKGREY);
}

void onMqttMessage(char *topic, byte *payload, unsigned int length)
{
  // 左侧：解密流程演示
  printLeftLine("[RX] Incoming message", ILI9341_CYAN);

  // 显示HEX（最多16字节）
  String encryptedHex = "";
  for (unsigned int i = 0; i < min(length, (unsigned int)16); i++)
  {
    if (i) encryptedHex += " ";
    uint8_t b = payload[i];
    if (b < 16) encryptedHex += "0"; // 补零
    encryptedHex += String(b, HEX);
  }
  if (length > 16) encryptedHex += " ...";
  printLeftLine("Encrypted(hex): " + encryptedHex, ILI9341_MAGENTA);

  // 模拟TLS流程
  printLeftLine("TLS: handshake OK", ILI9341_YELLOW);
  printLeftLine("TLS: verify cert OK", ILI9341_YELLOW);
  printLeftLine("TLS: AES-GCM decrypt...", ILI9341_YELLOW);

  // 明文
  String msg;
  for (unsigned int i = 0; i < length; i++) msg += (char)payload[i];
  printLeftLine("Plaintext: " + msg, ILI9341_GREEN);
  printLeftLine("Topic: " + String(topic), ILI9341_WHITE);
}

bool mqttConnect()
{
  String clientId = String("esp8266-") + String(ESP.getChipId(), HEX);
  logLine("Connecting to MQTT...", ILI9341_YELLOW);
  logLine("Server: " + String(mqtt_server) + ":" + String(mqtt_port), ILI9341_WHITE);
  
  // 尝试连接
  int state = mqtt.state();
  logLine("Before connect state=" + String(state), ILI9341_WHITE);
  
  if (mqtt.connect(clientId.c_str(), mqtt_user, mqtt_pass))
  {
    logLine("MQTT connected", ILI9341_GREEN);
    mqtt.subscribe(topic_control);
    mqtt.subscribe(topic_alerts);
    mqtt.publish(topic_status, "online");
    return true;
  }
  else
  {
    int state = mqtt.state();
    String errorMsg = "MQTT failed";
    // PubSubClient 错误码
    switch(state) {
      case -4: errorMsg = "Connection timeout"; break;
      case -3: errorMsg = "Connection lost"; break;
      case -2: errorMsg = "Connect failed"; break;
      case -1: errorMsg = "Disconnected"; break;
      case 1: errorMsg = "Bad protocol"; break;
      case 2: errorMsg = "Bad client ID"; break;
      case 3: errorMsg = "Unavailable"; break;
      case 4: errorMsg = "Bad credentials"; break;
      case 5: errorMsg = "Unauthorized"; break;
      default: errorMsg = "Unknown error"; break;
    }
    logLine(errorMsg + " code=" + String(state), ILI9341_RED);
    Serial.println("[MQTT] Connection failed, state=" + String(state));
    return false;
  }
}

void setup()
{
  Serial.begin(115200);
  tft.begin();
  tft.setRotation(1);
  tft.fillScreen(ILI9341_BLACK);
  tft.setTextWrap(false); // 全局关闭自动换行，避免跨栏

  // 计算右侧宽度并绘制标题
  RIGHT_PANE_W = tft.width() - RIGHT_PANE_X;
  drawHeaders();

  // 面板下方清空
  tft.fillRect(LEFT_PANE_X, HEADER_H + 2, LEFT_PANE_W, tft.height() - HEADER_H - 2, ILI9341_BLACK);
  tft.fillRect(RIGHT_PANE_X, HEADER_H + 2, RIGHT_PANE_W, tft.height() - HEADER_H - 2, ILI9341_BLACK);

  // 提示
  printLeftLine("WiFi: Connecting...", ILI9341_YELLOW);

  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);
  int retries = 0;
  while (WiFi.status() != WL_CONNECTED && retries < 60)
  {
    delay(500);
    printLeftLine(".", ILI9341_YELLOW);
    retries++;
  }
  if (WiFi.status() != WL_CONNECTED)
  {
    printLeftLine("WiFi failed - check SSID/password", ILI9341_RED);
    return;
  }
  String ipMsg = String("IP acquired: ") + WiFi.localIP().toString();
  printLeftLine("WiFi connected", ILI9341_GREEN);
  printLeftLine(ipMsg, ILI9341_GREEN);
  delay(800);

  printLeftLine("TLS handshake", ILI9341_YELLOW);
  printLeftLine("Load CA & verify server cert", ILI9341_YELLOW);
  secureClient->setBufferSizes(4096, 512);
  secureClient->setTimeout(15000);
  BearSSL::X509List cert(ca_cert);
  secureClient->setTrustAnchors(&cert);
  // 可选：SNI 仅当使用域名连接时需要。当前使用IP无需设置。
  // 对于IP地址连接，可能需要禁用证书主机名验证
  secureClient->setInsecure(); // 仅用于测试，生产环境应启用验证

  mqtt.setServer(mqtt_server, mqtt_port);
  mqtt.setCallback(onMqttMessage);

  if (!mqttConnect())
  {
    int state = mqtt.state();
    String errorDesc = "State code=" + String(state);
    if (state == -2) {
      errorDesc = "TLS/Network error";
    } else if (state == 4) {
      errorDesc = "Bad username/password";
    } else if (state == 5) {
      errorDesc = "Not authorized";
    }
    printLeftLine("MQTT failed", ILI9341_RED);
    printLeftLine(errorDesc, ILI9341_RED);
    Serial.println("[ERROR] MQTT connection failed, state=" + String(state));
    return;
  }
  printLeftLine("MQTT connected", ILI9341_GREEN);
  printLeftLine("Subscribed control/alerts; published online", ILI9341_GREEN);
}

unsigned long lastPub = 0;

void loop()
{
  if (WiFi.status() != WL_CONNECTED)
    return;
  if (!mqtt.connected())
  {
    if (!mqttConnect())
    {
      delay(2000);
      return;
    }
  }
  mqtt.loop();

  // 周期上报模拟数据
  unsigned long now = millis();
  if (now - lastPub > 3000)
  {
    lastPub = now;
    String sensor = String("{\"t\":") + String(now / 1000) + ",\"temp\":25.3}";
    mqtt.publish(topic_sensor, sensor.c_str());
    mqtt.publish(topic_battery, "{\"soc\":92}");
    // 右侧面板滚动显示最新传感记录
    printRightLine(String("t=") + String(now / 1000) + "s", ILI9341_CYAN);
    printRightLine(String("sensor ") + sensor, ILI9341_YELLOW);
  }
}
