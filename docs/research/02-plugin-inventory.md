# 基底：插件清单与玩家可见内容（r02）

```
状态：草稿
负责人：调研 agent（代码考古，只读，未修改任何源码）
最后更新：2026-10-19
上游依据：reference/folkways-67f28b0/（基线 67f28b0；引用已按 r10 迁移）
下游影响：docs/pack/*（整合包内容取舍）、plugins/*（新插件样板选型）
```

> 行内路径均相对 `reference/folkways-67f28b0/`。术语取 `mods/core/src/main/resources/assets/folkways/lang/zh_cn.json` 官方译名（下称 zh_cn）。
> 插件代码规模合计 13 个目录 / 384 个 .java / 约 38.4k 行；`core`+`front` 另有约 42k 行基础设施。

---

## 0. 架构总览：一个插件由什么构成

| 环节 | 接口/事件 | 出处 | 作用 |
| --- | --- | --- | --- |
| 安装 | `XPlugin.install(IEventBus)` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/BuiltinPlugins.java` | 每个插件唯一入口；内置插件也走这条路，与外部 mod 的插件同等 |
| 服务端声明 | `Declaring`（mod bus） | `mods/core/src/main/java/io/github/izakyl/folkways/core/api/Declaring.java` | `refinement` / `urges` / `colony(owner, ColonyContext)` / `vocation` / `locomotion` / `residentKind` / `passage` |
| 每殖民地状态 | `ColonyContext` | `mods/core/src/main/java/io/github/izakyl/folkways/core/api/colony/ColonyContext.java` | `share(state)` 注册状态对象、`tick`、`closed`、`urges`、`watch(held, …)`；状态对象通常实现 `Facing`（`act` / `board` / `boardAt`） |
| 面向玩家登记 | `Registering`（`front/api`） | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/Registering.java` | `enrollment`（可画的区域类型）、`admission`（某类居民如何入籍）、`facing`（找状态对象） |
| 区域类型 | `Enrollment(delegations, schema, pages)` + `Delegation(id, Shape, Schema, icon)` | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/Enrollment.java`、`Delegation.java` | 玩家用手势画完后可选的一种“用途”，带自己的设置项与面板页 |
| 手势 | `Shape.Gesture` = POINT / BOX / LINE | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/Shape.java` | `Block`/`Body`=点选；`Volume(maxCells)`=圈地；`Path(maxPoints)`=画线 |
| 设置项 | `Schema.Setting` = Flag / Count / Choice / Items | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/Schema.java` | 面板上的开关、数值、下拉、物品筛选器 |
| UI 登记 | `RegisteringUi` | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/ui/RegisteringUi.java` | `page(PageKind, …)`、`inlay`、`outline`；核心 5 页在 `mods/core/src/main/java/io/github/izakyl/folkways/front/ui/screen/PageKinds.java` |
| 教程 | `Scenes.folder(...)` | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/ponder/Scenes.java` | Ponder 场景成为面板「教程」页里该插件自己的文件夹 |
| 数据驱动 | `Shelves.Shelf` + 数据包注册表 | `mods/core/src/main/java/io/github/izakyl/folkways/library/Shelves.java` | 书架名：`pattern` `piece` `blueprint` `resident_model` `resident_skin`；注册表：`resident_look` `resident_look_set` `resident_name` |
| 工作单元 | `Node` + `NodeSpec` | `mods/core/src/main/java/io/github/izakyl/folkways/core/api/work/Node.java`、`NodeSpec.java` | needs/gives/leaves/tools/workload/effort/vocation/doing；`Outcome.Done/Failed` |
| 拒绝 | `RefusalKind.Named` | `mods/core/src/main/java/io/github/izakyl/folkways/core/api/terms/RefusalKind.java` | 自动拼 `folkways.refusal.<Area>.<CONST>`；`Shortfall` = LACKING / NO_ROOM |
| 面板内容 | `Board` / `Board.Row` / `Board.Act` | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/panel/Board.java` | 插件自己产出页面行与按钮动作 |

---

## 1. 插件总表

| 插件 | 玩家可见功能（官方中文） | 依赖的核心 API | 数据驱动 | 规模 / 关键类 |
| --- | --- | --- | --- | --- |
| `person` 居民 | 居民、人类居民页、居民分工、模型池、姓名池、起居（吃饭/睡觉）、逃跑、接纳一人 | `ResidentKind` `Locomotion` `Bodies` `PackKeeps` `Enrollment` `Admission` `RegisteringUi` 数据包注册表 | 高（3 个数据包注册表 + 2 个书架） | 68 / 6984；`PersonBody` `ResidentEntity` `PersonPresence` `Immigration` `LivingPresence` `LookPool` `ColonyNames` |
| `wares` 工坊 | 工坊页、工作站、制作、熔炉/高炉/烟熏炉、燃料、取出成品 | `Vocation` `Refinement` `Containers` `ItemFilter` `Enrollment` `Schema` `PageKind` | 中（配方走原版 RecipeManager；工作站硬编码） | 32 / 2201；`WaresPresence` `Stations` `CraftRecipes` `Bookings` `Smelt` `WorkSiteBlockEntity` |
| `build` 建造 | 建造页、蓝图页、样式（建筑样式）、建造单、脚手架、逐轮生长、交给殖民地建造 | `Vocation` `Shelves` `Pattern`(Starlark) `Enrollment` `Shape.Volume/Path` `Schema` `PageKind` | 极高（`.star` 脚本 + `.nbt` 结构） | 112 / 15003；`BuildPresence` `BuildSite` `BuildPlanner` `Patterns` `Templates` `Growing` `Blueprint` |
| `farming` 农业 | 农田、作物、锄地、播种、收割、伐木（林地）、补种 | `Vocation` `Enrollment` `Shape.Volume` `Schema` `Workload.Haste` | 中（作物由方块注册表推断；标签） | 19 / 1692；`FarmPresence` `Crop` `Habit` `Plot` `FieldChores` `Till/Plant/Harvest/FellNode` |
| `pasture` 牧场 | 牧场、牲畜（牛/羊/猪/鸡）、目标头数、剪羊毛、挤奶、宰杀牲畜、收集牲畜产物 | `Vocation` `Enrollment` `Shape.Volume` `Schema` | 低（4 种牲畜硬编码） | 21 / 1530；`PasturePresence` `Enclosure` `Herd` `Livestock` `PenChores` |
| `fishing` 捕鱼 | 渔场、钓鱼 | `Vocation` `Enrollment` `Shape.Volume` `Node` | 低（仅配置 + 工具清单） | 8 / 445；`FishingPresence` `Spot` `CastNode` |
| `groundwork` 整地 | 整地、清理、填充、除草、拔花、砍树、搬运 | `Enrollment` `Shape.Volume` `Schema`（无新工种） | 低（全靠 Schema 开关） | 13 / 1048；`GroundPresence` `Survey` `Chores` `Break/Fill/Fell/HaulNode` |
| `patrol` 巡逻 | 巡逻路线、巡逻、值守、迎敌、抑制刷怪 | `Vocation` `Enrollment` `Shape.Path` `NeoForge EVENT_BUS` | 低（路径 + 配置） | 8 / 551；`PatrolPresence` `Beats` `Wards` `WatchNode` `StrikeNode` |
| `orders` 订单 | 订单、订单草稿、维持、送来、收纳、槽位、库存页产出统计 | `Enrollment` `Schema` `Board` `Asking` `Grown` `StoreRule` `Delivery` | 中（NBT 持久化 + Schema） | 8 / 927；`OrdersPresence` `Order` `Shelf` `OrderAct` |
| `rail` 铁路 | 铁路页、列车长、驾驶、乘车、接管列车 | `Vocation` `Passage` `Conveyance` `Keepouts` `Enrollment` | 低（读 Create 时刻表） | 41 / 3151；`RailPresence` `CreateTransitNetwork` `Timetable` `Departures` `RailPassage` |
| `dispatch` 调度 | 调度页、物流网络、链网、邮箱、取货点、仓库管理员、打包包裹、收取包裹 | `Vocation` `Refinement/Intent/Produce` `Workshop` `Enrollment` | 低（读 Create 物流） | 39 / 4025；`DispatchPresence` `Networks` `Depot` `Counter` `Pack/Collect/Take/StrayNode` |
| `golem` 傀儡（可选） | 傀儡、修理傀儡、移交傀儡 | `ResidentKind` `Participation/Stake` `Admission` `UrgeSource` | 低 | 13 / 617；`GolemKinds` `GolemAi` `GolemBody` `MendAction` |
| `sable` 动态结构通行（可选） | 居民走上/走下带物理结构的载具 | `Passage` `Hop` `Fare` `Conveyance` `WorldSpaces.Frame` | 低 | 2 / 176；`SablePassage` |

未在 `plugins/` 下但玩家可见的插件级内容：`front`（殖民书面板全套 UI/网络/物品）、`core`（工种引擎、规划器、寻路、仓库）。

---

## 2. 插件详述

### 2.1 person —— 居民（其它一切插件的服务对象）
- 玩法：合成殖民书 → 点选床与容器 → 面板「居民分工」页按工种开/禁并滚轮设优先级 1–4 →「接纳一人」迎来新居民；「模型池」「姓名池」可逐项增删或整体替换为数据包集合。
- 背后：注册 `folkways:resident` 实体（`PersonBody`，MISC，0.6×1.95）；`ResidentKind.growing` 给出先天参与表（living/fear/patrol 恒参与，各工种可选参与）；`SettlerQueue` 让等候人数随人口线性放慢（`settlerIntervalTicks=2400`、上限 5）。
- 状态机/节点：`EatAction` / `SleepAction` / `FleeAction`（Node）；urges = 吃饭、睡觉、逃跑、闲逛、修补、迎敌；`LivingPresence` 管疲劳/饱食/床位认领，卡片显示鸡腿与月亮。
- 拒绝：`ImmigrationRefusal`（NOBODY_WAITING / NO_ROOM_IN_THE_WORLD / SWITCHED_OFF / NOT_ON_THE_ROSTER）、`LivingRefusal`（NOTHING_TO_EAT / NOT_ON_THE_BOOKS）、`folkways.refusal.settler.bed|food`。
- 数据驱动：极高。`data/folkways/folkways/resident_look/*.json`（type=skin/model）、`resident_look_set/*.json`、`resident_name/default.json`；另有服务器文件夹 `folkways/resident_model|resident_skin`。
- 依赖：LDLib2 必装；Ponder 内置；GeckoLib / 车万女仆（Touhou Little Maid）可选，女仆模型由 `MaidAssets` 现场转成 GeckoLib 几何。

### 2.2 wares —— 工坊
- 玩法：用点选的书点工作台、切石机、锻造台、熔炉、高炉、烟熏炉 → 成为工作站；工坊页列出工作站数量与各自燃料（默认煤炭/木炭）。
- 背后：`Stations.PACK_STATIONS`（crafting_table / stonecutter / smithing_table）与 `COOKERS`（furnace/blast_furnace/smoker → SMELTING/BLASTING/SMOKING）；`CraftRecipes` / `RecipeIndex` / `Ingredients` 直接查询原版 `RecipeManager`；`Bookings` 把熔炉按批次排队（一炉同时只烧一炉料）。
- 状态机/节点：`CraftNode`（抽象）、`LoadNode`、`FuelNode`、`TakeCookedNode`、`ClearNode`、`PackCraftNode`；`Smelt.SMELTING` 是 `Refinement`，把「一件成品」展开成「装料 →（加燃料）→ 取出」的 Grown 图。
- 拒绝：`WaresRefusal`（NOT_A_STATION / NOTHING_TO_WORK_WITH / STATION_FULL / STATION_BUSY），其中两个带 Shortfall。
- 方块实体：`folkways:work_site`（`WorkSiteBlockEntity`，空壳标记）挂在三个原版方块上——本模组**不注册任何新方块**。
- 要点：切石机按自身配方、锻造台只升级装备不加纹饰、烧好无人要的成品会被取出腾位。

### 2.3 build —— 建造、样式与蓝图
- 玩法：书切到圈地/画线 → 框完右键 → 用途里选「样式」→ 选一种 pattern → 调 knobs（材料、尺寸、灯具…）→「开工」；创造模式可「直接建成」；「建造页」列每份建造单的进度与「还需要」，删单会停工并拆脚手架。
- 蓝图：Create 蓝图工具多一项「交给殖民地」（空位可「保持原样」或「挖掉那里原有的方块」）；蓝图页把 `.nbt` 结构拿在书上立到瞄准处交接（大体量切片上传 `BlueprintChunkPacket`）。
- 背后：`BuildPresence`（613 行）管建造单、工地、占用与改名；`BuildSite` / `BuildJob` / `BuildTarget` 逐格砌筑；`Footprints` / `Layering` / `Fidelity` 处理层序与忠实度；`TemporaryScaffolds` + `ScaffoldNode` 在无可站立处搭临时柱；`Bystanders` 把被方块挤住的生物推开（原版从不允许往生物里放方块）。
- 状态机/节点：`LayNode` / `StripNode` / `PourNode` / `DrainNode` / `JoinNode` / `BuildSite.Stay`；轮次生长由 `Rounds` + `Growing`（NBT 存 round/kept/reach）驱动。
- pattern 格式（`data/folkways/folkways/pattern/*.star`，Starlark）：`accepts = ["zone"|"path"]`、`knobs = [count/choice/items/flag(...)]`、`lang = {en_us, zh_cn, zh_hk, zh_tw}`、`def draw(site)` 或 `def grow(site)` + `grown(parts, keep = {...})`；校验失败调 `reject("folkways.draft.error.*", args)`。
- 拒绝：`BuildRefusal`（8 项：UNKNOWN_BLOCK / NO_WAY_TO_BUILD / NO_STANCE / ACCESS_DEPENDENCY / CONTESTED / OCCUPIED / CELL_NOT_LOADED / NO_SUCH_ORDER）、`DraftRefusal`（10 项），外加约 60 条 `folkways.draft.error.*` 几何/材料校验。
- 依赖：Create 可选（仅「交给殖民地」一项）。

### 2.4 farming —— 农业
- 玩法：圈农田 → 选作物（默认小麦）+「清理草」「清理花」（默认开）→ 居民循环锄地、播种、收割；作物收割后原地补种下一轮。
- 特例（写进教程与代码）：甘蔗长到 3 格、竹子 4 格才砍且只砍到最下一节；西瓜/南瓜只收果实、茎留原地、茎种在离边一格处；林地＝作物为树苗的农田，整树连叶伐倒后补种，深色橡树四棵一组。
- 背后：`Crop` 从方块注册表推断可种清单（`CropBlock` / `SaplingBlock` / 白名单），`Habit`（Herb / Cane / Stem / Tree）决定收割形态；`Plot` 管行列与过道（竹子隔行留过道）；`FieldChores` 生成工作。
- 状态机/节点：`TillNode` / `PlantNode` / `HarvestNode` / `FellNode` / `FarmNode`；单格 10 tick，伐木按原木 12 tick、树叶 2 tick。
- 拒绝：`FarmRefusal`（NOTHING_TO_WORK / GROUND_TAKEN）。
- 工种：`folkways:farming`，工具 `ItemTags.HOES`，perk `farming_quick_hands`(4 级)、`farming_replant`(1 级)。
- 数据驱动：标签 `folkways:weeds`、`folkways:flowers`、`folkways:tillable_under_weeds`；作物清单随其它 mod 的作物方块自动扩展。

### 2.5 pasture —— 牧场
- 玩法：圈牧场 → 三项设置：养什么牲畜（牛/羊/猪/鸡）、目标头数 0–64、剪羊毛开关；牧场页显示现有头数 / 目标 / 其中成年数。
- 背后：`Enclosure` 按动物实际行走判定围栏（可上一格、可任意下落、不穿栅栏也不穿门），未被围住或围成多块会在卡片上显示红字；低于目标成对喂食繁殖（幼崽计入），高于目标一次宰杀完且只宰成年，目标 0 即清空成年。
- 状态机/节点：`PenNode`（抽象）+ `FeedNode` / `CullNode` / `ShearNode` / `MilkNode` / `GleanNode` / `AnimalNode`；牛奶只在殖民地缺牛奶时才挤，每头牛每天一次。
- 拒绝：`PastureRefusal`（BEAST_GONE / BEAST_TAKEN / NOTHING_TO_TAKE / NOTHING_TO_WORK_WITH / NOT_FEEDABLE / STILL_STANDING）。
- 工种：`folkways:herding`，perk `herding_quick_hands`(4)、`herding_butcher`(3)；工具需求剪刀。
- 数据驱动：牲畜 4 种硬编码（`Livestock.ALL`），加牲畜需改代码。

### 2.6 fishing —— 捕鱼
- 玩法：圈的是居民站立的**岸边**（不是水面）；每个渔场独占离岸边最近的一格水，重复占用则后来者闲着；居民站岸边等鱼咬钩（有线连浮漂）。
- 背后：`FishingPresence`（64 行）为每个渔场分配水格；`Spot` 描述岸位 + 水格；`CastNode` 是持续等待型 Node，`fishingHaste` 缩短咬钩等待。
- 拒绝：`FishingRefusal`（NO_WATER / LINE_ALREADY_OUT）。
- 工种：`folkways:fishing`，工具钓鱼竿（必须在殖民地工具清单上）。
- 数据驱动：仅 `maxFishCells`（默认 4096）与工具清单。**本插件是理解整套插件 API 的最小完整样例。**

### 2.7 groundwork —— 整地
- 玩法：框一块地 → 在设置里勾选清理 / 填充 / 除草 / 拔花 / 砍树 / 搬运（可多选）+ 选择填充方块；清理自上而下只挖框内、填充自下而上铺满（原样格子不动）。
- 分割：清理与填充由**建造**工种做、除草与砍树由**农业**工种做、搬运由**搬运**工种做——整地本身不自立工种。
- 背后：`Survey` 每个 sweep 读一次世界，只把**现在能做**的格变成工作（一层挖开才露出下一层）；`Chores` 缓存 standing/busy/spent 三态防止重复派工；`Job` 用实体 key 而非坐标来记搬运物。
- 状态机/节点：`BreakNode`（按硬度 10–80 tick）/ `FillNode` / `FellNode` / `HaulNode` / `GroundNode`。
- 拒绝：`GroundRefusal`（NOTHING_TO_WORK / NOTHING_TO_LAY）。
- 数据驱动：全部来自 `Schema` 开关，是「纯区域 + 多种活」的样板。

### 2.8 patrol —— 巡逻
- 玩法：画一条巡逻路线 → 有巡逻工种的居民沿路值守，并在值守点周围抑制**自然/巡逻**刷怪（刷怪笼、刷怪蛋、召唤不受影响）、攻击敌对生物。
- 背后：`Beats` 沿路径每 ≤ `patrolWardRadius`（默认 16）放一个 `Stop`，并在上下 8 格内找可落脚处；`Wards` 监听 NeoForge `MobSpawnEvent.PositionCheck` 直接 FAIL；ward 只存内存（`ServerStoppedEvent` 清空），重载世界需重新巡一圈。
- 状态机/节点：`WatchNode`（值守并留下 ward）/ `StrikeNode`（走到射程内挥击，目标消失不算失败）。
- 拒绝：无自有枚举；失败走通用 labor 拒绝。工具：`Tags.Items.MELEE_WEAPON_TOOLS`（其它 mod 武器只要挂通用标签即可用）。
- 数据驱动：`Shape.Path(maxPatrolPoints=32)` + 配置 `patrolWardTicks=2400`。

### 2.9 orders —— 订单
- 玩法：手持书右键殖民地的一个箱子 → 订单页登记草稿：物品、下界、上界、起始/结束槽位；点「维持」为常备（少于下界补到上界）、「送来」为单次（补到上限即完成）；容器可设「收纳」只收 / 不收草稿物品、「殖民地可用槽位」限范围。
- 背后：`OrdersPresence`（541 行）把 orders/shelves 存进殖民地 NBT；每 20 tick（`Cadence` 分摊）读世界算出 `Grown` 目标经 `Asking` 交给规划器；补货量由 `Order` 与在途量决定；`Shelf` 把收纳与槽位翻译成 `StoreRule`。
- 只订成品：原料由制作工种自取；需要烧炼的送熔炉（燃料来自工坊页燃料清单）；无人会为订单外出挖矿，缺料就干等（教程明说）。
- 页面：`PageKind.boarded("folkways:orders")` → 只在瞄准某个容器时打开（`boardAt`），否则列全部订单；上限 `MAX_ORDERS = 256`。
- 拒绝：`OrderRefusal`（TOO_MANY / UNKNOWN_ITEM / NOT_A_CONTAINER / NOT_ADMITTED / ORDERED_HERE）。

### 2.10 rail —— 铁路
- 玩法：副手持殖民书 + 对一列**还没有时刻表**的列车驾驶座使用列车时刻表 → 列车收下时刻表、殖民地接管；空手再点同一座位取回时刻表并交还；有驾驶工种的居民在停站且驾驶座空着时坐上去。
- 出行：满足「有列车长在车上 + 停靠 ≥2 站 + 还有空座」的列车即成为居民出行方式，居民按其计划乘它从一站到另一站（`RailPassage` / `RailConveyance` / `RailFare`）。
- 背后：`CreateTransitNetwork`（读 Create `ScheduleRuntime`）判断运行/停靠/缺列车长；`Departures` 记「每站发车次数」，判断某班车是否开走**只看计数不看时钟**；`Itinerary` 用上次实跑时长推算到站时间。
- 状态机/节点：`ConductNode`（Continuous，坐上驾驶座）/ `TakeSeatNode`。
- 拒绝：`RailRefusal`（SEAT_TAKEN / SEAT_GONE / ANOTHER_COLONY / RUN_MISSED / LINE_WITHDRAWN）+ `TimetableFault` 7 条「不搭乘」理由（未填站名、通配名、无此站、重名、停站条件非纯定时、第 n 项不是停站、停靠少于两站）。
- 其它：`Trackways` 让任何人都不沿铁轨走（轨宽按最宽列车、高度按车厢）；4 个 Create mixin（Train 离站、Carriage 载客存档、TrainMapManager、AbstractContraptionEntity）。

### 2.11 dispatch —— 调度
- 玩法：书点选仓储链接站 / 仓储发报机 → 接管整个物流网络；点货物蛙港 / 链条输送机 → 接管整张链网；点邮箱 → 接管该邮箱（只用殖民地接管的列车寄送）；再点一次交还。
- 门槛：仓储发报机旁要有「调度」工种居民坐着当仓库管理员（同层或下一层坐垫），否则只统计库存不订货；链网必须都在同一维度、链条在转、每个打包机都接蛙港，或全部走邮箱，否则暂停下单（`NetworkFlaw` 9 类缺陷）。
- 取货：链网上每个蛙港（除发货蛙港与向下倒包的蛙港）与殖民地接管的邮箱都是取货点，发往最方便取的那个；地址为 `*` 或含 `{ } , \` 的取货点不会被自发使用；无人等的包裹会被清空（`StrayNode`）。
- 背后：`DispatchPresence`（808 行，最大）管已接管网络/链网/邮箱与订阅；`Depot` 处理包裹与槽位；`Counter`（172 行）是「殖民地自己的邮政」：当某网络不打包时，refinement 把「要货」展开成 `PackNode` + `CollectNode` 的 Grown 图。
- 状态机/节点：`PackNode` / `CollectNode` / `TakeNode` / `StrayNode` / `KeepPostNode`（Continuous 值守）。
- 拒绝：`DispatchRefusal`（12 项：NO_PORT / NOTHING_ARRIVED / NO_SUPPLY / REQUEST_REJECTED / SEAT_TAKEN / ANOTHER_COLONY / NOT_YOURS / NO_NETWORK / NOT_PACKED / PORT_FULL / OFF_CHAIN / CHAIN_ELSEWHERE）。
- mixin：GlobalStation（列车自动收驿站包裹）、PackagePortBlockEntity、StationBlockEntity、StockTickerBlockEntity。

### 2.12 sable —— 动态结构通行（可选）
- 玩法：装了 Sable 时，居民能走上有物理结构的船/飞艇——动态结构与岸边之间的落差被当作一次可通行的 hop；结构离开岸边则此行失败。
- 背后：`SablePassage` 实现 `Passage`，扫描每个子关卡包围盒的边缘格，向下 1 格找到可落脚处，再检查水平 4 向岸边是否连通（高差 ≤0.5、水平 ≤1.5、无碰撞），成功后生成**成对** `Hop`（上船 / 下船）；`aboard(Hop)` 返回 `Conveyance`，每 tick 把 mob 的 `MoveControl` 指向对岸，80 tick 超时。
- 拒绝：`folkways.refusal.sable_step_gone`（动态结构与岸边的连接已断开。）。
- 依赖：由 `ModList.get().isLoaded("sable")` 检测，但 **`neoforge.mods.toml` 未声明 sable 依赖**（属隐性可选集成）。
- 数据驱动：无。**这是「新增一种通行方式」的最小样板。**

### 2.13 golem —— 傀儡（可选）
- 玩法：点选一个属于你的金属傀儡 → 作为居民加入殖民地；只有傀儡主人能移交，已属他殖民地的带不走；离开殖民地后恢复原行为。
- 限制：不吃饭不睡觉，本领是造出来就有的（`Growth.Built` 不给成长）；身体决定工种——大型金属傀儡：搬运/建造/巡逻；犬形：搬运/巡逻；人形：再加制作/驾驶/调度；生命 <60% 且包里有可修材料（如铁锭）会自我修补。
- 背后：`GolemKinds` 为 ModularGolems 的 metal/humanoid/dog 各建一个 `ResidentKind`（含 barehanded 表：金属与犬形徒手巡逻）；`GolemAi` 摘掉原目标、`GolemBody` 适配身体、`GolemPresence` 负责 urge；`GolemAdmission` 校验主人与归属。
- 状态机/节点：`MendAction`（Node）。
- 拒绝：`GolemRefusal.NOTHING_TO_MEND_WITH`；`folkways.refusal.golem.already_settled_elsewhere` / `not_yours_to_hand_over`。
- 数据驱动：无。是「把第三方实体接成居民」的样板。

---

## 3. 玩家可见内容清单

**物品**（`mods/core/src/main/java/io/github/izakyl/folkways/front/engine/registry/FolkwaysItems.java`）
- `folkways:colony_book` 殖民书（stacksTo 1、fireResistant；合成：1 本书 shapeless，见 `data/folkways/recipe/colony_book.json`）
- `folkways:tag_filter` 物品标签（带 `FILTER_TAG` 数据的标签筛选器，用于物品筛选器 UI）

**方块**：无自注册方块。`folkways:work_site` 方块实体（`mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/wares/WaresBlockEntities.java`）挂在原版 crafting_table / smithing_table / stonecutter 上。
**实体**：`folkways:resident` 居民（`MobCategory.MISC`，0.6×1.95，eyeHeight 1.74，clientTrackingRange 8）。
**区块实体**：`folkways:work_site`（另有 `FolkwaysDataComponents`、`FolkwaysPlayerAttachments`、`FolkwaysAttachments`）。

**界面页面**（核心 5 页 + 插件页；`mods/core/src/main/java/io/github/izakyl/folkways/front/ui/screen/PageKinds.java` 与各 `*Content`）
- 核心：`residents`（居民分工）、`metrics`（库存）、`members`（成员）、`lessons`（教程）、`settings`（设置）
- `person`：`person`（人类居民）、`names`（姓名池）、`looks`（模型池）；`living` 不建页而画进人类居民页（`inlay` + `outline`）
- `wares` 工坊、`build` 建造 + `blueprints` 蓝图、`pasture` 牧场、`rail` 铁路、`dispatch` 调度
- `orders`：`folkways:orders`，`PageKind.boarded`，只在瞄准容器时打开
- 无自有页面：`farming`、`fishing`、`groundwork`、`patrol`、`golem`（只在世界卡片/区域设置里出现）
- 悬停任意页面标签按住思索键 → 播放该页教程；教程页里每个插件一个文件夹（`Scenes.folder`），共 16 个 Ponder 场景（含核心 3 个：书的手势、殖民书、殖民地面板）

**图案（pattern）**：`data/folkways/folkways/pattern/` 共 10 个 `.star`
| 文件 | 中文 | 手势 | 备注 |
| --- | --- | --- | --- |
| `road.star` | 道路 | path | 宽 3–9、长 2–96，路灯/路缘/填土 |
| `railway.star` | 铁路 | path | 只能轴对齐或 45°，转弯需留直线 |
| `arch_bridge.star` | 拱桥 | path | 跨度 6–96、宽 3–15，仅两点 |
| `city_wall.star` | 城墙 | path | 高 5–14、厚 3–9、总长 ≤120 |
| `dock.star` | 码头 | path | 先岸上后水面，长 6–64 |
| `arcade.star` | 风雨廊 | path | 长 6–96，按开间 |
| `mine.star` | 矿井 | zone | 逐轮生长：竖井→支巷→追矿脉 |
| `quarry.star` | 采石场 | zone | 每边 8–64、深 0–16 |
| `terraced_field.star` | 梯田 | zone | 每边 6–56、台阶高 1–4 |
| `grading.star` / `materials.star` | （库） | — | 供其它 pattern `load()` 的几何与材料池，无标题 |

**蓝图 / 构件**：书架 `piece`（`data/folkways/folkways/piece/door.nbt` 一件）、`blueprint`（主 jar 未随包蓝图；`mods/vanilla/src/gametest/resources/data/folkways/folkways/blueprint/test_hut.nbt` 仅测试用）；玩家文件放进 `folkways/blueprint`。
**命令**：`/folkways library`（权限 `Commands.LEVEL_GAMEMASTERS`），列出每个书架装了什么、来自哪个数据包、哪些文件被拒，并可点击打开目录（`mods/core/src/main/java/io/github/izakyl/folkways/library/LibraryCommand.java`）。
**进度**：仅 1 个 —— `data/folkways/advancement/recipes/misc/colony_book.json`（拿到书解锁殖民书配方）。
**标签**：`folkways:weeds`、`folkways:flowers`、`folkways:tillable_under_weeds`；为 Create 提供 `create:ignore_seat`（居民不被当作乘客）。
**数据驱动外部入口**：服务器文件夹 `<gamedir>/folkways/{pattern,piece,blueprint,resident_model,resident_skin}`（命名空间 `local`）+ 数据包 `data/<ns>/folkways/<同名书架>`；数据包注册表 `folkways:resident_look`、`resident_look_set`、`resident_name`。
**按键/输入**：`key.folkways.overhead`（俯瞰，类目 `key.categories.folkways`）以及书中手势、Ctrl+滚轮调距离等（见 `folkways.keys.*`）。
**配置**（`FolkwaysConfig`（上游已拆为三份），SERVER）：`immigration.enabled`、`foodPerResident=8`、`settlerIntervalTicks=2400`、`maxWaitingSettlers=5`、`maxFishCells=4096`、`maxPastureCells=1024`、`maxFarmCells=4096`、`maxGroundworkCells=16384`、`maxPatrolPoints=32`、`patrolWardRadius=16`、`patrolWardTicks=2400`、`maxBuildCells=65536`、`maxBlueprintVolume=1048576`、`drawSeconds=10`、`refusedRecipes`（黑名单配方）、各 `*Haste` 列表、`planHorizonTicks=3000`、`pathSearchBudget=8.0`、`travelCeilingMicros=8000`。
**Mixin 配置**：9 个（`folkways.mixins.json`、`-optional`、`-rail`、`-dispatch`、`-build`、`-wares`、`-person`、`-front`、`-desk`）。
**依赖**（`mods/*/src/main/resources/META-INF/neoforge.mods.toml`，上游已拆为四份）：必需 minecraft / neoforge / `ldlib2` / `ponder`（内置）；`create`、`geckolib`、`shouldersurfing`、`jei`、`emi`、`modulargolems` 为可选；`sable` 未声明但被代码检测。

---

## 4. 官方中文术语表（zh_cn.json，150 条）

**殖民地与成员**（17）
| key | 中文 |
| --- | --- |
| `item.folkways.colony_book` | 殖民书 |
| `folkways.action.new_colony` | 新建殖民地 |
| `folkways.colony.create` | 建立殖民地 |
| `folkways.panel.title` | 殖民地 |
| `folkways.charter.claimed` | 这个殖民地归你了。任何一本殖民书都能打开它，包括这本。 |
| `folkways.charter.not_yours` | 这本书指向的殖民地由别人管理。 |
| `folkways.charter.founder` | %s（创建者） |
| `folkways.charter.admit` | 邀请 |
| `folkways.charter.accept` | 接受 |
| `folkways.charter.decline` | 拒绝 |
| `folkways.charter.leave` | 退出殖民地 |
| `folkways.charter.dismiss` | 移出 |
| `folkways.charter.hand_over` | 转让创建者 |
| `folkways.charter.entrust` | 交由 FTB 队伍管理 |
| `folkways.member.toggle` | 纳入 / 移出 |
| `folkways.metrics.raze` | 删除殖民地 |
| `folkways.refusal.charter.founder_only` | 只有殖民地的创建者能这样做 |

**工种（劳动）与技能**（15）
| key | 中文 |
| --- | --- |
| `folkways.vocation.folkways.building` | 建造 |
| `folkways.vocation.folkways.hauling` | 搬运 |
| `folkways.vocation.folkways.crafting` | 制作 |
| `folkways.vocation.folkways.dispatching` | 调度 |
| `folkways.vocation.folkways.conducting` | 驾驶 |
| `folkways.vocation.folkways.farming` | 农业 |
| `folkways.vocation.folkways.fishing` | 捕鱼 |
| `folkways.vocation.folkways.herding` | 放牧 |
| `folkways.vocation.folkways.patrolling` | 巡逻 |
| `folkways.tab.residents` | 居民分工 |
| `folkways.ui.residents.doing` | 当前工作 |
| `folkways.resident.unassigned` | 待派 |
| `folkways.perk.farming_replant` | 补种 |
| `folkways.perk.herding_butcher` | 屠宰 |
| `folkways.perk.ranked` | %s %s（如「迅捷 3」） |

**正在做的事（doing）与冲动（urge）**（26）
| key | 中文 |
| --- | --- |
| `folkways.doing.folkways.working` | 干活 |
| `folkways.doing.folkways.walking` | 走去干活 |
| `folkways.doing.folkways.idle` | 空闲 |
| `folkways.doing.folkways.tilling` | 翻土 |
| `folkways.doing.folkways.planting` | 播种 |
| `folkways.doing.folkways.harvesting` | 收割 |
| `folkways.doing.folkways.weeding` | 除草 |
| `folkways.doing.folkways.felling` | 伐木 |
| `folkways.doing.folkways.clearing` | 清除 |
| `folkways.doing.folkways.filling` | 填充 |
| `folkways.doing.folkways.loading` | 装料 |
| `folkways.doing.folkways.fueling` | 添加燃料 |
| `folkways.doing.folkways.unloading` | 取出成品 |
| `folkways.doing.folkways.fetching` | 取货 |
| `folkways.doing.folkways.picking_up` | 捡拾 |
| `folkways.doing.folkways.tidying` | 收拾散落物品 |
| `folkways.doing.folkways.feeding` | 喂养牲畜 |
| `folkways.doing.folkways.culling` | 宰杀牲畜 |
| `folkways.doing.folkways.gleaning` | 收集牲畜产物 |
| `folkways.doing.folkways.patrolling` | 巡逻 |
| `folkways.doing.folkways.keeping_post` | 值守 |
| `folkways.doing.folkways.fleeing` | 逃跑 |
| `folkways.doing.folkways.mending` | 修理傀儡 |
| `folkways.doing.folkways.packing` | 打包包裹 |
| `folkways.doing.now` | 正在%s |
| `folkways.urge.folkways.engage` | 迎敌 |

**区块类型与书的手势**（9）
| key | 中文 |
| --- | --- |
| `folkways.delegation.folkways.farm` | 农田 |
| `folkways.delegation.folkways.fish` | 渔场 |
| `folkways.delegation.folkways.ground` | 整地 |
| `folkways.delegation.folkways.pasture` | 牧场 |
| `folkways.delegation.folkways.patrol` | 巡逻路线 |
| `folkways.draft` | 样式 |
| `folkways.book.gesture.point` | 书：点选 |
| `folkways.book.gesture.box` | 书：圈地 |
| `folkways.book.gesture.line` | 书：画线 |

**区域设置项**（11）
| key | 中文 |
| --- | --- |
| `folkways.settings.crop` | 作物 |
| `folkways.settings.farm.clear_grass` | 清理草 |
| `folkways.settings.pasture.animal` | 牲畜 |
| `folkways.settings.pasture.target` | 目标头数 |
| `folkways.settings.pasture.shear` | 剪羊毛 |
| `folkways.settings.ground.clear` | 清理 |
| `folkways.settings.ground.fill` | 填充 |
| `folkways.settings.ground.weed` | 除草 |
| `folkways.settings.ground.fell` | 砍树 |
| `folkways.settings.fill_block` | 填充方块 |
| `folkways.settings.fuel` | 燃料 |

**订单、物资与库存**（11）
| key | 中文 |
| --- | --- |
| `folkways.panel.orders.draft` | 订单草稿 |
| `folkways.orders.maintain` | 维持：常备订单，少于下限就补到上限 |
| `folkways.orders.deliver` | 送来：单次订单，补到上限就结束 |
| `folkways.panel.orders.standing` | 常备 · 少于 %2$s 就补到 %3$s · 现有 %1$s |
| `folkways.panel.orders.coming` |  · 在途 %s |
| `folkways.panel.orders.admits` | 收纳 |
| `folkways.orders.admit_only` | 只收草稿物品 |
| `folkways.panel.orders.slots` | 殖民地可用槽位 |
| `folkways.tab.metrics` | 库存 |
| `folkways.card.made` | 过去一天产出 |
| `folkways.page.wares` | 工坊 |

**建造、样式与蓝图**（14）
| key | 中文 |
| --- | --- |
| `folkways.page.build` | 建造 |
| `folkways.page.build.orders` | 建造订单 |
| `folkways.page.build.progress` | %s / %s 格 |
| `folkways.card.build.needs` | 还需要 |
| `folkways.draft.confirm` | 开工 |
| `folkways.draft.raise` | 直接建成 |
| `folkways.blueprint.handoff` | 交给殖民地建造 |
| `folkways.tab.blueprints` | 蓝图 |
| `folkways.pattern.folkways.road` | 道路 |
| `folkways.pattern.folkways.railway` | 铁路 |
| `folkways.pattern.folkways.arch_bridge` | 拱桥 |
| `folkways.pattern.folkways.city_wall` | 城墙 |
| `folkways.pattern.folkways.mine` | 矿井 |
| `folkways.pattern.folkways.terraced_field` | 梯田 |

**铁路与调度**（12）
| key | 中文 |
| --- | --- |
| `folkways.page.rail` | 铁路 |
| `folkways.page.rail.driverless` | %s · 缺少列车长 |
| `folkways.page.rail.taken` | 已接管 |
| `folkways.rail.taken_on` | 殖民地已接管这列列车 |
| `folkways.train_map.driver` | 列车长：%s |
| `folkways.train_map.riders` | 乘客：%s/%s |
| `folkways.page.dispatch` | 调度 |
| `folkways.page.dispatch.networks` | 物流网络 |
| `folkways.page.dispatch.ports` | 取货点 |
| `folkways.dispatch.taken_on` | 殖民地已接管这个物流网络 |
| `folkways.page.dispatch.manned` | 仓库管理员在岗 · 库存 %s |
| `folkways.dispatch.flaw.no_packager` | 网络上没有打包机 |

**居民、起居与模型池**（13）
| key | 中文 |
| --- | --- |
| `entity.folkways.resident` | 居民 |
| `folkways.page.person` | 人类居民 |
| `folkways.page.person.joining` | 入住 |
| `folkways.page.living` | 起居 |
| `folkways.page.living.free` | 空闲床位 |
| `folkways.settlers.admit` | 接纳一人 |
| `folkways.settlers.waiting` | %s / %s 人等待加入 |
| `folkways.settler.need.bed` | 空闲床位 |
| `folkways.settler.need.food` | 存粮 |
| `folkways.tab.looks` | 模型池 |
| `folkways.tab.names` | 姓名池 |
| `folkways.pool.names.given` | 名 |
| `folkways.resident.look` | 模型 |

**界面、操作与权限**（8）
| key | 中文 |
| --- | --- |
| `folkways.ui.nav.colony` | 殖民地管理 |
| `folkways.ui.nav.production` | 生产与设施 |
| `folkways.tab.lessons` | 教程 |
| `folkways.keys.open` | 打开书 |
| `folkways.keys.overhead` | 俯瞰 |
| `folkways.keys.rank` | 优先级 1–4 |
| `folkways.selector.title` | 选择物品 |
| `folkways.settings.reset_layout` | 重置布局 |

**代表性别拒绝（refusal）**（14）
| key | 中文 |
| --- | --- |
| `folkways.refusal.labor.no_way_there` | 无法到达 |
| `folkways.refusal.labor.no_one_fit` | 没有居民能做这项工作 |
| `folkways.refusal.labor.goods_gone` | 携带的物品不见了 |
| `folkways.refusal.haul.pack_full` | 背包已满 |
| `folkways.refusal.build.no_stance` | 这一格旁边没有可以站立的位置 |
| `folkways.refusal.build.access_dependency` | 为保留施工通道，需等待其他部分完工 |
| `folkways.refusal.draft.nothing_drawn` | 建筑样式在这里没有生成任何东西 |
| `folkways.refusal.farm.ground_taken` | 这块地已经有人在打理 |
| `folkways.refusal.fishing.line_already_out` | 这里已经有人在钓鱼 |
| `folkways.refusal.wares.station_busy` | 这个工作站已经有人在用 |
| `folkways.refusal.dispatch.no_supply` | 物流网络的库存已不足以满足这次请求 |
| `folkways.refusal.rail.seat_taken` | 那个驾驶台已经有人了 |
| `folkways.refusal.immigration.nobody_waiting` | 还没有人等待加入 |
| `folkways.refusal.sable_step_gone` | 动态结构与岸边的连接已断开。 |

---

## 5. 可作为「新插件样板」的插件排名

| 排名 | 插件 | 注册面 | 数据驱动 | UI/网络/BE | 照抄理由 |
| --- | --- | --- | --- | --- | --- |
| 1 | `fishing` | `Declaring.vocation` + `Declaring.colony` + `Registering.enrollment/facing` | 低 | 无 / 无 / 无 | 8 文件 445 行，完整走通 `VocationSpec→Presence(Facing)→Shape.Volume+工具需求→Node`；一处 `tick`、一处 `closed`。**先照它跑通骨架。** |
| 2 | `farming` | 同上 + `Schema.Choice/Flag` + `Workload.Haste` | 中 | 无 / 无 / 无 | 与 fishing 同构但多出「设置项 + perk + 区域循环作业」，是「有设置、有循环」的标准样板（`FarmingContent` 109 行即可读完）。 |
| 3 | `groundwork` | `Declaring.colony` + `Registering.enrollment/facing`（**不注册新工种**） | 低 | 无 / 无 / 无 | 想加「一个区域干多种活、干活的人借用已有工种」时最省事：`Schema` 一堆 Flag + `Survey` 每 sweep 生成 `Chores` + 4 种 Node。 |
| 4 | `orders` | `Declaring.colony` + `Registering.enrollment` + `PageKind.boarded` | 中 | **只有面板页** / 无 / 无 | 「区域 + 自有面板页 + NBT 持久化 + 向规划器提交 `Grown` 目标」的最小样板；`OrdersPresence` 展示 Board 行/按钮动作写法。 |
| 5 | `wares` | 再 + `WaresBlockEntities.register`（方块实体）+ `declaring.refinement` | 中 | 页面 / 无 / **有 BE** | 需要「附着在原版方块上的标记 BE + 生产配方 + 把一件成品展开成多步 refine」时照它抄；`WorkSiteBlocks` 展示如何不注册新方块而借用原版方块。 |
| 6 | `pasture` | 同 farming | 低 | 无 / 无 / 无 | 与 farming 并列的第二份「圈地 + 设置 + 5 种 Node」样例，额外演示实体（动物）作为工作对象与「围栏连通性判定」。 |
| 7 | `patrol` | 同 farming + `NeoForge.EVENT_BUS.register` | 低 | 无 / 无 / 无 | 想监听原版/NeoForge 事件（这里是刷怪抑制）时的最小样板：`Shape.Path` + 事件监听 + 2 种 Node。 |
| 8 | `person` | 再 + `DeferredRegister` 实体 + 数据包注册表 + `RegisteringUi` inlay/outline | 高 | 大量页面+网络 / 有 / 无 | 只有要做「新居民种类 / 新资源池（模型、姓名）」时才抄；是 `ResidentKind`+`Admission`+`Participations` 的权威示例，但体量大（6984 行）。 |
| 9 | `build` | 再 + `Shelves.register` + 自定义网络包 + `RegisteringUi.page` | 极高 | 大量页面+分片网络 / 有 / 无 | 只建议抄其中三样：`Shelves` 书架注册、`Patterns.reload` 的 ResourceManagerReloadListener 用法、`.star` 引擎契约；其余（15003 行）不建议整体模仿。 |
| 10 | `rail` | 再 + `Declaring.passage` + `Keepouts.install` + 4 个 mixin | 低 | 页面+网络 / 有（Create mixin）/ 无 | 要做「新通行方式/载具」时抄 `Passage`+`Conveyance`；mixin 与 Create 版本耦合是风险点。 |
| 11 | `dispatch` | 再 + `Refinement`/`Workshop` 深化 | 低 | 页面 / 无 / 无 | `Counter`+`Refinement.Change`（把「要货」展开成多节点 + `Before` 顺序 + `Hold` 占位）是进阶规划样板，务必先读完 `core/engine/plan` 再仿。 |
| 12 | `sable` | 仅 `Declaring.passage` | 低 | 无 / 无 / 无 | 2 文件 176 行，是「接入第三方载具/结构 mod」的最小样板；但它没在 `mods.toml` 声明依赖，说明可选集成只在代码里探测。 |
| 13 | `golem` | `Declaring.residentKind` + `Registering.admission` | 低 | 无 / 无 / 无 | 要把第三方实体变成居民时照抄 `GolemKinds`（ResidentKind + Participation 表 + barehanded）+ `GolemAdmission`（主人校验）。 |

**选型结论**：整合包自研插件以 `fishing`（骨架）→ `orders`（页面+持久化）→ `wares`（BE+配方）这条线递进照抄；`build` 只复用 `Shelves`/`Patterns` 机制而不复制其规模；`rail`/`dispatch` 因与 Create 深度耦合（mixin、`ScheduleRuntime`、链网 API），建议在 Create 版本锁定后再动。