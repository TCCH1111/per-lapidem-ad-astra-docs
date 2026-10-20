# VERIFY-006 · 客户端实测（Prism CLI + 我们自己的实例）

```
状态：通过（客户端启动、四 mod 加载、成功进入服务器）
验证者：DSH 会话 + 用户桌面（GUI 实际运行）
验证日期：2026-10-20
关联：VERIFY-002/004/005（服务端与分发链）；k00 §10.1
环境：Windows 11 · Prism Launcher（便携 D:\Games\PrismLauncher）· JDK 21.0.7 · AMD RX 5700 XT
```

---

## 1. 结论

用 **Prism Launcher CLI** 走通了客户端链路：手工建实例 → `packwiz-installer` 按包安装（client 侧 50 个 mod，含我们 4 个 `plaa_*`）→ Prism `-l … -s 127.0.0.1:25565` 启动 → 客户端加载全部四个 `plaa_*` 模组 → **成功加入服务端**（报错为零，只有资源告警）。

```
客户端: JVM identified as Microsoft OpenJDK 64-Bit Server VM 21.0.7+6-LTS
        Per Lapidem ad Astra · Core 0.1.0 (plaa_core)
        Per Lapidem ad Astra · Vanilla 0.1.0 (plaa_vanilla)
        Per Lapidem ad Astra · Create 0.1.0 (plaa_create)
        Per Lapidem ad Astra · Modular Golems 0.1.0 (plaa_modulargolems)
服务端: [18:07:38] TC_1111 joined the game
```

---

## 2. 怎么做的（含踩到的坑，全部可复现）

| 步 | 做法 | 坑 / 结论 |
| --- | --- | --- |
| 1 | 定位 Prism：便携版在 `D:\Games\PrismLauncher`（实例在 `instances/`，不在 `%APPDATA%`） | 一开始盯错目录，白等 5 分钟 |
| 2 | `prismlauncher.exe -I <pack>.mrpack` | **认不出 `.mrpack`**（日志 `Can't Identify`）；改名 `.zip` 后才被识别为 Modrinth 包 |
| 3 | `.zip` 导入 | 会解包到 `instances/.tmp/…` 然后**停在 GUI 确认框**——无头环境点不了 |
| 4 | **改为手建实例**：`instances/PLAA-test/{mmc-pack.json, instance.cfg}` 指定 `net.minecraft 1.21.1` + `net.neoforged 21.1.264` | 可控，且不依赖导入器 |
| 5 | `java -jar packwiz-installer-bootstrap.jar -g -s client http://localhost:8086/pack.toml` | ⚠️ **`-g` 是 `--no-gui`，不是"游戏目录"**：它装到了**当前工作目录**（仓库根），要事后移进 `.minecraft/`。正确做法：`cd` 到实例的 `.minecraft` 再跑 |
| 6 | `prismlauncher.exe -l PLAA-test -s 127.0.0.1:25565 -a TC_1111` | Prism 是**单实例应用**：已有 Prism 在跑时，`-l` 会被转发而不生效 → 必须先全部关掉 |
| 7 | 账号 | Prism 的 MSA 令牌一度 `Bad Request`（刷新失败）；注入的 **Offline 账号会被 Prism 改写 accounts.json 时丢弃**。令牌恢复后反而正常 |
| 8 | 服务端 | WSL 里起的服务端 **25565 从 Windows 连不通**（8086 却通）→ 客户端测试改为**在 Windows 侧起服务端**（`win_args.txt`，`Done 1.687s`） |

---

## 3. 环境与产物

| 项 | 值 |
| --- | --- |
| 实例 | `D:\Games\PrismLauncher\instances\PLAA-test`（`mmc-pack.json` 指定 MC 1.21.1 + NeoForge 21.1.264） |
| 客户端 mods | **50**（46 下载 + 4 随包 `plaa_*`），含 FTB Quests / Library / Teams |
| 客户端 config | 3 份我们的服务端配置（从 `pack/config/` 装出） |
| 服务端 | Windows 侧 `.cache/test-server`（44 mod，端口 25565，online-mode=false），`Done (1.687s)` |
| 客户端启动耗时 | 54.8s（ModernFix 记录），首帧前后无崩溃 |

---

## 4. 已知缺陷（这一轮新发现，值得修）

| # | 现象 | 影响 | 判断 |
| --- | --- | --- | --- |
| 1 | 客户端资源加载出现 **41 条 `Unable to load model`**（`minecraft:pitchfork`、`nightmarescythe`、`shellmace`、`soulsaber`、`skullbreaker`、`spiderbite`、`nuthammer`、`executionersgreatax` 等） | 这些物品在客户端会**不可见/紫黑块** | 大概率来自某个武器类 mod 只注册物品没带模型；需要定位是哪个 mod（按 item id 反查注册者） |
| 2 | 服务端少了 FTB 三件套（`.cache/test-server` 是加 FTB 之前的快照），客户端却有 | 本机测试能连，但**包与测试实例不一致**；正式发布前应让服务端实例也按包重装 | 用 `.cache/test-pack-fresh` 走 installer 重建即可 |
| 3 | 加入瞬间 `Can't keep up! Running 3075ms behind` | 首帧资源加载导致的瞬时卡顿 | 观察项，非阻塞 |
| 4 | Xaero 地图版本检查 `Read timed out` | 无网络/被墙 | 无功能影响 |

---

## 5. 复现命令（要点）

```powershell
# 1) 关掉所有 Prism（单实例限制）
Get-Process prismlauncher | Stop-Process -Force
# 2) 实例目录就绪后，在 .minecraft 里装包（注意 -g 只是 --no-gui）
cd D:\Games\PrismLauncher\instances\PLAA-test\.minecraft
java -jar <packwiz-installer-bootstrap.jar> -g -s client http://localhost:8086/pack.toml
# 3) 服务端在 Windows 侧起（WSL 的 25565 从 Windows 连不通）
java @user_jvm_args.txt @libraries/net/neoforged/neoforge/21.1.264/win_args.txt nogui
# 4) 启动客户端并直连
prismlauncher.exe -l PLAA-test -s 127.0.0.1:25565 -a TC_1111
```
