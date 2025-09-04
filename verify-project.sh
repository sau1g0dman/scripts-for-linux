#!/bin/bash

# =============================================================================
# 项目验证脚本
# 作者: saul
# 版本: 1.0
# 描述: 验证Ubuntu服务器初始化脚本库项目的完整性和正确性
# =============================================================================

set -euo pipefail

# =============================================================================
# 颜色定义
# =============================================================================
readonly RED='\033[31m'
readonly GREEN='\033[32m'
readonly YELLOW='\033[33m'
readonly BLUE='\033[34m'
readonly CYAN='\033[36m'
readonly RESET='\033[0m'

# =============================================================================
# 计数器
# =============================================================================
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# =============================================================================
# 验证函数
# =============================================================================

# 记录检查结果
check_result() {
    local test_name=$1
    local result=$2

    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    if [ "$result" = "PASS" ]; then
        echo -e "${GREEN}✓${RESET} $test_name"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        echo -e "${RED}✗${RESET} $test_name"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
}

# 验证文件存在
verify_file_exists() {
    local file_path=$1
    local description=$2

    if [ -f "$file_path" ]; then
        check_result "$description" "PASS"
    else
        check_result "$description - 文件不存在: $file_path" "FAIL"
    fi
}

# 验证目录存在
verify_directory_exists() {
    local dir_path=$1
    local description=$2

    if [ -d "$dir_path" ]; then
        check_result "$description" "PASS"
    else
        check_result "$description - 目录不存在: $dir_path" "FAIL"
    fi
}

# 验证脚本可执行
verify_script_executable() {
    local script_path=$1
    local description=$2

    if [ -x "$script_path" ]; then
        check_result "$description" "PASS"
    else
        check_result "$description - 脚本不可执行: $script_path" "FAIL"
    fi
}

# 验证脚本语法
verify_script_syntax() {
    local script_path=$1
    local description=$2

    if bash -n "$script_path" 2>/dev/null; then
        check_result "$description" "PASS"
    else
        check_result "$description - 语法错误: $script_path" "FAIL"
    fi
}

# =============================================================================
# 主验证流程
# =============================================================================

echo -e "${BLUE}================================================================${RESET}"
echo -e "${BLUE} Ubuntu服务器初始化脚本库项目验证${RESET}"
echo -e "${BLUE}================================================================${RESET}"
echo

# 验证项目根文件
echo -e "${CYAN}验证项目根文件...${RESET}"
verify_file_exists "README.md" "README.md文件存在"
verify_file_exists "LICENSE" "LICENSE文件存在"
verify_file_exists "install.sh" "install.sh文件存在"
verify_file_exists "uninstall.sh" "uninstall.sh文件存在"
verify_script_executable "install.sh" "install.sh可执行"
verify_script_executable "uninstall.sh" "uninstall.sh可执行"
verify_script_syntax "install.sh" "install.sh语法正确"
verify_script_syntax "uninstall.sh" "uninstall.sh语法正确"
echo

# 验证目录结构
echo -e "${CYAN}验证目录结构...${RESET}"
verify_directory_exists "scripts" "scripts目录存在"
verify_directory_exists "scripts/system" "scripts/system目录存在"
verify_directory_exists "scripts/shell" "scripts/shell目录存在"
verify_directory_exists "scripts/development" "scripts/development目录存在"
verify_directory_exists "scripts/security" "scripts/security目录存在"
verify_directory_exists "scripts/containers" "scripts/containers目录存在"
verify_directory_exists "scripts/utilities" "scripts/utilities目录存在"
verify_directory_exists "docs" "docs目录存在"
verify_directory_exists "docs/modules" "docs/modules目录存在"
verify_directory_exists "themes" "themes目录存在"
verify_directory_exists "themes/powerlevel10k" "themes/powerlevel10k目录存在"
echo

# 验证核心脚本文件
echo -e "${CYAN}验证核心脚本文件...${RESET}"
verify_file_exists "scripts/common.sh" "通用函数库存在"
verify_script_executable "scripts/common.sh" "通用函数库可执行"
verify_script_syntax "scripts/common.sh" "通用函数库语法正确"
echo

# 验证系统配置脚本
echo -e "${CYAN}验证系统配置脚本...${RESET}"
verify_file_exists "scripts/system/time-sync.sh" "时间同步脚本存在"
verify_file_exists "scripts/system/mirrors.sh" "软件源配置脚本存在"
verify_script_executable "scripts/system/time-sync.sh" "时间同步脚本可执行"
verify_script_executable "scripts/system/mirrors.sh" "软件源配置脚本可执行"
verify_script_syntax "scripts/system/time-sync.sh" "时间同步脚本语法正确"
verify_script_syntax "scripts/system/mirrors.sh" "软件源配置脚本语法正确"
echo

# 验证Shell环境脚本
echo -e "${CYAN}验证Shell环境脚本...${RESET}"
verify_file_exists "scripts/shell/zsh-install.sh" "ZSH安装脚本存在"
verify_file_exists "scripts/shell/zsh-install-gitee.sh" "ZSH安装脚本（国内源）存在"
verify_file_exists "scripts/shell/zsh-arm.sh" "ARM版ZSH脚本存在"
verify_script_executable "scripts/shell/zsh-install.sh" "ZSH安装脚本可执行"
verify_script_executable "scripts/shell/zsh-install-gitee.sh" "ZSH安装脚本（国内源）可执行"
verify_script_executable "scripts/shell/zsh-arm.sh" "ARM版ZSH脚本可执行"
verify_script_syntax "scripts/shell/zsh-install.sh" "ZSH安装脚本语法正确"
verify_script_syntax "scripts/shell/zsh-install-gitee.sh" "ZSH安装脚本（国内源）语法正确"
verify_script_syntax "scripts/shell/zsh-arm.sh" "ARM版ZSH脚本语法正确"
echo

# 验证开发工具脚本
echo -e "${CYAN}验证开发工具脚本...${RESET}"
verify_file_exists "scripts/development/nvim-setup.sh" "Neovim配置脚本存在"
verify_script_executable "scripts/development/nvim-setup.sh" "Neovim配置脚本可执行"
verify_script_syntax "scripts/development/nvim-setup.sh" "Neovim配置脚本语法正确"
echo

# 验证安全配置脚本
echo -e "${CYAN}验证安全配置脚本...${RESET}"
verify_file_exists "scripts/security/ssh-config.sh" "SSH配置脚本存在"
verify_file_exists "scripts/security/ssh-keygen.sh" "SSH密钥生成脚本存在"
verify_script_executable "scripts/security/ssh-config.sh" "SSH配置脚本可执行"
verify_script_executable "scripts/security/ssh-keygen.sh" "SSH密钥生成脚本可执行"
verify_script_syntax "scripts/security/ssh-config.sh" "SSH配置脚本语法正确"
verify_script_syntax "scripts/security/ssh-keygen.sh" "SSH密钥生成脚本语法正确"
echo

# 验证容器化脚本
echo -e "${CYAN}验证容器化脚本...${RESET}"
verify_file_exists "scripts/containers/docker-install.sh" "Docker安装脚本存在"
verify_file_exists "scripts/containers/docker-mirrors.sh" "Docker镜像源脚本存在"
verify_file_exists "scripts/containers/docker-push.sh" "Docker推送脚本存在"
verify_file_exists "scripts/containers/harbor-push.sh" "Harbor推送脚本存在"
verify_script_executable "scripts/containers/docker-install.sh" "Docker安装脚本可执行"
verify_script_executable "scripts/containers/docker-mirrors.sh" "Docker镜像源脚本可执行"
verify_script_executable "scripts/containers/docker-push.sh" "Docker推送脚本可执行"
verify_script_executable "scripts/containers/harbor-push.sh" "Harbor推送脚本可执行"
verify_script_syntax "scripts/containers/docker-install.sh" "Docker安装脚本语法正确"
verify_script_syntax "scripts/containers/docker-mirrors.sh" "Docker镜像源脚本语法正确"
verify_script_syntax "scripts/containers/harbor-push.sh" "Harbor推送脚本语法正确"
echo

# 验证实用工具脚本
echo -e "${CYAN}验证实用工具脚本...${RESET}"
verify_file_exists "scripts/utilities/disk-formatter.sh" "磁盘格式化脚本存在"
verify_script_executable "scripts/utilities/disk-formatter.sh" "磁盘格式化脚本可执行"
verify_script_syntax "scripts/utilities/disk-formatter.sh" "磁盘格式化脚本语法正确"
echo

# 验证文档文件
echo -e "${CYAN}验证文档文件...${RESET}"
verify_file_exists "docs/installation.md" "安装指南文档存在"
verify_file_exists "docs/troubleshooting.md" "故障排除文档存在"
verify_file_exists "docs/modules/system.md" "系统模块文档存在"
verify_file_exists "docs/modules/shell.md" "Shell模块文档存在"
verify_file_exists "docs/modules/development.md" "开发工具模块文档存在"
verify_file_exists "docs/modules/security.md" "安全配置模块文档存在"
verify_file_exists "docs/modules/containers.md" "容器化模块文档存在"
echo

# 验证主题文件
echo -e "${CYAN}验证主题文件...${RESET}"
verify_file_exists "themes/powerlevel10k/dracula.zsh" "Dracula主题文件存在"
verify_file_exists "themes/powerlevel10k/rainbow.zsh" "Rainbow主题文件存在"
verify_file_exists "themes/powerlevel10k/emoji.zsh" "Emoji主题文件存在"
echo

# 验证项目验证脚本本身
echo -e "${CYAN}验证项目验证脚本...${RESET}"
verify_script_executable "verify-project.sh" "项目验证脚本可执行"
verify_script_syntax "verify-project.sh" "项目验证脚本语法正确"
echo

# 显示验证结果
echo -e "${BLUE}================================================================${RESET}"
echo -e "${BLUE} 验证结果统计${RESET}"
echo -e "${BLUE}================================================================${RESET}"
echo -e "总检查项: ${CYAN}$TOTAL_CHECKS${RESET}"
echo -e "通过检查: ${GREEN}$PASSED_CHECKS${RESET}"
echo -e "失败检查: ${RED}$FAILED_CHECKS${RESET}"
echo

if [ $FAILED_CHECKS -eq 0 ]; then
    echo -e "${GREEN} 所有检查项都通过了！项目结构完整且正确。${RESET}"
    echo -e "${GREEN} 项目已准备就绪，可以安全使用。${RESET}"
    exit 0
else
    echo -e "${RED} 发现 $FAILED_CHECKS 个问题，请检查并修复。${RESET}"
    echo -e "${YELLOW} 建议修复所有问题后再使用项目。${RESET}"
    exit 1
fi
