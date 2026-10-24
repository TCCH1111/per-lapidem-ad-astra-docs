# VERIFY-017 · WP-4 / T4b：区域 → 引擎的接线（665/665）

```
状态：通过（T4 完成；T5/T6 待做）
验证者：DSH 会话
验证日期：2026-10-24
关联：PLAN-003（T4）、PLAN-003-A（L3 提案）、VERIFY-016（管道）
fork 提交：8a3ec16
```

---

## 1. 结论

禁限区现在**真的能拦住人**：steering 插件把每个殖民地的 `SteeringState` 交给引擎，引擎在建该殖民地 labor 时读取，`Tours` 派活前逐格询问，命中即返回 `ZONE_FORBIDDEN`。

游戏测试：**`All 665 required tests passed`**（662 + 新增 3）。

---

## 2. 接线方式（core 不认识"区域"）

| 组件 | 位置 | 职责 |
| --- | --- | --- |
| `Standings`（新，L1） | `core/api/work/Standings.java` | 可替换 provider：`provide(Function<UUID, Standing>)`、`of(colonyId)`、`reset()`；默认 `Standing.ALL` |
| `Labor` 应用（**L3，2 行**） | `Labor.java:96-97` | 建好 `ColonyLabor` 后 `labor.standing(Standings.of(colony.colonyId()))` |
| steering 提供（L1） | `SteeringContent` | 静态 `STATES`（colonyId → state）；`Standings.provide(id -> standingOf(STATES.get(id)))`；`closed` 时移除 |
| 适配（L1） | `SteeringContent.standingOf` | `(resident, cell) -> state == null \|\| !state.forbids(cell)` |
| 判定（L1） | `SteeringState.forbids` | 只认 **FORBID 且 subjects 为空** 的区 |

**核心模块没有 import 任何 `plugins.*` 类**——引擎只认识 `Standing` 接口。

---

## 3. 三个新测试

| 测试 | 断言 |
| --- | --- |
| `aForbidZoneBecomesAStandingThatRefusesItsCells` | 禁入区格 `!permits`，区外 `permits` |
| `theRegistryHandsTheEngineTheColonysStanding` | 两个殖民地互不影响；`reset()` 后恢复全放行 |
| `anAbsentProviderAllowsEveryCell` | 没装插件时任何格都可站 |

---

## 4. 证据

```
$ ./gradlew build --offline            → BUILD SUCCESSFUL in 15s
$ ./gradlew runGameTestServer --offline
[22:10:51] All 665 required tests passed :)
```

---

## 5. 边界（诚实登记）

| # | 限制 | 原因 / 下一步 |
| --- | --- | --- |
| 1 | 只有 **FORBID + 空 subjects** 生效 | `Standing.permits(resident, cell)` 拿不到"这人的工种"，`ALLOW_ONLY`/`LIMIT` 无法在此层判定；它们留给 T5 与诊断层（需要 resident→vocation 查询） |
| 2 | **规划期仍会长活** | 未改 weave 侧 `Fitness.anyone`（那层也拿不到格子）；现语义是"长得出来、永远派不出去、并报告原因" |
| 3 | **未做端到端**"画区 → 居民绕行"的实测 | 需要 `DispatchPlanningGameTests` 级别的夹具；建议 T5 一并补 |
| 4 | `STATES` 是静态表 | 与 `Standings.provide` 组合在**多存档/重开**时要确认清理；`closed` 已移除，但异常退出可能残留（风险低） |

---

## 6. WP-4 进度

| 任务 | 状态 |
| --- | --- |
| T0 契约核实 | ✅ |
| T1 插件骨架 | ✅ |
| T2 区域模型 + 存档 | ✅ |
| T3 纯判定 | ✅（并入 T2 的 gametest） |
| T4 按人否决（L3，已批准） | ✅ T4a 管道 + T4b 接线 |
| T5 `SteeringRefusal` 枚举 + 诊断 | ⬜ |
| T6 殖民书面板 | ⬜ |
| T7 `steering why` 同源 | ⬜ |
| T8 登记与报告 | ⬜（本轮已登记 d12 行，收尾时补 AC 勾选） |
