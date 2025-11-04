#!/bin/bash
# MQTT消息监控脚本
# 用于实时监控EMQX MQTT服务器接收到的所有设备消息

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}   MQTT 消息监控工具${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# 检查mosquitto客户端是否安装
if ! command -v mosquitto_sub &> /dev/null; then
    echo -e "${YELLOW}警告: mosquitto-clients 未安装${NC}"
    echo -e "安装命令: sudo apt-get install mosquitto-clients"
    echo ""
    echo -e "${BLUE}使用Docker中的mosquitto客户端...${NC}"
    DOCKER_CMD="docker exec -it emqx mosquitto_sub"
else
    DOCKER_CMD="mosquitto_sub"
fi

# 配置参数
MQTT_HOST="${MQTT_HOST:-localhost}"
MQTT_PORT="${MQTT_PORT:-1883}"
MQTT_USER="${MQTT_USER:-admin}"
MQTT_PASS="${MQTT_PASS:-admin}"
TOPIC="${TOPIC:-devices/+/#}"

echo -e "${GREEN}配置信息:${NC}"
echo -e "  主机: ${MQTT_HOST}"
echo -e "  端口: ${MQTT_PORT}"
echo -e "  用户: ${MQTT_USER}"
echo -e "  主题: ${TOPIC}"
echo ""
echo -e "${YELLOW}开始监控MQTT消息... (按 Ctrl+C 停止)${NC}"
echo ""

# 监控函数
monitor_mqtt() {
    if command -v mosquitto_sub &> /dev/null; then
        mosquitto_sub \
            -h "${MQTT_HOST}" \
            -p "${MQTT_PORT}" \
            -u "${MQTT_USER}" \
            -P "${MQTT_PASS}" \
            -t "${TOPIC}" \
            -v \
            --will-topic "monitor/disconnect" \
            --will-payload "Monitor disconnected" \
            --will-qos 1 \
            2>&1 | while IFS= read -r line; do
                timestamp=$(date '+%Y-%m-%d %H:%M:%S')
                # 解析主题和消息
                if [[ $line =~ ^([^ ]+)[[:space:]]+(.*)$ ]]; then
                    topic="${BASH_REMATCH[1]}"
                    message="${BASH_REMATCH[2]}"
                    
                    # 根据主题类型显示不同颜色
                    if [[ $topic == *"/heartbeat"* ]]; then
                        echo -e "${CYAN}[${timestamp}]${NC} ${GREEN}${topic}${NC} -> ${message}"
                    elif [[ $topic == *"/sensor"* ]]; then
                        echo -e "${CYAN}[${timestamp}]${NC} ${BLUE}${topic}${NC} -> ${message}"
                    elif [[ $topic == *"/status"* ]]; then
                        echo -e "${CYAN}[${timestamp}]${NC} ${YELLOW}${topic}${NC} -> ${message}"
                    else
                        echo -e "${CYAN}[${timestamp}]${NC} ${topic} -> ${message}"
                    fi
                else
                    echo -e "${CYAN}[${timestamp}]${NC} ${line}"
                fi
            done
    else
        echo -e "${RED}错误: mosquitto_sub 未找到${NC}"
        echo -e "请安装: sudo apt-get install mosquitto-clients"
        exit 1
    fi
}

# 信号处理
trap 'echo -e "\n${YELLOW}监控已停止${NC}"; exit 0' INT TERM

# 开始监控
monitor_mqtt

