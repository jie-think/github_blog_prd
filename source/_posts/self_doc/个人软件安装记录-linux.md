---
title: 个人软件安装记录(linux-ubuntu)
date: 2018-09-04 09:51:07
tags:
 - tools安装
---


```sh
apt-get install -y git

apt-get install -y tree

apt-get install -y wget

## zsh
sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"

## zsh config
plugins=(
  git
  z
  wd
  zsh-autosuggestions
  docker
  docker-compose
)

## zsh install zsh-autosuggestions
git clone git://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions

## 持续增加中...
```

