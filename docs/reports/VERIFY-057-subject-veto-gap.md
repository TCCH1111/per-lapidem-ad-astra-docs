# VERIFY-057 · 否定结果：`CONFINE` 拦不住派活（引擎的否决权认不出"谁"）

```
状态：**否定结果**（发现设计缺口，未实现补救）
验证者：DSH 会话
验证日期：2026-11-06
关联：VERIFY-056（CONFINE 语义）、design/19（关押接缝）、M3
分支：main @ 3f36389（未改动）
```

---

## 1. 我本来要做什么

上一轮说：给 `CONFINE` 补一条**整链测试**——证明"区域真的能拦住派活"，
而不只是 `verdict` 纯函数返回 `FORBIDDEN`。

**结果：写不出来，因为引擎侧根本没读它。**

---

## 2. 证据（读代码，不是猜）

引擎派活前问的是 `Veto.check(UUID resident, BlockPos cell)`：

```java
public interface Veto {
    Optional<RefusalKind> check(UUID resident, BlockPos cell);
}
```

而 `SteeringContent.standingOf(state)` 这样回答：

```java
return (resident, cell) -> state.forbids(cell) ? … FORBIDDEN : empty;
```

再看 `SteeringState.forbids`：

```java
/**
 * PLA: WP-4 T4b — whether any forbid zone covers this cell. Only FORBID with an empty subject
 * list is consulted here: a resident's trade is not known at this point, so ALLOW_ONLY and LIMIT
 * stay with the diagnosis layer until they can name the subject.
 */
public boolean forbids(BlockPos cell) {
    for (ZoneRule rule : zones.values()) {
        if (rule.kind() == ZoneRule.Kind.FORBID && rule.subjects().isEmpty() && rule.covers(cell)) {
```

**注释本身就把话说清楚了**：主体不在这一步的视野里。

| Kind | 调度层会拦吗 | 诊断层能说吗 |
| --- | --- | --- |
| `FORBID`（空主体） | ✅ 会 | ✅ |
| `FORBID`（指定主体） | ❌ 不会 | ✅ |
| `ALLOW_ONLY` | ❌ 不会 | ✅ |
| `LIMIT` | ❌ 不会 | ✅ |
| **`CONFINE`**（本轮新增） | ❌ **不会** | ✅ |

---

## 3. 这意味着什么

**VERIFY-056 的措辞需要在这里被补正**：`CONFINE` 的**判定语义**是对的、有测试的，
但它在**调度层是惰性的**——一个囚犯**仍然可以被派到牢区外的活**。

我之前说"关押的最后一块原语已落地"，更准确的说法是：

> **关押的判定原语已落地；把它接到调度上，是另一件事，而且还没做。**

---

## 4. 为什么不能顺手接上

要让它生效，`Veto` 需要知道"这个人的身份"（`Resident.kind()`，字段存在）。
但 `Veto.check` 只给 `UUID`，所以 provider 必须自己反查。问题是：

| 问题 | 说明 |
| --- | --- |
| **调用频率** | 否决权在派活时按 (居民 × 格子) 被反复询问；每次线性扫居民列表会明显变慢 |
| **需要缓存** | 得为每个殖民地维护 `UUID → kind` 的映射，并在居民进出时更新 |
| **会改变现有行为** | 一旦接上，`ALLOW_ONLY` / `LIMIT` / 指定主体的 `FORBID` **也会开始真的拦人**——这是行为变更，不只是新功能 |
| **性能预算** | M1 的规划器对每 tick 有预算（d13 §9 同类要求）；这条路径在热区 |

**所以这不是"补一行"，而是"改一条被频繁调用的热路径 + 改变现有拦截语义"。**

---

## 5. 三个选项

| 选项 | 内容 | 代价 |
| --- | --- | --- |
| **A（我倾向）** | 教否决权认人：provider 绑定殖民地，缓存 `UUID→kind`，`forbids` 改为按主体裁决 | L1，但要性能测量；**会让 ALLOW_ONLY/LIMIT 开始生效** |
| B | 保持现状：主体类区域**只用于诊断**，实际拦截交给未来的守卫/押送系统 | 零代价；但"划了牢区却没人被拦住"会让人困惑 |
| C | 区域编辑时**预展开**成格子集合 | 格子数可能爆炸；不宜 |

**需要你拍板的是 A 还是 B**——这不是纯工程问题：A 会让现有（但未生效的）规则突然开始管事。

---

## 6. 本轮产出

| 项 | 内容 |
| --- | --- |
| 代码 | **无改动**（避免把未经确认的语义改到热路径上） |
| 文档 | 本报告；d19 与 ROADMAP 各补一条说明 |
| 债务 | **D20**：主体类区域在调度层惰性 |

---

## 7. 记一条方法论

**如果没有"整链测试"这一步，`CONFINE` 会被当成"关押已就绪"上线**，
而玩家真正遇到的问题是"囚犯照样被派出去砍树"。
纯函数测试证明"规则算得对"，**证明不了"引擎会问这条规则"**。
