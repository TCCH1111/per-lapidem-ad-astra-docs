# VERIFY-016 · WP-4 / T4a：`Standing` 否决管道（L3，默认零行为变化）

```
状态：管道完成（T4b 接线待做）
验证者：DSH 会话
验证日期：2026-10-24
关联：PLAN-003-A（L3 提案，已获批准）、VERIFY-015（662 基线）
fork 提交：9c66d7d
```

---

## 1. 结论

按批准的 L3 方案，把"按人 + 按格"的否决从 `ColonyLabor` 一路穿到 `Tours`：

- 新增 **`core/api/work/Standing`**（public，默认 `ALL` 全放行）
- `Unassigned.Reason.ZONE_FORBIDDEN`（**非 structural**：玩家可改区域）
- `Tours.unfit(...)` 在计算完 steps 后，逐格问 `Standing.permits(hand.id(), stance.cell())`，命中即返回该原因
- 管道：`ColonyLabor.standing` → `Pipeline.standing` → `Scheduler.standing` → `Tours.standing`（`closed()` 重建 `Tours` 时重新挂上）

**零行为变化证据**：`Standing.ALL` 下 **`All 662 required tests passed`**。

---

## 2. 实施与提案的一处偏差（有意，且更小）

提案原写"在 `Fitness.of` 加 `ZONE_FORBIDDEN`"，实施时发现 **`Fitness.Work` 里的 `cells` 是背包格数（`long`），不是方块位置**，`Fitness` 根本拿不到"这活站在哪些格子"。

于是判定移到 **`Tours.unfit(...)`**：那里刚从 `fixed(member).node().spec()` 取到 `NodeSpec`，`spec.stances().cells()` 正是站位数。

**结果**：`Fitness` **一行没动**（少一个 L3 文件），判定点仍在"派活"这一层，且 `Unassigned` 报告天然覆盖（诊断层可直接读）。

**未覆盖**：提案里"规划期就不长活"这一半**没做**（weave 的 `Fitness.anyone` 同样拿不到格子）。当前语义是：**活可能被长出来，但永远派不出去，并以 `ZONE_FORBIDDEN` 报告**。对玩家可见行为而言"居民不会进去"已成立；"不长活"留待 T4b 评估是否需要。

---

## 3. 改动清单

| 文件 | 层 | 内容 |
| --- | --- | --- |
| `core/api/work/Standing.java` | **L1（新）** | `boolean permits(UUID resident, BlockPos cell)`；`Standing ALL` |
| `core/engine/plan/Unassigned.java` | **L3** | 新原因 `ZONE_FORBIDDEN`（注释说明非 structural） |
| `core/engine/plan/Tours.java` | **L3** | 字段 + `standing(...)`；`unfit` 里的逐格判定；`progress()` 补 `ZONE_FORBIDDEN -> 12` |
| `core/engine/plan/Scheduler.java` | **L3** | 字段 + `standing(...)`；`closed()` 重建 `Tours` 后重挂 |
| `core/engine/labor/Pipeline.java` | **L3** | `standing(...)` 转发给 `Scheduler` |
| `core/engine/labor/ColonyLabor.java` | **L3** | `public void standing(Standing)` |

全部带 `// PLA: WP-4 T4` 标记；**没有 `L4`**。

---

## 4. 证据

```
$ ./gradlew build --offline            → BUILD SUCCESSFUL in 16s
$ ./gradlew runGameTestServer --offline
[17:00:03] All 662 required tests passed :)
```

编译期还抓到一个真实问题：`Tours.progress()` 是对 `Unassigned.Reason` 的**穷尽 switch**，加枚举后立刻报 `does not cover all possible input values` —— 说明这条链路没有静默兜底，新增原因必须显式给出排序（已补 `ZONE_FORBIDDEN -> 12`，语义：区域拒绝是"最具体"的理由，最后报告）。

---

## 5. T4b（接线）待做

| # | 项 | 说明 |
| --- | --- | --- |
| 1 | **Provider**：把 `SteeringState` 变成 `Standing` 并装进对应殖民地的 `ColonyLabor` | 需确认插件侧如何取到 `ColonyLabor`（`colony.service(...)` 是否暴露；否则走 core 侧注册表 `Standings`） |
| 2 | **行为测试**：画区 → 区内活报 `ZONE_FORBIDDEN`；删区 → 不报 | 可仿 `DispatchPlanningGameTests`（`new ColonyLabor(new ColonyData(), dim)`） |
| 3 | **LIMIT** 的 `insideCount` | 仍属 T5，不进 `Standing` |
| 4 | 是否要"规划期不长活" | 评估后再定，需改 weave 侧 |
