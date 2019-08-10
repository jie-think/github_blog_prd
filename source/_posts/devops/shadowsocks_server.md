---
title: 搭建 shadowsocks 服务器
date: 2018-12-07 15:28:31
categories:
- devops
tags:
- shadowsocks 服务器
---

## install

```
apt-get install python-pip
pip install shadowsocks
```



## start service

```shell
ssserver -p 443 -k password -m rc4-md5
```

如果要后台运行：

```shell
sudo ssserver -p 443 -k password -m rc4-md5 --user nobody -d start
```

如果要停止：

```shell
sudo ssserver -d stop
```

如果要检查日志：

```sh
sudo less /var/log/shadowsocks.log
```





### 启动示例

```sh
ssserver -p 8837 -k passwd --user nobody -d start
```

