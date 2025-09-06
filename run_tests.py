#!/usr/bin/env python3

"""
测试运行脚本
运行所有单元测试并生成报告
"""

import sys
import os
import unittest
import importlib.util
from pathlib import Path

# 添加项目路径
project_root = Path(__file__).parent
sys.path.insert(0, str(project_root))
sys.path.insert(0, str(project_root / "scripts"))
sys.path.insert(0, str(project_root / "tests"))

def discover_and_run_tests():
    """发现并运行所有测试"""
    print("🧪 开始运行Python脚本单元测试")
    print("=" * 60)
    
    # 测试目录
    test_dir = project_root / "tests"
    
    # 发现所有测试文件
    test_files = []
    for test_file in test_dir.rglob("test_*.py"):
        if test_file.name != "__init__.py":
            test_files.append(test_file)
    
    if not test_files:
        print("❌ 未找到测试文件")
        return False
    
    print(f"📁 找到 {len(test_files)} 个测试文件:")
    for test_file in test_files:
        rel_path = test_file.relative_to(project_root)
        print(f"   - {rel_path}")
    print()
    
    # 运行测试
    total_tests = 0
    total_failures = 0
    total_errors = 0
    test_results = {}
    
    for test_file in test_files:
        print(f"🔍 运行测试: {test_file.name}")
        print("-" * 40)
        
        try:
            # 动态导入测试模块
            spec = importlib.util.spec_from_file_location(
                test_file.stem, test_file
            )
            test_module = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(test_module)
            
            # 创建测试套件
            loader = unittest.TestLoader()
            suite = loader.loadTestsFromModule(test_module)
            
            # 运行测试
            runner = unittest.TextTestRunner(
                verbosity=2,
                stream=sys.stdout,
                buffer=True
            )
            result = runner.run(suite)
            
            # 记录结果
            test_results[test_file.name] = {
                'tests': result.testsRun,
                'failures': len(result.failures),
                'errors': len(result.errors),
                'success': result.wasSuccessful(),
                'failures_detail': result.failures,
                'errors_detail': result.errors
            }
            
            total_tests += result.testsRun
            total_failures += len(result.failures)
            total_errors += len(result.errors)
            
        except Exception as e:
            print(f"❌ 运行测试文件 {test_file.name} 时发生错误: {e}")
            test_results[test_file.name] = {
                'tests': 0,
                'failures': 0,
                'errors': 1,
                'success': False,
                'failures_detail': [],
                'errors_detail': [(None, str(e))]
            }
            total_errors += 1
        
        print()
    
    # 生成测试报告
    generate_test_report(test_results, total_tests, total_failures, total_errors)
    
    return total_failures + total_errors == 0

def generate_test_report(test_results, total_tests, total_failures, total_errors):
    """生成测试报告"""
    print("📊 测试结果报告")
    print("=" * 60)
    
    # 按模块显示结果
    for test_file, result in test_results.items():
        status_icon = "✅" if result['success'] else "❌"
        print(f"{status_icon} {test_file}")
        print(f"   测试数量: {result['tests']}")
        print(f"   失败数量: {result['failures']}")
        print(f"   错误数量: {result['errors']}")
        
        # 显示失败详情
        if result['failures_detail']:
            print("   失败详情:")
            for test_case, traceback in result['failures_detail']:
                print(f"     - {test_case}")
        
        # 显示错误详情
        if result['errors_detail']:
            print("   错误详情:")
            for test_case, traceback in result['errors_detail']:
                if test_case:
                    print(f"     - {test_case}")
                else:
                    print(f"     - {traceback}")
        
        print()
    
    # 总体统计
    print("📈 总体统计")
    print("-" * 30)
    print(f"总测试数量: {total_tests}")
    print(f"成功数量: {total_tests - total_failures - total_errors}")
    print(f"失败数量: {total_failures}")
    print(f"错误数量: {total_errors}")
    
    if total_tests > 0:
        success_rate = (total_tests - total_failures - total_errors) / total_tests * 100
        print(f"成功率: {success_rate:.1f}%")
    else:
        print("成功率: 0.0%")
    
    print()
    
    # 最终结果
    if total_failures + total_errors == 0:
        print("🎉 所有测试通过！")
    else:
        print("⚠️  部分测试失败，请检查上述错误信息")
    
    print("=" * 60)

def run_specific_test(test_name):
    """运行特定测试"""
    test_dir = project_root / "tests"
    test_file = None
    
    # 查找测试文件
    for candidate in test_dir.rglob(f"*{test_name}*.py"):
        if candidate.name.startswith("test_"):
            test_file = candidate
            break
    
    if not test_file:
        print(f"❌ 未找到测试文件: {test_name}")
        return False
    
    print(f"🔍 运行特定测试: {test_file.name}")
    print("=" * 60)
    
    try:
        # 动态导入测试模块
        spec = importlib.util.spec_from_file_location(
            test_file.stem, test_file
        )
        test_module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(test_module)
        
        # 创建测试套件
        loader = unittest.TestLoader()
        suite = loader.loadTestsFromModule(test_module)
        
        # 运行测试
        runner = unittest.TextTestRunner(verbosity=2)
        result = runner.run(suite)
        
        return result.wasSuccessful()
        
    except Exception as e:
        print(f"❌ 运行测试时发生错误: {e}")
        return False

def main():
    """主函数"""
    if len(sys.argv) > 1:
        # 运行特定测试
        test_name = sys.argv[1]
        success = run_specific_test(test_name)
    else:
        # 运行所有测试
        success = discover_and_run_tests()
    
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
