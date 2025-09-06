#!/usr/bin/env python3

"""
通用测试模块
提供测试框架和通用测试工具
"""

import unittest
import sys
import os
import tempfile
import shutil
import subprocess
from pathlib import Path
from unittest.mock import Mock, patch, MagicMock

# 添加项目根目录到Python路径
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))
sys.path.insert(0, str(project_root / "scripts"))

class BaseTestCase(unittest.TestCase):
    """基础测试类"""

    def setUp(self):
        """测试前设置"""
        self.temp_dir = tempfile.mkdtemp()
        self.original_cwd = os.getcwd()

        # Mock环境变量
        self.env_patcher = patch.dict(os.environ, {
            'USER': 'testuser',
            'HOME': self.temp_dir,
            'SUDO_USER': 'testuser'
        })
        self.env_patcher.start()

    def tearDown(self):
        """测试后清理"""
        os.chdir(self.original_cwd)
        shutil.rmtree(self.temp_dir, ignore_errors=True)
        self.env_patcher.stop()

    def create_temp_file(self, filename, content=""):
        """创建临时文件"""
        file_path = Path(self.temp_dir) / filename
        file_path.parent.mkdir(parents=True, exist_ok=True)
        with open(file_path, 'w') as f:
            f.write(content)
        return str(file_path)

    def create_temp_dir(self, dirname):
        """创建临时目录"""
        dir_path = Path(self.temp_dir) / dirname
        dir_path.mkdir(parents=True, exist_ok=True)
        return str(dir_path)

class MockSubprocess:
    """Mock subprocess模块"""

    def __init__(self):
        self.commands = []
        self.return_codes = {}
        self.outputs = {}
        self.errors = {}

    def set_return_code(self, command, return_code):
        """设置命令返回码"""
        self.return_codes[command] = return_code

    def set_output(self, command, stdout="", stderr=""):
        """设置命令输出"""
        self.outputs[command] = {
            'stdout': stdout,
            'stderr': stderr
        }

    def run(self, cmd, *args, **kwargs):
        """Mock subprocess.run"""
        if isinstance(cmd, list):
            cmd_str = ' '.join(cmd)
        else:
            cmd_str = cmd

        self.commands.append(cmd_str)

        # 创建mock结果
        result = Mock()
        result.returncode = self.return_codes.get(cmd_str, 0)

        if cmd_str in self.outputs:
            result.stdout = self.outputs[cmd_str]['stdout']
            result.stderr = self.outputs[cmd_str]['stderr']
        else:
            result.stdout = ""
            result.stderr = ""

        # 如果设置了check=True且返回码非0，抛出异常
        if kwargs.get('check', False) and result.returncode != 0:
            error = subprocess.CalledProcessError(
                result.returncode, cmd, result.stdout, result.stderr
            )
            raise error

        return result

class TestCommonModule(BaseTestCase):
    """测试common模块"""

    def setUp(self):
        super().setUp()
        try:
            import common
            self.common = common
        except ImportError:
            self.skipTest("common模块未找到")

    def test_detect_os(self):
        """测试操作系统检测"""
        # Mock /etc/os-release文件
        os_release_content = '''NAME="Ubuntu"
VERSION="22.04.3 LTS (Jammy Jellyfish)"
ID=ubuntu
ID_LIKE=debian
PRETTY_NAME="Ubuntu 22.04.3 LTS"
VERSION_ID="22.04"
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
VERSION_CODENAME=jammy
UBUNTU_CODENAME=jammy'''

        os_release_path = self.create_temp_file('etc/os-release', os_release_content)

        with patch('pathlib.Path.exists', return_value=True), \
             patch('builtins.open', mock_open(read_data=os_release_content)):
            result = self.common.detect_os()
            self.assertEqual(result, 'ubuntu')

    def test_detect_arch(self):
        """测试架构检测"""
        with patch('platform.machine', return_value='x86_64'):
            result = self.common.detect_arch()
            self.assertEqual(result, 'x64')

        with patch('platform.machine', return_value='aarch64'):
            result = self.common.detect_arch()
            self.assertEqual(result, 'arm64')

    def test_check_network(self):
        """测试网络连接检查"""
        # Mock成功的网络连接
        with patch('socket.socket') as mock_socket_class:
            mock_socket = Mock()
            mock_socket.connect.return_value = None
            mock_socket_class.return_value = mock_socket

            result = self.common.check_network()
            self.assertTrue(result)

        # Mock失败的网络连接
        with patch('socket.socket') as mock_socket_class:
            mock_socket = Mock()
            mock_socket.connect.side_effect = Exception("Connection failed")
            mock_socket_class.return_value = mock_socket

            result = self.common.check_network()
            self.assertFalse(result)

    def test_execute_command(self):
        """测试命令执行"""
        mock_subprocess = MockSubprocess()
        mock_subprocess.set_return_code('echo test', 0)
        mock_subprocess.set_output('echo test', 'test\n', '')

        with patch('subprocess.run', mock_subprocess.run):
            result = self.common.execute_command('echo test', '测试命令')
            self.assertTrue(result)
            self.assertIn('echo test', mock_subprocess.commands)

    def test_interactive_ask_confirmation(self):
        """测试交互式确认"""
        # Mock用户输入'y'
        with patch('builtins.input', return_value='y'):
            result = self.common.interactive_ask_confirmation('测试问题', False)
            self.assertTrue(result)

        # Mock用户输入'n'
        with patch('builtins.input', return_value='n'):
            result = self.common.interactive_ask_confirmation('测试问题', True)
            self.assertFalse(result)

        # Mock用户直接回车（使用默认值）
        with patch('builtins.input', return_value=''):
            result = self.common.interactive_ask_confirmation('测试问题', True)
            self.assertTrue(result)

def mock_open(read_data=""):
    """创建mock open函数"""
    from unittest.mock import mock_open as unittest_mock_open
    return unittest_mock_open(read_data=read_data)

class TestRunner:
    """测试运行器"""

    def __init__(self):
        self.test_modules = []
        self.results = {}

    def add_test_module(self, module_name):
        """添加测试模块"""
        self.test_modules.append(module_name)

    def run_tests(self):
        """运行所有测试"""
        total_tests = 0
        total_failures = 0
        total_errors = 0

        print("开始运行单元测试...")
        print("=" * 60)

        for module_name in self.test_modules:
            try:
                # 动态导入测试模块
                module = __import__(module_name)

                # 创建测试套件
                loader = unittest.TestLoader()
                suite = loader.loadTestsFromModule(module)

                # 运行测试
                runner = unittest.TextTestRunner(verbosity=2)
                result = runner.run(suite)

                # 记录结果
                self.results[module_name] = {
                    'tests': result.testsRun,
                    'failures': len(result.failures),
                    'errors': len(result.errors),
                    'success': result.wasSuccessful()
                }

                total_tests += result.testsRun
                total_failures += len(result.failures)
                total_errors += len(result.errors)

            except Exception as e:
                print(f"运行测试模块 {module_name} 时发生错误: {e}")
                self.results[module_name] = {
                    'tests': 0,
                    'failures': 0,
                    'errors': 1,
                    'success': False
                }
                total_errors += 1

        # 显示总结
        print("\n" + "=" * 60)
        print("测试结果总结:")
        print("=" * 60)

        for module_name, result in self.results.items():
            status = "✓ 通过" if result['success'] else "✗ 失败"
            print(f"{module_name}: {status} "
                  f"(测试: {result['tests']}, "
                  f"失败: {result['failures']}, "
                  f"错误: {result['errors']})")

        print("-" * 60)
        print(f"总计: 测试 {total_tests}, 失败 {total_failures}, 错误 {total_errors}")

        success_rate = ((total_tests - total_failures - total_errors) / total_tests * 100) if total_tests > 0 else 0
        print(f"成功率: {success_rate:.1f}%")

        return total_failures + total_errors == 0

if __name__ == "__main__":
    # 运行通用模块测试
    unittest.main(verbosity=2)
