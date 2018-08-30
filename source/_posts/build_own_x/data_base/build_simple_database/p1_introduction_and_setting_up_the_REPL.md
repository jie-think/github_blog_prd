---
title: Build a Simple Database - Introduction and Setting up the REPL
date: 2018-05-17 19:59:57
categories:
- build-own-x
tags:
- database
- db原理
---

# Part 1 - Introduction and Setting up the REPL



# Sqlite

There’s lots of [documentation of sqlite internals](https://www.sqlite.org/arch.html) on their website, plus I’ve got a copy of [SQLite Database System: Design and Implementation](https://play.google.com/store/books/details?id=9Z6IQQnX1JEC).

 ![https://cstack.github.io/db_tutorial/assets/images/arch1.gif](https://cstack.github.io/db_tutorial/assets/images/arch1.gif)

sqlite architecture (https://www.sqlite.org/zipvfs/doc/trunk/www/howitworks.wiki)



分成前后端:

前端部分:

- tokenizer
- parser
- code generator

后端部分:

- virtual machine
- B-tree
- pager
- os interface



[A journey of a thousand miles begins with a single step(千里之行始于足下)](https://en.wiktionary.org/wiki/a_journey_of_a_thousand_miles_begins_with_a_single_step), so let’s start with something a little more straightforward: the REPL.

**REPL:** *read-execute-print*

```C
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







