---
title: docker 构建最小 go app
date: 2018-08-30 13:56:07
categories:
- backend
tags:
- docker
- docker app
---

参考: [https://blog.codeship.com/building-minimal-docker-containers-for-go-applications/](https://blog.codeship.com/building-minimal-docker-containers-for-go-applications/)

## 写应用

```go
package main

import (
    "fmt"
    "io/ioutil"
    "net/http"
    "os"
)

func main() {
    resp, err := http.Get("http://www.baidu.com")
    check(err)
    body, err := ioutil.ReadAll(resp.Body)
    check(err)
    fmt.Println(len(body))
}

func check(err error) {
    if err != nil {
        fmt.Println(err)
        os.Exit(1)
    }
}
```

## Dockerize

basic image

```dockerfile
FROM golang:onbuild
```

compile Dockerfile

```Dockerfile
FROM golang:latest 
RUN mkdir /app 
ADD . /app/ 
WORKDIR /app 
RUN go build -o main . 
CMD ["/app/main"]
```

这个构建出来需要500M

因为 `golang:latest` 是从 `Debian Jessie` 构建出来的, 底层是操作系统, so 导致镜像特别大.

## Compile!!

1. 先编译工程
2. 构建镜像

```sh
go build -o main .
docker build -t example-scratch:v1 -f Dockerfile.scratch .
```

Dockerfile.scratch 内容:
```Dockerfile
FROM scratch
ADD main /
CMD ["/main"]
```

这样构建是无法工作的, 原因就在于生产的 main 是需要系统的动态链接库.

```sh
$ docker run -it example-scratch:v1
standard_init_linux.go:178: exec user process caused "exec format error" 
```

解决方法:

```sh
CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .
```
禁用cgo，生产一个静态二进制文件, 我们还将操作系统设置为Linux, -a标志意味着重建我们正在使用的所有软件包，这意味着所有导入都将在cgo禁用的情况下重建。

```sh
$ docker build -t example-scratch:v2 -f Dockerfile.scratch .
$ docker run -it example-scratch:v2
  118146 # it work
```


