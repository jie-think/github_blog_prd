---
title: Part 5 - 持久化到硬盘
date: 2019-01-28 22:30:00
categories:
- build-own-x
tags:
- database
- db原理
---

# Part 5 - 持久化到硬盘

> “Nothing in the world can take the place of persistence.” – Calvin Coolidge

我们的数据库允许你插入数据并且取回数据, 但是仅仅是在程序运行的时候.如果你 kill 程序或者重启它, 你的数据将会丢失. 这个spec单元测试类可以模拟这个情况:

```ruby
it 'keeps data after closing connection' do
  result1 = run_script([
    "insert 1 user1 person1@example.com",
    ".exit",
  ])
  expect(result1).to match_array([
    "db > Executed.",
    "db > ",
  ])
  result2 = run_script([
    "select",
    ".exit",
  ])
  expect(result2).to match_array([
    "db > (1, user1, person1@example.com)",
    "Executed.",
    "db > ",
  ])
end
```

就行 Sqlite 一样, 我们将持久化数据到一个文件中.

我们已经将行数据序列化行数据到内存块中了, 添加序列化, 我们可以简单的将内存块数据到文件中, 并且在下次程序启动时读取文件到内存中.

为了使其更加简单,我们将定义一个抽象的`pager` , 我们可以向 `pager` 获取页面 x 的内容, 可以简单的将内存块写到文件中. 它首先会在缓存中查看, 如果缓存中没有再从硬盘从拷贝数据.

![How our program matches up with SQLite architecture](https://cstack.github.io/db_tutorial/assets/images/arch-part5.gif)
How our program matches up with SQLite architecture

`Pager` 访问页面缓存和文件, `Tabel` 通过 `pager` 请求页面数据.

```c
+struct Pager_t {
+  int file_descriptor;
+  uint32_t file_length;
+  void* pages[TABLE_MAX_PAGES];
+};
+typedef struct Pager_t Pager;
+
 struct Table_t {
-  void* pages[TABLE_MAX_PAGES];
+  Pager* pager;
   uint32_t num_rows;
 };
```

我重新命名下 `new_table()` 为 `db_open()` , 它现在有打开数据库的效果了, 通过打开一个连接, 我的意思是:
- 打开数据库文件
- 初始化一页数据
- 初始化一个 table 的结构

```c
-Table* new_table() {
+Table* db_open(const char* filename) {
+  Pager* pager = pager_open(filename);
+  uint32_t num_rows = pager->file_length / ROW_SIZE;
+
   Table* table = malloc(sizeof(Table));
-  table->num_rows = 0;
+  table->pager = pager;
+  table->num_rows = num_rows;

   return table;
 }
```

`db_open()` 方法调用的是 `pager_open()` 方法, 将打开数据库文件并且跟踪它的大小, 同时初始化page 的缓存为 NULL.

```c
+Pager* pager_open(const char* filename) {
+  int fd = open(filename,
+                O_RDWR |      // Read/Write mode
+                    O_CREAT,  // Create file if it does not exist
+                S_IWUSR |     // User write permission
+                    S_IRUSR   // User read permission
+                );
+
+  if (fd == -1) {
+    printf("Unable to open file\n");
+    exit(EXIT_FAILURE);
+  }
+
+  off_t file_length = lseek(fd, 0, SEEK_END);
+
+  Pager* pager = malloc(sizeof(Pager));
+  pager->file_descriptor = fd;
+  pager->file_length = file_length;
+
+  for (uint32_t i = 0; i < TABLE_MAX_PAGES; i++) {
+    pager->pages[i] = NULL;
+  }
+
+  return pager;
+}
```

随着我们新的抽象, 我们需要将我们获取页数据的代码移动到新的方法中.

```c
 void* row_slot(Table* table, uint32_t row_num) {
   uint32_t page_num = row_num / ROWS_PER_PAGE;
-  void* page = table->pages[page_num];
-  if (!page) {
-    // Allocate memory only when we try to access page
-    page = table->pages[page_num] = malloc(PAGE_SIZE);
-  }
+  void* page = get_page(table->pager, page_num);
   uint32_t row_offset = row_num % ROWS_PER_PAGE;
   uint32_t byte_offset = row_offset * ROW_SIZE;
   return page + byte_offset;
 }
```

`get_page()` 方法中存在一个逻辑是处理丢失的缓存问题. 我们假设页面在数据库文件中一个接一个地保存：第0页的偏移量是0, 第一页的偏移量是4096, 第二页的偏移量是8192,等等. 如果请求的页面超出了文件边界值, 我们知道将会是空白的. 所以我们仅分配一些内存并且返回它. 当我 flush 缓存数据到硬盘后, 添加到文件中.

```c
+void* get_page(Pager* pager, uint32_t page_num) {
+  if (page_num > TABLE_MAX_PAGES) {
+    printf("Tried to fetch page number out of bounds. %d > %d\n", page_num,
+           TABLE_MAX_PAGES);
+    exit(EXIT_FAILURE);
+  }
+
+  if (pager->pages[page_num] == NULL) {
+    // Cache miss. Allocate memory and load from file.
+    void* page = malloc(PAGE_SIZE);
+    uint32_t num_pages = pager->file_length / PAGE_SIZE;
+
+    // We might save a partial page at the end of the file
+    if (pager->file_length % PAGE_SIZE) {
+      num_pages += 1;
+    }
+
+    if (page_num <= num_pages) {
+      lseek(pager->file_descriptor, page_num * PAGE_SIZE, SEEK_SET);
+      ssize_t bytes_read = read(pager->file_descriptor, page, PAGE_SIZE);
+      if (bytes_read == -1) {
+        printf("Error reading file: %d\n", errno);
+        exit(EXIT_FAILURE);
+      }
+    }
+
+    pager->pages[page_num] = page;
+  }
+
+  return pager->pages[page_num];
+}
```

现在我们将等待缓存flush 到硬盘, 直到用户关闭了数据库连接, 当用户退出后,我们会去调用`db_close()` 方法
- flush 页面缓存到硬盘
- 关闭数据库文件
- 释放 `pager` 和 `table` 的内存

```c
+void db_close(Table* table) {
+  Pager* pager = table->pager;
+  uint32_t num_full_pages = table->num_rows / ROWS_PER_PAGE;
+
+  for (uint32_t i = 0; i < num_full_pages; i++) {
+    if (pager->pages[i] == NULL) {
+      continue;
+    }
+    pager_flush(pager, i, PAGE_SIZE);
+    free(pager->pages[i]);
+    pager->pages[i] = NULL;
+  }
+
+  // There may be a partial page to write to the end of the file
+  // This should not be needed after we switch to a B-tree
+  uint32_t num_additional_rows = table->num_rows % ROWS_PER_PAGE;
+  if (num_additional_rows > 0) {
+    uint32_t page_num = num_full_pages;
+    if (pager->pages[page_num] != NULL) {
+      pager_flush(pager, page_num, num_additional_rows * ROW_SIZE);
+      free(pager->pages[page_num]);
+      pager->pages[page_num] = NULL;
+    }
+  }
+
+  int result = close(pager->file_descriptor);
+  if (result == -1) {
+    printf("Error closing db file.\n");
+    exit(EXIT_FAILURE);
+  }
+  for (uint32_t i = 0; i < TABLE_MAX_PAGES; i++) {
+    void* page = pager->pages[i];
+    if (page) {
+      free(page);
+      pager->pages[i] = NULL;
+    }
+  }
+  free(pager);
+}
+
-MetaCommandResult do_meta_command(InputBuffer* input_buffer) {
+MetaCommandResult do_meta_command(InputBuffer* input_buffer, Table* table) {
   if (strcmp(input_buffer->buffer, ".exit") == 0) {
+    db_close(table);
     exit(EXIT_SUCCESS);
   } else {
     return META_COMMAND_UNRECOGNIZED_COMMAND;
```

在我们当前的设计中, 文件的长度取决于有多少数据在数据库中. 所以我们需要写一个局部的文件在文件的尾部.  这就是为啥`pager_flush()` 同时需要一个页面和文件大小.这不是最好的设计, 当我们使用 B 树后, 这个会变好的.

```c
+void pager_flush(Pager* pager, uint32_t page_num, uint32_t size) {
+  if (pager->pages[page_num] == NULL) {
+    printf("Tried to flush null page\n");
+    exit(EXIT_FAILURE);
+  }
+
+  off_t offset = lseek(pager->file_descriptor, page_num * PAGE_SIZE, SEEK_SET);
+
+  if (offset == -1) {
+    printf("Error seeking: %d\n", errno);
+    exit(EXIT_FAILURE);
+  }
+
+  ssize_t bytes_written =
+      write(pager->file_descriptor, pager->pages[page_num], size);
+
+  if (bytes_written == -1) {
+    printf("Error writing: %d\n", errno);
+    exit(EXIT_FAILURE);
+  }
+}
```

最后, 我们需要从命令行接收文件名的参数, 别忘了添加扩展参数到do_meta_command方法中.

```c
int main(int argc, char* argv[]) {
-  Table* table = new_table();
+  if (argc < 2) {
+    printf("Must supply a database filename.\n");
+    exit(EXIT_FAILURE);
+  }
+
+  char* filename = argv[1];
+  Table* table = db_open(filename);
+
   InputBuffer* input_buffer = new_input_buffer();
   while (true) {
     print_prompt();
     read_input(input_buffer);
 
     if (input_buffer->buffer[0] == '.') {
-      switch (do_meta_command(input_buffer)) {
+      switch (do_meta_command(input_buffer, table)) {
```

通过这些改变, 我们的数据库可以关闭重新打开, 我们的数据依旧存在着

```sh
~ ./db mydb.db
db > insert 1 cstack foo@bar.com
Executed.
db > insert 2 voltorb volty@example.com
Executed.
db > .exit
~
~ ./db mydb.db
db > select
(1, cstack, foo@bar.com)
(2, voltorb, volty@example.com)
Executed.
db > .exit
~
```

为找一些有趣的事, 我们来看下 mydb.db 文件 看看我们的数据是如何存储的. 我们将使用 vim 的16进制编辑器打开它.

```sh
vim mydb.db
:%!xxd
```

![文件内容](https://cstack.github.io/db_tutorial/assets/images/file-format.png)

第一行的4个字节是我们的 ID (4个字节是因为我们存储了一个 uint32_t). 它以[little-endian字节顺序](https://zh.wikipedia.org/wiki/%E5%AD%97%E8%8A%82%E5%BA%8F)存储，因此最低有效字节首先出现（01）,随后跟的是高位字节(00 00 00). 我们使用`memcpy()`方法将 Row 结构的中的数据拷贝到 page 缓存中, 所以这个也意味着这个结构在内存中也是底字节序的. 这个属性是我们汇编程序所决定的. 如果我们写了一个小端序的数据库文件,然后在大端序的机器上打开的, 我们需要修改`serialize_now()` 和 `deserialize_now()`方法保证读取和存储都是相同的顺序.

下一个33字节存储的是用户名, 并且一个终止符结束.  显示出了 "cstack" 在 ASCII 码 在16进制 63 73 74 61 63 6b, 紧随其后的是的一个空字符(00). 剩下的33个字节是没有用的

下一个256字节存储的是邮箱,用的同样的方式. 这里我们能看见一堆随机码在空字符后面.这个很可能是在Row结构没有初始化的内存. 我们拷贝了整个256字节的邮件 buffer 到文件中, 包含了在字符串结束后的内容. 当我们分配该结构时，内存中的内容仍然存在. 但由于我们使用终止空字符，因此它对行为没有影响。

## 总结

好的,我们已经持久化了, 但是现在他并不是最好的. 例如, 如果你 kill 进程没有使用 `.exit` 命令, 你将会丢失你的修改. 另外我们写了所有的 page 到磁盘中, 甚至自从我们从磁盘读取它们以来没有改变的页面。

下一步我们将介绍游标, 这会使实现 B 树更加简单.

### 完整的修改

```c
+#include <errno.h>
+#include <fcntl.h>
 #include <stdbool.h>
 #include <stdio.h>
 #include <stdlib.h>
 #include <string.h>
+#include <unistd.h>
 
 struct InputBuffer_t {
   char* buffer;
@@ -61,8 +64,15 @@ const uint32_t TABLE_MAX_PAGES = 100;
 const uint32_t ROWS_PER_PAGE = PAGE_SIZE / ROW_SIZE;
 const uint32_t TABLE_MAX_ROWS = ROWS_PER_PAGE * TABLE_MAX_PAGES;
 
-struct Table_t {
+struct Pager_t {
+  int file_descriptor;
+  uint32_t file_length;
   void* pages[TABLE_MAX_PAGES];
+};
+typedef struct Pager_t Pager;
+
+struct Table_t {
+  Pager* pager;
   uint32_t num_rows;
 };
 typedef struct Table_t Table;
@@ -83,21 +93,79 @@ void deserialize_row(void* source, Row* destination) {
   memcpy(&(destination->email), source + EMAIL_OFFSET, EMAIL_SIZE);
 }
 
+void* get_page(Pager* pager, uint32_t page_num) {
+  if (page_num > TABLE_MAX_PAGES) {
+    printf("Tried to fetch page number out of bounds. %d > %d\n", page_num,
+           TABLE_MAX_PAGES);
+    exit(EXIT_FAILURE);
+  }
+
+  if (pager->pages[page_num] == NULL) {
+    // Cache miss. Allocate memory and load from file.
+    void* page = malloc(PAGE_SIZE);
+    uint32_t num_pages = pager->file_length / PAGE_SIZE;
+
+    // We might save a partial page at the end of the file
+    if (pager->file_length % PAGE_SIZE) {
+      num_pages += 1;
+    }
+
+    if (page_num <= num_pages) {
+      lseek(pager->file_descriptor, page_num * PAGE_SIZE, SEEK_SET);
+      ssize_t bytes_read = read(pager->file_descriptor, page, PAGE_SIZE);
+      if (bytes_read == -1) {
+        printf("Error reading file: %d\n", errno);
+        exit(EXIT_FAILURE);
+      }
+    }
+
+    pager->pages[page_num] = page;
+  }
+
+  return pager->pages[page_num];
+}
+
 void* row_slot(Table* table, uint32_t row_num) {
   uint32_t page_num = row_num / ROWS_PER_PAGE;
-  void* page = table->pages[page_num];
-  if (!page) {
-    // Allocate memory only when we try to access page
-    page = table->pages[page_num] = malloc(PAGE_SIZE);
-  }
+  void* page = get_page(table->pager, page_num);
   uint32_t row_offset = row_num % ROWS_PER_PAGE;
   uint32_t byte_offset = row_offset * ROW_SIZE;
   return page + byte_offset;
 }
 
-Table* new_table() {
+Pager* pager_open(const char* filename) {
+  int fd = open(filename,
+                O_RDWR |      // Read/Write mode
+                    O_CREAT,  // Create file if it does not exist
+                S_IWUSR |     // User write permission
+                    S_IRUSR   // User read permission
+                );
+
+  if (fd == -1) {
+    printf("Unable to open file\n");
+    exit(EXIT_FAILURE);
+  }
+
+  off_t file_length = lseek(fd, 0, SEEK_END);
+
+  Pager* pager = malloc(sizeof(Pager));
+  pager->file_descriptor = fd;
+  pager->file_length = file_length;
+
+  for (uint32_t i = 0; i < TABLE_MAX_PAGES; i++) {
+    pager->pages[i] = NULL;
+  }
+
+  return pager;
+}
+
+Table* db_open(const char* filename) {
+  Pager* pager = pager_open(filename);
+  uint32_t num_rows = pager->file_length / ROW_SIZE;
+
   Table* table = malloc(sizeof(Table));
-  table->num_rows = 0;
+  table->pager = pager;
+  table->num_rows = num_rows;
 
   return table;
 }
@@ -127,8 +195,71 @@ void read_input(InputBuffer* input_buffer) {
   input_buffer->buffer[bytes_read - 1] = 0;
 }
 
-MetaCommandResult do_meta_command(InputBuffer* input_buffer) {
+void pager_flush(Pager* pager, uint32_t page_num, uint32_t size) {
+  if (pager->pages[page_num] == NULL) {
+    printf("Tried to flush null page\n");
+    exit(EXIT_FAILURE);
+  }
+
+  off_t offset = lseek(pager->file_descriptor, page_num * PAGE_SIZE, SEEK_SET);
+
+  if (offset == -1) {
+    printf("Error seeking: %d\n", errno);
+    exit(EXIT_FAILURE);
+  }
+
+  ssize_t bytes_written =
+      write(pager->file_descriptor, pager->pages[page_num], size);
+
+  if (bytes_written == -1) {
+    printf("Error writing: %d\n", errno);
+    exit(EXIT_FAILURE);
+  }
+}
+
+void db_close(Table* table) {
+  Pager* pager = table->pager;
+  uint32_t num_full_pages = table->num_rows / ROWS_PER_PAGE;
+
+  for (uint32_t i = 0; i < num_full_pages; i++) {
+    if (pager->pages[i] == NULL) {
+      continue;
+    }
+    pager_flush(pager, i, PAGE_SIZE);
+    free(pager->pages[i]);
+    pager->pages[i] = NULL;
+  }
+
+  // There may be a partial page to write to the end of the file
+  // This should not be needed after we switch to a B-tree
+  uint32_t num_additional_rows = table->num_rows % ROWS_PER_PAGE;
+  if (num_additional_rows > 0) {
+    uint32_t page_num = num_full_pages;
+    if (pager->pages[page_num] != NULL) {
+      pager_flush(pager, page_num, num_additional_rows * ROW_SIZE);
+      free(pager->pages[page_num]);
+      pager->pages[page_num] = NULL;
+    }
+  }
+
+  int result = close(pager->file_descriptor);
+  if (result == -1) {
+    printf("Error closing db file.\n");
+    exit(EXIT_FAILURE);
+  }
+  for (uint32_t i = 0; i < TABLE_MAX_PAGES; i++) {
+    void* page = pager->pages[i];
+    if (page) {
+      free(page);
+      pager->pages[i] = NULL;
+    }
+  }
+  free(pager);
+}
+
+MetaCommandResult do_meta_command(InputBuffer* input_buffer, Table* table) {
   if (strcmp(input_buffer->buffer, ".exit") == 0) {
+    db_close(table);
     exit(EXIT_SUCCESS);
   } else {
     return META_COMMAND_UNRECOGNIZED_COMMAND;
@@ -210,14 +341,21 @@ ExecuteResult execute_statement(Statement* statement, Table* table) {
 }
 
 int main(int argc, char* argv[]) {
-  Table* table = new_table();
+  if (argc < 2) {
+    printf("Must supply a database filename.\n");
+    exit(EXIT_FAILURE);
+  }
+
+  char* filename = argv[1];
+  Table* table = db_open(filename);
+
   InputBuffer* input_buffer = new_input_buffer();
   while (true) {
     print_prompt();
     read_input(input_buffer);
 
     if (input_buffer->buffer[0] == '.') {
-      switch (do_meta_command(input_buffer)) {
+      switch (do_meta_command(input_buffer, table)) {
         case (META_COMMAND_SUCCESS):
           continue;
         case (META_COMMAND_UNRECOGNIZED_COMMAND):
diff --git a/spec/main_spec.rb b/spec/main_spec.rb
index 21561ce..bc0180a 100644
--- a/spec/main_spec.rb
+++ b/spec/main_spec.rb
@@ -1,7 +1,11 @@
 describe 'database' do
+  before do
+    `rm -rf test.db`
+  end
+
   def run_script(commands)
     raw_output = nil
-    IO.popen("./db", "r+") do |pipe|
+    IO.popen("./db test.db", "r+") do |pipe|
       commands.each do |command|
         pipe.puts command
       end
@@ -28,6 +32,27 @@ describe 'database' do
     ])
   end
 
+  it 'keeps data after closing connection' do
+    result1 = run_script([
+      "insert 1 user1 person1@example.com",
+      ".exit",
+    ])
+    expect(result1).to match_array([
+      "db > Executed.",
+      "db > ",
+    ])
+
+    result2 = run_script([
+      "select",
+      ".exit",
+    ])
+    expect(result2).to match_array([
+      "db > (1, user1, person1@example.com)",
+      "Executed.",
+      "db > ",
+    ])
+  end
+
   it 'prints error message when table is full' do
     script = (1..1401).map do |i|
       "insert #{i} user#{i} person#{i}@example.com"
And the diff to our tests:

 describe 'database' do
+  before do
+    `rm -rf test.db`
+  end
+
   def run_script(commands)
     raw_output = nil
-    IO.popen("./db", "r+") do |pipe|
+    IO.popen("./db test.db", "r+") do |pipe|
       commands.each do |command|
         pipe.puts command
       end
@@ -28,6 +32,27 @@ describe 'database' do
     ])
   end
 
+  it 'keeps data after closing connection' do
+    result1 = run_script([
+      "insert 1 user1 person1@example.com",
+      ".exit",
+    ])
+    expect(result1).to match_array([
+      "db > Executed.",
+      "db > ",
+    ])
+
+    result2 = run_script([
+      "select",
+      ".exit",
+    ])
+    expect(result2).to match_array([
+      "db > (1, user1, person1@example.com)",
+      "Executed.",
+      "db > ",
+    ])
+  end
+
   it 'prints error message when table is full' do
     script = (1..1401).map do |i|
       "insert #{i} user#{i} person#{i}@example.com"
```



