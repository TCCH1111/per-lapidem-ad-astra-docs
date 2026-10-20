# VERIFY-001 · B-2（modid 改为 `plaa_*` + 与上游互斥声明）

```
状态：通过（T1–T6 全部有证据；3 条遗留，不影响 B-2 收尾）
验证者：DSH 会话（独立于实现者）
验证日期：2026-10-20
对应计划：docs/plans/PLAN-001-b2-modid-rename.md
工作树：WSL Ubuntu-24.04 · ~/pla/mod · 分支 feat/b2-modid · HEAD = 3ce4d88（改动未提交）
```

---

## 1. 结论

**B-2 通过**：四个子项目的 modid 已变为 `plaa_core` / `plaa_vanilla` / `plaa_create` / `plaa_modulargolems`，产物名与显示名同步更新，四个 `neoforge.mods.toml` 各自对上游四个 modid 声明了 `incompatible`（每份 4 条），`NOTICE.md` 已建立；**单元/i18n、游戏测试、服务端正向启动、与上游互斥的负向测试**全部符合 PLAN-001 的判据。

**未验证的 3 条**（不阻塞 B-2，但必须记进后续）：客户端世界选择界面的"缺少 mod"提示、旧存档（`level.dat` 内含 `folkways_*`）载入、`plaa_modulargolems` 未上专用服务器实测。

---

## 2. 环境与基线

| 项 | 值 |
| --- | --- |
| 构建环境 | WSL2 Ubuntu-24.04，JDK **21.0.12.1+1**（Ubuntu 24.04.4），NeoForge Gradle 构建 **21.1.233** |
| 服务端测试环境 | `.cache/test-server-b2/`，NeoForge **21.1.264** server（ADR-023 ②留待单独提交升级） |
| 基线 | 上游 `master` @ **`3ce4d88`**（tag `upstream-base-3ce4d88-20261019`） |
| 改动规模 | **20 文件，+199 / −56**（`git diff --stat`），新增 `NOTICE.md`、`tests/i18n/mods-toml.test.ts` |
| 关键实现点 | 每个 `mods/<name>/build.gradle:7-8` 的 `ext.modId`/`ext.modName`；`gradle/mod.gradle:7` 产物名 = `${modName}-neoforge-${minecraft_version}`；`gradle/mod.gradle:63` 把 `NOTICE.md` 重命名为 `NOTICE_plaa.md` 打入 jar |

---

## 3. 逐项证据

| 项 | 判据（PLAN-001） | 证据 | 结论 |
| --- | --- | --- | --- |
| **T1** 静态与单元 | `gradlew check` + `test:unit` + `test:i18n` 全绿 | `.cache/logs/b2-verify3.log`：`# pass 134 / # fail 0`，i18n `# pass 7 / # fail 0`，`=== exit: 0 at 2026-10-20T13:08:59 ===` | ✅ |
| **T2** 四份 toml 结构 | 每份 `modId` 走模板变量、`incompatible` 覆盖上游四 modid、显示名已改 | `mods/*/src/main/resources/META-INF/neoforge.mods.toml`：`modId = "${mod_id}"` + `displayName = "Per Lapidem ad Astra · …" # PLA: ADR-023 modid`；每份 **4 条** `incompatible`（`grep -c` = 4/4/4/4） | ✅ |
| **T3** 游戏测试 | 改名后 `runGameTestServer` 全过 | `.cache/logs/wsl-gametest-inner.log`：`[13:11:33] … All 651 required tests passed :)`，`gradle exit: 0` | ✅ |
| **T4** 正向启动 | 只装我们的 jar（+ Create/ldlib2 前置）+ **全新世界** → 出现 `Done (` | `.cache/logs/b2-t4.log`：`[16:37:20] Preparing level "t4world"` → `[16:37:25] Done (4.453s)! For help, type "help"`；`mods/` 只剩 `create`、`ldlib2`、`plaa-core`、`plaa-create`、`plaa-vanilla`（上游 jar 已移到 `.cache/b2-upstream/`） | ✅ |
| **T5** 负向互斥 | 加入上游 `folkways-core` 后：① 不到 `Done`；② 日志含 `Mod plaa_core is incompatible with folkways_core` | `.cache/test-server-b2/logs/latest.log`（2026-10-20 13:47）：`FATAL … Mod plaa_core is incompatible with folkways_core 0 or above`（另有 `plaa_vanilla`、`plaa_create` 同款），`Crash report saved to ./crash-reports/crash-2026-10-20_13.47.33-fml.txt`；`server.out` 同时含 `reason` 原文 | ✅ |
| **T6** 产物与署名 | 四个 jar 名正确、`NOTICE.md` 在库且在 jar 内 | `build/libs/`：`plaa-core-neoforge-1.21.1-0.1.0.jar`（3.4M）、`plaa-vanilla…`（1.6M）、`plaa-create…`（304K）、`plaa-modulargolems…`（32K）；`NOTICE.md` 头部写明上游作者、基线 commit、双方 MIT | ✅ |

---

## 4. 未验证 / 遗留（诚实清单）

| # | 项 | 为什么没验 | 何时补 |
| --- | --- | --- | --- |
| 1 | 客户端世界选择界面的"缺少 `folkways_*`"提示 | T4 是专用服务端，客户端行为测不到（PLAN-001 R1-08 已识别） | 首次客户端安装时人工看一眼 |
| 2 | 旧存档载入（`level.dat` 含上游 mod 列表） | T4 用的是全新世界 `t4world` | 迁移演练（WP-10）时用真实旧档 |
| 3 | `plaa_modulargolems` 未上服务器 | 它需要 Modular Golems 本体，服务端测试实例未装 | 整合包档位确定后补一次 |

---

## 5. 给下一步的输入

1. **可以提交并推送**：改动已在工作树里（20 文件 + 2 新文件），验证证据齐备；建议消息：`feat(b2): rename modids to plaa_* and declare incompatibility with upstream`。
2. **pack 仍是上游 jar**：`pack/mods/folkways-*.pw.toml` 指向 `IzakyL/folkways` nightly（`folkways-core-…-0.1.0.jar`）。B-2 合并后应把这些条目**替换为我们的 `plaa-*` 产物**（本地 jar 或 release 资产），这是"整合包真正属于我们"的分界线。
3. **NeoForge 版本差**：构建 21.1.233 / 服务端 21.1.264。ADR-023 ②已把这件留作单独提交（R-BLD-1），不要在 B-2 里混改。
