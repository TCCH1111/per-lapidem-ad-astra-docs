# VERIFY-027 · WP-6 / W1–W2：一个地方把拒绝变成人话（689/689）

```
状态：通过（W1、W2 完成；W3–W6 待做）
验证者：DSH 会话
验证日期：2026-10-25
关联：PLAN-005（W1/W2）、VERIFY-026（686 基线）
fork 提交：a82a185
```

---

## 1. 结论

解释层的**词汇表**落地：`Unassigned.Reason` 的**每一个**取值都有标题与建议动作，其中两个"可修"的还带**跳转页面**。玩家读到的每一句都来自同一个函数。

游戏测试：**`All 689 required tests passed`**（686 + 3）。

---

## 2. 交付

| 文件 | 层 | 内容 |
| --- | --- | --- |
| `plugins/explain/Explanation.java` | L1 | `of(Unassigned.Reason) → Line(titleKey, adviceKey, Optional<page>)`；键由原因名推导；两个可修的指到各自页面 |
| 四个语言文件 | L2（各 +30 行） | 14 类 × 标题/建议 + `unknown` 兜底 |
| `ExplanationGameTests` | L1 | 3 个测试 |

**唯一的映射点**：页面（W3/W4）与将来的命令都必须调 `Explanation.of`，这是 WP-4 T7 验证过的"同源"做法。

---

## 3. 计划写 10 类，实际 14 类——测试替我抓到了

PLAN-005 §3.2 的表格列了 10 类。写测试时按 `Unassigned.Reason.values()` 遍历，第一次跑就红：

```
no words for folkways.explain.way_pending.title, got: folkways.explain.way_pending.title
```

漏掉的四类：`WAY_PENDING`、`CLAIM_TAKEN`、`SAME_WORKER_SPLIT`、`WORKER_AWAY`。补齐后 **14/14**。

**为什么会漏**：我按"记忆里的枚举"列表，而不是按**代码里的枚举**列表。测试用 `values()` 遍历，天然不会漏——这正是"把清单写成遍历"的价值。

---

## 4. 三个测试

| 测试 | 断言 |
| --- | --- |
| `everyReasonHasItsOwnWords` | 每个 reason 都有标题与建议；**标题互不重复** |
| `theFixableOnesPointAtTheirPage` | 禁限区 → steering 页；作息 → hours 页；缺工具无页面；`null` → unknown |
| `everyWordResolvesAtRuntime` | 全部键（含 unknown）都能在运行时语言表解析 |

```
./gradlew build --offline   → SUCCESSFUL in 9s
[21:50:24] All 689 required tests passed :)
```

---

## 5. 一次工具中断的处置

本轮中途有一次工具调用被中断、结果未知。我**没有直接重跑**，而是先核对：

- 测试文件与主代码都存在（83 行 / 前者）；
- `git status` 显示 4 个 lang 文件已改、两个新目录未跟踪。

确认"写入已发生、构建未确认"后才重跑构建（构建是幂等的）。这条记在这里，因为"盲目重试"在有副作用的操作上很容易制造重复提交。

---

## 6. 遗留

| # | 项 | 去向 |
| --- | --- | --- |
| 1 | 还没有页面消费这些文案（W3/W4） | 下一轮 |
| 2 | 需求类原因无法端到端（D9） | WP-6 W6 覆盖率表如实标注 |
| 3 | `WAY_PENDING` / `WORKER_AWAY` 等是否都值得给玩家看，需要玩法评审 | W6 时按"是否会误导"筛一遍 |