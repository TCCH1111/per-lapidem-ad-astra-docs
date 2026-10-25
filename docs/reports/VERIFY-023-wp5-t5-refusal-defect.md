# VERIFY-023 · WP-5 / T5：作息的具名理由（681/681）＋一个被发现的真实缺陷

```
状态：词表完成；接线被缺陷挡住（记为 D8）
验证者：DSH 会话
验证日期：2026-10-25
关联：PLAN-004（T5）、VERIFY-022（679 基线）
fork 提交：9110999
```

---

## 1. 交付

| 文件 | 层 | 内容 |
| --- | --- | --- |
| `plugins/hours/HoursRefusal.java` | L1 | `RESTING`；`lasting() = false`（钟会自己转回来，等就行） |
| 四个语言文件 | L2（各 +1 行） | `folkways.refusal.hours.resting`，四语齐全，JSON 均已重新解析验证 |
| `HoursRefusalGameTests` | L1 | 2 个测试：键名形状 + `lasting`；**运行时语言表**解析 |

```
./gradlew build --offline   → BUILD SUCCESSFUL in 13s
[20:55:13] All 681 required tests passed :)   // 679 + 2
```

---

## 2. 本轮发现的真实缺陷（D8）

作息的否决与禁区共用 `Standing`，而它只回答 **是/否**：

```java
boolean permits(UUID resident, BlockPos cell);
```

于是"现在不是工作时段"被引擎记成 `Unassigned.Reason.ZONE_FORBIDDEN`——**玩家会看到"禁限区禁止进入此处"，而不是"现在不在工作时段"**。词表（本轮）已经准备好，但**接不上**，因为接口不带原因。

### 三个可选修法

| 方案 | 层 | 代价 | 评价 |
| --- | --- | --- | --- |
| **A：`Standing` 返回 `Optional<RefusalKind>`** | L3 | 改接口 + `Tours.unfit` 取原因 + 两个 provider 各自给出理由 | **推荐**：一次到位，诊断永远说真话；与已批准的"给 Standing 加维度"是同一处、同一性质 |
| B：`Standing` 加 `reasonFor(resident, cell)` 默认方法 | L3 | 更小，但两个方法可能不一致 | 次选 |
| C：插件侧旁路（`HoursContent.lastRefusal`） | L1 | 不改 core，但诊断要去问插件，职责倒置 | 不推荐，只作为临时 |

**本轮没有擅自实施 A**——它是新的 L3，按规矩要单独评审（上一轮批准的 L3 是"加时间参数"，不是"改返回类型"，不能混用）。

---

## 3. 为什么值得为这个缺陷停下来

如果就这么发布，玩家会看到**自相矛盾的提示**：画了禁限区的地方说"禁入"，没画区只是到了晚上也说"禁入"。解释层是 M1 的卖点（w05：没有解释层的 M1 不值得演示），**理由说错比没有理由更糟**——它教玩家不信任提示。

---

## 4. 状态

| 项 | 状态 |
| --- | --- |
| WP-5 T0/T1（预设 + 闸） | ✅ VERIFY-022 |
| WP-5 T5 词表 | ✅ 本轮 |
| WP-5 T5 接线 | ⛔ 等 D8 的 L3 评审 |
| WP-5 T4（UI：Flag + Choice） | ⬜ 下一轮可直接做，不受 D8 阻塞 |