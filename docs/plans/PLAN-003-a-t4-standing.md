# PLAN-003 附录 A · T4 落点与 L3 变更提案（`Fitness` 单点否决）

```
状态：待评审（L3 · 未实施）
最后更新：2026-10-24
依据：本轮直读源码（文件:行号在文内）
关联：PLAN-003（T4）、VERIFY-015（T1/T2 已交付）
```

---

## 1. 结论先说

禁限区的"按人"判定有**唯一收口**：`Fitness.of(hand, work)`。

```java
// core/engine/plan/Fitness.java:1-10（类注释原文）
// The plan grows work only for someone fit for it, and the schedule gives work only to whoever is;
// both ask here, so they never disagree.
```

这句话就是设计保证：**规划长活**与**派活**都问 `Fitness`。所以只要在 `Fitness` 里加一条"禁区否决"，区内的活**既不会被长出来、也不会被派出去**，而且两处天然一致。

**这是 L3**（改 `core/engine/plan` 的判定），按 w05 §4 与 R1 需要**单独评审**后才能实施。本文件即评审材料。

---

## 2. 为什么不是别的钩子（已逐个排除）

| 候选 | 排除理由 |
| --- | --- |
| `Refinement` | 输入只有 `Intent` + `Grown`，**没有 `Worker`**（见 PLAN-003 §3）→ 无法按人判断 |
| `Licences` | 按**实体类型**建（`FolkwaysAttachments.licencesFor` 用 `entity.getType()`），表达"这类身体能否做这类活"，不是"这个居民能否去这格" |
| `Claims` | 只表示"某份活已被认领"，与"某格是否允许"无关 |
| 把禁区当 `NO_WAY` | 语义错误：`NO_WAY` 是"找不到路"，会让诊断层给出错误解释；且要动寻路 |
| `ColonyContext.urges` | 只能**增加** urge，不能否决既有 urge |

---

## 3. 提案（最小 L3，可回退）

### 3.1 新增（L1，不改上游）
`core/api/work/Standing.java`：
```java
public interface Standing {
    /** Whether this resident may stand on this cell at all. */
    boolean permits(UUID resident, BlockPos cell);

    Standing ALL = (resident, cell) -> true;   // 默认全放行
}
```

### 3.2 改动（L3，共 4 个文件、约 20 行）
| 文件 | 改动 | 行数量级 |
| --- | --- | --- |
| `core/engine/plan/Fitness.java` | `Unfit` 加 `ZONE_FORBIDDEN`；`of(hand, work, standing)` 在 `NO_LICENCE` 之前判 | +6 |
| `core/engine/plan/Tours.java` | `unfit(...)` 把 `ZONE_FORBIDDEN` 映射到 `Unassigned.Reason.ZONE_FORBIDDEN`（`:1456` 的 switch） | +2 |
| `core/engine/plan/Unassigned.java` | `Reason.ZONE_FORBIDDEN`（不属 structural：区域可被玩家改掉） | +1 |
| `core/engine/plan/Scheduler.java` | 构造时接收 `Standing`（默认 `Standing.ALL`），传给 `Tours` | +4 |
| `core/engine/labor/ColonyLabor.java` | 构造 `Scheduler` 时传入"问 steering 服务"的 `Standing`（未装 steering 时用 `ALL`） | +6 |

### 3.3 为什么这样是"单点"
- 判定只在 `Fitness.of` 一处发生 → 规划与派活不可能给出不同答案（这是上游自己的设计承诺）。
- 否决**不改变**既有 `Unfit` 语义：`BOUND_ELSEWHERE`/`NO_LICENCE`/`NO_TOOL`/`NO_ROOM` 全部保持，新枚举只在区域命中时出现。
- `Standing.ALL` 是默认值 → 不装 steering 插件时**行为完全不变**（回归可证）。

### 3.4 steering 侧（L1）
`SteeringContent` 提供：
```java
static Standing standing(Colony colony) { ... 读 SteeringState，命中 FORBIDDEN/ONLY_FOR_OTHERS 即 false ... }
```
- `LIMIT` 暂不参与 `Standing`（它需要"当前区内人数"，属 T5 的运行时计数，先不做）。
- `SteeringRefusal` 枚举（T5）与 `Unassigned.Reason.ZONE_FORBIDDEN` 一一对应，诊断文案同源。

---

## 4. 验证计划

| # | 证据 | 方式 |
| --- | --- | --- |
| 1 | 不装 steering 时零行为变化 | 现有 662 个 gametest 全过 |
| 2 | 禁入区内的活不被长出 | gametest：画区 → 区内 `Intent` 不产生 `Node` |
| 3 | 禁入区内的活不被派出 | gametest：已有 `Node` 在区内 → `Unassigned(ZONE_FORBIDDEN)` |
| 4 | 移除区域后恢复 | 同一测试里删区 → 重新可选 |
| 5 | 否决可被诊断读取 | `Unassigned` 里出现该 reason，且文案 key 存在 |
| 6 | 性能不退化 | 单测：64 指令 × 120 居民，`applyNanos` 与基线同量级（±20%） |

---

## 5. 风险与回退

| 风险 | 处理 |
| --- | --- |
| L3 改动在季度同步时冲突 | 全部带 `// PLA:`；改动集中在 4 个文件、20 行内；必要时可在同步时整体回退（`Standing.ALL` 等价于没有） |
| `Fitness` 是热路径（每次派活都问） | `Standing` 实现必须 O(1)/O(log n)：`SteeringState` 按格命中（`cells` 集合），不做全量扫描 |
| 区域判定把 `LIMIT` 也塞进来 | 明确不做：`LIMIT` 需运行时人数，属 T5；`Standing` 只表达"能不能站" |
| 玩家在区内已有居民 | 本提案只挡**新派活**；是否强制撤离见 PLAN-003 OQ-4（默认不撤离，等玩家自己调） |

---

## 6. 需要评审拍板的三件事

1. 是否接受在 `Fitness` 加 `ZONE_FORBIDDEN` + `Standing` 参数（**这是 L3**）？
2. `Unassigned.Reason.ZONE_FORBIDDEN` 是否算 **structural**？提案说**不算**（区域是玩家可改的世界状态，不是长活的 bug）。
3. `ColonyLabor` 里"未装 steering 就 `Standing.ALL`"的接法是否可接受（避免核心模块依赖 vanilla 插件）——若不可接受，改为 `Services`/`Contributions` 注册式（多 5 行）。

---

## 7. 若评审否决

替代路径（更弱但不动 L3）：只在 **steering 侧**的输出上做过滤——即插件自己不去提供区内的 urge，并给已派出的活加 `SteeringRefusal`。代价：**已存在的 `Node` 仍可能被派进禁区**，做不到"规划期就不长出来"。可作为 M1 降级方案，但不满足 PRD-005 AC 中"区域必须真正约束行动"的要求。
