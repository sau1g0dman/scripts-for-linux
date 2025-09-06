#!/bin/bash

# =============================================================================
# 虚拟环境激活脚本
# 作者: saul
# 版本: 1.0
# 描述: 快速激活Python虚拟环境的便捷脚本
# =============================================================================

# 颜色定义
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
CYAN='\033[36m'
RESET='\033[m'

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/venv"

echo -e "${BLUE}=================================="
echo -e "Python虚拟环境激活脚本"
echo -e "==================================${RESET}"

# 检查虚拟环境是否存在
if [ ! -d "$VENV_DIR" ]; then
    echo -e "${RED}[错误]${RESET} 虚拟环境不存在: $VENV_DIR"
    echo -e "${CYAN}[提示]${RESET} 请先运行: python3 setup_venv.py"
    exit 1
fi

# 检查激活脚本是否存在
ACTIVATE_SCRIPT="$VENV_DIR/bin/activate"
if [ ! -f "$ACTIVATE_SCRIPT" ]; then
    echo -e "${RED}[错误]${RESET} 激活脚本不存在: $ACTIVATE_SCRIPT"
    echo -e "${CYAN}[提示]${RESET} 虚拟环境可能损坏，请重新创建"
    exit 1
fi

echo -e "${GREEN}[信息]${RESET} 激活虚拟环境: $VENV_DIR"
echo -e "${YELLOW}[提示]${RESET} 使用 'deactivate' 命令退出虚拟环境"
echo

# 激活虚拟环境并启动新的shell
source "$ACTIVATE_SCRIPT"

# 显示虚拟环境信息
echo -e "${CYAN}[信息]${RESET} 虚拟环境已激活"
echo -e "${CYAN}[信息]${RESET} Python路径: $(which python)"
echo -e "${CYAN}[信息]${RESET} Python版本: $(python --version)"
echo

# 显示可用命令
echo -e "${BLUE}可用命令：${RESET}"
echo -e "  ${GREEN}python install.py${RESET}     - 运行主安装程序"
echo -e "  ${GREEN}python bootstrap.py${RESET}   - 运行引导脚本"
echo -e "  ${GREEN}python run_tests.py${RESET}   - 运行测试套件"
echo -e "  ${GREEN}deactivate${RESET}            - 退出虚拟环境"
echo

# 启动新的bash会话以保持虚拟环境激活状态
exec bash
