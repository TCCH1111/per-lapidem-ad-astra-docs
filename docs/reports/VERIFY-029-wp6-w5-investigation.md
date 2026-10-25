# VERIFY-029 · WP-6 / W5 调查：端到端测试缺口在哪

```
状态：调查完成，W5 受阻（无可交付代码）
验证者：DSH 会话
验证日期：2026-10-25
关联：PLAN-005（W5）、VERIFY-028（692 基线）
fork 基线：3cdf8ff（无新提交）
```

---

## 1. 这轮想做的与做不到的

**想做**：用真实派活链路证明"禁区/作息真的会产出 `ZONE_FORBIDDEN`/`HOURS_RESTING`"——目前这两个原因只被**零件测试**覆盖（`Tours.unfit` 里的判定、`Standings.reasonOf` 的映射），没有一次"从求解到拒绝"的证据。

**做不到的原因**（本轮实读）：

| 事实 | 位置 |
| --- | --- |
| 测试用的求解器 `Solving` **自己 new 了一个 `Scheduler`** | `PlanningFixture.java:139` `this.planner = new Solving(claims, cooldowns);` |
| 我们的 `Standing` 只装到 `ColonyLabor`（生产路径） | `ColonyLabor.standing(...)` → `Pipeline` → `Scheduler` |
| `PlanningFixture.solve(...)` 走 `planner.handle(...)`，**不经过 `ColonyLabor`** | `PlanningFixture.java:142-204` |

→ 在现有夹具上装 `Standings` **不会影响**求解器，写出来的测试只会是"看起来测了、其实没测"。

---

## 2. 可行的两条路（留给下一轮）

| 方案 | 做法 | 层 | 代价 |
| --- | --- | --- | --- |
| **A（推荐）** | 给测试夹具 `Solving` 加一个 `standing(Standing)` 转发到它的 `Scheduler`，再写"禁区拒绝"用例 | **测试代码 L1**（不改生产代码） | 小：约 10 行夹具 + 1 个测试 |
| B | 走 `ColonyLabor` 生产路径：`apply(labor, ...)` 后读 `labor` 的 unassigned | 生产路径需暴露 unassigned 的读点（当前只有 `Readout` 日志） | 中：可能要加只读 API（L2） |

**选 A**：只动测试夹具，不碰生产代码，且真能证明"求解器看到禁区就拒绝"。

---

## 3. 与 §W5 原文的偏差

PLAN-005 里 W5 写的是"用 `PlanningFixture`/`ColonyLabor` 造两例"，验收"两种 reason 都能被解释函数读到"。**实际**：

- `ColonyLabor` 那条路能跑，但读不到 `Unassigned`（只有日志）；
- `PlanningFixture` 那条路能读到 `Scheduled.unassigned()`，但需要注入 standing。

所以 W5 的**形状变了**（从"跑通两条"变成"先给夹具注入点，再跑一条"），已记入 PLAN-005。

---

## 4. 本轮没有代码改动

基线仍 `3cdf8ff`，测试仍 **692**。本轮产出是**边界结论**：知道了该改哪里（`Solving` 的 standing 注入），而不是继续在错的夹具上堆测试。

下一轮按 A 实施。