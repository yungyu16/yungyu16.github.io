---
layout: post
title: Github Packages和Github Actions实践之CI&CD
date: 2020-03-09
typora-root-url: ../
catalog: true
tags:
  - CI/CD
  - Github
  - 工作流
  - devops
---

![img](/img/2020-03-09-Github Packages和Github Actions实践之CI&CD/1168906-20200309053307431-877799527.png)

# 概述

Github在被微软收购后，不忘初心，且更大力度的造福开发者们，推出了免费私有仓库等大更新。近期又开放了packages和actions两个大招，经笔者试用后感觉这两个功能配合起来简直无敌。

[GitHub Packages](https://github.com/features/packages) 是一个和每一个代码仓库关联的软件包仓库。通俗来说就是代码仓库中存放的是源码，软件包仓库中存放的是编译输出后的**可以被各个语言生态的依赖管理工具直接依赖**的lib。类似的我们熟知的有maven中央仓库和nmp仓库。

[GitHub Actions](https://github.com/features/actions) 是一个Github原生的持续集成和部署的工作流组件。通俗来说就是Github**免费给你提供虚拟主机**，由你编写工作流脚本来进行源码的检出，编译，测试，和发布。类似的我们可以想象成Github给每个仓库都免费绑定了一个Jenkins服务，编写pipeline脚本即可进行源码的集成和发布。

# Github Token

首先我们讨论下Github Token，因为后续操作都需要用到这个Token.

Github Token是用户登录后生成的用户凭证，类似JWT登录令牌，令牌关联了操作权限，用户开发者授权给第三方服务进行仓库管理或者开发者自己利用Github Api做一些极客操作。

操作入口:https://github.com/settings/tokens。
![img](/img/2020-03-09-Github Packages和Github Actions实践之CI&CD/1168906-20200309050538067-1442301217.png)
![img](/img/2020-03-09-Github Packages和Github Actions实践之CI&CD/1168906-20200309050652039-1881799706.png)

点击生成Token后输入描述性名称，一般用来说明这个token是用来干嘛的，勾选这个token的权限。确认后会生成一个token字符串。这个token只会展示一次，退出页面后就会消失，所以要谨慎保存。

如果token不慎泄露，可以在token列表对token进行失效操作。

# [Github Secrets](https://help.github.com/en/actions/configuring-and-managing-workflows/creating-and-storing-encrypted-secrets) 密文字典

密文字典用于将一些隐私的保密的配置如password，token等通过键值对的形式以密文保存在Github中，在一些需要的场景如Github Actions中，可以通过Github暴露的Api进行取用，避免了源码公开导致的安全问题。

密文字典与各个代码仓库关联，只能在当前代码仓库的上下文中使用，当前没有全局的密文字典。

入口路径为：`仓库 > Settings > Secrets`

![img](/img/2020-03-09-Github Packages和Github Actions实践之CI&CD/1168906-20200309050752402-2122798601.png)

# [Github Packages](https://help.github.com/en/packages) 包仓库

入口:

![img](/img/2020-03-09-Github Packages和Github Actions实践之CI&CD/1168906-20200309050842044-355265119.png)

支持的包类型：

|   包客户端   |    语言    |                包格式                |                          描述                          |                         仓库地址                          |
| :----------: | :--------: | :----------------------------------: | :----------------------------------------------------: | :-------------------------------------------------------: |
|    `npm`     | JavaScript |            `package.json`            |                  Node package manager                  | [https://npm.pkg.github.com](https://npm.pkg.github.com/) |
|    `gem`     |    Ruby    |              `Gemfile`               |                RubyGems package manager                |   https://USERNAME:TOKEN@rubygems.pkg.github.com/OWNER/   |
|    `mvn`     |    Java    |              `pom.xml`               | Apache Maven project management and comprehension tool |       https://maven.pkg.github.com/OWNER/REPOSITORY       |
|   `gradle`   |    Java    | `build.gradle` 或 `build.gradle.kts` |         Gradle build automation tool for Java          |       https://maven.pkg.github.com/OWNER/REPOSITORY       |
|   `docker`   |    N/A     |             `Dockerfile`             |          Docker container management platform          |                                                           |
| `dotnet` CLI |    .NET    |               `nupkg`                |           NuGet package management for .NET            |                                                           |

各类型账户的限制(自用完全够用了)：

| 产品                    | 存储  | 每月流量 |
| ----------------------- | ----- | -------- |
| GitHub Free             | 500MB | 1GB      |
| GitHub Pro              | 1GB   | 5GB      |
| GitHub Team             | 2GB   | 10GB     |
| GitHub Enterprise Cloud | 50GB  | 100GB    |

当前Packages支持常见的Docker,Java,Nodejs等生态。默认每个Github仓库都会关联一个包仓库。每个包仓库为一个包命名空间，因为每个包仓库地址都关联了代码仓库的id拥有者的id和。如一个Docker镜像名为`Test:latest`可以发布到多个Github包仓库且不会互相覆盖(Npm包的命名规则将代码仓库id和用户id放在了包名上，没有放在包仓库地址上)。

虽然公开代码仓库的包仓库界面是公开可读的，但是**包的发布和下载需要认证**。需要使用Github Token。下载需要认证目前被吐槽的比较狠，社区已经在讨论这个[issue](https://github.community/t5/GitHub-API-Development-and/Download-from-Github-Package-Registry-without-authentication/td-p/35255)，后续可能会允许免密下载。
下面以Docker为例讲解用法。

1、首先我们要进行登陆：

```shell
$ docker login -u USERNAME -p TOKEN docker.pkg.github.com
```

2、登录后我们将指定镜像重命名为Github Packages规定的Docker镜像名：

```shell
$ docker tag IMAGE_ID docker.pkg.github.com/OWNER/REPOSITORY/IMAGE_NAME:VERSION
```

注意：镜像名格式为docker仓库域名+仓库拥有者id+仓库名+镜像名+版本号

3、发布镜像

```shell
$ docker push docker.pkg.github.com/OWNER/REPOSITORY/IMAGE_NAME:VERSION
```

回到仓库页面，进入Packages，可以看到发布的包：

![img](/img/2020-03-09-Github Packages和Github Actions实践之CI&CD/1168906-20200309051013633-191372674.png)

点击包名进入详情：
![img](/img/2020-03-09-Github Packages和Github Actions实践之CI&CD/1168906-20200309051046208-758161762.png)

# [Github Actions ](https://help.github.com/en/actions)持续集成工作流

1、Github免费提供了虚拟主机，用来提供持续集成的运行环境。处于安全性考虑也可以使用自己的服务器资源执行构建任务，详见：[Hosting your own runners](https://help.github.com/en/actions/hosting-your-own-runners)

主机规格：

- 2-core CPU
- 7 GB of RAM memory
- 14 GB of SSD disk space

当前可选的运行环境有：

| Environment         | YAML Label                         | Included Software                                            |
| ------------------- | ---------------------------------- | ------------------------------------------------------------ |
| Ubuntu 18.04        | `ubuntu-latest` or `ubuntu-18.04`  | [ubuntu-18.04](https://github.com/actions/virtual-environments/blob/master/images/linux/Ubuntu1804-README.md) |
| Ubuntu 16.04        | `ubuntu-16.04`                     | [ubuntu-16.04](https://github.com/actions/virtual-environments/blob/master/images/linux/Ubuntu1604-README.md) |
| macOS 10.15         | `macos-latest` or `macos-10.15`    | [macOS-10.15](https://github.com/actions/virtual-environments/blob/master/images/macos/macos-10.15-Readme.md) |
| Windows Server 2019 | `windows-latest` or `windows-2019` | [windows-2019](https://github.com/actions/virtual-environments/blob/master/images/win/Windows2019-Readme.md) |
| Windows Server 2016 | `windows-2016`                     | [windows-2016](https://github.com/actions/virtual-environments/blob/master/images/win/Windows2016-Readme.md) |

各个运行环境中预装了常用的工具和各个语言生态的工具链，Ubuntu环境预装的软件列表:[列表](https://github.com/actions/virtual-environments/blob/master/images/linux/Ubuntu1804-README.md)

以Java生态为例，**Git，Docker，JDK，Maven已经预装**：

![img](/img/2020-03-09-Github Packages和Github Actions实践之CI&CD/1168906-20200309051155964-972396863.png)

2、使用方式：

Actions使用[YAML文件](https://help.github.com/en/actions/reference/workflow-syntax-for-github-actions)来编写声明式工作流。

在代码仓库根目录新建`github/workflows`目录，目录内的所有`.yml`文件都会被识别为一个持续集成工作流。

![img](/img/2020-03-09-Github Packages和Github Actions实践之CI&CD/1168906-20200309051302712-1981581922.png)

脚本语法详见[阮一峰的博客](http://www.ruanyifeng.com/blog/2019/09/getting-started-with-github-actions.html)，简介如下：

![img](/img/2020-03-09-Github Packages和Github Actions实践之CI&CD/1168906-20200309051334022-330590248.png)

工作流使用声明式语法，指定要干嘛，不需要说明怎么干，使用这种策略脚本清晰可读，但是表达能力较弱。

指定目录下每个yml文件会被自动识别为一个工作流，每个工作流由有自己的名称，和触发工作流的事件。事件主要分为：

- git操作相关的事件如push，pull request等。
- cron表达式

一个工作流包含多个job，需要指定运行环境。job之间是异步执行的，可以通过needs显式指定依赖来干预job执行次序，由于job在不同主机上执行，分属不同的文件系统，各个job产生的构建中间产物无法共用，一般通过将构建产物发布到[artifacts](https://help.github.com/en/actions/configuring-and-managing-workflows/persisting-workflow-data-using-artifacts)来进行衔接。

一个job可以包含多个step，同一个job中的setp是同步执行的，各个步骤的构建产物都在当前job使用的主机上。

由于步骤重合度高，如maven编译，docker构建，docker发布等，Github使用[应用市场](https://github.com/marketplace?type=actions)来汇总开发者开源的构建步骤脚本，用于重用。Github自己也开发了一些基础功能脚本如 `actions/checkout`。

可以通过在步骤中使用`uses`命令+actions名称@版本来引用功能，节约成本和可读性。

Token，密码等隐私变量可以通过暴露的Secrets对象利用[插值语法](https://help.github.com/en/actions/reference/context-and-expression-syntax-for-github-actions#literals)来引用。

3、为了丰富工作流脚本的表达能力，Github在脚本编译执行上下文中暴露了一些Github变量和环境变量，用于开发者使用。

[Github变量](https://help.github.com/en/actions/reference/context-and-expression-syntax-for-github-actions)如下：

| Context name | Type     | Description                                                  |
| ------------ | -------- | ------------------------------------------------------------ |
| `github`     | `object` | Information about the workflow run. For more information, see [`github` context](https://help.github.com/en/actions/reference/context-and-expression-syntax-for-github-actions#github-context). |
| `env`        | `object` | Contains environment variables set in a workflow, job, or step. For more information, see [`env` context](https://help.github.com/en/actions/reference/context-and-expression-syntax-for-github-actions#env-context) . |
| `job`        | `object` | Information about the currently executing job. For more information, see [`job` context](https://help.github.com/en/actions/reference/context-and-expression-syntax-for-github-actions#job-context). |
| `steps`      | `object` | Information about the steps that have been run in this job. For more information, see [`steps` context](https://help.github.com/en/actions/reference/context-and-expression-syntax-for-github-actions#steps-context). |
| `runner`     | `object` | Information about the runner that is running the current job. For more information, see [`runner` context](https://help.github.com/en/actions/reference/context-and-expression-syntax-for-github-actions#runner-context). |
| `secrets`    | `object` | Enables access to secrets set in a repository. For more information about secrets, see "[Creating and using encrypted secrets](https://help.github.com/en/actions/automating-your-workflow-with-github-actions/creating-and-using-encrypted-secrets)." |
| `strategy`   | `object` | Enables access to the configured strategy parameters and information about the current job. Strategy parameters include `fail-fast`, `job-index`, `job-total`, and `max-parallel`. |
| `matrix`     | `object` | Enables access to the matrix parameters you configured for the current job. For example, if you configure a matrix build with the `os` and `node` versions, the `matrix` context object includes the `os` and `node` versions of the current job. |

[环境变量](https://help.github.com/en/actions/configuring-and-managing-workflows/using-environment-variables)如下：

| Environment variable | Description                                                  |
| -------------------- | ------------------------------------------------------------ |
| `HOME`               | The path to the GitHub home directory used to store user data. For example, `/github/home`. |
| `GITHUB_WORKFLOW`    | The name of the workflow.                                    |
| `GITHUB_RUN_ID`      | A unique number for each run within a repository. This number does not change if you re-run the workflow run. |
|                      |                                                              |
| `GITHUB_RUN_NUMBER`  | A unique number for each run of a particular workflow in a repository. This number begins at 1 for the workflow's first run, and increments with each new run. This number does not change if you re-run the workflow run. |
|                      |                                                              |
| `GITHUB_ACTION`      | The unique identifier (`id`) of the action.                  |
| `GITHUB_ACTIONS`     | Always set to `true` when GitHub Actions is running the workflow. You can use this variable to differentiate when tests are being run locally or by GitHub Actions. |
| `GITHUB_ACTOR`       | The name of the person or app that initiated the workflow. For example, `octocat`. |
| `GITHUB_REPOSITORY`  | The owner and repository name. For example, `octocat/Hello-World`. |
| `GITHUB_EVENT_NAME`  | The name of the webhook event that triggered the workflow.   |
| `GITHUB_EVENT_PATH`  | The path of the file with the complete webhook event payload. For example, `/github/workflow/event.json`. |
| `GITHUB_WORKSPACE`   | The GitHub workspace directory path. The workspace directory contains a subdirectory with a copy of your repository if your workflow uses the [actions/checkout](https://github.com/actions/checkout) action. If you don't use the `actions/checkout` action, the directory will be empty. For example, `/home/runner/work/my-repo-name/my-repo-name`. |
| `GITHUB_SHA`         | The commit SHA that triggered the workflow. For example, `ffac537e6cbbf934b08745a378932722df287a53`. |
| `GITHUB_REF`         | The branch or tag ref that triggered the workflow. For example, `refs/heads/feature-branch-1`. If neither a branch or tag is available for the event type, the variable will not exist. |
| `GITHUB_HEAD_REF`    | Only set for forked repositories. The branch of the head repository. |
| `GITHUB_BASE_REF`    | Only set for forked repositories. The branch of the base repository. |

# 总结

自从Github抱上了巨硬这条大腿以后，疯狂向开发者抛出大利好。毕竟背后有巨硬财大气粗，而且巨硬靠着企业业务赚钱也不指着向开发者个人收费。

结合Github Actions和Github Packages，可以完成一整个CI闭环，比如代码Push到Github上的某个分支，触发Action，构建Docker镜像push到Packages，调用Webhook触发阿里云服务器pull image部署。对于个人写一些小的开源项目完美够用，节约了在阿里云服务器搭建Jenkins等CI服务的资源。真香~~~

考虑到Github Actions提供的虚拟主机性能不错(比我买的阿里云主机好多了...)有公网IP可以访问外网，其实还可以玩点别的花活，比如抢火车票？爬网页？刷评论？发动你的脑瓜壳吧~
