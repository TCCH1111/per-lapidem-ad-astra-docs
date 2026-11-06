# VERIFY-060 · M2 R0-3：重伤者不被派活（口径 C，1495/1495）

```
状态：通过（判定与接线；**接线未做端到端测试**）
验证者：DSH 会话
验证日期：2026-11-06
关联：PLAN-009、PRD-013（R-MED-7）、用户口径 **C**
分支：main @ 5304838
```

---

## 1. 你的口径（已落实）

> **C：轻伤照常、重伤停下**

| 情形 | 行为 |
| --- | --- |
| 轻伤（severity ≤ 3 且血够） | **完全照常**：不减速、不停工 |
| **重伤**（severity ≥ 4 **或** 血 < 40%） | **不被派计划劳动**（仍能吃饭、睡觉） |

**注意**：C 不要求减速，所以**没有加移动速度惩罚**——轻伤"照常"就是字面意思。

---

## 2. 关键发现：引擎已有现成机制，不需要改调度

`Urge.reserve(id)` 的注释写得正是这件事：

> *A passive controller reservation: **excludes planned labour**, while personal urges still use the runner.*

于是：

```java
if (HealthContent.resting(colony, who)) {
    felt.add(Urge.reserve(HealthContent.RESTING));
}
```

**没有动引擎、没有新尊重排班逻辑**——这比"在调度里加 if"安全得多。

**而且它天然满足生存底线**：`reserve` 只排除**计划劳动**，吃饭与睡觉仍由 runner 处理。否则"重伤停工"会变成"重伤饿死"。

---

## 3. 判定写在一处

```java
public static final int SEVERE_SEVERITY = 4;
public static final double SEVERE_BLOOD_FRACTION = 0.4;
```

两个数字放在 `HealthState`，将来调平衡只改这里。

---

## 4. 测试

| 测试 | 断言 |
| --- | --- |
| `severityDecidesWhoStopsWork` | 割破手指（1）**不算**重伤；深裂伤（4）算 |
| `bloodAloneCanMakeSomebodySevere` | 小伤口但血被放干 → **仍算重伤** |
| `anUnwoundedResidentIsNeverSevere` | 无伤、满血 → 不受限 |

```
[21:20:22] All 1495 required tests passed :)   // 1492 + 3
```

---

## 5. 诚实边界（这一节比上面重要）

| 项 | 状态 |
| --- | --- |
| "重伤"判定 | ✅ 3 个测试覆盖 |
| **判定真的会变成"不被派活"吗** | ❌ **没有端到端测试** |
| 玩家能看到"他在养伤"吗 | ❌ 卡片没有这一行（R0-4 未做） |
| 在游戏里验过吗 | ⬜ 没有 |

**这正是上次 `CONFINE` 的同一个坑**：我证明了"规则算得对"，但**没证明"引擎会问这条规则"**。
`urges()` 的接线需要真实殖民地夹具，本轮没搭。

**所以这一条必须记成未验证，而不是"完成"**：重伤者是否真的停下，要等 R0-4 的卡片或 D11 实测一起验。

---

## 6. 下一步

| # | 内容 | 能否现在做 |
| --- | --- | --- |
| R0-4 | 卡片一行（「Deep gash，在养伤」+ 建议） | ✅ 无决策 |
| R0-5 | 解释层（"他为什么不去干活"） | ✅ 无决策 |
| **接线测试** | 找/搭殖民地夹具，断言 `urges()` 含 reservation | 需要时间（可做） |
| R1 | 感染 → 发烧 → 死亡（R-MED-5 完整链路） | 需要口径（死亡处理是否进 M2） |
