# VERIFY-045 · 队列 ⑦：CI 门禁 P0+P1 落地（并修掉一条真缺陷）

```
状态：通过 —— 门禁四件套在本机 Linux 复现全绿；队列 ⑦ 完成；债务 D6/D7 关闭
验证者：DSH 会话
验证日期：2026-10-26
关联：w06 §4.2（P0/P1）、d12 §5.1（改动登记表）、VERIFY-010/012（D7 偶发测试）、VERIFY-040（264 统一）
fork 提交：603bf68（本轮三提交 0ad0cf7 / 6233702 / 603bf68；**尚未推送——网络恢复后 push**）
```

---

## 1. 结论

`D6：无 CI` 是一张一直开着的债，而它的代价在这一轮暴露得很直接：**fork 的 `npm run test:unit` 与 `npm run test:i18n` 本来就是红的**（我们自己引入的两处缺陷从未被门禁挡住）。本轮：

1. 把 **P0（静态+单元+i18n）** 与 **P1（Linux 游戏测试）** 落进 `.github/workflows/`，按 w06 §4.2；
2. 在**本机 WSL（Linux）** 上把四件套原样跑通，作为"门禁确实能过"的可复现证据；
3. 修掉门禁一开就抓到的**真缺陷**（禁区页面文案缺失、bench 判据表未登记我们的拒绝原因）；
4. 对唯一已知偶发测试（D7）实现"**只此一条按名单重试一次**，其余失败绝不重试"。

```
四件套（改动前 → 改动后）
  build      ✅ BUILD SUCCESSFUL(8s,含 lintScaffold) → ✅(9s)
  unit       131/134  ❌（3 失败）                    → 134/134 ✅
  i18n       6/7      ❌（1 失败）                    → 7/7     ✅
  gametest   712/712  ✅ ×2                           → 712/712 ✅（P1 脚本 "passed on attempt 1"）
```

---

## 2. 交付

### 2.1 代码（fork `~/pla/mod`，三个提交）

| 提交 | 内容 |
| --- | --- |
| `0ad0cf7` | `fix(i18n)`：补 4 语言各 7 个键——禁区页面 `folkways.page.steering{,.zones,.zone,.empty}` 与区域种类 `folkways.zone.kind.{forbid,allow_only,limit}` |
| `6233702` | `test(bench)`：把 `SteeringRefusal.FORBIDDEN/ONLY_FOR_OTHERS/QUOTA_FULL`、`HoursRefusal.RESTING`、`ZONE_FORBIDDEN`、`HOURS_RESTING` 登记进判据表 |
| `603bf68` | `ci`：`build.yml` 加 `check`/`i18n`、nightly 改走 `main`；新增 `gametest.yml` + `tools/ci/run-gametest.sh` |

### 2.2 门禁设计（对应 w06 §4.2）

| 流水线 | 文件 | 跑什么 | 触发 |
| --- | --- | --- | --- |
| **P0 静态与单元** | `.github/workflows/build.yml` | `npm ci` → `setup` → **`./gradlew check`** → `typecheck` → `test:unit` → **`test:i18n`** → `./gradlew build` → 上传 jar | push / PR |
| **P1 游戏测试** | `.github/workflows/gametest.yml` + `tools/ci/run-gametest.sh` | `runGameTestServer`（ubuntu-24.04，**仅 Linux**） | PR / push→`main` |

**与上游 build.yml 的差别（即我们的增量）**：上游只跑 `build`/`typecheck`/`unit`；我们加了 **`check`（含 `lintScaffold`）** 与 **`i18n`**（D6 的核心补位），并把 **游戏测试**搬进 CI——这正是 w06 R-BLD-11 要求、上游当时没做的事。

### 2.3 D7 的偿还（重试策略）

`run-gametest.sh`：跑第 1 次；**仅当失败测试全部落在名单**（当前只有 `onefoodcannotfeedhalfofapair`）时重试第 2 次；名单外任何失败**不重试**、直接判红。既不再被偶发挡住"全绿"，也不把真回归盖过去。

---

## 3. 证据（本机 Linux / WSL 复现）

```
# 改动前（f2421e7）— 四件套并非全绿
.cache/logs/ci-01-build.log    : BUILD SUCCESSFUL in 8s（> Task :lintScaffold 已执行）
.cache/logs/ci-02-unit.log     : # tests 134 / # pass 131 / # fail 3
.cache/logs/ci-03-i18n.log     : # tests 7   / # pass 6   / # fail 1
.cache/logs/ci-04-gametest-1.log: All 712 required tests passed :)
.cache/logs/ci-05-gametest-2.log: All 712 required tests passed :)

# 改动后（603bf68）— 全绿，且经 P1 脚本实跑
.cache/logs/ci2-01-build.log    : BUILD SUCCESSFUL in 9s   (build_exit=0)
.cache/logs/ci2-02-unit.log     : # tests 134 / # pass 134 / # fail 0  (unit_exit=0)
.cache/logs/ci2-03-i18n.log     : # tests 7   / # pass 7   / # fail 0  (i18n_exit=0)
.cache/logs/ci2-04-gametest.log : All 712 required tests passed :)  GAMETEST: passed on attempt 1
```

环境：WSL2 Ubuntu-24.04，OpenJDK **21.0.12.1**、Node **22.23.3**、Gradle Wrapper 8.14.5（与 CI runner 同系）。

---

## 4. 门禁一开就抓到的真缺陷（说明 D6 的代价）

| 缺陷 | 位置 | 后果 | 为何此前没人发现 |
| --- | --- | --- | --- |
| 禁区页面**没有文案** | `SteeringFacing.java:40,45,49,53` 引用 `folkways.page.steering{,.zones,.zone,.empty}`，四种语言**一处都没有**；页面标题 `PageKind.boarded(... "folkways.page.steering")` 同样缺 | 书里那个页签与每一行区域都显示**生键**；演示脚本第 2 步会直接撞上 | `test:i18n` 一直在红，没人当门禁看 |
| bench 判据表**未登记我们的原因** | `SteeringRefusal` 3 条 / `HoursRefusal.RESTING` / `Unassigned.Reason` 2 条 不在 `NEVER_HERE` 也不在 `PASSING` | 本地 refusal-coverage 检查红（CI 下该测试自身 `skip`，所以只在本地暴露） | 同上 |

**注**：这正是 M1 差异化卖点（禁限区/作息）自己的文案缺口——不是上游的。修完后 `test:i18n` 由红转绿，且**四语齐全**（R5：新增键做 `zh_cn`+`en_us`；这里按上游惯例一并补齐 `zh_hk`/`zh_tw`，`catalog` 一致性测试要求四语键全）。

---

## 5. 诚实边界

| # | 项 | 说明 |
| --- | --- | --- |
| 1 | **未在真实 GitHub Actions 里跑过** | 本机 Linux 复现四件套全绿是"门禁内容可过"的证据；YAML 在 Actions 上的首跑仍待网络/推送后确认（D13 附带） |
| 2 | **fork 未推送** | 三提交仅在本机 `~/pla/mod`；内存中的 `origin` 为 GitHub，待网络恢复 `git push` |
| 3 | **P2/P3 未做** | 可选依赖构建矩阵（无能源/无 CCB/无 FTB）与 docs 文档门禁留待下一轮（新增 D13/D14） |
| 4 | **未跑上游全套** | 上游 P1 用四模块矩阵（core/vanilla/create/cookery、约 50 分钟）；我们单跑 root `runGameTestServer`（712 个）。覆盖一致、省时 |
| 5 | **`.github/workflows/gametest.yml` 未覆盖上游新增的 `client-smoke`** | 客户端冒烟需 GPU 与 X11 库；w06 OQ-B-4 记 M1 不入门禁——留 M2 visual profile |

---

## 6. 债务与队列的对账（本轮一并做）

ROADMAP 的债务表此前**格式已损坏**（D6/D7 被一个 `|`n|` 拼在两行里），且 `D8`（已修）、`D9`、`D10`、`D11`、`D12` 只在各 VERIFY 报告里出现、**没有回填到表**。本轮把表恢复成干净的一行一债，并补上遗漏项：

| 债务 | 状态变化 |
| --- | --- |
| **D6 无 CI** | ✅ **关闭**（P0+P1 落地） |
| **D7 偶发测试** | ✅ **关闭**（按名单重试一次） |
| D8 `Standing` 误报 | ✅ 补登（此前只在 VERIFY-024，未进表） |
| D9 缺殖民地夹具 | 补登（原仅在 PLAN-005/006 起） |
| D10 只对 5 类原因说话 | 补登（原仅在 VERIFY-031/035） |
| D11 人工验收 | 补登（演示脚本 19 点 + 跨进程存档） |
| D12 `rules-first` 需 L3 | 补登（原仅在 VERIFY-044） |
| **D13 CI P2 未做** | **新增** |
| **D14 CI P3 / docs 无门禁** | **新增**（DoD #6 的"链接/登记检查脚本 0 失败"） |

**队列**（§4）：①②③⑥（模拟）标记为已完成并写明后继；**新增队列 ⑦ = 本轮**；⑤ 保持"待你手动跑"（脚本就绪在 VERIFY-039）。

---

## 7. 下一步

1. **推送 fork**（网络恢复）+ 看 Actions 首跑（P0/P1），把 runner 结果回填本报告；
2. **队列 ⑤**：在你的屏幕上按 [M1-demo-script.md](../demo/M1-demo-script.md) 走 19 个观察点，回填 VERIFY-039——这是 M1 Gate 的最后一块人工拼图（D11）；
3. **P2/P3 门禁**（D13/D14）与**真实上游同步演练 #2**（SYNC-002，上游已到 `b70b948`、含 force-push）。