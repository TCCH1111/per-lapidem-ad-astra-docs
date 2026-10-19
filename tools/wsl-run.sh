#!/usr/bin/env bash
# Per Lapidem ad Astra — 从 Windows 侧调用 WSL 的统一入口。
#
# 为什么需要它（docs/workflow/06 §1.5）：
#   1. wsl.exe 会把 `--` 之后的参数重新拼成一行交给 Linux shell，内联脚本里的引号与位置参数会被打乱 → 只传简单参数；
#   2. wsl.exe 直出 stdout/stderr 时会丢字节 → 所有输出在 Linux 侧写入文件，再从 Windows 读；
#   3. D:\wsl\pla 是指向工作区的 NTFS junction，Linux 侧统一用 /mnt/d/wsl/pla 访问工作区。
#
# 用法（Windows 侧，Git Bash 需加 MSYS_NO_PATHCONV=1 防止 /mnt/... 被改写）：
#   wsl.exe -d Ubuntu-24.04 -u root -- bash /mnt/d/wsl/pla/tools/wsl-run.sh system tcch1111
#   wsl.exe --terminate Ubuntu-24.04
#   wsl.exe -d Ubuntu-24.04 -- bash /mnt/d/wsl/pla/tools/wsl-run.sh verify
#   wsl.exe -d Ubuntu-24.04 -- bash /mnt/d/wsl/pla/tools/wsl-run.sh clone
#   wsl.exe -d Ubuntu-24.04 -- bash /mnt/d/wsl/pla/tools/wsl-run.sh build
#   wsl.exe -d Ubuntu-24.04 -- bash /mnt/d/wsl/pla/tools/wsl-run.sh unit      # typecheck + test:unit + test:i18n
# 日志：<工作区>/.cache/logs/wsl-<phase>-inner.log
set -u
ROOT=/mnt/d/wsl/pla
phase="${1:?用法: wsl-run.sh <system|verify|clone|build|unit|gitcheck|gametest> [参数]}"
shift
LOG="$ROOT/.cache/logs/wsl-$phase-inner.log"
mkdir -p "$ROOT/.cache/logs"
{
    echo "=== $(date -Is) wsl-run $phase $* (user=$(whoami), host=$(hostname)) ==="
    case "$phase" in
        system)
            bash "$ROOT/tools/wsl-provision.sh" system "$@" ;;
        verify)
            echo "user=$(whoami) home=$HOME"
            /usr/bin/java -version 2>&1 | head -1
            /usr/local/bin/node -v
            /usr/local/bin/npm -v
            /usr/bin/git --version
            df -h / | tail -1
            echo "--- /etc/wsl.conf ---"; cat /etc/wsl.conf ;;
        clone)
            # 一次性迁移（2026-10-19 已完成，Windows 侧 mod/ 随后删除）：若需重建，直接从 GitHub 克隆
            if [ -d "$ROOT/mod/.git" ]; then
                bash "$ROOT/tools/wsl-provision.sh" clone "$ROOT/mod"
            else
                echo "Windows 侧 mod/ 已不存在；改为从 GitHub 克隆到 ~/pla/mod"
                mkdir -p "$HOME/pla" && git clone https://github.com/IzakyL/folkways.git "$HOME/pla/mod" \
                && git -C "$HOME/pla/mod" remote rename origin upstream \
                && git -C "$HOME/pla/mod" checkout -b main 67f28b0 \
                && git -C "$HOME/pla/mod" tag -a upstream-base-67f28b0-20261019 67f28b0 -m "Upstream baseline for the Per Lapidem ad Astra fork (see docs/design/12-fork-strategy.md section 4)"
            fi ;;
        build)
            # CONTRIBUTING.md 三步，全部在 WSL ext4 内执行
            cd "$HOME/pla/mod" \
            && echo "--- npm ci ---" && npm ci --no-audit --no-fund \
            && echo "--- npm run setup ---" && npm run setup \
            && echo "--- .blockwright/mods.json ---" && cat .blockwright/mods.json && echo \
            && echo "--- gradlew build ---" && ./gradlew build --no-daemon --console=plain --stacktrace \
            && echo "--- build/libs ---" && ls -l build/libs build/deps ;;
        gitcheck)
            # 删除 Windows 侧 mod/ 之前确认 WSL 仓库完整：对象完整、工作树干净、remote/标签齐
            cd "$HOME/pla/mod" && git fsck --no-dangling && echo "fsck OK" \
            && git status --short --branch | head -20 && git remote -v && git tag -n1 | head -5 \
            && git log --oneline -1 && git cat-file -t upstream-base-67f28b0-20261019 ;;
        unit)
            # 层 0 的三条 Node 检查（PLAN-001 T1/T6；w06 §2.2）：typecheck + 单测 + i18n
            cd "$HOME/pla/mod" \
            && echo "--- npm run typecheck ---" && npm run typecheck \
            && echo "--- npm run test:unit ---" && npm run test:unit \
            && echo "--- npm run test:i18n ---" && npm run test:i18n ;;
        gametest)
            # w06 B-6 / 层 1：根工程聚合 core+vanilla+create 的 @GameTest（modulargolems 被上游排除）
            cd "$HOME/pla/mod" \
            && ./gradlew runGameTestServer --no-daemon --console=plain --stacktrace \
            ; rc=$?; echo "gradle exit: $rc"; echo "--- run/gametest/logs ---"; ls -l run/gametest/logs 2>/dev/null; exit $rc ;;
        *)
            echo "未知阶段: $phase"; false ;;
    esac
    echo "=== exit: $? at $(date -Is) ==="
} > "$LOG" 2>&1
echo "log: $LOG"
