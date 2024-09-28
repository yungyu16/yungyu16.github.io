---
layout: post
title: Nginx之Location匹配规则
date: 2020-03-19
typora-root-url: ../
catalog: true
tags:
  - Nginx
---

# 概述

经过多年发展，nginx凭借其优异的性能征服了互联网界，成为了各个互联网公司架构设计中不可获取的要素。Nginx是一门大学问，但是对于Web开发者来说，最重要的是需要能捋的清楚Nginx的请求路由配置。

Nginx的路由配置放在配置文件中的Location子节，下面我们来熟练掌握Location的配置。

# 语法规则

```scss
 location [ = | ~ | ~* | ^~ ] uri { ... }
 location @name { ... }
```

location 为关键字 类似java中的case关键字，关键字后跟随可选的修饰符，然后是匹配规则(正则匹配和模式匹配)，后面的代码块为请求处理或转发的逻辑。

# 修饰符

一共4种修饰符：

1. `=` 表示精确匹配。只有请求的url路径与后面的字符串完全相等时，才会命中。
2. `~` 表示该规则是使用正则定义的，区分大小写。
3. `~*` 表示该规则是使用正则定义的，不区分大小写。
4. `^~` 表示前缀匹配，在正则之前。如果该符号后面的字符是最佳匹配，采用该规则，不再进行后续的查找。
5. `` **空修饰符，表示前缀匹配**，但是在正则匹配之后。

## 「=」 修饰符-完全匹配

**特点：要求路径完全匹配**

```fsharp
 server {
     server_name website.com;
     location = /abcd {
     	[…]
     }
 }
```

- `http://website.com/abcd`**匹配**
- `http://website.com/ABCD`**可能会匹配** ，也可以不匹配，取决于操作系统的文件系统是否大小写敏感
- `http://website.com/abcd?param1&param2`**匹配**，忽略 querystring
- `http://website.com/abcde`**不匹配

## 「~」修饰符-正则匹配

**特点：区分大小写的正则匹配**

```bash
server {
server_name website.com;
	location ~ ^/abcd$ {
		[…]
	}
}
```

注意： `^/abcd$`这个正则表达式表示字符串必须以`/`开始，以`$`结束，中间必须是`abcd`

- `http://website.com/abcd`**匹配**（完全匹配）
- `http://website.com/ABCD`**不匹配**，大小写敏感
- `http://website.com/abcd?param1&param2`**匹配**
- `http://website.com/abcd/`**不匹配**，不能匹配正则表达式
- `http://website.com/abcde`**不匹配**，不能匹配正则表达式

## 「~*」修饰符-正则匹配

**特点：不区分大小写的正则匹配**

```bash
 server {
     server_name website.com;
     location ~* ^/abcd$ {
     	[…]
     }
 }
```

- `http://website.com/abcd`**匹配** (完全匹配)
- `http://website.com/ABCD`**匹配** (大小写不敏感)
- `http://website.com/abcd?param1&param2`**匹配**
- `http://website.com/abcd/` `不匹配`，不能匹配正则表达式
- `http://website.com/abcde` `不匹配`，不能匹配正则表达式

## 「^~」修饰符-模式匹配

前缀匹配 如果该 location 是最佳的匹配，那么对于匹配这个 location 的字符串， 该修饰符不再进行正则表达式检测。  
注意，这不是一个正则表达式匹配，它的目的是优先于正则表达式的匹配

# 匹配过程

对请求的url序列化。例如，对`%xx`等字符进行解码，去除url中多个相连的`/`，解析url中的`.`，`..`等。这一步是匹配的前置工作。

location有两种表示形式，一种是使用前缀字符，一种是使用正则。如果是正则的话，前面有`~`或`~*`修饰符。

具体的匹配过程如下：

首先先检查使用前缀字符定义的location，选择最长匹配的项并记录下来。

如果找到了精确匹配的location，也就是使用了`=`修饰符的location，结束查找，使用它的配置。

然后按顺序查找使用正则定义的location，如果匹配则停止查找，使用它定义的配置。

如果没有匹配的正则location，则使用前面记录的最长匹配前缀字符location。

基于以上的匹配过程，我们可以得到以下两点启示：

1. **使用正则定义的location在配置文件中出现的顺序很重要**。因为找到第一个匹配的正则后，查找就停止了，后面定义的正则就是再匹配也没有机会了。
2. **使用精确匹配可以提高查找的速度**。例如经常请求`/`的话，可以使用`=`来定义location。

# 匹配规则

**原则：** 先精确匹配，没有则查找带有 `^~`的前缀匹配，没有则进行正则匹配，最后才返回前缀匹配的结果（如果有的话）

1. 首先精确匹配 =
2. 其次前缀匹配 ^~
3. 其次是按文件中顺序的正则匹配
4. 然后匹配不带任何修饰的前缀匹配。
5. 最后是交给 / 通用匹配
6. 当有匹配成功时候，停止匹配，按当前匹配规则处理请求

注意：前缀匹配，如果有包含关系时，按最大匹配原则进行匹配。比如在前缀匹配：`location /dir01` 与 `location /dir01/dir02`。   
如有请求 `http://localhost/dir01/dir02/file` 将最终匹配到 `location /dir01/dir02`

**匹配逻辑伪代码：**

```kotlin
 function match(uri):
  rv = NULL
  
  if uri in exact_match:
    return exact_match[uri]
  
  if uri in prefix_match:
    if prefix_match[uri] is '^~':
      return prefix_match[uri]
    else:
      rv = prefix_match[uri] // 注意这里没有 return，且这里是最长匹配
   
  if uri in regex_match:
    return regex_match[uri] // 按文件中顺序，找到即返回
  return rv```
```

# URL尾部的`/`

关于URL尾部的`/`有三点也需要说明一下。第一点与location配置有关，其他两点无关。

1. location中的字符有没有`/`都没有影响。也就是说`/user/`和`/user`是一样的。
2. 如果URL结构是`https://domain.com/`的形式，尾部有没有`/`都不会造成重定向。因为浏览器在发起请求的时候，默认加上了`/`。虽然很多浏览器在地址栏里也不会显示`/`。  
   这一点，可以访问[baidu](https://www.baidu.com/)验证一下。
3. 如果URL的结构是`https://domain.com/some-dir/`。尾部如果缺少`/`将导致重定向。因为根据约定，URL尾部的`/`表示目录，没有`/`表示文件。所以访问`/some-dir/`时，服务器会自动去该目录下找对应的默认文件。  
   如果访问`/some-dir`的话，服务器会先去找`some-dir`文件，找不到的话会将`some-dir`当成目录，重定向到`/some-dir/`，去该目录下找默认文件。可以去测试一下你的网站是不是这样的。

# 总结

location的配置有两种形式，前缀字符和正则。查找匹配的时候，先查找前缀字符，选择最长匹配项，再查找正则。正则的优先级高于前缀字符。

正则的查找是按照在配置文件中的顺序进行的。因此正则的顺序很重要，建议越精细的放的越靠前。

使用`=`精准匹配可以加快查找的顺序，如果根域名经常被访问的话建议使用`=`。

# 参考

- [一文弄懂Nginx的location匹配](https://segmentfault.com/a/1190000013267839)
- [彻底弄懂 Nginx location 匹配](https://juejin.im/post/5ce5e1f65188254159084141)
- [Nginx 入门教程](https://xuexb.github.io/learn-nginx/example/error-page.html)
- [location 匹配规则](https://moonbingbing.gitbooks.io/openresty-best-practices/ngx/nginx_local_pcre.html)
