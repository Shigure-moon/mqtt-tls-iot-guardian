#!/bin/bash
# MQTT配置一致性检查脚本

echo "=========================================="
echo "MQTT配置一致性检查"
echo "=========================================="
echo ""

# 检查后端配置
echo "1. 后端配置 (backend/.env):"
if [ -f "backend/.env" ]; then
    echo "   MQTT_BROKER_HOST: $(grep MQTT_BROKER_HOST backend/.env | cut -d'=' -f2)"
    echo "   MQTT_BROKER_PORT: $(grep MQTT_BROKER_PORT backend/.env | cut -d'=' -f2)"
    echo "   MQTT_USERNAME: $(grep MQTT_USERNAME backend/.env | cut -d'=' -f2)"
    echo "   MQTT_PASSWORD: $(grep MQTT_PASSWORD backend/.env | cut -d'=' -f2 | cut -c1-3)***"
else
    echo "   ❌ backend/.env 文件不存在"
fi

echo ""
echo "2. 设备固件配置 (从模板):"
if [ -f "backend/templates/ESP8266-ILI9341-v1.ino" ]; then
    echo "   mqtt_server: $(grep -E "const char\* mqtt_server" backend/templates/ESP8266-ILI9341-v1.ino | grep -oE '"[^"]+"' | tr -d '"')"
    echo "   mqtt_port: $(grep -E "const int mqtt_port" backend/templates/ESP8266-ILI9341-v1.ino | grep -oE '[0-9]+')"
    echo "   mqtt_user: $(grep -E "const char\* mqtt_user" backend/templates/ESP8266-ILI9341-v1.ino | grep -oE '"[^"]+"' | tr -d '"')"
    echo "   mqtt_pass: $(grep -E "const char\* mqtt_pass" backend/templates/ESP8266-ILI9341-v1.ino | grep -oE '"[^"]+"' | tr -d '"' | cut -c1-3)***"
fi

echo ""
echo "3. MQTT Broker状态:"
if command -v docker &> /dev/null; then
    if docker ps | grep -q emqx; then
        echo "   ✅ EMQX容器正在运行"
        echo "   端口映射: $(docker port emqx 2>/dev/null | grep -E '1883|8883' | head -2)"
    else
        echo "   ⚠️  EMQX容器未运行"
    fi
fi

echo ""
echo "4. CA证书检查:"
if [ -f "data/certs/ca.crt" ]; then
    echo "   ✅ CA证书存在: data/certs/ca.crt"
    echo "   证书信息:"
    openssl x509 -in data/certs/ca.crt -noout -subject -dates 2>/dev/null | sed 's/^/      /'
else
    echo "   ❌ CA证书不存在: data/certs/ca.crt"
fi

echo ""
echo "=========================================="
echo "检查完成"
echo "=========================================="
