---
title: Part 3 - 一个在内存, 仅追加的 单表数据库
date: 2019-01-26 16:11:20
categories:
- build-own-x
tags:
- database
- db原理
---

# Part 3 - 一个在内存, 仅追加的 单表数据库

我们将继续为我们的数据库添加一些小功能, 通过在数据库中添加一些限制. 添加的功能如下:

- 支持两个操作: 插入新的一行数据 and 打印所有行数据
- 让其暂住在内存中(并没有存储到硬盘中)
- 支持单个硬编码表

我们的硬编码表主要用于存储用户信息, 看起来像这样

column     |  type
------------    | ----------
id                | integer
username | varchar(32)
email          | varchar(255)

这是一个简单的 schema, 但是它支持多数据类型和多类型大小的文本类型.

插入语法现在看起来像这样:
```sql
insert 1 cstack foo@bar.com
```

这意味着我们需要去更新 `prepare_statement` 方法去解析参数.

```c
if (strncmp(input_buffer->buffer, "insert", 6) == 0) {
     statement->type = STATEMENT_INSERT;
+    int args_assigned = sscanf(
+        input_buffer->buffer, "insert %d %s %s", &(statement->row_to_insert.id),
+        statement->row_to_insert.username, statement->row_to_insert.email);
+    if (args_assigned < 3) {
+      return PREPARE_SYNTAX_ERROR;
+    }
     return PREPARE_SUCCESS;
   }
   if (strcmp(input_buffer->buffer, "select") == 0) {
```

我们声明一个新的 `Row` 结构放在 `statement` 下, 并将传入的参数放在其中.

```c
+const uint32_t COLUMN_USERNAME_SIZE = 32;
+const uint32_t COLUMN_EMAIL_SIZE = 255;
+struct Row_t {
+  uint32_t id;
+  char username[COLUMN_USERNAME_SIZE];
+  char email[COLUMN_EMAIL_SIZE];
+};
+typedef struct Row_t Row;
+
 struct Statement_t {
   StatementType type;
+  Row row_to_insert;  // only used by insert statement
 };
 typedef struct Statement_t Statement;
```

现在我们需要将传入的数据复制到 `Row` 中, 以此来代替表. Sqlite 使用 B 树来快速的查询,插入和删除. 我们将从简单的事情开始, 像 B 树结构是将数据行进行分组到页中, 但是在这里我们将用数组来代替 B 树.

这是我的计划:
- 将行存在在内存块中, 将其称为页面
- 每一个页面都用行数据填充
- 每一行都将序列化为紧凑形式
- 页面仅根据需要分配
- 保持固定大小的页面指针数组

第一, 我们将定义一个紧凑的行表示.

```c
+#define size_of_attribute(Struct, Attribute) sizeof(((Struct*)0)->Attribute)
+
+const uint32_t ID_SIZE = size_of_attribute(Row, id);
+const uint32_t USERNAME_SIZE = size_of_attribute(Row, username);
+const uint32_t EMAIL_SIZE = size_of_attribute(Row, email);
+const uint32_t ID_OFFSET = 0;
+const uint32_t USERNAME_OFFSET = ID_OFFSET + ID_SIZE;
+const uint32_t EMAIL_OFFSET = USERNAME_OFFSET + USERNAME_SIZE;
+const uint32_t ROW_SIZE = ID_SIZE + USERNAME_SIZE + EMAIL_SIZE;
```

这也意味着我们序列化行数据将会看起来像下面这样:

column      |   size (bytes)     |  offset
-------------   |  ------------------   | ---------
id                |           4              |   0
username |          32             |  4
email         |         255  	   |  36
total           |  	     291   	      |

我们也需要使用代码将行数据转换成紧凑的形式

```c
+void serialize_row(Row* source, void* destination) {
+  memcpy(destination + ID_OFFSET, &(source->id), ID_SIZE);
+  memcpy(destination + USERNAME_OFFSET, &(source->username), USERNAME_SIZE);
+  memcpy(destination + EMAIL_OFFSET, &(source->email), EMAIL_SIZE);
+}
+
+void deserialize_row(void* source, Row* destination) {
+  memcpy(&(destination->id), source + ID_OFFSET, ID_SIZE);
+  memcpy(&(destination->username), source + USERNAME_OFFSET, USERNAME_SIZE);
+  memcpy(&(destination->email), source + EMAIL_OFFSET, EMAIL_SIZE);
+}
```

下一步, 一个表结构记录着到 page 的指针和有多少条记录的

```c
+const uint32_t PAGE_SIZE = 4096;
+const uint32_t TABLE_MAX_PAGES = 100;
+const uint32_t ROWS_PER_PAGE = PAGE_SIZE / ROW_SIZE;
+const uint32_t TABLE_MAX_ROWS = ROWS_PER_PAGE * TABLE_MAX_PAGES;
+
+struct Table_t {
+  void* pages[TABLE_MAX_PAGES];
+  uint32_t num_rows;
+};
+typedef struct Table_t Table;
```

我定义了一页的大小为4千字节, 因为这个和虚拟内存系统框架的页大小刚好一样. 这也意味在数据库中的一页对应着操作系统中的一页. 操作系统也是整页数据的进行着操作.

我们随意的限制下页数为100页. 当我们使用数的结构的时候, 我们数据库最大的限制将会是文件的最大限制.(虽然我们依旧会去限制有多少页的数据驻留在内存中.)

行不应该超过页的限制, 因为页面之间可能不会彼此相邻, 这样会使得读写更加方便.

讲到这里, 我们将讲下如何计算特定的内存的位置.

```c
+void* row_slot(Table* table, uint32_t row_num) {
+  uint32_t page_num = row_num / ROWS_PER_PAGE;
+  void* page = table->pages[page_num];
+  if (!page) {
+    // Allocate memory only when we try to access page
+    page = table->pages[page_num] = malloc(PAGE_SIZE);
+  }
+  uint32_t row_offset = row_num % ROWS_PER_PAGE;
+  uint32_t byte_offset = row_offset * ROW_SIZE;
+  return page + byte_offset;
+}
```

现在, 我们可以让 `execute_statement` 方法可以从 table 结构中读写

```c
-void execute_statement(Statement* statement) {
+ExecuteResult execute_insert(Statement* statement, Table* table) {
+  if (table->num_rows >= TABLE_MAX_ROWS) {
+    return EXECUTE_TABLE_FULL;
+  }
+
+  Row* row_to_insert = &(statement->row_to_insert);
+
+  serialize_row(row_to_insert, row_slot(table, table->num_rows));
+  table->num_rows += 1;
+
+  return EXECUTE_SUCCESS;
+}
+
+ExecuteResult execute_select(Statement* statement, Table* table) {
+  Row row;
+  for (uint32_t i = 0; i < table->num_rows; i++) {
+    deserialize_row(row_slot(table, i), &row);
+    print_row(&row);
+  }
+  return EXECUTE_SUCCESS;
+}
+
+ExecuteResult execute_statement(Statement* statement, Table* table) {
   switch (statement->type) {
     case (STATEMENT_INSERT):
-      printf("This is where we would do an insert.\n");
-      break;
+      return execute_insert(statement, table);
     case (STATEMENT_SELECT):
-      printf("This is where we would do a select.\n");
-      break;
+      return execute_select(statement, table);
   }
 }
```

最后, 我们需要初始化table 并且处理一些错误的情况.

```c
+ Table* new_table() {
+  Table* table = malloc(sizeof(Table));
+  table->num_rows = 0;
+
+  return table;
+}
```

```c
int main(int argc, char* argv[]) {
+  Table* table = new_table();
   InputBuffer* input_buffer = new_input_buffer();
   while (true) {
     print_prompt();
@@ -105,13 +203,22 @@ int main(int argc, char* argv[]) {
     switch (prepare_statement(input_buffer, &statement)) {
       case (PREPARE_SUCCESS):
         break;
+      case (PREPARE_SYNTAX_ERROR):
+        printf("Syntax error. Could not parse statement.\n");
+        continue;
       case (PREPARE_UNRECOGNIZED_STATEMENT):
         printf("Unrecognized keyword at start of '%s'.\n",
                input_buffer->buffer);
         continue;
     }

-    execute_statement(&statement);
-    printf("Executed.\n");
+    switch (execute_statement(&statement, table)) {
+      case (EXECUTE_SUCCESS):
+        printf("Executed.\n");
+        break;
+      case (EXECUTE_TABLE_FULL):
+        printf("Error: Table full.\n");
+        break;
+    }
   }
 }
```

随着这些的修改,我们就能将数据保存到我们的数据库中了

```sh
~ ./db
db > insert 1 cstack foo@bar.com
Executed.
db > insert 2 bob bob@example.com
Executed.
db > select
(1, cstack, foo@bar.com)
(2, bob, bob@example.com)
Executed.
db > insert foo bar 1
Syntax error. Could not parse statement.
db > .exit
~
```

现在,我们可以写一些单元测试了, 原因有下面两点:
- 我们将大幅的改变数据存储到我们的 table中, 并回归它们.
- 还存在一些边缘情况我们还没有手动测试(如: 填满全表)

我们将在下一节中完善这些问题, 现在, 让我们看看整体的修改吧:

```c
typedef struct InputBuffer_t InputBuffer;
 
+enum ExecuteResult_t { EXECUTE_SUCCESS, EXECUTE_TABLE_FULL };
+typedef enum ExecuteResult_t ExecuteResult;
+
 enum MetaCommandResult_t {
   META_COMMAND_SUCCESS,
   META_COMMAND_UNRECOGNIZED_COMMAND
 };
 typedef enum MetaCommandResult_t MetaCommandResult;
 
-enum PrepareResult_t { PREPARE_SUCCESS, PREPARE_UNRECOGNIZED_STATEMENT };
+enum PrepareResult_t {
+  PREPARE_SUCCESS,
+  PREPARE_SYNTAX_ERROR,
+  PREPARE_UNRECOGNIZED_STATEMENT
+};
 typedef enum PrepareResult_t PrepareResult;
 
 enum StatementType_t { STATEMENT_INSERT, STATEMENT_SELECT };
 typedef enum StatementType_t StatementType;
 
+const uint32_t COLUMN_USERNAME_SIZE = 32;
+const uint32_t COLUMN_EMAIL_SIZE = 255;
+struct Row_t {
+  uint32_t id;
+  char username[COLUMN_USERNAME_SIZE];
+  char email[COLUMN_EMAIL_SIZE];
+};
+typedef struct Row_t Row;
+
 struct Statement_t {
   StatementType type;
+  Row row_to_insert;  // only used by insert statement
 };
 typedef struct Statement_t Statement;
 
+#define size_of_attribute(Struct, Attribute) sizeof(((Struct*)0)->Attribute)
+
+const uint32_t ID_SIZE = size_of_attribute(Row, id);
+const uint32_t USERNAME_SIZE = size_of_attribute(Row, username);
+const uint32_t EMAIL_SIZE = size_of_attribute(Row, email);
+const uint32_t ID_OFFSET = 0;
+const uint32_t USERNAME_OFFSET = ID_OFFSET + ID_SIZE;
+const uint32_t EMAIL_OFFSET = USERNAME_OFFSET + USERNAME_SIZE;
+const uint32_t ROW_SIZE = ID_SIZE + USERNAME_SIZE + EMAIL_SIZE;
+
+const uint32_t PAGE_SIZE = 4096;
+const uint32_t TABLE_MAX_PAGES = 100;
+const uint32_t ROWS_PER_PAGE = PAGE_SIZE / ROW_SIZE;
+const uint32_t TABLE_MAX_ROWS = ROWS_PER_PAGE * TABLE_MAX_PAGES;
+
+struct Table_t {
+  void* pages[TABLE_MAX_PAGES];
+  uint32_t num_rows;
+};
+typedef struct Table_t Table;
+
+void print_row(Row* row) {
+  printf("(%d, %s, %s)\n", row->id, row->username, row->email);
+}
+
+void serialize_row(Row* source, void* destination) {
+  memcpy(destination + ID_OFFSET, &(source->id), ID_SIZE);
+  memcpy(destination + USERNAME_OFFSET, &(source->username), USERNAME_SIZE);
+  memcpy(destination + EMAIL_OFFSET, &(source->email), EMAIL_SIZE);
+}
+
+void deserialize_row(void* source, Row* destination) {
+  memcpy(&(destination->id), source + ID_OFFSET, ID_SIZE);
+  memcpy(&(destination->username), source + USERNAME_OFFSET, USERNAME_SIZE);
+  memcpy(&(destination->email), source + EMAIL_OFFSET, EMAIL_SIZE);
+}
+
+void* row_slot(Table* table, uint32_t row_num) {
+  uint32_t page_num = row_num / ROWS_PER_PAGE;
+  void* page = table->pages[page_num];
+  if (!page) {
+    // Allocate memory only when we try to access page
+    page = table->pages[page_num] = malloc(PAGE_SIZE);
+  }
+  uint32_t row_offset = row_num % ROWS_PER_PAGE;
+  uint32_t byte_offset = row_offset * ROW_SIZE;
+  return page + byte_offset;
+}
+
+Table* new_table() {
+  Table* table = malloc(sizeof(Table));
+  table->num_rows = 0;
+
+  return table;
+}
+
 InputBuffer* new_input_buffer() {
   InputBuffer* input_buffer = malloc(sizeof(InputBuffer));
   input_buffer->buffer = NULL;
@@ -64,6 +137,12 @@ PrepareResult prepare_statement(InputBuffer* input_buffer,
                                 Statement* statement) {
   if (strncmp(input_buffer->buffer, "insert", 6) == 0) {
     statement->type = STATEMENT_INSERT;
+    int args_assigned = sscanf(
+        input_buffer->buffer, "insert %d %s %s", &(statement->row_to_insert.id),
+        statement->row_to_insert.username, statement->row_to_insert.email);
+    if (args_assigned < 3) {
+      return PREPARE_SYNTAX_ERROR;
+    }
     return PREPARE_SUCCESS;
   }
   if (strcmp(input_buffer->buffer, "select") == 0) {
@@ -74,18 +153,39 @@ PrepareResult prepare_statement(InputBuffer* input_buffer,
   return PREPARE_UNRECOGNIZED_STATEMENT;
 }
 
-void execute_statement(Statement* statement) {
+ExecuteResult execute_insert(Statement* statement, Table* table) {
+  if (table->num_rows >= TABLE_MAX_ROWS) {
+    return EXECUTE_TABLE_FULL;
+  }
+
+  Row* row_to_insert = &(statement->row_to_insert);
+
+  serialize_row(row_to_insert, row_slot(table, table->num_rows));
+  table->num_rows += 1;
+
+  return EXECUTE_SUCCESS;
+}
+
+ExecuteResult execute_select(Statement* statement, Table* table) {
+  Row row;
+  for (uint32_t i = 0; i < table->num_rows; i++) {
+    deserialize_row(row_slot(table, i), &row);
+    print_row(&row);
+  }
+  return EXECUTE_SUCCESS;
+}
+
+ExecuteResult execute_statement(Statement* statement, Table* table) {
   switch (statement->type) {
     case (STATEMENT_INSERT):
-      printf("This is where we would do an insert.\n");
-      break;
+      return execute_insert(statement, table);
     case (STATEMENT_SELECT):
-      printf("This is where we would do a select.\n");
-      break;
+      return execute_select(statement, table);
   }
 }
 
 int main(int argc, char* argv[]) {
+  Table* table = new_table();
   InputBuffer* input_buffer = new_input_buffer();
   while (true) {
     print_prompt();
@@ -105,13 +205,22 @@ int main(int argc, char* argv[]) {
     switch (prepare_statement(input_buffer, &statement)) {
       case (PREPARE_SUCCESS):
         break;
+      case (PREPARE_SYNTAX_ERROR):
+        printf("Syntax error. Could not parse statement.\n");
+        continue;
       case (PREPARE_UNRECOGNIZED_STATEMENT):
         printf("Unrecognized keyword at start of '%s'.\n",
                input_buffer->buffer);
         continue;
     }
 
-    execute_statement(&statement);
-    printf("Executed.\n");
+    switch (execute_statement(&statement, table)) {
+      case (EXECUTE_SUCCESS):
+        printf("Executed.\n");
+        break;
+      case (EXECUTE_TABLE_FULL):
+        printf("Error: Table full.\n");
+        break;
+    }
   }
 }
```