#!/usr/bin/env python3

"""
Docker镜像推送脚本 - Python版本
作者: saul
版本: 1.1
描述: 搜索、拉取、标记并推送Docker镜像到私有仓库，支持Ubuntu 20-22 x64/ARM64
"""

import os
import sys
import subprocess
import json
import requests
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

    if interactive_ask_confirmation("是否安装Docker？", True):
        log_info("正在安装Docker...")
        try:
            # 使用国内镜像安装脚本
            install_cmd = "bash <(curl -sSL https://gitee.com/SuperManito/LinuxMirrors/raw/main/DockerInstallation.sh)"
            execute_command(install_cmd, "安装Docker")

            log_info("正在安装lazydocker...")
            lazydocker_cmd = "curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash"
            execute_command(lazydocker_cmd, "安装LazyDocker")

            return True
        except Exception as e:
            log_error(f"Docker安装失败: {e}")
            return False
    else:
        log_error("未安装Docker，脚本退出")
        return False

def search_docker_images(search_term, limit=10):
    """搜索Docker Hub镜像"""
    log_info(f"搜索Docker镜像: {search_term}")

    try:
        # 使用Docker Hub API搜索镜像
        url = f"https://hub.docker.com/v2/search/repositories/?query={search_term}&page_size={limit}"
        response = requests.get(url, timeout=10)
        response.raise_for_status()

        data = response.json()
        results = data.get('results', [])

        if not results:
            log_warn("未找到匹配的镜像")
            return []

        log_info(f"找到 {len(results)} 个镜像:")
        for i, repo in enumerate(results, 1):
            name = repo.get('name', 'N/A')
            description = repo.get('short_description', 'No description')[:60]
            stars = repo.get('star_count', 0)
            is_official = repo.get('is_official', False)
            official_tag = " [OFFICIAL]" if is_official else ""

            print(f"{i:2d}. {name}{official_tag}")
            print(f"    描述: {description}")
            print(f"    星标: {stars}")
            print()

        return results
    except requests.RequestException as e:
        log_error(f"搜索镜像失败: {e}")
        return []
    except Exception as e:
        log_error(f"搜索过程中发生错误: {e}")
        return []

def pull_docker_image(image_name, tag="latest"):
    """拉取Docker镜像"""
    full_image = f"{image_name}:{tag}"
    log_info(f"拉取镜像: {full_image}")

    try:
        cmd = f"docker pull {full_image}"
        result = subprocess.run(cmd, shell=True, check=True,
                              capture_output=True, text=True)
        log_info(f"镜像拉取成功: {full_image}")
        return True
    except subprocess.CalledProcessError as e:
        log_error(f"镜像拉取失败: {e}")
        if e.stderr:
            log_error(f"错误详情: {e.stderr}")
        return False

def tag_docker_image(source_image, target_registry, target_image, tag="latest"):
    """标记Docker镜像"""
    source_full = f"{source_image}:{tag}"
    target_full = f"{target_registry}/{target_image}:{tag}"

    log_info(f"标记镜像: {source_full} -> {target_full}")

    try:
        cmd = f"docker tag {source_full} {target_full}"
        result = subprocess.run(cmd, shell=True, check=True,
                              capture_output=True, text=True)
        log_info(f"镜像标记成功: {target_full}")
        return target_full
    except subprocess.CalledProcessError as e:
        log_error(f"镜像标记失败: {e}")
        if e.stderr:
            log_error(f"错误详情: {e.stderr}")
        return None

def push_docker_image(image_name):
    """推送Docker镜像"""
    log_info(f"推送镜像: {image_name}")

    try:
        cmd = f"docker push {image_name}"
        result = subprocess.run(cmd, shell=True, check=True,
                              capture_output=True, text=True)
        log_info(f"镜像推送成功: {image_name}")
        return True
    except subprocess.CalledProcessError as e:
        log_error(f"镜像推送失败: {e}")
        if e.stderr:
            log_error(f"错误详情: {e.stderr}")
        return False

def docker_login(registry, username, password):
    """登录Docker仓库"""
    log_info(f"登录Docker仓库: {registry}")

    try:
        cmd = f"echo '{password}' | docker login {registry} -u {username} --password-stdin"
        result = subprocess.run(cmd, shell=True, check=True,
                              capture_output=True, text=True)
        log_info("Docker仓库登录成功")
        return True
    except subprocess.CalledProcessError as e:
        log_error(f"Docker仓库登录失败: {e}")
        return False

def interactive_image_search():
    """交互式镜像搜索"""
    while True:
        search_term = input("\n请输入要搜索的镜像名称 (输入 'q' 退出): ").strip()
        if search_term.lower() == 'q':
            return None

        if not search_term:
            log_warn("请输入有效的搜索词")
            continue

        results = search_docker_images(search_term)
        if not results:
            continue

        try:
            choice = input("请选择镜像编号 (1-{}, 输入 's' 重新搜索): ".format(len(results))).strip()
            if choice.lower() == 's':
                continue

            choice_num = int(choice)
            if 1 <= choice_num <= len(results):
                selected_image = results[choice_num - 1]['name']
                log_info(f"已选择镜像: {selected_image}")
                return selected_image
            else:
                log_warn("请输入有效的编号")
        except ValueError:
            log_warn("请输入有效的数字")

def interactive_push_workflow():
    """交互式推送工作流"""
    show_header("Docker镜像推送工具", "1.1", "搜索、拉取、标记并推送Docker镜像到私有仓库")

    # 检查Docker是否安装
    if not check_docker_installed():
        if not install_docker():
            log_error("Docker安装失败，无法继续")
            return False

    # 搜索并选择镜像
    selected_image = interactive_image_search()
    if not selected_image:
        log_info("用户取消操作")
        return False

    # 输入镜像标签
    tag = input(f"请输入镜像标签 (默认: latest): ").strip() or "latest"

    # 拉取镜像
    if not pull_docker_image(selected_image, tag):
        log_error("镜像拉取失败")
        return False

    # 输入目标仓库信息
    print("\n请输入目标仓库信息:")
    target_registry = input("目标仓库地址 (例: harbor.example.com): ").strip()
    if not target_registry:
        log_error("目标仓库地址不能为空")
        return False

    target_image = input(f"目标镜像名称 (默认: {selected_image}): ").strip() or selected_image
    target_tag = input(f"目标镜像标签 (默认: {tag}): ").strip() or tag

    # 登录仓库
    username = input("用户名: ").strip()
    if not username:
        log_error("用户名不能为空")
        return False

    password = input("密码: ").strip()
    if not password:
        log_error("密码不能为空")
        return False

    if not docker_login(target_registry, username, password):
        log_error("仓库登录失败")
        return False

    # 标记镜像
    tagged_image = tag_docker_image(selected_image, target_registry, target_image, target_tag)
    if not tagged_image:
        log_error("镜像标记失败")
        return False

    # 推送镜像
    if not push_docker_image(tagged_image):
        log_error("镜像推送失败")
        return False

    log_info("镜像推送完成！")
    return True

def main():
    """主函数"""
    try:
        interactive_push_workflow()
    except KeyboardInterrupt:
        log_info("\n用户中断操作")
    except Exception as e:
        log_error(f"程序执行过程中发生错误: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()

# 导出主要函数供测试使用
__all__ = [
    'search_docker_images',
    'pull_docker_image',
    'tag_docker_image',
    'push_docker_image',
    'docker_login',
    'interactive_image_search',
    'interactive_push_workflow',
    'main'
]
