# VERIFY-004 · 分发链端到端（全新实例 → packwiz-installer 装包 → 服务端到 Done）

```
状态：通过
验证者：DSH 会话
验证日期：2026-10-20
关联：VERIFY-002（包换成我们的 jar）、VERIFY-003（.mrpack）、k00 §10.1（冒烟方法）
```

---

## 1. 结论

**整合包作为"被分发物"是可用的**：在一个**全新实例目录**（只有 NeoForge 服务端 libraries 与 eula/properties，没有任何 mod）里，用 `packwiz-installer-bootstrap.jar` 从本地 HTTP 拉 `pack/pack.toml`，安装器 **exit 0**、装出 **44 个 mod**（其中 4 个是我们的 `plaa-*` jar，来自 `overrides` 随包分发），随后服务端从零生成世界并到 `Done (13.977s)`。

这是本轮最关键的证据：此前只证明"我们手工摆好的实例能跑"，现在证明"**别人按包安装出来的实例能跑**"。

---

## 2. 步骤与证据

| 步 | 动作 | 结果 |
| --- | --- | --- |
| 1 | `python3 -m http.server 8086 --bind 127.0.0.1` 在 `pack/` 起本地 HTTP | `pack.toml HTTP 200` |
| 2 | `.cache/test-pack-fresh/` = 全新目录，只拷 `libraries/`、`user_jvm_args.txt`、`eula.txt`、`server.properties`（**无 mods**） | — |
| 3 | `java -jar packwiz-installer-bootstrap.jar -g -s server http://127.0.0.1:8086/pack.toml` | **exit 0**；装出 **44** 个 jar |
| 4 | 检查随包条目 | `mods/plaa-core…jar`、`plaa-create…`、`plaa-modulargolems…`、`plaa-vanilla…` 均在 |
| 5 | 启动服务端（NeoForge 21.1.264，新世界 `installed`） | `Preparing level "installed"` → **`Done (13.977s)!`** |

日志：
- 安装：`.cache/logs/pack-installer-smoke.log`
- 服务端：`.cache/logs/pack-installer-smoke.log.server`
- HTTP：`.cache/logs/pack-http.log`

---

## 3. 为什么这就说明"包是自洽的"

| 可能出问题的地方 | 本次是否被覆盖 |
| --- | --- |
| `pack.toml` / `index.toml` 哈希不一致（改包后忘记 refresh） | ✅ 安装器会先校验，不一致即失败；本次通过 |
| `.pw.toml` 指向的下载 URL 失效 | ✅ 43 个 Modrinth 直链全部下载成功 |
| 随包 jar 缺失或与索引哈希不符 | ✅ 4 个 `plaa-*` 由 `overrides` 落地，服务端正常加载 |
| 侧别（client/server）错配导致服务端缺前置 | ✅ `-s server` 装出来的 44 个 mod 能过 mod 加载 |
| 我们改名后的 modid 与包内其它 mod 冲突 | ✅ 无 `incompatible` 报错（与上游互斥已由 T5 单独证明） |

---

## 4. 未验证 / 遗留

| # | 项 | 何时补 |
| --- | --- | --- |
| 1 | **客户端侧**（图形界面、渲染、按键、殖民书界面） | 人工装一次 Modrinth App / Prism 实例（无头环境做不了） |
| 2 | `.mrpack` 在启动器里的真实导入 | 同上 |
| 3 | 包里 `config/`、`kubejs/`、`quests/` 仍为空 | 内容阶段 |
| 4 | NeoForge 版本：包声明 21.1.264，构建用 21.1.233 | 统一版本时一并升级 |

---

## 5. 复现命令（要点）

```bash
# WSL 内
cd pack && python3 -m http.server 8086 --bind 127.0.0.1 &
mkdir -p /tmp/fresh && cd /tmp/fresh
# 只拷 NeoForge 运行时（libraries）与 eula/properties，不要 mods
java -jar .../packwiz-installer-bootstrap.jar -g -s server http://127.0.0.1:8086/pack.toml
java @user_jvm_args.txt @libraries/net/neoforged/neoforge/21.1.264/unix_args.txt nogui
# 期望：mods 44 个，日志出现 Done (...)
```
