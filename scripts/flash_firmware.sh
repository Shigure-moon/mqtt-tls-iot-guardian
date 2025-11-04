#!/bin/bash
# ESP8266固件烧录脚本

set -e

DEVICE_PORT="${1:-/dev/ttyUSB0}"
FIRMWARE_FILE="${2:-esp8266_encrypted.bin}"

if [ ! -f "$FIRMWARE_FILE" ]; then
    echo "错误: 固件文件不存在: $FIRMWARE_FILE"
    exit 1
fi

if [ ! -e "$DEVICE_PORT" ]; then
    echo "错误: 串口设备不存在: $DEVICE_PORT"
    echo "请检查设备连接并指定正确的端口"
    exit 1
fi

echo "=========================================="
echo "ESP8266固件烧录工具"
echo "=========================================="
echo "串口设备: $DEVICE_PORT"
echo "固件文件: $FIRMWARE_FILE"
echo "=========================================="
echo ""

# 检查设备连接
echo "正在检测设备..."
esptool --port "$DEVICE_PORT" chip-id 2>&1 | grep -E "(Chip type|MAC)" || {
    echo "错误: 无法连接到ESP8266设备"
    exit 1
}

echo ""
read -p "是否继续烧录？(y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "已取消"
    exit 0
fi

# 烧录固件
echo ""
echo "正在烧录固件..."
esptool --port "$DEVICE_PORT" write-flash \
  --flash-mode dio \
  --flash-size 4MB \
  0x0 "$FIRMWARE_FILE"

echo ""
echo "=========================================="
echo "✅ 固件烧录完成！"
echo "=========================================="
echo ""
echo "提示: 使用以下命令查看设备输出："
echo "  screen $DEVICE_PORT 115200"
echo "  或"
echo "  minicom -D $DEVICE_PORT -b 115200"
echo ""

