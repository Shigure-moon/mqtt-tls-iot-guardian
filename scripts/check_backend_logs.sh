#!/bin/bash
# 检查后端日志中的MQTT消息处理

echo "=========================================="
echo "检查后端MQTT消息处理日志"
echo "=========================================="
echo ""

# 查找uvicorn进程的输出
UVICORN_PID=$(ps aux | grep "uvicorn.*main:app" | grep -v grep | awk '{print $2}' | head -1)

if [ -z "$UVICORN_PID" ]; then
    echo "错误: 未找到运行中的uvicorn进程"
    exit 1
fi

echo "找到uvicorn进程: PID=$UVICORN_PID"
echo ""
echo "提示: 后端日志应该显示在运行uvicorn的终端窗口中"
echo "查找包含 [MQTT] 的日志行"
echo ""
echo "如果后端是在终端中运行的，请在该终端中查看日志"
echo "或者使用以下命令查看最近的日志:"
echo ""
echo "  tail -f /proc/$UVICORN_PID/fd/1 2>/dev/null | grep MQTT"
echo ""
echo "或者直接查看后端运行终端的输出"

