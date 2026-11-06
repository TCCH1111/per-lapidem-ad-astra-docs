# VERIFY-052 · M2-R1 第四段：卡片上的一行（1479/1479）

```
状态：通过（R1-4 完成；R1-5 解释 / R1-6 收口 待做）
验证者：DSH 会话
验证日期：2026-11-06
关联：PLAN-007、PRD-008、VERIFY-049..051
分支：port/aaac8b8 → 2086a76
```

---

## 1. 结论

关系系统**第一次可见**：朋友在旁边一起干活时，居民卡多一行；否则**什么都不说**。
**1479 / 1479** 游戏测试通过（1477 + 2），unit 138/138。

---

## 2. 只在该说话时说话

| 情形 | 卡片 |
| --- | --- |
| 朋友在旁一起干活 | 一行：「有个朋友在旁边一起干活」 |
| 独自干活 / 没有朋友 | **不加行** |

理由与心情那条一致：**卡片上永远存在的提示，等于教玩家别再看卡片。**

---

## 3. 交付

| 文件 | 层 | 内容 |
| --- | --- | --- |
| `Companion.java` | L1 新文件 | `NoticeKind`，裸键 `folkways.relate.companion`（沿用 mood 的键形） |
| `RelateFacing.java` | L1 新文件 | `lookLines` → `linesFor(amongFriends)`；规则抽成静态方法可测 |
| `RelationContent.enroll` | L1 | 注册 facing（`registering.facing(...)`） |
| 四个语言文件 | L2 | 各 +1 键（en / zh_cn / zh_hk / zh_tw），JSON 逐个校验 |

---

## 4. 两个测试

| 测试 | 断言 |
| --- | --- |
| `theLineOnlyAppearsWithCompany` | 独自 → **0 行**；有朋友 → **1 行** |
| `theLineHasWordsInTheLanguageTable` | 键在运行时语言表里能解析（不是原始键名） |

```
[12:17:16] All 1479 required tests passed :)
npm run test:unit → 138 / 138
```

---

## 5. 一个必须记下来的门禁缺口（本轮发现）

我们自己在旧分支上加过一条 **"枚举型 NoticeKind 必须有译文"** 的 i18n 检查（VERIFY-045/047 提过，`Mood` 就栽在它手里）。
**移植时它没跟过来**——因为上游把承载它的 `tests/i18n/lang.test.ts` 删了。

| 影响 | 说明 |
| --- | --- |
| 现状 | 没有任何 CI 检查新的 `NoticeKind` 是否遵守裸键约定 |
| 兜底 | 每个 NoticeKind 的 gametest 里有一条"键能解析"的断言（本轮 `RelationFacingGameTests` 就是这样） |
| 债务 | 记为 **D18**：把那条枚举键检查补回移植后的仓库 |

**这不是猜的**：`grep` 过 `tests/`，那个测试确实不存在；上游的 `test:unit` 只跑 `tests/**/*.test.ts`。

---

## 6. 下一步

| # | 任务 |
| --- | --- |
| R1-5 | 解释层：说清"他心情好是因为和 X 一起干活"（沿用 `Explanation` 单一映射点） |
| R1-6 | 收口报告 + 债务 |
| D18 | 把 i18n 枚举键检查补回 |
