---
title: goose learn start
date: 2018-08-29 20:12:00
categories:
- backend
tags:
- go
- goose
---

## what goose

> goose is a database migration tool.
> You can manage your database's evolution by creating incremental SQL or Go scripts.

## install

这个前提是需要安装 golang, 并会就 `goose` 命令生成到 `$GOPATH/bin` 目录下.
```shell
$ go get bitbucket.org/liamstask/goose/cmd/goose
```

## Usage

```shell
$ goose

goose is a database migration management system for Go projects.

Usage:
    goose [options] <subcommand> [subcommand options]

Options:
  -env string
    	which DB environment to use (default "development")
  -path string
    	folder containing db info (default "db")
  -pgschema string
    	which postgres-schema to migrate (default = none)

Commands:
    up         Migrate the DB to the most recent version available
    down       Roll back the version by 1
    redo       Re-run the latest migration
    status     dump the migration status for the current DB
    create     Create the scaffolding for a new migration
    dbversion  Print the current version of the database

```

### create

创建一个新的 migration , 这个创建的是 go migration
```shell
goose create AddSomeColumns
```

如果是创建 sql migration 的话, 在后边加个 sql 即可.
```shell
goose create AddSomeColumns sql
```

### up 

应用所有可用的 migrations

```shell
goose up
```

### down

从当前版本回滚单个 migrations
```shell
goose down
```

### redo

回滚最近应用的 migrations ，然后再次运行它。

```shell
goose redo
```

### status
打印所有 migrations 的状态：

```shell
goose status
```

### dbversion

```shell
goose dbversion
```

## 个人实验数据


### 配置如下:

目录结构:

jieLearn/
├── dbconf.yml
└── migrations
    ├── 20180829163647_jieTest.sql
    └── 20180829165529_addC4Col.sql

```shell
$ cat dbconf.yml

development:
    driver: mysql
    open: root:password@tcp(127.0.0.1:3306)/jie_test?timeout=200ms&parseTime=true&loc=Local

```


```shell
$ cat jieLearn/migrations/20180829163647_jieTest.sql

-- +goose Up
-- SQL in section 'Up' is executed when this migration is applied
CREATE TABLE `jie_test`.`test_table` (
  `c1` INT NOT NULL,
  `c2` VARCHAR(45) NULL,
  `c3` VARCHAR(45) NULL,
  PRIMARY KEY (`c1`));


-- +goose Down
-- SQL section 'Down' is executed when this migration is rolled back
DROP TABLE `jie_test`.`test_table`;


$ cat jieLearn/migrations/20180829165529_addC4Col.sql

-- +goose Up
-- SQL in section 'Up' is executed when this migration is applied
ALTER TABLE `jie_test`.`test_table`
ADD COLUMN `c4` VARCHAR(45) NULL AFTER `c3`;



-- +goose Down
-- SQL section 'Down' is executed when this migration is rolled back
ALTER TABLE `jie_test`.`test_table`
DROP COLUMN `c4`;


$ goose -path "jieLearn" up
$ goose -path "jieLearn" down

```

### 数据库

new table: goose_db_version, test_table

goose_db_version: content
```
1	0	1	2018-08-29 08:33:23
2	20180829163647	1	2018-08-29 08:33:23
3	20180829163647	0	2018-08-29 08:34:53
4	20180829163647	1	2018-08-29 08:35:35
5	20180829165529	1	2018-08-29 08:42:39
6	20180829165529	0	2018-08-29 08:43:00
```



参考: [https://bitbucket.org/liamstask/goose](https://bitbucket.org/liamstask/goose)
