# VERIFY-046 · M2 / N6：居民卡上看得见心情（714/714）

```
状态：通过（N6 完成；N7 待做）
验证者：DSH 会话
验证日期：2026-11-05
关联：PLAN-006（N6）、VERIFY-042（心情读数）、VERIFY-044（N5 解释）
fork 提交：0cb72e8
```

---

## 1. 结论

心情**上了居民卡**，而且**没有改动上游的居民页**——`ColonyLooks.of` 本来就会遍历所有已注册 `Facing` 的 `lookLines` 并合并，我们只是注册了自己的一个。

游戏测试：**`All 714 required tests passed`**（712 + 2）。

---

## 2. 交付

| 文件 | 层 | 内容 |
| --- | --- | --- |
| `Mood.java` | L1 改 | `implements NoticeKind`，`translationKey()` 复用 `titleKey()` |
| `MoodContent.java` | L1 新 | 注册 id `folkways:mood` |
| `MoodFacing.java` | L1 新 | `lookLines` 只对**非 CONTENT** 的居民给一行；规则抽成静态 `linesFor` |
| `PersonPlugin.java` | **L2（1 处注册）** | `event.facing(MoodContent.ID, ...)` |
| `MoodFacingGameTests` | L1 | 2 个测试 |

**为什么复用 `Line.of(NoticeKind)`**：基底已有这条序列化通路（`Line.of` + `NoticeKind`），沿用它就**不需要新的网络格式**，也不会碰到客户端协议。

---

## 3. 两个测试

| 测试 | 断言 |
| --- | --- |
| `onlyTroubleReachesTheCard` | `CONTENT` 与 `null` → **0 行**；`WORRIED`/`STRESSED`/`DESPERATE` → **各 1 行** |
| `theCardLinesResolveAtRuntime` | 四档的 `translationKey()` 在运行时语言表里都能解析 |

```
./gradlew build --offline   → BUILD SUCCESSFUL in 12s
[19:28:00] All 714 required tests passed :)
```

---

## 4. 过程中的两次失败（记录，不掩盖）

1. **`MoodFacing` 不是 public** → 跨包注册编译失败 → 改为 `public`；
2. **`Line.of` 要的是 `NoticeKind` 而非 `Notice`** → 我最初写成 `Line.of(Notice.of(mood))` → 直接传 `mood`。

两次都是**编译期**抓到，没有进测试；但它们说明"`Notice` 与 `NoticeKind` 不是一回事"这一点我一开始没读准。

---

## 5. 遗留

| # | 项 | 说明 |
| --- | --- | --- |
| 1 | 卡片上的**行位置**未在客户端确认 | `lookLines` 在健康条之后、`busy` 之前；实际观感需人工验收（并入 D11） |
| 2 | `zh_hk`/`zh_tw` 仍是简体措辞 | 双语润色轮处理 |
| 3 | 心情**不驱动行为** | 它目前只是"读出来"。要让心情影响行为是 M2 后半（含 D12 的 `rules-first`） |
