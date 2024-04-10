## 一键部署zsh和主题和插件
```shell
curl -o init-for-zsh-auto.sh https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/zsh/init-for-zsh-auto.sh && chmod +x init-for-zsh-auto.sh && ./init-for-zsh-auto.sh
````
## 设置ssh基础设置
```shell
curl -o ssh-base-auto.sh https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/zsh/ssh-config-auto.sh && chmod +x ssh-base-auto.sh && ./ssh-base-auto.sh
```
## 自动生成sshkey,并将公钥添加到指定的服务器
```shell
curl -o ssh-agent-auto.sh https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/zsh/ssh-agent-auto.sh && chmod +x ssh-agent-auto.sh && ./ssh-agent-auto.sh
```
## 转移推送docker镜像
```shell
curl -o docker-push-auto.sh https://raw.githubusercontent.com/sau1g0dman/scripts-for-linux/main/docker/docker-push-auto.sh && chmod +x docker-push-auto.sh && ./docker-push-auto.sh
```


## 更换软件源
```shell
bash <(curl -sSL https://gitee.com/SuperManito/LinuxMirrors/raw/main/ChangeMirrors.sh)
```
## Docker 一键安装脚本
```shell
bash <(curl -sSL https://gitee.com/SuperManito/LinuxMirrors/raw/main/DockerInstallation.sh)
```
