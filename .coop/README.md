# .coop —— 多模型协作总线

> 这个目录是 **agent 之间唯一的交接面**（依据 `docs/workflow/01-agent-roles-and-tools.md` 的 R-ROLE-2/3：对话里说过但没写进文件的决策，视为不存在）。
> 不写代码、不是文档正文、不进 `docs/README.md` 的登记表——它是**运行时的工作台**。

## 为什么是"文件总线"而不是"让模型互相聊天"

| 方案 | 问题 |
| --- | --- |
| 两个模型直接对话 | 上下文互相污染；一方压缩后另一方还在引用旧事实；无法审计 |
| 一个模型调另一个的 API | 需要共享密钥、有成本失控风险、失败无痕 |
| **文件总线（本方案）** | 可审计、可重放、可并行、任何模型都能参与（包括只能人工粘贴的桌面端） |

## 目录

```
.coop/
  README.md            ← 你在这里
  ledger.md            ← 只追加的状态流水（谁、何时、把哪张卡从什么状态改到什么）
  tasks/T-0001.md      ← 任务卡（YAML front-matter + 正文）
  reports/T-0001.md    ← 交付报告（六段式：结论/依据/取舍/风险/待决/不确定）
  reviews/T-0001.md    ← 交叉评审（由"另一个模型"写）
  locks/T-0001.lock    ← 认领锁（含 owner + 到期时间，防两个 agent 同时干）
  templates/task.md    ← 任务卡模板
  templates/report.md  ← 报告模板
```

## 与既有 handoff 约定的关系（重要）

项目里已经有**正式的交接物**（`docs/workflow/01-agent-roles-and-tools.md` 的 R-ROLE-2）：

| 层 | 载体 | 生命周期 | 谁写 |
| --- | --- | --- | --- |
| **运行时调度** | `.coop/tasks/T-*.md` + `reports/` + `reviews/` | 短（一张卡几小时～几天），可丢弃 | 编排者派、裁决者填 |
| **正式交接** | `docs/plans/PLAN-NNN-*.md` + `docs/reports/VERIFY-NNN-*.md` | 长（进版本库，可审计） | 规划者 / 验证者 |

**R-COOP-5**：`.coop` 里被采纳的结论**必须**沉淀成 `docs/plans` 或直接改进 `docs/prd|design|workflow`——**`.coop` 不是档案库**。卡片 front-matter 的 `plan:` / `verify:` 字段就是这两层的挂钩（例：`plan: docs/plans/PLAN-001-b2-modid-rename.md`）。

## 两棵树：Windows 仓库 vs WSL 工作树

按 ADR-022/025，**代码构建与游戏测试在 WSL**（`~/pla/mod`，Windows 侧可经 `\\wsl.localhost\Ubuntu-24.04\home\tcch1111\pla\mod\` 访问）；**文档与总线在 Windows 仓库**（就是这里）。

| 任务类型 | `tree:` 字段 | 谁在哪个树里动 |
| --- | --- | --- |
| 裁决 / 写文档 / 评审 | `windows` | 只碰 `docs/` 与 `.coop/` |
| 改代码 / 跑 build / 跑 gametest | `wsl` | 只碰 `~/pla/mod`；结论写回 `.coop/reports/`（Windows 侧路径） |
| 两边都要 | 拆成两张卡 | **禁止**一张卡横跨两棵树（冲突时无法判定谁赢） |

`reference/folkways-3ce4d88/` 是**只读快照**（核对行号用），任何 agent 都不许改。

## 三条铁律

**R-COOP-1（单写者）**：同一时刻一张卡只能有一个 owner。认领必须写 `locks/`，带**到期时间**；过期锁可被后来者抢占（并记入 ledger）。
**R-COOP-2（写者≠评审者）**：`reports/T-xxxx.md` 的作者**不能**写对应的 `reviews/T-xxxx.md`；评审必须换一个模型/会话（对应 R-ROLE-1）。
**R-COOP-3（证据优先）**：报告里每条结论必须跟 `文件:行号` 或文档链接；没有证据的结论按"未验证"处理，不得进入下游。

## 角色与模型路由

| 角色 | 建议模型 | 干什么 |
| --- | --- | --- |
| 编排者（Orchestrator） | 便宜/本地（DSH 主会话） | 拆卡、派卡、合并、跑校验脚本、登记文档 |
| 裁决者（Judge） | 贵模型（ZCode/GLM 或指定型号） | `docs/workflow/07-model-routing-and-escalation.md` §1 的 10 条刀刃任务 |
| 交叉评审（Reviewer） | 与作者**不同**的模型 | 只找茬：事实错误、越界改动、漏掉的风险 |
| 执行者（Implementer） | 便宜模型 | 按报告改文档/代码，只做机械改动 |

## 一张卡的完整生命周期

```
open ──claim──▶ claimed ──report──▶ reported ──review──▶ reviewed ──accept──▶ done
                    │                                        │
                    └────────── release（放弃/超时）◀─────────┘
```

用 `tools/coop.ps1` 操作（见 `tools/coop.ps1 -Help`），不要手改状态字段——手改不写 ledger，事后无法审计。

## 与其它文档的关系

- 任务从哪来：[w05 M1 拆解](../docs/workflow/05-m1-task-breakdown.md) 的 WP/任务、[w07 刀刃清单](../docs/workflow/07-model-routing-and-escalation.md) §1。
- 卡里怎么写"证据包"：[w07](../docs/workflow/07-model-routing-and-escalation.md) §3 的四段式。
- 报告/评审的格式：`templates/`。
- 协作机制本身的设计说明：[docs/workflow/08-multi-agent-collaboration.md](../docs/workflow/08-multi-agent-collaboration.md)。
