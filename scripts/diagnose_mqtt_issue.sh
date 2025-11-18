#!/bin/bash
# MQTT消息处理问题诊断脚本

echo "=========================================="
echo "MQTT消息处理问题诊断"
echo "=========================================="
echo ""

# 获取项目根目录
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CA_CERT="$PROJECT_ROOT/data/certs/ca.crt"

# 1. 检查Mosquitto服务状态
echo "1. 检查Mosquitto服务状态:"
if systemctl is-active --quiet mosquitto 2>/dev/null || pgrep -x mosquitto > /dev/null; then
    echo "   ✓ Mosquitto服务正在运行"
    # 检查端口
    if ss -tuln | grep -q ":8883"; then
        echo "   ✓ TLS端口 8883 正在监听"
    else
        echo "   ✗ TLS端口 8883 未监听"
    fi
else
    echo "   ✗ Mosquitto服务未运行"
fi

echo ""
echo "2. 检查后端MQTT连接配置:"
if [ -f "$PROJECT_ROOT/backend/.env" ]; then
    echo "   后端配置:"
    grep "^MQTT_" "$PROJECT_ROOT/backend/.env" | sed 's/PASSWORD=.*/PASSWORD=***/'
else
    echo "   ✗ 未找到 backend/.env 文件"
fi

echo ""
echo "3. 检查CA证书:"
if [ -f "$CA_CERT" ]; then
    echo "   ✓ CA证书存在: $CA_CERT"
    openssl x509 -in "$CA_CERT" -noout -subject -dates 2>/dev/null | sed 's/^/   /'
else
    echo "   ✗ CA证书不存在: $CA_CERT"
fi

echo ""
echo "4. 发布测试消息并检查:"
TEST_MSG='{"device_id":"esp8266","temperature":25.5,"humidity":60.0}'
if [ -f "$CA_CERT" ]; then
    mosquitto_pub -h localhost -p 8883 \
        --cafile "$CA_CERT" \
        -u admin -P password \
        -t "devices/esp8266/sensor" \
        -m "$TEST_MSG" 2>&1 && echo "   ✓ 测试消息已发布" || echo "   ✗ 发布失败"
else
    echo "   ⚠️  跳过测试（CA证书不存在）"
fi

echo ""
echo "5. 检查设备固件配置:"
if [ -f "$PROJECT_ROOT/shili_encrypted/shili_encrypted.ino" ]; then
    echo "   设备固件中的MQTT配置:"
    grep -E "mqtt_server|mqtt_port|mqtt_user|mqtt_pass" "$PROJECT_ROOT/shili_encrypted/shili_encrypted.ino" | head -4 | sed 's/.*= *//;s/;.*//;s/pass.*/pass=***/' | sed 's/^/   /'
fi

echo ""
echo "=========================================="
echo "诊断建议:"
echo "=========================================="
echo "1. 查看后端运行终端的日志输出，查找 [MQTT] 标记"
echo "2. 检查是否有错误信息"
echo "3. 确认设备ID 'esp8266' 在数据库中存在"
echo ""
echo "如果后端日志显示收到消息但数据库未更新，可能是:"
echo "  - 设备ID不匹配"
echo "  - 数据库提交失败"
echo "  - JSON解析错误"
echo ""

