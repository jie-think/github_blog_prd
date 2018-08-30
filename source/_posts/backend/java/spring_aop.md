
---
title: spring aop 切向编程
date: 
categories:
- backend
tags:
- java
- spring aop
---


## 概览

1. 什么是切向编程？
2. 切向编程的好处
3. spring aop的使用
4. spring中类似于`@Cacheable`的实现

重点讲3和4

## 什么是切向编程？

自己的理解：`在一个方法前后执行某段特定功能的代码`

## 切向编程的好处

举两个例子：
1. web应用中，需要打印接口传入的params and return result，就需要在接口前后加上log。
2. 将数据库查询出的数据缓存到redis中（类似于`@Cacheable`）。

## spring aop的使用

关键点：
1. 声明切面类，使用`@Aspect`并将类注册到IOC容器中`@Component`
2. 定义切点：`@Pointcut("execution(public * laboratory.controller..*.*(..))")`
3. 定义执行方法：`@Before("webLog()")`

### 切点类型

`@Pointcut(value = "")`  
value的类型：
TOTO: 总结value类型



### 完整代码

**WebLogAspect：**

```java
package laboratory.aop;

import com.alibaba.fastjson.JSON;
import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.annotation.AfterReturning;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Before;
import org.aspectj.lang.annotation.Pointcut;
import org.springframework.stereotype.Component;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import javax.servlet.http.HttpServletRequest;

@Aspect    // 1. 声明切面类
@Component
public class WebLogAspect {

    @Pointcut("execution(public * laboratory.controller..*.*(..))") // 2. 定义切点
    public void webLog(){
    }

    @Before("webLog()")  // 3. 定义执行方法
    public void doBefore(JoinPoint joinPoint) {
		// 接收到请求，记录请求内容
        ServletRequestAttributes attributes = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
        HttpServletRequest request =  attributes.getRequest();

        // 记录下请求内容
//        logger.info("URL : " + request.getRequestURL().toString());
//        logger.info("HTTP_METHOD : " + request.getMethod());
//        logger.info("IP : " + request.getRemoteAddr());
//        logger.info("CLASS_METHOD : " + joinPoint.getSignature().getDeclaringTypeName() + "." + joinPoint.getSignature().getName());
//        logger.info("ARGS : " + Arrays.toString(joinPoint.getArgs()));
    }

    @AfterReturning(returning = "ret", pointcut = "webLog()")  //3. 定义执行方法
    public void doAfterReturning(Object ret) {
        System.out.println("resp: " + JSON.toJSONString(ret));
    }
}
```


**FirstCache:**
```java
package laboratory.aop;

import laboratory.annotation.FirstCacheAno;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Pointcut;
import org.aspectj.lang.reflect.MethodSignature;
import org.springframework.stereotype.Component;

@Aspect
@Component
public class FirstCache {

    @Pointcut("@annotation(laboratory.annotation.FirstCacheAno)")
    public void firstCache() {
    }

    @Around("firstCache()")
    public Object aroundFirstCache(ProceedingJoinPoint proceedingJoinPoint) {
        System.out.println("aroundFirstCache after....");
        MethodSignature signature = (MethodSignature) proceedingJoinPoint.getSignature();
        FirstCacheAno firstCache = signature.getMethod().getAnnotation(FirstCacheAno.class);
        System.out.println("firstCache cacheName: " + firstCache.cacheName());
        System.out.println("firstCache unless: " + firstCache.unless());
        Object ret = null;
        try {
            ret = proceedingJoinPoint.proceed();
            System.out.println(ret);
        } catch (Throwable throwable) {
            throwable.printStackTrace();
        }
        System.out.println("aroundFirstCache end....");
        return ret;
    }
}

```

