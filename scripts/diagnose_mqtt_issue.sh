#!/bin/bash
# MQTT消息处理问题诊断脚本

echo "=========================================="
echo "MQTT消息处理问题诊断"
echo "=========================================="
echo ""

# 1. 检查EMQX客户端状态
echo "1. 检查后端MQTT客户端状态:"
docker exec emqx emqx_ctl clients show iot_backend 2>&1 | grep -E "delivered_msgs|subscriptions|connected"

echo ""
echo "2. 检查设备订阅:"
docker exec emqx emqx_ctl subscriptions list | grep "devices/esp8266" | head -5

echo ""
echo "3. 发布测试消息并检查:"
TEST_MSG='{"device_id":"esp8266","temperature":25.5,"humidity":60.0}'
mosquitto_pub -h localhost -p 1883 -u admin -P admin \
    -t "devices/esp8266/sensor" \
    -m "$TEST_MSG" 2>&1 && echo "✓ 测试消息已发布" || echo "✗ 发布失败"

sleep 2

echo ""
echo "4. 检查后端客户端消息计数:"
docker exec emqx emqx_ctl clients show iot_backend 2>&1 | grep "delivered_msgs"

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

