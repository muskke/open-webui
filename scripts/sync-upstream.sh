#!/bin/bash
# ================================================================
# 自动同步上游仓库更新脚本
# 此脚本用于同步原始 Open WebUI 仓库的更新到你的 fork 仓库
# ================================================================

set -e  # 遇到错误立即退出

echo "================================================================"
echo "🔄 开始同步 Open WebUI 上游仓库更新"
echo "================================================================"

# 保存当前分支
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "ℹ️ 当前分支: $CURRENT_BRANCH"

# 检查工作区是否干净
if [[ -n $(git status -s) ]]; then
    echo "⚠️ 警告: 工作区有未提交的更改"
    echo "请先提交或暂存您的更改"
    read -p "是否继续? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "🛑 同步操作已取消"
        exit 1
    fi
fi

# 检查远程仓库配置
if ! git remote | grep -q upstream; then
    echo "❓ 未找到 upstream 远程仓库，是否添加？"
    read -p "请输入原项目仓库URL (留空使用默认URL: https://github.com/open-webui/open-webui.git): " UPSTREAM_URL
    UPSTREAM_URL=${UPSTREAM_URL:-https://github.com/open-webui/open-webui.git}
    git remote add upstream $UPSTREAM_URL
    echo "✅ 已添加 upstream 远程仓库: $UPSTREAM_URL"
fi

# 同步main分支
echo "----------------------------------------------------------------"
echo "🔄 开始同步 main 分支..."
echo "----------------------------------------------------------------"
echo "ℹ️ 切换到 main 分支..."
git checkout main

echo "ℹ️ 获取上游更新..."
git fetch upstream

echo "ℹ️ 重置 main 分支到 upstream/main..."
git reset --hard upstream/main

echo "ℹ️ 强制推送更新到 origin/main..."
git push origin main --force
echo "✅ main 分支同步完成"

# 同步develop分支
echo "----------------------------------------------------------------"
echo "🔄 开始更新 develop 分支..."
echo "----------------------------------------------------------------"

# 检查develop分支是否存在
if ! git branch --list | grep -q "develop"; then
    echo "ℹ️ develop 分支不存在，正在创建..."
    git checkout -b develop
    git push -u origin develop
else
    echo "ℹ️ 切换到 develop 分支..."
    git checkout develop
fi

echo "ℹ️ 尝试合并 main 分支更新..."
if git merge main --no-edit; then
    echo "✅ 自动合并成功，推送更新到 origin/develop..."
    git push origin develop
else
    echo "⚠️ 合并冲突，请手动解决冲突后提交..."
    echo "💡 解决冲突后，请运行:"
    echo "    git add ."
    echo "    git commit -m \"merge: 解决与上游更新的冲突\""
    echo "    git push origin develop"
    exit 1
fi

# 返回到原始分支
echo "----------------------------------------------------------------"
echo "ℹ️ 切换回原始分支: $CURRENT_BRANCH"
git checkout $CURRENT_BRANCH

echo "================================================================"
echo "✅ 上游同步完成!"
echo "================================================================"
echo "📋 同步摘要:"
echo "  - main 分支已更新并与 upstream/main 同步"
echo "  - develop 分支已合并 main 分支的更新"
echo "  - 现在你可以继续在 develop 分支上开发新功能"
echo "================================================================" 