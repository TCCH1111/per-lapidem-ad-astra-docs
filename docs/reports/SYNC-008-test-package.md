# SYNC-008 · 移植版测试包（48 个文件 / 10 个 `plaa_*` + 38 个依赖）

```
状态：产物就绪，等待游戏内实测
验证者：DSH 会话
验证日期：2026-11-05
关联：SYNC-007（1467/1467）、D15
移植分支：port/aaac8b8 @ 1ea1dac
```

---

## 1. 为什么先做这个

代码侧已经全绿（1467/1467），但**测试全绿 ≠ 装进游戏能玩**。这份移植动过：

- modid（10 个模块、69 处代码字面量）
- 插件注册（steering / hours / mood 接回 `BuiltinPlugins`、`PersonPlugin`）
- 配置文件名（`serverconfig/plaa_*-server.toml`）
- CI 与构建布局

**这些恰恰只有进游戏才能确认。**

---

## 2. 一个必须先说清楚的事实

新模块的外部依赖是 **`required`**，不是可选：

| 模块 | 必需依赖 |
| --- | --- |
| `plaa-cookery` | `kaleidoscope_cookery`（`kaleidoscope_tavern` 可选） |
| `plaa-tacz` | `tacz` |
| `plaa-warfare` | `superbwarfare` + `kotlinforforge` |
| `plaa-firefighting` | `create` + `createfirefightingadd` |
| `plaa-chiselsandbits` | `chiselsandbits`（内含 scena/api/core，jarjar 打包） |
| `plaa-rts` | 无额外依赖 |

因此**不能只丢 10 个 jar**，否则游戏会明确报缺依赖。

---

## 3. 产物

| 项 | 值 |
| --- | --- |
| 目录 | `.cache/dist/port-1ea1dac/`（`mods/` + `README.md`） |
| 压缩包 | `.cache/dist/PLAA-port-1ea1dac.zip`（**216 MB**） |
| 文件数 | **48**（10 个 `plaa-*.jar` + 37 个依赖 jar + 1 个 shaderpack zip） |
| 依赖来源 | port 树的 `.blockwright/mods.json`（= 上游测试夹具集，版本已对齐） |

---

## 4. 加载性已被间接证明

`runGameTestServer` 的服务器**就是**在这套 mod 与依赖下启动的，跑完 1467 条测试——所以"十个 mod 能否一起加载"**不是未知数**。

真正需要人眼确认的是：

| 待确认 | 为什么机器测不了 |
| --- | --- |
| 客户端能进主菜单、模组列表显示 10 个 `plaa_*` | 需要真实客户端与显卡 |
| 殖民书能圈地、能开殖民地 | 需要玩家操作 |
| 禁区/作息/心情三处在界面上正常 | 需要看界面 |
| `serverconfig/plaa_*-server.toml` 正常生成 | 需要跑一局 |

---

## 5. 下一步

把 `.cache/dist/PLAA-port-1ea1dac.zip` 解压到 **新建的** Prism 实例（NeoForge 21.1.264，MC 1.21.1）的 `mods/`，
按包内 `README.md` 走一遍。

崩了就把 `logs/latest.log` + `crash-reports/` 最新报告给我，并说明崩在哪一步。

**这一步过了，才谈 A/B/C（怎么把移植落到 `main`）。**

---

## 6. 追加：mrpack 版本（Prism 直接导入，不用手抄）

原来的 216 MB zip 需要手工复制 48 个文件；现另出一个 Modrinth 格式包，Prism 可一步导入：

| 项 | 值 |
| --- | --- |
| 文件 | `.cache/dist/PLAA-port-1ea1dac.mrpack`（216 MB） |
| 结构 | `modrinth.index.json` + `overrides/mods/`（48 个文件全部随包） |
| `files[]` | 空数组——所有 jar 都在 `overrides/`，安装时不需要联网下载 |
| 依赖声明 | `minecraft 1.21.1` / `neoforge 21.1.264` |
| 校验 | 解压后 `overrides/mods` 48 个文件，其中 `plaa-*.jar` 10 个 |

为什么用"全随包"而不是"按需下载"：这份是测试包，目标是"能装上就能跑"，不该把
网络（Modrinth/CurseForge 可用性）变成额外变量。正式发布版才需要按需下载（分发与许可考量）。

导入步骤：Prism → Add Instance → Import → 选该 .mrpack → 启动。