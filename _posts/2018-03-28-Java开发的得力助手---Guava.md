---
layout: post
title: Java开发的得力助手---Guava
date: 2018-03-28
typora-root-url: ../
catalog: true
tags:
  - Java
  - Guava
  - 工具库
---

# 导语

![img](/img/2018-03-28-Java开发的得力助手---Guava/ph-quote.png)

[guava](https://github.com/google/guava)是google出品的java类库，被google广泛用于内部项目，该类库经过google大牛们的千锤百炼，以优雅的设计在java世界流行。版本迭代至今，很多思想甚至被JDK标准库借鉴，如`Optional`,`Objects`等。
Guava中的核心库有：

- 集合 [collections]
- 缓存 [caching]
- 原生类型支持 [primitives support]
- 并发库 [concurrency libraries]
- 通用注解 [common annotations]
- 字符串处理 [string processing]
- I/O 等等。

# 集合

编程是为业务服务，一个有效的业务必然会有输入和输出，比如HTTP服务中的请求参数和响应内容。所谓的输入和输出从本质上来说其实就是字节的不同持久化形式，如数据库，本地文件，JSON字符串等等。综上，业务中的java代码必然有I/O，并且以字节为载体。而连续的字节可以抽象为一串字节流，字节流中的字节可以通过不同划分方式(字符集，字符编码表)如每两个连续字节或者三个连续字节划分翻译为数字，数字又可以映射为字符，最后成为字符串。所以，最终的本质就是，java代码的所有操作最终都是对字符串的操作。因为代码的最终操作是对字节流的操作，而字节流总是可以通过一个合适的字符集转换成字符流，从而转换成字符串。

和Apache comomons类库不同，guava虽然提供了丰富且便捷的String操作，但是并不是放在一个工具类中作为静态方法类似过程式编程的使用。而是合理抽象成了若干个类，提供了更加OOP的操作。

### `com.google.common.base.Strings`

### `com.google.common.base.CharMatcher`

### `com.google.common.base.Charsets`

### `com.google.common.base.CaseFormat`

# 参数校验

> 参数相关

# 网络

> 网络相关
