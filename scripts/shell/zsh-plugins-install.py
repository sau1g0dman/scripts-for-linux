#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
=============================================================================
ZSH 插件和工具安装脚本
作者: saul
版本: 2.0
描述: 安装和配置ZSH插件、额外工具和优化配置的专用脚本
功能: 插件安装、工具配置、智能配置管理、依赖处理
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
    print("错误：无法加载通用函数库")
    print("请确保在项目根目录中运行此脚本")
    sys.exit(1)

# =============================================================================
# 全局配置变量
# =============================================================================

# 版本和模式配置
ZSH_PLUGINS_VERSION = "2.0"
ZSH_INSTALL_MODE = os.environ.get("ZSH_INSTALL_MODE", "interactive")  # interactive/auto/minimal

# 安装路径配置
ZSH_INSTALL_DIR = os.environ.get("ZSH_INSTALL_DIR", os.path.expanduser("~"))
OMZ_DIR = os.path.join(ZSH_INSTALL_DIR, ".oh-my-zsh")
ZSH_CUSTOM_DIR = os.path.join(OMZ_DIR, "custom")
ZSH_PLUGINS_DIR = os.path.join(ZSH_CUSTOM_DIR, "plugins")

# 插件配置
ZSH_PLUGINS = [
    ("zsh-autosuggestions", "https://github.com/zsh-users/zsh-autosuggestions"),
    ("zsh-syntax-highlighting", "https://github.com/zsh-users/zsh-syntax-highlighting"),
    ("you-should-use", "https://github.com/MichaelAquilina/zsh-you-should-use"),
]

# 完整插件列表（用于.zshrc配置）
COMPLETE_PLUGINS = [
    "git", "extract", "systemadmin", "zsh-interactive-cd", "systemd", "sudo",
    "docker", "ubuntu", "man", "command-not-found", "common-aliases",
    "docker-compose", "zsh-autosuggestions", "zsh-syntax-highlighting",
    "tmux", "you-should-use"
]

# 额外工具配置
TMUX_CONFIG_REPO = "https://github.com/gpakosz/.tmux.git"

# 状态管理
PLUGINS_INSTALL_STATE = ""
ROLLBACK_ACTIONS = []
INSTALL_LOG_FILE = f"/tmp/zsh-plugins-install-{datetime.now().strftime('%Y%m%d-%H%M%S')}.log"
ZSH_BACKUP_DIR = os.path.expanduser(f"~/.zsh-plugins-backup-{datetime.now().strftime('%Y%m%d-%H%M%S')}")

# =============================================================================
# 状态管理和回滚功能
# =============================================================================

def set_install_state(state: str) -> None:
    """
    设置安装状态

    Args:
        state: 状态名称
    """
    global PLUGINS_INSTALL_STATE
    PLUGINS_INSTALL_STATE = state
    log_debug(f"插件安装状态更新: {state}")

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
                path = action[7:].strip("'\"")  # 移除 "rm -rf " 前缀和引号
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
                    src, dst = parts[1].strip("'\""), parts[2].strip("'\"")
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

def check_zsh_plugins_requirements() -> bool:
    """
    检查ZSH插件安装要求

    Returns:
        bool: 要求是否满足
    """
    log_info("检查ZSH插件安装要求...")

    # 检查Oh My Zsh是否已安装
    if not os.path.exists(OMZ_DIR):
        log_error("Oh My Zsh未安装，请先运行ZSH核心安装脚本")
        return False

    # 检查必需工具
    required_tools = ["git", "curl"]
    for tool in required_tools:
        if not shutil.which(tool):
            log_error(f"缺少必需工具: {tool}")
            return False

    # 检查网络连接
    try:
        result = subprocess.run(['curl', '-fsSL', '--connect-timeout', '5',
                               '--max-time', '10', 'https://github.com'],
                              capture_output=True, timeout=15)
        if result.returncode != 0:
            log_error("网络连接失败，无法下载插件")
            return False
    except:
        log_error("网络连接检查失败")
        return False

    log_info("系统依赖检查通过")
    return True

def backup_existing_config() -> bool:
    """
    备份现有配置

    Returns:
        bool: 备份是否成功
    """
    log_info("备份现有ZSH插件配置...")

    backup_files = [
        os.path.expanduser("~/.zshrc"),
        os.path.expanduser("~/.tmux.conf"),
        ZSH_PLUGINS_DIR
    ]

    # 创建备份目录
    try:
        os.makedirs(ZSH_BACKUP_DIR, exist_ok=True)
        add_rollback_action(f"rm -rf '{ZSH_BACKUP_DIR}'")
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
# ZSH插件安装功能
# =============================================================================

def install_single_plugin(plugin_name: str, plugin_repo: str) -> bool:
    """
    安装单个ZSH插件

    Args:
        plugin_name: 插件名称
        plugin_repo: 插件仓库URL

    Returns:
        bool: 安装是否成功
    """
    plugin_dir = os.path.join(ZSH_PLUGINS_DIR, plugin_name)

    log_info(f"安装插件: {plugin_name}")

    # 检查插件是否已安装
    if os.path.exists(plugin_dir) and os.listdir(plugin_dir):
        log_info(f"插件 {plugin_name} 已安装，跳过")
        return True

    # 克隆插件仓库
    log_info(f"克隆插件仓库: {plugin_repo}")
    try:
        result = subprocess.run([
            'git', 'clone', '--depth=1', f'{plugin_repo}.git', plugin_dir
        ], capture_output=True, text=True)

        if result.returncode == 0:
            add_rollback_action(f"rm -rf '{plugin_dir}'")
            log_info(f"插件 {plugin_name} 安装成功")
            return True
        else:
            log_error(f"插件 {plugin_name} 安装失败: {result.stderr}")
            return False

    except Exception as e:
        log_error(f"插件 {plugin_name} 安装过程中发生错误: {e}")
        return False

def install_zsh_plugins() -> bool:
    """
    安装所有ZSH插件

    Returns:
        bool: 安装是否成功
    """
    log_info("安装ZSH插件...")
    set_install_state("INSTALLING_PLUGINS")

    failed_plugins = []
    success_count = 0
    total_plugins = len(ZSH_PLUGINS)

    # 确保插件目录存在
    os.makedirs(ZSH_PLUGINS_DIR, exist_ok=True)

    # 安装每个插件
    for plugin_name, plugin_repo in ZSH_PLUGINS:
        if install_single_plugin(plugin_name, plugin_repo):
            success_count += 1
        else:
            failed_plugins.append(plugin_name)

    # 显示安装结果
    log_info(f"插件安装完成: {success_count}/{total_plugins} 成功")

    if failed_plugins:
        log_warn(f"以下插件安装失败: {', '.join(failed_plugins)}")
        return False

    return True

# =============================================================================
# 配置更新功能
# =============================================================================

def update_zshrc_config() -> bool:
    """
    更新.zshrc配置文件

    Returns:
        bool: 更新是否成功
    """
    log_info("更新.zshrc配置...")
    set_install_state("UPDATING_ZSHRC")

    zshrc_path = os.path.expanduser("~/.zshrc")

    try:
        # 读取现有配置
        if os.path.exists(zshrc_path):
            with open(zshrc_path, 'r') as f:
                content = f.read()
        else:
            content = ""

        # 更新插件配置
        plugins_line = f"plugins=({' '.join(COMPLETE_PLUGINS)})"

        # 查找并替换plugins行
        import re
        if re.search(r'^plugins=\(.*\)$', content, re.MULTILINE):
            content = re.sub(r'^plugins=\(.*\)$', plugins_line, content, flags=re.MULTILINE)
        else:
            # 如果没有找到plugins行，在ZSH_THEME后添加
            if 'ZSH_THEME=' in content:
                content = re.sub(r'(ZSH_THEME=.*\n)', r'\1\n# 插件配置\n' + plugins_line + '\n', content)
            else:
                content += f"\n# 插件配置\n{plugins_line}\n"

        # 写入更新后的配置
        with open(zshrc_path, 'w') as f:
            f.write(content)

        log_info(f".zshrc配置更新完成: {zshrc_path}")
        add_rollback_action(f"mv '{zshrc_path}.backup' '{zshrc_path}'")
        return True

    except Exception as e:
        log_error(f"更新.zshrc配置失败: {e}")
        return False

def install_tmux_config() -> bool:
    """
    安装Tmux配置

    Returns:
        bool: 安装是否成功
    """
    log_info("安装Tmux配置...")
    set_install_state("INSTALLING_TMUX_CONFIG")

    tmux_config_dir = os.path.expanduser("~/.tmux")
    tmux_config_file = os.path.expanduser("~/.tmux.conf")

    try:
        # 检查是否已安装
        if os.path.exists(tmux_config_dir):
            log_info("Tmux配置已存在，跳过")
            return True

        # 克隆Tmux配置仓库
        result = subprocess.run([
            'git', 'clone', TMUX_CONFIG_REPO, tmux_config_dir
        ], capture_output=True, text=True)

        if result.returncode != 0:
            log_error(f"克隆Tmux配置失败: {result.stderr}")
            return False

        # 创建符号链接
        tmux_conf_source = os.path.join(tmux_config_dir, ".tmux.conf")
        if os.path.exists(tmux_conf_source):
            if os.path.exists(tmux_config_file):
                os.rename(tmux_config_file, f"{tmux_config_file}.backup")

            os.symlink(tmux_conf_source, tmux_config_file)

            add_rollback_action(f"rm -rf '{tmux_config_dir}'")
            add_rollback_action(f"rm -f '{tmux_config_file}'")

            log_info("Tmux配置安装成功")
            return True
        else:
            log_error("Tmux配置文件不存在")
            return False

    except Exception as e:
        log_error(f"安装Tmux配置时发生错误: {e}")
        return False

# =============================================================================
# 主函数
# =============================================================================

def show_header() -> None:
    """显示脚本头部信息"""
    os.system('clear' if os.name == 'posix' else 'cls')

    print(f"{BLUE}================================================================{RESET}")
    print(f"{BLUE}ZSH 插件和工具安装脚本{RESET}")
    print(f"{BLUE}版本: {ZSH_PLUGINS_VERSION}{RESET}")
    print(f"{BLUE}作者: saul{RESET}")
    print(f"{BLUE}邮箱: sau1amaranth@gmail.com{RESET}")
    print(f"{BLUE}================================================================{RESET}")
    print()
    print(f"{CYAN}本脚本将安装和配置ZSH插件和工具：{RESET}")
    print(f"{CYAN}• ZSH自动补全插件{RESET}")
    print(f"{CYAN}• ZSH语法高亮插件{RESET}")
    print(f"{CYAN}• ZSH实用插件{RESET}")
    print(f"{CYAN}• Tmux配置{RESET}")
    print()

def show_installation_summary() -> None:
    """显示安装总结"""
    print(f"{GREEN}================================================================{RESET}")
    print(f"{GREEN}ZSH 插件和工具安装完成！{RESET}")
    print(f"{GREEN}================================================================{RESET}")
    print()
    print(f"{CYAN}安装内容：{RESET}")

    # 显示已安装的插件
    for plugin_name, _ in ZSH_PLUGINS:
        plugin_dir = os.path.join(ZSH_PLUGINS_DIR, plugin_name)
        status = "✅ 已安装" if os.path.exists(plugin_dir) else "❌ 未安装"
        print(f"• {plugin_name}: {status}")

    # 显示配置文件
    zshrc_path = os.path.expanduser("~/.zshrc")
    tmux_conf_path = os.path.expanduser("~/.tmux.conf")

    print(f"• .zshrc配置: {'✅ 已更新' if os.path.exists(zshrc_path) else '❌ 未找到'}")
    print(f"• Tmux配置: {'✅ 已安装' if os.path.exists(tmux_conf_path) else '❌ 未安装'}")

    print()
    print(f"{YELLOW}后续步骤：{RESET}")
    print("1. 重新启动终端或运行 'source ~/.zshrc' 来加载新配置")
    print("2. 插件将在下次启动ZSH时自动生效")
    print("3. 使用 'tmux' 命令体验新的Tmux配置")
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
        show_header()

        # 检查系统要求
        if not check_zsh_plugins_requirements():
            log_error("系统要求检查失败")
            return 1

        # 用户确认
        if ZSH_INSTALL_MODE == "interactive":
            if not interactive_ask_confirmation("是否继续安装ZSH插件和工具？", "true"):
                log_info("用户取消安装")
                return 0

        # 备份现有配置
        if not backup_existing_config():
            log_error("配置备份失败")
            return 1

        # 安装ZSH插件
        if not install_zsh_plugins():
            log_error("ZSH插件安装失败")
            execute_rollback()
            return 1

        # 更新.zshrc配置
        if not update_zshrc_config():
            log_error(".zshrc配置更新失败")
            execute_rollback()
            return 1

        # 安装Tmux配置
        if not install_tmux_config():
            log_warn("Tmux配置安装失败，但不影响ZSH插件功能")

        # 显示安装总结
        show_installation_summary()

        set_install_state("completed")
        log_info("ZSH插件和工具安装完成")
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
