---
title: Part 2 - 世上最简单的 SQL 编译器和虚拟机
date: 2019-01-26 16:11:20
categories:
- build-own-x
tags:
- database
- db原理
---

# Part 2 - 世上最简单的 SQL 编译器和虚拟机

sqlite 的前端是一个 SQL 编辑器, 解析一个字符串和输出一个内部的字节编码. 

这个字节编码通过虚拟机执行它.

![SQLite Architecture](https://cstack.github.io/db_tutorial/assets/images/arch2.gif)
SQLite Architecture (https://www.sqlite.org/arch.html)

将整件事情分解为两步主要有两个优点:
- 减少每一块的复杂度(例如: 虚拟机不用去考虑语法的错误)
- 允许编译常见错误,并且缓存字节码以提高效率.

顺着这个思路, 让我重构一下主函数, 并且让其支持两个新的关键词:
```c
 int main(int argc, char* argv[]) {
   InputBuffer* input_buffer = new_input_buffer();
   while (true) {
     print_prompt();
     read_input(input_buffer);

-    if (strcmp(input_buffer->buffer, ".exit") == 0) {
-      exit(EXIT_SUCCESS);
-    } else {
-      printf("Unrecognized command '%s'.\n", input_buffer->buffer);
+    if (input_buffer->buffer[0] == '.') {
+      switch (do_meta_command(input_buffer)) {
+        case (META_COMMAND_SUCCESS):
+          continue;
+        case (META_COMMAND_UNRECOGNIZED_COMMAND):
+          printf("Unrecognized command '%s'\n", input_buffer->buffer);
+          continue;
+      }
     }
+
+    Statement statement;
+    switch (prepare_statement(input_buffer, &statement)) {
+      case (PREPARE_SUCCESS):
+        break;
+      case (PREPARE_UNRECOGNIZED_STATEMENT):
+        printf("Unrecognized keyword at start of '%s'.\n",
+               input_buffer->buffer);
+        continue;
+    }
+
+    execute_statement(&statement);
+    printf("Executed.\n");
   }
 }
```

`.exit` 不是 SQL 命令,被称为 "元命令". 他们开始于 `.` 号, 所有我们需要先检查它们, 并在分离函数中处理他们.

下一步,我们添加一步将输入的行转换成内部的 statement. 这是我们前端的 hacky 版本.

最后,我们将预处理好的 statement 传给 `execute_statement` 函数, 这个函数最终将会变成我们的虚拟机.

注意, 这个新的函数均返回 enums 来表示成功或者失败:
```c
enum MetaCommandResult_t {
  META_COMMAND_SUCCESS,
  META_COMMAND_UNRECOGNIZED_COMMAND
};
typedef enum MetaCommandResult_t MetaCommandResult;

enum PrepareResult_t { PREPARE_SUCCESS, PREPARE_UNRECOGNIZED_STATEMENT };
typedef enum PrepareResult_t PrepareResult;
```

`do_meta_command` 函数仅仅是一个包装了退出函数,为更多的命令留下空间.

```c
MetaCommandResult do_meta_command(InputBuffer* input_buffer) {
  if (strcmp(input_buffer->buffer, ".exit") == 0) {
    exit(EXIT_SUCCESS);
  } else {
    return META_COMMAND_UNRECOGNIZED_COMMAND;
  }
}
```

我们的`prepared statement`枚举 现在仅包含两个值, 它将来将会包含更多的参数在声明中.

```c
enum StatementType_t { STATEMENT_INSERT, STATEMENT_SELECT };
typedef enum StatementType_t StatementType;

struct Statement_t {
  StatementType type;
};
typedef struct Statement_t Statement;
```

`prepare_statement` (我们的 SQL 编译器) 现在并不能理解 SQL, 他现在仅仅能理解两个单词.

```c
PrepareResult prepare_statement(InputBuffer* input_buffer,
                                Statement* statement) {
  if (strncmp(input_buffer->buffer, "insert", 6) == 0) {
    statement->type = STATEMENT_INSERT;
    return PREPARE_SUCCESS;
  }
  if (strcmp(input_buffer->buffer, "select") == 0) {
    statement->type = STATEMENT_SELECT;
    return PREPARE_SUCCESS;
  }

  return PREPARE_UNRECOGNIZED_STATEMENT;
}
```

注意,我们现在使用 `strncmp` 以 insert 关键词来匹配 insert 其后将会跟随着要插入的数据(例如: insert 1 cstack foo@bar.com)

最后 `execute_statement` 函数现在仅仅是打印了一些东西.

```c
void execute_statement(Statement* statement) {
  switch (statement->type) {
    case (STATEMENT_INSERT):
      printf("This is where we would do an insert.\n");
      break;
    case (STATEMENT_SELECT):
      printf("This is where we would do a select.\n");
      break;
  }
}
```

注意这里将不会返回任何错误码,因为这里没有啥错误可能产生

随着代码的开发,我们可以发现两个新的单词了.

```sh
~ ./db
db > insert foo bar
This is where we would do an insert.
Executed.
db > delete foo
Unrecognized keyword at start of 'delete foo'.
db > select
This is where we would do a select.
Executed.
db > .tables
Unrecognized command '.tables'
db > .exit
~
```

我们的数据库的架子正在形成... 如果能存储数据将会更加友好? 这是下一章节的内容, 我们将会实现插入和 select, 创建世界上最差的数据库存储, 下面是本章修改的代码对照:

```c
@@ -10,6 +10,23 @@ struct InputBuffer_t {
 };
 typedef struct InputBuffer_t InputBuffer;
 
+enum MetaCommandResult_t {
+  META_COMMAND_SUCCESS,
+  META_COMMAND_UNRECOGNIZED_COMMAND
+};
+typedef enum MetaCommandResult_t MetaCommandResult;
+
+enum PrepareResult_t { PREPARE_SUCCESS, PREPARE_UNRECOGNIZED_STATEMENT };
+typedef enum PrepareResult_t PrepareResult;
+
+enum StatementType_t { STATEMENT_INSERT, STATEMENT_SELECT };
+typedef enum StatementType_t StatementType;
+
+struct Statement_t {
+  StatementType type;
+};
+typedef struct Statement_t Statement;
+
 InputBuffer* new_input_buffer() {
   InputBuffer* input_buffer = malloc(sizeof(InputBuffer));
   input_buffer->buffer = NULL;
@@ -35,16 +52,66 @@ void read_input(InputBuffer* input_buffer) {
   input_buffer->buffer[bytes_read - 1] = 0;
 }
 
+MetaCommandResult do_meta_command(InputBuffer* input_buffer) {
+  if (strcmp(input_buffer->buffer, ".exit") == 0) {
+    exit(EXIT_SUCCESS);
+  } else {
+    return META_COMMAND_UNRECOGNIZED_COMMAND;
+  }
+}
+
+PrepareResult prepare_statement(InputBuffer* input_buffer,
+                                Statement* statement) {
+  if (strncmp(input_buffer->buffer, "insert", 6) == 0) {
+    statement->type = STATEMENT_INSERT;
+    return PREPARE_SUCCESS;
+  }
+  if (strcmp(input_buffer->buffer, "select") == 0) {
+    statement->type = STATEMENT_SELECT;
+    return PREPARE_SUCCESS;
+  }
+
+  return PREPARE_UNRECOGNIZED_STATEMENT;
+}
+
+void execute_statement(Statement* statement) {
+  switch (statement->type) {
+    case (STATEMENT_INSERT):
+      printf("This is where we would do an insert.\n");
+      break;
+    case (STATEMENT_SELECT):
+      printf("This is where we would do a select.\n");
+      break;
+  }
+}
+
 int main(int argc, char* argv[]) {
   InputBuffer* input_buffer = new_input_buffer();
   while (true) {
     print_prompt();
     read_input(input_buffer);
 
-    if (strcmp(input_buffer->buffer, ".exit") == 0) {
-      exit(EXIT_SUCCESS);
-    } else {
-      printf("Unrecognized command '%s'.\n", input_buffer->buffer);
+    if (input_buffer->buffer[0] == '.') {
+      switch (do_meta_command(input_buffer)) {
+        case (META_COMMAND_SUCCESS):
+          continue;
+        case (META_COMMAND_UNRECOGNIZED_COMMAND):
+          printf("Unrecognized command '%s'\n", input_buffer->buffer);
+          continue;
+      }
     }
+
+    Statement statement;
+    switch (prepare_statement(input_buffer, &statement)) {
+      case (PREPARE_SUCCESS):
+        break;
+      case (PREPARE_UNRECOGNIZED_STATEMENT):
+        printf("Unrecognized keyword at start of '%s'.\n",
+               input_buffer->buffer);
+        continue;
+    }
+
+    execute_statement(&statement);
+    printf("Executed.\n");
   }
 }
```

