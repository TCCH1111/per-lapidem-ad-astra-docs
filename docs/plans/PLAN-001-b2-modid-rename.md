# PLAN-001 · B-2：把 fork 的四个 modid 改为 `plaa_*`（含 NOTICE 与冲突声明）

```
状态：**已验证（T1–T6，证据见 [VERIFY-001](../reports/VERIFY-001-b2.md)）**；待人工 Review；改动在 WSL 工作树（未推送）
负责人：规划者（agent）
最后更新：2026-10-20
上游依据：docs/00-charter.md ADR-017 / ADR-023；docs/design/12-fork-strategy.md §4、§5、§7（R-FK-2/3/4/8）；docs/workflow/06-build-and-ci.md §1.3 B-2、§6.1；docs/research/10-upstream-delta-f42e3c1-67f28b0.md §2、§3
事实快照：reference/folkways-3ce4d88/（基线已按 ADR-025 前移；本计划全部 文件:行号 已于 2026-10-19 在该快照上复核并经第 1 轮审查纠错（R1-02）；上游在 `FolkwaysMod.java:71` 新增 `registerConfig(ModConfig.Type.CLIENT, FolkwaysClientConfig.SPEC)`，由此多出一份客户端配置文件，见 §3）
改动目标：**WSL `~/pla/mod`**（分支 `feat/b2-modid`；Windows 侧经 `\\wsl.localhost\Ubuntu-24.04\home\tcch1111\pla\mod\` 访问，或在 WSL 内用 `tools/wsl-run.sh`）。`reference/folkways-3ce4d88/` **只读，禁止改动**——它只是核对行号用的快照，不是工作树（R2-03）
```

> 这是 fork 的**第一处改上游文件**。目的只有一个：让我们的四个 jar 与上游 Folkways 在 modid 上可区分、不可共装，并履行 MIT 的署名义务。**不改任何玩法行为、不改任何包名/类名/资源命名空间。**

---

## 1. 任务单（照 w05 §3.2 九字段）

| 字段 | 内容 |
| --- | --- |
| 任务编号 | **M1-WP0-B2** |
| 一句话目标 | 四个子项目的 modid 变为 `plaa_core` / `plaa_vanilla` / `plaa_create` / `plaa_modulargolems`，产物名 `plaa-<name>-neoforge-1.21.1-*.jar`，四个 `mods.toml` 对上游四个 modid 声明 `incompatible`，根目录新增 `NOTICE.md`；构建、游戏测试（数量与 w06 §1.3 在 3ce4d88 上的基线记录一致）、最小实例启动全部照旧通过 |
| 图层 | **L2**（在上游既有文件里改少量行，标记形式见 §5）+ **L1**（新文件 `NOTICE.md`、新测试 `tests/i18n/mods-toml.test.ts`——放在已被 `typecheck` 覆盖的 `tests/i18n/` 下，R1-12）。**无 L3/L4** |
| 允许触碰 | §2.6 清单的 **20 个既有文件** + 2 个新文件；**不得**触碰 `mods/*/src/main/java/**` 中除四个主类常量行以外的任何代码 |
| 必读 | ADR-023；d12 §4/§5/§7；w06 §1.3 B-2、§6.1；r10 §2.2、§3 |
| 验收 AC | 本计划 §6 的 T1–T6（无对应 PRD AC，属 w05 WP-0 环境类任务） |
| 自测命令 | **全部在 WSL `~/pla/mod` 内**：`tools/wsl-run.sh build`（T2）、`tools/wsl-run.sh unit`（T1/T6：`npm run typecheck` + `test:unit` + `test:i18n`，2026-10-19 新增阶段）、`tools/wsl-run.sh gametest`（T3）。Windows 侧不跑层 0（w06 R-BLD-17 ⚠️ 未验证） |
| 禁止事项 | 改 `reference/**`（只读快照，R2-03）；改 `FolkwaysMod.MOD_ID`（`"folkways"`，资源命名空间）；改 `gradle/mod.gradle` 的 `lib()`/`expanded` 逻辑（仅允许加 NOTICE 打包一行）；重命名包/类/目录（R-FK-2）；改 `enabledGameTestNamespaces`；改 `gradle.properties` 的 `neoforge_version` / `neoforge_requirement`（NeoForge 升级按 R-BLD-1 另开提交，R1-15）；顺手改任何玩法 |
| 交付物 | diff；`NOTICE.md`；`tests/i18n/mods-toml.test.ts`；d12 §5.1 改动登记表新增行（每个被改文件一行）；验证报告 `docs/reports/VERIFY-001-b2.md`（逐条 T1–T6 判定 + 证据） |
| 失败回退 | 任一 T 不过 → `git checkout upstream-base-3ce4d88-20261019 -- <文件>` 回退该文件；若 T3 因 modid 变化失败（例如附件/配置按 modid 寻址），**停下上报**，不得改成保留 `folkways_*` 别名绕过 |

---

## 2. 涉及的模块与路径（含 `文件:行号`，基于 `reference/folkways-3ce4d88/`）

### 2.1 构建坐标（Gradle）

| 文件:行 | 现值 | 改为 | 层 |
| --- | --- | --- | --- |
| `mods/core/build.gradle:7-8` | `ext.modId = "folkways_core"` / `ext.modName = "folkways-core"` | `plaa_core` / `plaa-core` | L2 |
| `mods/vanilla/build.gradle:7-8` | `folkways_vanilla` / `folkways-vanilla` | `plaa_vanilla` / `plaa-vanilla` | L2 |
| `mods/create/build.gradle:7-8` | `folkways_create` / `folkways-create` | `plaa_create` / `plaa-create` | L2 |
| `mods/modulargolems/build.gradle:7-8` | `folkways_modulargolems` / `folkways-modulargolems` | `plaa_modulargolems` / `plaa-modulargolems` | L2 |
| `build.gradle:8-11` | `modProjects` 映射键 `folkways_core: ":core"` … | 键改 `plaa_*`（值不变） | L2 |
| `settings.gradle:18` | `rootProject.name = "folkways"` | `"plaa"`（§7 OQ-P1-3 已定） | L2 |
| `gradle.properties:3` | `maven_group=io.github.izakyl` | `io.github.tcch1111`（§7 OQ-P1-1 已定）。**不动** `:7` `neoforge_version` 与 `:9` `neoforge_requirement` | L2 |
| `gradle/mod.gradle:55-60` | `tasks.named("jar")` 把 `LICENSE` 打入 `META-INF/LICENSE_folkways.txt` | 保留；在同一块内**另加一个 `from(rootProject.file("NOTICE.md"))`** → `META-INF/NOTICE_plaa.md`（§7 OQ-P1-4 已定） | L2 |

产物名由 `gradle/mod.gradle:6-8` 的 `archivesName = "${project.modName}-neoforge-${minecraft_version}"` 自动得到 `plaa-core-neoforge-1.21.1-0.1.0.jar` 等；`neoforge.mods.toml` 的 `${mod_id}` 由 `gradle/mod.gradle:67-74` 的 `expanded` 经 `:76-81` 的 `processResources` 展开，无需另改。

### 2.2 Java 常量（每个子 mod 恰好一处字面量）

| 文件:行 | 现值 | 改为 |
| --- | --- | --- |
| `mods/core/src/main/java/io/github/izakyl/folkways/FolkwaysMod.java:63` | `CORE_ID = "folkways_core"` | `"plaa_core"`（`:57` 的 `@Mod(FolkwaysMod.CORE_ID)` 自动跟随；main 侧 12 处 + gametest 侧若干处 `@EventBusSubscriber(modid = FolkwaysMod.CORE_ID)` 自动跟随） |
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
| 四份 toml 各新增 4 段 | `[[dependencies.${mod_id}]] modId = "folkways_core" type = "incompatible" reason = "Per Lapidem ad Astra is a fork of Folkways; the two cannot share a world (one colony system). 本 mod 是 Folkways 的 fork，同一世界只能装一套殖民地系统。" versionRange = "[0,)" ordering = "NONE" side = "BOTH"`，对 `folkways_core` / `folkways_vanilla` / `folkways_create` / `folkways_modulargolems` 各一段（NeoForge 21.1 支持 `type = "incompatible"`，命中即 `ModLoadingException`，与 k00 §10.1 v2 看到的 Create↔Radium 同机制） |
| 四份 toml 的顶层 `issueTrackerURL`（`:4`）与 `[[mods]]` 段的 `displayName` / `displayURL` / `authors`（`:9-12` 附近） | `issueTrackerURL = "https://github.com/TCCH1111/per-lapidem-ad-astra/issues"`；`displayName = "Per Lapidem ad Astra · Core"` / `· Vanilla` / `· Create` / `· Modular Golems`；`displayURL = "https://github.com/TCCH1111/per-lapidem-ad-astra"`；`authors = "IzakyL (Folkways); TCCH1111 (Per Lapidem ad Astra)"`；`license = "MIT"` 不变（§7 OQ-P1-2 已定） |

### 2.4 测试基建与文档（与 modid 字面量绑定）

| 文件:行 | 改动 |
| --- | --- |
| `blockwright.toml:16-26` | `[mods.folkways_core]`…四段 → `[mods.plaa_core]`…，`path = "build/libs/plaa-core-*.jar"` 等（**全部重命名、不留别名**，w06 OQ-B-5） |
| `blockwright.toml:153` | `[coverage] mods = ["plaa_core", "plaa_vanilla", "plaa_create", "plaa_modulargolems"]` |
| `tests/shared/harness/mod-settings.ts:39-40` | `config/folkways_vanilla-server.toml` → `config/plaa_vanilla-server.toml`；`config/folkways_core-server.toml` → `config/plaa_core-server.toml`（ModConfig 文件名 = `<modid>-server.toml`，由 `FolkwaysMod.java:70`、`FolkwaysVanillaMod.java:17`、`FolkwaysCreateMod.java:16` 的 `registerConfig(ModConfig.Type.SERVER, …)` 决定）。**另**：`FolkwaysMod.java:71` 的 `registerConfig(ModConfig.Type.CLIENT, …)` 使客户端目录多一份 `config/plaa_core-client.toml`（原 `folkways_core-client.toml`）；harness 目前不写它，无需改，但 §3 要列（R1-03） |
| `README.md:109`、`CONTRIBUTING.md:31-34` | 文字改为 plaa 的 id；README 顶部加 fork 声明（d12 §7"不洗白来源"） |
| **新增** `NOTICE.md`（根目录，L1） | 内容：本仓库是 Folkways（IzakyL，MIT，`https://github.com/IzakyL/folkways`）的 fork；基线 `3ce4d88`（标签 `upstream-base-3ce4d88-20261019`）；保留上游 `LICENSE` 与全部版权头；我们的代码同为 MIT；修改清单（首条即本计划）；配置文件名随 modid 改变的说明（§3）；`THIRD_PARTY.md` 不变。**新写的 md/toml/gradle 内容不得含 Tab 与行尾空白**——根 `build.gradle:105-128` 的 `lintScaffold` 扫 `**/*.md`、`**/*.toml`、`**/*.gradle`，T2 的 `check` 会抓（R2-09） |

### 2.5 不受影响（核对过）

`gradle/mod.gradle` 的 `lib()`（`:39-47`）与 `expanded`/`processResources`（`:67-74`/`:76-81`）；`build.gradle:47-54` 的 `gameTestServer`（`enabledGameTestNamespaces = "folkways,ldlib2"` 是命名空间）；全部 `assets/folkways/**`、`data/folkways/**`；mixin 配置文件名；lang 文件；`package.json`。`.github/workflows/build.yml:32/48/60-61` 含上游产物名文案（`folkways-jars`、nightly 说明），但 nightly job 以 `refs/heads/master` 为门（`:37`）而我们的分支是 `main`，功能上不受影响；CI 改造另列，B-2 不改（R1-11）。

**modid 常量的全部用途（2026-10-19 用 Grep 在快照 `mods/**/*.java` 复核）**：`FolkwaysMod.CORE_ID`、`FolkwaysVanillaMod.ID`、`FolkwaysCreateMod.ID`、`FolkwaysModularGolemsMod.ID` 只出现在 `@Mod(...)`（4 处）与 `@EventBusSubscriber(modid = ...)`（main 侧 12 处 + gametest 侧若干）两种注解里，**没有任何持久化/网络/注册名用途**；所有 `ResourceLocation ID` 常量（`WaresContent`、`RailContent`、`DispatchContent`、`PersonBody`、`SablePassage`…）与 `SweepOffer.ID` 都挂在 `FolkwaysMod.MOD_ID`（`"folkways"`）命名空间下，`colony.kept(…ID)` 的存档键亦然。四份 `neoforge.mods.toml` 目前没有任何 `type = "incompatible"` 段（本计划新增）。审查者另核：`DeferredRegister` 与 `PayloadRegistrar` 全挂 `MOD_ID`；`ColonyRegistry.java:25` 的 SavedData 名是字面量 `"folkways_colonies"`，`Shelves.java:19`、`WindowGeometry.java:15` 亦为字面量——存档/网络均不受 modid 影响。

### 2.6 文件清单（「允许触碰」的硬边界）

既有文件 20 个：`build.gradle`、`settings.gradle`、`gradle.properties`、`gradle/mod.gradle`、`mods/{core,vanilla,create,modulargolems}/build.gradle`（4）、四个主类 `FolkwaysMod.java` / `FolkwaysVanillaMod.java` / `FolkwaysCreateMod.java` / `FolkwaysModularGolemsMod.java`（4，各只改一行常量）、四份 `mods/*/src/main/resources/META-INF/neoforge.mods.toml`（4）、`blockwright.toml`、`tests/shared/harness/mod-settings.ts`、`README.md`、`CONTRIBUTING.md`。新文件 2 个：`NOTICE.md`、`tests/i18n/mods-toml.test.ts`。

---

## 3. 数据模型与存档影响

| 项 | 影响 | 处置 |
| --- | --- | --- |
| 方块/物品/实体/附件注册名 | **无**——全部在 `folkways:` 命名空间（`MOD_ID` 不变） | — |
| 数据包 `folkways/library`、图案、蓝图 | **无** | — |
| 服务端配置文件名 | `serverconfig/folkways_core-server.toml` 等 → `plaa_core-server.toml` / `plaa_vanilla-server.toml` / `plaa_create-server.toml` | 新世界无感；**从上游世界迁移过来的玩家会丢失配置改动（回到默认值）**→ 在 `NOTICE.md` 与整合包说明里写明；不做自动迁移（配置不是存档） |
| 客户端配置文件名 | `config/folkways_core-client.toml` → `config/plaa_core-client.toml`（`FolkwaysMod.java:71`，客户端目录） | 同上：玩家侧客户端设置回默认；写进 NOTICE 与整合包说明。专用服务端测不到，不作 T 判据，客户端实例手动核一次（R1-03） |
| `level.dat` 的 mod 列表 | 服务端载入上游世界：只打日志，不阻塞（本次 T4 使用新测试世界，未验证旧存档载入）；客户端世界选择界面会提示缺少 `folkways_*` mod——**客户端行为，T4 测不到**，另列手动核查项（R1-08） | 记录到验证报告 |
| 存档内数据 | **无**：`ColonyRegistry.java:25` 的 SavedData 名为字面量 `"folkways_colonies"`，`colony.kept(…)` 的键全在 `folkways:` 命名空间 | — |
| 与上游共存 | `incompatible` 声明生效后**不能共装**（这正是 R-FK-3 想要的） | T5 负向测试 |

---

## 4. 与 Folkways 公共 API 的交互点 / 网络同步 / i18n / 性能

- **API**：无（不触及 `core/api`、`front/api`）。
- **网络同步**：无新包、无字段变化。
- **i18n**：无 lang 键变动（`displayName` 等是 toml 字面量，不走 lang；上游既有四语言文件原样保留，`test:i18n` 应与基线一致）。
- **性能**：无。

---

## 5. 上游同步成本（d12 §5/§6）

除四份 toml 各新增 4 段 `incompatible`、`gradle/mod.gradle:55-60` 块内新增一个多行 `from(...)`、README 顶部新增 fork 声明段之外，其余 L2 改动都是**单行字面量替换**，分布在上游很少改的位置（`build.gradle` 映射、四个 `ext.modId`、四个常量、toml 依赖段、`blockwright.toml` 头部）。预期冲突形态：上游新增一个子 mod 或改 toml 结构时需手工合并。每处改动加标记：Java/TS/Gradle 用 `// PLA: ADR-023 modid`，TOML 用 `# PLA: ADR-023 modid`，Markdown 用 `<!-- PLA: ADR-023 modid -->`；定位命令 `git grep "PLA: ADR-023"`（与 w06 §6.2 S6 的 `git grep "PLA: ADR-"` 兼容，w06 已同步）；全部登记到 d12 §5.1 改动登记表并注明每个文件的标记形式（R1-14）。

---

## 6. 测试计划（TDD，R-WF-2）——先写 T1，再改代码

| 编号 | 层 | 内容 | 期望 |
| --- | --- | --- | --- |
| **T1** | 0（Node 单测，新文件 `tests/i18n/mods-toml.test.ts`：被 `package.json:9` 的 `tests/**/*.test.ts` 通配跑到，也被 `tests/i18n` 的 tsconfig 纳入 `typecheck`；无 TOML 库，用正则取 `ext.modId` 与 `[[dependencies.*]]` 段，同 `tests/i18n/lang.test.ts` 手法） | ① 四个 `mods/*/build.gradle` 的 `ext.modId` ∈ `{plaa_core, plaa_vanilla, plaa_create, plaa_modulargolems}`；② 四份 `neoforge.mods.toml`：**所有 `type != "incompatible"` 的依赖段** `modId` 不含 `folkways_*`，且每份恰含 4 段 `type = "incompatible"` 分别指向四个 `folkways_*`（结构化断言，避免 R1-01 的自相矛盾）；③ 全文扫描 `mods/**/*.java`、`**/*.gradle`（排除 `build/`、`node_modules/`、`.gradle/`）、`blockwright.toml`、`tests/shared/**/*.ts`，不再出现 `folkways_(core|vanilla|create|modulargolems)` 字面量（`neoforge.mods.toml` 不在此项，由 ② 覆盖；`NOTICE.md`/`README.md`/`CONTRIBUTING.md` 除外） | 改代码前 **红**，改完 **绿** |
| **T2** | 0 | `tools/wsl-run.sh build`：根 `build/libs/` 恰有 `plaa-core-…`、`plaa-vanilla-…`、`plaa-create-…`、`plaa-modulargolems-…` 四个 jar，无 `folkways-*.jar`（`-sources` 落在各子项目 `mods/<name>/build/libs/`，不作根目录判据，R1-13）；`./gradlew check`（含 `lintScaffold`）绿 | 全绿 |
| **T3** | 1 | `tools/wsl-run.sh gametest`：**651 个测试全部通过**（w06 §1.3 在未改动的 3ce4d88 上的基线：第 1 次 650/651、第 2 次 651/651）。唯一已知非确定性测试 `folkways:onefoodcannotfeedhalfofapair`（`PastureBreedingGameTests.java:137`）若失败，**重跑一次即过则视为通过**；其他任何失败都是回归 | 与基线一致 |
| **T4** | 1（w06 §3.5 手法 1，R-BLD-9） | **另建** `.cache/test-server-b2/`（复制 `.cache/test-server/` 的 `libraries/`、`user_jvm_args.txt`、`eula.txt`、`server.properties`，**不动**整合包冒烟实例 `.cache/test-server/`，R2-02）。`mods/` 只放最小集合：fork 产物 `plaa-core` / `plaa-vanilla` / `plaa-create`（取自 `\\wsl.localhost\Ubuntu-24.04\home\tcch1111\pla\mod\build\libs\`）+ `ldlib2`（`…\build\deps\`）+ `create`（`plaa_create` 要求 `[6.0.0,)`；jar 取 `.cache/mods-modrinth/create-1.21.1-6.0.10.jar`）。**先做对照**（R2-07）：同一最小集合换成上游 nightly 的 `folkways-{core,vanilla,create}`（取 `.cache/test-server/mods/`），须先到 `Done (`——对照不过则是最小集合缺东西，不归咎改名。然后换 `plaa-*`：到 `Done (`；`<world>/serverconfig/` 出现 `plaa_core-server.toml`、`plaa_vanilla-server.toml`、`plaa_create-server.toml` | 通过 |
| **T5** | 1（负向，R-FK-3） | 同 T4（`.cache/test-server-b2/`）再加入上游 nightly 的 `folkways-core-neoforge-1.21.1-0.1.0.jar`（取 `.cache/test-server/mods/`，packwiz 钉 e5b6838）：两条硬判据——① 服务端未到 `Done (`，以 FML 加载错误退出；② `logs/latest.log` 含 `Mod plaa_core is incompatible with folkways_core`（四对里至少一条；格式参照 k00 §10.1 v2 实测 `Mod create is incompatible with radium any`）。`reason` 文本是否出现只记录、不作判定（R1-07） | 拒绝启动 |
| **T6** | 0 | `npm run typecheck`（`mod-settings.ts` 改动）、`npm run test:i18n` | 绿，且 i18n 结果与基线一致 |

---

## 7. 待人类决定（2026-10-19 已全部裁决，[ADR-025](../00-charter.md)）

| 编号 | 问题 | 裁决 |
| --- | --- | --- |
| OQ-P1-1 | `gradle.properties` 的 `maven_group` | **`io.github.tcch1111`**（GitHub 账号 TCCH1111；远端仓库建立后生效） |
| OQ-P1-2 | 四份 toml 的 `displayName` / `authors` / `displayURL` / `issueTrackerURL` | 文案放进我们的仓库：`displayName = "Per Lapidem ad Astra · Core/Vanilla/Create/Modular Golems"`；`authors = "IzakyL (Folkways); TCCH1111 (Per Lapidem ad Astra)"`；`displayURL` / `issueTrackerURL` = 新建的 GitHub 仓库地址（§8 步骤 0） |
| OQ-P1-3 | `settings.gradle:18` 的 `rootProject.name` | **改为 `plaa`** |
| OQ-P1-4 | `NOTICE.md` 是否打进 jar | **是**：`gradle/mod.gradle:55-60` 的 `tasks.named("jar")` 块内加一个 `from` → `META-INF/NOTICE_plaa.md` |

**另因 ADR-024 §1/§12 新增范围**：B-2 之后紧接着（同一分支或 PLAN-002）新建子项目 `mods/plaa/`（modid `plaa`，承载我们新增的玩法；`settings.gradle` 的 `include` 列表与根 `build.gradle` 的 `modProjects` 各加一项）。本计划 **不做** `mods/plaa/` 的创建，只保证改名后四个上游子项目可构建；未来 `plaa` 对 `plaa_*` 是 `required` 依赖，与本计划的 `incompatible` 声明无交叉（审查核对）。

**后续归属（不在本计划内，R1-16）**：B-2 合入后，整合包侧把 `pack/mods/folkways-{core,vanilla,create,modulargolems}.pw.toml` 四个全部换成 fork 产物 `plaa-*`（k00 §7 过渡期结束；Modular Golems 本体与 L2 Library 已在 pack 内，k00 §10.1 v5）。

---

## 8. 执行顺序

0. ~~**前置（ADR-025）**~~ **已完成（2026-10-19 晚）**：基线前移到 `3ce4d88`（fast-forward，标签 `upstream-base-3ce4d88-20261019`，`reference/folkways-3ce4d88/` 已解出，§2 行号已复核）；`origin` = `https://github.com/TCCH1111/per-lapidem-ad-astra`，`main` + 两个基线标签已推送。新基线上的 build + gametest 复验结果见 w06 §1.3。
1. 在 WSL `~/pla/mod` 建分支 `feat/b2-modid`（w00 §5 分支规范；非 PRD 任务，用任务编号）。
2. 写 T1（红）。
3. 按 §2 改 20 个文件 + 新建 `NOTICE.md`；每处加 `PLA:` 标记（形式见 §5）。
4. `wsl-run.sh build` → T2；`wsl-run.sh unit` → T1/T6；`wsl-run.sh gametest` → T3（均在 WSL 内）。
5. T4/T5 在**另建的** `.cache/test-server-b2/` 手动跑（流程见 k00 §10.1，先对照再正式），截取日志进验证报告。
6. 登记 d12 §5.1；写 `docs/reports/VERIFY-001-b2.md`；提交信息 `build(modid): rename the four mods to plaa_* and add NOTICE (ADR-023)`。
7. 人工 Review（w00 阶段六）后合入 `main`。

## 9. 变更记录

| 日期 | 状态 | 说明 |
| --- | --- | --- |
| 2026-10-20 | 实现完成，待人工 Review | B-2 四 modid 重命名与 NOTICE 完成；T1–T6 结果见 [VERIFY-001-b2](../reports/VERIFY-001-b2.md)。专用服务端测试未覆盖 CLIENT 配置行为 |
| 2026-10-19 | 计划中 | 首稿；§2.5 补入 modid 常量用途的 Grep 复核结论 |
| 2026-10-19 | 计划中（第 1 轮已修订） | 第 1 轮审查（§10）：1 阻塞 / 7 应改 / 9 建议，全部采纳并修订正文：T1 改结构化断言（R1-01）；`gradle/mod.gradle` 行号纠正为 `:55-60` / `:67-74` / `:76-81`（R1-02）；补客户端配置 `plaa_core-client.toml`（R1-03）；三处基线改 `3ce4d88`（R1-04）；文件数 20 + §2.6 清单（R1-05）；T3 以 3ce4d88 基线记录为准（R1-06）；T5 两条硬判据（R1-07）；§3 `level.dat` 拆服务端/客户端（R1-08）；§2.1/§2.3 填入裁决值（R1-09）；计数措辞（R1-10）；CI 说明（R1-11）；测试文件移至 `tests/i18n/`（R1-12）；T2 去掉 `-sources`（R1-13）；Markdown 标记与统一 grep（R1-14）；禁改 NeoForge 版本（R1-15）；pack 侧后续归属（R1-16）；reason 双语（R1-17） |
| 2026-10-19 | **待人类确认** | 第 2 轮审查（§11）：R1 17 条全部确认已修；新 9 条（3 应改 / 6 建议）全部采纳：首页写明改动目标 = WSL `~/pla/mod`、快照只读（R2-03）；`tools/wsl-run.sh` 新增 `unit` 阶段承载 T1/T6（R2-01）；T4/T5 改在另建的 `.cache/test-server-b2/`、写明 jar 来源并先做上游对照（R2-02/07）；§7 后续改四 jar 全换（R2-04）；§5 与 w06 措辞对齐（R2-05）；T1 ③ glob 明确（R2-06）；§5 改动形态措辞（R2-08）；`lintScaffold` 提醒（R2-09）。审查结论「可交人类确认」 |

## 10. 评审记录 · 第 1 轮（2026-10-19，审查者）

> 只读审查，全部 `文件:行号` 在 `reference/folkways-3ce4d88/` 上逐条打开核对；NeoForge 机制结论有把握的引依据，没把握的标 ⚠️。

**核对通过（不列入下表）**：§2.1 四个 `mods/*/build.gradle:7-8`、`build.gradle:8-11`、`settings.gradle:18`、`gradle.properties:3`、`gradle/mod.gradle:6-8`（`archivesName`）；§2.2 四个常量行与 `FolkwaysMod.java:57/60/70`；§2.3 三份 toml 的 `:29`/`:37`；§2.4 `blockwright.toml:16-26`/`:153`、`mod-settings.ts:39-40`、`README.md:109`、`CONTRIBUTING.md:31-34`；§2.5 "main 侧 12 处 `@EventBusSubscriber`" 计数正确，modid 常量确无持久化/网络/注册用途（`DeferredRegister` 与 `PayloadRegistrar` 全挂 `MOD_ID`，`ColonyRegistry.java:25` 的 SavedData 名是字面量 `"folkways_colonies"`，`Shelves.java:19`、`WindowGeometry.java:15` 亦为字面量）；`enabledGameTestNamespaces`（`build.gradle:52`）与 `@GameTestHolder(FolkwaysMod.MOD_ID)` 不随 modid 变，不用改；`gradle/mod.gradle:67-81` 的 `expanded`+`processResources` 让 toml `${mod_id}` 自动跟随，`archivesName` 让产物名自动跟随；`build.gradle:38-44` 的 `neoForge.mods { create(id) }` 以 `modProjects` 键为名，键改 `plaa_*` 后与新 modid 一致；`tests/**` 无按 `folkways-*` 文件名找 jar 的代码（唯一的 jar 路径在 `blockwright.toml:17-26`，计划已列）；`type = "incompatible"` 在 NeoForge 21.1 存在且语义如计划所述（k00 §10.1 v2 实测日志 `Mod create is incompatible with radium any`，同一加载器 21.1.233），`ordering = "NONE"`/`side = "BOTH"` 为合法枚举值，`versionRange = "[0,)"` 为合法 Maven 区间（省略即 "any"，与上述日志一致）；w00 §4 七项、w05 §3.2 九字段齐全；L1/L2 分层判断成立；与 ADR-024 的边界（本计划不建 `mods/plaa/`）清晰，未来 `plaa` 对 `plaa_*` 是 `required` 依赖，与本计划的 `incompatible` 声明无交叉。

| 编号 | 严重度 | 位置（计划章节） | 问题与证据（带 文件:行号） | 修复建议 |
| --- | --- | --- | --- | --- |
| R1-01 | **阻塞** | §6 T1 | T1 自相矛盾、永远红：它既要求"每份 toml 含对四个 `folkways_*` 的 `incompatible` 段"，又要求扫描 `*.toml` 后"不再出现 `folkways_(core\|vanilla\|create\|modulargolems)` 字面量"。改完后四份 `neoforge.mods.toml` 每份恰好含 4 个 `modId = "folkways_*"`（§2.3 新增段），扫描必然命中 | 把字面量扫描改为结构化断言：对 `neoforge.mods.toml` 只要求"所有 `type != "incompatible"` 的依赖段 `modId` 不含 `folkways_*`"，其余 `*.gradle`/`*.java`/`blockwright.toml`/`tests/shared/**/*.ts` 维持全文扫描 |
| R1-02 | 应改 | §2.1、§2.5、§7 OQ-P1-4 | `gradle/mod.gradle` 两处行号与快照不符（67f28b0 与 3ce4d88 两份快照都如此，首页"已逐行复核"不成立）：LICENSE 打包块实际在 `gradle/mod.gradle:55-60`（计划写 `:52-56`；w06 OQ-B-8 写的 `:55-60` 才对）；`expanded` 实际在 `:67-74`、`processResources` 在 `:76-81`（计划写 `:62-73`）。`lib()` 的 `:39-47` 正确 | 改为 `:55-60` 与 `:67-74`/`:76-81`；§2.1 "NOTICE 另加一行"落在 `:55-60` 的 `tasks.named("jar")` 块内 |
| R1-03 | 应改 | §2.4、§3、§6 T4 | 漏掉 CLIENT 配置：`FolkwaysMod.java:71` `registerConfig(ModConfig.Type.CLIENT, FolkwaysClientConfig.SPEC)` 默认文件名同样由 modid 决定 → `config/folkways_core-client.toml` 变为 `config/plaa_core-client.toml`。首页只说"不影响任何引用行"，但 §3 的配置影响表只列了三份 server 配置，玩家侧客户端设置同样会回默认 | §3 增一行"客户端配置 `config/plaa_core-client.toml`"（客户端目录，非 `serverconfig/`）；NOTICE/整合包说明一并写明；T4 是专用服务端测不到它，注明"客户端实例手动核一次或不作为 T 判据" |
| R1-04 | 应改 | §1 失败回退、§2 标题、§2.4 NOTICE.md | 基线已前移但三处仍指旧基线：§1 回退命令 `git checkout upstream-base-67f28b0-20261019 -- <文件>`；§2 标题"基于 `reference/folkways-67f28b0/`"；§2.4 NOTICE.md 内容写"基线 `67f28b0`（标签 `upstream-base-67f28b0-20261019`）"。ADR-025 ①：当前基线 `3ce4d88`，标签 `upstream-base-3ce4d88-20261019` | 三处统一改为 `3ce4d88` / `upstream-base-3ce4d88-20261019`，与首页、§8 步骤 0 一致 |
| R1-05 | 应改 | §1 允许触碰 | "§3 列出的 16 个文件"数错，且 §3 不是文件清单（文件清单在 §2）。按 §2 实数：4×`mods/*/build.gradle` + `build.gradle` + `settings.gradle` + `gradle.properties` + `gradle/mod.gradle` + 4 个主类 + 4 份 toml + `blockwright.toml` + `mod-settings.ts` + `README.md` + `CONTRIBUTING.md` = **20** 个既有文件 + 2 个新文件。"允许触碰"是硬边界字段，数字错会让实现者在第 17 个文件处停下或越界 | 改为"§2 列出的 20 个文件 + 2 个新文件"，并在 §2 末尾给一张纯文件清单 |
| R1-06 | 应改 | §6 T3、§8 步骤 0 | T3 期望"仍 647"没有 3ce4d88 上的基线值支撑：§8 步骤 0 称"新基线上的 build + gametest 复验结果见 w06 §1.3"，但 w06 §1.3 首次构建记录表只有 67f28b0 的行（Grep `3ce4d88` 无命中）；3ce4d88 比 67f28b0 多 2 提交 109 文件，测试数可能已变 | 先在未改动的 3ce4d88 上跑一次 gametest 并把行写进 w06 §1.3，T3 期望改为"与该次记录的数量一致"；或把 647 标为 ⚠️ 待基线复验 |
| R1-07 | 应改 | §6 T5 | ⚠️ 判定依赖"报错含我们 `incompatible` 段的 `reason`"，但现有唯一实证（k00 §10.1 v2 日志 `Mod create is incompatible with radium any`）不含 reason 文本；NeoForge 的 incompatible 报错是否拼入 `reason` 我没有把握 | 把 T5 可观察判据改为两条硬条件：① 服务端未到 `Done (`，以 FML 加载错误退出；② 日志含 `Mod plaa_core is incompatible with folkways_core`（四对各一条或至少一条）。`reason` 出现与否只记录、不作判定 |
| R1-08 | 应改 | §3 `level.dat` 行、§6 T4 | "上游世界载入时 NeoForge 会提示缺少 mod（警告，不阻塞）"的提示是客户端世界选择界面行为；T4 是专用服务端（w06 §3.5 手法 1），服务端载入旧世界只会打日志，T4 验不到计划说的"提示" | 要么改为"服务端：日志不出现 FATAL、世界正常载入"（T4 可测），要么另开一条客户端手动核查项；同时把 `ColonyRegistry.java:25` SavedData 名为字面量 `folkways_colonies` 这条证据补进 §3"存档无影响"的依据 |
| R1-09 | 建议 | §2.1、§2.3 | §7 已写"全部裁决"，但 §2.1 `gradle.properties:3` 仍是"**待人类定**"、§2.3 `displayName` 等仍是"**待人类定文案**"，实现者会看到两种状态 | §2.1/§2.3 直接填 §7 的裁决值（`io.github.tcch1111`、`Per Lapidem ad Astra · Core` 等），`issueTrackerURL` 在四份 toml 的 `:4` 顶层、`displayURL` 在 `:10` |
| R1-10 | 建议 | §2.2 核心行 | "12 个 gametest 的 `@EventBusSubscriber(modid = FolkwaysMod.CORE_ID)`"数字错：12 是 **main** 侧（`Invitations`、`CurrentColony`、`ColonyBookKeeping`、`FolkwaysUiNetworkEvents`、`front/client/*` 8 个）；core 的 gametest 侧有 30+ 处。§2.5 的表述（main 12 + gametest 若干）才对 | 改为"main 12 处 + gametest 侧若干处自动跟随"，与 §2.5 一致 |
| R1-11 | 建议 | §2.5 "CI 不受影响" | `.github/workflows/build.yml:60-61` 的 nightly 发布说明含 `folkways-core`/`folkways-vanilla`/`folkways-create`/`folkways-modulargolems` 字面量、`:32`/`:48` 工件名 `folkways-jars`；nightly job 以 `refs/heads/master` 为门（`:37`），我们的分支是 `main`，所以**功能上**确实不受影响，但"不受影响"应说明理由而不是省略 | §2.5 补一句："`.github/workflows/build.yml` 含上游产物名文案，但 nightly 只在 `master` 触发，B-2 不改；CI 改造另列" |
| R1-12 | 建议 | §6 T1 文件位置 | `tests/mods-toml.test.ts` 放在 `tests/` 顶层：`package.json:9` 的 `tests/**/*.test.ts` 能跑到它，但 `package.json:8` 的 `typecheck` 只覆盖 `tests/{e2e,sable,visual,ponder,pattern,bench,promo,i18n}` 八个 tsconfig，顶层文件不会被 `tsc` 检查；T6 的"typecheck 绿"对它无意义。可行性本身没问题：无 TOML 库时用正则取 `ext.modId` 与 `[[dependencies.*]]` 段即可，`tests/i18n/lang.test.ts:1-28` 就是同样手法；WSL Node 22.23.3 支持 `--experimental-strip-types` | 放到已有 tsconfig 覆盖的目录（如 `tests/i18n/` 改名为 `tests/i18n/mods-toml.test.ts`，或新建 `tests/build/` + tsconfig 并加入 `typecheck`） |
| R1-13 | 建议 | §6 T2 | "`build/libs/` 恰有四个 jar（+ `-sources`）"：根 `build/libs` 由 `build.gradle:90-93` 的 `collectJars` 只拷各子项目 `jar` 任务输出，`sourcesJar` 落在 `mods/<name>/build/libs/`；w06 §1.3 B-4 记录也只列了四个主 jar。`-sources` 是否出现在根目录没有实证 | 把 `+ -sources` 从硬判定里拿掉，或改为"子项目 `build/libs/` 各有一份 `-sources`" |
| R1-14 | 建议 | §5 标记约定 | `PLA:` 标记只定了 Java/TS/Gradle（`// PLA:`）与 TOML（`# PLA:`），`README.md`/`CONTRIBUTING.md` 没定（Markdown 需 `<!-- PLA: ... -->`）；w06 §6.2 S6 的定位命令是 `git grep "// PLA:"`，会漏掉 `# PLA:` 与 Markdown 标记 | 补 Markdown 形式；建议统一用 `git grep "PLA: ADR-023"`，并在 d12 §5.1 登记时注明每个文件的标记形式 |
| R1-15 | 建议 | §1 禁止事项 / §7 | ADR-023 ② 把"是否同步升级 NeoForge 到 21.1.264"留到 B-2 时按 R-BLD-1 单独提交；本计划 T4/T5 用 21.1.264 服务端、构建仍是 21.1.233，但正文没有一句话说明 B-2 **不动** `gradle.properties:7/9` | 在 §1 禁止事项或 §7 明确："本计划不改 `neoforge_version`/`neoforge_requirement`，升级另开提交" |
| R1-16 | 建议 | §7 末段 / §8 | 改名后整合包（ADR-022 ②：当前钉的是上游 nightly `folkways-*` jar）何时换成 `plaa-*` jar 没有交代；k00 §7 说"fork 产出首个 jar 后替换"，B-2 正是那一刻 | §8 加一步"后续"：通知 pack 侧把 `pack/mods/folkways-*.pw.toml` 换为 fork 产物（不在本计划内做，但要写明归属） |
| R1-17 | 建议 | §2.3 reason 文案 | `reason` 是中文；该文本会出现在任何语言玩家的 FML 错误页与上游用户的报错截图里 | 用英文或中英双语，例如 `Per Lapidem ad Astra is a fork of Folkways; the two cannot share a world (one colony system). / …` |

**总体结论**：**可进入第 2 轮**，不需大改。事实核对有 1 处不符（R1-02 `gradle/mod.gradle` 行号）与 3 处过期基线引用（R1-04）；机制层面无臆造 API、无不存在的文件；唯一阻塞项是 T1 自相矛盾（R1-01），改成结构化断言即可。第 2 轮前请至少处理 R1-01～R1-08。

## 11. 评审记录 · 第 2 轮（2026-10-19，审查者）

> 只读复核。所有 `文件:行号` 再次在 `reference/folkways-3ce4d88/` 上打开核对；w06 / k00 / tools 的引用在 `docs/workflow/06-build-and-ci.md`、`docs/pack/00-pack-spec.md`、`tools/wsl-run.sh`、`pack/mods/` 上核对。

### 11.1 第 1 轮 17 条复核

| R1 编号 | 结论 | 证据（正文现句 / 快照核对） |
| --- | --- | --- |
| R1-01 | **已修** | T1 ②："**所有 `type != "incompatible"` 的依赖段** `modId` 不含 `folkways_*`，且每份恰含 4 段 `type = "incompatible"` 分别指向四个 `folkways_*`"；T1 ③ 扫描范围为 `mods/**/*.java`、`*.gradle`、`blockwright.toml`、`tests/shared/**/*.ts`，并明写"`neoforge.mods.toml` 不在此项，由 ② 覆盖"——toml 没有被扫回来。快照 Grep（排除 `neoforge.mods.toml`）命中的 `folkways_(core\|…)` 字面量只在：4 个 `mods/*/build.gradle:7`、4 个主类常量行、根 `build.gradle:8-11`、`blockwright.toml:16-26/153`、`mod-settings.ts:39-40`、`README.md:109`、`CONTRIBUTING.md:31-34`——全在 §2 改动表内或 ③ 的除外名单内，改完后 ③ 必绿。测试文件自身（`tests/i18n/`）不在 ③ 范围，正则字面量不会自触发 |
| R1-02 | **已修** | 快照 `gradle/mod.gradle`：`tasks.named("jar", Jar) { … }` 为 `:55-60` ✓；`def expanded = [ … ]` 为 `:67-74` ✓；`processResources { … }` 为 `:76-81` ✓；`base { archivesName … }` 为 `:6-8` ✓；`lib()` 的 `:39-47`（`modsManifest` 在 `:39`，闭包 `:41-47`）✓。正文 §2.1、§2.5、§7 OQ-P1-4 三处均已改为上述数字 |
| R1-03 | **已修** | §2.4 `mod-settings.ts` 行末尾与 §3 新增"客户端配置文件名"行，均引 `FolkwaysMod.java:71`（快照该行确为 `container.registerConfig(ModConfig.Type.CLIENT, FolkwaysClientConfig.SPEC);`）；并注明"专用服务端测不到，不作 T 判据，客户端实例手动核一次" |
| R1-04 | **已修** | Grep 正文（§10 以外）`67f28b0` 仅命中首页"上游依据"里的文件名 `docs/research/10-upstream-delta-f42e3c1-67f28b0.md`（合法引用）。§1 失败回退 = `git checkout upstream-base-3ce4d88-20261019 -- <文件>`；§2 标题 = "基于 `reference/folkways-3ce4d88/`"；§2.4 NOTICE = "基线 `3ce4d88`（标签 `upstream-base-3ce4d88-20261019`）" |
| R1-05 | **已修** | §2.6 清单 20 个逐一对账：§2.1 → `build.gradle`、`settings.gradle`、`gradle.properties`、`gradle/mod.gradle`、4×`mods/*/build.gradle`（8）；§2.2 → 4 个主类（12）；§2.3 → 4 份 toml（16）；§2.4 → `blockwright.toml`、`mod-settings.ts`、`README.md`、`CONTRIBUTING.md`（20）。无多无少。§1 "§2.6 清单的 **20 个既有文件** + 2 个新文件"、§8 步骤 3 "改 20 个文件 + 新建 `NOTICE.md`"（测试文件在步骤 2 建）三处一致 |
| R1-06 | **已修** | w06 §1.3 `:96-98` 已有 3ce4d88 三行：build 通过；gametest 第 1 次"651 个测试，1 失败"（`onefoodcannotfeedhalfofapair`）、第 2 次"651/651"，并写明"基线判据：651 个测试，允许该测试偶发失败、重跑即过"。T3 正文："651 个测试全部通过 … 第 1 次 650/651、第 2 次 651/651 … 若失败，重跑一次即过则视为通过；其他任何失败都是回归"——与 w06 一致。`PastureBreedingGameTests.java:137` 确为 `oneFoodCannotFeedHalfOfAPair` 方法行 ✓ |
| R1-07 | **已修** | T5："两条硬判据——① 服务端未到 `Done (` … ② `logs/latest.log` 含 `Mod plaa_core is incompatible with folkways_core` … `reason` 文本是否出现只记录、不作判定" |
| R1-08 | **已修** | §3 `level.dat` 行拆为"服务端 … 只打日志，不阻塞（T4 可测）"与"客户端 … T4 测不到，另列手动核查项"；§3 存档行补入 `ColonyRegistry.java:25` 字面量 `"folkways_colonies"`——快照该行为 `private static final String DATA_NAME = "folkways_colonies";` ✓ |
| R1-09 | **已修** | §2.1 `gradle.properties:3` → `io.github.tcch1111`；§2.3 末行填入 `displayName` / `displayURL` / `authors` / `issueTrackerURL` 具体值。快照四份 toml：`issueTrackerURL` 在 `:4`、`displayName :9`、`displayURL :10`、`authors :12` ✓ |
| R1-10 | **已修** | §2.2 核心行："main 侧 12 处 + gametest 侧若干处 `@EventBusSubscriber(modid = FolkwaysMod.CORE_ID)` 自动跟随"；快照 `mods/**/src/main/**/*.java` Grep 恰 12 处 ✓ |
| R1-11 | **已修** | §2.5 末句引 `build.yml:32/48/60-61` 与 `:37` 的 `refs/heads/master` 门；快照核对四个行号均正确 |
| R1-12 | **已修** | 测试文件改为 `tests/i18n/mods-toml.test.ts`；快照 `tests/i18n/tsconfig.json` 的 `include = ["**/*.ts"]`，`package.json:8` 的 `typecheck` 含 `tsc -p tests/i18n` ✓；`package.json:9` 的 `tests/**/*.test.ts` 通配能跑到 ✓ |
| R1-13 | **已修** | T2："无 `folkways-*.jar`（`-sources` 落在各子项目 `mods/<name>/build/libs/`，不作根目录判据）" |
| R1-14 | **已修** | §5 补 Markdown 形式 `<!-- PLA: ADR-023 modid -->`，定位命令 `git grep "PLA: ADR-023"`，要求登记表注明标记形式。但括号内对 w06 的描述已过期，见 R2-05 |
| R1-15 | **已修** | §1 禁止事项："改 `gradle.properties` 的 `neoforge_version` / `neoforge_requirement`（NeoForge 升级按 R-BLD-1 另开提交）"；§2.1 行注"**不动** `:7` … `:9`"。快照 `gradle.properties:7` = `neoforge_version=21.1.233`、`:9` = `neoforge_requirement=[21.1.233,)` ✓ |
| R1-16 | **已修**（事实过期） | §7 末段"后续归属"已加；但"届时一并加 `plaa-modulargolems` 与 Modular Golems 本体"与 `pack/mods/` 现状不符，见 R2-04 |
| R1-17 | **已修** | §2.3 `reason` 为英文在前、中文在后的双语文本 |

**计数**：已修 17 / 未修 0 / 修错 0；其中 R1-14、R1-16 的修订引入了两处过期事实（R2-04、R2-05）。

### 11.2 本轮新问题

| 编号 | 严重度 | 位置 | 问题与证据 | 修复建议 |
| --- | --- | --- | --- | --- |
| R2-01 | **应改** | §8 步骤 4、§1 自测命令 | 步骤 4 写"`wsl-run.sh build` → T1/T2/T6 绿"，但 `tools/wsl-run.sh:46-53` 的 `build` 阶段只做 `npm ci` → `npm run setup` → `./gradlew build` → `ls build/libs`，**不跑** `npm run typecheck` / `test:unit` / `test:i18n`（上游 CI `build.yml:28-29` 才跑）。T1（`test:unit`）和 T6（`typecheck` + `test:i18n`）没有执行路径；Windows 侧能否跑 `test:unit` 按 w06 R-BLD-17 ⚠️ 仍"待验证"，不能默认 | 步骤 4 拆成两句：`wsl-run.sh build` → T2；层 0 三条命令在 WSL `~/pla/mod` 内单独执行（或先给 `tools/wsl-run.sh` 加一个 `unit` 阶段——这属工作区根仓库 `chore`，不在本计划 20 文件内，需人类点头）。§1 自测命令同步注明"在 WSL 内" |
| R2-02 | **应改** | §6 T4、T5 | "本机 `.cache/test-server/`（NeoForge 21.1.264）**只放** `plaa-core`…" ——该目录正是 k00 §10.1 v5 的整合包冒烟实例（44 个 mod，`Done (2.468s)`），"只放"等于清空它，会毁掉整合包侧的复验环境；且 T4/T5 没说 jar 从哪取（build 在 WSL `~/pla/mod/build/libs/`，Windows 侧无 `mod/`）、上游 `folkways-core` nightly jar 从哪取（其实已在该目录 `mods/` 内，由 packwiz 钉到 e5b6838） | 改为另建 `.cache/test-server-b2/`（复制 `libraries/`、`user_jvm_args.txt`、`eula.txt`，`mods/` 只放最小集合），或先把现有 `mods/` 整目录备份再还原；写明取 jar 路径：`\\wsl.localhost\Ubuntu-24.04\home\<user>\pla\mod\build\libs\` 与上游 jar 来源 `.cache/test-server/mods/folkways-core-neoforge-1.21.1-0.1.0.jar` |
| R2-03 | **应改** | 首页"事实快照"、§8 步骤 1 | 全文 `文件:行号` 基于只读快照 `reference/folkways-3ce4d88/`，而真正要改的工作树在 WSL `~/pla/mod`（Windows 侧 `mod/` 已删，`tools/wsl-run.sh:36-40`）。计划没有一句话说"改哪棵树、怎么访问"，实现 agent 在 Windows 用 Edit 工具时最顺手的目标恰是 `reference/…`，有误改快照的风险；"允许触碰"硬边界也没说快照本身属禁区 | 首页加一行："改动目标 = WSL `~/pla/mod`（从 Windows 经 `\\wsl.localhost\Ubuntu-24.04\home\<user>\pla\mod\` 访问）；`reference/folkways-3ce4d88/` 只读，禁止改动"；§1 禁止事项补"改 `reference/**`" |
| R2-04 | 建议 | §7 末段（R1-16 修订） | "把 `pack/mods/folkways-{core,vanilla,create}.pw.toml` 换成 … 届时一并加 `plaa-modulargolems` 与 Modular Golems 本体"——`pack/mods/` 现已有 `folkways-modulargolems.pw.toml`、`modular-golems.pw.toml`、`l2library.pw.toml`（k00 §10.1 v5：44 个条目、四 jar 全装、`Done (2.468s)`） | 改为"把 `pack/mods/folkways-{core,vanilla,create,modulargolems}.pw.toml` 四个全部换成 fork 产物"，删掉"一并加"的半句 |
| R2-05 | 建议 | §5、§1 图层 | §5 括号："不是 w06 §6.2 写的 `// PLA:`，那会漏掉 `#` 与 Markdown 形式——w06 待同步改"——w06 `:508` S6 **已经**改为 `git grep "PLA: ADR-"` 并列出三种形式（注明来源 PLAN-001 R1-14），这句已过期；两条命令兼容（`PLA: ADR-023` ⊂ `PLA: ADR-`）但读者会以为 w06 还没改。§1 图层仍只写 `// PLA:` / `# PLA:` 两种形式 | §5 括号改为"与 w06 §6.2 S6 的 `git grep "PLA: ADR-"` 兼容"；§1 图层补 Markdown 形式或直接"标记形式见 §5" |
| R2-06 | 建议 | §6 T1 ③ | 扫描范围写 `*.gradle`，未说明是否递归。实际两种读法结果相同（根目录 `build.gradle:8-11` 有 4 个键；`settings.gradle`、`gradle/mod.gradle` 无字面量；`mods/*/build.gradle` 由 ① 覆盖），但测试代码要落成具体 glob | 写成 `**/*.gradle`（排除 `build/`、`node_modules/`）以免歧义 |
| R2-07 | 建议 | §6 T4 | ① "`create`（folkways_create 需要）"应为 `plaa_create`（改名后的 modid；快照 `mods/create/.../neoforge.mods.toml:44-50` 对 `create [6.0.0,)` 为 `required`）；② 这套"三 jar + ldlib2 + create"最小集合从未在**未改动基线**上跑过（k00 v4/v5 都是全包），T4 一旦不到 `Done (` 无法区分是 modid 改坏了还是最小集合本身缺东西，而 §1 失败回退只对 T3 写了归因规则 | 在 T4 前加一步"对照：用上游 `folkways-{core,vanilla,create}` 三 jar 跑同一最小集合，须先到 `Done (`"；T4 失败时按对照结果归因 |
| R2-08 | 建议 | §5 首句 | "全部 L2 改动都是**单行字面量替换**"不准确：四份 toml 各新增 4 段 × 7 行（§2.3）、`gradle/mod.gradle:55-60` 块内新增一个多行 `from(...)`、README 顶部新增 fork 声明段。冲突形态评估（"上游改 toml 结构时需手工合并"）仍成立，只是措辞要诚实 | 改为"除 toml 新增段、`mod.gradle` 的 NOTICE 块与 README 声明段外，其余均为单行字面量替换" |
| R2-09 | 建议 | §2.4 NOTICE.md、§2.3、§6 T2 | 根 `build.gradle:105-128` 的 `lintScaffold` 扫 `**/*.md`、`**/*.toml`、`**/*.gradle`（Tab / 行尾空白即失败），新建的 `NOTICE.md`、README 新段、toml 新段都在其内；计划没提醒。T2 的 `check` 会抓到，但晚于写文件 | §2.4 NOTICE 行或 §8 步骤 3 加一句"新写的 md/toml 不得含 Tab 与行尾空白（`lintScaffold`）" |

### 11.3 可执行性终审

实现 agent 拿到现稿，**技术内容**已足够开工：每个改动有 `文件:行号`、现值、目标值；裁决值（maven_group、displayName、URL、rootProject.name、NOTICE 入 jar）已填；T1–T6 判据可观察；回退命令与基线标签正确。**仍需规划者补的空白**（均为流程/环境信息，不是设计问题）：

1. 在哪棵工作树上改、怎么访问（R2-03）。
2. 层 0 三条 npm 命令在何处、怎样执行（R2-01）。
3. T4/T5 的实例目录与 jar 取用路径（R2-02）。
4. （可选）T4 最小集合的基线对照（R2-07）。

其余 R2-04～R2-09 为措辞/过期事实，实现时不会造成偏差。

**总体结论**：**可交人类确认**——R1 的 17 条全部修到位，无阻塞、无机制性错误；R2-01～R2-03 三条"应改"是执行环境的空白，由规划者补三句话即可，不需要第 3 轮审查。
