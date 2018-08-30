---
title: grpc start learn
date: 2018-08-29 20:21:53
categories:
- backend
tags:
- go
- grpc 
---
# ex helloworld start

## 基本流程

建立流程:
1. 建 proto3 文件, 定义 service
2. service 开发
3. client 开发


## 1. proto 文件

```go
// The greeting service definition.
service Greeter {
  // Sends a greeting
  rpc SayHello (HelloRequest) returns (HelloReply) {}
}

// The request message containing the user's name.
message HelloRequest {
  string name = 1;
}

// The response message containing the greetings
message HelloReply {
  string message = 1;
}
```

定义了一个 service Greeter , 参数: SayHello, return: HelloReply

## 2. service 开发

```go
const (
	port = ":50051"
)

// server is used to implement helloworld.GreeterServer.
type server struct{}

// 实现 helloworld.GreeterServer 方法
// SayHello implements helloworld.GreeterServer
func (s *server) SayHello(ctx context.Context, in *pb.HelloRequest) (*pb.HelloReply, error) {
	return &pb.HelloReply{Message: "Hello " + in.Name}, nil
}

func main() {
	lis, err := net.Listen("tcp", port)         // 开启监听
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}
	s := grpc.NewServer()                       // 建一个 grpc Server
	pb.RegisterGreeterServer(s, &server{})      // 将 RegisterGreeterServer 服务绑定到 grpc 上
	// Register reflection service on gRPC server.
	reflection.Register(s)                      // 将服务注册到 rpc 上
	if err := s.Serve(lis); err != nil {        // s.Serve(lis) 是将 grpc 服务绑定监听端口
		log.Fatalf("failed to serve: %v", err)
	}
}
```
流程:
> 1. 开一个监听端口
> 2. 建立一个 rpc 服务
> 3. 将服务绑定到 rpc 上
> 4. 将服务注册到 rpc 上
> 5. 绑定 grpc 服务 和 端口监听



## 3. client 使用 grpc 服务

```go
package main

import (
	"log"
	"os"
	"time"

	"golang.org/x/net/context"
	"google.golang.org/grpc"
	pb "google.golang.org/grpc/examples/helloworld/helloworld"
)

const (
	address     = "localhost:50051"
	defaultName = "jie"
)

func main() {
	// Set up a connection to the server.
	conn, err := grpc.Dial(address, grpc.WithInsecure()) // 创建客户端
	if err != nil {
		log.Fatalf("did not connect: %v", err)
	}
	defer conn.Close()                                  // 延迟关闭连接
	c := pb.NewGreeterClient(conn)                      // 新建一个Greeter连接客户端

	// Contact the server and print out its response.
	name := defaultName
	if len(os.Args) > 1 {
		name = os.Args[1]
	}
	ctx, cancel := context.WithTimeout(context.Background(), time.Second) // 设置超时 时间
	defer cancel()
	r, err := c.SayHello(ctx, &pb.HelloRequest{Name: name}) // 使用客户端调用远程方法
	if err != nil {
		log.Fatalf("could not greet: %v", err)
	}
	log.Printf("Greeting: %s", r.Message)
}
```

流程: 
> 1. 创建客户端
> 2. 新建一个Greeter连接客户端
> 3. 设置超时 时间
> 4. 使用客户端调用远程方法
> 5. cloes客户端连接 and cancel()


总结:



