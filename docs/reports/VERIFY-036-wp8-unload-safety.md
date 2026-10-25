# VERIFY-036 · WP-8 / 第一段：每殖民地一张作息表 + 可卸载（699/699）

```
状态：通过（WP-8 第一段完成）
验证者：DSH 会话
验证日期：2026-10-26
关联：VERIFY-035（WP-6 关闭）、WP-8（存档往返与卸载安全）
fork 提交：0476058
```

---

## 1. 发现的两个真实缺陷（都不是我事先想到的）

| # | 缺陷 | 后果 |
| --- | --- | --- |
| 1 | 作息插件的 `Standing` **把 `declare` 时的殖民地捕获进 lambda** | **同一世界第二个殖民地会借用第一个的时钟**（多殖民地串台） |
| 2 | 作息插件**完全没注册 `closed`** | 殖民地关闭后，`HoursState` 与 `Standings` 里的 provider **一直留在 JVM 里** |

缺陷 1 只在"一个世界有两个殖民地"时显形——如果只测单人单殖民地，永远不会发现。

---

## 2. 修复

| 改动 | 内容 |
| --- | --- |
| `HoursContent` | 改为 `Map<UUID, HoursState>` 按殖民地分表；provider 用 `id -> standingOf(STATES.get(id))`；`scope.closed(...)` 移除 state，**且当表为空时 `Standings.remove(ID)`** |
| `HoursContent.standingOf(state)` | 提取为公开方法，便于测试与复用 |
| `Standings.remove(owner)` | 新增：插件卸载时把自己的否决从引擎注册表里摘掉 |

---

## 3. 三个测试

| 测试 | 断言 |
| --- | --- |
| `twoColoniesKeepTheirOwnTimetables` | 一个在休息时段的殖民地拒绝；另一个同一格放行；**没有表**的殖民地也放行 |
| `aProviderCanBeLetGo` | 摘掉后引擎恢复全放行；**摘两次不炸** |
| `aRefusingProviderStopsRefusingWhenItIsLetGo` | 拒绝 → 摘掉 → 放行 |

```
./gradlew build --offline   → SUCCESSFUL in 11s
[23:19:46] All 699 required tests passed :)
```

---

## 4. WP-8 还剩什么

| 项 | 状态 |
| --- | --- |
| 每殖民地状态隔离 | ✅ 本轮 |
| 卸载时摘除 provider | ✅ 本轮 |
| **存档往返（跨重启）** | ⬜ 两个 `HoursState`/`SteeringState` 的 `save/load` 各有测试，但**没有"整局存盘→重启→读回"的验证** |
| 插件缺席时读旧存档 | ⬜ 未测：存档里有 `folkways:steering` 数据但插件没装，会不会崩 |
| NBT 结构变更（升级兼容） | ⬜ 未测 |

---

## 5. 判断

前两项是**代码里就能看出的泄漏**，所以先修；后三项需要真实服务端跑一局，属"下一段"，需要把测试实例的存档目录纳入流程（`.cache/test-server` 已有）。