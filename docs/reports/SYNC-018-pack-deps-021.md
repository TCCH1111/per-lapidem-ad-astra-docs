# SYNC-018 · v0.2.1 分发校验 + 依赖完整性

```
状态：通过（62/62 哈希匹配；10 jar 元数据正确；服务端必需依赖齐全）
验证者：DSH 会话
验证日期：2026-11-06
关联：SYNC-016（发布）、SYNC-011（v0.2.0 同类校验）、D11
```

---

## 1. 校验了什么

| # | 项 | 结果 |
| --- | --- | --- |
| 1 | `.mrpack` 里 **62 个下载条目**逐个下载 + sha1/sha256 核对 | **62 / 62 通过**（279 MB） |
| 2 | 6 个随包文件 | 计入结构，未逐个复校验（前一版已验过，本轮内容未变） |
| 3 | 我们 10 个 jar 的 `mods.toml` | **modId 全为 `plaa_*`、version 全为 `0.2.1`** |
| 4 | **服务端必需依赖是否在包里** | **全部满足**（唯一"缺失"是检查盲区，见 §3） |

---

## 2. 第 4 项的做法

读每个 jar 的 `META-INF/mods.toml`（或 `neoforge.mods.toml`）：

1. 建"包内提供"的 modid 集合（**只取 `[[mods]]` 段**）；
2. 对每个 `plaa_*` jar，取 `type = "required"` 的依赖；
3. 按 `side` 分类：`BOTH`/`SERVER` 必须能在包里找到；`CLIENT` 允许走 jar 内置（jarjar）；
4. `type = "incompatible"` 的项反过来查：**包里不该有它**（我们有 4 模块 × 4 条指向上游 `folkways_*` 的声明）。

结果：

```
plaa-core          服务端必需: ldlib2                    ✅
plaa-vanilla       服务端必需: plaa_core                  ✅
plaa-create        plaa_core, plaa_vanilla, create        ✅
plaa-modulargolems plaa_core, plaa_vanilla, modulargolems ✅
plaa-cookery       plaa_core, plaa_vanilla, kaleidoscope_cookery ✅
plaa-rts           plaa_core, plaa_vanilla                ✅
plaa-warfare       + superbwarfare, kotlinforforge        ⚠️ 见 §3
plaa-tacz          + tacz                                 ✅
plaa-firefighting  + create, createfirefightingadd         ✅
plaa-chiselsandbits + chiselsandbits                       ✅
```

**4 条"与上游 `folkways_*` 不兼容"的声明也没有误伤自己**（包里确实不含 `folkways_*`）。

---

## 3. 唯一的"缺失"是检查的盲区，不是包的问题

`kotlinforforge-5.12.0-all.jar` 在包里，但**它没有 `mods.toml`**（它是语言加载器，modid 由 loader 注册）。
所以脚本读不到 `kotlinforforge` 这个 id，报成"缺失"。

**结论**：包是完整的；检查对"没有 mods.toml 的 jar"无能力，**这一条要如实写明，而不是当成通过**。

同理，`ponder` / `shouldersurfing` 这类 `side = "CLIENT"` 的必需依赖，其 jar 内置在 `plaa_core` 里（toml 的 reason 写明），
本检查**不会**去开嵌套 jar 验证——属未覆盖面。

---

## 4. 这个检查自己也错了两次

| 第几次 | 错在哪 | 现象 |
| --- | --- | --- |
| 1 | 把 `[[dependencies]]` 里的 `modId` 也当成"包内提供" | 报 16 处"声明与 `folkways_core` 不兼容，但它就在包里"——全是假阳性 |
| 2 | 只认 `neoforge.mods.toml`，且 `modId` 正则不允许缩进 | `geckolib` 等被误判缺失 |
| 3 | 没看 `side`，也没考虑 jarjar | `ponder`/`shouldersurfing` 被当成必须随包 |

**三次都是"检查太天真"，不是包有问题。** 这类检查的价值取决于它能不能被证伪——本轮它三次被证伪，最终结论才可信。

---

## 5. 没证的

- **客户端安装与进世界**（D11，唯一硬门槛）；
- 嵌套 jar（ponder 等）是否真的可用——只有客户端能证；
- 62 个模组**同时加载**是否会冲突——服务端侧 VERIFY-048 验过十模块，客户端未验。

---

## 6. 下发建议

给玩家的 `.mrpack`：**[v0.2.1](https://github.com/TCCH1111/per-lapidem-ad-astra/releases/tag/v0.2.1)**（v0.2.0 有 C&B 图案缺陷）。
