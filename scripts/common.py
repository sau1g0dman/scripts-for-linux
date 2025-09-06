#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
=============================================================================
通用工具函数库
作者: saul
版本: 1.0
描述: 为Ubuntu 20-22服务器初始化脚本提供通用功能
支持平台: x64, ARM64
=============================================================================
"""

import os
import sys
import subprocess
import tempfile
import shutil
import platform
import socket
import time
import re
from datetime import datetime
from pathlib import Path
from typing import Optional, List, Dict, Tuple, Any, Union

# 防重复加载保护
if 'COMMON_PY_LOADED' in globals():
    sys.exit(0)
COMMON_PY_LOADED = True

# =============================================================================
# 颜色定义
# =============================================================================
try:
    # 尝试使用 colorama 库（如果可用）
    from colorama import init, Fore, Style
    init(autoreset=True)
    RED = Fore.RED
    GREEN = Fore.GREEN
    YELLOW = Fore.YELLOW
    BLUE = Fore.BLUE
    CYAN = Fore.CYAN
    MAGENTA = Fore.MAGENTA
    GRAY = Style.DIM
    BOLD = Style.BRIGHT
    RESET = Style.RESET_ALL
except ImportError:
    # 回退到 ANSI 转义序列
    RED = '\033[31m'
    GREEN = '\033[32m'
    YELLOW = '\033[33m'
    BLUE = '\033[34m'
    CYAN = '\033[36m'
    MAGENTA = '\033[35m'
    GRAY = '\033[90m'
    BOLD = '\033[1m'
    RESET = '\033[m'

# =============================================================================
# 日志函数
# =============================================================================

# 日志级别
LOG_DEBUG = 0
LOG_INFO = 1
LOG_WARN = 2
LOG_ERROR = 3

# 当前日志级别（默认INFO）
LOG_LEVEL = int(os.environ.get('LOG_LEVEL', LOG_INFO))

def log_info(message: str) -> None:
    """输出信息级别日志"""
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    print(f"{CYAN}[INFO] {timestamp} {message}{RESET}")

def log_warn(message: str) -> None:
    """输出警告级别日志"""
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    print(f"{YELLOW}[WARN] {timestamp} {message}{RESET}")

def log_error(message: str) -> None:
    """输出错误级别日志"""
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    print(f"{RED}[ERROR] {timestamp} {message}{RESET}")

def log_success(message: str) -> None:
    """输出成功级别日志"""
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    print(f"{GREEN}[SUCCESS] {timestamp} {message}{RESET}")

def log_debug(message: str) -> None:
    """输出调试级别日志"""
    if LOG_LEVEL <= LOG_DEBUG:
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        print(f"{BLUE}[DEBUG] {timestamp} {message}{RESET}")

def get_timestamp() -> str:
    """获取时间戳字符串（用于文件名）"""
    return datetime.now().strftime("%Y%m%d_%H%M%S")

def execute_command(cmd: Union[str, List[str]], description: str = "执行命令") -> bool:
    """
    执行命令并记录详细日志

    Args:
        cmd: 要执行的命令（字符串或列表）
        description: 命令描述

    Returns:
        bool: 命令是否执行成功
    """
    log_info(f"开始执行: {description}")
    log_debug(f"命令: {cmd}")

    try:
        # 创建临时文件存储输出
        with tempfile.NamedTemporaryFile(mode='w+', delete=False) as temp_output, \
             tempfile.NamedTemporaryFile(mode='w+', delete=False) as temp_error:

            # 执行命令
            if isinstance(cmd, str):
                result = subprocess.run(cmd, shell=True, stdout=temp_output,
                                      stderr=temp_error, text=True)
            else:
                result = subprocess.run(cmd, stdout=temp_output,
                                      stderr=temp_error, text=True)

            # 读取输出
            temp_output.seek(0)
            temp_error.seek(0)
            stdout_content = temp_output.read()
            stderr_content = temp_error.read()

            if result.returncode == 0:
                log_info(f"[SUCCESS] {description} - 成功完成")

                # 显示输出（如果有）
                if stdout_content.strip():
                    log_debug("命令输出:")
                    for line in stdout_content.strip().split('\n'):
                        log_debug(f"  {line}")

                return True
            else:
                log_error(f"[ERROR] {description} - 执行失败 (退出码: {result.returncode})")

                # 显示错误输出
                if stderr_content.strip():
                    log_error("错误信息:")
                    for line in stderr_content.strip().split('\n'):
                        log_error(f"  {line}")

                # 显示标准输出（可能包含有用信息）
                if stdout_content.strip():
                    log_warn("标准输出:")
                    for line in stdout_content.strip().split('\n'):
                        log_warn(f"  {line}")

                return False

    except Exception as e:
        log_error(f"执行命令时发生异常: {e}")
        return False
    finally:
        # 清理临时文件
        try:
            os.unlink(temp_output.name)
            os.unlink(temp_error.name)
        except:
            pass

def verify_command(cmd: str, package_name: str = None) -> bool:
    """
    验证命令是否成功安装

    Args:
        cmd: 要验证的命令
        package_name: 包名称（可选）

    Returns:
        bool: 命令是否可用
    """
    if package_name is None:
        package_name = cmd

    if shutil.which(cmd):
        try:
            result = subprocess.run([cmd, '--version'], capture_output=True,
                                  text=True, timeout=5)
            version_info = result.stdout.split('\n')[0] if result.stdout else "版本信息不可用"
            log_info(f"[SUCCESS] {package_name} 验证成功: {version_info}")
            return True
        except:
            log_info(f"[SUCCESS] {package_name} 验证成功: 命令可用")
            return True
    else:
        log_error(f"[ERROR] {package_name} 验证失败: 命令 '{cmd}' 未找到")
        return False

# =============================================================================
# 系统检测函数
# =============================================================================

def detect_os() -> Tuple[str, str]:
    """
    检测操作系统

    Returns:
        Tuple[str, str]: (操作系统名称, 版本)
    """
    try:
        if os.path.exists('/etc/os-release'):
            with open('/etc/os-release', 'r') as f:
                content = f.read()
                name_match = re.search(r'NAME="?([^"\n]+)"?', content)
                version_match = re.search(r'VERSION_ID="?([^"\n]+)"?', content)

                os_name = name_match.group(1) if name_match else "Unknown"
                os_version = version_match.group(1) if version_match else "Unknown"

                log_debug(f"检测到操作系统: {os_name} {os_version}")
                return os_name, os_version
        else:
            # 回退到 platform 模块
            os_name = platform.system()
            os_version = platform.release()
            log_debug(f"检测到操作系统: {os_name} {os_version}")
            return os_name, os_version

    except Exception as e:
        log_error(f"检测操作系统时发生错误: {e}")
        return "Unknown", "Unknown"

def detect_arch() -> str:
    """
    检测CPU架构

    Returns:
        str: CPU架构
    """
    arch = platform.machine()

    # 标准化架构名称
    arch_mapping = {
        'x86_64': 'x64',
        'aarch64': 'arm64',
        'arm64': 'arm64',
        'armv7l': 'arm'
    }

    normalized_arch = arch_mapping.get(arch, arch)
    log_debug(f"检测到CPU架构: {normalized_arch}")
    return normalized_arch

def check_root() -> str:
    """
    检查是否为root用户

    Returns:
        str: 如果是root返回空字符串，否则返回'sudo'
    """
    if os.geteuid() == 0:
        log_debug("当前用户为root")
        return ""
    else:
        log_debug("当前用户非root，将使用sudo")
        return "sudo"

# =============================================================================
# 网络检测函数
# =============================================================================

def check_network() -> bool:
    """
    检查网络连接

    Returns:
        bool: 网络是否正常
    """
    test_urls = [
        "www.baidu.com",
        "www.google.com",
        "github.com"
    ]

    log_info("检查网络连接...")

    for url in test_urls:
        try:
            result = subprocess.run(['curl', '-fsSL', '--connect-timeout', '5',
                                   '--max-time', '10', f'https://{url}'],
                                  capture_output=True, timeout=15)
            if result.returncode == 0:
                log_info(f"网络连接正常 ({url})")
                return True
        except:
            continue

    log_error("网络连接失败，请检查网络设置")
    return False

def check_dns() -> bool:
    """
    检查DNS解析

    Returns:
        bool: DNS是否正常
    """
    test_domain = "www.baidu.com"

    try:
        result = subprocess.run(['nslookup', test_domain],
                              capture_output=True, timeout=10)
        if result.returncode == 0:
            log_info("DNS解析正常")
            return True
        else:
            log_error("DNS解析失败")
            return False
    except:
        log_error("DNS解析失败")
        return False

# =============================================================================
# 包管理器函数
# =============================================================================

def update_package_manager() -> bool:
    """
    更新包管理器

    Returns:
        bool: 更新是否成功
    """
    log_info("[UPDATE] 开始更新包管理器...")

    sudo_cmd = check_root()

    if shutil.which('apt'):
        cmd = f"{sudo_cmd} apt update".strip()
        return execute_command(cmd, "更新APT包列表")
    elif shutil.which('yum'):
        cmd = f"{sudo_cmd} yum update -y".strip()
        return execute_command(cmd, "更新YUM包列表")
    elif shutil.which('dnf'):
        cmd = f"{sudo_cmd} dnf update -y".strip()
        return execute_command(cmd, "更新DNF包列表")
    elif shutil.which('pacman'):
        cmd = f"{sudo_cmd} pacman -Sy".strip()
        return execute_command(cmd, "更新Pacman包列表")
    else:
        log_error("[ERROR] 未找到支持的包管理器")
        return False

def install_package(package: str) -> bool:
    """
    安装包

    Args:
        package: 包名

    Returns:
        bool: 安装是否成功
    """
    log_info(f"[INSTALL] 开始安装软件包: {package}")

    # 首先检查包是否已安装
    if check_package_installed(package):
        log_info(f"[SUCCESS] {package} 已安装，跳过")
        return True

    sudo_cmd = check_root()

    if shutil.which('apt'):
        cmd = f"{sudo_cmd} apt install -y {package}".strip()
    elif shutil.which('yum'):
        cmd = f"{sudo_cmd} yum install -y {package}".strip()
    elif shutil.which('dnf'):
        cmd = f"{sudo_cmd} dnf install -y {package}".strip()
    elif shutil.which('pacman'):
        cmd = f"{sudo_cmd} pacman -S --noconfirm {package}".strip()
    else:
        log_error("[ERROR] 未找到支持的包管理器")
        return False

    if execute_command(cmd, f"安装 {package}"):
        # 验证安装是否成功
        if verify_package_installation(package):
            log_info(f"[SUCCESS] {package} 安装并验证成功")
            return True
        else:
            log_error(f"[ERROR] {package} 安装后验证失败")
            return False
    else:
        log_error(f"[ERROR] {package} 安装失败")
        return False

def verify_package_installation(package: str) -> bool:
    """
    验证软件包安装 - 使用多重策略

    Args:
        package: 包名

    Returns:
        bool: 包是否已正确安装
    """
    log_debug(f"开始验证软件包安装: {package}")

    # 策略1: 检查对应的命令是否可用
    command_mapping = {
        "git": "git",
        "curl": "curl",
        "wget": "wget",
        "zsh": "zsh",
        "unzip": "unzip"
    }

    if package in command_mapping:
        if shutil.which(command_mapping[package]):
            log_debug(f"命令验证: {package} 命令可用")
            return True

    # 策略2: 使用包管理器检查
    if check_package_installed(package):
        log_debug(f"包管理器验证: {package} 已安装")
        return True

    # 策略3: 对于某些包，检查关键文件是否存在
    if package == "fontconfig":
        if os.path.exists("/usr/bin/fc-cache") or os.path.exists("/usr/bin/fc-list"):
            log_debug("文件验证: fontconfig 工具存在")
            return True

    log_debug(f"所有验证策略都失败: {package}")
    return False

def check_package_installed(package: str) -> bool:
    """
    检查包是否已安装

    Args:
        package: 包名

    Returns:
        bool: 包是否已安装
    """
    log_debug(f"检查软件包安装状态: {package}")

    if shutil.which('apt'):
        # 使用多种方法检查包是否已安装
        try:
            result = subprocess.run(['dpkg', '-l', package],
                                  capture_output=True, text=True)
            if result.returncode == 0 and 'ii' in result.stdout:
                log_debug(f"dpkg检查: {package} 已安装")
                return True

            result = subprocess.run(['apt', 'list', '--installed', package],
                                  capture_output=True, text=True)
            if result.returncode == 0 and 'installed' in result.stdout:
                log_debug(f"apt list检查: {package} 已安装")
                return True
        except:
            pass

        log_debug(f"包管理器检查: {package} 未安装")
        return False

    elif shutil.which('yum'):
        try:
            result = subprocess.run(['yum', 'list', 'installed', package],
                                  capture_output=True, text=True)
            if result.returncode == 0:
                log_debug(f"yum检查: {package} 已安装")
                return True
        except:
            pass
        log_debug(f"yum检查: {package} 未安装")
        return False

    elif shutil.which('dnf'):
        try:
            result = subprocess.run(['dnf', 'list', 'installed', package],
                                  capture_output=True, text=True)
            if result.returncode == 0:
                log_debug(f"dnf检查: {package} 已安装")
                return True
        except:
            pass
        log_debug(f"dnf检查: {package} 未安装")
        return False

    elif shutil.which('pacman'):
        try:
            result = subprocess.run(['pacman', '-Q', package],
                                  capture_output=True, text=True)
            if result.returncode == 0:
                log_debug(f"pacman检查: {package} 已安装")
                return True
        except:
            pass
        log_debug(f"pacman检查: {package} 未安装")
        return False
    else:
        log_debug("未找到支持的包管理器")
        return False

# =============================================================================
# 错误处理函数
# =============================================================================

class ScriptError(Exception):
    """脚本执行错误"""
    pass

def handle_error(message: str, exit_code: int = 1) -> None:
    """
    错误处理

    Args:
        message: 错误消息
        exit_code: 退出码
    """
    log_error(f"脚本发生错误: {message}")
    sys.exit(exit_code)

# =============================================================================
# 用户交互函数
# =============================================================================

def can_use_interactive_selection() -> bool:
    """
    检查是否支持高级交互式选择器

    Returns:
        bool: 是否支持交互式选择
    """
    return shutil.which('tput') is not None and sys.stdin.isatty() and sys.stdout.isatty()

def interactive_ask_confirmation(message: str, default = "false") -> bool:
    """
    高级交互式确认选择器（支持键盘左右键选择）

    Args:
        message: 提示消息
        default: 默认选择 (True/False 或 "true"/"false")

    Returns:
        bool: 用户选择结果
    """
    # 检查是否在交互式环境中
    if not sys.stdin.isatty() or not sys.stdout.isatty():
        # 非交互式环境，直接返回默认值
        print(message)
        if isinstance(default, bool):
            default_bool = default
        else:
            default_bool = str(default).lower() in ["true", "y"]

        if default_bool:
            print(f"{GREEN}▶ 是{RESET} (自动选择)")
            return True
        else:
            print(f"{RED}▶ 否{RESET} (自动选择)")
            return False

    # 根据默认值设置初始选择
    if isinstance(default, bool):
        selected = 0 if default else 1
    else:
        selected = 0 if str(default).lower() in ["true", "y"] else 1

    try:
        import termios
        import tty

        def get_key():
            """获取按键输入"""
            fd = sys.stdin.fileno()
            old_settings = termios.tcgetattr(fd)
            try:
                tty.setraw(sys.stdin.fileno())
                key = sys.stdin.read(1)
                if key == '\x1b':  # ESC序列
                    key += sys.stdin.read(2)
                return key
            finally:
                termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)

        def clear_lines(n):
            """清除n行"""
            for _ in range(n):
                print('\033[A\033[K', end='')

        def draw_menu(selected_option):
            """绘制菜单"""
            print(f"╭─ {message}")
            print("│")
            if selected_option == 0:
                print(f"╰─ {BLUE}●{RESET} 是{CYAN} / ○ 否{RESET}")
            else:
                print(f"╰─ {CYAN}○ 是 / {RESET}{BLUE}●{RESET} 否")

        # 显示初始菜单
        draw_menu(selected)

        while True:
            key = get_key()

            if key in ['\x1b[D', 'a', 'A', 'h', 'H']:  # 左箭头或 a/h 键
                if selected > 0:
                    selected -= 1
                    clear_lines(3)
                    draw_menu(selected)
            elif key in ['\x1b[C', 'd', 'D', 'l', 'L']:  # 右箭头或 d/l 键
                if selected < 1:
                    selected += 1
                    clear_lines(3)
                    draw_menu(selected)
            elif key in ['\r', '\n']:  # 回车键
                clear_lines(3)
                break
            elif key == '\x03':  # Ctrl+C
                clear_lines(3)
                print(f"╭─ {message}")
                print("│")
                print(f"╰─ {YELLOW}操作被取消{RESET}")
                return False

        # 显示最终选择结果
        print(f"╭─ {message}")
        print("│")
        if selected == 0:
            print(f"╰─ {GREEN}●{RESET} {GREEN}是{RESET}{CYAN} / ○ 否{RESET}")
            return True
        else:
            print(f"╰─ {CYAN}○ 是 / {RESET}{GREEN}●{RESET} {GREEN}否{RESET}")
            return False

    except ImportError:
        # 回退到简单的输入方式
        while True:
            try:
                response = input(f"{message} (y/n) [{default}]: ").strip().lower()
                if not response:
                    response = default.lower()

                if response in ['y', 'yes', 'true']:
                    return True
                elif response in ['n', 'no', 'false']:
                    return False
                else:
                    print("请输入 y 或 n")
            except KeyboardInterrupt:
                print(f"\n{YELLOW}操作被取消{RESET}")
                return False

def interactive_select_menu(options: List[str], message: str, default_index: int = 0) -> Tuple[int, str]:
    """
    高级交互式菜单选择器（支持键盘上下键选择）

    Args:
        options: 选项列表
        message: 提示消息
        default_index: 默认选择的索引

    Returns:
        Tuple[int, str]: (选择的索引, 选择的选项)
    """
    if not options:
        return -1, ""

    # 检查是否在交互式环境中
    if not sys.stdin.isatty() or not sys.stdout.isatty():
        # 非交互式环境，返回默认选择
        if 0 <= default_index < len(options):
            print(message)
            print(f"{GREEN}▶ {options[default_index]}{RESET} (自动选择)")
            return default_index, options[default_index]
        else:
            return 0, options[0]

    selected = max(0, min(default_index, len(options) - 1))

    try:
        import termios
        import tty

        def get_key():
            """获取按键输入"""
            fd = sys.stdin.fileno()
            old_settings = termios.tcgetattr(fd)
            try:
                tty.setraw(sys.stdin.fileno())
                key = sys.stdin.read(1)
                if key == '\x1b':  # ESC序列
                    key += sys.stdin.read(2)
                return key
            finally:
                termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)

        def clear_lines(n):
            """清除n行"""
            if n <= 0:
                return

            # 移动光标到上n行并清除每一行
            for _ in range(n):
                print('\033[A\033[K', end='')

            # 确保光标位置正确
            sys.stdout.flush()

        def draw_menu(selected_option, show_header=True):
            """绘制美化菜单"""
            lines_count = 0

            if show_header:
                print(message)
                print()
                lines_count += 2

            for i, option in enumerate(options):
                if i == selected_option:
                    # 选中项使用蓝色背景和白色文字
                    print(f"  {BLUE}▶{RESET} {CYAN}{option}{RESET}")
                else:
                    print(f"    {option}")

                # 计算实际打印的行数（考虑选项中的换行符）
                option_lines = option.count('\n') + 1
                lines_count += option_lines

            # 添加底部分隔线
            print()
            print(f"{GRAY}{'─' * 78}{RESET}")
            lines_count += 2

            return lines_count

        # 显示初始菜单
        last_lines_count = draw_menu(selected)

        while True:
            key = get_key()

            if key in ['\x1b[A', 'w', 'W', 'k', 'K']:  # 上箭头或 w/k 键
                if selected > 0:
                    selected -= 1
                    clear_lines(last_lines_count)
                    last_lines_count = draw_menu(selected, False)
            elif key in ['\x1b[B', 's', 'S', 'j', 'J']:  # 下箭头或 s/j 键
                if selected < len(options) - 1:
                    selected += 1
                    clear_lines(last_lines_count)
                    last_lines_count = draw_menu(selected, False)
            elif key in ['\r', '\n']:  # 回车键
                clear_lines(last_lines_count)
                break
            elif key == '\x03':  # Ctrl+C
                clear_lines(last_lines_count)
                print(f"{YELLOW}操作被取消{RESET}")
                return -1, ""

        # 显示最终选择结果
        print(message)
        print(f"{GREEN}▶ {options[selected]}{RESET}")
        print()

        return selected, options[selected]

    except ImportError:
        # 回退到简单的选择方式
        print(message)
        for i, option in enumerate(options):
            print(f"{i + 1}. {option}")

        while True:
            try:
                choice = input(f"请选择 (1-{len(options)}) [{default_index + 1}]: ").strip()
                if not choice:
                    choice = str(default_index + 1)

                index = int(choice) - 1
                if 0 <= index < len(options):
                    return index, options[index]
                else:
                    print(f"请输入 1 到 {len(options)} 之间的数字")
            except (ValueError, KeyboardInterrupt):
                print(f"\n{YELLOW}操作被取消{RESET}")
                return -1, ""

def select_menu(options: List[str], message: str, default_index: int = 0) -> Tuple[int, str]:
    """
    标准化菜单选择函数 - 只使用高级交互模式

    Args:
        options: 选项列表
        message: 提示消息
        default_index: 默认选择的索引

    Returns:
        Tuple[int, str]: (选择的索引, 选择的选项)
    """
    return interactive_select_menu(options, message, default_index)

# =============================================================================
# 初始化函数
# =============================================================================

def init_environment() -> None:
    """初始化环境"""
    # 检测系统信息
    os_name, os_version = detect_os()
    arch = detect_arch()
    sudo_cmd = check_root()

    log_info("环境初始化完成")
    log_info(f"操作系统: {os_name} {os_version}")
    log_info(f"CPU架构: {arch}")
    log_info(f"权限模式: {'root' if not sudo_cmd else 'sudo'}")

# =============================================================================
# 脚本信息显示
# =============================================================================

def show_header(script_name: str, script_version: str = "1.0", script_description: str = "") -> None:
    """
    显示脚本头部信息

    Args:
        script_name: 脚本名称
        script_version: 脚本版本
        script_description: 脚本描述
    """
    print(f"{BLUE}================================================================{RESET}")
    print(f"{BLUE} {script_name}{RESET}")
    print(f"{BLUE}版本: {script_version}{RESET}")
    print(f"{BLUE}作者: saul{RESET}")
    print(f"{BLUE}邮箱: sau1amaranth@gmail.com{RESET}")
    if script_description:
        print(f"{BLUE}描述: {script_description}{RESET}")
    print(f"{BLUE}================================================================{RESET}")

def show_footer() -> None:
    """显示脚本尾部信息"""
    print(f"{GREEN}================================================================{RESET}")
    print(f"{GREEN} 脚本执行完成{RESET}")
    print(f"{GREEN}================================================================{RESET}")

# =============================================================================
# 全局变量和常量
# =============================================================================

# 存储全局状态
MENU_SELECT_RESULT = ""
MENU_SELECT_INDEX = -1

# 设置全局变量以便其他模块使用
def set_menu_result(index: int, result: str) -> None:
    """设置菜单选择结果"""
    global MENU_SELECT_INDEX, MENU_SELECT_RESULT
    MENU_SELECT_INDEX = index
    MENU_SELECT_RESULT = result

def get_menu_result() -> Tuple[int, str]:
    """获取菜单选择结果"""
    return MENU_SELECT_INDEX, MENU_SELECT_RESULT

# =============================================================================
# 模块导入检查
# =============================================================================

def check_python_version() -> bool:
    """检查Python版本"""
    if sys.version_info < (3, 6):
        log_error("错误：需要Python 3.6或更高版本")
        return False
    return True

def install_required_packages() -> bool:
    """安装必需的Python包"""
    required_packages = ['colorama']

    for package in required_packages:
        try:
            __import__(package)
        except ImportError:
            log_info(f"安装Python包: {package}")
            try:
                subprocess.run([sys.executable, '-m', 'pip', 'install', package],
                             check=True, capture_output=True)
                log_info(f"成功安装: {package}")
            except subprocess.CalledProcessError:
                log_warn(f"无法安装 {package}，将使用基本功能")

    return True

# 初始化检查
if __name__ != "__main__":
    if not check_python_version():
        sys.exit(1)
    install_required_packages()
