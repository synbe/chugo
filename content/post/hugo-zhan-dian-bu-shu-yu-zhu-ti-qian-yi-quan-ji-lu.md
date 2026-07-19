---
layout: post
title: 'Hugo 站点部署与主题迁移全记录：从 ananke 到 cleanwhite'
date: '2026-07-20T04:10:00+08:00'
author: 'axun'
description: 'chugo.synbe.com 部署流程、主题迁移踩坑、Cloudflare Pages 自动部署、日常写作发布全流程记录'
tags:
  - Hugo
  - 部署
  - Cloudflare Pages
  - 主题迁移
categories:
  - 技术
slug: hugo-zhan-dian-bu-shu-yu-zhu-ti-qian-yi-quan-ji-lu
draft: false
---

chugo.synbe.com 从零搭建、换主题、上线的完整记录。既是给自己留的档，也给后来者避坑。

## 技术栈一览

| 项目 | 选择 |
|------|------|
| 静态生成器 | Hugo v0.163.3 (extended) |
| 主题 | hugo-theme-cleanwhite（放在 `themes/hugo-theme-cleanwhite/`） |
| 部署平台 | Cloudflare Pages（连 GitHub 仓库自动构建） |
| 域名 | chugo.synbe.com（托管在 Cloudflare，自动配 DNS） |
| 代码仓库 | git@github.com:synbe/chugo.git，生产分支 `main` |

---

## 1. 本地开发环境

```bash
# 预览（含草稿）
hugo server -D

# 生产构建
hugo --gc --minify
```

写新文章：

```bash
hugo new content post/文章名.md
```

> **注意**：cleanwhite 主题要求目录为 `content/post/`（单数），且文章 front matter 必须有 `layout: post`。

---

## 2. Cloudflare Pages 首次部署

1. Cloudflare 控制台 → Workers & Pages → Create → Pages → Connect to Git
2. 选仓库 `synbe/chugo`
3. 构建配置：
   - Project name: `chugo`
   - Production branch: `main`
   - Framework preset: `Hugo`
   - Build command: `hugo --gc --minify`
   - Build output directory: `public`
   - Root directory: `/`
4. 环境变量（关键）：
   - `HUGO_VERSION` = `0.163.3`（与本地一致，避免版本差异导致构建失败）
5. Save and Deploy，等待 `*.pages.dev` 预览地址生成

---

## 3. 绑定正式域名

1. 项目 → Custom domains → Set up a domain → 填 `chugo.synbe.com`
2. 域名本就托管在 Cloudflare，CNAME 记录自动添加，无需手动操作
3. 等证书签发（通常几分钟），访问 `https://chugo.synbe.com/`

---

## 4. 日常更新流程

写完文章 → `./git2github.sh` 一键提交推送 → Cloudflare 自动构建部署。

脚本 `git2github.sh` 内容：

```bash
#!/bin/bash
set -euo pipefail
echo "----- 准备提交本目录所有改动到 main -----"
current_branch=$(git rev-parse --abbrev-ref HEAD)
if [ "$current_branch" != "main" ]; then
  echo "错误：当前在 '$current_branch' 分支，本脚本只提交 main。"
  echo "请先执行：git checkout main"
  exit 1
fi
git pull --ff-only origin main || { echo "pull 失败：本地与远程存在分歧，请手动解决"; exit 1; }
git add --all
if git diff --cached --quiet; then
  echo "无改动，跳过提交"
else
  today=$(date +%Y-%m-%d/%H:%M:%S)
  git commit -m "提交时间:$today"
fi
git push origin main
echo "----- 完毕 -----"
```

> **关键点**：必须在 `main` 分支运行，脚本会拦截非 main 分支。

---

## 5. public/ 为什么不入库

`public/` 是 Hugo 的**构建输出目录**，包含编译后的纯静态 HTML/CSS/JS。

Cloudflare Pages 的流程是：**拉源码 → 云端跑 `hugo --gc --minify` 生成自己的 `public/` → 发布**。

所以本地的 `public/` 不会被用到，也不该入库——它是可由源码 100% 复现的产物。存进 git 只会带来冗余和潜在冲突，已在 `.gitignore` 忽略。

---

## 6. 目录结构速览

```
content/                      文章（.md）           ← 日常只动这里
themes/hugo-theme-cleanwhite/ 主题模板与资源         ← 一般不动
hugo.toml                     站点配置              ← baseURL / 菜单 / 作者 / params
static/                       静态资源（图片、CSS、JS）
archetypes/                   文章模板（hugo new 用）
layouts/                      自定义模板覆盖位（空，预留）
assets/                       需 Hugo Pipe 处理的资源（空，预留）
data/ i18n/                   数据与多语言（空，预留）
public/                       构建产物（忽略，不入库）
resources/_gen/               构建缓存（忽略，不入库）
```

---

## 7. 主题迁移记录：ananke → cleanwhite

### 迁移步骤

1. `git clone https://github.com/zhaohuabing/hugo-theme-cleanwhite.git themes/hugo-theme-cleanwhite`
2. **删除主题自带 `.git`**（避免嵌套仓库）
3. 复制 `exampleSite/static/*` → 站点 `static/`（图片、CSS、JS、字体等）
4. 修改 `hugo.toml`：
   - `theme = 'hugo-theme-cleanwhite'`
   - 按 `exampleSite/hugo.toml` 调整 `[params]`、`[params.social]`、`[[params.additional_menus]]`
   - 关闭不需要的功能：`algolia_search = false`、`reward = false`、`friends = false` 等
5. 文章适配 cleanwhite：
   - 必须加 `layout: post`
   - 目录 `content/posts/` → `content/post/`（匹配 `/post/...` URL 结构）
   - `description` 用于首页摘要，`subtitle` 可选
6. 重新构建验证，推送触发自动部署

### 核心坑点

| 坑点 | 后果 | 解决 |
|------|------|------|
| 主题不在 `themes/<name>/` | Hugo 找不到主题 | 必须放标准目录 |
| 缺 `layout: post` | 首页不显示文章 | 所有文章必须加 |
| 目录名复数 `posts` | URL 生成 `/posts/...` 不匹配主题 | 改单数 `post` |
| 静态资源未复制 | 页面缺图/样式 | `exampleSite/static/*` → `static/` |
| 主题自带 `.git` 未删 | 嵌套仓库，提交异常 | `rm -rf themes/xxx/.git` |
| GitHub Actions 失败但线上正常 | 版本/缓存差异 | 以 Cloudflare Pages 部署为准 |

---

## 8. 新增文章模板

```bash
hugo new content post/文章名.md
```

编辑 front matter（必填）：

```yaml
---
layout: post
title: '文章标题'
date: 'YYYY-MM-DDTHH:MM:SS+08:00'
author: 'axun'
description: '首页显示的摘要'
tags:
  - 标签1
  - 标签2
categories:
  - 分类
draft: false
---
```

可选字段：`subtitle`、`featured_image`（放 `static/img/...`）、`slug`（自定义 URL）、`weight`（置顶权重）。

---

## 9. 一键发布

```bash
./git2github.sh
```

必须在 `main` 分支。脚本会：检查分支 → 拉取最新 → 暂存所有 → 提交（无改动跳过） → 推送 `origin main` → 触发 Cloudflare 自动部署。

---

## 10. 常见问题速查

| 现象 | 原因 | 解决 |
|------|------|------|
| 首页不显示新文 | 缺 `layout: post` 或目录不对 | 检查 front matter、目录是 `content/post/` |
| 文章页 404 | 文件名大小写、目录层级 | URL 区分大小写，目录必须 `content/post/` |
| 图片不显示 | 路径写错、未放 `static/img/` | 图片放 `static/img/`，Markdown 用 `/img/...` |
| 代码不高亮 | 语言标识写错 | 用标准标识如 `go` `python` `bash` `json` |
| 推送被拒 | 不在 main 分支 | 先 `git checkout main` 再跑脚本 |
| 摘要不显示 | 缺 `description` | front matter 必填 `description` |

---

写到这里，流程已跑通。**写文章 → 跑脚本 → 等几十秒 → 线上可见**。剩下的只是写内容了。