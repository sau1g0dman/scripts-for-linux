# 容器化模块

容器化模块提供了Docker环境的完整安装和配置解决方案，包括Docker、Docker Compose、镜像管理工具等。

## 📋 模块概述

### 功能列表

- **Docker安装**：自动安装Docker CE和相关工具
- **Docker Compose**：安装最新版本的Docker Compose
- **镜像加速**：配置国内Docker镜像源
- **管理工具**：安装LazyDocker等管理工具
- **镜像推送**：Docker镜像推送和管理工具
- **Harbor支持**：Harbor私有仓库集成

### 支持的系统

- Ubuntu 20.04 LTS
- Ubuntu 22.04 LTS
- Ubuntu 22.10
- 支持 x86_64 和 ARM64 架构

## 🐳 Docker安装脚本

### 脚本路径
`scripts/containers/docker-install.sh`

### 功能说明

Docker是现代应用部署的标准容器化平台，提供：

1. **应用隔离**：容器级别的应用隔离
2. **环境一致性**：开发、测试、生产环境一致
3. **快速部署**：秒级启动和部署
4. **资源效率**：比虚拟机更高的资源利用率
5. **微服务支持**：完美支持微服务架构

### 使用方法

```bash
# 直接执行
bash <(curl -sSL https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/scripts/containers/docker-install.sh)

# 或者下载后执行
curl -fsSL https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/scripts/containers/docker-install.sh -o docker-install.sh
chmod +x docker-install.sh
./docker-install.sh
```

### 安装的组件

#### 核心组件
1. **Docker CE**：Docker社区版
2. **Docker Compose**：多容器应用编排工具
3. **containerd**：容器运行时
4. **docker-cli**：Docker命令行工具

#### 管理工具
1. **LazyDocker**：Docker TUI管理界面
2. **Docker镜像加速器**：国内镜像源配置

### 执行流程

1. **环境检查**：检查系统版本和架构
2. **依赖安装**：安装必要的系统依赖
3. **仓库配置**：添加Docker官方仓库
4. **Docker安装**：安装Docker CE
5. **服务配置**：启动并启用Docker服务
6. **用户配置**：将用户添加到docker组
7. **镜像加速**：配置国内镜像源
8. **工具安装**：安装Docker Compose和LazyDocker
9. **验证测试**：运行hello-world容器验证

### 镜像加速器配置

脚本会自动配置以下国内镜像源：

```json
{
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
```

## 📦 Docker镜像推送工具

### 脚本路径
`scripts/containers/docker-push.sh`

### 功能说明

Docker镜像推送工具提供了完整的镜像管理解决方案：

1. **镜像搜索**：搜索Docker Hub上的镜像
2. **镜像拉取**：从公共仓库拉取镜像
3. **镜像标记**：为镜像添加私有仓库标签
4. **镜像推送**：推送到私有仓库
5. **批量操作**：支持批量镜像操作
6. **交互界面**：友好的交互式操作界面

### 使用方法

```bash
# 直接执行
bash <(curl -sSL https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/scripts/containers/docker-push.sh)

# 交互式使用
./scripts/containers/docker-push.sh
```

### 功能菜单

```
=== Docker镜像推送工具 ===
1. 搜索Docker镜像
2. 拉取Docker镜像
3. 列出本地镜像
4. 标记镜像
5. 推送镜像
6. 登录Docker仓库
7. 一键操作（拉取->标记->推送）
0. 退出
```

### 使用示例

#### 一键操作示例
```bash
# 启动脚本
./scripts/containers/docker-push.sh

# 选择选项7（一键操作）
请选择操作 [0-7]: 7

# 输入源镜像
请输入要拉取的镜像名称（如nginx:latest）: nginx:latest

# 输入目标镜像
请输入目标仓库地址和镜像名称（如registry.example.com/nginx:latest）: registry.example.com/nginx:latest

# 脚本会自动执行：
# 1. 拉取nginx:latest
# 2. 标记为registry.example.com/nginx:latest
# 3. 推送到私有仓库
```

#### 分步操作示例
```bash
# 1. 搜索镜像
选择选项1，搜索"nginx"

# 2. 拉取镜像
选择选项2，拉取"nginx:latest"

# 3. 标记镜像
选择选项4，将"nginx:latest"标记为"registry.example.com/nginx:latest"

# 4. 登录仓库
选择选项6，登录到"registry.example.com"

# 5. 推送镜像
选择选项5，推送"registry.example.com/nginx:latest"
```

## 🏗️ Harbor推送工具

### 脚本路径
`scripts/containers/harbor-push.sh`

### 功能说明

Harbor是企业级Docker镜像仓库，提供：

1. **权限管理**：基于角色的访问控制
2. **镜像扫描**：安全漏洞扫描
3. **镜像签名**：内容信任和签名
4. **复制策略**：多仓库同步
5. **审计日志**：完整的操作审计

### 使用方法

```bash
# 直接执行
bash <(curl -sSL https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/scripts/containers/harbor-push.sh)
```

## 🔧 Docker镜像源配置

### 脚本路径
`scripts/containers/docker-mirrors.sh`

### 功能说明

独立的Docker镜像源配置脚本，用于：

1. **加速下载**：配置国内镜像源
2. **网络优化**：优化网络连接设置
3. **缓存配置**：配置本地缓存策略

### 使用方法

```bash
# 直接执行
bash <(curl -sSL https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/scripts/containers/docker-mirrors.sh)
```

## 🔧 高级配置

### 自定义Docker配置

编辑Docker daemon配置文件：

```bash
# 编辑配置文件
sudo nano /etc/docker/daemon.json

# 示例配置
{
  "registry-mirrors": [
    "https://your-mirror.com"
  ],
  "insecure-registries": [
    "your-registry.com:5000"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}

# 重启Docker服务
sudo systemctl restart docker
```

### Docker Compose配置

创建docker-compose.yml文件：

```yaml
version: '3.8'

services:
  web:
    image: nginx:latest
    ports:
      - "80:80"
    volumes:
      - ./html:/usr/share/nginx/html
    restart: unless-stopped

  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: password
      MYSQL_DATABASE: myapp
    volumes:
      - db_data:/var/lib/mysql
    restart: unless-stopped

volumes:
  db_data:
```

### 环境变量配置

支持通过环境变量自定义安装行为：

```bash
# 跳过用户确认
export AUTO_INSTALL=true

# 自定义镜像源
export DOCKER_MIRROR="https://your-mirror.com"

# 跳过Docker Compose安装
export SKIP_COMPOSE=true

# 跳过LazyDocker安装
export SKIP_LAZYDOCKER=true

# 执行安装
./scripts/containers/docker-install.sh
```

## 📝 使用技巧

### Docker常用命令

```bash
# 容器管理
docker run -d --name myapp nginx:latest  # 运行容器
docker ps                                # 查看运行中的容器
docker ps -a                            # 查看所有容器
docker stop myapp                       # 停止容器
docker start myapp                      # 启动容器
docker restart myapp                    # 重启容器
docker rm myapp                         # 删除容器

# 镜像管理
docker images                           # 查看镜像
docker pull nginx:latest               # 拉取镜像
docker tag nginx:latest myregistry/nginx:latest  # 标记镜像
docker push myregistry/nginx:latest    # 推送镜像
docker rmi nginx:latest                # 删除镜像

# 系统管理
docker system df                        # 查看磁盘使用
docker system prune                     # 清理未使用的资源
docker logs myapp                       # 查看容器日志
docker exec -it myapp bash             # 进入容器
```

### Docker Compose常用命令

```bash
# 项目管理
docker-compose up -d                    # 启动项目
docker-compose down                     # 停止项目
docker-compose restart                  # 重启项目
docker-compose logs                     # 查看日志
docker-compose ps                       # 查看服务状态

# 服务管理
docker-compose up -d web                # 启动特定服务
docker-compose scale web=3              # 扩展服务
docker-compose exec web bash            # 进入服务容器
```

### LazyDocker使用

```bash
# 启动LazyDocker
lazydocker

# 快捷键
# j/k: 上下移动
# Enter: 进入详情
# d: 删除
# r: 重启
# l: 查看日志
# e: 进入容器
# q: 退出
```

## 🔧 故障排除

### 常见问题

#### Docker安装失败
```bash
# 检查系统版本
lsb_release -a

# 手动添加仓库
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io
```

#### Docker服务启动失败
```bash
# 检查服务状态
sudo systemctl status docker

# 查看详细日志
sudo journalctl -u docker.service

# 重启服务
sudo systemctl restart docker
```

#### 权限问题
```bash
# 添加用户到docker组
sudo usermod -aG docker $USER

# 重新登录或执行
newgrp docker

# 测试权限
docker run hello-world
```

#### 镜像拉取失败
```bash
# 检查镜像源配置
cat /etc/docker/daemon.json

# 重新配置镜像源
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn"
  ]
}
EOF

# 重启Docker
sudo systemctl restart docker
```

### 性能优化

#### 存储优化
```bash
# 清理未使用的资源
docker system prune -a

# 配置存储驱动
sudo nano /etc/docker/daemon.json
# 添加：
{
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
```

#### 网络优化
```bash
# 配置DNS
sudo nano /etc/docker/daemon.json
# 添加：
{
  "dns": ["8.8.8.8", "8.8.4.4"]
}
```

## 🔗 相关链接

- [Docker官方文档](https://docs.docker.com/)
- [Docker Compose文档](https://docs.docker.com/compose/)
- [Harbor项目](https://goharbor.io/)
- [LazyDocker项目](https://github.com/jesseduffield/lazydocker)
- [Docker Hub](https://hub.docker.com/)
