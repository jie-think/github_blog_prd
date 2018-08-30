---
title: redis ops learn
date: 2018-08-29 21:07:26
categories:
- backend
tags:
- go
- redis
---
## 连接测试

```go

package main

import (
	"github.com/go-redis/redis"
	"fmt"
	"log"
)

func main() {
	client := redis.NewClient(&redis.Options{
		Addr: "localhost:6379",
		Password: "",      //默认空密码
		DB: 0,             //使用默认数据库
	})

	defer client.Close()       //最后关闭

	pong, err := client.Ping().Result()
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println("Connected result: ", pong)
}

```

## ops: strings

```go
// ops: strings
//// set
client.Set("hello", "hello redis",0) //忽略错误

//// get string
str := client.Get("hello")
fmt.Println(str)

//// del string
client.Del("strtest")
```

## ops: lists

```go
// ops: lists
//// push
client.LPush("list","one","two","three") //rpush则在尾部插入

//// rm, pop
client.LRem("list",2,"three") //删除list中前2个value为 ‘three’的元素
client.LPop("list") //删除头部的值，同理RPop删除尾部的值。

// range
list, _ := client.LRange("list", 0, 2).Result()
fmt.Println("List: ", list)
```

## ops: hashes

```go
// hashes
//// set
user := make(map[string]interface{})
user["name"] = "jim"
user["gender"] = "man"
user["age"] = 23
client.HMSet("user",user)

//// set
client.HSet("user", "name","tom")

//// get
name := client.HGet("user","name")
fmt.Print(name)

//// getAll
hash, _ := client.HGetAll("user").Result()
for k, v:= range hash{
	fmt.Printf("key: %v, value: %v ",k, v)
}
```

参考: https://www.jianshu.com/p/4045a3721b3c