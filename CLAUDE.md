# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

这是一个基于 Jekyll 的个人博客网站，使用 chirpy 主题。博客托管在 GitHub Pages 上，通过 GitHub Actions 自动部署。

## 项目结构

- `_posts/` - 博客文章目录，文件命名格式为 `YYYY-MM-DD-标题.md`
- `_tabs/` - 网站导航标签页（关于、归档、标签等）
- `_config.yml` - Jekyll 配置文件
- `Makefile` - 项目构建和开发命令
- `newblog` - 创建新博客文章的脚本

## 开发命令

### 初始化环境
```bash
make init
```

### 本地预览
```bash
make local-preview
```

### 生产环境预览
```bash
make preview
```

### 清理缓存
```bash
make clean
```

## 博客文章格式

博客文章位于 `_posts/` 目录下，文件名格式为 `YYYY-MM-DD-标题.md`。文章头部包含 YAML front matter：

```yaml
---
layout: post
title: 文章标题
date: YYYY-MM-DD
typora-root-url: ../
catalog: true
tags:
  - 标签1
  - 标签2
---
```

## 创建新文章

使用 `newblog` 脚本创建新文章：
```bash
./newblog "文章标题"
```

这将在 `_posts/` 目录下创建一个带有正确日期和格式的新文章文件。

## 部署流程

项目通过 GitHub Actions 自动部署到 GitHub Pages。推送代码到 master 分支会触发部署流程。