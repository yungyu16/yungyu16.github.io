---
layout: post
title: 从Push Flag角度改善TCP的延时 [译]
date: 2021-10-20
typora-root-url: ../
catalog: true
tags:
  - 网络原理
---

当通过TCP进行通讯时，TCP协议会尝试通过将数据分块传输来优化性能。在进行文件和其他大数据传输时，这种方式的优化效果很好。  

TCP实现这种优化的基础是TCP报文头里的Push Flag(PSH位)。

[TCP报文头](http://en.wikipedia.org/wiki/Transmission_Control_Protocol)

发送端用PSH位来标记当前报文为一个数据块的结尾(例如：应用层协议头或应用层协议体被发送完时)。这个标记用来告知接受端的TCP协议层：立即将受到的数据通知给上层等待数据的应用，而不是等到接收端读缓冲区填充满。  
PSH位一般不被发送端应用层控制，而是由发送端TCP协议层控制。大部分现代的TCP/IP协议栈会在传入到send()方法的的用户缓冲区拆分的TCP最后一个分组上设置PSH位。  
PSH位通过将大块连续数据拆分成逻辑小块来帮助接收端来优化吞吐量。

但是接收端应用可能希望数据一旦到达，就尽快从TCP协议层拿到数据，而不是将数据留在TCP协议层进行缓冲优化。

- 流媒体场景如电影播放或音乐播放，应用需要尽快播放数据流。
- 低延迟应用比如在线游戏，应用需要和后端服务器进行尽可能实时的数据同步。

通常低延时应用和流媒体应用都不使用TCP协议进行通讯，因为在TCP协议中实现的许多“优化”通常是通过牺牲延迟来增加数据吞吐量。他们会直接使用UDP协议，并在必要时实现自己的重传协议。

# 通过较小的读缓冲区来避免延时

如果特定场景强制使用TCP协议且需要低延时通讯，那么接受方应用在调用recv()方法时可以通过传入较小的用户缓冲区来优化延迟。注意不要混淆接收方应用提供的用户态接收缓冲区和TCP协议层内部的读缓冲区。

[recv()](http://msdn.microsoft.com/en-us/library/windows/desktop/ms740121.aspx)

[读缓冲区](http://smallvoid.com/article/tcpip-rwin-size.html)

recv()、WSARecv()两个方法调用在下面任意条件满足时会返回：

- 当带有PSH位的分组到达
- 当用户缓冲区满了
- 0.5s内没有新数据到达

# 全局禁用PSH位优化

接收方可以通过禁用TCP协议PSH位缓冲优化来避免延时，这种方式会影响所有TCP/IP连接的性能，但是会减少预期外的延时。这种方式在不能修改发送端(Linux/Telnet)使用PSH位且不能修改应用用于接收数据的缓冲区大小时很有用。

```plaintext
[HKEY_LOCAL_MACHINE \System \CurrentControlSet \Services \Afd \Parameters]IgnorePushBitOnReceives = 1
```

# 在单个连接上禁用PSH位优化

Windows 8.1 / Windows 2012允许在连接上调用WSARecv()方法时添加MSG_PUSH_IMMEDIATE标志来禁用PSH位优化。

[WSARecv()](https://msdn.microsoft.com/en-us/library/windows/desktop/ms741688.aspx)

# 使用较大的写缓冲区来避免延时

发送方应用可以通过保证send()方法传入的用户缓冲区大小比TCP协议称写缓冲区小来修复这个问题。可以通过调用setsockopt(SO_SNDBUF) 来设置一个64KB的socket写缓冲区，调用WSASend()方法时传入一个32KB的用户缓冲区。  
这会保证每个写操作写入的缓冲区数据最后一个传输分组都会带上PSH位，且可以避免延迟数据分块导致的延迟确认问题。

[延迟确认](http://support.microsoft.com/kb/823764)

如果不能修改发送方应用，也可以通过修改下面的注册表键来实现：

```plaintext
[HKEY_LOCAL_MACHINE \System \CurrentControlSet \Services \Afd \Parameters]NonBlockingSendSpecialBuffering = 1
```

相关问题 TCP_NODELAY disables nagle algorithm and can improve latency

[TCP_NODELAY disables nagle algorithm and can improve latency](http://smallvoid.com/article/winnt-nagle-algorithm.html)
