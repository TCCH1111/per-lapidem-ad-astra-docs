# PLAN-001 · B-2：把 fork 的四个 modid 改为 `plaa_*`（含 NOTICE 与冲突声明）

```
状态：计划中（待审查 agent 两轮 review → 人类确认 → 实现）
负责人：规划者（agent）
最后更新：2026-10-19
上游依据：docs/00-charter.md ADR-017 / ADR-023；docs/design/12-fork-strategy.md §4、§5、§7（R-FK-2/3/4/8）；docs/workflow/06-build-and-ci.md §1.3 B-2、§6.1；docs/research/10-upstream-delta-f42e3c1-67f28b0.md §2、§3
事实快照：reference/folkways-3ce4d88/（基线已按 ADR-025 前移；本计划全部 文件:行号 已于 2026-10-19 在该快照上逐行复核，与 67f28b0 一致——上游仅在 `FolkwaysMod.java:71` 新增 `registerConfig(ModConfig.Type.CLIENT, FolkwaysClientConfig.SPEC)`，不影响任何引用行）
```

> 这是 fork 的**第一处改上游文件**。目的只有一个：让我们的四个 jar 与上游 Folkways 在 modid 上可区分、不可共装，并履行 MIT 的署名义务。**不改任何玩法行为、不改任何包名/类名/资源命名空间。**

---

## 1. 任务单（照 w05 §3.2 九字段）

| 字段 | 内容 |
| --- | --- |
| 任务编号 | **M1-WP0-B2** |
| 一句话目标 | 四个子项目的 modid 变为 `plaa_core` / `plaa_vanilla` / `plaa_create` / `plaa_modulargolems`，产物名 `plaa-<name>-neoforge-1.21.1-*.jar`，四个 `mods.toml` 对上游四个 modid 声明 `incompatible`，根目录新增 `NOTICE.md`；构建、647 个游戏测试、最小实例启动全部照旧通过 |
| 图层 | **L2**（在上游既有文件里改少量行，带 `// PLA:` / `# PLA:` 标记）+ **L1**（新文件 `NOTICE.md`、新测试 `tests/mods-toml.test.ts`）。**无 L3/L4** |
| 允许触碰 | §3 列出的 16 个文件 + 2 个新文件；**不得**触碰 `mods/*/src/main/java/**` 中除四个主类常量行以外的任何代码 |
| 必读 | ADR-023；d12 §4/§5/§7；w06 §1.3 B-2、§6.1；r10 §2.2、§3 |
| 验收 AC | 本计划 §6 的 T1–T6（无对应 PRD AC，属 w05 WP-0 环境类任务） |
| 自测命令 | WSL：`tools/wsl-run.sh build`、`tools/wsl-run.sh gametest`；`npm run test:unit`、`npm run typecheck`、`npm run test:i18n` |
| 禁止事项 | 改 `FolkwaysMod.MOD_ID`（`"folkways"`，资源命名空间）；改 `gradle/mod.gradle` 的 `lib()`/`expanded` 逻辑（仅允许加 NOTICE 打包一行）；重命名包/类/目录（R-FK-2）；改 `enabledGameTestNamespaces`；顺手改任何玩法 |
| 交付物 | diff；`NOTICE.md`；`tests/mods-toml.test.ts`；d12 §5.1 改动登记表新增行（每个被改文件一行）；验证报告 `docs/reports/VERIFY-001-b2.md`（逐条 T1–T6 判定 + 证据） |
| 失败回退 | 任一 T 不过 → `git checkout upstream-base-67f28b0-20261019 -- <文件>` 回退该文件；若 T3 因 modid 变化失败（例如附件/配置按 modid 寻址），**停下上报**，不得改成保留 `folkways_*` 别名绕过 |

---

## 2. 涉及的模块与路径（含 `文件:行号`，基于 `reference/folkways-67f28b0/`）

### 2.1 构建坐标（Gradle）

| 文件:行 | 现值 | 改为 | 层 |
| --- | --- | --- | --- |
| `mods/core/build.gradle:7-8` | `ext.modId = "folkways_core"` / `ext.modName = "folkways-core"` | `plaa_core` / `plaa-core` | L2 |
| `mods/vanilla/build.gradle:7-8` | `folkways_vanilla` / `folkways-vanilla` | `plaa_vanilla` / `plaa-vanilla` | L2 |
| `mods/create/build.gradle:7-8` | `folkways_create` / `folkways-create` | `plaa_create` / `plaa-create` | L2 |
| `mods/modulargolems/build.gradle:7-8` | `folkways_modulargolems` / `folkways-modulargolems` | `plaa_modulargolems` / `plaa-modulargolems` | L2 |
| `build.gradle:8-11` | `modProjects` 映射键 `folkways_core: ":core"` … | 键改 `plaa_*`（值不变） | L2 |
| `settings.gradle:18` | `rootProject.name = "folkways"` | `"plaa"` ⚠️ 待人类确认（§7 OQ-P1-3） | L2 |
| `gradle.properties:3` | `maven_group=io.github.izakyl` | **待人类定**（§7 OQ-P1-1） | L2 |
| `gradle/mod.gradle:52-56` | jar 打入 `LICENSE` → `META-INF/LICENSE_folkways.txt` | 保留；**另加一行**把 `NOTICE.md` 打入 `META-INF/NOTICE_plaa.md` ⚠️ 取决于 w06 OQ-B-8（§7 OQ-P1-4） | L2 |

产物名由 `gradle/mod.gradle:6-8` 的 `archivesName = "${project.modName}-neoforge-${minecraft_version}"` 自动得到 `plaa-core-neoforge-1.21.1-0.1.0.jar` 等；`neoforge.mods.toml` 的 `${mod_id}` 由 `gradle/mod.gradle:62-73` 的 `expanded` 展开，无需另改。

### 2.2 Java 常量（每个子 mod 恰好一处字面量）

| 文件:行 | 现值 | 改为 |
| --- | --- | --- |
| `mods/core/src/main/java/io/github/izakyl/folkways/FolkwaysMod.java:63` | `CORE_ID = "folkways_core"` | `"plaa_core"`（`:57` 的 `@Mod(FolkwaysMod.CORE_ID)` 自动跟随；12 个 gametest 的 `@EventBusSubscriber(modid = FolkwaysMod.CORE_ID)` 自动跟随） |
| `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/FolkwaysVanillaMod.java:14` | `ID = "folkways_vanilla"` | `"plaa_vanilla"` |
| `mods/create/src/main/java/io/github/izakyl/folkways/create/FolkwaysCreateMod.java:13` | `ID = "folkways_create"` | `"plaa_create"` |
| `mods/modulargolems/src/main/java/io/github/izakyl/folkways/modulargolems/FolkwaysModularGolemsMod.java:9` | `ID = "folkways_modulargolems"` | `"plaa_modulargolems"` |

**不改**：`FolkwaysMod.java:60` `MOD_ID = "folkways"`（资源命名空间，`@GameTestHolder(FolkwaysMod.MOD_ID)`、数据包 `folkways/library`、全部 `folkways:` 注册名都挂在它上面，ADR-023 明令不动）。

### 2.3 `neoforge.mods.toml`（四份）

| 文件:行 | 改动 |
| --- | --- |
| `mods/vanilla/src/main/resources/META-INF/neoforge.mods.toml:29` | 依赖 `modId = "folkways_core"` → `"plaa_core"` |
| `mods/create/.../neoforge.mods.toml:29`、`:37` | `folkways_core` → `plaa_core`；`folkways_vanilla` → `plaa_vanilla` |
| `mods/modulargolems/.../neoforge.mods.toml:29`、`:37` | 同上 |
| 四份 toml 各新增 4 段 | `[[dependencies.${mod_id}]] modId = "folkways_core" type = "incompatible" reason = "Per Lapidem ad Astra 是 Folkways 的 fork，同一世界只能有一套居民/殖民地系统（d12 R-FK-3）" versionRange = "[0,)" ordering = "NONE" side = "BOTH"`，对 `folkways_core` / `folkways_vanilla` / `folkways_create` / `folkways_modulargolems` 各一段（NeoForge 21.1 支持 `type = "incompatible"`，命中即 `ModLoadingException`，与 k00 §10.1 v2 看到的 Create↔Radium 同机制） |
| 四份 toml 的 `displayName` / `displayURL` / `authors` / `issueTrackerURL` | **待人类定文案**（§7 OQ-P1-2）；建议 `displayName = "Per Lapidem ad Astra · Core"` 等，`authors = "IzakyL (Folkways); TCCH1111 (Per Lapidem ad Astra)"`，`license = "MIT"` 不变 |

### 2.4 测试基建与文档（与 modid 字面量绑定）

| 文件:行 | 改动 |
| --- | --- |
| `blockwright.toml:16-26` | `[mods.folkways_core]`…四段 → `[mods.plaa_core]`…，`path = "build/libs/plaa-core-*.jar"` 等（**全部重命名、不留别名**，w06 OQ-B-5） |
| `blockwright.toml:153` | `[coverage] mods = ["plaa_core", "plaa_vanilla", "plaa_create", "plaa_modulargolems"]` |
| `tests/shared/harness/mod-settings.ts:39-40` | `config/folkways_vanilla-server.toml` → `config/plaa_vanilla-server.toml`；`config/folkways_core-server.toml` → `config/plaa_core-server.toml`（ModConfig 文件名 = `<modid>-server.toml`，由 `FolkwaysMod.java:70`、`FolkwaysVanillaMod.java:17`、`FolkwaysCreateMod.java:16` 的 `registerConfig(ModConfig.Type.SERVER, …)` 决定） |
| `README.md:109`、`CONTRIBUTING.md:31-34` | 文字改为 plaa 的 id；README 顶部加 fork 声明（d12 §7"不洗白来源"） |
| **新增** `NOTICE.md`（根目录，L1） | 内容：本仓库是 Folkways（IzakyL，MIT，`https://github.com/IzakyL/folkways`）的 fork；基线 `67f28b0`（标签 `upstream-base-67f28b0-20261019`）；保留上游 `LICENSE` 与全部版权头；我们的代码同为 MIT；修改清单（首条即本计划）；`THIRD_PARTY.md` 不变 |

### 2.5 不受影响（核对过）

`gradle/mod.gradle` 的 `lib()`（`:39-47`）与 `expanded`（`:62-73`）；`build.gradle:47-54` 的 `gameTestServer`（`enabledGameTestNamespaces = "folkways,ldlib2"` 是命名空间）；全部 `assets/folkways/**`、`data/folkways/**`；mixin 配置文件名；lang 文件；`package.json`/CI。

**modid 常量的全部用途（2026-10-19 用 Grep 在快照 `mods/**/*.java` 复核）**：`FolkwaysMod.CORE_ID`、`FolkwaysVanillaMod.ID`、`FolkwaysCreateMod.ID`、`FolkwaysModularGolemsMod.ID` 只出现在 `@Mod(...)`（4 处）与 `@EventBusSubscriber(modid = ...)`（main 侧 12 处 + gametest 侧若干）两种注解里，**没有任何持久化/网络/注册名用途**；所有 `ResourceLocation ID` 常量（`WaresContent`、`RailContent`、`DispatchContent`、`PersonBody`、`SablePassage`…）与 `SweepOffer.ID` 都挂在 `FolkwaysMod.MOD_ID`（`"folkways"`）命名空间下，`colony.kept(…ID)` 的存档键亦然。四份 `neoforge.mods.toml` 目前没有任何 `type = "incompatible"` 段（本计划新增）。

---

## 3. 数据模型与存档影响

| 项 | 影响 | 处置 |
| --- | --- | --- |
| 方块/物品/实体/附件注册名 | **无**——全部在 `folkways:` 命名空间（`MOD_ID` 不变） | — |
| 数据包 `folkways/library`、图案、蓝图 | **无** | — |
| 服务端配置文件名 | `serverconfig/folkways_core-server.toml` 等 → `plaa_core-server.toml` / `plaa_vanilla-server.toml` / `plaa_create-server.toml` | 新世界无感；**从上游世界迁移过来的玩家会丢失配置改动（回到默认值）**→ 在 `NOTICE.md` 与整合包说明里写明；不做自动迁移（配置不是存档） |
| `level.dat` 的 mod 列表 | 上游世界载入时 NeoForge 会提示缺少 `folkways_core` 等 mod（**警告，不阻塞**）⚠️ 待 T4 时用一份上游 nightly 建的世界实测确认 | 记录到验证报告 |
| 与上游共存 | `incompatible` 声明生效后**不能共装**（这正是 R-FK-3 想要的） | T5 负向测试 |

---

## 4. 与 Folkways 公共 API 的交互点 / 网络同步 / i18n / 性能

- **API**：无（不触及 `core/api`、`front/api`）。
- **网络同步**：无新包、无字段变化。
- **i18n**：无 lang 键变动（`displayName` 等是 toml 字面量，不走 lang；上游既有四语言文件原样保留，`test:i18n` 应与基线一致）。
- **性能**：无。

---

## 5. 上游同步成本（d12 §5/§6）

全部 L2 改动都是**单行字面量替换**，分布在上游很少改的位置（`build.gradle` 映射、四个 `ext.modId`、四个常量、toml 依赖段、`blockwright.toml` 头部）。预期冲突形态：上游新增一个子 mod 或改 toml 结构时需手工合并。每处改动加标记：Java/TS/Gradle 用 `// PLA: ADR-023 modid`，TOML 用 `# PLA: ADR-023 modid`；全部登记到 d12 §5.1 改动登记表。

---

## 6. 测试计划（TDD，R-WF-2）——先写 T1，再改代码

| 编号 | 层 | 内容 | 期望 |
| --- | --- | --- | --- |
| **T1** | 0（Node 单测，新文件 `tests/mods-toml.test.ts`，纳入 `npm run test:unit` 的 `tests/**/*.test.ts` 通配） | 读四个 `mods/*/build.gradle` 的 `ext.modId`，断言 ∈ `{plaa_core, plaa_vanilla, plaa_create, plaa_modulargolems}`；读四个 `neoforge.mods.toml`：断言内部依赖 `modId` 全为 `plaa_*`，且每份含对四个 `folkways_*` 的 `type = "incompatible"` 段；扫描 `mods/**/*.java`、`*.gradle`、`*.toml`、`tests/shared/**/*.ts`，断言不再出现 `folkways_(core|vanilla|create|modulargolems)` 字面量（`NOTICE.md`/`README.md`/`CONTRIBUTING.md` 除外） | 改代码前 **红**，改完 **绿** |
| **T2** | 0 | `tools/wsl-run.sh build`：`build/libs/` 恰有 `plaa-core-…`、`plaa-vanilla-…`、`plaa-create-…`、`plaa-modulargolems-…` 四个 jar（+ `-sources`），无 `folkways-*.jar`；`./gradlew check`（含 `lintScaffold`）绿 | 全绿 |
| **T3** | 1 | `tools/wsl-run.sh gametest`：仍 **647 required tests passed** | 与基线一致 |
| **T4** | 1（w06 §3.5 手法 1，R-BLD-9） | 本机 `.cache/test-server/`（NeoForge 21.1.264）只放 `plaa-core`、`plaa-vanilla`、`plaa-create` + `ldlib2` + `create`（folkways_create 需要）：到 `Done`；`serverconfig/` 出现 `plaa_core-server.toml`、`plaa_vanilla-server.toml`、`plaa_create-server.toml` | 通过 |
| **T5** | 1（负向，R-FK-3） | 同 T4 再加入上游 nightly 的 `folkways-core-neoforge-1.21.1-0.1.0.jar`：FML 必须以 `ModLoadingException` 拒绝启动，报错含我们 `incompatible` 段的 `reason` | 拒绝启动 |
| **T6** | 0 | `npm run typecheck`（`mod-settings.ts` 改动）、`npm run test:i18n` | 绿，且 i18n 结果与基线一致 |

---

## 7. 待人类决定（2026-10-19 已全部裁决，[ADR-025](../00-charter.md)）

| 编号 | 问题 | 裁决 |
| --- | --- | --- |
| OQ-P1-1 | `gradle.properties` 的 `maven_group` | **`io.github.tcch1111`**（GitHub 账号 TCCH1111；远端仓库建立后生效） |
| OQ-P1-2 | 四份 toml 的 `displayName` / `authors` / `displayURL` / `issueTrackerURL` | 文案放进我们的仓库：`displayName = "Per Lapidem ad Astra · Core/Vanilla/Create/Modular Golems"`；`authors = "IzakyL (Folkways); TCCH1111 (Per Lapidem ad Astra)"`；`displayURL` / `issueTrackerURL` = 新建的 GitHub 仓库地址（§8 步骤 0） |
| OQ-P1-3 | `settings.gradle:18` 的 `rootProject.name` | **改为 `plaa`** |
| OQ-P1-4 | `NOTICE.md` 是否打进 jar | **是**：`gradle/mod.gradle:52-56` 加一行 → `META-INF/NOTICE_plaa.md` |

**另因 ADR-024 §1/§12 新增范围**：B-2 之后紧接着（同一分支或 PLAN-002）新建子项目 `mods/plaa/`（modid `plaa`，承载我们新增的玩法；`settings.gradle` 的 `include` 列表与根 `build.gradle` 的 `modProjects` 各加一项）。本计划 **不做** `mods/plaa/` 的创建，只保证改名后四个上游子项目可构建。

---

## 8. 执行顺序

0. ~~**前置（ADR-025）**~~ **已完成（2026-10-19 晚）**：基线前移到 `3ce4d88`（fast-forward，标签 `upstream-base-3ce4d88-20261019`，`reference/folkways-3ce4d88/` 已解出，§2 行号已复核）；`origin` = `https://github.com/TCCH1111/per-lapidem-ad-astra`，`main` + 两个基线标签已推送。新基线上的 build + gametest 复验结果见 w06 §1.3。
1. 在 WSL `~/pla/mod` 建分支 `feat/b2-modid`（w00 §5 分支规范；非 PRD 任务，用任务编号）。
2. 写 T1（红）。
3. 按 §2 改 16 处 + 新建 `NOTICE.md`；每处加 `PLA:` 标记。
4. `wsl-run.sh build` → T1/T2/T6 绿；`wsl-run.sh gametest` → T3。
5. T4/T5 在 `.cache/test-server/` 手动跑（流程见 k00 §10.1），截取日志进验证报告。
6. 登记 d12 §5.1；写 `docs/reports/VERIFY-001-b2.md`；提交信息 `build(modid): rename the four mods to plaa_* and add NOTICE (ADR-023)`。
7. 人工 Review（w00 阶段六）后合入 `main`。

## 9. 变更记录

| 日期 | 状态 | 说明 |
| --- | --- | --- |
| 2026-10-19 | 计划中 | 首稿；§2.5 补入 modid 常量用途的 Grep 复核结论。**第 1 轮审查尚未开始**：三次派发审查 agent 均被工具侧拦截（一次 API 余额不足、两次分类器临时错误），按 R-ROLE-1 不由本会话自审，待重新派发或由人类直接审 |
