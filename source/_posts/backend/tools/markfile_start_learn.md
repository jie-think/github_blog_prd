---
title: markfile start learn
date: 2018-09-01 15:37:28
categories:
- backend
tags:
- markdown
- build tools
---

参考: [https://www.cnblogs.com/wang_yb/p/3990952.html](https://www.cnblogs.com/wang_yb/p/3990952.html)

## Makefile 简介

Makefile 是和 make 命令一起配合使用的.

很多大型项目的编译都是通过 Makefile 来组织的, 如果没有 Makefile, 那很多项目中各种库和代码之间的依赖关系不知会多复杂.

Makefile的组织流程的能力如此之强, 不仅可以用来编译项目, 还可以用来组织我们平时的一些日常操作. 这个需要大家发挥自己的想象力.


### Makefile 主要的 5个部分 (显示规则, 隐晦规则, 变量定义, 文件指示, 注释)

Makefile基本格式如下:

```makefile
target ... : prerequisites ...
    command
    ...
    ...
```
其中,
- target        - 目标文件, 可以是 Object File, 也可以是可执行文件
- prerequisites - 生成 target 所需要的文件或者目标
- command       - make需要执行的命令 (任意的shell命令), Makefile中的命令必须以 `[tab] 开头`

1. 显示规则 :: 说明如何生成一个或多个目标文件(包括 生成的文件, 文件的依赖文件, 生成的命令)
2. 隐晦规则 :: make的自动推导功能所执行的规则
3. 变量定义 :: Makefile中定义的变量
4. 文件指示 :: Makefile中引用其他Makefile; 指定Makefile中有效部分; 定义一个多行命令
5. 注释     :: Makefile只有行注释 "#", 如果要使用或者输出"#"字符, 需要进行转义, "\#"

### 1.2 GNU make 的工作方式

1. 读入主Makefile (主Makefile中可以引用其他Makefile)
2. 读入被include的其他Makefile
3. 初始化文件中的变量
4. 推导隐晦规则, 并分析所有规则
5. 为所有的目标文件创建依赖关系链
6. 根据依赖关系, 决定哪些目标要重新生成
7. 执行生成命令

## 实例解析





