# SecClient  安全客户端
# 安全客户端一键安装脚本
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/TLSminer/SecClient/main/seclient.sh)"
```



# WIN版下载地址
[win版安全客户端.rar](https://github.com/TLSminer/SecClient/blob/main/win%E7%89%88%E5%AE%89%E5%85%A8%E5%AE%A2%E6%88%B7%E7%AB%AF.rar)

开启服务
```bash
systemctl start seclient
```

重启服务
```bash
systemctl restart seclient
```
停止服务
```bash
systemctl stop seclient
```
安装好程序以后先执行开启服务命令 systemctl start seclient 然后 访问IP网页进行配置端口为21112  http://ip:21112
(openwrt系统 systemctl命令无效，须要用安装脚本菜单启动程序)



矿机连接 stratum+tcp://本地客户端IP:端口  

例：stratum+tcp://192.168.1.254:19001


适用于矿场，破解宽带运营商的连接数限制，数据加密更安全
