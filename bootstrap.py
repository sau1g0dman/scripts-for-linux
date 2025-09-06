#!/usr/bin/env python3

"""
Ubuntu/Debian服务器安装脚本 - 简化引导程序 Python版本
作者: saul
版本: 2.0
描述: 简化的三步安装流程：克隆仓库 -> 进入目录 -> 执行安装脚本
"""

import os
import sys
import subprocess
import shutil
from pathlib import Path

# 添加scripts目录到Python路径
script_dir = Path(__file__).parent
sys.path.insert(0, str(script_dir / "scripts"))

try:
    from common import *
except ImportError:
    # 如果无法导入common模块，使用基本的颜色定义
    RED = '\033[31m'
    GREEN = '\033[32m'
    YELLOW = '\033[33m'
    BLUE = '\033[34m'
    CYAN = '\033[36m'
    RESET = '\033[m'

    def log_info(message):
        """信息日志"""
        print(f"{CYAN}[步骤]{RESET} {message}")

    def log_error(message):
        """错误日志"""
        print(f"{RED}[错误]{RESET} {message}")

    def log_success(message):
        """成功日志"""
        print(f"{GREEN}[成功]{RESET} {message}")

    def log_warn(message):
        """警告日志"""
        print(f"{YELLOW}[警告]{RESET} {message}")

    def show_header(title, version, description):
        """显示脚本头部信息"""
        print(f"{BLUE}{'='*70}")
        print(f" {title}")
        print(f"版本: {version}")
        print(f"作者: saul")
        print(f"邮箱: sau1amaranth@gmail.com")
        print(f"描述: {description}")
        print(f"{'='*70}{RESET}")
        print()

# =============================================================================
# 配置变量
# =============================================================================
REPO_URL = "https://github.com/sau1g0dman/scripts-for-linux.git"
REPO_DIR = "scripts-for-linux"

# =============================================================================
# 主要功能函数
# =============================================================================

def check_dependencies():
    """检查依赖工具"""
    log_info("检查依赖工具...")

    required_tools = ['git', 'python3']
    missing_tools = []

    for tool in required_tools:
        try:
            subprocess.run([tool, '--version'],
                          capture_output=True, check=True)
        except (subprocess.CalledProcessError, FileNotFoundError):
            missing_tools.append(tool)

    if missing_tools:
        log_error(f"缺少必要工具: {', '.join(missing_tools)}")
        log_info("正在安装缺少的工具...")

        try:
            # 更新包列表
            subprocess.run(['apt', 'update'], check=True, capture_output=True)

            # 安装缺少的工具
            for tool in missing_tools:
                if tool == 'python3':
                    subprocess.run(['apt', 'install', '-y', 'python3', 'python3-pip'],
                                 check=True, capture_output=True)
                else:
                    subprocess.run(['apt', 'install', '-y', tool],
                                 check=True, capture_output=True)

            log_success("依赖工具安装完成")
        except subprocess.CalledProcessError as e:
            log_error(f"依赖工具安装失败: {e}")
            return False
    else:
        log_success("依赖工具检查完成")

    return True

def clone_repository():
    """步骤1：克隆仓库"""
    log_info("正在克隆仓库...")

    # 如果目录已存在，先删除
    if Path(REPO_DIR).exists():
        log_warn(f"目录 {REPO_DIR} 已存在，正在删除...")
        try:
            shutil.rmtree(REPO_DIR)
            log_success("旧目录删除成功")
        except Exception as e:
            log_error(f"删除旧目录失败: {e}")
            return False

    # 克隆仓库
    try:
        result = subprocess.run(['git', 'clone', REPO_URL, REPO_DIR],
                              capture_output=True, text=True, check=True)
        log_success(f"仓库克隆成功: {REPO_DIR}")
        return True
    except subprocess.CalledProcessError as e:
        log_error(f"仓库克隆失败: {e}")
        if e.stderr:
            log_error(f"错误详情: {e.stderr}")
        return False

def enter_directory():
    """步骤2：进入目录"""
    log_info(f"进入目录: {REPO_DIR}")

    repo_path = Path(REPO_DIR)
    if not repo_path.exists():
        log_error(f"目录不存在: {REPO_DIR}")
        return False

    if not repo_path.is_dir():
        log_error(f"路径不是目录: {REPO_DIR}")
        return False

    try:
        os.chdir(REPO_DIR)
        log_success(f"已进入目录: {os.getcwd()}")
        return True
    except Exception as e:
        log_error(f"进入目录失败: {e}")
        return False

def execute_install_script():
    """步骤3：执行安装脚本"""
    log_info("执行安装脚本...")

    # 检查安装脚本是否存在
    install_scripts = ['install.py', 'install.sh']
    install_script = None

    for script in install_scripts:
        if Path(script).exists():
            install_script = script
            break

    if not install_script:
        log_error("未找到安装脚本")
        log_error("请确保仓库中包含 install.py 或 install.sh")
        return False

    log_info(f"找到安装脚本: {install_script}")

    try:
        if install_script.endswith('.py'):
            # 执行Python脚本
            result = subprocess.run(['python3', install_script], check=True)
        else:
            # 执行Shell脚本
            result = subprocess.run(['bash', install_script], check=True)

        log_success("安装脚本执行完成")
        return True
    except subprocess.CalledProcessError as e:
        log_error(f"安装脚本执行失败: {e}")
        return False
    except KeyboardInterrupt:
        log_warn("用户中断安装")
        return False

def show_bootstrap_header():
    """显示引导程序头部信息"""
    show_header(
        "Ubuntu/Debian服务器安装脚本 - 引导程序",
        "2.0",
        "简化的三步安装流程：克隆仓库 -> 进入目录 -> 执行安装脚本"
    )

    print(f"{CYAN}此脚本将自动完成以下步骤：{RESET}")
    print(f"{BLUE}{'─'*70}{RESET}")
    print(f"  {CYAN}1.{RESET} 克隆项目仓库")
    print(f"  {CYAN}2.{RESET} 进入项目目录")
    print(f"  {CYAN}3.{RESET} 执行安装脚本")
    print(f"{BLUE}{'─'*70}{RESET}")
    print()

def show_completion_info():
    """显示完成信息"""
    print(f"\n{GREEN}{'='*70}")
    print(f" 🎉 引导程序执行完成！")
    print(f"{'='*70}{RESET}")
    print()
    print(f"{CYAN}如果需要重新运行安装脚本，请执行：{RESET}")
    print(f"{BLUE}{'─'*70}{RESET}")
    print(f"  {YELLOW}cd {REPO_DIR}{RESET}")
    print(f"  {YELLOW}python3 install.py{RESET}  # 或 {YELLOW}bash install.sh{RESET}")
    print(f"{BLUE}{'─'*70}{RESET}")
    print(f"{GREEN}感谢使用scripts-for-linux项目！{RESET}")
    print()

def main():
    """主函数"""
    try:
        # 显示头部信息
        show_bootstrap_header()

        # 检查依赖
        if not check_dependencies():
            log_error("依赖检查失败")
            sys.exit(1)

        # 步骤1：克隆仓库
        if not clone_repository():
            log_error("仓库克隆失败")
            sys.exit(1)

        # 步骤2：进入目录
        if not enter_directory():
            log_error("进入目录失败")
            sys.exit(1)

        # 步骤3：执行安装脚本
        if not execute_install_script():
            log_error("安装脚本执行失败")
            sys.exit(1)

        # 显示完成信息
        show_completion_info()

    except KeyboardInterrupt:
        log_warn("\n用户中断引导程序")
        sys.exit(1)
    except Exception as e:
        log_error(f"引导程序执行过程中发生错误: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
