# SYNC-020 · pack 规格 vs 实际：三处过期、一处措辞错

```
状态：通过（规格已更正）
验证者：DSH 会话
验证日期：2026-11-06
关联：pack/00-pack-spec.md §12、SYNC-010/016/018/019
```

---

## 1. 核对方法

把 [pack/00-pack-spec.md](../pack/00-pack-spec.md) §12 的每条断言拿去对：

- 实际 `pack/mods/` 的 `.pw.toml`（62 个）；
- 已下载的 v0.2.1 十个 jar（读 `mods.toml` 的依赖块）；
- 已发布的 `.mrpack`（v0.2.2，69 条）。

---

## 2. 核对的结论

| 规格里的断言 | 实际 | 判定 |
| --- | --- | --- |
| 10 个自研 jar 都要进包 | 10 个 `.pw.toml`，全部指向 release URL | ✅ |
| 补 7 个新依赖 `.pw.toml` | 恰为 7 个（cookery / tavern / tacz / superb-warfare / kotlin-forge / firefighting-additions / chisels-and-bits） | ✅ |
| `plaa_cookery` 的 Tavern 是**可选** | jar 内 `kaleidoscope_tavern  optional` | ✅ |
| `plaa_warfare` 需要 Superb Warfare + Kotlin | 两者均 `required BOTH`，且包里都有 | ✅ |
| 资源命名空间仍是 `folkways` | `data/folkways/**` 为主；C&B 的图案用 `data/plaa_chiselsandbits/`（mod 级命名空间，SYNC-015 修正） | ✅（需限定说明） |
| **§12.3 "1467/1467"** | 现在 **1488/1488** | ❌ **过期** |
| **§12.4 "尚未做"三条** | 三条**全部已做**（换条目 / 补依赖 / 重打 mrpack 并校验） | ❌ **过期** |
| **§12.1 标题"随包分发的自研 jar"** | jar **不随包**——自 SYNC-010 起走 release URL，mrpack 里只有 7 个配置文件 | ❌ **措辞错** |

---

## 3. 一处值得写清的细节：Ponder

规格写 `plaa_core` 需要"LDLib2（含 Ponder）"。实际依赖块是：

```
ldlib2           required   BOTH        ← 必须随包提供
ponder           required   CLIENT      ← 必需，但只在客户端，且内置在我们的 jar 里
shouldersurfing  optional   CLIENT
jei / emi / jecharacters   optional    CLIENT
```

**准确的表述**：LDLib2 是**双端必需**；Ponder 是**客户端必需**、且由我们的 jar 内置满足。
这解释了为什么 SYNC-018 的依赖检查里 Ponder 显示为"客户端/内置"，而不是缺失。

---

## 4. 已做的更正

| 位置 | 改成 |
| --- | --- |
| §12.1 标题 | 「十个自研 jar（**走 release URL**，不随包）」 |
| §12.3 | 测试数更新为 **1488/1488**，并补 CI #49 十一作业全绿 |
| §12.4 | 三条改为「✅ 已完成」，附 SYNC-010/016/019 证据 |
| §12.1 表格 `plaa_core` 行 | 补注 Ponder 是 CLIENT 侧必需、jar 内置 |

---

## 5. 为什么值得做这次核对

规格文档最容易腐化的方式不是"写错"，而是**写完就没人再看**：
§12.4 那三条"尚未做"在完成之后又挂了四轮，如果哪天有人照着它去"补做"，会重复劳动甚至改坏。

> **"尚未做"清单是最需要跟着进度更新的一节**——它直接指挥下一步动作。
