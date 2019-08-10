---
title: Part 4 - 第一个单元测试类(和一些 Bugs)
date: 2019-01-28 16:11:20
categories:
- build-own-x
tags:
- database
- db原理
---

Part 4 - 第一个单元测试类(和一些 Bugs)

我们可以插入一些行数据到我们的数据库中并且打印它们, 现在让我们花点时间测试下我们的代码吧.

我将会使用 [rspec](http://rspec.info/) 来进行测试, 因为对它们比较熟悉, 并且具有可读性.

我定义了一个简短的帮助函数向 db 程序发送一个命令集合, 然后为输出做短语.

```ruby
describe 'database' do
  def run_script(commands)
    raw_output = nil
    IO.popen("./db", "r+") do |pipe|
      commands.each do |command|
        pipe.puts command
      end

      pipe.close_write

      # Read entire output
      raw_output = pipe.gets(nil)
    end
    raw_output.split("\n")
  end

  it 'inserts and retreives a row' do
    result = run_script([
      "insert 1 user1 person1@example.com",
      "select",
      ".exit",
    ])
    expect(result).to match_array([
      "db > Executed.",
      "db > (1, user1, person1@example.com)",
      "Executed.",
      "db > ",
    ])
  end
end
```

这个简单的测试可以帮助我们确定输入和输出对应的内容.

```sh
bundle exec rspec
.

Finished in 0.00871 seconds (files took 0.09506 seconds to load)
1 example, 0 failures
```

现在将大量的数据插入数据库中变的可行了:

```ruby
it 'prints error message when table is full' do
  script = (1..1401).map do |i|
    "insert #{i} user#{i} person#{i}@example.com"
  end
  script << ".exit"
  result = run_script(script)
  expect(result[-2]).to eq('db > Error: Table full.')
end
```

再次跑测试用例..

```sh
bundle exec rspec
..

Finished in 0.01553 seconds (files took 0.08156 seconds to load)
2 examples, 0 failures
```

美滋滋, 它是能正常工作的! 我们的 db 现在可以存错1400条数据, 因为我们设置了最大页面数是100, 且一页有 14 条数据.

阅读到这里, 我意识到我们可能没有办法正常的处理文本数据, 我们可以从下面的例子中体现出来.

```c
it 'allows inserting strings that are the maximum length' do
  long_username = "a"*32
  long_email = "a"*255
  script = [
    "insert 1 #{long_username} #{long_email}",
    "select",
    ".exit",
  ]
  result = run_script(script)
  expect(result).to match_array([
    "db > Executed.",
    "db > (1, #{long_username}, #{long_email})",
    "Executed.",
    "db > ",
  ])
end
```

测试失败了!

```sh
Failures:

  1) database allows inserting strings that are the maximum length
     Failure/Error: raw_output.split("\n")

     ArgumentError:
       invalid byte sequence in UTF-8
     # ./spec/main_spec.rb:14:in `split'
     # ./spec/main_spec.rb:14:in `run_script'
     # ./spec/main_spec.rb:48:in `block (2 levels) in <top (required)>'
```

如果我们手动重试呢? 当我们尝试打印出行时，我们会看到有一些奇怪的字符

```sh
db > insert 1 aaaaa... aaaaa...
Executed.
db > select
(1, aaaaa...aaa\�, aaaaa...aaa\�)
Executed.
db >
```

这是咋回事呢? 如果你看一下我们对Row的定义，我们只为用户名分配32个字节，为电子邮件分配255个字节. 但是C字符串应该以空字符结尾，我们没有为其分配空间。解决方案是分配一个额外的字节:

```c
const uint32_t COLUMN_EMAIL_SIZE = 255;
 struct Row_t {
   uint32_t id;
-  char username[COLUMN_USERNAME_SIZE];
-  char email[COLUMN_EMAIL_SIZE];
+  char username[COLUMN_USERNAME_SIZE + 1];
+  char email[COLUMN_EMAIL_SIZE + 1];
 };
 typedef struct Row_t Row;
```

确定一下我们确实修复了它:
```sh
bundle exec rspec
...

Finished in 0.0188 seconds (files took 0.08516 seconds to load)
3 examples, 0 failures
```

我们应该不允许插入过长的用户名和邮件, `spec` 看起来就像这样:

```ruby
it 'prints error message if strings are too long' do
  long_username = "a"*33
  long_email = "a"*256
  script = [
    "insert 1 #{long_username} #{long_email}",
    "select",
    ".exit",
  ]
  result = run_script(script)
  expect(result).to match_array([
    "db > String is too long.",
    "db > Executed.",
    "db > ",
  ])
end
```

因此我们需要升级下我们的解析器, 我们当前用的是 `scanf()` 方法:

```c
if (strncmp(input_buffer->buffer, "insert", 6) == 0) {
  statement->type = STATEMENT_INSERT;
  int args_assigned = sscanf(
      input_buffer->buffer, "insert %d %s %s", &(statement->row_to_insert.id),
      statement->row_to_insert.username, statement->row_to_insert.email);
  if (args_assigned < 3) {
    return PREPARE_SYNTAX_ERROR;
  }
  return PREPARE_SUCCESS;
}
```

但是 `scanf` 存在一些缺点. 如果读取的字符串大于缓冲区, 它将导致缓冲区溢出问题, 并且开始写到不期望的地方. 我们想检查下每一个字符串的长度在将数据拷贝到行结构之前. 我们需要使用空格去划分它.

我将使用 `strtok()` 方法, 我想这应该不难理解.

```c
+PrepareResult prepare_insert(InputBuffer* input_buffer, Statement* statement) {
+  statement->type = STATEMENT_INSERT;
+
+  char* keyword = strtok(input_buffer->buffer, " ");
+  char* id_string = strtok(NULL, " ");
+  char* username = strtok(NULL, " ");
+  char* email = strtok(NULL, " ");
+
+  if (id_string == NULL || username == NULL || email == NULL) {
+    return PREPARE_SYNTAX_ERROR;
+  }
+
+  int id = atoi(id_string);
+  if (strlen(username) > COLUMN_USERNAME_SIZE) {
+    return PREPARE_STRING_TOO_LONG;
+  }
+  if (strlen(email) > COLUMN_EMAIL_SIZE) {
+    return PREPARE_STRING_TOO_LONG;
+  }
+
+  statement->row_to_insert.id = id;
+  strcpy(statement->row_to_insert.username, username);
+  strcpy(statement->row_to_insert.email, email);
+
+  return PREPARE_SUCCESS;
+}
+
 PrepareResult prepare_statement(InputBuffer* input_buffer,
                                 Statement* statement) {
   if (strncmp(input_buffer->buffer, "insert", 6) == 0) {
+    return prepare_insert(input_buffer, statement);
-    statement->type = STATEMENT_INSERT;
-    int args_assigned = sscanf(
-        input_buffer->buffer, "insert %d %s %s", &(statement->row_to_insert.id),
-        statement->row_to_insert.username, statement->row_to_insert.email);
-    if (args_assigned < 3) {
-      return PREPARE_SYNTAX_ERROR;
-    }
-    return PREPARE_SUCCESS;
   }
```

在输入缓冲区上连续调用strtok会在到达分隔符（在我们的例子中为空格）时通过插入空字符将其分解为子字符串。它返回指向子字符串开头的指针。

我们可以在每个文本值上调用`strlen()`来查看它是否太长。

我们可以像处理任何其他错误代码一样处理错误：

```c
enum PrepareResult_t {
   PREPARE_SUCCESS,
+  PREPARE_STRING_TOO_LONG,
   PREPARE_SYNTAX_ERROR,
   PREPARE_UNRECOGNIZED_STATEMENT
 };
```

```c
switch (prepare_statement(input_buffer, &statement)) {
   case (PREPARE_SUCCESS):
     break;
+  case (PREPARE_STRING_TOO_LONG):
+    printf("String is too long.\n");
+    continue;
   case (PREPARE_SYNTAX_ERROR):
     printf("Syntax error. Could not parse statement.\n");
     continue;
```

使我们的测试用例通过

```sh
bundle exec rspec
....

Finished in 0.02284 seconds (files took 0.116 seconds to load)
4 examples, 0 failures
```

虽然,我们在这里了,但是我们还有一个错误需要处理:

```ruby
it 'prints an error message if id is negative' do
  script = [
    "insert -1 cstack foo@bar.com",
    "select",
    ".exit",
  ]
  result = run_script(script)
  expect(result).to match_array([
    "db > ID must be positive.",
    "db > Executed.",
    "db > ",
  ])
end
```

```c
enum PrepareResult_t {
   PREPARE_SUCCESS,
+  PREPARE_NEGATIVE_ID,
   PREPARE_STRING_TOO_LONG,
   PREPARE_SYNTAX_ERROR,
   PREPARE_UNRECOGNIZED_STATEMENT
@@ -148,9 +147,6 @@ PrepareResult prepare_insert(InputBuffer* input_buffer, Statement* statement) {
   }

   int id = atoi(id_string);
+  if (id < 0) {
+    return PREPARE_NEGATIVE_ID;
+  }
   if (strlen(username) > COLUMN_USERNAME_SIZE) {
     return PREPARE_STRING_TOO_LONG;
   }
@@ -230,9 +226,6 @@ int main(int argc, char* argv[]) {
     switch (prepare_statement(input_buffer, &statement)) {
       case (PREPARE_SUCCESS):
         break;
+      case (PREPARE_NEGATIVE_ID):
+        printf("ID must be positive.\n");
+        continue;
       case (PREPARE_STRING_TOO_LONG):
         printf("String is too long.\n");
         continue;
```

好的,现在应该测试的差不多了, 下一步,将是一个非常重要的特性: 持久化! 我们将保存我们的数据到一个文件中并且将其读回到内存中.

代码完整的修改部分:

```c
enum PrepareResult_t {
   PREPARE_SUCCESS,
+  PREPARE_NEGATIVE_ID,
+  PREPARE_STRING_TOO_LONG,
   PREPARE_SYNTAX_ERROR,
   PREPARE_UNRECOGNIZED_STATEMENT
 };
@@ -33,8 +35,8 @@ const uint32_t COLUMN_USERNAME_SIZE = 32;
 const uint32_t COLUMN_EMAIL_SIZE = 255;
 struct Row_t {
   uint32_t id;
-  char username[COLUMN_USERNAME_SIZE];
-  char email[COLUMN_EMAIL_SIZE];
+  char username[COLUMN_USERNAME_SIZE + 1];
+  char email[COLUMN_EMAIL_SIZE + 1];
 };
 typedef struct Row_t Row;
 
@@ -133,17 +135,40 @@ MetaCommandResult do_meta_command(InputBuffer* input_buffer) {
   }
 }
 
+PrepareResult prepare_insert(InputBuffer* input_buffer, Statement* statement) {
+  statement->type = STATEMENT_INSERT;
+
+  char* keyword = strtok(input_buffer->buffer, " ");
+  char* id_string = strtok(NULL, " ");
+  char* username = strtok(NULL, " ");
+  char* email = strtok(NULL, " ");
+
+  if (id_string == NULL || username == NULL || email == NULL) {
+    return PREPARE_SYNTAX_ERROR;
+  }
+
+  int id = atoi(id_string);
+  if (id < 0) {
+    return PREPARE_NEGATIVE_ID;
+  }
+  if (strlen(username) > COLUMN_USERNAME_SIZE) {
+    return PREPARE_STRING_TOO_LONG;
+  }
+  if (strlen(email) > COLUMN_EMAIL_SIZE) {
+    return PREPARE_STRING_TOO_LONG;
+  }
+
+  statement->row_to_insert.id = id;
+  strcpy(statement->row_to_insert.username, username);
+  strcpy(statement->row_to_insert.email, email);
+
+  return PREPARE_SUCCESS;
+}
+
 PrepareResult prepare_statement(InputBuffer* input_buffer,
                                 Statement* statement) {
   if (strncmp(input_buffer->buffer, "insert", 6) == 0) {
-    statement->type = STATEMENT_INSERT;
-    int args_assigned = sscanf(
-        input_buffer->buffer, "insert %d %s %s", &(statement->row_to_insert.id),
-        statement->row_to_insert.username, statement->row_to_insert.email);
-    if (args_assigned < 3) {
-      return PREPARE_SYNTAX_ERROR;
-    }
-    return PREPARE_SUCCESS;
+    return prepare_insert(input_buffer, statement);
   }
   if (strcmp(input_buffer->buffer, "select") == 0) {
     statement->type = STATEMENT_SELECT;
@@ -205,6 +230,12 @@ int main(int argc, char* argv[]) {
     switch (prepare_statement(input_buffer, &statement)) {
       case (PREPARE_SUCCESS):
         break;
+      case (PREPARE_NEGATIVE_ID):
+        printf("ID must be positive.\n");
+        continue;
+      case (PREPARE_STRING_TOO_LONG):
+        printf("String is too long.\n");
+        continue;
       case (PREPARE_SYNTAX_ERROR):
         printf("Syntax error. Could not parse statement.\n");
         continue;
```

我们添加的单元测试:

```ruby
+describe 'database' do
+  def run_script(commands)
+    raw_output = nil
+    IO.popen("./db", "r+") do |pipe|
+      commands.each do |command|
+        pipe.puts command
+      end
+
+      pipe.close_write
+
+      # Read entire output
+      raw_output = pipe.gets(nil)
+    end
+    raw_output.split("\n")
+  end
+
+  it 'inserts and retreives a row' do
+    result = run_script([
+      "insert 1 user1 person1@example.com",
+      "select",
+      ".exit",
+    ])
+    expect(result).to match_array([
+      "db > Executed.",
+      "db > (1, user1, person1@example.com)",
+      "Executed.",
+      "db > ",
+    ])
+  end
+
+  it 'prints error message when table is full' do
+    script = (1..1401).map do |i|
+      "insert #{i} user#{i} person#{i}@example.com"
+    end
+    script << ".exit"
+    result = run_script(script)
+    expect(result[-2]).to eq('db > Error: Table full.')
+  end
+
+  it 'allows inserting strings that are the maximum length' do
+    long_username = "a"*32
+    long_email = "a"*255
+    script = [
+      "insert 1 #{long_username} #{long_email}",
+      "select",
+      ".exit",
+    ]
+    result = run_script(script)
+    expect(result).to match_array([
+      "db > Executed.",
+      "db > (1, #{long_username}, #{long_email})",
+      "Executed.",
+      "db > ",
+    ])
+  end
+
+  it 'prints error message if strings are too long' do
+    long_username = "a"*33
+    long_email = "a"*256
+    script = [
+      "insert 1 #{long_username} #{long_email}",
+      "select",
+      ".exit",
+    ]
+    result = run_script(script)
+    expect(result).to match_array([
+      "db > String is too long.",
+      "db > Executed.",
+      "db > ",
+    ])
+  end
+
+  it 'prints an error message if id is negative' do
+    script = [
+      "insert -1 cstack foo@bar.com",
+      "select",
+      ".exit",
+    ]
+    result = run_script(script)
+    expect(result).to match_array([
+      "db > ID must be positive.",
+      "db > Executed.",
+      "db > ",
+    ])
+  end
+end
```