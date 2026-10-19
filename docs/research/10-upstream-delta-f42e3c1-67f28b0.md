# 上游差异：f42e3c1 → 67f28b0（整树重构的路径与行号迁移）

```
状态：调研产出
负责人：调研者（agent）
最后更新：2026-10-19
上游依据：reference/README.md、docs/design/12-fork-strategy.md §4、docs/00-charter.md ADR-021
```

> **范围**：只读调研。比较两份只读快照——旧 `reference/folkways-master/`（上游 `f42e3c1`，2026-10-17，单 jar 结构）与新 `reference/folkways-67f28b0/`（上游 `67f28b0`，由 `git archive` 解出，含 `8fa9029`、`0af84f0`、`67f28b0` 三个提交）。**本文不改任何既有文档**，只给出迁移表与失效清单。
>
> **约定**：
> - 下文「旧」= `reference/folkways-master/`，「新」= `reference/folkways-67f28b0/`；表内路径均省略该前缀。
> - `J/` = `src/main/java/io/github/izakyl/folkways/`，`GT/` = `src/gametest/java/io/github/izakyl/folkways/`（仅用于「旧」路径的缩写；「新」路径一律写全）。
> - 每条事实带 `文件:行号`；**推断一律标 ⚠️**，不当作事实。
> - 行号核对方法：对每条引用，取旧文件被引行与新文件逐行比对（Python `difflib.SequenceMatcher`，整行相等才算匹配），再对新文件按行号回读确认；行内容有变化的人工打开新文件判读后归入「已改写」。
> - **扫描时点**：8 份被扫描文档的 mtime 为 d12 10-19 14:23、r01 10-17 22:40、r02 10-18 15:39、r03 10-17 23:13、r04 10-17 23:07、r05 10-18 15:39、w05 10-18 19:39、w06 10-19 15:09（w06 在调研期间被改过两次，14:34 与 15:09，第二次在中段插入了约 26 行 WSL 内容；§4 与 §5 的 w06 行号均按 15:09 版本重新生成；其余 7 份未再变动。之后若被修改，§4 的「所在行号」会漂移，以「原引用」文本为准）。

## 提交与工作量速览

| 指标 | 旧 | 新 | 证据 |
| --- | --- | --- | --- |
| Gradle 工程数 | 1（`rootProject.name = "folkways"`） | 根 + 4 个子项目（`:core :vanilla :create :modulargolems`） | 旧 `settings.gradle:18`；新 `settings.gradle:21-24` |
| 产出的 mod jar | 1 | 4（根不再出 jar） | 新 `build.gradle:5`、`:85-87`、`:90-93` |
| modid | `folkways`（`mod_id=folkways`） | `folkways_core` / `folkways_vanilla` / `folkways_create` / `folkways_modulargolems`；资源命名空间仍是 `folkways` | 旧 `gradle.properties:23`；新 `mods/core/build.gradle:7`、`mods/vanilla/build.gradle:7`、`mods/create/build.gradle:7`、`mods/modulargolems/build.gradle:7`；新 `mods/core/src/main/java/io/github/izakyl/folkways/FolkwaysMod.java:59-63` |
| `src/main` .java 总数 | 840 | 858（core 467 + vanilla 285 + create 92 + modulargolems 14） | 目录计数（`find … -name "*.java"`） |
| gametest .java | 85 | 87（core 40 + vanilla 41 + create 6 + modulargolems 0） | 同上 |
| `@GameTest` 出现次数 | 488 | 496 | `grep -rE "@GameTest"` 计数 ⚠️（口径与 r05 旧值 488 一致，故可比） |
| `tests/` 下 .ts | 182 | 176（`tests/fuzz/` 的 24 个文件整体删除，新增 1 个 e2e spec） | 目录计数；旧 `tests/fuzz/` |
| e2e spec | 44 | 45（新增 `tests/e2e/block-sweep-blackbox.spec.ts`） | 目录计数 |
| lang 文件行数（每个 json） | 896 | 932 | 旧 `src/main/resources/assets/folkways/lang/en_us.json`；新 `mods/core/src/main/resources/assets/folkways/lang/en_us.json` |

三个提交的内容（按本次比对所见，非提交信息复述）：
- `8fa9029`（bench 拒绝表）：新 `tests/bench/report/judgements.ts:224` 的 `NEVER_HERE` 增加 `"OFF_CHAIN", "CHAIN_ELSEWHERE"`；`tests/bench/report/refusal-coverage.test.ts`、`tests/i18n/lang.test.ts` 随之变化。「覆盖检查不上 CI」的具体含义本文未逐行验证 ⚠️（新 `.github/workflows/build.yml:28-29` 仍只有 `npm run typecheck`、`npm run test:unit`）。
- `0af84f0`（四模块）：本文 §1–§3。
- `67f28b0`（stalls / 拱桥）：新增 `Stall`/`Stalls`/`ColonyStalls`、`BlockSweep`/`SweepOffer`/`SweepBlocksPacket`；拱桥相关改动可见 `tests/visual/patterns/arch-bridge/BridgeGallery.java`、`tests/visual/patterns.spec.ts`（两文件内容在两快照间不同）。图案 `.star` 本身未做逐行比对 ⚠️。

---

## 1. 结构变化总表

### 1.1 五组目录级映射（旧路径 → 新路径）

#### (a) `src/main/java`

| 旧路径 | 新路径 | 文件数（旧→新） | 说明 |
| --- | --- | --- | --- |
| `J/FolkwaysMod.java`、`J/FolkwaysConfig.java` | `mods/core/src/main/java/io/github/izakyl/folkways/FolkwaysMod.java`、`…/FolkwaysConfig.java` | 2→2 | 配置类被拆成三份，见 §1.4 |
| `J/core/api/**`（除下列迁出者） | `mods/core/src/main/java/io/github/izakyl/folkways/core/api/**` | 124→113 | 少 12 个是迁出；多 1 个 `core/api/work/Stall.java` |
| `J/core/api/perk/*`（4 个） | `mods/core/…/effect/perk/*`（GlobalPerks、Perk、PerkPool、Perks） | 4→4 | 新增 `effect/` 层：`Effects`、`Flag`、`Modifier`、`Scope`、`Stat`、`Stats`（6 个新文件，新 `mods/core/src/main/java/io/github/izakyl/folkways/effect/`） |
| `J/core/api/library/*`（3 个） | `mods/core/…/library/*`（LibraryCommand、LooseFolder、Shelves） | 3→3 | 提交说明「effects and the library leave core」 |
| `J/core/api/persist/*`（3 个）、`J/core/api/Ledger.java`、`J/core/api/FolkwaysMixinPlugin.java` | `mods/core/…/base/persist/*`、`…/base/Ledger.java`、`…/base/FolkwaysMixinPlugin.java` | 5→5 | 「what every layer stands on」；新 `CONTRIBUTING.md:42` |
| `J/core/engine/**` | `mods/core/…/core/engine/**` | 128→129 | 多 1 个 `core/engine/labor/Stalls.java` |
| `J/core/shell/**` | `mods/core/…/core/shell/**` | 9→10 | 并入 `SablePassage`（来自旧 `plugins/sable/`），见 §1.3 |
| `J/front/**` | `mods/core/…/front/**` | 191→195 | 新增 `front/client/SweepOffer.java`、`front/engine/colony/BlockSweep.java`、`front/engine/colony/ColonyStalls.java`、`front/engine/net/SweepBlocksPacket.java` |
| `J/plugins/{build,farming,fishing,groundwork,orders,pasture,patrol,person,wares}/**` 与 `J/plugins/BuiltinPlugins.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/…`（同相对路径） | 见 §1.3 | 其中 `build/` 的 6 个 Create 相关文件改去 create |
| `J/plugins/{dispatch,rail}/**`、`J/plugins/CreateMod.java`、`J/plugins/build/Create*.java`（5 个）、`J/plugins/build/mixin/ToolTypeMixin.java` | `mods/create/src/main/java/io/github/izakyl/folkways/create/{dispatch,rail,CreateMod.java,build/…}` | 见 §1.3 | |
| `J/plugins/golem/**` | `mods/modulargolems/src/main/java/io/github/izakyl/folkways/modulargolems/**` | 13→13 | 去掉 `golem/` 一级，`domain/`、`resident/` 上提 |
| `J/plugins/sable/{SablePassage,SablePlugin}.java` | `SablePassage` → `mods/core/…/core/shell/structure/SablePassage.java`；`SablePlugin.java` **已删除** | 2→1 | 见 §1.3 |
| （无） | `mods/vanilla/…/plugins/{FolkwaysVanillaConfig,FolkwaysVanillaMod}.java`；`mods/create/…/create/{CreatePlugins,FolkwaysCreateConfig,FolkwaysCreateMod}.java` 与 `create/build/CreateBuildPlugin.java`、`create/build/mixin/CreateBuildMixinPlugin.java`；`mods/modulargolems/…/modulargolems/FolkwaysModularGolemsMod.java` | 新增 8 | 各子项目的 `@Mod` 入口与配置 |

#### (b) `src/gametest`

| 旧路径 | 新路径 | 文件数 | 说明 |
| --- | --- | --- | --- |
| `GT/ExtensionGameTests.java`、`GT/core/**`、`GT/front/**` | `mods/core/src/gametest/java/io/github/izakyl/folkways/…`（同相对路径） | 38→40 | 另新增 `effect/EffectsGameTests.java`、`core/engine/labor/StallsGameTests.java` |
| `GT/plugins/{build,farming,groundwork,orders,pasture,patrol,person,wares}/**` | `mods/vanilla/src/gametest/java/io/github/izakyl/folkways/plugins/…` | 41→41 | `plugins/build/CreateJointGameTests.java` 仍在 vanilla（靠 `gametestCompileOnly lib("create")`，新 `mods/vanilla/build.gradle:32-34`） |
| `GT/plugins/{dispatch,rail}/**` | `mods/create/src/gametest/java/io/github/izakyl/folkways/create/{dispatch,rail}/…` | 6→6 | |
| `src/gametest/resources/data/folkways/folkways/{blueprint,pattern}/*` | `mods/vanilla/src/gametest/resources/data/folkways/folkways/…` | 3→3 | |
| （无） | `mods/modulargolems` 没有 `src/gametest` 目录 | — | 目录列表确认 |

#### (c) `src/main/resources`

| 旧路径 | 新路径 | 说明 |
| --- | --- | --- |
| `src/main/resources/assets/folkways/**`（lang/lss/models/textures/animations） | `mods/core/src/main/resources/assets/folkways/**` | 全部在 core；四个 lang 各 932 行 |
| `src/main/resources/data/folkways/{advancement,recipe,structure}/**` | `mods/core/src/main/resources/data/folkways/{advancement,recipe,structure}/**` | 4 个文件 |
| `src/main/resources/data/folkways/folkways/**`（pattern、piece、resident_look、resident_look_set、resident_name）、`data/folkways/tags/**` | `mods/vanilla/src/main/resources/data/folkways/{folkways,tags}/**` | 37 个文件；内置图案现在随 vanilla（新 `README.md:31`、`CONTRIBUTING.md:50`） |
| `src/main/resources/data/create/tags/entity_type/ignore_seat.json` | `mods/create/src/main/resources/data/create/tags/entity_type/ignore_seat.json` | |
| `src/main/resources/folkways.mixins.json`、`folkways-optional.mixins.json`、`folkways-front.mixins.json`、`folkways-desk.mixins.json` | `mods/core/src/main/resources/` 同名（内容相同） | 逐文件 `diff` 无差异 |
| `src/main/resources/folkways-person.mixins.json`、`folkways-wares.mixins.json` | `mods/vanilla/src/main/resources/` 同名（内容相同） | |
| `src/main/resources/folkways-build.mixins.json` | `mods/vanilla/src/main/resources/folkways-build.mixins.json`（去掉 `plugin` 与 `client: ToolTypeMixin`）＋ `mods/create/src/main/resources/folkways-create-build.mixins.json`（新增，带 `plugin: …CreateBuildMixinPlugin` 与 `client: ToolTypeMixin`） | 拆分：vanilla 保留 `GrowingPlantBlockAccess`，Create 部分移走 |
| `src/main/resources/folkways-rail.mixins.json`、`folkways-dispatch.mixins.json` | `mods/create/src/main/resources/` 同名 | 仅 `package`/`plugin` 由 `…plugins.{rail.domain,dispatch}.mixin` 改为 `…create.{rail.domain,dispatch}.mixin` |
| `src/main/resources/META-INF/neoforge.mods.toml` | 4 份：`mods/{core,vanilla,create,modulargolems}/src/main/resources/META-INF/neoforge.mods.toml` | 见 §3 |
| `src/main/resources/META-INF/licenses/{Flywheel,Ponder,Starlark}-LICENSE.txt` | Flywheel、Ponder → core；Starlark → vanilla | 随各自 jarJar 的 jar 走（§2） |

#### (d) `tests/`

| 旧 | 新 | 说明 |
| --- | --- | --- |
| `tests/{bench,e2e,i18n,ldlib2,promo,shared,visual}/**` | 同路径 | 路径不变；有 21 个文件内容改变（`diff -rq`）：`bench/report/{judgements.ts,refusal-coverage.test.ts}`、`bench/town/{raise.ts,town-cache.ts}`、`e2e/{dispatch-mail-blackbox,library-folder,perk-blackbox,rail-map}.spec.ts`、`i18n/lang.test.ts`、`promo/{logistics.take.ts,overhead-view.ts}`、`shared/colony/{integration-tasks.ts,sable-probe.ts}`、`shared/harness/{budgets.ts,mod-settings.ts,out-paths.ts}`、`shared/rail/rail-drawn.ts`、`visual/patterns.spec.ts`、`visual/patterns/arch-bridge/BridgeGallery.java` |
| `tests/fuzz/**`（24 个文件：`build.fuzz.ts`、`campaign.ts`、`economy.fuzz.ts`、`fuzz-kit.ts`、`global-setup.ts`、`paths.fuzz.ts`、`playwright.config.ts`、`tsconfig.json`、`java/…`） | **已删除** | 新 `tests/` 下无 `fuzz`；新 `package.json:8` 的 typecheck 不含 `tests/fuzz`；无 `fuzz:run` |
| （无） | `tests/e2e/block-sweep-blackbox.spec.ts` | 新增，对应 `BlockSweep` |
| 测试里写死的类名 | `tests/shared/colony/integration-tasks.ts:16-18`：`io.github.izakyl.folkways.plugins.dispatch.*` → `io.github.izakyl.folkways.create.dispatch.*` | 由内容比对得出 |
| 测试种入的配置 | 旧 `config/folkways-server.toml` → 新 `config/folkways_vanilla-server.toml` + `config/folkways_core-server.toml` | 新 `tests/shared/harness/mod-settings.ts:36-40` |
| 预算表 | 旧 `tests/shared/harness/budgets.ts` 有 `fuzz: 10 * MINUTES`（旧 `:11-12`）→ 新无 | 内容比对 |

#### (e) 构建脚本与仓库根文件

| 旧 | 新 | 说明 |
| --- | --- | --- |
| `build.gradle`（266 行） | `build.gradle`（133 行，只做聚合）＋ `gradle/mod.gradle`（96 行，各 mod 共用）＋ `mods/core/build.gradle`（50 行）＋ `mods/vanilla/build.gradle`（35 行）＋ `mods/create/build.gradle`（23 行）＋ `mods/modulargolems/build.gradle`（18 行） | 详见 §2 |
| `settings.gradle`（18 行） | `settings.gradle`（24 行；`:20-24` 新增四个 `include`） | 新 `settings.gradle:20-24` |
| `gradle.properties`（20 行，含 `archives_base_name`、`mod_id`） | `gradle.properties`（18 行；这两项已删除） | 旧 `gradle.properties:4-5`；新 `gradle.properties:1-18` |
| `blockwright.toml`（312 行） | `blockwright.toml`（310 行） | `[mods.folkways]` → 四个 `[mods.folkways_*]`；`[profile.fuzz]` 删除 |
| `package.json`（31 行） | `package.json`（31 行） | typecheck 去 fuzz（`:8`）；`fuzz:run` → `promo:take`（`:18`） |
| `.github/workflows/build.yml`（59 行） | `.github/workflows/build.yml`（65 行） | 步骤不变；产物名、nightly 说明变 |
| `.github/ISSUE_TEMPLATE/bug_report.yml` | 同路径 | `:16-17` 改为「Name each Folkways jar you have installed」 |
| `.gitignore` | 同路径 | 新增 `/mods/*/.gradle/`（新 `.gitignore:2`）、`/mods/*/build/`（新 `.gitignore:4`）；旧 `.gitignore:34-35` → 新 `.gitignore:36-37` |
| `CONTRIBUTING.md`（103 行）、`README.md`（129 行） | 同路径（121 行、138 行） | 见 §2 |

### 1.2 四个子项目的顶层包与 `plugins/` 子目录

包根均为 `src/main/java/io/github/izakyl/folkways/`。各子项目只占自己的顶层包，**未见跨 jar 的同名包**（目录列表确认；⚠️ 未用工具验证 split-package）。

| 子项目 | `io/github/izakyl/folkways/` 下的顶层包与根类 | 规模 | 来源 |
| --- | --- | --- | --- |
| `mods/core`（modid `folkways_core`） | 根类 `FolkwaysMod`、`FolkwaysConfig`；包 `base`（`Ledger`、`FolkwaysMixinPlugin`、`persist/`）、`core`（`api/`、`engine/`、`shell/`）、`effect`（`Effects`、`Flag`、`Modifier`、`Scope`、`Stat`、`Stats`、`perk/`）、`front`（`api/`、`client/`、`engine/`、`ui/`）、`library`（`LibraryCommand`、`LooseFolder`、`Shelves`） | main 467 / gametest 40 | 新 `CONTRIBUTING.md:42-46`；目录列表 |
| `mods/vanilla`（`folkways_vanilla`） | 仅包 `plugins`：根类 `BuiltinPlugins`、`FolkwaysVanillaConfig`、`FolkwaysVanillaMod`；子目录 `build`(105)、`farming`(19)、`fishing`(8)、`groundwork`(13)、`orders`(8)、`pasture`(21)、`patrol`(8)、`person`(68)、`wares`(32) | main 285 / gametest 41 | 括号内为 .java 数；新 `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/BuiltinPlugins.java:20-30` 只装这 9 个 |
| `mods/create`（`folkways_create`） | 仅包 `create`：根类 `CreateMod`、`CreatePlugins`、`FolkwaysCreateConfig`、`FolkwaysCreateMod`；子目录 `build`(8)、`dispatch`(39)、`rail`(41)；**没有 `plugins/` 目录** | main 92 / gametest 6 | 新 `mods/create/src/main/java/io/github/izakyl/folkways/create/CreatePlugins.java:14-18` 装 `CreateBuildPlugin`、`RailPlugin`、`DispatchPlugin` |
| `mods/modulargolems`（`folkways_modulargolems`） | 仅包 `modulargolems`：根类 `FolkwaysModularGolemsMod`、`GolemPlugin`、`GolemScene`；子目录 `domain`(4)、`resident`(7)；**没有 `plugins/` 目录** | main 14 / gametest 0 | 新 `mods/modulargolems/src/main/java/io/github/izakyl/folkways/modulargolems/FolkwaysModularGolemsMod.java:11-13` 直接 `GolemPlugin.install(modBus)` |

### 1.3 旧 `plugins/` 各项的去向

| 旧 `J/plugins/…` | 新位置 | 说明 |
| --- | --- | --- |
| `build/`（旧 112 个 .java） | `mods/vanilla/…/plugins/build/`（105）＋ `mods/create/…/create/build/`（旧 6 个：`CreateBlueprintHandoff`、`CreateHandoffScene`、`CreateHandoffTool`、`CreateJoiner`、`CreateTrack`、`mixin/ToolTypeMixin`；另新增 `CreateBuildPlugin`、`mixin/CreateBuildMixinPlugin`） | 旧 `plugins/build/mixin/BuildMixinPlugin.java` 更名并移为 `create/build/mixin/CreateBuildMixinPlugin.java`（`diff` 仅类名、包名与 import 不同）；vanilla 的 `BuildPlugin.install` 不再含 `CreateMod.loaded()` 分支（新 `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/BuildPlugin.java:23-39`） |
| `dispatch/`（39） | `mods/create/…/create/dispatch/`（39） | |
| `farming/`(19) `fishing/`(8) `groundwork/`(13) `orders/`(8) `pasture/`(21) `patrol/`(8) `person/`(68) `wares/`(32) | `mods/vanilla/…/plugins/<同名>/` | 数量逐目录一致 |
| `golem/`（13） | `mods/modulargolems/…/modulargolems/`（`GolemPlugin`、`GolemScene`、`domain/`、`resident/`） | |
| `rail/`（41） | `mods/create/…/create/rail/`（`RailPlugin`、`RailScene`、`domain/`、`passage/`） | |
| `sable/SablePassage.java` | `mods/core/…/core/shell/structure/SablePassage.java` | 由 `FolkwaysMod.fitTheShell` 在 `isLoaded("sable")` 时挂 `event.passage(new SablePassage())`：新 `mods/core/src/main/java/io/github/izakyl/folkways/FolkwaysMod.java:91-95` |
| `sable/SablePlugin.java` | **已删除** | 新树无 `SablePlugin`；Sable mixin 由 `Map.of("SableAssemblyMixin", "sable")` 门控：新 `mods/core/src/main/java/io/github/izakyl/folkways/core/shell/mixin/CoreMixinPlugin.java:17` |
| `BuiltinPlugins.java` | `mods/vanilla/…/plugins/BuiltinPlugins.java` | 旧 `:25-43` 含 Rail/Dispatch/Sable/Golem 分支；新 `:20-30` 仅 9 个 vanilla 插件 |
| `CreateMod.java` | `mods/create/…/create/CreateMod.java` | `loaded()` 仍是 `ModList.get().isLoaded("create")`（新 `mods/create/src/main/java/io/github/izakyl/folkways/create/CreateMod.java:12-14`） |

> 判据原话（新 `CONTRIBUTING.md:36-38`）：An integration whose absence would leave the colony misreading a world that has that mod (Sable's sub-levels, Create's contraptions in the way) belongs in the core; one that only adds something when its mod is there is a mod of its own. 因此 Sable 的 `WorldSpaces`/`Passage` 与 Create 的 `CreateObstacles`（新 `mods/core/src/main/java/io/github/izakyl/folkways/FolkwaysMod.java:100-102`）留在 core。

### 1.4 配置类的拆分（与 §4 中 `FolkwaysConfig.java:行号` 引用相关）

| 旧 `J/FolkwaysConfig.java` 的旋钮 | 新位置 |
| --- | --- |
| `mode`、`solveThreads`（planning 段） | 新 `mods/core/src/main/java/io/github/izakyl/folkways/FolkwaysConfig.java:35-51` |
| `haulingHaste`、`asceticAppetite`（perks 段） | 同上 `:53-65`（`:58`、`:64`） |
| `haulReachTicks`、`planHorizonTicks`、`planHorizonDepth`（labor 段） | 同上 `:72`、`:80`、`:86` |
| `travelCeilingMicros`、`travelFloorMicros`（navigation 段） | 同上 `:96`、`:103` |
| `logPlanHeartbeat`、`heartbeatCycles`（diagnostics 段） | 同上 `:112`、`:115` |
| `immigration.*`、`zones.*`、`blueprints.*`、`crafting.refusedRecipes`、五个 `*Haste`（building/crafting/herding/farming/fishing）、`pathSearchBudget` | 新 `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/FolkwaysVanillaConfig.java`：immigration `:44-60`、zones `:63-94`、blueprints `:97-113`、crafting `:116-127`、perks `:129-152`、`pathSearchBudget` `:159` |
| `conductingHaste`、`dispatchHaste`、`dispatchReachTicks`、`seatTicks` | 新 `mods/create/src/main/java/io/github/izakyl/folkways/create/FolkwaysCreateConfig.java:28`、`:33`、`:41`、`:46` |
| 注册位置 | 三个 `ModConfig.Type.SERVER`：core `FolkwaysMod.java:70`；vanilla `FolkwaysVanillaMod.java:17`；create `FolkwaysCreateMod.java:16`；modulargolems 无（`FolkwaysModularGolemsMod.java:11-13`）。文件名见新 `README.md:109` |

---

## 2. 构建机制变化

> 比较对象：旧 `build.gradle` / `settings.gradle` / `gradle.properties` / `blockwright.toml` / `package.json` / `.github/workflows/build.yml` 与新的根 `build.gradle`、`gradle/mod.gradle`、`mods/*/build.gradle`、`settings.gradle`、`gradle.properties`、`blockwright.toml`、`package.json`、`.github/workflows/build.yml`、`CONTRIBUTING.md`、`README.md`。

### 2.1 总体结构

| 主题 | 旧（`reference/folkways-master/`） | 新（`reference/folkways-67f28b0/`） |
| --- | --- | --- |
| 工程拓扑 | 单工程：`settings.gradle:18` 仅 `rootProject.name = "folkways"` | `settings.gradle:20-24`：`["core","vanilla","create","modulargolems"].each { include ":${name}"; projectDir = file("mods/${name}") }`；根 `build.gradle:5` 注释 "The root builds no mod of its own: it runs the four under mods/ together for the game tests" |
| 谁出 jar | 根工程：`build.gradle:10-12`（archivesName）、`:173-178`（jar 打入 LICENSE） | 四个子项目各自出 jar；根的 `jar` 任务被禁用：`build.gradle:85-87` |
| 子项目依赖链 | 无 | `mods/vanilla/build.gradle:13` `api project(":core")`；`mods/create/build.gradle:14` `api project(":vanilla")`；`mods/modulargolems/build.gradle:12` `api project(":vanilla")`。即 core ← vanilla ← {create, modulargolems} |
| 各子项目共用逻辑 | 不适用 | `gradle/mod.gradle`：`modId`/`modName` 由子项目先设再 `apply from`（`gradle/mod.gradle:1`；`mods/core/build.gradle:7-9`、`mods/vanilla/build.gradle:7-9`、`mods/create/build.gradle:7-9`、`mods/modulargolems/build.gradle:7-9`） |
| 版本坐标属性 | `gradle.properties:4-5` 有 `archives_base_name=folkways`、`mod_id=folkways` | 新 `gradle.properties:1-18` 无这两项；其余键相同（`maven_group`、`mod_version`、`minecraft_*`、`neoforge_*`、`loader_version_range`、`java_release`、`ponder_version`、`flywheel_version`、`starlark_version`、`ldlib_*`），行号整体前移（旧 `gradle.properties:12` java_release → 新 `:10`） |

### 2.2 你关心的八个点

| 点 | 结论（带证据） |
| --- | --- |
| **`lib()` / `.blockwright/mods.json` 现在在哪** | 在 `gradle/mod.gradle:39-47`：`def modsManifest = rootProject.file(".blockwright/mods.json")`（`:39`）→ `ext.lib = { String name -> … files(paths.collect { rootProject.file(it) }) }`（`:41-47`）；缺条目抛 `GradleException("mod ${name} is missing from ${modsManifest}; run  npm run setup  first")`（`:44`）。各子项目在 `apply from: rootProject.file("gradle/mod.gradle")`（如 `mods/core/build.gradle:9`）之后直接调用 `lib("x")`（如 `mods/core/build.gradle:12-17`）；根项目则通过 `def core = project(":core")`（`build.gradle:32`）+ `core.lib("create")`（`build.gradle:70`）取用，且先 `evaluationDependsOn` 四个子项目（`build.gradle:13`）。旧位置 `build.gradle:81-89`。**机制本身不变**：manifest 仍由 `npm run setup` 生成（新 `package.json:7`），仍不入库（新 `.gitignore:36-37`） |
| **`mod_id` 怎么展开** | `gradle/mod.gradle:67-74` 定义 `expanded` 映射，其 `"mod_id": project.modId`（`:68`）取子项目的 `ext.modId`（`mods/core/build.gradle:7` = `folkways_core` 等）；`processResources` 把它展开进 `META-INF/neoforge.mods.toml`（`gradle/mod.gradle:76-81`）。toml 中用 `${mod_id}`（如 `mods/core/src/main/resources/META-INF/neoforge.mods.toml:7`、`:14`）。旧：`build.gradle:215-239` 从 `gradle.properties:23 mod_id=folkways` 展开。⚠️ `@Mod` 注解里的 id 另在 Java 常量里：`FolkwaysMod.CORE_ID = "folkways_core"`（`mods/core/src/main/java/io/github/izakyl/folkways/FolkwaysMod.java:63`）、`FolkwaysVanillaMod.ID`（`…/plugins/FolkwaysVanillaMod.java:14`）、`FolkwaysCreateMod.ID`（`…/create/FolkwaysCreateMod.java:13`）、`FolkwaysModularGolemsMod.ID`（`…/modulargolems/FolkwaysModularGolemsMod.java:9`）——**toml 的 modId 与 Java 常量是两处独立书写，没有构建期校验** ⚠️（推断：未见校验代码） |
| **jar 命名** | `gradle/mod.gradle:6-8`：`archivesName = "${project.modName}-neoforge-${project.minecraft_version}"`，`modName` 为 `folkways-core` / `folkways-vanilla` / `folkways-create` / `folkways-modulargolems`（各子项目 `build.gradle:8`）；`version = project.mod_version`（`gradle/mod.gradle:4`）。⚠️ 由此推得文件名形如 `folkways-core-neoforge-1.21.1-0.1.0.jar`（版本后缀由 Gradle 追加，本次未实际构建验证）；与之吻合的是 `blockwright.toml:17` 的 glob `build/libs/folkways-core-*.jar`。旧：`build.gradle:10-12` → `folkways-neoforge-1.21.1`（r05:26 的写法） |
| **`build/libs` 怎么收集四个 jar** | 根 `build.gradle:90-93`：`collectJars`（`Copy`）对 `modProjects.values()` 的每个 `project(path).tasks.named("jar")` 做 `from(…)`，`into layout.buildDirectory.dir("libs")`；`build` 依赖 `collectJars, "copyInstanceMods"` 以及每个 `${it}:build`（`build.gradle:95-98`）。所以根 `build/libs` 里只收各子项目 `jar` 任务的产物 ⚠️（推断：`-sources` jar 由 `withSourcesJar()`〔`gradle/mod.gradle:21`〕生成在各 `mods/<x>/build/libs`，不被 `collectJars` 复制；新 `.gitignore:2,4` 忽略 `/mods/*/.gradle/`、`/mods/*/build/`）。CI 仍上传 `build/libs/*.jar`（新 `.github/workflows/build.yml:30-34`）并在 nightly 里 `rm -f jars/*-sources.jar`（`:55`）|
| **gametest 怎么跑（`enabledGameTestNamespaces`）** | 只在根项目定义 `runs.gameTestServer`（`build.gradle:47-54`）：`gameDirectory = layout.projectDirectory.dir("run/gametest")`（`:50`）、`programArgument "--nogui"`（`:51`）、`systemProperty "neoforge.enabledGameTestNamespaces", "folkways,ldlib2"`（`:52`）——**字符串与旧 `build.gradle:60` 相同**；旧 `build.gradle:61` 的 `sourceSet = sourceSets.gametest` 没了，改由根的 `neoForge.mods` 逐个 `create(id) { sourceSet mod.sourceSets.main; sourceSet mod.sourceSets.gametest }`（`build.gradle:37-45`）把各子项目源集并入同一次运行；`runtimeOnly project(path).sourceSets.main.output` / `…gametest.output`（`build.gradle:65-68`）。任务名仍是 `runGameTestServer`，`CONTRIBUTING.md:51`、`:62` 称之为 "run together by the root's `runGameTestServer`"。每个子项目的 `gametest` 源集仍独立存在（`gradle/mod.gradle:24-26`），并依赖自己的 main 输出（`:51-53`）；core 的 gametest 额外 `gametestImplementation project(":vanilla")`、`gametestCompileOnly project(":create")`（`mods/core/build.gradle:39-40`），vanilla 的 gametest 依赖 core 的 gametest 输出（`mods/vanilla/build.gradle:31`），create 的 gametest 依赖 core 与 vanilla 的 gametest 输出（`mods/create/build.gradle:21-22`） |
| **哪些 mod 从 gametest 运行里排除** | `:modulargolems`：`build.gradle:15-16`（`def testedMods = modProjects.findAll { id, path -> path != ":modulargolems" }`，注释 "The game tests run without Modular Golems, so its Folkways mod stays out of that run"）。`CONTRIBUTING.md:62` 同："with all mods but Modular Golems loaded"。该子项目也没有 `src/gametest` 目录（§1.1(b)）。Create 真 jar 以 `runtimeOnly core.lib("create")` 进运行期（`build.gradle:70`），Modular Golems 的真 jar 不进 |
| **LDLib2 怎么进开发实例** | 三处：① 编译期：core 的 `api("com.lowdragmc.ldlib2:ldlib2-neoforge-${minecraft_version}:${ldlib_version}:all")`（`mods/core/build.gradle:36`；旧 `build.gradle:143` 为 `implementation(ldlib2Coordinate)`）；② gametest 运行期：根 `runtimeOnly ldlib2Coordinate`（`build.gradle:69`）；③ e2e/bench 实例：根的 `instanceMod` 配置（`build.gradle:57-62`、`:75-77`，`transitive = false`）+ `copyInstanceMods`（`Copy`，`into build/deps`，`build.gradle:80-83`），`build` 依赖它（`build.gradle:96`）；`blockwright.toml:28-29` 的 `[mods.ldlib2] path = "build/deps/ldlib2-*.jar"`（旧 `blockwright.toml:18-19`）把它装进测试实例。坐标变量 `ldlib2Coordinate` 仍定义在根（`build.gradle:31`；旧 `:66`） |
| **`blockwright.toml` 的 `[mods.folkways_*]`** | `blockwright.toml:16-26`：四个条目 `[mods.folkways_core] / [mods.folkways_vanilla] / [mods.folkways_create] / [mods.folkways_modulargolems]`，`path = "build/libs/folkways-<x>-*.jar"`（取代旧 `blockwright.toml:15-16` 的单条 `[mods.folkways] path = "build/libs/folkways-*.jar"`）。`[coverage]`：`mods = [四个 modid]`、`sources = ["mods/core/src/main/java", …]`（新 `blockwright.toml:151-154`；旧 `:142-144` 为 `mods = ["folkways"]`、`sources = ["src/main/java"]`）。`[profile.fuzz.*]`（旧 `:284-294`）已删，其余 profile 原样顺延（新 `:156-310`）。⚠️ 这四个顶层条目没有 `target` 限制，推断每个测试实例（含 `profile.*`）都会装上全部四个 jar，包括 Modular Golems 的 Folkways 子 mod（其 toml 对 `modulargolems` 为 required，新 `mods/modulargolems/src/main/resources/META-INF/neoforge.mods.toml:44-50`；而顶层 `[mods.modulargolems]` 夹具 mod 在新 `blockwright.toml:50-52`）——本次未实际启动实例验证 |

### 2.3 其它构建脚本逐项对照

| 项 | 旧 | 新 |
| --- | --- | --- |
| Gradle 插件 | `build.gradle:1-5`：moddev 2.0.141 + `java-library` + `maven-publish` | 根 `build.gradle:1-3` 只有 moddev 2.0.141；各子项目 `mods/*/build.gradle:1-5` 为 moddev（无版本）+ `java-library` + `maven-publish` |
| 仓库 | `build.gradle:14-19` | 根 `build.gradle:18-23` 与 `gradle/mod.gradle:10-15`（内容相同） |
| Java toolchain / sourcesJar | `build.gradle:21-26` | `gradle/mod.gradle:17-22`（含 `withSourcesJar()`）；根 `build.gradle:25-29`（toolchain） |
| 源集 | `build.gradle:28-40`：`gametest` + `fuzz`（`tests/fuzz/java`） | `gradle/mod.gradle:24-26` 仅 `gametest`；fuzz 源集与 `fuzzJar`（旧 `:159-171`）不存在 |
| ModDev `neoForge {}` | 单块，`mods { folkways { main + gametest } }` 与 `runs.gameTestServer`（旧 `build.gradle:42-64`） | 拆成 `gradle/mod.gradle:28-31`（版本 + gametest 的 modding 依赖）与根 `build.gradle:34-55`（`mods` 聚合 + `runs`） |
| 编译期 jar（`lib()`） | `build.gradle:95-110` 一个 `dependencies` 块里 emi/jei/geckolib/shouldersurfing/create/sable+sable-companion/modulargolems+l2*/ftbteams+architectury | core：`mods/core/build.gradle:12-17`（emi、jei、shouldersurfing、create、sable+sable-companion、ftbteams+architectury）；vanilla：`mods/vanilla/build.gradle:15`（geckolib）；modulargolems：`mods/modulargolems/build.gradle:14`（modulargolems + l2library/l2core/l2serial）；create：`mods/create/build.gradle:16`（create） |
| 随 jar 内嵌（jarJar） | `build.gradle:115-141`：ponder、starlark、flywheel 全进一个 jar | ponder + flywheel → core（`mods/core/build.gradle:22-35`）；starlark → vanilla（`mods/vanilla/build.gradle:19-29`，注释 "Patterns are Starlark; the interpreter ships inside this mod's jar"）。开发期 `additionalRuntimeClasspath` starlark 移到根（`build.gradle:71-73`；旧 `:125-127`） |
| create 真 jar 的运行期位置 | `build.gradle:104` `gametestRuntimeOnly lib("create")` | 根 `build.gradle:70` `runtimeOnly core.lib("create")`；vanilla 的 gametest 另有 `gametestCompileOnly lib("create")`（`mods/vanilla/build.gradle:34`），core 的 gametest `gametestCompileOnly project(":create")`（`mods/core/build.gradle:40`） |
| API jar / 发布 | `build.gradle:185-213`：`apiPackages` 含 `Declaring.class`、`Relating.class`、`core/api/**`、`front/api/**`，publication 名 `folkways` | 仅 core：`mods/core/build.gradle:43-50`（include `core/api/**`、`front/api/**`）；publication 名 `mod`、`artifactId = project.modName`（`gradle/mod.gradle:83-89`）；maven local 仓库 url `rootProject.layout.buildDirectory.dir("repo")`（`gradle/mod.gradle:90-95`） |
| processResources | `build.gradle:215-239` | `gradle/mod.gradle:67-81` |
| lintScaffold / check | `build.gradle:241-266`（`check.dependsOn lintScaffold`） | 根 `build.gradle:105-133`；`check` 另依赖每个子项目的 `:check` 与 `:compileGametestJava`（`build.gradle:130-133`） |
| `build` 的依赖 | `build.gradle:155-157`：`copyInstanceMods` | 根 `build.gradle:95-98`：`collectJars`、`copyInstanceMods`、各子项目 `:build` |
| `settings.gradle` | 18 行 | 24 行；多出 `:20-24` 的 include 循环；`:1-18` 原样 |

### 2.4 `package.json`、CI

| 项 | 旧 | 新 |
| --- | --- | --- |
| `typecheck` | `package.json:8` 含 `tsc -p tests/fuzz` | `package.json:8` 不含 |
| 脚本 | 末项 `fuzz:run`（旧 `package.json:18`） | 末项 `promo:take`（新 `package.json:18`）；`build`/`setup`/`test:*` 不变（新 `package.json:6-14`） |
| CI 步骤 | `.github/workflows/build.yml:25-29`、`:30-34` | 步骤相同；`name: folkways-jar` → `folkways-jars`（新 `build.yml:32`、`:48`）；nightly 的 release 说明改为 heredoc 生成 `notes.md`（`:57-62`），文案要求装 `folkways-core` + `folkways-vanilla` + LDLib2，Create/Modular Golems 视情况加，且 "All Folkways jars must come from the same build"（`:60-61`）；`gh release create … --notes-file notes.md`（`:63-65`） |
| bug 模板 | 旧 `.github/ISSUE_TEMPLATE/bug_report.yml:16` | 新 `:16-17`：要求列出每个 Folkways jar |

### 2.5 `CONTRIBUTING.md` 与 `README.md`（安装章节）

| 项 | 旧 | 新 |
| --- | --- | --- |
| 首次构建三步 | `CONTRIBUTING.md:14-18` | `CONTRIBUTING.md:14-18`，第 17 行改为 "the four mod jars, in build/libs/" |
| 布局表 | 旧 `CONTRIBUTING.md:26-33` 六行（`src/main/java/.../core` 等） | 新 `CONTRIBUTING.md:26-52`：四 mod 表（`:29-34`）＋ 判据（`:36-38`）＋ 路径表（`:40-52`，含 `mods/core/.../{base,effect,library,core,front}`、`mods/vanilla/.../plugins`、`mods/create/.../create`、`mods/modulargolems/.../modulargolems`、`mods/*/src/gametest`） |
| gametest 命令 | 旧 `CONTRIBUTING.md:43` "NeoForge game tests in `src/gametest`" | 新 `:62` "NeoForge game tests in every `mods/*/src/gametest`, with all mods but Modular Golems loaded" |
| 测试命令表 | 旧 `:48` 有 `npm run fuzz:run` | 新无该行；suite 列表去掉 `fuzz`（旧 `:59` → 新 `:77`） |
| README 安装 | 旧 `README.md:63-71`：NeoForge、LDLib2；Ponder/Flywheel 随 jar | 新 `README.md:57-80`：四 jar 表（`:65-70`），"All four must be the same version"（`:72`），"Ponder … and Flywheel ship inside the Folkways Core jar, and the Starlark interpreter inside the Folkways Vanilla jar"（`:79-80`） |
| README 可选集成 | 旧 `README.md:73-84` | 新 `:82-93`：Create 行加 "with Folkways × Create"（`:86`）并注明无该 jar 时 "residents still walk round Create's contraptions"；Modular Golems 行加 "with Folkways × Modular Golems"（`:88`） |
| README 服务端配置 | 旧 `README.md:100` `serverconfig/folkways-server.toml` | 新 `README.md:109` 三份：`folkways_core-server.toml`、`folkways_vanilla-server.toml`、`folkways_create-server.toml` |
| README 构建产物 | 旧 `README.md:114` "The mod jar lands in `build/libs/`" | 新 `README.md:123` "The four mod jars land in `build/libs/`" |

---

## 3. 四个 `neoforge.mods.toml`

共同点：每份都是 `modLoader = "javafml"`、`loaderVersion = "${loader_version_range}"`、`license = "MIT"`（各文件 `:1-4`）；`modId = "${mod_id}"`（`:7`）、`version = "${version}"`（`:8`）；依赖表头 `[[dependencies.${mod_id}]]`。`ordering` 列：除 minecraft/neoforge 为 `NONE` 外均为 `AFTER`。版本范围里的 `[${version}]` 是**精确版本钉死**，与 `README.md:72` "All four must be the same version" 对应。

### 3.1 `mods/core`（`folkways_core`，displayName "Folkways Core"）

文件：`mods/core/src/main/resources/META-INF/neoforge.mods.toml`（86 行）；`mod_id` 取自 `mods/core/build.gradle:7`。

| 行 | modId | type | versionRange | side | reason 摘要 |
| --- | --- | --- | --- | --- | --- |
| `:14-19` | minecraft | required | `${minecraft_requirement}` = `[1.21.1,1.21.2)`（`gradle.properties:6`） | BOTH | — |
| `:21-26` | neoforge | required | `${neoforge_requirement}` = `[21.1.233,)`（`gradle.properties:9`） | BOTH | — |
| `:28-34` | ldlib2 | required | `${ldlib_requirement}` = `[2.2.37,)`（`gradle.properties:18`） | BOTH | 玩家界面是 LDLib2 UI；LDLib2 有独立发行，故与 Folkways 并装而非内嵌（`:31`） |
| `:36-42` | create | **optional** | `[6.0.0,)` | BOTH | 有 Create 的世界里居民绕行 Create 的造物而不是穿过去；Create 带来的玩法随 Folkways × Create 提供（`:39`） |
| `:44-50` | ponder | required | `[1.0.82,)` | CLIENT | 教程场景是 Ponder 场景；Folkways 把 Ponder 内嵌在自己的 jar 里，装 Folkways 即满足（`:47`） |
| `:52-58` | shouldersurfing | optional | `[1.21.1-5.2.0,)` | CLIENT | 第三人称相机下书沿准星瞄准，别无他变（`:55`） |
| `:60-66` | jei | optional | `[19.39.0,)` | CLIENT | 物品筛选打开 JEI 的原料列表；缺失时回退到 Folkways 自带选择器（`:63`） |
| `:68-74` | emi | optional | `[1.1.24,)` | CLIENT | 同 JEI，经 EMI 的排除钩子；二者任意组合或都没有均可（`:71`） |
| `:76-86` | （mixins） | — | — | — | `folkways.mixins.json`、`folkways-optional.mixins.json`、`folkways-front.mixins.json`、`folkways-desk.mixins.json` |

### 3.2 `mods/vanilla`（`folkways_vanilla`，displayName "Folkways Vanilla"）

文件：`mods/vanilla/src/main/resources/META-INF/neoforge.mods.toml`（51 行）；`mod_id` 取自 `mods/vanilla/build.gradle:7`。

| 行 | modId | type | versionRange | side | reason 摘要 |
| --- | --- | --- | --- | --- | --- |
| `:14-19` | minecraft | required | `${minecraft_requirement}` | BOTH | — |
| `:21-26` | neoforge | required | `${neoforge_requirement}` | BOTH | — |
| `:28-34` | folkways_core | required | `[${version}]` | BOTH | Vanilla 是居民做的活，规划这些活的殖民地是 Core（`:31`） |
| `:36-42` | geckolib | optional | `[4.9,)` | CLIENT | 以基岩模型而非皮肤命名的外观由 GeckoLib 渲染；缺失则回退普通玩家皮肤，其余不受影响（`:39`） |
| `:44-51` | （mixins） | — | — | — | `folkways-build.mixins.json`、`folkways-wares.mixins.json`、`folkways-person.mixins.json` |

**没有** ldlib2、ponder、create 的依赖声明（它们由 core 声明；`grep -ci` 核对：该文件无 `ldlib2`、`create`、`sable` 字样）。

### 3.3 `mods/create`（`folkways_create`，displayName "Folkways × Create"）

文件：`mods/create/src/main/resources/META-INF/neoforge.mods.toml`（59 行）；`mod_id` 取自 `mods/create/build.gradle:7`。

| 行 | modId | type | versionRange | side | reason 摘要 |
| --- | --- | --- | --- | --- | --- |
| `:14-19` | minecraft | required | `${minecraft_requirement}` | BOTH | — |
| `:21-26` | neoforge | required | `${neoforge_requirement}` | BOTH | — |
| `:28-34` | folkways_core | required | `[${version}]` | BOTH | 给 Core 运行的殖民地增添内容（`:31`） |
| `:36-42` | folkways_vanilla | required | `[${version}]` | BOTH | 铁路与包裹由 Vanilla 的居民执行，schematic 按 Vanilla 的方式建造（`:39`） |
| `:44-50` | create | **required** | `[6.0.0,)` | BOTH | 本 mod 加的一切都是 Create 的（`:47`） |
| `:52-59` | （mixins） | — | — | — | `folkways-rail.mixins.json`、`folkways-dispatch.mixins.json`、`folkways-create-build.mixins.json` |

### 3.4 `mods/modulargolems`（`folkways_modulargolems`，displayName "Folkways × Modular Golems"）

文件：`mods/modulargolems/src/main/resources/META-INF/neoforge.mods.toml`（50 行）；`mod_id` 取自 `mods/modulargolems/build.gradle:7`。

| 行 | modId | type | versionRange | side | reason 摘要 |
| --- | --- | --- | --- | --- | --- |
| `:14-19` | minecraft | required | `${minecraft_requirement}` | BOTH | — |
| `:21-26` | neoforge | required | `${neoforge_requirement}` | BOTH | — |
| `:28-34` | folkways_core | required | `[${version}]` | BOTH | 傀儡加入 Core 运行的殖民地（`:31`） |
| `:36-42` | folkways_vanilla | required | `[${version}]` | BOTH | 傀儡接手 Vanilla 的工种（`:39`） |
| `:44-50` | modulargolems | **required** | `[3.1.43,)` | BOTH | 本 mod 加的居民就是 Modular Golems（`:47`） |

无 `[[mixins]]` 段（全文件 50 行，末段即 `:44-50`）。

### 3.5 与旧单 toml 的差异要点

- 旧 `src/main/resources/META-INF/neoforge.mods.toml`：`modId = "${mod_id}"` 展开为 `folkways`（旧 `gradle.properties:23`）；依赖块 minecraft/neoforge/ldlib2/create(optional)/ponder/geckolib(optional)/shouldersurfing/jei/emi/**modulargolems(optional, BOTH)**（旧 `:14-90`），mixin 九份（旧 `:92-117`）。
- **modulargolems 从 optional 变 required**，但只对 `folkways_modulargolems` 这一个 jar 成立（新 `mods/modulargolems/…/neoforge.mods.toml:44-50`）；core/vanilla/create 的 toml 都不提 modulargolems。
- create 的 `reason` 重写：旧 "Two entries need Create: …"（旧 `:37-42`）→ 新 core 版只说绕行（新 `mods/core/…/neoforge.mods.toml:39`），并另在 `folkways_create` 里 required。
- 任何一份 toml 都**不声明 sable**（`grep -c sable` 在四份 toml 中均为 0）；Sable 仍是代码内 `ModList.get().isLoaded("sable")` 探测的隐性可选集成（新 `mods/core/src/main/java/io/github/izakyl/folkways/FolkwaysMod.java:92`）——与旧 r02:152 的判断一致。

---

## 4. 引用迁移表

扫描对象：`docs/research/01-core-engine.md`、`docs/research/02-plugin-inventory.md`、`docs/research/03-front-and-interaction.md`、`docs/research/04-content-and-modding.md`、`docs/research/05-engineering-and-tooling.md`、`docs/workflow/05-m1-task-breakdown.md`、`docs/workflow/06-build-and-ci.md`、`docs/design/12-fork-strategy.md` 里所有指向旧快照的 `文件:行号` / `文件:行-行` / `路径:行号` 引用（含 `Class.method:行-行`、`README:100`、`.gitignore:34-35` 这类简写；`rNN:行号` 是指向 docs/research 自身的引用，不算）。**每个出现处各占一行，不抽样、不去重。**

列说明：「所在」= 文档简称:行号（r01…r05 = docs/research/01…05，w05/w06 = docs/workflow/05/06，d12 = docs/design/12）；「原引用」= 文档里的原文；「旧文件」= 按路径/文件名解析出的旧快照文件（`J/` 见文首约定）；「新位置」= 新快照中的 `路径:行号`（前缀 `reference/folkways-67f28b0/` 省略）。

状态含义：**已定位** = 被引行在新文件中逐行相等（或仅按备注所述的行内微调），给出新行号；**已改写** = 被引内容在新树里被重写、拆分到多个文件或语义有变，给出新的对应位置；**已删除** = 新树里没有对应物；**未定位** = 找不到。

### 4.0 汇总

| 文档 | 引用总数 | 已定位 | 已改写 | 已删除 | 未定位 |
| --- | --- | --- | --- | --- | --- |
| r01（`docs/research/01-core-engine.md`） | 86 | 85 | 1 | 0 | 0 |
| r02（`docs/research/02-plugin-inventory.md`） | 0 | 0 | 0 | 0 | 0 |
| r03（`docs/research/03-front-and-interaction.md`） | 120 | 118 | 2 | 0 | 0 |
| r04（`docs/research/04-content-and-modding.md`） | 70 | 63 | 7 | 0 | 0 |
| r05（`docs/research/05-engineering-and-tooling.md`） | 69 | 52 | 11 | 6 | 0 |
| w05（`docs/workflow/05-m1-task-breakdown.md`） | 24 | 17 | 7 | 0 | 0 |
| w06（`docs/workflow/06-build-and-ci.md`） | 57 | 44 | 12 | 1 | 0 |
| d12（`docs/design/12-fork-strategy.md`） | 5 | 3 | 2 | 0 | 0 |
| **合计** | **431** | **382** | **42** | **7** | **0** |

> r02 没有任何带行号的引用（全文只写路径，不写行号）；它的路径级引用见附录 A、B。

### 4.1 `docs/research/01-core-engine.md`（86 条）

| # | 所在 | 原引用 | 旧文件 | 新位置 | 状态 | 备注 |
| --- | --- | --- | --- | --- | --- | --- |
| R01-001 | r01:4 | `core/engine/plan/Planner.java:42` | `J/core/engine/plan/Planner.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/plan/Planner.java:43` | 已定位 | 文首「引用约定」里的格式示例 |
| R01-002 | r01:18 | `core/api/Declaring.java:30` | `J/core/api/Declaring.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/api/Declaring.java:30` | 已定位 |  |
| R01-003 | r01:19 | `core/engine/labor/ColonyLabor.java:295` | `J/core/engine/labor/ColonyLabor.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/labor/ColonyLabor.java:299` | 已定位 |  |
| R01-004 | r01:19 | `core/engine/labor/Urges.java:38` | `J/core/engine/labor/Urges.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/labor/Urges.java:38` | 已定位 |  |
| R01-005 | r01:20 | `core/api/colony/Colony.java:43` | `J/core/api/colony/Colony.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/api/colony/Colony.java:47` | 已定位 |  |
| R01-006 | r01:20 | `core/api/colony/Asking.java:39` | `J/core/api/colony/Asking.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/api/colony/Asking.java:39` | 已定位 |  |
| R01-007 | r01:20 | `core/api/colony/Sweep.java:29` | `J/core/api/colony/Sweep.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/api/colony/Sweep.java:29` | 已定位 |  |
| R01-008 | r01:21 | `core/api/work/Grown.java:14` | `J/core/api/work/Grown.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/api/work/Grown.java:14` | 已定位 |  |
| R01-009 | r01:21 | `Grown.java:82` | `J/core/api/work/Grown.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/api/work/Grown.java:82` | 已定位 |  |
| R01-010 | r01:22 | `Refining.java:80-124` | `J/core/engine/plan/Refining.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/plan/Refining.java:80-124` | 已定位 |  |
| R01-011 | r01:22 | `Refining.java:24,73` | `J/core/engine/plan/Refining.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/plan/Refining.java:24, 73` | 已定位 |  |
| R01-012 | r01:23 | `Edge.java:30` | `J/core/engine/plan/Edge.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/plan/Edge.java:30` | 已定位 |  |
| R01-013 | r01:23 | `core/engine/plan/WeaveDelta.java:18` | `J/core/engine/plan/WeaveDelta.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/plan/WeaveDelta.java:18` | 已定位 |  |
| R01-014 | r01:24 | `core/engine/plan/haul/Haul.java:41` | `J/core/engine/plan/haul/Haul.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/plan/haul/Haul.java:41` | 已定位 |  |
| R01-015 | r01:24 | `core/engine/plan/haul/TransferNode.java:52` | `J/core/engine/plan/haul/TransferNode.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/plan/haul/TransferNode.java:52` | 已定位 |  |
| R01-016 | r01:28 | `core/engine/plan/Planner.java:31,42` | `J/core/engine/plan/Planner.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/plan/Planner.java:32, 43` | 已定位 |  |
| R01-017 | r01:29 | `core/engine/plan/Scheduler.java:48,52` | `J/core/engine/plan/Scheduler.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/plan/Scheduler.java:48, 52` | 已定位 |  |
| R01-018 | r01:29 | `Scheduler.java:38` | `J/core/engine/plan/Scheduler.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/plan/Scheduler.java:38` | 已定位 |  |
| R01-019 | r01:30 | `core/engine/plan/Tours.java:40-64` | `J/core/engine/plan/Tours.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/plan/Tours.java:40-64` | 已定位 |  |
| R01-020 | r01:31 | `core/engine/plan/Unassigned.java:10-44` | `J/core/engine/plan/Unassigned.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/plan/Unassigned.java:10-44` | 已定位 |  |
| R01-021 | r01:32 | `core/engine/plan/Crew.java:19` | `J/core/engine/plan/Crew.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/plan/Crew.java:19` | 已定位 |  |
| R01-022 | r01:32 | `core/engine/labor/Survey.java:354` | `J/core/engine/labor/Survey.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/labor/Survey.java:354` | 已定位 |  |
| R01-023 | r01:35 | `core/engine/labor/ColonyLabor.java:171` | `J/core/engine/labor/ColonyLabor.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/labor/ColonyLabor.java:174` | 已定位 |  |
| R01-024 | r01:36 | `core/engine/labor/BodyRunner.java:200` | `J/core/engine/labor/BodyRunner.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/labor/BodyRunner.java:200` | 已定位 |  |
| R01-025 | r01:37 | `core/engine/labor/Commit.java:30` | `J/core/engine/labor/Commit.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/labor/Commit.java:31` | 已定位 |  |
| R01-026 | r01:37 | `core/engine/labor/Phases.java:74` | `J/core/engine/labor/Phases.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/labor/Phases.java:74` | 已定位 |  |
| R01-027 | r01:38 | `core/engine/labor/Phases.java:18` | `J/core/engine/labor/Phases.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/labor/Phases.java:18` | 已定位 |  |
| R01-028 | r01:39 | `core/engine/labor/Pipeline.java:168` | `J/core/engine/labor/Pipeline.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/labor/Pipeline.java:168` | 已定位 |  |
| R01-029 | r01:40 | `core/engine/labor/Wear.java:21` | `J/core/engine/labor/Wear.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/labor/Wear.java:21` | 已定位 |  |
| R01-030 | r01:43 | `core/engine/labor/Labor.java:60` | `J/core/engine/labor/Labor.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/labor/Labor.java:60` | 已定位 |  |
| R01-031 | r01:44 | `ColonyLabor.java:59` | `J/core/engine/labor/ColonyLabor.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/labor/ColonyLabor.java:59` | 已定位 |  |
| R01-032 | r01:44 | `Labor.java:97` | `J/core/engine/labor/Labor.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/labor/Labor.java:97` | 已定位 |  |
| R01-033 | r01:45 | `Labor.java:115-139` | `J/core/engine/labor/Labor.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/labor/Labor.java:115-139` | 已定位 |  |
| R01-034 | r01:46 | `ColonyLabor.java:63,246` | `J/core/engine/labor/ColonyLabor.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/labor/ColonyLabor.java:63, 250` | 已定位 |  |
| R01-035 | r01:47 | `core/api/colony/Cadence.java:82` | `J/core/api/colony/Cadence.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/api/colony/Cadence.java:82` | 已定位 |  |
| R01-036 | r01:48 | `Labor.java:156-167` | `J/core/engine/labor/Labor.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/labor/Labor.java:156-167` | 已定位 |  |
| R01-037 | r01:48 | `core/engine/labor/Solves.java:36` | `J/core/engine/labor/Solves.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/labor/Solves.java:36` | 已定位 |  |
| R01-038 | r01:51 | `core/engine/travel/Urgency.java:7` | `J/core/engine/travel/Urgency.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/travel/Urgency.java:7` | 已定位 |  |
| R01-039 | r01:52 | `core/engine/travel/graph/WayGraph.java:35` | `J/core/engine/travel/graph/WayGraph.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/travel/graph/WayGraph.java:35` | 已定位 |  |
| R01-040 | r01:53 | `core/engine/travel/graph/Waypoints.java:34` | `J/core/engine/travel/graph/Waypoints.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/travel/graph/Waypoints.java:34` | 已定位 |  |
| R01-041 | r01:54 | `core/engine/travel/graph/Roaming.java:42` | `J/core/engine/travel/graph/Roaming.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/travel/graph/Roaming.java:42` | 已定位 |  |
| R01-042 | r01:55 | `core/engine/travel/local/LocalGrounds.java:12` | `J/core/engine/travel/local/LocalGrounds.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/travel/local/LocalGrounds.java:12` | 已定位 |  |
| R01-043 | r01:55 | `travel/local/Survey.java:26` | `J/core/engine/travel/local/Survey.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/travel/local/Survey.java:26` | 已定位 |  |
| R01-044 | r01:56 | `core/engine/travel/PathfindingLoad.java:115` | `J/core/engine/travel/PathfindingLoad.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/travel/PathfindingLoad.java:115` | 已定位 |  |
| R01-045 | r01:57 | `core/engine/travel/TravelBudget.java:42` | `J/core/engine/travel/TravelBudget.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/travel/TravelBudget.java:42` | 已定位 |  |
| R01-046 | r01:61 | `core/engine/colony/ColonyRegistry.java:24-25,54` | `J/core/engine/colony/ColonyRegistry.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/colony/ColonyRegistry.java:24-25, 54` | 已定位 |  |
| R01-047 | r01:61 | `ColonyRegistry.java:42-51` | `J/core/engine/colony/ColonyRegistry.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/colony/ColonyRegistry.java:42-51` | 已定位 |  |
| R01-048 | r01:61 | `core/engine/colony/SaveVersion.java:9` | `J/core/engine/colony/SaveVersion.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/colony/SaveVersion.java:9` | 已定位 |  |
| R01-049 | r01:62 | `core/engine/colony/ColonyData.java:90-98` | `J/core/engine/colony/ColonyData.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/colony/ColonyData.java:90-98` | 已定位 |  |
| R01-050 | r01:62 | `core/engine/colony/Keeps.java:60-63` | `J/core/engine/colony/Keeps.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/colony/Keeps.java:60-63` | 已定位 |  |
| R01-051 | r01:119 | `core/api/Relating.java:27,32` | `J/core/api/Relating.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/api/Relating.java:27, 32` | 已定位 |  |
| R01-052 | r01:128 | `core/api/Ledger.java:29` | `J/core/api/Ledger.java` | `mods/core/src/main/java/io/github/izakyl/folkways/base/Ledger.java:29` | 已定位 |  |
| R01-053 | r01:128 | `Ledger.java:46,68-84` | `J/core/api/Ledger.java` | `mods/core/src/main/java/io/github/izakyl/folkways/base/Ledger.java:46, 68-84` | 已定位 |  |
| R01-054 | r01:130 | `core/engine/labor/Pipeline.java:77-82` | `J/core/engine/labor/Pipeline.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/labor/Pipeline.java:77-82` | 已定位 |  |
| R01-055 | r01:130 | `core/engine/labor/ColonyLabor.java:257-266` | `J/core/engine/labor/ColonyLabor.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/labor/ColonyLabor.java:261-270` | 已定位 |  |
| R01-056 | r01:132 | `core/engine/plan/haul/Haul.java:41,49` | `J/core/engine/plan/haul/Haul.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/plan/haul/Haul.java:41, 49` | 已定位 |  |
| R01-057 | r01:141 | `core/engine/plan/Refining.java:73` | `J/core/engine/plan/Refining.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/plan/Refining.java:73` | 已定位 |  |
| R01-058 | r01:141 | `core/api/work/Grown.java:82` | `J/core/api/work/Grown.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/api/work/Grown.java:82` | 已定位 |  |
| R01-059 | r01:142 | `core/engine/plan/PackSizing.java:47` | `J/core/engine/plan/PackSizing.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/plan/PackSizing.java:47` | 已定位 |  |
| R01-060 | r01:142 | `core/engine/labor/Kit.java:108` | `J/core/engine/labor/Kit.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/labor/Kit.java:108` | 已定位 |  |
| R01-061 | r01:143 | `core/engine/plan/Unassigned.java:7-43` | `J/core/engine/plan/Unassigned.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/plan/Unassigned.java:7-43` | 已定位 |  |
| R01-062 | r01:145 | `core/engine/labor/Pipeline.java:22-28` | `J/core/engine/labor/Pipeline.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/labor/Pipeline.java:22-28` | 已定位 |  |
| R01-063 | r01:146 | `core/engine/travel/TravelBudget.java:34-51` | `J/core/engine/travel/TravelBudget.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/travel/TravelBudget.java:34-51` | 已定位 |  |
| R01-064 | r01:146 | `FolkwaysConfig.java:257,264` | `J/FolkwaysConfig.java` | `mods/core/src/main/java/io/github/izakyl/folkways/FolkwaysConfig.java:96, 103` | 已定位 |  |
| R01-065 | r01:146 | `TravelBudget.java:43` | `J/core/engine/travel/TravelBudget.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/travel/TravelBudget.java:43` | 已定位 |  |
| R01-066 | r01:147 | `core/engine/travel/local/Walker.java:18` | `J/core/engine/travel/local/Walker.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/travel/local/Walker.java:18` | 已定位 |  |
| R01-067 | r01:148 | `core/engine/colony/ColonyRegistry.java:42-51` | `J/core/engine/colony/ColonyRegistry.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/colony/ColonyRegistry.java:42-51` | 已定位 |  |
| R01-068 | r01:148 | `SaveVersion.java:27` | `J/core/engine/colony/SaveVersion.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/colony/SaveVersion.java:27` | 已定位 |  |
| R01-069 | r01:149 | `core/engine/labor/Urges.java:23` | `J/core/engine/labor/Urges.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/labor/Urges.java:23` | 已定位 |  |
| R01-070 | r01:149 | `core/engine/plan/Cooldowns.java:11-13` | `J/core/engine/plan/Cooldowns.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/plan/Cooldowns.java:11-13` | 已定位 |  |
| R01-071 | r01:149 | `core/engine/labor/Labor.java:141` | `J/core/engine/labor/Labor.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/labor/Labor.java:141` | 已定位 |  |
| R01-072 | r01:150 | `plugins/farming/Crop.java:183` | `J/plugins/farming/Crop.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/farming/Crop.java:183` | 已定位 |  |
| R01-073 | r01:150 | `plugins/farming/Habit.java:198` | `J/plugins/farming/Habit.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/farming/Habit.java:198` | 已定位 |  |
| R01-074 | r01:150 | `plugins/pasture/ShearNode.java:24` | `J/plugins/pasture/ShearNode.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/pasture/ShearNode.java:24` | 已定位 |  |
| R01-075 | r01:150 | `core/api/terms/Containers.java:129-142` | `J/core/api/terms/Containers.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/api/terms/Containers.java:129-142` | 已定位 |  |
| R01-076 | r01:150 | `FolkwaysConfig.java:140-141` | `J/FolkwaysConfig.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/FolkwaysVanillaConfig.java:101-102` | 已定位 | `maxBuildCells` 的说明注释；配置类已拆为 FolkwaysConfig（core）/ FolkwaysVanillaConfig / FolkwaysCreateConfig |
| R01-077 | r01:150 | `FolkwaysConfig.java:246-250` | `J/FolkwaysConfig.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/FolkwaysVanillaConfig.java:155-159` | 已定位 | `pathSearchBudget` 移到 vanilla 配置的 `navigation` 段 |
| R01-078 | r01:151 | `core/engine/labor/BodyRunner.java:315,561` | `J/core/engine/labor/BodyRunner.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/labor/BodyRunner.java:315, 561` | 已定位 |  |
| R01-079 | r01:152 | `FolkwaysConfig.java:106-152` | `J/FolkwaysConfig.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/FolkwaysVanillaConfig.java:67-113` | 已定位 | `zones` 段与 `blueprints` 段（maxFishCells … drawSeconds）整体移到 vanilla 配置 |
| R01-080 | r01:158 | `core/engine/labor/LaborCensus.java:20` | `J/core/engine/labor/LaborCensus.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/labor/LaborCensus.java:20` | 已定位 |  |
| R01-081 | r01:159 | `core/api/Declaring.java:30` | `J/core/api/Declaring.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/api/Declaring.java:30` | 已定位 |  |
| R01-082 | r01:159 | `core/api/Relating.java:27` | `J/core/api/Relating.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/api/Relating.java:27` | 已定位 |  |
| R01-083 | r01:162 | `core/engine/plan/haul/Haul.java:49` | `J/core/engine/plan/haul/Haul.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/plan/haul/Haul.java:49` | 已定位 |  |
| R01-084 | r01:163 | `FolkwaysConfig.java:218-276` | `J/FolkwaysConfig.java` | `mods/core/src/main/java/io/github/izakyl/folkways/FolkwaysConfig.java:72`（haulReachTicks）、:80（planHorizonTicks）、:86（planHorizonDepth）、:96/:103（travelCeiling/FloorMicros）、:112（logPlanHeartbeat）、:115（heartbeatCycles）；`mods/create/src/main/java/io/github/izakyl/folkways/create/FolkwaysCreateConfig.java:41`（dispatchReachTicks）、:46（seatTicks）；`mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/FolkwaysVanillaConfig.java:159`（pathSearchBudget） | 已改写 | 同一段旋钮被拆进三份服务端配置：core 保留 labor/navigation/diagnostics，dispatch/seat 属 create，pathSearchBudget 属 vanilla |
| R01-085 | r01:164 | `core/engine/colony/ColonyRegistry.java:42` | `J/core/engine/colony/ColonyRegistry.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/colony/ColonyRegistry.java:42` | 已定位 |  |
| R01-086 | r01:166 | `core/engine/travel/local/Walker.java:18` | `J/core/engine/travel/local/Walker.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/travel/local/Walker.java:18` | 已定位 |  |

### 4.2 `docs/research/02-plugin-inventory.md`（0 条）

（无带行号的引用。）

### 4.3 `docs/research/03-front-and-interaction.md`（120 条）

| # | 所在 | 原引用 | 旧文件 | 新位置 | 状态 | 备注 |
| --- | --- | --- | --- | --- | --- | --- |
| R03-001 | r03:4 | `front/ui/screen/ColonyShell.java:53` | `J/front/ui/screen/ColonyShell.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/ui/screen/ColonyShell.java:53` | 已定位 |  |
| R03-002 | r03:12 | `front/engine/item/ColonyBookItem.java:37,53` | `J/front/engine/item/ColonyBookItem.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/engine/item/ColonyBookItem.java:37, 53` | 已定位 |  |
| R03-003 | r03:16 | `front/engine/item/BookGestures.java:13` | `J/front/engine/item/BookGestures.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/engine/item/BookGestures.java:13` | 已定位 |  |
| R03-004 | r03:17 | `front/client/FolkwaysClientRegistry.java:50-56` | `J/front/client/FolkwaysClientRegistry.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/client/FolkwaysClientRegistry.java:51-57` | 已定位 |  |
| R03-005 | r03:18 | `front/engine/item/ColonyBookKeeping.java:20-34` | `J/front/engine/item/ColonyBookKeeping.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/engine/item/ColonyBookKeeping.java:20-34` | 已定位 |  |
| R03-006 | r03:19 | `front/engine/item/HeldBook.java:14-29` | `J/front/engine/item/HeldBook.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/engine/item/HeldBook.java:14-29` | 已定位 |  |
| R03-007 | r03:19 | `front/engine/authority/ColonyAuthority.java:59-73` | `J/front/engine/authority/ColonyAuthority.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/engine/authority/ColonyAuthority.java:59-73` | 已定位 |  |
| R03-008 | r03:19 | `front/api/ui/Pages.java:20-31` | `J/front/api/ui/Pages.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/ui/Pages.java:20-31` | 已定位 |  |
| R03-009 | r03:24 | `front/client/FolkwaysClientGameEvents.java:102-144,157-164` | `J/front/client/FolkwaysClientGameEvents.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/client/FolkwaysClientGameEvents.java:102-144, 157-164` | 已定位 |  |
| R03-010 | r03:25 | `front/client/ZoneSelection.java:150-179` | `J/front/client/ZoneSelection.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/client/ZoneSelection.java:150-179` | 已定位 |  |
| R03-011 | r03:27 | `front/client/HeldPlacement.java:108` | `J/front/client/HeldPlacement.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/client/HeldPlacement.java:108` | 已定位 |  |
| R03-012 | r03:29 | `FolkwaysClientGameEvents.java:183-187` | `J/front/client/FolkwaysClientGameEvents.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/client/FolkwaysClientGameEvents.java:183-187` | 已定位 |  |
| R03-013 | r03:30 | `FolkwaysClientGameEvents.java:36-59` | `J/front/client/FolkwaysClientGameEvents.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/client/FolkwaysClientGameEvents.java:36-59` | 已定位 |  |
| R03-014 | r03:31 | `FolkwaysClientGameEvents.java:108-110` | `J/front/client/FolkwaysClientGameEvents.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/client/FolkwaysClientGameEvents.java:108-110` | 已定位 |  |
| R03-015 | r03:34 | `front/ui/screen/ColonyShell.java:53-57` | `J/front/ui/screen/ColonyShell.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/ui/screen/ColonyShell.java:53-57` | 已定位 |  |
| R03-016 | r03:35 | `ColonyShell.java:61-69,406-460` | `J/front/ui/screen/ColonyShell.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/ui/screen/ColonyShell.java:61-69, 406-460` | 已定位 |  |
| R03-017 | r03:37 | `ColonyShell.java:361-374` | `J/front/ui/screen/ColonyShell.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/ui/screen/ColonyShell.java:361-374` | 已定位 |  |
| R03-018 | r03:38 | `front/ui/screen/Desk.java:110-139` | `J/front/ui/screen/Desk.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/ui/screen/Desk.java:110-139` | 已定位 |  |
| R03-019 | r03:38 | `front/client/WindowKeys.java:20-28` | `J/front/client/WindowKeys.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/client/WindowKeys.java:20-28` | 已定位 |  |
| R03-020 | r03:38 | `ColonyShell.java:308-322,376-384` | `J/front/ui/screen/ColonyShell.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/ui/screen/ColonyShell.java:308-322, 376-384` | 已定位 |  |
| R03-021 | r03:38 | `front/ui/screen/PageKinds.java:31-48` | `J/front/ui/screen/PageKinds.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/ui/screen/PageKinds.java:31-48` | 已定位 |  |
| R03-022 | r03:39 | `FolkwaysClientRegistry.java:45` | `J/front/client/FolkwaysClientRegistry.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/client/FolkwaysClientRegistry.java:45` | 已定位 |  |
| R03-023 | r03:42 | `FolkwaysClientRegistry.java:29-32` | `J/front/client/FolkwaysClientRegistry.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/client/FolkwaysClientRegistry.java:29-32` | 已定位 |  |
| R03-024 | r03:42 | `front/client/Overhead.java:33-79,184-203` | `J/front/client/Overhead.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/client/Overhead.java:33-79, 184-203` | 已定位 |  |
| R03-025 | r03:43 | `OverheadScreen.java:187-191` | `J/front/client/OverheadScreen.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/client/OverheadScreen.java:187-191` | 已定位 |  |
| R03-026 | r03:43 | `Overhead.java:131-160` | `J/front/client/Overhead.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/client/Overhead.java:131-160` | 已定位 |  |
| R03-027 | r03:43 | `OverheadScreen.java:194-201` | `J/front/client/OverheadScreen.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/client/OverheadScreen.java:194-201` | 已定位 |  |
| R03-028 | r03:43 | `Overhead.aim:113-125` | `J/front/client/Overhead.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/client/Overhead.java:113-125` | 已定位 |  |
| R03-029 | r03:43 | `FolkwaysClientGameEvents.sneakDown:62-64` | `J/front/client/FolkwaysClientGameEvents.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/client/FolkwaysClientGameEvents.java:62-64` | 已定位 |  |
| R03-030 | r03:44 | `front/client/Layer.java:7-65` | `J/front/client/Layer.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/client/Layer.java:7-65` | 已定位 |  |
| R03-031 | r03:45 | `OverheadScreen.init:58-111` | `J/front/client/OverheadScreen.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/client/OverheadScreen.java:58-111` | 已定位 |  |
| R03-032 | r03:49 | `core/api/library/LibraryCommand.java:26-78` | `J/core/api/library/LibraryCommand.java` | `mods/core/src/main/java/io/github/izakyl/folkways/library/LibraryCommand.java:26-78` | 已定位 |  |
| R03-033 | r03:50 | `front/engine/charter/Invitations.java:84-102` | `J/front/engine/charter/Invitations.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/engine/charter/Invitations.java:84-102` | 已定位 |  |
| R03-034 | r03:57 | `front/ui/screen/PageKinds.java:15-26` | `J/front/ui/screen/PageKinds.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/ui/screen/PageKinds.java:15-26` | 已定位 |  |
| R03-035 | r03:61 | `front/ui/screen/ResidentsPage.java:314-325,346-389` | `J/front/ui/screen/ResidentsPage.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/ui/screen/ResidentsPage.java:314-325, 346-389` | 已定位 |  |
| R03-036 | r03:62 | `front/engine/colony/ColonyMetrics.java:30-46` | `J/front/engine/colony/ColonyMetrics.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/engine/colony/ColonyMetrics.java:30-46` | 已定位 |  |
| R03-037 | r03:62 | `front/ui/screen/Razing.java:99` | `J/front/ui/screen/Razing.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/ui/screen/Razing.java:99` | 已定位 |  |
| R03-038 | r03:63 | `front/ui/screen/MembersPage.java:100-202` | `J/front/ui/screen/MembersPage.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/ui/screen/MembersPage.java:100-202` | 已定位 |  |
| R03-039 | r03:64 | `front/ui/screen/LessonsPage.java:44-99` | `J/front/ui/screen/LessonsPage.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/ui/screen/LessonsPage.java:44-99` | 已定位 |  |
| R03-040 | r03:65 | `front/api/CoreSettings.java:22-29` | `J/front/api/CoreSettings.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/CoreSettings.java:22-29` | 已定位 |  |
| R03-041 | r03:66 | `plugins/build/BuildPresence.java:334-360` | `J/plugins/build/BuildPresence.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/BuildPresence.java:334-360` | 已定位 |  |
| R03-042 | r03:67 | `plugins/build/HeldBlueprints.java:50-79` | `J/plugins/build/HeldBlueprints.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/HeldBlueprints.java:50-79` | 已定位 |  |
| R03-043 | r03:68 | `plugins/wares/WaresContent.java:52,83-87` | `J/plugins/wares/WaresContent.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/wares/WaresContent.java:52, 83-87` | 已定位 |  |
| R03-044 | r03:69 | `plugins/person/PersonPresence.java:96-98` | `J/plugins/person/PersonPresence.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/person/PersonPresence.java:96-98` | 已定位 |  |
| R03-045 | r03:69 | `PersonContent.java:38-40` | `J/plugins/person/PersonContent.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/person/PersonContent.java:38-40` | 已定位 |  |
| R03-046 | r03:72 | `plugins/pasture/PastureContent.java:64` | `J/plugins/pasture/PastureContent.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/pasture/PastureContent.java:69` | 已定位 |  |
| R03-047 | r03:73 | `plugins/rail/domain/RailContent.java:42` | `J/plugins/rail/domain/RailContent.java` | `mods/create/src/main/java/io/github/izakyl/folkways/create/rail/domain/RailContent.java:41` | 已定位 |  |
| R03-048 | r03:74 | `plugins/dispatch/DispatchContent.java:49` | `J/plugins/dispatch/DispatchContent.java` | `mods/create/src/main/java/io/github/izakyl/folkways/create/dispatch/DispatchContent.java:48` | 已定位 |  |
| R03-049 | r03:75 | `plugins/orders/OrdersContent.java:40` | `J/plugins/orders/OrdersContent.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/orders/OrdersContent.java:40` | 已定位 |  |
| R03-050 | r03:78 | `front/ui/screen/DomainPage.java:251-289` | `J/front/ui/screen/DomainPage.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/ui/screen/DomainPage.java:251-289` | 已定位 |  |
| R03-051 | r03:78 | `front/api/Facing.java:15-28` | `J/front/api/Facing.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/Facing.java:15-28` | 已定位 |  |
| R03-052 | r03:79 | `front/api/panel/Board.java:98-119` | `J/front/api/panel/Board.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/panel/Board.java:98-119` | 已定位 |  |
| R03-053 | r03:79 | `front/engine/colony/ColonyBoards.java:87-104` | `J/front/engine/colony/ColonyBoards.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/engine/colony/ColonyBoards.java:123-140` | 已定位 |  |
| R03-054 | r03:86 | `FolkwaysClientGameEvents.java:129-144` | `J/front/client/FolkwaysClientGameEvents.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/client/FolkwaysClientGameEvents.java:129-144` | 已定位 |  |
| R03-055 | r03:87 | `front/engine/colony/MemberToggle.java:74-81` | `J/front/engine/colony/MemberToggle.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/engine/colony/MemberToggle.java:74-81` | 已定位 |  |
| R03-056 | r03:89 | `MemberToggle.pointed:86-96` | `J/front/engine/colony/MemberToggle.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/engine/colony/MemberToggle.java:86-96` | 已定位 |  |
| R03-057 | r03:94 | `ZoneSelection.java:174-178` | `J/front/client/ZoneSelection.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/client/ZoneSelection.java:174-178` | 已定位 |  |
| R03-058 | r03:95 | `ZoneSelection.gripped:220-228` | `J/front/client/ZoneSelection.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/client/ZoneSelection.java:220-228` | 已定位 |  |
| R03-059 | r03:95 | `handleScroll:181-218` | `J/front/client/ZoneSelection.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/client/ZoneSelection.java:181-218` | 已定位 |  |
| R03-060 | r03:97 | `front/ui/screen/Drawing.java:96-200` | `J/front/ui/screen/Drawing.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/ui/screen/Drawing.java:96-200` | 已定位 |  |
| R03-061 | r03:98 | `front/client/Draft.java:48-58` | `J/front/client/Draft.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/client/Draft.java:48-58` | 已定位 |  |
| R03-062 | r03:99 | `Drawing.java:296-308` | `J/front/ui/screen/Drawing.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/ui/screen/Drawing.java:296-308` | 已定位 |  |
| R03-063 | r03:103 | `PathSelection.java:104-179` | `J/front/client/PathSelection.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/client/PathSelection.java:104-179` | 已定位 |  |
| R03-064 | r03:104 | `plugins/patrol/PatrolContent.java:57` | `J/plugins/patrol/PatrolContent.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/patrol/PatrolContent.java:64` | 已定位 | `maxPatrolPoints()` 来源类改为 FolkwaysVanillaConfig |
| R03-065 | r03:109 | `front/client/HeldPlacement.java:50-63,104-160` | `J/front/client/HeldPlacement.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/client/HeldPlacement.java:50-63, 104-160` | 已定位 |  |
| R03-066 | r03:110 | `plugins/build/draft/client/DraftPanel.java:169-178,253-269` | `J/plugins/build/draft/client/DraftPanel.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/draft/client/DraftPanel.java:169-178, 253-269` | 已定位 |  |
| R03-067 | r03:114 | `plugins/patrol/PatrolContent.java:26-58` | `J/plugins/patrol/PatrolContent.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/patrol/PatrolContent.java:29-65` | 已改写 | 内容已变：新增 `PAGE = PageKind.boarded(ID, "folkways.page.patrol", …)`（:38-39）、`registering.facing(...)`（:62）、Enrollment 追加 `Schema.none(), List.of(PAGE)`（:63-65）；巡逻因此有了自己的面板页（lang `folkways.page.patrol` = "Patrols"，core 资源 en_us.json:340） |
| R03-068 | r03:117 | `front/ui/screen/ZoneSettings.java:122-137` | `J/front/ui/screen/ZoneSettings.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/ui/screen/ZoneSettings.java:132-148` | 已定位 | 旧 137 的 `Rows.page().addChildren(strip, noSettings, scroller)` 现拆为 147-148 并多一个 `stalled` 元素（新增 ColonyStalls/Stall 展示） |
| R03-069 | r03:117 | `FolkwaysClientGameEvents.aimOpening:157-164` | `J/front/client/FolkwaysClientGameEvents.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/client/FolkwaysClientGameEvents.java:157-164` | 已定位 |  |
| R03-070 | r03:117 | `ZoneSelection.openOn:120-129` | `J/front/client/ZoneSelection.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/client/ZoneSelection.java:120-129` | 已定位 |  |
| R03-071 | r03:123 | `front/api/notice/Notice.java:12-62` | `J/front/api/notice/Notice.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/notice/Notice.java:12-62` | 已定位 |  |
| R03-072 | r03:124 | `front/client/Draft.java:96-101` | `J/front/client/Draft.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/client/Draft.java:96-101` | 已定位 |  |
| R03-073 | r03:124 | `MemberToggle.told:98-101` | `J/front/engine/colony/MemberToggle.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/engine/colony/MemberToggle.java:98-101` | 已定位 |  |
| R03-074 | r03:124 | `Razing.asker:40-47` | `J/front/ui/screen/Razing.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/ui/screen/Razing.java:40-47` | 已定位 |  |
| R03-075 | r03:124 | `Invitations.run:110-113` | `J/front/engine/charter/Invitations.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/engine/charter/Invitations.java:110-113` | 已定位 |  |
| R03-076 | r03:125 | `front/api/notice/Line.java:13-66,114-199` | `J/front/api/notice/Line.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/notice/Line.java:13-66, 114-199` | 已定位 |  |
| R03-077 | r03:126 | `front/api/notice/Sentence.java:24-53` | `J/front/api/notice/Sentence.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/notice/Sentence.java:24-53` | 已定位 |  |
| R03-078 | r03:126 | `front/engine/colony/ColonyLooks.java:66-85` | `J/front/engine/colony/ColonyLooks.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/engine/colony/ColonyLooks.java:66-85` | 已定位 |  |
| R03-079 | r03:128 | `front/engine/net/LookLines.java:10-11` | `J/front/engine/net/LookLines.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/engine/net/LookLines.java:10-11` | 已定位 |  |
| R03-080 | r03:128 | `front/client/ColonyLookState.java:13-14,36-52` | `J/front/client/ColonyLookState.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/client/ColonyLookState.java:13-14, 36-52` | 已定位 |  |
| R03-081 | r03:128 | `ColonyLooks.java:43-61` | `J/front/engine/colony/ColonyLooks.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/engine/colony/ColonyLooks.java:43-61` | 已定位 |  |
| R03-082 | r03:129 | `front/client/ColonyHighlightState.java:42,77-91` | `J/front/client/ColonyHighlightState.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/client/ColonyHighlightState.java:42, 77-91` | 已定位 |  |
| R03-083 | r03:130 | `front/client/ColonyLookCard.java:26-74` | `J/front/client/ColonyLookCard.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/client/ColonyLookCard.java:26-74` | 已定位 |  |
| R03-084 | r03:132 | `front/client/LedgerTooltips.java:55-75` | `J/front/client/LedgerTooltips.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/client/LedgerTooltips.java:55-75` | 已定位 |  |
| R03-085 | r03:133 | `front/api/ui/Pages.java:39-55` | `J/front/api/ui/Pages.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/ui/Pages.java:39-55` | 已定位 |  |
| R03-086 | r03:133 | `DomainPage.java:273-343` | `J/front/ui/screen/DomainPage.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/ui/screen/DomainPage.java:273-343` | 已定位 |  |
| R03-087 | r03:133 | `ResidentsPage.java:357,525` | `J/front/ui/screen/ResidentsPage.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/ui/screen/ResidentsPage.java:357, 525` | 已定位 |  |
| R03-088 | r03:134 | `front/client/ponder/PonderTabs.java:61-91` | `J/front/client/ponder/PonderTabs.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/client/ponder/PonderTabs.java:61-91` | 已定位 |  |
| R03-089 | r03:141 | `front/api/ponder/Scenes.java:26-46` | `J/front/api/ponder/Scenes.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/ponder/Scenes.java:27-53` | 已定位 | 区间内新增 6 行 |
| R03-090 | r03:142 | `front/client/ponder/FolkwaysPonderPlugin.java:30-44` | `J/front/client/ponder/FolkwaysPonderPlugin.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/client/ponder/FolkwaysPonderPlugin.java:30-44` | 已定位 |  |
| R03-091 | r03:142 | `front/client/Lessons.java:41-51` | `J/front/client/Lessons.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/client/Lessons.java:41-51` | 已定位 |  |
| R03-092 | r03:143 | `Lessons.java:25-39` | `J/front/client/Lessons.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/client/Lessons.java:25-39` | 已定位 |  |
| R03-093 | r03:145 | `PonderTabs.aim:61-79` | `J/front/client/ponder/PonderTabs.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/client/ponder/PonderTabs.java:61-79` | 已定位 |  |
| R03-094 | r03:145 | `PonderHint.tick:77-93,95-103` | `J/front/client/ponder/PonderHint.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/client/ponder/PonderHint.java:77-93, 95-103` | 已定位 |  |
| R03-095 | r03:146 | `LessonsPage.java:82-93` | `J/front/ui/screen/LessonsPage.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/ui/screen/LessonsPage.java:82-93` | 已定位 |  |
| R03-096 | r03:147 | `FolkwaysPonderPlugin:30-42` | `J/front/client/ponder/FolkwaysPonderPlugin.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/client/ponder/FolkwaysPonderPlugin.java:30-42` | 已定位 |  |
| R03-097 | r03:148 | `front/client/ponder/PonderIntegration.java:22-25` | `J/front/client/ponder/PonderIntegration.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/client/ponder/PonderIntegration.java:25-28` | 已定位 |  |
| R03-098 | r03:149 | `FolkwaysPonderPlugin.unlessoned:46-55` | `J/front/client/ponder/FolkwaysPonderPlugin.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/client/ponder/FolkwaysPonderPlugin.java:46-55` | 已定位 |  |
| R03-099 | r03:155 | `ResidentsPage.java:305-325` | `J/front/ui/screen/ResidentsPage.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/ui/screen/ResidentsPage.java:305-325` | 已定位 |  |
| R03-100 | r03:155 | `Board.java:98-119` | `J/front/api/panel/Board.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/panel/Board.java:98-119` | 已定位 |  |
| R03-101 | r03:157 | `core/engine/labor/Labor.java:62` | `J/core/engine/labor/Labor.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/labor/Labor.java:62` | 已定位 |  |
| R03-102 | r03:157 | `Pipeline.java:173` | `J/core/engine/labor/Pipeline.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/labor/Pipeline.java:173` | 已定位 |  |
| R03-103 | r03:158 | `plugins/orders/Order.java:12-33` | `J/plugins/orders/Order.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/orders/Order.java:12-33` | 已定位 |  |
| R03-104 | r03:158 | `OrdersContent.java:20-43` | `J/plugins/orders/OrdersContent.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/orders/OrdersContent.java:20-43` | 已定位 |  |
| R03-105 | r03:158 | `plugins/orders/OrdersScene.java:71` | `J/plugins/orders/OrdersScene.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/orders/OrdersScene.java:71` | 已定位 |  |
| R03-106 | r03:159 | `PatrolContent.java:26-58` | `J/plugins/patrol/PatrolContent.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/patrol/PatrolContent.java:29-65` | 已改写 | 内容已变：新增 `PAGE = PageKind.boarded(ID, "folkways.page.patrol", …)`（:38-39）、`registering.facing(...)`（:62）、Enrollment 追加 `Schema.none(), List.of(PAGE)`（:63-65）；巡逻因此有了自己的面板页（lang `folkways.page.patrol` = "Patrols"，core 资源 en_us.json:340） |
| R03-107 | r03:160 | `front/engine/colony/ColonyMetrics.java:14-58` | `J/front/engine/colony/ColonyMetrics.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/engine/colony/ColonyMetrics.java:14-58` | 已定位 |  |
| R03-108 | r03:160 | `Razing.java:99` | `J/front/ui/screen/Razing.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/ui/screen/Razing.java:99` | 已定位 |  |
| R03-109 | r03:160 | `front/api/PastDay.java:29-95` | `J/front/api/PastDay.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/PastDay.java:29-95` | 已定位 |  |
| R03-110 | r03:162 | `schema:22-39` | `J/front/api/CoreSettings.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/CoreSettings.java:22-39` | 已定位 |  |
| R03-111 | r03:163 | `MembersPage.java:100-153` | `J/front/ui/screen/MembersPage.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/ui/screen/MembersPage.java:100-153` | 已定位 |  |
| R03-112 | r03:166 | `HeldBook.java:14-29` | `J/front/engine/item/HeldBook.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/engine/item/HeldBook.java:14-29` | 已定位 |  |
| R03-113 | r03:166 | `ColonyAuthority.java:59-73` | `J/front/engine/authority/ColonyAuthority.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/engine/authority/ColonyAuthority.java:59-73` | 已定位 |  |
| R03-114 | r03:167 | `front/ui/screen/Razing.java:36-88` | `J/front/ui/screen/Razing.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/ui/screen/Razing.java:36-88` | 已定位 |  |
| R03-115 | r03:169 | `DraftPanel.refresh:256-260` | `J/plugins/build/draft/client/DraftPanel.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/draft/client/DraftPanel.java:256-260` | 已定位 |  |
| R03-116 | r03:178 | `front/ui/screen/DomainPage.java:251-345,449-491` | `J/front/ui/screen/DomainPage.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/ui/screen/DomainPage.java:251-345, 449-491` | 已定位 |  |
| R03-117 | r03:179 | `front/ui/UiRegistrations.java:31-56` | `J/front/ui/UiRegistrations.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/ui/UiRegistrations.java:31-56` | 已定位 |  |
| R03-118 | r03:180 | `front/ui/screen/SettingsPage.java:97-120` | `J/front/ui/screen/SettingsPage.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/ui/screen/SettingsPage.java:97-120` | 已定位 |  |
| R03-119 | r03:180 | `ZoneSettings.java:85-140` | `J/front/ui/screen/ZoneSettings.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/ui/screen/ZoneSettings.java:95-150` | 已定位 | `build(Player)` 方法体整体后移 10 行；新增 `stalled` 元素（147）；其余行同 |
| R03-120 | r03:193 | `ResidentsPage.java:161-169` | `J/front/ui/screen/ResidentsPage.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/ui/screen/ResidentsPage.java:161-169` | 已定位 |  |

### 4.4 `docs/research/04-content-and-modding.md`（70 条）

| # | 所在 | 原引用 | 旧文件 | 新位置 | 状态 | 备注 |
| --- | --- | --- | --- | --- | --- | --- |
| R04-001 | r04:16 | `plugins/build/BuildPlugin.java:25` | `J/plugins/build/BuildPlugin.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/BuildPlugin.java:24` | 已定位 |  |
| R04-002 | r04:16 | `plugins/person/PersonPlugin.java:56` | `J/plugins/person/PersonPlugin.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/person/PersonPlugin.java:56` | 已定位 |  |
| R04-003 | r04:16 | `plugins/build/draft/Patterns.java:23` | `J/plugins/build/draft/Patterns.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/draft/Patterns.java:23` | 已定位 |  |
| R04-004 | r04:16 | `plugins/build/draft/Templates.java:26-27` | `J/plugins/build/draft/Templates.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/draft/Templates.java:26-27` | 已定位 |  |
| R04-005 | r04:16 | `plugins/person/look/ModelLibrary.java:39-40` | `J/plugins/person/look/ModelLibrary.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/person/look/ModelLibrary.java:39-40` | 已定位 |  |
| R04-006 | r04:20 | `BuildPlugin.java:31` | `J/plugins/build/BuildPlugin.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/BuildPlugin.java:30` | 已定位 |  |
| R04-007 | r04:21 | `draft/DraftTemplate.java:36-73` | `J/plugins/build/draft/DraftTemplate.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/draft/DraftTemplate.java:36-73` | 已定位 |  |
| R04-008 | r04:22 | `Templates.java:32` | `J/plugins/build/draft/Templates.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/draft/Templates.java:32` | 已定位 |  |
| R04-009 | r04:23 | `plugins/person/look/ResidentSkins.java:71-119` | `J/plugins/person/look/ResidentSkins.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/person/look/ResidentSkins.java:71-119` | 已定位 |  |
| R04-010 | r04:23 | `PersonPlugin.java:61` | `J/plugins/person/PersonPlugin.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/person/PersonPlugin.java:61` | 已定位 |  |
| R04-011 | r04:23 | `ClientResidentModels.java:37-84` | `J/plugins/person/look/ClientResidentModels.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/person/look/ClientResidentModels.java:37-84` | 已定位 |  |
| R04-012 | r04:24 | `ModelLibrary.java:124-190` | `J/plugins/person/look/ModelLibrary.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/person/look/ModelLibrary.java:124-190` | 已定位 |  |
| R04-013 | r04:24 | `neoforge.mods.toml:52-58` | `src/main/resources/META-INF/neoforge.mods.toml` | `mods/vanilla/src/main/resources/META-INF/neoforge.mods.toml:36-42` | 已定位 | geckolib optional 依赖块移到 folkways_vanilla |
| R04-014 | r04:24 | `ResidentRenderer.java:25` | `J/plugins/person/ResidentRenderer.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/person/ResidentRenderer.java:25` | 已定位 |  |
| R04-015 | r04:28 | `draft/PatternLibraryPacket.java:17-19` | `J/plugins/build/draft/PatternLibraryPacket.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/draft/PatternLibraryPacket.java:17-19` | 已定位 |  |
| R04-016 | r04:28 | `draft/Pattern.java:45` | `J/plugins/build/draft/Pattern.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/draft/Pattern.java:45` | 已定位 |  |
| R04-017 | r04:29 | `draft/TemplateLibraryPacket.java:17` | `J/plugins/build/draft/TemplateLibraryPacket.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/draft/TemplateLibraryPacket.java:17` | 已定位 |  |
| R04-018 | r04:30 | `ModelLibrary.java:42-43` | `J/plugins/person/look/ModelLibrary.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/person/look/ModelLibrary.java:42-43` | 已定位 |  |
| R04-019 | r04:30 | `ModelLibraryPacket.java:23-25` | `J/plugins/person/look/ModelLibraryPacket.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/person/look/ModelLibraryPacket.java:23-25` | 已定位 |  |
| R04-020 | r04:37 | `PersonPlugin.java:57` | `J/plugins/person/PersonPlugin.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/person/PersonPlugin.java:57` | 已定位 |  |
| R04-021 | r04:45 | `Pattern.java:49-163` | `J/plugins/build/draft/Pattern.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/draft/Pattern.java:49-163` | 已定位 |  |
| R04-022 | r04:45 | `Pattern.java:104-107, 199-205` | `J/plugins/build/draft/Pattern.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/draft/Pattern.java:104-107, 199-205` | 已定位 |  |
| R04-023 | r04:47 | `draft/Capture.java:22` | `J/plugins/build/draft/Capture.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/draft/Capture.java:22` | 已定位 |  |
| R04-024 | r04:47 | `draft/Pattern.java:215-225` | `J/plugins/build/draft/Pattern.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/draft/Pattern.java:215-225` | 已定位 |  |
| R04-025 | r04:48 | `draft/Extent.java:10` | `J/plugins/build/draft/Extent.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/draft/Extent.java:10` | 已定位 |  |
| R04-026 | r04:48 | `draft/Hint.java:18` | `J/plugins/build/draft/Hint.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/draft/Hint.java:18` | 已定位 |  |
| R04-027 | r04:55 | `Pattern.java:71-73, 94-99` | `J/plugins/build/draft/Pattern.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/draft/Pattern.java:71-73, 94-99` | 已定位 |  |
| R04-028 | r04:56 | `Vocabulary.java:967-1076` | `J/plugins/build/draft/Vocabulary.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/draft/Vocabulary.java:967-1076` | 已定位 |  |
| R04-029 | r04:57 | `draft/Face.java:13-57` | `J/plugins/build/draft/Face.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/draft/Face.java:13-57` | 已定位 |  |
| R04-030 | r04:57 | `Pattern.java:369-392` | `J/plugins/build/draft/Pattern.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/draft/Pattern.java:369-392` | 已定位 |  |
| R04-031 | r04:58 | `Pattern.java:394-408` | `J/plugins/build/draft/Pattern.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/draft/Pattern.java:394-408` | 已定位 |  |
| R04-032 | r04:59 | `Pattern.java:410-419` | `J/plugins/build/draft/Pattern.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/draft/Pattern.java:410-419` | 已定位 |  |
| R04-033 | r04:61 | `Vocabulary.java:1115-1125` | `J/plugins/build/draft/Vocabulary.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/draft/Vocabulary.java:1115-1125` | 已定位 |  |
| R04-034 | r04:65 | `DraftSite.java:29-390` | `J/plugins/build/draft/DraftSite.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/draft/DraftSite.java:29-390` | 已定位 |  |
| R04-035 | r04:70 | `Vocabulary.java:67-100` | `J/plugins/build/draft/Vocabulary.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/draft/Vocabulary.java:67-100` | 已定位 |  |
| R04-036 | r04:71 | `Vocabulary.java:927-935` | `J/plugins/build/draft/Vocabulary.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/draft/Vocabulary.java:927-935` | 已定位 |  |
| R04-037 | r04:71 | `plugins/build/Joints.java:35-72` | `J/plugins/build/Joints.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/Joints.java:35-72` | 已定位 |  |
| R04-038 | r04:75 | `pattern/materials.star:52-59` | `src/main/resources/data/folkways/folkways/pattern/materials.star` | `mods/vanilla/src/main/resources/data/folkways/folkways/pattern/materials.star:52-59` | 已定位 |  |
| R04-039 | r04:75 | `road.star:70-93` | `src/main/resources/data/folkways/folkways/pattern/road.star` | `mods/vanilla/src/main/resources/data/folkways/folkways/pattern/road.star:70-93` | 已定位 |  |
| R04-040 | r04:76 | `road.star:105-120` | `src/main/resources/data/folkways/folkways/pattern/road.star` | `mods/vanilla/src/main/resources/data/folkways/folkways/pattern/road.star:105-120` | 已定位 |  |
| R04-041 | r04:77 | `quarry.star:41-61` | `src/main/resources/data/folkways/folkways/pattern/quarry.star` | `mods/vanilla/src/main/resources/data/folkways/folkways/pattern/quarry.star:41-61` | 已定位 |  |
| R04-042 | r04:78 | `Vocabulary.java:743-880` | `J/plugins/build/draft/Vocabulary.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/draft/Vocabulary.java:743-880` | 已定位 |  |
| R04-043 | r04:79 | `terraced_field.star:90-95` | `src/main/resources/data/folkways/folkways/pattern/terraced_field.star` | `mods/vanilla/src/main/resources/data/folkways/folkways/pattern/terraced_field.star:90-95` | 已定位 |  |
| R04-044 | r04:80 | `arcade.star:272-277` | `src/main/resources/data/folkways/folkways/pattern/arcade.star` | `mods/vanilla/src/main/resources/data/folkways/folkways/pattern/arcade.star:272-277` | 已定位 |  |
| R04-045 | r04:81 | `mine.star:490-510` | `src/main/resources/data/folkways/folkways/pattern/mine.star` | `mods/vanilla/src/main/resources/data/folkways/folkways/pattern/mine.star:490-510` | 已定位 |  |
| R04-046 | r04:82 | `Vocabulary.java:887-926` | `J/plugins/build/draft/Vocabulary.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/draft/Vocabulary.java:887-926` | 已定位 |  |
| R04-047 | r04:82 | `terraced_field.star:94` | `src/main/resources/data/folkways/folkways/pattern/terraced_field.star` | `mods/vanilla/src/main/resources/data/folkways/folkways/pattern/terraced_field.star:94` | 已定位 |  |
| R04-048 | r04:83 | `road.star:7-20, 99-101` | `src/main/resources/data/folkways/folkways/pattern/road.star` | `mods/vanilla/src/main/resources/data/folkways/folkways/pattern/road.star:7-20, 99-101` | 已定位 |  |
| R04-049 | r04:84 | `road.star:21-66` | `src/main/resources/data/folkways/folkways/pattern/road.star` | `mods/vanilla/src/main/resources/data/folkways/folkways/pattern/road.star:21-66` | 已定位 |  |
| R04-050 | r04:88 | `Pattern.java:154` | `J/plugins/build/draft/Pattern.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/draft/Pattern.java:154` | 已定位 |  |
| R04-051 | r04:102 | `FolkwaysMod.java:98-121` | `J/FolkwaysMod.java` | `mods/core/src/main/java/io/github/izakyl/folkways/FolkwaysMod.java:105-128` | 已定位 | `GlobalPerks.install()` 变为 `GlobalPerks.install(FolkwaysConfig::asceticAppetite)`（:110）；其余行同 |
| R04-052 | r04:118 | `BuildPlugin.java:28` | `J/plugins/build/BuildPlugin.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/BuildPlugin.java:27` | 已定位 |  |
| R04-053 | r04:118 | `PersonPlugin.java:50-55` | `J/plugins/person/PersonPlugin.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/person/PersonPlugin.java:50-55` | 已定位 |  |
| R04-054 | r04:128 | `build.gradle:185-197` | `build.gradle` | `mods/core/build.gradle:43-48` | 已改写 | apiJar 只属 core；`apiPackages` 列表消失，改为内联 include `core/api/**`、`front/api/**`（原列表里的 `Declaring.class`、`Relating.class` 已随类一起位于 core/api 下） |
| R04-055 | r04:133 | `ColonyRegistry.java:109-116` | `J/core/engine/colony/ColonyRegistry.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/colony/ColonyRegistry.java:109-116` | 已定位 |  |
| R04-056 | r04:139 | `README:100` | `README.md` | `README.md:109` | 已改写 | "Server options live in `serverconfig/folkways-server.toml`" 改写为三份：`folkways_core-server.toml`（引擎）、`folkways_vanilla-server.toml`（原版方块上的工作）、`folkways_create-server.toml`（铁路与调度）；golems 无服务端配置（FolkwaysModularGolemsMod.java:11 未注册 config） |
| R04-057 | r04:180 | `src/main/resources/META-INF/neoforge.mods.toml:36-90` | `src/main/resources/META-INF/neoforge.mods.toml` | `mods/core/src/main/resources/META-INF/neoforge.mods.toml:36-74`（create 36-42 / ponder 44-50 / shouldersurfing 52-58 / jei 60-66 / emi 68-74）；`mods/vanilla/src/main/resources/META-INF/neoforge.mods.toml:36-42`（geckolib）；`mods/modulargolems/src/main/resources/META-INF/neoforge.mods.toml:44-50`（modulargolems，type 变为 required）；`mods/create/src/main/resources/META-INF/neoforge.mods.toml:44-50`（create，type = required） | 已改写 | 旧单 toml 的可选依赖块按子项目拆分；旧 modulargolems 是 optional（旧 85-90） |
| R04-058 | r04:180 | `plugins/BuiltinPlugins.java:37-42` | `J/plugins/BuiltinPlugins.java` | Sable：`mods/core/src/main/java/io/github/izakyl/folkways/FolkwaysMod.java:91-95`（`fitTheShell`：`isLoaded("sable")` → `WorldSpaces.install(new SableSpaces())` + `event.passage(new SablePassage())`）；Golem：`mods/modulargolems/src/main/java/io/github/izakyl/folkways/modulargolems/FolkwaysModularGolemsMod.java:11-13`（`GolemPlugin.install`，无 ModList 判断） | 已改写 | `BuiltinPlugins.install` 现仅装 9 个 vanilla 插件（mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/BuiltinPlugins.java:20-30）；`SablePlugin` 已删除，Sable 适配并入 core；Create 的三个插件装在 mods/create/src/main/java/io/github/izakyl/folkways/create/CreatePlugins.java:14-18；Golem 的“可选”靠 folkways_modulargolems 独立 mod + 其 toml 对 modulargolems 的 required 依赖（mods/modulargolems/src/main/resources/META-INF/neoforge.mods.toml:44-50） |
| R04-059 | r04:184 | `BuildPlugin.java:40-42` | `J/plugins/build/BuildPlugin.java` | `mods/create/src/main/java/io/github/izakyl/folkways/create/build/CreateBuildPlugin.java:15-16`（`CreateTrack.install()`）；调用方 `mods/create/src/main/java/io/github/izakyl/folkways/create/CreatePlugins.java:15` | 已改写 | vanilla 的 BuildPlugin 不再判断 `CreateMod.loaded()`（该 if 已删，见 mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/BuildPlugin.java:23-39 的 install()）；Create 侧 build 插件整体移到 create 子项目 |
| R04-060 | r04:184 | `Joints.java:35-72` | `J/plugins/build/Joints.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/Joints.java:35-72` | 已定位 |  |
| R04-061 | r04:185 | `FolkwaysMod:86` | `J/FolkwaysMod.java` | `mods/core/src/main/java/io/github/izakyl/folkways/FolkwaysMod.java:92` | 已定位 |  |
| R04-062 | r04:185 | `BuiltinPlugins:37` | `J/plugins/BuiltinPlugins.java` | `mods/core/src/main/java/io/github/izakyl/folkways/FolkwaysMod.java:92` | 已改写 | `isLoaded("sable")` 判断移到 core 的 `fitTheShell`；BuiltinPlugins 不再含 Sable 分支（mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/BuiltinPlugins.java:20-30 仅 9 个插件） |
| R04-063 | r04:187 | `ResidentRenderer.java:25` | `J/plugins/person/ResidentRenderer.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/person/ResidentRenderer.java:25` | 已定位 |  |
| R04-064 | r04:187 | `ModelLibrary.java:148-152` | `J/plugins/person/look/ModelLibrary.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/person/look/ModelLibrary.java:148-152` | 已定位 |  |
| R04-065 | r04:189 | `Charters.java:243-258` | `J/front/engine/charter/Charters.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/engine/charter/Charters.java:243-258` | 已定位 |  |
| R04-066 | r04:189 | `front/engine/Front.java:49-50` | `J/front/engine/Front.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/engine/Front.java:49-50` | 已定位 |  |
| R04-067 | r04:192 | `Aim.java:26` | `J/front/client/Aim.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/client/Aim.java:26` | 已定位 |  |
| R04-068 | r04:193 | `mods.toml:28-50` | `src/main/resources/META-INF/neoforge.mods.toml` | `mods/core/src/main/resources/META-INF/neoforge.mods.toml:28-50` | 已改写 | ldlib2 块（28-34）与 ponder 块（44-50）原样；create 块（36-42）改为 optional + reason 重写（"residents walk round what Create builds … comes with Folkways × Create"） |
| R04-069 | r04:194 | `blockwright.toml:98-113` | `blockwright.toml` | `blockwright.toml:108-123` | 已定位 |  |
| R04-070 | r04:194 | `profile.bench.mods:164-168` | `blockwright.toml` | `blockwright.toml:174-178` | 已定位 |  |

### 4.5 `docs/research/05-engineering-and-tooling.md`（69 条）

| # | 所在 | 原引用 | 旧文件 | 新位置 | 状态 | 备注 |
| --- | --- | --- | --- | --- | --- | --- |
| R05-001 | r05:22 | `build.gradle:1-5` | `build.gradle` | `build.gradle:1-3`；各子项目 `mods/core/build.gradle:1-5`（vanilla/create/modulargolems 同） | 已改写 | 根项目只留 moddev 插件（带版本）；java-library、maven-publish 下放到各 mods/*/build.gradle，moddev 不再带版本 |
| R05-002 | r05:23 | `gradle.properties:12` | `gradle.properties` | `gradle.properties:10` | 已定位 |  |
| R05-003 | r05:23 | `build.gradle:180-183` | `build.gradle` | `build.gradle:100-103`；`gradle/mod.gradle:62-65` | 已定位 |  |
| R05-004 | r05:24 | `gradle.properties:7-12` | `gradle.properties` | `gradle.properties:5-10` | 已定位 |  |
| R05-005 | r05:25 | `gradle.properties:14-19` | `gradle.properties` | `gradle.properties:12-17` | 已定位 |  |
| R05-006 | r05:26 | `build.gradle:10-12` | `build.gradle` | `gradle/mod.gradle:6-8` | 已改写 | archivesName 改为 `${project.modName}-neoforge-${project.minecraft_version}`；`archives_base_name` 已从 gradle.properties 删除，modName 由各子项目 build.gradle:8 设定 |
| R05-007 | r05:27 | `build.gradle:14-19` | `build.gradle` | `build.gradle:18-23`；`gradle/mod.gradle:10-15` | 已定位 | 仓库块原样出现在根与 mod.gradle 两处 |
| R05-008 | r05:28 | `settings.gradle:9-16` | `settings.gradle` | `settings.gradle:9-16` | 已定位 | 路径与行号均未变 |
| R05-009 | r05:33 | `build.gradle:28-46` | `build.gradle` | `gradle/mod.gradle:24-31` | 已改写 | gametest 源集 + `addModdingDependenciesTo sourceSets.gametest` 在 mod.gradle；fuzz 源集（旧 32-39）与 `addModdingDependenciesTo sourceSets.fuzz`（旧 46）已删除 |
| R05-010 | r05:34 | `build.gradle:30-31, 159-171` | `build.gradle` | （无） | 已删除 | fuzz 源集与 fuzzJar 任务均已删除：新根 build.gradle、gradle/mod.gradle、mods/*/build.gradle 中无 `fuzz` 字样 |
| R05-011 | r05:35 | `build.gradle:185-213` | `build.gradle` | `mods/core/build.gradle:43-50`（apiJar + `publishing.publications.mod.artifact apiJar`）；`gradle/mod.gradle:83-96`（publishing） | 已改写 | publication 名 folkways→mod，artifactId 由 `project.modName` 决定 |
| R05-012 | r05:36 | `build.gradle:241-266` | `build.gradle` | `build.gradle:105-133` | 已改写 | lintScaffold（旧 241-264 → 105-128）原样；旧 266 `check.dependsOn lintScaffold` 改写为 130-133：另依赖每个子项目的 `:check` 与 `:compileGametestJava` |
| R05-013 | r05:40 | `build.gradle:81-89` | `build.gradle` | `gradle/mod.gradle:39-47` | 已改写 | `lib()` 现为 `ext.lib`，读 `rootProject.file(".blockwright/mods.json")`，路径经 `rootProject.file(it)` 解析；各子项目 `compileOnly lib("x")` 调用（如 mods/core/build.gradle:12-17） |
| R05-014 | r05:48 | `build.gradle:95-115` | `build.gradle` | `mods/core/build.gradle:12-21`（含 ponder compileOnly :19-21）；`mods/vanilla/build.gradle:15`；`mods/modulargolems/build.gradle:14` | 已改写 | 同上；ponder 的 compileOnly 在 core/vanilla/create/modulargolems 各一份 |
| R05-015 | r05:53 | `build.gradle:104` | `build.gradle` | `build.gradle:70` | 已改写 | 改为根项目 `runtimeOnly core.lib("create")`（不再是 gametestRuntimeOnly）；另 mods/vanilla/build.gradle:34 为 vanilla 的 `gametestCompileOnly lib("create")` |
| R05-016 | r05:54 | `build.gradle:122-141` | `build.gradle` | `mods/vanilla/build.gradle:20-29`（starlark）；`build.gradle:71-73`；`mods/core/build.gradle:29-35`（flywheel jarJar） | 已改写 | 同上 |
| R05-017 | r05:55 | `build.gradle:66, 143-157` | `build.gradle` | `build.gradle:31`（ldlib2Coordinate）；`mods/core/build.gradle:36`（`api(...)`）；`build.gradle:75-77`（instanceMod）、`build.gradle:80-83`（copyInstanceMods）、`build.gradle:95-98`（build 依赖） | 已改写 | LDLib2 坐标定义仍在根；编译期依赖移到 core 的 `api`，运行期 `runtimeOnly ldlib2Coordinate` 在根 :69 |
| R05-018 | r05:55 | `blockwright.toml:18-19` | `blockwright.toml` | `blockwright.toml:28-29` | 已定位 |  |
| R05-019 | r05:61 | `package.json:7` | `package.json` | `package.json:7` | 已定位 | 路径与行号均未变 |
| R05-020 | r05:63 | `blockwright.toml:54-62` | `blockwright.toml` | `blockwright.toml:64-72` | 已定位 |  |
| R05-021 | r05:64 | `.github/workflows/build.yml:21-24` | `.github/workflows/build.yml` | `.github/workflows/build.yml:21-24` | 已定位 | 路径与行号均未变 |
| R05-022 | r05:64 | `gitignore:34-35` | `.gitignore` | `.gitignore:36-37` | 已定位 |  |
| R05-023 | r05:65 | `CONTRIBUTING.md:14-22` | `CONTRIBUTING.md` | `CONTRIBUTING.md:14-22` | 已定位 | 第 17 行 "the mod jar" → "the four mod jars, in build/libs/"；其余行未变 |
| R05-024 | r05:77 | `tests/shared/harness/out-paths.ts:10-16` | `tests/shared/harness/out-paths.ts` | `tests/shared/harness/out-paths.ts:10-15` | 已定位 | BUCKETS 去掉 `fuzz` 项（旧 15） |
| R05-025 | r05:78 | `tests/bench/town/town-cache.ts:19` | `tests/bench/town/town-cache.ts` | `tests/bench/town/town-cache.ts:19` | 已定位 | 路径与行号均未变 |
| R05-026 | r05:88 | `CONTRIBUTING.md:71-72` | `CONTRIBUTING.md` | `CONTRIBUTING.md:89-90` | 已定位 |  |
| R05-027 | r05:101 | `tests/shared/harness/setup.ts:4-17` | `tests/shared/harness/setup.ts` | `tests/shared/harness/setup.ts:4-17` | 已定位 | 路径与行号均未变 |
| R05-028 | r05:113 | `CONTRIBUTING.md:10-12` | `CONTRIBUTING.md` | `CONTRIBUTING.md:10-12` | 已定位 | 路径与行号均未变 |
| R05-029 | r05:121 | `package.json:20-30` | `package.json` | `package.json:20-30` | 已定位 | 路径与行号均未变 |
| R05-030 | r05:132 | `tests/shared/harness/pair.ts:47-56` | `tests/shared/harness/pair.ts` | `tests/shared/harness/pair.ts:47-56` | 已定位 | 路径与行号均未变 |
| R05-031 | r05:133 | `tests/shared/harness/run-id.ts:3-7` | `tests/shared/harness/run-id.ts` | `tests/shared/harness/run-id.ts:3-7` | 已定位 | 路径与行号均未变 |
| R05-032 | r05:135 | `tests/fuzz/fuzz-kit.ts:39-54` | `tests/fuzz/fuzz-kit.ts` | （无） | 已删除 | tests/fuzz/ 整个目录已删除（"fuzzers 暂停"，0af84f0） |
| R05-033 | r05:136 | `tests/shared/harness/bw-helpers.ts:146-156` | `tests/shared/harness/bw-helpers.ts` | `tests/shared/harness/bw-helpers.ts:146-156` | 已定位 | 路径与行号均未变 |
| R05-034 | r05:140 | `tests/shared/harness/stage.ts:30-31` | `tests/shared/harness/stage.ts` | `tests/shared/harness/stage.ts:30-31` | 已定位 | 路径与行号均未变 |
| R05-035 | r05:142 | `blockwright.toml:146-312` | `blockwright.toml` | `blockwright.toml:156-310` | 已定位 | 各 profile 原样顺延；旧 `[profile.fuzz.*]`（约旧 283-294）已删除；旧 `[coverage]`（142-144）变为 151-154 |
| R05-036 | r05:160 | `blockwright.toml:178` | `blockwright.toml` | `blockwright.toml:188` | 已定位 |  |
| R05-037 | r05:164 | `blockwright.toml:7` | `blockwright.toml` | `blockwright.toml:7` | 已定位 | 路径与行号均未变 |
| R05-038 | r05:164 | `CONTRIBUTING.md:50-53` | `CONTRIBUTING.md` | `CONTRIBUTING.md:68-71` | 已定位 |  |
| R05-039 | r05:165 | `pair.ts:43-45` | `tests/shared/harness/pair.ts` | `tests/shared/harness/pair.ts:43-45` | 已定位 | 路径与行号均未变 |
| R05-040 | r05:179 | `tests/e2e/farm-blackbox.spec.ts:583-608` | `tests/e2e/farm-blackbox.spec.ts` | `tests/e2e/farm-blackbox.spec.ts:583-608` | 已定位 | 路径与行号均未变 |
| R05-041 | r05:199 | `src/gametest/java/io/github/izakyl/folkways/core/api/ground/GroundGameTests.java:22-67` | `GT/core/api/ground/GroundGameTests.java` | `mods/core/src/gametest/java/io/github/izakyl/folkways/core/api/ground/GroundGameTests.java:22-67` | 已定位 | 第 22 行 `@EventBusSubscriber(modid = FolkwaysMod.MOD_ID …)` → `FolkwaysMod.CORE_ID`；`@GameTestHolder(FolkwaysMod.MOD_ID)` 仍是 "folkways"（:23） |
| R05-042 | r05:204 | `build.gradle:55-63` | `build.gradle` | `build.gradle:47-54` | 已改写 | `runs.gameTestServer` 移到根项目；`gameDirectory`、`--nogui`、`enabledGameTestNamespaces=folkways,ldlib2` 原样；`sourceSet = sourceSets.gametest`（旧 61）删除，改由根项目 `neoForge.mods` 的 create(id){main+gametest} 聚合（根 build.gradle:37-45） |
| R05-043 | r05:209 | `tests/fuzz/fuzz-kit.ts:82-111` | `tests/fuzz/fuzz-kit.ts` | （无） | 已删除 | tests/fuzz/ 整个目录已删除（"fuzzers 暂停"，0af84f0） |
| R05-044 | r05:210 | `fuzz-kit.ts:86-90` | `tests/fuzz/fuzz-kit.ts` | （无） | 已删除 | tests/fuzz/ 整个目录已删除（"fuzzers 暂停"，0af84f0） |
| R05-045 | r05:210 | `mod-settings.ts:42-45` | `tests/shared/harness/mod-settings.ts` | `tests/shared/harness/mod-settings.ts:44-47` | 已定位 |  |
| R05-046 | r05:211 | `tests/fuzz/java/.../fuzz/Live.java:47-140` | `tests/fuzz/java/io/github/izakyl/folkways/fuzz/Live.java` | （无） | 已删除 | tests/fuzz/java 已删除；package.json 无 fuzz:run，tsc 不再含 tests/fuzz |
| R05-047 | r05:237 | `tests/bench/playwright.config.ts:6` | `tests/bench/playwright.config.ts` | `tests/bench/playwright.config.ts:6` | 已定位 | 路径与行号均未变 |
| R05-048 | r05:239 | `large-colony.bench.ts:146` | `tests/bench/large-colony.bench.ts` | `tests/bench/large-colony.bench.ts:146` | 已定位 | 路径与行号均未变 |
| R05-049 | r05:240 | `tests/bench/town/town-cache.ts:20-41` | `tests/bench/town/town-cache.ts` | `tests/bench/town/town-cache.ts:20-41` | 已定位 | 第 24 行 pattern 路径前缀 `src/main/resources/` → `mods/vanilla/src/main/resources/` |
| R05-050 | r05:252 | `tests/bench/tools/compare.py:38-39` | `tests/bench/tools/compare.py` | `tests/bench/tools/compare.py:38-39` | 已定位 | 路径与行号均未变 |
| R05-051 | r05:252 | `engine-diagnostics.ts:83` | `tests/bench/report/engine-diagnostics.ts` | `tests/bench/report/engine-diagnostics.ts:83` | 已定位 | 路径与行号均未变 |
| R05-052 | r05:257 | `judgements.ts:221-265` | `tests/bench/report/judgements.ts` | `tests/bench/report/judgements.ts:221-265` | 已定位 | 第 224 行 NEVER_HERE 增 "OFF_CHAIN", "CHAIN_ELSEWHERE"（8fa9029） |
| R05-053 | r05:279 | `panels.spec.ts:109-114` | `tests/visual/panels.spec.ts` | `tests/visual/panels.spec.ts:109-114` | 已定位 | 路径与行号均未变 |
| R05-054 | r05:303 | `CONTRIBUTING.md:59-62` | `CONTRIBUTING.md` | `CONTRIBUTING.md:77-80` | 已定位 | 第 77 行 suite 列表去掉 `fuzz` |
| R05-055 | r05:318 | `package.json:6` | `package.json` | `package.json:6` | 已定位 | 路径与行号均未变 |
| R05-056 | r05:318 | `tests/shared/harness/setup.ts:21` | `tests/shared/harness/setup.ts` | `tests/shared/harness/setup.ts:21` | 已定位 | 路径与行号均未变 |
| R05-057 | r05:318 | `tests/fuzz/global-setup.ts:10` | `tests/fuzz/global-setup.ts` | （无） | 已删除 | tests/fuzz/ 已删除 |
| R05-058 | r05:319 | `farm-blackbox.spec.ts:583-608` | `tests/e2e/farm-blackbox.spec.ts` | `tests/e2e/farm-blackbox.spec.ts:583-608` | 已定位 | 路径与行号均未变 |
| R05-059 | r05:322 | `bench/playwright.config.ts:6` | `tests/bench/playwright.config.ts` | `tests/bench/playwright.config.ts:6` | 已定位 | 路径与行号均未变 |
| R05-060 | r05:322 | `promo/playwright.config.ts:6` | `tests/promo/playwright.config.ts` | `tests/promo/playwright.config.ts:6` | 已定位 | 路径与行号均未变 |
| R05-061 | r05:332 | `pair.ts:71-89` | `tests/shared/harness/pair.ts` | `tests/shared/harness/pair.ts:71-89` | 已定位 | 路径与行号均未变 |
| R05-062 | r05:336 | `CONTRIBUTING.md:10-12` | `CONTRIBUTING.md` | `CONTRIBUTING.md:10-12` | 已定位 | 路径与行号均未变 |
| R05-063 | r05:338 | `farm-blackbox.spec.ts:583-608` | `tests/e2e/farm-blackbox.spec.ts` | `tests/e2e/farm-blackbox.spec.ts:583-608` | 已定位 | 路径与行号均未变 |
| R05-064 | r05:339 | `run-id.ts:3-7` | `tests/shared/harness/run-id.ts` | `tests/shared/harness/run-id.ts:3-7` | 已定位 | 路径与行号均未变 |
| R05-065 | r05:340 | `package.json:9` | `package.json` | `package.json:9` | 已定位 | 路径与行号均未变 |
| R05-066 | r05:341 | `tests/e2e/playwright.config.ts:10` | `tests/e2e/playwright.config.ts` | `tests/e2e/playwright.config.ts:10` | 已定位 | 路径与行号均未变 |
| R05-067 | r05:341 | `blockwright.toml:4, 147` | `blockwright.toml` | `blockwright.toml:4, 157` | 已定位 |  |
| R05-068 | r05:341 | `CONTRIBUTING.md:50-57` | `CONTRIBUTING.md` | `CONTRIBUTING.md:68-75` | 已定位 |  |
| R05-069 | r05:342 | `blockwright.toml:7` | `blockwright.toml` | `blockwright.toml:7` | 已定位 | 路径与行号均未变 |

### 4.6 `docs/workflow/05-m1-task-breakdown.md`（24 条）

| # | 所在 | 原引用 | 旧文件 | 新位置 | 状态 | 备注 |
| --- | --- | --- | --- | --- | --- | --- |
| W05-001 | w05:50 | `CONTRIBUTING.md:14-22` | `CONTRIBUTING.md` | `CONTRIBUTING.md:14-22` | 已定位 | 第 17 行 "the mod jar" → "the four mod jars, in build/libs/"；其余行未变 |
| W05-002 | w05:50 | `build.gradle:81-89` | `build.gradle` | `gradle/mod.gradle:39-47` | 已改写 | `lib()` 现为 `ext.lib`，读 `rootProject.file(".blockwright/mods.json")`，路径经 `rootProject.file(it)` 解析；各子项目 `compileOnly lib("x")` 调用（如 mods/core/build.gradle:12-17） |
| W05-003 | w05:91 | `CONTRIBUTING.md:8-9` | `CONTRIBUTING.md` | `CONTRIBUTING.md:8-9` | 已定位 | 路径与行号均未变 |
| W05-004 | w05:92 | `CONTRIBUTING.md:10-12` | `CONTRIBUTING.md` | `CONTRIBUTING.md:10-12` | 已定位 | 路径与行号均未变 |
| W05-005 | w05:93 | `CONTRIBUTING.md:14-18` | `CONTRIBUTING.md` | `CONTRIBUTING.md:14-18` | 已定位 | 第 17 行 "the mod jar" → "the four mod jars, in build/libs/" |
| W05-006 | w05:94 | `build.gradle:81-89` | `build.gradle` | `gradle/mod.gradle:39-47` | 已改写 | `lib()` 现为 `ext.lib`，读 `rootProject.file(".blockwright/mods.json")`，路径经 `rootProject.file(it)` 解析；各子项目 `compileOnly lib("x")` 调用（如 mods/core/build.gradle:12-17） |
| W05-007 | w05:95 | `CONTRIBUTING.md:20-22` | `CONTRIBUTING.md` | `CONTRIBUTING.md:20-22` | 已定位 | 路径与行号均未变 |
| W05-008 | w05:96 | `build.gradle:28-29,92-93` | `build.gradle` | `gradle/mod.gradle:24-26`（sourceSets.gametest）；`gradle/mod.gradle:51-53`（gametestImplementation sourceSets.main.output） | 已改写 | gametest 仍是每个子项目各自的独立源集；fuzz 源集与 `fuzzImplementation` 行已删除 |
| W05-009 | w05:97 | `build.gradle:56-61` | `build.gradle` | `build.gradle:48-52` | 已改写 | 旧 61 行 `sourceSet = sourceSets.gametest` 无对应行 |
| W05-010 | w05:125 | `CONTRIBUTING.md:20-22` | `CONTRIBUTING.md` | `CONTRIBUTING.md:20-22` | 已定位 | 路径与行号均未变 |
| W05-011 | w05:191 | `build.gradle:81-89` | `build.gradle` | `gradle/mod.gradle:39-47` | 已改写 | `lib()` 现为 `ext.lib`，读 `rootProject.file(".blockwright/mods.json")`，路径经 `rootProject.file(it)` 解析；各子项目 `compileOnly lib("x")` 调用（如 mods/core/build.gradle:12-17） |
| W05-012 | w05:212 | `Beds.java:21,26,46` | `J/plugins/person/living/Beds.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/person/living/Beds.java:21, 26, 46` | 已定位 |  |
| W05-013 | w05:212 | `FolkwaysAttachments.java:29-30` | `J/core/api/resident/body/FolkwaysAttachments.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/api/resident/body/FolkwaysAttachments.java:29-30` | 已定位 |  |
| W05-014 | w05:213 | `ResidentEntity.java:288-296` | `J/plugins/person/ResidentEntity.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/api/resident/body/Bodies.java:48-74`（carry/modify，SPEED_MODIFIER :26-27，`addTransientModifier` :72）；`mods/core/src/main/java/io/github/izakyl/folkways/core/api/resident/body/Body.java:96-99`（`refreshEffects()`）；`mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/person/ResidentEntity.java:292`（调用 `refreshEffects()`）；`mods/core/src/main/java/io/github/izakyl/folkways/effect/perk/GlobalPerks.java:32`（BRISK→Stats.MOVE_SPEED） | 已改写 | ResidentEntity 内联的 perk→AttributeModifier 代码已删；改走新 `effect` 层（Effects/Stats/Modifier）→ `Bodies.carry` 统一写属性 |
| W05-015 | w05:235 | `core/api/Declaring.java:30` | `J/core/api/Declaring.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/api/Declaring.java:30` | 已定位 |  |
| W05-016 | w05:236 | `core/engine/colony/ColonyData.java:90-98` | `J/core/engine/colony/ColonyData.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/colony/ColonyData.java:90-98` | 已定位 |  |
| W05-017 | w05:237 | `ResidentEntity.java:288-296` | `J/plugins/person/ResidentEntity.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/api/resident/body/Bodies.java:48-74`（carry/modify，SPEED_MODIFIER :26-27，`addTransientModifier` :72）；`mods/core/src/main/java/io/github/izakyl/folkways/core/api/resident/body/Body.java:96-99`（`refreshEffects()`）；`mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/person/ResidentEntity.java:292`（调用 `refreshEffects()`）；`mods/core/src/main/java/io/github/izakyl/folkways/effect/perk/GlobalPerks.java:32`（BRISK→Stats.MOVE_SPEED） | 已改写 | ResidentEntity 内联的 perk→AttributeModifier 代码已删；改走新 `effect` 层（Effects/Stats/Modifier）→ `Bodies.carry` 统一写属性 |
| W05-018 | w05:238 | `Cadence.java:82` | `J/core/api/colony/Cadence.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/api/colony/Cadence.java:82` | 已定位 |  |
| W05-019 | w05:602 | `Refining.java:73` | `J/core/engine/plan/Refining.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/plan/Refining.java:73` | 已定位 |  |
| W05-020 | w05:604 | `TravelBudget.java:34-51` | `J/core/engine/travel/TravelBudget.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/travel/TravelBudget.java:34-51` | 已定位 |  |
| W05-021 | w05:605 | `Beds.java:21,26,46` | `J/plugins/person/living/Beds.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/person/living/Beds.java:21, 26, 46` | 已定位 |  |
| W05-022 | w05:605 | `FolkwaysAttachments.java:29-30` | `J/core/api/resident/body/FolkwaysAttachments.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/api/resident/body/FolkwaysAttachments.java:29-30` | 已定位 |  |
| W05-023 | w05:608 | `CONTRIBUTING.md:10-12` | `CONTRIBUTING.md` | `CONTRIBUTING.md:10-12` | 已定位 | 路径与行号均未变 |
| W05-024 | w05:609 | `Cadence.Cron:82` | `J/core/api/colony/Cadence.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/api/colony/Cadence.java:82` | 已定位 |  |

### 4.7 `docs/workflow/06-build-and-ci.md`（57 条）

| # | 所在 | 原引用 | 旧文件 | 新位置 | 状态 | 备注 |
| --- | --- | --- | --- | --- | --- | --- |
| W06-001 | w06:18 | `build.gradle:106` | `build.gradle` | `mods/core/build.gradle:16` | 已定位 | `compileOnly lib("sable"), lib("sable-companion")` 现在属 core（Sable 适配已进 core/shell） |
| W06-002 | w06:18 | `gitignore:34` | `.gitignore` | `.gitignore:36` | 已定位 |  |
| W06-003 | w06:38 | `gradle.properties:12` | `gradle.properties` | `gradle.properties:10` | 已定位 |  |
| W06-004 | w06:38 | `build.gradle:180-183` | `build.gradle` | `build.gradle:100-103`；`gradle/mod.gradle:62-65` | 已定位 |  |
| W06-005 | w06:39 | `CONTRIBUTING.md:6-12` | `CONTRIBUTING.md` | `CONTRIBUTING.md:6-12` | 已定位 | 路径与行号均未变 |
| W06-006 | w06:41 | `gradle.properties:7-9` | `gradle.properties` | `gradle.properties:5-7` | 已定位 |  |
| W06-007 | w06:42 | `gradle.properties:1` | `gradle.properties` | `gradle.properties:1` | 已定位 | 路径与行号均未变 |
| W06-008 | w06:43 | `blockwright.toml:4` | `blockwright.toml` | `blockwright.toml:4` | 已定位 | 路径与行号均未变 |
| W06-009 | w06:44 | `build.gradle:1-5` | `build.gradle` | `build.gradle:1-3`；各子项目 `mods/core/build.gradle:1-5`（vanilla/create/modulargolems 同） | 已改写 | 根项目只留 moddev 插件（带版本）；java-library、maven-publish 下放到各 mods/*/build.gradle，moddev 不再带版本 |
| W06-010 | w06:45 | `settings.gradle:1-7` | `settings.gradle` | `settings.gradle:1-7` | 已定位 | 路径与行号均未变 |
| W06-011 | w06:46 | `settings.gradle:9-16` | `settings.gradle` | `settings.gradle:9-16` | 已定位 | 路径与行号均未变 |
| W06-012 | w06:47 | `build.gradle:181` | `build.gradle` | `build.gradle:101`；`gradle/mod.gradle:63` | 已定位 | `options.encoding = "UTF-8"` |
| W06-013 | w06:48 | `build.gradle:241-266` | `build.gradle` | `build.gradle:105-133` | 已改写 | lintScaffold（旧 241-264 → 105-128）原样；旧 266 `check.dependsOn lintScaffold` 改写为 130-133：另依赖每个子项目的 `:check` 与 `:compileGametestJava` |
| W06-014 | w06:56 | `CONTRIBUTING.md:12` | `CONTRIBUTING.md` | `CONTRIBUTING.md:12` | 已定位 | 路径与行号均未变 |
| W06-015 | w06:58 | `CONTRIBUTING.md:10-12` | `CONTRIBUTING.md` | `CONTRIBUTING.md:10-12` | 已定位 | 路径与行号均未变 |
| W06-016 | w06:59 | `package.json:8-10` | `package.json` | `package.json:8-10` | 已定位 | 第 8 行 typecheck 去掉 `tsc -p tests/fuzz` |
| W06-017 | w06:62 | `CONTRIBUTING.md:12` | `CONTRIBUTING.md` | `CONTRIBUTING.md:12` | 已定位 | 路径与行号均未变 |
| W06-018 | w06:75 | `settings.gradle:18` | `settings.gradle` | `settings.gradle:18` | 已定位 | 路径与行号均未变 |
| W06-019 | w06:99 | `build.gradle:241-264` | `build.gradle` | `build.gradle:105-128` | 已定位 | lintScaffold 原样留在根项目 |
| W06-020 | w06:101 | `build.gradle:246-250` | `build.gradle` | `build.gradle:110-114` | 已定位 | lint 排除目录列表 |
| W06-021 | w06:102 | `CONTRIBUTING.md:78-79` | `CONTRIBUTING.md` | `CONTRIBUTING.md:96-97` | 已定位 |  |
| W06-022 | w06:103 | `CONTRIBUTING.md:95-96` | `CONTRIBUTING.md` | `CONTRIBUTING.md:113-114` | 已定位 |  |
| W06-023 | w06:143 | `CONTRIBUTING.md:14-22` | `CONTRIBUTING.md` | `CONTRIBUTING.md:14-22` | 已定位 | 第 17 行 "the mod jar" → "the four mod jars, in build/libs/"；其余行未变 |
| W06-024 | w06:143 | `package.json:6-7` | `package.json` | `package.json:6-7` | 已定位 | 路径与行号均未变 |
| W06-025 | w06:151 | `package.json:7` | `package.json` | `package.json:7` | 已定位 | 路径与行号均未变 |
| W06-026 | w06:161 | `blockwright.toml:1-4` | `blockwright.toml` | `blockwright.toml:1-4` | 已定位 | 路径与行号均未变 |
| W06-027 | w06:177 | `gitignore:34-35` | `.gitignore` | `.gitignore:36-37` | 已定位 |  |
| W06-028 | w06:178 | `build.gradle:81-89` | `build.gradle` | `gradle/mod.gradle:39-47` | 已改写 | `lib()` 现为 `ext.lib`，读 `rootProject.file(".blockwright/mods.json")`，路径经 `rootProject.file(it)` 解析；各子项目 `compileOnly lib("x")` 调用（如 mods/core/build.gradle:12-17） |
| W06-029 | w06:192 | `build.gradle:86` | `build.gradle` | `gradle/mod.gradle:44` | 已定位 | GradleException 报错 "run  npm run setup  first" 原样 |
| W06-030 | w06:212 | `gitignore:35` | `.gitignore` | `.gitignore:37` | 已定位 |  |
| W06-031 | w06:213 | `.github/workflows/build.yml:21-24` | `.github/workflows/build.yml` | `.github/workflows/build.yml:21-24` | 已定位 | 路径与行号均未变 |
| W06-032 | w06:218 | `blockwright.toml:23,127` | `blockwright.toml` | `blockwright.toml:33, 137` | 已定位 |  |
| W06-033 | w06:239 | `build.gradle:104` | `build.gradle` | `build.gradle:70` | 已改写 | 改为根项目 `runtimeOnly core.lib("create")`（不再是 gametestRuntimeOnly）；另 mods/vanilla/build.gradle:34 为 vanilla 的 `gametestCompileOnly lib("create")` |
| W06-034 | w06:240 | `build.gradle:112-141` | `build.gradle` | `mods/core/build.gradle:19-35`（ponder compileOnly+jarJar、flywheel jarJar）；`mods/vanilla/build.gradle:20-29`（starlark implementation + jarJar）；`build.gradle:71-73`（starlark additionalRuntimeClasspath） | 已改写 | ponder/flywheel 随 core jar；starlark 随 vanilla jar（mods/vanilla/build.gradle:19 注释 "Patterns are Starlark; the interpreter ships inside this mod's jar"） |
| W06-035 | w06:242 | `build.gradle:66,143-157` | `build.gradle` | `build.gradle:31`（ldlib2Coordinate）；`mods/core/build.gradle:36`（`api(...)`）；`build.gradle:75-77`（instanceMod）、`build.gradle:80-83`（copyInstanceMods）、`build.gradle:95-98`（build 依赖） | 已改写 | 同上 |
| W06-036 | w06:242 | `blockwright.toml:18-19` | `blockwright.toml` | `blockwright.toml:28-29` | 已定位 |  |
| W06-037 | w06:248 | `build.gradle:95` | `build.gradle` | `mods/core/build.gradle:12` | 已定位 | `compileOnly lib("emi")` |
| W06-038 | w06:360 | `build.gradle:55-63` | `build.gradle` | `build.gradle:47-54` | 已改写 | `runs.gameTestServer` 移到根项目；`gameDirectory`、`--nogui`、`enabledGameTestNamespaces=folkways,ldlib2` 原样；`sourceSet = sourceSets.gametest`（旧 61）删除，改由根项目 `neoForge.mods` 的 create(id){main+gametest} 聚合（根 build.gradle:37-45） |
| W06-039 | w06:361 | `build.gradle:60` | `build.gradle` | `build.gradle:52` | 已定位 | enabledGameTestNamespaces = folkways,ldlib2 |
| W06-040 | w06:362 | `build.gradle:58` | `build.gradle` | `build.gradle:50` | 已定位 | gameDirectory = run/gametest |
| W06-041 | w06:363 | `build.gradle:104` | `build.gradle` | `build.gradle:70` | 已改写 | 改为根项目 `runtimeOnly core.lib("create")`（不再是 gametestRuntimeOnly）；另 mods/vanilla/build.gradle:34 为 vanilla 的 `gametestCompileOnly lib("create")` |
| W06-042 | w06:419 | `build.yml:35-59` | `.github/workflows/build.yml` | `.github/workflows/build.yml:35-65` | 已定位 | nightly job 保留；产物名 folkways-jar → folkways-jars；`--notes` 改为 heredoc 生成 notes.md（57-62）+ `--notes-file`（65）；54-56 的 `rm -f jars/*-sources.jar` 等未变 |
| W06-043 | w06:421 | `build.gradle:10-12,185-197` | `build.gradle` | `gradle/mod.gradle:6-8`（产物名）；`mods/core/build.gradle:43-48`（apiJar） | 已改写 | 产物名按子项目展开；apiJar 只剩 core（include `core/api/**`、`front/api/**`），不再有 apiPackages 列表 |
| W06-044 | w06:440 | `build.gradle:55-63` | `build.gradle` | `build.gradle:47-54` | 已改写 | `runs.gameTestServer` 移到根项目；`gameDirectory`、`--nogui`、`enabledGameTestNamespaces=folkways,ldlib2` 原样；`sourceSet = sourceSets.gametest`（旧 61）删除，改由根项目 `neoForge.mods` 的 create(id){main+gametest} 聚合（根 build.gradle:37-45） |
| W06-045 | w06:448 | `CONTRIBUTING.md:91-94` | `CONTRIBUTING.md` | `CONTRIBUTING.md:109-112` | 已定位 |  |
| W06-046 | w06:458 | `build.gradle:10-12,185-197` | `build.gradle` | `gradle/mod.gradle:6-8`（产物名）；`mods/core/build.gradle:43-48`（apiJar） | 已改写 | 产物名按子项目展开；apiJar 只剩 core（include `core/api/**`、`front/api/**`），不再有 apiPackages 列表 |
| W06-047 | w06:459 | `build.gradle:159-171` | `build.gradle` | （无） | 已删除 | fuzzJar 已删除；blockwright.toml 的 `[profile.fuzz]` 与 `npm run fuzz:run` 亦已删除 |
| W06-048 | w06:460 | `build.gradle:150-157` | `build.gradle` | `build.gradle:80-83`（copyInstanceMods）；`build.gradle:95-98`（build 依赖 collectJars、copyInstanceMods 及各子项目 :build） | 已改写 |  |
| W06-049 | w06:461 | `build.gradle:58` | `build.gradle` | `build.gradle:50` | 已定位 | gameDirectory = run/gametest |
| W06-050 | w06:464 | `build.gradle:207-212` | `build.gradle` | `gradle/mod.gradle:90-95` | 已定位 | maven local 仓库 url 改为 `rootProject.layout.buildDirectory.dir("repo")` |
| W06-051 | w06:471 | `build.gradle:14-19` | `build.gradle` | `build.gradle:18-23`；`gradle/mod.gradle:10-15` | 已定位 | 仓库块原样出现在根与 mod.gradle 两处 |
| W06-052 | w06:472 | `gradle.properties:9` | `gradle.properties` | `gradle.properties:7` | 已定位 |  |
| W06-053 | w06:473 | `blockwright.toml:126-134` | `blockwright.toml` | `blockwright.toml:136-144` | 已定位 |  |
| W06-054 | w06:475 | `blockwright.toml:69-72` | `blockwright.toml` | `blockwright.toml:79-82` | 已定位 |  |
| W06-055 | w06:476 | `build.gradle:125-127` | `build.gradle` | `build.gradle:71-73` | 已定位 | additionalRuntimeClasspath(starlark) 移到根项目 |
| W06-056 | w06:479 | `CONTRIBUTING.md:10-12` | `CONTRIBUTING.md` | `CONTRIBUTING.md:10-12` | 已定位 | 路径与行号均未变 |
| W06-057 | w06:568 | `build.gradle:173-178` | `build.gradle` | `gradle/mod.gradle:55-60` | 已定位 | `from(rootProject.file("LICENSE"))`，对每个 mods/* 的 jar 生效 |

### 4.8 `docs/design/12-fork-strategy.md`（5 条）

| # | 所在 | 原引用 | 旧文件 | 新位置 | 状态 | 备注 |
| --- | --- | --- | --- | --- | --- | --- |
| D12-001 | d12:144 | `CONTRIBUTING.md:14-22` | `CONTRIBUTING.md` | `CONTRIBUTING.md:14-22` | 已定位 | 第 17 行 "the mod jar" → "the four mod jars, in build/libs/"；其余行未变 |
| D12-002 | d12:144 | `build.gradle:81-89` | `build.gradle` | `gradle/mod.gradle:39-47` | 已改写 | `lib()` 现为 `ext.lib`，读 `rootProject.file(".blockwright/mods.json")`，路径经 `rootProject.file(it)` 解析；各子项目 `compileOnly lib("x")` 调用（如 mods/core/build.gradle:12-17） |
| D12-003 | d12:145 | `CONTRIBUTING.md:6-12` | `CONTRIBUTING.md` | `CONTRIBUTING.md:6-12` | 已定位 | 路径与行号均未变 |
| D12-004 | d12:146 | `CONTRIBUTING.md:10-12` | `CONTRIBUTING.md` | `CONTRIBUTING.md:10-12` | 已定位 | 路径与行号均未变 |
| D12-005 | d12:147 | `build.gradle:95-110` | `build.gradle` | `mods/core/build.gradle:12-17`（emi/jei/shouldersurfing/create/sable+sable-companion/ftbteams+architectury）；`mods/vanilla/build.gradle:15`（geckolib）；`mods/modulargolems/build.gradle:14`（modulargolems+l2library/l2core/l2serial） | 已改写 | `lib()` 名单按子项目拆开；`gametestRuntimeOnly lib("create")` 变为根 build.gradle:70 |

### 4.9 附录 A：只写路径、不带行号的引用（按文档去重，列出首次出现行）

说明：这是对 §4 主表的补充——这些引用没有行号，所以只需换路径。只收能唯一解析到旧快照文件的；类名、目录、通配写法见附录 B。`tests/promo/models/**/main.json` 等同名资源文件未列。

| 文档 | 行（至多前 4 个） | 引用 | 旧文件 | 新位置 | 状态 |
| --- | --- | --- | --- | --- | --- |
| r01 | 12 | `core/api/Ledger.java` | `J/core/api/Ledger.java` | `mods/core/src/main/java/io/github/izakyl/folkways/base/Ledger.java` | 已移动 |
| r01 | 18 | `core/api/work/UrgeSource.java` | `J/core/api/work/UrgeSource.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/api/work/UrgeSource.java` | 已移动 |
| r01 | 22 | `core/engine/plan/Refining.java` | `J/core/engine/plan/Refining.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/plan/Refining.java` | 已移动 |
| r01 | 23 | `core/engine/plan/Edge.java` | `J/core/engine/plan/Edge.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/plan/Edge.java` | 已移动 |
| r01 | 24 | `core/engine/plan/haul/Carry.java` | `J/core/engine/plan/haul/Carry.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/plan/haul/Carry.java` | 已移动 |
| r01 | 25 | `core/engine/plan/Weaver.java` | `J/core/engine/plan/Weaver.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/plan/Weaver.java` | 已移动 |
| r01 | 30 | `core/engine/plan/Tours.java` | `J/core/engine/plan/Tours.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/plan/Tours.java` | 已移动 |
| r01 | 37 | `core/engine/plan/Staged.java` | `J/core/engine/plan/Staged.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/plan/Staged.java` | 已移动 |
| r01 | 40 | `core/api/work/WorkProgress.java` | `J/core/api/work/WorkProgress.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/api/work/WorkProgress.java` | 已移动 |
| r01 | 51 | `core/engine/travel/Ways.java` | `J/core/engine/travel/Ways.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/travel/Ways.java` | 已移动 |
| r01 | 63 | `core/api/resident/body/FolkwaysAttachments.java` | `J/core/api/resident/body/FolkwaysAttachments.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/api/resident/body/FolkwaysAttachments.java` | 已移动 |
| r01 | 64 | `core/api/persist/Entries.java` | `J/core/api/persist/Entries.java` | `mods/core/src/main/java/io/github/izakyl/folkways/base/persist/Entries.java` | 已移动 |
| r01 | 72 | `core/api/colony/Colony.java` | `J/core/api/colony/Colony.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/api/colony/Colony.java` | 已移动 |
| r01 | 117 | `core/api/Declaring.java` | `J/core/api/Declaring.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/api/Declaring.java` | 已移动 |
| r01 | 165 | `core/api/library/LibraryCommand.java` | `J/core/api/library/LibraryCommand.java` | `mods/core/src/main/java/io/github/izakyl/folkways/library/LibraryCommand.java` | 已移动 |
| r01 | 167 | `core/engine/labor/Readout.java` | `J/core/engine/labor/Readout.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/labor/Readout.java` | 已移动 |
| r01 | 167 | `core/engine/travel/PathfindingLoad.java` | `J/core/engine/travel/PathfindingLoad.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/travel/PathfindingLoad.java` | 已移动 |
| r02 | 11 | `src/main/resources/assets/folkways/lang/zh_cn.json` | `src/main/resources/assets/folkways/lang/zh_cn.json` | `mods/core/src/main/resources/assets/folkways/lang/zh_cn.json` | 已移动 |
| r02 | 20 | `plugins/BuiltinPlugins.java` | `J/plugins/BuiltinPlugins.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/BuiltinPlugins.java` | 已移动 |
| r02 | 21 | `core/api/Declaring.java` | `J/core/api/Declaring.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/api/Declaring.java` | 已移动 |
| r02 | 22 | `core/api/colony/ColonyContext.java` | `J/core/api/colony/ColonyContext.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/api/colony/ColonyContext.java` | 已移动 |
| r02 | 23 | `front/api/Registering.java` | `J/front/api/Registering.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/Registering.java` | 已移动 |
| r02 | 24 | `front/api/Enrollment.java` | `J/front/api/Enrollment.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/Enrollment.java` | 已移动 |
| r02 | 24 | `Delegation.java` | `J/front/api/Delegation.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/Delegation.java` | 已移动 |
| r02 | 25 | `front/api/Shape.java` | `J/front/api/Shape.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/Shape.java` | 已移动 |
| r02 | 26 | `front/api/Schema.java` | `J/front/api/Schema.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/Schema.java` | 已移动 |
| r02 | 27 | `front/api/ui/RegisteringUi.java` | `J/front/api/ui/RegisteringUi.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/ui/RegisteringUi.java` | 已移动 |
| r02 | 27, 175 | `front/ui/screen/PageKinds.java` | `J/front/ui/screen/PageKinds.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/ui/screen/PageKinds.java` | 已移动 |
| r02 | 28 | `front/api/ponder/Scenes.java` | `J/front/api/ponder/Scenes.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/ponder/Scenes.java` | 已移动 |
| r02 | 29 | `core/api/library/Shelves.java` | `J/core/api/library/Shelves.java` | `mods/core/src/main/java/io/github/izakyl/folkways/library/Shelves.java` | 已移动 |
| r02 | 30 | `core/api/work/Node.java` | `J/core/api/work/Node.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/api/work/Node.java` | 已移动 |
| r02 | 30 | `NodeSpec.java` | `J/core/api/work/NodeSpec.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/api/work/NodeSpec.java` | 已移动 |
| r02 | 31 | `core/api/terms/RefusalKind.java` | `J/core/api/terms/RefusalKind.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/api/terms/RefusalKind.java` | 已移动 |
| r02 | 32 | `front/api/panel/Board.java` | `J/front/api/panel/Board.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/panel/Board.java` | 已移动 |
| r02 | 65 | `resident_name/default.json` | `src/main/resources/data/folkways/folkways/resident_name/default.json` | `mods/vanilla/src/main/resources/data/folkways/folkways/resident_name/default.json` | 已移动 |
| r02 | 167 | `front/engine/registry/FolkwaysItems.java` | `J/front/engine/registry/FolkwaysItems.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/engine/registry/FolkwaysItems.java` | 已移动 |
| r02 | 168 | `data/folkways/recipe/colony_book.json` | `src/main/resources/data/folkways/recipe/colony_book.json` | `mods/core/src/main/resources/data/folkways/recipe/colony_book.json` | 已移动 |
| r02 | 171 | `plugins/wares/WaresBlockEntities.java` | `J/plugins/wares/WaresBlockEntities.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/wares/WaresBlockEntities.java` | 已移动 |
| r02 | 186 | `road.star` | `src/main/resources/data/folkways/folkways/pattern/road.star` | `mods/vanilla/src/main/resources/data/folkways/folkways/pattern/road.star` | 已移动 |
| r02 | 187 | `railway.star` | `src/main/resources/data/folkways/folkways/pattern/railway.star` | `mods/vanilla/src/main/resources/data/folkways/folkways/pattern/railway.star` | 已移动 |
| r02 | 188 | `arch_bridge.star` | `src/main/resources/data/folkways/folkways/pattern/arch_bridge.star` | `mods/vanilla/src/main/resources/data/folkways/folkways/pattern/arch_bridge.star` | 已移动 |
| r02 | 189 | `city_wall.star` | `src/main/resources/data/folkways/folkways/pattern/city_wall.star` | `mods/vanilla/src/main/resources/data/folkways/folkways/pattern/city_wall.star` | 已移动 |
| r02 | 190 | `dock.star` | `src/main/resources/data/folkways/folkways/pattern/dock.star` | `mods/vanilla/src/main/resources/data/folkways/folkways/pattern/dock.star` | 已移动 |
| r02 | 191 | `arcade.star` | `src/main/resources/data/folkways/folkways/pattern/arcade.star` | `mods/vanilla/src/main/resources/data/folkways/folkways/pattern/arcade.star` | 已移动 |
| r02 | 192 | `mine.star` | `src/main/resources/data/folkways/folkways/pattern/mine.star` | `mods/vanilla/src/main/resources/data/folkways/folkways/pattern/mine.star` | 已移动 |
| r02 | 193 | `quarry.star` | `src/main/resources/data/folkways/folkways/pattern/quarry.star` | `mods/vanilla/src/main/resources/data/folkways/folkways/pattern/quarry.star` | 已移动 |
| r02 | 194 | `terraced_field.star` | `src/main/resources/data/folkways/folkways/pattern/terraced_field.star` | `mods/vanilla/src/main/resources/data/folkways/folkways/pattern/terraced_field.star` | 已移动 |
| r02 | 195 | `grading.star` | `src/main/resources/data/folkways/folkways/pattern/grading.star` | `mods/vanilla/src/main/resources/data/folkways/folkways/pattern/grading.star` | 已移动 |
| r02 | 195 | `materials.star` | `src/main/resources/data/folkways/folkways/pattern/materials.star` | `mods/vanilla/src/main/resources/data/folkways/folkways/pattern/materials.star` | 已移动 |
| r02 | 197 | `data/folkways/folkways/piece/door.nbt` | `src/main/resources/data/folkways/folkways/piece/door.nbt` | `mods/vanilla/src/main/resources/data/folkways/folkways/piece/door.nbt` | 已移动 |
| r02 | 197 | `src/gametest/resources/data/folkways/folkways/blueprint/test_hut.nbt` | `src/gametest/resources/data/folkways/folkways/blueprint/test_hut.nbt` | `mods/vanilla/src/gametest/resources/data/folkways/folkways/blueprint/test_hut.nbt` | 已移动 |
| r02 | 198 | `core/api/library/LibraryCommand.java` | `J/core/api/library/LibraryCommand.java` | `mods/core/src/main/java/io/github/izakyl/folkways/library/LibraryCommand.java` | 已移动 |
| r02 | 199 | `data/folkways/advancement/recipes/misc/colony_book.json` | `src/main/resources/data/folkways/advancement/recipes/misc/colony_book.json` | `mods/core/src/main/resources/data/folkways/advancement/recipes/misc/colony_book.json` | 已移动 |
| r02 | 209 | `zh_cn.json` | `src/main/resources/assets/folkways/lang/zh_cn.json` | `mods/core/src/main/resources/assets/folkways/lang/zh_cn.json` | 已移动 |
| r03 | 26 | `front/client/PathSelection.java` | `J/front/client/PathSelection.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/client/PathSelection.java` | 已移动 |
| r03 | 26 | `front/ui/screen/Drawing.java` | `J/front/ui/screen/Drawing.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/ui/screen/Drawing.java` | 已移动 |
| r03 | 35 | `front/ui/screen/Chooser.java` | `J/front/ui/screen/Chooser.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/ui/screen/Chooser.java` | 已移动 |
| r03 | 39 | `front/api/ui/LonePanel.java` | `J/front/api/ui/LonePanel.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/ui/LonePanel.java` | 已移动 |
| r03 | 57 | `front/api/panel/PageKind.java` | `J/front/api/panel/PageKind.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/panel/PageKind.java` | 已移动 |
| r03 | 57, 179 | `front/api/Enrollment.java` | `J/front/api/Enrollment.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/Enrollment.java` | 已移动 |
| r03 | 70 | `plugins/person/name/NamesPage.java` | `J/plugins/person/name/NamesPage.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/person/name/NamesPage.java` | 已移动 |
| r03 | 71 | `plugins/person/look/LooksPage.java` | `J/plugins/person/look/LooksPage.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/person/look/LooksPage.java` | 已移动 |
| r03 | 110 | `plugins/build/BlueprintHandoffPanel.java` | `J/plugins/build/BlueprintHandoffPanel.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/BlueprintHandoffPanel.java` | 已移动 |
| r03 | 124 | `front/api/notice/Attempt.java` | `J/front/api/notice/Attempt.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/notice/Attempt.java` | 已移动 |
| r03 | 131 | `front/api/Placard.java` | `J/front/api/Placard.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/Placard.java` | 已移动 |
| r03 | 132 | `front/api/ui/Cue.java` | `J/front/api/ui/Cue.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/ui/Cue.java` | 已移动 |
| r03 | 132 | `Cues.java` | `J/front/api/ui/Cues.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/ui/Cues.java` | 已移动 |
| r03 | 134 | `front/api/ui/Tokens.java` | `J/front/api/ui/Tokens.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/ui/Tokens.java` | 已移动 |
| r03 | 135, 188 | `en_us.json` | `src/main/resources/assets/folkways/lang/en_us.json` | `mods/core/src/main/resources/assets/folkways/lang/en_us.json` | 已移动 |
| r03 | 135, 188 | `zh_cn.json` | `src/main/resources/assets/folkways/lang/zh_cn.json` | `mods/core/src/main/resources/assets/folkways/lang/zh_cn.json` | 已移动 |
| r03 | 135, 188 | `zh_hk.json` | `src/main/resources/assets/folkways/lang/zh_hk.json` | `mods/core/src/main/resources/assets/folkways/lang/zh_hk.json` | 已移动 |
| r03 | 135, 188 | `zh_tw.json` | `src/main/resources/assets/folkways/lang/zh_tw.json` | `mods/core/src/main/resources/assets/folkways/lang/zh_tw.json` | 已移动 |
| r03 | 156 | `plugins/person/living/LivingContent.java` | `J/plugins/person/living/LivingContent.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/person/living/LivingContent.java` | 已移动 |
| r03 | 157 | `FolkwaysConfig.java` | `J/FolkwaysConfig.java` | `mods/core/src/main/java/io/github/izakyl/folkways/FolkwaysConfig.java` | 已移动 |
| r03 | 163 | `front/engine/charter/Charters.java` | `J/front/engine/charter/Charters.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/engine/charter/Charters.java` | 已移动 |
| r03 | 164 | `front/api/Schema.java` | `J/front/api/Schema.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/Schema.java` | 已移动 |
| r03 | 177 | `front/api/ui/Rows.java` | `J/front/api/ui/Rows.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/ui/Rows.java` | 已移动 |
| r03 | 178 | `front/api/Facing.java` | `J/front/api/Facing.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/Facing.java` | 已移动 |
| r03 | 178 | `front/api/panel/Board.java` | `J/front/api/panel/Board.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/panel/Board.java` | 已移动 |
| r03 | 179 | `front/api/Registering.java` | `J/front/api/Registering.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/Registering.java` | 已移动 |
| r03 | 184 | `front/api/ui/Inlay.java` | `J/front/api/ui/Inlay.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/ui/Inlay.java` | 已移动 |
| r03 | 184 | `plugins/person/PersonInlay.java` | `J/plugins/person/PersonInlay.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/person/PersonInlay.java` | 已移动 |
| r04 | 15 | `src/main/java/io/github/izakyl/folkways/core/api/library/Shelves.java` | `J/core/api/library/Shelves.java` | `mods/core/src/main/java/io/github/izakyl/folkways/library/Shelves.java` | 已移动 |
| r04 | 15 | `LooseFolder.java` | `J/core/api/library/LooseFolder.java` | `mods/core/src/main/java/io/github/izakyl/folkways/library/LooseFolder.java` | 已移动 |
| r04 | 15 | `LibraryCommand.java` | `J/core/api/library/LibraryCommand.java` | `mods/core/src/main/java/io/github/izakyl/folkways/library/LibraryCommand.java` | 已移动 |
| r04 | 20, 200 | `materials.star` | `src/main/resources/data/folkways/folkways/pattern/materials.star` | `mods/vanilla/src/main/resources/data/folkways/folkways/pattern/materials.star` | 已移动 |
| r04 | 20, 98, 200 | `grading.star` | `src/main/resources/data/folkways/folkways/pattern/grading.star` | `mods/vanilla/src/main/resources/data/folkways/folkways/pattern/grading.star` | 已移动 |
| r04 | 20 | `draft/client/LocalPatterns.java` | `J/plugins/build/draft/client/LocalPatterns.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/draft/client/LocalPatterns.java` | 已移动 |
| r04 | 37 | `plugins/person/look/ResidentLook.java` | `J/plugins/person/look/ResidentLook.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/person/look/ResidentLook.java` | 已移动 |
| r04 | 38 | `LookSet.java` | `J/plugins/person/look/LookSet.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/person/look/LookSet.java` | 已移动 |
| r04 | 46 | `draft/Drafting.java` | `J/plugins/build/draft/Drafting.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/draft/Drafting.java` | 已移动 |
| r04 | 56 | `front/api/Schema.java` | `J/front/api/Schema.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/Schema.java` | 已移动 |
| r04 | 63, 125 | `Vocabulary.java` | `J/plugins/build/draft/Vocabulary.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/draft/Vocabulary.java` | 已移动 |
| r04 | 63 | `DraftSite.java` | `J/plugins/build/draft/DraftSite.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/draft/DraftSite.java` | 已移动 |
| r04 | 70, 120 | `front/api/notice/Notice.java` | `J/front/api/notice/Notice.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/notice/Notice.java` | 已移动 |
| r04 | 76 | `pattern/grading.star` | `src/main/resources/data/folkways/folkways/pattern/grading.star` | `mods/vanilla/src/main/resources/data/folkways/folkways/pattern/grading.star` | 已移动 |
| r04 | 78 | `data/folkways/folkways/piece/door.nbt` | `src/main/resources/data/folkways/folkways/piece/door.nbt` | `mods/vanilla/src/main/resources/data/folkways/folkways/piece/door.nbt` | 已移动 |
| r04 | 89 | `plugins/build/BuildSite.java` | `J/plugins/build/BuildSite.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/BuildSite.java` | 已移动 |
| r04 | 94 | `plugins/build/Costs.java` | `J/plugins/build/Costs.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/Costs.java` | 已移动 |
| r04 | 106 | `front/engine/registry/FolkwaysItems.java` | `J/front/engine/registry/FolkwaysItems.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/engine/registry/FolkwaysItems.java` | 已移动 |
| r04 | 106 | `plugins/wares/WaresBlockEntities.java` | `J/plugins/wares/WaresBlockEntities.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/wares/WaresBlockEntities.java` | 已移动 |
| r04 | 106 | `plugins/person/PersonBody.java` | `J/plugins/person/PersonBody.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/person/PersonBody.java` | 已移动 |
| r04 | 107 | `plugins/BuiltinPlugins.java` | `J/plugins/BuiltinPlugins.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/BuiltinPlugins.java` | 已移动 |
| r04 | 107 | `plugins/build/BuildPlugin.java` | `J/plugins/build/BuildPlugin.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/BuildPlugin.java` | 已移动 |
| r04 | 107 | `plugins/person/PersonPlugin.java` | `J/plugins/person/PersonPlugin.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/person/PersonPlugin.java` | 已移动 |
| r04 | 109 | `core/api/resident/ResidentKind.java` | `J/core/api/resident/ResidentKind.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/api/resident/ResidentKind.java` | 已移动 |
| r04 | 110 | `core/api/vocation/VocationSpec.java` | `J/core/api/vocation/VocationSpec.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/api/vocation/VocationSpec.java` | 已移动 |
| r04 | 110 | `core/api/perk/PerkPool.java` | `J/core/api/perk/PerkPool.java` | `mods/core/src/main/java/io/github/izakyl/folkways/effect/perk/PerkPool.java` | 已移动 |
| r04 | 112 | `Searches.java` | `J/core/api/resident/Searches.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/api/resident/Searches.java` | 已移动 |
| r04 | 112 | `plugins/person/walk/Walking.java` | `J/plugins/person/walk/Walking.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/person/walk/Walking.java` | 已移动 |
| r04 | 113 | `core/api/colony/Colony.java` | `J/core/api/colony/Colony.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/api/colony/Colony.java` | 已移动 |
| r04 | 114 | `core/api/colony/ColonyContext.java` | `J/core/api/colony/ColonyContext.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/api/colony/ColonyContext.java` | 已移动 |
| r04 | 114 | `Colony.java` | `J/core/api/colony/Colony.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/api/colony/Colony.java` | 已移动 |
| r04 | 116 | `core/api/passage/Passage.java` | `J/core/api/passage/Passage.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/api/passage/Passage.java` | 已移动 |
| r04 | 116, 185 | `plugins/sable/SablePassage.java` | `J/plugins/sable/SablePassage.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/shell/structure/SablePassage.java` | 已移动 |
| r04 | 116 | `plugins/rail/passage/RailConveyance.java` | `J/plugins/rail/passage/RailConveyance.java` | `mods/create/src/main/java/io/github/izakyl/folkways/create/rail/passage/RailConveyance.java` | 已移动 |
| r04 | 117 | `front/api/Enrollment.java` | `J/front/api/Enrollment.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/Enrollment.java` | 已移动 |
| r04 | 117 | `panel/Board.java` | `J/front/api/panel/Board.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/panel/Board.java` | 已移动 |
| r04 | 118 | `front/api/ui/RegisteringUi.java` | `J/front/api/ui/RegisteringUi.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/ui/RegisteringUi.java` | 已移动 |
| r04 | 118 | `ui/Draw.java` | `J/front/api/ui/Draw.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/ui/Draw.java` | 已移动 |
| r04 | 119 | `front/api/ponder/Scenes.java` | `J/front/api/ponder/Scenes.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/ponder/Scenes.java` | 已移动 |
| r04 | 120 | `NoticeKind.java` | `J/front/api/notice/NoticeKind.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/notice/NoticeKind.java` | 已移动 |
| r04 | 120 | `core/api/terms/RefusalKind.java` | `J/core/api/terms/RefusalKind.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/api/terms/RefusalKind.java` | 已移动 |
| r04 | 132 | `core/engine/colony/ColonyRegistry.java` | `J/core/engine/colony/ColonyRegistry.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/engine/colony/ColonyRegistry.java` | 已移动 |
| r04 | 139 | `FolkwaysConfig.java` | `J/FolkwaysConfig.java` | `mods/core/src/main/java/io/github/izakyl/folkways/FolkwaysConfig.java` | 已移动 |
| r04 | 180 | `blockwright.toml` | `blockwright.toml` | `blockwright.toml` | 路径未变 |
| r04 | 184 | `plugins/build/CreateBlueprintHandoff.java` | `J/plugins/build/CreateBlueprintHandoff.java` | `mods/create/src/main/java/io/github/izakyl/folkways/create/build/CreateBlueprintHandoff.java` | 已移动 |
| r04 | 184 | `CreateHandoffTool.java` | `J/plugins/build/CreateHandoffTool.java` | `mods/create/src/main/java/io/github/izakyl/folkways/create/build/CreateHandoffTool.java` | 已移动 |
| r04 | 184 | `mixin/ToolTypeMixin.java` | `J/plugins/build/mixin/ToolTypeMixin.java` | `mods/create/src/main/java/io/github/izakyl/folkways/create/build/mixin/ToolTypeMixin.java` | 已移动 |
| r04 | 184 | `CreatePackageNetwork.java` | `J/plugins/dispatch/CreatePackageNetwork.java` | `mods/create/src/main/java/io/github/izakyl/folkways/create/dispatch/CreatePackageNetwork.java` | 已移动 |
| r04 | 184 | `CreatePorts.java` | `J/plugins/dispatch/CreatePorts.java` | `mods/create/src/main/java/io/github/izakyl/folkways/create/dispatch/CreatePorts.java` | 已移动 |
| r04 | 184 | `plugins/build/CreateJoiner.java` | `J/plugins/build/CreateJoiner.java` | `mods/create/src/main/java/io/github/izakyl/folkways/create/build/CreateJoiner.java` | 已移动 |
| r04 | 184 | `CreateTrack.java` | `J/plugins/build/CreateTrack.java` | `mods/create/src/main/java/io/github/izakyl/folkways/create/build/CreateTrack.java` | 已移动 |
| r04 | 184 | `CreateObstacles.java` | `J/core/shell/structure/CreateObstacles.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/shell/structure/CreateObstacles.java` | 已移动 |
| r04 | 185 | `core/shell/structure/SableSpaces.java` | `J/core/shell/structure/SableSpaces.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/shell/structure/SableSpaces.java` | 已移动 |
| r04 | 185 | `SableMoves.java` | `J/core/shell/structure/SableMoves.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/shell/structure/SableMoves.java` | 已移动 |
| r04 | 185 | `core/shell/mixin/SableAssemblyMixin.java` | `J/core/shell/mixin/SableAssemblyMixin.java` | `mods/core/src/main/java/io/github/izakyl/folkways/core/shell/mixin/SableAssemblyMixin.java` | 已移动 |
| r04 | 185 | `SablePlugin.java` | `J/plugins/sable/SablePlugin.java` | （无） | 已删除 |
| r04 | 186 | `plugins/golem/GolemPlugin.java` | `J/plugins/golem/GolemPlugin.java` | `mods/modulargolems/src/main/java/io/github/izakyl/folkways/modulargolems/GolemPlugin.java` | 已移动 |
| r04 | 186 | `golem/domain/GolemContent.java` | `J/plugins/golem/domain/GolemContent.java` | `mods/modulargolems/src/main/java/io/github/izakyl/folkways/modulargolems/domain/GolemContent.java` | 已移动 |
| r04 | 186 | `golem/resident/GolemKinds.java` | `J/plugins/golem/resident/GolemKinds.java` | `mods/modulargolems/src/main/java/io/github/izakyl/folkways/modulargolems/resident/GolemKinds.java` | 已移动 |
| r04 | 186 | `Golems.java` | `J/plugins/golem/resident/Golems.java` | `mods/modulargolems/src/main/java/io/github/izakyl/folkways/modulargolems/resident/Golems.java` | 已移动 |
| r04 | 187 | `plugins/person/ResidentGeoBackend.java` | `J/plugins/person/ResidentGeoBackend.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/person/ResidentGeoBackend.java` | 已移动 |
| r04 | 188 | `plugins/person/look/MaidLooks.java` | `J/plugins/person/look/MaidLooks.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/person/look/MaidLooks.java` | 已移动 |
| r04 | 188 | `MaidAssets.java` | `J/plugins/person/look/MaidAssets.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/person/look/MaidAssets.java` | 已移动 |
| r04 | 188 | `Molang.java` | `J/plugins/person/look/Molang.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/person/look/Molang.java` | 已移动 |
| r04 | 188 | `ClientMaidModels.java` | `J/plugins/person/look/ClientMaidModels.java` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/person/look/ClientMaidModels.java` | 已移动 |
| r04 | 189 | `front/engine/charter/FtbTeams.java` | `J/front/engine/charter/FtbTeams.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/engine/charter/FtbTeams.java` | 已移动 |
| r04 | 189 | `Teams.java` | `J/front/engine/charter/Teams.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/engine/charter/Teams.java` | 已移动 |
| r04 | 190 | `front/client/FolkwaysJeiPlugin.java` | `J/front/client/FolkwaysJeiPlugin.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/client/FolkwaysJeiPlugin.java` | 已移动 |
| r04 | 190 | `front/client/FilterTargets.java` | `J/front/client/FilterTargets.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/client/FilterTargets.java` | 已移动 |
| r04 | 191 | `front/client/FolkwaysEmiPlugin.java` | `J/front/client/FolkwaysEmiPlugin.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/client/FolkwaysEmiPlugin.java` | 已移动 |
| r04 | 192 | `front/client/ShoulderAim.java` | `J/front/client/ShoulderAim.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/client/ShoulderAim.java` | 已移动 |
| r04 | 193 | `front/client/Lessons.java` | `J/front/client/Lessons.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/client/Lessons.java` | 已移动 |
| r04 | 194 | `quarry.star` | `src/main/resources/data/folkways/folkways/pattern/quarry.star` | `mods/vanilla/src/main/resources/data/folkways/folkways/pattern/quarry.star` | 已移动 |
| r05 | 29 | `gradle/wrapper/gradle-wrapper.properties` | `gradle/wrapper/gradle-wrapper.properties` | `gradle/wrapper/gradle-wrapper.properties` | 路径未变 |
| r05 | 34, 57, 61, 62 | `blockwright.toml` | `blockwright.toml` | `blockwright.toml` | 路径未变 |
| r05 | 82, 324 | `.github/workflows/build.yml` | `.github/workflows/build.yml` | `.github/workflows/build.yml` | 路径未变 |
| r05 | 88 | `tests/ldlib2/index.ts` | `tests/ldlib2/index.ts` | `tests/ldlib2/index.ts` | 路径未变 |
| r05 | 89, 310 | `.claude/settings.json` | `.claude/settings.json` | `.claude/settings.json` | 路径未变 |
| r05 | 90, 325 | `CONTRIBUTING.md` | `CONTRIBUTING.md` | `CONTRIBUTING.md` | 路径未变 |
| r05 | 126, 291 | `tests/ldlib2/adapter.ts` | `tests/ldlib2/adapter.ts` | `tests/ldlib2/adapter.ts` | 路径未变 |
| r05 | 135 | `tests/bench/probes/census.ts` | `tests/bench/probes/census.ts` | `tests/bench/probes/census.ts` | 路径未变 |
| r05 | 165 | `tests/shared/harness/mod-settings.ts` | `tests/shared/harness/mod-settings.ts` | `tests/shared/harness/mod-settings.ts` | 路径未变 |
| r05 | 178 | `build.gradle` | `build.gradle` | `build.gradle`（根，已缩成聚合）+ `gradle/mod.gradle` + mods/{core,vanilla,create,modulargolems}/build.gradle | 已拆分 |
| r05 | 202 | `blueprint/test_hut.nbt` | `src/gametest/resources/data/folkways/folkways/blueprint/test_hut.nbt` | `mods/vanilla/src/gametest/resources/data/folkways/folkways/blueprint/test_hut.nbt` | 已移动 |
| r05 | 202 | `pattern/test_grower.star` | `src/gametest/resources/data/folkways/folkways/pattern/test_grower.star` | `mods/vanilla/src/gametest/resources/data/folkways/folkways/pattern/test_grower.star` | 已移动 |
| r05 | 202 | `pattern/test_slab.star` | `src/gametest/resources/data/folkways/folkways/pattern/test_slab.star` | `mods/vanilla/src/gametest/resources/data/folkways/folkways/pattern/test_slab.star` | 已移动 |
| r05 | 203 | `plugins/build/SiteRig.java` | `GT/plugins/build/SiteRig.java` | `mods/vanilla/src/gametest/java/io/github/izakyl/folkways/plugins/build/SiteRig.java` | 已移动 |
| r05 | 203 | `core/engine/plan/PlanningFixture.java` | `GT/core/engine/plan/PlanningFixture.java` | `mods/core/src/gametest/java/io/github/izakyl/folkways/core/engine/plan/PlanningFixture.java` | 已移动 |
| r05 | 203 | `plugins/build/draft/DraftKit.java` | `GT/plugins/build/draft/DraftKit.java` | `mods/vanilla/src/gametest/java/io/github/izakyl/folkways/plugins/build/draft/DraftKit.java` | 已移动 |
| r05 | 205 | `front/api/notice/TextSyncGameTests.java` | `GT/front/api/notice/TextSyncGameTests.java` | `mods/core/src/gametest/java/io/github/izakyl/folkways/front/api/notice/TextSyncGameTests.java` | 已移动 |
| r05 | 212 | `tests/fuzz/campaign.ts` | `tests/fuzz/campaign.ts` | （无） | 已删除 |
| r05 | 245 | `tick-meter.ts` | `tests/bench/probes/tick-meter.ts` | `tests/bench/probes/tick-meter.ts` | 路径未变 |
| r05 | 246 | `work-tap.ts` | `tests/bench/probes/work-tap.ts` | `tests/bench/probes/work-tap.ts` | 路径未变 |
| r05 | 247 | `census.ts` | `tests/bench/probes/census.ts` | `tests/bench/probes/census.ts` | 路径未变 |
| r05 | 253 | `tests/bench/report/labor-share.ts` | `tests/bench/report/labor-share.ts` | `tests/bench/report/labor-share.ts` | 路径未变 |
| r05 | 254 | `tests/bench/report/engine-diagnostics.ts` | `tests/bench/report/engine-diagnostics.ts` | `tests/bench/report/engine-diagnostics.ts` | 路径未变 |
| r05 | 255 | `tests/bench/report/judgements.ts` | `tests/bench/report/judgements.ts` | `tests/bench/report/judgements.ts` | 路径未变 |
| r05 | 265 | `tools/save-town.ts` | `tests/bench/tools/save-town.ts` | `tests/bench/tools/save-town.ts` | 路径未变 |
| r05 | 273 | `tests/shared/capture/visual-kit.ts` | `tests/shared/capture/visual-kit.ts` | `tests/shared/capture/visual-kit.ts` | 路径未变 |
| r05 | 277 | `visual-teardown.ts` | `tests/visual/visual-teardown.ts` | `tests/visual/visual-teardown.ts` | 路径未变 |
| r05 | 278 | `tests/shared/capture/layout-lint.ts` | `tests/shared/capture/layout-lint.ts` | `tests/shared/capture/layout-lint.ts` | 路径未变 |
| r05 | 284 | `tests/promo/promo-kit.ts` | `tests/promo/promo-kit.ts` | `tests/promo/promo-kit.ts` | 路径未变 |
| r05 | 285 | `tests/promo/film/promo-text.toml` | `tests/promo/film/promo-text.toml` | `tests/promo/film/promo-text.toml` | 路径未变 |
| r05 | 287 | `tests/bench/film/overlay.ts` | `tests/bench/film/overlay.ts` | `tests/bench/film/overlay.ts` | 路径未变 |
| r05 | 292, 321 | `promo-text.toml` | `tests/promo/film/promo-text.toml` | `tests/promo/film/promo-text.toml` | 路径未变 |
| r05 | 323 | `campaign.ts` | `tests/fuzz/campaign.ts` | （无） | 已删除 |
| r05 | 323 | `fuzz-kit.ts` | `tests/fuzz/fuzz-kit.ts` | （无） | 已删除 |
| r05 | 325, 325 | `package.json` | `package.json` | `package.json` | 路径未变 |
| r05 | 336 | `build.yml` | `.github/workflows/build.yml` | `.github/workflows/build.yml` | 路径未变 |
| w05 | 95, 125 | `blockwright.toml` | `blockwright.toml` | `blockwright.toml` | 路径未变 |
| w05 | 98 | `package.json` | `package.json` | `package.json` | 路径未变 |
| w06 | 18, 68, 74, 226 | `build.gradle` | `build.gradle` | `build.gradle`（根，已缩成聚合）+ `gradle/mod.gradle` + mods/{core,vanilla,create,modulargolems}/build.gradle | 已拆分 |
| w06 | 24, 24, 25, 76 | `blockwright.toml` | `blockwright.toml` | `blockwright.toml` | 路径未变 |
| w06 | 40 | `gradle/wrapper/gradle-wrapper.properties` | `gradle/wrapper/gradle-wrapper.properties` | `gradle/wrapper/gradle-wrapper.properties` | 路径未变 |
| w06 | 60, 68 | `package.json` | `package.json` | `package.json` | 路径未变 |
| w06 | 68, 74 | `settings.gradle` | `settings.gradle` | `settings.gradle` | 路径未变 |
| w06 | 74, 75, 451 | `gradle.properties` | `gradle.properties` | `gradle.properties` | 路径未变 |
| w06 | 214 | `.claude/settings.json` | `.claude/settings.json` | `.claude/settings.json` | 路径未变 |
| w06 | 301 | `.github/workflows/build.yml` | `.github/workflows/build.yml` | `.github/workflows/build.yml` | 路径未变 |
| d12 | 107 | `core/api/library/Shelves.java` | `J/core/api/library/Shelves.java` | `mods/core/src/main/java/io/github/izakyl/folkways/library/Shelves.java` | 已移动 |
| d12 | 108 | `front/api/Schema.java` | `J/front/api/Schema.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/Schema.java` | 已移动 |
| d12 | 109 | `front/api/panel/Board.java` | `J/front/api/panel/Board.java` | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/panel/Board.java` | 已移动 |
| d12 | 139 | `package.json` | `package.json` | `package.json` | 路径未变 |
| d12 | 139, 139, 143, 145 | `blockwright.toml` | `blockwright.toml` | `blockwright.toml` | 路径未变 |

### 4.10 附录 B：目录级 / 类名级 / 配置文件名引用（无行号）

| 文档:行 | 原文片段 | 新位置 / 变化 |
| --- | --- | --- |
| r01:4 | `src/main/java` | src/main/java → mods/{core,vanilla,create,modulargolems}/src/main/java |
| r01:48 | `FolkwaysConfig` | FolkwaysConfig（单份服务端配置）→ core FolkwaysConfig + vanilla FolkwaysVanillaConfig + create FolkwaysCreateConfig |
| r01:110 | `FolkwaysConfig` | FolkwaysConfig（单份服务端配置）→ core FolkwaysConfig + vanilla FolkwaysVanillaConfig + create FolkwaysCreateConfig |
| r01:110 | `folkways-server.toml` | folkways-server.toml → folkways_core-server.toml / folkways_vanilla-server.toml / folkways_create-server.toml |
| r01:124 | `src/main/resources` | src/main/resources → mods/{core,vanilla,create,modulargolems}/src/main/resources（按内容拆分） |
| r01:163 | `FolkwaysConfig` | FolkwaysConfig（单份服务端配置）→ core FolkwaysConfig + vanilla FolkwaysVanillaConfig + create FolkwaysCreateConfig |
| r02:11 | `src/main/resources` | src/main/resources → mods/{core,vanilla,create,modulargolems}/src/main/resources（按内容拆分） |
| r02:197 | `src/gametest` | src/gametest → mods/{core,vanilla,create}/src/gametest（modulargolems 无 gametest 目录） |
| r02:203 | `FolkwaysConfig` | FolkwaysConfig（单份服务端配置）→ core FolkwaysConfig + vanilla FolkwaysVanillaConfig + create FolkwaysCreateConfig |
| r02:205 | `src/main/resources` | src/main/resources → mods/{core,vanilla,create,modulargolems}/src/main/resources（按内容拆分） |
| r03:3 | `core/api/library/**` | core/api/library → mods/core/…/library |
| r03:4 | `src/main/java` | src/main/java → mods/{core,vanilla,create,modulargolems}/src/main/java |
| r03:157 | `FolkwaysConfig` | FolkwaysConfig（单份服务端配置）→ core FolkwaysConfig + vanilla FolkwaysVanillaConfig + create FolkwaysCreateConfig |
| r04:15 | `src/main/java` | src/main/java → mods/{core,vanilla,create,modulargolems}/src/main/java |
| r04:121 | `BuildMixinPlugin` | plugins/build/mixin/BuildMixinPlugin → mods/create/…/create/build/mixin/CreateBuildMixinPlugin（改名并移至 create） |
| r04:139 | `folkways-server.toml` | folkways-server.toml → folkways_core-server.toml / folkways_vanilla-server.toml / folkways_create-server.toml |
| r04:180 | `src/main/resources` | src/main/resources → mods/{core,vanilla,create,modulargolems}/src/main/resources（按内容拆分） |
| r04:184 | `plugins/rail/**` | plugins/rail → mods/create/…/create/rail（RailPlugin、RailScene、domain/、passage/） |
| r04:184 | `plugins/dispatch/**` | plugins/dispatch → mods/create/…/create/dispatch |
| r04:184 | `CreateMod` | plugins/CreateMod → mods/create/…/create/CreateMod |
| r04:204 | `folkways-server.toml` | folkways-server.toml → folkways_core-server.toml / folkways_vanilla-server.toml / folkways_create-server.toml |
| r05:12 | `src/gametest` | src/gametest → mods/{core,vanilla,create}/src/gametest（modulargolems 无 gametest 目录） |
| r05:33 | `src/gametest` | src/gametest → mods/{core,vanilla,create}/src/gametest（modulargolems 无 gametest 目录） |
| r05:104 | `src/main/java` | src/main/java → mods/{core,vanilla,create,modulargolems}/src/main/java |
| r05:165 | `folkways-server.toml` | folkways-server.toml → folkways_core-server.toml / folkways_vanilla-server.toml / folkways_create-server.toml |
| r05:185 | `src/gametest` | src/gametest → mods/{core,vanilla,create}/src/gametest（modulargolems 无 gametest 目录） |
| r05:199 | `src/gametest` | src/gametest → mods/{core,vanilla,create}/src/gametest（modulargolems 无 gametest 目录） |
| r05:202 | `src/gametest` | src/gametest → mods/{core,vanilla,create}/src/gametest（modulargolems 无 gametest 目录） |
| r05:305 | `src/gametest` | src/gametest → mods/{core,vanilla,create}/src/gametest（modulargolems 无 gametest 目录） |
| w05:51 | `src/gametest` | src/gametest → mods/{core,vanilla,create}/src/gametest（modulargolems 无 gametest 目录） |
| w05:104 | `src/gametest` | src/gametest → mods/{core,vanilla,create}/src/gametest（modulargolems 无 gametest 目录） |
| w05:193 | `src/gametest` | src/gametest → mods/{core,vanilla,create}/src/gametest（modulargolems 无 gametest 目录） |
| w05:623 | `src/gametest` | src/gametest → mods/{core,vanilla,create}/src/gametest（modulargolems 无 gametest 目录） |
| w06:168 | `src/main/java` | src/main/java → mods/{core,vanilla,create,modulargolems}/src/main/java |

---

## 5. 对我们文档结论的影响

> 只列条目 + 理由 + 建议改成什么，**不改被点名的文档**。「所在」行号按本文生成时点读取。类别：**失效** = 结论/事实陈述不再成立；**措辞** = 方向对但路径、名称、归属需改；**数字** = 计数过期。§4 主表已覆盖的纯行号漂移不在此重复。

### 5.1 失效或需改措辞的条目

#### 构建与工程（r05、w05、w06、d12）

| # | 所在 | 原陈述 | 理由（新证据） | 建议改成 | 类别 |
| --- | --- | --- | --- | --- | --- |
| F-01 | r05:40、w05:50/94/191、w06:18/178-182、d12:144 | `build.gradle:81-89` 的 `lib()` 读 `file(".blockwright/mods.json")` | `lib()` 现在是 `gradle/mod.gradle:39-47` 的 `ext.lib`，读 `rootProject.file(...)`；调用点分散在 `mods/*/build.gradle`，根项目经 `core.lib("create")` 使用（新 `build.gradle:70`）。机制与报错文案不变（`gradle/mod.gradle:44`） | 引用改指 `gradle/mod.gradle:39-47`；w06:181-182 的代码引文改为 `rootProject.file(".blockwright/mods.json")` 与 `ext.lib = { … files(paths.collect { rootProject.file(it) }) }` | 措辞 |
| F-02 | w06:75（B-2）、w06:83、w06:565（OQ-B-5）、d12:75、d12:233（OQ-6） | 改 `gradle.properties` 的 `mod_id=plaa` / `archives_base_name`，产物名 `plaa-neoforge-1.21.1` | 新 `gradle.properties` 已无 `mod_id`、`archives_base_name`（新 `gradle.properties:1-18`）；modid 在每个 `mods/*/build.gradle:7`（`ext.modId`），产物名由 `ext.modName`（`:8`）经 `gradle/mod.gradle:6-8` 决定；Java 里另有 4 处 `ID` 常量（`FolkwaysMod.java:63`、`FolkwaysVanillaMod.java:14`、`FolkwaysCreateMod.java:13`、`FolkwaysModularGolemsMod.java:9`）与资源命名空间常量 `FolkwaysMod.MOD_ID = "folkways"`（`:60`）；各 toml 以 `[${version}]` 互相精确钉版（`mods/vanilla/…/neoforge.mods.toml:32`、`mods/create/…:32,40`、`mods/modulargolems/…:32,40`）。d12:233 的 OQ-6 已提出此问题，下列事实是它的输入 | B-2 的改名清单改为：每个子项目的 `ext.modId`/`ext.modName`、对应 toml 的依赖 modId、Java 常量、`blockwright.toml` 的 `[mods.folkways_*]` 与 `[coverage]`；`gradle.properties` 一行都不用改。是否保留命名空间 `folkways` 另议（见 §6） | 失效 |
| F-03 | w06:164、w06:167、r05:152、r05:142 | `[mods.folkways]` → `build/libs/folkways-*.jar`；profile 列表含 `fuzz` | 四条 `[mods.folkways_*]`（新 `blockwright.toml:16-26`）；`[profile.fuzz]` 已删（旧 `blockwright.toml:284-294`）；profile 区间旧 `:146-312` → 新 `:156-310` | 更新条目与行号；profile 列表去 `fuzz` | 失效 |
| F-04 | r05:26、w06:421、w06:458 | 产物 `folkways-neoforge-1.21.1`（+ `-sources`、`-api`、`-fuzz`）；`build/libs/*.jar` 含 `-sources`/`-api` | 四个 jar，名由 `${modName}-neoforge-${minecraft_version}` 决定（`gradle/mod.gradle:6-8`）；`-api` 只有 core（`mods/core/build.gradle:43-48`）；无 `-fuzz`；根 `build/libs` 由 `collectJars` 收集（`build.gradle:90-93`），⚠️ 推断其中只含各子项目 `jar` 任务产物，`-sources` 留在 `mods/<x>/build/libs` | 改为「四个 jar：`folkways-{core,vanilla,create,modulargolems}-neoforge-1.21.1-<ver>.jar`（⚠️ 版本后缀未实测）」；`-api` 仅 core | 失效 |
| F-05 | r05:33-34、r05:101、r05:110、r05:152、r05:207-227（§4.2、§4.3-3）、r05:323、r05:336、w05:96、w05:98、w05:110、w06:167、w06:438、w06:459、w06:566（OQ-B-6） | fuzz 源集、`fuzzJar`、`npm run fuzz:run`、`tests/fuzz`、`[profile.fuzz]`、「六层」里含 fuzz | 全部不存在：新根/子项目 `build.gradle` 无 `fuzz`；`tests/fuzz/` 整体删除（旧 24 个文件）；`package.json:8` 的 typecheck 与脚本表无 fuzz（`:6-18`）；`tests/shared/harness/budgets.ts` 无 `fuzz` 预算（旧 `:11-12`）；`tests/shared/harness/out-paths.ts:10-15` 无 `fuzz` 桶。提交说明为「fuzzers 暂停」 | r05 §4.2/§4.3 标注「旧快照 f42e3c1 的做法，67f28b0 已暂停并删除」，复用点 3（`fuzzJar`）和问题 7（三个 fuzz target）不再作为现行推荐；w05/w06 的命令表去掉 `fuzz:run`；OQ-B-6 改为「上游已暂停，是否自建」 | 失效 |
| F-06 | r05:33、w05:96 | `sourceSets.gametest` 默认目录 `src/gametest/java`；「gametest 是独立源集，能引用 main 的输出」 | 仍是独立源集，但**每个子项目各有一个**（`gradle/mod.gradle:24-26`，目录 `mods/{core,vanilla,create}/src/gametest`，modulargolems 无）；引用链：core ← vanilla ← create（`mods/core/build.gradle:39-40`、`mods/vanilla/build.gradle:31`、`mods/create/build.gradle:21-22`） | 「每个子项目一个 gametest 源集，由根项目聚合运行」 | 措辞 |
| F-07 | r05:204、r05:105、w05:97、w05:195、w06:360-363、w06:440、d12:215 | `runGameTestServer` 的定义在 `build.gradle:55-63`，含 `sourceSet=gametest`；依赖 `gametestRuntimeOnly` create；namespace 行加 `plaa` | 定义移到根 `build.gradle:47-54`，无 `sourceSet` 行；聚合方式见 §2.2；create 真 jar 为根 `runtimeOnly core.lib("create")`（`build.gradle:70`）；namespace 字符串所在行 `build.gradle:52`；**只有根项目有 `runs`**（`gradle/mod.gradle`、`mods/*/build.gradle` 中无 `runs`，grep 确认），因此子项目不能单独 `runGameTestServer`（⚠️ 推断自此，未实测） | 命令仍写 `./gradlew runGameTestServer`；「`plaa` 加进 `build.gradle:52`」；说明它同时跑 core+vanilla+create 的全部 gametest，modulargolems 不在其内（`build.gradle:15-16`） | 措辞 |
| F-08 | r05:188 | 示例 `@EventBusSubscriber(modid = FolkwaysMod.MOD_ID …)` | 新 gametest 写法为 `modid = FolkwaysMod.CORE_ID`，而 `@GameTestHolder(FolkwaysMod.MOD_ID)` 不变（新 `mods/core/src/gametest/java/io/github/izakyl/folkways/core/api/ground/GroundGameTests.java:22-23`）。对我们意味着：订阅用 modid（`folkways_core`），测试命名空间仍用 `folkways` | 示例改为 `CORE_ID` / `MOD_ID` 混用的现状 | 措辞 |
| F-09 | r05:53-55 | 三档集成：create 为 `gametestRuntimeOnly`；ponder/starlark/flywheel 随 jar 内嵌；LDLib2 `compileOnly` 之外用 `instanceMod` | create → 根 `runtimeOnly`；jarJar 按 mod 分家：ponder/flywheel 在 core（`mods/core/build.gradle:22-35`），starlark 在 vanilla（`mods/vanilla/build.gradle:23-29`）；LDLib2 现为 core 的 `api(...)`（`mods/core/build.gradle:36`）+ 根 `runtimeOnly`（`build.gradle:69`）+ `instanceMod`（`build.gradle:75-77`） | 三档表按 mod 重写 | 措辞 |
| F-10 | r05:35 | `apiJar` 打包 `Declaring`/`Relating`/`core/api/**`/`front/api/**`，「我们自研插件最可能直接依赖」 | 现在 `include "io/github/izakyl/folkways/core/api/**", "…/front/api/**"` 且只在 core（`mods/core/build.gradle:43-48`）；`Declaring`、`Relating` 本就位于 `core/api/`。但 **perk/effect、`Ledger`（`base/`）、`Shelves`（`library/`）已不在该 include 内** ⚠️（推断：include 只列这两个包前缀）——而我们的插件很可能要用 `PerkPool`/`Shelves`/`Ledger` | 注明 apiJar 的 include 只剩 `core/api/**` 与 `front/api/**`（`mods/core/build.gradle:46`），不含 `effect/**`、`base/**`、`library/**` | 失效 |
| F-11 | r05:12、r05:105、r05:106、w06:26、w06:313、w06:366、d12:59、d12:176 | 840 个 .java / 85 个 gametest 类 / 488 个 `@GameTest` / 44 个 e2e / 182 个 .ts | 新：858 / 87 / 496 / 45 / 176（§总览表） | 更新数字，并标注口径（grep 计数） | 数字 |
| F-12 | r05:164-165 | `seedInstance().write("config/folkways-server.toml", …)` | 新 `tests/shared/harness/mod-settings.ts:36-40` 写两份：`config/folkways_vanilla-server.toml`（zones/crafting）与 `config/folkways_core-server.toml`（planning） | 改为两份文件 | 失效 |
| F-13 | r05:325（§7 第 9 项） | `CONTRIBUTING.md` 写 `npm run promo:take` 但 `package.json` 里没有这个 script | 新 `package.json:18` 已有 `"promo:take"` | 删除该不一致项 | 失效 |
| F-14 | r05:318、r05:337 | 裸 `gradle` 调用点三处：`package.json:6`、`tests/shared/harness/setup.ts:21`、`tests/fuzz/global-setup.ts:10` | 第三处随 fuzz 删除；`package.json:6` 仍是 `gradle build`，`setup.ts:21` 仍在（逐行比对相等） | 改为两处 | 数字 |
| F-15 | r05:82、w06:310-313（CI 描述） | CI 只跑 build/typecheck/unit，上传 `build/libs/*.jar` | 仍成立（`build.yml:25-34` 步骤相同）；但 nightly 的 release 说明与产物名变了（`build.yml:32,48,57-65`），且 `./gradlew build` 现在还会触发各子项目 `:build` 与 `compileGametestJava`（`build.gradle:95-98`、`:130-133`） | 补一句 | 措辞 |
| F-16 | w05:93、w05:94、w05:191-193 | M1-WP0 的「干净机器出 jar」「jar 在 `build/libs/`」 | 现在是四个 jar；`GradleException` 触发点在 `gradle/mod.gradle:44`；WP0-T2「文件存在且被 `build.gradle:81-89` 接受」需改指 `gradle/mod.gradle:39-47` | G1 验收改为「`build/libs/` 有 4 个 jar」 | 措辞 |
| F-17 | w06:471（Top-10 失败 #2） | 检查 `build.gradle:14-19` 四个仓库 | 现在在 `build.gradle:18-23` 与 `gradle/mod.gradle:10-15` 两处 | 同时指两处 | 措辞 |

#### 引擎、插件与玩法（r01–r04、w05、d12）

| # | 所在 | 原陈述 | 理由（新证据） | 建议改成 | 类别 |
| --- | --- | --- | --- | --- | --- |
| F-18 | r01:3、r01:5、r03:3、r02:7/11/12、r04:3-4、r05:7/11 | 研究对象 `reference/folkways-master`；`core/**` 261 个（API 124 + engine 128）、`front/**` 191、`plugins/**` 386；r02 「13 个目录 / 384 个 .java」 | 新：`core/api` 113、`core/engine` 129、`core/shell` 10（合 252）；另 `base` 5、`effect` 10、`library` 3；`front` 195；插件类分布 vanilla 285 / create 92 / modulargolems 14（含各 mod 入口与配置类）；「13 个目录」不再对应任何目录结构（vanilla 9 + create 3 + golems 1，且 sable 已非插件） | 「范围」改写为 `reference/folkways-67f28b0/mods/*`，并给出新计数 | 数字 |
| F-19 | r01:12、r01:128 | 「注册表集中在 `core/api/Ledger.java`」 | 现为 `mods/core/…/base/Ledger.java`（与 `FolkwaysMixinPlugin`、`persist/` 同在 `base`）；`PerkPool`/`GlobalPerks` 在 `effect/perk`，`Shelves` 在 `library` | 路径改为 `base/Ledger.java`；「`core/api` 是唯一公共面」需加注：`base`、`effect`、`library` 也被上层 mod 直接 import（例如 `mods/create/src/main/java/io/github/izakyl/folkways/create/FolkwaysCreateMod.java:3` import `effect.perk.PerkPool`） | 措辞 |
| F-20 | r01:14 | 「内容层（`plugins/**`）：内置玩法，用与第三方相同的 API 写就」 | 内容层现在分三个 mod：`vanilla/plugins`、`create/create`、`modulargolems/modulargolems`；后两者是**独立 jar**，已经是「第三方式」用法的官方实例（`FolkwaysCreateMod.java:20`、`FolkwaysModularGolemsMod.java:12`） | 改述为「内容层 = 三个上层 mod；golems/create 是最贴近第三方的样例」 | 措辞 |
| F-21 | r01:81、r01:88、r04:110-111、r04:209、w05:213/237 | Perk/PerkPool/GlobalPerks「影响 `Workload.Haste`、XP」；`Workload.Haste` 由 perk 阶梯算（旧 `Workload.java:76` `Haste.ranked(perk, byRank)`）；`ResidentEntity` 以 transient modifier 实现 perk 的速度修正 | 新增 `effect` 层：`Perk` 是 `record Perk(String id, int maxRank, Grant grant)`，`Grant` 产出 `Modifier`（`effect/perk/Perk.java:14-68`）；`Stats` 定义 `WORK_SPEED`/`MOVE_SPEED`/`REACH`/`PACK_ROOM`/`APPETITE` 与 `Flag PATIENT`（`effect/Stats.java:9-24`）；`Workload.Haste.of(trade)` 读 `who.effects().value(Stats.WORK_SPEED, trade)`（`core/api/work/Workload.java:76-79`）；速度/触及/背包写属性由 `Bodies.carry`（`core/api/resident/body/Bodies.java:48-56`，`addTransientModifier` 在 `:72`）统一执行，`ResidentEntity` 里的内联代码已删，只在 `:292` 调 `refreshEffects()`；食欲由 `Stats.APPETITE` 驱动（`plugins/person/living/LivingPresence.java:127,141`）；`GlobalPerks.install` 现带参 `FolkwaysConfig::asceticAppetite`（`effect/perk/GlobalPerks.java:28`、`FolkwaysMod.java:110`）。`Body.effects()` 目前只返回 perk 产生的 `Effects`（`Body.java:46-48`、`BodyPerks.java:108-115`）⚠️（推断：未见 mood/place 等其他来源的接入点，尽管 `Effects.java:9-10` 注释写了 a perk, a mood, a place） | w05 WP-2「效率修正走 transient modifier、不改 `BodyRunner`」改为「效率修正走 `effect` 层（新增 `Stat` / `Perk.Grant` 或扩展来源），`BodyRunner` 不动」；AC-21 的「总乘数夹取 [0.55, 1.20]」要与上游 `Stat` 自带夹取（`WORK_SPEED` 0.05–20.0，`Stats.java:9`）协调；r01:81/88 改写为 Perk → Grant → Modifier → Effects → 消费方 | 失效 |
| F-22 | r01:110、r04:139、r04:204、r04:218 | 单一配置 `FolkwaysConfig` → 每个世界 `serverconfig/folkways-server.toml`；「全部可调项」 | 三个 `ModConfig.Type.SERVER`：`folkways_core-server.toml`、`folkways_vanilla-server.toml`、`folkways_create-server.toml`（新 `README.md:109`）；golems 无配置（§1.4） | 改为三份并列出归属（§1.4） | 失效 |
| F-23 | r01:150、r01:152、r01:163、r02:203、r04:140-157 | 旋钮清单与默认值都挂在 `FolkwaysConfig` | 默认值与键名不变，归属变了：dispatchReachTicks/seatTicks/conductingHaste/dispatchHaste → create；immigration/zones/blueprints/crafting/5 个 `*Haste`/pathSearchBudget → vanilla；其余 → core（§1.4）。r01:163「只在 `FolkwaysConfig` 允许的旋钮上调优」因此需要三处出处 | 在表里加「所属配置文件」列 | 措辞 |

| F-24 | r01:91、r01:143、w05:70、w05:153、w05:207-209（WP-1）、w05:321-334（WP-6） | 「M1 的差异化 = 画了区之后玩家知道为什么没生效」；`Unassigned`/`Why`/`Shortfall` 等诊断原料只有部分可读 | 上游 `67f28b0` 已落地一个最小实现：公共记录 `Stall`（`core/api/work/Stall.java:14`）、`Colony.stallsIn(dimension)`（`core/api/colony/Colony.java:36-37`）、`Weaver.stalls()`（`core/engine/plan/Weaver.java:582` 起）、`Stalls` 的稳定判据（`SETTLE_TICKS = 100`、`MET_TIMES = 2`、`FORGET_TICKS = 1_200`，`core/engine/labor/Stalls.java:19-24`）、新增 `LaborRefusal.NO_SOURCE/NO_ROOM_FOR/NO_WAY_FOR/NO_ONE_MAKES`（`core/engine/labor/LaborRefusal.java:14-17`）、玩家侧 `ColonyStalls`（`front/engine/colony/ColonyStalls.java`）与区域设置窗的 `stalled` 元素（`front/ui/screen/ZoneSettings.java:147`）。**与我们 WP-6/PRD-006 重叠**：上游已能在卡片/区域窗里说「这块活因缺 X/无路/无人会做而停着」 | w05 与 PRD-006 对标时把 `Stall` 当作既有基底：WP-1 的「提升为公开只读」清单去掉已公开的项；WP-6 的 ≥8 类阻塞与上游 5 类 stall 对齐，避免并行造两套 | 失效 |
| F-25 | r02:117-122、r03:104、r03:114、r03:159 | 「巡逻没有自己的页面或命令：它就是 LINE 手势 + `PatrolContent.BEAT = Shape.Path(maxPatrolPoints)`」；r02 §2.8 无页面 | 新 `PatrolContent` 有 `PAGE = PageKind.boarded(ID, "folkways.page.patrol", …)`（`plugins/patrol/PatrolContent.java:38-39`）、`registering.facing(...)`（`:62`）、Enrollment 带 `Schema.none(), List.of(PAGE)`（`:63-65`）；`PatrolPresence implements Facing`（`plugins/patrol/PatrolPresence.java:47`）；lang 新增 `folkways.page.patrol` / `.count` / `.empty`（`mods/core/src/main/resources/assets/folkways/lang/en_us.json:340-342`，zh_cn 为「巡逻 / 路线 / 没有画出巡逻路线」）。页内具体控件未细读 ⚠️ | r03 把巡逻加入「已有页面的插件」表（r03:66-75），删除「没有自己的页面」；「没有战斗指令」（r03:159）仍成立但措辞要避开「没有页面」 | 失效 |
| F-26 | r02:20 | 「`XPlugin.install(IEventBus)` 在 `plugins/BuiltinPlugins.java`——每个插件唯一入口」 | `BuiltinPlugins.install` 只装 9 个 vanilla 插件（新 `…/plugins/BuiltinPlugins.java:20-30`），由 `FolkwaysVanillaMod` 构造器调用（`:21`）；Create 的由 `CreatePlugins.install`（`FolkwaysCreateMod.java:20`）、Golem 的由 `FolkwaysModularGolemsMod` 构造器直接装（`:12`）。Core 自己不再 `BuiltinPlugins.install`（旧 `FolkwaysMod.java:70` 已无） | 「每个上层 mod 在自己的 `@Mod` 构造器里装自己的插件」；r04:107「仿 `BuiltinPlugins` 的 `install`」可保留，另增 create/golems 两个独立 mod 样例 | 失效 |
| F-27 | r02:36-57（总表）、r02:131-163（§2.10–2.13）、r04:116、r04:182-186、r04:185 | rail/dispatch/golem/sable 是「`plugins/` 下的插件」；golem、sable「可选」 | rail/dispatch → `folkways_create`（需 Create **且**本 jar，`mods/create/…/neoforge.mods.toml:44-50`）；golem → `folkways_modulargolems`（`mods/modulargolems/…/neoforge.mods.toml:44-50`，对 `modulargolems` 为 required）；sable 不再是插件：`SablePlugin` 删除，`SablePassage` 在 `core/shell/structure/`，探测在 `FolkwaysMod.fitTheShell`（`FolkwaysMod.java:91-95`）。规模「sable 2 / 176」过期（现 1 个类）。r02:152「toml 未声明 sable」仍成立 | 总表加「所属 mod」列；sable 行改为「core 内置适配（非插件）」；「可选」改述为「独立 jar，可选安装」或「core 内按 `ModList` 探测」 | 失效 |
| F-28 | r04:121 | mixin 门控类 `CoreMixinPlugin/BuildMixinPlugin/DispatchMixinPlugin` | 现为 `CoreMixinPlugin`（core，`core/shell/mixin/CoreMixinPlugin.java`）、`PersonMixinPlugin`（vanilla）、`CreateBuildMixinPlugin`/`DispatchMixinPlugin`/`RailMixinPlugin`（create）；`BuildMixinPlugin` 不存在；每个 mixin 配置须在**所属 jar** 的 toml 里声明 `[[mixins]]`（core `:76-86`、vanilla `:44-51`、create `:52-59`） | 更新类名与归属；加上「mixin 配置跟 jar 走」 | 措辞 |
| F-29 | r04:180、r04:184-186 | 依赖声明在一份 toml 的 `:36-90`；Create/Golem 为 optional（BOTH） | 见 §3：Create 在 core 里 optional、在 `folkways_create` 里 required；Golem 为单独 jar 里的 required；geckolib 的 optional 在 vanilla | 依赖表按 jar 拆开 | 失效 |
| F-30 | r03:117、r03:180 | 区域设置窗由 `ZoneSettings` 的 `build` 搭起 | 仍成立，但窗里多了 `stalled` 元素（`ZoneSettings.java:147-148`），且 `ZoneSettings` 现在 import `ColonyStalls`（`:22-23`） | 补一句：设置窗兼显示停工原因 | 措辞 |

| F-31 | r03:141、r03:148 | `Scenes.folder` / `Scenes.scene` 是挂课的唯一方式；`build` folder 含 `create_handoff` 且 folder 全部归属各自插件 | 新增 `Scenes.add(folder, scene)`（`front/api/ponder/Scenes.java:55-58`，`Addition` 记录 `:36-39`，`folders()` 合并见 `:60-66`）：一个 mod 可往另一个 mod 的 folder 追加课；Create 的 `create_handoff` 正是这样挂到 vanilla 的 `BuildContent.ID` 下（`mods/create/src/main/java/io/github/izakyl/folkways/create/build/CreateBuildPlugin.java:17-19`）。⚠️ 「13 个 folder / 14 个场景」的计数未在新树重数 | r03 的 Ponder 一节补充 `Scenes.add`，并把 `create_handoff` 的归属改为 create jar | 措辞 |
| F-32 | r03:135 | 「各约 70 KB / ~896 行」 | 每个 lang json 932 行（新 `mods/core/src/main/resources/assets/folkways/lang/*.json`）；「只有 4 个文件」仍成立 | 行数改 932 | 数字 |
| F-33 | r03:123-133（Notice、信息卡） | Notice/Line/信息卡链路 | 仍成立；新增来源：`ColonyStalls.lines(...)`（`front/engine/net/FolkwaysUiNetworkEvents.java:187,210`）把停工原因并入卡片行 | 补一条来源 | 措辞 |
| F-34 | d12:74、d12:75、d12:76、d12:81 | 「必须新取 mod id（建议 `plaa`）」；R-FK-3 在 `mods.toml` 里声明冲突；「不重命名上游包」 | d12:74 已记录四模块基线，下列事实供 OQ-6 使用：上游四个 mod 共用资源命名空间 `folkways`（`FolkwaysMod.java:59-60`），各 toml 的 `modId` 与 Java `@Mod` 常量是两处独立书写；包根仍是 `io.github.izakyl.folkways`，四个 jar 各占不同顶层包（§1.2），所以「我们的新增代码放新包」不会与任何上游 jar 冲突 ⚠️（推断：未见 split-package 工具验证） | 在 OQ-6 里加上这些事实；R-FK-3 的冲突声明要对四个 modid 写 | 措辞 |
| F-35 | w05:98、w05:104、w05:623 | 测试分层表写 `src/gametest`、`tests/fuzz`、「`src/gametest` 的 GameTest」 | 路径为 `mods/*/src/gametest`（modulargolems 无）；fuzz 已无（F-05） | 改路径、删 fuzz 行 | 措辞 |
| F-36 | r02:197 | 蓝图：「主 jar 未随包蓝图；`src/gametest/resources/data/folkways/folkways/blueprint/test_hut.nbt` 仅测试用」 | 测试资源移到 `mods/vanilla/src/gametest/resources/data/folkways/folkways/blueprint/test_hut.nbt`（§1.1(b)）；「主 jar」现在有四个 | 路径更新；「主 jar」改为「vanilla jar」 | 措辞 |

### 5.2 已核对、仍然成立（不必改）

- `neoforge.enabledGameTestNamespaces` 的值仍是 `folkways,ldlib2`（新 `build.gradle:52`，旧 `build.gradle:60`）；`gameDirectory = run/gametest`、`--nogui` 同（`build.gradle:50-51`）。
- `lintScaffold`（禁 Tab/行尾空白）原样挂在 `check` 上（`build.gradle:105-133`）；`CONTRIBUTING.md:95`（旧 `:77`）同。
- CI 步骤集合不变：`npm ci` → `npm run setup` → `./gradlew build` → `npm run typecheck` → `npm run test:unit`（新 `.github/workflows/build.yml:25-29`）；CI 仍不跑 gametest/e2e/bench。
- `.blockwright/`、`.blockwright-store/` 仍被 git 忽略（新 `.gitignore:36-37`，仅行号后移）。
- 「`npm run setup` 先于 `./gradlew build`，否则 `lib()` 抛 `GradleException`」仍成立（`gradle/mod.gradle:43-45`；`CONTRIBUTING.md:20` 同旧 `:20`）。
- Sable 仍未在任何 toml 声明（四份 toml `grep -c sable` 均为 0）。
- 内置图案仍是 `data/folkways/folkways/pattern/*.star`，只是搬到 vanilla（新 `CONTRIBUTING.md:50`）。
- 「LDLib2 是硬依赖、Ponder/Flywheel 内嵌」仍成立：ldlib2 required（`mods/core/src/main/resources/META-INF/neoforge.mods.toml:28-34`）、ponder required 且内嵌（`:44-50`、`mods/core/build.gradle:22-28`）。
- `package.json:6` 仍是裸 `gradle build`（Windows 要换 `gradlew.bat` 的结论成立）。

---

## 6. 不确定项

1. ⚠️ **jar 实际文件名**：由 `gradle/mod.gradle:4,6-8` 与 `blockwright.toml:17` 的 glob 推得 `folkways-core-neoforge-1.21.1-0.1.0.jar` 之类，**未运行构建验证**（本任务禁止在 `mod/`、`reference/` 下跑 gradle/npm）。
2. ⚠️ **根 `build/libs` 是否恰好只有 4 个 jar**：`collectJars` 只 `from(…tasks.named("jar"))`（`build.gradle:90-93`），推断 `-sources` / `-api` 不在其中；但 `build.yml:55` 仍保留 `rm -f jars/*-sources.jar`，这与「根 build/libs 里没有 sources」并不矛盾也不能证实。需 M1 第一次构建时 `ls build/libs` 确认。
3. ⚠️ **子项目能否单独跑 gametest**：只有根项目声明了 `runs`（grep 确认 `gradle/mod.gradle`、`mods/*/build.gradle` 无 `runs`），推断子项目没有自己的 `runGameTestServer`；`CONTRIBUTING.md:51` 的说法是「由根的 `runGameTestServer` 一起跑」。未实测。
4. ⚠️ **Blockwright 测试实例是否总装全部 4 个 Folkways jar**：`[mods.folkways_*]` 四条无 `target`（`blockwright.toml:16-26`），推断所有 profile 都带；其中 `folkways_modulargolems` 的 toml 要求 `modulargolems >= 3.1.43`（`mods/modulargolems/…/neoforge.mods.toml:44-50`），顶层 `[mods.modulargolems]` 夹具无 `target` 限制（`blockwright.toml:50-52`），故看起来自洽；未启动实例验证。
5. ⚠️ **`8fa9029` 所说「覆盖检查不上 CI」的确切含义**：只看到 `tests/bench/report/{judgements.ts,refusal-coverage.test.ts}` 与 `tests/i18n/lang.test.ts` 有改动；`test:unit` 的 glob 是 `tests/**/*.test.ts`（`package.json:9`），故 `refusal-coverage.test.ts` 是否被 CI 的 `test:unit` 拉起、其「覆盖检查」是否被排除，本文未读测试内容判定。
6. ⚠️ **图案 `.star` 与拱桥改动**（`67f28b0` 的另一半）：未逐行比对 `mods/vanilla/src/main/resources/data/folkways/folkways/pattern/*.star`，只在 §4 里覆盖了被文档引用的 `.star` 行。若 PRD 要依赖 `arch_bridge` 行为，需单独核对。
7. ⚠️ **`Effects` 的来源是否只有 perk**：`Body.effects()` 只返回 `perks().effects()`（`Body.java:46-48`），但 `Effects.java:9-10` 的注释写了「a perk, a mood, a place」，`ColonyView.effectsOf`（`ColonySnapshot.java:106`）、`Hands.effects()`（`Hands.java:106`）、`Commit.effects()`（`Commit.java:208`）三处如何拼装未细读；F-21 的「唯一来源」是推断。
8. ⚠️ **巡逻页内容**：F-25 只确认页面存在及其 lang 键，没读 `PatrolPresence` 渲染了哪些控件。
9. ⚠️ **Ponder folder / scene 计数**（r03:148「13 个 folder / 14 个场景」）未在新树重数。
10. ⚠️ **split-package**：目录列表显示四个 jar 各占不同顶层包（§1.2），但未用工具扫描包重叠；这对「我们的新增代码放新包」（d12:76）的安全性有影响。
11. ⚠️ **`@GameTest` 计数口径**：用 `grep -rE "@GameTest"` 的出现次数，旧值 488 与 r05 一致，新值 496 同口径；若注释里出现该字样会多计，两边同受影响。
12. **「已定位」只保证被引行整行相等**，不保证周边语义不变（例如 `ZoneSettings.java:85-140` 整体后移并新增了 `stalled` 元素，已在备注里写明；类似的「行相等但上下文变了」可能还有，未逐个通读）。
13. **附录 A 只收能唯一解析到旧文件的路径**；同名歧义的（`tsconfig.json`、`global-setup.ts`、`main.json`）与指向我们自己文档/仓库外文件的（`docs/...`、`AGENTS.md`、`NOTICE.md`）未列。附录 B 是正则扫描，可能漏掉用别名写的引用。
14. **8 份文档可能在本文生成之后继续被修改**（w06 在本调研期间改过两次：14:34、15:09，后一次使其第 117 行之后的内容整体下移约 26 行；本文按 15:09 版本生成）；§4 的「所在」行号以扫描时点为准，「原引用」文本是稳定锚。
15. **未覆盖的文档**：`docs/research/08`、`docs/research/09`、`docs/workflow/03`、`docs/prd/PRD-008`、`docs/00-charter.md`、`docs/README.md` 里也有指向 `reference/folkways-master/` 的字样（`grep -c` 为 1–3 处），本任务未扫描它们；它们的引用同样适用 §4 的映射规则。
16. **ADR / 结论层面**：本文没有评价 ADR-021 的取舍，也没有给实现建议；F-24（上游已有 stall 展示）是否改变 M1 的差异化定位，需要设计者/人类判断。
