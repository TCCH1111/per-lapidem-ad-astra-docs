# 整合包规格

```
状态：草稿
负责人：整合包维护者
最后更新：2026-10-19
上游依据：docs/00-charter.md（C1~C7、ADR-021）、docs/research/05-engineering-and-tooling.md
下游影响：docs/pack/01-modlist.md、02-config-and-datapack.md、03-performance-budget.md、docs/prd/*
```

> 本文定义**这个整合包作为一件产品**的形态：装什么、怎么装、怎么分发、怎么升级、怎么不砸存档。
> 「整合包 = 一堆 mod 的压缩包」是最容易做坏的部分：版本漂移、许可违规、存档报废、性能崩塌，几乎都出在这里。

---

## 1. 形态与目标

| 项 | 决定 |
| --- | --- |
| 目标平台 | Minecraft **1.21.1** |
| 加载器 | **NeoForge 21.1.233+**（与基底 Folkways 对齐） |
| 分发形态 | ① **Modrinth `.mrpack`**（首选）② CurseForge zip（可选）③ 手工安装说明（兜底）④ 专用服务器包 |
| 玩家语言 | 中文为第一语言；**新增内容双语（en_us / zh_cn）**；基底既有四语言文件保留（`zh_hk`/`zh_tw`）（[ADR-017](../00-charter.md)） |
| 目标规模 | 单人 / 2–4 人小服 |
| 配置档位 | 三档：**最小可玩 / 标准 / 完整**（见 §4） |
| 默认难度 | 标准叙述者；可调（对应 [威胁与叙事](../design/07-threats-and-narrative.md)） |
| 是否含自研插件 | 含（独立 jar，随整合包分发；见 §7） |

**R-PACK-1**：整合包必须**可解释**：每个 mod 的存在都要能在 [mod 清单](01-modlist.md) 里找到「它提供什么、为什么需要它」。禁止「顺手加进去的」mod。
**R-PACK-2**：默认档位的 mod 数量**不追求多**。目标是「每个 mod 都被用得上」，而不是「看起来内容丰富」。

---

## 2. 版本与锁定策略

| 组件 | 锁定方式 | 说明 |
| --- | --- | --- |
| Minecraft | `1.21.1` | 硬锁 |
| NeoForge | **`21.1.264`**（2026-10-19 起；首版曾钉 21.1.233） | 基底要求 `[21.1.233,)`。**不能停在 21.1.233**：`jei` 19.64.0.455 要求 ≥ 21.1.238、`supplementaries` 4.0.2 要求 ≥ 21.1.247（服务端冒烟实测 FML 预加载拒绝，见 [k01 §4.2](01-modlist.md)）→ 取 21.1.x 最新（`packwiz migrate loader`）。fork 开发环境仍为 21.1.233，是否同步升级按 [w06 R-BLD-1](../workflow/06-build-and-ci.md) 单独决定 |
| Folkways | **锁定具体 commit/构建**（nightly 会重写，必须记录校验和） | 上游是 pre-release，**不得**使用浮动版本 |
| LDLib2 | 锁定版本（基底要求 `2.2.37+`） | UI 前置 |
| 其它 mod | 每个 mod 锁定**精确版本 + sha512**（沿用基底的 `blockwright.toml` 风格） | 见 [mod 清单](01-modlist.md) |
| 自研插件 | `packVersion` 对齐 | 插件与整合包同版本号 |

**R-PACK-3**：**任何 mod 都不得使用「latest」**。所有版本必须写进清单并可校验（sha512/MD5 + 来源 URL）。
**R-PACK-4**：整合包版本号格式：`<packMajor>.<packMinor>.<patch>+mc<MC>+neoforge<loader>`，例：`0.3.0+mc1.21.1+neoforge21.1.233`。
**R-PACK-5**：升级**任一**「影响存档」的组件（Folkways、我们的插件、任何加方块的 mod），必须走 §8 的存档兼容流程。

---

## 3. 目录结构（整合包工程）

```
pack/
  pack.toml                 # 元数据：名称、版本、作者、MC/loader、目标档位
  index.toml                # 或 modrinth.index.json：文件清单（path + downloads + hashes）
  mods/                     # 仅放「不在分发平台上的」jar（如 Folkways nightly、自研插件）
  config/                   # 全部 mod 与我们的配置（默认值即推荐值）
  defaultconfigs/           # 新世界默认（若平台支持）
  kubejs/                   # 脚本：数据驱动的整合层（见 02-config-and-datapack.md）
  datapacks/                # 我们的数据包（事件/需求/剧本/图案/蓝图）
  resourcepacks/            # 风格统一资源包（可选）
  shaderpacks/              # 光影（可选档位）
  overrides/                # .mrpack 的覆盖目录（config/kubejs/datapacks 等）
  server/                   # 专用服务器包模板（server.properties、启动脚本、EULA 说明）
  README-安装.md            # 面向玩家的安装指南
```

**R-PACK-6**：**config 与 kubejs 必须可复现**：整合包包含的就是默认值，玩家改的是副本；更新时不覆盖玩家改动（靠 `.mrpack` 的 overrides 语义与文档说明）。

---

## 4. 三档配置

| 档位 | 目标玩家 | 内容 | mod 数量（估） | 性能目标 |
| --- | --- | --- | --- | --- |
| **最小可玩** | 低配机 / 只想玩核心 | 基底 + LDLib2 + 必要前置 + 最少 QoL + 我们的插件 | 15–25 | 60 FPS @ 1080p / TPS 稳 |
| **标准（默认）** | 大多数玩家 | + 世界生成 + 生存/食物 + 存储 + 任务引导 + 装饰（精选）+ 性能优化 | 40–70 | 60 FPS / TPS ≥ 20 |
| **完整** | 高配 / 长线玩家 | + 工程与机械（Create 系）+ 交通 + 光影 + 全部内容 mod | 80–120 | 60 FPS（高配）/ TPS ≥ 20 |

**R-PACK-7**：三档共享**同一份设计与同一套自研插件**；差异只在 mod 组合与配置，不产生「两套玩法」。
**R-PACK-8**：玩家自研插件的功能**不得依赖可选的 mod**（例如时代进程不能只在装了 Create 时可用）。可选 mod 只提供**加速/扩展**，不提供**唯一通路**。

---

## 5. 分发与许可

| 项 | 规则 |
| --- | --- |
| 分发平台 | Modrinth 优先（API 友好、许可清晰、支持 `.mrpack`） |
| 许可登记 | [mod 清单](01-modlist.md) 必须有「许可」列；**禁止再分发**的 mod 只能列下载链接，不进包体 |
| 再分发 | 采用 `.mrpack` 的「按需下载」模式可规避大部分问题；jar 内嵌仅用于明确允许或自有内容 |
| 我们的插件 | **MIT**（[ADR-017](../00-charter.md)）；必须在上游 `LICENSE` 之外另附 `NOTICE.md` |
| **非商业约束（2026-10-18 新增）** | 包内含 **CC BY-NC 4.0 资源**的 mod（如 **PoopSkyMod** 的美术资源，其代码是 MIT）→ **整合包必须免费发布、保留署名**；**若要商业化，必须先替换该 mod**（[ADR-019](../00-charter.md)） |
| 署名 | 整合包页面必须列出所有 mod 作者与 Folkways |
| 免责 | 明确说明「非官方，与 Mojang / 各 mod 作者无关联」 |

**R-PACK-9**：每个 mod 的许可必须**逐条核实**（不允许「大概可以」）。对许可不明或禁止整合的 mod，一律不采用。

---

## 6. 安装与开箱体验

| 项 | 要求 |
| --- | --- |
| 安装耗时 | 新玩家 20 分钟内可进入游戏（章程 S6） |
| 安装方式 | 平台一键导入 + 手工说明双通道 |
| 首次进入 | 有引导（任务书/课程）指向「立寨 → 接纳居民 → 划第一块地」 |
| 默认设置 | 已调好：按键、GUI 缩放、渲染距离、音效、难度、叙述者 |
| 中文 | 默认 `zh_cn`（若可配置）；新增内容**双语齐全**，基底既有四语言保留 |
| 崩溃兜底 | 提供排障文档（Java 版本、内存、常见冲突、日志位置） |

**R-PACK-10**：整合包**必须包含一份「第一小时」引导**，且不依赖外部视频/wiki。

---

## 7. 与 fork 的关系（2026-10-18 更新：ADR-007）

> **已决定 fork Folkways 本体**（[ADR-007](../00-charter.md) + [fork 策略](../design/12-fork-strategy.md)）。本节因此完全改写：整合包内置的是**我们自己的 mod**（Folkways 的 fork），不再是"上游 jar + 若干插件"。

| 问题 | 决定 |
| --- | --- |
| 包内装什么 | **我们的 fork jar**（modid 独立，见 [fork 策略](../design/12-fork-strategy.md) §4）+ 其它整合包 mod；**不装**上游 Folkways jar（两者概念冲突，不可共存） |
| 可否与上游共存 | **不可以**：我们的 fork 在 `mods.toml` 中声明与上游 modid 冲突，防止玩家误装导致双套居民/殖民地 |
| 依赖声明 | 我们的 jar 声明 `ldlib2`/`ponder` 等必需依赖（沿用上游）；Create/Sable/GeckoLib 等为 `compileOnly` + 运行时检测 |
| 版本对齐 | mod 版本与整合包版本同批发布，版本号记录在包清单 |
| 卸载行为 | 卸载我们的 mod 时存档必须**能加载**（丢失我们的内容但不崩）；由于 fork 改过存档格式，**降级到上游版本明确拒绝**并提示 |
| 上游署名 | 包内与平台页面必须声明"基于 Folkways（MIT，作者 IzakyL）"并附 `NOTICE.md`（[fork 策略](../design/12-fork-strategy.md) §7） |
| 可选集成 | Create / Sable / Modular Golems / GeckoLib / TLM 等按需，且**不得成为唯一通路**（R-PACK-8） |

> **过渡期（2026-10-19 起，[ADR-022](../00-charter.md)）**：在 fork 能产出 jar 之前，整合包**暂装上游 nightly 的 `folkways-core` / `folkways-vanilla` / `folkways-create`**（@ `67f28b0`，哈希钉死于 `pack/mods/folkways-*.pw.toml`；不装 `folkways-modulargolems`）。nightly 的 URL 固定但内容随上游 `master` 每次推送重写——哈希校验失败即提示"需重钉"，不得静默更新。上表"不装上游 Folkways jar"自 fork 首个 jar 产出之日起生效。

**R-PACK-11（改写）**：我们**可以**修改 Folkways 的内部实现，但必须走 [fork 策略](../design/12-fork-strategy.md) 的**分层登记**（L1 新文件 > L2 小改 > L3 逻辑改动；**L4 结构性重构禁止**），并在代码中加 `// PLA:` 标记，登记到改动表。目的是保住**上游同步能力**。

---

## 8. 升级与存档兼容流程

```
1. 检查上游变更（Folkways / 关键 mod）
2. 在副本存档上验证：加载 → 往返 → 旧版本迁移
3. 更新 mod 清单与校验和
4. 更新自研插件的迁移逻辑（若有数据模型变化）
5. 发布整合包 + 迁移说明（哪些改动不可逆）
6. 保留上一版本以支持回滚
```

| 检查项 | 通过标准 |
| --- | --- |
| 旧存档加载 | 无崩溃；无静默丢数据 |
| 存档往返 | 保存→加载后状态一致 |
| 卸载插件 | 可加载（内容缺失可接受） |
| 降级 | 明确拒绝并提示（不崩溃） |
| 配置文件 | 旧配置可被新版本读取（缺失项取默认值，不覆盖玩家改动） |

---

## 9. 服务器包

| 项 | 内容 |
| --- | --- |
| 必需 | 服务端 mod 集合、`server.properties` 模板、启动脚本（`.bat` / `.sh`）、EULA 说明（**不代接受**） |
| 内存建议 | 最小档 4G，标准档 6G，完整档 8G+ |
| 世界预生成 | 提供说明（用预生成工具），避免探索时卡顿 |
| 备份 | 说明存档位置与备份方法 |
| 权限 | 与 [多人、权限与性能](../design/10-multiplayer-and-server.md) 一致 |
| 反向代理/跨版本 | 不支持跨版本联机（未验证） |

---

## 10. 构建与发布流水线（工程侧）

| 步骤 | 内容 |
| --- | --- |
| 1 | 从 [mod 清单](01-modlist.md) 生成 `index.toml` / `modrinth.index.json`（版本 + 校验和） |
| 2 | 打包 `overrides/`（config、kubejs、datapacks、defaultoptions） |
| 3 | 构建自研插件（Gradle），产物进 `mods/` |
| 4 | 生成 `pack.toml` 元数据与更新日志 |
| 5 | 本地验证：安装 → 启动 → 新世界 → 存档往返 → **双语（`zh_cn` + `en_us`）** |
| 6 | 发布：平台 + 版本标签 + 更新说明 |

**R-PACK-12**：清单文件必须**由数据生成**而非手写，避免版本与校验和错配（清单是唯一事实来源，见 [文档地图](../README.md) 的单源规则）。

### 10.1 本机服务端冒烟测试（2026-10-19 首次建立）

做法：`packwiz serve --port 8085` 起本地 HTTP → 在 `.cache/test-server/` 用 `packwiz-installer-bootstrap.jar -g -s server http://localhost:8085/pack.toml` 装服务端侧文件（client-only 自动跳过）→ NeoForge 安装器 `--install-server` → 启动 `java @user_jvm_args.txt @libraries/net/neoforged/neoforge/<ver>/win_args.txt nogui`（Windows 用 `win_args.txt`，Linux 用 `unix_args.txt`），监控 `logs/latest.log` 出现 `Done (` 后经 stdin 发 `stop`。`eula=true` 仅写在本机测试目录（用户已确认），分发包仍按 §9 不代接受。

| 日期 | NeoForge | 服务端 mod 数 | 结果 | 发现 | 日志 |
| --- | --- | --- | --- | --- | --- |
| 2026-10-19 v2 | 21.1.233 | 42 | **FML 拒绝启动** | `Mod create is incompatible with radium any` → Radium 移出清单（k01） | `.cache/logs/smoke-server-20261019-151654.log` |
| 2026-10-19 v3 | 21.1.233 | 41 | **FML 拒绝启动** | `jei` 要求 ≥ 21.1.238、`supplementaries` 要求 ≥ 21.1.247 → 加载器升级 | `…-151913.log` |
| 2026-10-19 v4 | **21.1.264** | 41 | **通过**：`Done (8.753s)`，优雅 stop，`All dimensions are saved`，0 FATAL / 0 崩溃报告 | Folkways core/vanilla/create 与 LDLib2 正常初始化（`folkways/library` 数据包、9 个图案、4 线程规划器）；1 条 ERROR（`RuntimeDistCleaner`，紧随 `[Rhino] Failed to get declared methods for com.lowdragmc.lowdraglib2.editor.resource.IRendererResource`：KubeJS/Rhino 扫描 LDLib2 自带的 KubeJS 插件时触到客户端类，**良性噪音，与 Folkways 无关**）、13 WARN（ModernFix mixin 可见性提示 ×2、离线模式 ×4、Supplementaries 染色提示、KubeJS 跳过客户端插件、vanilla assets URL ×2、加载耗时 ×2、OSHI 注册表） | `…-152346.log` |

---

## 11. 开放问题

| 编号 | 问题 | 影响 | 何时定 |
| --- | --- | --- | --- |
| OQ-PK-1 | ~~用 packwiz / 平台自带打包工具 / 自建脚本？~~ | **已定：packwiz**（[ADR-021](../00-charter.md)）：`pack/` 即 packwiz 工程（`pack.toml` + `index.toml` + `mods/*.pw.toml`），每个 mod 以 Modrinth **版本 id** 钉死、哈希由 `packwiz refresh` 写入（满足 R-PACK-3 / R-PACK-12）；`packwiz modrinth export` 出 `.mrpack`，`packwiz curseforge export` 出 CF zip；**jar 本体不入库、不进 `pack/`**（本机下载的 jar 暂存 `.cache/mods-modrinth/`，仅供搭本地测试实例）；我们的 fork jar（不在分发平台）用 packwiz 的 URL/本地文件条目登记 | ✅ 已定（2026-10-19） |
| OQ-PK-2 | 三档是否都需要正式发布，还是只发「标准」+ 说明如何裁剪？ | 影响测试面 | M1 前 |
| OQ-PK-3 | 自研插件的许可选择 | 影响社区与再分发 | M1 前 |
| OQ-PK-4 | 是否随包分发资源包/光影（许可与体积） | 影响体验与合规 | M2 前 |
| OQ-PK-5 | 是否提供「无 Create」档（Create 系性能与复杂度都高） | 影响最小档定位 | 收 [mod 清单](01-modlist.md) 调研后定 |