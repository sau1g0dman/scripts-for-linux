#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
=============================================================================
ZSH 核心环境安装脚本
作者: saul
版本: 2.0
描述: 安装 ZSH shell、Oh My Zsh 框架和 Powerlevel10k 主题的核心脚本
功能: 系统检查、基础软件安装、框架配置、主题安装
=============================================================================
"""

import os
import sys
import subprocess
import tempfile
import shutil
import json
import urllib.request
from datetime import datetime
from pathlib import Path
from typing import List, Dict, Tuple, Optional

# 添加父目录到Python路径以导入common模块
script_dir = Path(__file__).parent
sys.path.insert(0, str(script_dir.parent))

try:
    from common import *
except ImportError:
    # 尝试远程加载common模块的功能
    print("错误：无法加载通用函数库")
    print("请确保在项目根目录中运行此脚本")
    sys.exit(1)

# =============================================================================
# 全局配置变量
# =============================================================================

# 版本和模式配置
ZSH_CORE_VERSION = "2.0"
ZSH_INSTALL_MODE = os.environ.get("ZSH_INSTALL_MODE", "interactive")  # interactive/auto/minimal

# 安装路径配置
ZSH_INSTALL_DIR = os.environ.get("ZSH_INSTALL_DIR", os.path.expanduser("~"))
OMZ_DIR = os.path.join(ZSH_INSTALL_DIR, ".oh-my-zsh")
ZSH_CUSTOM_DIR = os.path.join(OMZ_DIR, "custom")
ZSH_THEMES_DIR = os.path.join(ZSH_CUSTOM_DIR, "themes")

# 下载源配置
OMZ_INSTALL_URL = "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
P10K_THEME_REPO = "romkatv/powerlevel10k"
P10K_CONFIG_URL = "https://raw.githubusercontent.com/romkatv/powerlevel10k/master/config/p10k-rainbow.zsh"

# 必需软件包列表
REQUIRED_PACKAGES = [
    ("zsh", "ZSH Shell"),
    ("git", "Git版本控制"),
    ("curl", "网络下载工具"),
    ("wget", "备用下载工具"),
]

# 状态管理
ZSH_INSTALL_STATE = ""
ROLLBACK_ACTIONS = []
INSTALL_LOG_FILE = f"/tmp/zsh-core-install-{datetime.now().strftime('%Y%m%d-%H%M%S')}.log"
ZSH_BACKUP_DIR = os.path.expanduser(f"~/.zsh-backup-{datetime.now().strftime('%Y%m%d-%H%M%S')}")

# =============================================================================
# 状态管理和回滚功能
# =============================================================================

def set_install_state(state: str) -> None:
    """
    设置安装状态

    Args:
        state: 状态名称
    """
    global ZSH_INSTALL_STATE
    ZSH_INSTALL_STATE = state
    log_debug(f"安装状态更新: {state}")

    with open(INSTALL_LOG_FILE, "a") as f:
        f.write(f"{datetime.now().strftime('%Y-%m-%d %H:%M:%S')} - STATE: {state}\n")

def add_rollback_action(action: str) -> None:
    """
    添加回滚操作

    Args:
        action: 回滚命令
    """
    ROLLBACK_ACTIONS.append(action)
    log_debug(f"添加回滚操作: {action}")

def execute_rollback() -> bool:
    """
    执行回滚操作

    Returns:
        bool: 回滚是否成功
    """
    if not ROLLBACK_ACTIONS:
        log_info("无需回滚操作")
        return True

    log_warn("开始执行回滚操作...")
    rollback_count = 0

    # 逆序执行回滚操作
    for action in reversed(ROLLBACK_ACTIONS):
        log_info(f"执行回滚: {action}")

        try:
            if action.startswith("rm -rf "):
                # 安全删除操作
                path = action[7:]  # 移除 "rm -rf " 前缀
                if os.path.exists(path):
                    if os.path.isdir(path):
                        shutil.rmtree(path)
                    else:
                        os.unlink(path)
                    log_info(f"已删除: {path}")
            elif action.startswith("mv "):
                # 移动操作
                parts = action.split(" ", 2)
                if len(parts) == 3:
                    src, dst = parts[1], parts[2]
                    if os.path.exists(src):
                        shutil.move(src, dst)
                        log_info(f"已移动: {src} -> {dst}")
            else:
                # 其他shell命令
                result = subprocess.run(action, shell=True, capture_output=True, text=True)
                if result.returncode == 0:
                    log_info(f"回滚成功: {action}")
                else:
                    log_error(f"回滚失败: {action} - {result.stderr}")

            rollback_count += 1

        except Exception as e:
            log_error(f"回滚操作失败: {action} - {e}")

    log_info(f"回滚完成，执行了 {rollback_count} 个操作")
    return rollback_count > 0

# =============================================================================
# 系统检查函数
# =============================================================================

def check_zsh_requirements() -> bool:
    """
    检查ZSH安装要求

    Returns:
        bool: 要求是否满足
    """
    log_info("检查ZSH安装要求...")

    # 检查操作系统
    os_name, os_version = detect_os()

    if not any(supported in os_name.lower() for supported in ["ubuntu", "debian", "centos", "fedora"]):
        log_error(f"不支持的操作系统: {os_name}")
        return False

    # 检查必需软件包
    missing_packages = []
    for package, description in REQUIRED_PACKAGES:
        if not check_package_installed(package):
            missing_packages.append((package, description))

    if missing_packages:
        log_info("需要安装以下软件包:")
        for package, description in missing_packages:
            log_info(f"  - {description} ({package})")

        # 自动安装缺失的软件包
        for package, description in missing_packages:
            log_info(f"正在安装: {description}")
            if not install_package(package):
                log_error(f"安装失败: {description}")
                return False

    # 检查网络连接
    if not check_network():
        log_error("网络连接检查失败")
        return False

    log_info("ZSH安装要求检查通过")
    return True

def backup_existing_config() -> bool:
    """
    备份现有配置

    Returns:
        bool: 备份是否成功
    """
    log_info("备份现有ZSH配置...")

    backup_files = [
        os.path.expanduser("~/.zshrc"),
        os.path.expanduser("~/.zsh_history"),
        os.path.expanduser("~/.p10k.zsh"),
        OMZ_DIR
    ]

    # 创建备份目录
    try:
        os.makedirs(ZSH_BACKUP_DIR, exist_ok=True)
        add_rollback_action(f"rm -rf {ZSH_BACKUP_DIR}")
    except Exception as e:
        log_error(f"创建备份目录失败: {e}")
        return False

    backup_count = 0
    for file_path in backup_files:
        if os.path.exists(file_path):
            try:
                backup_name = os.path.basename(file_path)
                backup_path = os.path.join(ZSH_BACKUP_DIR, backup_name)

                if os.path.isdir(file_path):
                    shutil.copytree(file_path, backup_path)
                else:
                    shutil.copy2(file_path, backup_path)

                log_info(f"已备份: {file_path} -> {backup_path}")
                backup_count += 1

            except Exception as e:
                log_warn(f"备份失败: {file_path} - {e}")

    if backup_count > 0:
        log_info(f"配置备份完成，备份目录: {ZSH_BACKUP_DIR}")
    else:
        log_info("没有找到需要备份的配置文件")

    return True

# =============================================================================
# ZSH安装函数
# =============================================================================

def install_zsh_shell() -> bool:
    """
    安装ZSH Shell

    Returns:
        bool: 安装是否成功
    """
    log_info("安装ZSH Shell...")
    set_install_state("installing_zsh")

    if shutil.which("zsh"):
        log_info("ZSH已安装，跳过")
        return True

    if not install_package("zsh"):
        log_error("ZSH安装失败")
        return False

    # 验证安装
    if not shutil.which("zsh"):
        log_error("ZSH安装验证失败")
        return False

    log_info("ZSH Shell安装成功")
    return True

def install_oh_my_zsh() -> bool:
    """
    安装Oh My Zsh框架

    Returns:
        bool: 安装是否成功
    """
    log_info("安装Oh My Zsh框架...")
    set_install_state("installing_omz")

    # 检查是否已安装
    if os.path.exists(OMZ_DIR):
        log_info("Oh My Zsh已安装，跳过")
        return True

    try:
        # 下载安装脚本
        log_info("下载Oh My Zsh安装脚本...")
        with urllib.request.urlopen(OMZ_INSTALL_URL) as response:
            install_script = response.read().decode('utf-8')

        # 创建临时脚本文件
        with tempfile.NamedTemporaryFile(mode='w', suffix='.sh', delete=False) as temp_script:
            temp_script.write(install_script)
            temp_script_path = temp_script.name

        # 设置环境变量以自动安装
        env = os.environ.copy()
        env['RUNZSH'] = 'no'  # 不要在安装后切换到zsh
        env['CHSH'] = 'no'    # 不要改变默认shell

        # 执行安装脚本
        log_info("执行Oh My Zsh安装...")
        result = subprocess.run(['bash', temp_script_path], env=env,
                              capture_output=True, text=True)

        # 清理临时文件
        os.unlink(temp_script_path)

        if result.returncode == 0:
            log_info("Oh My Zsh安装成功")
            add_rollback_action(f"rm -rf {OMZ_DIR}")
            return True
        else:
            log_error(f"Oh My Zsh安装失败: {result.stderr}")
            return False

    except Exception as e:
        log_error(f"Oh My Zsh安装过程中发生错误: {e}")
        return False

def install_powerlevel10k() -> bool:
    """
    安装Powerlevel10k主题

    Returns:
        bool: 安装是否成功
    """
    log_info("安装Powerlevel10k主题...")
    set_install_state("installing_p10k")

    p10k_dir = os.path.join(ZSH_THEMES_DIR, "powerlevel10k")

    # 检查是否已安装
    if os.path.exists(p10k_dir):
        log_info("Powerlevel10k已安装，跳过")
        return True

    try:
        # 确保themes目录存在
        os.makedirs(ZSH_THEMES_DIR, exist_ok=True)

        # 克隆Powerlevel10k仓库
        log_info("克隆Powerlevel10k仓库...")
        result = subprocess.run([
            'git', 'clone', '--depth=1',
            f'https://github.com/{P10K_THEME_REPO}.git',
            p10k_dir
        ], capture_output=True, text=True)

        if result.returncode == 0:
            log_info("Powerlevel10k主题安装成功")
            add_rollback_action(f"rm -rf {p10k_dir}")
            return True
        else:
            log_error(f"Powerlevel10k安装失败: {result.stderr}")
            return False

    except Exception as e:
        log_error(f"Powerlevel10k安装过程中发生错误: {e}")
        return False

# =============================================================================
# 配置函数
# =============================================================================

def configure_zshrc() -> bool:
    """
    配置.zshrc文件

    Returns:
        bool: 配置是否成功
    """
    log_info("配置.zshrc文件...")
    set_install_state("configuring_zshrc")

    zshrc_path = os.path.expanduser("~/.zshrc")

    try:
        # 基本配置内容
        zshrc_content = f'''# Oh My Zsh配置
export ZSH="{OMZ_DIR}"

# 主题设置
ZSH_THEME="powerlevel10k/powerlevel10k"

# 插件配置
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    history-substring-search
)

# 加载Oh My Zsh
source $ZSH/oh-my-zsh.sh

# Powerlevel10k配置
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# 用户自定义配置
# 在这里添加你的自定义配置...

'''

        # 写入配置文件
        with open(zshrc_path, 'w') as f:
            f.write(zshrc_content)

        log_info(f".zshrc配置完成: {zshrc_path}")
        add_rollback_action(f"rm -f {zshrc_path}")
        return True

    except Exception as e:
        log_error(f"配置.zshrc失败: {e}")
        return False

def set_default_shell() -> bool:
    """
    设置ZSH为默认Shell

    Returns:
        bool: 设置是否成功
    """
    log_info("设置ZSH为默认Shell...")

    # 获取zsh路径
    zsh_path = shutil.which("zsh")
    if not zsh_path:
        log_error("找不到zsh可执行文件")
        return False

    # 检查当前shell
    current_shell = os.environ.get('SHELL', '')
    if current_shell == zsh_path:
        log_info("ZSH已是默认Shell")
        return True

    try:
        # 使用chsh命令更改默认shell
        result = subprocess.run(['chsh', '-s', zsh_path],
                              capture_output=True, text=True, input='\n')

        if result.returncode == 0:
            log_info(f"默认Shell已设置为: {zsh_path}")
            log_info("注意：需要重新登录才能生效")
            return True
        else:
            log_warn(f"自动设置默认Shell失败: {result.stderr}")
            log_info("请手动运行以下命令设置默认Shell:")
            log_info(f"  chsh -s {zsh_path}")
            return True  # 不算作失败，因为可以手动设置

    except Exception as e:
        log_warn(f"设置默认Shell时发生错误: {e}")
        log_info("请手动运行以下命令设置默认Shell:")
        log_info(f"  chsh -s {zsh_path}")
        return True

# =============================================================================
# 主函数
# =============================================================================

def show_zsh_core_header() -> None:
    """显示ZSH核心环境安装脚本的统一头部信息"""
    os.system('clear' if os.name == 'posix' else 'cls')

    # 使用统一的头部显示函数
    show_header(
        "ZSH 核心环境安装脚本",
        ZSH_CORE_VERSION,
        "安装 ZSH shell、Oh My Zsh 框架和 Powerlevel10k 主题的核心脚本"
    )

    print(f"{CYAN}本脚本将安装和配置ZSH核心环境：{RESET}")
    print(f"{BLUE}{'─'*70}{RESET}")
    print(f"  {GREEN}•{RESET} ZSH Shell")
    print(f"  {GREEN}•{RESET} Oh My Zsh 框架")
    print(f"  {GREEN}•{RESET} Powerlevel10k 主题")
    print(f"{BLUE}{'─'*70}{RESET}")
    print()

def show_installation_summary() -> None:
    """显示安装总结"""
    print(f"\n{GREEN}{'='*70}")
    print(f" ZSH 核心环境安装完成！")
    print(f"{'='*70}{RESET}")
    print()
    print(f"{CYAN}安装内容：{RESET}")
    print(f"{BLUE}{'─'*70}{RESET}")
    print(f"  {GREEN}•{RESET} ZSH Shell: {shutil.which('zsh') or '未安装'}")
    print(f"  {GREEN}•{RESET} Oh My Zsh: {OMZ_DIR}")
    print(f"  {GREEN}•{RESET} Powerlevel10k: {os.path.join(ZSH_THEMES_DIR, 'powerlevel10k')}")
    print(f"  {GREEN}•{RESET} 配置文件: ~/.zshrc")
    print(f"{BLUE}{'─'*70}{RESET}")
    print()
    print(f"{YELLOW}后续步骤：{RESET}")
    print(f"{BLUE}{'─'*70}{RESET}")
    print(f"  {GREEN}1.{RESET} 重新登录或运行 'exec zsh' 来启动ZSH")
    print(f"  {GREEN}2.{RESET} 首次启动时会自动运行Powerlevel10k配置向导")
    print(f"  {GREEN}3.{RESET} 可以通过 'p10k configure' 重新配置主题")
    print(f"{BLUE}{'─'*70}{RESET}")
    print(f"{GREEN}感谢使用ZSH核心环境安装脚本！{RESET}")
    print()
    print()
    if os.path.exists(ZSH_BACKUP_DIR):
        print(f"{CYAN}备份位置：{RESET}{ZSH_BACKUP_DIR}")
        print()

def main() -> int:
    """
    主函数

    Returns:
        int: 退出码
    """
    try:
        # 显示头部信息
        show_zsh_core_header()

        # 检查系统要求
        if not check_zsh_requirements():
            log_error("系统要求检查失败")
            return 1

        # 用户确认
        if ZSH_INSTALL_MODE == "interactive":
            if not interactive_ask_confirmation("是否继续安装ZSH核心环境？", "true"):
                log_info("用户取消安装")
                return 0

        # 备份现有配置
        if not backup_existing_config():
            log_error("配置备份失败")
            return 1

        # 安装ZSH Shell
        if not install_zsh_shell():
            log_error("ZSH Shell安装失败")
            execute_rollback()
            return 1

        # 安装Oh My Zsh
        if not install_oh_my_zsh():
            log_error("Oh My Zsh安装失败")
            execute_rollback()
            return 1

        # 安装Powerlevel10k主题
        if not install_powerlevel10k():
            log_error("Powerlevel10k主题安装失败")
            execute_rollback()
            return 1

        # 配置.zshrc
        if not configure_zshrc():
            log_error(".zshrc配置失败")
            execute_rollback()
            return 1

        # 设置默认Shell
        set_default_shell()  # 这个不算作关键失败

        # 显示安装总结
        show_installation_summary()

        set_install_state("completed")
        log_info("ZSH核心环境安装完成")
        return 0

    except KeyboardInterrupt:
        print(f"\n{YELLOW}安装被用户中断{RESET}")
        execute_rollback()
        return 130
    except Exception as e:
        log_error(f"安装过程中发生错误: {e}")
        execute_rollback()
        return 1

# =============================================================================
# 脚本入口点
# =============================================================================

if __name__ == "__main__":
    # 设置信号处理
    import signal

    def signal_handler(signum, frame):
        print(f"\n{RED}[ERROR] 脚本执行被中断{RESET}")
        execute_rollback()
        sys.exit(1)

    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    # 执行主函数
    exit_code = main()
    sys.exit(exit_code)
