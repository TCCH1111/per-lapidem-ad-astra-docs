# SYNC-022 · 旧 modid 字面量门禁扩到十模块（并发现六模块缺不兼容声明）

```
状态：通过（unit 142/142 · gametest 1488/1488）
验证者：DSH 会话
验证日期：2026-11-06
关联：SYNC-015（事故）、ADR-026、PLAN-001（四模块时代）
分支：main @ b62df24
```

---

## 1. 起点：仓库里已有一条检查，但它只认识 4 个模块

`tests/i18n/mods-toml.test.ts` 里有一条：

> `no upstream modid literal survives outside mods.toml, NOTICE and the contributor docs`

它写于**四模块时代**（PLAN-001），正则只覆盖 `core|vanilla|create|modulargolems`。
移植后我们有 **10 个模块** → **6 个新增模块的旧 id 从未被检查过**。

**做法：扩展这一条，而不是再加一个重复的。**（我中途写过一份新的，随后删掉了——同一件事两条检查是负担。）

---

## 2. 第一次写错了：前缀匹配产生 4 个假阳性

按"包含 `folkways_<module>`"判断，立刻报出 4 个**无辜**的文件：

| 文件 | 内容 | 真相 |
| --- | --- | --- |
| `CreateCandBPlacementGameTests` | `@GameTestHolder("folkways_create_candb")` | 游戏测试**命名空间** |
| `TaczWeaponGameTests` | `TicketType.create("folkways_tacz_test", …)` | 票据名 |
| `TaczDischargeGuard` | `"folkways_tacz_colony"` | 区块票据名 |
| `WarfareGameTests` | `"folkways_warfare_test", …` | 票据名 |

**四个都不是 modid。** 改成**精确匹配**（引号收尾或紧跟冒号）：

```
"folkways_<module>"     ← 精确 id
"folkways_<module>:...  ← 带冒号的 id
```

> 会对名字大喊大叫的门禁，最终会被人们学会无视。

---

## 3. 扩展时发现的第二个问题：六个新模块没有不兼容声明

四个老模块的 `neoforge.mods.toml` 都有 4 条：

```toml
[[dependencies.${mod_id}]]
modId = "folkways_core"
type = "incompatible"
reason = "…本 mod 是 Folkways 的 fork，同一世界只能装一套殖民地系统。"
```

**而 cookery / rts / warfare / tacz / firefighting / chiselsandbits 六个模块一条都没有**（`grep -c incompatible` = 0）。

**后果**：玩家同时装上游 `folkways_cookery` 与我们的 `plaa_cookery`，NeoForge **不会拒绝**，
而是让两套系统同时加载——这正是 ADR-026 要防的情况。

**已按老模块的同一写法补齐 4 条**（指向 `folkways_core/vanilla/create/modulargolems`，与现有约定一致）。

---

## 4. 验证

| 项 | 结果 |
| --- | --- |
| unit（含扩展后的门禁） | **142 / 142** |
| 注入 `"folkways_cookery"` 到源码 | **失败**，点名 `ZZTempStale.java:4 folkways_cookery` |
| 删除后 | **142 / 142** |
| gametest（验证新 toml 块能被解析） | **1488 / 1488** |

```
[20:30:55] All 1488 required tests passed :)
```

---

## 5. 仍然存在的不一致（记下来，不擅自改）

老模块的 4 条不兼容声明只覆盖**上游最初的 4 个 modid**，而上游现在也有 10 个模块。
也就是说：**`folkways_cookery` / `folkways_rts` / … 与我们的同名模块共存时，仍不会被拒绝。**

这与 SYNC-015 的教训同源：**模块数变了，声明没跟着变。**

但改它要同时改既有测试的断言（`incompatible` 必须**恰好**是那 4 个），属于规则变更，
**所以本轮只记录，不动**。
