#!/usr/bin/env python3

"""
Python虚拟环境设置脚本
作者: saul
版本: 1.0
描述: 自动创建和配置Python虚拟环境，安装项目依赖
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
        print(f"{CYAN}[信息]{RESET} {message}")

    def log_success(message):
        """成功日志"""
        print(f"{GREEN}[成功]{RESET} {message}")

    def log_warn(message):
        """警告日志"""
        print(f"{YELLOW}[警告]{RESET} {message}")

    def log_error(message):
        """错误日志"""
        print(f"{RED}[错误]{RESET} {message}")

    def show_header(title, version, description):
        """显示脚本头部信息"""
        print(f"{BLUE}{'='*60}")
        print(f" {title}")
        print(f"版本: {version}")
        print(f"作者: saul")
        print(f"邮箱: sau1amaranth@gmail.com")
        print(f"描述: {description}")
        print(f"{'='*60}{RESET}")
        print()

def check_python_version():
    """检查Python版本"""
    log_info("检查Python版本...")

    if sys.version_info < (3, 8):
        log_error(f"需要Python 3.8或更高版本，当前版本: {sys.version}")
        return False

    log_success(f"Python版本检查通过: {sys.version}")
    return True

def check_and_install_venv_module():
    """检查并安装venv模块"""
    log_info("检查venv模块...")

    try:
        import venv
        log_success("venv模块可用")
        return True
    except ImportError:
        log_warn("venv模块不可用，尝试自动安装...")

        # 检测系统类型
        try:
            with open('/etc/os-release', 'r') as f:
                os_info = f.read().lower()

            if 'ubuntu' in os_info or 'debian' in os_info:
                return install_python3_venv_ubuntu()
            else:
                log_error("不支持的系统类型，请手动安装python3-venv")
                return False
        except FileNotFoundError:
            log_error("无法检测系统类型，请手动安装python3-venv")
            return False

def install_python3_venv_ubuntu():
    """在Ubuntu/Debian系统上安装python3-venv"""
    log_info("检测到Ubuntu/Debian系统，尝试安装python3-venv...")

    # 获取Python版本号
    python_version = f"{sys.version_info.major}.{sys.version_info.minor}"
    package_name = f"python{python_version}-venv"

    try:
        # 更新包列表
        log_info("更新包列表...")
        subprocess.run(['sudo', 'apt', 'update'], check=True, capture_output=True)

        # 安装python3-venv包
        log_info(f"安装{package_name}...")
        subprocess.run(['sudo', 'apt', 'install', '-y', package_name], check=True)

        log_success(f"{package_name}安装成功")

        # 再次检查venv模块
        try:
            import venv
            log_success("venv模块现在可用")
            return True
        except ImportError:
            log_error("安装后venv模块仍不可用")
            return False

    except subprocess.CalledProcessError as e:
        log_error(f"安装{package_name}失败: {e}")
        log_info("请手动运行以下命令:")
        log_info(f"sudo apt update && sudo apt install -y {package_name}")
        return False
    except FileNotFoundError:
        log_error("未找到apt命令，请确认系统类型或手动安装python3-venv")
        return False

def create_virtual_environment():
    """创建虚拟环境"""
    venv_path = Path("venv")

    if venv_path.exists():
        log_warn("虚拟环境已存在")
        response = input("是否重新创建虚拟环境？(y/N): ").strip().lower()
        if response in ['y', 'yes']:
            log_info("删除现有虚拟环境...")
            shutil.rmtree(venv_path)
        else:
            log_info("使用现有虚拟环境")
            return True

    log_info("创建Python虚拟环境...")
    try:
        subprocess.run([sys.executable, '-m', 'venv', 'venv'], check=True)
        log_success("虚拟环境创建成功")
        return True
    except subprocess.CalledProcessError as e:
        log_error(f"虚拟环境创建失败: {e}")

        # 如果失败，尝试安装python3-venv包
        log_warn("尝试安装缺失的python3-venv包...")
        if install_python3_venv_ubuntu():
            log_info("重新尝试创建虚拟环境...")
            try:
                subprocess.run([sys.executable, '-m', 'venv', 'venv'], check=True)
                log_success("虚拟环境创建成功")
                return True
            except subprocess.CalledProcessError as e2:
                log_error(f"重试后仍然失败: {e2}")
                return False
        else:
            return False

def get_venv_python():
    """获取虚拟环境中的Python路径"""
    if os.name == 'nt':  # Windows
        return Path("venv/Scripts/python.exe")
    else:  # Linux/macOS
        return Path("venv/bin/python")

def get_venv_pip():
    """获取虚拟环境中的pip路径"""
    if os.name == 'nt':  # Windows
        return Path("venv/Scripts/pip.exe")
    else:  # Linux/macOS
        return Path("venv/bin/pip")

def upgrade_pip():
    """升级pip"""
    log_info("升级pip...")

    pip_path = get_venv_pip()
    try:
        subprocess.run([str(pip_path), 'install', '--upgrade', 'pip'], check=True)
        log_success("pip升级成功")
        return True
    except subprocess.CalledProcessError as e:
        log_error(f"pip升级失败: {e}")
        return False

def install_requirements():
    """安装项目依赖"""
    requirements_file = Path("requirements.txt")

    if not requirements_file.exists():
        log_error("requirements.txt文件不存在")
        return False

    log_info("安装项目依赖...")

    pip_path = get_venv_pip()
    try:
        subprocess.run([str(pip_path), 'install', '-r', 'requirements.txt'], check=True)
        log_success("项目依赖安装成功")
        return True
    except subprocess.CalledProcessError as e:
        log_error(f"依赖安装失败: {e}")
        return False

def verify_installation():
    """验证安装"""
    log_info("验证虚拟环境安装...")

    python_path = get_venv_python()
    pip_path = get_venv_pip()

    # 检查Python
    try:
        result = subprocess.run([str(python_path), '--version'],
                              capture_output=True, text=True, check=True)
        log_success(f"虚拟环境Python: {result.stdout.strip()}")
    except subprocess.CalledProcessError:
        log_error("虚拟环境Python验证失败")
        return False

    # 检查已安装的包
    try:
        result = subprocess.run([str(pip_path), 'list'],
                              capture_output=True, text=True, check=True)
        log_info("已安装的包:")
        for line in result.stdout.strip().split('\n')[2:]:  # 跳过标题行
            if line.strip():
                print(f"  {line}")
    except subprocess.CalledProcessError:
        log_warn("无法获取已安装包列表")

    return True

def show_usage_instructions():
    """显示使用说明"""
    print(f"\n{BLUE}{'='*60}")
    print("虚拟环境设置完成！")
    print("="*60)
    print(f"{CYAN}使用说明：{RESET}")
    print()
    print("1. 激活虚拟环境：")
    if os.name == 'nt':
        print(f"   {GREEN}venv\\Scripts\\activate{RESET}")
    else:
        print(f"   {GREEN}source venv/bin/activate{RESET}")
    print()
    print("2. 运行项目：")
    print(f"   {GREEN}python install.py{RESET}")
    print(f"   {GREEN}python bootstrap.py{RESET}")
    print()
    print("3. 运行测试：")
    print(f"   {GREEN}python run_tests.py{RESET}")
    print()
    print("4. 退出虚拟环境：")
    print(f"   {GREEN}deactivate{RESET}")
    print()
    print(f"{YELLOW}注意：每次使用项目前都需要先激活虚拟环境{RESET}")
    print(f"{BLUE}{'='*60}{RESET}")

def main():
    """主函数"""
    # 显示脚本头部信息
    show_header(
        "Python虚拟环境设置脚本",
        "1.0",
        "自动创建和配置Python虚拟环境，安装项目依赖"
    )

    print(f"{CYAN}此脚本将为scripts-for-linux项目创建Python虚拟环境{RESET}")
    print(f"{BLUE}{'─'*60}{RESET}")
    print()

    # 检查Python版本
    if not check_python_version():
        sys.exit(1)

    # 检查并安装venv模块
    if not check_and_install_venv_module():
        sys.exit(1)

    # 创建虚拟环境
    if not create_virtual_environment():
        sys.exit(1)

    # 升级pip
    if not upgrade_pip():
        log_warn("pip升级失败，继续安装依赖...")

    # 安装依赖
    if not install_requirements():
        sys.exit(1)

    # 验证安装
    if not verify_installation():
        sys.exit(1)

    # 显示使用说明
    show_usage_instructions()

    log_success("虚拟环境设置完成！")

if __name__ == "__main__":
    main()
