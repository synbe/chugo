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
- `public/` 为构建产物，已在 `.gitignore` 中忽略，不入库
- `baseURL` 固定为 `https://chugo.synbe.com/`（hugo.toml 第 1 行）
- 菜单含「关于」页（`/about/`），对应内容文件 `content/about.md` 尚未创建，访问会 404
