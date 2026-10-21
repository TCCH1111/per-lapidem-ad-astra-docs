# PLAN-002 附录 · T1 盘点：五个包私有类型的取得路径

```
状态：完成（T1 交付物）
最后更新：2026-10-21
对应：docs/plans/PLAN-002-wp1-engine-readable-surface.md §4 T1
方法：直读工作树源码（WSL ~/pla/mod），非猜测；每行都带 文件:行号
```

---

## 1. 结论摘要

| 类型 | 持有者 | 持有者可见性 | 取得路径 | 图层 | 需要改上游？ |
| --- | --- | --- | --- | --- | --- |
| `BodyState` | 数据附件 `FolkwaysAttachments.BODY_STATE`（`static final`，同包） | 附件表字段包私有，但**与 `BodyState` 同包** | 同包新增 `BodyViews`（public），内部读附件表 → 返回不可变 `BodyView` | **L1** | **否**（0 行） |
| `Hunger` | `LivingPresence.bellies`（`Map<UUID, Hunger>`，`private final`） | `LivingPresence` 本身是包私有 `final class`（`LivingPresence.java:57`） | 同包新增 `PresenceViews`；但需要 `LivingPresence` 暴露包内读点 | **L1 + L2(1 行)** | 是：`LivingPresence` 加 1 行包内方法 |
| `Beds` | `LivingPresence.beds`（`private final Beds`，`LivingPresence.java:79`） | 同上 | 同上（同一个门面里） | **L1 + L2(1 行)** | 是：同上一条可共用 |
| `Urges` | `ColonyLabor.urges`（`private final Urges`，`ColonyLabor.java:81`） | `ColonyLabor` 是 **public**（`ColonyLabor.java:57`） | 同包新增 `LaborViews`；需 `ColonyLabor` 暴露包内读点 | **L1 + L2(1 行)** | 是：`ColonyLabor` 加 1 行包内方法 |
| `Carry` | 实现 `Carrying`（public 接口） | `Carry` 包私有，但接口 public | 诊断层**直接用 `Carrying`**，不碰 `Carry` | **L0（无改动）** | 否 |

**总计**：新增 3 个 public 门面文件（L1）+ **3 行**上游包内读点（L2）+ 0 行行为改动。

---

## 2. 逐条依据

### 2.1 `BodyState`（最好做，零上游改动）
- 定义：`core/api/resident/body/BodyState.java`，`final class BodyState implements INBTSerializable<CompoundTag>`（包私有）。
- 全部成员已是 `public`（`pack()` / `perks()` / `colony()` / `doing()` / `balk()`…），只是**类不可见**。
- 附件表：`core/api/resident/body/FolkwaysAttachments.java` 的 `static final ... BODY_STATE`（**同包**）。
- 方案：新增 `core/api/resident/body/BodyViews.java`
  ```java
  public final class BodyViews {
      public static Optional<BodyView> of(Entity entity) { ... }   // 读 BODY_STATE，转不可变 record
  }
  public record BodyView(Optional<UUID> colony, Optional<Doing> doing, Optional<Balk> balk, boolean hasPack) {}
  ```
  → **L1，零上游行**。

### 2.2 `Hunger` 与 `Beds`（各 1 行 L2，可共用一行）
- `Hunger`：`plugins/person/living/Hunger.java`，`final class`；字段 `foodLevel/saturationLevel/exhaustionLevel`（`private`），已有 `public int foodLevel()`。
- `Beds`：同目录 `Beds.java`，`final class`。
- 持有者：`LivingPresence.java:79`（`private final Beds beds`）、`:86`（`private final Map<UUID, Hunger> bellies`）。
- `LivingPresence` 是**包私有**（`:57`），所以诊断层需要同包门面 `PresenceViews`。
- 但 `beds`/`bellies` 是 `private` → 门面也读不到 → **必须加 1 行包内读点**（两种写法二选一，T2 决定）：
  - `Hunger hunger(UUID id) { return bellies.get(id); }`
  - 或 `Map<UUID, Hunger> bellies() { return Collections.unmodifiableMap(bellies); }`（不推荐：暴露集合）
- 视图：`record HungerView(int foodLevel, float saturation, float exhaustion)`；`record BedView(boolean hasBed, Optional<BlockPos> pos, boolean occupied)`。

### 2.3 `Urges`（1 行 L2）
- `core/engine/labor/Urges.java`，`final class`；`private final Map<ResourceLocation, Long> cooling`；常量 `BACKOFF = 100L`（`:31`）。
- 持有者：`ColonyLabor.java:81`（`private final Urges urges`），`ColonyLabor` 是 **public**（`:57`）。
- 方案：`ColonyLabor` 加 1 行 `Urges urges() { return urges; }`（包内），同包新增 `LaborViews`：
  ```java
  public static Optional<Long> coolingUntil(ColonyLabor labor, ResourceLocation urge, long now)
  ```
  只读 `cooling` 与 `quiet(...)` 的语义（**不调用 `refused`**，不改变冷却）。

### 2.4 `Carry`（不改）
- `Carry` 包私有，但实现 **public** 接口 `Carrying`；诊断只需"当前搬运什么"，用 `Carrying` 即可。
- 结论：**T4 缩为"在诊断层用 `Carrying` + 写一段说明"**，不产生代码改动（PLAN-002 OQ-1 关闭）。

---

## 3. 由此修正 PLAN-002 的两条设计

1. **新增门面优先于提权**：能"同包 public 门面"就不改类可见性（`BodyState` 已证明可行）。
2. **L2 预算从"5 个文件"降为"3 行"**：`LivingPresence` 1 行、`ColonyLabor` 1 行、`BodyState` 0 行；`Carry` 0 行。上游同步冲突面因此极小。

---

## 4. 仍未确定（留给 T2/T3 开工前）

| # | 问题 | 需要读的文件 |
| --- | --- | --- |
| Q1 | `LivingPresence` 如何从 `Entity`/`ColonyView` 拿到（决定门面的入口签名） | `LivingContent.java`、`LivingPresence.java` 的注册/查找处 |
| Q2 | `BodyView` 要不要包含 `Pack` 摘要（`Pack` 已是 public，但含可变 `ItemStack`） | `Pack.java` |
| Q3 | `Urges.cooling` 的"读"是否需要清理过期项（`quiet()` 会 `remove`）——**只读视图不得 remove** | `Urges.java:33-46` |
