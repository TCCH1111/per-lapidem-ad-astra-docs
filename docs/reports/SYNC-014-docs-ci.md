# SYNC-014 · docs 仓库接上 CI，四次运行才变绿

```
状态：通过（run 42171675065 = success）
验证者：DSH 会话
验证日期：2026-11-06
关联：D14、SYNC-013（pack-lint）
工作流：.github/workflows/docs.yml
```

---

## 1. 做了什么

docs 仓库此前 **Actions 已启用、workflow 零个**。现在每次 push / PR 都会跑两道门禁：

| 门禁 | 内容 | 本地基线 |
| --- | --- | --- |
| `link-check` | 144 个 Markdown、**1578 条**本地链接 | ✅ |
| `pack-lint` | 68 个文件哈希、索引完整性、CRLF、62 个 `.pw.toml` 字段 | ✅ |

---

## 2. 前三次全红，每次抓到一个真问题

| 运行 | 失败点 | 真正的问题 | 处理 |
| --- | --- | --- | --- |
| #1 | link-check | 有文档链接到 `reference/...`，该目录被 **gitignore**（只放行 README）→ **在我机器上存在、干净克隆里不存在** | 改成路径文字 + 注明"本地快照，未入库" |
| #2 | pack-lint | 脚本用 Windows 分隔符拼相对路径 → Linux 上全对不上 | 改用 `[System.IO.Path]::GetRelativePath` |
| #3 | pack-lint | 工作流以相对路径调用脚本，`$PackDir` 保持相对 → `GetRelativePath` 返回**绝对**路径 | 目录先 `Resolve-Path` 成绝对 |

**第四次的失败原因在我自己**：同一行路径代码在脚本里出现两次（写索引 + 校验），我上一次只改了第一处。
把剩下那处也改掉 → **#4 绿**。

---

## 3. 这轮最值得记的一件事

**这三条都不是"CI 配置问题"，是产物/脚本的真缺陷**：

- 那个 `reference/` 链接，在此之前**一直**是断的——只是没人从干净克隆看过；
- 两个路径 bug 只会在 Linux 上出现，而我们的 CI 正是第一次在 Linux 上跑这两个脚本。

> 门禁的价值不是"通过"，而是**它失败时指出的东西通常是真的**。

---

## 4. 现状

```
run 42171675065 → success
https://github.com/TCCH1111/per-lapidem-ad-astra-docs/actions/runs/42171675065
```

工作流文件：`.github/workflows/docs.yml`（push / pull_request / 手动触发）。

---

## 5. 还没做的（D14 的另一半）

| 未接的 CI | 说明 |
| --- | --- |
| **fork 仓库的构建与游戏测试** | `./gradlew build` + `runGameTestServer` 需要 NeoForge 依赖与较长时间；fork 仓库目前 **没有** workflow |
| 文档登记检查（每个新报告必须出现在 README） | 现在是手工维护，可脚本化 |
| AC 编号门禁 | 同上 |

**D14 现在算"减半"**：docs 侧两道门禁已上线并验证；代码侧（build + gametest）仍未接。
