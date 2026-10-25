# VERIFY-031 · WP-6 / W6：解释层覆盖率报告（14 类，证据分级）

```
状态：报告完成（结论不乐观）
验证者：DSH 会话
验证日期：2026-10-25
方法：对 102 个 gametest 源文件逐条搜索 `Unassigned.Reason.<X>`，再看该文件是谁写的
关联：PLAN-005（W6）、VERIFY-030（693 基线）
fork 基线：1095d57
```

---

## 1. 先给结论

我们**能把 14 类原因翻译成人话**，但目前只有：

- **1 类**（`ZONE_FORBIDDEN`）有我们自己的**端到端**证据；
- **1 类**（`HOURS_RESTING`）有注册 + 映射，**没有端到端**；
- **3 类**有**上游**测试提及（`NO_WAY`、`WAY_PENDING`、`SAME_WORKER_SPLIT`）；
- **9 类零提及**：没有任何测试证明"引擎真的会产出它"。

这不是解释层写错了，而是**我们不知道那 9 类在什么情况下会出现**——写文案时是照着枚举名猜语义的。

---

## 2. 证据矩阵（grep 实测）

| 原因 | 提及文件 | 谁写的 | 证据等级 |
| --- | --- | --- | --- |
| `ZONE_FORBIDDEN` | 6 个（`StandingVetoGameTests` 等） | 我们 | **A：端到端**（真实求解器 → `unassigned`） |
| `HOURS_RESTING` | 3 个（`StandingsReason`、`Explanation*`） | 我们 | B：映射 + 注册，无端到端 |
| `NO_WAY` | `TravelPlanningGameTests` | 上游 | B：上游端到端（未复核具体断言） |
| `WAY_PENDING` | `TravelPlanningGameTests` | 上游 | B：同上 |
| `SAME_WORKER_SPLIT` | `WorkerConstraintGameTests` | 上游 | B：同上 |
| `NO_TOOL` | `Explanation*` | 我们 | C：**只有文案测试**，没有"引擎产出"证据 |
| `PACK_FULL` | `ExplanationRowGameTests` | 我们 | C：同上 |
| `NO_FREE_HAND` | — | — | **D：零证据** |
| `NO_LICENCE` | — | — | **D：零证据** |
| `PACK_BUSY` | — | — | **D** |
| `CLAIM_TAKEN` | — | — | **D** |
| `WORKER_AWAY` | — | — | **D** |
| `NO_FREE_STAND` | — | — | **D** |
| `BEYOND_HORIZON` | — | — | **D** |

> 统计口径：`Unassigned.Reason.X` 字面出现在 `mods/*/src/gametest/**` 的文件数。"提及"不等于"断言了产出"，所以 B 级仍需复核。

---

## 3. 这件事为什么重要

解释层是 M1 的卖点。如果玩家看到一个我们**从没见过触发**的原因（比如 `CLAIM_TAKEN`），有两种可能：

1. 文案对，玩家获益；
2. 文案错，玩家被误导——**比不给解释更糟**（VERIFY-023 已确立这条原则）。

当前 9 个 D 级原因就是 9 个"可能是第 2 种"的赌注。

---

## 4. 补证据的计划（下一阶段，按性价比排序）

| 优先 | 原因 | 怎么造出来（用 W5 的夹具） |
| --- | --- | --- |
| 1 | `NO_LICENCE` | 给 `Crew.Hand` 一份空 licences，派一份需要工种的活 |
| 2 | `PACK_FULL` | 把 `Hand` 的 pack 容量设为 0（W5 场景已有先例） |
| 3 | `NO_FREE_STAND` | 站位被别的活占用 |
| 4 | `NO_FREE_HAND` | 所有 hand 都在忙（`holding` 非空） |
| 5 | `BEYOND_HORIZON` | 把目标放到计划视野之外 |
| 6 | `CLAIM_TAKEN` / `PACK_BUSY` / `WORKER_AWAY` | 需要 `Claims`/状态注入，成本最高，最后做 |

**每造出一个，就把对应行从 D 提到 A**，并在报告里更新矩阵。这是可累积的工作。

---

## 5. 老实说：W6 的目标本该是"证明 ≥8 类可解释"

现在的实际状态是：**文案覆盖 14/14，证据覆盖 5/14（A 或 B）**。w05 要求"≥8 类阻塞可解释"，从**文案**看已满足，从**证据**看还差 3 类。把它写成"已完成"就是自欺。

---

## 6. 本轮无代码改动

基线 `1095d57`，测试 **693**。产出是一张**不想看到但必须看的表**，以及 6 条按性价比排序的补证计划。