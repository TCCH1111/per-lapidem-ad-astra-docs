# VERIFY-074 · M2 威胁 T0：危险会在到来进行预告（1525/1525）

```
状态：通过（T0 预告 + 倒计时 + 兵临城下；**结算公式待拍板**）
验证者：DSH 会话
验证日期：2026-11-10
关联：PLAN-012、PRD-004、VERIFY-073
fork 分支：main @ 40d73fa
```

---

## 1. 本轮做了什么

按 [PLAN-012](../plans/PLAN-012-m2-threats-abstract.md) 的第一刀，先做**唯一不需要公式的那一段**：
让"危险"（如掠夺者）能被**提前若干天预告**，殖民地能**数着日子等它**，到点后**停在"兵临城下"**。

### 状态机（`plugins/threat/ThreatState.java`）

```
Foretold（已预告，倒计时中）→ AtTheGates（到了城门口）→ Resolved（已了结）
```

- `foretell(kind, strength, now, days)` —— 登记一个危险，到达时刻 = `now + days × 24_000`（1 游戏日 = 24_000 tick）
- `advance(now)` —— 把到点的危险从 `Foretold` 推进到 `AtTheGates`，并**返回本次到达的列表**供调用方播报
- `pending()` / `all()` —— 读出"还在路上"的危险与全部危险
- `save()` / `load()` —— 用 `Writer`/`Reader` 走 NBT，危险与倒计时可存档、可跨进程读回

**关键克制**：`RESOLVED` 枚举存在，但**本轮没有任何代码把危险推进到它**。
到点只到"兵临城下"就停——因为"城门口之后发生什么"是还没拍板的结算公式（OQ-TH1/2/3）。
一个自己悄悄结算、什么后果都没有的危险，是**倒计时在撒谎**；宁可让它明明白白地等着。

### 插件接线（`plugins/threat/ThreatContent.java`）

- 声明殖民地作用域 `folkways:threat`，把 `ThreatState` 放进 `scope.share`；
- 每 100 tick 读一次倒计时：到点即向全服广播 `folkways.threat.at_the_gates`（带危险类型名）；
- 每 200 tick 存档一次，关闭世界时再存一次。

---

## 2. 四个游戏测试

| 测试 | 断言 |
| --- | --- |
| `aThreatIsKnownDaysBeforeItArrives` | 预告后状态为 `Foretold`、到达时刻 = 3 天；推进 2 天**尚未到达**但仍在路上 |
| `arrivingStopsAtTheGates` | 到点**恰好到达一次**、状态为 `AtTheGates`；再推进不会重复到达 |
| `aThreatSurvivesASave` | 存读往返后危险仍在、**阶段与数值（强度 30、到达时刻）不变** |
| `anEmptyBookDoesNothing` | 没有危险时 `pending()` 为空、推进也不产生到达 |

```
[17:24:30] All 1525 required tests passed :)   // 1521 + 4
```

**一个被确定性规则当场抓住的测试 bug**：`aThreatSurvivesASave` 第一次失败，
报"got FORETOLD"——因为测试把时钟推进到 2 天（`2 × DAY = 48000`），
而威胁的到达时刻是 `100 + 2 × DAY = 48100`，还差 100 tick。
把断言改成推进到 `100L + 2 * DAY` 后通过。这正是"可复现"的价值：错多少一眼可见。

---

## 3. 诚实边界

| 项 | 状态 |
| --- | --- |
| 状态机 + 倒计时 + 存档往返 | ✅ 逻辑与 4 个测试 |
| 到点广播"兵临城下" | ✅ 代码接线；四语键（`threat.at_the_gates` / `threat.kind.*`）已随插件加入 |
| **谁来"预告"一个危险** | ❌ 目前只有测试调用 `foretell()`；游戏内还没有产生威胁的来源（刷怪/事件/剧本待定） |
| **城门口之后发生什么** | ❌ 结算公式待拍板（OQ-TH1 确定/随机、OQ-TH2 阈值/比例、OQ-TH3 失败上限） |
| `RESOLVED` 阶段 | ⬜ 枚举在，但本轮无人写入——故意留白 |
| 玩家看到"还有 N 天"的常驻提示 | ❌ 只在**到达瞬间**广播一句；倒计时常驻 UI 未做 |
| 客户端实测（D11） | ❌ 所有玩家可见的东西至今没人眼确认 |

---

## 4. 下一步（三选一，任意一个都能开工）

| 回什么 | 我做什么 |
| --- | --- |
| **A** / **B** | 治疗包扎触发 → 把"能救"接完 |
| **按建议** | 威胁 T1/T2 开工（准备度 + 结算，公式按 OQ 建议 A/B/A 先落） |
| 装一次 v0.2.2 | 把 D11 验掉 |
