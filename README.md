## 一键部署zsh和主题和插件

```shell
bash <(curl -sSL https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/zsh/init-for-zsh-auto.sh)
````

````shell
# 国内源
bash <(curl -sSL https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/zsh/init-for-zsh-auto-gitee.sh)
````

```shell
# arm-openwrt版本的zsh
bash <(curl -sSL https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/refs/heads/main/zsh/zsh-arm.sh)
```

```shell
# 格式化TF卡
bash <(curl -sSL https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/refs/heads/main/zsh/formatter.sh)
```

## 设置ssh基础设置

```shell
bash <(curl -sSL https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/zsh/ssh-config-auto.sh)

```

## 安装nvim,lazynvim,astronvim,lazygit插件

```shell
bash <(curl -sSL https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/zsh/nvim-auto.sh)
```

## 自动生成sshkey,并将公钥添加到指定的服务器

```shell
bash <(curl -sSL https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/zsh/ssh-agent-auto.sh)
```

## 转移推送docker/harbor镜像

```shell
#docker
curl -o docker-push-auto.sh \
https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/docker/docker-push-auto.sh \
&& chmod +x docker-push-auto.sh && ./docker-push-auto.sh
```

```shell
#harbor
curl -o harbor-push-auto.sh \
https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/docker/harbor-push-auto.sh \
&& chmod +x harbor-push-auto.sh && ./harbor-push-auto.sh
```

## 更换软件源

```shell
bash <(curl -sSL https://gitee.com/SuperManito/LinuxMirrors/raw/main/ChangeMirrors.sh)
```

## Docker 一键安装脚本

```shell
bash <(curl -sSL https://gitee.com/SuperManito/LinuxMirrors/raw/main/DockerInstallation.sh)
# 安装lazydocker
curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
```
## Docker 添加国内源

```shell
bash <(curl -sSL https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/refs/heads/main/docker/docker-source-zh)
```
