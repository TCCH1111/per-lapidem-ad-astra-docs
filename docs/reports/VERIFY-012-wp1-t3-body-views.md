# VERIFY-012 · WP-1 / T3：`BodyViews` 只读门面（653/653 通过）

```
状态：通过
验证者：DSH 会话
验证日期：2026-10-22
关联：PLAN-002（T3）、PLAN-002-inventory（2.1）、VERIFY-010（264 结论更正）
fork 提交：892dc98（`feat(api): read-only BodyViews facade …`）
```

---

## 1. 结论

T3 完成：新增**同包 public 门面** `core/api/resident/body/BodyViews.java`，把包私有的 `BodyState` 以**不可变 record** 暴露给诊断层。**没有修改任何上游文件**（0 行 L2），`BodyState` 仍保持包私有、所有 mutator 未外泄。

游戏测试：**`All 653 required tests passed`**（上游 651 + 新增 2）。

---

## 2. 改了什么

| 文件 | 图层 | 内容 |
| --- | --- | --- |
| `mods/core/src/main/java/.../core/api/resident/body/BodyViews.java` | **L1（新文件）** | `public static Optional<BodyView> of(Entity)`、`public static BodyView of(Body)`；`record BodyView(Optional<UUID> colony, Optional<Doing> doing, Optional<Balk> balk, int packSlots)` |
| `mods/core/src/gametest/java/.../core/api/resident/body/BodyViewsGameTests.java` | **L1（新文件）** | 2 个 gametest |

**关键手法**：`BodyViews` 与 `BodyState`、`FolkwaysAttachments.BODY_STATE` **同包**，因此能读包私有成员；对外只交出 record。`Body.mob().getData(...)` 的写法照抄 `Body.java:30`，不是新发明。

**没有做的事**（同样重要）：没有把 `BodyState` 提权为 public（它有 `bindTo/nowDoing/balked/credit` 四个 mutator）；没有把 `Pack` 直接交出去（它是可变 `Container`），只给 `packSlots`。

---

## 3. 两个 gametest

| 测试 | 断言 |
| --- | --- |
| `aFreshBodyHasNoColonyNoDoingAndRoomInItsPack` | 新生成的牛：`colony/doing/balk` 全空、`packSlots > 0` |
| `readingTwiceChangesNothing` | 连读两次：colony 仍空、`packSlots` 稳定、doing 仍空 → **纯读，无副作用** |

用牛而不是居民：门面不需要 `ResidentKind`，任何实体都能挂 `BODY_STATE`，这样测试不依赖牧场/居民注册。

---

## 4. 证据

```
$ ./gradlew build --offline          → BUILD SUCCESSFUL in 27s
$ ./gradlew runGameTestServer --offline
[15:10:53] [Server thread/INFO] [minecraft/GameTestServer]: All 653 required tests passed :)
```

（上一轮非离线构建失败是 **网络**：`maven.neoforged.net: Network is unreachable`；`--offline` 用缓存即可，见 §5。）

---

## 5. 顺带纠正一条结论：`onefoodcannotfeedhalfofapair` 是**跨版本偶发**

本轮在 **233** 上第一次跑 gametest 时，同一个测试失败了：

```
[14:25:28] onefoodcannotfeedhalfofapair failed at … java.util.NoSuchElementException
[14:25:35] 1 required tests failed :(
```

紧接着**同一份代码**复跑 → `All 653 required tests passed`。

→ **VERIFY-010 里"264 引入回归"的判断下得太早**。已确认的事实变成：

| 版本 | 观察 |
| --- | --- |
| 233 | 通过 651/651（19:44）；本轮失败一次（14:25）、复跑通过（15:10） |
| 264 | 连续 3 次失败（19:34 / 19:36 / 20:46） |

也就是说：**该测试在 233 上偶发、在 264 上可能更频繁**，但"264 必定失败"尚未成立。要判定 264 是否真的更差，需要**同条件重复 N 次**（例如各跑 5 次统计失败率），这属于后续工作，不应阻塞 M1。

---

## 6. 遗留

| # | 项 | 何时补 |
| --- | --- | --- |
| 1 | T2（`Hunger`/`Beds` 视图）仍需 1 行包内 getter（`LivingPresence`） | 下一轮 |
| 2 | `onefoodcannotfeedhalfofapair` 的失败率统计（233 vs 264 各 5 次） | 独立一轮，或交给上游 |
| 3 | `BodyView` 是否要加 `perks` 摘要 | T2 之后按诊断需要定 |
