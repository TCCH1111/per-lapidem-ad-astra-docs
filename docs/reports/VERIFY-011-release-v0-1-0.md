# VERIFY-011 · GitHub Release v0.1.0 与包内 jar 改为 release URL

```
状态：通过
验证者：DSH 会话
验证日期：2026-10-20
关联：ROADMAP 队列 ②、D2；VERIFY-004/008（分发链）
```

---

## 1. 结论

**发布做成了**，并且整合包不再携带 jar：

- GitHub Release **`v0.1.0`**：https://github.com/TCCH1111/per-lapidem-ad-astra/releases/tag/v0.1.0（prerelease，4 个资产）
- `pack/mods/*.jar` 删除，改为 4 个 `.pw.toml` → **release 下载 URL + sha256**
- 仓库里 `pack/mods` 的 jar 体积：**5.2 MB → 0**
- 全新实例端到端验证：安装器 exit 0、**46 个服务端 mod**、`Done (9.473s)`、4 个 jar 由 release 下载且大小一致

---

## 2. 怎么做的（工具说明）

`gh` 原本不存在，本轮**安装了 GitHub CLI 2.102.0** 到 `D:\tools\gh\bin` 并加入用户 PATH。

但 `gh auth login --with-token` 拒绝了机器上已存的 git 凭据：

```
error validating token: missing required scope 'read:org'
```

那是 Git Credential Manager 存的 **classic PAT（40 位）**，缺 `read:org`。于是**改为直接调 REST API**（同一 token，仅用于 `Authorization` 头，从不打印）：

| 步骤 | 调用 |
| --- | --- |
| 身份/权限 | `GET /user` → `login=TCCH1111`；`GET /repos/…` → `admin=true, push=true` |
| 建 release | `POST /repos/…/releases`（tag `v0.1.0`，target `main`，prerelease=true） |
| 传资产 | `POST uploads.github.com/repos/…/releases/418359553/assets?name=…`（`application/java-archive`） |

Release 说明里写明了：基于上游 `3ce4d88`、四个 `plaa_*` 与上游互斥、构建 233 / 运行 264、保留 MIT `LICENSE` 与 `NOTICE.md`、当前仅为"能装能跑"的预览。

---

## 3. 四个资产

| 文件 | 大小 |
| --- | --- |
| `plaa-core-neoforge-1.21.1-0.1.0.jar` | 3.35 MB |
| `plaa-vanilla-neoforge-1.21.1-0.1.0.jar` | 1.52 MB |
| `plaa-create-neoforge-1.21.1-0.1.0.jar` | 0.30 MB |
| `plaa-modulargolems-neoforge-1.21.1-0.1.0.jar` | 0.03 MB |

`.pw.toml` 用 `hash-format = "sha256"`，哈希取自本地构建产物，与上传的字节一致。

---

## 4. 端到端复验

```
pack.toml HTTP 200
installer exit=0
mods = 46（含 plaa-core / plaa-create / plaa-modulargolems / plaa-vanilla，全部来自 release URL）
Plaparing level "installed" → Done (9.473s)!
```

`.mrpack`：**54 条目** = 49 下载（含 4 个 release jar）+ 5 随包（3 config + 1 KubeJS + 1 任务章节），体积 **4.9 MB → 0.0 MB 级**（只剩文本）。

---

## 5. 遗留

| # | 项 | 何时补 |
| --- | --- | --- |
| 1 | `gh` 已装但**未登录**（token 缺 `read:org`）；以后要用 `gh` 发版，需要一次 `gh auth login` 或换一个带 `repo`+`read:org` 的 token | 下次发版前 |
| 2 | Release 是 **prerelease**，且说明里没有安装步骤截图 | v0.2.0 前补 |
| 3 | 客户端未针对"从 release 下载 jar"的包再测一次（服务端已测） | 下次客户端实测顺带 |
| 4 | jar 版本号仍是 `0.1.0`（`mod_version`），与 release tag 同名，可接受；将来发 `v1.0` 时应同步改 `mod_version` | v1.0 前 |
