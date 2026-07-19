#!/bin/bash
set -euo pipefail

echo "----- 准备提交本目录所有改动到 main -----"

# 防护：必须在 main 分支上运行，否则报错退出（避免误切分支丢失改动）
current_branch=$(git rev-parse --abbrev-ref HEAD)
if [ "$current_branch" != "main" ]; then
  echo "错误：当前在 '$current_branch' 分支，本脚本只提交 main。"
  echo "请先执行：git checkout main"
  exit 1
fi

# 拉取远程更新（仅快进，遇分歧直接报错，避免意外 merge）
git pull --ff-only origin main || { echo "pull 失败：本地与远程存在分歧，请手动解决后再运行"; exit 1; }

# 暂存所有改动
git add --all

# 无改动则跳过提交，不报错
if git diff --cached --quiet; then
  echo "无改动，跳过提交"
else
  today=$(date +%Y-%m-%d/%H:%M:%S)
  git commit -m "提交时间:$today"
fi

# 推送到 main（Cloudflare Pages 生产分支）
git push origin main

echo "----- 完毕 -----"
