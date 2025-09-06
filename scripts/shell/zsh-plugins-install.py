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
import re
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
ZSH_THEMES_DIR = os.path.join(ZSH_CUSTOM_DIR, "themes")

# 插件配置
ZSH_PLUGINS = [
    ("zsh-autosuggestions", "https://github.com/zsh-users/zsh-autosuggestions"),
    ("zsh-syntax-highlighting", "https://github.com/zsh-users/zsh-syntax-highlighting"),
    ("you-should-use", "https://github.com/MichaelAquilina/zsh-you-should-use"),
]

# 主题配置
ZSH_THEMES = [
    ("powerlevel10k", "https://github.com/romkatv/powerlevel10k.git"),
]

# 主题备用仓库配置（中国镜像）
ZSH_THEMES_BACKUP = [
    ("powerlevel10k", "https://gitee.com/romkatv/powerlevel10k.git"),
]

# 完整插件列表（用于.zshrc配置）
COMPLETE_PLUGINS = [
    "git", "extract", "systemadmin", "zsh-interactive-cd", "systemd",
    "sudo", "docker", "ubuntu", "man", "command-not-found",
    "common-aliases", "docker-compose", "zsh-autosuggestions",
    "zsh-syntax-highlighting", "tmux", "you-should-use"
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

def check_oh_my_zsh_conflicts() -> bool:
    """
    检查Oh My Zsh冲突并处理

    Returns:
        bool: 是否可以继续
    """
    if os.path.exists(OMZ_DIR):
        # 检查是否是完整安装
        required_files = [
            os.path.join(OMZ_DIR, "oh-my-zsh.sh"),
            os.path.join(OMZ_DIR, "lib"),
            os.path.join(OMZ_DIR, "plugins")
        ]

        missing_files = [f for f in required_files if not os.path.exists(f)]

        if missing_files:
            log_warn("Oh My Zsh安装不完整，缺少以下文件/目录:")
            for f in missing_files:
                log_warn(f"  - {f}")

            if ZSH_INSTALL_MODE == "auto":
                log_info("自动模式：重新安装Oh My Zsh")
                return reinstall_oh_my_zsh()
            else:
                if interactive_ask_confirmation("Oh My Zsh安装不完整，是否重新安装？", "true"):
                    return reinstall_oh_my_zsh()
                else:
                    log_error("无法在不完整的Oh My Zsh环境中安装插件")
                    return False
        else:
            log_info("Oh My Zsh安装完整，继续插件安装")
            return True
    else:
        log_error("Oh My Zsh未安装，请先运行ZSH核心安装脚本")
        return False

def reinstall_oh_my_zsh() -> bool:
    """
    重新安装Oh My Zsh

    Returns:
        bool: 重装是否成功
    """
    log_info("开始重新安装Oh My Zsh...")

    # 备份现有配置
    backup_dir = f"{OMZ_DIR}.backup.{get_timestamp()}"
    try:
        if os.path.exists(OMZ_DIR):
            shutil.move(OMZ_DIR, backup_dir)
            log_info(f"已备份现有Oh My Zsh到: {backup_dir}")
            add_rollback_action(f"mv '{backup_dir}' '{OMZ_DIR}'")
    except Exception as e:
        log_error(f"备份Oh My Zsh失败: {e}")
        return False

    # 重新安装Oh My Zsh
    log_info("下载并安装Oh My Zsh...")
    try:
        # 使用官方安装脚本
        install_cmd = [
            'sh', '-c',
            'RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
        ]

        result = subprocess.run(install_cmd, capture_output=True, text=True)

        if result.returncode == 0:
            log_info("Oh My Zsh重新安装成功")
            return True
        else:
            log_error(f"Oh My Zsh重新安装失败: {result.stderr}")
            # 恢复备份
            if os.path.exists(backup_dir):
                shutil.move(backup_dir, OMZ_DIR)
                log_info("已恢复原有配置")
            return False

    except Exception as e:
        log_error(f"Oh My Zsh重新安装异常: {e}")
        # 恢复备份
        if os.path.exists(backup_dir):
            shutil.move(backup_dir, OMZ_DIR)
            log_info("已恢复原有配置")
        return False

def check_zsh_plugins_requirements() -> bool:
    """
    检查ZSH插件安装要求

    Returns:
        bool: 要求是否满足
    """
    log_info("检查ZSH插件安装要求...")

    # 检查Oh My Zsh冲突
    if not check_oh_my_zsh_conflicts():
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

def check_plugin_conflicts(plugin_name: str) -> bool:
    """
    检查插件冲突并处理

    Args:
        plugin_name: 插件名称

    Returns:
        bool: 是否可以继续安装
    """
    plugin_dir = os.path.join(ZSH_PLUGINS_DIR, plugin_name)

    if os.path.exists(plugin_dir):
        if os.listdir(plugin_dir):  # 目录不为空
            log_warn(f"发现已存在的插件: {plugin_name}")

            # 在自动模式下直接重新安装
            if ZSH_INSTALL_MODE == "auto":
                log_info(f"自动模式：删除现有插件 {plugin_name} 并重新安装")
                try:
                    shutil.rmtree(plugin_dir)
                    log_info(f"已删除现有插件目录: {plugin_dir}")
                    return True
                except Exception as e:
                    log_error(f"删除现有插件失败: {e}")
                    return False
            else:
                # 交互模式询问用户
                if interactive_ask_confirmation(f"插件 {plugin_name} 已存在，是否重新安装？", "true"):
                    try:
                        shutil.rmtree(plugin_dir)
                        log_info(f"已删除现有插件目录: {plugin_dir}")
                        return True
                    except Exception as e:
                        log_error(f"删除现有插件失败: {e}")
                        return False
                else:
                    log_info(f"跳过插件 {plugin_name} 的安装")
                    return True  # 用户选择跳过，不算失败
        else:
            # 目录为空，删除后重新安装
            try:
                os.rmdir(plugin_dir)
                log_debug(f"删除空目录: {plugin_dir}")
            except Exception as e:
                log_warn(f"删除空目录失败: {e}")

    return True

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

    # 检查插件冲突
    if not check_plugin_conflicts(plugin_name):
        return False

    # 如果插件已存在且用户选择跳过，直接返回成功
    if os.path.exists(plugin_dir) and os.listdir(plugin_dir):
        log_info(f"插件 {plugin_name} 已存在，跳过安装")
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

def show_installation_progress(current: int, total: int, plugin_name: str, status: str) -> None:
    """
    显示安装进度

    Args:
        current: 当前进度
        total: 总数
        plugin_name: 插件名称
        status: 状态
    """
    percentage = int((current / total) * 100)
    progress_bar = "█" * (percentage // 5) + "░" * (20 - percentage // 5)

    status_colors = {
        "installing": CYAN,
        "success": GREEN,
        "failed": RED,
        "skipped": YELLOW
    }

    color = status_colors.get(status, RESET)

    print(f"\r{BLUE}[{current:2d}/{total}]{RESET} {color}[{progress_bar}]{RESET} {percentage:3d}% - {plugin_name} ({status})", end="", flush=True)

    if current == total or status in ["success", "failed", "skipped"]:
        print()  # 换行

def install_zsh_plugins() -> bool:
    """
    安装所有ZSH插件

    Returns:
        bool: 安装是否成功
    """
    log_info("开始安装ZSH插件...")
    set_install_state("INSTALLING_PLUGINS")

    failed_plugins = []
    success_count = 0
    total_plugins = len(ZSH_PLUGINS)

    # 确保插件目录存在
    os.makedirs(ZSH_PLUGINS_DIR, exist_ok=True)

    print(f"\n{BLUE}{'='*60}")
    print(f"📦 ZSH插件安装进度")
    print(f"{'='*60}{RESET}")
    print(f"总插件数: {total_plugins}")
    print(f"安装目录: {ZSH_PLUGINS_DIR}")
    print()

    # 安装每个插件
    for i, (plugin_name, plugin_repo) in enumerate(ZSH_PLUGINS, 1):
        show_installation_progress(i, total_plugins, plugin_name, "installing")

        try:
            if install_single_plugin(plugin_name, plugin_repo):
                success_count += 1
                show_installation_progress(i, total_plugins, plugin_name, "success")
            else:
                failed_plugins.append(plugin_name)
                show_installation_progress(i, total_plugins, plugin_name, "failed")
        except Exception as e:
            log_error(f"插件 {plugin_name} 安装异常: {e}")
            failed_plugins.append(plugin_name)
            show_installation_progress(i, total_plugins, plugin_name, "failed")

    # 显示安装结果
    print(f"\n{BLUE}{'='*60}")
    print(f"📊 安装结果统计")
    print(f"{'='*60}{RESET}")
    print(f"{GREEN}✅ 成功安装: {success_count} 个插件{RESET}")

    if failed_plugins:
        print(f"{RED}❌ 安装失败: {len(failed_plugins)} 个插件{RESET}")
        for plugin in failed_plugins:
            print(f"   - {plugin}")
        print()

        # 在交互模式下询问是否继续
        if ZSH_INSTALL_MODE == "interactive":
            if not interactive_ask_confirmation("部分插件安装失败，是否继续配置？", "true"):
                log_info("用户选择停止安装")
                return False

        log_warn("部分插件安装失败，但继续配置过程")
    else:
        print(f"{GREEN}🎉 所有插件安装成功！{RESET}")

    print()
    return True

# =============================================================================
# 主题安装功能
# =============================================================================

def install_single_theme(theme_name: str, theme_repo: str) -> bool:
    """
    安装单个ZSH主题

    Args:
        theme_name: 主题名称
        theme_repo: 主题仓库URL

    Returns:
        bool: 安装是否成功
    """
    theme_dir = os.path.join(ZSH_THEMES_DIR, theme_name)

    try:
        # 创建主题目录
        os.makedirs(ZSH_THEMES_DIR, exist_ok=True)

        # 如果主题已存在，先删除
        if os.path.exists(theme_dir):
            log_info(f"主题 {theme_name} 已存在，正在更新...")
            shutil.rmtree(theme_dir)

        # 尝试克隆主题仓库
        log_info(f"正在安装主题 {theme_name}...")

        # 首先尝试主仓库
        try:
            result = subprocess.run(
                ["git", "clone", "--depth=1", theme_repo, theme_dir],
                capture_output=True,
                text=True,
                check=True,
                timeout=30  # 30秒超时
            )

            if result.returncode == 0:
                log_success(f"主题 {theme_name} 安装成功")
                return True

        except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as e:
            log_warn(f"主仓库安装失败: {e}")

            # 尝试备用仓库（中国镜像）
            backup_repo = None
            for backup_theme_name, backup_theme_repo in ZSH_THEMES_BACKUP:
                if backup_theme_name == theme_name:
                    backup_repo = backup_theme_repo
                    break

            if backup_repo:
                log_info(f"尝试使用备用仓库安装 {theme_name}...")
                try:
                    # 清理可能的部分安装
                    if os.path.exists(theme_dir):
                        shutil.rmtree(theme_dir)

                    result = subprocess.run(
                        ["git", "clone", "--depth=1", backup_repo, theme_dir],
                        capture_output=True,
                        text=True,
                        check=True,
                        timeout=30
                    )

                    if result.returncode == 0:
                        log_success(f"主题 {theme_name} 从备用仓库安装成功")
                        return True

                except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as backup_e:
                    log_error(f"备用仓库安装也失败: {backup_e}")

            log_error(f"主题 {theme_name} 安装失败，已尝试所有可用仓库")
            return False

    except Exception as e:
        log_error(f"主题 {theme_name} 安装过程中发生错误: {e}")
        return False
    except Exception as e:
        log_error(f"主题 {theme_name} 安装过程中发生错误: {e}")
        return False

def install_zsh_themes() -> bool:
    """
    安装所有ZSH主题

    Returns:
        bool: 安装是否成功
    """
    if not ZSH_THEMES:
        log_info("没有配置需要安装的主题")
        return True

    log_info("开始安装ZSH主题...")
    print(f"{BLUE}{'='*60}")
    print(f"🎨 ZSH主题安装")
    print(f"{'='*60}{RESET}")

    success_count = 0
    failed_themes = []
    total_themes = len(ZSH_THEMES)

    for i, (theme_name, theme_repo) in enumerate(ZSH_THEMES, 1):
        try:
            show_installation_progress(i, total_themes, theme_name, "installing")

            if install_single_theme(theme_name, theme_repo):
                success_count += 1
                show_installation_progress(i, total_themes, theme_name, "success")
            else:
                failed_themes.append(theme_name)
                show_installation_progress(i, total_themes, theme_name, "failed")
        except Exception as e:
            log_error(f"主题 {theme_name} 安装异常: {e}")
            failed_themes.append(theme_name)
            show_installation_progress(i, total_themes, theme_name, "failed")

    # 显示安装结果
    print(f"\n{BLUE}{'='*60}")
    print(f"🎨 主题安装结果统计")
    print(f"{'='*60}{RESET}")
    print(f"{GREEN}✅ 成功安装: {success_count} 个主题{RESET}")

    if failed_themes:
        print(f"{RED}❌ 安装失败: {len(failed_themes)} 个主题{RESET}")
        for theme in failed_themes:
            print(f"   - {theme}")
        print()
        log_warn("部分主题安装失败，但继续配置过程")
    else:
        print(f"{GREEN}🎉 所有主题安装成功！{RESET}")

    print()
    return True

# =============================================================================
# 配置更新功能
# =============================================================================

def smart_plugin_config_management(zshrc_file: str) -> bool:
    """
    智能插件配置管理

    Args:
        zshrc_file: .zshrc文件路径

    Returns:
        bool: 配置是否成功
    """
    log_info("智能插件配置管理...")

    try:
        # 读取现有配置
        with open(zshrc_file, 'r', encoding='utf-8') as f:
            content = f.read()

        # 检查是否存在plugins=()配置行
        import re
        plugin_pattern = r'^plugins=\(([^)]*)\)'
        plugin_match = re.search(plugin_pattern, content, re.MULTILINE)

        if plugin_match:
            log_info("发现现有插件配置，进行智能合并...")

            # 提取现有插件列表
            current_plugins_str = plugin_match.group(1).strip()
            log_debug(f"当前插件配置: {current_plugins_str}")

            # 解析现有插件
            existing_plugins = []
            if current_plugins_str:
                # 处理多行和单行格式
                current_plugins_str = re.sub(r'\s+', ' ', current_plugins_str)
                existing_plugins = [p.strip() for p in current_plugins_str.split() if p.strip()]

            # 合并插件列表，避免重复
            merged_plugins = list(existing_plugins)  # 保持现有插件顺序

            # 添加新插件（如果不存在）
            for new_plugin in COMPLETE_PLUGINS:
                if new_plugin not in merged_plugins:
                    merged_plugins.append(new_plugin)
                    log_debug(f"添加新插件: {new_plugin}")

            # 生成新的插件配置行
            new_plugins_line = f"plugins=({' '.join(merged_plugins)})"
            log_debug(f"新插件配置: {new_plugins_line}")

            # 替换插件配置行
            content = re.sub(plugin_pattern, new_plugins_line, content, flags=re.MULTILINE)
            log_info(f"插件配置已更新，包含 {len(merged_plugins)} 个插件")

        else:
            log_info("未找到插件配置，创建新的插件配置...")

            # 生成完整插件配置
            plugins_config = f"plugins=({' '.join(COMPLETE_PLUGINS)})"

            # 在Oh My Zsh源之前添加插件配置
            if 'source $ZSH/oh-my-zsh.sh' in content:
                content = content.replace(
                    'source $ZSH/oh-my-zsh.sh',
                    f'{plugins_config}\n\nsource $ZSH/oh-my-zsh.sh'
                )
                log_info("已在source之前添加完整插件配置")
            elif 'source ~/.oh-my-zsh/oh-my-zsh.sh' in content:
                content = content.replace(
                    'source ~/.oh-my-zsh/oh-my-zsh.sh',
                    f'{plugins_config}\n\nsource ~/.oh-my-zsh/oh-my-zsh.sh'
                )
                log_info("已在source之前添加完整插件配置")
            else:
                # 如果没有找到source行，在文件开头添加
                content = f'{plugins_config}\n\n{content}'
                log_info("已在文件开头添加插件配置")

        # 写入更新后的配置
        with open(zshrc_file, 'w', encoding='utf-8') as f:
            f.write(content)

        return True

    except Exception as e:
        log_error(f"智能插件配置管理失败: {e}")
        return False

def copy_p10k_default_config() -> bool:
    """
    复制Powerlevel10k默认配置文件

    Returns:
        bool: 复制是否成功
    """
    log_info("复制Powerlevel10k默认配置文件...")

    try:
        # 定义源文件和目标文件路径
        home_dir = Path.home()
        source_config = home_dir / ".oh-my-zsh" / "custom" / "themes" / "powerlevel10k" / "config" / "p10k-rainbow.zsh"
        target_config = home_dir / ".p10k.zsh"

        # 检查源文件是否存在
        if not source_config.exists():
            log_warn(f"Powerlevel10k默认配置文件不存在: {source_config}")
            log_info("尝试查找其他可用的配置文件...")

            # 尝试其他可能的配置文件
            alternative_configs = [
                home_dir / ".oh-my-zsh" / "custom" / "themes" / "powerlevel10k" / "config" / "p10k-classic.zsh",
                home_dir / ".oh-my-zsh" / "custom" / "themes" / "powerlevel10k" / "config" / "p10k-lean.zsh",
                home_dir / ".oh-my-zsh" / "custom" / "themes" / "powerlevel10k" / "config" / "p10k-pure.zsh"
            ]

            for alt_config in alternative_configs:
                if alt_config.exists():
                    source_config = alt_config
                    log_info(f"找到替代配置文件: {alt_config.name}")
                    break
            else:
                log_warn("未找到任何Powerlevel10k配置文件，跳过配置文件复制")
                return False

        # 检查目标文件是否已存在
        if target_config.exists():
            log_warn(f"目标配置文件已存在: {target_config}")

            # 在交互式环境中询问用户
            if sys.stdin.isatty():
                response = interactive_ask_confirmation(
                    f"是否覆盖现有的 ~/.p10k.zsh 配置文件？",
                    False  # 默认为否
                )
                if not response:
                    log_info("跳过配置文件复制，保留现有配置")
                    return True
            else:
                log_info("非交互式环境，跳过配置文件复制，保留现有配置")
                return True

        # 复制配置文件
        log_info(f"复制配置文件: {source_config.name} -> ~/.p10k.zsh")
        shutil.copy2(source_config, target_config)

        # 设置正确的文件权限
        target_config.chmod(0o644)

        log_success("Powerlevel10k默认配置文件复制成功")
        return True

    except Exception as e:
        log_error(f"复制Powerlevel10k配置文件失败: {e}")
        return False

def copy_p10k_default_config() -> bool:
    """
    复制Powerlevel10k默认配置文件

    Returns:
        bool: 复制是否成功
    """
    log_info("复制Powerlevel10k默认配置文件...")

    try:
        # 定义源文件和目标文件路径
        home_dir = Path.home()
        source_config = home_dir / ".oh-my-zsh" / "custom" / "themes" / "powerlevel10k" / "config" / "p10k-rainbow.zsh"
        target_config = home_dir / ".p10k.zsh"

        # 检查源文件是否存在
        if not source_config.exists():
            log_warn(f"Powerlevel10k默认配置文件不存在: {source_config}")
            log_info("尝试查找其他可用的配置文件...")

            # 尝试其他可能的配置文件
            alternative_configs = [
                home_dir / ".oh-my-zsh" / "custom" / "themes" / "powerlevel10k" / "config" / "p10k-classic.zsh",
                home_dir / ".oh-my-zsh" / "custom" / "themes" / "powerlevel10k" / "config" / "p10k-lean.zsh",
                home_dir / ".oh-my-zsh" / "custom" / "themes" / "powerlevel10k" / "config" / "p10k-pure.zsh"
            ]

            for alt_config in alternative_configs:
                if alt_config.exists():
                    source_config = alt_config
                    log_info(f"找到替代配置文件: {alt_config.name}")
                    break
            else:
                log_warn("未找到任何Powerlevel10k配置文件，跳过配置文件复制")
                return False

        # 检查目标文件是否已存在
        if target_config.exists():
            log_warn(f"目标配置文件已存在: {target_config}")

            # 在交互式环境中询问用户
            if sys.stdin.isatty():
                response = interactive_ask_confirmation(
                    f"是否覆盖现有的 ~/.p10k.zsh 配置文件？",
                    False  # 默认为否
                )
                if not response:
                    log_info("跳过配置文件复制，保留现有配置")
                    return True
            else:
                log_info("非交互式环境，跳过配置文件复制，保留现有配置")
                return True

        # 复制配置文件
        log_info(f"复制配置文件: {source_config.name} -> ~/.p10k.zsh")
        shutil.copy2(source_config, target_config)

        # 设置正确的文件权限
        target_config.chmod(0o644)

        log_success("Powerlevel10k默认配置文件复制成功")
        return True

    except Exception as e:
        log_error(f"复制Powerlevel10k配置文件失败: {e}")
        return False

def ensure_p10k_config(zshrc_file: str) -> bool:
    """
    确保Powerlevel10k配置

    Args:
        zshrc_file: .zshrc文件路径

    Returns:
        bool: 配置是否成功
    """
    log_info("确保Powerlevel10k配置...")

    try:
        # 读取现有配置
        with open(zshrc_file, 'r', encoding='utf-8') as f:
            content = f.read()

        # 检查是否已有p10k.zsh源配置
        p10k_pattern = r'\[\[.*-f.*\.p10k\.zsh.*\]\].*source.*\.p10k\.zsh'
        if not re.search(p10k_pattern, content):
            log_info("添加Powerlevel10k配置源...")

            # 在文件末尾添加p10k配置
            p10k_config = """
# Powerlevel10k 配置
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh"""

            content += p10k_config
            log_info("已添加Powerlevel10k配置源")
        else:
            log_info("Powerlevel10k配置源已存在")

        # 检查并设置ZSH_THEME为powerlevel10k
        if 'ZSH_THEME=' in content:
            # 替换现有主题设置
            content = re.sub(
                r'ZSH_THEME="[^"]*"',
                'ZSH_THEME="powerlevel10k/powerlevel10k"',
                content
            )
            log_info("已设置ZSH_THEME为powerlevel10k")
        else:
            # 添加主题设置
            theme_config = 'ZSH_THEME="powerlevel10k/powerlevel10k"\n'
            # 在export ZSH之后添加
            if 'export ZSH=' in content:
                content = content.replace(
                    'export ZSH=',
                    f'{theme_config}\nexport ZSH='
                )
            else:
                content = theme_config + content
            log_info("已添加ZSH_THEME设置")

        # 复制默认配置文件（关键步骤）
        if not copy_p10k_default_config():
            log_warn("Powerlevel10k默认配置文件复制失败，但继续安装流程")

        # 写入更新后的配置
        with open(zshrc_file, 'w', encoding='utf-8') as f:
            f.write(content)

        return True

    except Exception as e:
        log_error(f"Powerlevel10k配置失败: {e}")
        return False

def update_zshrc_config() -> bool:
    """
    更新.zshrc配置文件

    Returns:
        bool: 更新是否成功
    """
    log_info("更新.zshrc配置...")
    set_install_state("UPDATING_ZSHRC")

    zshrc_path = os.path.expanduser("~/.zshrc")

    if not os.path.exists(zshrc_path):
        log_error(".zshrc文件不存在，请先运行ZSH核心安装脚本")
        return False

    try:
        # 备份原配置
        backup_file = f"{zshrc_path}.backup.{get_timestamp()}"
        shutil.copy2(zshrc_path, backup_file)
        log_info(f"已备份.zshrc到: {backup_file}")
        add_rollback_action(f"mv '{backup_file}' '{zshrc_path}'")

        # 应用智能插件配置管理
        if not smart_plugin_config_management(zshrc_path):
            return False

        # 确保Powerlevel10k配置
        if not ensure_p10k_config(zshrc_path):
            return False

        log_info(".zshrc配置文件更新完成")
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

def integrate_ssh_agent_management() -> bool:
    """
    集成SSH代理管理到ZSH配置

    Returns:
        bool: 集成是否成功
    """
    log_info("集成SSH代理管理...")

    try:
        # 导入SSH代理管理器
        ssh_agent_script = script_dir.parent / "security" / "ssh-agent-manager.py"

        if not ssh_agent_script.exists():
            log_warn("SSH代理管理器脚本不存在，跳过集成")
            return True

        # 调用SSH代理管理器的ZSH集成功能
        result = subprocess.run([
            sys.executable, str(ssh_agent_script)
        ], capture_output=True, text=True)

        if result.returncode == 0:
            log_info("SSH代理管理已成功集成到ZSH配置")
            return True
        else:
            log_warn(f"SSH代理管理集成失败: {result.stderr}")
            return False

    except Exception as e:
        log_error(f"SSH代理管理集成过程中发生错误: {e}")
        return False

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

    # 显示SSH代理管理状态
    ssh_agent_config = Path.home() / ".ssh-agent-ohmyzsh"
    print(f"• SSH代理管理: {'✅ 已集成' if ssh_agent_config.exists() else '❌ 未集成'}")

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

        # 安装ZSH主题
        if not install_zsh_themes():
            log_error("ZSH主题安装失败")
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

        # 集成SSH代理管理
        if not integrate_ssh_agent_management():
            log_warn("SSH代理管理集成失败，但不影响ZSH插件功能")

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
