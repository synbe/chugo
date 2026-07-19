# 部署说明（chugo.synbe.com）

本仓库是一个 Hugo 静态站点，主题 ananke，通过 **Cloudflare Pages** 从 GitHub 导入并自动构建发布。

## 技术栈

- 静态生成器：Hugo v0.163.3（extended）
- 主题：ananke（位于 `themes/ananke`，直接提交进仓库，非 submodule）
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

（本仓库 `main` 与 `master` 指向同一提交，推送两者皆可。）

## 注意事项

- `themes/ananke` 是纯文件，非 git submodule；主题升级需手动覆盖 `themes/ananke`
- `baseURL` 固定为 `https://chugo.synbe.com/`（hugo.toml 第 1 行）

## public/ 是什么、为什么忽略

`public/` 是 Hugo 的**构建输出目录**：你写的 Markdown + 主题模板经 `hugo` 编译后，
生成的纯静态 HTML/CSS/JS 全部落在 `public/`（含 `index.html`、`posts/*/index.html`、
`ananke/` 静态资源、`index.xml` RSS、`sitemap.xml`、`404.html` 等）。

用户访问网站时看到的，就是 `public/` 里的文件。

本仓库已用 Cloudflare Pages 部署，流程是：**Cloudflare 从 GitHub 拉源码，在云端自己跑
`hugo --gc --minify` 生成它自己的 `public/`，再发布**。因此本地 `public/` 不会被用到，
也不应入库——它是可由源码 100% 重新生成的产物。存进 git 只会带来冗余与潜在的产物/云端
不一致冲突，故已在 `.gitignore` 中忽略。

若要本地查看效果，跑 `hugo server`（直接预览）或 `hugo`（生成 public/）即可；
不需要时 `rm -rf public` 删掉也不影响任何流程，下次构建会自动再生。

## 目录结构速览

```
content/      你写的文章（.md）        ← 日常只动这里
themes/ananke 主题模板与资源（332 文件）← 一般不动
hugo.toml     站点配置                 ← baseURL / 菜单 / 作者
static/       静态资源（图片等）
archetypes/   文章模板（hugo new 用）
layouts/      自定义模板覆盖位（空，预留）
assets/       需 Hugo Pipe 处理的资源（空，预留）
data/ i18n/   数据与多语言（空，预留）
public/       构建产物（忽略，不入库）
resources/_gen/ 构建缓存（忽略，不入库）
```

`layouts/ assets/ data/ i18n/` 是 `hugo new site` 生成的空占位骨架，预留给将来自定义，
空着属正常，git 不跟踪空目录故不影响提交。

