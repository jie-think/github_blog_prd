# GoRaft Read

建议粗略的看一下原理：https://www.jianshu.com/p/096ae57d1fe0

### 整体文件目录结构

raft
    ├── LICENSE
    ├── Makefile
    ├── README.md
    ├── append_entries.go
    ├── append_entries_test.go
    ├── command.go
    ├── commands.go
    ├── config.go
    ├── context.go
    ├── debug.go
    ├── event.go
    ├── event_dispatcher.go
    ├── event_dispatcher_test.go
    ├── http_transporter.go
    ├── http_transporter_test.go
    ├── log.go
    ├── log_entry.go
    ├── log_test.go
    ├── peer.go
    ├── protobuf
    │   ├── append_entries_request.pb.go
    │   ....
    ├── request_vote.go
    ├── server.go
    ├── server_test.go
    ├── snapshot.go
    ├── snapshot_test.go
    ├── statemachine.go
    ├── statemachine_test.go
    ├── test.go
    ├── transporter.go
    ├── util.go
    └── z_test.go



### 文件作用详解

**append_entries.go **

entries：项，日志中的一条指令？

存在两个结构体：

AppendEntriesRequest

```go
// The request sent to a server to append entries to the log.
// 这个请求是发送给服务端的增加一项到日志中
type AppendEntriesRequest struct {
	Term         uint64
	PrevLogIndex uint64
	PrevLogTerm  uint64
	CommitIndex  uint64
	LeaderName   string
	Entries      []*protobuf.LogEntry
}
```



AppendEntriesResponse

```go
// The response returned from a server appending entries to the log.
// 从服务端返回的应答
type AppendEntriesResponse struct {
	pb     *protobuf.AppendEntriesResponse
	peer   string
	append bool
}
```







**command.go**

一些和命令相关的接口定义:

```go
var commandTypes map[string]Command

func init() {
	commandTypes = map[string]Command{}
}

// Command represents an action to be taken on the replicated state machine.
type Command interface {
	CommandName() string
}

// CommandApply represents the interface to apply a command to the server.
type CommandApply interface {
	Apply(Context) (interface{}, error)
}
```



**commands.go**

定义了一些指令的接口和结构体

```go
// Join command interface
type JoinCommand interface {
	Command
	NodeName() string
}

// Join command
type DefaultJoinCommand struct {
	Name             string `json:"name"`
	ConnectionString string `json:"connectionString"`
}

// Leave command interface
type LeaveCommand interface {
	Command
	NodeName() string
}

// Leave command
type DefaultLeaveCommand struct {
	Name string `json:"name"`
}

// NOP command
type NOPCommand struct {
}
```



**context.go**

context

```go
// Context represents the current state of the server. It is passed into
// a command when the command is being applied since the server methods
// are locked.
// Context表示服务器的当前状态。 由于服务器方法被锁定，因此在应用命令时将其传递给命令
type Context interface {
	Server() Server
	CurrentTerm() uint64
	CurrentIndex() uint64
	CommitIndex() uint64
}

// context is the concrete implementation of Context.
// context是Context的具体实现
type context struct {
	server       Server
	currentIndex uint64
	currentTerm  uint64
	commitIndex  uint64
}
```



**event_dispatcher.go**

事件调度者

```go
// eventDispatcher is responsible for managing listeners for named events
// and dispatching event notifications to those listeners.
// eventDispatcher负责管理命名事件的侦听器并将事件通知分派给这些侦听器
type eventDispatcher struct {
	sync.RWMutex
	source    interface{}
	listeners map[string]eventListeners
}

// EventListener is a function that can receive event notifications.
// EventListener 是一个函数,能够接受事件通知
type EventListener func(Event)

// EventListeners represents a collection of individual listeners.
// EventListeners 一个监听器的收集器
type eventListeners []EventListener
```



**event.go**

定义了事件

```go
// Event represents an action that occurred within the Raft library.
// Listeners can subscribe to event types by using the Server.AddEventListener() function.
// Event 表示在Raft库中发生的操作。 监听器可以使用Server.AddEventListener（）函数订阅事件类型。
type Event interface {
	Type() string
	Source() interface{}
	Value() interface{}
	PrevValue() interface{}
}

// event is the concrete implementation of the Event interface.
// event 是 Event 接口的一个实现
type event struct {
	typ       string
	source    interface{}
	value     interface{}
	prevValue interface{}
}
```



**http_transporter.go**



```go
// An HTTPTransporter is a default transport layer used to communicate between
// multiple servers.
// HTTPTransporter 是用于在多个服务器之间进行通信的默认传输层
type HTTPTransporter struct {
	DisableKeepAlives    bool
	prefix               string
	appendEntriesPath    string
	requestVotePath      string
	snapshotPath         string
	snapshotRecoveryPath string
	httpClient           http.Client
	Transport            *http.Transport
}

type HTTPMuxer interface {
	HandleFunc(string, func(http.ResponseWriter, *http.Request))
}
```



**log_entry.go**

日志中的一项

```go
// A log entry stores a single item in the log.
// 日志中的单独一项
type LogEntry struct {
	pb       *protobuf.LogEntry
	Position int64 // position in the log file
	log      *Log
	event    *ev
}
```



**log.go**

日志

```go
// A log is a collection of log entries that are persisted to durable storage.
// Log 是 log entries 的一个收集器, 可以持久存储到持久存储器
type Log struct {
	ApplyFunc   func(*LogEntry, Command) (interface{}, error)
	file        *os.File
	path        string
	entries     []*LogEntry
	commitIndex uint64
	mutex       sync.RWMutex
	startIndex  uint64 // the index before the first entry in the Log entries
	startTerm   uint64
	initialized bool
}

// The results of the applying a log entry.
type logResult struct {
	returnValue interface{}
	err         error
}
```



**peer.go**

```go
// A peer is a reference to another server involved in the consensus protocol.
// Peer 是对共识协议中涉及的另一个服务器的引用
type Peer struct {
	server            *server
	Name              string `json:"name"`
	ConnectionString  string `json:"connectionString"`
	prevLogIndex      uint64
	stopChan          chan bool
	heartbeatInterval time.Duration
	lastActivity      time.Time
	sync.RWMutex
}
```



**request_vote.go**

```go
// The request sent to a server to vote for a candidate to become a leader.
type RequestVoteRequest struct {
	peer          *Peer
	Term          uint64
	LastLogIndex  uint64
	LastLogTerm   uint64
	CandidateName string
}

// The response returned from a server after a vote for a candidate to become a leader.
type RequestVoteResponse struct {
	peer        *Peer
	Term        uint64
	VoteGranted bool
}
```



**server.go**

```go
// A server is involved in the consensus protocol and can act as a follower,
// candidate or a leader.
type Server interface {
	Name() string
	Context() interface{}
	StateMachine() StateMachine
	Leader() string
	State() string
	Path() string
	LogPath() string
	SnapshotPath(lastIndex uint64, lastTerm uint64) string
	Term() uint64
	CommitIndex() uint64
	VotedFor() string
	MemberCount() int
	QuorumSize() int
	IsLogEmpty() bool
	LogEntries() []*LogEntry
	LastCommandName() string
	GetState() string
	ElectionTimeout() time.Duration
	SetElectionTimeout(duration time.Duration)
	HeartbeatInterval() time.Duration
	SetHeartbeatInterval(duration time.Duration)
	Transporter() Transporter
	SetTransporter(t Transporter)
	AppendEntries(req *AppendEntriesRequest) *AppendEntriesResponse
	RequestVote(req *RequestVoteRequest) *RequestVoteResponse
	RequestSnapshot(req *SnapshotRequest) *SnapshotResponse
	SnapshotRecoveryRequest(req *SnapshotRecoveryRequest) *SnapshotRecoveryResponse
	AddPeer(name string, connectiongString string) error
	RemovePeer(name string) error
	Peers() map[string]*Peer
	Init() error
	Start() error
	Stop()
	Running() bool
	Do(command Command) (interface{}, error)
	TakeSnapshot() error
	LoadSnapshot() error
	AddEventListener(string, EventListener)
	FlushCommitIndex()
}

type server struct {
	*eventDispatcher

	name        string
	path        string
	state       string
	transporter Transporter
	context     interface{}
	currentTerm uint64

	votedFor   string
	log        *Log
	leader     string
	peers      map[string]*Peer
	mutex      sync.RWMutex
	syncedPeer map[string]bool

	stopped           chan bool
	c                 chan *ev
	electionTimeout   time.Duration
	heartbeatInterval time.Duration

	snapshot *Snapshot

	// PendingSnapshot is an unfinished snapshot.
	// After the pendingSnapshot is saved to disk,
	// it will be set to snapshot and also will be
	// set to nil.
	pendingSnapshot *Snapshot

	stateMachine            StateMachine
	maxLogEntriesPerRequest uint64

	connectionString string

	routineGroup sync.WaitGroup
}

// An internal event to be processed by the server's event loop.
type ev struct {
	target      interface{}
	returnValue interface{}
	c           chan error
}

```



**snapshot.go**

```go
// Snapshot represents an in-memory representation of the current state of the system.
type Snapshot struct {
	LastIndex uint64 `json:"lastIndex"`
	LastTerm  uint64 `json:"lastTerm"`

	// Cluster configuration.
	Peers []*Peer `json:"peers"`
	State []byte  `json:"state"`
	Path  string  `json:"path"`
}

// The request sent to a server to start from the snapshot.
type SnapshotRecoveryRequest struct {
	LeaderName string
	LastIndex  uint64
	LastTerm   uint64
	Peers      []*Peer
	State      []byte
}

// The response returned from a server appending entries to the log.
type SnapshotRecoveryResponse struct {
	Term        uint64
	Success     bool
	CommitIndex uint64
}

// The request sent to a server to start from the snapshot.
type SnapshotRequest struct {
	LeaderName string
	LastIndex  uint64
	LastTerm   uint64
}

// The response returned if the follower entered snapshot state
type SnapshotResponse struct {
	Success bool `json:"success"`
}
```



**statemachine.go**

```go
// StateMachine is the interface for allowing the host application to save and
// recovery the state machine. This makes it possible to make snapshots
// and compact the log.
type StateMachine interface {
	Save() ([]byte, error)
	Recovery([]byte) error
}
```



**transporter.go**

```go
// Transporter is the interface for allowing the host application to transport
// requests to other nodes.
type Transporter interface {
	SendVoteRequest(server Server, peer *Peer, req *RequestVoteRequest) *RequestVoteResponse
	SendAppendEntriesRequest(server Server, peer *Peer, req *AppendEntriesRequest) *AppendEntriesResponse
	SendSnapshotRequest(server Server, peer *Peer, req *SnapshotRequest) *SnapshotResponse
	SendSnapshotRecoveryRequest(server Server, peer *Peer, req *SnapshotRecoveryRequest) *SnapshotRecoveryResponse
}
```





























