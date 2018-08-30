---
title: supervisor 使用
date: 
categories:
- devops
tags:
- supervisor
---


### install

```sh
apt-get install -y supervisor
```



### 启动命令

```sh
/usr/bin/python /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
```



### 配置

安装完后的默认配置 `/etc/supervisor/supervisord.conf`

```conf
; supervisor config file

[unix_http_server]
file=/var/run/supervisor.sock   ; (the path to the socket file)
chmod=0700                       ; sockef file mode (default 0700)

[supervisord]
logfile=/var/log/supervisor/supervisord.log ; (main log file;default $CWD/supervisord.log)
pidfile=/var/run/supervisord.pid ; (supervisord pidfile;default supervisord.pid)
childlogdir=/var/log/supervisor            ; ('AUTO' child log dir, default $TEMP)
environment=IPADDRESS="172.16.6.6", HOST_NAME="i-nom0vro7"

; the below section must remain in the config file for RPC
; (supervisorctl/web interface) to work, additional interfaces may be
; added by defining them in separate rpcinterface: sections
[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[supervisorctl]
serverurl=unix:///var/run/supervisor.sock ; use a unix:// URL  for a unix socket

; The [include] section can just contain the "files" setting.  This
; setting can list multiple files (separated by whitespace or
; newlines).  It can also contain wildcards.  The filenames are
; interpreted as relative to this file.  Included files *cannot*
; include files themselves.

[include]
files = /etc/supervisor/conf.d/*.conf
```



需要监控的进程

- consul 微服务守护进程
- coupon_web 守护进程
- coupon_gateway 守护进程
- coupon_trig 守护进程
- coupon_bot 守护进程



配置如下: (在 conf.d 目录下)

##### consul 守护进程:
```conf
[program:consul] ; 程序名称，在 supervisorctl 中通过这个值来对程序进行一系列的操作
autorestart=True      ; 程序异常退出后自动重启
autostart=True        ; 在 supervisord 启动的时候也自动启动
redirect_stderr=True  ; 把 stderr 重定向到 stdout，默认 false
command=consul agent -data-dir /data/consul -node=common-conpous.0.13 -bind=172.16.0.13 -join=172.16.0.210 1>/data/logs/out.log 2>&1  ; 启动命令，与手动在命令行启动的命令是一样的
user=root           ; 用哪个用户启动
directory=/data/caiqiu  ; 程序的启动目录
stdout_logfile_maxbytes = 20MB  ; stdout 日志文件大小，默认 50MB
stdout_logfile_backups = 20     ; stdout 日志文件备份数
; stdout 日志文件，需要注意当指定目录不存在时无法正常启动，所以需要手动创建目录（supervisord 会自动创建日志文件）
stdout_logfile = /data/logs/supervisord_consul.log
```

##### coupon_web 守护进程:
```conf
[program:coupon_web] ; 程序名称，在 supervisorctl 中通过这个值来对程序进行一系列的操作
autorestart=True      ; 程序异常退出后自动重启
autostart=True        ; 在 supervisord 启动的时候也自动启动
redirect_stderr=True  ; 把 stderr 重定向到 stdout，默认 false
command=java -jar -Xms512m -Xmx1024m /data/common-coupon/aries-coupon-web-1.0.0-SNAPSHOT.jar --server.port=8080 --server.address=172.16.0.13 --spring.profiles.active=dev --server.tomcat.max-thread=500
user=root           ; 用哪个用户启动
directory=/data/caiqiu  ; 程序的启动目录
stdout_logfile_maxbytes = 20MB  ; stdout 日志文件大小，默认 50MB
stdout_logfile_backups = 20     ; stdout 日志文件备份数
; stdout 日志文件，需要注意当指定目录不存在时无法正常启动，所以需要手动创建目录（supervisord 会自动创建日志文件）
stdout_logfile=/data/logs/supervisord_coupon_web.log
```

##### coupon_gateway 守护进程:
```conf
[program:coupon_gateway] ; 程序名称，在 supervisorctl 中通过这个值来对程序进行一系列的操作
autorestart=True      ; 程序异常退出后自动重启
autostart=True        ; 在 supervisord 启动的时候也自动启动
redirect_stderr=True  ; 把 stderr 重定向到 stdout，默认 false
command=java -jar -Xms512m -Xmx1024m /data/common-coupon/aries-coupon-gateway-1.0.0-SNAPSHOT.jar --server.port=9090 --server.address=172.16.0.13 --spring.profiles.active=dev --server.tomcat.max-thread=500
user=root           ; 用哪个用户启动
directory=/data/caiqiu  ; 程序的启动目录
stdout_logfile_maxbytes = 20MB  ; stdout 日志文件大小，默认 50MB
stdout_logfile_backups = 20     ; stdout 日志文件备份数
; stdout 日志文件，需要注意当指定目录不存在时无法正常启动，所以需要手动创建目录（supervisord 会自动创建日志文件）
stdout_logfile=/data/logs/supervisord_coupon_gateway.log
```

##### coupon_trig 守护进程:
```conf
[program:coupon_trig] ; 程序名称，在 supervisorctl 中通过这个值来对程序进行一系列的操作
autorestart=True      ; 程序异常退出后自动重启
autostart=True        ; 在 supervisord 启动的时候也自动启动
redirect_stderr=True  ; 把 stderr 重定向到 stdout，默认 false
command=java -jar -Xms512m -Xmx1024m /data/common-coupon/aries-coupon-trig-1.0.0-SNAPSHOT.jar --server.port=8090 --server.address=172.16.0.13 --spring.profiles.active=dev --server.tomcat.max-thread=500
user=root           ; 用哪个用户启动
directory=/data/caiqiu  ; 程序的启动目录
stdout_logfile_maxbytes = 20MB  ; stdout 日志文件大小，默认 50MB
stdout_logfile_backups = 20     ; stdout 日志文件备份数
; stdout 日志文件，需要注意当指定目录不存在时无法正常启动，所以需要手动创建目录（supervisord 会自动创建日志文件）
stdout_logfile=/data/logs/supervisord_coupon_trig.log
```

##### coupon_bot 守护进程:
```conf
[program:coupon_bot] ; 程序名称，在 supervisorctl 中通过这个值来对程序进行一系列的操作
autorestart=True      ; 程序异常退出后自动重启
autostart=True        ; 在 supervisord 启动的时候也自动启动
redirect_stderr=True  ; 把 stderr 重定向到 stdout，默认 false
command=java -jar -Xms512m -Xmx1024m /data/common-coupon/aries-coupon-bot-1.0.0-SNAPSHOT.jar --spring.profiles.active=dev --server.tomcat.max-thread=500
user=root           ; 用哪个用户启动
directory=/data/caiqiu  ; 程序的启动目录
stdout_logfile_maxbytes = 20MB  ; stdout 日志文件大小，默认 50MB
stdout_logfile_backups = 20     ; stdout 日志文件备份数
; stdout 日志文件，需要注意当指定目录不存在时无法正常启动，所以需要手动创建目录（supervisord 会自动创建日志文件）
stdout_logfile=/data/logs/supervisord_coupon_bot.log
```


#### supervisorctl 命令

```sh
supervisorctl status  # 查看 supervisorctl 的状态
# account_gateway                  RUNNING    pid 22892, uptime 1 day, 19:17:42
# account_web                      RUNNING    pid 22912, uptime 1 day, 19:17:41
# consul                           RUNNING    pid 22849, uptime 1 day, 19:17:51

supervisorctl reload  # 重新载入 supervisorctl 配置, 并且使其生效

supervisorctl help    # 帮助文档
# default commands (type help <topic>):
# =====================================
# add    clear  fg        open  quit    remove  restart   start   stop  update
# avail  exit   maintail  pid   reload  reread  shutdown  status  tail  version
```





