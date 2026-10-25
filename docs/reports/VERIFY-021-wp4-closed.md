# VERIFY-021 · WP-4 收口：T7 同源文案（673/673）

```
状态：通过 —— WP-4（禁限区）完成
验证者：DSH 会话
验证日期：2026-10-25
关联：PLAN-003（T7/T8）、VERIFY-020（671 基线）
fork 提交：45b9883
```

---

## 1. 结论

区域行的"为什么"只有一个来源：`SteeringContent.why(Unassigned.Reason)`。引擎报 `ZONE_FORBIDDEN` → 唯一的 `SteeringRefusal.FORBIDDEN`；面板用这个枚举的 key 渲染，不再写第二份文案。

游戏测试：**`All 673 required tests passed`**（671 + 2）。

---

## 2. 交付

| 改动 | 内容 |
| --- | --- |
| `SteeringContent.why(...)` | 引擎 reason → `Optional<RefusalKind>`；只认领 `ZONE_FORBIDDEN`，其余返回空（别人的理由不由我们解释） |
| `SteeringFacing.whyLine()` | 行的说明前缀 = `Component.translatable(SteeringRefusal.FORBIDDEN.translationKey())` |
| `SteeringWhyGameTests` | 2 个测试 |

---

## 3. 一个被证伪的做法（值得记）

第一版测试用 `getResourceAsStream("/assets/folkways/lang/en_us.json")` 检查键是否存在，**实测失败**：

```
en_us is missing folkways.refusal.steering.forbidden
```

原因：lang 资源在 `plaa_core` 的 jar 里，gametest 的类加载路径拿不到（返回空串）。改成**运行时语言表**：

```java
Component.translatable(refusal.translationKey()).getString()   // 不等于 key 即已翻译
```

这才是玩家真实看到的路径，也更难作弊（写错 key 立刻红）。**673/673** 说明三条文案在服务端语言表里都能解析。

---

## 4. WP-4 总账（对照 PLAN-003 验收）

| 判据 | 结果 |
| --- | --- |
| 全量回归 | ✅ 673 个测试全过 |
| 约束真的生效 | ✅ 区内目标派不出去（`Tours.unfit` 返回 `ZONE_FORBIDDEN`），画区即生效 |
| 解释得住 | ✅ 每个被挡候选都有具体 reason，且 reason → 具名 refusal → 现有语言键 |
| 不改引擎契约 | ✅ 只加 `Standing` 否决与一个新枚举值；`Refining.LIMIT` 未动 |
| 面板合规 | ✅ 每行 1 个动作（上限 4），无新增 `Board.Act` 动词 |
| L3 有评审 | ✅ 唯一 L3（`Standing` 管道）已单独评审并批准（PLAN-003-A） |

**WP-4 从 T0 到 T7 全部完成**，T8（登记与 AC 勾选）在本轮一并整理：d12 改动表已含 steering 各行的 L1/L2/L3，AC 勾选在下轮随 WP-5 计划一起做，避免只勾不验。

---

## 5. 遗留（随 WP-4 收口一并转给后续）

| # | 项 | 去向 |
| --- | --- | --- |
| 1 | 采纳时机在"打开书页"而非画完立刻 | WP-6 诊断层接入时一起改（需要 tick 里拿到 level） |
| 2 | 删除区域不清已画格子（用笔画哈希忽略） | 需 `Fronts.of(Colony)`，而 `act()` 只有 `ColonyView` → 记录为 API 缺口 |
| 3 | 一笔画 = 一个区；区名固定 | 多区与命名属 WP-5 之后的体验轮 |
| 4 | `ALLOW_ONLY` / `LIMIT` 未进 `Standing`（拿不到工种） | 等需求层给出 resident→vocation 查询（WP-7 附近） |

---

## 6. 下一步

WP-4 关闭，关键路径进入 **WP-5 作息表**（w05：三段式、默认关闭、显式启用、24h 条带自绘）。下一步先立 `PLAN-004`，并把"作息表与禁限区共享约束层"这件事在计划里写清楚——两者都在回答"这个人什么时候能去哪"。