# 差距分析：基底能给我们什么、我们必须自己造什么

```
状态：草稿（依赖 r01/r02 已完成；r03/r04 到位后需回填）
负责人：设计
最后更新：2026-10-17
事实来源：docs/research/01-core-engine.md、02-plugin-inventory.md、05-engineering-and-tooling.md
```

> 结论先行：**基底解决了「一个殖民地能自己运转」的全部难题**（规划器、劳动执行、物流、区块意图、图案建造、数据包内容）。
> **它完全没有做「人」与「世界」**：没有需求、情绪、关系、记忆、事件、威胁、时代、贸易、心情、传说。
> 这恰好与本项目的支柱（P2 人味 / P3 世界压力 / P4 进程）**互补而不重叠**。

---

## 1. 基底已提供（可直接复用，不要重做）

| 能力 | 事实依据 | 对我们的价值 |
| --- | --- | --- |
| 计划图引擎（Intent → Refinement → Node → Carry → Tour → BodyRunner） | r01 §1.2–1.4 | 一切新玩法的执行后端 |
| 提交与改世界的唯一通路 `Colony.submit(Grown)` + `Node.commit` | r01 §3.1 | 新工作类型的标准接入点 |
| 职业与授权（Vocation / Licence / Keenness / Perk） | r01 §2 | 新职业（民兵、学者、医师）的挂载点 |
| 欲望驱动（Urge / UrgeSource / Balk） | r01 §2、r02 §0 | **需求系统的接入点** |
| 区块意图（Enrollment / Delegation / Shape.POINT/BOX/LINE / Schema.Setting） | r02 §0 | **新玩法「画一块地/一条线」即可立项**，无需新 UI 框架 |
| 面板框架（RegisteringUi.page / Board.Row / Board.Act / PageKind） | r02 §0 | **新系统的 UI 页有官方扩展点** |
| 数据包书架（pattern / piece / blueprint / resident_model / resident_skin + 注册表 resident_look/name） | r02 §0 | 内容扩展（图案/蓝图/外观）零代码 |
| 拒绝与诊断（RefusalKind、Shortfall、Unassigned、Why、LaborCensus、heartbeat） | r01 §2、r05 §5 | **因果诊断的现成地基**（PRD-006 的关键） |
| 物流与仓储（Stash / StoreRule / Stores / Ledger / Carry / TransferNode） | r01 §2 | 经济系统不需要重做搬运 |
| 生产（wares：CraftNode / CraftRecipes / Smelt / Stations / Machines） | r02 §2.2 | 生产链与品质系统的挂载点 |
| 建造（build：Pattern(Starlark) / Blueprint / BuildSite / Growing） | r02 §2.3 | 工程自由的地基 |
| 已有玩法插件（farming / pasture / fishing / groundwork / patrol / orders / rail / dispatch） | r02 §1 | 我们不必做农牧渔猎与铁路 |
| 教学（Ponder / Scenes.folder） | r02 §0 | 新系统的课程有标准位置 |
| 测试基建（488 游戏测试、Blockwright、bench、fuzz、探针） | r05 §2–§5 | 自动验收可复用（受 Linux 限制） |

---

## 2. 必须自建（基底完全没有）

| # | 缺失 | 影响支柱 | 建议归属 | 关键 API 接入点 |
| --- | --- | --- | --- | --- |
| 1 | **需求层**（饥饿/休息/温暖/安全/社交/美感/意义） | P2 | 新插件 `needs`（或扩展 person/living） | `Declaring.urges(owner, UrgeSource)` + `Urge` + `ColonyContext.share(state)` |
| 2 | **情绪与精神崩溃** | P2/P5 | 同上 | 同上 + 自己的面板页（`RegisteringUi.page`/`Board`） |
| 3 | **记忆** | P2/P5 | 同上 | `Colony.keep(owner, CompoundTag)` 持久化 |
| 4 | **关系与社交** | P2/P5 | 新插件 `society` | 同上 + 社交 Node（占用休息时段） |
| 5 | **健康：伤病/疫病/医疗** | P3 | 新插件 `health` | `BodyState`（若可用）+ 新职业（医师） |
| 6 | **事件与叙述者** | P3/P5 | 新插件 `chronicle`（事件）/`lore`（记录） | 自己的日结算调度（复用 `Cadence.Cron`） |
| 7 | **威胁与战斗** | P3 | 新插件 `threat` | `patrol` 的 `WatchNode/StrikeNode` 可参考；敌人需要自定义实体 + `Locomotion` |
| 8 | **外交与外部势力** | P3/P4 | 新插件 `realms` | 抽象层 + `Colony.keep` |
| 9 | **时代与知识** | P4 | 新插件 `ages` | 配方/图案可用性过滤；`Shelves` 扩展 |
| 10 | **贸易与商队** | P4/经济 | 新插件 `trade` | `wares`/`Colony.stores` + 商队实体/抽象到达 |
| 11 | **经济扩展：品质、腐坏、工具消耗** | P4/经济 | 扩展 `wares`（或新插件） | `NodeSpec`（needs/gives）+ `ItemSpec` |
| 12 | **仓储规则扩展：预留、品质门槛、方向** | 管理 | 扩展 `orders`/`StoreRule` | `StoreRule`、`Board` |
| 13 | **微观控制层：作息表/禁限区/优先级矩阵** | 自由 | 新插件 `steering` | `Enrollment`/`Schema`（禁限区）+ `UrgeSource`（作息）+ 优先级需评估（见 §4 风险） |
| 14 | **剧本（Scenario）** | 自由 | 新插件 `scenario` | 世界创建钩子 + 数据包货架 |
| 15 | **传说页 / 编年史 / 家族树** | P2/P5 | `lore` 插件 | `Board` + 导出 |
| 16 | **统计与图表** | 管理 | `lore`/`insight` 插件 | `Board` + 日结算聚合 |
| 17 | **多人权限分级** | 多人 | 扩展基底成员机制 | `front/api` + 服务端校验 |
| 18 | **性能探针（我们系统的）** | 工程 | 测试侧 | 沿用 r05 的探针模式 |

---

## 3. 基底的硬约束（**已按 ADR-007 重新分类**）

> 来自 r01 §3.2、§4、§5。**2026-10-18 起我们 fork 了 Folkways 本体**（[ADR-007](../00-charter.md)），因此本表重新分三类：
> - **🔒 契约类**：即使 fork 也**不建议改**（改了会破坏引擎正确性或性能）→ 必须绕开/遵守
> - **🔧 可改类**：fork 内可以直接改（分层登记：L2/L3）→ 从"绕开"升级为"改造"
> - **🩹 缺陷类**：上游行为本身不合理 → **应当修**（我们比上游更能修）
>
> 详细分层与同步代价见 [fork 策略](../design/12-fork-strategy.md) §5。

| # | 类 | 约束 | 具体事实 | 我们的应对 |
| --- | --- | --- | --- | --- |
| 1 | 🔧 可改 | 计划规模上限 | `Refining.LIMIT = 256` 超限**抛异常**；`Tours` 4096 次重排后接受次优 | M1–M2 先按「分区/多殖民地」设计并给出同时活跃工作上限；M3 评估放宽 LIMIT 或改为**降级而非抛异常** |
| 2 | 🔧 可改 | 背包是 18 格整数模型 | `Pack.DEFAULT_SIZE = 18`；单次搬运受最宽裕搬运工包容量限制 | 短期：拆成多次 `Delivery`（基底会自动按包切分）；中长期（车队/集装箱/太空补给）：fork 内引入**多格容器/载具负载**模型，而不是硬改 18 |
| 3 | 🔒 契约 | 「结构性无解」被视为 bug | `Unassigned.structural()`：`NO_LICENCE / NO_TOOL / PACK_FULL / SAME_WORKER_SPLIT` 是「计划生长有 bug」，不是世界状态 | **保持**该语义（它是引擎的自检）；玩家侧改为**显式给许可/工具**或转成 `Shortfall`。**不允许**为"优雅等待"而改掉这个自检（那会掩盖真实缺陷） |
| 4 | 🔒 契约 | 后台线程契约隐式 | `Refinement.rewrite/expand`、`Sizing.runs`、`Ways.journey`、`Passage.hopsIn` 运行在 weave/schedule 线程；`Node.ready/commit`、`UrgeSource.urges` 在服务端线程 | **保持纯函数纪律**（这是性能与正确性的基础）；fork 后可做的改进是**把契约写成文档与断言**（`@ThreadSafe` 式注释 + 开发期断言），而不是取消它 |
| 5 | 🔧 可改 | 出行预算全局共享 | `travelCeilingMicros = 8000`（8ms/tick，AIMD，多殖民地共享）；单线程模式不计时 | 短期：给社交/巡航设计**低频次**与**就地优先**；中长期：fork 内做**分域预算**（按殖民地/按行为类别隔离上限）与"单线程也计时"的一致性修复 |
| 6 | 🔧 可改 | 人体尺度写死 | `Gait.BLOCKS_PER_TICK=0.165`、`Reach.PLAYER_BLOCK_REACH=4.5`、`Section` 8³、`Sweep.RANGE=64`、`Closures.MOST_DOORS=256` | 非人形单位（傀儡/牲畜/**载具与太空单位**）自带 `Locomotion` 是**正确做法**（保持）；fork 后可把尺度常量改为**按 `ResidentKind`/单位类型配置**（服务太空与大型生物，ADR-011 需要） |
| 7 | 🩹 缺陷 | 存档版本门是静默只读 | `SaveVersion.CURRENT = 1` 硬编码；不可解析/更高版本 → `sealed()` **静默**只读 | **修**：fork 内加入迁移框架（版本表 + 迁移函数），并把"只读"变成**可见警告**（PRD-001 §10）；我们的持久状态走 `Colony.keep(owner, CompoundTag)` |
| 8 | 🔒 契约 | 注册只在声明窗口 | `Ledger.writing` 窗口外抛异常；`sealedOnceRead` 账本读后不可写 | **保持**（它保证了注册的一致性与线程安全）；所有注册在 `Declaring`/`Relating` 内完成 |
| 9 | 🩹 缺陷 | 失败退避会「发粘」 | `Urges.BACKOFF=100`；`Cooldowns` 20 → 640 刻 | **修**：改为**分级退避**（短周期行为不被粘住）+ 退避状态进入诊断（[PRD-006](../prd/PRD-006-stock-rules-and-diagnosis.md) D-10 已有对应设计） |
| 10 | 🩹 缺陷 | 计划卡死只打警告 | `solving for Ns` 警告；`Cooldowns` 让失败工作很久才重试 | **修**：提升为**结构化诊断事件**（喂养 PRD-006 的瓶颈榜），而不是只写日志 |

---

## 4. 风险登记（按严重度）

| # | 风险 | 依据 | 严重度 | 缓解 |
| --- | --- | --- | --- | --- |
| R1 | **需求/情绪系统与计划图的耦合方式未验证**：`Urge` 是「想做什么」，我们的「饿/累/冷/怕」是「状态」，两者语义不同 | r01 §5.2、r02 §0 | 高 | PRD-001 前先做原型验证（原型主导工作流）：用 `UrgeSource` 表达「饿了」并驱动一次进食，验证是否够用 |
| R2 | **优先级矩阵/手动指派与基底「结构性无解=bug」冲突** | r01 §4.3 | 高 | PRD-005 需定义「玩家覆盖」如何映射到合法的工作（给许可/给工具/加优先级），而不是制造结构性无解 |
| R3 | **社交/集会/巡逻会抢 8ms/tick 出行预算** | r01 §4.6 | 中高 | 社交设计为「就地+低频」；用 `Cadence.Cron` 错相位；在 bench 中验证 `budget=` 行 |
| R4 | **袭击的战斗实现**（居民战斗 AI、敌人实体、非人形 Locomotion） | r01 §4.7、r02 §1 patrol | 中高 | PRD-004 先做抽象结算 + 少量表现（选项 C） |
| R5 | **存档迁移**：`SaveVersion.CURRENT=1` 且静默只读 | r01 §4.8 | 中高 | 我们用 `keep()` 自管版本；每个 PRD 写迁移策略；UI 显示只读状态 |
| R6 | **基底 pre-release，API 会变** | 章程 K1 | 中高 | 锁定版本；只用 `core/api`/`front/api`；维护 API 使用清单 |
| R7 | **UI 页面与基底 5 个核心页的整合** | r02 §0（`PageKinds`）、r03（待） | 中 | 等 r03 到位后定页面地图（d09 OQ-UI-1） |
| R8 | **Windows 无法跑 e2e/bench** | r05 §2 | 中 | CI + WSL2；层 0/1 本机保证 |
| R9 | **数据包货架能否承载我们的新内容类型**（事件/需求/剧本/时代） | r04（待） | 中 | 等 r04 后定「自建注册表 vs 复用 Shelves」 |
| R10 | **魔法般的「深度」不产生性能成本的想法不成立** | r05 §5、r01 §4.6 | 中 | 所有低频系统走日结算；每系统必须带探针 |

---

## 5. 建议的插件切分（初稿）

> 原则：**一个插件 = 一个玩家能理解的系统**（对应 r02 §0 的插件构成），且尽量与基底插件的粒度一致。

| 插件（建议名） | 承担 | 依赖基底 |
| --- | --- | --- |
| `needs`（需求） | 需求衰减、满足行为、食欲/疲劳/保暖 | `UrgeSource`、`Node`、person/living、wares（食物） |
| `mood`（情绪） | 情绪标量、原因清单、崩溃、恢复 | needs、society、环境 |
| `memory`（记忆） | 记忆条目、衰减、影响情绪/关系 | mood |
| `society`（社会） | 关系、社交行为、婚育、师徒、争执 | memory、needs、`Cadence` |
| `health`（健康） | 伤病、感染、疫病、医疗、后遗症 | body/BodyState、society |
| `steering`（调度/微观控制） | 作息表、禁限区、优先级、手动指派 | `Enrollment`、`Schema`、`UrgeSource` |
| `chronicle`（事件与叙述者） | 事件模板、权重、冷却、前兆、选项、叙述者 | `Cadence`、全部系统（作为作用面） |
| `threat`（威胁与战斗） | 敌人、袭击、防卫、民兵 | patrol、`Locomotion`、chronicle |
| `realms`（外部势力与外交） | 势力、关系、使节、条约、朝贡 | chronicle、抽象层 |
| `trade`（贸易） | 商队、价格、交易、货币演进 | wares、orders、realms |
| `ages`（时代与知识） | 时代门槛、解锁、学者、图书馆 | wares、build、`Shelves` |
| `lore`（传说与统计） | 编年史、人物条目、家族树、统计图表、导出 | 全部（只读） |
| `scenario`（剧本） | 开局条件、规则修正、难度 | 世界创建钩子、`Shelves` |
| `insight`（诊断） | 因果诊断视图、瓶颈列表、情绪解释 | `LaborCensus`、`Unassigned`、各系统状态 |

> 该切分是**建议**，最终以 PRD 为准。若某插件无法用现有 API 表达，宁可拆小也不要碰基底内部。

---

## 6. 回填状态（r03 / r04 / k01 / r07 均已到位）

| 回填项 | 结论 | 已反映到 |
| --- | --- | --- |
| 页面地图（复用哪些核心页、新增哪些） | 基底核心 5 页 + 每插件自带页；我们能加页（`RegisteringUi.page` + `PageKind.boarded`），但受「32 行/页、4 动作/行、8 行卡」硬预算约束 | d09 §3、PRD-005 |
| 覆盖层/可视化能力上限 | 有 `Layer`（俯瞰图层）可复用；但**没有图表/历史**（`MetricsPage` 只有实时网格 + 4 个数字，唯一时间窗是 `PastDay`） | d09 §5、PRD-006 |
| 数据包承载新内容类型的能力 | **新货架/发牌逻辑不在 API jar 内** → 新增货架（need/incident/…）可能需要上游 PR 或 fork；纯数据包目前只能做图案/部件/蓝图/皮肤/模型/名字池 | d11 §6、PRD-001 §15 |
| 配置项可扩展性 | `FolkwaysConfig` 全是速率/上限常数，**没有玩家可调的玩法开关**；我们要自己的 serverconfig | 所有 PRD §9.7 |
| mod 生态空缺（必须自研的类别） | 见 [pack/01 §3](../pack/01-modlist.md)：季节/温度数据层、外交势力、配置编辑器、轻量太空层、大型威胁生物 | pack/01、PRD-004/010 |
| MC 生态已有同类 mod | 见 §7 与 [r07](07-mc-landscape.md) | 本节、pack/01 |

---

## 7. MC 生态同类结论（来自 [r07](07-mc-landscape.md)，2026-10-17）

**差异化成立**：1.21.1 NeoForge 上没有任何 mod 同时具备「意图层 + 个体人味 + 时代进程」。

| 对象 | 判断 | 我们的动作 |
| --- | --- | --- |
| **Millénaire 9.0.2**（1.21.1 稳定） | 最强同类：7 种文化、贸易/声誉/外交、村庄编年史 | **定位为「外邦世界」**：作为邻村/势力来源整合，不做竞品；我们的 `realms` 可直接与之交互 |
| **MCA Reborn**（1.21.1） | 关系/婚姻/家族/遗传完整，但无生产与意图层；且是**另一套居民实体** | 只做外邦 NPC 或借其关系模型设计；**不做运行时依赖**（避免两套居民） |
| **MineColonies** | 重叠最大但稳定性差（稳定 43.6%/兼容 34.3%，`#5006` 长期未解） | **不做运行时依赖**；吸收其幸福三因子、技能受住宅等级上限、Research 列门槛 |
| **袭击类 mod**（Raided / The Hordes / More Raids / Guard Villagers） | 可作为敌人来源 | 评估整合：我们的 `threat` 专注「居民战斗/民兵/防御/后果」，敌人波次可交给它们（需验证是否攻击 Folkways 居民实体） |
| **商队类 mod**（Pillager Caravans / Better Caravans） | **全数据驱动**（编队/货物/生成规则/冷却/交易表） | 作为我们 `incident` / `trade_goods` 货架的**格式参照**；亦可直接整合提供商队 |
| **季节/温度**（Serene Seasons / Cold Sweat） | 各自维护一套状态，无法作为「数据层」交给规划器 | 仍需自研或 fork（见 pack/01 §3） |

**最有价值的证据（因果诊断必须自研）**：MineColonies 的 [`#11384 Alert Fatigue`](https://github.com/ldtteam/minecolonies/issues/11384) —— 红图标同时表示「停工」与「幸福抱怨」，导致玩家面对一片红而无从下手。这正是本项目的支柱 P1（意图层）与管理者的核心痛点。
→ **结论：把「因果诊断 UI」（PRD-006）提到与需求/情绪系统同等优先级**，并作为第一个原型验证对象（成本低、回报高）。