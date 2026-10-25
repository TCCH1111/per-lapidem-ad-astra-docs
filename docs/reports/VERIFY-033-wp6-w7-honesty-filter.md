# VERIFY-033 · WP-6 / W7 第二轮：三次造不出来 → 改为"没证据的就不说"

```
状态：通过（产品行为改变，696/696）
验证者：DSH 会话
验证日期：2026-10-25
关联：VERIFY-031（覆盖率）、VERIFY-032（首轮否定）
fork 提交：046a490（推送待网络恢复）
```

---

## 1. 三次尝试，全部为空

| # | 做法 | `unassigned` |
| --- | --- | --- |
| 1 | 静态不合适（空 licences / pack=0） | `[]` |
| 2 | 给合适的人长出活，再让**同一个人**变不合适 | `[]`（`keeping()` 会跳过已在路线上的活） |
| 3 | 给合适的人长出活，再让**陌生居民**（新 UUID）排 | `[]` |

第 3 次排除了"同一 id 被跳过"这一解释，指向真正原因：

- **调度只汇报它这一轮重新决策过的活**（增量语义）；
- **织造阶段不为"从来就不合适的人"生长活**（`Fitness` 的设计承诺）。

两者叠加：`NO_LICENCE`/`PACK_FULL` 在"运输 + 本夹具"这条路上**造不出来**。

---

## 2. 于是改了产品行为

既然造不出来，就不该对玩家**言之凿凿**。新增：

```java
Explanation.shown(reason)   // 只有 5 类带证据的原因返回 true
Explanation.row(nobody)     // 改为 Optional<Board.Row>，未证实的原因返回 empty
```

**会被显示（5 类）**：
`ZONE_FORBIDDEN`（我们端到端）、`HOURS_RESTING`（映射+注册）、`NO_WAY`、`WAY_PENDING`、`SAME_WORKER_SPLIT`（上游测试提及）。

**保持沉默（9 类）**：其余全部——包括 `NO_LICENCE`、`PACK_FULL`、`NO_FREE_HAND`、`CLAIM_TAKEN`、`WORKER_AWAY`、`NO_FREE_STAND`、`BEYOND_HORIZON`、`PACK_BUSY`、`NO_TOOL`。

这不是删代码：文案、`Explanation.of` 映射都还在，只是**不往玩家眼前推**。等哪天补出证据，把类名加进 `shown` 的 switch 即可。

---

## 3. 三个新测试

| 测试 | 断言 |
| --- | --- |
| `theProvenReasonsAreShown` | 5 类有证据的：`shown == true` 且能生成行 |
| `theUnprovenReasonsAreSilent` | 抽查 4 类未证实：`shown == false` 且**生成不出行** |
| `aNamelessReasonIsSilent` | `null` 原因同样沉默 |

```
./gradlew build --offline   → SUCCESSFUL in 11s
[22:47:25] All 696 required tests passed 🙂   → 696（693 + 3）
```

---

## 4. 与 w05 验收的关系（要说清）

w05 要求"≥8 类阻塞可解释"。现在**真正会对玩家说话的是 5 类**。

这句话必须写下来：**我们不再声称满足那一条**。要么补证据把数量提上去（W7 续，需要另一条数据路径），要么承认 M1 的解释层覆盖小于 PRD 设想。

我倾向后者当下如实登记，前者作为后续工作——而不是把 9 条没证据的文案算进"已覆盖"。

---

## 5. 下一步（W7 续的可行方向）

1. 读 `Survey` / `Requests` 里 `Unassigned.Reason` 的**其它构造点**（目前只找到 `Tours:1458` 一处映射）；
2. 若确认这些原因只出现在生产路径的特定分支，改用 `ColonyLabor` 的只读 unassigned 出口（需要 L2 暴露）；
3. 在那之前，5 类是诚实的上限。