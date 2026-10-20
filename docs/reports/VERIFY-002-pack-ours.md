# VERIFY-002 · 整合包改用我们的 jar（`plaa_*` 替换上游 `folkways_*`）

```
状态：通过（包已自包含；完整包服务端冒烟 Done 9.142s）
验证者：DSH 会话
验证日期：2026-10-20
上游依据：ADR-023（四 modid）、ADR-025（基线 3ce4d88）、k00 §10.1（冒烟方法）
关联：docs/reports/VERIFY-001-b2.md（B-2 改名本身）、PLAN-001
```

---

## 1. 结论

整合包 `pack/` 不再依赖上游 nightly：**4 个 `folkways-*.pw.toml` 已删除，替换为我们的 4 个 `plaa-*-neoforge-1.21.1-0.1.0.jar`**（直接分发文件，`metafile = false`）；`index.toml` / `pack.toml` 已按 packwiz 规则重建并自校验通过；**完整包（44 个 mod）在只装我们的 jar 的情况下，服务端从零生成世界并到达 `Done`**。

---

## 2. 做了什么

| 步骤 | 内容 | 证据 |
| --- | --- | --- |
| 1 | 删除 `pack/mods/folkways-{core,vanilla,create,modulargolems}.pw.toml`（原指向 `IzakyL/folkways` nightly） | `pack/mods/` 已无 `folkways-*`；全目录 `grep 'IzakyL/folkways|folkways-'` = **0** 命中 |
| 2 | 放入我们的 4 个 jar：`plaa-core`（3.3 MB）、`plaa-vanilla`（1.5 MB）、`plaa-create`（0.3 MB）、`plaa-modulargolems`（0.03 MB） | `ls pack/mods/*.jar` |
| 3 | 重建索引：`tools/pack-refresh.ps1`（本机无 packwiz CLI 的等价实现，**先证明了与 packwiz 字节级等价**） | 替换前 `-Check` 输出：`OK：index.toml 与 pack.toml 一致（47 个文件，sha256=20e65f12…）`，与 packwiz 原产物完全一致 |
| 4 | 刷新后自校验 | `OK：index.toml 与 pack.toml 一致（47 个文件，sha256=42c56a09…）` |

**包结构**：47 个受管文件 = **43 个 `.pw.toml`**（Modrinth/直链来源）+ **4 个我们的 jar**（随包分发）。

---

## 3. 完整包冒烟（关键证据）

在 `.cache/test-server`（44 个 mod 的完整包实例）上：把上游 4 个 jar 移出，放入我们的 4 个 jar，**新世界 `packours`** 启动。

```
[16:44:39] [Server thread/INFO]  Preparing level "packours"
[16:44:47] [Server thread/INFO]  Done (9.142s)! For help, type "help"
```
日志：`.cache/logs/pack-ours-smoke.log`（判据 = 出现 `Done (`，耗时 52 秒含 JVM+mod 加载）。

**对照**：T4（6 mod 最小实例）`Done (4.453s)`；完整包 44 mod `Done (9.142s)`——增量合理，无 FATAL。

---

## 4. 为什么把 jar 放进 `pack/mods/` 而不是写成下载 URL

| 方案 | 现在能否做 | 取舍 |
| --- | --- | --- |
| **随包分发 jar（采用）** | ✅ 立即可用、离线可装、与 `packwiz serve` / mrpack overrides 都兼容 | 仓库 +5.2 MB；不适合多平台分发 |
| GitHub Release URL + sha256 | ⚠️ 需要先给 `TCCH1111/per-lapidem-ad-astra` 打 release（推送权限在本机 WSL 尚未验证） | 更干净，适合正式发版 |
| Maven（GitHub Packages 等） | ❌ 还没配 | 长期最规范 |

**下一步建议**：B-2 推送并打 `v0.1.0` release 后，把这 4 个 jar 换成 release URL（`metafile = true`），仓库里就不再存 jar。

---

## 5. 未验证 / 遗留

| # | 项 | 何时补 |
| --- | --- | --- |
| 1 | `.mrpack` 未重建（现有 `.cache/dist/*.mrpack` 仍是旧内容，0.0 MB 级） | 本机装好 packwiz CLI 或写等价打包器后 |
| 2 | 客户端未实测（只测了专用服务端） | 首次客户端安装 |
| 3 | `plaa-modulargolems` 需要 Modular Golems 本体——包里已有 `modular-golems.pw.toml`，但**服务端未验证该 mod 是否被加载** | 下次冒烟看 `Loading N mods` 明细 |
| 4 | pack 内 `config/`、`kubejs/`、`quests/` 仍为空（k02/k04 的内容没落地） | 内容阶段 |

---

## 6. 对"做一个殖民地整合包"的意义

这是分界线：**在此之前，装这个包得到的是上游 Folkways；从现在起，装到的是我们自己的 fork**（四个 `plaa_*`，与上游互斥、带 NOTICE 署名）。剩下的差距是**内容**（配置/任务书/脚本）与**分发形态**（release + mrpack），不是"能不能跑"。
