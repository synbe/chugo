# 部署说明（chugo.synbe.com）

本仓库是一个 Hugo 静态站点，主题 **hugo-theme-cleanwhite**，通过 **Cloudflare Pages** 从 GitHub 导入并自动构建发布。

## 技术栈

- 静态生成器：Hugo v0.163.3（extended）
- 主题：hugo-theme-cleanwhite（位于 `themes/hugo-theme-cleanwhite`，直接提交进仓库，非 submodule）
- 域名：`chugo.synbe.com`（托管于 Cloudflare）
- 代码仓库：`git@github.com:synbe/chugo.git`，生产分支 `main`

## 本地开发

```bash
hugo server -D          # 带草稿预览，默认 http://localhost:1313/
hugo --gc --minify      # 生产构建，产物输出到 public/
```

写新文章：

```bash
hugo new content posts/文章名.md
```

文章 front matter 参考 `content/posts/my-first-post.md`（含 author / description / tags / categories）。

## Cloudflare Pages 部署（首次）

1. Cloudflare 控制台 → **Workers & Pages** → **Create** → **Pages** → **Connect to Git**
2. 授权并选中仓库 `synbe/chugo`
3. 构建设置：
   - Project name：`chugo`（或自取）
   - Production branch：`main`
   - Framework preset：`Hugo`
   - Build command：`hugo --gc --minify`
   - Build output directory：`public`
   - Root directory：`/`
4. 环境变量（重要，确保版本与本地一致）：
   - `HUGO_VERSION` = `0.163.3`
5. **Save and Deploy**，等待构建完成，会得到 `*.pages.dev` 预览地址

## 绑定正式域名

1. 项目内 → **Custom domains** → **Set up a domain** → 填 `chugo.synbe.com`
2. 因域名本就托管在 Cloudflare，DNS 的 CNAME 记录会自动添加，无需手动操作
3. 等待证书签发（通常几分钟），访问 `https://chugo.synbe.com/` 即可

## 日常更新

push 到 `main` 分支即触发 Cloudflare 自动重新构建并发布：

```bash
git push origin main
```

## 注意事项

- `themes/hugo-theme-cleanwhite` 是纯文件，非 git submodule；主题升级需手动覆盖
- `baseURL` 固定为 `https://chugo.synbe.com/`（hugo.toml 第 1 行）
- 静态资源（图片、CSS、JS）放在 `static/` 目录下，会被自动复制到 `public/`

## public/ 是什么、为什么忽略

`public/` 是 Hugo 的**构建输出目录**：你写的 Markdown + 主题模板经 `hugo` 编译后，
生成的纯静态 HTML/CSS/JS 全部落在 `public/`（含 `index.html`、`posts/*/index.html`、
`css/`、`js/`、`img/`、`index.xml` RSS、`sitemap.xml`、`404.html` 等）。

用户访问网站时看到的，就是 `public/` 里的文件。

本仓库已用 Cloudflare Pages 部署，流程是：**Cloudflare 从 GitHub 拉源码，在云端自己跑
`hugo --gc --minify` 生成它自己的 `public/`，再发布**。因此本地 `public/` 不会被用到，
也不应入库——它是可由源码 100% 重新生成的产物。存进 git 只会带来冗余与潜在的产物/云端
不一致冲突，故已在 `.gitignore` 中忽略。

若要本地查看效果，跑 `hugo server`（直接预览）或 `hugo`（生成 public/）即可；
不需要时 `rm -rf public` 删掉也不影响任何流程，下次构建会自动再生。

## 目录结构速览

```
content/              你写的文章（.md）        ← 日常只动这里
themes/hugo-theme-cleanwhite  主题模板与资源          ← 一般不动
hugo.toml             站点配置                 ← baseURL / 菜单 / 作者 / params
static/               静态资源（图片、CSS、JS）
archetypes/           文章模板（hugo new 用）
layouts/              自定义模板覆盖位（空，预留）
assets/               需 Hugo Pipe 处理的资源（空，预留）
data/ i18n/           数据与多语言（空，预留）
public/               构建产物（忽略，不入库）
resources/_gen/       构建缓存（忽略，不入库）
```

`layouts/ assets/ data/ i18n/` 是 `hugo new site` 生成的空占位骨架，预留给将来自定义，
空着属正常，git 不跟踪空目录故不影响提交。

## 主题迁移记录（2026-07-19）：从 ananke 迁移到 hugo-theme-cleanwhite

### 迁移步骤
1. 从 GitHub clone 主题到 `themes/hugo-theme-cleanwhite/`
2. 清理主题自带的 `.git` 目录（避免嵌套仓库）
3. 复制 `exampleSite/static/*` 到站点 `static/`（图片、CSS、JS、字体等静态资源）
4. 修改 `hugo.toml`：
   - `theme = 'hugo-theme-cleanwhite'`
   - 按 `exampleSite/hugo.toml` 调整 `[params]`、`[params.social]`、`[[params.additional_menus]]` 等配置
   - 关闭不需要的功能：`algolia_search = false`、`reward = false`、`friends = false` 等
5. 文章 front matter 适配 cleanwhite：
   - 必须加 `layout: post`
   - 目录由 `content/posts/` 改为 `content/post/`（匹配主题 URL 结构 `/post/...`）
   - `description` 字段用于首页摘要，`subtitle` 可选
6. 重新构建验证，推送触发 Cloudflare Pages 自动部署

### 坑点与经验
- **主题必须放在 `themes/<name>/`**，不能放在任意目录（Hugo 查找主题只在 `themes/` 下）
- **cleanwhite 要求文章 `layout: post`**，否则首页不显示文章列表
- **URL 路径区分大小写**：主题用 `/post/...`，所以内容目录必须是 `content/post/`
- **静态资源需手动复制**：主题 `exampleSite/static/` 下的图片、CSS、JS、字体必须复制到站点 `static/`，否则构建成功但页面缺样式/图片
- **Cloudflare Pages 构建失败不代表站点挂了**：GitHub Actions 可能因 Hugo 版本/缓存失败，但 Cloudflare Pages 用本地 Hugo 0.163.3 部署成功，线上站点正常
- **主题自带 `.git` 一定要删**，否则会形成嵌套仓库，提交报错或被忽略

### 日后新增文章模板
```bash
hugo new content post/文章名.md
```
编辑 front matter 必须包含：
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

一键发布：`./git2github.sh`（需在 `main` 分支运行）