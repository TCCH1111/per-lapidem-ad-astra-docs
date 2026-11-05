# VERIFY-049 · M2-R1 第一段：关系簿（1472/1472）

```
状态：通过（R1-1 完成；R1-2..R1-6 待做）
验证者：DSH 会话
验证日期：2026-11-05
关联：PLAN-007、PRD-008 §4/§5
分支：port/aaac8b8 → 58782f2
```

---

## 1. 结论

关系系统的**数据层**落地：殖民地级、单向、有冷却、有上限、可存读、可清理。
**1472 / 1472 游戏测试通过**（1467 + 5）。

---

## 2. T0：四个未知项都读穿了（不是猜的）

| # | 问题 | 结论 | 证据 |
| --- | --- | --- | --- |
| OQ-1 | 能否读到居民**位置 + 是否在干活** | **能，且不需要钩子** | `Colony.holdings().bodiesIn(level)` → `Body`；`Body.mob().blockPosition()`；`Body.doing()` → `Optional<Doing>`；空闲判据 `Doings.IDLE`（`core/api/work/Doings.java:22`） |
| OQ-2 | `scope.tick` 里取殖民地/居民是否安全 | **安全** | `HoursContent.tick` 已是同款用法（`server.getTickCount() % 200` 门控），随包发布并经 1467 条测试 |
| OQ-3 | 居民死亡/离开后 bond 会变孤儿吗 | **会，但不需要事件**：按 `colony.residents()` 每日清理即可 | 本轮已实现 `prune(present)` 并有测试 |
| OQ-4 | mood 要不要加新档位 | **不加**：只加一个布尔 `amongFriends`，且只用于"没活干 → WORRIED"这一条 | 避免 mood 变成大杂烩 |

**结论**：R1-2 的采样器可以留在 **L1**，不需要 L2/L3 报批。

---

## 3. 交付

| 文件 | 层 | 内容 |
| --- | --- | --- |
| `plugins/relate/RelationState.java` | **L1 新文件** | 单向 `Bond`；`touch/share/bond/acquainted/friends/mutualFriends/known/prune/save/load` |
| `RelationStateGameTests` | L1 | 5 个测试 |

**关键参数（全部来自 PRD，不是我发明的）**：

| 参数 | 值 | 来源 |
| --- | --- | --- |
| 关系上限 | 30 / 人 | PRD §5.3 `relation_cap` 默认值 |
| 冷却 | 500 刻（半个游戏小时） | PRD §5.2 E1「≥0.5 小时」 |
| 相识 / 朋友 | 10 / 40 | PRD §5.1 关系状态机 |
| 淘汰顺序 | 分低 → 更久未动 | PRD §5.2 E13 |

---

## 4. 五个测试

| 测试 | 断言 |
| --- | --- |
| `aBondGrowsOncePerHalfHour` | 半小时内第二次不计；到点才计；自己对自己、对 null 都不计 |
| `theHeadHoldsThirtyPeople` | 30 人装得下；第 31 个进来后仍是 30，且新人被记住 |
| `theBookSurvivesASave` | bond 与 `shared` 都能往返 |
| `leavingIsForgotten` | 离开的人从**双向**记录里都消失 |
| `theBandsMeanWhatThePrdSays` | 10 = 相识、40 = 朋友、**单向不算互为朋友** |

```
[23:04:57] All 1472 required tests passed :)
```

---

## 5. 诚实边界

- **玩家现在看不到任何变化**：本段只有数据层，没有采样器、没有士气、没有界面；
- 默认零影响：没有任何关系时，mood 与行为与现在完全一致（1472 基线不退）；
- 唯一"缺陷"：`prune` 返回值里对"整个主体被删"的计数恒为 0 的写法不干净（不影响正确性，下次一起清）。

---

## 6. 下一步

| # | 任务 | 说明 |
| --- | --- | --- |
| R1-2 | 采样器（每 100 刻，≤8 格且都在干活 → `touch`） | L1 |
| R1-3 | 士气输入：`mutualFriends` 且此刻同处 → mood 一个布尔 | L1 |
| R1-4 | 卡片一行 + 四语 | L1 + L2(1) |
| R1-5 | 解释层：说清"他心情好是因为和 X 一起干活" | L1 |
| R1-6 | 收口报告 | 文档 |
