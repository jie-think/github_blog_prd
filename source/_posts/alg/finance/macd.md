# MACD 指标

MACD ( Moving Average Convergence / Divergence ) 称为异同移动平均线, 是从双指数移动平均线发展而来的，由快的指数移动平均线（EMA12）减去慢的指数移动平均线（EMA26）得到快线DIF，再用2×（快线DIF-DIF的9日加权移动均线DEA）得到MACD柱. 



## MACD的计算过程

**1、计算移动平均值（EMA）**

$S_n: 今日收盘价​$

12日EMA的算式为

$EMA_{12}(n) = EMA_{12}(n - 1) * \frac{11}{13} + S_n * \frac{2}{13}​$



26日EMA的算式为

$EMA_{26}(n) = EMA_{26}(n - 1) * \frac{25}{27} + S_n * \frac{2}{27}​$



**2、计算离差值（DIF）**

$DIF(n) = EMA_{12}(n) - EMA_{26}(n)​$



**3、计算DIF的9日EMA**

根据离差值计算其9日的EMA，即离差平均值，是所求的MACD值。为了不与指标原名相混淆，此值又名DEA或DEM.

$DEA(n) = DEA(n-1) * \frac{8}{10} + DIF(n)*\frac{2}{10}​$

计算出的DIF和DEA的数值均为正值或负值。

$MACD柱状图 = (DIF - DEA) * 2​$



## 可参考方案

1. 当DIF和DEA均大于0(即在图形上表示为它们处于零线以上)并向上移动时，一般表示为行情处于[多头行情](https://baike.baidu.com/item/%E5%A4%9A%E5%A4%B4%E8%A1%8C%E6%83%85)中，可以买入[开仓](https://baike.baidu.com/item/%E5%BC%80%E4%BB%93)或[多头持仓](https://baike.baidu.com/item/%E5%A4%9A%E5%A4%B4%E6%8C%81%E4%BB%93)；

2. 当DIF和DEA均小于0(即在图形上表示为它们处于零线以下)并向下移动时，一般表示为行情处于[空头行情](https://baike.baidu.com/item/%E7%A9%BA%E5%A4%B4%E8%A1%8C%E6%83%85)中，可以卖出开仓或观望。

3. 当DIF和DEA均大于0(即在图形上表示为它们处于零线以上)但都向下移动时，一般表示为行情处于下跌阶段，可以卖出开仓和观望；

4. 当DIF和DEA均小于0时(即在图形上表示为它们处于零线以下)但向上移动时，一般表示为行情即将上涨，股票将上涨，可以买入开仓或多头持仓。



其买卖原则为：

1. DIF、DEA均为正，DIF向上突破DEA，买入信号参考。

2. DIF、DEA均为负，DIF向下跌破DEA，卖出信号参考。

3. DIF线与K线发生背离，行情可能出现反转信号。

4. DIF、DEA的值从正数变成负数，或者从负数变成正数并不是交易信号，因为它们落后于市场。



## 基本用法

1. MACD[金叉](https://baike.baidu.com/item/%E9%87%91%E5%8F%89)：DIFF 由下向上突破 DEA，为买入信号。

2. MACD[死叉](https://baike.baidu.com/item/%E6%AD%BB%E5%8F%89)：DIFF 由上向下突破 DEA，为卖出信号。

3. MACD 绿转红：MACD 值由负变正，市场由[空头](https://baike.baidu.com/item/%E7%A9%BA%E5%A4%B4/13825859)转为多头。

4. MACD 红转绿：MACD 值由正变负，市场由多头转为空头。

5. DIFF 与 DEA 均为正值,即都在零轴线以上时，大势属[多头市场](https://baike.baidu.com/item/%E5%A4%9A%E5%A4%B4%E5%B8%82%E5%9C%BA)，DIFF 向上突破 DEA，可作买入信号。

6. DIFF 与 DEA 均为负值,即都在零轴线以下时，大势属[空头市场](https://baike.baidu.com/item/%E7%A9%BA%E5%A4%B4%E5%B8%82%E5%9C%BA)，DIFF 向下跌破 DEA，可作卖出信号。

7. 当 DEA 线与 K 线趋势发生[背离](https://baike.baidu.com/item/%E8%83%8C%E7%A6%BB/3696078)时为反转信号。

8. DEA 在盘整局面时失误率较高,但如果配合[RSI](https://baike.baidu.com/item/RSI) 及[KD](https://baike.baidu.com/item/KD)j指标可适当弥补缺点。







**参考:**

[MACD-百度百科](<https://baike.baidu.com/item/MACD%E6%8C%87%E6%A0%87/6271283?fromtitle=MACD&fromid=3334786>)

