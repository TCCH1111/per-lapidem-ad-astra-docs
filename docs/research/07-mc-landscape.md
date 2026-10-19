# MC 生态调研：殖民地 / 居民 / 需求情绪 / 事件威胁（重点 1.21.1 NeoForge）

```
状态：草稿（待人工评审）
负责人：调研（AI 辅助）
最后更新：2026-10-17
上游依据：docs/design/01-vision-and-pillars.md、docs/design/02-benchmark.md
下游影响：docs/research/06-gap-analysis.md、docs/design/04~11、各 PRD
```

> 目的：回答「哪些机制别人已经做了、做到什么程度、我们该整合还是自研」。所有结论都带 URL；无法核实的写「未验证」。

---

## 1. 调研方法与来源

**可用通道**（本机 PowerShell）：Modrinth v2 API（search / project / version）、GitHub REST API（repo / releases / search/issues）、mcmod.cn 页面抓取、官方站点抓取、`web_search`。
**不可用/受限**：`web_fetch` 被沙箱阻断；Reddit 与 CurseForge 直连返回 403（因此 CurseForge 独家 mod 无法核实正文，已标注）；GitHub 未认证配额 60 次/小时，中途耗尽（`/rate_limit` 确认）后改用 search API 与已缓存数据；`git clone` 不可用。

**主要来源**

| 来源 | URL |
| --- | --- |
| Modrinth API 搜索/版本（facets: `categories:neoforge` + `versions:1.21.1`） | https://api.modrinth.com/v2/search |
| MineColonies 仓库与发布 | https://github.com/ldtteam/minecolonies · https://github.com/ldtteam/minecolonies/releases |
| MineColonies 官方 Wiki（Systems: Needs/Traits/Research/Raids/Requests） | https://www.minecolonies.com/wiki/ · https://www.minecolonies.com/wiki/needs/happiness/ · https://www.minecolonies.com/wiki/systems/traits/ · https://www.minecolonies.com/wiki/systems/research/ |
| MineColonies 中文百科（含玩家评分分布） | https://www.mcmod.cn/class/682.html |
| MineColonies 功能请求仓库 | https://github.com/ldtteam/minecolonies-features/issues |
| MCA Reborn（Modrinth） | https://modrinth.com/mod/minecraft-comes-alive-reborn · 源码 https://github.com/Luke100000/minecraft-comes-alive/ |
| MCA Reborn 中文百科（含玩家评分分布） | https://www.mcmod.cn/class/5099.html |
| Millénaire 官网下载页（版本/NeoForge 要求/更新说明） | https://new.millenaire.org/zh-Hans/%E4%B8%8B%E8%BD%BD |
| Millénaire 中文百科（含玩家评分分布） | https://www.mcmod.cn/class/46.html |
| Millénaire NeoForge 分叉 | https://github.com/Leviaria/Millenaire |
| MineFortress | https://github.com/remmintan/minefortress · https://modrinth.com/mod/minefortress |
| Tektopia 中文百科（停更状态） | https://www.mcmod.cn/class/2123.html |
| Tektopia 社区仓库 | https://github.com/TangoTek/TekTopia-Community |
| KubeJS 官网/仓库 | https://kubejs.com/ · https://github.com/kube-mod/KubeJS |

**未验证项（明确记录，不要当结论用）**
- `dwarfcolonies` / 「矮人殖民地」：Modrinth `/v2/project/dwarf-colonies` 返回 404，Modrinth 与 GitHub 搜索无结果，mcmod「矮人殖民地」检索 0 条。仅出现在 `docs/design/02-benchmark.md`。**未验证**（建议人工到 CurseForge 再核一次）。
- MineColonies 在 Modrinth 上的项目页只登记到 1.18.2（33,885 下载），与其 1.21.1 活跃发布不符：1.21.1 分发走 CurseForge（README 指向 https://www.curseforge.com/minecraft/mc-mods/minecolonies/files/all ，该页对本机 403，**未验证**）。**1.21.1 存在性以 GitHub releases 为准**。
- `RimMood`（疑似 RimWorld 式心情 mod）：仅见于 https://www.curseforge.com/minecraft/mc-mods/rimmood ，Modrinth 无此项目，mcmod 检索 0 条，ModDex 评价「No reviews yet」（https://moddex.gg/mod/rimmood ）。**内容未验证**。
- Millénaire 9.0.x 官方发布所用仓库未确认（官网未标注 repo；已核实的是 NeoForge 分叉 https://github.com/Leviaria/Millenaire ）。

---

## 2. 逐个 mod 拆解

> 玩家评价优先引用中文百科的量化评分（红票/黑票 + 七维属性票型），这是可核查的群体样本；GitHub issue 用于定位具体痛点。

### 2.1 MineColonies（模拟殖民地）

| 项 | 内容 |
| --- | --- |
| **平台/版本存活** | 活跃。GitHub 865 star，最后推送 2026-10-13；1.21.1 发布线 `v1.21.1-1.1.1403`（2026-10-04），1.20.1 线并行。GPL-3.0。（https://github.com/ldtteam/minecolonies/releases）1.21.1 依赖 Structurize / MultiPiston / BlockUI / Domum Ornamentum |
| **提供的机制** | 建筑放置+工人自动化+请求(Requests)系统；Systems 覆盖 Colony Border/Connections/Protection、Pathfinding、**Quests、Raids、Requests、Research、Traits**、Needs(Food/Gear/Happiness/Sleep)（https://www.minecolonies.com/wiki/ ）；**幸福度**=殖民地级+市民级，三因子「安全(卫兵比例)/住房(住宅等级)/饱和(食物)」，殖民地幸福度提升新市民初始等级与技能，市民幸福度提升图书馆智力上限，且**市民死亡会让其他人哀悼**（https://www.minecolonies.com/wiki/needs/happiness/ ）；**Traits** 8 项属性，技能随工作成长、上限由住宅等级决定（0→10…5→99），且「下雨/下雪/夜晚/昨天有人死亡」会停工（https://www.minecolonies.com/wiki/systems/traits/ ）；**Research** 大学+研究员，4 棵树（Civilian/Combat/Technology/Unlockables），列=大学等级门槛（https://www.minecolonies.com/wiki/systems/research/ ） |
| **优点（玩家评价）** | mcmod：红票 151(92%)/黑票 14(8%)；好玩 80.81%、漂亮 73.26%、耐玩 75.58%、实用 54.65%。「漂亮/耐玩」是强项（https://www.mcmod.cn/class/682.html ）。生态最完整：1.21.1 仍有大量第三方扩展（商队 `minecolonies-caravans`、诊断 `pathfinding-edition-for-minecolonies`、`colonyrank`、语音 `TownTalk`） |
| **缺点（玩家评价）** | 同一页面：**只有 43.6% 认为稳定（不稳定 75 票 > 稳定 47 票）**，兼容好仅 34.3%，合理 51.16%。技术侧痛点：`#5006 Schematic Issues`（481 条评论、仍 open，https://github.com/ldtteam/minecolonies/issues/5006 ）、`#2140 Constant Crashes`、`#4905 Resources disappearing for Builder`、`#6236 builder doesn't build`、`#10972 卡顿/碰撞计算`、`#11436 殖民地内存泄漏`、`#11442 服务员把自己饿死并成为自动化瓶颈`（open，31 评论）。UI 侧痛点：`#11384 Alert Fatigue`——红色感叹号同时表示「停工」与「幸福度抱怨」，殖民地常成「一片红海」（https://github.com/ldtteam/minecolonies/issues/11384 ） |
| **设计侧缺口（官方功能请求）** | `minecolonies-features` 中：`#135 Mod Compatibility Requests`(185 评论)、`#945 Food penalties need to go`、**`#128 Colonists are people`**、`#267 Getting started needs to be WAY easier`、`#769 建前未知材料清单`（https://github.com/ldtteam/minecolonies-features/issues ）——玩家自己就在要求「居民更像人」「少点惩罚」 |
| **与 Folkways 的关系** | **重叠（最大）+ 参考**。重叠：建筑放置→工人自动施工、请求/物流、研究树、职业与技能。互补：它没有我们的意图层（划地/订单/职业排序/图案）与个体叙事。冲突：若整合，居民体系会被它接管，与 Folkways 的 `ResidentObituary`/职业/perk 直接打架→**不整合作运行时依赖**，只吸收设计（幸福三因子、Traits 成长曲线、Research 列门槛） |

### 2.2 MineFortress（RTS 化殖民地）

| 项 | 内容 |
| --- | --- |
| **平台/版本存活** | Fabric，1.20.1/1.20.2（Modrinth 127,533 下载/580 关注，最后更新 2025-07-05）；GitHub 183 star，最后推送 2025-08-09，最新 release `1.17.5-beta`（2025-07-05），MIT。**无 1.21.1、无 NeoForge** |
| **提供的机制** | 把 MC 变 RTS：放弃第一人称、鼠标点选指挥；村民（pawn）职业分工、建造、扩张、征服邻村（https://github.com/remmintan/minefortress 、https://modrinth.com/mod/minefortress ） |
| **优点** | 唯一把「RTS 指挥层」做完整的 MC mod；省去第一人称操作摩擦；有网站/wiki/discord |
| **缺点** | issue 数仅 30，暴露完成度：`#50 Pawns become jobless`、`#29 Army needs to fight back when not assigned`、`#32 Miners don't eat while mining`、`#30 Blocks get deleted when stacking`、`#47 Port to more popular development versions`(open)。全部 beta |
| **与 Folkways 的关系** | **冲突**（P1「意图而非指令」的反面就是点选每个单位）。只借「袭击/征服循环」与「RTS 视角可选」的思路 |

### 2.3 Tektopia（桃花源记）+ Addons

| 项 | 内容 |
| --- | --- |
| **平台/版本存活** | **已停更/闭源**，仅 Forge 1.12.2（mcmod 标注「停更」「闭源」，作者 TangoTek，https://www.mcmod.cn/class/2123.html ）。社区仓库最后推送 2019-06-03（https://github.com/TangoTek/TekTopia-Community ）。后续只有 1.12.2 附属件（https://modrinth.com/mod/tektopia-addons ） |
| **提供的机制** | 完全重写村庄系统、20+ 职业、**幸福度→床旁生成「爱心」→生成小孩**、酒馆夜间提升幸福、城镇中心 120 格村庄范围、商人/建筑师 NPC、死灵法师敌人（https://www.mcmod.cn/class/2123.html ）；Addons 让村民吃任意模组食物并自动计算饥饿/快乐（https://www.mcmod.cn/class/20275.html ） |
| **优点** | mcmod：好玩 96.15%、耐玩 80.77%；「幸福度→生育」与「酒馆社交」是 MC 生态里最接近「居民有生活」的早期实现 |
| **缺点** | 稳定 34.62%、兼容好 30.77%；版本死在 1.12.2，无源码可复用 |
| **与 Folkways 的关系** | 只能当**设计参考**（幸福→生育、社交场所提升情绪、村庄边界），代码不可用 |

### 2.4 Millénaire（千年村庄）

| 项 | 内容 |
| --- | --- |
| **平台/版本存活** | **活跃且已到 1.21.1 NeoForge**：官网「Minecraft 1.21.1 稳定版 Millénaire 9.0.2 · 2026-09-18，适用于 NeoForge 21.1.226」（https://new.millenaire.org/zh-Hans/%E4%B8%8B%E8%BD%BD ）。9.0.0（2026-08-27）= 从 1.12 到 1.21.1 的**从零重写**。另有 1.12.2(8.1.2)、1.7.10(6.0.2) 分支。NeoForge 分叉仓库：GPL-3.0，8 star（https://github.com/Leviaria/Millenaire ） |
| **提供的机制** | 7 种文化（诺曼/印度/拜占庭/玛雅/日本/塞尔柱/因纽特）村庄自行成长；文化专属建筑/村民/语言；**贸易与硬币、声誉与外交**；任务系统；旅行书；9.0 新增**半透明建筑预览+建造队列**与**村庄编年史**；9.0.2 修复「客栈商人用村庄盈余出口、缺口进口」与「卡住村民寻路开销降为 1/10」（https://new.millenaire.org/zh-Hans/%E4%B8%8B%E8%BD%BD ） |
| **优点** | mcmod：红票 834(86%)；**好玩 97.73%（本报告样本最高）、耐玩 87.88%、漂亮 89.39%**、实用 72.73%（https://www.mcmod.cn/class/46.html ） |
| **缺点** | 同页：**有挑战仅 18.94%**（缺压力）、稳定 31.82%、兼容好 34.09%。玩家视角=「看村子自己长」，玩家能动性弱 |
| **与 Folkways 的关系** | **重叠 + 最佳参考对象**。重叠：村庄自主成长、村民各有生活、贸易/声誉/外交、建筑蓝图。差异：它的村民是「外邦 NPC 村庄」，玩家不是殖民者；我们的是「玩家殖民地的居民」。**强烈建议把它定位成 P3「外邦与世界」的整合候选，而不是竞争对手** |

### 2.5 MCA / MCA Reborn（凡家物语：重生）

| 项 | 内容 |
| --- | --- |
| **平台/版本存活** | 活跃。Modrinth 4,203,611 下载；1.21.1 共 100 个版本、其中 **49 个 NeoForge**，最新 `7.7.36+1.21.1`；loaders = fabric/forge/neoforge/quilt（https://modrinth.com/mod/minecraft-comes-alive-reborn ）。中文百科标注 Forge/Fabric/Quilt/NeoForge，1.21.1 + 26.x（https://www.mcmod.cn/class/5099.html ） |
| **提供的机制** | 用「像玩家的人形 NPC」替换村民；送礼/对话互动；关系与婚姻（含玩家间结婚）；**孩子遗传学**；管理整个村庄；Reaper 可复活死者（Modrinth 正文）；配套 **MCA Capitals**：君主制、贵族家族、继承/退位/私生化、宫廷职务、外交联盟/战争、**Capital Chronicle 编年史**，1.21.1 NeoForge 可用（https://modrinth.com/mod/capitals-a-monarchy-mod-for-mca-reborn ） |
| **优点** | mcmod：红票 85(97%)/黑票 3(3%)；好玩 95.52%、漂亮 85.07%、耐玩 82.09%、合理 74.63%、**稳定 65.67%（本样本最高）、兼容好 59.7%**。生态成熟且有 addon 体系 |
| **缺点** | 1,115 个 issue：`#299 开光影时崩溃`、`#259 None of the Villagers have jobs`、`#233 Villagers cannot use trading blocks from other mods`、`#765 Mod Breaks Elytras`(open)、`#527 Adventurers don't leave the inn`（https://github.com/Luke100000/minecraft-comes-alive/issues ）。机制上：社交/婚育强，**生产/殖民地经济弱**（没有请求系统、没有意图层） |
| **与 Folkways 的关系** | **部分重叠（人味支柱）+ 强参考**。「关系/婚姻/家族/遗传」已被它做完整；但它的主体是「村庄社交」，不是「殖民地模拟」。**冲突点**：两套居民实体（MCA 替换原版村民；Folkways 有自己的居民）不能同时占用同一生态位→建议只做「外邦村庄/访客」或借其设计，不混用实体 |

### 2.6 Ancient Warfare 系列（含 1.21.1 移植）

| 项 | 内容 |
| --- | --- |
| **平台/版本存活** | 老作停更：AW2(1.12.2)、AW3(1.7.10，16,330 下载，2022-06-17，https://modrinth.com/mod/ancient-warfare )。**现代化移植活跃**：`ancient-warfare-3-npcs`（1.21.1/1.21 有 3 个版本，最新 0.3.6 / 2026-02-22，238,685 下载）、`ancient-warfare-3-worksites`（1.21.1，0.2.3，248,782 下载）；另有 `Age of Steam AW2 Generators`（1.21.1 NeoForge，272,742 下载，https://modrinth.com/mod/age-of-steam-aw2-generators ） |
| **提供的机制** | NPC 从市政厅或自定义补给点取食；木工具点击分配职业；**工人晚上要睡觉，没设置家就站在外面等被怪吃**；职业=农夫/伐木工/矿工，配合 Worksites 的农田/林场/采石场（https://modrinth.com/mod/ancient-warfare-3-npcs ） |
| **优点** | 最简「需求（吃饭/睡觉）+ 职业指派」实现，轻量；1.21.1 NeoForge 可直接装 |
| **缺点** | 职业与需求极少；无情绪/关系/事件；「没床就被怪吃」属惩罚性设计 |
| **与 Folkways 的关系** | **互补（可整合）**，作为「极简外邦工人」或需求/睡眠机制的最低参考 |

### 2.7 1.21.1 NeoForge 生态中的其他同类（按机制归类）

| Mod | 存活（1.21.1 NeoForge） | 机制 | 与我们的关系 |
| --- | --- | --- | --- |
| **Bonecraft: Dominion** | 是（1.21.1，16 个版本/8 个 NeoForge，1.3.0，2026-09-05，仅 1,020 下载，https://modrinth.com/mod/bonecraft-dominion ） | 亡灵殖民地：召唤持续存在的工人（农夫/伐木/钓鱼/卫兵），自主工作、腐败转化村民、**计划中的 Raids** | 互补参考；成熟度低 |
| **New in Town（数据包）** | 1.21.1 有版本但**无 NeoForge 构建（纯数据包）**（139,545 下载，https://modrinth.com/mod/new-in-town ） | 分阶段定居剧本：定居者马车、模块化城镇、下界袭击逐级升级到「暴君」凋灵、税收、研究与随机事件 | **剧本系统的内容参考**；不能作为代码依赖 |
| **Guard Villagers** | 是（17 个 1.21.1 NeoForge 构建，2.4.12 / 2026-08-30，13,622,386 下载） | 村庄守卫（1.21.1 NeoForge 可用，https://modrinth.com/mod/guard-villagers ） | 互补：外邦村庄防卫 |
| **Raided / The Hordes / More Raids** | 是（Raided 3 构建 0.1.6；The Hordes 8 构建 `1.21.1-1.6.3f` 2026-09-09；More Raids 1 个 NeoForge 构建） | 袭击/尸潮波次 | 互补：现成的压力来源 |
| **Pillager Caravans** | 是（5 个 NeoForge 构建，3.0.1 / 2026-09-19，217,886 下载，https://modrinth.com/mod/pillager-caravans ） | 漫游劫掠商队：**全数据驱动**（编队/货物表/生成规则/冷却），生物群系货物，分级难度 | **互补（首选）**；其数据驱动写法值得抄 |
| **Better Caravans** | 是（6 个 NeoForge 构建，1.1.2 / 2026-08-10，https://modrinth.com/mod/better-caravans ） | 旅行商队、**数据包交易表** `data/bettercaravans/caravan_trades/*.json`、护卫、迷你袭击、护航奖励；**已兼容 MCA Reborn** | **互补（首选）** |
| **Minecolonies Caravans** | 是（NeoForge 1.21.1，1.0.4 / 2026-10-10，要求 NeoForge 21.1.235+，https://modrinth.com/mod/minecolonies-caravans ） | 商队小屋/领袖/成员/护卫 + **模拟旅行** + 消耗品（帐篷/食物/火把）+ 接入 MineColonies 请求系统 | 若走 MineColonies 路线的参考；与我们的库存/订单系统需自研接口 |
| **Lightman's Currency / Create: Numismatics / Create: Trading Floor / Tom's Trading Network** | 均为是（1.21.1 NeoForge） | 货币、商店、玩家间交易、自动化交易 | 互补：经济底座候选 |
| **Cold Sweat / Scorchful / Tough As Nails** | 是（Cold Sweat 45 个 NeoForge 构建，2.4.4 / 2026-10-16；Scorchful 4 个且为 alpha/beta；Tough As Nails 12 个但**全为 beta**，最新 2024-10-22） | 玩家侧温度/口渴/体温 | 互补：P3 环境压力底层 |
| **Serene Seasons** | 是（7 个 NeoForge 构建，`10.1.0.9` / 2026-09-05，**版本类型均为 beta**，7,507,572 下载） | 季节与作物生长季 | 互补：季节基线 |
| **Jade / spark** | 是（Jade 25 个 NeoForge 构建；spark 3 个） | 方块/实体信息浮层；性能剖析 | 互补：通用诊断 |
| **Open Parties and Claims / Simple Voice Chat / Waystones** | 是 | 领地与队伍、语音、传送 | 互补：多人底座 |
| **KubeJS** | 是（28 个 1.21.1 NeoForge 构建，`2101.7.2-build.377` / 2026-09-09，22,628,447 下载，LGPL-3.0，https://kubejs.com/ ） | JS 脚本：注册方块/物品、改配方、事件钩子；`startup_scripts`/`server_scripts`/`client_scripts` 分级重载 | **两者结合**：作为「数据包之上的脚本层」 |

---

## 3. 机制覆盖矩阵

结论口径：**直接用 mod** = 现成且 1.21.1 NeoForge 可用、语义吻合；**两者结合** = 外壳用 mod、与 Folkways 的接口自研；**自研** = 生态无可用实现或语义冲突。

| # | 我们规划的机制 | 已有 MC mod 与覆盖程度 | 结论 |
| --- | --- | --- | --- |
| 1 | **需求**（饥饿/休息/温暖/安全/社交/美感/意义） | MineColonies Needs(Food/Gear/Happiness/Sleep)（部分，含「雨/夜/死亡=停工」）；AW3 NPCs 吃饭+睡觉；Tektopia 饥饿/快乐（1.12.2）；Cold Sweat/Scorchful/Tough As Nails 覆盖玩家侧温度口渴。**社交/美感/意义需求全生态空白**；且需求都硬绑各自实体体系 | **两半**：环境压力用 mod；居民需求自研（数据包货架 `needs`） |
| 2 | **情绪** | MineColonies 幸福度（殖民地级+市民级，三因子；死亡哀悼）；MCA Reborn 有社交好感但无情绪状态机（**其情绪字段未逐一核实**）。**无情绪→阈值事件（崩溃/出走/暴力）** | **自研**（对标 RimWorld）；借 MineColonies「幸福影响学习/新人质量」的耦合思路 |
| 3 | **关系** | MCA Reborn：送礼/对话/好感/婚姻/与玩家结婚；MCA Capitals：贵族家族/宫廷/外交战争；Millénaire：村庄声誉与外交。**跨居民的关系网/恩怨/师徒/血亲链条无现成通用件** | **自研**；MCA 只作为「外邦 NPC」时的现成关系层 |
| 4 | **记忆** | MineColonies：市民死亡→他人哀悼（集体短期修正）；Millénaire 村庄编年史；MCA Capitals Capital Chronicle。**无个体化、带权重与衰减的记忆条目** | **自研** |
| 5 | **事件叙述者** | **无专用 mod**。相近物只有袭击冷却/分级（Raided、The Hordes、Pillager Caravans 的 cooldown、MineColonies Raids）、季节基线（Serene Seasons）、数据包分阶段袭击（New in Town）。**无风格化叙述者、无前兆、无强度可调** | **自研**（差异化支点） |
| 6 | **袭击防卫** | 现成且齐全：Guard Villagers、Raided、The Hordes、More Raids、MineColonies 卫兵/兵营/岗楼+Raids（含 `minecolonies-raid-fix`） | **直接用 mod** 提供袭击事件；民兵/居民战斗判定与伤亡叙事自研 |
| 7 | **贸易商队** | Pillager Caravans、Better Caravans、Villager Caravan、Minecolonies Caravans（模拟旅行+消耗品）、Lightman's Currency、Create: Numismatics/Trading Floor、Tom's Trading Network。**商队实体与交易表现成；与「我的库存/订单/外交」自动对接无通用方案** | **两者结合** |
| 8 | **科技时代** | MineColonies Research（4 棵树、大学等级=列门槛）；Millénaire 村庄成长；New in Town 阶段；Create 进度链。**全是「配方/建筑解锁」，没有「时代=新玩法层」** | **自研**时代框架（门槛机制借 Research 形状） |
| 9 | **剧本** | New in Town（单一数据包剧本）、MineColonies Supply Camp/Ship 开局、Millénaire 文化选择。**无通用 scenario 货架** | **自研**（内容可参考 New in Town） |
| 10 | **多人协作** | Open Parties and Claims、Simple Voice Chat、Waystones、Essential（通用件）；MCA 支持与玩家结婚（玩法件）。**殖民地内权限细分（谁能改订单/划地/改作息）无现成** | **两者结合** |
| 11 | **数据驱动改写** | KubeJS（1.21.1 NeoForge，22.6M 下载）+ 数据包生态；Pillager Caravans 全数据驱动；Better Caravans 交易表 JSON；Millénaire 以 `cultures/quests/languages` 目录/子模组扩展；MineColonies 有 Datapacks 页 | **两者结合**：沿用 Folkways 货架，暴露 KubeJS 可见钩子；实体行为/状态机不能只靠数据包 |
| 12 | **UI 诊断** | Jade（信息浮层）、spark（性能剖析）、MineColonies 工具（Clipboard/Resource Scroll/Builder's Goggles/Scan Tool）、`pathfinding-edition-for-minecolonies`（指南针读工人工作状态）、TownTalk（语音反馈）。**「为什么停工/为什么不高兴」的因果面板没有**——MineColonies `#11384 Alert Fatigue` 正是这个问题 | **两者结合**：通用件整合；**因果诊断自研** |
| 13 | **世代传承** | MCA Reborn 儿童遗传学；MCA Capitals 继承/退位/私生化/贵族家族/编年史；Tektopia 爱心→小孩（1.12.2）；`familytree`（**仅宠物**）；`Villager Names`（仅命名）。**面向「玩家殖民地居民」的人口曲线+技能传承+墓碑讣告无通用件** | **自研**；若选 MCA 路线则与其重叠，需二选一 |

---

## 4. 可直接整合的 mod 清单（附 1.21.1 NeoForge 支持情况与来源）

> 「可整合」= 建议以**外部依赖**方式引入（不复制其代码，规避 GPL 传染：MineColonies 与 MCA 上游均为 GPL-3.0，Millénaire 分叉为 GPL-3.0）。

| 机制位 | Mod（slug） | 1.21.1 NeoForge 证据 | 来源 |
| --- | --- | --- | --- |
| 袭击事件 | `raided` | 3 个 1.21.1 NeoForge 构建，0.1.6 | https://modrinth.com/mod/raided |
| 尸潮/围城 | `the-hordes` | 8 个构建，`1.21.1-1.6.3f`（2026-09-09） | https://modrinth.com/mod/the-hordes |
| 更多袭击 | `more-raids` | 1 个 NeoForge 构建 | https://modrinth.com/mod/more-raids |
| 村庄守卫 | `guard-villagers` | 17 个构建，2.4.12（13.6M 下载） | https://modrinth.com/mod/guard-villagers |
| 贸易商队（商队事件） | `pillager-caravans` | 5 个构建，3.0.1（全数据驱动） | https://modrinth.com/mod/pillager-caravans |
| 贸易商队（和平商队） | `better-caravans` | 6 个构建，1.1.2（数据包交易；兼容 MCA） | https://modrinth.com/mod/better-caravans |
| 简易商队 | `villager-caravan` | 1 个构建，`1.0.0+mod` | https://modrinth.com/mod/villager-caravan |
| 货币/经济 | `lightmans-currency`、`numismatics`、`create-trading-floor`、`toms-trading-network` | 各有多 1.21.1 NeoForge 构建 | 见 2.7 表 |
| 季节 | `serene-seasons` | 7 个构建，`10.1.0.9`（**均 beta**） | https://modrinth.com/mod/serene-seasons |
| 温度/体温（玩家） | `cold-sweat`、`scorchful`、`tough-as-nails` | Cold Sweat 45 个构建（release）；Scorchful alpha/beta；TAN 全 beta | https://modrinth.com/mod/cold-sweat · https://modrinth.com/mod/scorchful · https://modrinth.com/mod/tough-as-nails |
| 数据驱动脚本层 | `kubejs` | 28 个构建，`2101.7.2-build.377` | https://modrinth.com/mod/kubejs |
| 通用诊断 | `jade`、`spark` | 25 / 3 个构建 | https://modrinth.com/mod/jade · https://modrinth.com/mod/spark |
| 死亡遗留 | `corpse`、`gravestone-mod` | 各 12/13 个构建（1.21.1 NeoForge） | https://modrinth.com/mod/corpse · https://modrinth.com/mod/gravestone-mod |
| 多人领地/通信/传送 | `open-parties-and-claims`、`simple-voice-chat`、`waystones` | 各 29/43/41 个构建 | https://modrinth.com/mod/open-parties-and-claims |
| 机械与物流（已规划） | `create`、`create-aeronautics` | 11 / 8 个 1.21.1 NeoForge 构建 | https://modrinth.com/mod/create · https://modrinth.com/mod/create-aeronautics |
| 外邦村庄（人味来源） | MCA Reborn + MCA Capitals；Millénaire 9.0.2 | MCA 49 个 NeoForge 构建；Millénaire 官网标注 NeoForge 21.1.226 | https://modrinth.com/mod/minecraft-comes-alive-reborn · https://modrinth.com/mod/capitals-a-monarchy-mod-for-mca-reborn · https://new.millenaire.org/zh-Hans/%E4%B8%8B%E8%BD%BD |
| 居民/村庄模拟（**仅参考，不建议运行时依赖**） | MineColonies、Ancient Warfare 3 NPCs | 1.21.1 均存在（GitHub release / Modrinth） | https://github.com/ldtteam/minecolonies/releases · https://modrinth.com/mod/ancient-warfare-3-npcs |

**整合风险提示**：MineColonies 的稳定性与兼容性评分偏低（43.6% / 34.3%，https://www.mcmod.cn/class/682.html ），把它作为硬依赖会把它的崩溃与兼容问题继承进我们的整合包；MCA 与我们是「两套居民体系」的冲突（见 2.5）。

---

## 5. 必须自研的部分（及理由）

1. **居民需求→情绪→精神阈值链**。理由：生态里只有 MineColonies 的幸福度标量与 Tektopia 的快乐值，二者都硬绑自家实体的数据与 AI；没有任何 mod 提供「需求条+情绪状态机+阈值事件」并允许外挂到别人的居民实体上。
2. **事件叙述者（风格/频率/强度/冷却/前兆）**。理由：全生态无对应 mod；现有袭击 mod 只做「固定波次+冷却」（Raided / The Hordes / Pillager Caravans 的 cooldown 是最近似物）。这是 P5 与 P3 的核心，必须自研。
3. **因果诊断 UI（为什么停工 / 为什么不高兴）**。理由：MineColonies 官方 issue `#11384` 明确记录了「红色图标同时表示停工与幸福抱怨→一片红海」的 Alert Fatigue；Jade/spark 只给事实与性能，不给因果链。管理者原型的成败取决于这一层。
4. **个体记忆与传说/编年史（带权重与衰减）**。理由：现有只是「死亡→哀悼」的短期修正（MineColonies）或村庄级编年史（Millénaire / MCA Capitals），没有个体记忆条目与衰减模型。
5. **时代进程（每时代解锁新动词）**。理由：MineColonies Research 与各类科技 mod 的树都只是「解锁配方/建筑」；我们的反支柱明确禁止「数值+10%」，没有可复用实现。
6. **剧本（Scenario）货架与 Folkways 世界状态对接**。理由：New in Town 是单一固定数据包剧本，非通用框架；Millénaire/MineColonies 的开局是硬编码流程。
7. **与意图层耦合的接口**（订单/划地/职业排序 ↔ 需求、情绪、事件、商队、时代门槛）。理由：所有现有 mod 都是「建筑/工作站驱动」而非「意图驱动」，无人提供该接口。
8. **多人协作下的殖民地权限细分与 LOD 性能**。理由：现有只有通用领地/队伍（Open Parties and Claims）与性能剖析（spark），没有「殖民地内角色权限」与「远处居民抽象化」。

---

## 6. 结论与建议（≤10 条）

1. **生态里没有「MC + 意图层 + 个体人味 + 时代进程」的组合**：最接近的三个是 MineColonies（自动化/建筑）、Millénaire（活的 NPC 村庄）、MCA（社交/家族），各自只占一角——我们的差异化声明仍然成立。
2. **1.21.1 NeoForge 上真正的同类竞品是 Millénaire 9.0.2**（2026-09-18 稳定版、NeoForge 21.1.226、7 种文化、贸易/声誉/外交、村庄编年史）。它好玩度评分最高（97.73%）但「有挑战」仅 18.94%——**这是我们的机会位：压力与失败叙事**。
3. **强烈建议把 MCA Reborn 与 Millénaire 定位成「外邦世界」而不是竞争对手**：用它们充当邻村/访客/商队来源，既避免「两套居民实体」的冲突，又直接补齐 P3 的外部世界与外交。
4. **MineColonies 只吸收设计、不做运行时依赖**：借用「幸福三因子（安全/住房/饱和）」「技能成长受住宅等级上限约束」「Research 列=建筑等级门槛」三点；其 43.6% 稳定评分与 `#5006`(481 评论)/`#11442` 说明它自身仍在打补丁。
5. **可直接整合的清单**：袭击（Raided / The Hordes / More Raids / Guard Villagers）、商队（Pillager Caravans、Better Caravans）、经济（Lightman's Currency / Numismatics）、季节与温度（Serene Seasons、Cold Sweat）、脚本层（KubeJS）、诊断（Jade、spark）、多人（Open Parties and Claims、Simple Voice Chat）、Create 系物流。
6. **整合时抄「数据驱动写法」而非抄代码**：Pillager Caravans 把编队/货物/生成规则/冷却全做成数据包，Better Caravans 的交易表也是 JSON——与 Folkways 的货架哲学同构，应作为我们 `events`/`trade_goods` 货架的格式参照。
7. **必须自研的六件事**：需求→情绪→阈值、叙述者（含前兆与冷却）、因果诊断 UI、个体记忆与编年史、时代进程、剧本货架。它们既是缺口，也是支柱 P2/P5 的护城河。
8. **优先做「因果诊断 UI」的低成本验证**：MineColonies 的 Alert Fatigue issue 证明这是同类产品公认痛点，而它不需要复杂的模拟底子就能先做出来，能最快兑现「管理者」体验。
9. **许可与依赖风险要先定策略**：MineColonies/MCA/Millénaire 为 GPL-3.0 血统，只做外部依赖、不复制代码；Tough As Nails 的 1.21.1 构建全为 beta、Serene Seasons 亦然——需在整合包里锁版本并准备降级方案。
10. **需要人工补核的三项**：`dwarfcolonies`（Modrinth/GitHub/mcmod 均无记录）、CurseForge 独家 mod（RimMood；本机直连 403）、Millénaire 9.0.x 官方发布仓库。建议下一轮用人工浏览器补齐，并在 `docs/research/06-gap-analysis.md` 中与本报告的矩阵对齐。

---

## 附：本次未能核实的项（避免误用）

- CurseForge 全部页面（403）：MineColonies 1.21.1 文件列表、MineFortress 下载页、RimMood 正文、FTB Quests / FTB Teams / FTB Chunks（Modrinth 404，**分发渠道未验证**）。
- Reddit / 论坛玩家长评（403）：本报告的「玩家评价」以 mcmod 量化票型 + GitHub issue 为主，缺少英文社区定性评论。
- MCA Reborn 的逐项机制细节（性格/情绪字段是否存在）未逐条核实，仅依据 Modrinth 正文与 issue 标题。
- Tektopia 的幸福度具体公式、MineColonies Raids 的波次参数：wiki 对应 URL（如 `/wiki/systems/raids/`）返回 404，未取到。