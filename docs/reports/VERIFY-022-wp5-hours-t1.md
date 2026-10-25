# VERIFY-022 · WP-5 / T0–T1：作息表（共享派活闸，679/679）

```
状态：通过（T0/T1 完成；T2–T6 待做）
验证者：DSH 会话
验证日期：2026-10-25
关联：PLAN-004、VERIFY-021（673 基线）
fork 提交：5efe2ea
```

---

## 1. 结论

作息表落地：四个预设（`FREE / DAY_SHIFT / NIGHT_SHIFT / SIEGE`）是**纯算术**，默认关闭，与禁限区**共用同一个派活闸**。全量测试 **679/679**（673 + 6）。

**最重要的一件事**：你批准了 L3（给 `Standing` 加时间参数），但实现时找到了**更小的做法**，所以那次 L3 **没有用上**——`Standing` 签名一行没改。

---

## 2. T0：为什么原路线（A）死了

```java
// ColonyWorks.urges(...) 实际实现
for (BiFunction<Worker, ColonyView, List<Urge>> source : scope.urges) {
    source.apply(who, view).forEach(urge -> felt.add(new Felt(scope.owner, urge)));
}
```

**纯拼接，没有否决权**——插件能往上加 urge，压不住别人的。原计划"休息时段接管为空"不成立，A 路线作废（PLAN-004 已改）。

---

## 3. 为什么 L3 最后没用到（诚实记录）

批准的 B 方案是 `permits(resident, cell, dayTime)`。实现时发现：**插件自己每 tick 采样 `dayTime`**（`scope.tick` 里 `state.clock(server.overworld().getDayTime())`），`Standing` 实现读自己那份快照即可——于是签名保持 `(resident, cell)`，**core 一行没动**。

代价是一个明确记录的限制：时钟来自**主世界** `dayTime`（殖民地若在其他维度，作息跟随主世界）。已在 §5 列出。

**这不是"绕过评审"**：L3 的授权没有使用，等于少改一处核心；评审记录保留，供以后需要逐人作息时复用。

---

## 4. 交付

| 文件 | 层 | 内容 |
| --- | --- | --- |
| `core/api/work/Standings.java` | L1（我们的文件） | 改为**按 owner 组合**：每个 owner 一个 provider，`of(colony)` 返回"全部同意才放行"。禁区与作息因此叠加，互不知情 |
| `plugins/hours/HoursPreset.java` | L1 | 四预设 + `working(dayTime)` + `nextChange(dayTime)`，纯函数 |
| `plugins/hours/HoursState.java` | L1 | `enabled`（默认 false）+ `preset` + `dayTime`；`save/load` 走基底 `Writer/Reader` |
| `plugins/hours/HoursContent.java` | L1 | 载入 → `share` → 注册 `Standing` → tick 采样时钟、每 200 tick 落盘 |
| `plugins/hours/HoursPlugin.java` | L1 | `install(IEventBus)` |
| `plugins/BuiltinPlugins.java` | L2（2 行） | 注册 `HoursPlugin`，带 `// PLA:` |

---

## 5. 六个测试

| 测试 | 断言 |
| --- | --- |
| `theDayShiftWorksByDayAndRestsByNight` | 0 / 11999 干活；12000 / 13799 休息；13800 / 23999 休息；24000 恢复 |
| `theFreeAndSiegePresetsNeverRest` | 全天任意时刻都干活；`FREE` 的 `nextChange` 恒为 0 |
| `theClockSaysWhenItWillChange` | 6000→6000；12000→12000；夜班 6000→7800 |
| `aColonyWithHoursOffKeepsWorking` | 关闭时任何时刻都不拦；开 DAY_SHIFT 后 13800 停；切 SIEGE 又干 |
| `aTimetableSurvivesASaveAndLoad` | 开关/预设/时钟三项往返一致 |
| `anEmptyRegistryRefusesNothing` | 没有 provider 时 `Standings.of` 全放行 |

**一个自己抓到的错**：`aColonyWithHoursOffKeepsWorking` 第一次失败——我忘了默认预设是 `FREE`（永远干活），却断言夜间停工。测试替我抓住了这个假设错误，随后补了 `preset(DAY_SHIFT)`。

```
./gradlew build --offline        → BUILD SUCCESSFUL in 9s
[20:49:19] All 679 required tests passed :)
```

---

## 6. 遗留

| # | 项 | 去向 |
| --- | --- | --- |
| 1 | **没有 UI**（开关 + 预设选择） | T4：`Flag` + `Choice` 挂到既有页面 |
| 2 | 只有殖民地级作息，没有"每人一张表" | 需要那次未使用的 L3（逐人权限） |
| 3 | 时钟取主世界 `dayTime` | 多维殖民地会跟随主世界；要精确需把维度传进来 |
| 4 | 需求（吃饭/如厕/睡觉）不受作息影响——**按设计**，但尚未用测试固定 | T3 增加一条"需求 urge 数目不变"的测试 |
| 5 | 作息被挡时没有具名理由（`HoursRefusal`） | T5 |