# VERIFY-062 · M2 R0 收口：重伤 → 一条 reservation（1498/1498）

```
状态：通过（R0 全部完成；调度是否承认 reservation 仍记为未证）
验证者：DSH 会话
验证日期：2026-11-06
关联：PLAN-009、VERIFY-060/061、Urge 契约
分支：main @ 2d25a51
```

---

## 1. 这一轮解决的是"接线有没有被证明"

VERIFY-060 留的问题是：*`severe` 真的会变成"不被派活"吗？*

上一轮卡片证明了健康簿**是活的**，但没证明**劳动系统会读它**。
本轮把贡献抽成纯函数并测：

```java
static List<Urge> restriction(boolean resting) {
    return resting
        ? List.of(Urge.reserve(HealthContent.RESTING))
        : List.of();
}
```

`urges()` 现在是 `felt.addAll(restriction(resting(...)))`——**只有一个调用点**。

---

## 2. 两个测试

| 测试 | 断言 |
| --- | --- |
| `aHurtBodyAsksForNothingExtraWhenItIsOnlyLightlyHurt` | 轻伤 → 贡献**为空**（口径 C：照常） |
| `aHurtBodyReservesItselfAgainstPlannedWork` | 重伤 → **恰好一条**，且 `reservation() == true`、id 是 `folkways:resting` |

```
[21:49:29] All 1498 required tests passed :)   // 1496 + 2
```

---

## 3. 仍然没证的那一句（照写）

> **一个活着的殖民地，调度器会不会真的因为这条 reservation 而不派活？**

**没有端到端测试证明它**（→ 已于 [VERIFY-065](VERIFY-065-work-stop-end-to-end.md) 补上：真实殖民地会返回该 reservation）。 我能说的是：

- `Urge.reserve` 的**上游契约**写明 "excludes planned labour, while personal urges still use the runner"；
- 我们的贡献**恰好**是这种形状（`reservation() == true`）；
- 我们这一侧的决策**有测试**（轻伤空、重伤一条）。

**这不是"引擎已验证"，而是"我们按契约的形状交付，且我们的形状有测试"。** 区别要留在这里。

---

## 4. R0-5 解释层：为什么没有新增代码

原本计划"让玩家看到为什么他不去干活"。实际检查后发现：
**一条 reservation 不产生 `Unassigned.Reason`**（它排除计划劳动，而不是让某次派活失败），
所以解释层**没有可映射的东西**。

现在的解释就是卡片那两行：

```
「伤得太重，暂时不接活」
「把急活交给别人」
```

**不再为解释层新造 `Unassigned.Reason`**——那会为了"有东西可显示"而发明一个不存在的事件。

---

## 5. R0 全景

| 段 | 内容 | 证据 |
| --- | --- | --- |
| R0-1 | 伤口数据（部位/伤型/严重度/来源/时间） | VERIFY-055 |
| R0-2 | 流血结算 + 存盘 | VERIFY-055 |
| R0-3 | 重伤判定 + reservation | VERIFY-060/062 |
| R0-4 | 卡片两行（仅重伤） | VERIFY-061 |
| R0-5 | 解释层（结论：卡片即解释，不新增原因） | 本文件 |

**1498 / 1498。**

---

## 6. 诚实边界

| 项 | 状态 |
| --- | --- |
| 玩家能看见 | ✅ 卡片两行 |
| 玩家能做什么 | 把急活交给别人 |
| 治疗/感染/死亡 | ❌ 不存在（R1） |
| 调度器是否真的停派活 | ⬜ 未证（契约层面成立） |
| 客户端看过吗 | ⬜ 未看（D11） |

---

## 7. 下一步：R1（PRD-013 的 R-MED-5 要求完整链路）

| 内容 | 需要你 |
| --- | --- |
| 感染 → 发烧 → 死亡（"康复或死亡"闭环） | **死亡处理是否进 M2**（Q3，之前问过未答） |
| 包扎/治疗（医生、绷带、病房） | R-MED-8 要求三者各自可测，需先定"药品从哪来" |

**R1 会第一次让殖民地里死人**——这是玩法尺度问题，我不擅自决定。
