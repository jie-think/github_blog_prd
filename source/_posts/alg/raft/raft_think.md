---
title: 关于 Raft 的 think
date: 2018-12-10 19:54:15
categories:
- alg
tags:
- raft think
---

## 日志复制问题

由 leader 发送日志给 follower 

心跳和日志拷贝是在一起的.

TK: 日志复制的二段提交问题????

日志复制是二段提交的: 发送日志给各个 follower, 超过一半的 follower 接收成功了, 就发起一个 commit 提交.



如果leader的任期到期后会自动转换成 follower 等待下次选举的开始.

应该做个时序图??









