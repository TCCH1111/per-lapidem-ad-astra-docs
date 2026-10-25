# PLAN-004 · M1-WP5：作息表（什么时候干活）

```
状态：计划中（待派单）
负责人：规划者（agent）
最后更新：2026-10-25
上游依据：docs/workflow/05-m1-task-breakdown.md §4 WP-5；docs/prd/PRD-005-intent-and-micro-control.md
工作树：WSL `~/pla/mod`（main @ 45b9883）；构建 NeoForge 21.1.233（`--offline` 可用）
```

---

## 1. 一句话目标

让玩家能给殖民地**排作息**（默认关闭，显式开启）：到了休息时段居民停止接活回家，到了工作时段恢复。第一版只做**殖民地层面的三段式**，不做每人一张表。

**图层**：**L1 为主**；若必须新增 `Schema.Setting` 的"时段"类型 → **L3 待评审**。

---

## 2. T0 已核实的契约（这轮实读，不是猜）

| 事实 | 位置 | 影响 |
| --- | --- | --- |
| `plan/Schedule.java` **不是作息表** | `core/engine/plan/Schedule.java`（仅 `tours` + `unassigned`） | 基底的 "schedule" 指**派活结果**，与"作息"无关，名字易混 |
| `Schema.Setting` 只有四种 | `front/api/Schema.java:40-58`：`Flag`、`Count`、`Choice`、`Items` | **没有"时段/一周条带"类型**；自绘 24h 条带 = 新类型 = **L3** |
| 已有的时间来源 | `LivingPresence` 用 `Rest`/`Watermark` 表达疲劳；`ServerLevel.dayTime()` 可用 | 作息判定应当基于 `dayTime`（世界时间），不是真实时钟 |
| 派活的唯一收口 | `Tours.unfit(...)`（WP-4 已在此加了 `Standing`） | 时段判定若放这里，与禁区共用一条路径；但它**没有时间参数** → 需扩展 |

**T0 结论（2026-10-25，已实读）**：`ColonyWorks.urges(...)` 把**每个 scope 的每个来源直接拼接**（`felt.add(...)`，无过滤、无否决权），因此 **A 路线（休息时段"接管为空"）不成立**——插件只能往上加，不能压别人。A 作废，改走 **B**。

**结论（改后，按代价排序）**：

1. **A（推荐，纯 L1）**：作息以 `Schema.Setting.Choice` 的**预设**表达（`free` / `day_shift` / `night_shift` / `siege`），插件在 `ColonyContext.urges` 里"休息时段不提供工作"。**零 core 改动**。
2. **B（L3）**：把 `Standing` 扩成 `permits(resident, cell, tick)`，时段判定进 `Tours.unfit`。语义最正（与禁区同源），但要再走一次 L3 评审。
3. **C（L3）**：新增 `Schema.Setting.Hours`，支持逐小时编辑与自绘条带。玩家体验最好，工作量最大。

**本计划做 B**（`Standing` 加时间维度，一次 L3 评审），C 留到体验轮（w05 把它列在"时段设置类型"里，属预期内）。

---

## 3. 设计（A 路线）

### 3.1 数据
```
HoursState {
  enabled: boolean          // 默认 false，显式开启
  preset:  FREE | DAY_SHIFT | NIGHT_SHIFT | SIEGE
}
```
- 存在新插件 `plugins/hours`，用 `colony.keep(ID, ...)` 落盘（与 steering 同款写法）。
- 预设 → 三段时段表的**纯函数**：

```java
record Segment(long fromTick, long toTick) {}
static List<Segment> work(HoursPreset preset)   // 纯函数，可单测
static boolean working(HoursPreset preset, long dayTime)
```

- `DAY_SHIFT`：`0–12000` 工作，`12000–13800` 用餐/自由，`13800–24000` 休息。
- `NIGHT_SHIFT`：与 DAY 相反（为看不清的人/地底殖民地）。
- `SIEGE`：全天工作（应急开关）。

### 3.2 生效方式（B：`Standing` 加时间维度，**L3**）
```java
// core/api/work/Standing.java（改）
boolean permits(UUID resident, BlockPos cell, long dayTime);

// Tours.unfit(...) 里传给 Standing 的 tick = 当前 dayTime
```
- 休息时段：`HoursStanding` 对**所有居民**返回 false → 排不出活（与禁区走同一收口，语义一致）。
- 需求类豁免（吃饭/如厕/睡觉）**不经过 `Standing`**（它们是需求 urge，不是"去某格干活"），因此天然不受影响；这一点在 T3 用测试固定。
- `enabled=false` 时不安装 provider（保持 `Standing.ALL`），零行为变化。

> 与 WP-4 的 `Standing` 是**同一条管道**：只把签名从 `(resident, cell)` 扩成 `(resident, cell, dayTime)`，其余不动。这也是为什么 B 比"再造一条时间闸"更可取——两条闸迟早会打架。

**这是 L3，需要评审后才能实施**（与 PLAN-003-A 同规矩）。

### 3.3 UI
- 一个 `Flag`（enabled）+ 一个 `Choice`（四个预设），挂在**已存在的页面**上（不新开图表）。
- 文案四语（en/简/港/繁），键前缀 `folkways.hours.*`。
- 面板行显示当前时段与"下一个切换还有多久"（用 `dayTime` 计算，纯函数）。

---

## 4. 任务单

| # | 任务 | 层 | 验收 |
| --- | --- | --- | --- |
| **T0** | ✅ 已做：`ColonyWorks.urges` 纯追加，A 路线作废，改走 B | 文档 | 结论已落纸；路线已更新 |
| **T1** | `plugins/hours` 骨架：`HoursState` + 预设纯函数 + 存档 | L1 | gametest：四预设边界（0、11999、12000、13800、23999）全过 |
| **T2** | `enabled=false` 时行为与现在**逐 tick 等价** | L1 | 671→673 基线全绿 + 一条"关闭时 urge 数不变"的测试 |
| **T3** | 开启 DAY_SHIFT：休息时段无活、工作时段恢复 | L1 | gametest：模拟 `dayTime` 两侧 |
| **T4** | UI：`Flag` + `Choice` 挂到既有页面 | L1 | 编译 + 语言键四语齐全（运行时语言表验证，见 VERIFY-021 的教训） |
| **T5** | 解释层：休息时段不派活时，理由写 `HoursRefusal.RESTING` | L1 | 行文案与枚举同源 |
| **T6** | 登记 + VERIFY 报告 + ROADMAP/AC | 文档 | 断链 0 |

---

## 5. 验收

| 判据 | 怎么验 |
| --- | --- |
| 默认零影响 | `enabled=false` 时全量 gametest 与基线一致（测试数只增不减） |
| 时段真的生效 | 休息时段 `urges` 为空；工作时段恢复 |
| 解释得住 | 休息被挡有具名理由，四语可解析 |
| 不碰 L4 | diff 只在新插件 + 若走 B 则**一次** L3 评审 |

---

## 6. 风险

| 风险 | 处理 |
| --- | --- |
| 休息时段把"吃饭/喝水"也停了 | 需求类 urge（进食/如厕）必须**豁免**，白名单在 T3 固定并测试 |
| 与禁限区叠加产生死锁（区禁 + 时段禁） | 两者都只"减少可选"，不会互相"要求"；测试覆盖叠加情形 |
| 玩家开了作息却看不到效果 | 面板显示"当前时段/下次切换"，T4 必做 |
| `dayTime` 与床/睡眠逻辑冲突 | 作息只管"接不接活"，不改睡眠；`Rest` 不动 |

---

## 7. 开放问题

| 编号 | 问题 | 何时定 |
| --- | --- | --- |
| OQ-1 | ~~能否压制其他来源~~ → **不能**（`ColonyWorks.urges` 直接拼接）。已关闭 | ✅ |
| OQ-2 | 需求类 urge（进食/如厕/睡觉）的白名单具体有哪些？ | T3 前读 `LivingPresence.urges` |
| OQ-3 | 是否要"每人一张表"（B 路线的自然延伸）？ | WP-5 收口时评估 |