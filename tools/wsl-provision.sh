#!/usr/bin/env bash
# Per Lapidem ad Astra — WSL2 (Ubuntu 24.04) 开发环境配置脚本
#
# 依据：docs/workflow/06-build-and-ci.md §1.1（JDK 21、Node ≥ 22.14、Gradle wrapper）、§1.2（Blockwright 仅 Linux x64）、
#       docs/00-charter.md ADR-022（WSL2 Ubuntu-24.04 装 D:，fork 工作树放 WSL ext4 ~/pla/mod）。
#
# 用法（在 Windows 侧）：
#   wsl.exe -d Ubuntu-24.04 -u root bash /mnt/d/<工作区>/tools/wsl-provision.sh system [linux用户名]
#   wsl.exe --terminate Ubuntu-24.04            # 让 /etc/wsl.conf 的默认用户生效
#   wsl.exe -d Ubuntu-24.04 bash /mnt/d/<工作区>/tools/wsl-provision.sh clone /mnt/d/<工作区>/mod
# 之后构建在 ~/pla/mod 内按 CONTRIBUTING.md 三步：npm ci → npm run setup → ./gradlew build。
set -euo pipefail

phase="${1:-}"

system() {
    # 以 root 运行：建用户、免密 sudo、设默认用户、装 JDK 21 / Node 22 LTS / 基础工具。
    local user="${1:-tcch1111}"
    if ! id -u "$user" >/dev/null 2>&1; then
        adduser --disabled-password --gecos "" "$user"
    fi
    usermod -aG sudo "$user"
    printf '%s ALL=(ALL) NOPASSWD:ALL\n' "$user" > "/etc/sudoers.d/90-$user"
    chmod 440 "/etc/sudoers.d/90-$user"
    # 保留镜像自带的 /etc/wsl.conf（Ubuntu 24.04 默认含 [boot] systemd=true），只增改 [user] 段。
    if grep -q '^\[user\]' /etc/wsl.conf 2>/dev/null; then
        sed -i "/^\[user\]/,/^\[/{s/^default=.*/default=$user/}" /etc/wsl.conf
        grep -q "^default=$user" /etc/wsl.conf || sed -i "/^\[user\]/a default=$user" /etc/wsl.conf
    else
        printf '\n[user]\ndefault=%s\n' "$user" >> /etc/wsl.conf
    fi

    # WSL2 NAT 下宿主网关可能不应答 DNS（2026-10-19 实测：裸 IP 通、域名全部超时）→ 改为静态公共 DNS。
    if ! getent hosts archive.ubuntu.com >/dev/null 2>&1; then
        echo "WSL 生成的 resolv.conf 无法解析域名，改用静态 DNS 223.5.5.5 / 8.8.8.8"
        grep -q '^\[network\]' /etc/wsl.conf || printf '\n[network]\ngenerateResolvConf=false\n' >> /etc/wsl.conf
        rm -f /etc/resolv.conf
        printf 'nameserver 223.5.5.5\nnameserver 8.8.8.8\n' > /etc/resolv.conf
        getent hosts archive.ubuntu.com >/dev/null 2>&1 || { echo "静态 DNS 仍无法解析，检查宿主防火墙/VPN 对 UDP 53 的拦截" >&2; exit 1; }
        echo "DNS OK: $(getent hosts archive.ubuntu.com | head -1)"
    fi

    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y --no-install-recommends \
        openjdk-21-jdk-headless unzip zip curl git ca-certificates xz-utils python3

    # Node 22 LTS：从 nodejs.org 取最新 v22，按 SHASUMS256.txt 校验后装到 /usr/local（不用 curl | bash）。
    local ver
    ver="$(curl -fsSL https://nodejs.org/dist/index.json | python3 -c '
import json, sys
for e in json.load(sys.stdin):
    if e["version"].startswith("v22.") and e.get("lts"):
        print(e["version"]); break')"
    [ -n "$ver" ] || { echo "无法从 nodejs.org 解析 v22 LTS 版本" >&2; exit 1; }
    local tmp; tmp="$(mktemp -d)"
    ( cd "$tmp" \
      && curl -fsSLO "https://nodejs.org/dist/$ver/node-$ver-linux-x64.tar.xz" \
      && curl -fsSLO "https://nodejs.org/dist/$ver/SHASUMS256.txt" \
      && grep " node-$ver-linux-x64.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
      && tar -xJf "node-$ver-linux-x64.tar.xz" -C /usr/local --strip-components=1 --no-same-owner )
    rm -rf "$tmp"

    echo "== 版本 =="; java -version 2>&1 | head -1; node -v; npm -v; git --version
    echo "== 默认用户 ==: $user（执行 wsl.exe --terminate Ubuntu-24.04 后生效）"
}

clone() {
    # 以普通用户运行：从 Windows 侧已有的本地克隆复制到 WSL ext4（标签/分支照搬，无需联网），remote 改回 GitHub 并命名为 upstream。
    local src="${1:?用法: clone /mnt/d/<工作区>/mod}"
    local dst="$HOME/pla/mod"
    [ -e "$dst" ] && { echo "$dst 已存在，跳过克隆" >&2; return 0; }
    mkdir -p "$HOME/pla"
    git clone --no-hardlinks "$src" "$dst"
    git -C "$dst" remote rename origin upstream
    git -C "$dst" remote set-url upstream https://github.com/IzakyL/folkways.git
    git -C "$dst" fetch "$src" 'refs/tags/*:refs/tags/*' >/dev/null 2>&1 || true
    git -C "$dst" checkout -q main
    echo "== $dst =="; git -C "$dst" log --oneline -1; git -C "$dst" tag -n1 | sed 's/^/  /'; git -C "$dst" remote -v
}

case "$phase" in
    system) shift; system "$@" ;;
    clone)  shift; clone "$@" ;;
    *) echo "用法: $0 system [用户名] | clone <Windows侧mod克隆的 /mnt 路径>" >&2; exit 2 ;;
esac
