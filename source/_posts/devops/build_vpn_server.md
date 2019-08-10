---
title: 搭建 vpn 服务器
date: 2018-12-03 22:33:29
categories:
- devops
tags:
- vpn 服务器
---

## Setp1. install OpenVPN

```sh
$ sudo apt-get update
$ sudo apt-get install openvpn easy-rsa
```

## Setp2. 构建 CA(certificate authority) 目录

使用`make-cadir`拷贝`easy-rsa` 的模板.

```sh
$ make-cadir ~/openvpn-ca
```



## Setp3.  配置 CA 变量

`~/openvpn-ca/vars` 自己喜欢填啥就填啥吧, 不可以空着就是了

```sh
. . .
export KEY_NAME="server" # 服务器的名字

export KEY_COUNTRY="US"
export KEY_PROVINCE="CA"
export KEY_CITY="SanFrancisco"
export KEY_ORG="Fort-Funston"
export KEY_EMAIL="me@myhost.mydomain"
export KEY_OU="MyOrganizationalUnit"

. . .
```

## Setp4. Build the Certificate Authority

```sh
$ cd ~/openvpn-ca
$ source vars
$ ./clean-all	# 确保干净的环境中操作
$ ./build-ca	# 构建CA
```

## Setp5.  创建服务器证书,key和加密文件

```sh
$ ./build-key-server server
$ ./build-dh
$ openvpn --genkey --secret keys/ta.key
```

## Setp6. 创建客户端的证书和key pair

```sh
$ ./build-key client1 # 不需要密码版
$ ./build-key-pass client1 # 需要密码版
```

## Setp7. 配置 OpenVPN 服务

### Copy the Files to the OpenVPN Directory

```sh
cd ~/openvpn-ca/keys
sudo cp ca.crt server.crt server.key ta.key dh2048.pem /etc/openvpn
# 拷贝 vpn 服务器
gunzip -c /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz | sudo tee /etc/openvpn/server.conf
```

### 调整 OpenVPN 的配置

**Basic Configuration**

`vi /etc/openvpn/server.conf`

```sh
tls-auth ta.key 0 # This file is secret
key-direction 0

cipher AES-128-CBC

auth SHA256

user nobody
group nogroup

push "redirect-gateway def1 bypass-dhcp"

push "dhcp-option DNS 208.67.222.222"
push "dhcp-option DNS 208.67.220.220"

port 443
proto tcp

cert server.crt
key server.key
```

## Setp8. 调整网络的服务配置

`vi /etc/sysctl.conf`

```sh
net.ipv4.ip_forward=1
```



### Adjust the UFW Rules to Masquerade Client Connections

防火墙先不考虑



## Setp9. 开始 OpenVPN 服务器

```sh
systemctl start openvpn@server
systemctl status openvpn@server
```

## Setp10. 创建客户端的配置和基础设施

### Creating the Client Config Directory Structure

```sh
mkdir -p ~/client-configs/files
chmod 700 ~/client-configs/files
```

### Creating a Base Configuration

```sh
cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf ~/client-configs/base.conf
```

编辑`~/client-configs/base.conf`文件

```text
remote {server_IP_address} {1194}

proto udp

user nobody
group nogroup

ca ca.crt
cert client.crt
key client.key

cipher AES-128-CBC
auth SHA256

key-direction 1

# script-security 2
# up /etc/openvpn/update-resolv-conf
# down /etc/openvpn/update-resolv-conf
```

### Creating a Configuration Generation Script

`vi ~/client-configs/make_config.sh`

内容如下:

```sh
#!/bin/bash

# First argument: Client identifier

KEY_DIR=~/openvpn-ca/keys
OUTPUT_DIR=~/client-configs/files
BASE_CONFIG=~/client-configs/base.conf

cat ${BASE_CONFIG} \
    <(echo -e '<ca>') \
    ${KEY_DIR}/ca.crt \
    <(echo -e '</ca>\n<cert>') \
    ${KEY_DIR}/${1}.crt \
    <(echo -e '</cert>\n<key>') \
    ${KEY_DIR}/${1}.key \
    <(echo -e '</key>\n<tls-auth>') \
    ${KEY_DIR}/ta.key \
    <(echo -e '</tls-auth>') \
    > ${OUTPUT_DIR}/${1}.ovpn
```

```sh
chmod 700 ~/client-configs/make_config.sh
```



## Step 11: Generate Client Configurations

```sh
cd ~/client-configs
./make_config.sh client1
ls ~/client-configs/files
```

**将文件拷贝到目标系统中**











参考: https://www.digitalocean.com/community/tutorials/how-to-set-up-an-openvpn-server-on-ubuntu-16-04