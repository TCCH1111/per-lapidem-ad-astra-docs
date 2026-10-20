# VERIFY-003 · 可分发产物 `.mrpack` 生成与结构校验

```
状态：通过（结构化校验通过；未做真实客户端安装）
验证者：DSH 会话
验证日期：2026-10-20
关联：VERIFY-002（包换成我们的 jar）、k00 §10.1（冒烟方法）
产物：.cache/dist/PerLapidemAdAstra-0.1.0+mc1.21.1+neoforge21.1.264.mrpack（4.9 MB）
```

---

## 1. 结论

在**本机没有 packwiz CLI** 的前提下，用 [`tools/pack-mrpack.ps1`](../../tools/pack-mrpack.ps1) 从 `pack/` 直接生成符合 Modrinth 规范的 `.mrpack`，并通过结构校验：**47 个文件条目（43 个下载 + 4 个随包 jar）**、哈希齐全且长度合规、随包 jar 的 sha256 与源文件逐一相等、抽样 3 个下载 URL 可达。

---

## 2. 产物结构

| 项 | 值 |
| --- | --- |
| zip 条目 | 5（`modrinth.index.json` + `overrides/mods/*.jar` × 4） |
| `formatVersion` | 1 |
| `game` / `versionId` | `minecraft` / `0.1.0+mc1.21.1+neoforge21.1.264` |
| `dependencies` | `minecraft = 1.21.1`、`neoforge = 21.1.264` |
| `files[]` | **47**：43 条带 `downloads[url]`；4 条 `downloads = []`（内容在 `overrides/`） |
| 哈希合规 | sha1 40 位、sha256 64 位，逐条检查 **0 条不合规** |
| 随包 jar 一致性 | 4/4 的 sha256 与 `pack/mods/` 源文件**完全一致** |

`env` 侧的映射：`.pw.toml` 的 `side = both` → `client/server = required`；`side = client` → `server = unsupported`（反之亦然），由脚本按 side 生成。

---

## 3. 哈希是怎么来的（关键实现细节）

`packwiz` 的 `.pw.toml` 里存的是 **sha512**（43/43 条），而 mrpack 只接受 **sha1 / sha256**。因此脚本走的是：

1. `.pw.toml` 的 `[update.modrinth] version` → 调 `api.modrinth.com/v2/version/<id>` 取该文件的 `hashes.sha1` / `hashes.sha256`；
2. 结果缓存在 `.cache/mrpack-hashes.json`（下次构建不重复请求）；
3. 没有 Modrinth 信息的条目 → 下载一次现算（本次 0 条走这条路）。

随包 jar（我们的 4 个）直接对本地字节算 sha1/sha256。

---

## 4. 验证命令与输出（可复现）

```
$ pwsh -File tools/pack-mrpack.ps1
43 个下载条目 + 4 个随包 jar → .cache/dist/PerLapidemAdAstra-0.1.0+mc1.21.1+neoforge21.1.264.mrpack (4.9 MB)
```

结构断言（本次实跑）：

```
zip 条目数: 5      index.json: 47 files      哈希不合规: 0
随包: plaa-core / plaa-create / plaa-modulargolems / plaa-vanilla（sha256 均一致）
HEAD 抽样 3 条 URL：waystones / moonlight / mcw-roofs 全部 OK
```

---

## 5. 未验证 / 遗留

| # | 项 | 影响 | 何时补 |
| --- | --- | --- | --- |
| 1 | **未做真实客户端安装**（Modrinth App / Prism） | 只证明了结构合规，没证明启动器接受 | 下次人工装一次 |
| 2 | `overrides/` 只放了 4 个 jar，**没有 config/kubejs/quests** | 包当前是"纯 mod 列表" | 内容阶段（k02/k04） |
| 3 | `neoforge = 21.1.264` 而构建用 21.1.233 | 已在 T4 证明服务端可跑，但客户端未测 | 升级提交时统一 |
| 4 | 未用 `packwiz-installer` 对**新装实例**做一次端到端 | 缺"分发链"证据 | 下一轮计划 |

---

## 6. 复现方式（给后来者）

```powershell
# 1) 改完 pack/ 后刷新索引（等价 packwiz refresh，已证明字节级一致）
pwsh -File tools/pack-refresh.ps1
# 2) 生成 .mrpack
pwsh -File tools/pack-mrpack.ps1
# 3) 校验（结构 + 哈希 + 抽样 URL）
#    见本文件 §4 的断言，或直接解压看 modrinth.index.json
```
