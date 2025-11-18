#!/bin/bash
# 生成所有 C4 架构图的脚本
# 使用方法: ./generate.sh

set -e

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# PlantUML jar 文件路径（优先使用最新下载的版本）
PLANTUML_JAR="${PLANTUML_JAR:-/tmp/plantuml.jar}"

# 如果指定的 jar 不存在，尝试使用系统安装的版本
if [ ! -f "$PLANTUML_JAR" ]; then
    if command -v plantuml &> /dev/null; then
        echo "使用系统安装的 PlantUML..."
        PLANTUML_CMD="plantuml"
    else
        echo "错误: 找不到 PlantUML jar 文件: $PLANTUML_JAR"
        echo "请下载最新版本:"
        echo "  wget https://github.com/plantuml/plantuml/releases/latest/download/plantuml.jar -O /tmp/plantuml.jar"
        exit 1
    fi
else
    PLANTUML_CMD="java -jar $PLANTUML_JAR"
fi

# 切换到项目根目录
cd "$PROJECT_ROOT"

# 生成所有架构图
echo "正在生成 C4 架构图..."
echo "项目根目录: $PROJECT_ROOT"
echo "使用 PlantUML: $PLANTUML_CMD"
echo ""

# 生成所有 .puml 文件
if [ "$PLANTUML_CMD" = "plantuml" ]; then
    # 使用系统安装的版本（可能不支持 -D 参数）
    $PLANTUML_CMD "$SCRIPT_DIR"/*.puml
else
    # 使用 jar 文件，设置 RELATIVE_INCLUDE
    $PLANTUML_CMD -DRELATIVE_INCLUDE=./C4-PlantUML "$SCRIPT_DIR"/*.puml
fi

echo ""
echo "✅ 所有架构图生成完成！"
echo "图片文件位置: $SCRIPT_DIR"
ls -lh "$SCRIPT_DIR"/*.png 2>/dev/null | tail -n +2 || echo "未找到生成的图片文件"

