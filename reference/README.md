# reference/ — 基底只读参考副本

```
状态：已定稿（事实记录）
负责人：整合包维护者
最后更新：2026-10-19
上游依据：docs/workflow/01-agent-roles-and-tools.md R-ROLE-4（reference/ 必须记录来源与 commit）；ADR-021（基线前移）
```

本目录**不入库（仅本文件入库）、只读、升级时整体替换**（[w01 §3.3](../docs/workflow/01-agent-roles-and-tools.md)）。
不要在这里 `npm install` / `gradlew build`；可写的 fork 工作树在 **WSL2 Ubuntu-24.04 的 `~/pla/mod`**（独立 git 仓库，分支 `main`，remote `upstream` → GitHub；[d12 §4](../docs/design/12-fork-strategy.md)、[ADR-022](../docs/00-charter.md)）。Windows 侧的临时克隆 `../mod/` 已于 2026-10-19 删除；从 Windows 访问用 `\\wsl.localhost\Ubuntu-24.04\home\tcch1111\pla\mod` 或 `tools/wsl-run.sh`。

## 内容与来源

| 路径 | 来源 | 版本 / commit | 获取日期 | 状态 |
| --- | --- | --- | --- | --- |
| `folkways-67f28b0/` | `git archive 67f28b0`（取自 fork 仓库；上游 `master`，`https://github.com/IzakyL/folkways`） | **`67f28b0`**（2026-10-18T09:06Z；含 `0af84f0` 四模块拆分） | 2026-10-19 | **当前基线**。新写的 `文件:行号` 引用一律指向这里 |
| `folkways-master/` | `folkways.zip` 解压 | `f42e3c16e1ba15e49da9d5843ee1bf9fd06c391c`（2026-10-17T13:13Z，单 jar 结构） | 2026-10-17 | **旧快照，仅供过渡**：`docs/research/01~05`、w05、w06 的既有引用仍指向它；迁移表见 `docs/research/10-upstream-delta-f42e3c1-67f28b0.md`，迁移完成后删除本目录与 zip |
| `folkways.zip` | GitHub 归档（zip 注释即 commit SHA，`unzip -z` 可见） | 同上 | 2026-10-17 | 随 `folkways-master/` 一同删除 |
| `tyk-construction-prd-zh.txt` | `https://tyksworks.com/posts/construction-prd-zh/` | — | 2026-10-17 | PRD 格式样例（[w00](../docs/workflow/00-ai-workflow.md)） |

**基线标签**（[d12 §4](../docs/design/12-fork-strategy.md)）：`upstream-base-67f28b0-20261019`，已打在 WSL 仓库 `~/pla/mod`。标签、本表与 d12 §4 三处必须一致。

## 升级流程

[w01 §5](../docs/workflow/01-agent-roles-and-tools.md)：在 WSL 内 `git -C ~/pla/mod fetch upstream --prune`（WSL 侧直连，无需绕 Windows 的 git 代理）→ 新快照 `git -C ~/pla/mod archive --format=tar <sha> | tar -x -C /mnt/d/wsl/pla/reference/folkways-<sha7>/` → 重跑 `docs/research/01~05` 差异（照 r10 的做法）→ 更新本表与 d12 §4 → 旧快照待引用迁移完成后删除。
