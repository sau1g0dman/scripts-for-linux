#!/usr/bin/env python3

"""
Docker安装脚本测试
"""

import unittest
import sys
import os
from pathlib import Path
from unittest.mock import Mock, patch, mock_open

# 添加项目路径
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))
sys.path.insert(0, str(project_root / "scripts"))

from tests.test_common import BaseTestCase, MockSubprocess

class TestDockerInstall(BaseTestCase):
    """测试Docker安装脚本"""

    def setUp(self):
        super().setUp()
        try:
            # 导入Docker安装模块
            sys.path.insert(0, str(project_root / "scripts" / "containers"))
            import importlib.util

            # 动态导入docker_install模块
            spec = importlib.util.spec_from_file_location(
                "docker_install",
                project_root / "scripts" / "containers" / "docker-install.py"
            )
            docker_install = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(docker_install)
            self.docker_install = docker_install
        except Exception as e:
            self.skipTest(f"docker_install模块未找到: {e}")

    def test_check_docker_installed_true(self):
        """测试Docker已安装的情况"""
        mock_subprocess = MockSubprocess()
        mock_subprocess.set_return_code('docker --version', 0)
        mock_subprocess.set_output('docker --version', 'Docker version 24.0.0', '')

        with patch('subprocess.run', mock_subprocess.run):
            result = self.docker_install.check_docker_installed()
            self.assertTrue(result)

    def test_check_docker_installed_false(self):
        """测试Docker未安装的情况"""
        mock_subprocess = MockSubprocess()
        mock_subprocess.set_return_code('docker --version', 1)

        with patch('subprocess.run', side_effect=FileNotFoundError()):
            result = self.docker_install.check_docker_installed()
            self.assertFalse(result)

    def test_install_docker_success(self):
        """测试Docker安装成功"""
        mock_subprocess = MockSubprocess()

        # Mock网络检查成功
        with patch('common.check_network', return_value=True), \
             patch('common.execute_command', return_value=True), \
             patch('subprocess.run', mock_subprocess.run), \
             patch('os.getuid', return_value=1000):  # 非root用户

            result = self.docker_install.install_docker()
            self.assertTrue(result)

    def test_install_docker_network_fail(self):
        """测试网络连接失败的情况"""
        with patch('common.check_network', return_value=False):
            result = self.docker_install.install_docker()
            self.assertFalse(result)

    def test_install_docker_compose_success(self):
        """测试Docker Compose安装成功"""
        mock_subprocess = MockSubprocess()
        mock_subprocess.set_return_code('docker-compose --version', 1)  # 未安装

        with patch('common.detect_arch', return_value='x64'), \
             patch('common.execute_command', return_value=True), \
             patch('subprocess.run', mock_subprocess.run):

            result = self.docker_install.install_docker_compose()
            self.assertTrue(result)

    def test_install_docker_compose_already_installed(self):
        """测试Docker Compose已安装"""
        mock_subprocess = MockSubprocess()
        mock_subprocess.set_return_code('docker-compose --version', 0)
        mock_subprocess.set_output('docker-compose --version', 'docker-compose version 2.24.0', '')

        with patch('subprocess.run', mock_subprocess.run):
            result = self.docker_install.install_docker_compose()
            self.assertTrue(result)

    def test_install_lazydocker_success(self):
        """测试LazyDocker安装成功"""
        mock_subprocess = MockSubprocess()
        mock_subprocess.set_return_code('lazydocker --version', 1)  # 未安装

        with patch('common.execute_command', return_value=True), \
             patch('subprocess.run', mock_subprocess.run):

            result = self.docker_install.install_lazydocker()
            self.assertTrue(result)

    def test_configure_docker_mirrors_success(self):
        """测试Docker镜像加速器配置成功"""
        with patch('os.path.exists', return_value=False), \
             patch('os.makedirs'), \
             patch('builtins.open', mock_open()), \
             patch('common.execute_command', return_value=True), \
             patch('common.get_timestamp', return_value='20240101_120000'):

            result = self.docker_install.configure_docker_mirrors()
            self.assertTrue(result)

    def test_configure_docker_mirrors_with_backup(self):
        """测试有备份文件的Docker镜像加速器配置"""
        with patch('os.path.exists', return_value=True), \
             patch('os.makedirs'), \
             patch('builtins.open', mock_open()), \
             patch('common.execute_command', return_value=True), \
             patch('common.get_timestamp', return_value='20240101_120000'):

            result = self.docker_install.configure_docker_mirrors()
            self.assertTrue(result)

    def test_verify_docker_installation_success(self):
        """测试Docker安装验证成功"""
        mock_subprocess = MockSubprocess()
        mock_subprocess.set_return_code('docker --version', 0)
        mock_subprocess.set_output('docker --version', 'Docker version 24.0.0', '')
        mock_subprocess.set_return_code('systemctl is-active docker', 0)
        mock_subprocess.set_output('systemctl is-active docker', 'active', '')
        mock_subprocess.set_return_code('docker run --rm hello-world', 0)
        mock_subprocess.set_output('docker run --rm hello-world', 'Hello from Docker!', '')

        with patch('subprocess.run', mock_subprocess.run):
            result = self.docker_install.verify_docker_installation()
            self.assertTrue(result)

    def test_verify_docker_installation_service_inactive(self):
        """测试Docker服务未激活的情况"""
        mock_subprocess = MockSubprocess()
        mock_subprocess.set_return_code('docker --version', 0)
        mock_subprocess.set_output('docker --version', 'Docker version 24.0.0', '')
        mock_subprocess.set_return_code('systemctl is-active docker', 0)
        mock_subprocess.set_output('systemctl is-active docker', 'inactive', '')

        with patch('subprocess.run', mock_subprocess.run):
            result = self.docker_install.verify_docker_installation()
            self.assertFalse(result)

    def test_verify_docker_installation_hello_world_fail(self):
        """测试hello-world容器运行失败"""
        mock_subprocess = MockSubprocess()
        mock_subprocess.set_return_code('docker --version', 0)
        mock_subprocess.set_output('docker --version', 'Docker version 24.0.0', '')
        mock_subprocess.set_return_code('systemctl is-active docker', 0)
        mock_subprocess.set_output('systemctl is-active docker', 'active', '')
        mock_subprocess.set_return_code('docker run --rm hello-world', 0)
        mock_subprocess.set_output('docker run --rm hello-world', 'Some other output', '')

        with patch('subprocess.run', mock_subprocess.run):
            result = self.docker_install.verify_docker_installation()
            self.assertFalse(result)

class TestDockerPush(BaseTestCase):
    """测试Docker推送脚本"""

    def setUp(self):
        super().setUp()
        try:
            sys.path.insert(0, str(project_root / "scripts" / "containers"))
            import importlib.util

            # 动态导入docker_push模块
            spec = importlib.util.spec_from_file_location(
                "docker_push",
                project_root / "scripts" / "containers" / "docker-push.py"
            )
            docker_push = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(docker_push)
            self.docker_push = docker_push
        except Exception as e:
            self.skipTest(f"docker_push模块未找到: {e}")

    def test_search_docker_images_success(self):
        """测试Docker镜像搜索成功"""
        mock_response = Mock()
        mock_response.json.return_value = {
            'results': [
                {
                    'name': 'nginx',
                    'short_description': 'Official build of Nginx.',
                    'star_count': 15000,
                    'is_official': True
                }
            ]
        }
        mock_response.raise_for_status.return_value = None

        with patch('requests.get', return_value=mock_response):
            results = self.docker_push.search_docker_images('nginx')
            self.assertEqual(len(results), 1)
            self.assertEqual(results[0]['name'], 'nginx')

    def test_search_docker_images_no_results(self):
        """测试Docker镜像搜索无结果"""
        mock_response = Mock()
        mock_response.json.return_value = {'results': []}
        mock_response.raise_for_status.return_value = None

        with patch('requests.get', return_value=mock_response):
            results = self.docker_push.search_docker_images('nonexistent')
            self.assertEqual(len(results), 0)

    def test_pull_docker_image_success(self):
        """测试Docker镜像拉取成功"""
        mock_subprocess = MockSubprocess()
        mock_subprocess.set_return_code('docker pull nginx:latest', 0)

        with patch('subprocess.run', mock_subprocess.run):
            result = self.docker_push.pull_docker_image('nginx', 'latest')
            self.assertTrue(result)

    def test_pull_docker_image_fail(self):
        """测试Docker镜像拉取失败"""
        mock_subprocess = MockSubprocess()
        mock_subprocess.set_return_code('docker pull nginx:latest', 1)

        with patch('subprocess.run', mock_subprocess.run):
            result = self.docker_push.pull_docker_image('nginx', 'latest')
            self.assertFalse(result)

    def test_tag_docker_image_success(self):
        """测试Docker镜像标记成功"""
        mock_subprocess = MockSubprocess()
        mock_subprocess.set_return_code('docker tag nginx:latest registry.example.com/nginx:latest', 0)

        with patch('subprocess.run', mock_subprocess.run):
            result = self.docker_push.tag_docker_image('nginx', 'registry.example.com', 'nginx', 'latest')
            self.assertEqual(result, 'registry.example.com/nginx:latest')

    def test_push_docker_image_success(self):
        """测试Docker镜像推送成功"""
        mock_subprocess = MockSubprocess()
        mock_subprocess.set_return_code('docker push registry.example.com/nginx:latest', 0)

        with patch('subprocess.run', mock_subprocess.run):
            result = self.docker_push.push_docker_image('registry.example.com/nginx:latest')
            self.assertTrue(result)

    def test_docker_login_success(self):
        """测试Docker登录成功"""
        mock_subprocess = MockSubprocess()
        mock_subprocess.set_return_code("echo 'password' | docker login registry.example.com -u username --password-stdin", 0)

        with patch('subprocess.run', mock_subprocess.run):
            result = self.docker_push.docker_login('registry.example.com', 'username', 'password')
            self.assertTrue(result)

if __name__ == "__main__":
    unittest.main(verbosity=2)
