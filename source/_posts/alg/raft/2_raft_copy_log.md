---
​---
titile: raft log copy
date: 2018-12-22 11:56:59
categories:
- raft
tags:
- raft learn
​---
---

## 总体分为两个过程

### 接受命令的过程：

1. 领导者接受客户端请求；
2. 领导者把指令追加到日志；
3. 发送AppendEntries RPC到追随者；
4. 领导者收到大多数追随者的确认后，领导者Commit该日志，把日志在状态机中回放，并返回结果给客户端；

### 提交过程：

1. 在下一个心跳阶段，领导者再次发送AppendEntries RPC给追随者，日志已经commited；
2. 追随者收到Commited日志后，将日志在状态机中回放。

 

 

 

 

 