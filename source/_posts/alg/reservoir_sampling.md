# Reservoir Sampling

```
從S中抽取首k項放入「水塘」中
對於每一個S[j]項（j ≥ k）：
   隨機產生一個範圍從0到j的整數r
   若 r < k 則把水塘中的第r項換成S[j]項
```



参考:

[https://zh.wikipedia.org/wiki/%E6%B0%B4%E5%A1%98%E6%8A%BD%E6%A8%A3](https://zh.wikipedia.org/wiki/水塘抽樣)