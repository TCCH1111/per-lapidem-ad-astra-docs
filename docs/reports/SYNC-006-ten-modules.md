# SYNC-006 · 移植第四阶段：**十个模块、全套 plaa_* 跑起来了**（1465 / 1467）

```
状态：进行中（只剩 2 条失败）
验证者：DSH 会话
验证日期：2026-11-05
关联：SYNC-003/004/005、ADR-023、D15
main：c456385（四件套全绿，未受影响）
移植分支：port/aaac8b8 → **aec3fbf**
```

---

## 1. 本轮由你的四个决策驱动

| 决策 | 你的选择 | 影响 |
| --- | --- | --- |
| 移植优先级 | **先把移植收尾** | 继续 port，不切功能开发 |
| 两条失败 | **继续二分定位** | 已排除 3 类可能，下一步逐文件回退 |
| `rules-first`（D12） | **不做**，保持需求优先 + 解释 | D12 关闭为"不做"，不再占队列 |
| 模块范围 | **6 个上游模块全要** | port 从 4 模块扩到 **10 模块** |
| modid 方案 | **10 个全改 `plaa_*`** | 统一品牌；每次同步要跟着改 |

---

## 2. 十个模块全部构建成功

```
plaa-core / plaa-vanilla / plaa-create / plaa-modulargolems
plaa-cookery / plaa-chiselsandbits / plaa-rts / plaa-tacz
plaa-warfare / plaa-firefighting
```

`./gradlew build` → **BUILD SUCCESSFUL**，产出 **10 个 jar**（`build/libs/plaa-*-neoforge-1.21.1-0.1.0.jar`）。

### 改名覆盖的范围

| 位置 | 改动 |
| --- | --- |
| `mods/*/build.gradle` | `ext.modId` / `ext.modName`（决定 jar 名） |
| `mods/*/src/main/resources/META-INF/neoforge.mods.toml` | 各模块的 `modId` 依赖声明 + 显示名 |
| 根 `build.gradle` | `modProjects` 键 |
| `blockwright.toml` | `[mods.*]` 段、jar 路径、**profile 的 mods 列表** |
| **资源命名空间 `assets/folkways`、`data/folkways`** | **不动**（改了配方/标签/存档全废） |

---

## 3. 一个只有跑起来才会发现的错误（这轮最有价值的部分）

改名后第一次跑游戏测试，**整个服务器起不来**：

```
FATAL: Mod plaa_create is incompatible with plaa_core 0 or above
FATAL: Mod plaa_core is incompatible with plaa_core 0 or above
...
```

**原因**：我加过 4 条"与上游 `folkways_*` 不兼容"的声明，改名脚本把它们**也改成了 `plaa_*`** ——于是每个 mod 声明**与自己、与兄弟模块不兼容**。

**修法**：这类声明必须是 `type = "incompatible"` 的块，把它们的 `modId` 指回**上游**的 `folkways_*`（那才是它们本该拒绝的东西）。

**教训**：modid 改名不能是"全库字符串替换"——**语义不同的引用要分开处理**（依赖 vs 不兼容声明 vs 资源命名空间）。这已经是本项目第二次栽在"一刀切替换"上（上一次是 `Standing → Veto` 误伤基底方法）。

---

## 4. 测试现状

```
批次累加总数：1467 条
失败：2 条（与 4 模块时完全相同）
```

这两条依旧在 `SeedObservationGameTests`（与上游逐字一致的文件），症状是**规划预算从未完成对容器的观测**。

已排除：
- 我们的新增注入（关掉插件安装 + 否决权查找 → 仍失败）；
- 我们新增的 23 个测试（移走 → 仍失败）；
- 夹具缺失（26 → 38 与上游一致 → 仍失败）；
- `blockwright.toml` 差异（采用上游全文 → 仍失败）。

下一步：**逐文件回退**（把嫌疑的引擎文件换回上游版本再跑），锁定到具体文件。

---

## 5. 状态

| 项 | 值 |
| --- | --- |
| `compileJava` | ✅ 10 模块 |
| `./gradlew build` | ✅ 10 个 jar |
| `runGameTestServer` | **1465 / 1467** |
| `main` | `c456385` 未受影响（714/714） |
| 移植分支 | `aec3fbf`（已推送） |
