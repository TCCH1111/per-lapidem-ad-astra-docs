# 09 · 太空终局：多方块火箭 + 空间站的候选技术方案

- 上游依据：`docs/00-charter.md` ADR-011 / ADR-013、`docs/design/08-progression-and-ages.md` §5.1、`docs/pack/01-modlist.md`
- 下游影响：M4 里程碑立项、PRD（太空时代）、`docs/pack/01-modlist.md` 太空类选型修订
- 调研日期：2026-10-18。方法：Modrinth API v2 核实 + 下载 jar 解压读 `neoforge.mods.toml` / 类清单（**无反编译器**）+ `reference/folkways-master/` 源码直读。
- 证据分级：**A** = 直接读到的源码 / toml / API 返回值 / 类清单；**B** = 由 class 文件常量池字符串或类名推断（无反编译器，签名未验证）；**C** = 未验证。

---

## 0. 一分钟结论

1. **没有任何一个现成 1.21.1 mod 同时提供「居民可建造的多方块火箭 + 可居住空间站 + 公开载具 API」。** 三方各有其一：Creating Space 有多方块（Create contraption）火箭 + 计划表 API；Advanced Rocketry 3 有火箭装配厂 + 空间站维度 + 生命维持（但 **ARR 许可**、无 API）；Ad Astra 有环境 API + 轨道站点（但火箭是**实体，不是多方块**）。
2. **换道的代价比想象小**：Folkways 已经为「居民在移动结构上行走」和「跨 Realm 的通道」准备好了三处公开扩展点，且都是 A 级证据：
   - `Declaring.passage(...)` / `Passage.hopsIn` / `Conveyance.step`（`core/api/passage/*`、`Declaring.java:50`）
   - `Roaming` 已支持 **boarding 与 landing 分属不同 Realm** 的 `Crossing`（`Roaming.java:789-803`）
   - `WorldSpaces.Source` 可注册自研「站体/箭体」为 `Realm.Frame`（`WorldSpaces.java:50-53`、`FolkwaysMod.java:87`），且 `Realm` 只有 `Dimension` 与 `Frame` 两种形态（`Realm.java:14-28`）——**不绑定 Sable**。
3. **因此推荐：M4 主线走「自研多方块火箭 + 自研空间站维度」（候选 C）**，把 Ad Astra 当**环境/维度素材与可选目的地**（不用它的火箭实体）；**备选是「Create/Sable 移动结构」（候选 B）**，用于「看得见的物理飞行」与后期轨道造船。
4. **最贵的不是飞行动力学，而是**：(a) 推导一个新插件的出行/结算预算（现基线 `travelCeilingMicros = 8000`，`FolkwaysConfig.java:257`）；(b) 太空需求（氧/温）接进 `Contributions.urges` 并与 `Hunger` 同构（`Hunger.java:29-101`）；(c) 远离时的抽象结算。三者都有现成范式可抄，属 M 量级。
5. **发现两处 modlist 需修订**：`deep-space`（1.21.1 存在，但 toml 只声明 `veil`+`create`）**隐式依赖 `dimensional-sable`（MIT）**，其 `required:true` mixin 目标是 `dev.egg.SubLevelWarper`——不加会崩；`ad-astra` 1.21.1 **确实有 NeoForge 版本**（1.16.26）。

---

## 1. 现成 mod 核实表（Modrinth API + jar 实读，2026-10-18）

| mod | 1.21.1 版本（日期） | loader / 端 | 许可 | 声明依赖 | 多方块火箭？ | 空间站 / 自定义维度 | 公开 API | 承载非玩家实体 | 级 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `ad-astra` | 1.16.26（2026-09-13） | NF 21.1 + Fabric/Forge；C/S 均 required | LicenseRef-Terrarium-Licence | `resourcefullib`、`resourcefulconfig`、`common_storage_lib` | **否**：`Rocket`/`Lander` 是实体（`RocketItem` 生成），`LaunchPadBlock` 有 `PART/CENTER` 但只是**发射台**多方块 | 有轨道维度（`earth_orbit`/`moon_orbit`…）；站点是轨道维度里的坐标+配方产物（`SpaceStationHandler` 用 level `DataStorage` key `adastra_space_station_data`） | **有**：`earth.terrarium.adastra.api.*`（`PlanetApi`、`OxygenApi`、`GravityApi`、`TemperatureApi`、`AdAstraEvents$*`、`ApiHelper`） | 乘客类型为 `LivingEntity`（`getControllingPassenger`、`getDismountLocationForPassenger`、`getPassengerAttachmentPoint`） | A/B |
| `stellaris` | 1.4.25（2026-07-09） | NF + Fabric；C/S required | **CC-BY-NC-SA-4.0** | `architectury`、`potentials`、`sky_aesthetics` | **否**：`RocketEntity`/`LanderEntity` + `RocketLaunchPad`/`LaunchPad` | 有 `SpaceStationRecipe`、`PlaceStationPacket`、`DimensionOxygenManager` | **无 api 包**（仅 `client.events`） | 未验证 | A/C |
| `creating-space` | 1.7.18（2026-05-03） | NF；C/S required | **MIT** | `create` ≥ 0.6.0.9 | **是**：`RocketContraption` + `RocketContraptionEntity`（Create 动态结构），`RocketAssembleScreen` | 目的地由 datapack registry `RocketAccessibleDimension` 定义（`orbitedBody`/`gravity`/`arrivalHeight`/`adjacentDimensions`/`sun`） | **有**：`api.squedule.RocketSchedule`（`registerInstruction`/`registerCondition`；内建 condition `time_of_day`/`fluid_threshold`/`item_threshold`/`player_count`，instruction `destination`/`delay`）、`api.planets.*`、`api.IMass` | Create contraption 载体；是否收非玩家 actor 未验证（见 §6） | A/B |
| `deep-space` | 1.4.5-RELEASE（2026-07-19） | NF；C/S required | **MIT** | `veil`、`create [6.0.7,6.1.0)`（**实际还需 `dimensional-sable`，未声明**） | **否**：只给推进器道具（`RocketBoosterItem`/`JetpackItem`）与维度 | 有：`PlanetRegistry`/`PlanetTeleportHandler`/`SpaceDimensionEffects`，且 `MixinSubLevelWarper` → `dev.egg.SubLevelWarper` | 无 api 包 | 未验证 | A（依赖缺口为 B） |
| `create-rockets` | 0.5（2026-05-11） | NF；C/S required | **MIT** | `create ≥6.0.0`、`simulated ≥1.0.0`（`simulated` 打包在 create-aeronautics 内） | **否（也不是火箭）**：两种推力器方块（`data/create_rockets/physics_block_properties/{raptor_3,saturn_v_f1}.json`），BlockEntity 实现 Sable 的 `BlockEntityPropeller`（`createThrusterBehaviour(SmartBlockEntity, BlockEntityPropeller)`） | 无 | 无 | — | A/B |
| `advanced-rocketry-3` | 3.0.beta（2026-08-19，beta） | NF；C/S required | **All Rights Reserved** | 无声明 | **是**：`RocketAssembler`（+`ConstructionResult`/`DockingOrientation`）、`EntitySpaceStationAssembler`、`StationController`、`Blocks/Seat` | **有**：`Dimension/SpaceStationDimension`+`SpaceStationDimensionProperties`、`RocketTravelDimension`、`DimensionManager` | **无 api 包** | 有 `Rocket/EntityRocket` + `RocketProgram`（计划式导航/对接） | A/B |
| `sable` | 2.0.6（2026-10-03） | NF + Fabric；C/S required | PolyForm-Shield-1.0.0 | 内嵌 `veil` 等；不兼容 `sablecompanion >1.6.0`、旧 sodium | 载体基础设施（见 §2） | 子层（sublevel）非维度 | **有**：`dev.ryanhcode.sable.api.*`（`sublevel.SubLevelContainer`/`ServerSubLevelContainer`、`SubLevelHelper`、`EntitySubLevelUtil`、`sublevel.ticket.SubLevelLoadingTicket*`、`physics.force.ForceGroup`、`api.event.Sable{Pre,Post}PhysicsTickEvent`/`SableSubLevelContainerReadyEvent`、`block.BlockSubLevelLiftProvider`） | 未验证（票证机制只是类名证据） | A（清单）/B（用法） |
| `create-aeronautics` | 1.3.2（2026-08-29） | NF；C/S required | LicenseRef-Simulated-Project-License（代码 MIT、assets ARR，`LICENSE.md` 实读） | 打包 aeronautics + offroad + simulated | 提供移动结构，不含火箭语义 | 无 | **基本没有**：`aeronautics.api.*` 只有 levitite/音乐；`simulated.api.*` 只有音频/资源注册 | 未验证 | A |
| `veil` | 4.5.2（2026-10-10） | NF + Fabric；client required / server optional | LGPL-3.0-only | — | — | — | — | — | A |
| `dimensional-sable` | 1.0.5（2026-06-23） | NF；C/S required | **MIT** | `sable`（必需）、`create-aeronautics`（可选） | — | 提供 `dev.egg.SubLevelWarper`（跨维度搬运子层） | 无 api 包 | 未验证 | A（元数据）/B（类名） |

**许可小结（能否进包 / 能否编译期依赖）**：`creating-space`/`deep-space`/`create-rockets`/`dimensional-sable` 为 MIT，可进包、可编译期依赖。`sable`（PolyForm Shield）与 `create-aeronautics`（Simulated Project License）为自定义许可且 Folkways **已经在编译期依赖 sable**（`reference/folkways-master/build.gradle:106` `compileOnly lib("sable")`），说明这条路在本项目内已被接受。`stellaris` 的 NC 条款与 `advanced-rocketry-3` 的 ARR 需要法务确认：**AR3 不能作编译期依赖**，作为整合包成员也必须先确认分发许可。

---

## 2. Create 系路线（Sable 移动结构能不能当火箭/空间站）

**能承载"火箭是移动的多方块结构"**，因为 Sable 的 sublevel 就是一个**带物理的、可含 Create contraption 的独立坐标系**（`dev.ryanhcode.sable.api.sublevel.KinematicContraption`，A 级清单；Deep Space 的 mixin 同时引用 `KinematicContraption` 与 `AbstractContraptionEntity`，B 级）。而且 **Folkways 已经把「居民站上移动结构」做完了**：

| 已有能力 | 证据（`reference/folkways-master/`） | 级 |
| --- | --- | --- |
| sublevel 被登记为 `WorldPos` 的一个 Realm | `plugins/sable/SablePlugin.java:12` 注册 Passage；`core/shell/structure/SableSpaces.java:16` `implements WorldSpaces.Source`；`FolkwaysMod.java:87` `WorldSpaces.install(new SableSpaces())` | A |
| 站上/走下移动结构 = 一次 `Hop`（10 tick 平地费） | `plugins/sable/SablePassage.java:47-92`（枚举 sublevel 边缘落脚点造 Hop）、`:121-140` `connected()` 用 `Structures.obstacles` + `level.noCollision` 判连通 | A |
| 走上/走下的执行者 | `SablePassage.java:149-175` `Conveyance.step` 用 `body.getMoveControl().setWantedPosition(...)`，失败返回 `Going.Failed` | A |
| 站在静止结构上也判为"在船上" | `SableSpaces.java:37-58`（Sable 的跟随只跟会动的实体，静止的靠脚下实心块反查） | A |
| 结构被移动时同步地址 | `core/shell/mixin/SableAssemblyMixin.java:17-26` wrap `SubLevelAssemblyHelper.moveBlocks` + `core/shell/structure/SableMoves.java` | A |
| 远处结构按"装载票"保留 | `dev.ryanhcode.sable.api.sublevel.ticket.SubLevelLoadingTicket*`（仅类名/包名） | B |
| Create contraption 的座位语义 | `plugins/rail/passage/RailConveyance.java:70-108`（`network.board(...)` 上座）、`:148-158`（乘坐中）、`:182-194`（下车 teleport）、`plugins/rail/domain/mixin/AbstractContraptionEntityMixin.java:14-31`（接管 Create 的动态结构交互） | A |

**缺口（决定这条路线不能单独立项）**：
- `create-rockets` 只给推力，**没有发射状态机、没有维度穿越、没有空间站**（A）；维度穿越要靠 `deep-space` + `dimensional-sable`，而 `deep-space` 未声明后者（A/B），**依赖链长度 = create → sable → aeronautics → create-rockets → deep-space → dimensional-sable → veil**，任一环升级都要整链回归（与 `docs/pack/01-modlist.md:238` 的"Create 生态锁"判断一致）。
- `create-aeronautics` 几乎没有 gameplay API（A），一切要落在 **Create 的 contraption API + Sable 的 api 包 + mixin** 上——Folkways 已经在这么做（`folkways-rail.mixins.json`、`folkways-optional.mixins.json` 的 `SableAssemblyMixin`），但这是**成本与脆弱性最高**的一类集成。
- 移动结构本身要吃物理 tick（`Sable{Pre,Post}PhysicsTickEvent`），与 `travelCeilingMicros = 8000`（`FolkwaysConfig.java:257`）**不是同一预算**，但同样压在 server tick 上；`docs/pack/03-performance-budget.md` 尚未为它立账。

---

## 3. 自研路线：最小可信架构

### 3.1 多方块如何被居民建造——**复用 `build`，不需要新 Node 类型**

| 需求 | 现成机制 | 证据 | 级 |
| --- | --- | --- | --- |
| 声明"火箭长什么样" | Starlark `pattern`（多 phase、多轮生长），`draft.Derivation` 收 `List<String> phases` | `plugins/build/draft/Pattern.java:227,243`、`draft/Derivation.java:56`、`plugins/build/draft/Growth.java:19,28` | A |
| 委托一份建造 | `CommissionPacket` → `Commissions.begun/file` → `Rounds.drawOnce/draw/logged` | `plugins/build/BuildPackets.java:132,152,160,169,190`、`Commissions.java:43`、`Rounds.java:94-95` | A |
| 逐轮生长与"卡住"重试 | `Growing`（pattern/settings/anchor/growth/round/retryAt/stuck） | `plugins/build/Growing.java:19-37,77-105` | A |
| 把工作交给引擎（唯一合法改世界路径） | `BuildSite.Asks.submit` → `colony.submit(BuildContent.ID, dimension, work, ended)` | `plugins/build/BuildPresence.java:100-110`、`core/api/colony/Colony.java:43` | A |
| 完成判定 | `BuildPlanner.complete`（逐格 `satisfied` + `Joint.joined`） | `plugins/build/BuildPlanner.java:73-89` | A |
| 脚手架 | `ScaffoldNode`、`TemporaryScaffolds`、`BuildSite`（脚手架/材料/赔偿） | `plugins/build/ScaffoldNode.java`、`TemporaryScaffolds.java`、`BuildSite.java` | A |
| 蓝图捕捉/外部交接（含 Create 蓝图） | `Blueprint`、`BlueprintBook`、`CreateBlueprintHandoff`、`HeldBlueprints` | `plugins/build/Blueprint.java`、`BuildPackets.java:201`、`CreateBlueprintHandoff.java` | A |

**火箭的 phase 建议**（每 phase 一轮 `Growth`，就是"居民逐步建造"）：`基座/发射台 → 箭体框架 → 推进器组 → 燃料舱与管路 → 载荷舱/舱室 → 发射塔与脐带`。因为 `Growth` 与 `Round` 已是"建完上一轮再画下一轮"（`BuildScene.java:191` 的文案即此语义），所以不需要给火箭写专用的建造系统。

### 3.2 发射/着陆状态机与失败模式

- **形态**：新插件 `plugins/space`（owner id `folkways:space`），按 `BuiltinPlugins.install` 的方式接入（`plugins/BuiltinPlugins.java` 末尾的 `ModList.get().isLoaded(...)` 门控，`FolkwaysMod.java:70`），并用 `Declaring.colony(ID, scope -> {...})`（范式见 `BuildContent.java:52-58`）挂 tick/close。
- **一切推进由节点完成**（ADR-013 / R-AGE-9）：每个阶段是一次 `colony.submit(...)` 的 `Grown`，`ended` 回调推进状态；拒绝路径照 `BuildRefusal` / `RailRefusal` 写（`plugins/build/BuildRefusal.java`、`plugins/rail/domain/RailRefusal.java`）。居民要做的动作：装载推进剂（走 `wares`）、氧/食物打包、倒数值守、点火、在站卸货。
- **状态**：`PAD_TANKING(装填) → CREWED(乘员就位) → COUNTDOWN → ASCENT → COAST → CAPTURE/DOCK → LANDED`；失败态 `ABORT`（中止，可回收）、`STRUCTURAL_FAILURE`（结构损伤/爆炸——由"用错材料/超载"触发，需有前兆：`docs/design/08 §5.1` 的失败模式表）、`LOST`（失联：超窗未回，落地为"下次远征的调查点"）、`CRASHLAND`（迫降：在目标维度随机落地，货物损毁）。
- **零成本实现提示**：M4 第一版**不要真飞行动力学**。火箭形态由 `build` 决定、飞行是"发射台 → 过场 → 目标维度着陆舱"的一次 `Hop`（费用 `Fare.flat(ticks)`，见 `Fare.java:33-42`），失败模式由 `Going.Failed(RefusalKind)` 表达（`core/api/resident/Going.java:13`）。

### 3.3 空间站：维度还是子层？

两条都可行，**建议主线走"独立维度"，把子层留给后期"轨道造船"**：

| 方案 | 接入点 | 证据 | 优劣 |
| --- | --- | --- | --- |
| **独立维度**（推荐） | `Colony.views(server)` 已按 `ServerLevel` 分组；出行图按 `(colony, dimension)` 各自一份；`ColonyView.holdings()` 给出本维度持有的东西 | `core/api/colony/Colony.java:89`、`core/engine/colony/ColonyWays.java:105-109`、`plugins/sable/SablePassage.java:58-67` | 零新机制；不加载区块时天然"什么都没跑"，抽象结算好写 |
| **子层**（`Realm.Frame`） | `WorldSpaces.Source` 的自研实现 + `WorldSpaces.install(...)`；`Realm.Frame(UUID)` 与 Sable 无关 | `core/api/terms/WorldSpaces.java:16-53,102-132`、`core/api/terms/Realm.java:23-28` | 可与箭体同坐标系、可做"看得见的轨道站"；但要自己负责物理/序列化/装载票 |
| 跨 Realm 通道 | `Roaming` 为 boarding 与 landing **各自建 Tract**，`Crossing` 两端可不同 Realm，且会保留所有相关 Realm | `core/engine/travel/graph/Roaming.java:789-803,909-952`、`WorldPos.sameRealm/in`（`WorldPos.java:41-53`）、地面解析 `travel/Feet.java:19`、`graph/Ground.java:12-16` | **基底已支持**，火箭 Passage 只需返回"发射台 ↔ 站内着陆舱"的 Hop |

**不加载区块时如何继续模拟（允许抽象结算）**：维度不 tick ⇒ 站内不需要跑实体；生产/消耗按低频"批次结算"写进同一个 `Colony` 的持仓与库存（`Colony.stores/withhold/rule`，`Colony.java:31-40`），节奏用 `Cadence`（`core/api/colony/Cadence.java`，`BuildPresence.java:95,99` 的 `Cadence.claim/ Cron` 是现成范式；内部语义见 §6 未验证）。**红线**：抽象结算只能改 `Colony` 账本，不能直接改世界——改世界仍须 `submit(Grown)` + `Node.commit`。

### 3.4 太空生命维持（氧/温/食物）如何接入需求系统

- 新增一个 `UrgeSource`：`Declaring.urges(owner, source)`（`core/api/Declaring.java:30-32`）→ `Contributions.urges`（`core/api/colony/Contributions.java:19-23`）。
- 与既有需求**同构**：`LivingNeed` 是枚举 `BED/FOOD` + 翻译键 + 图标（`plugins/person/living/LivingNeed.java:7-24`），`Hunger` 是"计量 + 逐 tick `stepVitals` + 存档"的完整范式（`Hunger.java:29-101,107-122`）。**氧气 = 同一形状的第二条计量**（`Oxygen` 计量 + `stepVitals` 扣血 + `PackKeeps` 里的补给品），温度同理。
- "这个格子里有没有氧"有三条路，按成本排序：(1) **抽象**（本维度/本房间 hasOxygen 布尔，最省）；(2) **密封房间检测**（Creating Space 的 `RoomPressuriserBlockEntity`/`RoomAtmosphere`/`RoomShape` 是现成实现，但其房间对象是否对外可读未验证）；(3) **接 Ad Astra**：`OxygenApi.hasOxygen/setOxygen/removeOxygen` 与 `AdAstraEvents$EntityOxygenEvent/ZeroGravityTickEvent/ColdTemperatureTickEvent`（B 级：字节码常量池）——若采纳 Ad Astra 维度，这是最省的一条。
- 非人形单位（机械、牲畜、载具乘员）必须自带 `Locomotion`（`core/api/resident/Locomotion.java:10-21`；`Gait.BLOCKS_PER_TICK=0.165`，`core/api/terms/Gait.java:5`），出行图按 `ResidentKind.locomotion()` 分 Sort（`ColonyWays.java:115-128`）。**太空单位（舱外作业机器人等）应作为新 `ResidentKind` 注册**（`Declaring.residentKind`，`Declaring.java:46-48`），否则会被当人形处理。
- **预算**：新插件必须自报探针与预算（`docs/pack/03-performance-budget.md` R-PB-7）；注意 `travelCeilingMicros` 默认 8000µs 是**出行**预算（`FolkwaysConfig.java:257`，floor 250µs 在 `:264`），`TravelBudget` 用 AIMD 自适应（`core/engine/travel/TravelBudget.java:42-100`）。

---

## 4. 三个候选架构对比与推荐

| | **A. 建在 Ad Astra 之上** | **B. 建在 Create 系移动结构之上** | **C. 自研多方块 + 自研维度（推荐）** |
| --- | --- | --- | --- |
| 形态 | 用 Ad Astra 的火箭实体/发射台/轨道站与维度 | 火箭 = Sable sublevel + Create contraption + `create-rockets` 推力；维度来自 `deep-space`+`dimensional-sable` | 火箭 = `build` pattern 的多方块产物；空间站 = 自研维度（或 `Realm.Frame`）；飞行 = 一次跨 Realm 的 `Hop` |
| 能力上限 | 环境系统（氧/重力/温度）与多行星维度最省事；火箭永远是"点一下发射"的单体实体 → **与 ADR-011 直接冲突** | 视觉与物理上限最高（真移动、真可站、可轨道造船、可对接） | 居民执行力上限最高（每一步都是 `Node`）；视觉与物理最低（除非后期叠加 B） |
| 与居民联动难度 | **中**：能上船（乘客是 `LivingEntity`，B 级），但"建造"无法交给居民 | **低-中**：站上/走下已由 `SablePassage` 完成（A）；但上"座位"要按 `RailConveyance` 那套写，且火箭没有可用的 mod API（A） | **低**：三处扩展点全是官方接口，不需要 mixin |
| 工作量量级 | S（若只借维度/环境）／M（若要其站点可居住，站点语义未知） | **L**：自研飞行状态机 + 生命维持 + 对接，且依赖链 7 环 | **M**：1 个新插件（`build` 复用）+ 1 个维度 + 1 个 urge + 1 个 Passage；无新物理 |
| 主要风险 | 违反 ADR-011；火箭实体不可被居民建造 | `deep-space` 未声明 `dimensional-sable`（A/B）；aeronautics 无 API；物理 tick 预算未立账；许可链复杂 | 需要自己做"发射/着陆"的全部手感与表现；子层方案要自研物理序列化 |
| 作为 M4 | 只作**素材**（维度 + 环境 API + 轨道站贴图/方块） | **备选** | **主线** |

**推荐（M4）**

- **主线 = C**：ADR-011（多方块火箭 + 可居住空间站）与 ADR-013/R-AGE-9（每一步居民可执行）在 C 上是**直接可满足**的；三处扩展点都是 A 级证据，且不需要新增 mixin。M4 交付物建议定为：「居民按图案分工建完一枚火箭 → 装燃料/装氧 → 乘员登箭 → 发射并抵达轨道站维度 → 在站内继续吃饭/睡觉/劳动 → 分批运回」。**飞行做成剧本式状态机，不做动力学。**
- **备选 = B**：当玩家/我们需要"看得见的飞行"或"轨道造船"时启用；此时 C 的火箭状态机不变，只把"飞行实体"换成 Sable sublevel，把 `Conveyance` 换成"站在结构上"（直接复用 `SablePassage` 的模式）。
- **A 只作为素材与可选目的地**：如果采纳 Ad Astra 的行星维度，则氧气/温度/重力接入可省一大截（§3.4 第 3 条）；但**不采纳它的火箭实体作为终局通道**。

---

## 5. 与居民联动的接口清单（每条带依据）

| # | 联动需求 | 机制 / 接口 | 依据 | 级 |
| --- | --- | --- | --- | --- |
| 1 | 居民**建造**火箭 | Starlark `pattern` + `BuildSite` + `Growth` 多轮 | `plugins/build/draft/Pattern.java:227,243`；`draft/Growth.java:19,28`；`plugins/build/BuildSite.java` | A |
| 2 | 建造委托/进度/卡住重试 | `Commissions` + `Rounds` + `Growing(stuck,retryAt)` | `plugins/build/Commissions.java:43`；`Rounds.java:94-95`；`Growing.java:19-37,102-105` | A |
| 3 | 把工作交给引擎（改世界唯一路径） | `colony.submit(owner, dimension, Grown, ended)` | `plugins/build/BuildPresence.java:100-110`；`core/api/colony/Colony.java:43`；`core/api/work/Grown.java` | A |
| 4 | 蓝图 / 外部蓝图交接 | `Blueprint`、`BlueprintBook`、`CreateBlueprintHandoff` | `plugins/build/Blueprint.java`；`BuildPackets.java:201`；`CreateBlueprintHandoff.java` | A |
| 5 | 居民**搭乘**（注册一条通道） | `Declaring.passage(...)` → `Passages.register` | `core/api/Declaring.java:50-52`；`core/api/passage/Passages.java:15-17`；`plugins/sable/SablePlugin.java:12`；`plugins/rail/RailPlugin.java:28` | A |
| 6 | 通道如何描述"从哪上、到哪下、要多久、怎么走" | `Passage.hopsIn(Hop(service,boarding,landing,fare))` + `Conveyance.step` + `Going` | `core/api/passage/Passage.java:8-27`；`Hop.java:6`；`Fare.java:33-42`；`core/api/resident/Conveyance.java:10-21`、`Going.java:5-17` | A |
| 7 | 跨维度 / 跨 Realm 通行 | `Roaming.wire` 为两端各建 `Tract`，`Crossing` 两端可不同 Realm | `core/engine/travel/graph/Roaming.java:789-803,909-952`；`core/api/terms/Realm.java:14-28`；`WorldPos.java:41-53` | A |
| 8 | 移动结构/站体作为坐标空间 | `WorldSpaces.Source`（`frame`/`containing`/`aboard`）+ `WorldSpaces.install` | `core/api/terms/WorldSpaces.java:16-53`；`core/shell/structure/SableSpaces.java:16-98`；`FolkwaysMod.java:87` | A |
| 9 | 站在移动结构上/走下 | 现成 `SablePassage`（含静止实体的"脚下反查"） | `plugins/sable/SablePassage.java:37-58,121-140,149-175` | A |
| 10 | 结构移动时地址同步 | wrap `SubLevelAssemblyHelper.moveBlocks` | `core/shell/mixin/SableAssemblyMixin.java:17-26`；`core/shell/structure/SableMoves.java` | A |
| 11 | Create 动态结构座位（列车范式，可移植到火箭） | `RailConveyance` + `TransitNetwork` + `AbstractContraptionEntityMixin` | `plugins/rail/passage/RailConveyance.java:70-108,148-194`；`plugins/rail/domain/mixin/AbstractContraptionEntityMixin.java:14-31` | A |
| 12 | 站内**生活**：日常需求 | `LivingNeed(BED/FOOD)` 与 `Hunger` 计量 | `plugins/person/living/LivingNeed.java:7-24`；`Hunger.java:29-101,107-122` | A |
| 13 | 新增太空需求（氧/温） | `Declaring.urges(owner, UrgeSource)` → `Contributions.urges` | `core/api/Declaring.java:30-32`；`Contributions.java:19-23` | A |
| 14 | 多殖民地独立模拟/远离时结算 | `Colony`（`views`/`stores`/`withhold`/`rule`）与 `Cadence` | `Colony.java:31-40,89`；`core/api/colony/Cadence.java`；`BuildPresence.java:95,99` | A |
| 15 | 非人形太空单位 | `Declaring.locomotion` + `Declaring.residentKind` | `core/api/Declaring.java:42-48`；`core/api/resident/Locomotion.java:10-21`；`ColonyWays.java:115-128` | A |
| 16 | 装载/运力 | `Colony.stores/rule` + `Pack` 固定 18 格 | `Colony.java:31-40`；`docs/research/06-gap-analysis.md:74` | A |
| 17 | 预算与探针 | `travelCeilingMicros`（默认 8000µs）+ `TravelBudget` AIMD | `FolkwaysConfig.java:257,264`；`core/engine/travel/TravelBudget.java:42-100`；`docs/pack/03-performance-budget.md` | A |
| 18 | （若借 Ad Astra）环境接入 | `OxygenApi.hasOxygen/setOxygen`、`GravityApi.getGravity/setGravity`、`TemperatureApi.isLiveable`、`PlanetApi.isPlanet/isSpace`、`AdAstraEvents$EntityOxygenEvent` 等 | jar 内 `earth/terrarium/adastra/api/**` 类清单 + 常量池方法名 | B |
| 19 | （若借 Creating Space）计划表自动化 | `RocketSchedule.registerInstruction/registerCondition`、`RocketAccessibleDimension`（datapack registry） | jar 内 `com/rae/creatingspace/api/**` 类清单 + 常量池方法名 | B |
| 20 | （若走 Sable）远处结构保留 / 物理前后钩子 | `SubLevelLoadingTicket*`、`SablePrePhysicsTickEvent`/`SablePostPhysicsTickEvent`/`SableSubLevelContainerReadyEvent` | `dev/ryanhcode/sable/api/sublevel/ticket/*`、`api/event/*` 类清单 | B |

---

## 6. 未验证清单（不得当作依据）

1. **Ad Astra 火箭是否接受非玩家乘客**：类常量池显示乘客类型是 `LivingEntity` 与 `addPassenger(Entity)`，但 `getControllingPassenger` 的实际条件、`Rocket` 是否 `onlyPlayerRide` 未验证（无反编译器）。→ 若采纳 A 路线，**必须先实测**：把 `ResidentEntity` 塞进 `Rocket`。
2. **Ad Astra 空间站能否"被居住"**：只见到 `SpaceStationRecipe`/`SpaceStationHandler`/`ServerboundConstructSpaceStationPacket` 与 `adastra_space_station_data` 存储键（A）；站点是否生成可居住结构、是否随区块加载，未验证。
3. **Ad Astra 的 Terrarium License 全文**（未取得）：能否编译期依赖、能否随包分发，未核实。
4. **AR3 的整合包分发许可**：Modrinth 记为 All Rights Reserved；CF 页面未取得，**不得假设可进包**。
5. **`deep-space` 的真实依赖集**：`neoforge.mods.toml` 只声明 `neoforge/minecraft/create/veil`，但 mixin 目标 `dev.egg.SubLevelWarper` 属 `dimensional-sable`（MIT，1.0.5 / 2026-06-23）。**未验证**它在缺 `dimensional-sable` 时是否会因 `required: true` 直接崩。
6. **Creating Space 火箭是否收非玩家 actor**：`RocketContraptionEntity` 的 `RocketStatus = IDLE/TRAVELING/BLOCKED/ON_FINAL` 与 `hasFailed` 已见（B），但 Create contraption 的 actor 机制通常只认玩家（Folkways 的 Rail 是用 mixin 绕开的，A）；未实测。
7. **Stellaris 是否有隐藏 API 包**：只按"类名含 api"筛过，未全量枚举 `com.st0x0ef.stellaris` 下所有包。
8. **Sable 子层在离开视距/未加载时是否继续物理 tick**：只有 `SubLevelLoadingTicket*` 的类名证据（B），票证语义与超时行为未验证。
9. **`Cadence` 的抽象结算语义**（能否承担"站内离线生产"）未验证；只见到它是 `Colony` 的节奏领取器。
10. **本 reference 树缺 `.blockwright/mods.json`**（`build.gradle:81-86` 依赖它，`:106` 用 `compileOnly lib("sable")`）：说明我们 fork 后的编译期依赖要靠本项目自己的本地 jar 机制，具体坐标未确认。
11. **量级估计（S/M/L）全部未实测**，只是相对比较。

---

## 7. 对 M4 里程碑的建议

1. **立项形态**：在 fork 内新增 `plugins/space`（owner `folkways:space`），按 `BuiltinPlugins` 的既有写法接入并**用 `ModList.get().isLoaded(...)` 门控可选部分**（`FolkwaysMod.java:70,86-95`；`plugins/BuiltinPlugins.java` 末尾）。不要做成外部插件（ADR 已定 fork 内改造）。
2. **M4.0 三个最小 spike（各 ≤ 数日，先证明接口通）**：
   - (a) `Declaring.passage(...)` 注册一个 test Passage，boarding 在 Overworld、landing 在一个自制的空维度；验证 `Roaming.wire` 的跨 Realm `Crossing`（依据 `Roaming.java:789-803`）。
   - (b) 一条最小 Starlark `pattern`（3 phase）作为"火箭"，用 `BuildPlanner.complete` 判定完成（依据 `BuildPlanner.java:73-89`）。
   - (c) 一个新 urge `OXYGEN` 挂在 `Contributions.urges`，与 `Hunger` 同构（依据 `Hunger.java:29-101`、`Contributions.java:19-23`）。
3. **M4.1 主线交付（推荐验收线）**：居民建完火箭 → 装填 → 乘员登箭 → 剧本式飞行 → 抵达空间站维度 → **站内继续吃饭/睡觉/上工** → 货运回地表。**明确不做**：真飞行动力学、真实气压/温度场、对接物理。
4. **预算先立账**：在新插件立项时同时提交探针与常态/峰值预算（R-PB-7），并区分"出行预算"（`travelCeilingMicros=8000`）与"太空结算预算"（新账）。
5. **pack 侧修订两条**：(1) 若进 `deep-space`，必须同时进 `dimensional-sable`（并做一次不带它的崩溃验证）；(2) 重新评估 `advanced-rocketry-3`（ARR + beta）与 `stellaris`（NC）——两者都不建议进主线，**不要作编译期依赖**。
6. **备选触发条件**：当"玩家/演示需要看见物理飞行"或"轨道造船"被排进里程碑时，切到候选 B，并把 C 的火箭状态机保留（只替换"飞行载体"为 Sable sublevel，复用 `SablePassage` 的移动结构通行范式）。
7. **不要做的事**：不要为"多方块火箭"新写一套 Node 类型（`build` 已覆盖，§3.1）；不要在抽象结算里直接改世界（必须走 `submit(Grown)`）；不要把 18 格 `Pack` 硬改成大容量来运推进剂（`docs/research/06-gap-analysis.md:74` 的中长期方案是多格容器/载具负载）。