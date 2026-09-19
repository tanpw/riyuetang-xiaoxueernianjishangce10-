#!/bin/bash
set -euo pipefail

LOCAL="/mnt/d/小学语文/二年级/上册/单元四/10日月潭"
REPO="git@github.com:tanpw/riyuetang-xiaoxueernianjishangce10-.git"
BRANCH="main"

cd "$LOCAL"

# 不存在.git则初始化仓库，绑定远端
if [ ! -d ".git" ]; then
    echo "🔧 本地未初始化git仓库，开始git init"
    git init -b "$BRANCH"
    git remote add origin "$REPO"
fi

# Git网络参数
git config http.postBuffer 40000000
git config http.lowSpeedLimit 1000
git config http.lowSpeedTime 120
git config core.compression 1
git config http.timeout 300

# 获取待新增/修改文件，从小到大排序
FILES=($(git ls-files --others --modified --exclude-standard | xargs ls -Sr 2>/dev/null))

BATCH=()
BATCH_SIZE=0
MAX_BYTES=$((38 * 1024 * 1024)) # 38MB安全上限

for f in "${FILES[@]}"; do
    if [ ! -f "$f" ];then continue; fi
    FSIZE=$(stat -c%s "$f")
    if [ $FSIZE -gt $MAX_BYTES ];then
        echo "⚠️ 文件 $f 大于38MB，跳过"
        continue
    fi
    if [ $((BATCH_SIZE + FSIZE)) -gt $MAX_BYTES ];then
        echo "👉 push批次：${#BATCH[@]} 文件，总字节 $BATCH_SIZE"
        git add "${BATCH[@]}"
        git commit -m "batch upload: ${#BATCH[@]} files"
        git push origin "$BRANCH"
        BATCH=()
        BATCH_SIZE=0
    fi
    BATCH+=("$f")
    BATCH_SIZE=$((BATCH_SIZE + FSIZE))
done

# 剩余文件提交
if [ ${#BATCH[@]} -gt 0 ];then
    echo "👉 push剩余：${#BATCH[@]} 文件，总字节 $BATCH_SIZE"
    git add "${BATCH[@]}"
    git commit -m "batch upload: ${#BATCH[@]} files"
    git push origin "$BRANCH"
fi

echo "✅ 全部上传完成"

