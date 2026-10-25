# VERIFY-024 · WP-5 / D8 修复：拒绝会说明"是谁拒绝的"（684/684）

```
状态：通过 —— D8 关闭
验证者：DSH 会话
验证日期：2026-10-25
关联：VERIFY-023（缺陷发现）、PLAN-004
fork 提交：a319960
```

---

## 1. 结论

`Standing` 从"是/否"改成"**拒绝 + 拒绝者的理由**"，于是：

| 情形 | 修复前的说法 | 修复后的说法 |
| --- | --- | --- |
| 画了禁入区 | 禁限区禁止进入此处 | **禁限区禁止进入此处** ✓ |
| 没画区，只是到了休息时段 | 禁限区禁止进入此处 ✗ | **现在不在殖民地的作息工作时段内** ✓ |

游戏测试：**`All 684 required tests passed`**（681 + 3）。

---

## 2. 为什么不能直接把 `RefusalKind` 塞进 `Unassigned`

本轮实测发现一个结构性限制（上一轮估"20 行"时没看到）：

```java
// Tours 对拒绝原因做按 ordinal 的字节缓存
byte[] known = fits.computeIfAbsent(id, key -> new byte[seats.size()]);
known[seat.slot] = (byte) (why == null ? 1 : why.ordinal() + 2);
```

原因必须是**枚举值**，否则这条缓存（每个 hand × 每份活的"适合度"）就得推倒重来。

**解决**：让 `RefusalKind` 在**注册时就绑定**它对应的 `Unassigned.Reason`：

```java
Standings.provide(owner, provider, refusedAs /*RefusalKind*/, reason /*Unassigned.Reason*/);
Standings.reasonOf(why)  // why.getClass() → 注册时那条 reason
```

于是组合后的 `Standing.check` 返回 `Optional<RefusalKind>`，`Tours` 拿到后立刻换成枚举——**缓存结构一行没改**。

---

## 3. 改动

| 文件 | 层 | 内容 |
| --- | --- | --- |
| `core/api/work/Standing.java` | L1（我们的文件） | `Optional<RefusalKind> check(...)`；`permits` 变默认方法；`ALL` 空拒绝 |
| `core/api/work/Standings.java` | L1 | 注册时带 `refusedAs` + `reason`；`reasonOf` 映射；组合时取**第一个**拒绝 |
| `core/engine/plan/Unassigned.java` | L3 | 新原因 `HOURS_RESTING`（非 structural：钟会自己转回来） |
| `core/engine/plan/Tours.java` | L3 | 用 `check` + `reasonOf`；`progress()` 补 `HOURS_RESTING -> 13` |
| `plugins/steering/SteeringContent.java` | L1 | provider 改为返回 `Optional.of(SteeringRefusal.FORBIDDEN)` |
| `plugins/hours/HoursContent.java` | L1 | provider 改为返回 `Optional.of(HoursRefusal.RESTING)` |

---

## 4. 三个测试

| 测试 | 断言 |
| --- | --- |
| `theScheduleReportsTheReasonTheOwnerSpokeWith` | 作息拒绝 → `reasonOf` = `HOURS_RESTING`（不是 `ZONE_FORBIDDEN`） |
| `twoProvidersStackAndTheFirstRefusalWins` | 两个 provider 叠加；拒绝者是谁就报谁 |
| `anUnregisteredRefusalFallsBackToTheZoneReason` | 未注册时回退到 `ZONE_FORBIDDEN`（有兜底，不崩） |

```
./gradlew build --offline   → SUCCESSFUL in 16s
[21:06:58] All 684 required tests passed :)
```

---

## 5. 说明

- 这次是对**已批准 L3 的忠实实施**（你上一轮批准的方向），但因发现缓存限制而**换了实现形状**；形状变化已写在本报告 §2，供以后复查。
- 回退极简：把 provider 的 `refusedAs/reason` 都传 null，行为等价于旧版"只回答是否"。

---

## 6. 下一步

D8 关闭，回到 **T4：面板**（`Flag` + `Choice` 挂到既有页面），作息即可由玩家开关与选班次。