---
layout: post
title: 'Hugo 写文章到发布的完整操作手册'
date: '2026-07-20T03:40:00+08:00'
author: 'axun'
description: '从 hugo new 到 git push，一步步把文章发到 chugo.synbe.com'
tags:
  - Hugo
  - 部署
  - 工作流
categories:
  - 技术
draft: false
---

用 Hugo 写文章、发上线，核心就四步：

```bash
hugo new content post/文章名.md   # 1. 新建文件
# 编辑器打开文件，写 front matter + 正文
./git2github.sh                    # 2. 提交 + 推送
# 等 Cloudflare Pages 自动构建，几十秒后线上可见
```

下面把每一步、每个细节展开，照着做不会错。

## 1. 新建文章

```bash
hugo new content post/我的新文章.md
```

- 目录必须是 `content/post/`（单数），否则 cleanwhite 主题首页不显示
- 文件名用 kebab-case（全小写、短横线连词），URL 里会直接用这个名字
- 命令会按 `archetypes/default.md` 生成骨架，但 cleanwhite 需要 `layout: post`，archetypes 里没加，所以**必须手动补上**

## 2. 编辑 front matter（必填项）

打开刚生成的文件，按下面模板填：

```yaml
---
layout: post
title: '文章标题'
date: '2026-07-20T10:30:00+08:00'
author: 'axun'
description: '首页和 SEO 摘要，1-2 句话概括全文'
tags:
  - 标签1
  - 标签2
categories:
  - 分类名
draft: false
---
```

**关键字段说明**：

| 字段 | 必填 | 说明 |
|------|------|------|
| `layout: post` | ✅ | cleanwhite 必须，缺了首页不显示 |
| `title` | ✅ | 文章标题，首页、文章页、RSS 都用 |
| `date` | ✅ | ISO 8601 带时区，决定排序与永久链接 |
| `author` | ✅ | 对应侧边栏作者名 |
| `description` | ✅ | 首页卡片摘要、SEO meta description |
| `tags` | 可选 | 标签页聚合用，建议 2-5 个 |
| `categories` | 可选 | 分类页聚合用，建议 1 个 |
| `subtitle` | 可选 | 标题下方小标题 |
| `featured_image` | 可选 | 文章顶部大图，放 `static/img/...` 路径 |
| `draft: false` | ✅ | `true` 只在 `hugo server -D` 预览，不发布 |

> **注意**：日期用 `T` 分隔日期时间，时区写 `+08:00`（东八区）。不要用空格。

## 3. 写正文

front matter 后空一行，直接写 Markdown。cleanwhite 支持标准语法 + 扩展：

- 标题：`## 二级标题` `### 三级标题`
- 代码块：```` ```go ```` 指定语言高亮
- 图片：`![alt](/img/xxx.jpg)` —— 图片放 `static/img/`
- 数学公式：行内 `\(...\)`、块级 `$$...$$`（需 `unsafe = true` 已在配置里开启）
- 目录：文章自动生成右侧目录，基于 `h2/h3`

**图片路径规则**：
- 源文件放 `static/img/xxx.jpg`
- Markdown 里写 `![alt](/img/xxx.jpg)`（以 `/img/` 开头）
- 构建后自动复制到 `public/img/`

## 4. 本地预览（可选但推荐）

```bash
hugo server -D
# 输出：Web Server is available at http://localhost:1313/
```

- `-D` 会渲染 `draft: true` 的文章
- 浏览器打开 `http://localhost:1313/` 检查：
  - 首页卡片有无标题、摘要、日期、标签
  - 点进文章，排版、代码高亮、图片、目录是否正常
  - 侧边栏：作者简介、标签云、最新文章
  - 导航栏：All Posts、分类、Archive、About、搜索

有问题回去改 front matter 或 Markdown，保存即热重载。

## 5. 一键发布

确认无误后：

```bash
./git2github.sh
```

脚本会做三件事：
1. `git checkout main` 确保在主分支
2. `git add --all` + `git commit -m "提交时间:..."`（无改动则跳过）
3. `git push origin main` 推送到 GitHub

**前置条件**：
- 必须在 `main` 分支（脚本会检查并拦截）
- 已配置 SSH Key 推送到 `git@github.com:synbe/chugo.git`

跑完看到 `----- 完毕 -----` 即可。

## 6. 等待自动部署

推送后，Cloudflare Pages 自动触发构建：
- Build command: `hugo --gc --minify`
- 通常 30-60 秒完成
- 部署成功后，访问 `https://chugo.synbe.com/` 刷新即见新文

**查看构建状态**：
- GitHub 仓库 → Actions 标签
- Cloudflare Dashboard → Workers & Pages → chugo → Deployments

若 Actions 显示失败但线上已更新，**以线上为准**（Cloudflare 用固定 Hugo 0.163.3，GitHub Actions 可能因缓存/版本失败）。

## 6. 常见问题排查

| 现象 | 原因 | 解决 |
|------|------|------|
| 首页不显示新文 | 缺 `layout: post` 或目录不对 | 检查 front matter、目录是 `content/post/` |
| 文章页 404 | 文件名大小写、目录层级 | URL 区分大小写，目录必须 `content/post/` |
| 图片不显示 | 路径写错、未放 `static/img/` | 图片放 `static/img/`，Markdown 用 `/img/...` |
| 代码不高亮 | 语言标识写错 | 用标准标识如 `go` `python` `bash` `json` |
| 推送被拒 | 不在 main 分支 | 先 `git checkout main` 再跑脚本 |
| 摘要不显示 | 缺 `description` | front matter 必填 `description` |

## 7. 进阶技巧

**指定永久链接**（不想用文件名做 URL）：
```yaml
url: "/post/自定义路径/"
```

**置顶文章**：
```yaml
weight: 100  # 越大越靠前
```

**系列文章**：
```yaml
series: "系列名"
series_weight: 1
```

**自定义 CSS/JS**（单篇）：
```yaml
custom_css: ["/css/xxx.css"]
custom_js: ["/js/xxx.js"]
```

## 8. 一张表速查

| 操作 | 命令 |
|------|------|
| 新建草稿 | `hugo new content post/xxx.md` |
| 本地预览（含草稿） | `hugo server -D` |
| 生产构建 | `hugo --gc --minify` |
| 一键发布 | `./git2github.sh` |
| 查看本地草稿列表 | `hugo list drafts` |
| 清理构建产物 | `rm -rf public resources/_gen` |

---

**核心口诀**：`layout: post` 不能漏、`content/post/` 单数、图片进 `static/img/`、`./git2github.sh` 一把梭。

照着这手册走，下一篇文章十分钟上线。