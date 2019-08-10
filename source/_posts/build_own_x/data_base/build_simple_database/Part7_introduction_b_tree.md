---
title: Part 6 - B树介绍
date: 2019-02-03 18:08:34
categories:
- build-own-x
tags:
- database
- db原理
---

# 介绍 B 树

B树在SQLite中同时代表了表和索引, 这是一个非常棒的idea. 这一篇文章仅仅介绍数据结构, 所以不涉及代码的改动.

为什么 B 树对于数据库是一个非常棒的结构.
- 搜索一部分内容非常快(时间复杂度是 log 基本)
- 插入和删除一个值你也会发现相等的快(重新平衡是常数时间).
- 便利一个范围的数据也是非常快(当然不能和 map 比).

B 树不像二叉树, B树的 "B"可能代表发现者的名称, 但是也有平衡的意思.下图是一个 B 树的例子:
![example B-Tree](https://cstack.github.io/db_tutorial/assets/images/B-tree.png)
example B-Tree (https://en.wikipedia.org/wiki/File:B-tree.svg)

不像二叉树, B树的每个节点可以有 m 个孩子, 这里 m 叫树的 "order". 为了保证树尽可能的平衡, 我们不得不控制节点个数在 m/2 的数量下.

一些例外:
- 叶子节点有0个孩子
- 根节点可能可能有少于 m 个节点,但是至少是有两个的
- 如果根节点是一个叶子节点,他就会有0个孩子.


上图是一个B树,在 Sqlite 中被用于存储索引, 为了存储表数据 Sqlite 用了一个 B+ 树.

title |  B-tree   | B+ tree
 ------ | ------- | ------
Pronounced | “Bee Tree” | “Bee Plus Tree”
Used to store | Indexes | Tables
Internal nodes store keys | Yes | Yes
Internal nodes store values | Yes | No
Number of children per node | Less | More
Internal nodes vs. leaf nodes | Same structure | Different structure

在我们开始实现索引之前，我将仅讨论B +树，但我只是将其称为B树或b树

带子节点的节点称为“内部”节点。内部节点和叶节点的结构不同：

For an order-m tree… |  Internal Node   | Leaf Node
 ------ | ------- | ------
Stores | keys and pointers to children | keys and values
Number of keys | up to m-1 | as many as will fit
Number of pointers | number of keys + 1 | none
Number of values | none | number of keys
Key purpose | used for routing | paired with value
Stores values? | No | Yes

让我们通过一个例子来看下B树在插入元素后是如何增长的. 为了简单, 树的 `order` 是3. 这也意味着: 
- 每个内部节点最多有三个孩子
- 每一个内部节点最多两个键.
- 每个内部节点至少有2个子节点
- 每个内部节点至少有一个key

一个空的B树就一个单节点: 根节点. 根节点开始于叶子接口存在0个键值对:
![empty btree](https://cstack.github.io/db_tutorial/assets/images/btree1.png)
empty btree

如果我们插入一个键值对, 它们将按顺序存储在叶子节点中.

![one-node btree](https://cstack.github.io/db_tutorial/assets/images/btree2.png)
one-node btree


假设叶节点的容量是两个键/值对。当我们插入另一个时，我们必须拆分叶节点并在每个节点中放置一半对。两个节点都成为新内部节点的子节点，现在它将成为根节点。

![two-level btree](https://cstack.github.io/db_tutorial/assets/images/btree3.png)
two-level btree

内部节点有1个键和2个指向子节点的指针。如果我们想要查找小于或等于5的键，我们会查看左边的孩子。如果我们想要查找大于5的密钥，我们会找到合适的孩子。
![](https://cstack.github.io/db_tutorial/assets/images/btree4.png)