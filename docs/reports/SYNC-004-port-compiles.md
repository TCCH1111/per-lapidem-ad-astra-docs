# SYNC-004 · 移植第二阶段：配置全部解开，**主源码编译通过**

```
状态：进行中（关键里程碑）
验证者：DSH 会话
验证日期：2026-11-05
关联：SYNC-003（第一阶段）、D15
main：c456385（四件套全绿，未受影响）
移植分支：port/aaac8b8 → **c231de2**
```

---

## 1. 结论

**主源码 `compileJava` 通过**——我们的 4 个模块 + 上游这一年的新代码能一起编译。剩下的是**测试面**：上游删掉了 `Solving.java`，我们的测试夹具改动无处落地。

```
./gradlew compileJava        → BUILD SUCCESSFUL in 24s
./gradlew compileGametestJava → 1 个 error（VetoGameTests 引用 Solving）
```

---

## 2. 一处必须更正上一轮的说法

SYNC-003 我写"上游新增的都是 `mods/vanilla` 里的包，移植时自然带过来"——**这是错的**。

实际情况：上游新增了 **6 个真实模块**：

| 上游模块 | 我们是否构建 |
| --- | --- |
| `cookery` / `chiselsandbits` / `rts` / `warfare` / `tacz` / `firefighting` | ❌ 不构建（本 fork 只发 4 个） |
| `core` / `vanilla` / `create` / `modulargolems` | ✅ |

另外上游还有一个 `:capture` 测试工程（推广短片用），我们也不需要。

**代价**：不是"白捡"，而是要**把 6 个模块的接线全部摘掉**（下一节）。

---

## 3. 这轮做的结构性手术

| 文件 | 改动 |
| --- | --- |
| `settings.gradle` | 只 include 4 个模块；去掉 `:capture` |
| `blockwright.toml` | 保留我们 4 个 `plaa_*` 条目；**补上** `jecharacters`、`pinin`、`kaleidoscope_cookery`（上游新代码要链接它们） |
| `build.gradle`（根） | 移除 `:chiselsandbits` 源集注入；`modProjects` 只留 4 个 |
| `mods/core/build.gradle` | 移除 `cookeryTest` 依赖块 |
| `mods/vanilla/build.gradle` | 移除 `cookeryTest` / `rtsTest` / `warfareTest` 三套源集与依赖 |
| `Labor.java` | 以上游重构后的 tick-budget 循环为骨架，把否决权查找插回去（方法名是 `standing`，不是 `veto`） |
| `BuiltinPlugins.java` | 并集：上游新插件 + 我们的 `SteeringPlugin` / `HoursPlugin` |
| `README.md` | 取上游新版（覆盖现在真的带过来的功能）+ 加 fork 说明统一段 |
| `CONTRIBUTING.md` / `build.yml` | 取我们 fork 的版本（VERIFY-045 已实测） |

---

## 4. 构建环境的两个坑（都记下来）

1. **worktree 缺 `node_modules`**：`npm run setup` 报 `blockwright: not found`。
   → 从主工作树**符号链接** `node_modules` 与 `.blockwright-store` 即可，无需重装。
2. **`gradle/mod.gradle` 按名字校验集成**：报 `mod jecharacters is missing`、`mod pinin is missing`。
   → 这些不是 `\#[mods.x]` 缺失，而是模块 `build.gradle` 里 `lib("x")` 的要求；补齐 pin 后 `npm run setup` 同步 **26 个 mod**。

---

## 5. 剩余工作（下一轮）

| # | 项 | 说明 |
| --- | --- | --- |
| 1 | **`Solving.java` 重定位** | 上游已无此文件；我们的 `planner.standing(...)` 夹具改动要适配到上游新的测试骨架 |
| 2 | 我们 48 个新文件的测试适配 | 引用旧 API 的地方（`Planner`/`Scheduled`/`Fixture`） |
| 3 | 跑 `runGameTestServer` | 目标 **714 全过**（数量可能因上游新增测试而变化） |
| 4 | 四件套 | build / unit / i18n / gametest |

---

## 6. 诚实边界

- 移植分支**测试尚不能编译**，因此**还不能说移植完成**；
- `main` 未受影响：`c456385`，714/714；
- 所有进度已推送（`origin/port/aaac8b8` = `c231de2`）。
