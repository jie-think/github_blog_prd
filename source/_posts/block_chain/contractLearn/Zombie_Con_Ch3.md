---
title: Zombie T3
date: 
categories:
- backend
tags:
- blockchain
- 智能合约
---


涉及内容：`智能协议的所有权`，`Gas的花费`，`代码优化`，和`代码安全`

## ch1. 智能协议的永固性

在你把智能协议传上以太坊之后，它就变得`不可更改`, 这种永固性意味着你的代码永远不能被调整或更新。

**尽量不要写死代码**

## ch2. Ownable Contracts

OpenZeppelin库的Ownable 合约：OpenZeppelin 是主打安保和社区审查的智能合约库，您可以在自己的 DApps中引用。

```solidity
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}
```

- 构造函数: `function Ownable()` 是一个 constructor (构造函数)，构造函数不是必须的，它与合约同名，构造函数一生中唯一的一次执行，就是在合约最初被创建的时候。

- 函数修饰符：`modifier onlyOwner()` 修饰符跟函数很类似，不过是用来修饰其他已有函数用的， 在其他语句执行前，为它检查下先验条件。`_;` 类似于 ruby 中的 `yield`

所以`Ownable`合约基本都会这么干：
1. 合约创建，构造函数先行，将其 owner 设置为msg.sender（其部署者）
2. 为它加上一个修饰符 onlyOwner，它会限制陌生人的访问，将访问某些函数的权限锁定在 owner 上。
3. 允许将合约所有权转让给他人。


## ch4. Gas

**重要概念：** `Gas - 驱动以太坊DApps的能源`

在 Solidity 中，你的用户想要每次执行你的 DApp 都需要支付一定的 gas，gas 可以用以太币购买，因此，用户每次跑 DApp 都得花费以太币。

一个 DApp 收取多少 gas 取决于功能逻辑的复杂程度。每个操作背后，都在计算完成这个操作所需要的计算资源，（比如，存储数据就比做个加法运算贵得多）， 一次操作所需要花费的 gas 等于这个操作背后的所有运算花销的总和。

由于运行你的程序需要花费用户的真金白银，在以太坊中代码的编程语言，比其他任何编程语言都更强调优化。同样的功能，使用笨拙的代码开发的程序，比起经过精巧优化的代码来，运行花费更高，这显然会给成千上万的用户带来大量不必要的开销。

### 为什么要用 gas 来驱动？

以太坊就像一个巨大、缓慢、但非常安全的电脑。当你运行一个程序的时候，网络上的每一个节点都在进行相同的运算，以验证它的输出 —— 这就是所谓的”去中心化“ 由于数以千计的节点同时在验证着每个功能的运行，这可以确保它的数据不会被被监控，或者被刻意修改。

可能会有用户用无限循环堵塞网络，抑或用密集运算来占用大量的网络资源，为了防止这种事情的发生，以太坊的创建者为以太坊上的资源制定了价格，想要在以太坊上运算或者存储，你需要先付费。


### 省 gas 的招数：结构封装 （Struct packing）

在第1课中，我们提到除了基本版的 uint 外，还有其他变种 uint：uint8，uint16，uint32等。

通常情况下我们不会考虑使用 unit 变种，因为无论如何定义 uint的大小，Solidity 为它保留256位的存储空间。例如，使用 uint8 而不是uint（uint256）不会为你节省任何 gas。

除非，把 unit 绑定到 struct 里面。

如果一个 struct 中有多个 uint，则尽可能使用较小的 uint, Solidity 会将这些 uint 打包在一起，从而占用较少的存储空间。例如：

```solidity
struct NormalStruct {
  uint a;
  uint b;
  uint c;
}

struct MiniMe {
  uint32 a;
  uint32 b;
  uint c;
}
```
// 因为使用了结构打包，`mini` 比 `normal` 占用的空间更少
NormalStruct normal = NormalStruct(10, 20, 30);
MiniMe mini = MiniMe(10, 20, 30);
所以，当 uint 定义在一个 struct 中的时候，尽量使用最小的整数子类型以节约空间。 并且把同样类型的变量放一起（即在 struct 中将把变量按照类型依次放置），这样 Solidity 可以将存储空间最小化。例如，有两个 struct：

uint c; uint32 a; uint32 b; 和 uint32 a; uint c; uint32 b;

前者比后者需要的gas更少，因为前者把uint32放一起了。

## ch5. 时间单位

Solidity 使用自己的本地时间单位。

变量 `now` 将返回当前的unix时间戳（自1970年1月1日以来经过的秒数）。

Solidity 还包含秒(seconds)，分钟(minutes)，小时(hours)，天(days)，周(weeks) 和 年(years) 等时间单位。它们都会转换成对应的秒数放入 uint 中。所以 1分钟 就是 60，1小时是 3600（60秒×60分钟），1天是86400（24小时×60分钟×60秒），以此类推。

示例：
```solidity
uint lastUpdated;

// 将‘上次更新时间’ 设置为 ‘现在’
function updateTimestamp() public {
  lastUpdated = now;
}

// 如果到上次`updateTimestamp` 超过5分钟，返回 'true'
// 不到5分钟返回 'false'
function fiveMinutesHavePassed() public view returns (bool) {
  return (now >= (lastUpdated + 5 minutes));
```

## ch6. 结构体作为参数传入
由于结构体的存储指针可以以参数的方式传递给一个 private 或 internal 的函数，因此结构体可以在多个函数之间相互传递。

遵循这样的语法：

```solidity
function _doStuff(Zombie storage _zombie) internal {
  // do stuff with _zombie
}
```

## ch7. 公有函数和安全性

你必须仔细地检查所有声明为 public 和 external的函数，一个个排除用户滥用它们的可能，谨防安全漏洞。请记住，如果这些函数没有类似 onlyOwner 这样的函数修饰符，用户能利用各种可能的参数去调用它们。

## ch8. 进一步了解函数修饰符

### 带参数的函数修饰符
之前我们已经读过一个简单的函数修饰符了：onlyOwner。函数修饰符也可以带参数。例如：

```solidity
// 存储用户年龄的映射
mapping (uint => uint) public age;

// 限定用户年龄的修饰符
modifier olderThan(uint _age, uint _userId) {
  require(age[_userId] >= _age);
  _;
}

// 必须年满16周岁才允许开车 (至少在美国是这样的).
// 我们可以用如下参数调用`olderThan` 修饰符:
function driveCar(uint _userId) public olderThan(16, _userId) {
  // 其余的程序逻辑
}
```

看到了吧， olderThan 修饰符可以像函数一样接收参数，是“宿主”函数 driveCar 把参数传递给它的修饰符的。

## ch10. 利用 'View' 函数节省 Gas

### “view” 函数不花 “gas”

当玩家从外部调用一个view函数，是不需要支付一分 gas 的。

这是因为 view 函数不会真正改变区块链上的任何数据 - `它们只是读取`。因此用 view 标记一个函数，意味着告诉 web3.js，`运行这个函数只需要查询你的本地以太坊节点`，而不需要在区块链上创建一个事务（事务需要运行在每个节点上，因此花费 gas）。

稍后我们将介绍如何在自己的节点上设置 web3.js。但现在，你关键是要记住，在所能只读的函数上标记上表示“只读”的“external view 声明，就能为你的玩家减少在 DApp 中 gas 用量。

注意：如果一个 view 函数在另一个函数的内部被调用，而调用函数与 view 函数的不属于同一个合约，也会产生调用成本。这是因为如果主调函数在以太坊创建了一个事务，它仍然需要逐个节点去验证。所以标记为 view 的函数只有在外部调用时才是免费的。

## ch11. 存储非常昂贵

Solidity 使用storage(存储)是相当昂贵的，”写入“操作尤其贵。

这是因为，无论是写入还是更改一段数据， 这都将永久性地写入区块链。”永久性“啊！需要在全球数千个节点的硬盘上存入这些数据，随着区块链的增长，拷贝份数更多，存储量也就越大。这是需要成本的！

为了降低成本，不到万不得已，避免将数据写入存储。这也会导致效率低下的编程逻辑 - 比如每次调用一个函数，都需要在 memory(内存) 中重建一个数组，而不是简单地将上次计算的数组给存储下来以便快速查找。

在大多数编程语言中，遍历大数据集合都是昂贵的。但是在 Solidity 中，使用一个标记了external view的函数，遍历比 storage 要便宜太多，因为 view 函数不会产生任何花销。 （gas可是真金白银啊！）。

我们将在下一章讨论for循环，现在我们来看一下看如何如何在内存中声明数组。

在内存中声明数组
在数组后面加上 memory关键字， 表明这个数组是仅仅在内存中创建，不需要写入外部存储，并且在函数调用结束时它就解散了。与在程序结束时把数据保存进 storage 的做法相比，内存运算可以大大节省gas开销 -- 把这数组放在view里用，完全不用花钱。

以下是申明一个内存数组的例子：

```solidity
function getArray() external pure returns(uint[]) {
  // 初始化一个长度为3的内存数组
  uint[] memory values = new uint[](3);
  // 赋值
  values.push(1);
  values.push(2);
  values.push(3);
  // 返回数组
  return values;
}
```

这个小例子展示了一些语法规则，下一章中，我们将通过一个实际用例，展示它和 for 循环结合的做法。

注意：内存数组 必须 用长度参数（在本例中为3）创建。目前不支持 array.push()之类的方法调整数组大小，在未来的版本可能会支持长度修改。


## 使用 for 循环
for循环的语法在 Solidity 和 JavaScript 中类似。

来看一个创建偶数数组的例子：
```solidity
function getEvens() pure external returns(uint[]) {
  uint[] memory evens = new uint[](5);
  // 在新数组中记录序列号
  uint counter = 0;
  // 在循环从1迭代到10：
  for (uint i = 1; i <= 10; i++) {
    // 如果 `i` 是偶数...
    if (i % 2 == 0) {
      // 把它加入偶数数组
      evens[counter] = i;
      //索引加一， 指向下一个空的‘even’
      counter++;
    }
  }
  return evens;
}
```
这个函数将返回一个形为 [2,4,6,8,10] 的数组。