# VERIFY-005 · 包内容第一批（我们的配置 + FTB 三件套）与端到端复验

```
状态：通过
验证者：DSH 会话
验证日期：2026-10-20
关联：VERIFY-002/003/004；ADR-018（FTB 取舍）；k02（config 口径）
```

---

## 1. 结论

整合包不再是"纯 mod 列表"：**包内现在带 3 份我们自己的服务端配置**（从真实运行里采集，不是手编的键）与 **FTB Quests / Library / Teams** 三件套（任务书的运行基础）。全新实例端到端复验通过：安装器装出 **47 个 mod**、配置落地、FTB Quests 加载、服务端 `Done (20.745s)`；`.mrpack` 重建为 **46 下载 + 4 随包 = 50 条目**。

---

## 2. 包内新增内容

| 新增 | 内容 | 依据 |
| --- | --- | --- |
| `pack/config/plaa_core-server.toml` | 4341 B，实际键如 `[planning] mode/solveThreads`、`[perks] haulingHaste/asceticAppetite`、`[labor] haulReachTicks`… | **来自 `.cache/test-pack-fresh/` 的真实生成**，非手写 |
| `pack/config/plaa_create-server.toml` | 1080 B | 同上 |
| `pack/config/plaa_vanilla-server.toml` | 7135 B | 同上 |
| `pack/mods/ftb-quests.pw.toml` | FTB Quests `2101.1.36`（maven.ftb.dev，sha256 pin） | k04 / ADR-018 |
| `pack/mods/ftb-library.pw.toml` | FTB Library `2101.1.37` | Quests 的前置 |
| `pack/mods/ftb-teams.pw.toml` | FTB Teams `2101.1.11` | **Quests 的 required 依赖** |

索引刷新：**53 个受管文件**（46 个 `.pw.toml` + 4 个我们的 jar + 3 份配置），`pack-refresh -Check` 通过（sha256 `51f1780f…`）。

---

## 3. 一条事实修正（ADR-018）

此前文档写"**FTB Teams 可选**"。实测 `ftb-quests-neoforge-2101.1.36.jar` 的 `META-INF/neoforge.mods.toml`：

```
modId = "architectury"   type = "required"   versionRange = "[13.0.8,)"
modId = "ftblibrary"     type = "required"   versionRange = "[2101.1.36,)"
modId = "ftbteams"       type = "required"   versionRange = "[2101.1.9,)"
modId = "ftbxmodcompat"  type = "optional"
```

→ **Teams 是硬依赖**，不是可选。已在 [ADR-018](../00-charter.md) 与 [k01](../pack/01-modlist.md) 更正为"必装，但**不启用它的权限功能**（权限仍以 PRD-012 为唯一来源）"。

---

## 4. 端到端复验（关键输出）

```
pack.toml HTTP 200
installer exit=0
mods/*.jar = 47
mods/plaa-*.jar = 4
mods/ftb-*.jar = 3（library / quests / teams）
config/plaa_*-server.toml = 3（4341 / 1080 / 7135 B，与 pack 内一致）
日志: "FTB Quests 2101.1.36 (ftbquests)"
Preparing level "installed"
Done (20.745s)! For help, type "help"
```

对照：上一轮（无 FTB、无配置）44 mod / `Done 13.977s`；本轮 47 mod / `Done 20.745s`——增量来自 FTB 三件套，合理，无 FATAL。

`.mrpack` 重建：**50 条目**（46 下载 + 4 随包 overrides），4.9 MB。

---

## 5. 未验证 / 遗留

| # | 项 | 何时补 |
| --- | --- | --- |
| 1 | 配置放 `config/` 还是 `defaultconfigs/`：本次选 `config/`（全局默认，端到端已验证生效）；k02 提到的"新世界默认"语义尚未实测 | 有客户端实例后对比 |
| 2 | 客户端侧仍未测（GUI/渲染/任务书界面） | 人工安装一次 |
| 3 | FTB Quests 的**任务书内容**还没写（`pack/quests/` 为空，只有框架能跑） | k04 的 8 章 57 条任务落地 |
| 4 | 用 maven 直链而非 Modrinth，`packwiz update` 无法追踪新版本 | 稳定后再换 Modrinth 元数据（FTB 不在 Modrinth，需人工跟版） |
