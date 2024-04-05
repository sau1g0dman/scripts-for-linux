## 一键部署zsh和主题和插件
```shell
# install ohmyzsh and theme and plugins
curl -o init-for-zsh-auto.sh https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/zsh/init-for-zsh-auto.sh && chmod +x init-for-zsh-auto.sh && ./init-for-zsh-auto.sh

#自动生成sshkey,并将公钥添加到指定的服务器
curl -o ssh-agent-auto.sh https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/ssh/ssh-agent-auto.sh && chmod +x ssh-agent-auto.sh && ./ssh-agent-auto.sh
```

```
## 更换软件源
```shell
bash <(curl -sSL https://gitee.com/SuperManito/LinuxMirrors/raw/main/ChangeMirrors.sh)
```
## Docker 一键安装脚本
```shell
bash <(curl -sSL https://gitee.com/SuperManito/LinuxMirrors/raw/main/DockerInstallation.sh)
```
