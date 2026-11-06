# VERIFY-050 · M2-R1 第二段：采样器（1476/1476）

```
状态：通过（R1-2 完成；R1-3 士气 / R1-4 卡片 / R1-5 解释 待做）
验证者：DSH 会话
验证日期：2026-11-06
关联：PLAN-007、VERIFY-049（数据层）
分支：port/aaac8b8 → e45b55f
```

---

## 1. 结论

关系簿现在**自己会长了**：每 5 秒采一次"谁在干活、站哪"，把 ≤8 格的一对交给关系簿。
**1476 / 1476 通过**（1472 + 4）。

---

## 2. 做法：采样而不是挂钩

| 决定 | 原因 |
| --- | --- |
| **每 100 刻采样**，不做每刻钩子 | 不碰引擎；开销可预估 |
| 规则写成**纯函数** `sample(List<Spot>, book, now)` | 没有殖民地也能测 |
| 居民用 `colony.residents()` + `Bodies.of(entity)` 找 | 这是插件层既有门面（`patrol`/`combat` 都在用），不碰引擎内部 |
| 冷却、上限、淘汰仍由关系簿负责 | 采样只管"谁和谁在一起" |

**"在干活"的判据**：`body.doing()` 存在且 `what != Doings.IDLE`（`core/api/work/Doings.java:22`）。

---

## 3. 交付

| 文件 | 层 | 内容 |
| --- | --- | --- |
| `plugins/relate/RelationContent.java` | **L1 新文件** | `Spot` 记录、纯函数 `sample`、`spotsOf`、`enroll`/`declare`（每 100 刻采样、每 24000 刻清理、每 200 刻存盘） |
| `plugins/relate/RelatePlugin.java` | L1 新文件 | 一个 `install`，挂 `Declaring` + `Registering` |
| `BuiltinPlugins.java` | **L2（1 处）** | 注册 `RelatePlugin` |
| `RelationContentGameTests` | L1 | 4 个测试 |

---

## 4. 四个测试

| 测试 | 断言 |
| --- | --- |
| `workingSideBySideMakesFriends` | 3 格、都在干活 → 记 1 对，**双向**各 +1 |
| `standingApartOrIdleCountsForNothing` | 10 格不算；旁边的人闲着也不算 |
| `samplingTwiceInHalfAnHourCountsOnce` | 同一半小时内第二次采样不再加（冷却在簿里） |
| `aResidentDoesNotBondWithThemselves` | 同一个人出现两次不算一对 |

```
[11:49:35] All 1476 required tests passed :)
```

---

## 5. 诚实边界

- **玩家仍然看不到任何变化**：没有士气、没有卡片行、没有解释——这是 R1-3/4/5；
- 采样开销未实测（≤50 居民时是 O(n²) 的两两比较，每 5 秒一次，预期可忽略；**若后续人口上限提高需重测**）；
- 只在**同一 level** 内比较（跨维度不建立关系），这是有意的简化，写在这里以免被当成 bug。

---

## 6. 下一步

| # | 任务 | 说明 |
| --- | --- | --- |
| R1-3 | 士气：`mutualFriends` 且此刻同处 → mood 多一个布尔输入 | L1 |
| R1-4 | 卡片一行（只在生效时出现）+ 四语 | L1 + L2(1) |
| R1-5 | 解释层：说清"他心情好是因为和 X 一起干活" | L1 |
| R1-6 | 收口 | 文档 |
