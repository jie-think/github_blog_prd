---
title: Part 11 - Recursively Searching the B-Tree
date: 2019-02-24 22:08:35
categories:
- build-own-x
tags:
- database
- db原理
---

上次我们插入第15行时出错:
```sh
db > insert 15 user15 person15@example.com
Need to implement searching an internal node
```

首先，用新的函数调用替换代码存根.

```c
   if (get_node_type(root_node) == NODE_LEAF) {
     return leaf_node_find(table, root_page_num, key);
   } else {
-    printf("Need to implement searching an internal node\n");
-    exit(EXIT_FAILURE);
+    return internal_node_find(table, root_page_num, key);
   }
 }
```

此函数将执行二进制搜索以查找应包含给定键的子项。请记住，每个子指针右侧的键是该子项包含的最大键。

![three-level btree](https://cstack.github.io/db_tutorial/assets/images/btree6.png)
three-level btree

所以我们的二进制搜索比较了查找的键和子指针右侧的键:
```c
+Cursor* internal_node_find(Table* table, uint32_t page_num, uint32_t key) {
+  void* node = get_page(table->pager, page_num);
+  uint32_t num_keys = *internal_node_num_keys(node);
+
+  /* Binary search to find index of child to search */
+  uint32_t min_index = 0;
+  uint32_t max_index = num_keys; /* there is one more child than key */
+
+  while (min_index != max_index) {
+    uint32_t index = (min_index + max_index) / 2;
+    uint32_t key_to_right = *internal_node_key(node, index);
+    if (key_to_right >= key) {
+      max_index = index;
+    } else {
+      min_index = index + 1;
+    }
+  }
```

还要记住，内部节点的子节点可以是叶节点或更多内部节点。找到正确的孩子后，在其上调用相应的搜索功能:
```c
+  uint32_t child_num = *internal_node_child(node, min_index);
+  void* child = get_page(table->pager, child_num);
+  switch (get_node_type(child)) {
+    case NODE_LEAF:
+      return leaf_node_find(table, child_num, key);
+    case NODE_INTERNAL:
+      return internal_node_find(table, child_num, key);
+  }
+}
```

## 测试

现在，将密钥插入多节点btree不再导致错误。我们可以更新我们的测试:
```c
       "    - 12",
       "    - 13",
       "    - 14",
-      "db > Need to implement searching an internal node",
+      "db > Executed.",
+      "db > ",
     ])
   end
```

我也认为是时候重新考虑另一个测试了。尝试插入1400行的那个。它仍然是错误，但错误消息是新的。现在，当程序崩溃时，我们的测试不能很好地处理它。如果发生这种情况，让我们使用我们迄今为止得到的输出:

```c
     raw_output = nil
     IO.popen("./db test.db", "r+") do |pipe|
       commands.each do |command|
-        pipe.puts command
+        begin
+          pipe.puts command
+        rescue Errno::EPIPE
+          break
+        end
       end

       pipe.close_write
```

这表明我们的1400行测试输出了这个错误：

```c
     end
     script << ".exit"
     result = run_script(script)
-    expect(result[-2]).to eq('db > Error: Table full.')
+    expect(result.last(2)).to match_array([
+      "db > Executed.",
+      "db > Need to implement updating parent after split",
+    ])
   end
```
看起来就像我们的待办事项列表中的下一个!