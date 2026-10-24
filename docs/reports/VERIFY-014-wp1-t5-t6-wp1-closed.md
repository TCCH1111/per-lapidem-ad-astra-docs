# VERIFY-014 · WP-1 收口：T5 退避视图 + T6 变更登记（657/657）

```
状态：通过 —— WP-1（引擎可读面）完成
验证者：DSH 会话
验证日期：2026-10-24
关联：PLAN-002（T5/T6）、VERIFY-012（T3）、VERIFY-013（T2）
fork 提交：7a62ea4（T5）；WP-1 全部提交 892dc98 / 77a3885 / 7a62ea4
```

---

## 1. 结论

T5 与 T6 完成，**WP-1 三个可读面全部就位**：

| 面 | 门面 | 上游改动 | 测试 |
| --- | --- | --- | --- |
| 身体状态（body） | `BodyViews`（60 行） | **0 行** | ✅ |
| 饥饿 / 床位（living） | `PresenceViews`（75 行） | 2 个包内方法（`LivingPresence:91`） | ✅ |
| 退避（labor） | `LaborViews`（28 行） | 2 个包内方法（`ColonyLabor:83`、`Urges:56`） | ✅ |

游戏测试：**`All 657 required tests passed`**（655 + 新增 2；上游 651 + 我们 6 个）。

---

## 2. T5 做了什么

| 文件 | 层 | 内容 |
| --- | --- | --- |
| `core/engine/labor/Urges.java` | **L2（1 个方法）** | `long coolingLeft(urge, now)` —— 只读 `cooling`，**不 remove**（与 `quiet()` 的关键区别） |
| `core/engine/labor/ColonyLabor.java` | **L2（1 个方法）** | `Urges urgeBook()` 包内句柄 |
| `core/engine/labor/LaborViews.java` | **L1（新文件）** | `coolingLeft(labor, urge, now)` / `cooling(...)` |
| `core/src/gametest/.../labor/LaborViewsGameTests.java` | **L1** | 2 个 gametest |

**两个测试**：
- `aRefusedUrgeCoolsForItsBackoff`：拒绝后 `coolingLeft(1000)=100`、`(1050)=50`、`(1100)=0` → 与 `Urges.BACKOFF = 100L` 一致。
- `readingTheBackoffDoesNotClearIt`：连读三次仍报 100→99→98 → **读不消费**（这正是 D-10「失败退避中」要的语义）。

---

## 3. T6：三处 `// PLA:` 已登记进唯一清单

`docs/design/12-fork-strategy.md §5.1` 追加 3 行（并加 1 段说明 L1 门面不属上游改动）：

```
mods/vanilla/.../LivingPresence.java   L2（2 个方法）  bellyOf(UUID) / bedClaims()      PLAN-002 T2 / VERIFY-013
mods/core/.../ColonyLabor.java         L2（1 个方法）  urgeBook()                        PLAN-002 T5 / VERIFY-014
mods/core/.../Urges.java               L2（1 个方法）  coolingLeft(urge, now)，不清理     PLAN-002 T5 / VERIFY-014
```

代码里的标记位置（`grep "// PLA:"` 实测）：

```
LivingPresence.java:91   // PLA: WP-1 T2 — read-only handles for the diagnosis facade (PresenceViews)
ColonyLabor.java:83      // PLA: WP-1 T5 — read-only handle for the diagnosis facade (LaborViews)
Urges.java:56            // PLA: WP-1 T5 — read-only backoff query … Reads never remove an entry
```

---

## 4. WP-1 总账（对照 PLAN-002 的验收）

| 判据 | 结果 |
| --- | --- |
| 零行为变化 | ✅ 657 个 gametest 全过（含上游 651） |
| 只读 | ✅ diff 里没有新增 `set`/`add`/`remove`/`clear` 的公开入口 |
| 不碰结算 | ✅ 未改 `tick`/`reconcile`/`Commit` 调用点 |
| 视图不可变 | ✅ 三处都返回 `record`（`BodyView`/`HungerView`/`BedView`） |
| 可追溯 | ✅ 3 处标记 + d12 登记表 3 行 |
| 复杂度 | ✅ 门面 163 行 + 测试 6 个；L2 仅 4 个方法 |

`git diff --stat upstream-base-3ce4d88-20261019`：**31 文件、+667 / −56**（含 B-2 改名的 20 文件；WP-1 自身只占其中 7 个文件）。

---

## 5. 遗留

| # | 项 | 何时补 |
| --- | --- | --- |
| 1 | `PresenceViews.hunger/bed` 的**真实殖民地查找路径**仍未测（T2 遗留）；`LaborViews` 的 `ColonyLabor` 入口同理 | WP-6 诊断层接入时用真实殖民地补 |
| 2 | `HungerView` 无饱食度/消耗度（`Hunger` 那两个字段没 getter） | 需求 UI（WP-7）需要时再加 2 行 |
| 3 | 行尾：本轮又因 `WriteAllLines` 把两个文件转成 CRLF，已 sed 回 LF，`git status` 干净 | 已记入长期记忆，下次直接用 `WriteAllText` + LF 拼接 |

---

## 6. 下一步

WP-1 关闭，关键路径进入 **WP-4（禁限区）**——w05 说它需要先立 `PLAN-003`（L1 + L3：区域类型、约束求值纯函数化、`steering why`）。WP-4 是 M1 第一个**玩家可见**的功能，也是演示脚本第 2–6 步的基础。
