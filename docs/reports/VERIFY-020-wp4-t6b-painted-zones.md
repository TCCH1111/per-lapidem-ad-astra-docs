# VERIFY-020 · WP-4 / T6b：画出的体积变成禁入区（671/671）

```
状态：通过（T6b 完成；T7 待做）
验证者：DSH 会话
验证日期：2026-10-25
关联：PLAN-003（T6b）、VERIFY-019（668 基线）
fork 提交：1407e96
```

---

## 1. 结论

玩家用基底手势画出的 `steering_zone` 体积，现在会被采纳成**一个禁入区**；在页面上删除它之后，同一笔画**不会**被下一次刷新重新画出来。

游戏测试：**`All 671 required tests passed`**（668 + 新增 3）。

---

## 2. 交付

| 文件 | 改动 |
| --- | --- |
| `SteeringState.java` | `PAINTED` 稳定 id；`adoptPainted(Set<BlockPos>)`；`dismissPainted(Set<BlockPos>)`（按笔画哈希记住"已忽略"） |
| `SteeringFacing.java` | 画面前先 `adoptPainted(colony.blocks(ZONE))`；对 `PAINTED` 行执行 `dismissPainted` 而不是普通 `remove` |
| `SteeringPaintedGameTests.java` | 3 个测试 |

**数据来源**：`ColonyView.blocks(ResourceLocation owner)`——基底注释写明它含 "blocks, areas and lines"，所以画好的区域格可以直接读，不需要 `FrontView`。

---

## 3. 三个测试

| 测试 | 断言 |
| --- | --- |
| `aPaintedVolumeBecomesAForbidZone` | 一画 → 一区、`FORBID`、区内 `forbids` 为真、区外为假 |
| `dismissingIgnoresThatPaintingUntilItChanges` | 删除后不再被同笔画重建；**换一笔画**则重新采纳 |
| `anEmptyPaintingChangesNothing` | 没画 → 无区、不脏 |

---

## 4. 证据

```
$ ./gradlew build --offline            → BUILD SUCCESSFUL in 10s
$ ./gradlew runGameTestServer --offline
[20:10:07] All 671 required tests passed :)
```

本轮**没有命中**那条偶发测试（D7 仍在）。

---

## 5. 已知限制（诚实登记）

| # | 限制 | 原因 |
| --- | --- | --- |
| 1 | 采纳发生在**打开书页**时，不是画完立刻 | `Facing` 只拿到 `ColonyView`；tick 里虽有 `Colony` 但没有 level 参数 |
| 2 | 删除区域**不清除已画格子** | `FrontView.erase(UUID)` 需要 `Colony`（`Fronts.of(Colony)`），而 `act()` 只有 `ColonyView`；当前用"记住笔画哈希、忽略"绕开 |
| 3 | 只支持**一笔画一个区** | 一个委托 id 对应一个区；多区需要多委托或区 id 分配策略（后续） |
| 4 | 区名固定 "steering zone" | `ZoneView` 的 settings 里可能有名字，尚未接 |

---

## 6. WP-4 剩下

| 任务 | 状态 |
| --- | --- |
| T7 `steering why` 与面板同源 | ⬜ |
| T8 登记与 AC 勾选 | ⬜（登记表已随时补行） |

T7 之后 WP-4 收口，即可进入 **WP-5 作息表**（PLAN-004）。