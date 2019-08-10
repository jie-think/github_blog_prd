# ATR

ATR又称 Average true range平均真实波动范围，简称ATR指标，是由J.Welles Wilder 发明的，ATR指标主要是用来衡量市场波动的强烈度，即为了显示市场变化率的指标。

首先提出的，这一指标主要用来衡量价格的波动。因此，这一技术指标并不能直接反映价格走向及其趋势稳定性，而只是表明价格波动的程度。

### 计算方法

![img](https://alicdn.ricequant.com/upload/62/2fae2f750d188ad79b9c969e732ba562.jpeg)



$$TR = max[(high-low), abs(high - close_{prev}), abs(low-close_{prev})]$$

$$ATR_t = \frac{ATR_{t-1} * (n - 1) + TR_t}{n}$$

$$ATR = \frac{1}{n}\sum^{n}_{i=1}{TR_i}$$

参考:

https://www.ricequant.com/community/topic/2397

[https://wiki.mbalib.com/wiki/%E5%9D%87%E5%B9%85%E6%8C%87%E6%A0%87](https://wiki.mbalib.com/wiki/均幅指标)