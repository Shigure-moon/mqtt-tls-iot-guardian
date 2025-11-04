#!/bin/bash
# 测试MQTT消息流脚本
# 用于验证设备消息是否能被后端接收

set -e

echo "=========================================="
echo "MQTT消息流测试"
echo "=========================================="
echo ""

# 测试1: 发布测试消息到1883端口
echo "测试1: 发布测试消息到1883端口..."
mosquitto_pub -h localhost -p 1883 -u admin -P admin \
    -t "devices/esp8266/sensor" \
    -m '{"device_id":"esp8266","temperature":25.5,"humidity":60.0}' \
    2>&1 && echo "✓ 消息已发布" || echo "✗ 发布失败"

sleep 1

# 测试2: 发布心跳消息
echo ""
echo "测试2: 发布心跳消息..."
mosquitto_pub -h localhost -p 1883 -u admin -P admin \
    -t "devices/esp8266/heartbeat" \
    -m '{"device_id":"esp8266","timestamp":'$(date +%s)'}' \
    2>&1 && echo "✓ 心跳已发布" || echo "✗ 发布失败"

sleep 1

# 测试3: 检查EMQX中的消息
echo ""
echo "测试3: 检查EMQX统计信息..."
docker exec emqx emqx_ctl broker stats 2>&1 | grep -E "messages|delivered" | head -5

echo ""
echo "测试完成！"
echo "请检查后端日志中是否有 [MQTT] 消息处理记录"

