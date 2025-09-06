#!/usr/bin/env python3

"""
Docker安装配置脚本 - Python版本
作者: saul
版本: 1.0
描述: 自动安装Docker和相关工具，支持Ubuntu 20-24和Debian 10-12 x64/ARM64
"""

import os
import sys
import subprocess
import json
import tempfile
from pathlib import Path

# 添加scripts目录到Python路径
script_dir = Path(__file__).parent
sys.path.insert(0, str(script_dir.parent))

try:
    from common import *
except ImportError:
    print("错误：无法导入common模块")
    print("请确保common.py文件存在于scripts目录中")
    sys.exit(1)

# =============================================================================
# 配置变量
# =============================================================================

DOCKER_INSTALL_URL = "https://get.docker.com"
DOCKER_COMPOSE_VERSION = "v2.24.0"
LAZYDOCKER_VERSION = "v0.21.1"

# =============================================================================
# Docker检查和安装函数
# =============================================================================

def check_docker_installed():
    """检查Docker是否已安装"""
    try:
        result = subprocess.run(['docker', '--version'],
                              capture_output=True, text=True, check=True)
        log_info(f"Docker已安装: {result.stdout.strip()}")
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        log_info("Docker未安装")
        return False

def install_docker():
    """安装Docker"""
    log_info("开始安装Docker...")

    # 检查网络连接
    if not check_network():
        log_error("网络连接失败，无法下载Docker安装脚本")
        return False

    # 下载并执行Docker安装脚本
    log_info("下载Docker安装脚本...")
    try:
        # 使用curl下载并通过bash执行
        cmd = f"curl -fsSL {DOCKER_INSTALL_URL} | bash"
        result = subprocess.run(cmd, shell=True, check=True,
                              capture_output=True, text=True)
        log_info("Docker安装完成")
    except subprocess.CalledProcessError as e:
        log_error(f"Docker安装失败: {e}")
        if e.stderr:
            log_error(f"错误详情: {e.stderr}")
        return False

    # 启动Docker服务
    log_info("启动Docker服务...")
    try:
        execute_command("systemctl enable docker", "启用Docker服务")
        execute_command("systemctl start docker", "启动Docker服务")
    except Exception as e:
        log_error(f"启动Docker服务失败: {e}")
        return False

    # 将当前用户添加到docker组
    if os.getuid() != 0:
        log_info("将当前用户添加到docker组...")
        try:
            username = os.getenv('USER')
            execute_command(f"usermod -aG docker {username}", "添加用户到docker组")
            log_info("请重新登录以使docker组权限生效")
        except Exception as e:
            log_error(f"添加用户到docker组失败: {e}")
            return False

    return True

def install_docker_compose():
    """安装Docker Compose"""
    log_info("开始安装Docker Compose...")

    # 检查是否已安装
    try:
        result = subprocess.run(['docker-compose', '--version'],
                              capture_output=True, text=True, check=True)
        log_info(f"Docker Compose已安装: {result.stdout.strip()}")
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        pass

    # 检测系统架构
    arch = detect_arch()
    if arch == "x64":
        arch = "x86_64"
    elif arch == "arm64":
        arch = "aarch64"
    else:
        log_error(f"不支持的架构: {arch}")
        return False

    # 下载Docker Compose
    compose_url = f"https://github.com/docker/compose/releases/download/{DOCKER_COMPOSE_VERSION}/docker-compose-linux-{arch}"
    compose_path = "/usr/local/bin/docker-compose"

    try:
        log_info(f"下载Docker Compose {DOCKER_COMPOSE_VERSION}...")
        execute_command(f"curl -L {compose_url} -o {compose_path}", "下载Docker Compose")
        execute_command(f"chmod +x {compose_path}", "设置执行权限")

        # 验证安装
        result = subprocess.run(['docker-compose', '--version'],
                              capture_output=True, text=True, check=True)
        log_info(f"Docker Compose安装成功: {result.stdout.strip()}")
        return True
    except Exception as e:
        log_error(f"Docker Compose安装失败: {e}")
        return False

def install_lazydocker():
    """安装LazyDocker"""
    log_info("开始安装LazyDocker...")

    # 检查是否已安装
    try:
        result = subprocess.run(['lazydocker', '--version'],
                              capture_output=True, text=True, check=True)
        log_info(f"LazyDocker已安装: {result.stdout.strip()}")
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        pass

    try:
        # 使用官方安装脚本
        install_cmd = "curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash"
        execute_command(install_cmd, "安装LazyDocker")

        # 验证安装
        result = subprocess.run(['lazydocker', '--version'],
                              capture_output=True, text=True, check=True)
        log_info(f"LazyDocker安装成功: {result.stdout.strip()}")
        return True
    except Exception as e:
        log_error(f"LazyDocker安装失败: {e}")
        return False

def configure_docker_mirrors():
    """配置Docker镜像加速器"""
    log_info("配置Docker镜像加速器...")

    daemon_json_path = "/etc/docker/daemon.json"

    # 备份原配置文件
    if os.path.exists(daemon_json_path):
        backup_path = f"{daemon_json_path}.backup.{get_timestamp()}"
        try:
            execute_command(f"cp {daemon_json_path} {backup_path}", "备份原配置文件")
        except Exception as e:
            log_warn(f"备份配置文件失败: {e}")

    # 创建新的daemon.json配置
    daemon_config = {
        "registry-mirrors": [
            "https://docker.mirrors.ustc.edu.cn",
            "https://hub-mirror.c.163.com",
            "https://mirror.baidubce.com",
            "https://ccr.ccs.tencentyun.com"
        ],
        "log-driver": "json-file",
        "log-opts": {
            "max-size": "100m",
            "max-file": "3"
        },
        "storage-driver": "overlay2"
    }

    try:
        # 确保目录存在
        os.makedirs("/etc/docker", exist_ok=True)

        # 写入配置文件
        with open(daemon_json_path, 'w') as f:
            json.dump(daemon_config, f, indent=2)

        log_info("Docker镜像加速器配置文件已创建")

        # 重启Docker服务
        log_info("重启Docker服务以应用配置...")
        execute_command("systemctl daemon-reload", "重新加载systemd配置")
        execute_command("systemctl restart docker", "重启Docker服务")

        log_info("Docker镜像加速器配置完成")
        return True
    except Exception as e:
        log_error(f"配置Docker镜像加速器失败: {e}")
        return False

def verify_docker_installation():
    """验证Docker安装"""
    log_info("验证Docker安装...")

    try:
        # 检查Docker版本
        result = subprocess.run(['docker', '--version'],
                              capture_output=True, text=True, check=True)
        log_info(f"Docker版本: {result.stdout.strip()}")

        # 检查Docker服务状态
        result = subprocess.run(['systemctl', 'is-active', 'docker'],
                              capture_output=True, text=True, check=True)
        if result.stdout.strip() == "active":
            log_info("Docker服务运行正常")
        else:
            log_warn("Docker服务状态异常")
            return False

        # 运行测试容器
        log_info("运行测试容器...")
        test_cmd = "docker run --rm hello-world"
        result = subprocess.run(test_cmd, shell=True,
                              capture_output=True, text=True, check=True)

        if "Hello from Docker!" in result.stdout:
            log_info("Docker测试容器运行成功")
            return True
        else:
            log_warn("Docker测试容器运行异常")
            return False

    except subprocess.CalledProcessError as e:
        log_error(f"Docker验证失败: {e}")
        if e.stderr:
            log_error(f"错误详情: {e.stderr}")
        return False
    except Exception as e:
        log_error(f"Docker验证过程中发生错误: {e}")
        return False

def main():
    """主函数"""
    # 初始化环境
    init_environment()

    # 显示脚本信息
    show_header("Docker安装配置脚本", "1.0", "自动安装Docker和相关工具")

    # 检查网络连接
    if not check_network():
        log_error("网络连接失败，无法下载Docker组件")
        sys.exit(1)

    # 检查并安装Docker
    if not check_docker_installed():
        if not install_docker():
            log_error("Docker安装失败")
            sys.exit(1)

    # 配置Docker镜像加速器
    if interactive_ask_confirmation("是否配置Docker镜像加速器？", True):
        configure_docker_mirrors()

    # 安装Docker Compose
    if interactive_ask_confirmation("是否安装Docker Compose？", True):
        install_docker_compose()

    # 安装LazyDocker
    if interactive_ask_confirmation("是否安装LazyDocker（Docker管理工具）？", True):
        install_lazydocker()

    # 验证安装
    if not verify_docker_installation():
        log_error("Docker安装验证失败")
        sys.exit(1)

    log_info("Docker安装配置完成！")
    log_info("提示：如果您不是root用户，请重新登录以使docker组权限生效")

if __name__ == "__main__":
    main()

# 导出主要函数供测试使用
__all__ = [
    'check_docker_installed',
    'install_docker',
    'install_docker_compose',
    'install_lazydocker',
    'configure_docker_mirrors',
    'verify_docker_installation',
    'main'
]
