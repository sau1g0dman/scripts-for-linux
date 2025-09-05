# 交互式确认功能使用指南

## 概述

这个功能为你的脚本提供了一个现代化的交互式确认选择器，支持键盘导航，提升用户体验。

## 功能特性

### 🎯 智能模式选择
- **高级模式**：支持终端的情况下使用图形化选择器
- **兼容模式**：不支持的终端自动降级为传统文本输入

### ⌨️ 键盘操作
- **左右箭头键** 或 **a/d 键**：选择是/否
- **回车键**：确认选择
- **Ctrl+C**：取消操作

### 🎨 视觉效果
```
╭─ 是否继续安装Docker？
│
╰─ ● 是 / ○ 否
```

## 使用方法

### 基本用法

```bash
# 导入通用函数库
source "path/to/common.sh"

# 基本确认（默认选择"否"）
if ask_confirmation "是否继续安装？"; then
    echo "用户选择：是"
else
    echo "用户选择：否"
fi

# 指定默认选择为"是"
if ask_confirmation "是否更新系统？" "y"; then
    echo "用户选择：是"
else
    echo "用户选择：否"
fi
```

### 在现有脚本中替换

#### 替换前（传统方式）
```bash
read -p "是否继续？ [y/N]: " choice
case $choice in
    [Yy]|[Yy][Ee][Ss])
        echo "继续执行..."
        ;;
    *)
        echo "取消执行"
        exit 1
        ;;
esac
```

#### 替换后（新方式）
```bash
if ask_confirmation "是否继续？"; then
    echo "继续执行..."
else
    echo "取消执行"
    exit 1
fi
```

### 实际应用示例

#### Docker安装脚本
```bash
#!/bin/bash
source "$(dirname "$0")/../common.sh"

main() {
    init_environment
    
    if ! command -v docker >/dev/null 2>&1; then
        if ask_confirmation "Docker未安装，是否现在安装？" "y"; then
            install_docker
            
            if ask_confirmation "是否配置Docker镜像加速？" "y"; then
                configure_docker_mirrors
            fi
            
            if ask_confirmation "是否将当前用户添加到docker组？" "y"; then
                add_user_to_docker_group
            fi
        fi
    else
        log_info "Docker已安装"
        
        if ask_confirmation "是否重新配置Docker？"; then
            reconfigure_docker
        fi
    fi
}

main "$@"
```

#### 系统初始化脚本
```bash
#!/bin/bash
source "$(dirname "$0")/../common.sh"

main() {
    init_environment
    
    local tasks=(
        "更新系统软件包:update_system:y"
        "安装基础工具:install_basic_tools:y"
        "配置SSH安全设置:configure_ssh:n"
        "设置防火墙:setup_firewall:n"
        "安装Docker:install_docker:n"
    )
    
    for task_info in "${tasks[@]}"; do
        IFS=':' read -r task_name task_func default <<< "$task_info"
        
        if ask_confirmation "是否执行：${task_name}？" "$default"; then
            log_info "执行任务：$task_name"
            $task_func
        else
            log_info "跳过任务：$task_name"
        fi
    done
}

main "$@"
```

## 高级功能

### 检查终端支持
```bash
if can_use_interactive_selection; then
    echo "支持高级交互式选择器"
else
    echo "使用传统文本模式"
fi
```

### 直接调用特定模式
```bash
# 强制使用高级交互式模式
interactive_ask_confirmation "确认操作？" "y"

# 强制使用传统文本模式
traditional_ask_confirmation "确认操作？" "y"
```

## 错误处理

### 用户取消操作
当用户按 Ctrl+C 时，函数会：
1. 清理屏幕显示
2. 显示取消提示
3. 退出程序（退出码 130）

### 自定义错误处理
```bash
# 捕获用户取消
trap 'handle_user_cancel' INT

handle_user_cancel() {
    log_warn "用户取消了操作"
    cleanup_resources
    exit 0
}

if ask_confirmation "执行危险操作？"; then
    perform_dangerous_operation
fi

trap - INT  # 重置陷阱
```

## 兼容性

### 支持的终端
- ✅ 大多数现代终端（支持 tput 命令）
- ✅ SSH 远程终端
- ✅ VSCode 集成终端
- ✅ 各种 Linux 发行版默认终端

### 不支持的环境
- ❌ 非交互式环境（CI/CD）
- ❌ 极简终端（无 tput 支持）
- ❌ 某些嵌入式系统

在不支持的环境中，会自动降级为传统文本输入模式。

## 最佳实践

### 1. 合理设置默认值
```bash
# 安全操作默认为"是"
ask_confirmation "是否更新软件包？" "y"

# 危险操作默认为"否"
ask_confirmation "是否删除所有数据？" "n"
```

### 2. 提供清晰的提示信息
```bash
# 好的提示
ask_confirmation "是否安装Docker？（需要约5分钟）"

# 不好的提示
ask_confirmation "继续？"
```

### 3. 合理的确认流程
```bash
# 重要操作前给出详细信息
log_info "即将执行以下操作："
log_info "1. 更新系统软件包"
log_info "2. 安装Docker"
log_info "3. 配置防火墙规则"

if ask_confirmation "确认执行上述操作？"; then
    # 执行操作
fi
```

## 故障排除

### 问题：选择器显示异常
**解决方案**：检查终端是否支持 ANSI 转义序列
```bash
# 测试终端支持
if can_use_interactive_selection; then
    echo "终端支持正常"
else
    echo "终端不支持，将使用文本模式"
fi
```

### 问题：键盘操作无响应
**解决方案**：确保终端处于交互模式
```bash
# 检查是否为交互式终端
if [[ -t 0 ]]; then
    echo "交互式终端"
else
    echo "非交互式终端，某些功能可能不可用"
fi
```

## 演示脚本

运行演示脚本来体验功能：
```bash
chmod +x scripts/examples/interactive-confirmation-demo.sh
./scripts/examples/interactive-confirmation-demo.sh
```
