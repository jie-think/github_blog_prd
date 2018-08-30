---
title: Lombok原理分析与功能实现
date: 
categories:
- backend
tags:
- java
- lombok
- 原理
---


参考：https://blog.mythsman.com/2017/12/19/1/

## 原理

1. 定义编译期的注解
2. 利用JSR269 api(Pluggable Annotation Processing API )创建编译期的注解处理器
3. 利用tools.jar的javac api处理AST(抽象语法树)
4. 将功能注册进jar包

## 基础点

1. 注解
2. JSR269 api
3. javac api处理AST


## 手撸Getter

实验的目的是自定义一个针对类的Getter注解，它能够读取该类的成员方法并自动生成getter方法。

### 创建Getter注解
```java
package laboratory.lombokLearn;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

@Target({ElementType.TYPE})
@Retention(RetentionPolicy.SOURCE)
public @interface Getter {
}
```

### 创建Getter注解的处理器
#### 基本框架
```java
package laboratory.lombokLearn;

import javax.annotation.processing.*;
import javax.lang.model.SourceVersion;
import javax.lang.model.element.TypeElement;
import java.util.Set;

@SupportedAnnotationTypes("laboratory.lombokLearn.Getter")
@SupportedSourceVersion(SourceVersion.RELEASE_8)
public class GetterProcessor extends AbstractProcessor {

    @Override
    public synchronized void init(ProcessingEnvironment processingEnv) {
        super.init(processingEnv);
    }

    @Override
    public boolean process(Set<? extends TypeElement> annotations, RoundEnvironment roundEnv) {
        return true;
    }
}
```
然后需要着重实现两个方法，init跟process。init的主要用途是通过ProcessingEnvironment来获取编译阶段的一些环境信息;process主要是实现具体逻辑的地方，也就是对AST进行处理的地方。

#### init 方法

```java
private Messager messager;
private JavacTrees trees;
private TreeMaker treeMaker;
private Names names;

@Override
public synchronized void init(ProcessingEnvironment processingEnv) {
    super.init(processingEnv);
    this.messager = processingEnv.getMessager();
    this.trees = JavacTrees.instance(processingEnv);
    Context context = ((JavacProcessingEnvironment) processingEnv).getContext();
    this.treeMaker = TreeMaker.instance(context);
    this.names = Names.instance(context);
}
```

1. Messager主要是用来在编译期打log用的
2. JavacTrees提供了待处理的抽象语法树
3. TreeMaker封装了创建AST节点的一些方法
4. Names提供了创建标识符的方法


#### PROCESS方法


步骤大概是下面这样：

1. 利用roundEnv的getElementsAnnotatedWith方法过滤出被Getter这个注解标记的类，并存入set
2. 遍历这个set里的每一个元素，并生成jCTree这个语法树
3. 创建一个TreeTranslator，并重写其中的visitClassDef方法，这个方法处理遍历语法树得到的类定义部分jcClassDecl
> 创建一个jcVariableDeclList保存类的成员变量
> 遍历jcTree的所有成员(包括成员变量和成员函数和构造函数)，过滤出其中的成员变量，并添加进jcVariableDeclList
> 将jcVariableDeclList的所有变量转换成需要添加的getter方法，并添加进jcClassDecl的成员中
调用默认的遍历方法遍历处理后的jcClassDecl
4. 利用上面的TreeTranslator去处理jcTree


## summary (answer question)

### 1. 注解的理解
```java
@Target({ElementType.TYPE})
@Retention(RetentionPolicy.SOURCE)
```
这个是编译时运行的注解，其实我更加想知道运行时的注解，如何运作的。


### 2. JSR269 api 是啥？
Pluggable Annotation Processing API（注解处理器）

### 3. AST what？

```java
private JavacTrees trees;
```
这个就是语法树


```java
jcTree.accept(）
```
为类增加方法

### 运行时的注解
我研究一下`@Cacheable`注解吧
