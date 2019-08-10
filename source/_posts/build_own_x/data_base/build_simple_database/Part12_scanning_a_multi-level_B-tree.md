---
titile: Part 12 - Scanning a Multi-Level B-Tree
date: 2019-03-09 11:05:29
categories:
- build-own-x
tags:
- database
- db原理
---

# Part12 扫描多层 B 树

我们现在支持构建一个多层的 B 树, 但是对于 select 语句确还不支持, 这是一个插入15条记录的然后打印它们的测试例子.
```c
+  it 'prints all rows in a multi-level tree' do
+    script = []
+    (1..15).each do |i|
+      script << "insert #{i} user#{i} person#{i}@example.com"
+    end
+    script << "select"
+    script << ".exit"
+    result = run_script(script)
+
+    expect(result[15...result.length]).to match_array([
+      "db > (1, user1, person1@example.com)",
+      "(2, user2, person2@example.com)",
+      "(3, user3, person3@example.com)",
+      "(4, user4, person4@example.com)",
+      "(5, user5, person5@example.com)",
+      "(6, user6, person6@example.com)",
+      "(7, user7, person7@example.com)",
+      "(8, user8, person8@example.com)",
+      "(9, user9, person9@example.com)",
+      "(10, user10, person10@example.com)",
+      "(11, user11, person11@example.com)",
+      "(12, user12, person12@example.com)",
+      "(13, user13, person13@example.com)",
+      "(14, user14, person14@example.com)",
+      "(15, user15, person15@example.com)",
+      "Executed.", "db > ",
+    ])
+  end
```

但是当我们跑这个例子的时候, 会发生下面这样的情况:
```sh
db > select
(2, user1, person1@example.com)
Executed.
```
这太糟糕了, 仅打印了一条语句, 并且看起来这条记录好像损坏了. 

这糟糕的情况是因为 `execute_select()` 方法在表开始的时候, 我们当前接口`table_start()` 返回 的是根节点. 但是现在根节点现在是一个中间节点,不包含任何行信息. 打印的数据必须在根节点为叶子时保留. `execute_select()` 应该返回第0个 cell 最左边的叶子节点.

所以我们需要改进下旧的实现.
```c
-Cursor* table_start(Table* table) {
-  Cursor* cursor = malloc(sizeof(Cursor));
-  cursor->table = table;
-  cursor->page_num = table->root_page_num;
-  cursor->cell_num = 0;
-
-  void* root_node = get_page(table->pager, table->root_page_num);
-  uint32_t num_cells = *leaf_node_num_cells(root_node);
-  cursor->end_of_table = (num_cells == 0);
-
-  return cursor;
-}
```

并添加一个新的实现, 如果第0个 key 不存在, 这个方法将会返回一个最低位置的指针回去.
```c
+Cursor* table_start(Table* table) {
+  Cursor* cursor =  table_find(table, 0);
+
+  void* node = get_page(table->pager, cursor->page_num);
+  uint32_t num_cells = *leaf_node_num_cells(node);
+  cursor->end_of_table = (num_cells == 0);
+
+  return cursor;
+}
```

通过这些改变,它依旧只会打印一个节点的行数据:
```sh
db > select
(1, user1, person1@example.com)
(2, user2, person2@example.com)
(3, user3, person3@example.com)
(4, user4, person4@example.com)
(5, user5, person5@example.com)
(6, user6, person6@example.com)
(7, user7, person7@example.com)
Executed.
db >
```

有15条数据, 那么就包含1个中间节点和两个叶子节点, 它看起来就像这样:
![structure of our btree](https://cstack.github.io/db_tutorial/assets/images/btree3.png)
structure of our btree

要扫描整个表，我们需要在到达第一个叶节点后跳转到第二个叶节点。为此，我们将在名为“next_leaf”的叶节点标题中保存一个新字段，该字段将保存右侧叶子的兄弟节点的页码。最右边的叶节点将具有next_leaf值0以表示没有兄弟（无论如何，页0都保留给表的根节点）。

更新叶节点标头格式以包含新字段:

```sh
 const uint32_t LEAF_NODE_NUM_CELLS_SIZE = sizeof(uint32_t);
 const uint32_t LEAF_NODE_NUM_CELLS_OFFSET = COMMON_NODE_HEADER_SIZE;
-const uint32_t LEAF_NODE_HEADER_SIZE =
-    COMMON_NODE_HEADER_SIZE + LEAF_NODE_NUM_CELLS_SIZE;
+const uint32_t LEAF_NODE_NEXT_LEAF_SIZE = sizeof(uint32_t);
+const uint32_t LEAF_NODE_NEXT_LEAF_OFFSET =
+    LEAF_NODE_NUM_CELLS_OFFSET + LEAF_NODE_NUM_CELLS_SIZE;
+const uint32_t LEAF_NODE_HEADER_SIZE = COMMON_NODE_HEADER_SIZE +
+                                       LEAF_NODE_NUM_CELLS_SIZE +
+                                       LEAF_NODE_NEXT_LEAF_SIZE;
```

添加一个新的方法去访问新的文件:
```sh
+uint32_t* leaf_node_next_leaf(void* node) {
+  return node + LEAF_NODE_NEXT_LEAF_OFFSET;
+}
```



