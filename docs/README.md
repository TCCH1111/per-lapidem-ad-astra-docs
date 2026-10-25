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
| `reference/folkways-67f28b0/` | 基底 mod 的只读参考副本（当前基线，升级时整体替换；来源与 commit 见 `reference/README.md`）。`reference/folkways-master/`（旧快照 f42e3c1）仅供既有引用过渡 |
| `reference/tyk-construction-prd-zh.txt` | 参考 PRD 原文（格式样例） |
| `pack/` | 整合包工程（**packwiz**，[ADR-021](00-charter.md)）：`pack.toml`、`index.toml`、`mods/*.pw.toml`；`config/`、`kubejs/`、`datapacks/` 按 PRD 需要再建 |
| WSL `~/pla/mod`（Windows 侧无副本） | Folkways 的 fork，**独立 git 仓库**（分支 `main`、remote `upstream` → GitHub、标签 `upstream-base-67f28b0-20261019`），位于 WSL2 Ubuntu-24.04 的 ext4（[ADR-022](00-charter.md)）；Windows 侧经 `\\wsl.localhost\Ubuntu-24.04\home\tcch1111\pla\mod` 或 [`tools/wsl-run.sh`](../tools/wsl-run.sh) 访问；临时克隆 `mod/` 已于 2026-10-19 删除 |
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
| d12 | [Folkways fork 策略](design/12-fork-strategy.md) | 草稿（ADR-007 已定） |
| d13 | [气体、污染与资源循环](design/13-gases-pollution-and-cycles.md) | 草稿（ADR-016；M3 预埋/M4 实现） |
| d14 | [存档、备份与迁移](design/14-saves-backups-and-migration.md) | 草稿（ADR-018；增量+全量、永不覆盖、决策日志独立归档） |
| d15 | [能源、动力适配层与机械族](design/15-power-and-mechanical-residents.md) | 草稿（ADR-019；FE/EU/旋转/蒸汽适配、四种驱动、人造子宫） |
| d16 | [诊断界面文字线框原型](design/16-diagnosis-ui-prototype.md) | 草稿（6 页 × 三态线框；D-1~D-31 全覆盖） |
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
