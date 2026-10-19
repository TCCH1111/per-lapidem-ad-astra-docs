#!/usr/bin/env bash
# WSL 内网络诊断：DNS、裸 IP、HTTP/HTTPS；输出写文件（wsl.exe 直出会丢字节）
OUT=/mnt/d/wsl/pla/.cache/logs/wsl-netcheck.txt
{
    echo "=== $(date -Is) netcheck (user=$(whoami)) ==="
    echo "--- /etc/resolv.conf ---"; cat /etc/resolv.conf
    echo "--- /etc/wsl.conf ---"; cat /etc/wsl.conf
    echo "--- ip route ---"; ip route 2>&1 | head -5
    echo "--- ping gateway/1.1.1.1 ---"; ping -c1 -W2 1.1.1.1 2>&1 | tail -2
    echo "--- raw IP http (1.1.1.1) ---"; curl -sS -o /dev/null -m 8 -w 'http_code=%{http_code}\n' http://1.1.1.1/ 2>&1
    echo "--- DNS via system resolver ---"; getent hosts archive.ubuntu.com 2>&1 || echo "getent failed"
    echo "--- DNS via 223.5.5.5 / 8.8.8.8 (dig may be absent; use nslookup if present) ---"
    for ns in 223.5.5.5 8.8.8.8; do printf '%s: ' "$ns"; (command -v nslookup >/dev/null && nslookup -timeout=3 archive.ubuntu.com "$ns" 2>&1 | tail -2 | tr '\n' ' ') || echo "(nslookup absent)"; echo; done
    echo "--- https nodejs.org by name ---"; curl -sS -o /dev/null -m 8 -w 'http_code=%{http_code}\n' https://nodejs.org/dist/index.json 2>&1
    echo "--- windows host ip (for proxy use) ---"; grep nameserver /etc/resolv.conf | awk '{print $2}'
    echo "--- env proxy ---"; env | grep -i proxy || echo "(none)"
} > "$OUT" 2>&1
