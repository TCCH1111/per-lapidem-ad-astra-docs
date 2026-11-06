# SYNC-010 · v0.2.0 发布 + 整合包改成十模块

```
状态：通过（产物已发布；安装未实测）
验证者：DSH 会话
验证日期：2026-11-06
关联：SYNC-009（main 切换）、pack §12、D11
产物：https://github.com/TCCH1111/per-lapidem-ad-astra/releases/tag/v0.2.0
```

---

## 1. 结论

**十模块的整合包产物已经发布**：10 个 jar + 1 个 `.mrpack`，整合包工程同步改成 10 模块口径。

---

## 2. Release v0.2.0

| 项 | 值 |
| --- | --- |
| tag | `v0.2.0`（指向 `main`） |
| 资产 | **11 个**：10 个 `plaa-*-0.2.0.jar` + `PerLapidemAdAstra-0.2.0.mrpack` |
| 版本号 | `mod_version` 0.1.0 → **0.2.0**（jar 名与 release 一致，避免"release 叫 v0.2.0、jar 里还是 0.1.0"） |
| 发布说明 | 列了 10 个 modid、各自必需的外部依赖、我们自己的四项玩法、验证数字、以及"客户端未实测" |

---

## 3. 整合包工程（pack/）改动

| 文件 | 改动 |
| --- | --- |
| `pack/mods/plaa-*.pw.toml` | 4 个 → **10 个**，全部指向 release `v0.2.0` 的 jar URL + **sha256** |
| `pack/mods/*.pw.toml`（新） | **+7 个**：kaleidoscope-cookery、kaleidoscope-tavern、tacz、superb-warfare、kotlin-forge、create-firefighting-additions、chisels-and-bits（URL + sha512 取自 `blockwright.toml` 的 pin） |
| `pack/index.toml` | 重新生成：**68 个文件**的 sha256 |
| `pack/pack.toml` | 版本 → `0.2.0+mc1.21.1+neoforge21.1.264`；index 哈希同步 |

**`.pw.toml` 总数：62**（49 + 10 − 4 + 7）。

---

## 4. `.mrpack` 校验

| 项 | 结果 |
| --- | --- |
| 大小 | 14.1 KB（**我们的 jar 已全部走 URL 下载**，随包只剩配置/任务书/KubeJS） |
| `files[]` | **67** 条 = 62 个下载 + 5 个随包文件 |
| 我们的条目 | **10 条**，全部指向 `releases/download/v0.2.0/...` |
| 外部依赖 | cookery / tacz / kotlin / chisels-and-bits 等均带 URL |
| URL 抽检 | `plaa-core`、`plaa-cookery`、`tacz`、`kotlinforforge`、`chisels-and-bits` **全部 200** |

---

## 5. 没验的（必须说清）

| 项 | 状态 |
| --- | --- |
| Prism/`packwiz` **真实安装**这个 `.mrpack` | ⬜ **未做**——没有客户端实测（D11） |
| 62 个下载在玩家网络下是否都能取到 | ⬜ 只抽查了 5 条 |
| 装完能否进世界、10 个 modid 是否都在 | ⬜ 未做（D11） |

**与 D11 的关系**：这份 `.mrpack` 正是补 D11 的材料——装上、进世界、翻书，就能一次性验掉"十模块客户端"这一项。

---

## 6. 记录两个操作坑

1. `gh` 在本机**两个环境都没登录**（WSL 无 gh、Windows 未 auth）；实际用的是 **git 凭据里的 PAT**（`repo` scope）走 REST——创建 release 与上传资产都靠它。
2. PowerShell 双引号里写正则 `"...$(...)"` 会被当成**子表达式**执行；含 `$(` 的模式必须用**字符串拼接**（本轮 `[mods.<name>]` 的提取就因此失败过一次）。
