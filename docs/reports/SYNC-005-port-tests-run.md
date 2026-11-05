# SYNC-005 · 移植第三阶段：测试跑起来了（1402 / 1404）

```
状态：进行中（只差 2 条）
验证者：DSH 会话
验证日期：2026-11-05
关联：SYNC-003/004、D15
main：c456385（四件套全绿，未受影响）
移植分支：port/aaac8b8 → **77cc838**
```

---

## 1. 结论

**整套管游戏测试在移植树上跑起来了：1402 / 1404 通过**，只剩 2 条失败，且已证明**不是我们新增注入造成的**。

---

## 2. 上一轮的"上游删了 `Solving`"是误判

真相：上游把测试夹具**搬了家**——

| 之前 | 之后 |
| --- | --- |
| `mods/core/src/gametest/java/.../plan/Solving.java` | `mods/core/src/**gameTestFixtures**/java/.../plan/Solving.java` |
| `PlanningFixture.java` 等 | 同上 |

它们仍在被上游自己的测试大量使用。所以我们的改动**只需重新应用到新路径**（一个 5 行的 `standing(Veto)` 方法），不需要重建夹具。

**教训**：用 `git ls-tree` 看目录得到"文件不存在"的结论太快了——**应该先 `git grep` 类名**。

---

## 3. 两条失败的定位过程（有进展，未定案）

| 步骤 | 结果 |
| --- | --- |
| 跑移植树 | 1402/1404，失败：`insertionIntoCachedEmptyStore…`、`settingsOnlyChangeReallocates…` |
| 查这两条属于哪个文件 | `SeedObservationGameTests.java`，**与上游逐字一致**（我们没改过它） |
| 纯净上游跑两次 | **1404 全过 ×2** → 不是上游偶发 |
| 夹具从 26 增到 38（与上游一致） | **仍然失败** → 不是夹具缺失 |
| 采用上游全文 `blockwright.toml`（只改 4 个模块名） | **仍然失败** |
| **关掉我们的两处注入**（插件安装 + 否决权查找），跑全量 | **仍然失败** → **不是我们的新增代码** |

**结论**：失败来自**我们合并时带进来的旧版本代码**（某个上游后来改过行为、而我们文本上"干净合并"的文件）。

**共同症状**：两条失败都是"**规划预算从未完成对容器的观测**"（`budget.complete()` 为假；由它推导出的 `compostable` 因此是 0，而期望 36）。

---

## 4. 已排除的嫌疑（都是纯附加、默认放行）

逐一 diff 过：`Tours`（否决检查 + 2 个 reason 分支）、`Scheduler`（字段 + 转发）、`Pipeline`、`ColonyLabor`、`Urges`、`Labor`（否决查找）、`FolkwaysMod`（仅 modid）、`neoforge.mods.toml`（仅命名 + incompatibility）、`mods/vanilla/build.gradle`（仅删 cookery/rts/warfare 接线）。

**下一步**：分组二分——把这些文件逐个回退成上游版本，跑一次看两条是否转绿，用 5–6 次运行锁定到具体文件。

---

## 5. 状态

```
compileJava          ✅
compileGametestJava  ✅
runGameTestServer    1402 / 1404
```

- `main` 未受影响（`c456385`，714/714）；
- 移植分支已推送（`origin/port/aaac8b8` = `77cc838`）；
- 实验期间的临时改动已完整恢复（`EXP:` 标记 0 处），树是干净的。
