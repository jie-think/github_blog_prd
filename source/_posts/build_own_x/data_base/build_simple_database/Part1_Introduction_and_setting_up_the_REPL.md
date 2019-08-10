---
title: Part 1 - 介绍和设置 REPL
date: 2019-01-26 16:11:20
categories:
- build-own-x
tags:
- database
- db原理
---

# Part 1 - 介绍和设置 REPL

> 下面涉及一些专业术语,不做具体翻译,第一次出现时可能会解释下.

作为一个 web 开发者, 在工作中每天都会使用到关系型数据库,但是它对于我就像是一个黑箱子一样. 我存在好多问题:

- 在内存和磁盘上, 数据保存的格式是啥?
- 什么时候会从内存中移动到硬盘上?
- 为什么每个表仅有一个主键呢?
- 事务回滚是如何工作的呢?
- 索引是如何格式化? FIXME(Jx)  (How are indexes formatted?)
- 啥时候全表扫描会发生呢?
- 保存前的预准备格式是啥样的呢? FIXME(Jx) (What format is a prepared statement saved in?)

换而言之,它是如何工作的呢?

为了弄清这些事情,我从头写了一个数据库. 它是已 sqlite 为原型, 因为sqlite 的设计相对于 mysql 和 PostgreSQL 简单不少. 所以能够更好的理解它, 整个数据存储在单个文件中.

## Sqlite

Sqlite 官网有许多内部[设计文档](https://www.sqlite.org/arch.html) , 这里拷贝一份 [Sqlite 数据库系统的设计和实现文档](https://play.google.com/store/books/details?id=9Z6IQQnX1JEC)

![sqlite architecture](https://cstack.github.io/db_tutorial/assets/images/arch1.gif)
sqlite architecture (https://www.sqlite.org/zipvfs/doc/trunk/www/howitworks.wiki)

一个查询是通过一条长链的组件来取回或者修改数据. 前端组件的组成:

- tokenizer (标记生成器)
- parser (解析器)
- code generator (代码生成器)

给前端输入一个 SQL 查询, 输出的是 Sqlite 虚拟机的字节码(本质上是一个可以在数据库上运行的编译程序)

后端组件的组成:

- virtual machine
- B-tree
- pager
- os interface

`virtual machine`: 虚拟机接收前端传过来的字节码, 它能够操作一个或者多个表或者索引, 所有的这些都是存储在一个数据结构中, is B 树. VM 其本质其实是一个字节指令, 一个大的 switch 语句.

`B-tree`: 每个 B 树都是有许多个节点组成的, 每个节点是一个页. B树可以通过向 `pager` 发送指令从硬盘中取回一页 或者是将数据保存回硬盘.

`pager`: 接收指令读取或者写入一页数据. 它的主要责任是在适当的时候读或写数据库文件. 同时会在内存中保存一份最近读取的页, 并且确定在什么时候需要就这页数据回写到硬盘.

`os interface`: 根据操作系统的不同会有很大的不同, 在这份教程中, 不会去支持多操作系统.

千里之行始于足下, so 让我们从第一步开始吧: the REPL

## 制作一个简单的 REPL

Sqlite 开始于 read-execute-print(读取-执行-打印) 的循环, 从命令行开始吧:
```sh
~ sqlite3
SQLite version 3.16.0 2016-11-04 19:09:39
Enter ".help" for usage hints.
Connected to a transient in-memory database.
Use ".open FILENAME" to reopen on a persistent database.
sqlite> create table users (id int, username varchar(255), email varchar(255));
sqlite> .tables
users
sqlite> .exit
~
```

要做到这一点我们需要在主程序中用一个无限循环打印提示,  获取一行输入, 然后处理这行输入.

```c
int main(int argc, char* argv[]) {
  InputBuffer* input_buffer = new_input_buffer();
  while (true) {
    print_prompt();
    read_input(input_buffer);

    if (strcmp(input_buffer->buffer, ".exit") == 0) {
      exit(EXIT_SUCCESS);
    } else {
      printf("Unrecognized command '%s'.\n", input_buffer->buffer);
    }
  }
}
```

我们将定义一个 InputBuffer 使用一个简单的包装器, 需要存储 `getline()` 的信息.

```c
struct InputBuffer_t {
  char* buffer;
  size_t buffer_length;
  ssize_t input_length;
};
typedef struct InputBuffer_t InputBuffer;

InputBuffer* new_input_buffer() {
  InputBuffer* input_buffer = malloc(sizeof(InputBuffer));
  input_buffer->buffer = NULL;
  input_buffer->buffer_length = 0;
  input_buffer->input_length = 0;

  return input_buffer;
}
```

下一步打印提示, 在每一行输入之前都需要打印它

```c
void print_prompt() { printf("db > "); }
```

为了读取一行输入,需要使用到`getline()`:

```c
ssize_t getline(char **lineptr, size_t *n, FILE *stream);
```

buffer 开始的时候是 null 的, 所以在 getline 分配足够的内存来保存输入的内容.

```c
void read_input(InputBuffer* input_buffer) {
  ssize_t bytes_read =
      getline(&(input_buffer->buffer), &(input_buffer->buffer_length), stdin);

  if (bytes_read <= 0) {
    printf("Error reading input\n");
    exit(EXIT_FAILURE);
  }

  // Ignore trailing newline(忽略换行符)
  input_buffer->input_length = bytes_read - 1;
  input_buffer->buffer[bytes_read - 1] = 0;
}
```

最后,我们将执行命令, 在这仅有一个可解析的命令 `.exit` , 输入其它的内容都会继续循环.

```c
if (strcmp(input_buffer->buffer, ".exit") == 0) {
  exit(EXIT_SUCCESS);
} else {
  printf("Unrecognized command '%s'.\n", input_buffer->buffer);
}
```

编译运行下吧~
```sh
~ ./db
db > .tables
Unrecognized command '.tables'.
db > .exit
~
```

完整实例:

```c
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct InputBuffer_t {
  char* buffer;
  size_t buffer_length;
  ssize_t input_length;
};
typedef struct InputBuffer_t InputBuffer;

InputBuffer* new_input_buffer() {
  InputBuffer* input_buffer = malloc(sizeof(InputBuffer));
  input_buffer->buffer = NULL;
  input_buffer->buffer_length = 0;
  input_buffer->input_length = 0;

  return input_buffer;
}

void print_prompt() { printf("db > "); }

void read_input(InputBuffer* input_buffer) {
  ssize_t bytes_read =
      getline(&(input_buffer->buffer), &(input_buffer->buffer_length), stdin);

  if (bytes_read <= 0) {
    printf("Error reading input\n");
    exit(EXIT_FAILURE);
  }

  // Ignore trailing newline
  input_buffer->input_length = bytes_read - 1;
  input_buffer->buffer[bytes_read - 1] = 0;
}

int main(int argc, char* argv[]) {
  InputBuffer* input_buffer = new_input_buffer();
  while (true) {
    print_prompt();
    read_input(input_buffer);

    if (strcmp(input_buffer->buffer, ".exit") == 0) {
      exit(EXIT_SUCCESS);
    } else {
      printf("Unrecognized command '%s'.\n", input_buffer->buffer);
    }
  }
}
```
