# cron source code read

github: https://github.com/jakecoffman/cron

## 概念

**Cron**

​    控制板, 保存了所有的任务,有停止,添加,移除,snapshot 等操作通道.

**Entry**

​    任务项: 包含了一个 schedule 和一个需要执行的 func

**Schedule**

​	日程表: 描述了工作周期

## 使用示例

步骤:

> 1. new 控制板
> 2. 添加任务项
> 3. 启动任务

```go
// 1. new 控制板
c := cron.New()
// 2. 添加任务项
c.AddFunc("0 5 * * * *",  func() { fmt.Println("Every 5 minutes") }, "Often")
c.AddFunc("@hourly",      func() { fmt.Println("Every hour") }, "Frequent")
c.AddFunc("@every 1h30m", func() { fmt.Println("Every hour thirty") }, "Less Frequent")
// 3. 启动任务
c.Start()
..
// Funcs are invoked in their own goroutine, asynchronously.
...
// Funcs may also be added to a running Cron
c.AddFunc("@daily", func() { fmt.Println("Every day") }, "My Job")
..
// Inspect the cron job entries' next and previous run times.
inspect(c.Entries())
..
// Remove an entry from the cron by name.
c.RemoveJob("My Job")
..
c.Stop()  // Stop the scheduler (does not stop any jobs already running).
```



## 详细解析

### newCron

```go
func New() *Cron {
	return &Cron{
		entries:  nil,
		add:      make(chan *Entry),
		remove:   make(chan string),
		stop:     make(chan struct{}),
		snapshot: make(chan entries),
		running:  false,
	}
}
```



### AddFunc

AddFunc -> AddJob

```go
func (c *Cron) AddJob(spec string, cmd Job, name string) {
	c.Schedule(Parse(spec), cmd, name)
}
```

`Parse` 功能: 解析 `spec` 生成 `schedule` ,**生成的`schedule`很有意思哦!!**

`Schedule`主要职能:

> 1. new Entry
> 2. 添加 entry 到 cron 的 entries 中

### Start

go 程启动

```go
func (c *Cron) Start() {
	c.running = true
	go c.run()
}

// for 中 select 了解下
func (c *Cron) run() {
	// Figure out the next activation times for each entry.
	now := time.Now().Local()
	for _, entry := range c.entries {
		entry.Next = entry.Schedule.Next(now)
	}

	for {
		// Determine the next entry to run.
		sort.Sort(byTime(c.entries))

		var effective time.Time
		if len(c.entries) == 0 || c.entries[0].Next.IsZero() {
			// If there are no entries yet, just sleep - it still handles new entries
			// and stop requests.
			effective = now.AddDate(10, 0, 0)
		} else {
			effective = c.entries[0].Next
		}

		select {
		case now = <-time.After(effective.Sub(now)):
			// Run every entry whose next time was this effective time.
			for _, e := range c.entries {
				if e.Next != effective {
					break
				}
				go e.Job.Run()
				e.Prev = e.Next
				e.Next = e.Schedule.Next(effective)
			}
			continue

		case newEntry := <-c.add:
			i := c.entries.pos(newEntry.Name)
			if i != -1 {
				break
			}
			c.entries = append(c.entries, newEntry)
			newEntry.Next = newEntry.Schedule.Next(time.Now().Local())

		case name := <-c.remove:
			i := c.entries.pos(name)

			if i == -1 {
				break
			}

			c.entries = c.entries[:i+copy(c.entries[i:], c.entries[i+1:])]

		case <-c.snapshot:
			c.snapshot <- c.entrySnapshot()

		case <-c.stop:
			return
		}

		// 'now' should be updated after newEntry and snapshot cases.
		now = time.Now().Local()
	}
}
```



## Next

位比较来筛选出下一个执行的时间点, 了解下?

