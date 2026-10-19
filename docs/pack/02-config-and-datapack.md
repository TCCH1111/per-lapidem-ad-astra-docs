# 配置、数据包与脚本内容规划

```
状态：草稿
负责人：整合包维护者 + 设计
最后更新：2026-10-17
上游依据：docs/pack/00-pack-spec.md、docs/research/04-content-and-modding.md、docs/research/03-front-and-interaction.md
下游影响：所有 PRD 的「可改写性」章节、docs/workflow/03-test-and-acceptance.md（内容校验）
```

> 目标：让「加内容」尽量**不写 Java**，让「调难度」尽量**不改代码**，并让**每一处可写入口只有一个负责人**（避免配置文件与数据包互相打架）。

---

## 1. 四层内容载体（谁负责什么）

| 载体 | 负责 | 不负责 | 谁维护 |
| --- | --- | --- | --- |
| **`serverconfig/folkways-server.toml` + 我们的配置** | 数值、上限、开关、频率、难度 | 新增内容（新事件/新图案） | 整合包 + 玩家 |
| **数据包（`data/<ns>/…`）** | 新增内容：图案、部件、蓝图、外观、名字池、事件模板、需求定义、剧本 | 逻辑与行为 | 内容作者 |
| **KubeJS 脚本** | 配方、标签、物品/方块微调、跨 mod 桥接 | 我们的货架内容（避免与数据包重复） | 整合包 |
| **资源包** | 贴图、语言、字体、模型外观 | 玩法 | 整合包 + 玩家 |

**R-CD-1**：**同一个事实只能有一个来源**。若某数值既在配置里又在数据包里，必须由文档明确谁是权威（默认：数据包默认值 ← 配置可覆盖 ← 剧本可再覆盖）。
**R-CD-2**：整合包发布的内容必须是**数据包 + 配置 + KubeJS**，不得要求玩家手改 jar。

---

## 2. 配置层级（三级覆盖）

```
① 包内默认（随整合包分发，玩家不应修改）
      config/…            ← 各 mod 的配置
      defaultconfigs/…    ← 新世界默认
② 世界级（基底只有这一级）
      serverconfig/folkways-server.toml
③ 剧本级（我们的新机制，见 PRD-007）
      datapacks/<pack>/data/<ns>/folkways/scenario/<id>.json
```

**R-CD-3**：自研插件的配置项**必须**能通过剧本覆盖（否则剧本无法表达难度）。
**R-CD-4**：配置项命名统一 `snake_case`，并在文档中给出「默认值 / 范围 / 谁需要它」（对应 [R-F8](../design/11-freedom-design.md)：每个旋钮都要说明谁需要它）。

### 2.1 基底已有的配置面（可直接用）

来自 [r04 §4](../research/04-content-and-modding.md)：`serverconfig/folkways-server.toml` 共 22 组，含：

| 组 | 例 | 用途 |
| --- | --- | --- |
| 引擎 | `mode`、`solveThreads` | 单/多线程、线程数 |
| 移民 | 4 项 | 到来频率、技能阶梯 |
| 区域上限 | 6 类区域格数上限、`maxBuildCells=65536`、`maxBlueprintVolume` | 规模阀 |
| 图案 | `drawSeconds=10`、服务端最多 256 图案 | 内容阀 |
| 配方 | `refusedRecipes` | 禁配白名单 |
| 快手阶梯 | 8 条 | 熟练度速度 |
| 预算 | labor / navigation 预算、diagnostics | 性能 |
| 其它 | ghost block 绘制等 | 表现 |

### 2.2 基底缺少、我们必须补的配置面

| # | 缺失项 | 影响 | 归属 |
| --- | --- | --- | --- |
| 1 | **人口上限**（引擎级保护） | 性能与玩法（[性能预算](03-performance-budget.md) 降级第 5 级） | 我们 |
| 2 | 工时/作息开关 | PRD-005 | 我们 |
| 3 | 图案白名单（限制玩家能写什么） | 内容治理 | **fork 内实现**（改服务端发牌逻辑，L2；r04 §6 的"需 fork"已由 ADR-007 满足） |
| 4 | 外观池默认集合 | 内容 | 数据包已有注册表，配置缺 |
| 5 | 集成 mod 模块开关（Create/Sable/Golem…） | 整合包三档 | 我们 |
| 6 | 经济：价格、腐坏、品质门槛 | PRD-006/010 | 我们 |
| 7 | 需求/情绪：衰减、阈值、崩溃开关 | PRD-001 | 我们 |
| 8 | 事件：频率、强度、前兆、模块开关 | PRD-002 | 我们 |
| 9 | 威胁：袭击规模、敌人上限、民兵比例 | PRD-004 | 我们 |
| 10 | 时代：门槛数值、知识速率 | PRD-011 | 我们 |
| 11 | 多人：权限分级 | PRD-012 | 我们 |

**R-CD-5**：新增配置项必须登记到本文档 §2.2 的对应行，并在 PRD 的 §9.7 给出默认值与范围。

---

## 3. 目录布局与命名规范

```
<整合包根>
  config/                                  # 各 mod 配置（含我们的）
  defaultconfigs/                          # 新世界默认
  serverconfig/folkways-server.toml        # 基底世界级配置
  kubejs/
    server_scripts/                        # 配方/标签（仅在服务端语义处）
    startup_scripts/
    client_scripts/                        # 语言/贴图微调（谨慎）
    data/                                  # KubeJS 自带数据（**不与我们数据包重复**）
  datapacks/
    plaa-core/                             # 我们的基础数据包
      pack.mcmeta
      data/
        plaa/
          folkways/
            need/*.json                    # ← 若基底货架可扩展（见 §4.2）
            incident/*.json
            narrator/*.json
            scenario/*.json
          tags/…
    plaa-content-<模块>/                    # 内容分包（可按档位裁剪）
  resourcepacks/
    plaa-lang/                             # 双语补全（zh_cn + en_us；基底既有四语言文件保留）
    plaa-style/                            # 统一风格（可选）
  mods/                                    # 仅放不可平台分发的 jar（Folkways nightly、我们的插件）
```

| 规范 | 内容 |
| --- | --- |
| 命名空间 | **核心 = `plaa`**（[ADR-017](../00-charter.md)；基底内容仍在 `folkways`）；**第三方内容用其自有命名空间**，我们的加载器**读取所有命名空间**（R-AUTH-1，不允许只认 `plaa`） |
| 数据包文件名 | `snake_case`，与 id 一致（`incident/<id>.json`） |
| 版本 | `pack.mcmeta` 的 `pack_format` 必须与 1.21.1 匹配；我们的数据包版本独立 |
| 分包 | 内容按模块分包（core / needs / incidents / threats / ages / trade），便于三档裁剪 |
| id 稳定性 | **id 一经发布不得改名**（存档引用 id，见 PRD-002 R-DATA-2） |

---

## 4. 数据驱动面

### 4.1 基底已提供（直接用）

| 载体 | 路径 | 说明 |
| --- | --- | --- |
| `pattern`（Starlark） | `data/<ns>/folkways/pattern/*.star` | 建筑样式：地形自适应、几何、部件、多阶段、多轮生长、玩家旋钮、内嵌 i18n |
| `piece` | `data/<ns>/folkways/piece/*.nbt` | 部件（被图案 `template()` 引用） |
| `blueprint` | `data/<ns>/folkways/blueprint/*.nbt` | 整栋蓝图（玩家整栋放置） |
| `resident_skin` | `data/<ns>/folkways/resident_skin/*.png` | 外观贴图（服务端分发） |
| `resident_model` | `data/<ns>/folkways/resident_model/<名>/` | Bedrock 模型（需 GeckoLib） |
| `resident_look` / `resident_look_set` / `resident_name` | 数据包注册表（`DataPackRegistryEvent`） | 外观权重、外观集合、名字池；**`/folkways library` 看不到**，出错只进日志 |

**内容策略**：整合包的主要内容量应放在 **图案 + 部件 + 蓝图 + 外观 + 名字池**（[r04 §6](../research/04-content-and-modding.md) 明确建议）。这是**目前唯一零 Java 成本**的内容通道。

**R-CD-6**：图案的硬限制必须写进内容作者手册：capture 视野、边长 ≤512、`drawSeconds` 默认 10s、解析 20 万步、单文件 128KB、服务端 ≤256 个图案。
**R-CD-7**：图案**不能**读容器/实体、不能改世界（只出方案由居民施工）、不能持久化自有状态 → 任何依赖这些的设计必须走 Java。

### 4.2 我们计划新增的货架（2026-10-18 更新：**fork 后已无前置阻塞**）

| 货架 | 内容 | 归属 PRD |
| --- | --- | --- |
| `need` | 需求定义（名称、衰减、情绪映射、图标） | PRD-001 |
| `addiction` / `focus_source` / `duty_priority` | 成瘾物质与计量、专注度来源与侵蚀、工作优先级 | PRD-001 |
| `memory` | 记忆类别与权重 | PRD-001 |
| `incident` | 事件模板（条件/权重/前兆/选项/后果） | PRD-002 |
| `narrator` | 叙述者预设 | PRD-002 |
| `season` / `climate` | 季节曲线与气候档案 | PRD-003 |
| `threat_profile` | 威胁等级与波次 | PRD-004 |
| `scenario` | 剧本（开局条件 + 规则覆盖） | PRD-007 |
| `relation_kind` / `social_activity` / `grudge_cause` | 关系类型、社交活动、恩怨成因 | PRD-008 |
| `life_stage` / `upbringing` / `ritual` | 生命阶段、养育与教育、仪式（含葬礼） | PRD-009 |
| `faction` / `trade_goods` / `caravan` | 势力、贸易品与货单、商队档案 | PRD-010 |
| `age` / `knowledge` / `burden` | 时代门槛、知识（洞见/获得途径）、时代压力 | PRD-011 |
| `gas_kind` / `gas_source` / `gas_sink` / `gas_reactor` / `gas_barrier` / `gas_vent` / `pollution_rule` | 气体种类、排放源、吸收源、反应器、密封屏障、通风口、污染后果规则 | [d13](../design/13-gases-pollution-and-cycles.md)（M3 注册，M4 实现） |
| `body_part` / `injury_kind` / `surgery` / `prosthetic` / `medicine` | 部位、伤病、手术、义体、药品 | PRD-013 |

**货架总数（截至 2026-10-18）**：**43 个**（`need`、`addiction`、`focus_source`、`duty_priority`、`memory`、`incident`、`narrator`、`season`、`climate`、`threat_profile`、`scenario`、`relation_kind`、`social_activity`、`grudge_cause`、`life_stage`、`upbringing`、`ritual`、`faction`、`trade_goods`、`caravan`、`age`、`knowledge`、`burden`、`gas_kind`、`gas_source`、`gas_sink`、`gas_reactor`、`gas_barrier`、`gas_vent`、`pollution_rule`、`body_part`、`injury_kind`、`surgery`、`prosthetic`、`medicine`、`prisoner_state`、`captivity_action`、`sentence`、`power_adapter`、`power_generator`、`power_storage`、`machine_drive`、`womb_recipe`），全部为 **L2** 改动（扩 `Shelves` 注册表），无一需要 L3/L4。清单是唯一的（[PRD-012 §3.4](../prd/PRD-012-multiplayer-and-permissions.md) 的收口纪律同样适用于此表：新货架必须在此登记）。其中 **7 个气体货架 M3 注册、M4 才实现**（[d13 §1.3](../design/13-gases-pollution-and-cycles.md)），**3 个关押货架归 M3**（[PRD-015](../prd/PRD-015-captivity-and-prisoners.md)），**5 个能源/机械族货架归 M3**（[d15](../design/15-power-and-mechanical-residents.md)）。注：`addiction_substance` 是 `addiction` 货架内的**记录类型**，不算独立货架。

**已解决的前置问题**：基底 `Shelves` 的书架名是固定集合（`Vocabulary.predeclared()` 硬编码、`apiJar` 只含 `core/api`+`front/api`）—— 这在**插件路线下**是硬阻塞。**我们已 fork（[ADR-007](../00-charter.md)）**，因此：

| 路线 | 做法 | 结论 |
| --- | --- | --- |
| **F1 扩展 `Shelves`**（采用） | 在 fork 内把书架注册表改为**可扩展**（L2 改动），新货架复用 `/reload` 与 `/folkways library` 自检 | ✅ 采用：体验统一、复用上游基础设施 |
| F2 自建加载器 | 自己读目录、自己管校验与热重载 | ❌ 不采用（除非 F1 出现无法解决的架构冲突） |

**R-CD-8（保留）**：我们的数据面必须与 `/folkways library` **同等可诊断**：列出条目、来源 pack、被拒原因。
→ 这是 [PRD-006 诊断](../design/09-interaction-and-ui.md) 精神在内容层的延伸：**内容也要能自证为什么没加载**。
**R-CD-11（新增）**：扩展 `Shelves` 属于 [fork 策略](../design/12-fork-strategy.md) 的 **L2 改动**（加 `// PLA:` 标记 + 登记），并且**必须保持上游既有 5 个货架行为不变**（新书架是新增，不是替换）。

### 4.3 参考格式

`Pillager Caravans` / `Better Caravans` 用纯数据包定义编队、货物、生成规则、冷却与交易表（[r07](../research/07-mc-landscape.md)）——与本项目的「事件/商队」货架目标同构，**直接借鉴其 schema 风格**（易读、可局部覆盖、冷却显式）。

---

## 5. KubeJS 的边界

| 该做 | 不该做 |
| --- | --- |
| 增删改配方（含 Create 系） | 定义事件/需求/剧本（属于我们的货架） |
| 调整标签（方块/物品分类） | 实现玩法逻辑（应在插件里，KubeJS 难测试） |
| 跨 mod 桥接（把 A 的物品接进 B 的配方） | 存储长期状态 |
| 临时平衡调整（发布前的快速试错） | 依赖顺序敏感的启动逻辑 |
| **酿酒/药物配方**：把 Create Big Pharma / Create Pop / CustomBrewRecipes 的物品接进我们的酒/药生产链，补 `create-addictives` 一类缺失配方 | **成瘾规则**（剂量曲线、耐受、戒断、过量阈值）——属 `addiction` 货架 + [PRD-001](../prd/PRD-001-needs-mood-memory.md)/[PRD-013](../prd/PRD-013-medical-and-surgery.md) |
| 把某支内容 mod 的物品**映射**到我们已有的物质 id | 把"某物质是否可成瘾""成瘾阈值多少"写成脚本常量 |

**R-CD-9**：KubeJS 脚本必须可被 `npm`/测试侧静态检查（至少语法与 id 存在性），不允许"运行才知道错"。
**R-CD-12（2026-10-18 定，ADR-017）**：**KubeJS 是整合包侧依赖，不是我们 mod 的依赖**——我们的 mod 在**没有任何 KubeJS 脚本**时也必须完整可玩（缺它只丢内容，不丢功能）；反过来，任何**玩法规则**（需求/知识/剧本/诊断/时代等）**都不得**只写在 KubeJS 里，否则无法测试与诊断（§5 表已经划定边界，这条是它的可执行版本）。
**R-CD-13（2026-10-18 新增）**：**酿酒与药物 = 脚本写配方、货架写规则**。物质条目（`kind`/`dose`/`tolerance_rate`/`withdrawal_curve`/`overdose_threshold`/`work_effects`…）必须落在 `data/<ns>/folkways/addiction/*.json`（可热重载、可被数据包覆盖、可被诊断解释）；**KubeJS 里只允许出现"物品 ↔ 物质 id"的映射与配方**。理由：脚本里的阈值不可测、不可诊断、删脚本就会让已有成瘾者凭空痊愈（违反 [PRD-001 R-NM-27](../prd/PRD-001-needs-mood-memory.md)）。

---

## 6. 资源包与语言

| 项 | 要求 |
| --- | --- |
| 语言 | **我们新增的每个键只要两份：`zh_cn` + `en_us`**（[ADR-017](../00-charter.md)）；基底既有的 `en_us`/`zh_cn`/`zh_hk`/`zh_tw` 文件保留不动，缺键回退 `en_us`（[PRD 模板](../prd/00-prd-template.md) §12） |
| 术语一致 | 沿用基底官方译名（[全局术语表](../design/03-glossary.md) R-GL-2） |
| 字体 | 中文字体覆盖（避免缺字方块）；确认 LDLib2 的文本渲染 |
| 简繁 | **仅当改动基底既有键时**，`zh_hk`/`zh_tw` 才需按各地区 Minecraft 术语核对，**不做机器简繁转换** |
| 风格 | 统一贴图风格（可选资源包），与 folkways 原生风格不冲突 |
| 校验 | 复用基底的 i18n 检查思路（键集一致、占位符一致）→ 纳入我们的 CI（[测试策略](../workflow/03-test-and-acceptance.md)） |

---

## 7. 版本化、热重载与校验流程

| 步骤 | 工具 | 说明 |
| --- | --- | --- |
| 1 | `/reload` | 数据包热重载（基底 5 货架 + 我们新增的货架） |
| 2 | `/folkways library`（op2） | 列出条目、来源 pack、被拒原因（扩展后覆盖我们的货架） |
| 3 | 我们的自检命令 | `/<ns> content`：我们的货架条目/拒绝原因/引用完整性（例：事件引用的物品/需求 id 是否存在） |
| 4 | i18n 检查 | 上游既有键四语言不回归；**我们新增的键 `zh_cn` + `en_us` 键集与占位符一致** |
| 5 | 引用完整性 | 事件 → 效果引用的物品/需求/势力；剧本 → 引用的货架 id；图案 → 引用的部件 |
| 6 | 启动日志 | 不允许出现 warning 级以上的内容错误 |

**R-CD-10**：内容校验必须能在**不开世界**的情况下跑（静态检查），进入 CI。

---

## 8. 反模式（禁止）

| 反模式 | 后果 |
| --- | --- |
| 把玩法逻辑写进 KubeJS | 无法测试、无法诊断、版本升级即坏 |
| 把数值同时写在配置与数据包且不一致 | 玩家永远不知道哪个生效 |
| 依赖「加载顺序」的内容 | 随机失败 |
| 改名已发布的 id | 破坏存档（PRD-002 R-DATA-2） |
| 用图案实现需要读容器/实体的功能 | 做不到（r04 硬边界），必然返工 |
| 让内容依赖可选 mod（例：某事件只在装 Create 时可用） | 违反 [R-PACK-8](00-pack-spec.md)，造成「两套玩法」 |
| 玩家的自定义内容与整合包内容混在同一目录 | 升级时覆盖玩家改动（[R-PACK-6](00-pack-spec.md)） |

---

## 9. 开放问题

| 编号 | 问题 | 影响 | 何时定 |
| --- | --- | --- | --- |
| OQ-CD-1 | ~~F1（上游 PR 扩展货架）还是 F2（自建加载器）？~~ | **已裁决：F1 —— fork 内扩展 `Shelves`**（ADR-007，L2 改动；见 §4.2） | ✅ 已定（2026-10-18） |
| OQ-CD-2 | ~~内容的命名空间与目录名（`plaa`？）~~ | **已定：`plaa`**（[ADR-017](../00-charter.md)；所有数据包目录为 `data/plaa/...`） | ✅ 已定（2026-10-18） |
| OQ-CD-3 | ~~是否用 KubeJS 做配方层，还是用数据包 + 我们自己的配方货架？~~ | **已裁决：采用 KubeJS 作为内容层**（配方/标签/跨 mod 桥接/内容微调）；**但引擎级内容（需求/知识/剧本等货架）仍走数据包 + 我们的货架**；**红线：我们的 mod 本身不得依赖 KubeJS —— 缺它时必须能启动**（[ADR-017](../00-charter.md)） | ✅ 已定（2026-10-18） |
| OQ-CD-4 | 内容分包粒度（按模块分包 vs 一个大包） | 三档裁剪难度 | M1 前 |
| OQ-CD-5 | 图案白名单（限制玩家能加载什么图案）是否需要？ | 服务器安全 | M2 前（可能需 fork） |