# Folkways fork 策略

```
状态：草稿（决策已定，执行细节待补）
负责人：项目发起人（人类）+ 实现者
最后更新：2026-10-19
上游依据：ADR-007（fork）、ADR-021（基线/分仓/远端/打包工具）、C2/C3/C8（章程硬约束）
事实依据：docs/research/04-content-and-modding.md（API 边界）、05-engineering-and-tooling.md（工程与测试基建）
下游影响：所有 PRD 的「与基底 API 的关系」章节、docs/pack/00-pack-spec.md、docs/workflow/01-agent-roles-and-tools.md
```

> **决策（ADR-007）**：不再"只写插件"，而是 **fork Folkways 源码直接改造**。
> 理由很直接：调研显示插件路线做不到的事太多（见 §2），而我们真正想要的东西大多在那些位置。
> 代价同样明确：**我们要自己维护一个 Minecraft mod**。本文的核心目的就是让这份代价**可控**。

---

## 1. 为什么 fork 是对的（基于调研事实）

插件路线在 [r04 §3.3/§6](../research/04-content-and-modding.md) 里的硬边界（每条都有源码依据）：

| 想做 | 插件路线的结论 | 影响 |
| --- | --- | --- |
| 新增数据包货架（`need`/`incident`/`scenario`…） | 书架名是固定集合，`Patterns`/`PatternLibraryPacket` 不在 API jar 内 | PRD-001/002/007 全部卡住 |
| 扩展 `Schema.Setting`（排班/条件规则/更多档位） | 密封接口，改一处牵动四处 | PRD-005/006 卡住 |
| 新增 Starlark 图案函数/标记类型 | `Vocabulary.predeclared()` 是硬编码单例 | 内容生产能力封顶 |
| 新的动作类型（手动指派、战斗指令） | `Board.Act` 只有 5 个动词 | A-max 不可能 |
| 从 API 读诊断数据 | `Unassigned`/`Cooldowns`/`Why` 多在包私有层 | 因果诊断（PRD-006）交付受限 |
| 核心需求/情绪/温度层 | `core/api` 里根本没有 | 只能在插件侧"外挂"，与规划器耦合脆弱 |
| 整合包级保护（人口上限等） | 配置项没有入口 | 性能与玩法保护缺失 |

**结论**：我们想在的地方插不上手，而我们能插手的地方又不够。fork 是唯一能把设计落地的路径。

---

## 2. fork 能解锁什么（对照）

| 之前做不到 | fork 后 | 对应文档 |
| --- | --- | --- |
| 新增货架 | 直接改 `Shelves` 注册表，支持任意书架名 + `/reload` + `/folkways library` 自检 | [pack/02](../pack/02-config-and-datapack.md) F1 路线成立（不再需要 F2 兜底） |
| 扩展 `Schema.Setting` | 一次改到位（`Schema`/`SettingsPage`/`DomainPage`/`ZoneSettings`） | [PRD-005](../prd/PRD-005-intent-and-micro-control.md) |
| 新动作类型 | 扩 `Board.Act` 或以 `Facing.act` 为基础新增动作分类 | PRD-005（指派）、A-max |
| 诊断数据 | 把 `Unassigned`/`Cooldowns`/`RefusalKind` 提升为公开只读 API | [PRD-006](../prd/PRD-006-stock-rules-and-diagnosis.md) |
| 居民需求/情绪进核心 | 在引擎层拥有 `Need`/`Mood`，规划器直接消费 | [PRD-001](../prd/PRD-001-needs-mood-memory.md) |
| 世界状态层（季节/温度/口渴） | 原生实现，作为规划器可读的数据层 | ADR-010、PRD-003 |
| 人口上限、玩法开关 | 进 serverconfig | [pack/03](../pack/03-performance-budget.md) |
| 多方块火箭/空间站与居民联动 | 新建工作节点、新维度/子层、新载具语义 | ADR-011、PRD-011 |
| 图案白名单、内容治理 | 服务端发牌逻辑可控 | [pack/02](../pack/02-config-and-datapack.md) OQ-CD-5 |
| 性能：`Pack` 18 格、`Refining.LIMIT` 等硬常量 | 可以重新评估与放宽 | [PRD-006](../prd/PRD-006-stock-rules-and-diagnosis.md)、PRD-010 |

---

## 3. fork 的代价（必须正视）

| 代价 | 说明 | 缓解 |
| --- | --- | --- |
| 上游同步 | 上游是 pre-release，仍在活跃开发 | 改动分层（§5）+ 季度同步（§6） |
| 我们成为 mod 作者 | 存档兼容、崩溃、性能、i18n 都由我们负责 | 沿用上游的工程规范（Tab/lint/i18n 检查）与测试基建 |
| 测试基建维护 | 488 个游戏测试、44 个 e2e、Blockwright（**仅 Linux x64**） | 层 0/1 保 Windows；CI 上 Linux runner；不删上游测试 |
| 许可义务 | MIT：保留版权与许可、注明修改 | `NOTICE` 文件 + README 声明（§7） |
| 用户预期管理 | 不能与上游同名发布，避免混淆 | 独立 modid 与版本号（§4） |
| 社区关系 | 不建议把我们的改造要求强加给上游 | 对我们的改造保持独立；上游好修复可反向 PR（可选） |

**R-FK-1**：fork 的目的不是"摆脱上游"，而是"在被卡住的地方能动手"。**每一个改动都要能回答：这是必须改上游吗？**

---

## 4. 仓库、命名与目录

| 项 | 决定 |
| --- | --- |
| 仓库 | **分仓（2026-10-19 已定，OQ-1 / [ADR-021](../00-charter.md)）**：fork 是**独立 git 仓库**，位于工作区 `mod/`（完整克隆上游历史，目录结构与上游一致，季度同步即普通 `git merge upstream/master`）；工作区根目录（`docs/` + `pack/`）另成一仓并忽略 `mod/`，有远端后改为 submodule 钉 commit。我们的集成分支名 **`main`**（上游为 `master`，避免混淆）；**远端暂无，先本地 git** |
| 上游来源 | `https://github.com/IzakyL/folkways`，以 `upstream` remote 形式保留（本机 git 全局代理 `127.0.0.1:10809` 常不在线，fetch 时用 `git -c http.proxy= -c https.proxy= fetch upstream`） |
| 上游基线 | **已打标签 `upstream-base-67f28b0-20261019`**：上游 `master` @ `67f28b0`（2026-10-18T09:06Z）。**该基线已含 `0af84f0` 的四模块拆分**：`mods/core`、`mods/vanilla`、`mods/create`、`mods/modulargolems` 四个 Gradle 子项目 / 四个 modid（`folkways_core`、`folkways_vanilla`、`folkways_create`、`folkways_modulargolems`），根工程不再出 jar，`lib()`/`mods.json` 机制移至 `gradle/mod.gradle`。首个快照 `f42e3c1`（2026-10-17，单 jar）已被取代，`docs/research/01~05`、w05、w06 中指向 `reference/folkways-master/` 的 `文件:行号` 引用待按 [w01 §5](../workflow/01-agent-roles-and-tools.md) 重跑差异（见 `reference/README.md`；已于 2026-10-19 迁移到 67f28b0，见 r10） |
| 上游动态 | 2026-10-19 在 WSL 仓库 `git fetch upstream --prune`：`upstream/master` = `29498b0`（feat(ui): pickers file in folders, the wheel pushes away as Create's does, and a work site joins the ways），**领先基线 1 提交**；我们的 `main` 不设上游跟踪，同步只走 §6 的 `git merge upstream/master`。是否前移基线由人类定；该提交即 WP-10 同步演练（R-FK-11）的现成素材 |
| mod id | **必须新取**（不能占用上游 modid，否则无法与上游区分/共存判定）。**已定（[ADR-017](../00-charter.md) + [ADR-023](../00-charter.md)）**：四个子项目 1:1 对应 **`plaa_core` / `plaa_vanilla` / `plaa_create` / `plaa_modulargolems`**（改 `mods/<name>/build.gradle` 的 `ext.modId` / `ext.modName`）；**资源命名空间 `folkways` 不改**（上游四 mod 共用，改它等同 L4） |
| Java 包名 | 保留上游包结构不动（`folkways.*` 或上游实际包名），我们的新增代码放**新包**；**不重命名上游包**（否则与上游彻底分叉，失去同步能力） |
| 玩家可见名称 | 我们自己的名字（Per Lapidem ad Astra），不叫 Folkways |
| 目录 | 沿用上游目录结构（`core/`、`front/`、`plugins/`），我们新增插件放在 `plugins/` 同级（例 `plugins/needs/`），保持"一个插件一个系统"的组织 |

**R-FK-2**：**不重命名上游的包与类**。改名的收益（整齐）远小于代价（上游同步全冲突）。
**R-FK-3**：我们的 modid 与上游不同 → 两者的数据包/配置目录不冲突；但**同一个存档不能同时装两个**（同一套居民/殖民地概念），必须在 `mods.toml` 里声明冲突。

---

## 5. 改动分层（上游同步友好度）

> 原则：**能在新文件里做的，就不要改上游文件**；必须改上游文件时，改动要**小、可读、可回滚**。

| 层 | 做法 | 上游同步难度 | 例 |
| --- | --- | --- | --- |
| **L0 配置级** | 只改数据/配置，不改代码 | 无 | 数值、配方、标签 |
| **L1 新文件** | 在上游目录里**新增**文件（新插件、新类） | 极低 | `plugins/needs/…`、新货架注册 |
| **L2 小改上游文件** | 在既有类里加**少量、带标记注释**的钩子（注册调用、公开只读访问器） | 低–中（可能冲突，易手工合并） | 在 `Shelves` 注册新书架；把 `Unassigned` 提升为公开 |
| **L3 改上游逻辑** | 修改既有行为（规划器求值、包容量、动作类型） | 高（必须逐次评审） | `Schema.Setting` 扩展、`Board.Act` 新动作、需求接入求值 |
| **L4 结构性重构** | 移动/重命名/替换上游模块 | **禁止**（等同于永久分叉） | —— |

**R-FK-4**：L2/L3 的每一处改动必须在代码里加统一标记注释（例：`// PLA: <原因> <PRD 编号>`），便于同步时定位。
**R-FK-5**：每个 PRD 的「与基底 API 的关系」章节必须标注它需要 L1/L2/L3/L4 中的哪一层。**L4 一律不做**。
**R-FK-6**：新增系统优先作为**新插件**（L1）；只有当插件形态无法接入求值/UI 时才升到 L2/L3。

**改动清单（单源）**：`docs/design/12-fork-strategy.md` 附表维护「我们改了上游哪些文件、为什么、属于哪一层」。这张表就是将来同步上游时的清单。

### 5.1 改动登记表（初始为空，随实现补充）

| 文件/类 | 层 | 原因 | PRD | 日期 |
| --- | --- | --- | --- | --- |
| `mods/core/src/main/java/io/github/izakyl/folkways/library/Shelves.java`（示例） | L2 | 允许注册新书架 | PRD-001/002/007 | 待实现 |
| `mods/core/src/main/java/io/github/izakyl/folkways/front/api/Schema.java`（示例） | L3 | 扩展设置项类型 | PRD-005 | 待实现 |
| `mods/core/src/main/java/io/github/izakyl/folkways/front/api/panel/Board.java`（示例） | L3 | 新增动作分类 | PRD-005（A-max） | 待实现 |

---

## 6. 上游同步流程

```
每季度一次（或上游发布重要修复时）：

1. 拉取 upstream → 查看变更（CHANGELOG / git log）
2. 评估影响：是否触及改动登记表里的文件（L2/L3）
3. 无冲突：直接 merge/rebase 到我们的分支
4. 有冲突：按登记表逐项手工合并；L3 项需要重新验证行为（跑层 0/1 测试）
5. 更新基线标签与登记表日期
6. 记录到 CHANGELOG（上游变更 / 我们的取舍）
```

| 情形 | 处理 |
| --- | --- |
| 上游修了我们已修的同一 bug | 采用上游版本，删除我们的改动（登记表标记"已回上游"） |
| 上游改了数据包格式 | 我们先写迁移，再合并（存档兼容优先） |
| 上游改了存档版本号 | **暂停**，先评估我们自管版本的冲突 |
| 上游停止维护 | 我们 takeover 该 fork（这正是 ADR-007 的保险） |
| 上游重写某模块 | 评估是否放弃我们的 L3 改动、改用上游新结构 |

**R-FK-7**：同步上游前必须**有可回滚点**（标签/分支）与**跑通的层 0/1 测试**。

### 6.1 编译期依赖的获取机制（2026-10-18 直读上游核实，**推翻本节旧结论**）

**旧结论（错）**：以为要我们自己手写 `.blockwright/mods.json`。
**事实**：该文件是**生成的**——`package.json` 的 `setup` 脚本 = `blockwright mods sync --config blockwright.toml`，它按 `blockwright.toml` 里 pin 的 URL **下载并 sha512 校验**后写出 `.blockwright/mods.json`。

| 事项 | 结论（带依据） |
| --- | --- |
| 依赖清单的唯一真源 | **`blockwright.toml`**（pin 了 URL + sha512）；我们不手写 `mods.json`，fork 后**改 toml** |
| 正确的首次构建顺序 | `npm install` → **`npm run setup`** → `./gradlew build`（`CONTRIBUTING.md:14-22`；缺文件时 `gradle/mod.gradle:39-47`（上游已拆为 ext.lib） 的 `lib()` 会抛 `GradleException`，报错里就写着 "run npm run setup first"） |
| 环境要求 | **Java 21 JDK**、**Node.js ≥ 22.14**、NeoForge **21.1.233** / MC **1.21.1**（`CONTRIBUTING.md:6-12`、`blockwright.toml`） |
| 平台限制 | **构建**在任何 Gradle 支持的平台都行；**游戏测试（Blockwright/Playwright）目前只支持 Linux x64**（`CONTRIBUTING.md:10-12`）→ CI 的 gametest/e2e 必须跑在 Linux runner |
| 编译期需要哪些 jar | `emi`/`jei`/`geckolib`/`shouldersurfing`/`create`/`sable`+`sable-companion`/`modulargolems`/`l2library`+`l2core`+`l2serial`/`ftbteams`/`architectury`（`mods/core/build.gradle:12-17`、`mods/vanilla/build.gradle:15`、`mods/modulargolems/build.gradle:14`（依赖声明按子项目拆开））；`ponder` 走 Maven 坐标且 **`jarJar` 内嵌**（`mods/core/build.gradle:19-28`（ponder，上游已移到 core）），是真运行期依赖 |
| 缺文件时的后果 | 不是"可选集为空"，而是**构建直接失败**（`lib()` 抛异常）——所以"零依赖也能 build"这句话必须限定 |

**R-FK-12（2026-10-18 修订，措辞纠正）**：M1 的硬门禁是「**运行期零可选依赖**」——即在**只装 NeoForge + 我们的 jar** 的环境里游戏能启动、核心功能可用、缺的只是可选桥接；**编译期**依赖由 `blockwright.toml` 统一提供（这是上游既定机制，不是我们的负债）。**验收**：干净机器上按 `npm install → npm run setup → ./gradlew build` 一次通过，且产物在不含任何可选 mod 的实例里能进世界。

**离线与镜像**：`npm run setup` 依赖 CDN/maven 可达（已抽查 `blockwright.toml` 里 create/emi/sable/l2library/ftb-teams 五个 pin，均可下载；Blockwright 的六个 npm 包均已发布，`0.1.0-alpha.1` 在 `next` 标签下）；离线构建可用**已生成的 `mods.json` + jar 缓存快照**（是否入库、如何更新，见 workflow/06 构建与 CI 规格的 OQ）。

---

## 7. 许可与署名（法律义务）

| 义务 | 做法 |
| --- | --- |
| 保留版权声明 | 保留上游 `LICENSE`（MIT）原文与所有版权头**不得删除** |
| 注明修改 | 新增 `NOTICE.md`：说明这是基于 Folkways 的 fork、列出主要修改、保留原作者署名与链接 |
| 我们不"洗白"来源 | README 与整合包页面明确写「基于 Folkways（作者 IzakyL）」，不得暗示原创 |
| 我们的代码许可 | **已定：MIT**（与上游一致；保留上游 `LICENSE` 与版权头，另加 `NOTICE.md`）（[ADR-017](../00-charter.md)） |
| 文档 | 本仓库文档（docs/）为我们的原创，可单独授权 |
| 依赖 | 引入的第三方 mod（Create/GPL 类）不影响我们的许可，但要登记（见 [k01 §4.4](../pack/01-modlist.md)） |

**R-FK-8**：任何发布物（jar、整合包）必须包含 `LICENSE`（上游 MIT）与 `NOTICE.md`（我们的修改说明）。

---

## 8. 测试基建（fork 后归我们维护）

| 层 | 工具 | 现状（上游） | 我们要做的 |
| --- | --- | --- | --- |
| 0 静态/单元 | `gradlew check`、15 个 `*.test.ts`、i18n 检查 | 有，CI 跑 | **保留并扩展**（上游既有键仍过四语言检查；**我们新增的键只需 `zh_cn` + `en_us` 双语齐全**，[ADR-017](../00-charter.md)） |
| 1 游戏内 | `@GameTest`，**488 个**（85 类） | 有，**CI 不跑** | **纳入 CI**（相对上游立刻取得工程优势） |
| 2 端到端/视觉/基准/模糊 | Blockwright（**仅 Linux x64**）、44 个 e2e spec、bench 400 居民场景 | 有 | 保留；新增我们系统的 spec 与探针；本机 Windows 只跑层 0/1 |
| 内容校验 | `/folkways library`、i18n | 有 | 加我们的货架自检（[pack/02 R-CD-8](../pack/02-config-and-datapack.md)） |

**R-FK-9**：**不得删除上游测试**；废弃的功能要连同其测试一起标记（保留历史）而不是直接删。
**R-FK-10**：fork 后的发布门禁 = 层 0 + 层 1 全绿 + **i18n：上游既有键不回归（四语言检查）且我们新增的键 `zh_cn` + `en_us` 齐全** + 阻塞覆盖率 ≥95%（[PRD-006](../prd/PRD-006-stock-rules-and-diagnosis.md)）。

---

## 9. 发布形态

| 项 | 决定 |
| --- | --- |
| 发布物 | ① 我们的 mod jar（平台发布，独立页面，声明基于 Folkways）② 整合包（含我们的 jar，见 [pack/00](../pack/00-pack-spec.md)） |
| 版本号 | `<major>.<minor>.<patch>+mc1.21.1`，与上游版本号**无关联**（避免误导） |
| 与上游共存 | **不允许**（`mods.toml` 声明冲突：同一个世界只能有一套居民系统） |
| 升级 | 我们自己的迁移责任（[fork 策略 §6](#6-上游同步流程) + 各 PRD 存档章节） |
| 回滚 | 提供上一版本下载；存档降级明确拒绝而非崩溃 |

---

## 10. 禁止事项

| 禁止 | 理由 |
| --- | --- |
| L4 结构性重构（重命名上游包/移动模块） | 等于永久分叉，失去同步能力（R-FK-2/4） |
| 重写规划器内核 | 上游最强的部分；改它的求值输入，不改它的算法（[PRD-005 R-ST-1](../prd/PRD-005-intent-and-micro-control.md)） |
| 删除上游测试或数据包格式 | 破坏可验证性与存档兼容 |
| 与我们自己的插件**再**分一层（fork 里再搞插件 API） | 过度设计；fork 后直接写 |
| 把上游代码重新发布为"全新项目" | 许可与诚信要求（§7） |
| 在 fork 里堆砌与支柱无关的实验特性 | 对照[章程 K5](../00-charter.md)（设计膨胀） |

---

## 11. 与里程碑的关系

| 里程碑 | fork 相关动作 |
| --- | --- |
| M0 文档 | 本文 + ADR-007 定稿；建立改动登记表 |
| M1 可玩骨架 | 打上游基线标签；跑通层 0/1；**把 `runGameTestServer` 纳入 CI**；改 modid/名称；第一个 L2 改动（如新书架） |
| M2 张力 | 首批 L3 改动（`Schema.Setting`、诊断数据公开、需求接入求值） |
| M3 进程 | 世界状态层（季节/温度）、经济扩展 |
| M4 故事与打磨 | 太空终局（多方块火箭/空间站，ADR-011）；发布候选 |

**R-FK-11**：M1 必须完成一次**完整的上游同步演练**（即便当时无上游变更，也要走一遍流程），以验证同步机制可用。

---

## 12. 开放问题

| 编号 | 问题 | 影响 | 何时定 |
| --- | --- | --- | --- |
| OQ-1 | ~~mod 与整合包同仓还是分仓？~~ | **已定：分仓**（§4"仓库"行；[ADR-021](../00-charter.md)） | ✅ 已定（2026-10-19） |
| OQ-2 | ~~我们自己的代码用什么许可（MIT / ARR）？~~ | **已定：MIT**（[ADR-017](../00-charter.md)） | ✅ 已定（2026-10-18） |
| OQ-3 | 是否向上游反哺非项目特有的修复（PR）？ | 社区关系与同步成本 | M2 前 |
| OQ-4 | ~~modid 最终取值（与 [OQ-G-2](../design/03-glossary.md) 同）~~ | **已定：`plaa`**（[ADR-017](../00-charter.md)） | ✅ 已定（2026-10-18） |
| OQ-5 | 改动登记表是否用脚本校验（确保每个 L2/L3 改动都有标记注释）？ | 同步可靠性 | M2 前 |
| OQ-6 | 上游拆成四个 modid 后，[ADR-017](../00-charter.md) 的 `plaa` 如何展开：`plaa_core` / `plaa_vanilla` / `plaa_create`…？资源命名空间是否仍沿用上游的 `folkways`（四个上游 mod 共用该命名空间）？R-FK-3 的 `mods.toml` 冲突声明要对四个上游 modid 逐一写？ | w06 B-2 步、`blockwright.toml` 的 `[mods.folkways_*]`、整合包 jar 清单。事实（[r10 §2](../research/10-upstream-delta-f42e3c1-67f28b0.md)）：modid 在 `mods/<name>/build.gradle` 的 `ext.modId`，产物名在 `ext.modName`，`gradle.properties` 已无 `mod_id`；四个 toml 之间用 `[${version}]` 精确互钉 | ✅ **已定（2026-10-19，[ADR-023](../00-charter.md)）**：`plaa_core` / `plaa_vanilla` / `plaa_create` / `plaa_modulargolems`；资源命名空间 `folkways` 不动；R-FK-3 对四个上游 modid 逐一声明 `incompatible`。B-2 仍在上游原状通过 B-3..B-6 之后执行 |