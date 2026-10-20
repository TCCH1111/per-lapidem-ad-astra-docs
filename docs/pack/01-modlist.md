# 01 · Mod 清单：1.21.1 + NeoForge 可用性核实

状态：草稿（可用性数据已核实；选型裁决待人工）
负责人：整合包技术调研员（agent）
最后更新：2026-10-19（LDLib2 行更正：Modrinth 有 NeoForge 1.21.1 版本，许可 LGPL-3.0-only）
上游依据：[整合包规格](00-pack-spec.md)、[世界与模拟总纲](../design/04-world-and-simulation.md)、[自由度设计纲领](../design/11-freedom-design.md)、[威胁与叙事](../design/07-threats-and-narrative.md)

---

## 1. 说明

### 1.1 核实方法

| 步骤 | 做法 | 用途 |
| --- | --- | --- |
| 精确定位 | `GET https://api.modrinth.com/v2/project/<slug>` | 是否存在、加载器集合、`client_side`/`server_side`、许可 |
| 版本核实 | `GET .../project/<slug>/version?loaders=["neoforge"]&game_versions=["1.21.1"]` | 取得 1.21.1+NeoForge 的**具体版本号、发布日期、类型、必需依赖**（核心证据） |
| 名称→slug | `GET /v2/search?query=...&facets=[["categories:neoforge"],["versions:1.21.1"]]` | 候选按名搜不到时定位真实 slug（如 `farmersdelight`→`farmers-delight`） |
| 依赖反查 | `GET /v2/projects?ids=[...]` | 把依赖 `project_id` 解析成 slug |
| CF 兜底 | `https://api.cfwidget.com/minecraft/mc-mods/<slug>`（CurseForge 公开镜像） | Modrinth 无条目者（FTB、MineColonies、Millenaire、LDLib2、Ice and Fire） |
| FTB 官方渠道 | `https://maven.ftb.dev/releases/dev/ftb/mods/<artifact>/` 目录列表 | FTB 系列 1.21.1 版本号（`2101.x`） |
| GitHub | `github.com/.../branches/all`（HTML） | 分支佐证（Ice and Fire、MineColonies） |

### 1.2 核实日期与数据来源

- **核实日期：2026-10-17**（本机 `Get-Date`，Asia/Hong_Kong）。
- 主源：**Modrinth 官方 API v2**（无 API key，无需登录）。
- 辅源：**api.cfwidget.com**（CurseForge 数据镜像）、**maven.ftb.dev**（FTB 官方发布仓库）、**api.github.com / github.com**。

### 1.3 可信度声明（务必先读）

| 级别 | 含义 | 覆盖范围 |
| --- | --- | --- |
| **A** | Modrinth API 精确版本查询命中：确有 `neoforge` + `1.21.1` 的发布文件，版本号/日期/依赖为 API 原文 | 本表约 80 项 |
| **B** | 非 Modrinth 官方渠道的文件级证据（cfwidget 文件记录的 `versions` 含 `1.21.1`+`NeoForge`；或 FTB 官方 maven 版本号） | FTB 三件套、MineColonies、Millenaire、LDLib2、Ice and Fire（判定为"无"）、Canary（判定为"无"） |
| **C** | 仅搜索 facets 命中（能搜到，但本轮未取精确版本） | 无（本轮所有候选均已取到 A 或 B） |
| **未验证** | 无任何来源可证实 | 见下 |

**未验证项（本轮无法证实，禁止当成事实使用）**：

1. **许可条款中的"整合包分发许可"**：Modrinth 只给 SPDX/许可 ID，cfwidget 不提供该字段；`curseforge.com` 直连返回 **403**，无法读 CF 页面上的 modpack 授权条款。所有 ARR / LicenseRef / PolyForm 条目的**再分发许可均属未验证**，需人工逐页确认。
2. ~~**FTB Quests / Teams / Chunks 的许可与 CF 页面信息**（版本有 B 级证据，许可未验证）。~~ **已核实（2026-10-18）**：`FTBTeam/FTB-Quests`、`FTB-Teams`、`FTB-Chunks`、`FTB-Library` 的 GitHub 仓库**均无开源许可文件** → 事实上的 **ARR**，允许在整合包内使用但**不可 fork / 不可再分发其代码**。结论：**Quests 采用（可选引导）**、**Teams 可选**、**Chunks 不采用**、**Library 随 Quests**（见 k04 与 [ADR-018](../00-charter.md)）。
3. **MineColonies / Millenaire 的必需依赖清单**（cfwidget 文件记录不含依赖字段）。
4. **Ice and Fire 的 1.21.1 状态**：CF 最新文件为 `iceandfire-2.1.13-1.20.1-beta-5.jar`（1.20.1），GitHub 分支页未给出干净的 1.21.1 分支名 → **判定为"当前无 1.21.1"，但"未来是否计划"未验证**。
5. **第三方移植 `alexs-mobs-1.21.1` / `alexs-mobs-continued` 是否获得原作者授权**（未验证）。
6. 沙箱限制：`web_fetch`/浏览器抓取被阻断；`api.github.com` 触发速率限制（403）；`git clone` 不可用。以上均不影响 A/B 级结论，但限制了许可文本与 CF 页面的直接核实。

> 表中"结论"仅为**技术可用性 + 与既有设计的重叠度**判断；凡涉及授权、设计取舍者一律标 **待验证**，不替设计方做决定。

---

## 2. 主表

图例：**端** = `C/S` 两端必需；`C必/S可`、`C可/S必`、`仅客户端`、`仅服务端`。**来源**列 URL 均可直接复现。

### 2.1 核心 / 前置

| 名称 | mod id | MC 版本 | 加载器 | 最新版本 | 发布日期 | 必需依赖 | 端 | 许可 | 与 Folkways 的潜在冲突 | 结论 | 来源 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| LDLib2 | `ldlib`（**Modrinth 亦有**，2026-10-19 以 `GET /v2/project/ldlib` + 版本查询核实，A 级；基底 Gradle 另从 `maven.firstdark.dev/snapshots` 解析 2.2.37 供开发实例） | 1.21.1 ✔ | NF/F/Forge | `mc1.21.1-2.2.42-neoforge`（文件 `ldlib2-neoforge-1.21.1-2.2.42-all.jar`） | 2026-10-04 | — | C/S | **LGPL-3.0-only**（Modrinth 许可字段） | 无（UI 前置；Folkways 四个 jar 的**必需**依赖，版本范围 `[2.2.37,)`） | **采用（必装）** | https://modrinth.com/mod/ldlib |
| GeckoLib | `geckolib` | 1.21.1 ✔ | NF/F/Forge/Q | 4.9.3 | 2026-09-16 | — | C必/S可 | MIT | 无 | 采用 | https://modrinth.com/mod/geckolib |
| Architectury API | `architectury-api` | 1.21.1 ✔ | 全加载器 | 13.0.11+neoforge | 2026-07-23 | — | C/S | LGPL-3.0-only | 无 | 采用 | https://modrinth.com/mod/architectury-api |
| Kotlin for Forge | `kotlin-for-forge` | 1.21.1 ✔ | NF/Forge | 5.12.0 | 2026-06-28 | — | C可/S可 | LGPL-2.1-only | 无 | 待验证（当前无 mod 依赖它） | https://modrinth.com/mod/kotlin-for-forge |
| Modular Golems | `modular-golems`（项目 id `gtGDlsAD`；注意 slug 带连字符） | 1.21.1 ✔ | NF/Forge | **3.1.43**（版本 id `zNXsPDeF`，与上游 `blockwright.toml` 钉版一致） | 2026-08-21 | `l2library` | C/S | **LGPL-2.1-only** | 无——它是 `folkways_modulargolems`（要求 `[3.1.43,)`）的必需前置，使傀儡成为第二种居民 | **采用（必装，[ADR-024](../00-charter.md) §8：四个 Folkways jar 全装）**，2026-10-19 登记 | https://modrinth.com/mod/modular-golems |
| L2 Library | `l2library`（`4Vh3BQ3F`） | 1.21.1 ✔ | NF/Forge | **3.0.8**（`640EOvKh`，与上游钉版一致；3.0.9 为 2026-10-12 新版，未跟进以免与基底编译期 jar 不一致） | 2026-02-06 | — | C/S | **LGPL-2.1-only** | 无（Modular Golems 前置；内嵌 `l2core`/`l2serial`，基底编译期也用它） | **采用（随 Modular Golems）** | https://modrinth.com/mod/l2library |

### 2.2 工程与机械

| 名称 | mod id | MC 版本 | 加载器 | 最新版本 | 发布日期 | 必需依赖 | 端 | 许可 | 与 Folkways 的潜在冲突 | 结论 | 来源 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Create | `create` | 1.21.1 ✔ | NF/Forge | 6.0.10+mc1.21.1 | 2026-04-21 | — | C可/S必 | LicenseRef-Create-Mod-License | 方向 B/B3 的集成对象（居民操作机械） | 采用 | https://modrinth.com/mod/create |
| Create Aeronautics | `create-aeronautics` | 1.21.1 ✔ | NeoForge | 1.3.2+mc1.21.1 | 2026-08-29 | `sable`,`create` | C/S | LicenseRef-Simulated-Project | 移动结构 + 寻路/领地判定的 tick 成本 | 采用 | https://modrinth.com/mod/create-aeronautics |
| Sable | `sable` | 1.21.1 ✔ | NF/Fabric | 2.0.6+mc1.21.1 | 2026-10-03 | — | C/S | PolyForm-Shield-1.0.0 | 同上（子层级物理） | 采用 | https://modrinth.com/mod/sable |
| Steam 'n' Rails（1.21.1 独立项目） | `create-steam-n-rails-1.21.1` | 1.21.1 ✔ | NeoForge | 0.3.0-beta.2+neoforge-mc1.21.1 | 2026-07-27 | `create` | C/S | LGPL-3.0-or-later | 铁路交通网（06 §5 物流） | 待验证（原项目 `create-steam-n-rails` **无 1.21.1**） | https://modrinth.com/mod/create-steam-n-rails-1.21.1 |
| Create Crafts & Additions | `createaddition` | 1.21.1 ✔ | NF/F/Forge/Q | neoforge-1.21.1-1.7.2 | 2026-10-01 | — | C/S | MIT | 电力进入科技树（08 时代） | 采用 | https://modrinth.com/mod/createaddition |
| Immersive Engineering | `immersiveengineering` | 1.21.1 ✔ | NF/Forge | 12.4.2-194 | 2025-07-05 | — | C/S | LicenseRef-Custom | 电力/多方块；与 Create 定位重叠 | 待验证（更新较旧） | https://modrinth.com/mod/immersiveengineering |
| Mekanism | `mekanism` | 1.21.1 ✔ | NF/Forge | 10.7.19.85 | 2026-04-10 | — | C/S | MIT | 强科技树会跳过 08 的时代软门槛 | 待验证 | https://modrinth.com/mod/mekanism |
| Thermal 系列（Expansion/Foundation/Dynamics/Cultivation/Innovation/Locomotion/Integration） | `thermal-*` | **无 1.21.1**（最高 1.20.1） | Forge | — | — | — | — | ARR | — | **不采用** | https://modrinth.com/mod/thermal-expansion |

### 2.3 世界生成

| 名称 | mod id | MC 版本 | 加载器 | 最新版本 | 发布日期 | 必需依赖 | 端 | 许可 | 与 Folkways 的潜在冲突 | 结论 | 来源 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Terralith | `terralith` | 1.21.1 ✔ | 数据包+全加载器 | 2.6.2 | 2026-06-09 | `lithostitched` | C可/S必 | LicenseRef-Stardust-Labs | 群系替换影响 04 §5.1 生态值分布 | 采用 | https://modrinth.com/mod/terralith |
| Tectonic | `tectonic` | 1.21.1 ✔ | 数据包+全加载器 | 3.0.28-neoforge-21.1 | 2026-09-11 | `lithostitched` | C可/S必 | MIT | 地形尺度影响选址/矿脉（04 §5.2） | 采用 | https://modrinth.com/mod/tectonic |
| Lithostitched | `lithostitched` | 1.21.1 ✔ | NF/F/Forge | 1.8.1-neoforge-21.1 | 2026-10-14 | — | 仅服务端 | MIT | 无（三款世界生成的公共前置） | 采用 | https://modrinth.com/mod/lithostitched |
| Biomes O' Plenty | `biomes-o-plenty` | 1.21.1 ✔ | NF/F/Forge | 21.1.0.14 | 2026-06-20（beta） | `glitchcore`,`terrablender` | C/S | ARR | 与 Terralith 争夺群系权重，须测共存 | 待验证（与 Terralith 二选一或调权重） | https://modrinth.com/mod/biomes-o-plenty |
| Regions Unexplored | `regions-unexplored` | 1.21.1 ✔ | NF/F/Forge/Q | 0.6.2-neoforge-21.1 | 2026-07-12 | `lithostitched` | C/S | MIT | 同上 | 待验证 | https://modrinth.com/mod/regions-unexplored |

### 2.4 生存与环境

| 名称 | mod id | MC 版本 | 加载器 | 最新版本 | 发布日期 | 必需依赖 | 端 | 许可 | 与 Folkways 的潜在冲突 | 结论 | 来源 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Serene Seasons | `serene-seasons` | 1.21.1 ✔ | NF/F/Forge | 10.1.0.9 | 2026-09-05（beta） | `glitchcore` | C/S | **ARR**（LICENSE 全文仅 "All rights reserved."） | 与我们的自研季节**重复**（两套季节会打架） | **可选传感器，非必需**（`compileOnly` + 运行期可选；**必须能无它运行**；不得打包/拷贝）——[r08 §2](../research/08-temperature-thirst-integration.md) |
| Cold Sweat | `cold-sweat` | 1.21.1 ✔ | NF/Forge | 2.4.4 | 2026-10-16 | — | C/S | **GPL-3.0-or-later**（四份声明互相矛盾，保守处理） | 与自研温度重复 | **可选传感器**：`EnableTemperatureEvent.setEnabled(true)` 可把 `folkways:resident` 拉进它的温度模型（**A 级**，r08 §1）；但**不 fork**、不作唯一通路 |
| Thirst Was Taken | `thirst-was-taken` | 1.21.1 ✔ | NF/Forge | 1.21.1-2.1.5 | 2025-09-21 | — | C/S | MIT | 纯玩家（`IThirst.tick(Player)`） | **不采用于居民**：NPC 无入口（r08 §3）→ 口渴**自研** |
| Tough As Nails | `tough-as-nails` | 1.21.1 ✔ | NF/Forge | beta | — | — | C/S | ARR | 纯玩家（`ThirstHelper.getThirst(Player)`） | **不采用于居民**（同上）；仅作玩家侧可选 |
| Farmer's Delight | `farmers-delight` | 1.21.1 ✔ | NF/Forge | 1.21.1-1.3.4 | 2026-08-29 | — | C/S | MIT | 低（食物内容层，可被烹饪/农业系统吸收） | 采用 | https://modrinth.com/mod/farmers-delight |
| Diet | `diet` | **无 1.21.1**（最高 1.20.1） | Fabric/Forge/Quilt | — | — | — | — | LGPL-3.0-or-later | — | **不采用** → 替代 `nutritional-balance` | https://modrinth.com/mod/diet |
| Comforts | `comforts` | 1.21.1 ✔ | NF/F/Forge/Q | 9.0.5+1.21.1 | 2026-01-24 | — | C/S | LGPL-3.0-or-later | 低（睡袋/吊床，与休息需求相关性弱） | 采用 | https://modrinth.com/mod/comforts |
| Tough As Nails | `tough-as-nails` | 1.21.1 ✔ | NF/F/Forge | 10.1.0.13 | 2024-10-22（beta） | `glitchcore` | C/S | ARR | 温度+口渴双系统重复（04 §4.2） | 待验证（停更于 2024） | https://modrinth.com/mod/tough-as-nails |
| **PoopSky** | `poopsky` | 1.21.1 ✔ | NeoForge | 2.2.1+NeoForge1.21.1（NF 21.1.248） | 2026-10-15 | — | C/S | **代码 MIT**（`LICENSE-CODE`）+ **美术 CC BY-NC 4.0**（`LICENSE-ASSETS`） | 低（只提供厕所/马桶与相关物品，不提供需求；我们只把它映射成 `ToiletNode`） | **采用**（[ADR-019](../00-charter.md)；**缺它必须能降级为自建茅厕**；⚠️ NC → 整合包免费发布即可，需署名；商业化前替换） | https://github.com/Altnoir/PoopSkyMod |
| Pollution of the Realms | `pollution-of-the-realms` | — | — | — | — | — | C/S | **CC-BY-ND 4.0**（**禁止演绎**） | 与我们的自研气体/污染层重复；**ND 使我们无法按其理念改造** | **不采用**（只作参照；禁改、不打包） | — |
| RePother Reload | `repother-reload` | 1.21.1（仓库 `wuziyue840/repother-reload`，Java，main 分支） | NeoForge（推定） | 无发布版本可考 | 2026-08-01（最后提交） | — | — | **无任何许可证文件 = ARR**；**0 star** | 同上；且**许可不明 = 不可打包、不可 fork、不可作依赖** | **不采用**（只作参照；[ADR-016](../00-charter.md)、d13 §4.3 R-GAS-31） | https://github.com/wuziyue840/repother-reload |

### 2.5 生物与威胁

| 名称 | mod id | MC 版本 | 加载器 | 最新版本 | 发布日期 | 必需依赖 | 端 | 许可 | 与 Folkways 的潜在冲突 | 结论 | 来源 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Mowzie's Mobs | `mowzies-mobs` | 1.21.1 ✔ | NF/Forge | 1.8.2 | 2026-03-15 | `geckolib` | C/S | LicenseRef-Mowzies | 与 07 §2 威胁分类的强度曲线需调 | 采用 | https://modrinth.com/mod/mowzies-mobs |
| Ice and Fire | `ice-and-fire-dragons`（CF） | **无 1.21.1**（最高 1.20.1） | Forge/NeoForge | 2.1.13-1.20.1-beta-5 | 未取得 | 未验证 | C/S | 未验证 | — | **不采用**（1.21.1 无版本） | https://api.cfwidget.com/minecraft/mc-mods/ice-and-fire-dragons |
| Alex's Mobs（官方） | 无（Modrinth slug `alexsmobs` 404；CF slug 未核实） | **未见 1.21.1** | — | — | — | — | — | 未验证 | — | **不采用**（官方无 1.21.1 证据，仅见移植） | https://api.modrinth.com/v2/search?query=alex%27s+mobs&facets=%5B%5B%22categories%3Aneoforge%22%5D%2C%5B%22versions%3A1.21.1%22%5D%5D |
| Alex's Mobs（非官方移植） | `alexs-mobs-1.21.1` | 1.21.1 ✔ | NeoForge | 1.22.17 | 2026-01-26 | `citadel-1.21.1-port` | C/S | GPL-3.0-only | 同上 | 待验证（第三方移植，授权未验证） | https://modrinth.com/mod/alexs-mobs-1.21.1 |
| Alex's Mobs Continued | `alexs-mobs-continued` | 1.21.1 ✔ | NF/F/Forge | 2.2.3+1.21.1-neoforge | 2026-10-16 | `codxlib` | C/S | GPL-3.0-only | 同上 | 待验证（第三方移植） | https://modrinth.com/mod/alexs-mobs-continued |
| Born in Chaos | `borninchaos` | 1.21.1 ✔ | NF/Forge | 1.7.6 | 2026-06-17 | `geckolib` | C/S | ARR | 与 07 事件/袭击系统的强度耦合 | **移除**（2026-10-20：ARR + 31 个自引用 parent 导致 41 条模型告警，包内无法覆盖，见 [VERIFY-007](../reports/VERIFY-007-missing-models.md)；威胁内容由 `mowzies-mobs` + 自研事件承担） | https://modrinth.com/mod/borninchaos |
| Better Combat | `better-combat` | 1.21.1 ✔ | NF/F/Forge | 2.4.0+1.21.1-neoforge | 2026-07-14 | `playeranimator`,`cloth-config` | C/S | ARR | 与 07 §5.4 战斗实现边界重叠 | 待验证（与 Epic Fight **互斥**） | https://modrinth.com/mod/better-combat |
| Epic Fight | `epic-fight` | 1.21.1 ✔ | NF/Forge | 21.17.3.1-mc1.21.1-neoforge | 2026-05-31 | — | C/S | GPL-3.0-or-later | 同上；动画/骨骼会改动所有生物表现 | 待验证（与 Better Combat **互斥**） | https://modrinth.com/mod/epic-fight |
| Guard Villagers | `guard-villagers` | 1.21.1 ✔ | NF/Forge | 2.4.12 | 2026-08-30 | — | C/S | LicenseRef-Custom | 与殖民地防卫/居民角色重叠（07 §5.3） | 待验证 | https://modrinth.com/mod/guard-villagers |
| Naturalist | `naturalist` | 1.21.1 ✔ | NF/F/Forge | 2.0.5+1.21.1-neoforge | 2026-09-28 | — | C/S | LicenseRef-Custom | 动物行为与 04 §5.1 生态模拟重叠 | 待验证 | https://modrinth.com/mod/naturalist |

### 2.6 殖民 / 村庄同类（**仅作对比，不建议采用**）

| 名称 | mod id | MC 版本 | 加载器 | 最新版本 | 发布日期 | 必需依赖 | 端 | 许可 | 与 Folkways 的潜在冲突 | 结论 | 来源 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| MineColonies | `minecolonies`（CF） | 1.21.1 ✔ | NeoForge | 1.1.1403 | 2026-10-04 | 未验证 | C/S | GPL-3.0-or-later | **两套殖民 AI 根本冲突**（居民/职业/建筑全重叠） | **不采用**（对比样本） | https://api.cfwidget.com/minecraft/mc-mods/minecolonies |
| Millenaire | `millenaire`（CF） | 1.21.1 ✔ | NeoForge | 9.0.2 | 未取得 | 未验证 | C/S | 未验证 | 同上（含 NPC 村庄经济） | **不采用**（对比样本，可读其村庄 AI 设计） | https://api.cfwidget.com/minecraft/mc-mods/millenaire |
| TekTopia | `tektopia`（CF） | 最高 1.12.2 | Forge | — | — | — | — | 未验证 | — | **不采用**（已停更） | https://modrinth.com/mod/tektopia-addons |
| Ancient Warfare 3 | `ancient-warfare` | **无 1.21.1** | Forge | — | — | — | — | LicenseRef-Custom | — | **不采用** | https://modrinth.com/mod/ancient-warfare |

### 2.7 存储与物流

| 名称 | mod id | MC 版本 | 加载器 | 最新版本 | 发布日期 | 必需依赖 | 端 | 许可 | 与 Folkways 的潜在冲突 | 结论 | 来源 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Sophisticated Storage | `sophisticated-storage` | 1.21.1 ✔ | NF/Forge | 1.21.1-1.6.7.2184 | 2026-10-15 | `sophisticated-core` | C/S | ARR | 与 06 §4 存储层级/库存规则重叠（可作实现层） | 待验证 | https://modrinth.com/mod/sophisticated-storage |
| Functional Storage | `functional-storage` | 1.21.1 ✔ | NF/Forge | 1.21-1.5.7 | 2026-06-01（beta） | `titanium` | C/S | MIT | 低（抽屉类存储） | 采用 | https://modrinth.com/mod/functional-storage |
| Storage Drawers | `storagedrawers` | 1.21.1 ✔ | NF/F/Forge | 1.21.1-13.11.4 | 2025-09-14 | — | C/S | MIT | 低；与 Functional Storage 功能重叠 | 采用（与上者二选一） | https://modrinth.com/mod/storagedrawers |
| AE2 | `ae2` | 1.21.1 ✔ | NF/F/Forge | 19.2.18 | 2026-09-27 | `guideme` | C/S | LicenseRef-Multiple | 自动化库存绕过 06 §4.2 Store Rule 的规划语义 | 待验证 | https://modrinth.com/mod/ae2 |
| Refined Storage | `refined-storage` | 1.21.1 ✔ | NF/F/Forge | 2.0.9 | 2026-06-07 | — | C/S | MIT | 同上；与 AE2 二选一 | 待验证 | https://modrinth.com/mod/refined-storage |

### 2.8 太空 / 终局

| 名称 | mod id | MC 版本 | 加载器 | 最新版本 | 发布日期 | 必需依赖 | 端 | 许可 | 与 Folkways 的潜在冲突 | 结论 | 来源 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Ad Astra | `ad-astra` | 1.21.1 ✔ | NF/F/Forge | 1.16.26 | 2026-09-13 | `resourceful-lib`,`resourceful-config`,`common-storage-lib` | C/S | LicenseRef-Terrarium（全文未取得） | 火箭是**实体**（`RocketItem`），与 ADR-011「居民建多方块火箭」冲突 | **只作维度/环境素材**（`adastra.api.*` 的氧/重力/温度可省一大截）；不用其火箭实体（[r09 §4](../research/09-space-endgame.md)） | https://modrinth.com/mod/ad-astra |
| Stellaris | `stellaris` | 1.21.1 ✔ | NF/Fabric | 1.4.25 | 2026-07-09 | `architectury-api`,`potentials` | C/S | **CC-BY-NC-SA-4.0** | 无 api 包（仅 client events）；NC 许可禁止商用 | **不进主线**（与 Ad Astra 重复；NC 条款） | https://modrinth.com/mod/stellaris |
| Cosmic Horizons | `cosmic-horizons`（CF） | **无 1.21.1**（最高 1.20.1） | Forge | 0.0.7.3 | 未取得 | 未验证 | C/S | 未验证 | — | **不采用** | https://api.cfwidget.com/minecraft/mc-mods/cosmic-horizons |
| Creating Space | `creating-space` | 1.21.1 ✔ | NF/Forge | 1.7.18 | 2026-05-03 | `create` | C/S | **MIT** | 与自研多方块火箭功能重复 | **备选/素材**：多方块（Create contraption）+ `RocketSchedule` API + 密封房间生命维持可借鉴；**是否收非玩家 actor 未验证**（r09 §6） | https://modrinth.com/mod/creating-space |
| Deep Space | `deep-space` | 1.21.1 ✔ | NeoForge | 1.4.5-RELEASE | 2026-07-19 | `veil`,`create`（**实际还缺 `dimensional-sable`，未声明**） | C/S | MIT | ⚠️ **隐式依赖未声明**：mixin 目标 `dev.egg.SubLevelWarper` 属 `dimensional-sable` | **若要进包，必须同时进 `dimensional-sable`（MIT）**，并做一次"不带它的崩溃验证"（r09 §0.5/§7） | https://modrinth.com/mod/deep-space |
| Create rockets | `create-rockets` | 1.21.1 ✔ | NeoForge | 0.5 | 2026-05-11 | `create-aeronautics`,`create` | C/S | MIT | 只是 Sable 推力器（`BlockEntityPropeller`），**无火箭语义/无状态机/无维度** | **不采用**（备选路线 B 的零件，非火箭） | https://modrinth.com/mod/create-rockets |
| Advanced Rocketry 3 | `advanced-rocketry-3` | 1.21.1 ✔ | NeoForge | 3.0.beta | 2026-08-19 | 未验证 | C/S | **ARR** | 功能最完整（装配厂/空间站维度/LifeSupport）但**无 api 包、beta、ARR** | **不进主线、不作编译期依赖**；分发许可未确认前不得进包 | https://modrinth.com/mod/advanced-rocketry-3 |
| Spaceward Expansion | `spaceward-expansion` | 1.21.1 ✔ | NF/Fabric | 1.2.3 | 2024-08-20 | — | C/S | ARR | — | **不采用**（2024 后未更新） | https://modrinth.com/mod/spaceward-expansion |

### 2.9 任务 / 引导 / 数据自由

| 名称 | mod id | MC 版本 | 加载器 | 最新版本 | 发布日期 | 必需依赖 | 端 | 许可 | 与 Folkways 的潜在冲突 | 结论 | 来源 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| FTB Quests (NeoForge) | `ftb-quests`（CF） | 1.21.1 ✔ | NeoForge | 2101.1.36 | 2026-09-15 | `ftb-library-neoforge`,`ftb-teams` | C/S | **ARR（GitHub `FTBTeam/FTB-Quests` 无许可文件，2026-10-18 核实；允许在整合包内使用，不可 fork/再分发代码）** | 与 09 §7 教学（Lessons）重叠，需分工 | **采用（可选引导任务书，[k04](04-quest-book-and-guidance.md)；缺失必须可玩）** | https://maven.ftb.dev/releases/dev/ftb/mods/ftb-quests-neoforge/ |
| FTB Teams (NeoForge) | `ftb-teams`（CF） | 1.21.1 ✔ | NeoForge | 2101.1.11 | 2026-08-24 | `ftb-library-neoforge` | C/S | **ARR（同上，2026-10-18 核实）** | 与 10 §3 权限/队伍模型重叠 | **必装**（2026-10-20：FTB Quests 把它声明为 `required`；**不启用它的权限功能**，权限以 [PRD-012](../prd/PRD-012-multiplayer-and-permissions.md) 为唯一来源） | https://maven.ftb.dev/releases/dev/ftb/mods/ftb-teams-neoforge/ |
| FTB Chunks (NeoForge) | `ftb-chunks`（CF） | 1.21.1 ✔ | NeoForge | 2101.1.22 | 2026-09-02 | `ftb-library-neoforge` | C/S | **ARR（同上，2026-10-18 核实）** | 区块认领与 10 §3 领地/权限重叠 | **不采用**（区块认领/传送与我们自己的禁限区与领土概念**会打架**，留着只会让玩家困惑） | https://maven.ftb.dev/releases/dev/ftb/mods/ftb-chunks-neoforge/ |
| FTB Library (NeoForge) | `ftb-library`（CF） | 1.21.1 ✔ | NeoForge | 2101.1.37 | 未取得 | — | C/S | **ARR（同上，2026-10-18 核实）** | 无（FTB 三件套前置） | **随 Quests 进包**（仅作前置；版本必须与 Quests 成套，混用不同 `2101.x` 会崩） | https://maven.ftb.dev/releases/dev/ftb/mods/ftb-library-neoforge/ |
| KubeJS | `kubejs` | 1.21.1 ✔ | 全加载器 | 2101.7.2-build.377 | 2026-09-09 | `rhino`,`better-advanced-tooltips` | C可/S可 | LGPL-3.0-only | 无（P6「一切可被改写」的主力工具） | 采用 | https://modrinth.com/mod/kubejs |
| CraftTweaker | `crafttweaker` | 1.21.1 ✔ | NF/F/Forge | 21.0.38 | 2026-03-17 | — | C/S | MIT | 与 KubeJS 功能重叠（脚本层二选一） | 待验证（与 KubeJS 二选一） | https://modrinth.com/mod/crafttweaker |
| Configured | `configured` | 1.21.1 ✔（**仅 Fabric**） | Fabric | v1.9.5mc1.21.11 等全为 fabric | — | — | 仅服务端 | MIT | — | **不采用**（NeoForge 1.21.1 无版本） | https://modrinth.com/mod/configured |
| Jade | `jade` | 1.21.1 ✔ | 全加载器 | 15.10.6+neoforge | 2026-08-06 | — | C可/S可 | **CC-BY-NC-SA-4.0** | 与 09 §5 覆盖层信息设计重叠 | 采用（NC 许可需注意） | https://modrinth.com/mod/jade |
| JEI | `jei` | 1.21.1 ✔ | NF/F/Forge | 19.64.0.455 | 2026-10-16 | `mezzconfig` | C可/S可 | MIT | 与 EMI 二选一 | 采用（二选一） | https://modrinth.com/mod/jei |
| EMI | `emi` | 1.21.1 ✔ | 全加载器 | 1.1.24+1.21.1+neoforge | 2026-05-13 | — | C必/S可 | MIT | 与 JEI 二选一（EMI 更偏合成树） | 采用（二选一） | https://modrinth.com/mod/emi |

### 2.10 QoL

| 名称 | mod id | MC 版本 | 加载器 | 最新版本 | 发布日期 | 必需依赖 | 端 | 许可 | 与 Folkways 的潜在冲突 | 结论 | 来源 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Corpse | `corpse` | 1.21.1 ✔ | NF/Forge | neoforge-1.21.1-1.1.21 | 2026-10-15 | — | C/S | ARR | 与 05 §6 死亡/葬礼语义略有张力（尸体可回收） | 采用 | https://modrinth.com/mod/corpse |
| Sophisticated Backpacks | `sophisticated-backpacks` | 1.21.1 ✔ | NF/Forge | 1.21.1-3.26.12.2208 | 2026-10-13 | `sophisticated-core` | C/S | ARR | 与 06 §4.1 存储层级重叠 | 采用 | https://modrinth.com/mod/sophisticated-backpacks |
| Traveler's Backpack | `travelersbackpack` | 1.21.1 ✔ | NF/F/Forge | 1.21.1-10.1.39 | 2026-08-29 | — | C/S | LGPL-3.0-only | 与上者二选一 | 采用（二选一） | https://modrinth.com/mod/travelersbackpack |
| Waystones | `waystones` | 1.21.1 ✔ | NF/F/Forge | 21.1.46+neoforge-1.21.1 | 2026-09-25 | `balm` | C/S | ARR | 与 06 §5 交通网/基底 rail 定位冲突（传送 vs 铁路） | 待验证 | https://modrinth.com/mod/waystones |
| Carry On | `carry-on` | 1.21.1 ✔ | NF/F/Forge | 2.2.6 | 2026-07-26 | — | C/S | LGPL-3.0-only | 低（搬运方块） | 采用 | https://modrinth.com/mod/carry-on |
| Xaero's Minimap | `xaeros-minimap` | 1.21.1 ✔ | NF/F/Forge/Q | neoforge-1.21.1-26.6.0 | 2026-10-05 | — | C必/S可 | ARR | 与 09 §5 覆盖层/地图设计重叠 | 采用（与 JourneyMap 二选一） | https://modrinth.com/mod/xaeros-minimap |
| Xaero's World Map | `xaeros-world-map` | 1.21.1 ✔ | NF/F/Forge/Q | neoforge-1.21.1-1.47.0 | 2026-10-05 | — | C必/S可 | ARR | 同上 | 采用 | https://modrinth.com/mod/xaeros-world-map |
| JourneyMap | `journeymap` | 1.21.1 ✔ | NF/F/Forge/Paper/Q | 1.21.1-6.0.9+neoforge | 2026-09-19 | — | C可/S可 | ARR | 同上（服务端可提供网页地图） | 采用（二选一） | https://modrinth.com/mod/journeymap |

### 2.11 装饰与建筑

| 名称 | mod id | MC 版本 | 加载器 | 最新版本 | 发布日期 | 必需依赖 | 端 | 许可 | 与 Folkways 的潜在冲突 | 结论 | 来源 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Macaw's Bridges | `macaws-bridges` | 1.21.1 ✔ | NF/F/Forge | 3.1.2 | 2026-02-15 | — | C/S | ARR | 低 | 采用 | https://modrinth.com/mod/macaws-bridges |
| Macaw's Roofs | `macaws-roofs` | 1.21.1 ✔ | NF/F/Forge | 2.3.2 | 2025-05-04 | — | C/S | ARR | 低（建筑图案可复用其方块） | 采用 | https://modrinth.com/mod/macaws-roofs |
| Macaw's Fences and Walls | `macaws-fences-and-walls` | 1.21.1 ✔ | NF/F/Forge | 1.2.1 | 2025-12-08 | — | C/S | MIT | 低（城墙/防御工事） | 采用 | https://modrinth.com/mod/macaws-fences-and-walls |
| Macaw's Doors | `macaws-doors` | 1.21.1 ✔ | NF/F/Forge | 1.1.5 | 2026-02-13 | — | C/S | MIT | 低 | 采用 | https://modrinth.com/mod/macaws-doors |
| Macaw's Trapdoors | `macaws-trapdoors` | 1.21.1 ✔ | NF/F/Forge | 1.1.5 | 2025-11-24 | — | C/S | MIT | 低 | 采用 | https://modrinth.com/mod/macaws-trapdoors |
| Macaw's Windows | `macaws-windows` | 1.21.1 ✔ | NF/F/Forge | 2.4.2 | 2025-12-10 | — | C/S | ARR | 低 | 采用 | https://modrinth.com/mod/macaws-windows |
| Macaw's Furniture | `macaws-furniture` | 1.21.1 ✔ | NF/F/Forge | 3.4.1 | 2025-11-24 | — | C/S | ARR | 低（可作室内设施外观） | 采用 | https://modrinth.com/mod/macaws-furniture |
| Macaw's Stairs | `macaws-stairs` | 1.21.1 ✔ | NF/F/Forge | 1.0.2 | 2025-12-10 | — | C/S | ARR | 低 | 采用 | https://modrinth.com/mod/macaws-stairs |
| Macaw's Paths and Pavings | `macaws-paths-and-pavings` | 1.21.1 ✔ | NF/F/Forge | 1.1.1 | 2025-09-24 | — | C/S | MIT | 低（道路图案可复用） | 采用 | https://modrinth.com/mod/macaws-paths-and-pavings |
| Macaw's Lights and Lamps | `macaws-lights-and-lamps` | 1.21.1 ✔ | NF/F/Forge | 1.1.5 | 2025-12-07 | — | C/S | ARR | 低（与 04 §4.2 火源保暖弱相关） | 采用 | https://modrinth.com/mod/macaws-lights-and-lamps |
| Handcrafted | `handcrafted` | 1.21.1 ✔ | NF/F/Forge | 4.0.3 | 2025-03-22 | `resourceful-lib` | C/S | LicenseRef-Terrarium | 低 | 采用 | https://modrinth.com/mod/handcrafted |
| Chipped | `chipped` | 1.21.1 ✔ | NF/F/Forge | 4.0.2 | 2024-10-15 | `athena-ctm`,`resourceful-lib` | C/S | ARR | 低（变体量大，注意 JEI/EMI 条目膨胀） | 采用 | https://modrinth.com/mod/chipped |
| Rechiseled | `rechiseled` | 1.21.1 ✔ | NF/F/Forge/Q | 1.2.6-neoforge-mc1.21 | 2026-09-13 | `supermartijn642s-core-lib`,`-config-lib`,`fusion-connected-textures` | C/S | ARR | 低 | 采用 | https://modrinth.com/mod/rechiseled |
| Every Compat (Wood Good) | `every-compat` | 1.21.1 ✔ | NF/F/Forge | 1.21-2.11.54 | 2026-10-17 | `moonlight` | C/S | ARR | 低（自动补全木材变体，去掉大量重复 mod） | 采用 | https://modrinth.com/mod/every-compat |
| Supplementaries | `supplementaries` | 1.21.1 ✔ | NF/F/Forge | 1.21.1-4.0.2 | 2026-10-16 | `moonlight` | C/S | LicenseRef-Supplementaries | 低（部分方块含功能，注意与 Create 重复） | 采用 | https://modrinth.com/mod/supplementaries |
| Quark | `quark` | 1.21.1 ✔ | NF/Forge | 4.1-487 | 2026-10-05 | `zeta` | C/S | **CC-BY-NC-SA-3.0** | 中（QoL 功能多，部分与自研系统语义重叠，需逐项关配置） | 待验证 | https://modrinth.com/mod/quark |

### 2.12 性能优化

| 名称 | mod id | MC 版本 | 加载器 | 最新版本 | 发布日期 | 必需依赖 | 端 | 许可 | 与 Folkways 的潜在冲突 | 结论 | 来源 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Sodium (NeoForge) | `sodium` | 1.21.1 ✔ | NF/Fabric/Q | mc1.21.1-0.8.13-neoforge | 2026-08-28 | — | 仅客户端 | PolyForm-Shield-1.0.0 | 无（G5 性能预算的必需项） | 采用（与 Embeddium 二选一） | https://modrinth.com/mod/sodium |
| Embeddium | `embeddium` | 1.21.1 ✔ | NF/F/Forge | 1.0.15+mc1.21.1 | 2025-01-24 | — | 仅客户端 | LGPL-3.0-only | 同上 | 采用（二选一，较旧） | https://modrinth.com/mod/embeddium |
| Iris Shaders | `iris` | 1.21.1 ✔ | NF/Fabric/Q | 1.8.14-beta.1+1.21.1-neoforge | 2026-06-13（beta） | — | 仅客户端 | LGPL-3.0-only | 无 | 采用（beta） | https://modrinth.com/mod/iris |
| ModernFix | `modernfix` | 1.21.1 ✔ | NF/F/Forge | 5.27.26+mc1.21.1 | 2026-10-08 | — | C可/S可 | LGPL-3.0-only | 无 | 采用（服务端同样受益） | https://modrinth.com/mod/modernfix |
| FerriteCore | `ferrite-core` | 1.21.1 ✔ | 全加载器 | 7.0.3-neoforge | 2026-01-25 | — | C可/S可 | MIT | 无（内存） | 采用 | https://modrinth.com/mod/ferrite-core |
| EntityCulling | `entityculling` | 1.21.1 ✔ | NF/F/Forge/Q | 1.11.3 | 2026-10-08 | — | 仅客户端 | tr7zw-Protective | 无 | 采用 | https://modrinth.com/mod/entityculling |
| ImmediatelyFast | `immediatelyfast` | 1.21.1 ✔ | NF/F/Forge/Q | 1.6.15+1.21.1-neoforge | 2026-10-13 | — | 仅客户端 | LGPL-3.0-or-later | 无 | 采用 | https://modrinth.com/mod/immediatelyfast |
| Clumps | `clumps` | 1.21.1 ✔ | NF/F/Forge | 19.0.0.1 | 2024-08-13 | — | C可/S可 | MIT | 无 | 采用 | https://modrinth.com/mod/clumps |
| Canary | `canary`（CF） | **无 1.21.1**（最新 1.20.4） | Forge | 0.3.3 | 未取得 | — | C可/S可 | LGPL-3.0-only | — | **不采用** → 用 `radium` | https://api.cfwidget.com/minecraft/mc-mods/canary |
| Radium | `radium` | 1.21.1 ✔ | NF/Forge | 0.13.1 | 2024-09-20（beta） | — | 仅服务端 | LGPL-3.0-only | **与 Create 硬冲突**：Create 6.0.10 的 `neoforge.mods.toml` 声明 `incompatible` radium，FML 预加载阶段直接失败（2026-10-19 服务端冒烟实测：`Mod create is incompatible with radium any`，`crash-2026-10-19_15.17.06-fml.txt`） | **不采用**（Create 为必装；且 2024 停更 beta）。已从 `pack/` 移除 | https://modrinth.com/mod/radium |
| Chunky | `chunky` | 1.21.1 ✔ | 全平台 | 1.4.23 | 2025-04-04 | — | C可/S可 | GPL-3.0-only | 无（预生成，搭 LOD/抽象层） | 采用 | https://modrinth.com/mod/chunky |
| spark | `spark` | 1.21.1 ✔ | NF/F/Forge/Q | 1.10.124-neoforge-1.21.1 | 2025-02-23 | — | C可/S可 | GPL-3.0-only | 无（性能诊断，对应 09 §4 诊断性） | 采用 | https://modrinth.com/mod/spark |
| Sodium Dynamic Lights | `sodium-dynamic-lights` | 1.21.1 ✔ | NF/F/Forge | neoforge-1.21.1-1.0.10 | 2025-01-02 | `sodium-options-api`,`sodium` | 仅客户端 | MIT | 无 | 采用 | https://modrinth.com/mod/sodium-dynamic-lights |
| Sound Physics Remastered | `sound-physics-remastered` | 1.21.1 ✔ | NF/F/Forge/Q | neoforge-1.21.1-1.5.1 | 2025-09-25（alpha） | — | C必/S可 | GPL-3.0-only | 弱（声学可增强"世界会回应"） | 待验证（alpha） | https://modrinth.com/mod/sound-physics-remastered |

### 2.13 饮品、药物与成瘾物质来源（2026-10-18 新增）

> 成瘾**规则**只在我们自己的系统里（[PRD-001 §4.3](../prd/PRD-001-needs-mood-memory.md) 的 `addiction` 货架）；下面这些 mod 只提供**物品与配方**。每一支都必须**可整体删除**（ADR-010）。**自建的最基础发酵/蒸馏与草药是兜底**——不装本表任何 mod 时，成瘾系统仍必须完整可玩。

| 名称 | mod id | MC 版本 | 加载器 | 许可 | 结论 | 理由 |
| --- | --- | --- | --- | --- | --- | --- |
| Create Big Pharma | `create-big-pharma` | 1.21.1 ✔ | NeoForge | **Apache-2.0** | **采用（可打包）** | 制药链，许可干净（Modrinth 约 1.6k 下载） |
| Create Pop | `create-pop` | 1.21.1 ✔ | NeoForge | **MIT** | **采用（可打包）** | 工业化饮品/糖类物质来源（约 1.1k 下载） |
| CustomBrewRecipes | `custombrewrecipes` | 1.21.1 ✔（分支 `1.21-neoforge`） | NeoForge | **CC0-1.0** | **采用但需实测** | 让酒/药配方可被数据驱动；2025-03 停更、1 star → 必须跑通再进默认档 |
| Create: Addictives | `create-addictives`（CF） | 1.21.1 ✔ | NeoForge | **ARR（CF 许可字段为空）** | **不打包** | 只作**内容灵感**；其补丁仓 `deR0R0/create-addictives-patcher` 亦无许可、0 star |
| Kaleidoscope Tavern | `kaleidoscope-tavern` | 1.21.1 ✔ | NeoForge | **NOASSERTION（许可不明）** | **不打包（待核实许可）** | 18 star、2026-08 仍更新，但许可不明前不能进包 |

来源：`https://modrinth.com/mod/create-big-pharma`、`https://modrinth.com/mod/create-pop`、`https://github.com/Emafire003/CustomBrewRecipes/tree/1.21-neoforge`、`https://github.com/deR0R0/create-addictives-patcher`、`https://github.com/KaleidoscopeMods/KaleidoscopeTavern`。

---

## 3. 替代与空缺（需要在 NeoForge 1.21.1 上自研的部分）

| # | 类别 | 现状 | 结论 |
| --- | --- | --- | --- |
| 1 | **被外部 API 驱动的季节/温度/口渴系统** | 现成 mod 都是**玩家向**或**不可依赖**：Cold Sweat 可扩展到任意实体（A 级：`EntityTempCap` + `EnableTemperatureEvent`）但许可混乱、NPC 降频 ×40、**行为后果要自己写**；Serene Seasons 是世界级季节但 **ARR**；TAN/TWT 口渴**纯玩家** | **自研居民侧**（体温 + 口渴，挂 `ColonyContext`，照基底 `Hunger` 范式），外部 mod 降级为**三个可整体删除的可选桥接**（[r08 §5](../research/08-temperature-thirst-integration.md)、ADR-010） |
| 2 | **殖民地/居民模拟本体** | NeoForge 1.21.1 上只有 `millenaire` 9.0.2 是活的独立殖民地 AI，且与我们是竞争设计而非组件；MineColonies 同为整体方案 | **自研**（基底 Folkways 已有核心，本项即项目本体） |
| 3 | **配置编辑器** | `Configured` 在 1.21.1 只有 Fabric 版本；Modrinth 无 `catalogue` | **空缺**：需自研轻量配置 GUI，或接受手改 TOML/JSON |
| 4 | **太空终局** | 现成 mod 各有其一但都不满足 ADR-011：[r09 §1](../research/09-space-endgame.md) 核实 `creating-space`（MIT，多方块 Create contraption + `RocketSchedule` API + 密封房间生命维持）、`ad-astra`（火箭是**实体**，但有 `adastra.api.*` 环境 API）、`advanced-rocketry-3`（最完整但 **ARR + beta + 无 API**） | **自研主线**（复用 `build` 建火箭 + 自研空间站维度 + 跨 Realm `Passage`）；Ad Astra 仅作维度/环境素材；AR3/Stellaris 不进主线（ADR-011） |
| 5 | **龙/大型威胁生物** | `ice-and-fire-dragons` 最高 1.20.1 → 1.21.1 无 | **空缺**：威胁来源改用 `mowzies-mobs`/`borninchaos`/自研事件怪 |
| 6 | **官方 Alex's Mobs** | 官方无 1.21.1；只有第三方移植（`alexs-mobs-1.21.1`、`alexs-mobs-continued`，授权未验证） | **空缺/未验证** |
| 7 | **饮食/营养（Diet 类）** | `Diet` 最高 1.20.1；替代候选 `nutritional-balance`（NeoForge 1.21.1 ✔，GPL-3.0） | **改为自研**（并入居民维生/营养系统，ADR-013）：外部营养 mod 只作用玩家，无法驱动居民；见 [PRD-003](../prd/PRD-003-season-temperature-thirst-nutrition.md) |
| 8 | **Thermal 系科技** | 全系列无 1.21.1（ARR） | **不补**：电力用 `createaddition` + `immersiveengineering`/`mekanism` 覆盖 |
| 9 | **Lithium 系优化** | `Canary` 无 1.21.1；`radium` 0.13.1（2024，beta）是唯一对应物，**但与 Create 硬冲突**（§4.2，2026-10-19 实测） | **空缺**：本包内无可用的服务端 Lithium 系优化；[k03 性能预算](03-performance-budget.md) 须按"无 Lithium"评估，候选替代需重新调研 |
| 10 | **外部势力/外交/贸易阵营**（07 §6） | 无任何现成 mod | **自研** |

---

## 4. 风险清单

### 4.1 版本锁定与更新停滞

1. **Create 生态锁**：`create` 6.0.10 → `create-aeronautics` 1.3.2 → `sable` 2.0.6 → `create-rockets` 0.5；`create-steam-n-rails-1.21.1` 仍是 `0.3.0-beta.2`。任一升级都要整链回归测试。
2. **停更/低频更新项**：`radium`（2024-09）、`chunky`（2025-04）、`immersiveengineering`（2025-07）、`storagedrawers`（2025-09）、`spark`（2025-02）、`sodium-dynamic-lights`（2025-01）、`tough-as-nails`（2024-10）、`clumps`（2024-08）、`spaceward-expansion`（2024-08）。→ 1.21.1 已是这些项目的"末期版本"，长期维护风险高。
3. **pre-release 依赖**：`iris`（beta）、`serene-seasons`（beta）、`functional-storage`（beta）、`tough-as-nails`（beta）、`sound-physics-remastered`（alpha）、`radium`（beta）、`steam-n-rails`（beta）、`advanced-rocketry-3`（beta）。

### 4.2 依赖链冲突

- **FTB 三件套**：Quests/Teams/Chunks 均需 `ftb-library-neoforge`（2101.1.37）；版本必须成套，混用不同 `2101.x` 会崩。
- **Moonlight 双载**：`supplementaries` + `every-compat` 共享 `moonlight`。
- **GlitchCore 三载**：`biomes-o-plenty` + `serene-seasons` + `tough-as-nails` 共享 `glitchcore`，且 BOP 另需 `terrablender`。
- **Lithostitched 三载**：`terralith` + `tectonic` + `regions-unexplored`。
- **KubeJS**：`rhino` + `better-advanced-tooltips`（后者是 **NeoForge 专属**，勿与 Forge 版混装）。
- **加载器下限（2026-10-19 服务端冒烟实测，FML 预加载直接拒绝）**：`jei` 19.64.0.455 要求 **NeoForge ≥ 21.1.238**；`supplementaries` 1.21.1-4.0.2 要求 **≥ 21.1.247**；（k01 §2.4）`poopsky` 2.2.1 要求 21.1.248。因此整合包的 NeoForge **不能停在 21.1.233**，须取 21.1.x 最新（k00 §2 允许"或更新的 21.1.x"；基底依赖范围 `[21.1.233,)`）。基底 fork 的开发环境是否同步升级按 [w06 R-BLD-1](../workflow/06-build-and-ci.md) 单独决定。
- **互斥组合（严禁同时装）**：Sodium ↔ Embeddium；Canary ↔ Radium（且 Canary 无 1.21.1）；Better Combat ↔ Epic Fight（动画/攻击判定双重改写）；JEI ↔ EMI（可共存但 UI 会重复，建议二选一）；Xaero's ↔ JourneyMap（小地图/全屏地图功能重叠）；Traveler's Backpack ↔ Sophisticated Backpacks；**Create ↔ Radium（Create 的 mods.toml 硬声明 `incompatible`，FML 拒绝启动——2026-10-19 冒烟实测，非推测）**。

### 4.3 客户端 / 服务端不一致

| 类型 | mod | 说明 |
| --- | --- | --- |
| **仅客户端**（服务端 `unsupported`，绝不能进服务端 mods） | `sodium`、`embeddium`、`iris`、`entityculling`、`immediatelyfast`、`sodium-dynamic-lights` | 放错会导致服务端启动崩溃 |
| **仅服务端**（客户端 `unsupported`） | `lithostitched`、`radium` | `lithostitched` 必须装在服务端才生效 |
| **客户端必需**（进服务端需一同存在但不影响逻辑） | `geckolib`、`xaeros-*`、`emi`、`quark`（两端必需）、`chipped`（两端必需） | 整合包两端版本号必须一致 |

### 4.4 许可风险（**未验证**：CF 条款页 403，无法核对 modpack 授权）

| 风险级 | 许可 / 条目 | 说明 |
| --- | --- | --- |
| **高** | `jade`、`quark`、`stellaris` = **CC-BY-NC-SA**（4.0/3.0/4.0） | 禁止商用 + 要求署名与相同许可；免费发布整合包一般可行，**不得进任何付费渠道**，且需在包内保留署名 |
| **高** | `sable`、`sodium` = **PolyForm Shield 1.0.0** | 含"不得用于竞争产品"条款，商用/托管服务需法务确认 |
| **高** | `create`（Create Mod License）、`create-aeronautics`（Simulated Project License） | 自定义许可，条款需逐条读 |
| **高** | `alexs-mobs-1.21.1`、`alexs-mobs-continued` | 第三方移植，**是否获原作者授权未验证** |
| **中** | 全部 `LicenseRef-All-Rights-Reserved`：`corpse`、`sophisticated-storage/-backpacks`、`waystones`、`xaero-*`、`journeymap`、`chipped`、`rechiseled`、`every-compat`、`macaws-bridges/roofs/windows/furniture/stairs/lights-and-lamps`、`borninchaos`、`serene-seasons`、`tough-as-nails`、`advanced-rocketry-3`、`thermal-*`（无 1.21.1）、`spaceward-expansion`（不采用） | 默认保留所有权利；**必须逐个确认 CF 页面上的 modpack 许可**（本轮无法读取） |
| **中** | `immersiveengineering`(LicenseRef-Custom)、`ae2`(LicenseRef-Multiple)、`terralith`(Stardust Labs)、`ad-astra`(Terrarium)、`handcrafted`(Terrarium)、`mowzies-mobs`、`supplementaries`、`naturalist`、`guard-villagers` | 自定义/多许可条款，需逐页核对 |
| **低** | MIT / LGPL / GPL / Unlicense：`createaddition`、`farmers-delight`、`mekanism`、`crafttweaker`、`jei`、`emi`、`kubejs`、`comforts`、`cold-sweat`、`epic-fight`、`storagedrawers`、`refined-storage`、`functional-storage`、`carry-on`、`travelersbackpack`、`ferrite-core`、`chunky`、`spark`、`clumps`、`radium`、`sound-physics-remastered`、`architectury-api`、`geckolib`、`lithostitched`、`tectonic`、`regions-unexplored` | 允许再分发（GPL/LGPL 需附带源码或声明） |

### 4.5 性能与设计耦合风险

1. **Create + Aeronautics + Sable** 的移动结构会持续触发区块/物理结算，与 04 §8「不加载区块结算」的抽象层冲突，必须设上限（对应 [性能预算](03-performance-budget.md)）。
2. **世界生成三选多**（Terralith × BOP × Regions Unexplored）会互相争夺群系权重，建议只留 1 主 + 1 辅。
3. **战斗大改（Epic Fight）**会改变所有生物动画管线，可能与 `mowzies-mobs`、`borninchaos` 的自定义动画冲突。
4. **`naturalist` + `mowzies-mobs` + `borninchaos`** 增加大量实体，需与 `entityculling`/性能预算一起评估。

---

### 4.6 战斗中/待整合候选（来自 r07 生态调研，**本轮未经 Modrinth 精确核实**）

| 候选 | 类别 | 用途 | 待验证 |
| --- | --- | --- | --- |
| `millenaire` 9.0.2 | 外邦村庄 | 作为「邻村/势力」的可选整合（见 [d07 §6.1](../design/07-threats-and-narrative.md)） | API 稳定性、与我们的 `realms` 边界 |
| `mca-reborn` | 外邦 NPC / 关系模型 | 只借设计或做不可招募的外邦人 | **两套居民实体**冲突风险 |
| `raided` / `the-hordes` / `more-raids` | 袭击来源 | 敌人波次可外包，我们专注居民战斗与后果 | 是否攻击 Folkways 居民实体 |
| `guard-villagers` | 守卫 | 可作外邦守卫（**不能**代替我们的民兵） | 与居民实体隔离 |
| `pillager-caravans` / `better-caravans` | 商队 | 可直接整合提供商队；其数据包格式作为我们货架参照 | 交易表可扩展性 |
| `tough-as-nails` | 温度（beta） | 备选（与 Serene Seasons 同源 GlitchCore） | 1.21.1 仍为 beta |

> 核实方式：Modrinth API 精确版本查询；`web_fetch` 与 `curseforge.com` 直连被沙箱阻断（403），故所有 ARR/自定义许可的**整合包再分发授权**一律标为**未验证**——发布前必须逐页人工确认（见 §4.4）。

---

## 5. 推荐的整合包骨架（三档）

> 数量为 mod 计数（不含数据包/资源包）；`⊕` 表示"二选一，任选其一计入总数"。

### 档位 1 · 最小可玩（约 34 个）

目标：能验证 Folkways 基底 + 世界 + 基本工程，无内容冗余。

> **落地状态（2026-10-19）**：本档已写入 packwiz 工程 `pack/mods/*.pw.toml`（共 47 个元文件 = 下表 35 项（`sodium` 取 Sodium；`radium` 因与 Create 硬冲突移除）+ `ldlib`（必装前置）+ `modular-golems` 与 `l2library`（ADR-024 §8）+ packwiz 按 Modrinth 依赖自动补入的 `rhino`、`better-advanced-tooltips`、`mezzconfig`、`moonlight`、`balm` + 过渡期的 4 个 Folkways nightly jar（[ADR-022](../00-charter.md)））。全部按本表版本以 Modrinth **版本 id** 钉死，37 个 sha512 与 `GET /v2/version_files` 反查一致。`pack/mods/*.pw.toml` 是**锁文件**，本表是**选型依据**：改选型先改本表，再改锁。

| 分组 | mod id |
| --- | --- |
| 前置 | `geckolib`、`architectury-api` |
| 工程 | `create`、`sable`、`create-aeronautics` |
| 世界 | `lithostitched`、`terralith`、`tectonic` |
| 生存 | `farmers-delight`、`comforts` |
| 生物 | `mowzies-mobs`、`borninchaos`、`guard-villagers` |
| 存储 | `storagedrawers` |
| 脚本/信息 | `kubejs`、`jei`、`jade` |
| QoL | `corpse`、`travelersbackpack`、`waystones`、`carry-on`、`xaeros-minimap`、`xaeros-world-map` |
| 装饰 | `supplementaries`、`macaws-bridges`、`macaws-windows`、`macaws-roofs` |
| 性能 | `sodium` ⊕ `embeddium`、`ferrite-core`、`modernfix`、`clumps`、~~`radium`~~（与 Create 冲突，2026-10-19 移除）、`entityculling`、`immediatelyfast`、`spark`、`chunky` |

### 档位 2 · 标准（约 60 个）

在档位 1 基础上加：

| 分组 | mod id |
| --- | --- |
| 前置 | `kotlin-for-forge`、`ldlib2`(待许可) |
| 工程 | `createaddition`、`create-steam-n-rails-1.21.1`、`immersiveengineering` |
| 世界 | `regions-unexplored`、`biomes-o-plenty`（与 Terralith 调权重） |
| 生存/环境 | `serene-seasons` ⊕ `cold-sweat`（**先做设计裁决**）、`thirst-was-taken` |
| 生物 | `naturalist`、`better-combat` ⊕ `epic-fight`、`alexs-mobs-continued`(许可待验) |
| 存储 | `functional-storage`、`sophisticated-storage`、`refined-storage` |
| 脚本 | `crafttweaker` |
| QoL | `sophisticated-backpacks` |
| 装饰 | `handcrafted`、`chipped`、`rechiseled`、`every-compat`、`quark`(需逐项配置)、其余 `macaws-*`（doors/trapdoors/furniture/stairs/paths/lights/fences） |
| 性能 | `iris`、`sodium-dynamic-lights` |

### 档位 3 · 完整（约 85 个）

在档位 2 基础上加：

| 分组 | mod id |
| --- | --- |
| 太空/终局 | `ad-astra`（**仅作维度/环境素材**，不用其火箭实体）；`creating-space`/`deep-space`/`dimensional-sable`（**若要走 Create 备选路线 B 才加，且必须成套加**） |
| 任务/引导 | `ftb-quests` + `ftb-library`（**采用**，可选引导；许可 ARR、不可 fork）；`ftb-teams`（可选）；~~`ftb-chunks`~~（**不采用**，与禁限区/领土打架） |
| 存储自动化 | `ae2`（与 `refined-storage` 二选一） |
| 环境增强 | `sound-physics-remastered`、`journeymap`（服务端网页地图场景才加，替代 Xaero） |
| 可选传感器（**可整套删除**） | `cold-sweat`（温度传感器）、`serene-seasons`（季节传感器，**ARR → 不可打包**）——两者缺失时游戏必须完整可玩（ADR-010） |

**明确不进入任何档位**：`thermal-*`（无 1.21.1）、`diet`（无 1.21.1）、`configured`（无 NeoForge）、`canary`（无 1.21.1）、`ice-and-fire`（无 1.21.1）、`cosmic-horizons`（无 1.21.1）、`tektopia`/`ancient-warfare`（无 1.21.1）、`spaceward-expansion`（停更）、`advanced-rocketry-3`（ARR + beta + 无 API）、`stellaris`（NC + 无 API + 与 Ad Astra 重复）、`tough-as-nails`/`thirst-was-taken`（居民口渴自研，玩家侧也不再单独加）、`minecolonies`/`millenaire`（与基底根本冲突，仅作对比）。

---

## 6. 下一步（建议派给谁）

1. **许可核实**（人工/带浏览器）：逐个打开 §4.4 中"高/中"风险 mod 的 CF/Modrinth 页面，记录 modpack 授权原文 → 回填本表"许可"列。
2. **设计裁决**（设计负责人）：~~季节性/温度/口渴是否自研或采用 `cold-sweat` + `serene-seasons`~~ → **已裁决（ADR-010，[r08](../research/08-temperature-thirst-integration.md) 证据）**：居民侧自研；外部 mod 仅作可整体删除的可选传感器。剩余待办：Cold Sweat 许可冲突条款、是否默认进包（见 PRD-003 OQ）。
3. **技术验证**（实现）：Create 6 + Aeronautics 1.3.2 + Sable 2.0.6 的最小可运行包，测 TPS 与移动结构区块开销。
4. **替代验证**：`nutritional-balance` 是否满足饮食需求（§3 #7）。
