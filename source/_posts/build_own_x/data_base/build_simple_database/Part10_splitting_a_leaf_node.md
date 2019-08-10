---
title: Part 10 - Splitting a Leaf Node
date: 2019-02-23 21:33:19
categories:
- build-own-x
tags:
- database
- db原理
---

# Part 10 - 分割叶子节点

我们的 B树现在仅有一个节点. 修复它, 我们需要一些代码去分割一个叶子节点. 在哪之后我们需要去创建一个中间节点作为两个叶子节点的中间节点.
基本上我们这篇文章的目标就是从这样:
![one-node btree](https://cstack.github.io/db_tutorial/assets/images/btree2.png)
one-node btree

到这样:
![two-level btree](https://cstack.github.io/db_tutorial/assets/images/btree3.png)
two-level btree

第一步, 先让我们移除叶子节点填充完的错误.
```c
void leaf_node_insert(Cursor* cursor, uint32_t key, Row* value) {
   void* node = get_page(cursor->table->pager, cursor->page_num);
 
   uint32_t num_cells = *leaf_node_num_cells(node);
   if (num_cells >= LEAF_NODE_MAX_CELLS) {
     // Node full
-    printf("Need to implement splitting a leaf node.\n");
-    exit(EXIT_FAILURE);
+    leaf_node_split_and_insert(cursor, key, value);
+    return;
   }
```

```c
ExecuteResult execute_insert(Statement* statement, Table* table) {
   void* node = get_page(table->pager, table->root_page_num);
   uint32_t num_cells = (*leaf_node_num_cells(node));
-  if (num_cells >= LEAF_NODE_MAX_CELLS) {
-    return EXECUTE_TABLE_FULL;
-  }
 
   Row* row_to_insert = &(statement->row_to_insert);
   uint32_t key_to_insert = row_to_insert->id;
```

## 切分算法

简单的部分结束了. 从 sqlite 官网获得的一些描述信息: https://play.google.com/store/books/details/Sibsankar_Haldar_SQLite_Database_System_Design_and?id=9Z6IQQnX1JEC&hl=en

> If there is no space on the leaf node, we would split the existing entries residing there and the new one (being inserted) into two equal halves: lower and upper halves. (Keys on the upper half are strictly greater than those on the lower half.) We allocate a new leaf node, and move the upper half into the new node.

> 如果叶子节点没有空间了, 我们会将驻留在那里的现有条目和新的条目（被插入）分成两半：下半部分和上半部分.  (上半部分的键严格大于下半部分的键.) 我们分配一个新的叶子节点，并将上半部分移动到新节点.

让我来处理旧的节点并且创建一个新的节点:
```c
+void leaf_node_split_and_insert(Cursor* cursor, uint32_t key, Row* value) {
+  /*
+  Create a new node and move half the cells over.
+  Insert the new value in one of the two nodes.
+  Update parent or create a new parent.
+  */
+
+  void* old_node = get_page(cursor->table->pager, cursor->page_num);
+  uint32_t new_page_num = get_unused_page_num(cursor->table->pager);
+  void* new_node = get_page(cursor->table->pager, new_page_num);
+  initialize_leaf_node(new_node);
```

下一步, 拷贝每一个 cell 到新的地方:

```c
+  /*
+  All existing keys plus new key should be divided
+  evenly between old (left) and new (right) nodes.
+  Starting from the right, move each key to correct position.
+  */
+  for (int32_t i = LEAF_NODE_MAX_CELLS; i >= 0; i--) {
+    void* destination_node;
+    if (i >= LEAF_NODE_LEFT_SPLIT_COUNT) {
+      destination_node = new_node;
+    } else {
+      destination_node = old_node;
+    }
+    uint32_t index_within_node = i % LEAF_NODE_LEFT_SPLIT_COUNT;
+    void* destination = leaf_node_cell(destination_node, index_within_node);
+
+    if (i == cursor->cell_num) {
+      serialize_row(value, destination);
+    } else if (i > cursor->cell_num) {
+      memcpy(destination, leaf_node_cell(old_node, i - 1), LEAF_NODE_CELL_SIZE);
+    } else {
+      memcpy(destination, leaf_node_cell(old_node, i), LEAF_NODE_CELL_SIZE);
+    }
+  }
```
更新 cell 的数量在每一个节点的头部:
```c
+  /* Update cell count on both leaf nodes */
+  *(leaf_node_num_cells(old_node)) = LEAF_NODE_LEFT_SPLIT_COUNT;
+  *(leaf_node_num_cells(new_node)) = LEAF_NODE_RIGHT_SPLIT_COUNT;
```
然后我们需要更新节点的父节点. 如果原节点是一个根节点就没有父节点了. 在这种情况下, 新建一个根节点去作为父节点. 我们先去除其它情况:
```c
+  if (is_node_root(old_node)) {
+    return create_new_root(cursor->table, new_page_num);
+  } else {
+    printf("Need to implement updating parent after split\n");
+    exit(EXIT_FAILURE);
+  }
+}
```

## 分配新的页

定义一些新的函数和常量. 当我们创建一个新的叶子节点的时, 我们将其放在由`get_unused_page_num()` 决定的页面中.
```c
+/*
+Until we start recycling free pages, new pages will always
+go onto the end of the database file
+*/
+uint32_t get_unused_page_num(Pager* pager) { return pager->num_pages; }
```

现在我们假设数据库现在有 N 页, 从 0 到 N -1 被分配完了. 我们总是能分配第 N 页. 最终我们实行删除后, 一些页面可能变成空并且他们的页码将不可用. 为了高效, 我们可以重新分配这些页面.

## 叶子节点的大小

为了让树保持平衡, 我们在两个新节点之间均匀分配cells. 如果一个叶子节点能保存 N 个 cell, 然后在分割的时候需要在两个节点间分配 N+1 的 cells. (N 为原始单元加一个新的单元). 如果 N+1 是一个基数, 我随意选择左节点再获得一个单元格.
```c
+const uint32_t LEAF_NODE_RIGHT_SPLIT_COUNT = (LEAF_NODE_MAX_CELLS + 1) / 2;
+const uint32_t LEAF_NODE_LEFT_SPLIT_COUNT =
+    (LEAF_NODE_MAX_CELLS + 1) - LEAF_NODE_RIGHT_SPLIT_COUNT;
```

## 创建一个新的根节点

以下是SQLite数据库系统如何解释创建新根节点的过程: https://play.google.com/store/books/details/Sibsankar_Haldar_SQLite_Database_System_Design_and?id=9Z6IQQnX1JEC&hl=en

> Let N be the root node. First allocate two nodes, say L and R. Move lower half of N into L and the upper half into R. Now N is empty. Add 〈L, K,R〉 in N, where K is the max key in L. Page N remains the root. Note that the depth of the tree has increased by one, but the new tree remains height balanced without violating any B+-tree property.
> 
> 设N为根节点. 首先, 分配两个节点 L 和 R. 移动低一半的 N 到 L 和 高一半到 R 中. 现在 N 是空的了. 在 N 中, 增加 <L, K, R>. 这里的 K 是 L 中的最大 key . 第 N 页依旧是根. 请注意，树的深度增加了1，但新树保持高度平衡而不违反任何B + tree属性。

在这一点上，我们已经分配了正确的孩子，并将上半部分移入其中. 我们的函数将正确的子项作为输入，并分配一个新页面来存储左子项.

```c
+void create_new_root(Table* table, uint32_t right_child_page_num) {
+  /*
+  Handle splitting the root.
+  Old root copied to new page, becomes left child.
+  Address of right child passed in.
+  Re-initialize root page to contain the new root node.
+  New root node points to two children.
+  */
+
+  void* root = get_page(table->pager, table->root_page_num);
+  void* right_child = get_page(table->pager, right_child_page_num);
+  uint32_t left_child_page_num = get_unused_page_num(table->pager);
+  void* left_child = get_page(table->pager, left_child_page_num);
```

旧的根数据被拷贝到左子项, 所以我能重用根页.
```c
+  /* Left child has data copied from old root */
+  memcpy(left_child, root, PAGE_SIZE);
+  set_node_root(left_child, false);
```

最后,我们初始化一个根页为有两个孩子的中间节点.
```c
+  /* Root node is a new internal node with one key and two children */
+  initialize_internal_node(root);
+  set_node_root(root, true);
+  *internal_node_num_keys(root) = 1;
+  *internal_node_child(root, 0) = left_child_page_num;
+  uint32_t left_child_max_key = get_node_max_key(left_child);
+  *internal_node_key(root, 0) = left_child_max_key;
+  *internal_node_right_child(root) = right_child_page_num;
+}
```

## 中间节点的格式

现在我们终于创建了一个内部节点, 我们现在去定义他的layout. 它一开始是一个普通的头, 然后是包含的键的数量, 然后是最右边孩子的页码. 内部节点总是有一个子指针而不是它们的键, 额外的指针存储在header 中.
```c
+/*
+ * Internal Node Header Layout
+ */
+const uint32_t INTERNAL_NODE_NUM_KEYS_SIZE = sizeof(uint32_t);
+const uint32_t INTERNAL_NODE_NUM_KEYS_OFFSET = COMMON_NODE_HEADER_SIZE;
+const uint32_t INTERNAL_NODE_RIGHT_CHILD_SIZE = sizeof(uint32_t);
+const uint32_t INTERNAL_NODE_RIGHT_CHILD_OFFSET =
+    INTERNAL_NODE_NUM_KEYS_OFFSET + INTERNAL_NODE_NUM_KEYS_SIZE;
+const uint32_t INTERNAL_NODE_HEADER_SIZE = COMMON_NODE_HEADER_SIZE +
+                                           INTERNAL_NODE_NUM_KEYS_SIZE +
+                                         INTERNAL_NODE_RIGHT_CHILD_SIZE;
```

内容时一个cells 的数组, 每一个 cell 包含一个子指针和一个键. 每个键应该是左侧子项中包含的最大键.
```c
+/*
+ * Internal Node Body Layout
+ */
+const uint32_t INTERNAL_NODE_KEY_SIZE = sizeof(uint32_t);
+const uint32_t INTERNAL_NODE_CHILD_SIZE = sizeof(uint32_t);
+const uint32_t INTERNAL_NODE_CELL_SIZE =
+    INTERNAL_NODE_CHILD_SIZE + INTERNAL_NODE_KEY_SIZE;
```

基于这些常量, 以下是内部节点的布局:

![Our internal node format](https://cstack.github.io/db_tutorial/assets/images/internal-node-format.png)
Our internal node format

注意我们巨大的变化. 因为每一个子指针和键值对都很小, 我们能够填充510 key 和511 个子指针,在每一个中间节点. 这意味着我们永远不必遍历树的许多层来找到给定的key.

| # internal node layers | max # leaf nodes | Size of all leaf nodes |
| ------- | -------- | -------- |
| 0 | 511^0 = 1 | 4 KB |
| 1 | 511^1 = 512 | ~2 MB |
| 2 | 511^2 = 261,121 | ~1 GB |
| 3 | 511^3 = 133,432,831 | ~550 GB |

实际上，由于头部信息，key和浪费空间的开销，我们无法为每个叶节点存储完整的4 KB数据。但是我们可以通过从磁盘加载仅4页来搜索500 GB的数据。这就是B-Tree是数据库的有用数据结构的原因。
以下是读取和写入内部节点的方法:
```c
+uint32_t* internal_node_num_keys(void* node) {
+  return node + INTERNAL_NODE_NUM_KEYS_OFFSET;
+}
+
+uint32_t* internal_node_right_child(void* node) {
+  return node + INTERNAL_NODE_RIGHT_CHILD_OFFSET;
+}
+
+uint32_t* internal_node_cell(void* node, uint32_t cell_num) {
+  return node + INTERNAL_NODE_HEADER_SIZE + cell_num * INTERNAL_NODE_CELL_SIZE;
+}
+
+uint32_t* internal_node_child(void* node, uint32_t child_num) {
+  uint32_t num_keys = *internal_node_num_keys(node);
+  if (child_num > num_keys) {
+    printf("Tried to access child_num %d > num_keys %d\n", child_num, num_keys);
+    exit(EXIT_FAILURE);
+  } else if (child_num == num_keys) {
+    return internal_node_right_child(node);
+  } else {
+    return internal_node_cell(node, child_num);
+  }
+}
+
+uint32_t* internal_node_key(void* node, uint32_t key_num) {
+  return internal_node_cell(node, key_num) + INTERNAL_NODE_CHILD_SIZE;
+}
```

对于内部节点，最大密钥始终是其右键。对于叶节点，它是最大索引处的键:
```c
+uint32_t get_node_max_key(void* node) {
+  switch (get_node_type(node)) {
+    case NODE_INTERNAL:
+      return *internal_node_key(node, *internal_node_num_keys(node) - 1);
+    case NODE_LEAF:
+      return *leaf_node_key(node, *leaf_node_num_cells(node) - 1);
+  }
+}
```

## 跟踪 Root

我们最终在公共节点头中使用了is_root字段。回想一下，我们使用它来决定如何拆分叶节点:

```c
+bool is_node_root(void* node) {
+  uint8_t value = *((uint8_t*)(node + IS_ROOT_OFFSET));
+  return (bool)value;
+}
+
+void set_node_root(void* node, bool is_root) {
+  uint8_t value = is_root;
+  *((uint8_t*)(node + IS_ROOT_OFFSET)) = value;
+}
```

以下是getter 和 setter 方法:
```c
+bool is_node_root(void* node) {
+  uint8_t value = *((uint8_t*)(node + IS_ROOT_OFFSET));
+  return (bool)value;
+}
+
+void set_node_root(void* node, bool is_root) {
+  uint8_t value = is_root;
+  *((uint8_t*)(node + IS_ROOT_OFFSET)) = value;
+}
```

初始化两种类型的节点应该默认将is_root设置为false：
```c
void initialize_leaf_node(void* node) {
   set_node_type(node, NODE_LEAF);
+  set_node_root(node, false);
   *leaf_node_num_cells(node) = 0;
 }

+void initialize_internal_node(void* node) {
+  set_node_type(node, NODE_INTERNAL);
+  set_node_root(node, false);
+  *internal_node_num_keys(node) = 0;
+}
```

我们应该在创建表的第一个节点时将is_root设置为true:

```c
     // New database file. Initialize page 0 as leaf node.
     void* root_node = get_page(pager, 0);
     initialize_leaf_node(root_node);
+    set_node_root(root_node, true);
   }
 
   return table;
```

## 打印树
为了帮助我们可视化数据库的状态，我们应该更新.btree metacommand以打印多级树.
我要替换当前的print_leaf_node（）函数.
```c
-void print_leaf_node(void* node) {
-  uint32_t num_cells = *leaf_node_num_cells(node);
-  printf("leaf (size %d)\n", num_cells);
-  for (uint32_t i = 0; i < num_cells; i++) {
-    uint32_t key = *leaf_node_key(node, i);
-    printf("  - %d : %d\n", i, key);
-  }
-}
```

使用一个新的递归函数，它接受任何节点，然后打印它及其子节点。它将缩进级别作为参数，随着每次递归调用而增加。我还添加了一个小的辅助函数来缩进。
```c
+void indent(uint32_t level) {
+  for (uint32_t i = 0; i < level; i++) {
+    printf("  ");
+  }
+}
+
+void print_tree(Pager* pager, uint32_t page_num, uint32_t indentation_level) {
+  void* node = get_page(pager, page_num);
+  uint32_t num_keys, child;
+
+  switch (get_node_type(node)) {
+    case (NODE_LEAF):
+      num_keys = *leaf_node_num_cells(node);
+      indent(indentation_level);
+      printf("- leaf (size %d)\n", num_keys);
+      for (uint32_t i = 0; i < num_keys; i++) {
+        indent(indentation_level + 1);
+        printf("- %d\n", *leaf_node_key(node, i));
+      }
+      break;
+    case (NODE_INTERNAL):
+      num_keys = *internal_node_num_keys(node);
+      indent(indentation_level);
+      printf("- internal (size %d)\n", num_keys);
+      for (uint32_t i = 0; i < num_keys; i++) {
+        child = *internal_node_child(node, i);
+        print_tree(pager, child, indentation_level + 1);
+
+        indent(indentation_level);
+        printf("- key %d\n", *internal_node_key(node, i));
+      }
+      child = *internal_node_right_child(node);
+      print_tree(pager, child, indentation_level + 1);
+      break;
+  }
+}
```

并更新对print函数的调用，将缩进级别传递给零.

```c
   } else if (strcmp(input_buffer->buffer, ".btree") == 0) {
     printf("Tree:\n");
-    print_leaf_node(get_page(table->pager, 0));
+    print_tree(table->pager, 0, 0);
     return META_COMMAND_SUCCESS;
```
这是新打印功能的测试用例
```ruby
+  it 'allows printing out the structure of a 3-leaf-node btree' do
+    script = (1..14).map do |i|
+      "insert #{i} user#{i} person#{i}@example.com"
+    end
+    script << ".btree"
+    script << "insert 15 user15 person15@example.com"
+    script << ".exit"
+    result = run_script(script)
+
+    expect(result[14...(result.length)]).to match_array([
+      "db > Tree:",
+      "- internal (size 1)",
+      "  - leaf (size 7)",
+      "    - 1",
+      "    - 2",
+      "    - 3",
+      "    - 4",
+      "    - 5",
+      "    - 6",
+      "    - 7",
+      "- key 7",
+      "  - leaf (size 7)",
+      "    - 8",
+      "    - 9",
+      "    - 10",
+      "    - 11",
+      "    - 12",
+      "    - 13",
+      "    - 14",
+      "db > Need to implement searching an internal node",
+    ])
+  end
```

新格式有点简化，所以我们需要更新现有的.btree测试:
```ruby
       "db > Executed.",
       "db > Executed.",
       "db > Tree:",
-      "leaf (size 3)",
-      "  - 0 : 1",
-      "  - 1 : 2",
-      "  - 2 : 3",
+      "- leaf (size 3)",
+      "  - 1",
+      "  - 2",
+      "  - 3",
       "db > "
     ])
   end
```
这是新测试的.btree输出：
```txt
Tree:
- internal (size 1)
  - leaf (size 7)
    - 1
    - 2
    - 3
    - 4
    - 5
    - 6
    - 7
  - key 7
  - leaf (size 7)
    - 8
    - 9
    - 10
    - 11
    - 12
    - 13
    - 14
```

## 主要问题
如果你一直密切关注，你可能会注意到我们错过了一些大事。看看如果我们尝试插入另一行会发生什么.
```sh
db > insert 15 user15 person15@example.com
Need to implement searching an internal node
```