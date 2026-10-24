# PLAN-003 · M1-WP4：禁限区（谁能去哪）

```
状态：计划中（待派单）
负责人：规划者（agent）
最后更新：2026-10-24
上游依据：docs/workflow/05-m1-task-breakdown.md §4 WP-4；docs/prd/PRD-005-intent-and-micro-control.md；docs/design/12-fork-strategy.md §5（L0–L4）
工作树：WSL `~/pla/mod`（main @ 7a62ea4）；参考快照 `reference/folkways-3ce4d88/` 只读
构建：NeoForge 21.1.233（`--offline` 可用）
```

---

## 1. 一句话目标

让玩家能在殖民地范围内**画出"不许去"与"只许/限量去"的区域**，让居民在规划时就遵守它，并且在殖民书里**能问出"他为什么没去那儿"**。

**图层**：**L1 为主**（新插件 `plugins/steering`）+ **L3 待评审**（若必须新增 `Board.Act` 动词或扩 `Schema.Setting`）。**无 L4**。

---

## 2. 为什么它是 M1 的第一个玩家可见功能

w05 的演示脚本第 2–6 步就是"画区 → 开作息表 → 居民按约束行动"。禁限区是**玩家第一次感到"我在指挥他们"**的地方；也是 PRD-006 解释层的第一批真实阻塞来源（D-9「被规则挡住」）。

---

## 3. 先用到的上游契约（已核实，T0 再补两处）

| 契约 | 位置 | 用途 |
| --- | --- | --- |
| 插件注册 | `FarmingPlugin.install(IEventBus)`：`modBus.addListener(Declaring.class, XxxContent::declare)` + `Registering.class` | 我们的 `SteeringPlugin.install` 照抄 |
| 殖民地作用域 | `ColonyContext`：`share(Object)`、`urges(BiFunction)`、`tick(Consumer)`、`watch(...)` | 禁限区状态与清扫节拍 |
| 拒绝理由 | `RefusalKind` 是 public 接口（`RefusalKind.java:5`），`Named` 用枚举自动拼 key | 新增 `SteeringRefusal` 枚举**不需要改上游** |
| 面板 | `Board.Row`：**每行最多 4 个 `Act`**（`Board.java:50`）；`Board.Act` 是 `Board` 的嵌套类型 | 区域列表与"为什么" |
| 规划过滤 | `Declaring.refinement(Refinement)`（`Declaring.java:33`） | 约束作为一条 refinement 参与候选裁剪 |

**T0 必须补读的两处**（无法从这几行确定）：
1. `Refinement` 的接口签名（`core/api/work/Refinement.java`）——它是否拿得到 `Worker`/目标格/`Passage`，决定"区域判定"能放在哪一层；
2. `Board.Act` 的 5 个动词到底是什么（`Board.java` 后段）——决定"新建/删除区域"是否**必须**新增动词（若是，则 L3 评审）。

---

## 4. 数据与判定（设计）

### 4.1 区域模型
```
ZoneRule {
  id, name,
  kind:  FORBID | ALLOW_ONLY | LIMIT      // 禁入 / 只许这些人 / 限人数
  cells: Set<BlockPos>                     // 复用基底选区，不新画法
  subjects: Resident | Vocation | ResidentKind   // 对谁生效
  quota: int                               // 仅 LIMIT：同时在区内的人数
}
```
- 每个殖民地一份 `SteeringState`（`ColonyContext.share`），随 `colony.keep(...)` 存档（自有 schema，L1）。
- **不做**逐 tick 全图扫描：区域格是画的时候一次性展开，之后只按格所属的 chunk 失效重算（与 `Section` 8³ 对齐）。

### 4.2 判定（纯函数，可单测）
```java
Verdict verdict(SteeringState state, BlockPos cell, Resident who, long now)
  → ALLOWED | FORBIDDEN(zoneId) | LIMITED(zoneId, quotaFull)
```
- **纯函数**：输入状态 + 格 + 人 + 时间；不读 `level`、不写任何东西。
- 作为一条 `Refinement` 注册（T0 确认签名后决定是"过滤候选"还是"给候选打拒绝标记"）。

### 4.3 "为什么"（解释层最小接口）
- 新增 `enum SteeringRefusal implements RefusalKind.Named { ZONE_FORBIDDEN, ZONE_ONLY_FOR_OTHERS, ZONE_QUOTA_FULL }`
  → 自动得到 `folkways.refusal.steering.*` 键；**L1**。
- 殖民书一行：`"去不了 X：被禁限区「Y」挡住"` + 一键跳到该区（复用既有 Row/Act）。

---

## 5. 任务单（T0–T8）

| # | 任务 | 层 | 验收 | 自测 |
| --- | --- | --- | --- | --- |
| **T0** | 补读 `Refinement` 与 `Board.Act`，写进本计划的"契约附表" | 文档 | 两处签名/动词落纸，无"待定" | — |
| **T1** | 新建插件骨架 `plugins/steering/{SteeringPlugin,SteeringContent,SteeringState}.java` + `install` 注册 | L1 | 编译通过；服务器启动日志出现插件声明（不加日志则用 gametest 断言 state 已 share） | `gradlew build --offline` |
| **T2** | `ZoneRule` + `SteeringState` + 存档序列化（`keep`） | L1 | gametest：存→读回→规则一致；空状态读回为空 | 单测 + gametest |
| **T3** | 判定纯函数 `verdict(...)` | L1 | gametest 覆盖 6 种边界（区外、区内禁入、ALLOW_ONLY 命中/不命中、LIMIT 未满/已满） | gametest |
| **T4** | 接 `Refinement`：把 FORBID 变成规划期的"不可选" | L1（T0 若需改 core 则 L2 并评审） | gametest：同种子下，有禁入区时该区内的 `Node` 不出现在候选；保持 `Refining.LIMIT=256` 不被放大 | gametest |
| **T5** | `SteeringRefusal` 枚举 + 接到拒绝路径 | L1 | gametest：被禁入的目标产出 `Outcome.Failed(RefusalKind)` 而非静默丢弃 | gametest |
| **T6** | 殖民书面板：区域列表 + 每行 ≤4 个既有 `Act` | L1（若缺动词 → **L3 评审**） | 手工：能列出、能删除；行数不超预算（8 行/卡、32 行/页） | 人工 + 截图 |
| **T7** | `steering why` 文案与 UI 一致（同源） | L1 | 手工：`/plaa why` 与面板逐字一致 | 人工 |
| **T8** | 登记与报告：d12 改动表（若有 L2/L3）、VERIFY 报告、AC 勾选 | 文档 | 断链 0、登记齐全 | 脚本 |

---

## 6. 验收总表（WP-4 Gate）

| 判据 | 怎么验 |
| --- | --- |
| 全量回归 | `runGameTestServer --offline` 全绿（当前基线 657） |
| 约束真的生效 | gametest：禁入区内不派活；解除后重新可选 |
| 解释得住 | 每个被挡的候选都有 `SteeringRefusal` 且能定位到区域 |
| 不改引擎契约 | diff 不触及 `BodyRunner`/`Gait`/`Refining.LIMIT` |
| 面板合规 | 行/动作预算不超；无新增图表 |
| L3 有评审 | 若新增 `Board.Act` 动词，必须单独评审并记录理由 |

---

## 7. 风险

| 风险 | 触发信号 | 处理 |
| --- | --- | --- |
| 区域判定放大 refinement 数量 | 日志 `refinement` 数逼近 256 | 判定在**过滤前**裁剪候选；单测固定"64 指令 × 120 居民" |
| 面板动词不够用 | T6 发现删除/编辑没有对应 `Act` | 停，提交 L3 评审；**不许**私加第 6 个动词 |
| 选区与基底手势冲突 | 玩家画区行为与既有选区不同 | 复用既有手势，不自造画笔 |
| 多人并发改同一区 | 两人同时改 | 以殖民书的权限层为准（PRD-012），区内操作走同一入口 |

---

## 8. 开放问题

| 编号 | 问题 | 何时定 |
| --- | --- | --- |
| OQ-1 | `Refinement` 能否拿到"目标格"，还是只能看指令类型？决定 T4 的实现位置 | T0 |
| OQ-2 | `Board.Act` 的 5 个动词是否够"新建/删除区域"？ | T0 |
| OQ-3 | LIMIT 的"同时在区内人数"如何计数——按格集还是按区心半径？ | T3 开工前 |
| OQ-4 | 禁限区是否影响**已有**在区内的居民（强制撤离）还是只挡新派活？ | T5 开工前 |
