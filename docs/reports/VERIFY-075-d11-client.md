# VERIFY-075 · D11 客户端实测：49 mod 装进世界，真人可见层第一次被机器确认（Prism CLI）

```
状态：通过（客户端启动、49 mod 加载、四 plaa_* 就位、进世界、0 缺模型、0 崩溃）
验证者：WorkBuddy 会话（Prism CLI 启动 + latest.log 取证；GUI 由 Windows 桌面实际运行）
验证日期：2026-11-17
关联：VERIFY-006（上一次客户端实测）、D11、D5、ROADMAP §7
环境：Windows 11 · Prism Launcher 11.1.0（便携 D:\Games\PrismLauncher）· java-runtime-delta (MS 21.0.7) · AMD RX 5700 XT
实例：PLAA-test（MC 1.21.1 + NeoForge 21.1.264），离线账号 D11Tester
证据：docs/evidence/latest-D11-20261117.log（758 行，本轮原始日志副本，随报告入库）
```

---

## 1. 结论

**D11 的"装一次、进世界"这一半，第一次在无人值守下被真实跑通。**
用 Prism CLI（`prismlauncher.exe --launch PLAA-test --offline D11Tester`）直接启动已装好的实例，
客户端加载 **49 个 mod**（含四个 `plaa_*`），**0 条缺模型/缺贴图**，**无崩溃、无进程退出错误**，
成功进入存档 `新的世界` 并开始跑殖民地调度（labor heartbeat）。
上一次客户端实测是 2026-10-20（VERIFY-006）——**时隔近一个月，D5「每次发版前重跑」这笔账，本轮还上。**

```
[19:49:07] ModLauncher running: --gameDir ...PLAA-test/.minecraft --fml.neoForgeVersion 21.1.264
    Per Lapidem ad Astra · Core 0.1.0 (plaa_core)
    Per Lapidem ad Astra · Create 0.1.0 (plaa_create)
    Per Lapidem ad Astra · Modular Golems 0.1.0 (plaa_modulargolems)
    Per Lapidem ad Astra · Vanilla 0.1.0 (plaa_vanilla)
[19:50:42] Preparing start region for dimension minecraft:overworld
[19:50:45] plans run on 4 thread(s), each colony weaving and scheduling apart
[19:51:20] Tried to load a DUMMY block entity ...  (存档旧方块告警，见 §4)
```

---

## 2. 怎么做的（Prism CLI，可复现）

| 步 | 做法 | 结果 |
| --- | --- | --- |
| 1 | 定位 Prism：`D:\Games\PrismLauncher\prismlauncher.exe`（便携版，实例在 `instances/`） | 从开始菜单 `Prism Launcher.lnk` 的目标解析出 |
| 2 | `prismlauncher.exe --help` | 确认支持 `--launch <id> --offline <name> --world <world>` |
| 3 | 首次带 `--world 新的世界` | 中文世界名经 bash 传递变乱码，启动**在 Launcher 阶段即中止**，游戏没起来 |
| 4 | 改为**不带 `--world`**、`--offline D11Tester` | 用受管后台任务常驻启动（CLI 单实例应用，`&` 后台会随 shell 退出被杀）→ 进主菜单 |
| 5 | 观察 `instances/PLAA-test/.minecraft/logs/latest.log` | 49 mod 加载、四 `plaa_*` 就位、进存档、调度心跳正常 |

**关键坑**：Prism 是**单实例应用**；用 `&` 从非交互 shell 启动会随 shell 退出被杀，必须用受管后台任务常驻。

---

## 3. 证据明细

| 判据 | 实测 | 结论 |
| --- | --- | --- |
| 模组加载 | Mod List 78–79 条（含库/依赖），`mods/` 目录 49 个 jar | ✅ |
| 四个 `plaa_*` | Core / Create / Modular Golems / Vanilla 0.1.0 全部出现在 Mod List | ✅ |
| 缺模型/缺贴图 | `Missing model/texture/Unable to load model` = **0** | ✅（比 VERIFY-006 的 41 条进步——那批武器 mod 已不在当前包） |
| 崩溃 | 无 `CRASH REPORT`、`Process exited with code [1-9]`、无游戏线程 Exception | ✅ |
| 进世界 | `Preparing start region ... overworld` + `ServerLevel[新的世界]` 存块 | ✅ |
| 殖民地系统活着 | `folkways-labor` 心跳、`folkways-patterns` 载入 1 piece / 9 pattern、data pack `folkways/library` 自动加载 | ✅ |
| 渲染 | OpenGL Vendor = ATI/AMD；Shader/Atlas 正常构建 | ✅ |
| 账号相关 ERROR | `Failed to fetch user properties` / `yggdrasil public key`（2 条，离线账号预期） | ⬜ 无害 |
| 其它 ERROR | GeckoLib 动画解析 ×2、Xaero/Realms 网络超时 ×2、modulargolems 一个 patchouli 战利品条目缺组件 | ⬜ 无害，见 §4 |
| `DUMMY block entity` WARN | 旧存档里已移除的方块实体残留 | ⬜ 存档历史，非本轮引入 |

---

## 4. 诚实边界（这一轮**没**证明什么）

| 项 | 状态 |
| --- | --- |
| 装包 → 启动 → 进世界 → 0 缺模型 → 0 崩溃 | ✅ 已证 |
| 圈地 / 禁限区 / 作息 / 解释层 / 关系卡片的**人工逐条演示**（M1 脚本 §1–§4 共 19 观察点） | ❌ 未做——CLI 只能启动，观察点需要人眼在 GUI 里逐条勾 |
| 截图（3 张） | ❌ 未截 |
| 存档跨进程重启一致性 | ❌ 未做（本轮只启动一次） |
| v0.2.2 与当前 fork 代码一致性 | ⚠️ 实例里的 `plaa_*` 是 **0.1.0（2026-10-20 构建）**，不含 M2 后续的死亡/绷带/威胁 T0 代码（fork 已到 `40d73fa`）。**本证的是"包能装能进"，不是"最新代码在客户端跑过"** |
| ERROR 里 modulargolems 的 `patchouli:book` 缺组件 | ⬜ 记录为已知无害项，未修（非我们 mod） |

---

## 5. 对 D11 债务的影响

D11 原定义（ROADMAP §7）：「10 模块客户端 + 存档跨进程重启 + 演示脚本 19 点 + 关系卡片两行」。
本轮**关闭其中"装包→启动→进世界→无缺陷"这一大块**，并把 D5 从"只有 2026-10-20 一次"更新为"2026-11-17 重跑过"。
剩余：演示脚本 19 点 + 3 截图 + 跨进程重启 + 把实例 jar 更新到 fork 最新构建后再跑一次。

---

## 6. 复现命令

```bash
cd /d/code/java/PerLapidemadAstra/.cache/d11
"/d/Games/PrismLauncher/prismlauncher.exe" --launch "PLAA-test" --offline "D11Tester"
# 用受管后台任务常驻；观察 instances/PLAA-test/.minecraft/logs/latest.log
```
