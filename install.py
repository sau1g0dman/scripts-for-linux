#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
=============================================================================
Ubuntu/Debian服务器安装脚本 - 菜单入口
作者: saul
版本: 2.0
描述: 模块化安装脚本的菜单入口，支持Ubuntu 20-24和Debian 10-12 x64/ARM64
功能: 提供交互式菜单，调用独立的安装脚本模块，无自动安装行为
=============================================================================
"""

import os
import sys
import subprocess
import signal
from pathlib import Path
from typing import List, Dict, Tuple, Optional

# 添加scripts目录到Python路径
script_dir = Path(__file__).parent
scripts_dir = script_dir / "scripts"
sys.path.insert(0, str(scripts_dir))

try:
    from common import *
except ImportError:
    print("错误：找不到 common.py 文件")
    print("请确保在项目根目录中运行此脚本")
    sys.exit(1)

# =============================================================================
# 配置变量
# =============================================================================
INSTALL_DIR = os.path.expanduser("~/.scripts-for-linux")

# =============================================================================
# 脚本验证函数
# =============================================================================

def verify_local_scripts() -> bool:
    """
    验证本地脚本目录

    Returns:
        bool: 验证是否通过
    """
    if not scripts_dir.exists():
        log_error(f"脚本目录不存在: {scripts_dir}")
        log_error("请确保在正确的项目根目录中运行此脚本")
        return False

    # 检查关键脚本文件
    required_files = [
        scripts_dir / "common.py",
        scripts_dir / "software" / "common-software-install.py",
        scripts_dir / "shell" / "zsh-core-install.py",
    ]

    for file_path in required_files:
        if not file_path.exists():
            log_error(f"缺少必需文件: {file_path}")
            return False

    log_info("本地脚本验证通过")
    return True

# =============================================================================
# 工具函数
# =============================================================================

def show_header() -> None:
    """显示脚本头部信息"""
    os.system('clear' if os.name == 'posix' else 'cls')

    print(f"{BLUE}================================================================{RESET}")
    print(f"{BLUE}Ubuntu/Debian服务器安装脚本 - 菜单入口{RESET}")
    print(f"{BLUE}版本: 2.0{RESET}")
    print(f"{BLUE}作者: saul{RESET}")
    print(f"{BLUE}邮箱: sau1amaranth@gmail.com{RESET}")
    print(f"{BLUE}================================================================{RESET}")
    print()
    print(f"{CYAN}本脚本提供模块化的安装选项菜单{RESET}")
    print(f"{CYAN}支持Ubuntu 20-24和Debian 10-12，x64和ARM64架构{RESET}")
    print()
    print(f"{YELLOW}📋 使用方法：{RESET}")
    print(f"{YELLOW}   1. git clone https://github.com/sau1g0dman/scripts-for-linux.git{RESET}")
    print(f"{YELLOW}   2. cd scripts-for-linux{RESET}")
    print(f"{YELLOW}   3. python3 install.py{RESET}")
    print()
    print(f"{YELLOW}⚠️  注意：本脚本不会自动安装任何软件{RESET}")
    print(f"{YELLOW}   所有安装操作都需要您的明确选择和确认{RESET}")

def execute_python_script(script_path: str, script_name: str) -> bool:
    """
    执行Python脚本

    Args:
        script_path: 脚本相对路径
        script_name: 脚本名称

    Returns:
        bool: 执行是否成功
    """
    script_file = scripts_dir / script_path

    log_info(f"开始执行: {script_name}")
    log_debug(f"脚本路径: {script_file}")

    # 检查脚本文件是否存在
    if not script_file.exists():
        log_error(f"脚本文件不存在: {script_file}")
        return False

    # 检查脚本是否可读
    if not os.access(script_file, os.R_OK):
        log_error(f"脚本文件不可读: {script_file}")
        return False

    # 设置详细日志级别
    os.environ["LOG_LEVEL"] = "0"  # 启用DEBUG级别日志

    # 执行Python脚本
    log_info("执行Python脚本...")

    try:
        # 设置环境变量标识调用来源，让子脚本知道是被主菜单调用的
        env = os.environ.copy()
        env['CALLED_FROM_INSTALL_SH'] = '1'
        env['PARENT_SCRIPT'] = 'install.py'

        result = subprocess.run([sys.executable, str(script_file)],
                              env=env, cwd=str(script_dir))

        if result.returncode == 0:
            log_info(f"{script_name} 执行成功")
            return True
        elif result.returncode == 130:
            # 用户取消 (Ctrl+C)
            log_warn(f"{script_name} 被用户取消")
            return True
        else:
            log_error(f"{script_name} 执行失败 (退出码: {result.returncode})")
            log_error("请检查上述错误信息以了解失败原因")
            return False

    except Exception as e:
        log_error(f"执行脚本时发生异常: {e}")
        return False

# =============================================================================
# 安装函数
# =============================================================================

def install_common_software() -> bool:
    """安装常用软件（调用独立脚本）"""
    return execute_python_script("software/common-software-install.py", "常用软件安装")

def install_zsh_core() -> bool:
    """安装ZSH核心环境（调用独立脚本）"""
    return execute_python_script("shell/zsh-core-install.py", "ZSH核心环境安装")

def install_zsh_plugins() -> bool:
    """安装ZSH插件（调用独立脚本）"""
    return execute_python_script("shell/zsh-plugins-install.py", "ZSH插件安装")

def install_zsh_arm() -> bool:
    """安装ZSH ARM优化（调用独立脚本）"""
    # 注意：这里需要先转换对应的bash脚本为Python
    log_warn("ZSH ARM优化脚本尚未转换为Python版本")
    return False

def install_ssh_config() -> bool:
    """SSH安全配置（调用独立脚本）"""
    return execute_python_script("security/ssh-config.py", "SSH安全配置")

def install_ssh_keygen() -> bool:
    """SSH密钥生成（调用独立脚本）"""
    return execute_python_script("security/ssh-keygen.py", "SSH密钥生成")

def install_all() -> bool:
    """全部安装"""
    log_info("开始全部安装...")

    # 获取所有可用的安装选项（排除"全部安装"和"退出"）
    all_options = get_menu_options()
    install_functions = []

    for name, desc, func, status in all_options:
        if status == "READY" and name not in ["全部安装", "退出"]:
            install_functions.append((name, func))

    success_count = 0
    total_count = len(install_functions)

    log_info(f"将安装 {total_count} 个组件...")

    # 执行所有安装
    for name, func in install_functions:
        log_info(f"正在安装: {name}")
        try:
            if func():
                success_count += 1
                log_info(f"✅ {name} 安装成功")
            else:
                log_warn(f"❌ {name} 安装失败")
        except Exception as e:
            log_error(f"❌ {name} 安装异常: {e}")

    # 显示安装结果
    print(f"\n{BLUE}{'='*60}")
    print(f"📊 全部安装结果统计")
    print(f"{'='*60}{RESET}")
    print(f"{GREEN}✅ 成功安装: {success_count}/{total_count} 个组件{RESET}")

    if success_count == total_count:
        print(f"{GREEN}🎉 全部组件安装成功！{RESET}")
        log_info("全部安装完成")
        return True
    else:
        print(f"{YELLOW}⚠️  部分组件安装失败{RESET}")
        log_warn(f"部分安装完成 ({success_count}/{total_count})")
        return False

# =============================================================================
# 菜单系统
# =============================================================================

def show_main_menu() -> None:
    """显示美化的主菜单"""
    # 菜单标题
    print(f"{BLUE}╔══════════════════════════════════════════════════════════════════════════════╗{RESET}")
    print(f"{BLUE}║{RESET}                            {CYAN}【 安装组件选择菜单 】{RESET}                            {BLUE}║{RESET}")
    print(f"{BLUE}╚══════════════════════════════════════════════════════════════════════════════╝{RESET}")
    print()

    # 菜单说明
    print(f"{YELLOW}┌─ 操作说明 ─────────────────────────────────────────────────────────────────┐{RESET}")
    print(f"{YELLOW}│{RESET} {CYAN}↑↓{RESET} 方向键或 {CYAN}W/S{RESET} 键移动光标  {CYAN}Enter{RESET} 键确认选择  {CYAN}Ctrl+C{RESET} 退出程序 {YELLOW}│{RESET}")
    print(f"{YELLOW}└─────────────────────────────────────────────────────────────────────────────┘{RESET}")
    print()

def get_menu_options() -> List[Tuple[str, str, callable, str]]:
    """
    获取菜单选项

    Returns:
        List[Tuple[str, str, callable, str]]: (显示名称, 描述, 处理函数, 状态)
    """
    return [
        ("常用软件安装", "7个基础工具包（curl, git, vim, htop等）", install_common_software, "READY"),
        ("ZSH核心环境安装", "ZSH + Oh My Zsh + Powerlevel10k主题", install_zsh_core, "READY"),
        ("ZSH插件安装", "自动补全、语法高亮等实用插件", install_zsh_plugins, "READY"),
        ("ZSH ARM优化", "ARM64架构性能优化配置", install_zsh_arm, "PENDING"),
        ("SSH安全配置", "SSH服务器安全配置和优化", install_ssh_config, "READY"),
        ("SSH密钥生成", "生成和配置SSH密钥对", install_ssh_keygen, "READY"),
        ("全部安装", "安装所有可用组件", install_all, "READY"),
        ("退出", "退出安装程序", lambda: False, "EXIT")
    ]

def format_menu_option(name: str, description: str, status: str) -> str:
    """
    格式化菜单选项显示

    Args:
        name: 选项名称
        description: 选项描述
        status: 状态 (READY/PENDING/WARNING/ERROR/EXIT)

    Returns:
        str: 格式化后的菜单选项
    """
    # 状态指示器和颜色
    status_indicators = {
        "READY": f"{GREEN}●{RESET}",      # 绿色圆点 - 可用
        "PENDING": f"{YELLOW}◐{RESET}",   # 黄色半圆 - 待转换
        "WARNING": f"{YELLOW}▲{RESET}",   # 黄色三角 - 警告
        "ERROR": f"{RED}✗{RESET}",        # 红色叉号 - 错误
        "EXIT": f"{CYAN}◆{RESET}"         # 青色菱形 - 退出
    }

    # 状态文本
    status_texts = {
        "READY": f"{GREEN}[可用]{RESET}",
        "PENDING": f"{YELLOW}[待转换]{RESET}",
        "WARNING": f"{YELLOW}[警告]{RESET}",
        "ERROR": f"{RED}[错误]{RESET}",
        "EXIT": f"{CYAN}[退出]{RESET}"
    }

    indicator = status_indicators.get(status, f"{GRAY}○{RESET}")
    status_text = status_texts.get(status, f"{GRAY}[未知]{RESET}")

    # 格式化选项
    return f"{indicator} {BOLD}{name}{RESET} {status_text}\n    {GRAY}└─ {description}{RESET}"

def handle_menu_selection(selection_index: int, options: List[Tuple[str, str, callable, str]]) -> bool:
    """
    处理菜单选择

    Args:
        selection_index: 选择的索引
        options: 菜单选项列表

    Returns:
        bool: 是否继续显示菜单
    """
    if selection_index < 0 or selection_index >= len(options):
        return True

    option_name, option_desc, option_func, option_status = options[selection_index]

    # 检查选项状态
    if option_status == "PENDING":
        log_warn(f"功能 '{option_name}' 尚未转换为Python版本")
        input("按任意键继续...")
        return True
    elif option_status == "ERROR":
        log_error(f"功能 '{option_name}' 当前不可用")
        input("按任意键继续...")
        return True

    if option_name == "退出":
        log_info("用户选择退出")
        return False

    log_info(f"用户选择: {option_name}")

    try:
        # 执行选择的功能
        result = option_func()

        if result:
            print(f"\n{GREEN}✅ {option_name} 完成{RESET}")
        else:
            print(f"\n{YELLOW}⚠️  {option_name} 部分完成或失败{RESET}")

        # 等待用户确认
        input(f"\n{CYAN}按 Enter 键返回主菜单...{RESET}")

    except KeyboardInterrupt:
        print(f"\n{YELLOW}操作被用户中断{RESET}")
        input(f"\n{CYAN}按 Enter 键返回主菜单...{RESET}")
    except Exception as e:
        log_error(f"执行 {option_name} 时发生错误: {e}")
        input(f"\n{CYAN}按 Enter 键返回主菜单...{RESET}")

    return True

# =============================================================================
# 主函数
# =============================================================================

def main() -> int:
    """
    主函数

    Returns:
        int: 退出码
    """
    try:
        # 显示头部信息
        show_header()

        # 验证本地脚本
        if not verify_local_scripts():
            log_error("脚本验证失败")
            return 1

        # 用户确认
        if not interactive_ask_confirmation("是否继续使用安装脚本？", "true"):
            log_info("用户取消使用")
            return 0

        # 主菜单循环
        while True:
            show_header()
            show_main_menu()

            # 获取菜单选项
            options = get_menu_options()
            option_names = [format_menu_option(name, desc, status) for name, desc, _, status in options]

            # 显示菜单并获取用户选择
            selection_index, selection_text = interactive_select_menu(
                option_names,
                f"{CYAN}请选择要执行的操作：{RESET}",
                0
            )

            # 处理用户选择
            if selection_index == -1:  # 用户取消
                log_info("用户取消操作")
                break

            # 执行选择的操作
            if not handle_menu_selection(selection_index, options):
                break

        log_info("安装脚本退出")
        return 0

    except KeyboardInterrupt:
        print(f"\n{YELLOW}程序被用户中断{RESET}")
        return 130
    except Exception as e:
        log_error(f"程序执行过程中发生错误: {e}")
        return 1

# =============================================================================
# 脚本入口点
# =============================================================================

if __name__ == "__main__":
    # 设置信号处理
    def signal_handler(signum, frame):
        print(f"\n{RED}[ERROR] 程序执行被中断{RESET}")
        sys.exit(1)

    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    # 执行主函数
    exit_code = main()
    sys.exit(exit_code)
