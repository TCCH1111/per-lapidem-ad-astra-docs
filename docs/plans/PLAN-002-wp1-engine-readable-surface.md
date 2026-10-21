# PLAN-002 · M1-WP1：引擎可读面（把诊断需要的数据提升为公开只读）

```
状态：计划中（待派单）
负责人：规划者（agent）
最后更新：2026-10-21
上游依据：docs/workflow/05-m1-task-breakdown.md §3（WP-1）、§4 任务单模板；docs/prd/PRD-006-stock-rules-and-diagnosis.md；docs/prd/PRD-001-needs-mood-memory.md；docs/design/12-fork-strategy.md §5（L0–L4）与改动登记
工作树：WSL `~/pla/mod`（分支 main，HEAD 7344f9d）；`reference/folkways-3ce4d88/` 只读
构建：NeoForge **21.1.233**（264 升级挂起，见 VERIFY-010）
```

---

## 1. 一句话目标

让**诊断层**（PRD-006 的"为什么"）与**需求层**（PRD-001 的状态展示）能读到它们需要的基底数据，而**不修改任何行为**：只加**只读访问器**，不加可写入口、不改结算逻辑、不改存档格式。

**图层**：**L2**（在上游既有文件里加少量行 + `// PLA:` 标记）。**无 L3/L4**。

---

## 2. 为什么需要（不做的后果）

PRD-006 要求"任何没发生的事都能被解释"（覆盖率 ≥95%）。但下列类型当前是**包私有**，诊断层在自己的包里根本拿不到：

| 类型 | 当前可见性 | 诊断需要它做什么 |
| --- | --- | --- |
| `Hunger` | `final class`（包私有） | 读饥饿水位，解释 D-8「被更高优先占用」与需求展示（PRD-001） |
| `BodyState` | `final class`（在 `core.api...` 下却非 public） | 读身体状态，供 PRD-013 医疗与 PRD-001 的 vitals 展示 |
| `Beds` | `final class`（包私有） | 解释"没有床/床被占"（D-6 类） |
| `Carry` | `final class`（实现 `Carrying`） | 解释搬运中的物品去向（物流诊断） |
| `Urges` | `final class`（包私有） | 读 urge 的退避状态（`Urges.BACKOFF=100`），解释 D-10「失败退避中」 |

**已经够用的**（本轮不动）：`Shortfall`、`Unassigned`、`RefusalKind`、`Pack`、`Cooldowns`、`Commit` 都已是 `public`。

---

## 3. 设计原则（每条都可被评审）

1. **只读**：只暴露 `getter`/`record` 视图；**不新增任何 `set`/`add`/`clear`**。
2. **不加宽类**：优先在**已有的 public 类型**上挂静态只读入口（如 `Resident`/`Body` 的公开视图），而不是把包私有类改成 `public`。只有当"没有合适的公开宿主"时才提权，并在计划里单列理由。
3. **视图不可变**：跨包返回的必须是 `record`/不可变拷贝，禁止把内部 `Map`/`List` 直接交出去（防止外部改内部状态）。
4. **空值语义明确**：`Optional`/`null` 二选一并写进文档；不允许"有时 null 有时空集合"。
5. **零行为变化**：访问器不得触发结算、不得写 `dirty`、不得读世界方块（纯内存读）。
6. **每个改动行带 `// PLA:` 与登记行**（d12 §5），保证季度同步时能一眼找出我们的改动。

---

## 4. 任务单（六条，按依赖排序）

### T1 · 盘点与命名（0.5 天）
- **目标**：确认上表 5 个类型的**真实包路径与成员**，并为每个选出"公开宿主"。
- **产出**：`docs/plans/PLAN-002-inventory.md`（一页表格：类型 / 包 / 成员 / 宿主 / 访问器签名 / 是否需提权）。
- **验收**：每个类型都有宿主结论；不允许出现"待定"。
- **禁止**：不得在这一步改任何代码。

### T2 · `Hunger` 只读视图（0.5–1 天）
- **宿主**：`Resident`（公开接口）上新增 `hungerLevel()`，或 `Hunger.view(LivingEntity)` 静态方法（二选一，由 T1 定）。
- **返回**：`record HungerView(float level, float capacity, boolean satisfied)`——纯拷贝。
- **验收**：`./gradlew build` 通过；`npm run test:unit` 不回归；新增 gametest：生成一个居民 → 断言视图非空且 `level <= capacity`。
- **禁止**：不得改 `Hunger.tick`/衰减；不得让视图写 `dirty`。

### T3 · `BodyState` 只读视图（1 天）
- **特别注意**：它在 `core/api/resident/body/` 下却**不是 public** —— 这是最"意外"的一个，也是最该修的一个。
- **返回**：不可变 `BodyView`（部位列表 + 每个部位的状态枚举），**不暴露 `INBTSerializable` 的 `CompoundTag`**。
- **验收**：同上；gametest 断言新建居民返回空部位集而不是 `null`。
- **禁止**：不得改存档序列化；不得暴露可变 `ItemStack`。

### T4 · `Beds` 与 `Carry` 的只读（0.5–1 天）
- `Beds`：暴露"该居民是否有床 / 床位坐标 / 是否被占"（供 D-6）。
- `Carry`：暴露"当前搬运的物品与数量"（注意：`Carrying` 已是 public 接口，先确认诊断层能否直接用 `Carrying`，**能就不动 `Carry`**）。
- **验收**：两个 gametest 各断言一次；若 `Carrying` 已够用 → 本任务缩为"只加文档说明"，不产生代码改动（记进报告）。

### T5 · `Urges` 退避可读（1 天）
- 暴露 `backoffTicks(Urge)` 或 `isBackingOff(Urge)`，供 D-10 的解释文案使用（"上次失败，%s 后重试"）。
- **验收**：gametest 触发一次失败 → 断言 `isBackingOff` 为真、且**不触发重新规划**。
- **禁止**：不得改 `BACKOFF=100` 常量；不得在访问器里清退避。

### T6 · 登记与交付（0.5 天）
- 在 `docs/design/12-fork-strategy.md` 的改动登记表加行：文件、行号、图层、原因、`// PLA:` 标记。
- 在 `docs/reports/VERIFY-0xx-wp1.md` 写验收报告（含每条的 gametest 名称与结果）。
- **验收**：`git diff --stat` 只包含计划内文件；每个改动行都有 `// PLA:`。

---

## 5. 验收总表

| 判据 | 怎么验 |
| --- | --- |
| 零行为变化 | 全部 651 个既有 gametest 仍通过（`./gradlew runGameTestServer`） |
| 只读 | `git diff` 里不出现 `public void set`/`add`/`remove`/`clear` |
| 不碰结算 | `git diff` 不触及 `tick(`/`reconcile(`/`Commit.` 的调用点 |
| 视图不可变 | 代码评审：返回类型都是 `record` 或无 setter 的接口 |
| 可追溯 | 每行有 `// PLA:`，且 d12 登记表有对应行 |
| 复杂度 | 净增代码 ≤ 250 行（含 gametest） |

---

## 6. 风险与回退

| 风险 | 触发信号 | 回退 |
| --- | --- | --- |
| 提权后上游同步冲突变大 | 下次同步时这几个文件反复冲突 | 优先改用"公开宿主上的静态入口"，减少提权 |
| 视图泄漏可变集合 | 评审发现返回 `Map`/`List` 本体 | 立刻改为拷贝/不可变包装 |
| 访问器意外触发计算 | gametest 的 tick 数变化 | 规格要求"纯内存读"，违反即回退该任务 |
| `BodyState` 在 `api` 下却非 public 属上游有意 | 上游文档/注释说明原因 | 改为"公开只读接口 + 包内实现"，不动类可见性 |

---

## 7. 为什么先做 WP-1

WP-1 是**关键路径的第一个玩法前置**（w05 §6：`WP-0 → WP-1 → WP-4 → …`）。它不产出玩家可见功能，但它决定 WP-6（解释层）能不能做到"每条阻塞都有具体对象与原因"。**先做它，后面的诊断代码不用一边写一边回来改可见性。**

---

## 8. 开放问题

| 编号 | 问题 | 何时定 |
| --- | --- | --- |
| OQ-1 | `Carrying` 是否已满足物流诊断？若够用，T4 缩为文档 | T4 开工前 |
| OQ-2 | `BodyState` 的公开视图是"部位枚举"还是"部位+损伤"（后者属 PRD-013，M2） | T3 开工前 |
| OQ-3 | 视图对象是否要参与 `keep` 序列化？（**默认不参与**，视图是瞬时的） | T2 开工前 |
