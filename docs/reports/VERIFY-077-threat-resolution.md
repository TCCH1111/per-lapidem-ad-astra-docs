# VERIFY-077 · M2 威胁结算 A/B/A：可复现、按比例、致命有上限（CI 全绿）

```
状态：通过（结算规则 A/B/A 已接，游戏测试全绿）
CI：run 44089632787（11/11 作业 success，含 GameTests (vanilla)）

本地：javac 类型检查通过；CI run 44089632787
验证者：WorkBuddy 会话（本地 javac + CI Linux runner）
验证日期：2026-11-17
关联：PLAN-012、PRD-004、VERIFY-074（威胁 T0）
fork 提交：dfb65160
```

---

## 1. 用户拍板：OQ-TH1=A，OQ-TH2=B，OQ-TH3=A

| 编号 | 问题 | 选择 |
| --- | --- | --- |
| OQ-TH1 | 结算随机还是确定 | **A 确定**——相同输入总得相同结果，危机可复现 |
| OQ-TH2 | 准备度怎么比 | **B 比例**——损失 = 强度 − 准备度 |
| OQ-TH3 | 失败后果上限 | **A 最多重伤**——一次袭击会疼、要养，但不直接死 |

---

## 2. 本轮做了什么

| 文件 | 改动 |
| --- | --- |
| `ThreatState.java` | 加 `readiness(militia, weapons, barriers, warningDays)`（T1，逐项可解释、预警天数封顶 5）；`Resolution(loss, severity, held)` 记录与 `resolve(strength, readiness)`（T2）；`settle()` 只结算已到城门口的危险（T3） |
| `HealthContent.java` | 加 `wound(state, who, severity, kind, now)`——后果复用同一本健康簿，不另造伤害模型 |
| `ThreatContent.java` | 到点后：算准备度 → 按比例结算 → 把后果写进健康簿 → 四语播报结果 → 结算该危险 |
| 语言文件 ×4 | 新增 `folkways.threat.held` / `folkways.threat.hurt`（en/zh_cn/zh_hk/zh_tw） |
| `ThreatResolutionGameTests.java`（新） | 5 个纯算术测试 |

**确定性**：`resolve()` 里没有任何随机数；`loss = max(0, strength − readiness)`。
**致命上限**：伤口 severity 封顶 3，而健康簿把 4 及以上才叫"重伤"（severe）——所以一次结算**不会直接致死**，死亡仍留给以后明确更狠的一档。

---

## 3. 测试（5 个纯 gametest）

| 测试 | 断言 |
| --- | --- |
| `aPreparedColonyHoldsWithNoLoss` | 准备≥强度 → 守住、零损失 |
| `lossIsTheProportionalShortfall` | 损失按比例缩小；同输入同输出（确定性 TH1=A） |
| `evenTotalDefeatCapsBelowSevere` | 最惨败情境 severity>0 且 <4（TH3=A，不直接死） |
| `readinessCountsOnlyWhatCanBePointedTo` | 四项各计一份、空准备为 0、预警封顶 |
| `settlingOnlyTouchesThoseAtTheGates` | 只结算已到达的危险，未到的仍在路上 |

本地 `javac`（Java 21）将 8 个改动文件一起编译通过。CI 结果见 §6。

---

## 4. 诚实边界

| 项 | 状态 |
| --- | --- |
| 结算规则 + 后果写健康簿 + 四语播报 | ✅ 逻辑与测试 |
| 准备度输入 | ⚠️ 当前只接了**居民数**作为民兵代理；武器/围墙数、事件驱动的危险来源尚未接（PLAN-012 T1 余项） |
| 谁来"预告"危险 | ❌ 目前只有测试调用 `foretell()`；游戏内还没有产生威胁的来源（刷怪/事件/剧本待定） |
| 玩家看到"还有 N 天"的常驻提示 | ❌ 只在到达/结算瞬间播报 |
| `RESOLVED` 之后 | —— 现由 `settle()` 正确写入；后果应用后危险才结算 |
| 客户端实测 | ⚠️ 实例是 0.1.0，不含本轮代码 |

---

## 5. 设计取舍

- 选择只数"居民数"作第一刀，是因为 PRD-004 §3 要求"每一份准备度都要能说出它来自什么"——居民数是现成可数事实；武器/围墙需要新定义"什么算武器/墙"，留到 T1 后续，**不瞎编一个来源**。
- 后果按 `loss` 逐人分摊（轮转），伤口 severity 由结算给出并封顶——复用医疗，威胁线与健康线在此合流。

---

## 6. CI 结果

```
CI run 44089632787（fork dfb65160）：
  build ✅ · typecheck ✅ · test:unit ✅（含 i18n 四语键门禁，覆盖本轮 2 个新键）
  GameTests (vanilla) ✅（含本轮 5 条）· core/rts/create/cookery/warfare/tacz/firefighting/chiselsandbits ✅
  Client smoke ✅ · nightly ✅ —— 11/11 success
```

两次功能提交（`abd316e5` 自救、`dfb65160` 结算）各自独立跑出全绿 CI，均可复现。
