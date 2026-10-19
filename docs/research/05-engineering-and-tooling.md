# 基底：工程与测试基建（r05）

```
状态：草稿
负责人：调研 agent（代码考古，只读）
最后更新：2026-10-19
上游依据：reference/folkways-67f28b0/（基线 67f28b0，只读；引用已按 r10 迁移）
下游影响：docs/workflow/03-test-and-acceptance.md、docs/pack/03-performance-budget.md、plugins/ 工程脚手架、pack/ 自动验收方案
```

> 本文只记录**事实**与**复用判断**。行内路径均相对 `reference/folkways-67f28b0/`。
> 规模参考：`src/main` 840 个 .java / 约 80.4k 行；`src/gametest` 85 个文件 / 488 个 `@GameTest`；`tests/` 182 个 .ts、e2e 44 个 spec。

---

## 1. 构建与依赖

### 1.1 Gradle 配置要点

| 项 | 事实 | 出处 |
| --- | --- | --- |
| 插件 | `net.neoforged.moddev` 2.0.141 + `java-library` + `maven-publish` | `build.gradle:1-3`、`mods/core/build.gradle:1-5`（插件声明下放子项目） |
| Java | toolchain 21，`options.release=21`，UTF-8 | `gradle.properties:10`、`build.gradle:100-103`、`gradle/mod.gradle:62-65` |
| 版本坐标 | MC 1.21.1 / NeoForge 21.1.233 / Java 21 | `gradle.properties:5-10` |
| 关键库 | Ponder 1.0.82、Flywheel 1.0.6、Starlark 4.2.1、LDLib2 2.2.37 | `gradle.properties:12-17` |
| 产物名 | `folkways-neoforge-1.21.1`（+ `-sources`、`-api`、`-fuzz`） | `gradle/mod.gradle:6-8`（产物名由子项目设定） |
| 仓库 | mavenCentral、libraries.minecraft.net、maven.createmod.net、maven.firstdark.dev | `build.gradle:18-23`、`gradle/mod.gradle:10-15` |
| settings | `PREFER_PROJECT`；pluginManagement 含 neoforged releases | `settings.gradle:9-16` |
| 包装器 | Gradle 8.14.5 | `gradle/wrapper/gradle-wrapper.properties` |

三个自定义 sourceSet / 任务值得注意：

- `sourceSets.gametest`（默认目录 `src/gametest/java`（现为 mods/*/src/gametest））+ `sourceSets.fuzz { srcDirs = ["tests/fuzz/java"] }`，二者都拿到 modding 依赖（`gradle/mod.gradle:24-31`（fuzz 源集已删除））。
- `fuzzJar`：把 mod jar 与 `tests/fuzz/java` 的类**合并**成 `build/fuzz/folkways-*-fuzz.jar`，供 `blockwright.toml#fuzz` 加载。理由写在注释里——模糊测试要摸到 package-private 的规划/旅行/建造代码（`build.gradle:30-31, 159-171`（已随上游 0af84f0 删除））。
- `apiJar`：只打包 `Declaring`/`Relating`/`core/api/**`/`front/api/**`，随 publication 一起发布（`mods/core/build.gradle:43-50`、`gradle/mod.gradle:83-96`（apiJar 与发布已拆分））。**这是给第三方插件作者的编译期 API 面**，也是我们自研插件最可能直接依赖的东西。
- `lintScaffold`：全仓库禁用 Tab 与行尾空白，并挂到 `check` 上（`build.gradle:105-133`（check 另依赖子项目））。

### 1.2 可选集成的 compileOnly 方式（核心机制）

`gradle/mod.gradle:39-47`（上游已拆为 ext.lib） 先读 `.blockwright/mods.json`，再用闭包 `lib(name)` 把某个 jar 路径列表变成依赖；缺条目直接抛 `mod X is missing from ...; run npm run setup first`。

```groovy
def modsManifest = file(".blockwright/mods.json")
def modPaths = modsManifest.isFile() ? new groovy.json.JsonSlurper().parse(modsManifest) : [:]
def lib = { String name -> ... files(modPaths[name]) ... }
```

于是集成被分成三档（`mods/core/build.gradle:12-21`、`mods/vanilla/build.gradle:15`、`mods/modulargolems/build.gradle:14`（依赖声明按子项目拆开））：

| 档位 | 例子 | 说明 |
| --- | --- | --- |
| 仅编译期 | emi、jei、geckolib、shouldersurfing、sable(+companion)、modulargolems、l2library/l2core/l2serial、ftbteams、architectury | 反射/软依赖，运行期缺失也能跑 |
| 编译期 + 游戏测试运行期 | create（`gametestRuntimeOnly`，`build.gradle:70`（上游改为 runtimeOnly）） | 只在 gametest 里需要真 jar |
| 随 jar 内嵌 | ponder、starlark、flywheel（`jarJar`）；Starlark 另加 `additionalRuntimeClasspath`（开发环境 jarJar 内嵌 jar 不进 classpath，`mods/vanilla/build.gradle:20-29`、`build.gradle:71-73`、`mods/core/build.gradle:29-35`（内嵌依赖按子项目拆开）） | 玩家无需另装 |
| 开发实例用 | LDLib2（`compileOnly` 之外用 `instanceMod` 配置 + `copyInstanceMods` 拷到 `build/deps`，`build.gradle:31, 75-83, 95-98`、`mods/core/build.gradle:36`（编译期依赖移入 core）） | `blockwright.toml:28-29` 直接指 `build/deps/ldlib2-*.jar` |

**结论**：这个「manifest → 可选依赖」模式是整份基建里最值得照搬的单点。整合包/插件工程只要把 `blockwright.toml` 的 mod 清单换掉、`lib()` 名单换掉即可复用；它对「同一个 mod 有 N 个可选联动」的场景是最省事的做法。

### 1.3 `npm run setup` 与 `.blockwright/mods.json`

- `package.json:7`：`node_modules/@izakyl/blockwright-client/dist/blockwright mods sync --config blockwright.toml`。
- 作用：按 `blockwright.toml` 的 `[mods.*]` 下载（Modrinth/FTB maven，带 sha512 校验）与解包，写 `.blockwright/mods.json`（**每个 mod 名 → jar 路径列表**，Gradle 与 Blockwright 都读它）。
- 嵌套 jar 也能满足：`[mods.l2core] from="l2library" entry="META-INF/jarjar/l2core-*.jar"`（`blockwright.toml:64-72`）——从宿主 jar 里抽 jarjar 条目，这是「编译依赖藏在别人 jar 里」的通用解法（sable-companion 同理）。
- `.blockwright/`、`.blockwright-store/` 都在 `.gitignore` 里（`.gitignore:36-37`）；CI 缓存 `.blockwright-store`，key 是 `hashFiles('blockwright.toml')`（`.github/workflows/build.yml:21-24`）。
- **首次构建前必须先 `npm install && npm run setup`**（`CONTRIBUTING.md:14-22`），否则 `compileOnly` 解析失败。

### 1.4 产物位置一览

| 产物 | 路径 |
| --- | --- |
| mod jar（+ sources/api） | `build/libs/*.jar` |
| LDLib2 实例用 jar | `build/deps/ldlib2-*.jar` |
| fuzz 合并 jar | `build/fuzz/folkways-*-fuzz.jar` |
| 本地 maven 仓库 | `build/repo/` |
| gametest 工作目录 | `run/gametest/` |
| Blockwright 实例（含 `logs/latest.log`） | `.blockwright/instances/<instance>/` |
| 所有测试输出 | `tests/out/<suite>/{traces,shots,reports,takes,film}/`（`tests/shared/harness/out-paths.ts:10-15`） |
| bench 城镇缓存 | `.blockwright/bench-town/<key>/`（`tests/bench/town/town-cache.ts:19`） |

### 1.5 CI 现状（重要缺口）

`.github/workflows/build.yml`：`ubuntu-24.04` → `npm ci` → `npm run setup` → `./gradlew build` → `npm run typecheck` → `npm run test:unit` → 上传 `build/libs/*.jar`；master push 另起 `nightly` job 覆盖 prerelease。

**CI 完全没跑游戏内测试**（e2e / visual / bench / fuzz / gametest 都不在流水线里）。也就是说「真游戏验证」在这份仓库里是**开发者本地行为**，没有任何服务器兜底。我们若要复刻六阶段工作流，这一层必须自己补。

### 1.6 agent 侧的配置

- `.mcp.json`：把 Blockwright 暴露成 MCP server（`node node_modules/@izakyl/blockwright-mcp/dist/main.js --config blockwright.toml --ui-adapter tests/ldlib2/index.ts`）——**agent 可以直接在真游戏里操作 UI**，这是「AI 干活 + 自动验证」闭环的关键件（`CONTRIBUTING.md:89-90`）。
- `.claude/settings.json`：`worktree.symlinkDirectories = ["node_modules", ".blockwright-store"]`——让多 agent 在 git worktree 里并行时共享依赖与 mod 缓存（对应我们六阶段的阶段四）。
- **没有** `AGENTS.md` / `CLAUDE.md`；agent 规则散在 `CONTRIBUTING.md` 与源码注释里。

---

## 2. 测试金字塔总表

「能否在 Windows 跑」列：✅ 可 / ⚠️ 理论可但仓库未验证 / ❌ 不可（见 §3.6、§7.3）。

| 层 | 命令 | 跑什么 | 体量 / 耗时 | Windows | 覆盖的风险 |
| --- | --- | --- | --- | --- | --- |
| 静态 lint | `./gradlew check`（含 `lintScaffold`） | Tab、行尾空白 | 秒级 | ✅ | 风格噪声、diff 污染 |
| 类型检查 | `npm run typecheck` | `tsc -p tests/{e2e,visual,bench,promo,fuzz,i18n}`，`tsconfig.base.json` 只查不产 | 十几秒~分钟 | ✅ | TS 类型/导入错；**故意在启动 MC 前拦住**（`tests/shared/harness/setup.ts:4-17`） |
| 单元（无游戏） | `npm run test:unit` → `node --test --experimental-strip-types "tests/**/*.test.ts"` | 15 个 `*.test.ts`：bench 判定器、心跳解析、labor-share、拒绝覆盖率表、engine-diagnostics | 秒级 | ✅ | 判定逻辑正确性、表与源码同步 |
| i18n | `npm run test:i18n` | `tests/i18n/lang.test.ts` 179 行：四语言键集合、`%s/%1$s/%%` 占位符、pattern 字典、notice/refusal 枚举全覆盖 | 秒级 | ✅ | 漏译、错译占位符、UI 出现裸 key |
| 注册表一致性 | （在 `test:unit` 内）`tests/bench/report/refusal-coverage.test.ts` | 静态扫 `src/main/java`（现为 mods/*/src/main/java），把每个 `RefusalKind` 常量、每个 `Unassigned.Reason` 与判定表对照；表里不许留已删常量 | 秒级 | ✅ | bench 把「正常拒绝」误判成红、或无判定 |
| 游戏内单测 | `./gradlew runGameTestServer` | 85 个类 / **488 个 `@GameTest`**，`--nogui`，命名空间 `folkways,ldlib2` | 分钟级（纯 JVM，无 GPU） | ⚠️ | 引擎/规划/建造/旅行的行为正确性 |
| 端到端 | `npm run test:e2e` | 44 个 spec、约 55 处 `test(` 声明（其中 24 处在 `twins()` 里 → 实际约 79 个 test），每个 test = 一对真实客户端+服务端 | 单测 15~20 min 预算，`workers:4` 全并行 | ❌ | 玩家可见行为、面板、跨 mod 集成（Sable/FTB/女仆/肩视） |
| 覆盖率 | `npm run test:coverage` | e2e + `BLOCKWRIGHT_COVERAGE=1`，再 `coverage report` | 比 e2e 更慢（探针拖慢 wall-clock） | ❌ | mod 自身代码行覆盖（含 mixin） |
| 视觉 | `npm run visual:take` | 12 个 spec：截图 + 录屏 + 布局 lint + 窗口覆盖 | 20 min/spec 预算 | ❌ | UI 溢出/裁切、模型/贴图、ponder 场景 |
| 基准 | `npm run bench:take` | 1 个 bench（400 居民城镇） | 60 min + 运行时长（≥25 min） | ❌ | 性能回归、劳动利用率、守恒 |
| 模糊 | `npm run fuzz:run` | 3 个 target：build / economy / paths，headless 服务端 | 10 min + `FUZZ_MINUTES`（默认 2） | ❌ | 规划器/旅行/建造的不变量 |
| 宣传片 | 无 npm script；`npm exec -- playwright test --config tests/promo/playwright.config.ts`（match `*.take.ts`） | 10 个 take | 60 min/个，`workers:1` | ❌ | 无回归意义，出素材 |

**Blockwright 平台限制**：`CONTRIBUTING.md:10-12` 明说 Blockwright「the harness that drives real Minecraft clients and servers, supports only **Linux x64** for now. Building the mod works anywhere Gradle does.」→ 上表里所有 ❌ 都源自这一条，而不是我们的配置。CI 选 ubuntu-24.04 与此一致。

---

## 3. Blockwright 是什么

### 3.1 组成

`package.json:20-30`：`@izakyl/blockwright-{client,minecraft,test,ui,cinema,mcp}` 均 `0.1.0-alpha.1` + `@playwright/test ^1.60`。CLI 在 `node_modules/@izakyl/blockwright-client/dist/blockwright`。

- **client**：实例与进程生命周期（`BlockwrightDriver`、`launchNeoForge`、`launchGame`、`seedInstance`、`instanceDirOf`、`crashAwareRetry`）。
- **minecraft**：游戏内 API 面（`server/client`、`tick`、`world`、`player`、`screen`、`input`、`camera`、`media`、`reflect`、`defineTask/javaTask`、`attempt/isRefusal`）。
- **test**：Playwright 适配（`defineConfig`）与失败取证（`attachFailureEvidence`）。
- **ui / ui-adapter**：抽象 UI 树与动作；本仓库的实现是 LDLib2 适配器（`tests/ldlib2/adapter.ts`）。
- **cinema**：多相机、`stillWorld`、`walkSpeed` 之类演出工具。
- **mcp**：把同一套 API 暴露给 MCP 客户端（`.mcp.json`）。

### 3.2 怎么驱动真实客户端/服务端

- 配置来自 `blockwright.toml`；`launchPair()`（`tests/shared/harness/pair.ts:47-56`）一次性拉起服务端+客户端，`crashAwareRetry(2)` 容忍崩溃重试，失败时 `attachFailureEvidence` 自动附 UI 树/容器/实体快照。
- 实例目录 `.blockwright/instances/<name>`，从共享库 `.blockwright-store` **硬链接**填充；同毫秒两个实例必须不同名，否则填充竞态会损坏目录（`tests/shared/harness/run-id.ts:3-7`）。
- 每个实例可带 `trace`，落 `tests/out/<suite>/traces/*.ndjson`（全量交互日志，排障主力）。
- `defineTask({name, side, timeoutMs, limits, source: javaTask({imports, body, members})})`：**把一段 Java 源码编译进正在运行的游戏 JVM**。bench/fuzz 的所有探针都靠它（`tests/bench/probes/census.ts`、`tests/fuzz/fuzz-kit.ts:39-54`（已随上游 0af84f0 删除））。这是从 TS 侧触达 mod 内部（含 package-private）的通用钥匙。
- `reflect.dump` 可把实体/方块实体/句柄导出成值树（`tests/shared/harness/bw-helpers.ts:146-156`）。

### 3.3 profile 与 mod 组合机制

`blockwright.toml` = 全局 `[neoforge.*]` + 全局 `[mods.*]`（各自 `target=["server"/"client"]`）+ `[profile.<名>.*]` 覆盖；引用方式是字符串 `"blockwright.toml#<profile>"`（`tests/shared/harness/stage.ts:30-31` 给出 `#sable` 的用法）。profile 只写差异，mod 组合 = 全局 target 与 profile 覆盖**合并**。

各 profile 用途（`blockwright.toml:156-310`）：

| profile | 配置/组合 | 用途 |
| --- | --- | --- |
| 默认（无后缀） | 服务端 flat 世界 seed `folkways-e2e`、`online-mode=false`、`allow-flight=true`；客户端连 127.0.0.1:25565、1280×720；mods：create 双端 + emi/jei/geckolib（client）+ modulargolems + l2library | e2e / visual 的默认对 |
| `bench` | `-Xmx3G`；vanilla 世界 seed `folkways-promo-land`、`max-tick-time=-1`、view-distance 20、entity-broadcast 300%；客户端 1920×1080 GPU、`maxFps=20`、renderDistance 24；mods：+ Terralith/Tectonic/Lithostitched + sodium/iris | 400 居民大城镇基准 + 拍片 |
| `bench-cam-1/2` | 与 bench 同画面设置，但**各自账号** `BenchCam1/2`（uuid 固定） | 第二、第三个客户端当「漫游相机」 |
| `promo` | `-Xmx3G`；flat 世界 seed `folkways-promo`、`maxFps=260`、guiScale 2、静音；mods：+ sable + create-aeronautics + sodium/iris | 宣传片（平地） |
| `promo-sky` | 同上但生成地形 | 航拍景色 |
| `promo-land` | bench 的地形 + `lang=zh_cn` | 真实地形下的宣传片（影片面向中文观众） |
| `fuzz` | 单独服务端（无客户端），`view-distance=4`、无生物生成、`max-tick-time=-1`、超平坦单层基岩；`[profile.fuzz.mods.folkways] path="build/fuzz/folkways-*.jar"` | 模糊测试（headless） |
| `maids` | + touhou_little_maid 双端 | 女仆模型当居民外观 |
| `shoulder` | + shouldersurfing（client） | 肩视相机下书的准星 |
| `sable` | + sable 双端 | 「甲板上」孪生测试与 Sable 专属 spec |
| `ftbteams` | + ftbteams + ftblibrary + architectury 双端 | 殖民地移交给 FTB 队伍 |

### 3.4 账号 / 世界 / 属性配置

- 账号：`[profile.X.neoforge.client.account] { username, uuid }`（`blockwright.toml:188`）。
- 世界：`[neoforge.server] world = "flat" | "vanilla"`；`properties` 直写 `server.properties`（`level-seed`、`max-tick-time`、`level-type`+`generator-settings` 内联 JSON、`online-mode`）。
- 客户端：`options` 直写 `options.txt`（`guiScale`、`overrideWidth/Height`、`maxFps`、`renderDistance`、`lang`、`soundCategory_*`、`fov`、`pauseOnLostFocus`）；`game_args = ["--width","--height"]`；`jvm_args`。
- 显示：`[profile.X.neoforge.client.display] device = "gpu"`（bench/promo 需要真 GPU）。
- EULA：`[neoforge.server] eula = true`——**代玩家接受 Minecraft EULA**（`blockwright.toml:7`，`CONTRIBUTING.md:68-71` 明确提示）。
- mod 设置注入：`tests/shared/harness/mod-settings.ts` 用 `seedInstance().write("config/folkways-server.toml", ...)`（上游已拆为三份 *-server.toml） 直接写 mod 配置，并可要求 `reuseInstanceDir: true` 以免被清空（`tests/shared/harness/pair.ts:43-45`）。

### 3.5 能否当作「整合包自动验收」的地基

**可以，而且几乎是现成的**：换掉 `blockwright.toml` 的 `[mods.*]` 就等于定义了「整包在哪种 mod 组合 / 世界 / 客户端选项下验收」，`npm run setup` 顺带解决了「整合包依赖下载 + 版本锁定（sha512）」，profile 机制天然表达「同一整合包的多种场景」。

前置代价：
1. 需要 **Linux x64 + 能跑 GPU 的机器**（bench/visual/promo 要 `display.device="gpu"`；纯 e2e/fuzz 是服务端为主，但仍需 Blockwright 支持的平台）。
2. 版本绑定：`[neoforge] minecraft_version` 必须与我们的整合包 MC 版本一致；换版本要等 Blockwright 跟进。
3. `0.1.0-alpha.1` 闭源 alpha，接口可能变；我们应把它当作「可替换的测试执行器」而非依赖，最好把用例写成 `tests/shared/harness/*` 之类薄封装（Folkways 自己就是这么做的）。

### 3.6 补充事实

- `npm run setup` 与 `gradle` 之间是硬耦合：`build.gradle` 没有 `mods.json` 时直接失败。
- 全文只有一处平台硬编码：`tests/e2e/farm-blackbox.spec.ts:583-608` 直接检查 `/usr/bin/ffmpeg`、`/usr/bin/ffprobe`。

---

## 4. 游戏内测试与无头测试

### 4.1 `src/gametest`（现为 mods/*/src/gametest） 的写法与注册

```java
@EventBusSubscriber(modid = FolkwaysMod.MOD_ID, bus = EventBusSubscriber.Bus.MOD)
@GameTestHolder(FolkwaysMod.MOD_ID)
@PrefixGameTestTemplate(false)
public final class GroundGameTests {
    @SubscribeEvent public static void register(RegisterGameTestsEvent event) { event.register(GroundGameTests.class); }

    @GameTest(template = "empty_large", timeoutTicks = 100)
    public static void reachAcrossSectionsFollowsTheWorldAndTrialsLeaveItAlone(GameTestHelper helper) { ... helper.succeed(); }
}
```

（`mods/core/src/gametest/java/io/github/izakyl/folkways/core/api/ground/GroundGameTests.java:22-67`）

- 注册三件套：`@GameTestHolder(MOD_ID)` + `@PrefixGameTestTemplate(false)` + MOD 总线订阅 `RegisterGameTestsEvent`（85 个文件全用同一套）。
- 模板用原版 `empty` / `empty_large`，必要资源自带：`mods/vanilla/src/gametest/resources/data/folkways/folkways/{blueprint/test_hut.nbt, pattern/test_grower.star, pattern/test_slab.star}`。
- 常见辅助类：`mods/vanilla/src/gametest/java/io/github/izakyl/folkways/plugins/build/SiteRig.java`（自建工地）、`mods/core/src/gametest/java/io/github/izakyl/folkways/core/engine/plan/PlanningFixture.java`（规划夹具）、`mods/vanilla/src/gametest/java/io/github/izakyl/folkways/plugins/build/draft/DraftKit.java`——**测试自带夹具层**是这套 gametest 可维护的关键。
- 运行：`./gradlew runGameTestServer`（`build.gradle:47-54`（run 定义移到根项目）：`gameDirectory=run/gametest`、`--nogui`、`neoforge.enabledGameTestNamespaces=folkways,ldlib2`、`sourceSet=gametest`）。
- 覆盖面偏向**引擎/规划/建造**（BuildPlanning 799 行、TransferPlanning 563 行、HaulExecution 548 行…），UI 只测数据同步（`mods/core/src/gametest/java/io/github/izakyl/folkways/front/api/notice/TextSyncGameTests.java`）。

### 4.2 无头（headless）侧：fuzz

- 只有服务端，无客户端（`tests/fuzz/fuzz-kit.ts:82-111`（已随上游 0af84f0 删除） 直接 `driver.launchNeoForge("server", ...)`）。
- 关键前提：**引擎单线程模式**。`seededServer()` 写 `planning.mode = "SINGLE_THREAD"`，注释理由是「fuzz 服务器 sprint，没有 tick 预算，单线程下每 tick 做完所有事、case 在任何机器上可复现」（`fuzz-kit.ts:86-90`（已随上游 0af84f0 删除）、`tests/shared/harness/mod-settings.ts:44-47`）。
- Java 侧只暴露四个静态入口：`Live.open / step / close / candidates`（`tests/fuzz/java/.../fuzz/Live.java:47-140`（已随上游 0af84f0 删除）），TS 侧 `defineTask` 包装后按 `SEGMENT=20` tick 推进（`tick.sprint(server, SEGMENT)`）。目标实现是三个 `LiveTarget`：`LiveBuild`(1325 行)、`LiveEconomy`(1121 行)、`LivePaths`(1391 行)，共享 `Plot`（8 个台面/服务器）、`Rng`、`Shrink`、`Violation`。
- 调度与收敛（`tests/fuzz/campaign.ts`（已随上游 0af84f0 删除））：

| 机制 | 事实 |
| --- | --- |
| 分片 | `FUZZ_SHARDS`（默认按 `availableParallelism()/(2*3)` 与内存/4GiB·3 取 min） |
| 并行 | 每服务器 8 个 plot（`Plot.RING`），每 target 3 个 target 并行（`playwright.config.ts` workers:3） |
| 语料 | 每 target 先回放 `tests/fuzz/corpus/<target>/*.json`；**当前副本没有 corpus 目录**（尚未有失败被固化） |
| 画新 case | `FUZZ_MINUTES`（默认 2，0=只回放）；`FUZZ_SEED` 是 64 位十进制，失败信息带回 `seed` 与 `case #index` 可复现 |
| 收缩 | 首次违反的 case 用 `Shrink.candidates`（一次一改，最多 64 个候选）在空 plot 上收缩，上限 4 分钟 / 48 次尝试 |
| 产出 | `tests/out/fuzz/reports/<target>.json`（replayed/ran/ticks/seen/stillBroken/mended/found）+ `<target>-cases.ndjson`（每个 case 一行）+ 失败时 `verdict()` 文本 |

### 4.3 可复用点

1. **`javaTask` 探针**：不改 mod 源码就能挂监听器（work-tap 用 `NeoForge.EVENT_BUS.addListener(EventPriority.LOWEST, false, WorkProgress.class, ...)`）。
2. **确定性前提显式化**：把「单线程 / 固定种子 / 冻结 tick」当作 fuzz 与 bench 的一等配置项。
3. **把测试类打进 mod jar**（`fuzzJar`）以突破可见性——比到处加 `@VisibleForTesting` 更干净。
4. **corpus + shrink 资产化**：bug 修完后回归免费。
5. 反例警示：三个 target 合计约 4000 行 Java 与 Folkways 内核强耦合，**不建议整体照搬**（见 §7.2）。

---

## 5. 度量与基准

### 5.1 怎么产生数据

- 入口：`tests/bench/large-colony.bench.ts`（1129 行，单个 test）。`CONFIG="blockwright.toml#bench"`；`workers:1`；`process.env.BLOCKWRIGHT_COVERAGE = "0"`（覆盖探针会扭曲数字，`tests/bench/playwright.config.ts:6`）；超时 = `BUDGET.bench(60min)` + `max(25min, ticks*50*4)`。
- 规模与时长全由环境变量控制：`FOLKWAYS_LC_RESIDENTS`(400)、`FOLKWAYS_LC_DAYS`(3，≤10) / `FOLKWAYS_LC_TICKS`、`FOLKWAYS_LC_GROWTH`(4)、`FOLKWAYS_LC_HORIZON`(12000)、`FOLKWAYS_LC_RAIL`、`FOLKWAYS_LC_CAMERAS`、`FOLKWAYS_LC_VIDEO/SHADERS/FPS/FILM_SPEED`；固定装置：36 熔炉/12 高炉/16 烟熏炉/56 工作台/24 畜栏/12 钓点。
- 装置方式：**反射 + NBT**（不走真实 UI，`tests/bench/large-colony.bench.ts:146`）：summon 居民 → `data-merge colony_member` → 直接写 `folkways_colonies.dat` → 反射 `cache.remove` 强制重载。
- 城镇只造一次并缓存：`.blockwright/bench-town/<key>/`，key = 对 `blockwright.toml` 的该 profile 服务端段（剔除 client 段与 client-only mod）+ counts + rail + 一组源文件做 sha256（`tests/bench/town/town-cache.ts:20-41`）；`FOLKWAYS_LC_RERAISE=1` 强制重造。
- 运行期探针（`tests/bench/probes/*`，全部 `javaTask` 实现）：

| 探针 | 内容 |
| --- | --- |
| `tick-meter.ts` | 每 tick 一行：`game_time, wall_ns, full_ns, post_ns, normal_ns, epoch_ms`；冻结 tick 不记；`full_ns` = Pre(HIGHEST)→Post(LOWEST) 全 tick（含 NeoForge Post 里的劳动） |
| `work-tap.ts` | `WorkProgress`/`WorkExertion`/`WorkYield` → work/exertion/yield 三张 CSV（STARTED/FINISHED/RELEASED/FAILED、谁在哪做什么、active_ticks、distance、实际产量） |
| `census.ts` | 每 20 tick 一行 JSON 追加写：`submitted/planned/phases/unassigned/missing/standing`（standing 含 idle/stalled/walking/working/holding/riding/urge/*） |
| `path-probe / piece-probe / rail-reach-probe / body-snapshot` | 路径队列、零散构件、轨道可达、身体快照 |

### 5.2 指标与判定

- **tick 时间**：`full_ns` 均值/p95（`tests/bench/tools/compare.py:38-39`）。注意 `tests/bench/report/engine-diagnostics.ts:83` 的说明：`Labor.work` 跑在 `ServerTickEvent.Post`，**vanilla MSPT 不含它**，所以必须用 tick meter 的 `full_ns` 才看到全貌。
- **劳动占比**（`tests/bench/report/labor-share.ts`）：`standing_share`（holding 计入 working，idle/stalled 单列）、`done_total`、`throughput_per_1000_ticks`、`deferred`（`BEYOND_HORIZON` 的中位/峰值/末值）。注释明确了口径：idle ≠ 闲人（受 plan horizon 限制），throughput 才是产出度量；一 beat = 200 tick。
- **引擎诊断**（`tests/bench/report/engine-diagnostics.ts`）：`planning_failures`、`failed_batch_peak`、`pending_peak/last`、`labor_ms_per_tick_median/max`、`publish_ms_per_tick_*`、`publish_share_of_labor_pct`、slow weave/schedule 分位、`rail_complete_laps`、`unassigned_kinds_series`。
- **判定器**（`tests/bench/report/judgements.ts`，324 行）：输出 `{rule, severity: "red"|"caveat", said, evidence}`。规则名即指标清单：`utilisation/on-duty`、`utilisation/stalled`、`utilisation/nothing-happens`、`utilisation/never-finishes`、`conservation/tool-vanished`、`conservation/pair-broken`、`conservation/capped`、`failures/never-here`、`failures/unknown-kind`、`failures/jam`、`failures/deferred`、`failures/task-identity-missing`。
- **拒绝覆盖率**（我们关心的「拒绝覆盖率」）= 四张分类表 + 静态校验：
  - `NEVER_HERE`（这个受控世界里**不应出现**，出现即 red）、`PASSING`（世界竞争导致的正常拒绝）、`UNASSIGNED_PASSING`、`UNASSIGNED_TRANSIENT`、`UNASSIGNED_DEFERRED`（`tests/bench/report/judgements.ts:221-265`）。
  - `refusal-coverage.test.ts` 反向校验：源码里每个 `RefusalKind` 常量、每个 `Unassigned.Reason` 必须归表，表里不许留僵尸条目，且拒绝常量总数须 >30（防解析失效）。**这是整套基建里最值得抄的一个「防误报」设计。**
- **观测到的接缝**：`judge*` 三个函数在本副本中只被 `judgements.test.ts` 调用，`large-colony.bench.ts` 未调用它们——bench 报告目前以**原始数据 + `caveats`** 为主，判定留给外部分析（很可能就是给 AI 读的）。

### 5.3 报告如何生成

`tests/out/bench/reports/large-colony.json`（`schema_version 0.4.0`）字段分区：`environment`（含 heap/view-distance/地形/labor）、`setup`（town/roster/orders/staffing/rail/dat/reload/zones/members/animals/integrations/population）、`perf_controls`（P0 无殖民地 / P2 全量设置的 tick 代价对比）、`run`、`conservation`（前后物品盘点）、`end_state`（path_queue/rail_reach/loose_pieces）、`video`、`hero_shots`、`raw`（4 个 CSV + census + 各探针 note）、`caveats[]`、`fatal`。

同目录还会落：`large-colony.ticks.csv`、`.work.csv`、`.exertion.csv`、`.yield.csv`、`.census.ndjson`、`.server.log`、`.layout.json`。分析用 Python：`tools/summarise.py`（单次摘要）、`tools/compare.py`（**与 `tests/out/bench/reports.baseline/` 逐项对照**）、`tools/stalls.py`、`tools/recut.py`、`tools/save-town.ts`。

---

## 6. 视觉与影像

### 6.1 visual 套件（截图 / 录屏 / 布局回归）

`tests/visual/` 12 个 spec（`build`、`colony-shell`、`ghosts`、`handoff`、`looks`、`panels`、`patterns`、`picker-shots`、`ponder`、`resident-ui`、`zones`、`zones-panel`），核心是 `tests/shared/capture/visual-kit.ts` 的 `VisualRun`：

- `shot(client, name, {subject, worldState, camera, hard})`：`media.screenshot()` → PNG；记录 sha256/terrain/可见窗口列表/bytes；`hard` 时断言「captured 且 bytes>0」。所有条目写 `tests/out/visual/takes/<scope>/index.json`。
- `clip(client, server, name, {seconds, fps, audio, during})`：`media.record()` 录制；gates 含 frames/dropped/audio muxed/duration/**black_fraction**/ticks_advanced；断言非空（≥32 KiB）且黑帧 <50%。设 `FOLKWAYS_VISUAL_IMAGES_ONLY=1` 时退化为 start/middle/end 三张 PNG（跳过视频，便于无 GPU 环境）。
- **覆盖度门禁**（比截图本身更有价值）：`expectTaken()`（预期拍到的镜头必须真在）、`expectWindows()`（每个注册窗口必须有开窗场景）、`expectLintClean()` / `expectLinted()`（每个页面必须被 lint 过）。`visual-teardown.ts` 汇总成 `tests/out/visual/takes/index.html` + `INDEX.md`，并明确写「状态列只说明管线成立，不说画面对不对——按眼验收」。
- 布局 lint：`tests/shared/capture/layout-lint.ts`（531 行）通过 LDLib2 适配器读元素矩形/文本/`TextWrap`，按规则报 `error`/`warn`（溢出、被裁、填充率不足、文字被卷走等），`formatReport()` 出可读报告。
- 相机控制：`camera.set/reset`、截图可带 `camera` 位姿（`tests/visual/panels.spec.ts:109-114` 俯视全场）。

### 6.2 promo 套件（宣传片）

- 10 个 `*.take.ts`：`airship / declare / household / logistics / models / overhead / overhead-patterns / patterns / rail / tour`，配置 `#promo` `#promo-sky` `#promo-land`。
- `tests/promo/promo-kit.ts`：`promoClip()` = 60fps + `audio: true`；`seedShaders()` 把 Complementary Reimagined 装进客户端实例；`hideHud`（F1）、`setFov`、`setWalkSpeed`、`setTickRate`、`cinematicWorld`（`stillWorld`）。
- 台词/字幕全在 `tests/promo/film/promo-text.toml`（符合「玩家可见文字集中管理」的仓库风格）。
- 剪辑：`tests/promo/film/build.py`（337 行）用 `ffmpeg/ffprobe` 按 take 里打的 marks 切片、变速、叠 Noto Sans CJK 字体（首次下载）、生成描述；`assemble.py` 合成，`overhead.py` 出俯视路径。
- bench 也会拍片：`tests/bench/film/{director,video,overlay}.ts` + `hud.html`。多相机（复用 `bench-cam-N` profile 的独立账号）由 director 派往最忙处；`npm run bench:overlay` 用 Playwright Chromium **逐帧**把 tick 时间/任务数/产量画成 HUD 叠到成片上（`tests/bench/film/overlay.ts`）。

### 6.3 对我们的用处

- **UI 回归**：`VisualRun` + 布局 lint + 覆盖度门禁这套组合，是自研面板最实用的自动化层（「有截图 ≠ 有人会看出它坏了」这句判据值得直接继承）。前提是自研 UI 若非 LDLib2，需要照 `tests/ldlib2/adapter.ts` 实现 `ui.Adapter`（约 255 行 + rules）。
- **宣传片**：思路可借（多相机、HUD 数据叠加、文案外置），但 take 脚本与 `promo-text.toml` 强绑 Folkways 玩法，只能当模板重写。

---

## 7. 复用结论

### 7.1 可直接照搬

| # | 对象 | 理由 |
| --- | --- | --- |
| 1 | `blockwright.toml` 的 **profile + `[mods.*]` + `npm run setup` → `.blockwright/mods.json` → Gradle `lib(name)` compileOnly** | 一套机制同时解决「可选联动的编译依赖」「测试实例的 mod 组合」「版本锁定/校验」。整合包几乎原样可用 |
| 2 | 测试目录学：每 suite 一个目录（`playwright.config.ts` + `tsconfig.json` + `global-setup.ts`），共享代码放 `tests/shared/`，绝不跨 suite import；输出统一 `tests/out/<suite>/<bucket>/` | 边界清晰、可并行、可按层挑命令（`CONTRIBUTING.md:77-80`） |
| 3 | `globalSetup` 三步曲：`ensureOut` → `checkSpecTypes`（类型错就拒绝启动 MC）→ `buildMod`（`gradle build -x test`） | 直接把 AI agent 最低级的错误挡在启动 Minecraft 之前，省时省钱 |
| 4 | `src/gametest`（现为 mods/*/src/gametest） 三件套 + `runGameTestServer` | **Windows 上唯一能本机跑的游戏内测试层**，自研插件的第一道功能验证 |
| 5 | `javaTask` 探针范式（tick meter / work tap / census）+ 报告「全原始数据、不汇总」 | 无侵入观测；原始数据留给后续（人或 agent）分析 |
| 6 | 拒绝原因分类表 + `refusal-coverage.test.ts` 式静态校验 | 整合包的失败路径（缺 mod、版本不符、配置非法）同样需要「不许未归类」的纪律 |
| 7 | 视觉门禁与索引（`expectTaken/expectWindows/expectLinted` + `index.html` + `INDEX.md`） | 素材与回归兼得，且有明确的「机器只判管线、人判画面」分工 |
| 8 | i18n 目录测试（键集合 + 占位符 + 枚举覆盖） | 自研文本可精简为 zh_cn/en_us 两语，逻辑照抄 |
| 9 | `.claude/settings.json` 的 worktree 软链（`node_modules`、`.blockwright-store`） | 六阶段阶段四「多 agent 并行」的前置条件 |
| 10 | `apiJar` + `publish` 到 `build/repo` 的做法 | 自研插件对基底的编译期契约，版本化、可替换 |

### 7.2 必须替换 / 自建

| # | 对象 | 原因与替代 |
| --- | --- | --- |
| 1 | **Blockwright 本体** | `0.1.0-alpha.1`、仅 Linux x64。Windows 开发下「真客户端」层完全不可用。替代：(a) 追加一台 Linux 机器/自建 runner 跑 e2e+visual+bench+fuzz；(b) 或降低自动化上限，只保留 gametest + 单元 + 静态层，人工验收 |
| 2 | npm scripts 里的 `gradle` 调用 | `package.json:6`、`tests/shared/harness/setup.ts:21`、`tests/fuzz/global-setup.ts:10`（已随上游 0af84f0 删除） 都用裸 `gradle`，Windows 要换 `gradlew.bat`（否则 globalSetup 直接炸） |
| 3 | ffmpeg / Chromium / 字体的外部依赖 | `tests/e2e/farm-blackbox.spec.ts:583-608` 硬编码 `/usr/bin/ffmpeg`；`promo/film/build.py` 下载 Noto CJK；`bench:overlay` 用 Playwright Chromium。Windows 要安装并改路径 |
| 4 | LDLib2 UI adapter（`tests/ldlib2/`） | 与产线 UI 框架绑定；自研 UI 需实现 Blockwright 的 `ui.Adapter` + 自己的 rules |
| 5 | promo take 脚本与 `promo-text.toml` | 内容强绑 Folkways 玩法，只能当模板 |
| 6 | 覆盖率与性能的互斥设置 | `BLOCKWRIGHT_COVERAGE` 会拖慢 wall-clock，bench/promo 都显式置 0（`tests/bench/playwright.config.ts:6`、`tests/promo/playwright.config.ts:6`）；我们自建性能门禁时必须照做 |
| 7 | 三个 fuzz target（约 4000 行 Java） | 价值来自 Folkways 内核的 package-private 结构；只应照搬 `campaign.ts`（已随上游 0af84f0 删除）/`fuzz-kit.ts`（已随上游 0af84f0 删除）/`Live` 框架，为自研插件的核心算法（如配置求解/任务调度）写 1 个 target |
| 8 | CI 流水线 | 上游 CI 只跑 build/typecheck/unit（`.github/workflows/build.yml`）。我们要补游戏测试层（见 §7.1-1 的平台选择） |
| 9 | `CONTRIBUTING.md` 与 `package.json` 的不一致 | 文档写 `npm run promo:take`，但 `package.json` 里**没有**这个 script（只有 `visual:take`/`bench:take`/`fuzz:run`）；promo 实际要 `npm exec -- playwright test --config tests/promo/playwright.config.ts`。我们自己的文档要避免这类漂移 |

### 7.3 建议放弃

1. **把 400 居民级 bench 当日常门禁**：单次 ≥60 min + 运行时长、3G 堆、还要 GPU。建议「里程碑前跑一次 + `compare.py` 式基线对比」，日常用 gametest + 小规模 fixture。
2. **promo 影视流水线**（ffmpeg 切片 + CJK 排版 + 字体下载 + Chromium 叠加）：除非确有宣传片需求，性价比低。
3. **四语言翻译矩阵**（en/zh_cn/zh_hk/zh_tw）：整合包若面向简中，只保留 zh_cn + en_us，但保留 `lang.test.ts` 的检查逻辑。
4. **`attachFailureEvidence` 之外的全量 UI 树快照**：先只留失败时的容器/实体快照（`tests/shared/harness/pair.ts:71-89` 的用法），避免存储爆炸。

### 7.4 Windows 开发环境的坑（清单）

1. **平台**：`CONTRIBUTING.md:10-12` 明确 Blockwright 仅 Linux x64 → e2e/visual/bench/promo/fuzz/coverage **六层全部不可本机运行**；而 CI 也不跑它们（`build.yml` 只有 build/typecheck/unit）。Windows 上能跑的只有：lintScaffold、typecheck、test:unit、test:i18n、gametest（⚠️ 理论可行，仓库未验证）。
2. **裸 `gradle`**：见 §7.2-2，三处调用点。
3. **`/usr/bin/ffmpeg|ffprobe`**：`tests/e2e/farm-blackbox.spec.ts:583-608`。
4. **硬链接依赖**：实例目录从 `.blockwright-store` 硬链接填充（`tests/shared/harness/run-id.ts:3-7` 注释），跨盘符或受限 ACL 的 NTFS 目录会失败；Blockwright 对 Windows 无官方支持，遇到即无解。
5. **glob 与引号**：`test:unit` 把 glob 作为字符串传给 `node --test`（`package.json:9`），Windows cmd/PowerShell 不做展开，靠 Node 自己解析；一旦有人改写命令要注意引号语义差异。
6. **内存/句柄压力**：e2e 默认 `workers: 4`（`tests/e2e/playwright.config.ts:10`）、每个实例 1~3G 堆（`blockwright.toml:4, 157`），Windows 上更易 OOM/句柄耗尽；务必用 `--workers=1`（`CONTRIBUTING.md:68-75`）。
7. **首跑下载量大**：MC、NeoForge、Terralith/Tectonic/Create 等首个游戏套件会拉数个 GB，且 `eula = true` 代接受 EULA（`blockwright.toml:7`）——合规上要有意识。
8. **`.mcp.json` 的 agent 通道**：它依赖 Blockwright，因此 Windows 上「让 agent 到游戏里操作 UI」这条路同样不可用；这直接削弱「AI 干活 + 自动验证」闭环，是我们选择开发平台时必须先定的事。