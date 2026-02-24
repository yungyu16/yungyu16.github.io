---
layout: post
title: 从IDE到Terminal：适合后端宝宝体质的Claude Code工作流
typora-root-url: ../
catalog: true
mermaid: true
tags:
  - AI
---

# 背景

事情是这样的，之前对AI编程一直是观望态度，但是部门最近在做AI辅助编程POC，有幸成为POC用户，用上了自己舍不得买的高级编程模型(感谢公司)，尽管我自认为是一个在代码上很挑剔的人，但是我试了下感觉居然还可以(Go和React)！

只能说还得是谷歌，调整重心略微发力，Gemini3表现确实很不错。

既然尝到甜头了，觉得自己是时候好好的琢磨琢磨、研究研究，沉淀一套自己的工作流、方法论，解放自己的生产力，顺应潮流努力成为AI时代的受益者，而不是被淘汰的人！

新的开发范式需要搭建新的开发环境和匹配自己开发习惯的工作流，这就像刚学编程那会，需要挑一个自己喜欢的IDE、熟悉IDE快捷键和优化IDE设置一样。过程中间肯定有阵痛，Java开发者们回忆一下多年之前从Eclipse转IDEA那会的阵痛吧，但是磨刀不误砍柴工，阵痛之后一定是生产力提升。

借本文分享下我摸索后的方案，供大家参考。

# 工具选型

目前AI辅助编程领域热火朝天，各种GUI工具、TUI工具如雨后春笋让人目不暇接，这对于花心的强迫症选手(比如我)来说选型很困难。

但是我觉得有两个基础认知可以帮助我们更好的做决定：

1. AI辅助编程工具由脑和手两部分组成。脑是外接的大模型API、手是各个产品调教的提示词和内部工作流。按我理解，【脑】决定了工具的上限，【手】决定了工具的下限。
   在这个场景里，大模型就像是汽车里的发动机，而且所有型号的汽车支持的【发动机】规格都是通用的、统一的、标准化的。有了这个基础，我们可以随便选一个趁手的工具，然后自行按场景选配【合适】的【发动机】。

   ![img](/img/2026-02-01-%E4%BB%8EIDE%E5%88%B0Terminal%EF%BC%9A%E9%80%82%E5%90%88%E5%90%8E%E7%AB%AF%E5%AE%9D%E5%AE%9D%E4%BD%93%E8%B4%A8%E7%9A%84Claude%20Code%E5%B7%A5%E4%BD%9C%E6%B5%81/20260223151932248.png)
2. AI辅助编程当前是一个【千帆竞发】的热门领域，而且单纯就【工具】来说，这个领域【没有技术壁垒】。A产品抛出的杀手级特性，不出半个月一定会有B产品跟进。毕竟现在软件迭代的速度借助AI提升了很多，A产品验证过的想法，B产品可以很快的跟进和实现。

> Claude Code CLI 的开发者 就使用 Claude Code CLI 迭代 Claude Code CLI ，有点绕口，大概就是【工具自举】的意思吧。

## Claude Code CLI

综上，其实没啥纠结的，我们照着这两点来选型就好：

1. 这个工具一定得便捷的支持模型插拔，就是我随时可以根据场景换一个更适合的、更便宜的、表现更好的大模型。而且这种插拔一定要简单。
2. 这个工具一定要有积极的维护者，不断的迭代、优化它的工作流、提示词。最好是一个商业化产品，因为商业化产品出于其商业目标，一定会投入资源积极进行迭代。

当前满足这两个条件的，我想也就是Claude Code CLI了：

1. Claude Code CLI是一个商业化产品，有专门的技术团队在不停的更新、迭代。
2. Claude Code CLI可以非常便捷的支持大模型插拔，我可以随时根据成本、效率、体验来切换合适的大模型。

因此，这个环节我选【Claude Code CLI】。

> 后文以CCC代指Claude Code CLI
{: .prompt-tip }

## 快速切换模型

我通过自定义Shell函数来实现便捷的模型切换，不同的场景、不同的任务使用不同的模型。

基本原理就是，CCC支持环境变量注入LLM配置信息，因此我只需要按场景注入【行内临时环境变量】即可。

![img](/img/2026-02-01-%E4%BB%8EIDE%E5%88%B0Terminal%EF%BC%9A%E9%80%82%E5%90%88%E5%90%8E%E7%AB%AF%E5%AE%9D%E5%AE%9D%E4%BD%93%E8%B4%A8%E7%9A%84Claude%20Code%E5%B7%A5%E4%BD%9C%E6%B5%81/20260223151932324.png)

> 详见：[Bash-行内环境变量](https://www.gnu.org/software/bash/manual/html_node/Environment.html)
>
> Bash是标准的Shell实现，其他Shell如Zsh都兼容其行为。

### Shell配置

![img](/img/2026-02-01-%E4%BB%8EIDE%E5%88%B0Terminal%EF%BC%9A%E9%80%82%E5%90%88%E5%90%8E%E7%AB%AF%E5%AE%9D%E5%AE%9D%E4%BD%93%E8%B4%A8%E7%9A%84Claude%20Code%E5%B7%A5%E4%BD%9C%E6%B5%81/20260223151932247.png)

我到处弄了一堆免费的、收费的模型用，然后给他们取了我记得住的别名：

![img](/img/2026-02-01-%E4%BB%8EIDE%E5%88%B0Terminal%EF%BC%9A%E9%80%82%E5%90%88%E5%90%8E%E7%AB%AF%E5%AE%9D%E5%AE%9D%E4%BD%93%E8%B4%A8%E7%9A%84Claude%20Code%E5%B7%A5%E4%BD%9C%E6%B5%81/20260223151932484.png)

### 使用效果

![img](/img/2026-02-01-%E4%BB%8EIDE%E5%88%B0Terminal%EF%BC%9A%E9%80%82%E5%90%88%E5%90%8E%E7%AB%AF%E5%AE%9D%E5%AE%9D%E4%BD%93%E8%B4%A8%E7%9A%84Claude%20Code%E5%B7%A5%E4%BD%9C%E6%B5%81/20260223151932430.png)

为了兼容，设置了一个claude别名：

![img](/img/2026-02-01-%E4%BB%8EIDE%E5%88%B0Terminal%EF%BC%9A%E9%80%82%E5%90%88%E5%90%8E%E7%AB%AF%E5%AE%9D%E5%AE%9D%E4%BD%93%E8%B4%A8%E7%9A%84Claude%20Code%E5%B7%A5%E4%BD%9C%E6%B5%81/20260223151932361.png)

这样输入claude时，默认使用智谱GLM模型。

### 脚本源码

Shell脚本大概这样，可以修改后配置到自己的`~/.zshrc`中。

如果不熟悉Shell，嫌麻烦也可以试试这个开源工具：[farion1231/cc-switch](https://github.com/farion1231/cc-switch)

```shell
# claude 默认
alias claude='zcc'

# Kimi
function kcc(){
    echo Kimi Claude Code...
    local model="kimi-k2.5"
    ANTHROPIC_BASE_URL="https://api.moonshot.cn/anthropic" \
    ANTHROPIC_AUTH_TOKEN="sk-xxxxxxxxx" \
    ANTHROPIC_SMALL_FAST_MODEL="$model" \
    ANTHROPIC_DEFAULT_OPUS_MODEL="$model" \
    ANTHROPIC_DEFAULT_SONNET_MODEL="$model" \
    ANTHROPIC_DEFAULT_HAIKU_MODEL="$model" \
    CLAUDE_CODE_SUBAGENT_MODEL="$model" \
    launch_claude_code $@
}
# 智谱GLM
function zcc(){
    echo GLM Claude Code...
    ANTHROPIC_BASE_URL="https://open.bigmodel.cn/api/anthropic" \
    ANTHROPIC_AUTH_TOKEN="sk-xxxxxxxxx" \
    launch_claude_code $@
}
# 七牛
function qcc(){
    echo QiNiu Claude Code...
    local model="minimax/minimax-m2.1"
    ANTHROPIC_BASE_URL="https://api.qnaigc.com" \
    ANTHROPIC_AUTH_TOKEN="sk-xxxxxxxxx" \
    ANTHROPIC_SMALL_FAST_MODEL="$model" \
    ANTHROPIC_DEFAULT_OPUS_MODEL="$model" \
    ANTHROPIC_DEFAULT_SONNET_MODEL="$model" \
    ANTHROPIC_DEFAULT_HAIKU_MODEL="$model" \
    CLAUDE_CODE_SUBAGENT_MODEL="$model" \
    launch_claude_code $@
}
function launch_claude_code(){
    CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1 \
#    clear
    command claude $@
}
```

# 开发环境

在当前的气氛下，我想我算是一个【古板】的开发者，我做不到【fire and forget】，或者说完全靠黑盒的自然语言对话来完成代码开发。

我还是只将AI当助手，还是想要白盒的掌控AI写的代码，还是希望最终交付的代码有我的风格、我的审美、我的品味。毕竟AI也只能帮我写代码，并不能帮我背锅。

尽管我选择了TUI工具Claude Code CLI，但是我还做不到全程只在终端操作，我还是习惯JetBrains特色的双栏diff。

因此，当前我开发流程的起点还是传统的IDE，比如我最喜欢的JetBrains。每天上班第一件事是接水，第二件事就是打开IDE。

所以我需要想办法来将GUI工具和TUI工具流畅的衔接起来，减少代码开发时的频繁切换产生的割裂感！

## 多屏协作

![img](/img/2026-02-01-%E4%BB%8EIDE%E5%88%B0Terminal%EF%BC%9A%E9%80%82%E5%90%88%E5%90%8E%E7%AB%AF%E5%AE%9D%E5%AE%9D%E4%BD%93%E8%B4%A8%E7%9A%84Claude%20Code%E5%B7%A5%E4%BD%9C%E6%B5%81/20260223151932431.png)

如上图，我有3个显示器，我的构想是这样的：

1. MacBook 内置显示器：常驻两个空间

   一个用来打开浏览器，还有VPN、网易云音乐、Finder等软件，用来承接各种临时的操作
   
   一个用来打开飞书，用来沟通、协作
   ![img](/img/2026-02-01-%E4%BB%8EIDE%E5%88%B0Terminal%EF%BC%9A%E9%80%82%E5%90%88%E5%90%8E%E7%AB%AF%E5%AE%9D%E5%AE%9D%E4%BD%93%E8%B4%A8%E7%9A%84Claude%20Code%E5%B7%A5%E4%BD%9C%E6%B5%81/20260223151932337.png)
2. 中间主屏：常驻两个空间
   
   一个用来打开浏览器，用来做各种【输出】
   
   一个用来打开IDE，专注于写代码、看代码，用标签页打开多个Project
   ![img](/img/2026-02-01-%E4%BB%8EIDE%E5%88%B0Terminal%EF%BC%9A%E9%80%82%E5%90%88%E5%90%8E%E7%AB%AF%E5%AE%9D%E5%AE%9D%E4%BD%93%E8%B4%A8%E7%9A%84Claude%20Code%E5%B7%A5%E4%BD%9C%E6%B5%81/20260223151932647.png)
3. 左边竖屏：常驻两个空间

   一个用来打开浏览器，用于看文档、查资料等各种【输入】
   
   一个用来打开TUI工具，进行辅助编程！
   ![img](/img/2026-02-01-%E4%BB%8EIDE%E5%88%B0Terminal%EF%BC%9A%E9%80%82%E5%90%88%E5%90%8E%E7%AB%AF%E5%AE%9D%E5%AE%9D%E4%BD%93%E8%B4%A8%E7%9A%84Claude%20Code%E5%B7%A5%E4%BD%9C%E6%B5%81/20260223151932298.png)

## GUI/TUI衔接

现在问题来了，我希望我的开发工作的【主轴】是IDE，流程的起点是IDE。

但是我的IDE在中间屏幕，终端在左边屏幕，它俩是独立软件，没法协作、自动跟随切换Project的工作目录。

我希望有个【自动化流程】，当我在IDE里切换项目的时候，CCC自动跟随切换！

### 衔接流程

我期待的流程是这样的：

1. 因为某个原因，我在IDE里打开了一个项目A
2. 准备写代码了，点击IDE里的某个【按钮】，左边屏幕自动【新建】一个项目A的CCC会话终端并激活到前台显示
3. 我跟左边的CCC对话，让他干活
4. 我在中间的IDE里评审、调试、诊断
5. 因为某些原因我又要在IDE打开一个别的项目B
6. 我再次点击那个【按钮】，左边屏幕自动【新建】一个项目B的CCC会话终端并激活到前台显示
7. 我在IDE里又切回了项目A，我又点击了那个【按钮】，左边屏幕自动【切换】到A的CCC会话终端并激活到前台显示

好的，想法已经有了，AI时代就怕你没有想法，有想法就一定有办法实现！

### 代码实现

1. macOS 上的原生软件，大部分支持AppleScript自动化，也就是说我们可以写脚本驱动软件的行为、模拟人机交互，比如打开软件、新建tab、点击按钮等
2. JetBrains IDE 支持集成外部命令，也就是说：可以在IDE里点击一个按钮，自动执行一个Shell脚本或者别的可执行文件。

产品需求清晰了，接下来开始让AI牛马干活！

一顿沟通和调试之后，我们有了一个【自动化】创建iTerm2新标签的可执行脚本！

![img](/img/2026-02-01-%E4%BB%8EIDE%E5%88%B0Terminal%EF%BC%9A%E9%80%82%E5%90%88%E5%90%8E%E7%AB%AF%E5%AE%9D%E5%AE%9D%E4%BD%93%E8%B4%A8%E7%9A%84Claude%20Code%E5%B7%A5%E4%BD%9C%E6%B5%81/20260223151932266.png)

这是给大模型的需求提示词，大家可以按需选用，做个性化的调整：

~~~markdown
## 📌 工具功能说明

请帮我创建一个 macOS 上的 iTerm2 自动化工具,主要功能包括:

### 核心需求
1. **智能窗口管理**:自动使用或创建 iTerm2 窗口
2. **项目标签管理**:为每个项目目录维护独立的标签页,支持标签复用
3. **三面板布局**:自动创建固定的三面板布局(上方一个全宽面板,下方两个并排面板)
4. **命令自动执行**:在每个面板中自动切换到项目目录并执行预定义的命令

### 使用场景
```bash
# 基本用法:在当前目录打开
./open-claude-in-iterm.sh

# 指定项目目录
./open-claude-in-iterm.sh /path/to/project
```

---

## 🎯 技术架构要求

### 技术栈
- **Shell 脚本** (open-claude-in-iterm.sh):参数处理、路径规范化、日志管理
- **AppleScript** (open-claude-in-iterm.applescript):iTerm2 自动化核心逻辑
- **依赖**:macOS、iTerm2、Bash

---

## 📋 详细功能规格

### 1. Shell 脚本 (open-claude-in-iterm.sh)

#### 参数处理
- **参数1**:项目目录(可选,默认当前目录)
- **自动处理**:相对路径转绝对路径

#### 面板命令配置
```bash
PAN1_CMD="claude"     # 上方面板命令
PAN2_CMD="claude"     # 左下面板命令
PAN3_CMD="claude"     # 右下面板命令
```

### 2. AppleScript (open-claude-in-iterm.applescript)

#### 主要流程

**步骤1:窗口管理**
- 检查 iTerm2 是否运行(未运行则自动启动)
- 使用当前激活的 iTerm2 窗口,如果没有则创建新窗口

**步骤2:标签管理(关键逻辑)**
- 在找到的窗口中,查找 `session.path` 变量等于项目目录的标签
- **复用逻辑**:如果找到现有标签 且 窗口不是新创建的 → 直接切换标签并返回
- **创建逻辑**:如果未找到标签 或 窗口是新创建的 → 创建新标签和布局

**步骤3:三面板布局创建**
```
布局示意图:
┌─────────────────────────┐
│   上方面板 (全宽)         │
│   执行: PAN1_CMD         │
├──────────────┬──────────┤
│  左下面板    │  右下面板 │
│  PAN2_CMD   │  PAN3_CMD │
└──────────────┴──────────┘
```

**分割顺序(重要)**:
1. 初始状态:一个全屏 session(上方面板)
2. 第一次分割:对上方 session 执行**水平分割**,创建下方面板
3. 第二次分割:对下方 session 执行**垂直分割**,创建右下面板

**步骤4:命令执行**
在每个面板中依次执行:
1. 切换到项目目录:`cd "/path/to/project"`
2. 清屏:`clear`
3. 等待 0.3 秒(确保目录切换完成)
4. 执行命令:`PAN_CMD`
5. 等待 0.5 秒(确保命令启动)

## ⚠️ 常见错误

- ❌ 符号链接未处理,导致找不到 AppleScript 文件
- ❌ 分割顺序错误,导致布局不正确
- ❌ 缺少 delay,导致命令执行失败或在错误目录执行
- ❌ 新窗口处理错误,导致多余空白标签
- ❌ 标签复用逻辑错误,导致同一项目创建多个标签
- ❌ 路径未引用,导致包含空格的路径失败
~~~

### IDE配置

#### 1. 创建外部工具

![img](/img/2026-02-01-%E4%BB%8EIDE%E5%88%B0Terminal%EF%BC%9A%E9%80%82%E5%90%88%E5%90%8E%E7%AB%AF%E5%AE%9D%E5%AE%9D%E4%BD%93%E8%B4%A8%E7%9A%84Claude%20Code%E5%B7%A5%E4%BD%9C%E6%B5%81/20260223151932562.png)

#### 2. 添加到工具栏

![img](/img/2026-02-01-%E4%BB%8EIDE%E5%88%B0Terminal%EF%BC%9A%E9%80%82%E5%90%88%E5%90%8E%E7%AB%AF%E5%AE%9D%E5%AE%9D%E4%BD%93%E8%B4%A8%E7%9A%84Claude%20Code%E5%B7%A5%E4%BD%9C%E6%B5%81/20260223151932605.png)

### 使用效果

点击工具栏按钮后，自动在全屏的iTerm2窗口新建或激活项目目录下的CCC会话，下图里就是3个项目。

![img](/img/2026-02-01-%E4%BB%8EIDE%E5%88%B0Terminal%EF%BC%9A%E9%80%82%E5%90%88%E5%90%8E%E7%AB%AF%E5%AE%9D%E5%AE%9D%E4%BD%93%E8%B4%A8%E7%9A%84Claude%20Code%E5%B7%A5%E4%BD%9C%E6%B5%81/20260223151932508.png)

# 多Agent协作

会的越多，让你干的就越多。

既然AI那么牛，一个CCC会话已经满足不了我膨胀的想法和需求了。

我希望我可以同时支配多个AI开发工程师，而我变成PM！

所以参考酒米的思路，我给每个项目的终端，自动化的划分了3个子窗口，每个子窗口都是一个CCC会话。效果大概这样：

![img](/img/2026-02-01-%E4%BB%8EIDE%E5%88%B0Terminal%EF%BC%9A%E9%80%82%E5%90%88%E5%90%8E%E7%AB%AF%E5%AE%9D%E5%AE%9D%E4%BD%93%E8%B4%A8%E7%9A%84Claude%20Code%E5%B7%A5%E4%BD%9C%E6%B5%81/20260223151932657.png)

## 主从架构

每个项目自动打开3个常驻的AI会话，我设想的工作流是这样的：

1. 【架构师】上面的大屏，用贵的模型！专门用来跟我聊需求、对方案、产出任务列表
2. 【开发者】下面的两个小屏呢，用领域特定的模型，专门用来落地大屏架构师产出的方案和任务。比如前端需求用前端效果好的模型，后端需求用后端效果好的模型。

知人善用才是好PM！

这个模式也很匹配现实中的组织架构和成本取舍，现实中每个需求一般也都是由一个架构师和多个中高级开发者来协作完成！

感谢热心市民无声雨，给我们小组共享了自己采购的纯血Claude模型，所以目前我用Claude模型来对方案，用GLM或者MiniMax来实施方案！

## 规范驱动开发(SDD)

主从智能体的协作很重要，我跟【架构师】聊了半天确定的方案和设计，需要有一个清晰的、对大模型友好的方案和任务文档作为【开发者】的输入。

这就很巧，刚好最近在流行SDD，规范驱动开发。大致就是模拟现实中的软件开发流程将开发生命周期拆分为3个阶段：

1. 【proposal】需求对齐、方案设计、**【任务细化】**
2. 【apply】开发任务实施
3. 【archive】功能验收、文档沉淀

围绕这个流程，开源社区设计和研发了一系列对大模型非常友好的工具和提示词(比如OpenSpec)，【阶段1】和【阶段2】中间通过格式设计良好的【设计文档和任务文档】来进行上下文交接。

也就是说，我可以在上述的3窗口环境中，按照SDD流程来：

1. 【proposal】跟【架构师】交互，对齐需求、设计和任务A
2. 【apply】让【开发者1】着手完成任务A
3. 【proposal】继续跟【架构师】交互，对齐需求、设计和任务B
4. 【apply】让【开发者2】着手完成任务B
5. 【proposal】继续跟【架构师】交互，对齐需求、设计和任务C
6. 【apply】让【开发者1】着手完成任务C
7. ........

![img](/img/2026-02-01-%E4%BB%8EIDE%E5%88%B0Terminal%EF%BC%9A%E9%80%82%E5%90%88%E5%90%8E%E7%AB%AF%E5%AE%9D%E5%AE%9D%E4%BD%93%E8%B4%A8%E7%9A%84Claude%20Code%E5%B7%A5%E4%BD%9C%E6%B5%81/20260223151932803.png)

# CCC拓展

CCC当然很厉害，但它本质上也就是一个朴素的ReAct模式智能体。

![img](/img/2026-02-01-%E4%BB%8EIDE%E5%88%B0Terminal%EF%BC%9A%E9%80%82%E5%90%88%E5%90%8E%E7%AB%AF%E5%AE%9D%E5%AE%9D%E4%BD%93%E8%B4%A8%E7%9A%84Claude%20Code%E5%B7%A5%E4%BD%9C%E6%B5%81/20260223151932752.png)

ReAct这么火，大家肯定也都耳熟能详了，我们也就不说太多。

当然CCC团队围绕编程这个课题做了很多细致的提示词调优和内置工作流设计，这个我们黑盒的用就好了，也没必要关注太多。

我们最需要关注的，是CCC提供给我们使用者的【拓展点】，那些允许我们个性化设置的东西。

## 1. 命令(command)

命令的本质就是 预定义的提示词模板。目的是为了省事，不用每次都重复的输入类似的提示词。

比如想让CCC帮我提交代码，每次我们可能都要交代一大堆字，比如：

```plaintext
请调用 git diff --cached 获取当前暂存区的代码变动。
忽略所有的 node_modules 或二进制文件。
基于变动内容，判断这是一个 feat (新功能), fix (修复) 还是 chore (杂务)。
生成一个不超过 50 字符的标题，并在正文详细列出影响的文件。
由我确认后执行 git commit。”
```

就像写代码的时候将重复代码提取为一个独立方法一样，我们可以把这些可以复用的提示词固定成一个【命令】，后续使用的时候，直接输入命令名字就好。

> 斜杠命令是一段提示词的快捷方式
{: .prompt-tip }

## 2. 技能(skill)

技能 和 命令 最大的差别就是：命令是用户主动提交的提示词，而技能是Agent自己决策后自动导入的提示词。

当然技能包里除了提示词，一般还会携带一些配套的工具、脚本、命令或者文档。

比如，我安装了一个【html转pdf的技能包】，这只能提示CCC可以使用这个技能，但是具体用不用、什么时候用、怎么用都是CCC自己规划、决策的。

## 3. 子代理(subAgent)

**subAgents** 是可以并行处理任务的独立 AI 代理，每个子代理拥有独立的上下文窗口，可以分配不同任务以提高效率。【主代理】的上下文窗口中包含有【子代理】的**【简短】描述信息**，可以基于这个描述信息规划、决策使用哪个 子代理。

```json
{
  "agents": {
    "code-reviewer": {
      "description": "专门负责代码审查的子代理",
      "model": "claude-opus-4-5",
      "instructions": "你是一个专业的代码审查专家,专注于检查代码质量、安全漏洞和性能问题。",
      "tools": ["read", "search", "git"],
      "permissions": {
        "allowWrite": false
      }
    },
    "test-writer": {
      "description": "专门负责编写测试的子代理",
      "model": "claude-sonnet-4-5",
      "instructions": "你是一个测试工程师,专注于编写全面的单元测试和集成测试。",
      "tools": ["read", "write", "bash"]
    },
    "doc-generator": {
      "description": "专门负责生成文档的子代理",
      "model": "claude-sonnet-4-5",
      "instructions": "你是一个技术文档专家,专注于生成清晰、准确的技术文档。",
      "tools": ["read", "write"]
    }
  }
}
```

![img](/img/2026-02-01-%E4%BB%8EIDE%E5%88%B0Terminal%EF%BC%9A%E9%80%82%E5%90%88%E5%90%8E%E7%AB%AF%E5%AE%9D%E5%AE%9D%E4%BD%93%E8%B4%A8%E7%9A%84Claude%20Code%E5%B7%A5%E4%BD%9C%E6%B5%81/20260223151932659.png)

独立上下文窗口的好处是：**避免上下文污染和占用**。

比如我要在代码里找一个接口的所有实现类，这个就很适合子代理来做。主代理只需要交代给 子代理 接口名，然后就等 子代理 返回 实现类列表。

这样在 主代理的 上下文窗口里，只会有 子代理 的 输入和输出（几个类文件路径），而 子代理在搜索过程中遍历文件、目录、读取文件内容产生的临时token，不会对 主代理 产生影响。

> 我感觉 SubAgent 和 Skill 差不太多。不过我不确认Skill是不是在独立的上下文中执行。
{: .prompt-tip }

## 4. MCP

MCP和技能一样，都是由CCC自主规划、决策使用的。差别有两个：

1. MCP工具的说明信息占用的上下文太多了！不管是否被使用，每次都需要一口气提交所有工具的完整元信息(使用说明+出入参Schema )供大模型规划、决策，占用大量上下文。
而【技能】选择了【渐进式披露】，先向大模型提供少量关键信息，只有在大模型选择了使用技能时，才告诉大模型更多关于技能的补充说明信息，让大模型进一步推理、决策。
2. MCP工具更多的偏向【远程RPC】，基于网络来实现原子化的远程能力调用。而【技能】更多的偏向【本地IPC】，具体能力更多通过【编排】本地脚本、本地命令来实现，有点像stdio模式下的MCP。

## 5. 钩子(hook)

**hook** 是在特定事件触发时自动执行的脚本,用于自定义工作流、拦截危险操作、自动格式化代码等。

就类似 Linux NetFilter，CCC在很多地方植入了流程执行的劫持点，将流程上下文交给用户开发的脚本或者命令。

![img](/img/2026-02-01-%E4%BB%8EIDE%E5%88%B0Terminal%EF%BC%9A%E9%80%82%E5%90%88%E5%90%8E%E7%AB%AF%E5%AE%9D%E5%AE%9D%E4%BD%93%E8%B4%A8%E7%9A%84Claude%20Code%E5%B7%A5%E4%BD%9C%E6%B5%81/20260223151932775.png)

## 6. 插件(plugin)

**plugin**就是上述各种拓展打包、分发、安装的一种格式。你可以把它想象成npm包、pip包、apk包等我们比较熟悉的概念。然后我们可以按流程和格式建设 插件市场，类似 pip-index、npm-index等。

我没有细看流程和格式，但是大概也就是一个特定文件布局的zip文件包，里面有插件描述信息和各类拓展，比如可以包含：

- 5 个 Skills
- 10 个斜杠命令
- 3 个 MCP 服务器配置
- 2 个 SubAgent 定义
- 若干 Hooks

# CCC技巧

## 1. 飞书MCP

飞书官方提供了MCP，我主要用它来读写飞书文档，蛮好用的，大家可以试试。

> [飞书 MCP 服务](https://open.feishu.cn/page/mcp/)
{: .prompt-tip }

比如我每周都要在固定目录下创建固定标题格式的【系统巡检文档】，所以我借助飞书MCP 整了个自定义command 帮我自动创建这些文档去除重复劳动，感觉真香！之前每次都要手动建3个文档、选目录、改名字！

![img](/img/2026-02-01-%E4%BB%8EIDE%E5%88%B0Terminal%EF%BC%9A%E9%80%82%E5%90%88%E5%90%8E%E7%AB%AF%E5%AE%9D%E5%AE%9D%E4%BD%93%E8%B4%A8%E7%9A%84Claude%20Code%E5%B7%A5%E4%BD%9C%E6%B5%81/20260223151932889.png)

## 2. @模糊搜索

![img](/img/2026-02-01-%E4%BB%8EIDE%E5%88%B0Terminal%EF%BC%9A%E9%80%82%E5%90%88%E5%90%8E%E7%AB%AF%E5%AE%9D%E5%AE%9D%E4%BD%93%E8%B4%A8%E7%9A%84Claude%20Code%E5%B7%A5%E4%BD%9C%E6%B5%81/20260223153639368.png)

有时候我们需要 精确的告诉CCC，哪个文件需要读或者改，其实不用从IDE里复制文件路径，直接在终端里模糊搜索就好了。

## 3. WebFetch

![img](/img/2026-02-01-%E4%BB%8EIDE%E5%88%B0Terminal%EF%BC%9A%E9%80%82%E5%90%88%E5%90%8E%E7%AB%AF%E5%AE%9D%E5%AE%9D%E4%BD%93%E8%B4%A8%E7%9A%84Claude%20Code%E5%B7%A5%E4%BD%9C%E6%B5%81/20260223152957202.png)

CCC默认集成了WebFetch命令，就是指定URL读取网页内容，这个理论上就是一个本地执行的curl命令，没有云端成本，不需要云端协作。但是有个问题：

1. CCC在访问地址之前，会先调用`anthropic.com`的一个风控接口，判断这个网络地址是否有安全风险
2. 政策原因，`anthropic.com`会拒绝所有来自中国大陆、香港的请求，风控接口返回404或者其他
3. 风控不通过，WebFetch失败

![img](/img/2026-02-01-%E4%BB%8EIDE%E5%88%B0Terminal%EF%BC%9A%E9%80%82%E5%90%88%E5%90%8E%E7%AB%AF%E5%AE%9D%E5%AE%9D%E4%BD%93%E8%B4%A8%E7%9A%84Claude%20Code%E5%B7%A5%E4%BD%9C%E6%B5%81/20260223151932892.png)

在`~/.claude/settings.json`中添加如下配置，禁用WebFetch工具前置的风控检查就好了。

```shell
{
  "skipWebFetchPreflight": true,
}
```

> 详见：<https://linux.do/t/topic/1148954>

## 4. WebSearch

WebSearch是需要云端协作的，需要有个搜索引擎服务提供能力。因为我们没有用官方的付费订阅，所以默认的WebSearch工具我们用不了，调用WebSearch工具得到的结果都是0。

办法是去找一个免费或者收费的MCP服务。

免费的我看大家都推荐Brave<[brave.com](https://brave.com/zh/search/api/guides/use-with-claude-desktop-with-mcp/)>，大家也可以找找别的。

收费的也有很多，我看智谱的套餐里限量提供了<[联网搜索 MCP - 智谱AI开放文档](https://docs.bigmodel.cn/cn/coding-plan/mcp/search-mcp-server)>。

也有很多按量付费的，大概几分钱一次，有需要的可以找找。

添加了MCP搜索工具后，建议禁用CCC自带的WebSearch工具，不然每次跟大模型交互时，工具信息还会带给大模型，产生额外的token开销和推理误判。

在`~/.claude/settings.json`中添加如下配置

```json
{
  "permissions": {
    "deny": [
      "WebSearch"
    ]
  }
}
```

## 5. iTerm2通知

终端上的任务需要我们输入的时候，可以配置下，让iTerm2发出声音和通知。这样我们就不会因为忘记确认操作而阻塞进度。

![img](/img/2026-02-01-%E4%BB%8EIDE%E5%88%B0Terminal%EF%BC%9A%E9%80%82%E5%90%88%E5%90%8E%E7%AB%AF%E5%AE%9D%E5%AE%9D%E4%BD%93%E8%B4%A8%E7%9A%84Claude%20Code%E5%B7%A5%E4%BD%9C%E6%B5%81/20260223151932956.png)

> 详见：[Optimize your terminal setup - Claude Code Docs](https://code.claude.com/docs/en/terminal-config#iterm-2-system-notifications)

## 6. 清空上下文

因为我们每个项目都复用一屏内的3个子窗口，一般不会重开。

为了避免上下文溢出或者之前对话对新任务产生干扰，当我们完成一个任务时，需要及时的执行`/clear`命令，清空上下文，从0开始新对话。 

如果任务没有完成，但是又不得不clear，那么可以维护一个自定义命令，在clear后提示大模型根据`git status`看到的文件变更快速找回上下文。

> 把 **git 状态** 当作 AI 的“短期记忆快照”， `/clear` 只清上下文，不清工作进度。

```markdown
# Context Catch-up

当前对话已被 `/clear`，请通过 git 状态恢复上下文。

使用方式：
1. 阅读 `git status`（必要时结合 `git diff`）
2. 仅基于文件变更推断正在进行的任务
3. 延续现有实现思路，不要假设额外背景
4. 在未收到明确指令前，先给出你对当前上下文的判断

目标：
- 快速找回任务状态
- 避免旧对话或错误假设干扰新任务
```

## 7. 注意力哨兵

在记忆文件里要求大模型扮演一个特别的角色，如果聊着聊着角色行为丢失了，说明大模型注意力失焦了，已经丢掉了你最开始的要求。这时候就该clear一下重开会话了。

![img](/img/2026-02-01-%E4%BB%8EIDE%E5%88%B0Terminal%EF%BC%9A%E9%80%82%E5%90%88%E5%90%8E%E7%AB%AF%E5%AE%9D%E5%AE%9D%E4%BD%93%E8%B4%A8%E7%9A%84Claude%20Code%E5%B7%A5%E4%BD%9C%E6%B5%81/20260223151932933.png)

## 8. 拓展市场

为了便于相关个性化拓展物料的分发、便于大家搜索、安装，市面上已经有了相关的分发平台和便捷安装命令了。

1. <https://skills.sh>

   ![img](/img/2026-02-01-%E4%BB%8EIDE%E5%88%B0Terminal%EF%BC%9A%E9%80%82%E5%90%88%E5%90%8E%E7%AB%AF%E5%AE%9D%E5%AE%9D%E4%BD%93%E8%B4%A8%E7%9A%84Claude%20Code%E5%B7%A5%E4%BD%9C%E6%B5%81/20260223151932982.png)

2. <https://www.aitmpl.com>

   ![img](/img/2026-02-01-%E4%BB%8EIDE%E5%88%B0Terminal%EF%BC%9A%E9%80%82%E5%90%88%E5%90%8E%E7%AB%AF%E5%AE%9D%E5%AE%9D%E4%BD%93%E8%B4%A8%E7%9A%84Claude%20Code%E5%B7%A5%E4%BD%9C%E6%B5%81/20260223151933005.png)

## 9. 状态行个性化

![img](/img/2026-02-01-%E4%BB%8EIDE%E5%88%B0Terminal%EF%BC%9A%E9%80%82%E5%90%88%E5%90%8E%E7%AB%AF%E5%AE%9D%E5%AE%9D%E4%BD%93%E8%B4%A8%E7%9A%84Claude%20Code%E5%B7%A5%E4%BD%9C%E6%B5%81/20260223151933064.png)

状态行显示在 Claude Code 会话界面底部，可以自定义显示的内容，比如git分支名、目录名、模型名等。

推荐使用github开源项目：claude-code-statusline-pro-aicodeditor，效果如下：

![img](/img/2026-02-01-%E4%BB%8EIDE%E5%88%B0Terminal%EF%BC%9A%E9%80%82%E5%90%88%E5%90%8E%E7%AB%AF%E5%AE%9D%E5%AE%9D%E4%BD%93%E8%B4%A8%E7%9A%84Claude%20Code%E5%B7%A5%E4%BD%9C%E6%B5%81/20260223151933028.png)

> 详见：<https://github.com/HorizonWing/claude-code-statusline-pro-aicodeditor>

# 总结

差生文具多，尽管我暂时还没有使用CCC产出啥说得上来的东西，但是确实花了很多时间琢磨怎么让它用起来更顺手。

一些不成熟的想法，希望可以给到大家启发。

# 参考

1. [我的 Claude Code 实战经验：深度使用每个功能](https://www.ginonotes.com/posts/how-i-use-every-claude-code-feature)
2. [Claude Code 完全指南:使用方式、技巧与最佳实践 - knqiufan - 博客园](https://www.cnblogs.com/knqiufan/p/19449849)
