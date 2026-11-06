# 17 · 气体接口预埋（M3 的接缝，不是气体系统）

```
状态：设计（预埋契约）
负责人：规划者（agent）
最后更新：2026-11-06
上游依据：design/13-gases-pollution-and-cycles.md（模型与数值）、prd/PRD-014-atmosphere-and-pollution.md
前提：**本文件不实现气体**；它定义"以后实现气体时，哪些地方不需要重写"
```

---

## 1. 为什么现在做接缝

气体要在 M3 末期才做（d13 §10 的 Spike 排在 M3 末尾）。但如果 M3 的建筑、能源、居民行为都假定"空气永远无害"，
等气体进来时就要回头改一大片。

**预埋的目标**：让 M3 期间写的代码**只通过一个只读接缝**回答"这里的空气行不行"，而这个接缝在没有气体系统时
**恒定返回"干净"**。这样：

- M3 现在就能写下正确的调用；
- 气体实装时只换实现，不改调用方；
- 默认零影响（项目的硬规矩）。

---

## 2. 契约（只读，三个问题）

```java
/** 某个位置在这一刻的呼吸条件。没有气体系统时，永远是 CLEAN。 */
public record Air(boolean breathable, boolean toxic, Optional<ResourceLocation> because) {
    public static final Air CLEAN = new Air(true, false, Optional.empty());
}

public interface GasViews {
    /** 这一格现在的空气；没有气体系统时返回 CLEAN。 */
    Air airAt(ServerLevel level, BlockPos cell);

    /** 这名居民此刻所在位置的空气；找不到居民时返回 CLEAN。 */
    default Air airOf(ServerLevel level, UUID resident) { ... }
}
```

**三条约束**：

| 约束 | 原因 |
| --- | --- |
| **只读** | 规划器与卡片都会频繁调用，写操作会在错误线程上出问题 |
| **不可为 null** | 调用方不该写 `if (air != null)`；"没有系统"由 `CLEAN` 表达 |
| **不做单位换算** | 浓度、分压、温度都不进这个接口；需要时另开 `GasDetail`（M3 末期再定） |

---

## 3. 谁来问（消费者清单）

| 消费者 | 问什么 | 现在写还是以后写 |
| --- | --- | --- |
| **工作资格** | 这一格能不能干活 | **现在**（见 §4） |
| 医疗（PRD-013） | 窒息/中毒 | M3 末期 |
| 心情（PRD-001） | 空气难闻 → 掉心情 | M3 末期 |
| 诊断界面（PRD-006） | "为什么没人来干这活" | M3 末期（复用 `Explanation`） |
| 气体机器（风机/过滤） | 这个房间的浓度 | 与气体系统一起 |

---

## 4. 关键决定：工作资格**复用已有的否决权**

气体最直接的影响是"这一格有毒，别去"。
我们**已经在 M1 建好了那条管道**：`Vetoes.provide(owner, provider, refusal, reason)` + `Veto.check(resident, cell)`，
并由 `Tours` 在派活前询问（VERIFY-016/017）。

所以气体**不需要新的引擎钩子**：

```java
// 气体实装时，只需这样注册（示意，非本轮代码）
Vetoes.provide(GasContent.ID,
    colony -> (resident, cell) -> GasViews.airAt(level, cell).breathable()
        ? Optional.empty() : Optional.of(GasRefusal.UNBREATHABLE),
    GasRefusal.UNBREATHABLE,
    Unassigned.Reason.NO_WAY);   // 或新增 Gas 专用 reason，届时评估
```

**这带来的好处**：

- 拒绝理由自然进入我们已有的解释层（"空气不能呼吸"）与卡片；
- `Unassigned.Reason` 不需要为气体新增值（先用 `NO_WAY` 或后续评估新值）；
- 排班的"重叠否决"逻辑（多个 provider 组合）已经存在（`Vetoes.of` 组合所有 provider）。

**因此预埋真正要做的事只有一件**：M3 期间任何"这格能不能干活"的判断，都写成
**"向 Vetoes 注册/询问"**，而不是写成 `if (building.isToxic())` 这类硬编码。

---

## 5. 明确不做（防止 scope 蔓延）

| 不做 | 为什么 |
| --- | --- |
| 浓度仿真、分区池、扩散 | d13 §2 选的模型，属 M3 末期 Spike |
| 温度场 | d13 §13 已列为未验证项 |
| 存档格式 | PRD-014 §10 已有草案，等实现时定 |
| 玩家可见的仪表 | 需要浓度数据，现在没有 |
| 任何 `GasViews` 的实现类 | 现在只定义契约；实现由气体系统带来 |

---

## 6. 验收（M3 期间）

| 判据 | 怎么验 |
| --- | --- |
| M3 代码里没有"空气永远无害"的硬编码 | 搜 `breathable` / `toxic` 只出现在契约与调用点 |
| 没有气体系统时行为零变化 | 既有 1482 条测试不退；`Air.CLEAN` 是默认 |
| 气体实装时不需要改引擎 | 注册一个 provider 即可生效——**到那时用测试证明**，现在只能证明"接缝形状允许" |

---

## 7. 开放问题

| 编号 | 问题 | 何时定 |
| --- | --- | --- |
| OQ-G1 | 气体拒绝要不要自己的 `Unassigned.Reason`？ | 气体 Spike 时（会动枚举，需评估 byte cache 兼容） |
| OQ-G2 | 居民在毒气里是"拒绝去"还是"去了会中毒"（或两者）？ | 决定是否需要第二个接缝（健康侧） |
| OQ-G3 | 多个气体 provider 的组合语义（现有 `Vetoes.of` 是"任一拒绝即拒绝"）够不够？ | 同上 |

---

## 8. 与既有工作的关系

| 已有 | 复用方式 |
| --- | --- |
| `Vetoes` / `Veto`（M1-L3，VERIFY-016/017） | 气体"不能在这干活"直接注册为 provider |
| `Explanation`（M1-WP6） | 拒绝理由自动变成人话 |
| `Facing.lookLines`（M2-N6） | 卡片可加"这里空气不好" |
| `StandingsReasonGameTests` 等 | 组合语义已有测试，气体 provider 可照抄模式 |
