#!/bin/bash

# 快速SSH脚本测试
echo "=== SSH配置脚本修复验证 ==="

# 1. 语法检查
echo "1. 语法检查..."
if bash -n scripts/security/ssh-config.sh; then
    echo "✅ 语法检查通过"
else
    echo "❌ 语法检查失败"
    exit 1
fi

# 2. 检查 local 变量问题
echo "2. 检查 local 变量使用..."
if bash -c 'source scripts/security/ssh-config.sh' 2>&1 | grep -q "local: can only be used in a function"; then
    echo "❌ 仍然存在 local 变量问题"
    bash -c 'source scripts/security/ssh-config.sh' 2>&1 | grep "local:"
    exit 1
else
    echo "✅ local 变量使用正确"
fi

# 3. 基本导入测试
echo "3. 脚本导入测试..."
if timeout 5 bash -c 'source scripts/security/ssh-config.sh' >/dev/null 2>&1; then
    echo "✅ 脚本导入成功"
else
    echo "❌ 脚本导入失败或超时"
    exit 1
fi

echo "=== 所有测试通过！SSH配置脚本修复成功！ ==="
echo "现在可以正常使用: sudo ./scripts/security/ssh-config.sh"
