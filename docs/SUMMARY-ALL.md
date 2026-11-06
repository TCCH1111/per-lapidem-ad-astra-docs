# 全项目文档汇总（单文件版）

```
生成日期：2026-11-05
覆盖范围：docs/ 下全部 Markdown（本文件除外）
性质：只读汇总；本文件不影响任何既有文档
```

> **用途**：一份文件看清「项目是什么、文档都在哪、决定了什么、欠了什么、下一步做什么」。
> 需要细节时按表里的链接进原文，本文件只做索引与摘要。

---

## 1. 项目一句话

**Per Lapidem ad Astra**：以 [Folkways](https://github.com/IzakyL/folkways) 为基底 fork 的 1.21.1 NeoForge 殖民地整合包，
目标是"更丰富、更好玩、自由度更高"的矮人要塞 / 环世界 / 希克斯之歌式体验——**每位居民都会自己安排工作**，
玩家负责规则、区域、时代与叙事，而不是替每个人点鼠标。

| 维度 | 现状 |
| --- | --- |
| 上游 | `IzakyL/folkways` @ `aaac8b8`（**已重写历史，与我们无共同祖先**） |
| 我们的分支 | `main` = `c456385`（旧版，714/714）· `port/aaac8b8` = `cb5a659`（**10 模块，1477/1477**） |
| 版本 | MC 1.21.1 · NeoForge **21.1.264** · Java 21 |
| 模块 | **10 个**：core / vanilla / create / modulargolems / cookery / rts / warfare / tacz / firefighting / chiselsandbits（modid 全 `plaa_*`） |
| 已交付玩法 | 禁限区（画区→绕行）、作息表（到点停工）、解释层（说得出为什么）、心情（四档可见） |
| 关系系统 | R1-1 数据层 + R1-2 采样器 + R1-3 士气已落地（**1477/1477**），卡片/解释未做 |
| 门禁 | build ✅ · unit 138/138 ✅ · typecheck ✅ · gametest 1472/1472 ✅ |
| 发布物 | v0.1.0 已发（4 jar 时代）；移植版测试包已备（`.mrpack` 216 MB） |

---

## 2. 文档地图（按目录）

### 2.1 顶层与章程

| 文件 | 标题 | 行数 |
| --- | --- | --- |
| [00-charter.md](00-charter.md) | 项目章程 · Per Lapidem ad Astra | 125 |
| [README.md](README.md) | 文档地图 · Per Lapidem ad Astra | 200 |
| [ROADMAP.md](ROADMAP.md) | 长期目标与路线（ROADMAP） | 93 |

### 2.2 设计（design/）——「要做成什么样」

| 文件 | 标题 | 行数 |
| --- | --- | --- |
| [01-vision-and-pillars.md](design/01-vision-and-pillars.md) | 愿景与设计支柱 | 153 |
| [02-benchmark.md](design/02-benchmark.md) | 对标分析：我们借什么、弃什么 | 185 |
| [03-glossary.md](design/03-glossary.md) | 全局术语表 | 190 |
| [04-world-and-simulation.md](design/04-world-and-simulation.md) | 世界与模拟总纲 | 165 |
| [05-settlement-and-residents.md](design/05-settlement-and-residents.md) | 殖民地与居民 | 236 |
| [06-economy-and-logistics.md](design/06-economy-and-logistics.md) | 经济与物流 | 163 |
| [07-threats-and-narrative.md](design/07-threats-and-narrative.md) | 威胁、防卫与故事生成 | 207 |
| [08-progression-and-ages.md](design/08-progression-and-ages.md) | 时代进程（Per Lapidem ad Astra） | 142 |
| [09-interaction-and-ui.md](design/09-interaction-and-ui.md) | 交互层与信息呈现 | 144 |
| [10-multiplayer-and-server.md](design/10-multiplayer-and-server.md) | 多人、权限与性能 | 119 |
| [11-freedom-design.md](design/11-freedom-design.md) | 自由度设计纲领 | 189 |
| [12-fork-strategy.md](design/12-fork-strategy.md) | Folkways fork 策略 | 253 |
| [13-gases-pollution-and-cycles.md](design/13-gases-pollution-and-cycles.md) | 气体、污染与资源循环 | 450 |
| [14-saves-backups-and-migration.md](design/14-saves-backups-and-migration.md) | d14 存档、备份与迁移 | 316 |
| [15-power-and-mechanical-residents.md](design/15-power-and-mechanical-residents.md) | 能源、动力适配层与机械族（Per Lapidem ad Astra） | 384 |
| [16-diagnosis-ui-prototype.md](design/16-diagnosis-ui-prototype.md) | 16 · 诊断界面的文字线框原型 | 597 |

### 2.3 PRD（prd/）——「每个系统怎么运作、验收是什么」

| 文件 | 标题 | 行数 |
| --- | --- | --- |
| [00-prd-template.md](prd/00-prd-template.md) | PRD-NNN · <系统名称> | 263 |
| [PRD-001-needs-mood-memory.md](prd/PRD-001-needs-mood-memory.md) | PRD-001 · 需求、情绪与记忆 | 930 |
| [PRD-002-incidents-and-narrator.md](prd/PRD-002-incidents-and-narrator.md) | PRD-002 · 事件与叙述者 | 460 |
| [PRD-003-season-temperature-thirst-nutrition.md](prd/PRD-003-season-temperature-thirst-nutrition.md) | PRD-003 · 季节、温度、口渴与营养 | 677 |
| [PRD-004-threats-and-defence.md](prd/PRD-004-threats-and-defence.md) | PRD-004 · 威胁、袭击与防卫 | 525 |
| [PRD-005-intent-and-micro-control.md](prd/PRD-005-intent-and-micro-control.md) | PRD-005 · 意图与微观控制（调度层） | 544 |
| [PRD-006-stock-rules-and-diagnosis.md](prd/PRD-006-stock-rules-and-diagnosis.md) | PRD-006 · 仓储规则与因果诊断 | 531 |
| [PRD-007-scenarios.md](prd/PRD-007-scenarios.md) | PRD-007 · 剧本（开局与规则覆盖） | 608 |
| [PRD-008-relationships-and-social.md](prd/PRD-008-relationships-and-social.md) | PRD-008 · 关系与社交 | 747 |
| [PRD-009-generations-and-legacy.md](prd/PRD-009-generations-and-legacy.md) | PRD-009 · 世代与传承 | 880 |
| [PRD-010-diplomacy-and-trade.md](prd/PRD-010-diplomacy-and-trade.md) | PRD-010 · 外交与贸易 | 725 |
| [PRD-011-progression-knowledge-and-space.md](prd/PRD-011-progression-knowledge-and-space.md) | PRD-011 · 时代进程、知识与太空计划 | 556 |
| [PRD-012-multiplayer-and-permissions.md](prd/PRD-012-multiplayer-and-permissions.md) | PRD-012 · 多人协作与权限 | 633 |
| [PRD-013-medical-and-surgery.md](prd/PRD-013-medical-and-surgery.md) | PRD-013 · 医疗、伤病与手术 | 754 |
| [PRD-014-atmosphere-and-pollution.md](prd/PRD-014-atmosphere-and-pollution.md) | PRD-014 · 气体、污染与资源循环 | 667 |
| [PRD-015-captivity-and-prisoners.md](prd/PRD-015-captivity-and-prisoners.md) | PRD-015 · 关押、人质、劳役与处置 | 620 |

### 2.4 工作流（workflow/）——「怎么干活」

| 文件 | 标题 | 行数 |
| --- | --- | --- |
| [00-ai-workflow.md](workflow/00-ai-workflow.md) | 文档驱动的 AI 工作流（本项目定制版） | 194 |
| [01-agent-roles-and-tools.md](workflow/01-agent-roles-and-tools.md) | 角色分工与工具约定 | 94 |
| [02-doc-lifecycle.md](workflow/02-doc-lifecycle.md) | 文档生命周期 | 107 |
| [03-test-and-acceptance.md](workflow/03-test-and-acceptance.md) | 测试与验收策略 | 161 |
| [04-prompts.md](workflow/04-prompts.md) | 提示词模板库 | 190 |
| [05-m1-task-breakdown.md](workflow/05-m1-task-breakdown.md) | M1 可玩骨架 · 任务拆解与验收矩阵 | 499 |
| [06-build-and-ci.md](workflow/06-build-and-ci.md) | 构建环境、依赖与 CI 规格（w06） | 440 |
| [07-model-routing-and-escalation.md](workflow/07-model-routing-and-escalation.md) | 模型分级与升级协议（把钱花在刀刃上） | 122 |
| [08-multi-agent-collaboration.md](workflow/08-multi-agent-collaboration.md) | 多模型协作（DSH × ZCode/GLM × claude × codex） | 142 |

### 2.5 整合包（pack/）——「玩家实际拿到什么」

| 文件 | 标题 | 行数 |
| --- | --- | --- |
| [00-pack-spec.md](pack/00-pack-spec.md) | 整合包规格 | 189 |
| [01-modlist.md](pack/01-modlist.md) | 01 · Mod 清单：1.21.1 + NeoForge 可用性核实 | 316 |
| [02-config-and-datapack.md](pack/02-config-and-datapack.md) | 配置、数据包与脚本内容规划 | 191 |
| [03-performance-budget.md](pack/03-performance-budget.md) | 性能预算 | 113 |
| [04-quest-book-and-guidance.md](pack/04-quest-book-and-guidance.md) | 04 · 任务书与剧情引导（FTB Quests） | 471 |
| [05-content-author-handbook.md](pack/05-content-author-handbook.md) | 内容作者手册 | 515 |
| [06-incident-templates.md](pack/06-incident-templates.md) | 首批事件模板清单（40 条） | 586 |

### 2.6 计划（plans/）——「每一轮具体做什么」

| 文件 | 标题 | 行数 |
| --- | --- | --- |
| [PLAN-001-b2-modid-rename.md](plans/PLAN-001-b2-modid-rename.md) | PLAN-001 · B-2：把 fork 的四个 modid 改为 `plaa_*`（含 NOTICE 与冲突声明） | 190 |
| [PLAN-002-inventory.md](plans/PLAN-002-inventory.md) | PLAN-002 附录 · T1 盘点：五个包私有类型的取得路径 | 62 |
| [PLAN-002-wp1-engine-readable-surface.md](plans/PLAN-002-wp1-engine-readable-surface.md) | PLAN-002 · M1-WP1：引擎可读面（把诊断需要的数据提升为公开只读） | 89 |
| [PLAN-003-a-t4-standing.md](plans/PLAN-003-a-t4-standing.md) | PLAN-003 附录 A · T4 落点与 L3 变更提案（`Fitness` 单点否决） | 82 |
| [PLAN-003-wp4-steering-zones.md](plans/PLAN-003-wp4-steering-zones.md) | PLAN-003 · M1-WP4：禁限区（谁能去哪） | 100 |
| [PLAN-004-wp5-hours.md](plans/PLAN-004-wp5-hours.md) | PLAN-004 · M1-WP5：作息表（什么时候干活） | 94 |
| [PLAN-005-wp6-explanation.md](plans/PLAN-005-wp6-explanation.md) | PLAN-005 · M1-WP6：解释层（说得出为什么） | 71 |
| [PLAN-006-m2-needs-mood.md](plans/PLAN-006-m2-needs-mood.md) | PLAN-006 · M2-WP7：需求与情绪（张力的第一层） | 81 |
| [PLAN-007-m2-r1-companions.md](plans/PLAN-007-m2-r1-companions.md) | PLAN-007 · M2-R1：同行伙伴（关系系统的第一刀） | 87 |

### 2.7 调研（research/）——「上游与生态的事实」

| 文件 | 标题 | 行数 |
| --- | --- | --- |
| [01-core-engine.md](research/01-core-engine.md) | 01 · Folkways 核心引擎能力清单 | 143 |
| [02-plugin-inventory.md](research/02-plugin-inventory.md) | 基底：插件清单与玩家可见内容（r02） | 377 |
| [03-front-and-interaction.md](research/03-front-and-interaction.md) | 03 · Folkways 玩家交互层能力清单 | 168 |
| [04-content-and-modding.md](research/04-content-and-modding.md) | 04 · Folkways 内容创作与二次开发能力边界 | 176 |
| [05-engineering-and-tooling.md](research/05-engineering-and-tooling.md) | 基底：工程与测试基建（r05） | 256 |
| [06-gap-analysis.md](research/06-gap-analysis.md) | 差距分析：基底能给我们什么、我们必须自己造什么 | 127 |
| [07-mc-landscape.md](research/07-mc-landscape.md) | MC 生态调研：殖民地 / 居民 / 需求情绪 / 事件威胁（重点 1.21.1 NeoForge） | 172 |
| [08-temperature-thirst-integration.md](research/08-temperature-thirst-integration.md) | 08 · 季节 / 温度 / 口渴能否挂到 Folkways 居民身上 | 223 |
| [09-space-endgame.md](research/09-space-endgame.md) | 09 · 太空终局：多方块火箭 + 空间站的候选技术方案 | 141 |
| [10-upstream-delta-f42e3c1-67f28b0.md](research/10-upstream-delta-f42e3c1-67f28b0.md) | 上游差异：f42e3c1 → 67f28b0（整树重构的路径与行号迁移） | 1024 |

### 2.8 演示（demo/）

| 文件 | 标题 | 行数 |
| --- | --- | --- |
| [M1-demo-script.md](demo/M1-demo-script.md) | M1 演示脚本 · Per Lapidem ad Astra | 76 |

### 2.9 证据（reports/）

共 **57** 份：`VERIFY-001..049`（做了什么、证据是什么）与 `SYNC-001..008`（上游同步与移植）。
完整逐份标题见下表：

| 文件 | 标题 |
| --- | --- |
| [SYNC-001-upstream-drill.md](reports/SYNC-001-upstream-drill.md) | SYNC-001 · 上游同步演练 #1（本地模拟，无网络） |
| [SYNC-002-upstream-precheck.md](reports/SYNC-002-upstream-precheck.md) | SYNC-002 · 上游同步预检 #2：历史已被重写，不能用 merge |
| [SYNC-003-port-phase1.md](reports/SYNC-003-port-phase1.md) | SYNC-003 · 移植第一阶段：改动已落到 aaac8b8，剩 8 个冲突 |
| [SYNC-004-port-compiles.md](reports/SYNC-004-port-compiles.md) | SYNC-004 · 移植第二阶段：配置全部解开，**主源码编译通过** |
| [SYNC-005-port-tests-run.md](reports/SYNC-005-port-tests-run.md) | SYNC-005 · 移植第三阶段：测试跑起来了（1402 / 1404） |
| [SYNC-006-ten-modules.md](reports/SYNC-006-ten-modules.md) | SYNC-006 · 移植第四阶段：**十个模块、全套 plaa_* 跑起来了**（1465 / 1467） |
| [SYNC-007-port-green.md](reports/SYNC-007-port-green.md) | SYNC-007 · 移植收尾：**1467 / 1467 全绿**，根因是 69 处硬编码 modid |
| [SYNC-008-test-package.md](reports/SYNC-008-test-package.md) | SYNC-008 · 移植版测试包（48 个文件 / 10 个 `plaa_*` + 38 个依赖） |
| [VERIFY-001-b2.md](reports/VERIFY-001-b2.md) | VERIFY-001 · B-2（modid 改为 `plaa_*` + 与上游互斥声明） |
| [VERIFY-002-pack-ours.md](reports/VERIFY-002-pack-ours.md) | VERIFY-002 · 整合包改用我们的 jar（`plaa_*` 替换上游 `folkways_*`） |
| [VERIFY-003-mrpack.md](reports/VERIFY-003-mrpack.md) | VERIFY-003 · 可分发产物 `.mrpack` 生成与结构校验 |
| [VERIFY-004-pack-install-e2e.md](reports/VERIFY-004-pack-install-e2e.md) | VERIFY-004 · 分发链端到端（全新实例 → packwiz-installer 装包 → 服务端到 Done） |
| [VERIFY-005-pack-content-1.md](reports/VERIFY-005-pack-content-1.md) | VERIFY-005 · 包内容第一批（我们的配置 + FTB 三件套）与端到端复验 |
| [VERIFY-006-client-test.md](reports/VERIFY-006-client-test.md) | VERIFY-006 · 客户端实测（Prism CLI + 我们自己的实例） |
| [VERIFY-007-missing-models.md](reports/VERIFY-007-missing-models.md) | VERIFY-007 · 41 条缺模型告警的根因定位与修复尝试 |
| [VERIFY-008-kubejs-content.md](reports/VERIFY-008-kubejs-content.md) | VERIFY-008 · 包内 KubeJS 内容管线（并修复 mrpack 打包器漏带 overrides 的 bug） |
| [VERIFY-009-quest-chapter-1.md](reports/VERIFY-009-quest-chapter-1.md) | VERIFY-009 · 任务书第一章（FTB Quests 数据手写并验证零解析错误） |
| [VERIFY-010-neoforge-264-upgrade.md](reports/VERIFY-010-neoforge-264-upgrade.md) | VERIFY-010 · NeoForge 21.1.264 升级尝试（A/B 证明回归，暂缓） |
| [VERIFY-011-release-v0-1-0.md](reports/VERIFY-011-release-v0-1-0.md) | VERIFY-011 · GitHub Release v0.1.0 与包内 jar 改为 release URL |
| [VERIFY-012-wp1-t3-body-views.md](reports/VERIFY-012-wp1-t3-body-views.md) | VERIFY-012 · WP-1 / T3：`BodyViews` 只读门面（653/653 通过） |
| [VERIFY-013-wp1-t2-presence-views.md](reports/VERIFY-013-wp1-t2-presence-views.md) | VERIFY-013 · WP-1 / T2：`PresenceViews`（饥饿与床位只读视图，655/655 通过） |
| [VERIFY-014-wp1-t5-t6-wp1-closed.md](reports/VERIFY-014-wp1-t5-t6-wp1-closed.md) | VERIFY-014 · WP-1 收口：T5 退避视图 + T6 变更登记（657/657） |
| [VERIFY-015-wp4-t1-t2-steering-skeleton.md](reports/VERIFY-015-wp4-t1-t2-steering-skeleton.md) | VERIFY-015 · WP-4 / T1–T2：禁限区骨架与区域判定（662/662） |
| [VERIFY-016-wp4-t4a-standing.md](reports/VERIFY-016-wp4-t4a-standing.md) | VERIFY-016 · WP-4 / T4a：`Standing` 否决管道（L3，默认零行为变化） |
| [VERIFY-017-wp4-t4b-wiring.md](reports/VERIFY-017-wp4-t4b-wiring.md) | VERIFY-017 · WP-4 / T4b：区域 → 引擎的接线（665/665） |
| [VERIFY-018-wp4-t5-refusals.md](reports/VERIFY-018-wp4-t5-refusals.md) | VERIFY-018 · WP-4 / T5：`SteeringRefusal` 与四语文案（668/668） |
| [VERIFY-019-wp4-t6-steering-page.md](reports/VERIFY-019-wp4-t6-steering-page.md) | VERIFY-019 · WP-4 / T6：禁限区页面（列表 + 删除） |
| [VERIFY-020-wp4-t6b-painted-zones.md](reports/VERIFY-020-wp4-t6b-painted-zones.md) | VERIFY-020 · WP-4 / T6b：画出的体积变成禁入区（671/671） |
| [VERIFY-021-wp4-closed.md](reports/VERIFY-021-wp4-closed.md) | VERIFY-021 · WP-4 收口：T7 同源文案（673/673） |
| [VERIFY-022-wp5-hours-t1.md](reports/VERIFY-022-wp5-hours-t1.md) | VERIFY-022 · WP-5 / T0–T1：作息表（共享派活闸，679/679） |
| [VERIFY-023-wp5-t5-refusal-defect.md](reports/VERIFY-023-wp5-t5-refusal-defect.md) | VERIFY-023 · WP-5 / T5：作息的具名理由（681/681）＋一个被发现的真实缺陷 |
| [VERIFY-024-d8-fixed.md](reports/VERIFY-024-d8-fixed.md) | VERIFY-024 · WP-5 / D8 修复：拒绝会说明"是谁拒绝的"（684/684） |
| [VERIFY-025-wp5-t4-page.md](reports/VERIFY-025-wp5-t4-page.md) | VERIFY-025 · WP-5 / T4：作息页面与两个开关（686/686） |
| [VERIFY-026-wp5-closed.md](reports/VERIFY-026-wp5-closed.md) | VERIFY-026 · WP-5 收口：T3 降级与债务登记 |
| [VERIFY-027-wp6-w1-w2.md](reports/VERIFY-027-wp6-w1-w2.md) | VERIFY-027 · WP-6 / W1–W2：一个地方把拒绝变成人话（689/689） |
| [VERIFY-028-wp6-w3.md](reports/VERIFY-028-wp6-w3.md) | VERIFY-028 · WP-6 / W3：没人接的活变成一行（692/692） |
| [VERIFY-029-wp6-w5-investigation.md](reports/VERIFY-029-wp6-w5-investigation.md) | VERIFY-029 · WP-6 / W5 调查：端到端测试缺口在哪 |
| [VERIFY-030-wp6-w5.md](reports/VERIFY-030-wp6-w5.md) | VERIFY-030 · WP-6 / W5：否决真的让人不接活（693/693） |
| [VERIFY-031-wp6-w6-coverage.md](reports/VERIFY-031-wp6-w6-coverage.md) | VERIFY-031 · WP-6 / W6：解释层覆盖率报告（14 类，证据分级） |
| [VERIFY-032-wp6-w7-negative.md](reports/VERIFY-032-wp6-w7-negative.md) | VERIFY-032 · WP-6 / W7 第一轮：两次尝试，两次空白（否定结果） |
| [VERIFY-033-wp6-w7-honesty-filter.md](reports/VERIFY-033-wp6-w7-honesty-filter.md) | VERIFY-033 · WP-6 / W7 第二轮：三次造不出来 → 改为"没证据的就不说" |
| [VERIFY-034-wp6-w7-production-map.md](reports/VERIFY-034-wp6-w7-production-map.md) | VERIFY-034 · WP-6 / W7 第三轮：每个原因到底由谁产出（生产代码地图） |
| [VERIFY-035-wp6-closed.md](reports/VERIFY-035-wp6-closed.md) | VERIFY-035 · WP-6 收口：W7 不再追（四次尝试的账） |
| [VERIFY-036-wp8-unload-safety.md](reports/VERIFY-036-wp8-unload-safety.md) | VERIFY-036 · WP-8 / 第一段：每殖民地一张作息表 + 可卸载（699/699） |
| [VERIFY-037-wp8-colony-store.md](reports/VERIFY-037-wp8-colony-store.md) | VERIFY-037 · WP-8 / 第二段：数据真的走了殖民地仓库（702/702） |
| [VERIFY-038-wp8-level-backed.md](reports/VERIFY-038-wp8-level-backed.md) | VERIFY-038 · WP-8 / 第三段：数据在"关卡拥有的殖民地"上（703/703） |
| [VERIFY-039-demo-script.md](reports/VERIFY-039-demo-script.md) | VERIFY-039 · 队列 ⑤：M1 演示脚本就绪（19 个观察点，**未跑通**） |
| [VERIFY-040-build-aligned-264.md](reports/VERIFY-040-build-aligned-264.md) | VERIFY-040 · 队列 ③ 收尾：构建统一到 264（结论被推翻并更正） |
| [VERIFY-041-m2-n1-n2-mood.md](reports/VERIFY-041-m2-n1-n2-mood.md) | VERIFY-041 · M2 / N1–N2：心情由需求推出（708/708） |
| [VERIFY-042-m2-n3-mood-readout.md](reports/VERIFY-042-m2-n3-mood-readout.md) | VERIFY-042 · M2 / N3：心情读得出来（710/710） |
| [VERIFY-043-m2-n4-investigation.md](reports/VERIFY-043-m2-n4-investigation.md) | VERIFY-043 · M2 / N4 前置调查：`rules-first` 只能靠 L3（无代码改动） |
| [VERIFY-044-m2-n5-needs-explanation.md](reports/VERIFY-044-m2-n5-needs-explanation.md) | VERIFY-044 · M2 / N5：说清"他为什么在休息时段还动着"（712/712） |
| [VERIFY-045-ci-gates.md](reports/VERIFY-045-ci-gates.md) | VERIFY-045 · 队列 ⑦：CI 门禁 P0+P1 落地（并修掉一条真缺陷） |
| [VERIFY-046-m2-n6-mood-card.md](reports/VERIFY-046-m2-n6-mood-card.md) | VERIFY-046 · M2 / N6：居民卡上看得见心情（714/714） |
| [VERIFY-047-veto-rename.md](reports/VERIFY-047-veto-rename.md) | VERIFY-047 · D16 关闭：`Standing → Veto` 改名，并让门禁抓到了一条真回归 |
| [VERIFY-048-dedicated-server.md](reports/VERIFY-048-dedicated-server.md) | VERIFY-048 · 十模块**打包后的 jar** 能在真实专用服务端启动 |
| [VERIFY-049-m2-r1-book.md](reports/VERIFY-049-m2-r1-book.md) | VERIFY-049 · M2-R1 第一段：关系簿（1472/1472） |

---

## 3. 关键决策（ADR，摘自 [00-charter.md](00-charter.md)）

| 编号 | 主题 |
| --- | --- |
| ADR-001 | ~~整合包 + 自研插件路线，不 fork~~ → 已被 ADR-007 取代（已废弃） |
| ADR-002 | 锁定 NeoForge 1.21.1 + Folkways |
| ADR-003 | 主题定为「拾石而上，直至星辰」的纵向进程 |
| ADR-004 | 四个自由度方向全部保留（微观管理/建造工程/叙事/世界规则） |
| ADR-005 | 第一里程碑为「单人/小服 30+ 小时核心循环」 |
| ADR-006 | 文档体系照搬「文档驱动 AI 工作流」的六阶段方法 |
| ADR-007 | 直接 fork Folkways 本体并改造，保留上游同步能力与 MIT 声明 |
| ADR-008 | 微观控制到 A-max，但不推翻规划器（约束注入） |
| ADR-009 | 需求做全部 7 条（饥饿/休息/温暖/安全/社交/美感/意义） |
| ADR-010 | 季节/温度/口渴作为规划器可读的世界数据层 |
| ADR-011 | 终局「星辰」= 多方块火箭 + 可居住空间站 |
| ADR-012 | 术语统一：殖民地 / 殖民书（废弃「聚落」） |
| ADR-013 | 新增环境/经济系统必须驱动居民本身，不做玩家侧状态 |
| ADR-014 | 衰老三层可配，不写死 |
| ADR-015 | 医疗与手术自研；器官摘取带道德代价 |
| ADR-016 | 气体/污染/资源循环自研（分区池 + 格级梯度，不做逐格仿真） |
| ADR-017 | 基线：modid=plaa、代码 MIT、内容层 KubeJS |
| ADR-018 | 整合包与发布基线：FTB Quests 进包作可选引导 |
| ADR-019 | 厕所联动 PoopSkyMod 等四件事的形态 |
| ADR-020 | 构建与测试平台的事实基线（mods.json 是生成的） |
| ADR-021 | M1 开工基线：fork 基线前移 |
| ADR-022 | Linux 侧构建与过渡期整合包 |
| ADR-023 | 四 modid 与 M1 构建口径（plaa_core 等 4 个） |
| ADR-024 | r10 设计级影响 17 条裁决 |
| ADR-025 | 基线前移与远端（GitHub 仓库） |
| ADR-026 | **十模块与 modid 全量改名**（2026-11-05，当前口径） |

---

## 4. 债务清单（摘自 [ROADMAP.md](ROADMAP.md)）

| 编号 | 现状 | 何时处理 |
| --- | --- | --- |
| D1 | 任务书第一章已上线；**第二章草案已写**（11 任务，SNBT 已校验），待进包并进游戏验证 | `pack/` 更新后 |
| D2 | ✅ jar 随包分发 → 已改为 release URL | 已完成 |
| D3 | ✅ 「264 回归」结论已推翻，构建统一 264 | 已完成 |
| D4 | `pack/resourcepacks/` 为空 | 有需要时再评估 |
| D5 | 客户端只有一次实测记录（2026-10-20） | 每次发版前重跑 |
| D6 | ✅ 无 CI → P0+P1 落地 | 已完成 |
| D7 | ✅ 偶发测试按名单重试一次 | 已完成 |
| D8 | ✅ 拒绝会说明「是谁拒绝的」 | 已完成 |
| D9 | 缺殖民地测试夹具（需求类原因无法端到端测） | M2 内 |
| D10 | 只对 5 类原因说话，其余 9 类故意沉默 | 补证后逐条放行 |
| D11 | 人工验收：存档跨进程重启 + 客户端演示脚本（19 点） | 发版前，需要你的屏幕 |
| D12 | ✅ `rules-first` 决定不做（保持需求优先 + 解释） | 已关闭 |
| D13 | CI P2（缺可选依赖矩阵）未做 | Blockwright profile 语义确认后 |
| D14 | CI P3（文档登记/断链门禁）未接 | docs 仓库可跑 Actions 时 |
| D15 | 上游重写历史；移植已完成（代码侧），**只剩客户端实测** | 实测后决定如何落到 main |
| D16 | ✅ `Standing` 撞词 → 改名 `Veto`/`Vetoes` | 已完成 |
| D17 | 10 模块 + `plaa_*` 改名要覆盖四类引用；漏一类静默失效 | 每次同步后复查 |

---

## 5. 当前进度（截至 2026-11-05）

| 里程碑 | 状态 |
| --- | --- |
| M0 文档 | ✅ 章程/设计/PRD/规格/工作流齐全，断链 0 |
| M1 可玩骨架 | 🟡 禁限区 / 作息 / 解释层 / CI 门禁 ✅；演示人工验收待做 |
| M2 张力 | 🟡 需求与情绪 N1–N6 ✅；关系 R1-1 ✅；医疗与威胁未开工 |
| M3 进程 | ⬜ 未开始（设计文档 [d13](design/13-gases-pollution-and-cycles.md)/[d15](design/15-power-and-mechanical-residents.md) 已写） |
| M4 故事与太空 | ⬜ 未开始（[PRD-011](prd/PRD-011-progression-knowledge-and-space.md) 已写） |
| v1.0 发布 | ⬜ 未开始 |

### 5.1 移植（D15）现状

| 项 | 结果 | 证据 |
| --- | --- | --- |
| 上游历史被重写，无共同祖先 | 确认 | [SYNC-002](reports/SYNC-002-upstream-precheck.md) |
| 移植到 `aaac8b8` | 48 新增 / 24 干净 / 12 冲突逐个解 | [SYNC-003](reports/SYNC-003-port-phase1.md) · [SYNC-004](reports/SYNC-004-port-compiles.md) · [SYNC-005](reports/SYNC-005-port-tests-run.md) |
| 十模块 + 全套 `plaa_*` | 10 个 jar 构建成功 | [SYNC-006](reports/SYNC-006-ten-modules.md) |
| 游戏测试 | **1472 / 1472** | [SYNC-007](reports/SYNC-007-port-green.md) |
| 打包 jar 在真实服务端 | `Done (4.511s)`、0 FATAL、10 modid 全注册 | [VERIFY-048](reports/VERIFY-048-dedicated-server.md) |
| 客户端 | ⬜ **未实测**（测试包已备好） | [SYNC-008](reports/SYNC-008-test-package.md) |

---

## 6. 下一步（按顺序）

1. **你在客户端跑一次测试包**（Prism 导入 `.mrpack`）→ 决定 `main` 如何落到移植分支；
2. `pack/` 改成 10 模块口径（换 jar + 补 7 个 `.pw.toml`，规格见 [pack §12](pack/00-pack-spec.md)）；
3. 重打 `.mrpack` → 发 v0.2.0；
4. 回 M2：R1-2 采样器 → R1-3 士气 → R1-4 卡片 → R1-5 解释（[PLAN-007](plans/PLAN-007-m2-r1-companions.md)）；
5. 任务书第二章进包并进游戏验证（[草案](pack/drafts/plaa_chapter_2.snbt)）。

---

## 7. 建议阅读路线

| 你是谁 | 先读 |
| --- | --- |
| 第一次接触 | 本文件 → [章程](00-charter.md) → [愿景与支柱](design/01-vision-and-pillars.md) → [术语表](design/03-glossary.md) |
| 想玩 | [演示脚本](demo/M1-demo-script.md) → [整合包规格](pack/00-pack-spec.md) |
| 想改代码 | [fork 策略](design/12-fork-strategy.md) → [构建与 CI](workflow/06-build-and-ci.md) → [测试与验收](workflow/03-test-and-acceptance.md) |
| 想加内容 | [内容作者手册](pack/05-content-author-handbook.md) → [事件模板](pack/06-incident-templates.md) → [任务书](pack/04-quest-book-and-guidance.md) |
| 想接手 | 本文件 → [ROADMAP](ROADMAP.md) → 最近 10 份 [reports](reports/) |

---

## 8. 统计

| 项 | 数 |
| --- | --- |
| Markdown 文档 | **129** |
| 总行数 | **25719** |
| 设计文档 | 16 |
| PRD | 16 |
| 计划 | 9 |
| 证据报告 | 57 |
| 调研 | 10 |
| 工作流 | 9 |
| 整合包 | 7 |

---

**本文件是汇总，不是权威来源。** 与原文冲突时，以原文为准；改口径请改原文并在此同步一行说明。
