# VERIFY-042 · M2 / N3：心情读得出来（710/710）

```
状态：通过（N3 完成；N4–N7 待做）
验证者：DSH 会话
验证日期：2026-10-26
关联：PLAN-006（N3）、VERIFY-041（708 基线）
fork 提交：7e72aa6
```

---

## 1. 结论

`PresenceViews.mood(Colony, UUID)` 能从殖民地现有的生活服务里读出**居民心情**；数据全部来自基底自己的量，不new一套。

游戏测试：**`All 710 required tests passed`**（708 + 2）。

---

## 2. 交付

| 文件 | 层 | 内容 |
| --- | --- | --- |
| `LivingPresence.java` | **L2（1 个方法）** | `needsOf(UUID)`：快照出口（肚子水位/上限、`hunger.urgent`、`Rest.alertness`、`Rest.SPENT`、`tiredness.urgent`） |
| `PresenceViews.java` | L1 | `mood(Colony, UUID)` → `Optional<Mood>`；包内 `moodOf(Needs)` 供测试 |
| `PresenceMoodGameTests` | L1 | 2 个测试 |

**关键取舍**：`workRefused` / `workWaiting` **这一层不知道**，于是写死 `false` / `true` 并在注释里说明——**宁可低估情绪，也不要用不知道的信息把它撑起来**。

---

## 3. 两个测试

| 测试 | 断言 |
| --- | --- |
| `theReadOutFollowsTheNeeds` | 饱睡 → `CONTENT`；紧急饥饿 → `DESPERATE`；`null` 快照 → `CONTENT` |
| `askingAboutNothingIsAnswered` | 无殖民地 / 无居民 → `empty`，**不抛异常** |

第 2 条是给界面用的：书页可能在任何状态下被打开。

---

## 4. 证据

```
./gradlew build --offline   → BUILD SUCCESSFUL in 11s
[16:52:37] All 710 required tests passed :)
```

---

## 5. 遗留（与 T2 同款，写明）

**`colony.service(...)` 这条真实查找路径仍未测**——需要殖民地夹具（D9）。当前证明的是"映射正确 + 空路径安全"。

---

## 6. 下一步

**N4：冲突语义**（`needs-first` / `rules-first`）——M2 的张力本体：作息与需求第一次见面。
设计要点已定：**默认保持现状**（需求优先），所以 703→710 的基线不会退；新模式只在显式开启时生效。