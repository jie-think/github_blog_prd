---
title: Learn CSS Grid
date: 
categories:
- frontend
- learn notebook
tags:
- css
- css grid
---

视频教程推荐(建议先看一些基础概念): [https://scrimba.com/g/gR8PTE](https://scrimba.com/g/gR8PTE)
简单教程: [https://medium.freecodecamp.org/learn-css-grid-in-5-minutes-f582e87b1228](https://medium.freecodecamp.org/learn-css-grid-in-5-minutes-f582e87b1228) 
详细教程: [https://learncssgrid.com/](https://learncssgrid.com/)


该内容主要来自:
https://scrimba.com/g/gR8PTE and https://medium.freecodecamp.org/learn-css-grid-in-5-minutes-f582e87b1228


![目标结构](https://cdn-images-1.medium.com/max/2000/1*Oc88rInEcNuY-xCN3e1iPQ.png)

## 重要术语解释

参考: [https://www.jianshu.com/p/d183265a8dad](https://www.jianshu.com/p/d183265a8dad)

1. 网格容器（Grid Container）
元素应用display:grid，它是其所有网格项的父元素。下面例子container就是网格容器。
```html
<div class="container">
  <div class="item item-1"></div>
  <div class="item item-2"></div>
  <div class="item item-3"></div>
</div>
```

2. 网格项（Grid Item）

网格容器的子元素，下面的item元素是网格项，但sub-item不是。
```html
<div class="container">
  <div class="item"></div> 
  <div class="item">
    <p class="sub-item"></p>
  </div>
  <div class="item"></div>
</div>
```

3. 网格线（Grid Line）

组成网格线的分界线。它们可以是列网格线（column grid lines），也可以是行网格线（row grid lines）并且居于行或列的任意一侧，下面黄色线就是列网格线。
![grid lines](https://upload-images.jianshu.io/upload_images/3600755-294354d5cb39077a.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/383/format/webp)

4. 网格轨道（Grid Track）
两个相邻的网格线之间为网格轨道。你可以认为它们是网格的列或行，下面在第二个和第三个网格线之间的黄色部分为网格轨道。
![Grid Track](https://upload-images.jianshu.io/upload_images/3600755-6fd45c7949a3f29b.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/383/format/webp)

5. 网格单元（Grid Cell）
两个相邻的列网格线和两个相邻的行网格线组成的是网格单元，它是最小的网格单元。下面行网格线1（row grid lines 1）、行网格线2（row grid lines 2）和列网格线2（column grid lines 2）、列网格线3（column grid lines 3）组成的黄色区域为网格单元。
![Grid Cell](https://upload-images.jianshu.io/upload_images/3600755-5feacaa8175909c7.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/383/format/webp)

6. 网格区（Grid Area）
网格区是由任意数量网格单元组成，下面行网格线1（row grid lines 1）、行网格线3（row grid lines 3）和列网格线1（column grid lines 1）、列网格线3（column grid lines3）组成的黄色区域为网格区。
![Grid Area](https://upload-images.jianshu.io/upload_images/3600755-2a62922e76f77c3c.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/383/format/webp)


## 第一个 grid 布局

> The two core ingredients of a CSS Grid are the wrapper (parent) and the items (children). The wrapper is the actual grid and the items are the content inside the grid.
> CSS Grid的两个核心组成部分是包装器（父）和项（子）。 包装器是实际网格，项目是网格内的内容。


```html
<div class="wrapper">
  <div>1</div>
  <div>2</div>
  <div>3</div>
  <div>4</div>
  <div>5</div>
  <div>6</div>
</div>
```

```css
.wrapper {
    display: grid;
}
```

result: 
![first grid layout result](https://cdn-images-1.medium.com/max/1600/1*vTY7C5FMIp8OLkjrgp-vBg.png)

## Columns and rows

```css
.wrapper {
    display: grid;
    grid-template-columns: 100px 100px 100px;
    grid-template-rows: 50px 50px;
}
```

![](https://cdn-images-1.medium.com/max/1600/1*fJNIdDiScjhI9CZjdxv3Eg.png)

```css
.wrapper {
    display: grid;
    grid-template-columns: 200px 50px 100px;
    grid-template-rows: 100px 30px;
}
```
![](https://cdn-images-1.medium.com/max/1600/1*M9WbiVEFcseUCW6qeG4lSQ.png)


## items

```css
.item1 {
    grid-column-start: 1;
    grid-column-end: 4;
}
```

![](https://cdn-images-1.medium.com/max/1600/1*he7CoAzdQB3sei_WpHOtNg.png)

```css
.item1 {
    grid-column: 1 / 4;
}
```

![](https://cdn-images-1.medium.com/max/1600/1*l-adYpQCGve7W6DWY949pw.png)



