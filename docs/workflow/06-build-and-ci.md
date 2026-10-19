# 构建环境、依赖与 CI 规格（w06）

```
状态：草稿
负责人：工程 agent（文档）
最后更新：2026-10-19（首次 Windows 构建实测：`npm ci` 因 `EBADPLATFORM` 失败，见 §1.2/§1.3）
上游依据：reference/folkways-67f28b0/（基线 67f28b0，只读；本文的 `文件:行号` 已按 docs/research/10-upstream-delta-f42e3c1-67f28b0.md 迁移）、ADR-021
下游影响：M1 实施任务单、[d12 §6](../design/12-fork-strategy.md)、[w03 测试与验收](03-test-and-acceptance.md)、[k03 性能预算](../pack/03-performance-budget.md)
```

> 本文只回答"**怎么把项目 build 起来、怎么让 CI 替我们守住它**"，不含实现代码。
> 所有上游事实都带 `reference/folkways-67f28b0/` 内的 `文件:行号`；**推断一律标 ⚠️** 并写明"待 M1 第一次 build 时确认"。

---

## 0. 为什么单独写这一份

M1 的第一道坎不是玩法，而是**能不能构建**。上游 `build.gradle` 的 `lib()` 闭包要求仓库里存在 `.blockwright/mods.json`，而它**不在版本库里**（`.gitignore:36`），必须先跑一条 Node 命令生成；同时 `compileOnly lib("sable")`（`mods/core/build.gradle:16`）意味着**编译期需要真实 jar**。

没有这份规格，实现 agent 会在"缺 jar / 版本不配套 / 该不该把 mods.json 提交"上耗掉一整天，然后在第一次 `gradlew build` 失败时误判为"上游坏了"。

**本文的三个结论先放在这里**：

1. `.blockwright/mods.json` **不是手写的**，是 `npm run setup` 从 `blockwright.toml` **派生**出来的；唯一真源是 `blockwright.toml`（§2）。
2. **R-FK-12 的正确口径**：**运行期**零可选依赖（缺了也能玩），**编译期**依赖由 `blockwright.toml` 统一提供（不是"什么都不装也能 build"，那句会误导实现者）（§3.4）。
3. 上游 CI **只跑构建 / 类型检查 / 单元测试**，488 个游戏测试与 44 个 e2e **完全不在流水线里**（§4.1）——所以"层 1 进 CI"是我们相对上游的**工程增量**，也是 M1 的验收项之一。

> **本文与任务级拆解的分工**：本文定义"**环境与流水线怎么搭、怎么判**"；"**M1 具体派哪些活、每条 AC 怎么验**"见 [w05 M1 任务拆解](05-m1-task-breakdown.md)。两者冲突时以 [d12](../design/12-fork-strategy.md) 的门禁口径为准。

---

## 1. 环境基线

### 1.1 硬要求

| 项 | 要求 | 依据 |
| --- | --- | --- |
| JDK | **21**（toolchain 21，`options.release=21`） | `gradle.properties:10`、`build.gradle:100-103`、`gradle/mod.gradle:62-65` |
| Node.js | **≥ 22.14** | `CONTRIBUTING.md:6-12` |
| Gradle | **Wrapper 8.14.5**（用 `./gradlew`，不要用系统 `gradle`） | `gradle/wrapper/gradle-wrapper.properties`（[r05 §1.1](../research/05-engineering-and-tooling.md)） |
| MC / Loader | **1.21.1 / NeoForge 21.1.233** | `gradle.properties:5-7` |
| Gradle JVM 内存 | `-Xmx1G`（daemon 默认） | `gradle.properties:1` |
| 游戏测试 JVM 内存 | `-Xmx2G`（Blockwright 实例） | `blockwright.toml:4` |
| 构建插件 | `net.neoforged.moddev` 2.0.141 + `java-library` + `maven-publish` | `build.gradle:1-3`、`mods/core/build.gradle:1-5`（插件声明下放子项目） |
| 插件仓库 | `pluginManagement` 含 gradlePluginPortal / mavenCentral / **neoforged releases** | `settings.gradle:1-7` |
| 依赖仓库策略 | `RepositoriesMode.PREFER_PROJECT`（项目级 `repositories` 优先） | `settings.gradle:9-16` |
| 编码 | **UTF-8**（`options.encoding`） | `build.gradle:101`、`gradle/mod.gradle:63` |
| 换行 | 仓库不强制 CRLF/LF，但**禁止 Tab 与行尾空白**（`lintScaffold` 挂到 `check`） | `build.gradle:105-133`（check 另依赖子项目） |

**R-BLD-1**：构建环境的版本以本表为准；**升级 JDK / NeoForge / Gradle 必须单独一个提交**，附"为什么升、要重跑哪些层"。

### 1.2 平台现实（Windows 开发机）

| 能力 | Windows | Linux x64 | 依据 |
| --- | --- | --- | --- |
| `./gradlew build` / `check` | ✅ | ✅ | `CONTRIBUTING.md:12`（"Building the mod works anywhere Gradle does"） |
| `runGameTestServer`（无头） | ⚠️ 理论可、仓库未验证 | ✅ | [w03 §2](../workflow/03-test-and-acceptance.md)、[r05 §2](../research/05-engineering-and-tooling.md) |
| e2e / 视觉 / 基准 / 模糊（Blockwright） | ❌ | ✅（**仅 Linux x64**） | `CONTRIBUTING.md:10-12` |
| `npm run typecheck` / `test:unit` / `test:i18n` | ✅ | ✅ | `package.json:8-10` |
| `npm ci` / `npm install`（→ `npm run setup` 的前提） | ❌ **直接失败（2026-10-19 实测）**：`@izakyl/blockwright-client@0.1.0-alpha.1` 的 package.json 声明 `os: ["linux"], cpu: ["x64"]`，npm 报 `EBADPLATFORM` 拒绝安装。`npm ci --force` 可装上（106 包），**但 `dist/blockwright` 是 Linux x64 的 ELF 可执行文件而非 JS**：`npm run setup` 在 Windows 下 cmd.exe 无法执行它，`node dist/blockwright` 则报 `SyntaxError: Invalid or unexpected token`（文件首字节 `ELF`）。**结论：`npm run setup` 在 Windows 不可能运行，`.blockwright/mods.json` 只能在 Linux x64 生成** | ✅ | 本机日志 `.cache/logs/build-upstream-67f28b0.log`、`…-force.log`；npm registry 元数据（六个 `@izakyl/blockwright-*` 包里仅 `client` 与 `mcp` 声明 `os: linux`） |

> **对 R-BLD-2 的影响（2026-10-19 已确认）**："层 0 在 Windows 通过"**只对 Gradle/测试命令成立，不对依赖获取成立**——`CONTRIBUTING.md:12` 的"Building the mod works anywhere Gradle does"没有把 `npm run setup` 的平台限制说出来。又因 `mods.json` 里是本机路径（§2.3 ⚠️），`gradlew build` 必须与 `npm run setup` 在**同一侧**运行 → Windows 开发机上，**整条 B-3..B-6 都要在 WSL2（或 CI / Linux 机）里跑**，Windows 侧只剩编辑代码与 `test:unit`/`test:i18n`（这两条不依赖 Blockwright）。OQ-B-7 由此升级为必答。

**R-BLD-2**：**层 0**（构建 + 类型 + 单元 + i18n）必须能在**没有网络、没有 GPU 的 Windows** 上通过——这是 [w03 R-T-1](03-test-and-acceptance.md) 的构建侧重申。

### 1.3 我们仓库的现状（诚实前置）

截至 2026-10-18，工作区根目录只有 `docs/`、`reference/` 与临时材料，**没有任何构建文件**（无 `build.gradle` / `settings.gradle` / `gradle/` / `package.json`）。

因此 M1 的第一次构建包含"**初始化工程**"这一步，而不是"直接 build 上游"：

| 步骤 | 做什么 | 完成判据 |
| --- | --- | --- |
| B-1 | 以上游为基线创建工程骨架（`settings.gradle`、`build.gradle`、`gradle.properties`、wrapper） | `./gradlew --version` 报 8.14.5 |
| B-2 | 把坐标改成我们的。**按基线 67f28b0 重写（[r10 §2](../research/10-upstream-delta-f42e3c1-67f28b0.md)）**：`gradle.properties` 已**没有** `mod_id` / `archives_base_name`，modid 与产物名由每个子项目 `mods/<name>/build.gradle` 顶部的 `ext.modId` / `ext.modName` 设定（`gradle/mod.gradle` 据此展开 `neoforge.mods.toml` 与 `archivesName`）；要改的是四个子项目的这两行 + `gradle.properties` 的 `maven_group` + `settings.gradle` 的 `rootProject.name`，以及 `blockwright.toml` 的 `[mods.folkways_*]` 四个条目与 `path` 通配。**取值待 [d12 OQ-6](../design/12-fork-strategy.md) 由人类定**，定之前先用未改动的上游跑通 B-3..B-6 | 四个产物名与 modid 按 OQ-6 结论 ⚠️ |
| B-3 | 落 `blockwright.toml`（见 §2.2） | `npm run setup` 成功并生成 `mods.json` |
| B-4 | 跑通 `./gradlew build` | `build/libs/*.jar` 产出 |
| B-5 | 跑通 `./gradlew check` | 无 Tab / 行尾空白（`lintScaffold`） |
| B-6 | 跑通 `./gradlew runGameTestServer`（空测试集也算过） | `run/gametest/` 下有日志、退出码 0 |

**R-BLD-3**：B-1..B-6 是 M1 的**门禁步骤**，任何一项没过，不得进入玩法实现。

⚠️ B-2 的产物名与 modid 迁移细节（`processResources` 里的 `neoforge.mods.toml` 展开、`assets/<ns>/lang` 目录）**待 M1 第一次 build 时确认**。

**首次构建记录（M1 时填写，用于把本文的 ⚠️ 逐条落实）**：

| 日期 | 机器 / OS | JDK | Node | 步骤 | 结果 | 耗时 | 备注（报错原文） |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 2026-10-19 | 开发机 / Windows 10 Pro 19045 | Liberica 21（`JAVA_HOME`；PATH 上另有 Temurin 25） | 24.21.0 / npm 11.19.0 | B-3 前置 `npm ci`（上游 **67f28b0 未改动**，`mod/`） | **失败** | 2 s | `npm error code EBADPLATFORM` / `Unsupported platform for @izakyl/blockwright-client@0.1.0-alpha.1: wanted {"os":"linux","cpu":"x64"} (current: {"os":"win32","cpu":"x64"})` |
| 2026-10-19 | 同上 | 同上 | 同上 | B-3 `npm ci --force` → `npm run setup` | **安装成功、setup 失败** | 12 s | `npm run setup`：cmd.exe 报"'node_modules' 不是内部或外部命令"；`node node_modules/@izakyl/blockwright-client/dist/blockwright mods sync --config blockwright.toml`：`SyntaxError: Invalid or unexpected token`，首行内容为 `ELF`（Linux x64 可执行文件）。B-4..B-6 未能开始 |
| 2026-10-19 | 同上 → **WSL2 Ubuntu-24.04**（`D:\wsl\ubuntu-24.04`，WSL 2.7.3） | OpenJDK **21.0.12.1**（apt `openjdk-21-jdk-headless`） | **22.23.3** / npm 10.9.9 | B-W1..B-W4（装发行版、junction、`system`、`verify`） | **通过** | 装发行版 ~3 min；`system` 2.5 min | 坑均已固化进 `tools/wsl-*.sh`：WSL NAT 下宿主网关不应答 DNS → 静态 223.5.5.5/8.8.8.8（⚠️ 解析结果落在 198.18.x.x fake-ip 段，推测宿主有 TUN 代理，流量实际经代理）；`wsl.exe` 直出丢字节；`--` 后参数被重拼；MSYS 路径转换 |
| 2026-10-19 | WSL2 Ubuntu-24.04（ext4 `~/pla/mod`，上游 **67f28b0 未改动**） | OpenJDK 21.0.12.1 | 22.23.3 / npm 10.9.9 | B-3 `npm ci` → `npm run setup` | **通过** | 24 s + ~1 min | 106 包；`mods: 23 synced into …/.blockwright/mods.json`（真实形状见 §2.3） |
| 2026-10-19 | 同上 | 同上 | 同上 | B-4 `./gradlew build --no-daemon` | **通过** | **9 min 45 s**（含下载 Gradle 8.14.5 与 NeoForm 产物） | 30 个任务；产物 `build/libs/folkways-{core,vanilla,create,modulargolems}-neoforge-1.21.1-0.1.0.jar` + `build/deps/ldlib2-neoforge-1.21.1-2.2.37-all.jar`；sha256 与上游 nightly 不同（大小几乎一致；Gradle jar 默认不可复现归档，预期现象） |
| 2026-10-19 | 同上 | 同上 | 同上 | B-5 `check`（含 `lintScaffold`，随 `build` 执行） | **通过** | 含于 B-4 | 日志有 `> Task :check`，无 Tab/行尾空白告警。⚠️ 未单独运行 `./gradlew check` |
| 2026-10-19 | 同上 | 同上 | 同上 | B-6 `./gradlew runGameTestServer` | **通过** | **3 min 16 s** | `647 GAME TESTS COMPLETE IN 21.77 s` / `All 647 required tests passed`（根工程聚合 core+vanilla+create；日志 `.cache/logs/wsl-gametest-inner.log`、WSL `~/pla/mod/run/gametest/logs/latest.log`） |
| 2026-10-19 晚 | 同上，基线 **3ce4d88**（ADR-025 前移后，未改动） | 同上 | 同上 | B-3..B-5（`npm ci` → `setup` → `build`） | **通过** | 32 s（依赖已缓存） | 四个 jar 重新产出（core 3509781 B、create 308960 B…） |
| 2026-10-19 晚 | 同上 | 同上 | 同上 | B-6 `runGameTestServer` 第 1 次 | **651 个测试，1 失败** | 52 s | 失败：`folkways:onefoodcannotfeedhalfofapair`（`mods/vanilla/src/gametest/.../pasture/PastureBreedingGameTests.java:137`，`java.util.NoSuchElementException`）。该测试在 67f28b0 也存在且当时通过 → 疑似**非确定性**（取食/配对竞争），第 2 次运行结果见下一行；若复现则属上游 bug，按 d12 §6 评估是否反哺。**T3 的基线判据以本表为准**（PLAN-001 R1-06） |
| 2026-10-19 晚 | 同上 | 同上 | 同上 | B-6 `runGameTestServer` 第 2 次（同一代码，无改动） | **通过：651/651** | 55 s | 确认 `onefoodcannotfeedhalfofapair` 为**非确定性失败**（1/2 次）。**基线判据**：651 个测试，允许该测试偶发失败、重跑即过；其他任何失败视为回归。CI（P1）需对它配重试或标记 `@GameTest(required = false)` 的等价物——列入 R-BLD-11 的实现注意项，并考虑向上游报告 |

> **R-BLD-3 结论（2026-10-19）**：B-1..B-6 在上游原状 67f28b0 上全部通过（WSL 侧）。B-2（改坐标）按 [ADR-023](../00-charter.md) 单独计划：[PLAN-001](../plans/PLAN-001-b2-modid-rename.md)。

### 1.4 风格与编码约定（构建期强制）

| 约定 | 执行者 | 失败表现 |
| --- | --- | --- |
| 禁止 Tab | `lintScaffold`（`build.gradle:105-128`） | `GradleException("Tab character in <file>:<line>")` |
| 禁止行尾空白 | 同上 | `GradleException("Trailing whitespace in <file>:<line>")` |
| 排除目录 | `.gradle/`、`build/`、`run/`、`node_modules/`、`.blockwright/`、`.blockwright-store/`、`tests/out/`（`build.gradle:110-114`） | 报告不会因产物噪声失败 |
| 玩家可见文案 | 上游：**四语言**（`en_us`/`zh_cn`/`zh_hk`/`zh_tw`，`CONTRIBUTING.md:96-97`）；**我们新增的键：`zh_cn` + `en_us`** | [ADR-017](../00-charter.md)、[w03 §2.1](03-test-and-acceptance.md) |
| 提交信息 | `type(scope): summary`（`CONTRIBUTING.md:113-114`） | 评审时人工拦 |

---

### 1.5 Windows 开发机的 WSL2 runbook（2026-10-19 建立，[ADR-022](../00-charter.md)）

> 依据 §1.2/§1.3 实测：`npm run setup` 在 Windows 不可能运行，B-3..B-6 必须整条在 Linux 侧。本机方案 = WSL2 **Ubuntu-24.04**（与 Blockwright 原生基线一致），工作树放 WSL ext4。

| 步 | 命令 / 动作（Windows 侧，Git Bash 先 `export MSYS_NO_PATHCONV=1`） | 说明 |
| --- | --- | --- |
| B-W1 | `wsl.exe --install Ubuntu-24.04 --location D:\wsl\ubuntu-24.04 --no-launch --web-download` | WSL 2.7.3；装到 D:（C: 剩 9.7 GB）；实测 vhdx 初始 1.4 GB |
| B-W2 | PowerShell：`New-Item -ItemType Junction -Path D:\wsl\pla -Target <工作区>` | Linux 侧统一经 `/mnt/d/wsl/pla` 访问工作区（原因见下"三个坑"之 3） |
| B-W3 | `wsl.exe -d Ubuntu-24.04 -u root -- bash /mnt/d/wsl/pla/tools/wsl-run.sh system <linux用户>`，然后 `wsl.exe --terminate Ubuntu-24.04` | 建用户（免密 sudo、`/etc/wsl.conf` 默认用户，保留镜像自带 `[boot] systemd=true`）、`openjdk-21-jdk-headless`、Node 22 LTS（从 nodejs.org 取最新 v22 并按 `SHASUMS256.txt` 校验，不用 `curl \| bash`）。实现：[`tools/wsl-provision.sh`](../../tools/wsl-provision.sh) |
| B-W4 | `wsl.exe -d Ubuntu-24.04 -- bash /mnt/d/wsl/pla/tools/wsl-run.sh verify` | 用绝对路径核对 `/usr/bin/java`、`/usr/local/bin/node` 版本与默认用户 |
| B-W5 | `… wsl-run.sh clone` | `git clone /mnt/d/wsl/pla/mod ~/pla/mod`（复制 Windows 侧克隆，标签/分支照搬），remote 改名 `upstream` 并指回 GitHub；随后删除 Windows 侧 `mod/` 工作树 |
| B-W6 | `… wsl-run.sh build` | 在 `~/pla/mod` 内执行 §2.1 三步；产物 `build/libs/folkways-{core,vanilla,create,modulargolems}-*.jar` 与 `build/deps/ldlib2-*.jar` |

所有阶段的 Linux 侧日志在 `.cache/logs/wsl-<phase>-inner.log`（入口：[`tools/wsl-run.sh`](../../tools/wsl-run.sh)）。

**三个坑（2026-10-19 全部踩过，已固化进 `wsl-run.sh`）**：

1. `wsl.exe` 把 `--` 之后的参数重新拼成一行交给 Linux shell，内联 `bash -c '…"$1"…'` 里的引号与位置参数会被打乱 → 命令行只传"脚本路径 + 简单参数"，逻辑放在脚本文件里。
2. `wsl.exe` 直出 stdout/stderr 混合流时会丢字节（半行消失、`ls: cannot` 后面截断）→ 输出在 Linux 侧写文件，Windows 侧再读。
3. Git Bash（MSYS2）把 `/mnt/…` 形式的参数转成 Windows 路径传给原生 exe → `MSYS_NO_PATHCONV=1`；且工作区路径一律经 junction `/mnt/d/wsl/pla` 引用。
另：WSL 互操作把 Windows `PATH` 接进 Linux，`java` / `npm` 可能解析到 Windows 版本（实测 `npm -v` 打出的是 Windows 的 11.19.0）→ 版本核对用绝对路径。

**R-BLD-17**：Windows 开发机上，B-3..B-6 与层 1 一律在 WSL2 内执行；Windows 侧只做编辑与不依赖 Blockwright 的检查。⚠️ Windows 侧 `npm run test:unit` / `test:i18n` 是否能在 `npm ci --force` 后运行（`tests/**/*.test.ts` 是否 import `@izakyl/*`）待验证。

---

## 2. 依赖获取流程（依赖是**生成**的，不是手写的）

### 2.1 三步，顺序不能换

```sh
npm install      # Blockwright、Playwright、TypeScript
npm run setup    # 下载集成 mod 并写出 .blockwright/mods.json
./gradlew build  # 产物在 build/libs/
```

依据：`CONTRIBUTING.md:14-22`（原文明确"`npm run setup` must run before the first Gradle build"）、`package.json:6-7`。

`npm run setup` 实际执行的是：

```text
node_modules/@izakyl/blockwright-client/dist/blockwright mods sync --config blockwright.toml
```

（`package.json:7`）——即"**按 `blockwright.toml` 同步 mod，并写出 manifest**"。

### 2.2 `blockwright.toml` 是依赖的唯一真源

它同时服务两件事：**给 Gradle 提供编译期 jar**（经 `mods.json`）与**给测试实例提供运行期 mod**（[r05 §1.3](../research/05-engineering-and-tooling.md)）。

关键内容（全部来自 `blockwright.toml`，不另列版本）：

| 类别 | 条目 | 出处 |
| --- | --- | --- |
| loader | `minecraft_version = "1.21.1"`、`loader_version = "21.1.233"`、`jvm_args = ["-Xmx2G"]` | `blockwright.toml:1-4` |
| 服务端 | `eula = true`、`world = "flat"`、`online-mode=false`、固定 seed | `:6-9` |
| 客户端 | `connect = 127.0.0.1:25565`、`guiScale=1`、1280×720 | `:11-13` |
| 本体与依赖 | `mods.folkways`→`build/libs/folkways-*.jar`；`mods.ldlib2`→`build/deps/ldlib2-*.jar` | `:15-29`（本体已拆为四个 mod 块） |
| 固定 mod（带 sha512） | create 6.0.10、emi 1.1.24、geckolib 4.9.2（client）、jei 19.39.0.372（client）、modulargolems 3.1.43、l2library 3.0.8、sable 2.0.6、create-aeronautics 1.3.2、sodium 0.8.13、iris 1.8.14-beta.1、ComplementaryReimagined r5.8.1、lithostitched 1.8.0、terralith 2.6.2、tectonic 3.0.28、touhou_little_maid 1.5.3、shouldersurfing 5.2.0、ftbteams 2101.1.11、ftblibrary 2101.1.37、architectury 13.0.11 | `:32-149` |
| 嵌套 jar 抽取 | `mods.l2core` / `mods.l2serial` / `mods.sable-companion`：`from` + `entry` 从宿主 jar 里抽 | `:64-82` |
| profile | `bench`、`bench-cam-1/2`、`promo`、`promo-sky`、`promo-land`、`fuzz`、`maids`、`shoulder`、`sable`、`ftbteams` | `:156-310` |
| 覆盖率 | `[coverage] mods=["folkways"] sources=["src/main/java"]`（`BLOCKWRIGHT_COVERAGE=1` 才开） | `:151-154` |

**R-BLD-4**：**`blockwright.toml` 是唯一真源**；任何"我这台机器上能 build"的操作都不得绕过它（不允许手工改 jar 路径、不允许在 CI 里替换 manifest）。

**R-BLD-5**：每个下载项**必须带 `sha512`**；禁止关闭校验，禁止"先把校验删了跑通再说"。

### 2.3 `.blockwright/mods.json` 是什么

- **它是派生物**：`mods sync` 写出的"mod 名 → jar 路径列表"映射，Gradle 与 Blockwright 都读它（[r05 §1.3](../research/05-engineering-and-tooling.md)）。
- **它不进版本库**：`.blockwright/` 与 `.blockwright-store/` 都在 `.gitignore:36-37`。
- **它的消费方式**（`gradle/mod.gradle:39-47`（上游已拆为 ext.lib））：

```groovy
def modsManifest = file(".blockwright/mods.json")
def modPaths = modsManifest.isFile() ? new groovy.json.JsonSlurper().parse(modsManifest) : [:]
def lib = { String name ->
    def paths = modPaths[name]
    if (!paths) {
        throw new GradleException("mod ${name} is missing from ${modsManifest}; run  npm run setup  first")
    }
    files(paths)
}
```

- **缺失时的报错**（原文，含双空格）：`mod <name> is missing from <abs path>; run  npm run setup  first`（`gradle/mod.gradle:44`）。看到这句 = **没跑 setup 或 setup 失败**，不是上游坏了。

**字段结构（2026-10-19 首次 `npm run setup` 实测，WSL）**：顶层对象，**键 = `blockwright.toml` 里的 mod 名，值 = 绝对路径数组**（只有一个 jar 也是数组）。路径指向 `<仓库>/.blockwright-store/cache/sha512-<该文件的 sha512>/<文件名>`；由 `from`/`entry` 从宿主 jar 抽出的嵌套 jar（`l2core`、`l2serial`、`sable-companion`）落在 `cache/sha256-<sha256>/<文件名>`。`[mods.folkways_*]` / `[mods.ldlib2]` 这类 `path` 条目**不会**写进 `mods.json`（实测 23 个键全是 `url` / `from` 类条目）。节选（WSL 侧路径）：

```json
{
  "create": ["/home/tcch1111/pla/mod/.blockwright-store/cache/sha512-11cc8fc0…/create-1.21.1-6.0.10.jar"],
  "l2core": ["/home/tcch1111/pla/mod/.blockwright-store/cache/sha256-e7853f90…/l2core-3.0.8+15.jar"],
  "sable-companion": ["/home/tcch1111/pla/mod/.blockwright-store/cache/sha256-873633e3…/sable-companion-common-1.21.1-1.6.0.jar"]
}
```

**路径是生成它那台机器/那一侧的绝对路径，所以 `mods.json` 不可拷到别处用，也不要手写**（R-BLD-4；这也是 Windows 侧 Gradle 用不了 WSL 生成的 manifest 的原因，见 §1.2）。

### 2.4 完整性、缓存与离线

| 机制 | 事实 | 出处 |
| --- | --- | --- |
| sha512 校验 | `blockwright.toml` 每项都带 `sha512` | `:32-149` |
| 缓存目录 | `.blockwright-store/`（gitignore） | `.gitignore:37` |
| CI 缓存 key | `hashFiles('blockwright.toml')` | `.github/workflows/build.yml:21-24` |
| 缓存复用（本地多 worktree） | `.claude/settings.json` 的 `worktree.symlinkDirectories` | [r05 §1.6](../research/05-engineering-and-tooling.md) |

**R-BLD-6**：CI 的 mod 缓存 key 必须包含 `blockwright.toml` 的哈希——**改了依赖就必然重下**，不允许命中旧缓存导致"版本对但 jar 旧"。

**R-BLD-7**：`npm run setup` 依赖 **Modrinth CDN** 与 **FTB maven**（`blockwright.toml:33,137`）。CI 必须能在"CDN 抖动"下有明确失败信息（见 §4.3 的日志要求），**不允许静默降级到旧 jar**。

### 2.5 替代方案评估（如果哪天必须离线）

| 方案 | 做法 | 优点 | 风险 / 代价 | 结论 |
| --- | --- | --- | --- | --- |
| **A. 提交 `blockwright.toml` + 预热缓存** | 仓库里放 toml，CI 缓存 `.blockwright-store`，本地首次联网 | 与上游一致；改动最小 | 首次仍需联网；缓存失效要重下 | **推荐（默认）** |
| B. 提交 jar（vendor） | 把 jar 放进仓库或用 Git LFS | 完全离线 | **许可风险**（再分发）；仓库膨胀；与上游 `lib()` 名单脱钩 | 仅当出现"必须离线"的硬约束时评估 |
| C. 本地 maven 仓库 | `./gradlew publishToMavenLocal` 或自建 repo，改 `build.gradle` 依赖坐标 | 控制力强 | **改上游构建脚本 = L2/L3**，每次同步要重放；且 `lib()` 机制被绕过 | 不推荐 |
| D. 手工放 jar + 手写 manifest | 把 jar 丢进目录、手写 `mods.json` | 看起来最快 | **不可复现**、版本漂移、`npm run setup` 会覆盖它；团队必踩 | **禁止** |
| E. 删掉 `compileOnly lib(...)` | 改 `build.gradle` 去掉可选集成 | 立刻能编译 | 失去与 Create/FTB/Sable 的编译期集成（正是我们要的）；等于永久分叉 | **禁止**（违反 R-FK-12 的口径） |

---

## 3. 可选依赖矩阵

### 3.1 三档（必须先分清）

| 档位 | 含义 | 例子（上游） | 缺了会怎样 |
| --- | --- | --- | --- |
| **仅编译期** | 编译要 jar，运行期软依赖 | `emi`、`jei`、`geckolib`、`shouldersurfing`、`sable`(+companion)、`modulargolems`、`l2library`/`l2core`/`l2serial`、`ftbteams`、`architectury` | 运行期自动降级（反射/软依赖） |
| **编译期 + 游戏测试运行期** | gametest 需要真 jar | `create`（`gametestRuntimeOnly`，`build.gradle:70`（上游改为 runtimeOnly）） | **层 1 跑不了**，但普通运行期不要求 |
| **随 jar 内嵌** | `jarJar`，玩家无需另装 | `ponder`、`starlark`、`flywheel`（`mods/core/build.gradle:19-35`、`mods/vanilla/build.gradle:20-29`、`build.gradle:71-73`（内嵌依赖按子项目拆开）） | **不能缺**：这是真实运行期依赖 |

另有 **开发实例用**：LDLib2 通过 `instanceMod` + `copyInstanceMods` 拷到 `build/deps`（`build.gradle:31, 75-83, 95-98`、`mods/core/build.gradle:36`（编译期依赖移入 core）），`blockwright.toml:28-29` 直接指向它。

### 3.2 上游 compileOnly 清单（逐条）

| 依赖 | 声明 | 行 | 我们的处理 |
| --- | --- | --- | --- |
| `emi` | `compileOnly` | `mods/core/build.gradle:12` | 保留（可选集成） |
| `jei` | `compileOnly` | `mods/core/build.gradle:13` | 保留 |
| `geckolib` | `compileOnly` | `mods/vanilla/build.gradle:15` | 保留（模型动画，可选） |
| `shouldersurfing` | `compileOnly` | `mods/core/build.gradle:14` | 保留（镜头兼容） |
| `create` | `compileOnly` + `gametestRuntimeOnly` | `mods/core/build.gradle:15`、`build.gradle:70` | 保留；**层 1 需要它** |
| `sable` + `sable-companion` | `compileOnly` | `mods/core/build.gradle:16` | 保留（子层级物理，跨 Realm） |
| `modulargolems` / `l2library` / `l2core` / `l2serial` | `compileOnly` | `mods/modulargolems/build.gradle:14` | 保留 |
| `ftbteams` / `architectury` | `compileOnly` | `mods/core/build.gradle:17` | 保留（队伍/跨平台） |
| `ponder` | Maven 坐标 + `jarJar` | `mods/core/build.gradle:19-28` | **不可当可选**（内嵌运行期依赖） |
| `starlark` | `implementation` + `additionalRuntimeClasspath` + `jarJar` | `mods/vanilla/build.gradle:20-29`、`build.gradle:71-73` | 同上（开发环境 jarJar 不进 classpath，故另加） |
| `flywheel` | `jarJar` | `mods/core/build.gradle:29-35` | 同上 |
| `ldlib2` | `implementation` + `instanceMod` | `build.gradle:75-77`、`mods/core/build.gradle:36` | 同上 |

### 3.3 我们新增的依赖（fork 之后）

| 依赖 | 用途 | 档位 | 结论 |
| --- | --- | --- | --- |
| **Chest Cavity Beyond**（CCB，MIT） | 器官腔层（[PRD-013 §14.1](../prd/PRD-013-medical-and-surgery.md)、[ADR-015](../00-charter.md)） | 建议 **`compileOnly`**（反射/软依赖），**不进 `jarJar`** | ⚠️ 待 M1 确认其 API 是否稳定到可编译期使用；**缺失时必须降级为抽象内脏槽** |
| **PoopSky**（代码 MIT） | 厕所方块（[ADR-019](../00-charter.md)） | **无编译期依赖**：只按方块 id 识别 | 保留"缺它→自建茅厕"分支 |
| **Create / Mekanism / GT** | 能量适配层（[d15](../design/15-power-and-mechanical-residents.md)） | 上游已有 `create`；Mek/GT **建议全部 `compileOnly`** | 缺失时只降级"适配器数量"，不降级模拟能力（R-FK-12） |
| **KubeJS** | 内容层（ADR-017） | **不编译**（脚本由整合包侧提供） | 我们 mod 必须能在无 KubeJS 时启动 |

**R-BLD-8**：新增任何可选集成，必须同时提交三样东西：① `blockwright.toml` 的 `[mods.*]`；② `build.gradle` 的 `lib(...)`（或明确"不需要"）；③ **一条"缺失路径"测试**（见 §3.5）。缺一项视为未完成。

### 3.4 R-FK-12 的正确口径（重要修正）

[d12 §6.1](../design/12-fork-strategy.md) 的 R-FK-12 原文是"M1 必须验证**无任何可选依赖**时也能构建成功"。直读上游构建脚本后，这句话需要**精确化**，否则会误导实现者：

| 口径 | 表述 | 可验证方式 |
| --- | --- | --- |
| ❌ 错误理解 | "不装 Create/Sable/FTB 也能 `gradlew build`" | ——（会失败：`lib()` 缺条目直接抛异常） |
| ✅ 正确理解（**运行期**） | "**运行期**缺任何可选 mod 都能启动并完整可玩，只是失去对应集成" | 起一个只有 NeoForge + 我们 jar 的实例（§3.5 手法 1） |
| ✅ 正确理解（**编译期**） | "**编译期**依赖由 `blockwright.toml` 统一提供，任何人 clone 后按 §2.1 三步即可复现构建" | 干净机器/容器跑 §2.1（§3.5 手法 4） |

**R-BLD-9（改写 R-FK-12）**：M1 必须验证两件事：① **开发环境可复现**（干净目录 + 三步命令 → 产出 jar）；② **运行期零可选依赖**（最小实例可启动、可进世界、居民能干活）。**不要求**"不下载任何集成 jar 也能编译"——那与上游的 `compileOnly` 设计冲突。

### 3.5 怎么验证"缺失分支"（四种手法，成本递增）

| 手法 | 做法 | 能证明什么 | 成本 | 放进哪层 |
| --- | --- | --- | --- | --- |
| 1. 最小实例 | `blockwright.toml` 里临时清空 mods（或用 `path` 只挂我们 jar），起 server | 运行期不崩、功能降级 | 分钟级 | 层 1（CI 矩阵，§4.2 P2） |
| 2. 单测断言 | 对"集成缺失"的注册表/条件分支写 unit test | 代码路径存在且返回降级值 | 秒级 | 层 0 |
| 3. gametest 夹具 | `@GameTest` 里断言缺 CCB 时 `OrganSlot` 走抽象实现 | 行为正确 | 分钟级 | 层 1 |
| 4. 干净容器构建 | Docker/新目录：`npm ci && npm run setup && ./gradlew build` | 可复现性 | 10–20 分钟 | 层 2（按里程碑） |

**R-BLD-10**：每个可选集成在 PR 里必须声明它属于上表哪几种手法；**至少手法 1 或 2**。

---

## 4. CI 设计

### 4.1 现状与缺口（诚实）

上游 `.github/workflows/build.yml` 的实际流水线：

| 步骤 | 命令 | 行 |
| --- | --- | --- |
| 环境 | `ubuntu-24.04`、Temurin **21**、Node **22** | `:8-19` |
| 依赖 | `npm ci` → `npm run setup` | `:25-26` |
| 构建 | `./gradlew build` | `:27` |
| 类型 | `npm run typecheck` | `:28` |
| 单元 | `npm run test:unit` | `:29` |
| 产物 | 上传 `build/libs/*.jar`（缺失即失败） | `:30-34` |
| nightly | master push 覆盖 `nightly` prerelease | `:35-65` |

**缺什么**：`runGameTestServer`（488 个 `@GameTest`）、44 个 e2e、视觉、基准、模糊——**一条都不在 CI 里**（[r05 §1.5](../research/05-engineering-and-tooling.md)、[w03 §2.1](03-test-and-acceptance.md)）。上游把"真游戏验证"完全交给开发者本地。

这既是风险也是机会：**我们把层 1 纳入 CI，就立刻领先基底一个身位**（[w03 R-T-4](03-test-and-acceptance.md)）。

### 4.2 四条流水线

| 编号 | 名称 | 跑什么 | 层 | runner | 触发 |
| --- | --- | --- | --- | --- | --- |
| **P0** | 静态与单元 | `gradlew check`（含 lintScaffold）+ `typecheck` + `test:unit` + `test:i18n` | 层 0 | ubuntu（也可 Windows） | 每次 push / PR |
| **P1** | 游戏测试 | `./gradlew runGameTestServer` | 层 1 | ubuntu（Linux 必需） | 每次 PR；push 到主分支 |
| **P2** | 构建矩阵 | 三种"缺失档"构建 + 最小实例启动 | 层 1 | ubuntu | 每次 PR（可夜间全量） |
| **P3** | 文档门禁 | README 登记完整、相对链接有效、AC 编号不重复 | 层 0（文档） | ubuntu | 每次 PR（仅当 `docs/**` 变更） |

#### P0：静态与单元

```yaml
# 文档示例，不是最终实现
name: P0 static
on: [push, pull_request]
jobs:
  static:
    runs-on: ubuntu-24.04
    timeout-minutes: 20
    steps:
      - uses: actions/checkout@v5
      - uses: actions/setup-java@v5
        with: { distribution: temurin, java-version: '21' }
      - uses: actions/setup-node@v5
        with: { node-version: '22', cache: npm }
      - uses: actions/cache@v5
        with:
          path: .blockwright-store
          key: bw-${{ hashFiles('blockwright.toml') }}
      - run: npm ci
      - run: npm run setup
      - run: ./gradlew check
      - run: npm run typecheck
      - run: npm run test:unit
      - run: npm run test:i18n
```

**证据要求**：`gradlew check` 失败必须打印 `文件:行号`（`lintScaffold` 已具备）；i18n 失败必须打印缺失的键与语言。

#### P1：游戏测试（我们相对上游的增量）

| 项 | 规格 |
| --- | --- |
| 命令 | `./gradlew runGameTestServer`（run 定义见 `build.gradle:47-54`（run 定义移到根项目）） |
| 关键参数 | `--nogui`；`neoforge.enabledGameTestNamespaces=folkways,ldlib2`（`build.gradle:52`）——**我们的测试命名空间 `plaa` 必须加进这一行**，否则我们的 `@GameTest` 一个都不会被收集 |
| 工作目录 | `run/gametest/`（`build.gradle:50`） |
| 依赖 | 需要 `create` 的真 jar（`gametestRuntimeOnly`，`build.gradle:70`（上游改为 runtimeOnly））→ 必须 `npm run setup` |
| 触发 | 每个 PR（**必过**）；超时 30 分钟 |
| 证据 | 上传 `run/gametest/logs/latest.log` 与 gametest 报告；失败时保留完整日志 |
| 已知风险 | ⚠️ 488 个上游测试的耗时未在本机实测；若超时，先跑"我们新增的子集"（namespace 过滤），再逐步放开 |

**R-BLD-11**：层 1 进 CI 是 **M1 的验收项**（[d12 §8](../design/12-fork-strategy.md) 的 M1 行已写"把 `runGameTestServer` 纳入 CI"）；不允许以"上游也不跑"为理由跳过。

#### P2：构建矩阵（证明 R-BLD-9）

| 档 | 配置 | 判据 |
| --- | --- | --- |
| **M-A 全量** | 默认 `blockwright.toml` | 构建成功 + 层 1 通过 |
| **M-B 无能源 mod** | 清空 Create/Mek/GT 的运行期挂载（保留编译期 jar） | 服务器能起；机器人只"停机"不崩（[PRD-001 R-NM-24](../prd/PRD-001-needs-mood-memory.md)） |
| **M-C 无 CCB** | 不挂 CCB | 器官槽走抽象降级（[PRD-013](../prd/PRD-013-medical-and-surgery.md)） |
| **M-D 无 FTB / 无 PoopSky** | 不挂 | 任务书缺失→殖民书兜底；厕所缺失→自建茅厕（[k04](../pack/04-quest-book-and-guidance.md)、[ADR-019](../00-charter.md)） |

⚠️ M-B~M-D 的"清空挂载"具体怎么做（`profile` 覆写 / 单独的 toml 变体 / 环境变量）**待 M1 确认 Blockwright 的 profile 覆盖语义**；本文只规定**判据**，不规定实现。

#### P3：文档门禁

我们已经有 55 份文档，且历史上出现过断链与"README 未登记"。这三条检查成本极低、收益极高：

| 检查 | 规则 | 失败示例 |
| --- | --- | --- |
| 登记完整 | `docs/**/*.md` 的每个文件都能在 `docs/README.md` 找到相对路径 | 新增文档忘了登记 |
| 链接有效 | 所有指向 `.md` 的相对链接目标存在（外链跳过） | `../../prd/` 多写一层 |
| 编号唯一 | 每个 PRD 的 `AC-n` 不重复、`R-xxx-n` 不重复 | 复制粘贴导致重号 |

**R-BLD-12**：P3 只在 `docs/**` 变更时触发，**不阻塞代码 PR**；但"文档 PR 必须过 P3"。

### 4.3 失败时必须留下的证据（统一规范）

| 流水线 | 证据 | 保存位置 |
| --- | --- | --- |
| P0 | 失败命令的完整 stdout/stderr；`lintScaffold` 的 `文件:行号` | CI 日志（不额外上传） |
| P1 | `run/gametest/logs/latest.log`、gametest 报告、崩档报告（若有） | artifact，保留 14 天 |
| P2 | 每档的启动日志尾部 200 行 + 是否进入世界 | artifact |
| P3 | 失败项清单（缺登记/断链/重号） | CI 日志 |

**R-BLD-13**：**没有证据的 CI 失败等于没跑**——实现 agent 无法从"exit code 1"里修任何东西。

### 4.4 成本与取舍

| 项 | 估算 | 说明 |
| --- | --- | --- |
| P0 | 5–10 分钟 | 含 `npm run setup` 下载（缓存命中则 1–2 分钟） |
| P1 | 10–30 分钟 ⚠️ | 取决于跑多少个 `@GameTest`；可先按 namespace 子集 |
| P2 | 4 × 5 分钟 | 每档独立 job，可并行 |
| P3 | < 1 分钟 | 纯文本检查 |

**结论**：把 P1 做成"**每个 PR 必跑 + 允许 namespace 子集**"，全量放夜间。这是上游完全没做的事，也是 M1 唯一值得投入的 CI 增量。

### 4.5 发布与夜间

| 通道 | 规则 | 依据 |
| --- | --- | --- |
| nightly | 主分支每次 push 覆盖 prerelease | 上游 `.github/workflows/build.yml:35-65`；我们沿用 |
| 发布门禁 | 层 0 + 层 1 全绿 + i18n（上游键不回归 + 我们的键双语齐）+ 阻塞覆盖率 ≥95% | [d12 R-FK-10](../design/12-fork-strategy.md) |
| 产物 | `build/libs/*.jar` + `-sources` + `-api`（`gradle/mod.gradle:6-8`、`mods/core/build.gradle:43-48`（产物名按子项目展开）） | 沿用 |
| 许可 | 包内必须含上游 `LICENSE` 与我们的 `NOTICE.md` | [d12 §7](../design/12-fork-strategy.md)、[ADR-017](../00-charter.md) |

---

## 5. 本地开发回路

### 5.1 命令表（按"多久跑一次"排序）

| 频率 | 命令 | 说明 |
| --- | --- | --- |
| 每次保存 | `./gradlew check`（可只 `compileJava`） | 编译 + 风格 |
| 每 10 分钟 | `npm run test:unit` + `npm run test:i18n` | 秒级 |
| 每次改动玩法 | `./gradlew runGameTestServer` | 层 1 |
| 每个 PRD 完成 | `npm run test:e2e`（Linux/WSL2） | 层 2 |
| 改 UI | `npm run visual:take` | 截图/布局 |
| 改性能相关 | `npm run bench:take` | 60 分钟 + 25 分钟 ⚠️ |
| 改规划/路径/建造 | `npm run fuzz:run` | 3 个 target |

`runClient` / `runServer`：上游 `build.gradle:47-54`（run 定义移到根项目） 只显式定义了 `gameTestServer`；`runClient`/`runServer` 由 ModDevGradle 默认提供 ⚠️（待 M1 确认是否需要在 `runs {}` 里显式声明，尤其**客户端要带 LDLib2**）。

### 5.2 热重载边界（省时间的真相）

| 改动 | 是否热重载 | 必须做什么 |
| --- | --- | --- |
| 数据包 JSON（含我们的货架） | ✅ `/reload` | 无 |
| 语言文件 | ✅ `/reload` | 无 |
| Starlark 图案 | ✅ 重载库即可 | ⚠️ 自定义图案的 `reject()` 只接受 4 个参数（`CONTRIBUTING.md:109-112`） |
| 资源（贴图/模型） | ⚠️ 部分需 F3+T | 无 |
| Java 代码 | ❌ | 重启 `runClient`/`runGameTestServer` |
| `build.gradle` / `gradle.properties` | ❌ | 重跑 Gradle（必要时 `--refresh-dependencies`） |
| `blockwright.toml` | ❌ | 重跑 `npm run setup` |

### 5.3 日志与产物在哪

| 想看什么 | 路径 | 出处 |
| --- | --- | --- |
| 构建产物 | `build/libs/*.jar`（含 `-sources`/`-api`） | `gradle/mod.gradle:6-8`、`mods/core/build.gradle:43-48`（产物名按子项目展开） |
| fuzz 合并 jar | `build/fuzz/*.jar` | `build.gradle:159-171`（已随上游 0af84f0 删除） |
| 开发实例 mod | `build/deps/ldlib2-*.jar` | `build.gradle:80-83, 95-98`（构建依赖已调整） |
| gametest 日志 | `run/gametest/logs/latest.log` | `build.gradle:50` |
| Blockwright 实例日志 | `.blockwright/instances/<name>/logs/latest.log` | [r05 §1.4](../research/05-engineering-and-tooling.md) |
| 测试输出 | `tests/out/<suite>/{traces,shots,reports,takes,film}/` | [r05 §1.4](../research/05-engineering-and-tooling.md) |
| 本地 maven | `build/repo/` | `gradle/mod.gradle:90-95` |

### 5.4 常见构建失败 Top 10 与修法

| # | 症状 | 根因 | 修法 |
| --- | --- | --- | --- |
| 1 | `mod X is missing from ...; run  npm run setup  first` | 没跑 setup / setup 失败 | 跑 §2.1 三步；看 setup 输出是否下载失败 |
| 2 | `Could not resolve net.createmod.ponder:...` | maven 仓库未连通/坐标变 | 检查 `build.gradle:18-23`、`gradle/mod.gradle:10-15` 四个仓库；代理；`--refresh-dependencies` |
| 3 | FML 启动即崩：mod 需要 `21.1.233` 但装的是 `21.1.248` | NeoForge 版本不配套 | 统一 `gradle.properties:7` 与实例 loader |
| 4 | FTB 相关崩：`2101.x` 混用 | FTB 版本必须成套 | 以 `blockwright.toml:136-144` 为准（teams 2101.1.11 / library 2101.1.37） |
| 5 | `Tab character in ...` / `Trailing whitespace in ...` | 编辑器设置 | 见 §1.4；CI 与本地一致 |
| 6 | 编译期找不到 `sable` 的类 | `sable-companion` 未被 `npm run setup` 从宿主 jar 抽出 | 检查 `blockwright.toml:79-82` 的 `from`/`entry` |
| 7 | 开发环境 `jarJar` 的库（Ponder/Flywheel/Starlark）在运行时 NoClassDefFoundError | 开发环境 jarJar 内嵌 jar 不进 classpath | 上游已给 Starlark 加 `additionalRuntimeClasspath`（`build.gradle:71-73`）；我们的新内嵌库要照做 ⚠️ |
| 8 | `runGameTestServer` 起不来 / 卡在下载 | 首次启动要下载 MC/NeoForge/夹具 mod | 联网跑一次；或预先 `npm run setup` |
| 9 | Mixin 在开发环境不生效 | 开发环境默认不同（`-Dmixin.debug` 等） | ⚠️ 待 M1 确认；先用 gametest 而非客户端验证 |
| 10 | Windows 上 e2e/视觉直接失败 | Blockwright **仅 Linux x64** | 用 WSL2 或 CI（`CONTRIBUTING.md:10-12`） |

---

## 6. 上游同步演练（runbook）

[d12 R-FK-11](../design/12-fork-strategy.md) 要求 **M1 必须完整走一次同步演练**，即便当时上游没有变更。

### 6.1 前置条件

- [ ] 已打基线标签：`upstream-base-<commit短哈希>-<日期>`（[d12 §5](../design/12-fork-strategy.md)）
- [ ] `plaa` 的第一个提交已包含 `NOTICE.md`（说明这是 Folkways 的 fork）
- [ ] 层 0 全绿（否则演练结果无法归因）

### 6.2 步骤清单

| # | 步骤 | 命令 / 动作 | 完成判据 |
| --- | --- | --- | --- |
| S1 | 记录当前状态 | `git log --oneline -1`、`git status` | 工作区干净 |
| S2 | 拉取上游 | `git fetch upstream`；`git log upstream/master --oneline -5` | 看到上游提交 |
| S3 | 打合并基线 | 在**分支**上操作（不直接动主分支） | 新分支存在 |
| S4 | 合并 | `git merge upstream/master`（或 `git rebase`，二选一，禁止混用） | 冲突清单可见 |
| S5 | 解冲突 | 按 [d12 §5 改动登记表](../design/12-fork-strategy.md) 逐项手工合并；**L3 项要重新评审** | 冲突全部标记解决 |
| S6 | 定位我们的钩子 | `git grep "PLA: ADR-"`（标记有三种形式：Java/TS/Gradle `// PLA:`、TOML `# PLA:`、Markdown `<!-- PLA: -->`，统一按 `PLA: ADR-` 前缀搜索——PLAN-001 R1-14） | 每处 L2/L3 标记都在，且编号与 PRD/ADR 对应 |
| S7 | 跑层 0 | `./gradlew check` + `test:unit` + `test:i18n` | 全绿 |
| S8 | 跑层 1 | `./gradlew runGameTestServer` | 全绿（或与基线一致的已知失败） |
| S9 | 更新登记表 | 增删 L2/L3 条目、更新"最后同步日期" | 文档与代码一致 |
| S10 | 出报告 | 见 §6.4 模板 | 报告入 `docs/` 或 PR 描述 |

### 6.3 失败回滚点

| 失败点 | 回滚动作 | 代价 |
| --- | --- | --- |
| S4 合并冲突过多 | `git merge --abort` | 零 |
| S6 发现钩子丢失 | 从 S2 重来，或逐文件 `git checkout <baseline> -- <file>` 后重做 | 半天 |
| S7/S8 出现**新**失败 | 回滚到 S4 前状态；把上游提交拆成子集逐条试 | 1–2 天 |
| 已合并进主分支才发现问题 | `git revert -m 1 <merge>` | 一次发布延迟 |

**R-BLD-14**：同步必须在**独立分支**上进行，主分支只接受"层 0 + 层 1 全绿"的合并。

### 6.4 同步报告模板

```markdown
## 上游同步报告 YYYY-MM-DD
- 基线标签：upstream-base-<hash>-<date> → 新上游：<hash>
- 上游变更摘要：（模块 / 文件数 / 是否触及我们 L2-L3 的文件）
- 冲突：N 处（文件列表），解决方式（保留上游 / 保留我们 / 手工合并）
- // PLA: 钩子：原有 M 处，丢失 0 处，新增 K 处
- 层 0：通过 / 失败（失败项）
- 层 1：通过 / 失败（失败项，是否与基线一致）
- 结论：可合并 / 需返工
```

---

## 7. 规则族 `R-BLD`

| 编号 | 规则 | 理由 |
| --- | --- | --- |
| R-BLD-1 | 版本以 §1.1 为准；升级 JDK/NeoForge/Gradle 必须单独提交 | 把"为什么突然全崩"变成可二分 |
| R-BLD-2 | 层 0 必须在无网络、无 GPU 的 Windows 上通过 | 日常回路不能被环境卡死 |
| R-BLD-3 | B-1..B-6 是 M1 门禁步骤 | 没有可构建的骨架，一切玩法都是空谈 |
| R-BLD-4 | `blockwright.toml` 是依赖唯一真源 | 杜绝"各自手工放 jar" |
| R-BLD-5 | 每个下载项必须带 `sha512`，禁止关闭校验 | 供应链与可复现性 |
| R-BLD-6 | CI 缓存 key 必须含 `blockwright.toml` 哈希 | 防止"旧 jar 命中新清单" |
| R-BLD-7 | `npm run setup` 依赖 CDN，失败必须显式报错，不得静默降级 | 否则会拿到半个依赖集 |
| R-BLD-8 | 新增可选集成必须同时给 toml、`lib()`（或声明不需要）、缺失路径测试 | 三件套缺一即未完成 |
| R-BLD-9 | R-FK-12 按"运行期零可选依赖 + 编译期由 toml 提供"验证 | 原文口径会误导实现者 |
| R-BLD-10 | 每个可选集成在 PR 里声明验证手法（§3.5 的 1–4） | 让"我看过代码"变成"我验证过行为" |
| R-BLD-11 | 层 1（`runGameTestServer`）必须在 CI 里跑，不接受"上游也不跑" | 这是我们相对基底的工程增量 |
| R-BLD-12 | 文档门禁（P3）只阻塞文档 PR | 不拖慢代码迭代 |
| R-BLD-13 | 没有证据的 CI 失败等于没跑 | 失败必须可修 |
| R-BLD-14 | 上游同步必须在独立分支，主分支只收全绿合并 | 保护可回滚性 |
| R-BLD-15 | 内嵌运行期库（`jarJar`）必须同时声明开发环境可见性 | 否则"能打包、跑不起来" |
| R-BLD-16 | 禁止把上游 `compileOnly` 扩成我们的运行期依赖 | 会让整合包被迫装一堆 mod |

---

## 8. 开放问题

| 编号 | 问题 | 影响 | 何时必须定 | 谁定 |
| --- | --- | --- | --- | --- |
| OQ-B-1 | 是否随仓库提供 `blockwright.toml` 的**快照 + 预热缓存**，以支持完全离线构建？ | 离线/内网开发；CI 稳定性 | M1 第一次 build 后 | 人类 |
| OQ-B-2 | `npm run setup` 只依赖 Modrinth CDN 与 FTB maven；是否需要镜像或自建缓存？ | 供应稳定性 | M2 前 | 人类 |
| OQ-B-3 | CI 是否跑**客户端** gametest（需要 GPU/display）？ | 覆盖 UI 相关行为 | M1 末 | 人类 + 实现 |
| OQ-B-4 | 是否允许本地用 `-P` 覆盖依赖路径（开发调试用）？ | 便利 vs 可复现 | M1 | 实现 |
| OQ-B-5 | ~~`mod_id` 改为 `plaa` 后，`blockwright.toml` 的 `[mods.folkways]` 与产物名如何迁移？~~ | **已定（[ADR-023](../00-charter.md)）**：四个 modid `plaa_core/vanilla/create/modulargolems`，产物名随 `ext.modName`（`plaa-core-neoforge-1.21.1-*.jar` 等）；`blockwright.toml` 的 `[mods.folkways_*]` 四条**全部重命名**为 `[mods.plaa_*]` 并改 `path` 通配，**不保留别名**（避免双套 manifest 键）。在 B-2 执行 | ✅ 已定（2026-10-19） | — |
| OQ-B-6 | 是否把 `fuzz` 纳入夜间 CI？（10 分钟 + 运行时长） | 规划器健壮性 | M2 | 人类 |
| OQ-B-7 | ~~Windows 开发机是否统一要求 WSL2 以跑层 2？~~ | **已定（[ADR-022](../00-charter.md)）：是**，且不止层 2——`npm run setup` 只能在 Linux x64 运行，故 B-3..B-6 与层 1 也在 WSL2 内（§1.5 runbook） | ✅ 已定（2026-10-19） | — |
| OQ-B-8 | 我们的 `NOTICE.md` 与 `LICENSE` 是否也进 jar（`gradle/mod.gradle:55-60` 已把上游 LICENSE 打进 `META-INF`）？ | 许可合规 | M1 | 人类 |

---

## 9. 变更记录

| 日期 | 版本 | 变更 |
| --- | --- | --- |
| 2026-10-18 | 草稿 | 首次起草：环境基线、依赖获取流程（修正"手写 mods.json"的误解）、可选依赖矩阵与 R-FK-12 口径修正、四条 CI 流水线与证据规范、本地回路与 Top 10 失败、上游同步 runbook、16 条 R-BLD、8 条 OQ |
| 2026-10-19 | 草稿 | 引用迁移到基线 67f28b0（依据 r10） |
