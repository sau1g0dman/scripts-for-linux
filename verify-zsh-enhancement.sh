#!/bin/bash

# ZSH安装脚本增强功能验证
echo "=== ZSH安装脚本增强功能验证 ==="

# 1. 语法检查
echo "1. 语法检查..."
if bash -n scripts/shell/zsh-install.sh; then
    echo "✅ 语法检查通过"
else
    echo "❌ 语法检查失败"
    exit 1
fi

# 2. 检查增强函数
echo "2. 检查增强函数..."
if timeout 10 bash -c 'source scripts/shell/zsh-install.sh >/dev/null 2>&1'; then
    echo "✅ 脚本导入成功"
    
    # 检查关键函数
    if timeout 5 bash -c 'source scripts/shell/zsh-install.sh >/dev/null 2>&1 && declare -f install_package_with_progress >/dev/null'; then
        echo "✅ install_package_with_progress 函数存在"
    else
        echo "❌ install_package_with_progress 函数缺失"
    fi
    
    if timeout 5 bash -c 'source scripts/shell/zsh-install.sh >/dev/null 2>&1 && declare -f check_network_status >/dev/null'; then
        echo "✅ check_network_status 函数存在"
    else
        echo "❌ check_network_status 函数缺失"
    fi
    
    if timeout 5 bash -c 'source scripts/shell/zsh-install.sh >/dev/null 2>&1 && declare -f analyze_install_error >/dev/null'; then
        echo "✅ analyze_install_error 函数存在"
    else
        echo "❌ analyze_install_error 函数缺失"
    fi
else
    echo "❌ 脚本导入失败或超时"
    exit 1
fi

# 3. 检查软件包列表
echo "3. 检查软件包列表..."
if timeout 5 bash -c 'source scripts/shell/zsh-install.sh >/dev/null 2>&1 && [ ${#REQUIRED_PACKAGES[@]} -gt 0 ]'; then
    echo "✅ 必需软件包列表存在"
else
    echo "❌ 必需软件包列表问题"
fi

if timeout 5 bash -c 'source scripts/shell/zsh-install.sh >/dev/null 2>&1 && [ ${#OPTIONAL_PACKAGES[@]} -gt 0 ]'; then
    echo "✅ 可选软件包列表存在"
else
    echo "❌ 可选软件包列表问题"
fi

echo "=== 验证完成 ==="
echo
echo "增强功能包括："
echo "• 实时安装进度显示（↓📦⚙️✅等符号）"
echo "• 网络状态检测和慢速提示"
echo "• 智能错误分析和解决建议"
echo "• 详细的安装统计和概览"
echo "• 超时保护和取消提示"
echo
echo "现在可以使用增强版的ZSH安装脚本："
echo "  ./scripts/shell/zsh-install.sh"
