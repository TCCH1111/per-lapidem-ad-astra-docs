# VERIFY-076 · M2 治疗 A：受伤的居民会自己包扎（CI 全绿）

```
状态：通过（自救触发 A 已接，游戏测试全绿）
验证者：WorkBuddy 会话（本地 javac 类型检查 + CI Linux runner）
验证日期：2026-11-17
关联：PLAN-011、VERIFY-072（绷带）、VERIFY-073（包扎动作）、VERIFY-074
fork 提交：abd316e5 · CI run 44087024991（11/11 作业 success，含 GameTests (vanilla)）
```

---

## 1. 用户拍板

PLAN-011 的开放问题"谁触发包扎"——用户回 **A：居民自己包扎**。
（数据层 `HealthContent.dress(state, who, pack)` 早在 VERIFY-073 就绪；A 只差"什么时候触发"。）

---

## 2. 本轮做了什么

| 文件 | 改动 |
| --- | --- |
| `HealthContent.java` | 加 `needsDressing(state, who, carried)` 纯决策：有仍在流血的伤口 **且** 携带绷带才为真；提供 `Container` 与 `List<ItemStack>` 两个重载（规划用快照、提交用活背包） |
| `DressAction.java`（新） | 一个 24 tick 的本地节点，`commit` 调用共享的 `HealthContent.dress`；空操作按 done 处理（伤口已好/绷带被用掉无需解释） |
| `LivingPresence.java` | `urges()` 开头加入自救 urge：`DIRE` 权重 + `preempts=true`，压过普通劳动；从健康簿与线程安全的背包快照决策，节点在提交时读活背包 |
| `HealthStateGameTests.java` | 2 个新测试 |

**为什么先做纯决策函数**：它不吃殖民地、不吃世界——测试直接喂 `HealthState` 和物品列表；触发的时机（A 的语义）只是"何时调用它"，规则本身不用重写。

---

## 3. 测试

| 测试 | 断言 |
| --- | --- |
| `selfCareIsWantedOnlyWhenBleedingAndCarryingABandage` | 流血 + 有绷带 → 想自救；同样伤口没绷带 → 无请求 |
| `aTreatedWoundNoLongerAsksForSelfCare` | 处置后即使绷带还在包里，也不再请求 |

本地 `javac`（Java 21，对十模块编译产物建 classpath）将 4 个改动文件一起编译通过；
CI 在 Ubuntu 上跑完整 `vanilla` 套件，含上面 2 条：

```
CI run 44087024991：build ✅ · typecheck ✅ · test:unit ✅
GameTests (vanilla) ✅ · (core/rts/create/cookery/warfare/tacz/firefighting/chiselsandbits) ✅
Client smoke ✅ · nightly ✅ —— 11/11 success
```

---

## 4. 诚实边界

| 项 | 状态 |
| --- | --- |
| 自救触发 + 包扎动作 | ✅ 逻辑、测试、CI |
| 绷带来源 | ❌ 仍无配方（OQ-T2 未拍板） |
| 玩家看到"他自己包扎了" | ❌ 无卡片行/通知 |
| 已感染伤口能否被包扎阻止恶化 | ❌ 未定（OQ-T3） |
| 客户端实测 | ⚠️ VERIFY-075 验的是 0.1.0 实例，**不含本轮代码**；需用最新 jar 重跑（D11 剩余项） |

---

## 5. 顺带修掉的 CI 假红

本轮开工前发现 fork CI 自 `69a601e`（11-06）起一路红：不是 Java 编译，而是
`tests/i18n/notice-keys.test.ts` 只读枚举常量后固定 1200 字符，`Mood.translationKey()` 落在 1631 字符处
被误判"无 key 规则"——**实际 120 个键四语齐全**。改成读到匹配右花括号后恢复全绿（fork `ea6c0ecb`）。
否则 build 失败会让所有 gametest 被 skip，A/B 两个功能都无法按 R7 验证。
