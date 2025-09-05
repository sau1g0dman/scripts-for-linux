#!/bin/bash

# 简化的测试脚本
set +e  # 暂时禁用错误退出

# 导入通用函数库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
echo "正在加载 common.sh..."
source "$SCRIPT_DIR/scripts/common.sh"
echo "common.sh 加载完成"

echo "测试开始..."

# 设置调试级别
export LOG_LEVEL=0

echo "1. 测试变量..."
echo "LOG_DEBUG: $LOG_DEBUG"
echo "LOG_INFO: $LOG_INFO"
echo "LOG_LEVEL: $LOG_LEVEL"

echo "2. 测试 log_debug..."
log_debug "这是一个调试消息"

echo "3. 测试 detect_os..."
if detect_os; then
    echo "OS: $OS, VER: $VER"
else
    echo "detect_os 失败"
fi

echo "测试完成！"
