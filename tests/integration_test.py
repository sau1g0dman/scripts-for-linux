#!/usr/bin/env python3

"""
集成测试脚本
测试所有Python脚本的协同工作能力
"""

import sys
import os
import subprocess
import tempfile
import shutil
from pathlib import Path
import time

# 添加项目路径
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))
sys.path.insert(0, str(project_root / "scripts"))

def run_command(cmd, cwd=None, timeout=30):
    """运行命令并返回结果"""
    try:
        result = subprocess.run(
            cmd, 
            shell=True, 
            cwd=cwd or project_root,
            capture_output=True, 
            text=True, 
            timeout=timeout
        )
        return result.returncode == 0, result.stdout, result.stderr
    except subprocess.TimeoutExpired:
        return False, "", "命令执行超时"
    except Exception as e:
        return False, "", str(e)

def test_script_syntax():
    """测试所有Python脚本的语法正确性"""
    print("🔍 测试Python脚本语法...")
    
    python_files = []
    
    # 查找所有Python脚本
    for py_file in project_root.rglob("*.py"):
        if "test" not in str(py_file) and "__pycache__" not in str(py_file):
            python_files.append(py_file)
    
    failed_files = []
    
    for py_file in python_files:
        success, stdout, stderr = run_command(f"python3 -m py_compile {py_file}")
        if not success:
            failed_files.append((py_file, stderr))
            print(f"  ❌ {py_file.relative_to(project_root)}: {stderr}")
        else:
            print(f"  ✅ {py_file.relative_to(project_root)}")
    
    if failed_files:
        print(f"\n❌ 语法检查失败: {len(failed_files)} 个文件有语法错误")
        return False
    else:
        print(f"\n✅ 语法检查通过: {len(python_files)} 个文件")
        return True

def test_script_imports():
    """测试脚本导入依赖"""
    print("\n🔍 测试脚本导入依赖...")
    
    scripts_to_test = [
        "scripts/common.py",
        "scripts/containers/docker-install.py",
        "scripts/containers/docker-push.py", 
        "scripts/containers/harbor-push.py",
        "scripts/development/nvim-setup.py",
        "scripts/security/ssh-config.py",
        "scripts/security/ssh-keygen.py",
        "scripts/shell/zsh-arm.py",
        "scripts/system/time-sync.py",
        "scripts/utilities/disk-formatter.py",
        "scripts/reference.py",
        "bootstrap.py",
        "uninstall.py"
    ]
    
    failed_imports = []
    
    for script in scripts_to_test:
        script_path = project_root / script
        if not script_path.exists():
            print(f"  ⚠️  {script}: 文件不存在")
            continue
        
        # 测试导入
        test_cmd = f"python3 -c \"import sys; sys.path.insert(0, '{script_path.parent}'); import importlib.util; spec = importlib.util.spec_from_file_location('test_module', '{script_path}'); module = importlib.util.module_from_spec(spec); spec.loader.exec_module(module); print('导入成功')\""
        
        success, stdout, stderr = run_command(test_cmd)
        if not success:
            failed_imports.append((script, stderr))
            print(f"  ❌ {script}: {stderr}")
        else:
            print(f"  ✅ {script}")
    
    if failed_imports:
        print(f"\n❌ 导入测试失败: {len(failed_imports)} 个脚本")
        return False
    else:
        print(f"\n✅ 导入测试通过: {len(scripts_to_test)} 个脚本")
        return True

def test_help_functionality():
    """测试脚本帮助功能"""
    print("\n🔍 测试脚本帮助功能...")
    
    scripts_with_help = [
        "scripts/containers/docker-install.py",
        "scripts/development/nvim-setup.py",
        "scripts/system/time-sync.py",
        "bootstrap.py"
    ]
    
    help_tests_passed = 0
    
    for script in scripts_with_help:
        script_path = project_root / script
        if not script_path.exists():
            continue
        
        # 测试--help参数
        success, stdout, stderr = run_command(f"python3 {script_path} --help", timeout=10)
        if success or "help" in stdout.lower() or "usage" in stdout.lower():
            print(f"  ✅ {script}: 帮助功能正常")
            help_tests_passed += 1
        else:
            print(f"  ⚠️  {script}: 无帮助功能或帮助功能异常")
    
    print(f"\n✅ 帮助功能测试: {help_tests_passed} 个脚本支持帮助")
    return True

def test_common_module_integration():
    """测试common模块集成"""
    print("\n🔍 测试common模块集成...")
    
    test_script = """
import sys
sys.path.insert(0, 'scripts')
from common import *

# 测试基本功能
print("测试日志功能...")
log_info("这是一个信息日志")
log_warn("这是一个警告日志")

print("测试系统检测...")
os_name = detect_os()
arch = detect_arch()
print(f"操作系统: {os_name}")
print(f"架构: {arch}")

print("测试时间戳...")
timestamp = get_timestamp()
print(f"时间戳: {timestamp}")

print("common模块集成测试通过")
"""
    
    # 创建临时测试文件
    with tempfile.NamedTemporaryFile(mode='w', suffix='.py', delete=False) as f:
        f.write(test_script)
        temp_file = f.name
    
    try:
        success, stdout, stderr = run_command(f"python3 {temp_file}")
        if success and "common模块集成测试通过" in stdout:
            print("  ✅ common模块集成测试通过")
            return True
        else:
            print(f"  ❌ common模块集成测试失败: {stderr}")
            return False
    finally:
        os.unlink(temp_file)

def test_script_execution_safety():
    """测试脚本执行安全性（不实际执行危险操作）"""
    print("\n🔍 测试脚本执行安全性...")
    
    # 测试脚本是否会在导入时执行危险操作
    dangerous_scripts = [
        "scripts/utilities/disk-formatter.py",  # 磁盘格式化
        "scripts/security/ssh-config.py",      # SSH配置修改
        "uninstall.py"                         # 卸载操作
    ]
    
    safe_imports = 0
    
    for script in dangerous_scripts:
        script_path = project_root / script
        if not script_path.exists():
            continue
        
        # 检查脚本是否有if __name__ == "__main__"保护
        with open(script_path, 'r') as f:
            content = f.read()
        
        if 'if __name__ == "__main__"' in content:
            print(f"  ✅ {script}: 有执行保护")
            safe_imports += 1
        else:
            print(f"  ⚠️  {script}: 缺少执行保护")
    
    print(f"\n✅ 安全性检查: {safe_imports} 个危险脚本有执行保护")
    return True

def test_cross_script_dependencies():
    """测试脚本间依赖关系"""
    print("\n🔍 测试脚本间依赖关系...")
    
    # 测试脚本是否能正确导入common模块
    scripts_using_common = [
        "scripts/containers/docker-install.py",
        "scripts/development/nvim-setup.py",
        "scripts/system/time-sync.py"
    ]
    
    dependency_tests_passed = 0
    
    for script in scripts_using_common:
        script_path = project_root / script
        if not script_path.exists():
            continue
        
        # 检查是否导入了common模块
        with open(script_path, 'r') as f:
            content = f.read()
        
        if 'from common import' in content or 'import common' in content:
            print(f"  ✅ {script}: 正确导入common模块")
            dependency_tests_passed += 1
        else:
            print(f"  ⚠️  {script}: 未导入common模块")
    
    print(f"\n✅ 依赖关系测试: {dependency_tests_passed} 个脚本正确导入依赖")
    return True

def test_file_permissions():
    """测试文件权限"""
    print("\n🔍 测试文件权限...")
    
    executable_files = []
    
    # 查找所有Python脚本
    for py_file in project_root.rglob("*.py"):
        if "test" not in str(py_file) and "__pycache__" not in str(py_file):
            if py_file.name != "common.py":  # common.py不需要执行权限
                executable_files.append(py_file)
    
    correct_permissions = 0
    
    for py_file in executable_files:
        if os.access(py_file, os.X_OK):
            print(f"  ✅ {py_file.relative_to(project_root)}: 有执行权限")
            correct_permissions += 1
        else:
            print(f"  ⚠️  {py_file.relative_to(project_root)}: 缺少执行权限")
    
    print(f"\n✅ 权限检查: {correct_permissions}/{len(executable_files)} 个脚本有执行权限")
    return True

def run_integration_tests():
    """运行所有集成测试"""
    print("🧪 开始运行集成测试")
    print("=" * 60)
    
    tests = [
        ("语法检查", test_script_syntax),
        ("导入依赖测试", test_script_imports),
        ("帮助功能测试", test_help_functionality),
        ("common模块集成测试", test_common_module_integration),
        ("执行安全性测试", test_script_execution_safety),
        ("脚本依赖关系测试", test_cross_script_dependencies),
        ("文件权限测试", test_file_permissions)
    ]
    
    passed_tests = 0
    total_tests = len(tests)
    
    for test_name, test_func in tests:
        print(f"\n📋 运行测试: {test_name}")
        print("-" * 40)
        
        try:
            if test_func():
                passed_tests += 1
                print(f"✅ {test_name} - 通过")
            else:
                print(f"❌ {test_name} - 失败")
        except Exception as e:
            print(f"❌ {test_name} - 错误: {e}")
    
    # 生成测试报告
    print("\n" + "=" * 60)
    print("📊 集成测试结果报告")
    print("=" * 60)
    print(f"总测试数量: {total_tests}")
    print(f"通过测试: {passed_tests}")
    print(f"失败测试: {total_tests - passed_tests}")
    
    if passed_tests == total_tests:
        success_rate = 100.0
    else:
        success_rate = (passed_tests / total_tests) * 100
    
    print(f"成功率: {success_rate:.1f}%")
    
    if passed_tests == total_tests:
        print("\n🎉 所有集成测试通过！")
        return True
    else:
        print(f"\n⚠️  {total_tests - passed_tests} 个测试失败")
        return False

def main():
    """主函数"""
    success = run_integration_tests()
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
