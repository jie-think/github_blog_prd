---
title: Let's Build a Simple Database
date: 2019-01-26 16:11:20
categories:
- build-own-x
tags:
- database
- db原理
---

# Let's Build a Simple Database

原文: https://cstack.github.io/db_tutorial/

从 C 重新开始写 Sqlite

## 数据库是如何工作的?

- 在内存和磁盘上, 数据保存的格式是啥?
- 什么时候会从内存中移动到硬盘上?
- 为什么每个表仅有一个主键呢?
- 事务回滚是如何工作的呢?
- 索引是如何格式化? FIXME(Jx)  (How are indexes formatted?)
- 啥时候全表扫描会发生呢?
- 保存前的预准备格式是啥样的呢? FIXME(Jx) (What format is a prepared statement saved in?)

总而言之, 数据库是如何工作的呢?

为了理解这个, 我将会用 C 重新构建一个 Sqlite , 并且会记录其过程.

## 目录

- Part 1 - 介绍和设置 REPL
- Part 2 - 世上最简单的 SQL 编译器和虚拟机
- Part 3 - 一个在内存, 仅追加的 单表数据库
- Part 4 - 第一个单元测试类(和一些Bugs)
- Part 5 - 持久化到硬盘
- Part 6 - 游标的抽象化
- Part 7 - 介绍 B 树
- Part 8 - B 树叶子接口格式化
- Part 9 - 二分查找和重复键
- Part 10 - 拆分叶子节点
- Part 11 - 递归搜索 B 树
- Part 12 - 扫描多层级的 B 树
- Part 13 - 拆分后更新父节点

> “What I cannot create, I do not understand.” – [Richard Feynman](https://en.m.wikiquote.org/wiki/Richard_Feynman)

### Sqlite 架构图
![Sqlite 架构图](https://cstack.github.io/db_tutorial/assets/images/arch2.gif)

Sqlite 架构图: https://www.sqlite.org/arch.html

