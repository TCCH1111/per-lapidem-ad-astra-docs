# 01 · Folkways 核心引擎能力清单

范围：`reference/folkways-67f28b0`（NeoForge 21.1.233 / MC 1.21.1 / Java 21 / MIT）的 `core/**`（API 124 文件 + engine 128 文件，261 个 java 文件）。
引用约定：路径相对 `mods/core/src/main/java/io/github/izakyl/folkways/`（core 子项目；其它子项目写全 `mods/<子项目>/…`），形如 `core/engine/plan/Planner.java:43`。只读阅读，未改动被审仓库。
边界：`front/**`（191 文件，界面/命令/渲染）与 `plugins/**`（386 文件，内置内容如 farming/pasture/dispatch/groundwork）不在本报告正文，仅在作为“API 参考实现”时点名。

---

## 1. 总体架构与数据流

### 1.1 分层
- **API 层**（`core/api/**`）：全部为接口 / record / 静态注册表，是第三方唯一可依赖的面。注册表集中在 `base/Ledger.java`，服务定位缝集中在各 `*.install()`（`Colonies`、`Books`、`Grounds`、`WorldSpaces`、`MobControls`、`KitRules`、`Searches`、`Keepouts`、`Structures`、`PackKeeps`）。
- **引擎层**（`core/engine/**`）：实现上述接口并把它们缝起来。大量协作类是**包私有**（`Weaver`、`Tours`、`BodyRunner`、`ColonyLabor`、`Pipeline`、`Waypoints`、`Roaming`、`Quest`），不是扩展点。
- **内容层**（`plugins/**`）：内置玩法，用与第三方相同的 API 写就，是最可靠的用法样例。
- 分层数据流一句话：`Urge/Intent → Refinement 展开 → 计划图(Node+Before) → 开边生长出供应源 → Transfer/Carrying 铺搬运 → Scheduler 排路线(Tour) → BodyRunner 执行 → Node.commit 改世界 → 事件/XP/结算回归计划`。

### 1.2 需求 → 计划（第一段：weave）
- **欲望来源**：`core/api/work/UrgeSource.java` 的 `urges(Colony, Worker, ColonyView)`；内置由 `Contributions.urges(owner, source)` 挂到殖民地（`core/api/Declaring.java:30`）。`Urge` 权重 `IDLE .05 / SPARE .5 / NOW 1.0 / DIRE 2.0`，`preempts()` 决定能否抢占手上的活。
- **欲望取活**：`ColonyLabor.interrupt`（`core/engine/labor/ColonyLabor.java:299`）逐 tick 对每个 body 取最keenest的 urge（`core/engine/labor/Urges.java:38`），`urge.take().get()` 直接给出一个 `Node`（个人事务，走 `Phases personal` 独立通道），与殖民地的计划通道分开结算。
- **殖民地级活**：owner 通过 `Colony.submit(owner, dimension, Grown, BiConsumer<UUID,Ending>)` 提交（`core/api/colony/Colony.java:47`）；`Asking` 把“想要的 Grown”与“已提交的 live 集合”做 diff，自动补提交/撤单，并可重复提交已结束的节点（`core/api/colony/Asking.java:39`）。`Sweep` 用 `Cadence.Cron` 定周期驱动 `Asking.offer`（`core/api/colony/Sweep.java:29`）。
- **图的结构**：`Grown(List<Node> nodes, List<Before> links, List<Set<UUID>> workerGroups, List<Before> follows)`（`core/api/work/Grown.java:14`），构造时做拓扑排序，有环即抛 `IllegalArgumentException`（`Grown.java:82`）。`links` 只表达顺序，`workerGroups` 表达“必须同一人做”，`follows` 表达跨提交片段的顺序。
- **展开**：`core/engine/plan/Refining.java` 反复用 `Refinement.rewrite (Intent, Grown, Context)` 把每个 `Intent` 替换成真实工作，保持边界 id（`Refining.java:80-124`），硬上限 `LIMIT = 256` 步，超限抛异常（`Refining.java:24,73`）。
- **开边 → 源**：`core/engine/plan/Edge.java` 把一个 `Need` 变成一条“还没有供方”的边（`Edge.into`，`Edge.java:30`）；`Weaver` 按 `Costs` 由廉到贵生长源：库存（store）、工坊 `Produce` 报价、pack 内已有物。`WeaveDelta` 是引擎对外（对 labor 层）唯一的计划差量（`core/engine/plan/WeaveDelta.java:18`）。
- **搬运**：`core/engine/plan/haul/Carry.java` 是内核唯一的 `Carrying` 规则（`Haul.CARRYING`，`core/engine/plan/haul/Haul.java:41`）：生料够近就直接用、在做事的人包里就直接用、厂里刚产出就直接传，否则拆成 take（进包）+ put（出包）的 `TransferNode`（`core/engine/plan/haul/TransferNode.java:52`）。
- 收敛约束：每个 weave 轮次都会对开边设“收敛地板”，并对相似路径做“同价四分之一内即替换”的合并（`core/engine/plan/Weaver.java`，`OWNER = folkways:supply`）。计划本体是 `WeaveView`（全量）/`WeaveDelta`（差量），weave 线程只读快照。

### 1.3 计划 → 路线（第二段：schedule）
- `Planner.handle(Known, List<Message>, long tick, Map<UUID,Tour>) → Woven(delta, crew, ways, retry, shortfalls, refused, asks, timing, nodes)`（`core/engine/plan/Planner.java:32,43`）。
- `Scheduler.handle(List<Input>) → Scheduled(changed, unassigned, hands, wakeAt, all, timing, tick)`（`core/engine/plan/Scheduler.java:48,52`），`Input.wake(tick)` 表示“只为时间而醒”，不带世界变化（`Scheduler.java:38`）。
- 排线在 `core/engine/plan/Tours.java`：把节点放到 `Crew.Hand`（resident）的路线上，受 `planHorizonTicks`（默认 3000）与 `planHorizonDepth`（默认 8）裁剪；`Tour = (resident, List<UUID> nodes)`。硬上限：`MOST_TRIES = 4096`、`LONGEST_RUN = 3`、`SAVING = 0.5` 刻、`TIER_TICKS = 400`、`RIDE_SPEEDUP = 4`、`MOST_INSERTS = 16`、`MOST_JOINS = 4`、`MOST_TAIL = 16`、`MOST_SHEDS = 64`、`HOP_TICKS = 100`（`core/engine/plan/Tours.java:40-64`）——计数驱动而非计时，保证同世界可复现。
- 分派约束依次为：licence/vocation（`Fitness.Unfit.NO_LICENCE`）、工具、站脚（`Stands`）、pack 容量（`PackSizing`）、`Claims` 资源占用、`workerGroups` 同人、`Cooldowns` 失败退避。失败/未派工原因枚举见 `core/engine/plan/Unassigned.java:10-44`。
- `Crew.Hand(who, at, packCells, packCapacity, pace, licences, tools, holding, cargo)`（`core/engine/plan/Crew.java:19`）是计划所知的“手”；`pace` 取自 `Attributes.MOVEMENT_SPEED / baseValue`（`core/engine/labor/Survey.java:354`）。

### 1.4 劳动执行 → 世界改变（第三段）
- 每 (colony, dimension) 一个 `ColonyLabor`，每 tick `run(level, lanes)`（`core/engine/labor/ColonyLabor.java:174`）：先 `pipeline.applyReady` 应用后台产出，再结算 `phases.settling()`，再对每个在场 body `interrupt` + `runner.tick`，然后最多 `MOST_ROUNDS = 2` 轮 `plan()`，最后按 `scheduleWakeAt` 唤醒排线。
- `BodyRunner` 状态机（`core/engine/labor/BodyRunner.java:200`）：取路线节点 → 走到位（`Trip`）→ `windUp` → `Commit.run` → 结算。常量：`STALL_POLL_TICKS = 4`、`WAIT_POLL_TICKS = 10`、`BEAT_TICKS = 10`（工作期间每 10 刻朝仓库或工件转一次）、`AWAY_TICKS = 100`。
- **提交语义**：`Commit.run(level, node, who)`（`core/engine/labor/Commit.java:31`）把 `Placement.Draw` 指定的货物从指定位置取出、交给 `Node.commit(level, Worker.Supplied)`，`Outcome.Done.unused()` 归还、`Outcome.Failed` 全量回滚；`Staged` 走两阶段 `draw/restore`（`core/engine/plan/Staged.java`）。节点抛异常会被捕获记日志并按 `LaborRefusal.WORK_BROKE` 失败（`core/engine/labor/Phases.java:74`）。
- **节点生命周期**：`Phases`（`core/engine/labor/Phases.java:18`）持有 `NodeState PENDING/READY/WORKING/SETTLING/DONE/FAILED/CANCELLED`，`ready/refusal/settled` 是对 API 的调用点；`Ending`/`Outcome`/`Recourse`/`Unmet`/`Balk` 决定失败是重试、等待还是放弃（`Balk.FRESH_TICKS = 200`）。
- **世界改变只发生在服务端线程**：`Pipeline.applyReady(ServerLevel)` 按产出顺序在服务端 tick 上执行（`core/engine/labor/Pipeline.java:168`）；计划线程只产出 `Runnable` 与 `WeaveDelta`。
- **可观测副作用**：`core/api/work/WorkProgress.java`（STARTED/FINISHED/RELEASED/FAILED）、`WorkYield`、`WorkExertion` 走 NeoForge `EVENT_BUS`；`WorkExertion` + `Wear.from` 磨损工具（`core/engine/labor/Wear.java:21`），`Xp`/`BodyPerks` 记经验（`XP_STEP = 32`）。

### 1.5 时钟与节拍（sim clock）
- 总入口 `Labor.onServerTick(ServerTickEvent.Post)`（`core/engine/labor/Labor.java:60`）：tickrate 非正常即返回；`GameTestServer` 跳过 `work()`；`pulse()` 每 tick 调用 `ColonyData.works().pulse(server)`。
- 每 tick：对每个 level × 每个 colony 建 `Site`，`ColonyWays.advance` 推进行走图，`ColonyLabor.run` 干活。空殖民地（`holdings().bodiesIn(level).isEmpty()`）且已有 site 时仍继续跑，直到空置 `DESERTED_TICKS = 1200` 刻才关闭并 `ColonyWays.forget`（`ColonyLabor.java:59`、`Labor.java:97`）。
- 心跳：`BEAT_TICKS = 20` × `heartbeatCycles`（默认 10）= 每 200 刻做 `colony.reconcile(server)`、`warnOnStuckSolves()`、`PathfindingLoad.drainHeartbeat()`、`TravelBudget.drainHeartbeat()`，并按 `logPlanHeartbeat`（默认 true）逐 colony 打一行 labor heartbeat（`Labor.java:115-139`）。
- 计划唤醒：`Asks.wakeAt`（weave 请求）/`Scheduled.wakeAt`（schedule 请求）驱动“无事也醒来重算”的节拍；`WAYS_ANSWER_TICKS = 20` 保证 ways 回答后最多 1 秒内重算（`ColonyLabor.java:63,250`）。
- 周期任务统一走 `Cadence.Cron`：只声明周期，tick 相位由 `phaseFor` 用 lcm/gcd 选“与其他 cron 相遇最少”的那一格（`core/api/colony/Cadence.java:82`），可 `claim(colony, period, count)` 批量占位。
- 线程模型：`EngineMode.begin() == FolkwaysConfig.Mode.DEFAULT` 时每个 colony 两条 lane（weave、schedule）跑在 `Solves` 的固定线程池（线程名 `folkways-solve-N`），否则 `Lanes.INLINE` 全部在服务端 tick 上串行（`Labor.java:156-167`、`core/engine/labor/Solves.java:36`）。

### 1.6 出行 / 寻路图的组织
- 接口：`core/engine/travel/Ways.java`（`journey / anyoneReaches / reckon`），`Faring = Yes(Journey) | Later | No`；`Journey(walkTicks, rideTicks, List<Leg>)`，`Leg(hop, to, from, passing)`，`Hop` 来自 `Passage`（`core/api/passage/**`）。`Urgency` 分 `WALKING/PLANNING/CHECKING/BACKGROUND` 四档 + rank，用于调度优先级（`core/engine/travel/Urgency.java:7`）。
- **per (server, dimension, colony)**：`ColonyWays` 维护 `Roaming` + `WayGraph` 快照；`WayGraph` 是查询面（`journey/anyoneReaches/reckon`，`core/engine/travel/graph/WayGraph.java:35`），由 weave/schedule 线程读取，`UNBUILT` 为哨兵。
- **路点网**：`Waypoints`（`core/engine/travel/graph/Waypoints.java:34`）以 `SPACING = 12` / `SNAP = 2` 抽样成图，`FEWEST_POINTS = 512`、`MOST_POINTS_EVER = 65536`、每点至多 `ATTACHED_PER_POINT = 4` 条附着；链接有 `PROBATION_TICKS = 600` 试用期与 `MOST_STRIKES = 5` 判死。
- **自生长**：`Roaming`（`core/engine/travel/graph/Roaming.java:42`）每 `RAMBLE_EVERY = 20` 刻做至多 `MOST_RAMBLES = 2` 次 ramble、`BRIDGE_EVERY = 20` 刻做至多 `MOST_BRIDGES = 2` 次跨岛桥接，失败按 `RAMBLED_TICKS = 2400` 指数退避（`MOST_BRIDGE_BACKOFFS = 4`）；有预算时每 `FREEZE_EVERY = 20` 刻冻结一份给计划线程。回答缓存 TTL：`WALKING_TTL = 60`、`PLANNING_TTL = 1200`、`BACKGROUND_TTL = 600`。
- **局部地面**：`Grounds.Source` 实现 `LocalGrounds`（`core/engine/travel/local/LocalGrounds.java:12`），`BlockChanges.listen` → `LocalGrounds.blockChanged` 使 `Section`（8×8×8 体素，`Section.SHIFT = 3`，读取外扩 `READ_ACROSS = 2 / BELOW = 5 / ABOVE = 4`）失效；节段由 `core/engine/travel/local/Survey.java:26` 用 `Locomotion.newEvaluator` 逐格问 `PathType` 生成 stands+steps。
- **搜索**：A* 用 MC 原生 `NodeEvaluator`（`Sweep.from`，半径 `RANGE = 64`、`MOST_VISITED = 1024`、`MARGIN = 8`）；图内寻路 `Quest` 上限 `MOST_STEPS = 96`；把孤点接网 `Attach` 上限 `MOST_VISITED = 512`；`WayGraph.NEAR = 128` 内直接问路，`MOST_DOORS_TRIED = 8`。计数全部汇入 `PathfindingLoad`，并经 `Searches.install(Searches.Meter)` 让第三方 gait 的搜索也被计入（`core/engine/travel/PathfindingLoad.java:115`）。
- **预算**：`TravelBudget` 用 AIMD 控制每 tick 全局 way 计算时间，`travelCeilingMicros`（默认 8000）与 `travelFloorMicros`（默认 250）之间按 `BACK_OFF = 0.7` 退让、每 tick `CLIMB_NANOS = 125 000` 爬升；单线程模式直接 `untimed`（`core/engine/travel/TravelBudget.java:42`）。
- 多域：`Realm = Dimension | Frame`（Sable 子层），`WorldPos = realm + cell`，`WorldSpaces.at/resolve/storage/world/relative` 统一跨域寻址；`Closures` 只处理门（`DOOR_DROP = 4`，`MOST_DOORS = 256` 抽样），`Keepouts`/`Structures.Obstacles` → `ObstructedPathRegion` 屏蔽不可通行区。

### 1.7 存档
- `ColonyRegistry extends SavedData`，名字 `folkways_colonies`，挂在 overworld `DataStorage`（`core/engine/colony/ColonyRegistry.java:24-25,54`）。`SaveVersion.CURRENT = 1`；版本读不出/过新 → `sealed()` 只读注册表，`setDirty` 被吞（`ColonyRegistry.java:42-51`、`core/engine/colony/SaveVersion.java:9`），即“不覆盖、也不再保存”。
- 每 colony：`ColonyData.save/load` 存 `holdings` + `keeps`（`core/engine/colony/ColonyData.java:90-98`）；`Keeps` 存 owner 的任意 `CompoundTag`，并递归迁移其中的 `WorldPos`（`core/engine/colony/Keeps.java:60-63`）。
- body 侧：NeoForge attachment `folkways:body_state`（`Pack.save/load`，需要 `HolderLookup.Provider`）、`folkways:resident_capabilities`、`folkways:colony_member`（`core/api/resident/body/FolkwaysAttachments.java`）。
- 不可读的 NBT 条目按条丢弃并记日志，而不是整体失败（`base/persist/Entries.java`）。

---

## 2. 关键概念清单（每条一行：是什么 · 谁用 · 玩家可见性）

| 概念 | 说明 |
|---|---|
| **Colony** | 由 Colony Book 标记的方块集合构成的殖民地（`core/api/colony/Colony.java`）；插件所有者提交工作/商店/持有的容器；玩家可见（书/命令）。 |
| **ColonyView / ColonySnapshot** | 某维度上的殖民地只读切片（等级、持有物、方块、居民、`rankOf`）；计划与插件读世界用；不可见。 |
| **ColonyContext** | 插件注册殖民地时的上下文：`urges/tick/closed/watch/share`；插件用；不可见。 |
| **Resident / ResidentKind** | 居民身份（id+kind）与种类定义（成长方式、具身化、参与关系、是否有手）；决定 gait/裸手；玩家可见（居民面板）。 |
| **Body** | 居民在实体上的具身化（mob、pack、licences、perks、doing、balk、colonyId）；引擎用；部分可见（头顶状态）。 |
| **Pack** | 固定 `DEFAULT_SIZE = 18` 格的背包抽象（容量倍率、`plannableCells/plannableRoom`）；计划用它算搬运批量；可见（居民清单）。 |
| **Licence / Licences** | “职业授权”+ 熟练度，可 NBT 序列化并有 revision；`Kit`/`Fitness` 靠它放行工作；可见（职业面板）。 |
| **Keenness** | 熟练等级 FIRST..FOURTH，缺省 THIRD；影响 `Costs`/产出；可见。 |
| **Vocation / VocationSpec** | 职业与它的工具包（`kit()`）与专属 perk 池；注册于 `Vocations`（Ledger `TRADES`）；内置 `HAULING`；可见。 |
| **Perk / PerkPool / GlobalPerks** | `Perk(id, maxRank)`，全局与职业池；内置 `global_stoic/longarm/brisk/packmule/ascetic`；影响 `Workload.Haste`、XP；可见。 |
| **Node / NodeSpec** | 计划图上的一个工作单元与其规格（needs/gives/leaves/tools/effort/pace/vocation/gesture/focus/estimate/doing）；API 核心；不可见（有调试命令）。 |
| **Doing / Doings** | 节点对外的“正在做什么”（WALKING/WORKING/WAITING/IDLE/PICKING_UP/FETCHING/STOWING 等）；界面与动画读；可见。 |
| **Intent / Refinement / Refinements** | 抽象意图与把它展开为真实工作的规则；第三方主要扩展点；不可见。 |
| **Grown / Before / workerGroups / follows** | 一次提交的工作片段、先后关系、同人绑定、跨片段顺序；构造即验环；不可见。 |
| **Edge / Source / Transfer / Flow / Laying / Manifest** | 未满足的需求边、为它生长的供方、供需之间的搬运与流账；Weaver 内部；不可见。 |
| **Carrying / Carry / TransferNode / Receipt** | 内核的搬运规则与“取/放”节点；`Haul.DOMAIN`；不可见。 |
| **Workload / WorkEffort / Haste** | 工作量形态 `Once`（起手+原子提交）`Continuous`（持续）`Within`（工地分片交接）；与“抽象劳动单位”分离；不可见。 |
| **Weaver / Planner** | 计划图生长者与它的单轮入口（`Woven`）；引擎内部（包私有）；不可见。 |
| **Scheduler / Tours / Tour / Crew / Hand** | 路线排布者、排线算法、每个居民一条路线、计划所知的“手”；引擎内部；不可见（诊断输出间接可见）。 |
| **Unassigned / Why / Shortfall / RefusalKind / Cooldowns** | 未派工原因、无源/无位/无路/无手、缺料与无空间、失败退避；诊断与 heartbeat 用；可见（诊断）。 |
| **Claims / Claim / Resource** | 计划对具体货物/工位/容量的占用登记；防重复分配；不可见。 |
| **Phases / NodeState** | 节点在 labor 层的状态机；引擎内部；不可见。 |
| **ColonyLabor / Pipeline / Inbox / Message** | 每殖民地劳动调度、两段式后台流水线、消息队列；引擎内部；不可见。 |
| **BodyRunner / Lanes / Solves / Runners** | 单个体执行器、weave/schedule 通道、线程池、执行器表；引擎内部；不可见。 |
| **Worker / Hands / Store / ToolNeed / Placement** | 交给 `Node.commit` 的“手”：包、可达商店、手持工具、计划给的取放位置；API；不可见。 |
| **Urge / UrgeSource / Balk** | 个人欲望、欲望来源、拒绝做某事的持久标记（`FRESH_TICKS = 200`）；插件用；可见（居民状态）。 |
| **Ways / Faring / Journey / Leg / Hop / Trip / Passage / Fare / Conveyance** | 出行查询、答案、行程与分段、搭车节点、执行中的行程、交通服务与票价、实体载具接口；插件可注册 `Passage`；可见（乘坐/坐骑）。 |
| **Locomotion / Locomotions / Gait / Searches** | 移动方式（gait）、注册表、`Gait.BLOCKS_PER_TICK = 0.165` 的刻速估算、搜索计量；插件可注册；可见。 |
| **Ground / Grounds / Stands / Stances / Footing / Reach** | 局部地面读取、站位与站姿、脚感（`NEARLY_FULL = 14/16`）、可达距离（`PLAYER_BLOCK_REACH = 4.5`）；计划与执行用；不可见。 |
| **Stash / StoreRule / Containers / Stores** | 仓库地址、Reserve/Admit/Slots 规则、容器包装（双箱锚点、`PICKY` ClassValue）；玩家配规则；可见。 |
| **Realm / WorldPos / WorldSpaces** | 维度或子层（Sable Frame）中的地址与跨域解析；全引擎通用；不可见。 |
| **Closures / Keepouts / Structures** | 关门/禁区/结构障碍对寻路的影响；由方块与结构驱动；不可见。 |
| **Participation / Participations / Stake** | 某居民种类是否参与某内容（URGE/VOCATION/PASSAGE），`NONE/ALWAYS/OPTIONAL`；`Relating` 注册；不可见。 |
| **Term 族：ItemSpec / ItemQuery / ItemFilter / Goods / Leaves** | 物品规格（item/tag/anyOf 三选一）、搜索语法（`| @mod #tag * ?`）、行式过滤器、匹配与堆叠计算、未知掉落的容量预测（`Leaves.UNSEEN`）；插件与数据包用；可见（过滤器 UI）。 |
| **Ledger / Declaring / Relating** | 注册窗口与两个 mod-bus 事件；插件入口；不可见。 |
| **Cadence.Cron / Sweep / Asking** | 周期任务与相位安排、周期“问一次”、想要集合的 diff 提交；插件用；不可见。 |
| **LaborCensus / Readout / Diagnosis** | 只读统计（submitted/phases/planned/unassigned/missing/standing）与 heartbeat 一行诊断；运维/基准用；命令可见。 |
| **Library / Shelves / LooseFolder** | 数据包侧内容书架（根目录 `<game>/folkways/`，命名空间 `local`，pattern/piece/blueprint/resident_skin/resident_model），`LooseFolder` 以内置 `folkways/library` SERVER_DATA 包挂载，`/folkways library` 报告库存与拒绝原因；内容作者用；可见。 |
| **EngineMode / FolkwaysConfig** | 单线程 vs 图引擎开关与全部可调项（`serverconfig/folkways-server.toml`（上游已拆为三份 *-server.toml））；运维用；可见。 |

---

## 3. 公开 API 边界

### 3.1 第三方能做（都有方法级入口）
- **注册声明**（仅在 `Declaring` 事件窗口内，`core/api/Declaring.java`）：
  - `refinement(Refinement)` → `Refinements.register`；`urges(ResourceLocation, UrgeSource)`；`colony(ResourceLocation, Consumer<ColonyContext>)`；`vocation(VocationSpec)`；`locomotion(Locomotion)`；`residentKind(ResidentKind)`；`passage(Passage)`。
  - `Relating.participation(ResourceLocation resident, Stake content, Participation how)` / `defaultParticipation(...)`（`core/api/Relating.java:27,32`），事件回调里必须 `close()` 前的窗口。
- **提交与库存**（`Colony` 接口）：`submit(owner, dimension, Grown, BiConsumer<UUID,Ending>)`、`withdraw`、`publish(...Collection<Workshop>)`、`stores(...)`、`withhold(...)`、`rule(...Collection<StoreRule>)`、`keep(owner, CompoundTag)` / `kept(owner)`、`hold/release/holdings/holdingAt/holdingOf`、`residents()`、`service(owner, Class<T>)`。
- **观察（只读）**：`WorkProgress`/`WorkYield`/`WorkExertion`（NeoForge `EVENT_BUS`）；`ColonyLifecycle.listen(Listener)` 的 `relocating/closed`；`ColonyContext.tick/closed/watch/share`；`Holding.Watch`；`BlockChanges.listen(level, box, told)`；`Grounds.watch(level, box)`；`LaborCensus.of(level, colony)`；`Stores.revision()`。
- **安装缝（服务定位）**：`Colonies.install(Source)`、`Books.install`、`Grounds.install(Source)`、`WorldSpaces.install`、`MobControls.install`、`KitRules.install(Rule)`、`Searches.install(Meter)`、`Keepouts.install`、`Structures.install(Obstacles)`、`PackKeeps.add(Rule)`、`Shelves.register`。
- **实现自己的工作与移动**：实现 `Node`（`ready/commit/settled/refusal/ended`）+ `NodeSpec.Builder`（`needs/gives/leaves/tools/effort/pace/vocation/gesture/focus/estimate/doing`）；实现 `Locomotion`（`newEvaluator/fit/along`）与 `Passage`（`hopsIn/through/joined/aboard` + `Fare.arriveBy/boardingAt/then/flat`）；实现 `UrgeSource` 返回 `Urge`。
- **内容而非代码**：数据包经 `Shelves`（构建 pattern 用 Starlark，内置样例在 `mods/vanilla/src/main/resources/data/folkways/folkways/pattern/`）；`/folkways library`（gamemaster 权限）可查库存与拒绝。

### 3.2 第三方不能做（读代码可验证的硬边界）
- **不能改计划/排线算法**：`Weaver`、`Tours`、`Scheduler`、`BodyRunner`、`ColonyLabor`、`Pipeline`、`Waypoints`、`Roaming`、`Quest` 均是包私有 final/无插槽；所有硬上限是 `private static final`。
- **不能绕过注册窗口**：`Ledger.writing` 在窗口外抛 `IllegalStateException`（`base/Ledger.java:29`）；`sealedOnceRead` 的账本（如 `Vocations.TRADES`）一旦被读过就再也写不进（`Ledger.java:46,68-84`）。
- **不能访问别的 owner 的保留数据**：`keep/kept` 以 `ResourceLocation owner` 为键，`service(owner, type)` 同理。
- **不能在计划线程外调用非纯 API**：`Refinement.rewrite`、`Sizing.runs`、`Ways.journey/reckon`、`Passage.hopsIn` 由 weave/schedule 线程调用（`core/engine/labor/Pipeline.java:77-82`、`core/engine/labor/ColonyLabor.java:261-270`），而 `Node.ready/commit/refusal/settled/ended`、`UrgeSource.urges` 在服务端线程——这一线程契约在 API 上没有文档，混淆会在并发下出错。
- **不能加新存档后端**：只有 `Colonies.install(Source)` 一个替换点；版本门 `SaveVersion.CURRENT` 是硬编码常量。
- **不能改内核搬运规则**：`Haul.CARRYING` 是 `Carrying` 的唯一实现，`Haul.DELIVERIES` 是 `folkways:haul` 域名下的 `Refinement`（`core/engine/plan/haul/Haul.java:41,49`）。
- **没有通用插件加载器**：核心无脚本/插件发现机制；行为扩展只能编译期实现接口，内容扩展走数据包/Starlark。`FolkwaysMixinPlugin` 只对 Degradable 类做条件 mixin，并把 Create 限制在 `[6.0.0,7.0)`；核心 mixin 失败为致命 `ModLoadingIssue`。

---

## 4. 现存实现限制与缺口

按“对更丰富 / 更自由 / 更深模拟”的影响排序。核心代码里**没有字面 `TODO`**（全仓 140 处匹配基本是设计注释），限制主要以硬上限、退化路径与设计注释形式存在。

1. **计划与出行都有硬上限，且会抛异常而非降级**：`Refining.LIMIT = 256` 超限抛 `IllegalArgumentException`（`core/engine/plan/Refining.java:73`），`Grown` 建构时遇环抛异常（`core/api/work/Grown.java:82`），`Tours` 的 4096 次重排后“接受现状”。超大型据点（数千工作节点）会得到次优排线而不是分治。
2. **pack 容量是整数格子模型**：`Pack.DEFAULT_SIZE = 18`，`PackSizing` 用“最宽裕搬运工的包”做一次搬运上限（`core/engine/plan/PackSizing.java:47`），`Kit.keptCells` 明说“计划会以为包能清空、而实际腾不出位置”（`core/engine/labor/Kit.java:108`）。大宗/超重/多级物流（车队、驮兽、集装箱）无法表达。
3. **“结构性无解”被定义为 bug 而非世界状态**：`Unassigned.structural()` 把 `NO_LICENCE / NO_TOOL / PACK_FULL / SAME_WORKER_SPLIT` 视为“计划生长有 bug，不是世界的一种状态”（`core/engine/plan/Unassigned.java:7-43`）。因此“有意识地不发给某人工具/许可并期待优雅等待”在语义上不被支持。
4. **核心没有需求/心情/社交/经济层**：`core/api` 中不存在饥饿、疲劳、情绪、关系、记忆、货币等模型；个人事务全靠插件 `UrgeSource` 供给。与 DF/RimWorld/SoS 相比，“更深模拟”必须在插件侧自建，并自行承担与计划图的耦合。
5. **线程契约隐式**：`Pipeline` 文档只说明了顺序保证（`core/engine/labor/Pipeline.java:22-28`），未声明插件回调运行在哪个线程；`Refinement`/`Sizing`/`Ways`/`Passage` 会被后台线程调用，而 `Node.commit` 等在前台。API 无 `@ThreadSafe` 之类的约束声明。
6. **出行预算全局共享且默认仅 8 ms/tick**：`TravelBudget` 的 AIMD 上限 `travelCeilingMicros = 8000`、地板 250（`core/engine/travel/TravelBudget.java:34-51`，`FolkwaysConfig.java:96,103`），多殖民地共用；单线程模式完全不计时（`TravelBudget.java:43`），意味着两种模式的性能与行为不可比。
7. **人体尺度假设写死**：`Gait.BLOCKS_PER_TICK = 0.165`、`Reach.PLAYER_BLOCK_REACH = 4.5`、`Reach.EYE_HEIGHT = 1.62`、`Footing.NEARLY_FULL = 14/16`、`Section` 的 8³ 采样（外扩 2/5/4）、`Sweep.RANGE = 64`、`Closures.MOST_DOORS = 256`、`DOOR_DROP = 4`。非人形/大型/飞行单位必须自带 `Locomotion` 才能在寻路上不被沿用“类人”判断；`Walker.of` 对未知种类直接退化为 `WALKING`（`core/engine/travel/local/Walker.java:18`）。
8. **存档版本门是“静默只读”**：读到不可解析或更高版本时 `sealed()`，从此不再 `setDirty`（`core/engine/colony/ColonyRegistry.java:42-51`、`SaveVersion.java:27`），玩家会看到殖民地不回写而没有任何错误提示，除非看 `folkways-persist` 日志。
9. **失败会变“粘”**：`Urges.BACKOFF = 100` 刻、`Cooldowns.FIRST_WAIT = 20`→`LONGEST_WAIT = 640`（`core/engine/labor/Urges.java:23`、`core/engine/plan/Cooldowns.java:11-13`）；一次失败后的工作要很久才重试，短周期上下文（如昼夜）容易被错过；计划卡住只打 `solving for Ns` 警告（`core/engine/labor/Labor.java:141`）。
10. **内置内容自带已知缺口（可作为“待补深”的信号）**：`mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/farming/Crop.java:183`（竹子按不可走的秆处理）、`mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/farming/Habit.java:198`（叶/树归属）、`mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/pasture/ShearNode.java:24`（羊最多 3 份羊毛）、`core/api/terms/Containers.java:129-142`（`canPlaceItemThroughFace` 的单面判定）、`mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/FolkwaysVanillaConfig.java:101-102`（ghost block 绘制的代价）、`mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/FolkwaysVanillaConfig.java:155-159`（`pathSearchBudget` 只放大节点扩展预算，路径长度上限另有其量）。
11. **计划与执行的边界收得很窄**：`Workload.Once` 的原子提交（`windup` 后一次性改世界）使“中途被打断/被抢占”基本等于回滚重来；`Within` 分片交接是唯一的细粒度协作形态（`core/engine/labor/BodyRunner.java:315,561`）。多人协作、工具共享、施工中的半成品语义有限。
12. **面积/数量类可调项只覆盖内置内容**：`maxFarmCells/maxPastureCells/maxGroundworkCells/maxBuildCells/maxBlueprintVolume` 等是 `plugins` 侧音量阀（`mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/FolkwaysVanillaConfig.java:67-113`），不是引擎级公平调度；引擎本身没有“每 tick 可做多少活”的配额（只有 way/搜索预算）。

---

## 5. 对模组包 / 插件工作的可执行结论（每条可验证）

1. **把计划图当唯一集成面**：新玩法实现 `Node`+`NodeSpec` 并由 `Colony.submit` 提交 `Grown`，用 `Refinement` 展开自定义 `Intent`；验证方式：`LaborCensus.of(level, colony)` 的 `submitted/phases/planned/unassigned` 应随之变化（`core/engine/labor/LaborCensus.java:20`）。
2. **需求/心情/社交层自建在插件侧**：用 `Declaring.urges(owner, UrgeSource)` + `Relating.participation(...)` 决定谁参与；核心无此类状态，不要期待引擎提供饥饿/情绪/关系（`core/api/Declaring.java:30`、`core/api/Relating.java:27`）。
3. **把上限当设计约束而非待修 bug**：假设每殖民地可承受的计划规模受 `Refining.LIMIT=256`、`Tours` 4096 次重排、`Waypoints.MOST_POINTS_EVER=65536` 约束；大地图按“多殖民地分区”设计，验证方式：开启 `logPlanHeartbeat=true`，观察 heartbeat 中 `unassigned`/`shortfall` 与 `budget=` 行是否稳定。
4. **对后台线程保持纯函数**：`Refinement.rewrite/expand`、`Sizing.runs`、`Ways.journey`、`Passage.hopsIn` 不得访问 level/实体，只吃快照（`Known`/`Situation`/`Crew`）；验证方式：将 `solveThreads` 设为 1 与 N 分别跑同一场景，结果应一致。
5. **物流按“包格”设计物品**：单次搬运批量受最宽裕搬运工包容量限制（默认 18 格），大批量配方应拆成多次 `Delivery`（`Haul.DELIVERIES` 自动按包切分，`core/engine/plan/haul/Haul.java:49`）；验证方式：给配方需求 > 一包输入，观察是否拆成多个 `TransferNode` 而不是永久 `LONGEST_WAIT` 式停滞。
6. **只在 `FolkwaysConfig` 允许的旋钮上做性能调优**：`planHorizonTicks/planHorizonDepth`、`travelCeilingMicros/travelFloorMicros`、`haulReachTicks`、`dispatchReachTicks`、`seatTicks`、`solveThreads`、`heartbeatCycles`（`FolkwaysConfig.java:72-115`、`mods/create/src/main/java/io/github/izakyl/folkways/create/FolkwaysCreateConfig.java:41,46`、`mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/FolkwaysVanillaConfig.java:159`（上游已拆为三份配置））；不要试图通过插件改 `Tours`/`Roaming` 的上限。
7. **存档兼容从第一天抓**：任何自定义持久状态走 `Colony.keep(owner, CompoundTag)`（含 `WorldPos` 时注意 `Keeps` 迁移）或 body attachment；当需要超过 `SaveVersion.CURRENT = 1` 的格式时，先准备好迁移，否则注册表会静默进入只读（`core/engine/colony/ColonyRegistry.java:42`）。
8. **注册只在 declared 窗口**：所有注册从 `Declaring`/`Relating` 进入，禁止运行时注册（`Ledger.writing` 抛异常）；数据包内容放 `<game>/folkways/` 并用 `/folkways library` 自检拒绝原因（`library/LibraryCommand.java`）。
9. **移动能力要显式声明**：非类人单位必须提供自己的 `Locomotion`（gait/尺寸/`newEvaluator`），否则会被 `Walker.of` 当成行走的人形处理，站脚与容量判断失真（`core/engine/travel/local/Walker.java:18`）。
10. **把“深/自由”指标量化后再扩**：以 `LaborCensus`（`standing` 中 idle/stalled 比例、`missing` 缺料、`unassigned` 理由分布）与 heartbeat 的 `budget=`、`solving for Ns` 警告为基准线；任何声称“更深模拟”的插件都应证明这些指标不退化（`core/engine/labor/Readout.java`、`core/engine/travel/PathfindingLoad.java`）。