#!/bin/bash
# 更新MQTT配置脚本
# 用于将后端配置连接到EMQX服务器

set -e

ENV_FILE="backend/.env"

if [ ! -f "$ENV_FILE" ]; then
    echo "错误: $ENV_FILE 文件不存在"
    exit 1
fi

echo "更新MQTT配置以连接到EMQX..."

# 检查当前配置
echo ""
echo "当前MQTT配置:"
grep "^MQTT" "$ENV_FILE" || echo "未找到MQTT配置"

echo ""
echo "EMQX默认配置:"
echo "  - 用户名: admin"
echo "  - 密码: public (或您在EMQX中设置的密码)"
echo "  - 端口: 1883 (非TLS) 或 18883 (TLS)"
echo ""

# 读取用户输入
read -p "MQTT用户名 [admin]: " MQTT_USER
MQTT_USER=${MQTT_USER:-admin}

read -p "MQTT密码 [public]: " MQTT_PASS
MQTT_PASS=${MQTT_PASS:-public}

read -p "MQTT端口 [1883]: " MQTT_PORT
MQTT_PORT=${MQTT_PORT:-1883}

# 更新配置
if grep -q "^MQTT_USERNAME=" "$ENV_FILE"; then
    sed -i "s/^MQTT_USERNAME=.*/MQTT_USERNAME=${MQTT_USER}/" "$ENV_FILE"
else
    echo "MQTT_USERNAME=${MQTT_USER}" >> "$ENV_FILE"
fi

if grep -q "^MQTT_PASSWORD=" "$ENV_FILE"; then
    sed -i "s/^MQTT_PASSWORD=.*/MQTT_PASSWORD=${MQTT_PASS}/" "$ENV_FILE"
else
    echo "MQTT_PASSWORD=${MQTT_PASS}" >> "$ENV_FILE"
fi

if grep -q "^MQTT_BROKER_PORT=" "$ENV_FILE"; then
    sed -i "s/^MQTT_BROKER_PORT=.*/MQTT_BROKER_PORT=${MQTT_PORT}/" "$ENV_FILE"
else
    echo "MQTT_BROKER_PORT=${MQTT_PORT}" >> "$ENV_FILE"
fi

echo ""
echo "配置已更新！"
echo ""
echo "新的MQTT配置:"
grep "^MQTT" "$ENV_FILE"
echo ""
echo "请重启后端服务以使配置生效"

