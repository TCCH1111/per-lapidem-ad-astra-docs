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

**T0 已核实（2026-10-24，两条都已落纸）：**

1. **`Board.Act` 是 sealed interface，恰好 5 个动词**（`Board.java:97-113`）：
   `Edit(settingKey)`、`Admit(labelKey, kind)`、`Ping(BlockPos)`、`Open(pageLoc)`、**`Do(actionKey, labelKey, icon)`**。
   → **`Do` 是通用的**：新建/删除/编辑区域都能挂在自定义 `actionKey` 上，**不需要第 6 个动词，T6 因此是 L1，不触发 L3**（OQ-2 关闭）。

2. **`Refinement` 不是"按人"的钩子**（`Refinement.java`）：它的输入是 `Intent` 与 `Grown` 图（`expand`/`rewrite`/`options` → `Change`），**没有 `Worker`/`Resident` 参数**。
   → 它只能回答"**这份活该不该被规划出来**"，不能回答"**这个人能不能去那儿**"。本计划 §4.2 原先"把区域判定塞进 Refinement"的假设**作废**。

3. **因此 T4 改为"先找按人的资格钩子"**：候选（按可能性排序）——
   `core/api/resident/Licences.java`（基底已用它表达"谁被允许做哪类工种"，`RefusalKind` 里也有对应拒绝）、
   `core/api/participation/Participations.java`（`Stake` 模型，`Urges.offered` 里用它过滤 `urge`）、
   `core/engine/labor/Requests.java` / `Scheduler.java`（派活的最后一道）。
   若只有 `Scheduler` 能表达，则 WP-4 的 T4 按 w05 预期升为 **L3 并单独评审**——这正是 w05 写"L1 + L3"的原因。

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
| **T0** | ✅ 已做：`Board.Act` 5 动词（含通用 `Do`）、`Refinement` 无 `Worker` → 改走按人资格钩子 | 文档 | 两条结论已落纸；OQ-2 关闭 | — |
| **T1** | 新建插件骨架 `plugins/steering/{SteeringPlugin,SteeringContent,SteeringState}.java` + `install` 注册 | L1 | 编译通过；服务器启动日志出现插件声明（不加日志则用 gametest 断言 state 已 share） | `gradlew build --offline` |
| **T2** | `ZoneRule` + `SteeringState` + 存档序列化（`keep`） | L1 | gametest：存→读回→规则一致；空状态读回为空 | 单测 + gametest |
| **T3** | 判定纯函数 `verdict(...)` | L1 | gametest 覆盖 6 种边界（区外、区内禁入、ALLOW_ONLY 命中/不命中、LIMIT 未满/已满） | gametest |
| **T4** | 承接 T0 的结论：在**按人资格**处拒绝（`Licences`/`Participations` 优先；只有 `Scheduler` 可用则升 **L3 评审**） | L1/L2，或 **L3** | gametest：禁入区内该居民取不到该活，且产出 `SteeringRefusal`；`Refining.LIMIT=256` 不被放大 | gametest |
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
| OQ-1 | ~~`Refinement` 能否拿到目标格~~ → **不能**（无 `Worker` 参数，见 §3）。改为：**按人资格钩子在哪一层？**（`Licences` / `Participations` / `Scheduler`）决定 T4 是 L1/L2 还是 L3 | T4 开工前 |
| OQ-2 | ~~5 个动词是否够用~~ → **够**：`Do(actionKey, …)` 通用（§3）。**已关闭** | ✅ |
| OQ-3 | LIMIT 的"同时在区内人数"如何计数——按格集还是按区心半径？ | T3 开工前 |
| OQ-4 | 禁限区是否影响**已有**在区内的居民（强制撤离）还是只挡新派活？ | T5 开工前 |
