---
layout: post
title: HTTP请求偶现ConnectionClosedException
date: 2024-02-04
typora-root-url: ../
catalog: true
tags:
  - 网络
  - Java
  - HTTP
  - 异常处理
  - Keep-Alive
---

# 现象
基于HTTP协议进行C/S通讯的业务上线后，偶现如下异常，频率大概在两三天一两次：

![20240928151220273.jpg](/img/2024-02-04-HTTP请求偶现ConnectionClosedException/20240928151220273.jpg)

```properties
org.apache.http.ConnectionClosedException: Connection is closed
```

异常提示http请求时，复用的底层tcp连接已经被断开。

# 排查
要解释这个现象、修复这个问题，需要对齐的上下文很长，笔者尽力一点一点的梳理清楚。
## 网络通讯技术选型
按业务的架构，SDK中需要初始化一个http-server用于接受来自server的指令。  
考虑到组件自身的成熟度和对组件的掌控度，server端使用老牌的apache-http-client来发起http请求、下发指令，SDK端使用Undertow来接受、处理server端下发的指令。

![20240928153833639.jpg](/img/2024-02-04-HTTP请求偶现ConnectionClosedException/20240928153833639.jpg)

1. Apache-http-client起源于commons-httpclient，诞生于2001年，生态完整、社区活跃。其对HTTP协议实现的兼容性、完整性毋庸置疑。

> *HttpClient* was started in 2001 as a subproject of the Jakarta Commons, based on code developed by the [Jakarta Slide](http://jakarta.apache.org/slide/) project. 
> It was promoted out of the Commons in 2004, graduating to a separate Jakarta project.
> In 2005, the HttpComponents project at Jakarta was created, with the task of developing a successor to *HttpClient 3.x* and to maintain the existing codebase until the new one is ready to take over.
> The [Commons](http://commons.apache.org/) project, cradle of *HttpClient*, left [Jakarta](http://jakarta.apache.org/) in 2007 to become an independent Top Level Project. 
> Later in the same year, the [HttpComponents](http://httpcomponents.apache.org/) project also left Jakarta to become an independent Top Level Project, taking the responsibility for maintaining *HttpClient* with it.
> 
> 
> [HttpClient - HttpClient Home](https://hc.apache.org/httpclient-legacy/index.html)

2. Undertow在SpringBoot生态中引入来替换tomcat，其稳定性和可用性因为SpringBoot的广泛使用而久经考验。

审慎的选用上述两个组件来支撑业务，按理来说应该是强强联合，绝不应该出现上文提到的异常情况。

> 下文以HC代指 apache-http-client

## http1.1持久连接
该中间件使用的HC、Undertow版本都比较新，默认支持http协议1.1版本。在http1.1中，引入了一个杀手级特性：**连接复用(keep alive)**。  
在http协议请求-响应交互模型下，http1每次发出请求都会新建tcp连接，服务端处理完请求、发出响应后立马回关闭tcp连接，如下左图。tcp连接的建立和销毁是开销比较大的动作，因此该短连接模式无法适应互联网服务规模的快速增长。  
为了解决该问题，http1.1设计、规范了持久连接。应用层代码无需修改，照旧按http协议请求-响应交互模型进行编排业务，底层的UA(如上述HC)透明的进行连接复用。通过复用tcp连接来**分摊**tcp连接建立和销毁的开销，如下右图。

![img](/img/2024-02-04-HTTP请求偶现ConnectionClosedException/20240928151220346.jpg)

## http1.1长连生命周期
当http协议演进到这个阶段，可以对照到我们比较熟悉的其他通讯协议了，如redis通讯协议、mysql通讯协议。这些协议都会复用底层的tcp长连，设计特定的拆包机制在同一个连接上读写请求、响应。  
为了提升请求吞吐，redis-client、mysql-client等组件会在必要时建立多个tcp连接维护到【连接池】中，类似的，http1.1-client如HC，底层也会维护一个连接池供上层业务【租用】。  
HC组件抽象的连接池接口如下：

![img](/img/2024-02-04-HTTP请求偶现ConnectionClosedException/20240928151220390.jpg)

> org.apache.http.pool.ConnPool

如上述，HC底层会维护一个【连接池】，【连接池】本质上是一个【对象池】，进一步可以理解为【缓存】，因此，必要时可能还会按缓存管理的思路，用LRU、LFU算法来进行【本地】生命周期管理。  
这是连接生命周期的第一层。
## C/S生命周期对齐
我们说的连接、tcp连接或者socket，不是普通的对象(Object)。普通的值对象(VO)缓存，用LRU、LFU来进行【本地】生命周期管理就足够了，但网络连接对象不行。  
网络连接对象的特殊性在于：网络连接对象是连接client、server两端的，一个网络连接会在C、S两端各自产生一个socket对象，连接池中的连接对象的有效性是C/S两端联动的。  
换句话说，C端关闭、剔除了socket对象缓存，会导致S端也需要**被动的**剔除该socket对象缓存，反之亦然。  
为了避免上述C/S两端socket对象生命周期没有对齐导致的诡异问题，一个tcp连接在C/S两端产生的socket对象缓存的生命周期需要**协商**一致。   
为此，http1.1协议设计了一个新的控制头：**Keep-Alive**。   
该控制头由server端在响应中返回，用于提示client当前socket对象的最大空闲时间，如下图：

![20240928151220271.jpg](/img/2024-02-04-HTTP请求偶现ConnectionClosedException/20240928151220271.jpg)

> `timeout`: An integer that is the time in seconds that the host will allow an idle connection to remain open before it is closed. A connection is idle if no data is sent or received by a host. A host may keep an idle connection open for longer than `timeout` seconds, but the host should attempt to retain a connection for at least `timeout` seconds.
>
> [Keep-Alive - HTTP | MDN](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Keep-Alive)

如上图，HC收到该响应后，会提取`timeout=5`，设置连接的空闲时间为5s，然后将连接重新放回连接池。   
有新请求时，HC从连接池租借连接(socket)，检查该socket是否已经超过最大空闲时间(如上述5s)，如果超过则关闭、从连接池剔除该连接，换其他健康连接或新建新连接。  
同时，返回上述timeout参数的server端也必须按它返回给client的空闲时间(如上述**5s**)来保留连接，保证在`timeout`时间窗口内，该连接在C/S两端的socket对象都是健康的。  

## Undertow Keepalive
Undertow默认实现了http1.1 Keepalive特性，连接最大空闲时间默认为**60s**，一旦tcp连接上超过**60s**没有新请求进来，就会关闭连接。

![img](/img/2024-02-04-HTTP请求偶现ConnectionClosedException/20240928151220328.jpg)

> io.undertow.UndertowOptions#NO_REQUEST_TIMEOUT

![img](/img/2024-02-04-HTTP请求偶现ConnectionClosedException/20240928151220465.jpg)

> io.undertow.Undertow#start

这个60s没啥问题，在SpringMVC中也支持通过如下配置来调整：

```properties
server.undertow.no-request-timeout=600s
```

![img](/img/2024-02-04-HTTP请求偶现ConnectionClosedException/20240928151220385.jpg)

关键的问题在，Undertow在返回响应时，没有将这个`timeout`时间返回到client。如下示例：

![20240928155028652.jpg](/img/2024-02-04-HTTP请求偶现ConnectionClosedException/20240928155028652.jpg)

## HttpClient Keepalive

HC收到响应后，会提取**`Keep-Alive`**响应头，确定当前连接的最大空闲时间。代码如下：

![img](/img/2024-02-04-HTTP请求偶现ConnectionClosedException/20240928151220527.jpg)

> org.apache.http.impl.client.DefaultConnectionKeepAliveStrategy#getKeepAliveDuration

由于Undertow没有返回`keepalive timeout`，则HC会认为该连接永久有效。  
这里就产生了冲突：HC认为该连接永久有效，但是Undertow会在连接空闲60s后关闭连接。假设一个连接刚好空闲了60s，Undertow正在关闭连接的同时，HC在该连接上发出了一个请求，就会**导致请求失败**。

![image-20240928162830719](/img/2024-02-04-HTTP请求偶现ConnectionClosedException/20240928161206518.jpg)

# 处置
一路下来，我们发现问题的本质为：C、S两端维护的socket状态没有对齐，导致并发场景下会偶现C端认为连接健康发出请求，同时S端认为连接空闲超时关闭请求引发的错误。  
这个现象很普遍，为了解决这个问题，SDK调整了HC对象的构造参数，覆盖默认的`ConnectionKeepAliveStrategy`。如果服务端没有返回keepalive timeout，则兜底使用30s作为timeout。  
保证在undertow(S端)判定连接超时(默认60s)、关闭连接前，HC(C端)提前就弃用了该连接。

![image-20240928161206517](/img/2024-02-04-HTTP请求偶现ConnectionClosedException/20240928161206517.jpg)

发布上线后，再没有类似的`ConnectionClosedException`异常告警啦~
