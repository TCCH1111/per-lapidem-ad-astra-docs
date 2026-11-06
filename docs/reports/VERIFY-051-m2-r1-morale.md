# VERIFY-051 · M2-R1 第三段：陪伴即有意义（1477/1477）

```
状态：通过（R1-3 完成；R1-4 卡片 / R1-5 解释 待做）
验证者：DSH 会话
验证日期：2026-11-06
关联：PLAN-007、PRD-008、VERIFY-049/050
分支：port/aaac8b8 → cb5a659
```

---

## 1. 结论

关系第一次**产生影响**：有朋友在旁边干活时，居民**不会因为暂时没活而发愁**。
**1477 / 1477 通过**（1476 + 1）。

---

## 2. 只做一件事的布尔

| 项 | 决定 | 理由 |
| --- | --- | --- |
| 形状 | `Mood.Needs` 多一个 `amongFriends` | 不加新档位（OQ-4 的结论） |
| 作用面 | **只压**"没活干 → `WORRIED`"这一条 | 最小可感变化，不动其它规则 |
| 不能做什么 | 压不住紧急饥饿、也压不住四分之一饱 | 陪伴不是饱腹，**不许冒充需求** |
| 数据来源 | 采样器缓存"谁在谁旁边"（每 5 秒刷新） | 卡片随时会被打开，不能去看整个世界 |

---

## 3. 交付

| 文件 | 层 | 改动 |
| --- | --- | --- |
| `Mood.java` | L1 | `Needs` 加 `amongFriends`；`of()` 里只用于最后一条判断 |
| `LivingPresence.java` | **L2** | `needsOf(resident, amongFriends)` 签名扩展（1 处调用） |
| `PresenceViews.java` | L1 | `mood(...)` 传入 `RelationContent.amongFriends(...)` |
| `RelationContent.java` | L1 | 新增 `BESIDE` 快照、`amongFriends(colony, who)`、`beside(spots)`、`closed` 清理 |
| 两个测试文件 | L1 | 构造点更新 + 新增 `companyIsWorthSomething` |

---

## 4. 测试

| 测试 | 断言 |
| --- | --- |
| `companyIsWorthSomething` | 没活干且独自 → `WORRIED`；没活干但朋友在旁 → **`CONTENT`** |
| 同上（反面） | **紧急饥饿 + 朋友在旁 → 仍是 `DESPERATE`**（陪伴不能掩盖需求） |
| 既有 5 个 mood 测试 | 全部保持通过（默认 `amongFriends=false`，行为不变） |

```
[12:07:11] All 1477 required tests passed :)
```

---

## 5. 诚实边界

- **界面上还看不到**：卡片与解释是 R1-4/R1-5；
- `amongFriends` 目前**只影响 mood 的最后一档判断**；它不改变 mood 的其它输入，也不影响行为；
- 快照在**同一维度**内建立（与采样一致），跨维度不生效。

---

## 6. 下一步

| # | 任务 |
| --- | --- |
| R1-4 | 卡片一行（只在生效时出现）+ 四语文案 |
| R1-5 | 解释层：说清"他心情好是因为和 X 一起干活" |
| R1-6 | 收口 |
