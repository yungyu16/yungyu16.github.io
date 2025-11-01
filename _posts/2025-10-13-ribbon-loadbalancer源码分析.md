---
layout: post
title: ribbon-loadbalancer源码分析
date: 2025-10-13
typora-root-url: ../
catalog: true
tags:
  - 微服务
  - 负载均衡
  - 源码分析
---

# 1. 简介

ribbon-loadbalancer 是 Netflix 开源的一款基于 HTTP 和 TCP 的客户端负载均衡工具 ，主要用于在分布式系统中将服务请求合理地分配到多个服务实例上，以提高系统的可用性和性能。

它是 Spring Cloud 生态中的核心组件之一，常与 Eureka、Consul 等服务发现工具配合使用。

1. 负载均衡
   1. 支持多种负载均衡策略（如轮询、随机、加权响应时间等），默认是轮询（Round Robin）。
   2. 在客户端（消费者侧）实现请求分发，避免集中式负载均衡器的单点故障。
2. 服务发现集成
   1. 与 Eureka、Consul 等服务注册中心无缝集成，动态获取服务实例列表。
   2. 自动剔除失效实例，保证请求转发到健康的节点。

Ribbon是一个门面，它封装了 服务发现/负载均衡 场景下的样板代码，**它不绑定具体的微服务****注册中心****和上层使用服务发现的组件**，只是在流程中提供了易集成、易拓展的API，供各个业务场景灵活适配。

![image-20251108192503696](/img/2025-10-13-ribbon-loadbalancer源码分析/20251108192503696.png)



# 2. 核心API

## 1. Server

![img](/img/2025-10-13-ribbon-loadbalancer%E6%BA%90%E7%A0%81%E5%88%86%E6%9E%90/20251108192113792.png)

服务注册中心中 【实例】概念的抽象，核心是 schema、ip、port。

提供各类 服务注册中心(consul/nacos/eureka等) 服务实例 数据模型的 最小化抽象，是最大公约数。

## 2. ServerList

![img](/img/2025-10-13-ribbon-loadbalancer%E6%BA%90%E7%A0%81%E5%88%86%E6%9E%90/20251108192113519.png)

桥接各个数据源(注册中心)的 适配器，用于拓展、对接各个注册中心，转换数据结构。

Nacos对接的代码如下：

![img](/img/2025-10-13-ribbon-loadbalancer%E6%BA%90%E7%A0%81%E5%88%86%E6%9E%90/20251108192113574.png)

## 3. Filter

![img](/img/2025-10-13-ribbon-loadbalancer%E6%BA%90%E7%A0%81%E5%88%86%E6%9E%90/20251108192113611.png)

对原始的实例列表进行过滤，比如按可用区、按染色环境等逻辑标记。

## 4. Rule

![img](/img/2025-10-13-ribbon-loadbalancer%E6%BA%90%E7%A0%81%E5%88%86%E6%9E%90/20251108192113350.png)

职责是：基于既有的Server列表，动态的评估、决策、挑选一个合适的Server。

是负载均衡的策略拓展，各个不同的负载均衡策略在这个接口拓展、实现。

## 5. LoadBalancer

![img](/img/2025-10-13-ribbon-loadbalancer%E6%BA%90%E7%A0%81%E5%88%86%E6%9E%90/20251108192113501.png)

LoadBanancer是整个服务发现、负载均衡的门面，用于集成、编排上述拓展API。

是上层代码感知和操作的核心API。

经典的预定义实现类DynamicServerListLoadBalancer的构造方法如下：

![img](/img/2025-10-13-ribbon-loadbalancer%E6%BA%90%E7%A0%81%E5%88%86%E6%9E%90/20251108192113561.png)![img](/img/2025-10-13-ribbon-loadbalancer%E6%BA%90%E7%A0%81%E5%88%86%E6%9E%90/20251108192113702.png)

LoadBanancer实例只负责单个 服务 的 服务发现和负载均衡。

以Dubbo为例，每个API Interface都需要一个对应的LoadBanancer实例。

# 3. 集成使用

## 1. 对接注册中心，获取实例列表

```java
import com.netflix.loadbalancer.Server;
import com.netflix.loadbalancer.ServerList;
import java.util.List;

public class UnifiedServerList implements ServerList<Server> {

    @Override
    public List<Server> getInitialListOfServers() {
        return getServerList(); // 统一调用
    }

    @Override
    public List<Server> getUpdatedListOfServers() {
        return getServerList(); // 统一调用
    }

    // 统一的服务列表获取逻辑
    private List<Server> getServerList() {
        // 模拟从注册中心（如Eureka/Consul）或数据库动态获取
        return List.of(
            new Server("http://service1:8080"),
            new Server("http://service2:8080"),
            new Server("http://service3:8080")
        );
    }
}
```

## 2. 构造/使用LoadBalancer

```java
import com.netflix.loadbalancer.*;

public class RibbonManualExample {

    public static void main(String[] args) {
        // 1. 使用统一的服务列表实现
        ServerList<Server> serverList = new UnifiedServerList();

        // 2. 创建负载均衡器
        DynamicServerListLoadBalancer<Server> loadBalancer = new DynamicServerListLoadBalancer<>(
            new DefaultClientConfigImpl(),
            new RoundRobinRule(),            // 负载均衡策略
            new PollingServerListUpdater(),  // 定时更新器
            serverList,                      // 统一的服务列表源
            null                             // 无过滤器
        );

        // 3. 初始化
        loadBalancer.initWithNiwsConfig(new DefaultClientConfigImpl());

        // 4. 模拟请求分发
        for (int i = 0; i < 3; i++) {
            Server server = loadBalancer.chooseServer("default");
            System.out.println("Selected Server: " + server.getHostPort());
        }
    }
}
```

# 4. 核心流程

## 1. 实例列表刷新

![img](/img/2025-10-13-ribbon-loadbalancer%E6%BA%90%E7%A0%81%E5%88%86%E6%9E%90/20251108192113816.png)

### 1. 开启任务

![img](/img/2025-10-13-ribbon-loadbalancer%E6%BA%90%E7%A0%81%E5%88%86%E6%9E%90/20251108192113726.png)

![img](/img/2025-10-13-ribbon-loadbalancer%E6%BA%90%E7%A0%81%E5%88%86%E6%9E%90/20251108192113763.png)

### 2. 定时任务

![img](/img/2025-10-13-ribbon-loadbalancer%E6%BA%90%E7%A0%81%E5%88%86%E6%9E%90/20251108192113893.png)

![img](/img/2025-10-13-ribbon-loadbalancer%E6%BA%90%E7%A0%81%E5%88%86%E6%9E%90/20251108192113870.png)

## 2. 实例状态

![image-20251108192256493](/img/2025-10-13-ribbon-loadbalancer源码分析/20251108192256493.png)

### 1. LoadBalancerStats

![img](/img/2025-10-13-ribbon-loadbalancer%E6%BA%90%E7%A0%81%E5%88%86%E6%9E%90/20251108192114089.png)

`LoadBalancerStats` 是 Ribbon 的核心统计类，负责聚合所有服务实例（Server）的运行状态 ，为负载均衡决策提供全局视角的数据支持（如区域/集群级别的健康状态、请求分布等）。

| **功能**         | **说明**                                                     |
| ---------------- | ------------------------------------------------------------ |
| 全局实例统计     | 跟踪所有 Server 的请求量、错误率、响应时间等                 |
| 区域（Zone）感知 | 统计不同可用区（Zone）的实例数量和负载情况                   |
| 熔断状态监控     | 汇总各实例的熔断状态（CircuitBreaker）                       |
| 自定义指标暴露   | 提供方法获取负载均衡器的整体健康度（如平均延迟、最忙Zone等） |

#### 关键方法

##### 1. 实例级统计

```java
// 获取特定Server的统计对象（ServerStats）
ServerStats getServerStats(Server server);

// 获取所有实例的平均响应时间（毫秒）
double getAverageResponseTime(String zone);
```

##### 2. 区域（Zone）级统计

```java
// 获取某个Zone的活跃实例数
int getAvailableServersCountInZone(String zone);

// 获取所有Zone的名称列表
Set<String> getAvailableZones();
```

##### 3. 全局健康状态

```java
// 计算负载均衡器的整体错误率（0~1）
double getOverallFailureRate();

// 检查是否所有实例均被熔断
boolean isAllServersDownInZone(String zone);
```

### 2. ServerStats

![img](/img/2025-10-13-ribbon-loadbalancer%E6%BA%90%E7%A0%81%E5%88%86%E6%9E%90/20251108192114617.png)

`com.netflix.loadbalancer.ServerStats`用于统计和跟踪服务实例（Server）的运行状态 ，为负载均衡策略（如 `WeightedResponseTimeRule`）提供关键指标（如响应时间、请求数、错误率等）。

| **功能**     | **说明**                                           |
| ------------ | -------------------------------------------------- |
| 请求计数     | 记录总请求数、成功/失败请求数                      |
| 响应时间统计 | 计算平均响应时间、滚动窗口响应时间（用于动态权重） |
| 错误率计算   | 基于失败请求数统计错误率                           |

#### 1. 关键方法

##### 1. 请求记录

```java
// 记录请求开始时间（用于计算响应时间）
void noteRequestStart();
// 记录请求完成（成功/失败）
void noteRequestCompletion(long duration);
void noteRequestFailure();
```

##### 2. 统计数据获取

```java
// 获取平均响应时间（毫秒）
long getResponseTimeAvg();
// 获取错误率（0~1）
double getFailureRate();
// 获取总请求数
int getTotalRequestsCount();
// 获取当前实例是否健康（未被熔断）
boolean isCircuitBreakerTripped();
```

##### 3. 熔断控制

```java
// 手动触发熔断
void setCircuitBreakerTripped(boolean tripped);
// 检查熔断状态
boolean isCircuitBreakerTripped();
```

![img](/img/2025-10-13-ribbon-loadbalancer%E6%BA%90%E7%A0%81%E5%88%86%E6%9E%90/20251108192114223.png)

### 3. 状态维护

状态的维护需要上层代码来协作，根据调用结果，来更新ServerStats。

![image-20251108192408632](/img/2025-10-13-ribbon-loadbalancer源码分析/20251108192408632.png)


**样板代码**

```java
 // 1. 定义命令接口（核心：封装请求逻辑和状态更新）
    @FunctionalInterface
    public interface RibbonCommand<T> {
        T execute(Server server) throws Exception; // 业务逻辑
    }

    // 2. 负载均衡执行器（维护状态 + 执行命令）
    public static class RibbonExecutor {
        private final ILoadBalancer loadBalancer;
        private final LoadBalancerStats stats;

        public RibbonExecutor(ILoadBalancer loadBalancer) {
            this.loadBalancer = loadBalancer;
            this.stats = new LoadBalancerStats("demo");
        }

        // 执行命令并自动更新状态
        public <T> T executeCommand(RibbonCommand<T> command) {
            Server server = null;
            try {
                // 选择目标实例
                server = loadBalancer.chooseServer("default");
                ServerStats serverStats = stats.getServerStats(server);

                // 记录请求开始时间（用于计算耗时）
                long startTime = System.nanoTime();
                serverStats.noteRequestStart();

                // 执行业务逻辑
                T result = command.execute(server);

                // 记录成功状态
                serverStats.noteRequestCompletion(System.nanoTime() - startTime);
                return result;
            } catch (Exception e) {
                // 记录失败状态
                if (server != null) {
                    stats.getServerStats(server).noteRequestFailure();
                }
                throw new RuntimeException("Execution failed", e);
            }
        }

        public LoadBalancerStats getStats() {
            return stats;
        }
    }
```

## 3. 负载均衡

![img](/img/2025-10-13-ribbon-loadbalancer%E6%BA%90%E7%A0%81%E5%88%86%E6%9E%90/20251108192114048.png)

> com.netflix.loadbalancer.BaseLoadBalancer#chooseServer

### 1. 可用性过滤

![img](/img/2025-10-13-ribbon-loadbalancer%E6%BA%90%E7%A0%81%E5%88%86%E6%9E%90/20251108192114163.png)

> com.netflix.loadbalancer.AvailabilityFilteringRule#choose

![img](/img/2025-10-13-ribbon-loadbalancer%E6%BA%90%E7%A0%81%E5%88%86%E6%9E%90/20251108192114526.png)

> com.netflix.loadbalancer.AvailabilityFilteringRule#AvailabilityFilteringRule

![img](/img/2025-10-13-ribbon-loadbalancer%E6%BA%90%E7%A0%81%E5%88%86%E6%9E%90/20251108192114009.png)

![img](/img/2025-10-13-ribbon-loadbalancer%E6%BA%90%E7%A0%81%E5%88%86%E6%9E%90/20251108192114309.png)

> com.netflix.loadbalancer.AvailabilityPredicate#apply

默认开启熔断、默认不考虑实例在途请求数

### 2. 轮询算法

![img](/img/2025-10-13-ribbon-loadbalancer%E6%BA%90%E7%A0%81%E5%88%86%E6%9E%90/20251108192114410.png)

![img](/img/2025-10-13-ribbon-loadbalancer%E6%BA%90%E7%A0%81%E5%88%86%E6%9E%90/20251108192114489.png)

![img](/img/2025-10-13-ribbon-loadbalancer%E6%BA%90%E7%A0%81%E5%88%86%E6%9E%90/20251108192114248.png)

> com.netflix.loadbalancer.RoundRobinRule#choose(com.netflix.loadbalancer.ILoadBalancer, java.lang.Object)

使用基于计数器的 轮询算法。

# 5. 总结

Ribbon 作为 Netflix 开源的 客户端负载均衡器 ，其核心价值在于通过 解耦、可扩展的架构设计 ，为分布式系统提供了灵活的服务发现与负载均衡能力。它的设计哲学体现在以下几个方面：

1. 模块化与可插拔
   1. 通过 `ServerList`、`IRule`、`ServerListFilter` 等接口，实现与注册中心（如 Eureka、Consul）的无缝对接，同时支持自定义策略（如权重、区域感知）。
   2. “约定优于配置” ：默认提供 `RoundRobinRule`、`ZoneAvoidanceRule` 等常用策略，用户可按需替换。
2. 客户端负载均衡的优势
   1. 避免集中式负载均衡器（如 Nginx）的单点故障，由消费方自主决策请求分发，提升系统弹性、韧性。
   2. 结合 `ServerStats` 实时监控实例状态（如响应时间、熔断状态），实现动态路由和容错。
3. 状态驱动的智能决策
   1. 负载均衡器（`ILoadBalancer`）通过 `LoadBalancerStats` 聚合全局指标，`IRule` 基于实时数据（如错误率、区域负载）选择最优实例。
   2. 被动更新机制 ：由业务调用结果驱动状态更新（如 `noteRequestCompletion`），而非主动探测，降低开销。

尽管 Spring Cloud 已推荐使用 `Spring Cloud LoadBalancer`，Ribbon 的设计理念（如模块化、客户端负载均衡）仍值得借鉴，其核心思想在云原生领域持续发挥作用。
