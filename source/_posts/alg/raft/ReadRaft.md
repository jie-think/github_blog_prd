---
titile: learn raft
date: 2018-12-09 22:31:08
categories:
- alg
tags:
- raft learn
---

参考: https://github.com/shishujuan/mit6.824-2017-raft.git



`raft.go @Make`

1. 初始化 rf

```go
state=Follower // 初始化成 Folloer

rf.heartbeatInterval = time.Duration(HeartbeatInterval) * time.Millisecond // 50 ms
```



2. 启动 bot

```go
electionTimeout := getRandomElectionTimeout() // 范围 {300 + [0,100)}ms

switch state {
    case Follower:
        select {
        case <-rf.appendEntryCh: // 不用去处理接收的日志吗?
        case <-rf.grantVoteCh:   // ??
        case <-time.After(electionTimeout): // 选举超时, Follower -> Candidate
            rf.mu.Lock()
            rf.convertToCandidate()
            rf.mu.Unlock()
        }
    case Candidate:
        go rf.leaderElection() // 1. 发起选举
        select {
        case <-rf.appendEntryCh:
        case <-rf.grantVoteCh:
        case <-rf.leaderCh:
        case <-time.After(electionTimeout):
            rf.mu.Lock()
            rf.convertToCandidate() // 选举超时, 重新开始选举
            rf.mu.Unlock()
        }
    case Leader:
        rf.startAppendEntries() // 开始去追加日志
        time.Sleep(rf.heartbeatInterval) // 心跳间隙
}
```











