# 汇总：Per Lapidem ad Astra（一页看完）

> 这是**唯一**把项目现状汇总到一个文件里的文档。
> 前半是判断，后半（§2/§3/§4/§8）由 `tools/summarize.py` 从源文件生成，不会与源文件脱节。
> 最后更新：2026-11-06

---

## 1. 项目一句话

> 一个以 **Folkways**（MIT，`IzakyL/folkways`）为基底、面向 **Minecraft 1.21.1 / NeoForge** 的殖民地模拟模组整合包：
> 玩家不是直接操作每个方块，而是给居民**制定规则、划区域、排序任务**，让他们自己把殖民地运转起来——
> 目标是"矮人要塞 / 环世界 / 石炉 / 希克斯之歌"的**人与故事感**，加上 Minecraft 的**建造自由度**。

### 现在的状态

| 维度 | 现状 |
| --- | --- |
| 代码分支 | `main` = `3234812`（十模块，全部 `plaa_*`） |
| 测试 | 本地 **1482** 游戏测试 全绿；unit **140/140** |
| CI | fork **Build #49**：11 个作业全绿；docs 仓库**四道门禁**全绿 |
| 发布物 | **[v0.2.1](https://github.com/TCCH1111/per-lapidem-ad-astra/releases/tag/v0.2.1)**：10 jar + `.mrpack`（62 下载条目） |
| 里程碑 | M0 ✅ · M1 ✅（WP-0/1/4/5/6/8 + CI）· M2 🟡（情绪 N1–N6 ✅、关系切片 R1 ✅） |
| 最大缺口 | **D11：没有任何人真正装过这个整合包并进世界** |


## 2. 文档地图（自动生成；改动后重跑 `tools/summarize.py`）

### 根目录

| 文件 | 标题 | 行数 |
| --- | --- | --- |
| [00-charter.md](00-charter.md) | 项目章程 · Per Lapidem ad Astra | 155 |
| [README.md](README.md) | 文档地图 · Per Lapidem ad Astra | 256 |
| [ROADMAP.md](ROADMAP.md) | 长期目标与路线（ROADMAP） | 122 |

### prd/

| 文件 | 标题 | 行数 |
| --- | --- | --- |
| [00-prd-template.md](prd/00-prd-template.md) | PRD-NNN · <系统名称> | 397 |
| [PRD-001-needs-mood-memory.md](prd/PRD-001-needs-mood-memory.md) | PRD-001 · 需求、情绪与记忆 | 1131 |
| [PRD-002-incidents-and-narrator.md](prd/PRD-002-incidents-and-narrator.md) | PRD-002 · 事件与叙述者 | 587 |
| [PRD-003-season-temperature-thirst-nutrition.md](prd/PRD-003-season-temperature-thirst-nutrition.md) | PRD-003 · 季节、温度、口渴与营养 | 848 |
| [PRD-004-threats-and-defence.md](prd/PRD-004-threats-and-defence.md) | PRD-004 · 威胁、袭击与防卫 | 660 |
| [PRD-005-intent-and-micro-control.md](prd/PRD-005-intent-and-micro-control.md) | PRD-005 · 意图与微观控制（调度层） | 693 |
| [PRD-006-stock-rules-and-diagnosis.md](prd/PRD-006-stock-rules-and-diagnosis.md) | PRD-006 · 仓储规则与因果诊断 | 677 |
| [PRD-007-scenarios.md](prd/PRD-007-scenarios.md) | PRD-007 · 剧本（开局与规则覆盖） | 769 |
| [PRD-008-relationships-and-social.md](prd/PRD-008-relationships-and-social.md) | PRD-008 · 关系与社交 | 911 |
| [PRD-009-generations-and-legacy.md](prd/PRD-009-generations-and-legacy.md) | PRD-009 · 世代与传承 | 1062 |
| [PRD-010-diplomacy-and-trade.md](prd/PRD-010-diplomacy-and-trade.md) | PRD-010 · 外交与贸易 | 868 |
| [PRD-011-progression-knowledge-and-space.md](prd/PRD-011-progression-knowledge-and-space.md) | PRD-011 · 时代进程、知识与太空计划 | 690 |
| [PRD-012-multiplayer-and-permissions.md](prd/PRD-012-multiplayer-and-permissions.md) | PRD-012 · 多人协作与权限 | 793 |
| [PRD-013-medical-and-surgery.md](prd/PRD-013-medical-and-surgery.md) | PRD-013 · 医疗、伤病与手术 | 907 |
| [PRD-014-atmosphere-and-pollution.md](prd/PRD-014-atmosphere-and-pollution.md) | PRD-014 · 气体、污染与资源循环 | 835 |
| [PRD-015-captivity-and-prisoners.md](prd/PRD-015-captivity-and-prisoners.md) | PRD-015 · 关押、人质、劳役与处置 | 763 |

### design/

| 文件 | 标题 | 行数 |
| --- | --- | --- |
| [01-vision-and-pillars.md](design/01-vision-and-pillars.md) | 愿景与设计支柱 | 194 |
| [02-benchmark.md](design/02-benchmark.md) | 对标分析：我们借什么、弃什么 | 217 |
| [03-glossary.md](design/03-glossary.md) | 全局术语表 | 232 |
| [04-world-and-simulation.md](design/04-world-and-simulation.md) | 世界与模拟总纲 | 220 |
| [05-settlement-and-residents.md](design/05-settlement-and-residents.md) | 殖民地与居民 | 296 |
| [06-economy-and-logistics.md](design/06-economy-and-logistics.md) | 经济与物流 | 216 |
| [07-threats-and-narrative.md](design/07-threats-and-narrative.md) | 威胁、防卫与故事生成 | 274 |
| [08-progression-and-ages.md](design/08-progression-and-ages.md) | 时代进程（Per Lapidem ad Astra） | 188 |
| [09-interaction-and-ui.md](design/09-interaction-and-ui.md) | 交互层与信息呈现 | 188 |
| [10-multiplayer-and-server.md](design/10-multiplayer-and-server.md) | 多人、权限与性能 | 158 |
| [11-freedom-design.md](design/11-freedom-design.md) | 自由度设计纲领 | 251 |
| [12-fork-strategy.md](design/12-fork-strategy.md) | Folkways fork 策略 | 336 |
| [13-gases-pollution-and-cycles.md](design/13-gases-pollution-and-cycles.md) | 气体、污染与资源循环 | 578 |
| [14-saves-backups-and-migration.md](design/14-saves-backups-and-migration.md) | d14 存档、备份与迁移 | 450 |
| [15-power-and-mechanical-residents.md](design/15-power-and-mechanical-residents.md) | 能源、动力适配层与机械族（Per Lapidem ad Astra） | 526 |
| [16-diagnosis-ui-prototype.md](design/16-diagnosis-ui-prototype.md) | 16 · 诊断界面的文字线框原型 | 749 |
| [17-gas-seam.md](design/17-gas-seam.md) | 17 · 气体接口预埋（M3 的接缝，不是气体系统） | 133 |
| [18-power-seam.md](design/18-power-seam.md) | 18 · 能源与机械族的接缝（M3 的预埋） | 112 |
| [19-captivity-seam.md](design/19-captivity-seam.md) | 19 · 关押的接缝（M3 的预埋） | 119 |

### pack/

| 文件 | 标题 | 行数 |
| --- | --- | --- |
| [00-pack-spec.md](pack/00-pack-spec.md) | 整合包规格 | 252 |
| [01-modlist.md](pack/01-modlist.md) | 01 · Mod 清单：1.21.1 + NeoForge 可用性核实 | 402 |
| [02-config-and-datapack.md](pack/02-config-and-datapack.md) | 配置、数据包与脚本内容规划 | 242 |
| [03-performance-budget.md](pack/03-performance-budget.md) | 性能预算 | 150 |
| [04-quest-book-and-guidance.md](pack/04-quest-book-and-guidance.md) | 04 · 任务书与剧情引导（FTB Quests） | 617 |
| [05-content-author-handbook.md](pack/05-content-author-handbook.md) | 内容作者手册 | 650 |
| [06-incident-templates.md](pack/06-incident-templates.md) | 首批事件模板清单（40 条） | 739 |

### plans/

| 文件 | 标题 | 行数 |
| --- | --- | --- |
| [PLAN-001-b2-modid-rename.md](plans/PLAN-001-b2-modid-rename.md) | PLAN-001 · B-2：把 fork 的四个 modid 改为 `plaa_*`（含 NOTICE 与冲突声明） | 251 |
| [PLAN-002-inventory.md](plans/PLAN-002-inventory.md) | PLAN-002 附录 · T1 盘点：五个包私有类型的取得路径 | 79 |
| [PLAN-002-wp1-engine-readable-surface.md](plans/PLAN-002-wp1-engine-readable-surface.md) | PLAN-002 · M1-WP1：引擎可读面（把诊断需要的数据提升为公开只读） | 122 |
| [PLAN-003-a-t4-standing.md](plans/PLAN-003-a-t4-standing.md) | PLAN-003 附录 A · T4 落点与 L3 变更提案（`Fitness` 单点否决） | 111 |
| [PLAN-003-wp4-steering-zones.md](plans/PLAN-003-wp4-steering-zones.md) | PLAN-003 · M1-WP4：禁限区（谁能去哪） | 132 |
| [PLAN-004-wp5-hours.md](plans/PLAN-004-wp5-hours.md) | PLAN-004 · M1-WP5：作息表（什么时候干活） | 128 |
| [PLAN-005-wp6-explanation.md](plans/PLAN-005-wp6-explanation.md) | PLAN-005 · M1-WP6：解释层（说得出为什么） | 96 |
| [PLAN-006-m2-needs-mood.md](plans/PLAN-006-m2-needs-mood.md) | PLAN-006 · M2-WP7：需求与情绪（张力的第一层） | 107 |
| [PLAN-007-m2-r1-companions.md](plans/PLAN-007-m2-r1-companions.md) | PLAN-007 · M2-R1：同行伙伴（关系系统的第一刀） | 119 |
| [PLAN-008-m2-r2-friction.md](plans/PLAN-008-m2-r2-friction.md) | PLAN-008 · M2-R2：摩擦（关系第二刀） | 96 |
| [PLAN-009-m2-medical-r0.md](plans/PLAN-009-m2-medical-r0.md) | PLAN-009 · M2 医疗第一刀（R0：伤口、流血、看得见） | 106 |

### reports/

| 文件 | 标题 | 行数 |
| --- | --- | --- |
| [SYNC-001-upstream-drill.md](reports/SYNC-001-upstream-drill.md) | SYNC-001 · 上游同步演练 #1（本地模拟，无网络） | 85 |
| [SYNC-002-upstream-precheck.md](reports/SYNC-002-upstream-precheck.md) | SYNC-002 · 上游同步预检 #2：历史已被重写，不能用 merge | 122 |
| [SYNC-003-port-phase1.md](reports/SYNC-003-port-phase1.md) | SYNC-003 · 移植第一阶段：改动已落到 aaac8b8，剩 8 个冲突 | 99 |
| [SYNC-004-port-compiles.md](reports/SYNC-004-port-compiles.md) | SYNC-004 · 移植第二阶段：配置全部解开，**主源码编译通过** | 82 |
| [SYNC-005-port-tests-run.md](reports/SYNC-005-port-tests-run.md) | SYNC-005 · 移植第三阶段：测试跑起来了（1402 / 1404） | 70 |
| [SYNC-006-ten-modules.md](reports/SYNC-006-ten-modules.md) | SYNC-006 · 移植第四阶段：**十个模块、全套 plaa_* 跑起来了**（1465 / 1467） | 93 |
| [SYNC-007-port-green.md](reports/SYNC-007-port-green.md) | SYNC-007 · 移植收尾：**1467 / 1467 全绿**，根因是 69 处硬编码 modid | 100 |
| [SYNC-008-test-package.md](reports/SYNC-008-test-package.md) | SYNC-008 · 移植版测试包（48 个文件 / 10 个 `plaa_*` + 38 个依赖） | 95 |
| [SYNC-009-main-switch.md](reports/SYNC-009-main-switch.md) | SYNC-009 · 移植落到 `main`（用户决定：跳过客户端实测） | 88 |
| [SYNC-010-release-020.md](reports/SYNC-010-release-020.md) | SYNC-010 · v0.2.0 发布 + 整合包改成十模块 | 70 |
| [SYNC-011-mrpack-verified.md](reports/SYNC-011-mrpack-verified.md) | SYNC-011 · 发布包整体校验：62 个下载全部可达且哈希匹配 | 67 |
| [SYNC-012-pack-audit.md](reports/SYNC-012-pack-audit.md) | SYNC-012 · 整合包内容审计：桥接配方有效，配置已过时（已刷新） | 86 |
| [SYNC-013-pack-lint.md](reports/SYNC-013-pack-lint.md) | SYNC-013 · `pack-lint`：把重复劳动变成检查 | 104 |
| [SYNC-014-docs-ci.md](reports/SYNC-014-docs-ci.md) | SYNC-014 · docs 仓库接上 CI，四次运行才变绿 | 129 |
| [SYNC-015-fork-ci-fix.md](reports/SYNC-015-fork-ci-fix.md) | SYNC-015 · fork 的 CI 一直是红的，原因是被漏掉的第五个改名面 | 114 |
| [SYNC-016-release-021.md](reports/SYNC-016-release-021.md) | SYNC-016 · v0.2.1：把带缺陷的 v0.2.0 替换掉 | 74 |
| [SYNC-017-summary-generator.md](reports/SYNC-017-summary-generator.md) | SYNC-017 · SUMMARY-ALL 改成可重新生成 | 76 |
| [SYNC-018-pack-deps-021.md](reports/SYNC-018-pack-deps-021.md) | SYNC-018 · v0.2.1 分发校验 + 依赖完整性 | 85 |
| [SYNC-019-chapter-2-shipped.md](reports/SYNC-019-chapter-2-shipped.md) | SYNC-019 · 任务书第二章进包，v0.2.2 只更新整合包 | 67 |
| [SYNC-020-pack-spec-audit.md](reports/SYNC-020-pack-spec-audit.md) | SYNC-020 · pack 规格 vs 实际：三处过期、一处措辞错 | 69 |
| [SYNC-021-namespace-gate.md](reports/SYNC-021-namespace-gate.md) | SYNC-021 · 把"数据命名空间"事故变成回归门禁（unit 142/142） | 90 |
| [VERIFY-001-b2.md](reports/VERIFY-001-b2.md) | VERIFY-001 · B-2（modid 改为 `plaa_*` + 与上游互斥声明） | 60 |
| [VERIFY-002-pack-ours.md](reports/VERIFY-002-pack-ours.md) | VERIFY-002 · 整合包改用我们的 jar（`plaa_*` 替换上游 `folkways_*`） | 71 |
| [VERIFY-003-mrpack.md](reports/VERIFY-003-mrpack.md) | VERIFY-003 · 可分发产物 `.mrpack` 生成与结构校验 | 84 |
| [VERIFY-004-pack-install-e2e.md](reports/VERIFY-004-pack-install-e2e.md) | VERIFY-004 · 分发链端到端（全新实例 → packwiz-installer 装包 → 服务端到 Done） | 70 |
| [VERIFY-005-pack-content-1.md](reports/VERIFY-005-pack-content-1.md) | VERIFY-005 · 包内容第一批（我们的配置 + FTB 三件套）与端到端复验 | 75 |
| [VERIFY-006-client-test.md](reports/VERIFY-006-client-test.md) | VERIFY-006 · 客户端实测（Prism CLI + 我们自己的实例） | 78 |
| [VERIFY-007-missing-models.md](reports/VERIFY-007-missing-models.md) | VERIFY-007 · 41 条缺模型告警的根因定位与修复尝试 | 64 |
| [VERIFY-008-kubejs-content.md](reports/VERIFY-008-kubejs-content.md) | VERIFY-008 · 包内 KubeJS 内容管线（并修复 mrpack 打包器漏带 overrides 的 bug） | 67 |
| [VERIFY-009-quest-chapter-1.md](reports/VERIFY-009-quest-chapter-1.md) | VERIFY-009 · 任务书第一章（FTB Quests 数据手写并验证零解析错误） | 82 |
| [VERIFY-010-neoforge-264-upgrade.md](reports/VERIFY-010-neoforge-264-upgrade.md) | VERIFY-010 · NeoForge 21.1.264 升级尝试（A/B 证明回归，暂缓） | 148 |
| [VERIFY-011-release-v0-1-0.md](reports/VERIFY-011-release-v0-1-0.md) | VERIFY-011 · GitHub Release v0.1.0 与包内 jar 改为 release URL | 78 |
| [VERIFY-012-wp1-t3-body-views.md](reports/VERIFY-012-wp1-t3-body-views.md) | VERIFY-012 · WP-1 / T3：`BodyViews` 只读门面（653/653 通过） | 85 |
| [VERIFY-013-wp1-t2-presence-views.md](reports/VERIFY-013-wp1-t2-presence-views.md) | VERIFY-013 · WP-1 / T2：`PresenceViews`（饥饿与床位只读视图，655/655 通过） | 83 |
| [VERIFY-014-wp1-t5-t6-wp1-closed.md](reports/VERIFY-014-wp1-t5-t6-wp1-closed.md) | VERIFY-014 · WP-1 收口：T5 退避视图 + T6 变更登记（657/657） | 89 |
| [VERIFY-015-wp4-t1-t2-steering-skeleton.md](reports/VERIFY-015-wp4-t1-t2-steering-skeleton.md) | VERIFY-015 · WP-4 / T1–T2：禁限区骨架与区域判定（662/662） | 80 |
| [VERIFY-016-wp4-t4a-standing.md](reports/VERIFY-016-wp4-t4a-standing.md) | VERIFY-016 · WP-4 / T4a：`Standing` 否决管道（L3，默认零行为变化） | 72 |
| [VERIFY-017-wp4-t4b-wiring.md](reports/VERIFY-017-wp4-t4b-wiring.md) | VERIFY-017 · WP-4 / T4b：区域 → 引擎的接线（665/665） | 78 |
| [VERIFY-018-wp4-t5-refusals.md](reports/VERIFY-018-wp4-t5-refusals.md) | VERIFY-018 · WP-4 / T5：`SteeringRefusal` 与四语文案（668/668） | 59 |
| [VERIFY-019-wp4-t6-steering-page.md](reports/VERIFY-019-wp4-t6-steering-page.md) | VERIFY-019 · WP-4 / T6：禁限区页面（列表 + 删除） | 65 |
| [VERIFY-020-wp4-t6b-painted-zones.md](reports/VERIFY-020-wp4-t6b-painted-zones.md) | VERIFY-020 · WP-4 / T6b：画出的体积变成禁入区（671/671） | 73 |
| [VERIFY-021-wp4-closed.md](reports/VERIFY-021-wp4-closed.md) | VERIFY-021 · WP-4 收口：T7 同源文案（673/673） | 77 |
| [VERIFY-022-wp5-hours-t1.md](reports/VERIFY-022-wp5-hours-t1.md) | VERIFY-022 · WP-5 / T0–T1：作息表（共享派活闸，679/679） | 85 |
| [VERIFY-023-wp5-t5-refusal-defect.md](reports/VERIFY-023-wp5-t5-refusal-defect.md) | VERIFY-023 · WP-5 / T5：作息的具名理由（681/681）＋一个被发现的真实缺陷 | 63 |
| [VERIFY-024-d8-fixed.md](reports/VERIFY-024-d8-fixed.md) | VERIFY-024 · WP-5 / D8 修复：拒绝会说明"是谁拒绝的"（684/684） | 86 |
| [VERIFY-025-wp5-t4-page.md](reports/VERIFY-025-wp5-t4-page.md) | VERIFY-025 · WP-5 / T4：作息页面与两个开关（686/686） | 68 |
| [VERIFY-026-wp5-closed.md](reports/VERIFY-026-wp5-closed.md) | VERIFY-026 · WP-5 收口：T3 降级与债务登记 | 59 |
| [VERIFY-027-wp6-w1-w2.md](reports/VERIFY-027-wp6-w1-w2.md) | VERIFY-027 · WP-6 / W1–W2：一个地方把拒绝变成人话（689/689） | 79 |
| [VERIFY-028-wp6-w3.md](reports/VERIFY-028-wp6-w3.md) | VERIFY-028 · WP-6 / W3：没人接的活变成一行（692/692） | 55 |
| [VERIFY-029-wp6-w5-investigation.md](reports/VERIFY-029-wp6-w5-investigation.md) | VERIFY-029 · WP-6 / W5 调查：端到端测试缺口在哪 | 55 |
| [VERIFY-030-wp6-w5.md](reports/VERIFY-030-wp6-w5.md) | VERIFY-030 · WP-6 / W5：否决真的让人不接活（693/693） | 58 |
| [VERIFY-031-wp6-w6-coverage.md](reports/VERIFY-031-wp6-w6-coverage.md) | VERIFY-031 · WP-6 / W6：解释层覆盖率报告（14 类，证据分级） | 84 |
| [VERIFY-032-wp6-w7-negative.md](reports/VERIFY-032-wp6-w7-negative.md) | VERIFY-032 · WP-6 / W7 第一轮：两次尝试，两次空白（否定结果） | 52 |
| [VERIFY-033-wp6-w7-honesty-filter.md](reports/VERIFY-033-wp6-w7-honesty-filter.md) | VERIFY-033 · WP-6 / W7 第二轮：三次造不出来 → 改为"没证据的就不说" | 77 |
| [VERIFY-034-wp6-w7-production-map.md](reports/VERIFY-034-wp6-w7-production-map.md) | VERIFY-034 · WP-6 / W7 第三轮：每个原因到底由谁产出（生产代码地图） | 70 |
| [VERIFY-035-wp6-closed.md](reports/VERIFY-035-wp6-closed.md) | VERIFY-035 · WP-6 收口：W7 不再追（四次尝试的账） | 68 |
| [VERIFY-036-wp8-unload-safety.md](reports/VERIFY-036-wp8-unload-safety.md) | VERIFY-036 · WP-8 / 第一段：每殖民地一张作息表 + 可卸载（699/699） | 63 |
| [VERIFY-037-wp8-colony-store.md](reports/VERIFY-037-wp8-colony-store.md) | VERIFY-037 · WP-8 / 第二段：数据真的走了殖民地仓库（702/702） | 54 |
| [VERIFY-038-wp8-level-backed.md](reports/VERIFY-038-wp8-level-backed.md) | VERIFY-038 · WP-8 / 第三段：数据在"关卡拥有的殖民地"上（703/703） | 61 |
| [VERIFY-039-demo-script.md](reports/VERIFY-039-demo-script.md) | VERIFY-039 · 队列 ⑤：M1 演示脚本就绪（19 个观察点，**未跑通**） | 54 |
| [VERIFY-040-build-aligned-264.md](reports/VERIFY-040-build-aligned-264.md) | VERIFY-040 · 队列 ③ 收尾：构建统一到 264（结论被推翻并更正） | 70 |
| [VERIFY-041-m2-n1-n2-mood.md](reports/VERIFY-041-m2-n1-n2-mood.md) | VERIFY-041 · M2 / N1–N2：心情由需求推出（708/708） | 75 |
| [VERIFY-042-m2-n3-mood-readout.md](reports/VERIFY-042-m2-n3-mood-readout.md) | VERIFY-042 · M2 / N3：心情读得出来（710/710） | 62 |
| [VERIFY-043-m2-n4-investigation.md](reports/VERIFY-043-m2-n4-investigation.md) | VERIFY-043 · M2 / N4 前置调查：`rules-first` 只能靠 L3（无代码改动） | 58 |
| [VERIFY-044-m2-n5-needs-explanation.md](reports/VERIFY-044-m2-n5-needs-explanation.md) | VERIFY-044 · M2 / N5：说清"他为什么在休息时段还动着"（712/712） | 64 |
| [VERIFY-045-ci-gates.md](reports/VERIFY-045-ci-gates.md) | VERIFY-045 · 队列 ⑦：CI 门禁 P0+P1 落地（并修掉一条真缺陷） | 125 |
| [VERIFY-046-m2-n6-mood-card.md](reports/VERIFY-046-m2-n6-mood-card.md) | VERIFY-046 · M2 / N6：居民卡上看得见心情（714/714） | 64 |
| [VERIFY-047-veto-rename.md](reports/VERIFY-047-veto-rename.md) | VERIFY-047 · D16 关闭：`Standing → Veto` 改名，并让门禁抓到了一条真回归 | 118 |
| [VERIFY-048-dedicated-server.md](reports/VERIFY-048-dedicated-server.md) | VERIFY-048 · 十模块**打包后的 jar** 能在真实专用服务端启动 | 87 |
| [VERIFY-049-m2-r1-book.md](reports/VERIFY-049-m2-r1-book.md) | VERIFY-049 · M2-R1 第一段：关系簿（1472/1472） | 83 |
| [VERIFY-050-m2-r1-sampler.md](reports/VERIFY-050-m2-r1-sampler.md) | VERIFY-050 · M2-R1 第二段：采样器（1476/1476） | 74 |
| [VERIFY-051-m2-r1-morale.md](reports/VERIFY-051-m2-r1-morale.md) | VERIFY-051 · M2-R1 第三段：陪伴即有意义（1477/1477） | 71 |
| [VERIFY-052-m2-r1-card.md](reports/VERIFY-052-m2-r1-card.md) | VERIFY-052 · M2-R1 第四段：卡片上的一行（1479/1479） | 77 |
| [VERIFY-053-m2-r1-closed.md](reports/VERIFY-053-m2-r1-closed.md) | VERIFY-053 · M2-R1 收口：关系第一刀完整落地（1479/1479） | 83 |
| [VERIFY-054-d18-i18n-gate.md](reports/VERIFY-054-d18-i18n-gate.md) | VERIFY-054 · D18 关闭：i18n 枚举键门禁恢复（unit 140/140） | 84 |
| [VERIFY-055-m2-medical-data.md](reports/VERIFY-055-m2-medical-data.md) | VERIFY-055 · M2 医疗 R0-1/R0-2：伤口与流血（1485/1485） | 91 |
| [VERIFY-056-confine-kind.md](reports/VERIFY-056-confine-kind.md) | VERIFY-056 · M3 关押接缝落地：`Kind.CONFINE`（1488/1488） | 84 |
| [VERIFY-057-subject-veto-gap.md](reports/VERIFY-057-subject-veto-gap.md) | VERIFY-057 · 否定结果：`CONFINE` 拦不住派活（引擎的否决权认不出"谁"） | 116 |

### research/

| 文件 | 标题 | 行数 |
| --- | --- | --- |
| [01-core-engine.md](research/01-core-engine.md) | 01 · Folkways 核心引擎能力清单 | 167 |
| [02-plugin-inventory.md](research/02-plugin-inventory.md) | 基底：插件清单与玩家可见内容（r02） | 425 |
| [03-front-and-interaction.md](research/03-front-and-interaction.md) | 03 · Folkways 玩家交互层能力清单 | 204 |
| [04-content-and-modding.md](research/04-content-and-modding.md) | 04 · Folkways 内容创作与二次开发能力边界 | 218 |
| [05-engineering-and-tooling.md](research/05-engineering-and-tooling.md) | 基底：工程与测试基建（r05） | 343 |
| [06-gap-analysis.md](research/06-gap-analysis.md) | 差距分析：基底能给我们什么、我们必须自己造什么 | 155 |
| [07-mc-landscape.md](research/07-mc-landscape.md) | MC 生态调研：殖民地 / 居民 / 需求情绪 / 事件威胁（重点 1.21.1 NeoForge） | 215 |
| [08-temperature-thirst-integration.md](research/08-temperature-thirst-integration.md) | 08 · 季节 / 温度 / 口渴能否挂到 Folkways 居民身上 | 294 |
| [09-space-endgame.md](research/09-space-endgame.md) | 09 · 太空终局：多方块火箭 + 空间站的候选技术方案 | 181 |
| [10-upstream-delta-f42e3c1-67f28b0.md](research/10-upstream-delta-f42e3c1-67f28b0.md) | 上游差异：f42e3c1 → 67f28b0（整树重构的路径与行号迁移） | 1126 |

### workflow/

| 文件 | 标题 | 行数 |
| --- | --- | --- |
| [00-ai-workflow.md](workflow/00-ai-workflow.md) | 文档驱动的 AI 工作流（本项目定制版） | 263 |
| [01-agent-roles-and-tools.md](workflow/01-agent-roles-and-tools.md) | 角色分工与工具约定 | 126 |
| [02-doc-lifecycle.md](workflow/02-doc-lifecycle.md) | 文档生命周期 | 136 |
| [03-test-and-acceptance.md](workflow/03-test-and-acceptance.md) | 测试与验收策略 | 213 |
| [04-prompts.md](workflow/04-prompts.md) | 提示词模板库 | 258 |
| [05-m1-task-breakdown.md](workflow/05-m1-task-breakdown.md) | M1 可玩骨架 · 任务拆解与验收矩阵 | 660 |
| [06-build-and-ci.md](workflow/06-build-and-ci.md) | 构建环境、依赖与 CI 规格（w06） | 583 |
| [07-model-routing-and-escalation.md](workflow/07-model-routing-and-escalation.md) | 模型分级与升级协议（把钱花在刀刃上） | 170 |
| [08-multi-agent-collaboration.md](workflow/08-multi-agent-collaboration.md) | 多模型协作（DSH × ZCode/GLM × claude × codex） | 189 |

### demo/

| 文件 | 标题 | 行数 |
| --- | --- | --- |
| [M1-demo-script.md](demo/M1-demo-script.md) | M1 演示脚本 · Per Lapidem ad Astra | 110 |

## 3. 关键决策（自动摘取 [00-charter.md](00-charter.md)，共 26 条）

| 编号 | 决定（首句） |
| --- | --- |
| ADR-001 | ~~采用「整合包 + 自研插件」路线，不 fork Folkways 本体~~ → **已被 ADR-007 取代** |
| ADR-002 | 锁定 NeoForge 1.21.1 + Folkways |
| ADR-003 | 主题定为「拾石而上，直至星辰」的纵向进程 |
| ADR-004 | 四个自由度方向全部保留（微观管理/建造工程/叙事/世界规则） |
| ADR-005 | 第一里程碑为「单人/小服 30+ 小时核心循环」 |
| ADR-006 | 文档体系照搬「文档驱动 AI 工作流」的六阶段方法 |
| ADR-007 | **直接 fork Folkways 本体并改造**（不再只写插件）；保留上游同步能力与 MIT 声明 |
| ADR-008 | 微观控制做到 **A-max**（L1 策略 + L2 覆盖 + L3 深度控制），但**不推翻规划器**（仍为约束注入） |
| ADR-009 | 需求系统做**全部 7 条**（饥饿/休息/温暖/安全/社交/美感/意义），不做「先 3 条」裁剪 |
| ADR-010 | 季节/温度/口渴作为**可被规划器读取的世界数据层** |
| ADR-011 | 终局的「星辰」= **多方块火箭 + 可居住空间站**；架构已定 |
| ADR-012 | 术语统一 |
| ADR-013 | 一切新增环境/经济系统（营养、温度、口渴、季节）**必须驱动 Folkways 居民本身**，不允许只做玩家侧状态 |
| ADR-014 | **衰老三层可配，绝不写死** |
| ADR-015 | **医疗与手术自研**（分部位伤病 → 感染 → 手术 → 义体），**器官摘取要做，但必须带道德代价**（目击者记忆、关系恶化、外邦名声与贸易后果） |
| ADR-016 | **气体、污染与资源循环自研**，模型 = **分区池 + 格级梯度混合**（**不做** ONI 式逐格仿真 |
| ADR-017 | **项目基线一次定清** |
| ADR-018 | **整合包与发布基线（第二批）** |
| ADR-019 | **四件事的形态定了** |
| ADR-020 | **构建与测试平台的事实基线（2026-10-18 直读上游核实）** |
| ADR-021 | **M1 开工基线（四项，用户裁决）** |
| ADR-022 | **Linux 侧构建与过渡期整合包（用户裁决）** |
| ADR-023 | **四 modid 与 M1 构建口径（用户裁决）** |
| ADR-024 | **r10 设计级影响 17 条裁决（用户，依据 [draft-r10](research/drafts/draft-r10-design-impact-202 |
| ADR-025 | **基线前移与远端（用户）** |
| ADR-026 | **十模块与 modid 全量改名（用户裁决，2026-11-05）** |

## 4. 债务清单（自动摘取 [ROADMAP.md](ROADMAP.md)，共 20 条）

| 状态 | 债务 | 结清条件 / 说明 |
| --- | --- | --- |
| ⚠️ D1 | 任务书为空 → 第一、二章均已进包（第二章 12 任务，跨章 id/依赖校验通过，SYNC-019，v0.2.2）；只剩"进游戏验证"（并入 D11） | 游戏内加载并完成一次 |
| ✅ D2 | jar 随包分发 → 已改为 release URL（VERIFY-011） | ✅ |
| ✅ D3 | 264 升级被测试挡住 → 已推翻 | ✅ |
| ⚠️ D4 | `pack/resourcepacks/` 为空；之前证明"资源包改不了 mod 资源" | 有需要时再评估 KubeJS 虚拟包 |
| ⚠️ D5 | 客户端只有一次实测记录（2026-10-20） | 每次发版前重跑 |
| ✅ D6 | 无 CI → 已偿还 | ✅ |
| ✅ D7 | `onefoodcannotfeedhalfofapair` 偶发挡住"全绿" → 已偿还 | ✅ |
| ✅ D8 | Boolean `Standing` 把"非工作时段"误报成"禁限区" → 已修 | ✅ |
| ⚠️ D9 | 缺殖民地测试夹具 | 下一个测试基建轮（WP-6/W7 遗留；M2 内） |
| ⚠️ D10 | 只对 5 类原因说话，其余 9 类故意沉默 | 已知限制，保持开启（VERIFY-033/035）；补证后逐条放行 |
| ⚠️ D11 | 人工验收（已变大） | 因跳过实测切换（SYNC-009）而放大；**分发层已另验**（SYNC-011 |
| ✅ D12 | `rules-first`（需求让位于规则） → 决定不做（2026-11-05 由项目发起人拍板） | ✅ 关闭 |
| ⚠️ D13 | CI P2 未做 | Blockwright profile 覆盖语义确认后（w06 §4.2 P2） |
| ✅ D14 | CI 未接 → ✅ 关闭 | ✅ 完成 |
| ✅ D15 | 上游重写历史、只能逐文件移植 → 已完成并落到 main（10 模块；本地 1482 全绿；CI Build #49 十一作业全绿，SYNC-007/009/015）；旧历史存于标 | ✅ 完成（客户端待补） |
| ✅ D16 | `Standing` 与上游 "stand（站位）"撞词 → 已偿还 | ✅ |
| ⚠️ D17 | 模块 = 上游全部 10 个，modid 统一 `plaa_*`；改名要覆盖五个表面（gradle / mods.toml / Java 字符串字面量 / profile / `d | `data/` 已由 unit 门禁自动复查（SYNC-021）；Java 源码 |
| ✅ D18 | i18n 枚举键门禁未随移植过来 → 已偿还 | ✅ 关闭 |
| ⚠️ D19 | 包里现在有三条面粉链（Create→FD 桥接、Cookery 自带、FD 自带）；不冲突但配方重复 | 等你定是否把 Cookery 也桥进来（涉及该 mod 平衡） |
| ⚠️ D20 | 主体类区域在调度层是惰性的 | 选 A（教否决权认人，需性能测量）或 B（只做诊断） |

## 5. 当前进度

| 里程碑 | 状态 | 说明 |
| --- | --- | --- |
| **M0 基底** | ✅ | 上游端口、许可证、构建、CI、分发四件套 |
| **M1 可玩骨架** | ✅ | 禁限区（含配额/主体/解释）、作息表（默认关）、解释层、诊断 UI 原型、CI 门禁 |
| **M2 张力** | 🟡 进行中 | 情绪 N1–N6 ✅；关系切片 R1 ✅（R2 摩擦已立项，等怨气来源口径）；医疗仅有 PRD |
| **M3 进程** | ⬜ 未开工 | 气体/能源/关押三条**接缝已定**（[d17](design/17-gas-seam.md)/[d18](design/18-power-seam.md)/[d19](design/19-captivity-seam.md)），实现未写 |
| **M4 故事与太空** | ⬜ 未开工 | PRD 与设计已有，代码未动 |
| **v1.0** | ⬜ | 依赖 M2–M4 |

---

## 6. 下一步（按顺序）

1. **D11 客户端实测**：装 [v0.2.1 的 `.mrpack`](https://github.com/TCCH1111/per-lapidem-ad-astra/releases/tag/v0.2.1)，进世界、圈地、开殖民地——所有"能不能玩"的判断都卡在这一步。
2. **M2-R2 摩擦**：等一句口径确认（怨气从哪来：A 旁人在受罪 / B 抢同一个活 / C 随机），[PLAN-008](plans/PLAN-008-m2-r2-friction.md) 已写好。
3. **M2 医疗**：PRD-013 已有 754 行与 API 映射；需要先定"受伤是否影响排班"。
4. **M3 三条接缝落地**：气体 → 能源 → 关押（前两者复用否决权，第三条要加 `CONFINE` 语义）。
5. **D19**：包里三条面粉链是否合并（涉及 Cookery 平衡）。

---

## 7. 建议阅读路线

| 目的 | 读这几份 |
| --- | --- |
| 先知道这是什么 | 本文件 §1 → [README](README.md) → [00-charter.md](00-charter.md) |
| 判断"能不能玩" | [reports/VERIFY-053](reports/VERIFY-053-m2-r1-closed.md) → [reports/SYNC-016](reports/SYNC-016-release-021.md) |
| 想改代码 | [design/12-fork-strategy.md](design/12-fork-strategy.md)（五表面改名规则）→ [workflow/05-m1-task-breakdown.md](workflow/05-m1-task-breakdown.md) |
| 想加玩法 | 对应 PRD → [design/17](design/17-gas-seam.md)（接缝写法范例） |
| 想发版 | [pack/00-pack-spec.md](pack/00-pack-spec.md) → [reports/SYNC-010](reports/SYNC-010-release-020.md) |
| 想知道哪里还欠着 | §4 债务清单 |

---

## 8. 统计（自动计算）

| 项 | 值 |
| --- | --- |
| 文档总数 | **156** |
| 总行数 | **35735** |
| 证据报告 | **78** |
| 本次生成 | `tools/summarize.py` |

> 本文件由脚本生成；请勿手改，改脚本或改源文件后重跑。
