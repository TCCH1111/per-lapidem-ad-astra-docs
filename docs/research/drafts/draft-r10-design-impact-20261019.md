# r10 设计级影响：待裁决清单（上游 f42e3c1 → 67f28b0）

```
状态：已裁决（2026-10-19，用户；结论见 docs/00-charter.md ADR-024）
负责人：文档实现者（agent）
最后更新：2026-10-19
上游依据：docs/research/10-upstream-delta-f42e3c1-67f28b0.md §5、docs/00-charter.md ADR-023
```

> **裁决结果（ADR-024）**：§1 C · §2 A · §3 A · §4 A · §5 A+C · §6 A · §7 A · §8 A · §9 C · §10 C · §11 C · §12 B（仅"新增玩法 = 单 jar"部分，命名空间与四 modid 按 ADR-023 不变）· §13 C · §14 C · §15 A · §16 A · §17 A。本文件保留作裁决依据；后续改 PRD/WP/k01/k03 时引用 ADR-024 而非本文。

> **用途**：ADR-023 已裁决「引用由 agent 机械迁移，不改结论文字；设计级结论单独整理成待裁决清单交人类」。本文是那份清单。8 份文档（r01–r05、w05、w06、d12）的引用已按 r10 §4 迁移，**结论文字一字未改**；下列条目是「引用换了之后，结论本身是否还成立 / 我们打算怎么做是否要变」。
> **范围**：从 r10 §5.1 的 36 条 F 项中选出 17 条设计/玩法/里程碑取舍项（§1–§17）；其余 19 条纯路径/数字/措辞项见文末表格。
> **约定**：上游事实一律写 `reference/folkways-67f28b0/文件:行号`，均转抄自 r10，**本文未重新通读上游源码**；推断标 ⚠️。本文不写代码、不写实现步骤，只给备选与推荐。「推荐项」是 agent 的建议，不是决定。

---

## 1. F-20 内容层不再是「与第三方同款 API 的内置玩法」

- **原结论（r01:14）**：内容层（`plugins/**`）是内置玩法，用与第三方相同的 API 写就，是最可靠的用法样例。
- **上游新事实**：内容层分成三个 mod。`vanilla/plugins` 之外，`create` 与 `modulargolems` 是**独立 jar**，各有自己的 `@Mod` 入口（`reference/folkways-67f28b0/mods/create/src/main/java/io/github/izakyl/folkways/create/FolkwaysCreateMod.java:20`、`reference/folkways-67f28b0/mods/modulargolems/src/main/java/io/github/izakyl/folkways/modulargolems/FolkwaysModularGolemsMod.java:12`）。这两个 jar 是上游自己对「第三方式写法」的官方实例。
- **受影响条目**：d12 §5（L1/L2/L3 分层中「新增代码放哪」）；PRD 各「与基底 API 的关系」章节里把 `plugins/*` 当样板的写法（PRD-004 基底复用表、PRD-001 §14）；w05 WP-1 的扩展点表。
- **备选**：
  - A. 我们的新玩法也做成与 `folkways_create` 同构的**独立 jar**（每个 PRD 一个或一组 mod）。
  - B. 全部进一个我们自己的 jar，只保留 L1 新增包。
  - C. 混合：引擎改动（L2）留在 core，玩法按体量分「与 Create 耦合的独立 jar」和「其余合进一个 jar」。
- **推荐**：C。理由：上游已证明「独立 jar + 精确钉版」可行，但每多一个 jar 就多一份 toml/mixin/配置维护，需与 §12 的命名裁决一起定。

## 2. F-21 效率修正的落点从 `ResidentEntity` 改为 `effect` 层

- **原结论（r01:81/88、r04:110-111、w05:213/237）**：Perk/PerkPool 影响 `Workload.Haste`、XP；效率修正走 `ResidentEntity` 的 transient modifier 范式，**不改 `BodyRunner`**。
- **上游新事实**：新增 `effect` 层。`Perk` 是 `record Perk(String id, int maxRank, Grant grant)`，`Grant` 产出 `Modifier`（`reference/folkways-67f28b0/mods/core/src/main/java/io/github/izakyl/folkways/effect/perk/Perk.java:14-68`）；`Stats` 定义 `WORK_SPEED`（夹取 0.05–20.0）/`MOVE_SPEED`/`REACH`/`PACK_ROOM`/`APPETITE` 与 `Flag PATIENT`（`reference/folkways-67f28b0/mods/core/src/main/java/io/github/izakyl/folkways/effect/Stats.java:9-24`）；`Workload.Haste.of(trade)` 读 `who.effects().value(Stats.WORK_SPEED, trade)`（`reference/folkways-67f28b0/mods/core/src/main/java/io/github/izakyl/folkways/core/api/work/Workload.java:76-79`）；属性写入统一在 `Bodies.carry`（`reference/folkways-67f28b0/mods/core/src/main/java/io/github/izakyl/folkways/core/api/resident/body/Bodies.java:48-56`，`addTransientModifier` 在 `:72`），`ResidentEntity` 内联代码已删，仅 `reference/folkways-67f28b0/mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/person/ResidentEntity.java:292` 调 `refreshEffects()`；食欲由 `Stats.APPETITE` 驱动（`reference/folkways-67f28b0/mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/person/living/LivingPresence.java:127,141`）；`GlobalPerks.install` 带参 `FolkwaysConfig::asceticAppetite`（`reference/folkways-67f28b0/mods/core/src/main/java/io/github/izakyl/folkways/effect/perk/GlobalPerks.java:28`、`reference/folkways-67f28b0/mods/core/src/main/java/io/github/izakyl/folkways/FolkwaysMod.java:110`）。⚠️ `Body.effects()` 目前只返回 perk 来源，`Effects.java:9-10` 注释却写了 perk/mood/place 三类来源，是否已接入未确认（r10 §6-7）。
- **受影响条目**：PRD-001 AC-21（效率修正档位 + 总乘数夹取 [0.55, 1.20]）与情绪→效率章节；w05 WP-2（M1-WP2-T2）与 WP-1 扩展点表中「transient modifier」行；d12 §5 改动登记表（原计划的 L1/L2 位置）。
- **备选**：
  - A. 效率修正作为**新的 `Perk.Grant` / `Stat` 来源**接入 `effect` 层（情绪档位 = 一种 Modifier 来源）。
  - B. 沿用原计划，在我们自己的 L1 代码里直接写 transient modifier，绕开 `effect` 层。
  - C. 只在 `effect` 层新增 `Stat`（如 `MOOD_WORK`），由我们的结算系统写入，不扩展 `Perk`。
- **推荐**：A（若 §6-7 的「mood 来源」确认可接入则更佳）。理由：B 会与 `Bodies.carry` 统一写属性的路径冲突并造成双重叠加，且 AC-21 的夹取必须与 `WORK_SPEED` 自带夹取对齐，只有走同一层才能对齐。

## 3. F-22 单一配置文件变为三份，且 golems 无配置

- **原结论（r01:110、r04:139/204/218）**：单一 `FolkwaysConfig` → 每个世界 `serverconfig/folkways-server.toml`，含「全部可调项」。
- **上游新事实**：三个 `ModConfig.Type.SERVER`：`folkways_core-server.toml`、`folkways_vanilla-server.toml`、`folkways_create-server.toml`（`reference/folkways-67f28b0/README.md:109`）；golems 不注册配置（`reference/folkways-67f28b0/mods/modulargolems/src/main/java/io/github/izakyl/folkways/modulargolems/FolkwaysModularGolemsMod.java:11`）。
- **受影响条目**：pack/02-config-and-datapack.md（整合包默认配置交付）；pack/03-performance-budget.md（调参入口）；PRD-001/005/006 里各自「配置项」小节需要决定落在哪个文件；r01:163 的性能调优建议。
- **备选**：
  - A. 我们的新配置**另起一份**（用我们自己的 modid 命名的 `*-server.toml`），不碰上游三份。
  - B. 把我们的开关加进上游相应的 `FolkwaysConfig`（L2）。
  - C. 不暴露配置，写死默认值，靠数据包/整合包预设。
- **推荐**：A。理由：与 d12 的「改动尽量留在 L1」一致，上游三份配置的键会随上游继续拆分，加进去会放大同步冲突。

## 4. F-23 旋钮归属变化使「只在 `FolkwaysConfig` 的旋钮上调优」不再成立

- **原结论（r01:163）**：性能调优只在 `FolkwaysConfig` 允许的旋钮上做（`planHorizonTicks/Depth`、`travelCeiling/FloorMicros`、`haulReachTicks`、`dispatchReachTicks`、`seatTicks`、`solveThreads`、`heartbeatCycles`）。r01:150/152、r02:203、r04:140-157 的旋钮表都挂在 `FolkwaysConfig` 下。
- **上游新事实**：键名与默认值不变，归属改变：`dispatchReachTicks`/`seatTicks`/`conductingHaste`/`dispatchHaste` → create（`reference/folkways-67f28b0/mods/create/src/main/java/io/github/izakyl/folkways/create/FolkwaysCreateConfig.java:41,46`）；immigration/zones/blueprints/crafting/5 个 `*Haste`/`pathSearchBudget` → vanilla（`reference/folkways-67f28b0/mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/FolkwaysVanillaConfig.java:67-113,155-159`）；其余 → core（`reference/folkways-67f28b0/mods/core/src/main/java/io/github/izakyl/folkways/FolkwaysConfig.java:72-115`）。
- **受影响条目**：pack/03-performance-budget.md 的调参清单；w05 WP-9（性能探针与预算）；PRD 中引用「基底旋钮」的预算段。
- **备选**：
  - A. 预算文档按「所属配置文件」重列，并把「vanilla/create 是否安装」写成前提（不装 create 就没有 dispatch 旋钮）。
  - B. 只引用 core 的旋钮，把其余视为内容层细节。
  - C. 要求整合包同时装全部 Folkways jar，预算以「全装」为口径。
- **推荐**：A。理由：整合包是否装 create 影响预算口径，必须显式。

## 5. F-24 上游已落地最小「停工原因」展示，与 M1 差异化定位重叠

- **原结论（r01:91/143、w05:70/153、WP-1、WP-6）**：M1 的差异化 = 画了区之后玩家知道为什么没生效；`Unassigned`/`Why`/`Shortfall` 等诊断原料只有部分可读，WP-1 负责提升为公开只读，WP-6 做解释层。
- **上游新事实**：公共记录 `Stall`（`reference/folkways-67f28b0/mods/core/src/main/java/io/github/izakyl/folkways/core/api/work/Stall.java:14`）、`Colony.stallsIn(dimension)`（`reference/folkways-67f28b0/mods/core/src/main/java/io/github/izakyl/folkways/core/api/colony/Colony.java:36-37`）、`Weaver.stalls()`（`reference/folkways-67f28b0/mods/core/src/main/java/io/github/izakyl/folkways/core/engine/plan/Weaver.java:582` 起）、稳定判据 `SETTLE_TICKS = 100`、`MET_TIMES = 2`、`FORGET_TICKS = 1_200`（`reference/folkways-67f28b0/mods/core/src/main/java/io/github/izakyl/folkways/core/engine/labor/Stalls.java:19-24`）、新增 `LaborRefusal.NO_SOURCE/NO_ROOM_FOR/NO_WAY_FOR/NO_ONE_MAKES`（`reference/folkways-67f28b0/mods/core/src/main/java/io/github/izakyl/folkways/core/engine/labor/LaborRefusal.java:14-17`）、玩家侧 `ColonyStalls`（`reference/folkways-67f28b0/mods/core/src/main/java/io/github/izakyl/folkways/front/engine/colony/ColonyStalls.java`）与区域设置窗 `stalled` 元素（`reference/folkways-67f28b0/mods/core/src/main/java/io/github/izakyl/folkways/front/ui/screen/ZoneSettings.java:147`）。
- **受影响条目**：PRD-006（解释层）全篇的基线声明与 AC 清单；w05 WP-1（「提升为公开只读」清单）、WP-6（≥8 类阻塞）、§1.2 门禁与 §1.3 演示脚本里的「差异化」措辞；design/16-diagnosis-ui-prototype.md。
- **备选**：
  - A. 把 `Stall` 当既有基底：WP-1 去掉已公开项，WP-6 在其上**扩展**（我们的 ≥8 类阻塞与上游 5 类重合的直接复用，其余新增）。
  - B. 保持原计划另造一套诊断数据，只在展示层做差异。
  - C. 重新评估 M1 差异化：把重心从「知道为什么没生效」移到上游尚无的东西（需求/情绪/如厕、作息、禁限区）。
- **推荐**：A，并请人类确认是否需要同时走 C。理由：并行造两套在同步时必然冲突；F-24 是 r10 唯一一条直接动摇 M1 卖点的发现，必须由人拍板。

## 6. F-25 巡逻已有自己的面板页

- **原结论（r02:117-122、r03:104/114/159）**：「巡逻没有自己的页面或命令：它就是 LINE 手势 + `PatrolContent.BEAT = Shape.Path(maxPatrolPoints)`」；r03:159「没有战斗指令」。
- **上游新事实**：`PatrolContent` 新增 `PAGE = PageKind.boarded(ID, "folkways.page.patrol", …)`（`reference/folkways-67f28b0/mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/patrol/PatrolContent.java:38-39`）、`registering.facing(...)`（`:62`）、Enrollment 带 `Schema.none(), List.of(PAGE)`（`:63-65`）；`PatrolPresence implements Facing`（`reference/folkways-67f28b0/mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/patrol/PatrolPresence.java:47`）；lang 新增 `folkways.page.patrol` 等（`reference/folkways-67f28b0/mods/core/src/main/resources/assets/folkways/lang/en_us.json:340-342`）。⚠️ 页内具体控件未读（r10 §6-8）。
- **受影响条目**：PRD-004（防御，把巡逻当「直接复用」，见其基底复用表与「巡逻与预警」行）；PRD-005（禁限区 + 作息，与「画区」类交互的统一）；r03 §6.5 的「已有页面的插件」表；design/09-interaction-and-ui.md。
- **备选**：
  - A. PRD-004 继续「直接复用」，但先由调研者读 `PatrolPresence` 确认页面能力，再决定要不要在其上加民兵编制等控制。
  - B. 把巡逻页视为我们防御 UI 的**入口**，PRD-004 的编制/预警面板挂在它之下（`Facing` 扩展）。
  - C. 忽略巡逻页，另做独立防御面板。
- **推荐**：A，确认后再接 B。理由：F-25 只确认页面存在，未确认其内容，先补事实再选，避免重复造。

## 7. F-26 插件入口不再统一在 `BuiltinPlugins`

- **原结论（r02:20）**：`XPlugin.install(IEventBus)` 在 `plugins/BuiltinPlugins.java`，是每个插件的唯一入口。
- **上游新事实**：`BuiltinPlugins.install` 只装 9 个 vanilla 插件（`reference/folkways-67f28b0/mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/BuiltinPlugins.java:20-30`），由 `FolkwaysVanillaMod` 构造器调用（`:21`）；Create 由 `CreatePlugins.install`（`reference/folkways-67f28b0/mods/create/src/main/java/io/github/izakyl/folkways/create/FolkwaysCreateMod.java:20`）、Golem 由 `FolkwaysModularGolemsMod` 构造器直接装（`reference/folkways-67f28b0/mods/modulargolems/src/main/java/io/github/izakyl/folkways/modulargolems/FolkwaysModularGolemsMod.java:12`）。Core 不再 `BuiltinPlugins.install`。
- **受影响条目**：d12 §5（插件如何接入基底、改动登记表中「入口」一栏）；w05 各 WP 中「在 `BuiltinPlugins` 登记」的隐含假设；r04:107「仿 `BuiltinPlugins`」。
- **备选**：
  - A. 我们的每个 mod 在自己的 `@Mod` 构造器里装自己的插件（与上游 create/golems 同构）。
  - B. 把我们的插件塞进 `BuiltinPlugins`（修改 vanilla 的 L2 文件）。
  - C. 在 core 新增一个我们自己的统一入口类。
- **推荐**：A。理由：B 是同步冲突热点，C 与上游「各 mod 自装」的新方向相反；与 §1 一并裁决。

## 8. F-27 rail/dispatch/golem 成为独立 jar，sable 不再是插件

- **原结论（r02:36-57、131-163；r04:116/182-186）**：rail/dispatch/golem/sable 是 `plugins/` 下的插件；golem、sable「可选」。
- **上游新事实**：rail/dispatch → `folkways_create`（需 Create **且**本 jar，`reference/folkways-67f28b0/mods/create/src/main/resources/META-INF/neoforge.mods.toml:44-50`）；golem → `folkways_modulargolems`（对 `modulargolems` 为 required，`reference/folkways-67f28b0/mods/modulargolems/src/main/resources/META-INF/neoforge.mods.toml:44-50`）；`SablePlugin` 删除，`SablePassage` 在 `core/shell/structure/`，探测在 `reference/folkways-67f28b0/mods/core/src/main/java/io/github/izakyl/folkways/FolkwaysMod.java:91-95`。r02:152「toml 未声明 sable」仍成立。
- **受影响条目**：pack/01-modlist.md（Create/Sable/Aeronautics 的「采用」与依赖说明）；pack/00-pack-spec.md；PRD-011（太空/进阶，依赖 Sable 与 Create 系）；w06 §3.4 R-FK-12 的「运行期零可选依赖」口径（「可选」变成「选装哪几个 Folkways jar」）。
- **备选**：
  - A. 整合包**四个 Folkways jar 全装**，把「可选」改述为「独立 jar，整合包默认全带」。
  - B. 只带 core + vanilla，Create/golems 按整合包方向取舍。
  - C. fork 时删掉不需要的 jar（如 golems），减少维护面。
- **推荐**：A（M1 默认），M2 再按方向裁剪。理由：上游测试实例默认四 jar 全装（r10 §6-4 ⚠️），先对齐可减少 M1 的未知。

## 9. F-29 依赖声明按 jar 拆开，Create/Golem 由 optional 变 required

- **原结论（r04:180、184-186）**：依赖声明在一份 toml 的 `:36-90`；Create/Golem 为 optional（BOTH）。
- **上游新事实**：Create 在 core 里 optional、在 `folkways_create` 里 required；Golem 为单独 jar 里的 required；geckolib 的 optional 在 vanilla（`reference/folkways-67f28b0/mods/core/src/main/resources/META-INF/neoforge.mods.toml:36-74`、`reference/folkways-67f28b0/mods/vanilla/src/main/resources/META-INF/neoforge.mods.toml:36-42`、`reference/folkways-67f28b0/mods/create/src/main/resources/META-INF/neoforge.mods.toml:44-50`、`reference/folkways-67f28b0/mods/modulargolems/src/main/resources/META-INF/neoforge.mods.toml:44-50`）。
- **受影响条目**：w06 §3（依赖矩阵）与 §3.4 R-FK-12 的运行期门禁表述；pack/01-modlist.md；PRD-012（多人/服务端）里关于客户端必装项的约定。
- **备选**：
  - A. 沿用上游拆法，我们的每个 jar 各写各的依赖 toml，门禁按 jar 判定。
  - B. 把我们的依赖合并到少数 jar，toml 更少。
  - C. 在 A 之上，对 R-FK-12 增补一条「`folkways_create` 属必装可选集」的例外说明。
- **推荐**：C（即 A + 例外说明）。理由：R-FK-12 原表述「运行期零可选依赖」在 jar 拆分后需要明确「以哪个 jar 为单位」。

## 10. F-31 Ponder 课程可跨 mod 追加（`Scenes.add`）

- **原结论（r03:141/148）**：`Scenes.folder` / `Scenes.scene` 是挂课的唯一方式；`build` folder 含 `create_handoff`，folder 全部归属各自插件。
- **上游新事实**：新增 `Scenes.add(folder, scene)`（`reference/folkways-67f28b0/mods/core/src/main/java/io/github/izakyl/folkways/front/api/ponder/Scenes.java:55-58`，`Addition` 记录 `:36-39`，`folders()` 合并 `:60-66`）；Create 的 `create_handoff` 以此挂到 vanilla 的 `BuildContent.ID` 下（`reference/folkways-67f28b0/mods/create/src/main/java/io/github/izakyl/folkways/create/build/CreateBuildPlugin.java:17-19`）。⚠️ 13 folder / 14 scene 的计数未重数。
- **受影响条目**：w05 WP-7（需求/情绪 UI 与教学）里的教程挂载；PRD-001 教学/引导章节；pack/04-quest-book-and-guidance.md。
- **备选**：
  - A. 我们的教学场景用 `Scenes.add` 追加进上游已有 folder（如 `build`）。
  - B. 新建我们自己的 folder，不追加。
  - C. 两者并用：与上游已有页面相关的课追加，新系统的课另立 folder。
- **推荐**：C。理由：新系统（需求/情绪/如厕）没有可追加的上游 folder，而与已有页面相关的说明追加最自然，且不改上游文件，符合 L1。

## 11. F-33 信息卡行有了新来源（`ColonyStalls.lines`）

- **原结论（r03:123-133）**：Notice/Line/信息卡链路由既有来源产生。
- **上游新事实**：`ColonyStalls.lines(...)` 把停工原因并入卡片行（`reference/folkways-67f28b0/mods/core/src/main/java/io/github/izakyl/folkways/front/engine/net/FolkwaysUiNetworkEvents.java:187,210`）。
- **受影响条目**：PRD-006 的解释层展示位置（卡片行 vs 独立面板）；PRD-001 的需求/情绪卡片行；design/09-interaction-and-ui.md、design/16-diagnosis-ui-prototype.md 的原型布局。
- **备选**：
  - A. 我们的需求/情绪/阻塞提示也接入同一条「卡片行」链路，与停工原因并列。
  - B. 另做独立面板，卡片行保持上游内容。
  - C. 先沿用上游卡片行，等 §5（F-24）裁决后再定。
- **推荐**：C。理由：卡片行的来源与 §5 绑定，先后顺序不能颠倒。

## 12. F-34 四个 modid 共用命名空间，`plaa` 的展开方式待定

- **原结论（d12:74-76、81）**：必须新取 mod id（建议 `plaa`）；R-FK-3 在 `mods.toml` 里声明冲突；不重命名上游包。
- **上游新事实**：四个 mod 共用资源命名空间 `folkways`（`reference/folkways-67f28b0/mods/core/src/main/java/io/github/izakyl/folkways/FolkwaysMod.java:59-60`）；各 toml 的 `modId` 与 Java `@Mod` 常量是两处独立书写；包根仍是 `io.github.izakyl.folkways`，四个 jar 各占不同顶层包。⚠️ 未用工具验证 split-package（r10 §6-10）。d12 OQ-6 已提出该问题。
- **受影响条目**：d12 §4、§12 OQ-6、R-FK-3；docs/00-charter.md ADR-017（`plaa`）；w06 §1.3 B-2（改名清单，见 §13）；docs/design/03-glossary.md 的命名空间约定；pack/00-pack-spec.md。
- **备选**：
  - A. 我们的 jar 也成对分层：`plaa_core` / `plaa_vanilla` / …，资源命名空间保持 `folkways`（共用上游数据包）。
  - B. 单个 `plaa` jar 承载全部新增，命名空间 `plaa`；依赖四个上游 jar。
  - C. 命名空间也改 `plaa`（与上游数据包彻底隔离）。
- **推荐**：B 作为起点。理由：新增代码少时单 jar 维护成本最低，且命名空间 `plaa` 避免与上游数据包同名冲突；若 §1 选 A（多 jar）则回到 A。需人类同时回答「是否需要与上游数据包共存」。

## 13. F-02 `gradle.properties` 不再决定 modid，w06 B-2 的改名清单失效

- **原结论（w06:75 B-2、83、565 OQ-B-5；d12:75、233 OQ-6）**：改 `gradle.properties` 的 `mod_id=plaa` / `archives_base_name`，产物名 `plaa-neoforge-1.21.1`。
- **上游新事实**：新 `gradle.properties` 已无 `mod_id`、`archives_base_name`（`reference/folkways-67f28b0/gradle.properties:1-18`）；modid 在每个 `reference/folkways-67f28b0/mods/core/build.gradle:7`（`ext.modId`，其余三个子项目同），产物名由 `ext.modName`（`:8`）经 `reference/folkways-67f28b0/gradle/mod.gradle:6-8` 决定；Java 另有 4 处 `ID` 常量与资源命名空间 `FolkwaysMod.MOD_ID = "folkways"`；各 toml 以 `[${version}]` 互相精确钉版（`reference/folkways-67f28b0/mods/vanilla/src/main/resources/META-INF/neoforge.mods.toml:32` 等）。
- **受影响条目**：w05 WP-0（构建就绪）与 G1 验收；w06 B-2、OQ-B-5；d12 OQ-6；ADR-017。
- **备选**：
  - A. 沿用上游每个子项目一个 `ext.modId`，我们按 §12 的裁决逐个改。
  - B. 在根层引入我们自己的属性集中管理 modid，减小同步冲突面（会修改上游构建脚本，属 L2/L3）。
  - C. M1 暂不改 modid，先用上游 modid 跑通，之后再改。
- **推荐**：C 起步，M1 DoD 之后按 §12 裁决落实 A。理由：改名是同步冲突最大的一次性改动，宜与 WP-10（上游同步演练）一起做。

## 14. F-04 产物由一个 jar 变四个（及其对 G1 验收的影响）

- **原结论（r05:26、w06:421/458、w05 G1/WP-0）**：产物 `folkways-neoforge-1.21.1`（+ `-sources`/`-api`/`-fuzz`）；M1 验收「干净机器出 jar」「jar 在 `build/libs/`」。
- **上游新事实**：四个 jar，名由 `${modName}-neoforge-${minecraft_version}` 决定（`reference/folkways-67f28b0/gradle/mod.gradle:6-8`）；`-api` 只有 core（`reference/folkways-67f28b0/mods/core/build.gradle:43-48`）；无 `-fuzz`；根 `build/libs` 由 `collectJars` 收集（`reference/folkways-67f28b0/build.gradle:90-93`）。⚠️ 根 `build/libs` 是否恰好 4 个 jar 未验证（r10 §6-2）。
- **受影响条目**：w05 §1.2 G1、M1-WP0-T3、§1.3 演示脚本第 1 步；w06 §4.5 发布与夜间、§5.3 产物位置；d12 §9 发布形态；pack/00-pack-spec.md。
- **备选**：
  - A. G1 改为「`build/libs/` 有 4 个上游 jar + 我们的 jar」，发布形态为多 jar。
  - B. 打包阶段把我们的 jar 与上游 jar 合成一个整合包 zip，G1 只看 zip 完整性。
  - C. 将 G1 拆为两条：构建可重复（jar 数量不硬编码）+ 整合包可装载。
- **推荐**：C。理由：jar 数量取决于 §1/§12 的裁决，G1 不应硬编码数字；事实也未验证，宜等 M1 第一次构建后确认。

## 15. F-05 上游 fuzz 整体删除（「fuzzers 暂停」）

- **原结论（r05 §4.2/§4.3、复用点 3、问题 7；w05:96/98/110；w06:438/459/566 OQ-B-6）**：fuzz 源集、`fuzzJar`、`npm run fuzz:run`、`tests/fuzz`、`[profile.fuzz]` 是测试六层之一，可借鉴；OQ-B-6「是否借鉴 fuzz」。
- **上游新事实**：`tests/fuzz/` 整体删除（旧 24 个文件）；新根/子项目 `build.gradle` 无 `fuzz`；`reference/folkways-67f28b0/package.json:8` 的 typecheck 与脚本表（`:6-18`）无 fuzz；`reference/folkways-67f28b0/tests/shared/harness/out-paths.ts:10-15` 无 `fuzz` 桶，`budgets.ts` 无 `fuzz` 预算。提交说明为「fuzzers 暂停」。
- **受影响条目**：w03 测试分层（「六层」里的 fuzz 层）；w05 WP-8/WP-9 的测试手段；w06 §5.1 命令表；r05 的「复用判断」。
- **备选**：
  - A. 从自家测试分层中去掉 fuzz，不自建。
  - B. 自建一个最小 fuzz target，仅覆盖我们新增的核心算法（需求结算、作息求解）。
  - C. 等上游恢复 fuzz 再同步。
- **推荐**：M1 取 A，B 留作 M2 议题。理由：fuzz 需要访问 package-private 内核，成本高；上游自己已暂停也说明其维护代价不低。

## 16. F-10 `apiJar` 的 include 只剩 `core/api/**` 与 `front/api/**`

- **原结论（r05:35、r04:128）**：`apiJar` 打包 `Declaring`/`Relating`/`core/api/**`/`front/api/**`，是我们自研插件最可能直接依赖的编译期 API 面。
- **上游新事实**：现为 `include "io/github/izakyl/folkways/core/api/**", "…/front/api/**"` 且只在 core（`reference/folkways-67f28b0/mods/core/build.gradle:43-48`）；**perk/effect、`Ledger`（`base/`）、`Shelves`（`library/`）已不在该 include 内** ⚠️（推断：include 只列这两个包前缀）；而 `reference/folkways-67f28b0/mods/create/src/main/java/io/github/izakyl/folkways/create/FolkwaysCreateMod.java:3` 直接 import `effect.perk.PerkPool`。
- **受影响条目**：d12 §5「扩展点分级」表（L2 示例 `Shelves.java` 等）；w05 WP-1 的公开只读清单；PRD-001/002/007 对 `Shelves`、`PerkPool` 的依赖说明。
- **备选**：
  - A. 我们的 mod 不依赖 apiJar，直接对上游 core 的完整 jar 编译（与上游 create/golems 做法一致）。
  - B. 在我们 fork 的 `mods/core/build.gradle` 里扩大 apiJar 的 include（构建文件改动，需登记）。
  - C. 只依赖 apiJar 内的包，把 `effect/base/library` 的需求以 L2 公开化。
- **推荐**：A。理由：上游自己的上层 mod 就是这样做的，且 d12 的改动是 fork 内源码级，不需要二进制 API 面；B/C 增加同步冲突面。

## 17. F-19 「`core/api` 是唯一公共面」不再成立

- **原结论（r01:12/128）**：注册表集中在 `core/api/Ledger.java`；`core/api` 是第三方唯一可依赖的面。
- **上游新事实**：`Ledger` 在 `reference/folkways-67f28b0/mods/core/src/main/java/io/github/izakyl/folkways/base/Ledger.java`（与 `FolkwaysMixinPlugin`、`persist/` 同在 `base`）；`PerkPool`/`GlobalPerks` 在 `effect/perk`，`Shelves` 在 `library`；`base`、`effect`、`library` 被上层 mod 直接 import（`reference/folkways-67f28b0/mods/create/src/main/java/io/github/izakyl/folkways/create/FolkwaysCreateMod.java:3`）。
- **受影响条目**：d12 §5「改动分层」与 L2 示例表；PRD 里「与基底 API 的关系」的包范围描述；w05 WP-1。
- **备选**：
  - A. 把「公共面」重新定义为「上游四个 jar 中被上层 mod 直接 import 的包」，以 import 实况为准。
  - B. 仍以 `core/api` 与 `front/api` 为官方面，其余包的依赖都按 L2 登记。
  - C. 不定义公共面，所有对 core 的依赖都登记在改动表中。
- **推荐**：A。理由：与上游事实一致，登记表也更简单；与 §16 同时裁决。

---

## 已随任务 A 机械处理，无需裁决

下列 19 条是路径、数字、措辞类，不涉及「我们打算怎么做」。「处理」列写明任务 A 实际做了什么；凡写「正文未改」的，是因为 ADR-023 规定不改结论文字，仅换了引用。

| F 项 | 内容 | 处理 |
| --- | --- | --- |
| F-01 | `lib()` 移到 `gradle/mod.gradle:39-47` | 引用已迁移并加括注 |
| F-03 | `[mods.folkways]` 变四条；profile 区间 `:156-310`；去 `fuzz` | 行号已迁移；w06 表内裸行号一并补齐；列表文字未改 |
| F-06 | gametest 源集每子项目一个 | 引用已迁移，文字未改 |
| F-07 | `runGameTestServer` 定义移到根 `build.gradle:47-54` | 引用已迁移并加括注 |
| F-08 | gametest 示例的 `CORE_ID` / `MOD_ID` | 引用已迁移，示例正文未改 |
| F-09 | 三档集成按 mod 分家 | 引用已迁移并加括注 |
| F-11 | 数量过期（858 / 87 / 496 / 45 / 176） | 纯数字，正文未改；r10 §总览表有新值 |
| F-12 | 测试种入配置变两份文件 | 正文未改；文件名处加括注 |
| F-13 | `promo:take` 已存在 | 正文未改 |
| F-14 | 裸 `gradle` 调用点变两处 | 引用加「已删除」括注 |
| F-15 | CI 补一句 | 正文未改 |
| F-16 | G1 验收「4 个 jar」 | 并入 §14 |
| F-17 | 仓库块出现在两处 | 引用已迁移（两处并列） |
| F-18 | 范围/规模计数过期 | 前缀已迁移，计数未改 |
| F-28 | mixin 门控类名变化 | 类名处加括注（`CreateBuildMixinPlugin`） |
| F-30 | 设置窗多 `stalled` 元素 | 并入 §5 |
| F-32 | lang 行数 896→932 | 纯数字，正文未改 |
| F-35 | 测试分层表路径 | `src/gametest` 处加括注 |
| F-36 | 蓝图测试资源路径 | 路径已迁移到 `mods/vanilla/src/gametest/…`；「主 jar」措辞未改 |
