# VERIFY-028 · WP-6 / W3：没人接的活变成一行（692/692）

```
状态：通过（W3 完成；W4–W6 待做）
验证者：DSH 会话
验证日期：2026-10-25
关联：PLAN-005（W3）、VERIFY-027（689 基线）
fork 提交：3cdf8ff
```

---

## 1. 结论

`Explanation.row(Unassigned)` 把一份没人接的活变成**恰好一行**：标题是该原因的标题、细节是建议动作；两个"可修"的附带**一个** `Board.Act.Open` 指向能修它的页面。

因为映射仍只在 `Explanation` 里，**这一行不可能与页面说两套话**。

游戏测试：**`All 692 required tests passed`**（689 + 3）。

---

## 2. 交付

| 改动 | 内容 |
| --- | --- |
| `Explanation.row(...)` | `Line` → `Board.Row`（纸图标、标题、建议、0 或 1 个 `Open`） |
| `ExplanationRowGameTests` | 3 个测试 |

**动作预算**：一行最多 1 个动作（基底上限 4），W3 不新增任何 `Board.Act` 类型。

---

## 3. 三个测试

| 测试 | 断言 |
| --- | --- |
| `aRefusalBecomesOneRowWithItsWords` | 行的标题/细节 = `Explanation.of` 的键经语言表渲染的结果；缺工具**无动作** |
| `theFixableRefusalCarriesOneAct` | 作息拒绝 → **1 个** `Open`，且指向 hours 页 |
| `aPageOfRefusalsStaysWithinTheActBudget` | 三行组一页，每行动作数 ≤ `MAX_ACTS` |

```
./gradlew build --offline   → SUCCESSFUL in 15s
[21:54:57] All 692 required tests passed :)
```

---

## 4. 遗留

| # | 项 | 去向 |
| --- | --- | --- |
| 1 | 还没有**真正的页面**列出这些行（W3 只是造行） | W4/W5 接入；入口位置待定（居民页 vs 新开"没人干的活"页） |
| 2 | "按人问"（`BodyViews.doing` 空 + 最近拒绝） | W4 |
| 3 | 需求类原因仍无法端到端（D9） | W6 覆盖率表如实标注 |