# VERIFY-030 · WP-6 / W5：否决真的让人不接活（693/693）

```
状态：通过（W5 完成；W4/W6 待做）
验证者：DSH 会话
验证日期：2026-10-25
关联：PLAN-005（W5）、VERIFY-029（调查）
fork 提交：1095d57（推送待网络恢复）
```

---

## 1. 结论

现在有**端到端证据**：真实求解器 + 真实运输目标 + 一个"全格否决"的 `Standing`，活**留在 `unassigned` 里，理由是 `ZONE_FORBIDDEN`**，而不是被派出去。

游戏测试：**`All 693 required tests passed`**（692 + 1）。

---

## 2. 怎么做到的

| 改动 | 层 | 内容 |
| --- | --- | --- |
| `Solving.standing(Standing)` | **测试代码 L1** | 把否决交给夹具自己的 `Scheduler`；**生产代码一行未动** |
| `StandingVetoGameTests` | **测试代码 L1** | 造三堆面包 + 一个运输目标，全格否决，断言 `laid().unassigned()` 里有 `ZONE_FORBIDDEN`、且**没有** `NO_WAY` |

测试内的 `TestRefusal` 用 `RefusalKind.Named`（枚举自动拼 key），因此 **core 模块不必依赖 vanilla 的 `SteeringRefusal`**。

---

## 3. 两次假失败，都是我的问题

| 现象 | 真因 | 修法 |
| --- | --- | --- |
| 第一次：断言失败，`got []` | **场景搭错**：三个货堆没有 `stands.container(...)` 注册站位 → 活根本没长出来 | 照 `StandingPlanGameTests.Scene.of` 补齐 `Stands` |
| 编译失败：`TestRefusal is not abstract` | `RefusalKind` 要求 `translationKey()` | 改成 `RefusalKind.Named`（枚举自动派生） |

**`got []` 那一刻我怀疑的是产品缺陷**（"禁区只改标签、不真拦人"）。查了 `Tours` 的两处判定（`:541` `holds`、`:740` 插队），两处都调 `groupRefusal`，逻辑上会拦；补齐场景后一次通过。**记录这段，是因为"先怀疑产品、后发现自己搭错场景"是很容易冤枉自己代码的路径。**

---

## 4. 证据

```
./gradlew build --offline   → SUCCESSFUL in 11s
[22:12:15] All 693 required tests passed :)
```

---

## 5. 遗留

| # | 项 | 去向 |
| --- | --- | --- |
| 1 | 只测了"全格否决"这一种，未测"只否决目标格" | 可选加强；当前证据已足够证明闸生效 |
| 2 | 作息（`HOURS_RESTING`）走同一闸，但端到端未单独测 | 同一机制，风险低；W6 覆盖率表标注 |
| 3 | 网络不通，fork 与 docs 各有一个提交待推 | 下轮先推 |