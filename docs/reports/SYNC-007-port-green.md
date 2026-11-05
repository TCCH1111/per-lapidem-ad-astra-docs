# SYNC-007 · 移植收尾：**1467 / 1467 全绿**，根因是 69 处硬编码 modid

```
状态：通过（移植的测试面完成）
验证者：DSH 会话
验证日期：2026-11-05
关联：SYNC-003~006、D15、D17
main：c456385（未受影响）
移植分支：port/aaac8b8 → **1ea1dac**
```

---

## 1. 结论

**十个模块、全套 `plaa_*`、1467 条游戏测试全绿。**

```
./gradlew build           → BUILD SUCCESSFUL（10 个 jar）
./gradlew runGameTestServer → All 1467 required tests passed :)
npm run typecheck         → exit 0
npm run test:unit         → 138 / 138
```

---

## 2. 那两条失败的真正原因（不是规划逻辑）

两条测试都在 `SeedObservationGameTests`，而这个测试类里有一行关键代码：

```java
@EventBusSubscriber(modid = "folkways_vanilla", bus = EventBusSubscriber.Bus.MOD)
public final class SeedObservationGameTests {
    @SubscribeEvent
    public static void register(RegisterGameTestsEvent event) {
        Containers.register(BellBlockEntity.class, ...);   // ← 让"钟"能被当成仓库读取
        event.register(SeedObservationGameTests.class);
    }
```

**modid 改成 `plaa_vanilla` 后，这个订阅器不再触发** → 容器读取适配器从未注册 → 预算永远观测不到容器 → `budget.complete()` 为假、`compostable` 为 0。**症状与原因完全对应。**

这也解释了为什么之前"关掉我们自己的注入"毫无效果——**根本不是我们的注入**。

---

## 3. 全局排查：69 处硬编码 modid

| 形态 | 数量 |
| --- | --- |
| `@EventBusSubscriber(modid = "folkways_*")` | **60** |
| `public static final String ID = "folkways_*"` | 5 |
| `DeferredRegister.create(..., "folkways_*")` 等 | 4 |

全部改为 `plaa_*`（`grep` 复查剩余 0 处）。

**这 60 个订阅器是潜在雪崩**：它们不会报错，只是**静默不再触发**。如果只修这一个测试文件，其余 59 处会在未来某个时刻以"某个功能莫名失效"的形式逐个冒出来。

---

## 4. 教训（写进 D17）

> **modid 改名不是构建文件的事，是代码的事。**
>
> 一次改名要同时处理四类引用：构建脚本（gradle）、元数据（mods.toml）、**代码里的字符串字面量**、以及 profile 配置。任何一类漏掉，都不会编译失败——只会在运行时静默失效。

这也解释了本项目三次"一刀切替换"事故的同源问题（`Standing→Veto` 误伤方法、incompatible 声明被改名、这次的 69 处字面量）：**改名的风险不在改，而在"哪些地方也该改"的判断**。

---

## 5. CI 对齐

采用**上游的 `build.yml`**（按模块矩阵跑游戏测试，比我们那份更适合 10 模块），只把 nightly 的分支从 `master` 改成 `main`；删除我们那份重复的 `gametest.yml` 与已失效的 `test:i18n` 脚本（上游已把语言校验并入 `test:unit`）。

**注**：原 `gametest.yml` 里"对唯一已知偶发按名单重试一次"的策略没有带过来——本次 1467 条一次跑通，暂不需要；若偶发重现再单独处理。

---

## 6. 状态

| 项 | 值 |
| --- | --- |
| 十模块构建 | ✅ 10 个 `plaa-*.jar` |
| 游戏测试 | **1467 / 1467** |
| unit | 138 / 138 |
| typecheck | ✅ |
| `main` | `c456385`（714/714，未受影响） |
| 移植分支 | `1ea1dac`（已推送） |

---

## 7. 下一步（需要你拍板）

移植分支已经是**可交付状态**，但它和 `main` 分属两套历史（上游重写过历史，无共同祖先）。把工作转到 `main` 有三种做法：

| 方案 | 说明 |
| --- | --- |
| **A. `main` 直接切到移植分支** | 最简单；`main` 历史变成上游历史 + 我们的提交，旧历史用 tag 保留 |
| **B. 移植分支合并进 `main`（`--allow-unrelated-histories`）** | 保留双历史，但仓库里会有一条巨大的合并点，日常 `git log` 会很难读 |
| **C. 先不切，用移植分支出包验证** | 更稳：先在 Prism 里跑一遍演示脚本，确认游戏内没问题再切 |
