---
title: Part 5 - 游标的抽象化
date: 2019-02-03 17:18:34
categories:
- build-own-x
tags:
- database
- db原理
---

# Part 5 - 游标的抽象化

这应该是最短的一章了, 我们仅仅是重构了一点,为了更好的开始 B 树的抽象化.

我们将会添加一个 `Cursor` 类, 标识数据在表的位置. 你可能需要做的事情:
- 在表开始之前创建游标
- 在表结束之后创建游标
- 访问光标指向的行
- 将光标前进到下一行

基于上面的行为,我们需要将会实现下面的一些东西:
- 通过游标删除行点
- 通过游标修改行点
- 通过给你的 ID 搜索表, 通过行的 ID 创建游标点.

游标的类型:
```c
+struct Cursor_t {
+  Table* table;
+  uint32_t row_num;
+  bool end_of_table;  // Indicates a position one past the last element
+};
+typedef struct Cursor_t Cursor;
```

根据我们当前的表数据结构，您需要在表中标识位置的所有内容都是行号。
一个游标当然还有对表的应用.
最后有一个布尔类型的标识`end_of_table`, 所以我们可以代表这是表的末尾

`table_start()` 和 `table_end()` 会创建一些新的游标.

```c
+Cursor* table_start(Table* table) {
+  Cursor* cursor = malloc(sizeof(Cursor));
+  cursor->table = table;
+  cursor->row_num = 0;
+  cursor->end_of_table = (table->num_rows == 0);
+
+  return cursor;
+}
+
+Cursor* table_end(Table* table) {
+  Cursor* cursor = malloc(sizeof(Cursor));
+  cursor->table = table;
+  cursor->row_num = table->num_rows;
+  cursor->end_of_table = true;
+
+  return cursor;
+}
```

我们的`row_slot()` 方法将会变为`cursor_value()` 它返回一个指向光标所描述位置的指针.

```c
-void* row_slot(Table* table, uint32_t row_num) {
+void* cursor_value(Cursor* cursor) {
+  uint32_t row_num = cursor->row_num;
   uint32_t page_num = row_num / ROWS_PER_PAGE;
-  void* page = get_page(table->pager, page_num);
+  void* page = get_page(cursor->table->pager, page_num);
   uint32_t row_offset = row_num % ROWS_PER_PAGE;
   uint32_t byte_offset = row_offset * ROW_SIZE;
   return page + byte_offset;
 }
```

在我们当前的表结构中推进游标就像递增行号一样简单. 这在 B 树中会更加复杂

```c
+void cursor_advance(Cursor* cursor) {
+  cursor->row_num += 1;
+  if (cursor->row_num >= cursor->table->num_rows) {
+    cursor->end_of_table = true;
+  }
+}
```

最后,我们可以改变虚拟机方法来使用游标抽象, 当我们查出一行数据, 我们将在表的尾部开一个游标, 将地址写入, 然后关闭游标.
```c
   Row* row_to_insert = &(statement->row_to_insert);
+  Cursor* cursor = table_end(table);

-  serialize_row(row_to_insert, row_slot(table, table->num_rows));
+  serialize_row(row_to_insert, cursor_value(cursor));
   table->num_rows += 1;

+  free(cursor);
+
   return EXECUTE_SUCCESS;
 }
```

当我们 select 所有的行的时候, 我们在表开始的地方开一个游标, 打印行,然后移动游标到下一行, 一直重复直到行末.

```c
ExecuteResult execute_select(Statement* statement, Table* table) {
+  Cursor* cursor = table_start(table);
+
   Row row;
-  for (uint32_t i = 0; i < table->num_rows; i++) {
-    deserialize_row(row_slot(table, i), &row);
+  while (!(cursor->end_of_table)) {
+    deserialize_row(cursor_value(cursor), &row);
     print_row(&row);
+    cursor_advance(cursor);
   }
+
+  free(cursor);
+
   return EXECUTE_SUCCESS;
 }
```

正如我所讲的, 这是一个简短的重构,为了将我们的table 数据重新写到 B 树中.
`execute_select()` 和 `execute_insert()` 可以完全通过游标与表进行交互，而无需假设表的存储方式。

下面是完整的代码改动:

```c
 };
 typedef struct Table_t Table;
 
+struct Cursor_t {
+  Table* table;
+  uint32_t row_num;
+  bool end_of_table;  // Indicates a position one past the last element
+};
+typedef struct Cursor_t Cursor;
+
 void print_row(Row* row) {
   printf("(%d, %s, %s)\n", row->id, row->username, row->email);
 }
@@ -125,14 +132,40 @@ void* get_page(Pager* pager, uint32_t page_num) {
   return pager->pages[page_num];
 }
 
-void* row_slot(Table* table, uint32_t row_num) {
+Cursor* table_start(Table* table) {
+  Cursor* cursor = malloc(sizeof(Cursor));
+  cursor->table = table;
+  cursor->row_num = 0;
+  cursor->end_of_table = (table->num_rows == 0);
+
+  return cursor;
+}
+
+Cursor* table_end(Table* table) {
+  Cursor* cursor = malloc(sizeof(Cursor));
+  cursor->table = table;
+  cursor->row_num = table->num_rows;
+  cursor->end_of_table = true;
+
+  return cursor;
+}
+
+void* cursor_value(Cursor* cursor) {
+  uint32_t row_num = cursor->row_num;
   uint32_t page_num = row_num / ROWS_PER_PAGE;
-  void* page = get_page(table->pager, page_num);
+  void* page = get_page(cursor->table->pager, page_num);
   uint32_t row_offset = row_num % ROWS_PER_PAGE;
   uint32_t byte_offset = row_offset * ROW_SIZE;
   return page + byte_offset;
 }
 
+void cursor_advance(Cursor* cursor) {
+  cursor->row_num += 1;
+  if (cursor->row_num >= cursor->table->num_rows) {
+    cursor->end_of_table = true;
+  }
+}
+
 Pager* pager_open(const char* filename) {
   int fd = open(filename,
                 O_RDWR |      // Read/Write mode
@@ -315,19 +348,28 @@ ExecuteResult execute_insert(Statement* statement, Table* table) {
   }
 
   Row* row_to_insert = &(statement->row_to_insert);
+  Cursor* cursor = table_end(table);
 
-  serialize_row(row_to_insert, row_slot(table, table->num_rows));
+  serialize_row(row_to_insert, cursor_value(cursor));
   table->num_rows += 1;
 
+  free(cursor);
+
   return EXECUTE_SUCCESS;
 }
 
 ExecuteResult execute_select(Statement* statement, Table* table) {
+  Cursor* cursor = table_start(table);
+
   Row row;
-  for (uint32_t i = 0; i < table->num_rows; i++) {
-    deserialize_row(row_slot(table, i), &row);
+  while (!(cursor->end_of_table)) {
+    deserialize_row(cursor_value(cursor), &row);
     print_row(&row);
+    cursor_advance(cursor);
   }
+
+  free(cursor);
+
   return EXECUTE_SUCCESS;
 }
```