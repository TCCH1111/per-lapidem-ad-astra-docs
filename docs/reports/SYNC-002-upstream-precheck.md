# SYNC-002 · 上游同步预检 #2：历史已被重写，不能用 merge

```
状态：预检完成（**未合并、未改动任何分支**）
验证者：DSH 会话
验证日期：2026-11-05
关联：SYNC-001（演练 #1）、ROADMAP D15
fork 基线：0cb72e8（714/714）；上游：aaac8b8
```

---

## 1. 一句话结论

**上游把历史重写了**，我们与它**已经没有共同祖先**；`git merge` 会直接报 *unrelated histories*。所以 SYNC-002 不能是"合并"，只能是**把我们的改动重新移植**（patch port）。预检已经把移植的每一类结果数清楚了。

---

## 2. 证据：历史确实被重写

| 检查 | 结果 |
| --- | --- |
| `git merge-base HEAD upstream/master` | **空（无共同祖先）** |
| 我们的基线 `3ce4d88` 是否仍是上游祖先 | **否** |
| 我们的根提交 | `7cd6105 ready to publish` |
| 上游的根提交 | `731d528 ready to publish`（**同名、不同 SHA**） |
| 上游历史里是否存在与我们 `3ce4d88` 同 tree 的提交 | **没有**（84 条历史全查过） |

**含义**：这不只是"上游多了几个提交"，而是**整条历史被重建**（根提交都换了）。任何基于旧 SHA 的理想化假设（共同祖先、三方合并、`git range-diff`）全部失效。

---

## 3. 分叉规模

```
我们独有 58 提交 / 上游独有 84 提交
上游内容相对我们基线：1403 文件，+160750 / −157313
```

上游新增了一大批插件模块：`build / combat / compost / damagecontrol / farming / fishing / groundwork / orders / pasture / patrol / supply / wares`。**即使抛开历史重写，内容层面也已是另一个量级的项目。**

---

## 4. 移植预检（本轮真正做的事）

我们自己相对基线改了 **85 个文件：48 新增 / 37 修改 / 0 删除**。把每个文件单独 `git apply --3way` 到上游 tip：

| 类别 | 数量 | 说明 |
| --- | --- | --- |
| 修改类 · **干净合并** | **24** | 三方合并无冲突 |
| 修改类 · **有冲突** | **12** | 需人工解 |
| 修改类 · **上游已删除** | **1** | `Solving.java`（我们的测试夹具改动需重新安置） |
| 新增类 · 路径被上游占用 | **0** | 我们新建的 48 个文件没有一个撞路径 |
| 其它失败 | 0 | — |

### 4.1 需要人工解的 12 个

| 文件 | 性质 | 难度预估 |
| --- | --- | --- |
| `.github/workflows/build.yml` | CI 定义 | 低（我们对 CI 的改动可重打） |
| `build.gradle` / `blockwright.toml` | 版本与依赖 | 低 |
| `CONTRIBUTING.md` / `README.md` | 文档 | 低 |
| `neoforge.mods.toml` | mod 元数据（我们的 modid/名称） | 低 |
| `lang/en_us.json` `zh_cn` `zh_hk` `zh_tw` | 四语言键 | 低（取并集即可） |
| `Labor.java` | **我们的 L3 改动** | **中** |
| `BuiltinPlugins.java` | 插件注册（我们加了 steering/hours） | **中** |

### 4.2 真正危险的部分：14 个"两边都动过"的 L2/L3 文件

带 `// PLA:` 标记的文件共 **67** 个，其中**上游也改了的有 14 个**：

```
core:  Labor.java · ColonyLabor.java · Tours.java · Scheduler.java · Urges.java · Pipeline.java
       FolkwaysMod.java · neoforge.mods.toml · build.gradle(×3)
vanilla: BuiltinPlugins.java · PersonPlugin.java · LivingPresence.java
```

这些正是我们**否决权、作息、心情**三套改动的落点。上游在这些文件上有大量重构（如 `perf(labor): share one tick budget across every site`），**冲突不是文本级的，而是语义级的**。

---

## 5. 一个必须处理的命名撞车

上游新出现了 `StandingPlanGameTests` / `StandTravelGameTests`——**上游的 "Standing" 指 "stand（站位）相关的规划"**，而我们用 `Standing` 表示"否决权"。

- 路径上不冲突（我们的 `core/api/work/Standing.java` 上游没有）；
- **语义上会长期误导**：同一个词在一个代码库里指两件事，移植时尤其危险。

**建议**：移植前把我们的 `Standing` / `Standings` 改名为 `Veto` / `Vetoes`（纯我们自己的 L1 API + 引用，改动可控），顺便让"否决"这件事名副其实。

---

## 6. 结论与建议路线

### 结论

| 方案 | 判定 |
| --- | --- |
| `git merge upstream/master` | **不可行**（无共同祖先） |
| 在旧历史上继续开发、以后再合并 | **不可行**（差距只会更大：上游一周多就 +84 提交） |
| **把我们的改动移植到上游 tip** | **可行**：24 干净 / 12 可解 / 1 重定位 / 48 直接新增 |

### 路线（SYNC-002 正式执行）

1. 从上游 tip 开专用分支 `port/aaac8b8`（不动 `main`，`main` 保持可发布）；
2. **先改名** `Standing → Veto`（在旧树上做一次，测试仍 714 通过）；
3. 在 `port/` 分支上：先加 48 个新文件 → 再合 24 个干净的 → 再逐个人工解 12 个冲突 → 最后安置 `Solving.java`；
4. 跑四件套（build / unit / i18n / gametest），目标 **714 全过**；
5. 通过后再考虑把 `main` 快进到 `port/`（或反向合并），并更新文档追认新基线。

### 风险与代价（说清楚）

- 第 3 步的 12 个冲突里，`Labor.java`、`BuiltinPlugins.java` 可能牵动上游重构，**不保证一轮完成**；
- 移植期间上游还会继续前进（预计仍是每周数十提交），**移植完成即落后**——所以完成后应改为**小步定期移植**，而不是等攒到 84 个提交再动。

---

## 7. 本轮没有做的事（明确边界）

- **没有合并、没有切换分支、没有改任何上游文件**；
- 预检在一次性 worktree `/home/tcch1111/pla/sync002-perfile2` 中进行，事后已清理；
- `main` 仍在 `0cb72e8`，714/714，随时可发布。
