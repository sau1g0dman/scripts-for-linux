# 脚本升级指南：集成交互式确认功能

## 概述

本指南说明如何将你现有的所有脚本升级为使用新的交互式确认功能，替换传统的 y/n 输入方式。

## 🎯 升级目标

将传统的文本确认：
```
是否继续？ [Y/n]: _
```

升级为现代化的交互式选择器：
```
╭─ 是否继续？
│
╰─ ● 是 / ○ 否
```

## 📋 需要升级的脚本列表

基于你的项目结构，以下脚本需要升级：

### 容器相关脚本
- `scripts/containers/docker-install.sh` ✅ 已使用通用函数库
- `scripts/containers/docker-mirrors.sh`
- `scripts/containers/docker-push.sh`
- `scripts/containers/harbor-push.sh`

### 开发环境脚本
- `scripts/development/nvim-setup.sh` ✅ 已升级
- 其他开发环境脚本

### 安全配置脚本
- `scripts/security/ssh-config.sh`
- `scripts/security/ssh-keygen.sh`

### Shell 配置脚本
- `scripts/shell/zsh-arm.sh`
- `scripts/shell/zsh-install.sh`

### 系统工具脚本
- `scripts/system/time-sync.sh`
- `scripts/utilities/disk-formatter.sh`

## 🔧 升级步骤

### 步骤1：更新脚本头部

#### 原来的方式：
```bash
#!/bin/bash
# 各种自定义函数...
```

#### 升级后的方式：
```bash
#!/bin/bash

# 导入通用函数库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

# 检查是否为远程执行（通过curl | bash）
if [[ -f "$SCRIPT_DIR/../common.sh" ]]; then
    # 本地执行
    source "$SCRIPT_DIR/../common.sh"
else
    # 远程执行，下载common.sh
    COMMON_SH_URL="https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/scripts/common.sh"
    if ! source <(curl -fsSL "$COMMON_SH_URL"); then
        echo "错误：无法加载通用函数库"
        exit 1
    fi
fi
```

### 步骤2：替换确认函数

#### 查找并替换以下模式：

**模式1：简单的 read 确认**
```bash
# 原来的代码
read -p "是否继续？ [y/N]: " choice
case $choice in
    [Yy]|[Yy][Ee][Ss])
        echo "继续..."
        ;;
    *)
        echo "取消"
        exit 1
        ;;
esac

# 替换为
if ask_confirmation "是否继续？"; then
    echo "继续..."
else
    echo "取消"
    exit 1
fi
```

**模式2：自定义确认函数**
```bash
# 删除原来的自定义函数
ask_confirmation() {
    # ... 原来的实现
}

# 直接使用通用函数库中的 ask_confirmation
```

**模式3：复杂的确认逻辑**
```bash
# 原来的代码
while true; do
    read -p "选择操作 [y/N]: " choice
    case $choice in
        [Yy]*) 
            perform_action
            break
            ;;
        [Nn]*|"")
            echo "跳过操作"
            break
            ;;
        *)
            echo "请输入 y 或 n"
            ;;
    esac
done

# 替换为
if ask_confirmation "选择操作"; then
    perform_action
else
    echo "跳过操作"
fi
```

### 步骤3：更新主函数

```bash
main() {
    # 初始化环境（包含系统检测、权限检查等）
    init_environment
    
    # 显示脚本信息
    show_header "脚本名称" "版本" "描述"
    
    # 你的脚本逻辑...
    
    # 显示完成信息
    show_footer
}

# 运行主函数
main "$@"
```

## 📝 具体升级示例

### 示例1：docker-mirrors.sh 升级

**升级前：**
```bash
#!/bin/bash
echo "配置Docker镜像加速..."
read -p "是否继续？ [Y/n]: " choice
if [[ $choice =~ ^[Nn] ]]; then
    exit 0
fi
```

**升级后：**
```bash
#!/bin/bash

# 导入通用函数库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

main() {
    init_environment
    show_header "Docker镜像加速配置" "1.0" "配置Docker镜像加速服务"
    
    if ask_confirmation "是否配置Docker镜像加速？" "y"; then
        configure_docker_mirrors
    else
        log_info "取消配置"
        exit 0
    fi
    
    show_footer
}

main "$@"
```

### 示例2：ssh-config.sh 升级

**升级前：**
```bash
#!/bin/bash
echo "SSH安全配置脚本"

echo "即将进行以下配置："
echo "1. 禁用root登录"
echo "2. 修改SSH端口"
echo "3. 配置密钥认证"

read -p "确认执行？ [y/N]: " confirm
if [[ ! $confirm =~ ^[Yy] ]]; then
    echo "取消执行"
    exit 1
fi
```

**升级后：**
```bash
#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

main() {
    init_environment
    show_header "SSH安全配置" "1.0" "配置SSH服务安全设置"
    
    log_info "即将进行以下配置："
    log_info "1. 禁用root登录"
    log_info "2. 修改SSH端口"
    log_info "3. 配置密钥认证"
    
    if ask_confirmation "确认执行SSH安全配置？"; then
        configure_ssh_security
    else
        log_info "取消执行"
        exit 1
    fi
    
    show_footer
}

main "$@"
```

## 🧪 测试升级结果

### 1. 运行测试脚本
```bash
./test-interactive-confirmation.sh
```

### 2. 测试各个升级后的脚本
```bash
# 测试Docker安装脚本
./scripts/containers/docker-install.sh

# 测试Neovim配置脚本
./scripts/development/nvim-setup.sh

# 测试其他脚本...
```

### 3. 验证功能
- ✅ 支持键盘导航（左右箭头键）
- ✅ 支持快捷键（a/d 键）
- ✅ 回车确认
- ✅ Ctrl+C 取消
- ✅ 兼容模式降级
- ✅ 默认值设置

## 🔄 批量升级脚本

创建一个批量升级脚本来自动化这个过程：

```bash
#!/bin/bash
# upgrade-all-scripts.sh

SCRIPTS_TO_UPGRADE=(
    "scripts/containers/docker-mirrors.sh"
    "scripts/containers/docker-push.sh"
    "scripts/containers/harbor-push.sh"
    "scripts/security/ssh-config.sh"
    "scripts/security/ssh-keygen.sh"
    "scripts/shell/zsh-arm.sh"
    "scripts/shell/zsh-install.sh"
    "scripts/system/time-sync.sh"
    "scripts/utilities/disk-formatter.sh"
)

for script in "${SCRIPTS_TO_UPGRADE[@]}"; do
    echo "升级脚本: $script"
    # 在这里添加自动升级逻辑
    # 或者提示手动升级
done
```

## 📚 最佳实践

### 1. 保持向后兼容
```bash
# 在脚本中添加兼容性检查
if [[ "${USE_BUILTIN_FUNCTIONS:-false}" == "true" ]]; then
    # 使用内置函数
else
    # 使用通用函数库
fi
```

### 2. 合理设置默认值
```bash
# 安全操作默认为"是"
ask_confirmation "是否更新软件包？" "y"

# 危险操作默认为"否"  
ask_confirmation "是否删除所有数据？" "n"
```

### 3. 提供清晰的提示
```bash
# 好的提示
ask_confirmation "是否安装Docker？（大约需要5分钟）"

# 不好的提示
ask_confirmation "继续？"
```

## 🚀 升级完成后的优势

1. **统一的用户体验**：所有脚本使用相同的交互方式
2. **现代化界面**：美观的图形化选择器
3. **更好的可用性**：键盘导航支持
4. **智能降级**：自动适配不同终端环境
5. **易于维护**：集中管理通用功能
6. **更好的错误处理**：统一的错误处理机制

## 📞 需要帮助？

如果在升级过程中遇到问题：

1. 查看 `docs/interactive-confirmation-guide.md` 详细文档
2. 运行 `./scripts/examples/interactive-confirmation-demo.sh` 查看演示
3. 检查 `test-interactive-confirmation.sh` 测试结果
4. 查看具体脚本的升级示例

升级愉快！🎉
