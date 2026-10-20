# 多模型协作（DSH × ZCode/GLM × claude × codex）

```
状态：草稿
负责人：项目发起人
最后更新：2026-10-20
上游依据：docs/workflow/01-agent-roles-and-tools.md（R-ROLE-1/2/3）、docs/workflow/07-model-routing-and-escalation.md
实测环境：Windows / DSH Web / ZCode 3.16.2（GLM）/ Claude Code CLI / Codex CLI
```

> 结论先说：**没有"模型互相聊天"这种省事办法**——能长期工作的只有一种：**它们共用一个磁盘上的任务总线**，各自用自己最擅长的能力干活，中间的交接**只走文件**。
> 本文件定义这套机制；载体是仓库根的 [`.coop/`](../../.coop/README.md)，操作入口是 [`tools/coop.ps1`](../../tools/coop.ps1)。

---

## 1. 三种真实可用的连接方式（2026-10-20 实测，不是设想）

| 方向 | 机制 | 实测证据 | 适合什么 |
| --- | --- | --- | --- |
| **DSH → Claude** | `claude -p "<prompt>" --add-dir <repo>` | `claude --help` 明确 `-p/--print` 为非交互输出、`--add-dir` 追加可访问目录 | 交叉评审、第二意见、代码审阅 |
| **DSH → Codex** | `codex exec -C <repo> -o <out.md> "<prompt>"` | `codex exec --help`：`-C/--cd`、`-o/--output-last-message`、`--sandbox`、`--json` | 同上；`-o` 能**把结论直接写成文件**，最省事 |
| **DSH → ZCode/GLM** | **没有 CLI 入口**：`ZCode.exe --help` 只启动主进程并退出（stdout 全是启动日志，stderr 仅 SQLite 警告），无参数解析 | 当场实测 | 只能：① 人工把卡片粘进 ZCode；② 在 ZCode 里让它直接读 `.coop/tasks/T-xxxx.md` |
| **任意 agent → 总线** | `pwsh -File tools/coop.ps1 -Action Claim/Report/Review ...` | 脚本已自带 `-Help` 与 `-DryRun` | 让"能跑 shell 的那个模型"把结果写回总线 |

**R-COOP-CLI-1**：**能用 CLI 的用它，不能用的走文件**。不要为了"自动化"去逆向 ZCode 的进程通信——桌面端每次升级都会变（本机已从 3.15.3 升到 3.16.2），而文件格式十年不变。

**环境坑（本机专属）**：DSH 终端里带 `ELECTRON_RUN_AS_NODE=1`，直接启动 `ZCode.exe` 会被当成 node 运行并立刻退出（`--version` 打印的是 node 版本）。在 PowerShell 里先 `Remove-Item Env:ELECTRON_RUN_AS_NODE` 再启动。

---

## 2. 角色：谁干什么（与 w07 的成本路由对齐）

| 角色 | 建议模型 | 输入 | 输出（**必须落文件**） |
| --- | --- | --- | --- |
| 编排者 Orchestrator | 便宜/本地（DSH 主会话） | 里程碑文档（w05）、刀刃清单（w07 §1） | 任务卡 `.coop/tasks/T-*.md`、把结论合并进 `docs/`、登记 README |
| 裁决者 Judge | 贵（ZCode/GLM 或指定型号） | 一张卡（含证据包） | `.coop/reports/T-*.md` 六段式 |
| 交叉评审 Reviewer | **与作者不同**的模型 | 卡 + 报告 | `.coop/reviews/T-*.md`（只找茬） |
| 执行者 Implementer | 便宜 | 已采纳的报告 | 文档/代码改动 + 测试 |

**R-COOP-2（写者≠评审者）**：`coop.ps1` 会拒绝"作者=评审者"的组合。推荐交叉矩阵：

| 作者 | 评审 |
| --- | --- |
| ZCode / GLM | claude（`-p` 非交互，最省心） |
| claude | codex（`-o` 直接落盘） |
| codex | ZCode / 或人工 |
| DSH（便宜侧） | 任何一个贵模型 |

---

## 3. 总线：一张卡的生命周期

```
open ──claim──▶ claimed ──report──▶ reported ──review──▶ reviewed ──accept──▶ done
                    │                                        │
                    └──────── release（放弃/锁过期）◀─────────┘
```

| 状态 | 含义 | 谁改 |
| --- | --- | --- |
| `open` | 卡已写好（问题/边界/证据包/交付规格/验收），等人接 | 编排者 |
| `claimed` | 有人认领，`locks/T-xxxx.lock` 里写着 owner + 到期时间 | 认领者 |
| `reported` | 报告已生成（可能是骨架） | 认领者 |
| `reviewed` | 有另一模型写了评审 | 评审者 |
| `done` | 结论被采纳并已合并进 `docs/` | 编排者 |

**R-COOP-1（单写者 + 租约）**：锁带到期时间（默认 240 分钟）。过期可被抢占，抢占会记进 `ledger.md`——**不允许悄悄超时**，否则两个人会同时改同一张卡。

**R-COOP-3（证据优先）**：报告每条结论必须跟 `文件:行号` 或文档链接；拿不出证据的，按"未验证"处理，不得进下游。

---

## 4. 一次完整协作的实际流程（以 T-0001 为例）

**第 0 步 · 编排者（DSH，便宜）**
```powershell
pwsh -File tools/coop.ps1 -Action New -Title "裁决出行预算三方配额" `
  -Source "docs/workflow/05-m1-task-breakdown.md §7 R3" -Layer L3
# 然后手工把"问题/边界/证据包/交付规格/验收"写进 .coop/tasks/T-0001.md
pwsh -File tools/coop.ps1 -Action Verify     # 结构合法才允许派
```

**第 1 步 · 裁决者（ZCode/GLM，贵）**
```powershell
pwsh -File tools/coop.ps1 -Action Claim  -Id T-0001 -Owner zcode -Model glm-5.3 -Minutes 240
pwsh -File tools/coop.ps1 -Action Report -Id T-0001 -Author zcode
```
把 `.coop/tasks/T-0001.md` 整份粘给 ZCode（或让它自己读这个路径），要求它**只填 `.coop/reports/T-0001.md`**。

**第 2 步 · 交叉评审（claude 或 codex，另一个模型）**
```powershell
pwsh -File tools/coop.ps1 -Action Review -Id T-0001 -Reviewer claude -Via claude
# 或： -Reviewer codex -Via codex   （codex 的 -o 会直接把结论写成文件）
```

**第 3 步 · 编排者合并**
```powershell
pwsh -File tools/coop.ps1 -Action Verify          # 结构 + 写者≠评审者
pwsh -File tools/coop.ps1 -Action Status
```
采纳 → 把结论写进 `docs/`（例如 w05 的 R3 缓解栏）→ 手工把卡 `status` 改成 `done` → 追加 ledger。

---

## 5. 并发：两个人同时改仓库怎么办

| 场景 | 做法 |
| --- | --- |
| 只改 `.coop/` | 无需隔离：每人只碰自己的 `T-xxxx` 文件 |
| 都要改 `docs/` | **一个 worktree 一个 agent**：`git worktree add ../plaa-zcode -b zcode/xxx`，各自提交，由编排者合并 |
| 都要改同一份文档 | **禁止**；先拆卡（一张卡一个文件），或在卡里写死"只改第 N 节的某句" |
| 长任务跨天 | 卡上的 `deadline` + 锁的 `expires` 是唯一事实；不要相信对话里的"我在做" |

**R-COOP-4**：**同一份文件同一时间只有一个 agent 有写权**。这条比任何并发工具都重要——冲突的成本远高于串行。

### 5.1 两棵树：Windows 仓库（文档/总线）× WSL 工作树（代码）

按 [ADR-022](../00-charter.md) 与 [ADR-025](../00-charter.md)：**`npm run setup` 在 Windows 不可能跑**（Blockwright 的 `dist/blockwright` 是 Linux x64 ELF），所以**构建、游戏测试、改上游代码**都在 **WSL `~/pla/mod`**；而**文档、计划、总线**在 Windows 仓库。

| 任务 | 卡里的 `tree:` | 允许动的路径 |
| --- | --- | --- |
| 裁决 / 写文档 / 评审 | `windows` | `docs/`、`.coop/` |
| 改代码 / build / gametest | `wsl` | `~/pla/mod`（结论回写 `.coop/reports/`） |
| 两边都要 | **拆卡** | 一张卡横跨两棵树 = 冲突时无法判定谁赢 |

`reference/folkways-3ce4d88/` 是**只读快照**，只用于核对 `文件:行号`，任何人不得修改（ADR-025）。

### 5.2 总线 × 正式交接：`.coop` 与 `docs/plans` / `docs/reports`

| 层 | 载体 | 生命周期 | 谁写 |
| --- | --- | --- | --- |
| 运行时调度 | `.coop/tasks/T-*.md`、`reports/`、`reviews/` | 短（几小时～几天），可丢弃 | 编排者派、裁决者填 |
| 正式交接 | `docs/plans/PLAN-NNN-*.md`、`docs/reports/VERIFY-NNN-*.md` | 长（进版本库、可审计） | 规划者 / 验证者 |

**R-COOP-5**：`.coop` 里被采纳的结论**必须**沉淀成 `docs/plans` 或直接改进 `docs/prd|design|workflow`；**`.coop` 不是档案库**。卡片 front-matter 的 `plan:` / `verify:` 字段就是挂钩（例：`plan: docs/plans/PLAN-001-b2-modid-rename.md`）。

---

## 6. 失败模式（都在这台机器上真实发生过或极可能发生）

| # | 失败 | 表现 | 对策 |
| --- | --- | --- | --- |
| 1 | 上下文漂移 | ZCode 引用了三天前的结论 | 卡里带**证据包**（文件:行号），不靠对话记忆 |
| 2 | 越界改动 | 让它判一个问题，它顺手重写了三节 | 卡里写"不要动：…"，评审第 2 条查 `git status --short` |
| 3 | 报告只有空话 | "建议按需分配" | 验收要求"配额是数字"；`Verify` 查六段式与占位符 |
| 4 | 同源自审 | 作者自己写评审 | `coop.ps1` 直接拒绝（R-COOP-2） |
| 5 | 锁过期无人管 | 两个人同时改 | 租约 + 抢占记 ledger |
| 6 | 成本失控 | 一个卡跑了 5 轮 | 卡里 `budget: 1 次尝试，≤120 行，只读 N 个文件` |
| 7 | CLI 不可用 | `claude`/`codex` 未登录 | 先跑一次最小验证；失败就退回"人工粘贴" |
| 8 | 桌面端升级 | ZCode 从 3.15.3 → 3.16.2，注入的补丁失效 | 不依赖 ZCode 内部；只依赖它能读写文件 |

---

## 7. 成本控制（和 w07 的分工）

| 原则 | 落地 |
| --- | --- |
| 便宜的先干 | 拆卡、写证据包、合并结论、跑 `Verify`、改 README —— 全在便宜侧 |
| 贵的只判断 | 每张卡只问**一个问题**，输出 ≤120 行 |
| 先 DryRun | `-Action Review -DryRun` 先看提示词与命令，确认无误再真调 |
| 用 `-o` 收口 | codex 的 `-o` 让"评审结论"必然落成文件，避免"它说了但我没存下来" |
| 一次一卡 | 不要在一个会话里连做 5 张卡（上下文会互相污染，回溯成本极高） |

---

## 8. 命令速查

```powershell
pwsh -File tools/coop.ps1 -Action Help
pwsh -File tools/coop.ps1 -Action Status
pwsh -File tools/coop.ps1 -Action New     -Title "<一句话>" -Source "<来源>" -Layer L3
pwsh -File tools/coop.ps1 -Action Claim   -Id T-0001 -Owner zcode -Model glm-5.3 -Minutes 240
pwsh -File tools/coop.ps1 -Action Report  -Id T-0001 -Author zcode
pwsh -File tools/coop.ps1 -Action Review  -Id T-0001 -Reviewer claude -Via claude [-DryRun]
pwsh -File tools/coop.ps1 -Action Release -Id T-0001 -Owner zcode
pwsh -File tools/coop.ps1 -Action Verify
```

---

## 9. 开放问题

| 编号 | 问题 | 何时定 |
| --- | --- | --- |
| OQ-1 | ZCode 是否值得为它做一个"读卡→执行→写卡"的固定开场提示词（省人工粘贴）？ | 用满 3 张卡后 |
| OQ-2 | 评审用 claude 还是 codex 作默认？两者成本/风格差异需实测 2–3 次 | 下次派卡时 |
| OQ-3 | 是否让 `mnemon` 记忆与 `.coop` 打通（把已采纳结论写进记忆，减少重复喂上下文）？ | M1 期间 |
| OQ-4 | 多人（多个真实玩家/多台机器）场景下，`.coop` 是否要进 git（会冲突）还是只留本地？ | 首次多人协作前 |
| OQ-5 | worktree 隔离由脚本自动建，还是人工？ | 第一次并发改文档时 |
