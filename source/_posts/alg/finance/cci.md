# CCI 算法

CCI（Commodity Channel lndex）顺势指标是测量股价是否已超出常态分布范围的一个指数。由唐纳德·R.兰伯特（DonaldLambert）所创，属于超买超卖类指标中较特殊的一种，波动于正无限大和负无限小之间。

## 计算公式

系统默认n为14



$TP = \frac{最高价 + 最低价 + 收盘价}{3}$



$MA = \frac{\sum\limits_{k=1}^{n} TP(i)}{n}$



MD = 最近n日 (MA - TP)的绝对值的累计和 ÷ n

可能不太准确...

$MD = \frac{MA - TP}{n}​$



$CCI(n) = \frac{TP - MA}{MD} * 0.015$



## 使用方法

**1,观察CCI范围**

当CCI从0~+100的正常范围内，由下往上突破+100时，[股指](https://baike.baidu.com/item/%E8%82%A1%E6%8C%87)或[股价](https://baike.baidu.com/item/%E8%82%A1%E4%BB%B7)有可能出现强势上涨，是买入的时机；当CCI从+100之上，由上往下跌破+100，股指或股价[短线](https://baike.baidu.com/item/%E7%9F%AD%E7%BA%BF)有可能出现[回调](https://baike.baidu.com/item/%E5%9B%9E%E8%B0%83/9837525)，是卖出的时机。当CCI从0~-100的正常范围内，由上往下跌破-100时，股指或股价有可能出现弱势下跌，是抛出的时机。当CCI从-100的下方，由下往上突破-100时，有可能出现反弹，可逢低买入。

**2, CCI运用也可以用[顶背离](https://baike.baidu.com/item/%E9%A1%B6%E8%83%8C%E7%A6%BB)来判断[短线头部](https://baike.baidu.com/item/%E7%9F%AD%E7%BA%BF%E5%A4%B4%E9%83%A8)的出现，用[底背离](https://baike.baidu.com/item/%E5%BA%95%E8%83%8C%E7%A6%BB)来判断短线底部的到来**

当股指或股价创出新高，而CCI没有同步创出新高时，[顶背离](https://baike.baidu.com/item/%E9%A1%B6%E8%83%8C%E7%A6%BB)出现，[短线](https://baike.baidu.com/item/%E7%9F%AD%E7%BA%BF)[股指](https://baike.baidu.com/item/%E8%82%A1%E6%8C%87/3342555)或股价有可能出现[回挡](https://baike.baidu.com/item/%E5%9B%9E%E6%8C%A1)，可逢高卖出；当股指或股价创出新低，而CCI没有同步创出新低时，底背离出现，短线股指或股价有可能出现反弹，可逢低买入。



## 应用技巧

1、如果CCI指标一直上行突破了100的话,表示此时的股市进入了异常波动的阶段,可能伴随着较大的[成交量](https://baike.baidu.com/item/%E6%88%90%E4%BA%A4%E9%87%8F),可以进行中短线的投资者,此时的[买入](https://baike.baidu.com/item/%E4%B9%B0%E5%85%A5)信号比较明显.

2、反之如果CCI指标向下突破了-100,则代表此时的股市进入了新一轮的下跌趋势,此时可以选择不要操作,保持观望的态度面对市场.

3、如果CCI指标从上行突破100又回到100之内的正常范围,则代表股价这一阶段的上涨行情已经疲软,投资者可以在此时选择卖出.反之CCI突破-100又回到正常范围,则代表[下跌趋势](https://baike.baidu.com/item/%E4%B8%8B%E8%B7%8C%E8%B6%8B%E5%8A%BF)已经结束,观察一段时间可能有转折的信号出现,可以先少量买入.

注意[CCI指标](https://baike.baidu.com/item/CCI%E6%8C%87%E6%A0%87)主要用来判断100到-100范围之外的行情趋势,在这之间的趋势分析应用 [CCI指标](https://baike.baidu.com/item/CCI%E6%8C%87%E6%A0%87)没有作用和意义,可以选择[KDJ指标](https://baike.baidu.com/item/KDJ%E6%8C%87%E6%A0%87)来分析.另外CCI指标是进行[短线操作](https://baike.baidu.com/item/%E7%9F%AD%E7%BA%BF%E6%93%8D%E4%BD%9C)的投资者比较实用的武器,可以很快帮助交易者找到准确的[交易信号](https://baike.baidu.com/item/%E4%BA%A4%E6%98%93%E4%BF%A1%E5%8F%B7). [2] 




**参考：**

[CCI百度百科(https://baike.baidu.com/item/CCI%E9%A1%BA%E5%8A%BF%E6%8C%87%E6%A0%87/6982196)