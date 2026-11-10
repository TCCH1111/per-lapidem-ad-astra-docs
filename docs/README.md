# 文档地图 · Per Lapidem ad Astra

> 「Per Lapidem ad Astra」——拾石而上，直至星辰。
> 一个以 [Folkways](https://github.com/IzakyL/folkways) 为基底、对标矮人要塞 / 希克斯之歌 / 环世界 / 石炉的 Minecraft 殖民地模拟整合包。

这份文件是**所有文档的入口**。任何 agent 或人接手工作前，先读这里，再按「上手路径」读对应的文档。

---

## 1. 文档分层

| 层 | 目录 | 回答什么问题 | 变更频率 | 生命周期策略 |
| --- | --- | --- | --- | --- |
| 章程 | `docs/00-charter.md` | 我们为什么做、做到什么程度算成功、不做什么 | 低（每里程碑复核） | 持续维护 |
| **路线图** | `docs/ROADMAP.md` | **长期目标、v1.0 DoD、阶段门禁、当前快照、债务表** | 最高（每轮更新） | 持续维护 |
| 设计 | `docs/design/` | 游戏是什么体验、有哪些系统、术语怎么定义 | 中（改机制先改这里） | 核心文档持续维护 |
| 需求（PRD） | `docs/prd/` | 单个系统**具体**怎么表现、玩家怎么操作、验收标准 | 高（每个 feature 一轮） | 核心且可描述 → 持续维护；其余用完即弃 |
| 整合包 | `docs/pack/` | 装哪些 mod、怎么配置、怎么打包发布、性能预算 | 中 | 持续维护 |
| 工作流 | `docs/workflow/` | 人和 agent 怎么协作、文档怎么写、怎么测 | 低 | 持续维护 |
| 计划 | `docs/plans/` | 某个任务/PRD **具体怎么改**：路径、数据模型、测试清单、风险（w00 阶段三产物，w01 §2 交接件） | 高（每个任务一份） | 实现合入后转「已实现」，保留作追溯 |
| 报告 | `docs/reports/` | 实现 → 验证的交接件：逐条 AC/测试判定 + 证据（w01 §2） | 高 | 保留作追溯 |
| 调研 | `docs/research/` | 基底 mod 到底能干什么（事实记录） | 一次性（随上游更新重跑） | 用完即弃（结论沉淀进设计文档） |

**唯一事实来源（single source of truth）规则**：同一个概念只在**一个**文件里定义，其他地方链接过去。术语只在 `docs/design/03-glossary.md` 定义；机制数值只在对应 PRD 定义；mod 清单只在 `docs/pack/01-modlist.md` 定义。

---

## 2. 上手路径

### 2.1 人要读的（按顺序）

1. [项目章程](00-charter.md) — 5 分钟
2. [愿景与设计支柱](design/01-vision-and-pillars.md) — 15 分钟
3. [对标分析](design/02-benchmark.md) — 20 分钟，看「我们借什么、弃什么」
4. [全局术语表](design/03-glossary.md) — 遇到不懂的词回来查
5. [自由度设计纲领](design/11-freedom-design.md) — 本项目的核心卖点
6. 具体系统的设计纲要（`design/04`~`design/10`）
7. 要做哪个系统，就读对应 PRD

### 2.2 agent 开始干活前必须读的

1. [文档驱动 AI 工作流](workflow/00-ai-workflow.md) — 六阶段流水线，你处在哪一阶段
2. [角色分工与工具约定](workflow/01-agent-roles-and-tools.md)
3. [测试与验收策略](workflow/03-test-and-acceptance.md)
4. 目标任务对应的 PRD（没有 PRD 就先别写代码，先补 PRD）
5. `docs/research/01-core-engine.md` 与 `docs/research/04-content-and-modding.md` — 基底 API 的事实边界

### 2.3 实现阶段的代码位置约定

| 路径 | 内容 |
| --- | --- |
| `reference/folkways-3ce4d88/` | 基底 mod 的只读参考副本（**当前基线**，升级时整体替换；来源与 commit 见 `reference/README.md`）。`reference/folkways-67f28b0/`（前基线）仅供既有引用过渡 |
| `reference/tyk-construction-prd-zh.txt` | 参考 PRD 原文（格式样例） |
| `pack/` | 整合包工程（**packwiz**，[ADR-021](00-charter.md)）：`pack.toml`、`index.toml`、`mods/*.pw.toml`；`config/`、`kubejs/`、`datapacks/` 按 PRD 需要再建 |
| WSL `~/pla/mod`（Windows 侧无副本） | Folkways 的 fork，**独立 git 仓库**（分支 `main`、remote `origin` → `TCCH1111/per-lapidem-ad-astra` 与 `upstream` → `IzakyL/folkways`、标签 `upstream-base-67f28b0-20261019` 与 `upstream-base-3ce4d88-20261019`），位于 WSL2 Ubuntu-24.04 的 ext4（[ADR-022](00-charter.md)）；Windows 侧经 `\\wsl.localhost\Ubuntu-24.04\home\tcch1111\pla\mod` 或 [`tools/wsl-run.sh`](../tools/wsl-run.sh) 访问；临时克隆 `mod/` 已于 2026-10-19 删除 |
| `tools/` | 开发环境脚本（`wsl-provision.sh`、`wsl-run.sh`，见 [w06 §1.5](workflow/06-build-and-ci.md)） |
| `.cache/`、`.tools/` | 本机缓存与工具（已核验 jar、日志、packwiz 可执行文件），不入库 |

M0（文档阶段）于 2026-10-19 结束，M1 从环境门禁（w06 B-1..B-6 / w05 WP-0）开始。

---

## 3. 维护规则

### 3.1 改动从文档开始

发现「实现和预想不一样」时，**先改文档，再改代码**。顺序永远是：

```
设计纲要 → PRD（含验收标准）→ 计划（Plan）→ 实现 → 测试 → 人工 Review
   ↑______________________________________________|
                   偏差回流到这里，而不是直接改代码
```

### 3.2 文档生命周期（详见 [workflow/02-doc-lifecycle.md](workflow/02-doc-lifecycle.md)）

| | 难以自然语言描述 | 容易自然语言描述 |
| --- | --- | --- |
| **核心系统** | Q2 视情况而定（例：寻路/规划器内核） | **Q1 持续维护**（例：殖民地、经济、威胁、进程） |
| **非核心系统** | Q4 跳过文档（例：渲染细节、模型缓存） | Q3 用完即弃（例：一次性迁移脚本、临时 UI） |

### 3.3 状态标记

每篇文档头部标注：

```
状态：草稿 | 评审中 | 已定稿 | 已实现 | 已废弃
负责人：<人或 agent 角色>
最后更新：YYYY-MM-DD
上游依据：<链接到它依赖的文档>
```

### 3.4 命名与索引

- 文件用 `NN-kebab-case.md`，编号留空位（10、20、30 递增式留空亦可，当前用连续编号）。
- PRD 用 `PRD-NNN-短名.md`，编号一旦分配永不复用。
- 新增文档必须在本文档第 1 节的表格所辖目录内，并在此处登记（`docs/README.md` 是索引的唯一来源）。

---

## 4. 文档清单（随进度更新）

| 编号 | 文档 | 状态 |
| --- | --- | --- |
| — | [文档地图](README.md) | 已定稿 |
| 00 | [项目章程](00-charter.md) | 已定稿 |
| d01 | [愿景与设计支柱](design/01-vision-and-pillars.md) | 草稿 |
| d02 | [对标分析](design/02-benchmark.md) | 草稿 |
| d03 | [全局术语表](design/03-glossary.md) | 草稿 |
| d04 | [世界与模拟总纲](design/04-world-and-simulation.md) | 草稿 |
| d05 | [殖民地与居民](design/05-settlement-and-residents.md) | 草稿 |
| d06 | [经济与物流](design/06-economy-and-logistics.md) | 草稿 |
| d07 | [威胁、防卫与故事生成](design/07-threats-and-narrative.md) | 草稿 |
| d08 | [时代进程](design/08-progression-and-ages.md) | 草稿 |
| d09 | [交互层与信息呈现](design/09-interaction-and-ui.md) | 草稿 |
| d10 | [多人、权限与性能](design/10-multiplayer-and-server.md) | 草稿 |
| d11 | [自由度设计纲领](design/11-freedom-design.md) | 草稿（A-max 已定） |
| d12 | [Folkways fork 策略](design/12-fork-strategy.md) | 草稿（ADR-007 已定；§5.1 登记表随每轮更新——最近 2026-10-26 CI P0/P1） |
| d13 | [气体、污染与资源循环](design/13-gases-pollution-and-cycles.md) | 草稿（ADR-016；M3 预埋/M4 实现） |
| d14 | [存档、备份与迁移](design/14-saves-backups-and-migration.md) | 草稿（ADR-018；增量+全量、永不覆盖、决策日志独立归档） |
| d15 | [能源、动力适配层与机械族](design/15-power-and-mechanical-residents.md) | 草稿（ADR-019；FE/EU/旋转/蒸汽适配、四种驱动、人造子宫） |
| d16 | [诊断界面文字线框原型](design/16-diagnosis-ui-prototype.md) | 草稿（6 页 × 三态线框；D-1~D-31 全覆盖） |
| d17 | [气体接口预埋：M3 的接缝，不是气体系统](design/17-gas-seam.md) | 设计：只读 `GasViews.airAt` + `Air.CLEAN` 默认；**工作资格复用 `Vetoes`**，不需要新引擎钩子 |
| d18 | [能源与机械族的接缝](design/18-power-seam.md) | 设计：`PowerViews.energised` 只读布尔（无系统时 true）；没电也走 `Vetoes`；机械族不新开居民概念 |
| d19 | [关押的接缝](design/19-captivity-seam.md) | 盘点：`ALLOW_ONLY`/`LIMIT` 已够围与限；缺**反向白名单**（新增 `CONFINE`，L1）与**强制劳动**（需 L3，建议缓做） |
| p00 | [PRD 模板](prd/00-prd-template.md) | 已定稿 |
| PRD-001 | [需求、情绪与记忆](prd/PRD-001-needs-mood-memory.md) | 草稿PRD |
| PRD-002 | [事件与叙述者](prd/PRD-002-incidents-and-narrator.md) | 草稿PRD |
| PRD-003 | [季节、温度、口渴与营养](prd/PRD-003-season-temperature-thirst-nutrition.md) | 草稿PRD |
| PRD-004 | [威胁、袭击与防卫](prd/PRD-004-threats-and-defence.md) | 草稿PRD |
| PRD-005 | [意图与微观控制](prd/PRD-005-intent-and-micro-control.md) | 草稿PRD |
| PRD-006 | [仓储规则与因果诊断](prd/PRD-006-stock-rules-and-diagnosis.md) | 草稿PRD |
| PRD-007 | [剧本](prd/PRD-007-scenarios.md) | 草稿PRD |
| PRD-008 | [关系、恩怨与社交](prd/PRD-008-relationships-and-social.md) | 草稿PRD |
| PRD-009 | [世代、儿童与传承](prd/PRD-009-generations-and-legacy.md) | 草稿PRD |
| PRD-010 | [外交与贸易](prd/PRD-010-diplomacy-and-trade.md) | 草稿PRD |
| PRD-011 | [时代进程、知识与太空计划](prd/PRD-011-progression-knowledge-and-space.md) | 草稿PRD |
| PRD-012 | [多人协作与权限](prd/PRD-012-multiplayer-and-permissions.md) | 草稿PRD |
| PRD-013 | [医疗、伤病与手术](prd/PRD-013-medical-and-surgery.md) | 草稿PRD（M2/M3 分期，ADR-015） |
| PRD-014 | [气体、污染与大气](prd/PRD-014-atmosphere-and-pollution.md) | 草稿PRD（ADR-016；M3 预埋/M4 实现，44 AC） |
| PRD-015 | [关押、人质、劳役与处置](prd/PRD-015-captivity-and-prisoners.md) | 草稿PRD（M3；ADR-017 关押系统独立成篇） |
| r01 | [基底：核心引擎](research/01-core-engine.md) | 调研产出 |
| r02 | [基底：插件全景](research/02-plugin-inventory.md) | 调研产出 |
| r03 | [基底：交互层](research/03-front-and-interaction.md) | 调研产出 |
| r04 | [基底：内容与二次开发](research/04-content-and-modding.md) | 调研产出 |
| r05 | [基底：工程与测试基建](research/05-engineering-and-tooling.md) | 调研产出 |
| r06 | [差距分析](research/06-gap-analysis.md) | 草稿 |
| r07 | [MC 生态同类调研](research/07-mc-landscape.md) | 调研产出 |
| r08 | [温度/口渴集成可行性](research/08-temperature-thirst-integration.md) | 调研产出（→ ADR-010） |
| r09 | [太空终局方案对比](research/09-space-endgame.md) | 调研产出（→ ADR-011） |
| r10 | [上游变更与引用迁移：f42e3c1 → 67f28b0](research/10-upstream-delta-f42e3c1-67f28b0.md) | 调研产出（ADR-021 基线前移；431 条引用迁移表、36 条失效结论 F-01…F-36；r01–r05/w05/w06/d12 的 `文件:行号` 改写以此为准） |
| draft | [r10 设计级影响待裁决清单](research/drafts/draft-r10-design-impact-20261019.md) | **已裁决**（ADR-024，2026-10-19）；保留作依据 |
| PLAN-001 | [B-2：四个 modid 改为 plaa_* 含 NOTICE 与冲突声明](plans/PLAN-001-b2-modid-rename.md) | **已验证**（VERIFY-001，2026-10-20）；待人工 Review；改动已提交 `7344f9d`（WSL） |
| PLAN-002 | [M1-WP1：引擎可读面（只读访问器）](plans/PLAN-002-wp1-engine-readable-surface.md) | 计划中（L2；5 个包私有类型；T1–T6；零行为变化验收） |
| PLAN-002-T1 | [WP-1 盘点：五个包私有类型的取得路径](plans/PLAN-002-inventory.md) | 完成：BodyState 可零改动（L1）；Hunger/Beds/Urges 各 1 行 L2；Carry 免改 |
| PLAN-003 | [M1-WP4：禁限区（谁能去哪）](plans/PLAN-003-wp4-steering-zones.md) | 计划中（L1 + L3 待评审；T0–T8；T0 需补读 Refinement 与 Board.Act） |
| PLAN-003-A | [T4 落点与 L3 变更提案（Fitness 单点否决）](plans/PLAN-003-a-t4-standing.md) | **待评审**：`Fitness.of` 是唯一按人闸门；4 文件约 20 行；默认 `Standing.ALL` 零行为变化 |
| PLAN-004 | [M1-WP5：作息表（什么时候干活）](plans/PLAN-004-wp5-hours.md) | 计划中（L1 为主；A 预设路线；T0 待核 `ColonyContext.urges` 能否压制） |
| PLAN-005 | [M1-WP6：解释层（说得出为什么）](plans/PLAN-005-wp6-explanation.md) | 计划中（L1 为主；10 类阻塞；T0 夹具已核：派活可测、需求不可测） |
| PLAN-006 | [M2-WP7：需求与情绪（张力的第一层）](plans/PLAN-006-m2-needs-mood.md) | 计划中（L1 为主；T0 已核：基底已有需求机制，M2 做"张力+可见性+解释"） |
| PLAN-007 | [M2-R1：同行伙伴（关系系统第一刀）](plans/PLAN-007-m2-r1-companions.md) | 计划中：共同劳作→bond→士气→卡片；L1 为主；4 个未知项待读穿 |
| PLAN-008 | [M2-R2：摩擦（关系第二刀）](plans/PLAN-008-m2-r2-friction.md) | 计划中：`grudge` 与 `bond` 独立；状态差的人起摩擦；仇人在旁至少 WORRIED；**不碰否决权（那要 L3）** |
| PLAN-009 | [M2 医疗第一刀：伤口/流血/速度/卡片](plans/PLAN-009-m2-medical-r0.md) | 全 L1；R0 只做可见的伤与后果；**三个问题待拍板**（排班影响/包扎发起/死亡处理） |
| PLAN-010 | [M2 医疗 R1：感染→发烧→死亡（口径 Q3=A）](plans/PLAN-010-m2-medical-r1-infection.md) | 分期计划；R1-1 已开工；死亡含尸体/讣告（PRD-009 G2） |
| VERIFY-001 | [B-2 验证报告（modid 改名 + 与上游互斥）](reports/VERIFY-001-b2.md) | 通过：T1–T6 有证据（unit/i18n 134/0、gametest 651/651、服务端 Done 4.453s、混装上游被拒绝）；3 条遗留 |
| VERIFY-002 | [整合包改用我们的 jar（plaa_* 替换上游 folkways_*）](reports/VERIFY-002-pack-ours.md) | 通过：4 个 jar 入包、索引自校验 47 文件、完整包 44 mod 服务端 Done 9.142s |
| VERIFY-003 | [可分发产物 .mrpack 生成与结构校验](reports/VERIFY-003-mrpack.md) | 通过：47 条目（43 下载 + 4 随包）、哈希合规 0 例外、抽样 URL 可达；未做真实客户端安装 |
| VERIFY-004 | [分发链端到端（全新实例 → 安装器 → 服务端 Done）](reports/VERIFY-004-pack-install-e2e.md) | 通过：44 mod 装出（含 4 个 plaa jar）、installer exit 0、服务端 Done 13.977s |
| VERIFY-005 | [包内容第一批（我们的配置 + FTB 三件套）与端到端复验](reports/VERIFY-005-pack-content-1.md) | 通过：47 mod、配置落地、FTB Quests 加载、Done 20.745s；修正"Teams 可选"为必装 |
| VERIFY-006 | [客户端实测（Prism CLI + 我们自己的实例）](reports/VERIFY-006-client-test.md) | 通过：四个 plaa_* 加载、加入服务端成功；记录 4 个坑与 1 个 41 条缺模型缺陷 |
| VERIFY-007 | [41 条缺模型告警的根因定位与处置](reports/VERIFY-007-missing-models.md) | 根因=Born in Chaos 的 31 个自引用裸 parent；资源包覆盖无效（mod 资源优先）→ **已移除该 mod**，复验 0 告警 0 FATAL |
| VERIFY-008 | [包内 KubeJS 内容管线（附 mrpack 打包器修复）](reports/VERIFY-008-kubejs-content.md) | 通过：1/1 脚本 0 错误、Added 1 recipes、服务端 Done 11.099s；mrpack 现在会带 config/kubejs |
| VERIFY-009 | [任务书第一章（FTB Quests 手写并验证）](reports/VERIFY-009-quest-chapter-1.md) | 通过：1 章 8 任务、0 missing_item、服务端 0 解析错误；记录 tag 任务在本版不可用 |
| VERIFY-010 | [NeoForge 21.1.264 升级尝试（A/B 证明回归，暂缓）](reports/VERIFY-010-neoforge-264-upgrade.md) | 264 编译通过但 1 个 gametest 稳定失败；退回 233 后 651/651；保留 233 构建、包声明 264 |
| VERIFY-011 | [GitHub Release v0.1.0 与包内 jar 改为 release URL](reports/VERIFY-011-release-v0-1-0.md) | 通过：release 4 资产、pack jar 体积归零、安装器 46 mod、Done 9.473s；附 gh 安装与 token scope 记录 |
| VERIFY-012 | [WP-1/T3：BodyViews 只读门面（653/653）](reports/VERIFY-012-wp1-t3-body-views.md) | 通过：0 行上游改动、不可变 record、653/653；并更正 264 结论为"跨版本偶发" |
| VERIFY-013 | [WP-1/T2：PresenceViews（饥饿与床位只读视图，655/655）](reports/VERIFY-013-wp1-t2-presence-views.md) | 通过：2 行包内句柄 + 不可变 record + 2 测试；殖民地查找路径待 WP-6 补验 |
| VERIFY-014 | [WP-1 收口：T5 退避视图 + T6 变更登记（657/657）](reports/VERIFY-014-wp1-t5-t6-wp1-closed.md) | **WP-1 完成**：三个可读面就位、4 个方法 L2、3 处 `// PLA:` 已登记；657 测试全过 |
| VERIFY-015 | [WP-4/T1–T2：禁限区骨架与区域判定（662/662）](reports/VERIFY-015-wp4-t1-t2-steering-skeleton.md) | 通过：新插件 4 文件 + 1 行注册 + 5 测试；`Licences` 是按类型非按人，T4 可能升 L3 |
| VERIFY-016 | [WP-4/T4a：Standing 否决管道（L3，662/662）](reports/VERIFY-016-wp4-t4a-standing.md) | 管道完成：Standing + ZONE_FORBIDDEN + 5 文件接线；`ALL` 下零行为变化；T4b 接线待做 |
| VERIFY-017 | [WP-4/T4b：区域 → 引擎接线（665/665）](reports/VERIFY-017-wp4-t4b-wiring.md) | 通过：Standings provider + Labor 应用 + steering 适配；core 不 import plugins；3 个测试 |
| VERIFY-018 | [WP-4/T5：SteeringRefusal 与四语文案（668/668）](reports/VERIFY-018-wp4-t5-refusals.md) | 通过：`RefusalKind.Named` 自动键、4 语言各 +3 键、3 测试；含偶发测试复跑说明 |
| VERIFY-019 | [WP-4/T6：禁限区页面（列表 + 删除）](reports/VERIFY-019-wp4-t6-steering-page.md) | 页面可用、零新动词；画区接线与擦除留 T6b；偶发测试升为债务 D7 |
| VERIFY-020 | [WP-4/T6b：画出的体积变成禁入区（671/671）](reports/VERIFY-020-wp4-t6b-painted-zones.md) | 通过：采纳 + 忽略同笔画 + 换笔画重采纳；4 条限制如实登记（采纳时机、擦除、单区、区名） |
| VERIFY-021 | [WP-4 收口：T7 同源文案（673/673）](reports/VERIFY-021-wp4-closed.md) | **WP-4 完成**：reason→refusal 单一映射、运行时语言表验证、6 条验收全过；4 条遗留转后续 |
| VERIFY-022 | [WP-5/T0–T1：作息表（共享派活闸，679/679）](reports/VERIFY-022-wp5-hours-t1.md) | 通过：四预设纯算术、默认关闭、与禁区共用闸；**批准的 L3 未使用**（找到了更小的做法） |
| VERIFY-023 | [WP-5/T5：作息的具名理由 + 一个真实缺陷（681/681）](reports/VERIFY-023-wp5-t5-refusal-defect.md) | 词表与四语落地；**发现** Boolean `Standing` 会把"非工作时段"误报成"禁限区"，记为 D8 |
| VERIFY-024 | [WP-5/D8 修复：拒绝会说明是谁拒绝的（684/684）](reports/VERIFY-024-d8-fixed.md) | 通过：`Standing.check` 返回理由 + 注册时绑定 reason；缓存结构未动；3 测试 |
| VERIFY-025 | [WP-5/T4：作息页面与两个开关（686/686）](reports/VERIFY-025-wp5-t4-page.md) | 通过：Flag+Choice、页面显示当前班次与切换倒计时、4 语 10 键；记录"物品当选项"的妥协 |
| VERIFY-026 | [WP-5 收口：T3 降级与债务登记](reports/VERIFY-026-wp5-closed.md) | 收口轮（无代码）：d12 +5 行、T3 降级为结构性保证、新债 D9；测试仍 686 |
| VERIFY-027 | [WP-6/W1–W2：一个地方把拒绝变成人话（689/689）](reports/VERIFY-027-wp6-w1-w2.md) | 通过：14 类原因全覆盖（计划写 10 类，测试抓出漏的 4 类）、四语 30 键、唯一映射点 |
| VERIFY-028 | [WP-6/W3：没人接的活变成一行（692/692）](reports/VERIFY-028-wp6-w3.md) | 通过：行与页面同源、可修的带 1 个 `Open`、动作预算内 |
| VERIFY-029 | [WP-6/W5 调查：端到端测试缺口在哪](reports/VERIFY-029-wp6-w5-investigation.md) | 调查轮（无代码）：求解器自建 `Scheduler`、standing 装不到；下一轮给夹具加注入点（仅测试代码） |
| VERIFY-030 | [WP-6/W5：否决真的让人不接活（693/693）](reports/VERIFY-030-wp6-w5.md) | 通过：测试夹具注入 standing、真实求解器 + 全格否决 → `ZONE_FORBIDDEN`；记录两次假失败的教训 |
| VERIFY-031 | [WP-6/W6：解释层覆盖率报告（14 类，证据分级）](reports/VERIFY-031-wp6-w6-coverage.md) | 文案 14/14，证据 5/14：1 类端到端、3 类上游、9 类零证据；附补证计划 |
| VERIFY-032 | [WP-6/W7 第一轮：两次尝试，两次空白（否定结果）](reports/VERIFY-032-wp6-w7-negative.md) | 否定：静态/换人两种造法都没产出 `NO_LICENCE`/`PACK_FULL`；记三个假设与下一步；基线仍 693 |
| VERIFY-033 | [WP-6/W7 第二轮：三次造不出来 → 没证据的就不说（696/696）](reports/VERIFY-033-wp6-w7-honesty-filter.md) | 通过：`Explanation.shown` 只放行 5 类有证据的原因；`row()` 变 Optional；9 类保持沉默 |
| VERIFY-034 | [WP-6/W7 第三轮：每个原因由谁产出（生产地图）](reports/VERIFY-034-wp6-w7-production-map.md) | 调查：8 类有产出点、**`CLAIM_TAKEN` 零产出**；造不出的真因是"本轮未重排"，下步双人编组+新消息 |
| VERIFY-035 | [WP-6 收口：W7 不再追（四次尝试的账）](reports/VERIFY-035-wp6-closed.md) | **WP-6 关闭**：5/14 对玩家可见，w05"≥8 类"未达；W4/W7 明确不做并说明理由 |
| VERIFY-036 | [WP-8 第一段：每殖民地一张作息表 + 可卸载（699/699）](reports/VERIFY-036-wp8-unload-safety.md) | 修两处真缺陷：多殖民地串台、卸载不摘 provider；3 个测试 |
| VERIFY-037 | [WP-8 第二段：数据真的走了殖民地仓库（702/702）](reports/VERIFY-037-wp8-colony-store.md) | 通过：keep→kept 往返（两个数据源 + 空仓库默认）；整局重启仍属 D11 |
| VERIFY-038 | [WP-8 第三段：数据在关卡拥有的殖民地上（703/703）](reports/VERIFY-038-wp8-level-backed.md) | 通过：mint→keep→按 id 取回；**进程重启改为人工验收**（无玩家建不了殖民地） |
| VERIFY-039 | [队列 ⑤：M1 演示脚本就绪（19 个观察点，未跑通）](reports/VERIFY-039-demo-script.md) | 脚本：[M1-demo-script.md](demo/M1-demo-script.md)；**客户端未实测**，跑通后才算完成 |
| SYNC-001 | [上游同步演练 #1（本地模拟）](reports/SYNC-001-upstream-drill.md) | 通过：0 冲突、PLA 标记保留、合并后构建成功；暴露 `.blockwright/mods.json` 坑 |
| SYNC-002 | [上游同步预检 #2：历史已被重写，不能 merge](reports/SYNC-002-upstream-precheck.md) | 预检（未改动 main）：无共同祖先；85 文件移植预演 = 24 干净 / 12 冲突 / 1 重定位 / 48 新增；`Standing` 撞词 |
| SYNC-003 | [移植第一阶段：改动已落到 aaac8b8，剩 8 个冲突](reports/SYNC-003-port-phase1.md) | 48 新增 / 24 干净 / 4 语言并集已解；剩 8（含 Labor.java、BuiltinPlugins.java）；main 未受影响 |
| SYNC-004 | [移植第二阶段：配置全解开，主源码编译通过](reports/SYNC-004-port-compiles.md) | `compileJava` ✅；上游新增 **6 个模块**（更正 SYNC-003 说法）；剩测试面（`Solving.java` 已无） |
| SYNC-005 | [移植第三阶段：测试跑起来（1402/1404）](reports/SYNC-005-port-tests-run.md) | `compileGametestJava` ✅；1402/1404；两条失败已排除我方注入，疑为旧版合并残留 |
| SYNC-006 | [移植第四阶段：十模块 + 全套 plaa_* 跑起来（1465/1467）](reports/SYNC-006-ten-modules.md) | 10 jar 构建成功；改名误伤「不兼容声明」导致启动崩溃（已修）；仍剩 2 条失败 |
| SYNC-007 | [移植收尾：1467/1467 全绿，根因是 69 处硬编码 modid](reports/SYNC-007-port-green.md) | 十模块构建 + 全套测试通过；60 个事件订阅器曾静默失效；CI 对齐上游矩阵 |
| SYNC-008 | [移植版测试包（10 个 plaa_* + 38 依赖）](reports/SYNC-008-test-package.md) | 产物：216 MB zip；新模块依赖是 required（须整套放）；待游戏内实测 |
| SYNC-009 | [移植落到 main（跳过客户端实测）](reports/SYNC-009-main-switch.md) | `main` = 64e35ad（10 模块 / 1479）；旧历史标签 `pre-port-main-20261106`；**未做客户端实测，风险已写明** |
| SYNC-010 | [v0.2.0 发布 + 整合包改成十模块](reports/SYNC-010-release-020.md) | 11 个资产（10 jar + mrpack）；pack 62 个条目；URL 抽检全 200；**安装未实测** |
| SYNC-011 | [发布包整体校验：62 个下载全部可达且哈希匹配](reports/SYNC-011-mrpack-verified.md) | 62/62 通过（279 MB）· 5 个随包文件与 pack/ 一致；**安装与客户端仍未测（D11）** |
| SYNC-012 | [整合包审计：桥接有效、配置过时（已刷新）](reports/SYNC-012-pack-audit.md) | 桥接 id 在真实 jar 中确认；配置从旧构建换成十模块生成版；发现三条面粉链（待定） |
| SYNC-013 | [`pack-lint`：检查 + 修复](reports/SYNC-013-pack-lint.md) | 5 项检查；首次运行抓到 index↔pack 循环依赖；**`-Fix` 已验证（破坏→报错→修复→幂等）** |
| SYNC-014 | [docs 仓库 CI：四道门禁，四次运行才变绿](reports/SYNC-014-docs-ci.md) | 断链 / pack-lint / 报告登记 / AC 一致性；三次失败各抓到一个真缺陷；**D14 关闭** |
| SYNC-015 | [fork CI 一直是红的：漏掉的第五个改名面](reports/SYNC-015-fork-ci-fix.md) | `data/<modid>/` 未随改名走；修后 **Build #49 十一个作业全绿**（移植后首次） |
| SYNC-016 | [v0.2.1：把带缺陷的 v0.2.0 替换掉](reports/SYNC-016-release-021.md) | 11 个资产；C&B 图案修复进入发布物；整合包 URL/哈希同步；URL 抽检 200 |
| SYNC-017 | [SUMMARY-ALL 改成可重新生成](reports/SYNC-017-summary-generator.md) | `tools/summarize.py` 生成 §2/§3/§4/§8；抓到三个"差点算错"（ADR 20→26、划掉≠结清、行数只数非空） |
| SYNC-018 | [v0.2.1 分发校验 + 依赖完整性](reports/SYNC-018-pack-deps-021.md) | 62/62 哈希匹配 · 10 jar 元数据正确 · 服务端必需依赖齐全；检查自身被证伪三次 |
| SYNC-019 | [任务书第二章进包，v0.2.2 只更新整合包](reports/SYNC-019-chapter-2-shipped.md) | 跨章 id/依赖校验通过；mrpack 69 条（含 2 章节）；**游戏内加载仍未验**（并入 D11） |
| SYNC-020 | [pack 规格 vs 实际：三处过期、一处措辞错](reports/SYNC-020-pack-spec-audit.md) | 10 jar / 7 依赖 / Tavern 可选均属实；**jar 其实不随包**；§12.3/§12.4 已更正 |
| SYNC-021 | [数据命名空间回归门禁（unit 142/142）](reports/SYNC-021-namespace-gate.md) | 规则做窄（只查 folkways/plaa 前缀）；**改回旧名当场变红**，恢复即绿 |
| SYNC-022 | [旧 modid 门禁扩到十模块（并发现六模块缺不兼容声明）](reports/SYNC-022-stale-id-gate-ten.md) | 精确匹配（前缀会误伤票据名）；六个新模块补齐 4 条 `incompatible`；unit 142 · gametest 1488 |
| VERIFY-048 | [十模块打包 jar 在真实专用服务端启动](reports/VERIFY-048-dedicated-server.md) | `Done (4.511s)`、0 FATAL、10 个 modid 全注册；16 条 ERROR 均为可选集成噪音 |
| VERIFY-049 | [M2-R1 第一段：关系簿（1472/1472）](reports/VERIFY-049-m2-r1-book.md) | 数据层落地：上限 30 / 冷却 500 刻 / 淘汰 / prune / 存读；T0 四个未知项读穿，采样器可留 L1 |
| VERIFY-050 | [M2-R1 第二段：采样器（1476/1476）](reports/VERIFY-050-m2-r1-sampler.md) | 每 5 秒采样"谁在干活、站哪"，≤8 格成对入簿；纯函数可测；L2 仅一处注册 |
| VERIFY-051 | [M2-R1 第三段：陪伴即有意义（1477/1477）](reports/VERIFY-051-m2-r1-morale.md) | `amongFriends` 只压"没活干→发愁"；压不住饥饿；快照缓存避免看世界 |
| VERIFY-052 | [M2-R1 第四段：卡片上的一行（1479/1479）](reports/VERIFY-052-m2-r1-card.md) | 朋友在旁才显示；四语键；**发现 i18n 枚举键门禁未随移植过来 → D18** |
| VERIFY-053 | [M2-R1 收口：关系第一刀完整落地（1479/1479）](reports/VERIFY-053-m2-r1-closed.md) | R1-1..R1-5 全绿；卡片两行（事实+建议）；明确未做怨恨/哀悼/关系页 |
| VERIFY-054 | [D18 关闭：i18n 枚举键门禁恢复（unit 140/140）](reports/VERIFY-054-d18-i18n-gate.md) | 门禁比旧版更严（查四语）；它当场拒绝了我们自己写死键的枚举，于是改代码不改测试 |
| VERIFY-055 | [M2 医疗 R0-1/R0-2：伤口与流血（1485/1485）](reports/VERIFY-055-m2-medical-data.md) | 数据层落地；**玩家仍看不到、行为无变化**；速度惩罚等 Q1 |
| VERIFY-056 | [M3 关押接缝：`Kind.CONFINE`（1488/1488）](reports/VERIFY-056-confine-kind.md) | 白名单语义落地；空主体列表不生效；**尚无内容使用它，零影响** |
| VERIFY-057 | [否定结果：`CONFINE` 拦不住派活](reports/VERIFY-057-subject-veto-gap.md) | 引擎否决权认不出"谁"；主体类区域（含 ALLOW_ONLY/LIMIT）在调度层惰性；**A/B 待拍板** |
| VERIFY-058 | [M2 R2-2：怨气按「A·旁人在受罪」积累（1491/1491）](reports/VERIFY-058-m2-r2-friction-sampler.md) | 采样层接上；**测试抓到共享冷却与 now=0 两个真 bug**；mood/卡片未接 |
| VERIFY-059 | [M2 R2 收口：仇人让他不痛快（1492/1492）](reports/VERIFY-059-m2-r2-closed.md) | 关系第二刀完成；卡片首次呈现"人事安排的代价"；两类并存时只说仇人那条 |
| VERIFY-060 | [M2 R0-3：重伤者不被派活（口径 C，1495/1495）](reports/VERIFY-060-m2-r03-severe.md) | 复用 `Urge.reserve`，不动调度；**接线未做端到端测试**（记为未验证） |
| VERIFY-061 | [M2 R0-4：卡片说「伤得太重，暂时不接活」（1496/1496）](reports/VERIFY-061-m2-r04-card.md) | 玩家第一次看见医疗状态；**只承诺真实的事**（无治疗就不承诺康复） |
| VERIFY-062 | [M2 R0 收口：重伤 → 一条 reservation（1498/1498）](reports/VERIFY-062-m2-r0-closed.md) | 贡献抽成纯函数并测；**调度是否承认 reservation 仍记为未证**；解释层结论：卡片即解释 |
| VERIFY-063 | [D20 关闭：否决权认人（1500/1500）](reports/VERIFY-063-d20-subject-veto.md) | ALLOW_ONLY 与 CONFINE 在调度层生效；**LIMIT 仍只走诊断**（会扫全殖民地） |
| VERIFY-064 | [M2 R1-1：感染会自己变深（1504/1504）](reports/VERIFY-064-m2-r1-1-infection.md) | 感染按部位记录、骰子作为参数（可复现）；到门槛即"重伤"；**玩家仍看不到** |
| VERIFY-065 | [那句话划掉了：真实殖民地会为重伤者保留（1505/1505）](reports/VERIFY-065-work-stop-end-to-end.md) | 端到端：真殖民地 + 真健康簿 + 真 `urges()`；**"夹具太贵"被证明是误判** |
| VERIFY-066 | [M2 R1-3 地基：每次死亡都留痕（1508/1508）](reports/VERIFY-066-m2-r1-3-deaths.md) | 死亡记录（谁/何名/何因/何时）已就位；**尚无人会死**，书架还空着 |
| VERIFY-067 | [R1-2/R1-3 地基：派生发烧 + 未安葬状态（1511/1511）](reports/VERIFY-067-fever-and-burial.md) | 发烧由感染派生（单一真相源）；`unburiedCount` 对应 PRD-009 G2；**仍无人会死** |
| VERIFY-068 | [M2 R1-2：居民会死了（1513/1513）](reports/VERIFY-068-m2-r1-2-death.md) | 任一满足触发死亡；真实殖民地端到端；**玩家还看不到讣告，尸体下一段** |
| VERIFY-047 | [D16 关闭：`Standing → Veto` 改名，门禁抓到一条真回归](reports/VERIFY-047-veto-rename.md) | 改名（只改标识符，注释/字符串/语言文件不动）；i18n 门禁抓到 N6 的键约定回归并修复；四件套全绿 |
| VERIFY-040 | [队列 ③ 收尾：构建统一到 264（原 A/B 结论被推翻）](reports/VERIFY-040-build-aligned-264.md) | 同机同日 5+5 次零失败；两版本 ERROR 剖面一致 → **264 回归结论作废**，构建已对齐 |
| VERIFY-041 | [M2/N1–N2：心情由需求推出（708/708）](reports/VERIFY-041-m2-n1-n2-mood.md) | 通过：4 档纯函数 + 基底紧急阈值 + 四语 8 键；每档必须能给建议 |
| VERIFY-042 | [M2/N3：心情读得出来（710/710）](reports/VERIFY-042-m2-n3-mood-readout.md) | 通过：`PresenceViews.mood` + 1 个 L2 快照出口；未知项宁低不高；空路径安全 |
| VERIFY-043 | [M2/N4 前置调查：rules-first 只能靠 L3](reports/VERIFY-043-m2-n4-investigation.md) | 调查（无代码）：选留谓词内联、无插件钩子 → N4 收窄为 needs-first + 解释 |
| VERIFY-044 | [M2/N5：说清"为什么休息时段还动着"（712/712）](reports/VERIFY-044-m2-n5-needs-explanation.md) | 通过：有需求才解释、没需求保持沉默；解决"需求优先 vs 作息坏了"的误判 |
| VERIFY-045 | [队列 ⑦：CI 门禁 P0+P1 落地（修掉一条真缺陷）](reports/VERIFY-045-ci-gates.md) | 通过：本机 Linux 四件套全绿（build/134/7/712）；补禁区页面四语文案、登记 bench 判据表；P1 只对 D7 按名单重试一次；D6/D7 关闭 |
| VERIFY-046 | [M2/N6：居民卡上看得见心情（714/714）](reports/VERIFY-046-m2-n6-mood-card.md) | 通过：复用 lookLines 聚合，零改动上游居民页；CONTENT 与无人时保持沉默；四档键运行时均可解析 |
| k00 | [整合包规格](pack/00-pack-spec.md) | 草稿 |
| k01 | [Mod 清单（已核实 1.21.1+NeoForge 可用性）](pack/01-modlist.md) | 调研产出 |
| k02 | [配置、数据包与脚本内容](pack/02-config-and-datapack.md) | 草稿 |
| k03 | [性能预算](pack/03-performance-budget.md) | 草稿 |
| k04 | [任务书与剧情引导（FTB Quests）](pack/04-quest-book-and-guidance.md) | 草稿（ADR-018；可选引导，缺 FTB 可玩） |
| k05 | [内容作者手册](pack/05-content-author-handbook.md) | 草稿（43 货架作者视角、图案上限、KubeJS 边界、3 个完整示例） |
| k06 | [首批 40 条事件模板](pack/06-incident-templates.md) | 草稿（PRD-002 的内容填充；环境 8/社会 9/威胁 8/机会 8/神秘 7） |
| w00 | [文档驱动 AI 工作流](workflow/00-ai-workflow.md) | 已定稿 |
| w01 | [角色分工与工具约定](workflow/01-agent-roles-and-tools.md) | 草稿 |
| w02 | [文档生命周期](workflow/02-doc-lifecycle.md) | 草稿 |
| w03 | [测试与验收策略](workflow/03-test-and-acceptance.md) | 草稿 |
| w04 | [提示词模板库](workflow/04-prompts.md) | 草稿 |
| w05 | [M1 任务拆解与验收矩阵](workflow/05-m1-task-breakdown.md) | 草稿（WP-0…WP-11；83 条 AC 映射；关键路径与风险） |
| w06 | [构建环境、依赖与 CI 规格](workflow/06-build-and-ci.md) | 草稿（依赖获取流程、Linux gametest、P0–P3 流水线、上游同步 runbook） |
| w07 | [模型分级与升级协议](workflow/07-model-routing-and-escalation.md) | 草稿（刀刃清单 10 条、四段式模板、升级触发信号、反模式） || w08 | [多模型协作（DSH × ZCode/GLM × claude × codex）](workflow/08-multi-agent-collaboration.md) | 草稿（文件总线 .coop + 交叉评审 + 失败模式） |
