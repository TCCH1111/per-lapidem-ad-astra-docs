# PLAN-005 · M1-WP6：解释层（说得出为什么）

```
状态：W1、W2、W3、W5、W6 完成（VERIFY-027/028/030/031）；**W6 结论：文案 14/14、证据 5/14**；W4 与 W7（补证据）待做
负责人：规划者（agent）
最后更新：2026-10-25
上游依据：docs/workflow/05-m1-task-breakdown.md §4 WP-6；docs/prd/PRD-006-stock-rules-and-diagnosis.md
工作树：WSL `~/pla/mod`（main @ d0bfaf4）；构建 233（`--offline` 可用）；测试基线 686
```

---

## 1. 一句话目标

让玩家在殖民书里问"**他为什么没去干活 / 这件活为什么没人干**"，得到**具体到对象**的答案（哪个人、哪份活、被什么挡住、下一步该做什么），而不是一句"没人手"。

**图层**：**L1 为主**（读 `Unassigned`/`RefusalKind`/`Standings` 的既有数据）；若要在书里新增页面类型 → 可能 **L3**（见 §3）。

---

## 2. T0 已核实的夹具现状（D9 的关键）

| 事实 | 位置 | 影响 |
| --- | --- | --- |
| `PlanningFixture` 能造 **Crew / Worker / Ways / Stands**，含真实 `PersonBody` 实体 | `mods/core/src/gametest/.../plan/PlanningFixture.java`（267 行） | 派活链路**可测** |
| 它**不建殖民地服务**：没有 `ColonyData` 的 scope、没有 `LivingPresence`、没有 urge 来源 | 同上（`import` 里没有 `Colonies`/`Contributions`） | **需求类**（吃饭/如厕/睡觉）仍无法端到端测 → D9 未解 |
| `ColonyLabor(new ColonyData(), dim)` 在多个测试里可用 | `DispatchPlanningGameTests:82` 等 | **派活**能测，但只是"空殖民地" |
| `Standings` 已是可注入的组合 | `core/api/work/Standings.java`（VERIFY-024） | 解释层可以直接读"谁拒绝、什么理由" |

**结论**：解释层的**派活类**阻塞（`NO_LICENCE`/`NO_TOOL`/`NO_WAY`/`ZONE_FORBIDDEN`/`HOURS_RESTING`）可以用现有夹具证明；**需求类**（"他饿了所以去吃饭"）需要新夹具 → 仍挂 D9。**不假装两者都做完。**

---

## 3. 设计

### 3.1 统一入口（一本书里两处）
1. **按活问**：某份没被派出的活 → 显示 `Unassigned.Reason` + 具体是谁（若 `blockedBy` 非空）+ 建议动作。
2. **按人问**：某居民 → 显示他手上没活的原因（`BodyViews.doing()` 空 + 最近一次被拒的理由）。

两处共用**同一个映射函数**（本计划的 W1），保证措辞不漂移——这是 WP-4 T7 已验证过的做法。

### 3.2 映射表（≥8 类，逐条可解释）
| Reason | 玩家读到的 | 建议动作 |
| --- | --- | --- |
| `NO_FREE_HAND` | 所有人都在忙 | 加人 / 等 |
| `NO_LICENCE` | 没人有这门手艺 | 改工种 / 招人 |
| `NO_TOOL` | 缺工具 | 造/买工具 |
| `NO_WAY` | 走不到 | 修路/开门 |
| `PACK_FULL` | 背包塞不下 | 清包 |
| `PACK_BUSY` | 手上有活 | 等 |
| `NO_FREE_STAND` | 站位被占 | 清出站位 |
| `ZONE_FORBIDDEN` | 禁限区挡住 | 改区（跳到该页） |
| `HOURS_RESTING` | 不在工作时段 | 改作息（跳到该页） |
| `BEYOND_HORIZON` | 太远，计划看不到 | 等 / 搬近 |

> 10 类 > w05 要求的 8 类；每类都要**四语**。

### 3.3 建议动作怎么落地
- 能跳转的（区/作息）用 `Board.Act.Open(page)`；不能跳的（缺工具）只给文字。
- **不新增 `Board.Act` 动词**（WP-4 已验证 `Do`/`Open` 够用）。

---

## 4. 任务单

| # | 任务 | 层 | 验收 |
| --- | --- | --- | --- |
| **T0** | ✅ 夹具现状已核实（§2） | 文档 | 已落纸 |`n| **W1** | ✅ `Explanation` 纯函数（VERIFY-027） | L1 | 14 类全覆盖（比计划的 10 类多 4，测试抓出） |`n| **W2** | ✅ 四语 30 键（VERIFY-027） | L2 | 运行时语言表逐条验证 |
| **W1** | `Explanation` 纯函数：`Reason → (titleKey, adviceKey, Option<page>)` | L1 | gametest：**10 类全覆盖**，未知 reason 有兜底 |
| **W2** | 四语文案（10 类 × 标题/建议/单位） | L2 | 运行时语言表逐条验证（照 VERIFY-021 的教训） |
| **W3** | ✅ "按活问"：`Explanation.row(Unassigned)`（VERIFY-028） | L1 | 3 个 gametest 全过 |
| **W4** | "按人问"：`BodyViews`(`doing` 空) + 最近拒绝 → 行 | L1 | gametest：无 doing 的居民给出行 |
| **W5** | ✅ 端到端（VERIFY-030）：`Solving.standing(...)` 注入 + 全格否决 → `ZONE_FORBIDDEN` | 测试 L1 | 1 个 gametest 通过 |
| **W6** | ✅ 覆盖率报告（VERIFY-031）：14 类逐条分级，A/B/C/D | 文档 | 表已出，**不夸大**：9 类零证据 |`n| **W7** | 补证据：按性价比造出 D 级原因（licence/pack/stand/hand/horizon） | 测试 L1 | 每条从 D 提到 A |

---

## 5. 验收

| 判据 | 怎么验 |
| --- | --- |
| ≥8 类阻塞可解释 | W1 的测试逐条断言 |
| 措辞不漂移 | 页面与（将来的）命令共用 W1 |
| 四语齐全 | 运行时语言表验证 |
| 不吹牛 | W6 的覆盖率表明确写出 `NO_FREE_HAND` 等**未能端到端**复现的部分与原因 |
| 基线不破 | 686 起，只增不减 |

---

## 6. 风险

| 风险 | 处理 |
| --- | --- |
| 解释层变成"翻译表"而不是"诊断" | 每类必须带**建议动作**；没有建议的类别要说明为什么（例如"等"） |
| 需求类原因无法端到端 | 如实标"未接"，并留 D9 指向 WP-7 |
| 页面行数超预算（8 行/卡） | 分页：只显示"当前有阻塞的"前 8 条 + "更多…"行 |