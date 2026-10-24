# VERIFY-015 · WP-4 / T1–T2：禁限区骨架与区域判定（662/662）

```
状态：通过（T1、T2 完成；T3–T8 待做）
验证者：DSH 会话
验证日期：2026-10-24
关联：PLAN-003（T1/T2）、VERIFY-014（657 基线）
fork 提交：cd38ed1
```

---

## 1. 结论

新插件 `plugins/steering` 落地：区域模型 + 殖民地级状态 + 存档往返 + 纯判定函数，全部通过 gametest。

游戏测试：**`All 662 required tests passed`**（657 + 新增 5）。

---

## 2. 新增了什么

| 文件 | 层 | 内容 |
| --- | --- | --- |
| `plugins/steering/ZoneRule.java` | L1 | `record ZoneRule(id, name, kind, subjects, quota, cells)`；`Kind{FORBID, ALLOW_ONLY, LIMIT}`；`verdict(cell, subject, insideCount)` **纯函数** |
| `plugins/steering/SteeringState.java` | L1 | `Map<UUID, ZoneRule>` + `dirty` 标记；`save()`/`load(Reader)` 走 `Writer`/`Reader` |
| `plugins/steering/SteeringContent.java` | L1 | `ID = folkways:steering`；`declare` → `colony(ID, scope)`：载入、`share`、脏时每 tick 写一次 |
| `plugins/steering/SteeringPlugin.java` | L1 | `install(IEventBus)`：`addListener(Declaring.class, SteeringContent::declare)` |
| `plugins/BuiltinPlugins.java` | **L2（1 行 + 1 import）** | `SteeringPlugin.install(modBus)`，带 `// PLA:` 标记 |
| `gametest/.../steering/SteeringStateGameTests.java` | L1 | 5 个测试 |

**存档写法**照抄既有插件（`FishingPresence:121`、`FarmPresence:109`）：`colony.keep(ID, Writer…tag())`，读取用 `Reader.of(colony.kept(ID))`。**没有引入任何新的存储 API。**

---

## 3. 五个 gametest

| 测试 | 断言 |
| --- | --- |
| `aForbidZoneRefusesEverySubjectOnItsCells` | 禁入区格上 `FORBIDDEN`，紧邻区外 `ALLOWED` |
| `anAllowOnlyZoneAdmitsItsSubjectsAndNoOneElse` | 名单内 `ALLOWED`，名单外 `ONLY_FOR_OTHERS` |
| `aLimitZoneIsFullAtItsQuota` | quota=2：已有 1 人 `ALLOWED`、已有 2 人 `QUOTA_FULL` |
| `zonesSurviveASaveAndLoad` | id/name/kind/quota/subjects/cells **六项全相等** |
| `anEmptyColonyKeepsNoZones` | 空存档 → 0 区、`dirty=false` |

判定函数**不读世界、不看时钟**——这正是 PLAN-003 §4.2 要求的"纯函数可单测"。

---

## 4. 证据

```
$ ./gradlew build --offline        → BUILD SUCCESSFUL in 12s
$ ./gradlew runGameTestServer --offline
[16:26:15] All 662 required tests passed :)
```

657 → 662：新增 5 个测试确实注册并运行。

---

## 5. 对 T4 的直接影响（下一步的关键）

T4 要找"按人资格"的钩子。本轮顺带把 `Licences` 读透了：

- `Licences` 是**按实体类型**建的（`FolkwaysAttachments` 里 `licencesFor(holder)` 用 `entity.getType()`），存的是 `withheld`（工种）与 `keenness`；
- 它表达的是"**这类身体**能不能做这类活"，**不是"这个居民能不能去这个格子"**。

→ **禁限区不能只靠 `Licences`**。T4 大概率要在**派活/请求层**（`Requests`/`Scheduler`）加判定，按 w05 预期属于 **L3，需要单独评审**。这一点必须在 T4 开工前先探明，不能边写边猜。

---

## 6. 遗留

| # | 项 | 何时补 |
| --- | --- | --- |
| 1 | `SteeringState` 目前只挂在殖民地 scope，**没有 UI 能创建区域**（T6） | T6 |
| 2 | 区域格集合没有按 chunk 分桶（T3 之前判断是否需要；当前规模可接受） | T3 前评估 |
| 3 | T4 的落点（L3 评审） | 下一轮先探明 |
| 4 | `LIMIT` 的 `insideCount` 由调用方提供，尚无真实计数来源 | T4/T5 |
