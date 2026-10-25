# VERIFY-044 · M2 / N5：说清"他为什么在休息时段还动着"（712/712）

```
状态：通过（N5 完成；N6/N7 待做）
验证者：DSH 会话
验证日期：2026-10-26
关联：PLAN-006（N5）、VERIFY-043（N4 收窄）
fork 提交：f2421e7
```

---

## 1. 结论

从现在起，玩家看到"作息开着、他还在动"时，**能读到原因**——而且只在**有原因可读**时才说话。

游戏测试：**`All 712 required tests passed`**（710 + 2）。

---

## 2. 要解决的具体误判

从外面看，这两件事**长得一模一样**：

1. 他饿/困了，**需求优先于作息**（设计如此）；
2. 作息**没生效**（真 bug）。

没有解释，玩家会默认是第 2 种——**这正是 D8 修过的那类"说错话/不说话"的翻版**：界面不解释，等于让玩家自己猜出一个错误的结论。

---

## 3. 交付

| 改动 | 内容 |
| --- | --- |
| `Explanation.upDuringRest(Mood)` | `STRESSED` / `DESPERATE` → **给出解释**；`CONTENT` / `WORRIED` / `null` → **什么都不说** |
| 四个语言文件 | `folkways.explain.needs_first.title/advice`，JSON 均重新解析 |
| `ExplanationNeedsGameTests` | 2 个测试 |

**为什么"没需求就不说"**：一个状态良好的居民在作息外走动是**正常的**（收尾、走路、上厕所）。给正常行为也配一句解释，会把提示变成噪音——**"只在有话说时说"与"有理由就说"同样重要**。

---

## 4. 两个测试

| 测试 | 断言 |
| --- | --- |
| `aResidentWithANeedIsExplained` | 撑得住/撑不住 → 有解释；正常/隐隐不安 → **无解释**；`null` → 无解释 |
| `itsWordsResolveAtRuntime` | 两个键在运行时语言表里都能解析 |

```
./gradlew build --offline   → BUILD SUCCESSFUL in 10s
[17:08:41] All 712 required tests passed :)
```

---

## 5. 遗留

| # | 项 | 说明 |
| --- | --- | --- |
| 1 | `zh_hk` / `zh_tw` 目前用的是**简体措辞** | 双语润色轮统一处理（与 VERIFY-018 同款缺口） |
| 2 | 解释尚未接到**界面行**上 | N6（书里显示）——先读 `SettlerNeed` 卡片已有什么，只补缺的 |
| 3 | `rules-first` 仍为独立候选（D12） | 需要时单独 L3 报批 |