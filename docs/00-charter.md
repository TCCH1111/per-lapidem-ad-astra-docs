# 项目章程 · Per Lapidem ad Astra

```
状态：已定稿
负责人：项目发起人（人类）
最后更新：2026-10-19
上游依据：无（本文是根文档）
```

---

## 1. 一句话定位

**《Per Lapidem ad Astra》是一套以 [Folkways](https://github.com/IzakyL/folkways) 为模拟内核的 Minecraft 整合包：在一块方块构成的世界里，经营一个会自己思考、会吵架、会死人的殖民地，从石器时代一路走到星辰。**

- **形态**：NeoForge 1.21.1 整合包（Modrinth/CurseForge 可分发）+ **Folkways 的自维护 fork**（在其源码上直接改造，见 ADR-007 与 [fork 策略](design/12-fork-strategy.md)）。
- **载体**：Minecraft 1.21.1（Folkways 目前唯一支持的版本）。
- **模拟内核**：Folkways —— 居民自己规划一天劳动的殖民地模拟 mod（MIT 许可，**允许 fork 与再分发，需保留原作者版权声明**）。
- **对标**：Dwarf Fortress（深度与叙事）、Songs of Syx（规模与战略）、RimWorld（人物与张力）、Stonehearth（建造与可爱）。

## 2. 目标玩家

| 玩家原型 | 他要什么 | 我们给他什么 |
| --- | --- | --- |
| **建筑师**（Minecraft 原生玩家） | 亲手造出好看的、有用的东西 | 居民的劳动会真的把你的建筑用起来；蓝图/图案/机械/铁路让基建规模化 |
| **管理者**（环世界/石炉玩家） | 优化、调度、扩张、看着系统跑起来 | 意图层（划地、订单、职业排序）+ 生产力与物流可视化 + 微观控制可选深入 |
| **故事家**（矮人要塞玩家） | 意外、人物、灾难、可以讲的故事 | 需求与情绪、关系与恩怨、袭击与疫病、世代更替、传说页（Legends） |

**判定标准**：三类玩家都能在**同一个存档**里找到自己的乐趣，互不排斥。

## 3. 体验目标（第一里程碑）

> 单人 / 小型服务器（2–4 人），**稳定玩 30 小时以上**仍有新内容解锁、仍会产生新故事。

拆解为可验收的体验里程碑：

| 时间点 | 玩家应当经历的 | 验收方式 |
| --- | --- | --- |
| 0–30 分钟 | 找到落脚点，用殖民书成立殖民地，第一批居民入住，划出第一块田 | 新人试玩观察：无需外部教程即可完成 |
| 30–120 分钟 | 理解「意图层」——划地、下订单、排序职业，而不是逐个点任务 | 试玩者能自己说出「我不用指挥每个人」 |
| 2–8 小时 | 经历第一次真正的危机（饥荒 / 严冬 / 袭击 / 疫病 / 士气崩溃），并从中恢复 | 试玩者能复述这次危机的故事 |
| 8–20 小时 | 进入第二、第三时代；建造工程（铁路 / 矿场 / 城墙 / 工坊群）；人口过 20 | 存档回顾：可见明显的技术与规模台阶 |
| 20–30 小时 | 有居民死了并留下故事；有盟友或敌人；有战斗与外交；有飞船或星际的最初一步 | 传说页里有 ≥5 条可读事件 |
| 30 小时以后 | 新开局仍然不同（不同风土、不同剧本、不同灾祸） | 三局不同种子的对局差异清单 |

## 4. 设计支柱（详见 [愿景与设计支柱](design/01-vision-and-pillars.md)）

1. **意图，而非指令**（Intent over orders）—— 玩家表达目标，居民自己算路径；微观控制是**可选**的深度，不是义务。
2. **每个人都是一个故事**（Every settler is a story）—— 需求、情绪、关系、恩怨、记忆、死亡与讣告。
3. **世界会回应**（The world pushes back）—— 季节、灾荒、疫病、兽群、袭击、外交压力。
4. **从石头到星辰**（Per lapidem ad astra）—— 纵向进程每一层解锁**新玩法**，不是新数值。
5. **失败长出故事**（Failure is content）—— 崩溃与死亡是内容，不是读档理由；但玩家永远有选择（可关、可调、可规避）。
6. **一切可被改写**（Everything is a datapack）—— 规则、内容、剧本都能被数据包 / Starlark / 脚本替换。

## 5. 范围

### 5.1 做（In scope）

- 一个**能自己运转**的殖民地模拟：居民、劳动、需求、情绪、关系、世代。
- 一套**有张力的**生存循环：食物、季节、温度、健康、威胁。
- 一条**纵向进程**：石器 → 铜 → 铁 → 工业 → 蒸汽/铁路 → 天空/星际（分层解锁，每层新玩法）。
- 一套**可玩的经济**：实物物流、生产链、仓储规则、订单、贸易与商队。
- 一套**叙事层**：事件、恩怨、袭击、死亡、传说页、剧本与叙述者风格。
- 一套**自由度工具**：微观指令（可选）、建造与工程、剧本/规则改写、多人协作。
- 一份**可分发**的整合包：安装简单、性能可预期、中文优先（四语言）。

### 5.2 不做（Out of scope，明确拒绝）

| 不做 | 理由 |
| --- | --- |
| PVP 竞技、竞技场、排行榜 | 与「殖民地经营」张力方向冲突，分散资源 |
| 数百人同屏的大战略地图（Songs of Syx 的 1000+ 人口） | Minecraft 单世界 tick 预算不支持，我们用「多殖民地 + 世界地图抽象层」替代 |
| 写实向硬核生存（口渴/排泄/疾病全拟真） | 会压过殖民地经营的主体验；只保留与「人」相关的部分（饥饿、温度、伤病、士气） |
| 手机版 / 基岩版 | 技术栈不兼容 |
| 重新实现一套规划器内核（自己写劳动/寻路/计划图） | 这是 Folkways 花了大量工程做好的部分；fork 后**改造**它远比**重写**它便宜（ADR-007）。我们改内核，但不推翻内核 |
| 内购、联网账号、云存档 | 不引入运营负担 |

## 6. 硬约束

| 约束 | 内容 | 影响 |
| --- | --- | --- |
| C1 版本 | Minecraft 1.21.1 + NeoForge 21.1.233+ | 所有 mod 必须支持该组合；1.21.1 仍是 NeoForge 生态最成熟版本 |
| C2 基座 | **Folkways 自维护 fork**（在其源码上改造），锁定的上游基线 commit 记录在 [fork 策略](design/12-fork-strategy.md) | 上游是 **pre-release**；fork 后我们对自己的代码负责，但必须保留上游同步能力 |
| C3 许可 | Folkways 为 MIT：fork 与再分发**允许**，但**必须保留原版权与许可声明**并注明修改（ADR-007）；整合包内各 mod 许可需逐一登记 | `docs/pack/01-modlist.md` 必须有许可列 |
| C4 平台 | 开发环境为 Windows；Folkways 的 Blockwright 自动化测试**仅支持 Linux x64** | 自动化验收需 WSL2/Linux 机器或云 runner；Windows 侧只能跑构建、单元测试、i18n、类型检查 |
| C5 性能 | 目标：60 居民 + 2 人联机时服务端 TPS ≥ 20（详见 [性能预算](pack/03-performance-budget.md)） | 每个新增系统必须提交性能成本估算 |
| C6 语言 | 中文为第一语言；玩家可见文本必须四语言（`en_us` / `zh_cn` / `zh_hk` / `zh_tw`） | 沿用 Folkways 的 i18n 规范 |
| C7 单人优先 | 单机体验完整；多人是增强而非前提 | 任何系统先定义单人行为，再定义多人行为 |
| C8 fork 维护 | fork 后的代码必须保持**可同步上游**：改动分层（见 [fork 策略](design/12-fork-strategy.md)），上游关键修复可定期合并；每季度做一次上游同步评估 | 禁止「一次性大改后与上游永久分叉」的写法 |

## 7. 成功标准（可验收）

| 编号 | 标准 | 验收方式 |
| --- | --- | --- |
| S1 | 新玩家 30 分钟内完成立寨并理解意图层 | 3 名未接触过的玩家试玩记录 |
| S2 | 30 小时存档仍解锁新内容 | 一份 30 小时存档的进度回顾清单 |
| S3 | 出现至少 5 类互不相同的危机，且都能被预防/缓解 | 危机矩阵表（见 [威胁与叙事](design/07-threats-and-narrative.md)） |
| S4 | 四语言无缺失（i18n 检查通过） | `test:i18n` 等价检查 |
| S5 | 60 居民 TPS ≥ 20，客户端 60 FPS @ 1080p | bench 场景实测（Linux runner） |
| S6 | 陌生人能在 20 分钟内装好并进入游戏 | 安装指南实测 |
| S7 | 三局不同种子的对局，系统差异可列举 | 对局差异记录 |

## 8. 里程碑

| 里程碑 | 目标 | 出口条件 |
| --- | --- | --- |
| **M0 文档**（已完成，2026-10-19） | 设计体系与工作流成型 | 本仓库 `docs/` 完成：章程、设计纲要、差距分析、整合包规格、首批 PRD、工作流 |
| **M1 可玩骨架**（进行中，2026-10-19 起） | 装好就能玩、殖民地能跑、意图层可理解 | S1 通过；整合包可分发；无阻塞性 bug。**已达**：w06 B-1..B-6 在上游原状 67f28b0 上全绿（WSL：build 9m45s、647 个游戏测试通过）；packwiz 整合包（NeoForge 21.1.264，44 个条目）服务端冒烟通过（k00 §10.1）。**未达**：B-2 改坐标（ADR-023）、WP-1 起的玩法工作包、同步演练 WP-10 |
| **M2 张力** | 需求/情绪/威胁/事件上线 | S3 通过；第一次危机可复现、可预防 |
| **M3 进程** | 时代推进 + 经济纵深 + 工程自由 | S2 通过；第二、三时代完整 |
| **M4 故事与打磨** | 叙事层、世代、传说页、多人 | S6、S7 通过；发布候选 |

## 9. 风险登记

| 编号 | 风险 | 概率 | 影响 | 缓解 |
| --- | --- | --- | --- | --- |
| K1 | Folkways 处于 pre-release，且我们**已 fork**：上游变动需要我们自己合并 | 高 | 高 | 锁定上游基线 commit；改动分层并记录「哪些文件被我们改过」；每季度评估上游同步；关键系统存档自管版本号 |
| K2 | 性能（大量居民 + mod 叠加） | 高 | 高 | 性能预算前置；bench 场景；限制初始人口上限；优先复用 Folkways 的规划器而非新增 tick 循环 |
| K3 | 自动化验收在 Windows 不可用 | 高 | 中 | 手动验收清单 + 单元/无头测试；Linux runner 处理 e2e |
| K4 | mod 生态碎片化（同功能多 mod、许可冲突） | 中 | 中 | mod 清单集中管理 + 许可登记 + 单一职责原则 |
| K5 | 设计膨胀（想做的比能做的多） | 高 | 高 | 支柱过滤：任何 feature 必须服务一条支柱，否则进「未来池」 |
| K6 | ~~与上游设计哲学冲突~~ → fork 后**我们就是上游**：风险转为**内部一致性**（居民自主 vs 玩家控制的边界） | 中 | 中 | 微观控制一律实现为「约束/偏好注入」（[自由度设计纲领](design/11-freedom-design.md) R-F2），**即使 fork 也不推翻规划器** |

## 10. 决策记录（ADR 索引）

| 编号 | 决策 | 日期 | 状态 |
| --- | --- | --- | --- |
| ADR-001 | ~~采用「整合包 + 自研插件」路线，不 fork Folkways 本体~~ → **已被 ADR-007 取代** | 2026-10-17 | 已废弃 |
| ADR-002 | 锁定 NeoForge 1.21.1 + Folkways | 2026-10-17 | 已定 |
| ADR-003 | 主题定为「拾石而上，直至星辰」的纵向进程 | 2026-10-17 | 已定 |
| ADR-004 | 四个自由度方向全部保留（微观管理/建造工程/叙事/世界规则） | 2026-10-17 | 已定 |
| ADR-005 | 第一里程碑为「单人/小服 30+ 小时核心循环」 | 2026-10-17 | 已定 |
| ADR-006 | 文档体系照搬「文档驱动 AI 工作流」的六阶段方法 | 2026-10-17 | 已定 |
| **ADR-007** | **直接 fork Folkways 本体并改造**（不再只写插件）；保留上游同步能力与 MIT 声明 | 2026-10-18 | 已定 |
| **ADR-008** | 微观控制做到 **A-max**（L1 策略 + L2 覆盖 + L3 深度控制），但**不推翻规划器**（仍为约束注入） | 2026-10-18 | 已定 |
| **ADR-009** | 需求系统做**全部 7 条**（饥饿/休息/温暖/安全/社交/美感/意义），不做「先 3 条」裁剪 | 2026-10-18 | 已定 |
| **ADR-010** | 季节/温度/口渴作为**可被规划器读取的世界数据层**：居民侧体温与口渴**自研**（挂 `ColonyContext`，照基底 `Hunger` 范式）；外部 mod（Cold Sweat / Serene Seasons 等）**只作可选传感器**，允许缺失，不 fork（Cold Sweat 许可声明冲突、Serene Seasons 为 ARR） | 2026-10-18 | 已定（依据 [r08](research/08-temperature-thirst-integration.md) 的 A 级证据） |
| **ADR-011** | 终局的「星辰」= **多方块火箭 + 可居住空间站**；架构已定：**主线自研**（复用 `build` 的图案/逐轮生长 + 自研空间站维度 + 跨 Realm `Passage`；飞行第一版为剧本式状态机，不做动力学），**备选** Create/Sable 移动结构，Ad Astra 仅作维度与环境素材 | 2026-10-18 | 已定（依据 [r09](research/09-space-endgame.md)：三处扩展点均为 A 级证据、无需新 mixin） |
| **ADR-012** | 术语统一：全项目使用基底官方译名「**殖民地 / 殖民书**」，废弃「聚落」 | 2026-10-18 | 已定（已全局替换） |
| **ADR-013** | 一切新增环境/经济系统（营养、温度、口渴、季节）**必须驱动 Folkways 居民本身**，不允许只做玩家侧状态 | 2026-10-18 | 已定 |
| **ADR-014** | **衰老三层可配，绝不写死**：① 全局衰老速度（`ticks_per_age_year` 默认 24000 ≈ 1 游戏日 1 岁）② **时代寿命加成**（每进入新时代期望寿命默认 +15%，科技越强人越长寿，避免高属性居民"死得太亏"）③ 个体体质/长寿特质。`aging_enabled` 默认开；三代同堂必须在 30 小时里程碑内可见 | 2026-10-18 | 已定（依据 [PRD-009](prd/PRD-009-generations-and-legacy.md)；d04 历法一年 = 32 游戏日） |
| **ADR-015** | **医疗与手术自研**（分部位伤病 → 感染 → 手术 → 义体），**器官摘取要做，但必须带道德代价**（目击者记忆、关系恶化、外邦名声与贸易后果）。**器官腔层改用 Chest Cavity Beyond**（`zhaijineet/Chest-Cavity-Beyond`，**MIT + 美术 Apache-2.0**，MC 1.21.1 / NF 21.1.216，**按 `EntityType` 注册**、3×9 器官槽、`api/capability/Organ` 与 `OrganChangeEvent`）：作为**可选但一等支持的依赖**，**缺失时降级为我们自有的抽象内脏槽**；因 MIT 我们保留 vendor 选项。**不用** `Who-Am-I-Core`（无 LICENSE = ARR）、`sons-of-sins`（ARR）、`med-system`（ARR） | 2026-10-18 | 已定（依据 [PRD-013](prd/PRD-013-medical-and-surgery.md)；CCB 许可与 API 已直读仓库核实） |
| **ADR-016** | **气体、污染与资源循环自研**，模型 = **分区池 + 格级梯度混合**（**不做** ONI 式逐格仿真：性能/多人/存档体积不可接受）；温度场由此层统一提供（PRD-003 不再自建第二套）；**不采用** Pollution of the Realms（**CC-BY-ND 禁演绎** + 实测性能差），RePother Reload（`wuziyue840/repother-reload`）**无任何许可证 = ARR**，两者均只作参照；**外部同类 mod 只允许单向只读输入、不得成为第二套权威**（R-GAS-31）；空间站复用同一套气体层 | 2026-10-18 | 已定（依据 [d13](design/13-gases-pollution-and-cycles.md)） |
| **ADR-017** | **项目基线一次定清**：modid = **`plaa`**；我们的代码许可 = **MIT**（保留上游 LICENSE 与 NOTICE）；内容层 = **KubeJS**（整合包侧依赖，**我们的 mod 本身不得依赖它**，缺失时必须能启动）；首发语言 = **zh_cn + en_us**（新增键两份，基底既有四语言文件保留不动，缺键回退 `en_us`）；医疗里程碑 = **M2 伤病/感染/基础治疗，M3 手术与义体**；气体/污染 = **M4 完整实现，M3 仅预埋接口**；关押系统（囚犯/人质/劳役/赎金）独立成 PRD | 2026-10-18 | 已定 |
| **ADR-018** | **整合包与发布基线（第二批）**：**FTB Quests + FTB Library 进包**（**Quests 只作可选引导任务书**并承载剧情呈现；规则仍只在 PRD 里，缺任务书必须可玩）、**FTB Teams 可选**、**FTB Chunks 不采用**（区块认领与我们的禁限区/领土概念会打架）；四者 GitHub 仓库**均无许可文件 = 事实 ARR**（允许在整合包内使用，**不可 fork/不可再分发代码**）；**机械族/机器人居民归 M3**，其「能量」需求 = **电力（FE，NeoForge Energy）**，**不得依赖任何能源 mod**（自建最基础发电设备必须能充电，缺电只允许表现为停机）；**专用服务器包延后**到单机全部完成之后；**世界生成类 mod 不采用**（用原版 + 我们的风土参数）；**Sodium 必装、光影只推荐不打包**；**PRD-014（气体落地规格）等 M4 前再写**；存档备份默认 = **每 30 分钟增量 + 每日全量、保留 24 增量 + 7 全量、压缩级别 6**（全部可配，**永不覆盖历史包**） | 2026-10-18 | 已定（依据 [k04](pack/04-quest-book-and-guidance.md)、[k01](pack/01-modlist.md)、[d14](design/14-saves-backups-and-migration.md)、[PRD-001](prd/PRD-001-needs-mood-memory.md) R-NM-24..26） |
| **ADR-019** | **四件事的形态定了**：① **厕所 = 联动 PoopSkyMod**（`Altnoir/PoopSkyMod`：**代码 MIT**、**美术资源 CC BY-NC 4.0**、1.21.1 / NF 21.1.248 / `poopsky` 2.2.1、默认分支即 `1.21.1-NeoForge`）；**如厕计量、失禁与卫生后果自研**（PRD-001）；**缺失时降级**为自建简易茅厕/粪桶；**因 NC 资源，整合包必须免费发布并保留署名**（用户已确认整合包免费；商业化前必须替换该 mod）；**同时我们自己再写一套"与殖民地联动的厕所"**（公厕/旱厕+粪坑/堆肥厕所/沼气池：既是需求满足点也是工作地点，掏粪清坑是居民的活，产出进 d13 的废物闭环，臭味与堵塞会产生事故）；② **能源 = 适配层，不做独立电网**：兼容 **Create 旋转力 / Mekanism FE / GregTech EU 与蒸汽**，内部以 **FE 为桥接基准**，机器人四种动力（**齿轮 / 蒸汽 / 电动 / 发条彩蛋**），**缺任何能源 mod 时我们自建的最基础发电设备必须能充电**；③ **成瘾物质 = 内容桥**：`Create Big Pharma`（Apache-2.0，可打包）、`Create Pop`（MIT，可打包）、`CustomBrewRecipes`（CC0，可打包但停更）、`Kaleidoscope Tavern`（许可不明，**默认不打包**）、`Create: Addictives`（CF-only 且无许可，**不打包**，只作灵感）；**成瘾规则自研**，且**不装任何酿酒 mod 也必须能成瘾**（自建基础酒/药）；④ **机械族可以恋爱与成为伴侣**（完整接 PRD-008），并可通过**人造子宫**生育（体外孕育生物居民 + 组装机械族），**全部有代价，不得成为无限人口打印机** | 2026-10-18 | 已定（依据 [d15](design/15-power-and-mechanical-residents.md)、[PRD-001](prd/PRD-001-needs-mood-memory.md)、[PRD-008](prd/PRD-008-relationships-and-social.md)、[PRD-009](prd/PRD-009-generations-and-legacy.md)） |
| **ADR-020** | **构建与测试平台的事实基线（2026-10-18 直读上游核实）**：`.blockwright/mods.json` **是生成的、不是手写的**——`npm install` → **`npm run setup`**（按 `blockwright.toml` 的 URL+sha512 下载）→ `./gradlew build`；环境 = **Java 21 + Node ≥ 22.14**，NeoForge **21.1.233** / MC 1.21.1；**构建跨平台，游戏测试（Blockwright/Playwright）目前只支持 Linux x64** → CI 的 gametest/e2e 必须 Linux runner；**R-FK-12 修正为"运行期零可选依赖"**（编译期依赖由 `blockwright.toml` 统一提供，不是我们的负债） | 2026-10-18 | 已定（依据 [d12 §6.1](design/12-fork-strategy.md)、`reference/folkways-master/CONTRIBUTING.md:6-22`、`build.gradle:81-110`、`blockwright.toml`） |
| **ADR-021** | **M1 开工基线（四项，用户裁决）**：① fork 基线**前移**到上游 `master` @ **`67f28b0`**（标签 `upstream-base-67f28b0-20261019`）——上游 `0af84f0`（2026-10-17，晚于我们首个快照 6 小时）已把单 jar 拆为**四个 Gradle 子项目 / 四个 modid**：`folkways_core`（必装：引擎 + 殖民书）、`folkways_vanilla`（必装：农牧渔搬运建造巡逻）、`folkways_create`（随 Create）、`folkways_modulargolems`（随 Modular Golems），四者须同版本，LDLib2 `[2.2.37,)` 仍为必需前置；我们尚无代码，前移零成本，留在 `f42e3c1` 则首次同步即吞下整树搬家。**代价**：`reference/` 换新快照，`docs/research/01~05`、w05、w06 的 `文件:行号` 引用按 w01 §5 重跑差异；**ADR-017 的 modid=`plaa` 须按四 modid 重述（[d12 OQ-6](design/12-fork-strategy.md)，待定）** ② **分仓**：fork 为独立 git 仓库，位于工作区 `mod/`，集成分支 `main`，remote `upstream`（[d12 OQ-1](design/12-fork-strategy.md) 已定） ③ **远端暂无**：先本地 git（完整克隆上游历史），GitHub fork 之后再加 ④ **整合包工具 = packwiz**（[k00 OQ-PK-1](pack/00-pack-spec.md) 已定）：清单由 Modrinth 数据生成、导出 `.mrpack` / CF zip、jar 不入库；**整合包装 `folkways_core` + `folkways_vanilla` + `folkways_create` + LDLib2，不装 `folkways_modulargolems`**（Modular Golems 不在 k01 清单） | 2026-10-19 | 已定 |
| **ADR-022** | **Linux 侧构建与过渡期整合包（用户裁决）**：① **`npm run setup` 在 Windows 不可能运行**——`@izakyl/blockwright-client` 的 `dist/blockwright` 是 Linux x64 ELF 可执行文件，Blockwright 官方只支持 Linux x64（Ubuntu 24.04 / glibc 2.39 基线），`npm ci --force` 也无济于事（[w06 §1.2/§1.3](workflow/06-build-and-ci.md) 实测）→ 开发机安装 **WSL2 Ubuntu-24.04 到 D:**（C: 仅剩 9.7 GB），fork 仓库工作树**搬进 WSL ext4**（`~/pla/mod`），Windows 侧不再保留 `mod/` 工作树（经 VS Code Remote-WSL / `\\wsl.localhost` 编辑）；整条 B-3..B-6 与 gametest 都在 WSL 内运行（w06 OQ-B-7 已定） ② **过渡期整合包先用上游 nightly jar**：`folkways-core` / `folkways-vanilla` / `folkways-create` @ 67f28b0（MIT，GitHub 发布资产带 sha256 摘要，packwiz 以哈希钉死）；[k00 §7](pack/00-pack-spec.md)"只装 fork jar"是终态，fork 产出首个 jar 后替换 ③ `pack.toml`：name `Per Lapidem ad Astra`、author **TCCH1111**、version `0.1.0+mc1.21.1+neoforge21.1.233`（R-PACK-4） | 2026-10-19 | 已定 |
| **ADR-023** | **四 modid 与 M1 构建口径（用户裁决）**：① ADR-017 的 modid=`plaa` 展开为 **`plaa_core` / `plaa_vanilla` / `plaa_create` / `plaa_modulargolems`**（与上游四模块 1:1；每个子项目只改 `mods/<name>/build.gradle` 的 `ext.modId` / `ext.modName`，四个 toml 的 `[${version}]` 互钉自动跟随）；**资源命名空间 `folkways` 不改**（R-FK-2，上游四 mod 本就共用）；R-FK-3 的 `mods.toml` 冲突声明对 `folkways_core` / `folkways_vanilla` / `folkways_create` / `folkways_modulargolems` 逐一写 `incompatible`（[d12 OQ-6](design/12-fork-strategy.md) 已定） ② fork 开发环境的 NeoForge **暂保持上游的 21.1.233**，先让上游原状通过 w06 B-3..B-6；整合包已是 21.1.264，二者兼容（`[21.1.233,)`）；是否同步升级在 B-2 时按 [w06 R-BLD-1](workflow/06-build-and-ci.md) 单独提交 ③ [r10](research/10-upstream-delta-f42e3c1-67f28b0.md) 的 431 条引用迁移由 agent **机械改写**（只改 `文件:行号`，不改结论文字）；36 条失效结论中涉及设计的（F-21 效率修正范式、F-24 上游 `Stall` 诊断与 PRD-006 重叠、F-27 插件归属等）整理为待裁决清单 `docs/research/drafts/draft-r10-design-impact-20261019.md` 交人类 | 2026-10-19 | 已定 |
| **ADR-024** | **r10 设计级影响 17 条裁决（用户，依据 [draft-r10](research/drafts/draft-r10-design-impact-20261019.md)）**：§1 F-20 **C**（混合：引擎 L2 改动留 core；与 Create 耦合的玩法进 `plaa_create`；其余新玩法合进**一个新子项目 `mods/plaa/`**，modid `plaa`）；§2 F-21 **A**（效率/情绪修正作为 `effect` 层的 `Perk.Grant`/`Stat` 来源接入，不再走 `ResidentEntity` transient modifier；PRD-001 AC-21 的夹取与 `Stats.WORK_SPEED` 对齐）；§3 F-22 **A**（我们的配置另起 `plaa-server.toml`，不碰上游三份）；§4 F-23 **A**（k03 预算按所属配置文件重列，`create` 是否安装写成前提）；§5 F-24 **A + C**（`Stall` 当基底：WP-1 去掉已公开项、WP-6 在其上扩展并复用重合类别；同时 M1 差异化重心改为上游尚无的需求/情绪/如厕、作息、禁限区——"为什么没发生"保留为 WP-6 目标但不再是唯一卖点）；§6 F-25 **A**（先由调研者读 `PatrolPresence` 页面能力，再定 PRD-004 是否挂在其下）；§7 F-26 **A**（每个 mod 在自己的 `@Mod` 构造器装自己的插件）；§8 F-27 **A**（整合包四个 Folkways jar 默认全装；此前 ADR-021 "不装 modulargolems" **作废**，k01 补 Modular Golems 行）；§9 F-29 **C**（按 jar 拆 toml + R-FK-12 增补"`folkways_create` 属必装可选集"例外）；§10 F-31 **C**（与上游页面相关的课用 `Scenes.add` 追加，新系统另立 folder）；§11 F-33 **C**（先沿用上游卡片行，待 F-24 落地后再定展示位）；§12 F-34 **B 的"单 jar"部分已由 §1 吸收**：新增玩法 = 一个 `plaa` jar；**但 fork 本体仍按 [ADR-023](#) 为四个 `plaa_*`，资源命名空间保持 `folkways`**（B 原文的"命名空间 `plaa`、依赖上游四 jar"与 ADR-007/023 冲突，不采）；§13 F-02 **C**（M1 先用上游 modid 跑通——已达成；改名按 PLAN-001 与 WP-10 一起做）；§14 F-04 **C**（G1 拆为"构建可重复（不硬编码 jar 数）+ 整合包可装载"）；§15 F-05 **A**（M1 去掉 fuzz 层，B 留 M2）；§16 F-10 **A**（我们的 mod 对上游 core 完整 jar 编译，不依赖 apiJar）；§17 F-19 **A**（公共面 = 上层 mod 实际 import 的包，以实况为准） | 2026-10-19 | 已定 |
| **ADR-025** | **基线前移与远端（用户）**：① fork 基线从 `67f28b0` **前移到上游当前 `master` @ `29498b0`**（标签 `upstream-base-29498b0-20261019`；差异 1 提交，B-2 涉及的文件是否被触及待核）；`reference/` 换新快照、r10 的迁移表按同样方法补差分 ② **建 GitHub 远端**：在用户账号 **TCCH1111** 下新建仓库承载 fork（名称待定，建议 `per-lapidem-ad-astra`），`origin` 指向它，`upstream` 仍指 IzakyL/folkways；toml 的 `displayURL` / `issueTrackerURL` 与 `maven_group`（`io.github.tcch1111`）随之确定（PLAN-001 OQ-P1-1/2）③ PLAN-001 OQ-P1-3 **改** `rootProject.name = "plaa"`；OQ-P1-4 **是**，`NOTICE.md` 打进四个 jar 的 `META-INF` ④ 工作区根仓库开始**分批提交**（`docs(...)` / `pack(...)` / `tools(...)`） | 2026-10-19 | 已定 |

> ADR 展开记录：后续新决策追加到 `docs/design/adr/ADR-NNN-*.md`（当前数量少，暂以索引形式记录在本表）。