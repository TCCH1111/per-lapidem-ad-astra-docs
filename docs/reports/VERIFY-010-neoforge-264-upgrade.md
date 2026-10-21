# VERIFY-010 · NeoForge 21.1.264 升级尝试（A/B 证明回归，暂缓）

```
状态：阻塞（保留 233 构建；264 升级待定位）
验证者：DSH 会话
验证日期：2026-10-20
关联：ROADMAP 队列 ③、ROADMAP D3、ADR-023 ②（版本升级单独提交）
```

---

## 1. 结论

把构建从 **21.1.233 升到 21.1.264**：**编译通过、jar 正常产出**，但游戏测试**稳定失败 1 条**（`onefoodcannotfeedhalfofapair`，`NoSuchElementException`），连跑两次均失败；退回 233 后**同一套测试 651/651 全绿**。

→ **判定为 264 的回归/不兼容，不是偶发**。当前**保持 233 构建**（fork 工作树已回退，无改动），整合包仍声明 264（运行期已验证兼容）。升级延后，等待定位。

---

## 2. A/B 证据

| 轮次 | 构建版本 | 编译 | 游戏测试结果 |
| --- | --- | --- | --- |
| A1 | 21.1.264 | ✅ `BUILD SUCCESSFUL`（`--rerun-tasks`，30 tasks executed） | ❌ `1 required tests failed`：`onefoodcannotfeedhalfofapair` @ `-13478043, -60, 14587814` |
| A2（复跑） | 21.1.264 | （无需重建） | ❌ 同一测试失败 @ `6848068, -60, -4986157`，`java.util.NoSuchElementException` |
| B | 21.1.233 | ✅ `BUILD SUCCESSFUL` | ✅ **`All 651 required tests passed :)`** |

依赖解析确认（264 时）：`net.neoforged:neoforge:21.1.264`（`./gradlew :core:dependencies --configuration compileClasspath`），不是"改了没生效"。

---

## 3. 264 下另外出现的新错误

```
[Server thread/ERROR] [folkways-patterns/]: minecraft:looping:
  java.lang.IllegalStateException: minecraft:lib/b loads minecraft:lib/a,
  which is still loading: a load cycle (Starlark…)
java.lang.IllegalStateException: machine broke
```

264 上运行时多出这条 Starlark 装载环错误（233 的日志里没有）。它**未被计入 failed tests**，但说明 264 在图案/脚本装载顺序上也有行为差异——升级时同样要看。

---

## 4. 回退后的状态（已核对）

```
git status: 干净（无未提交改动）
gradle.properties: neoforge_version=21.1.233
HEAD: 7344f9d feat(b2): rename modids to plaa_* …
游戏测试: All 651 required tests passed :)
```

整合包侧不变：`pack/pack.toml` 的 `neoforge = 21.1.264`（客户端/服务端实测都能跑），**构建 233 / 运行 264** 的组合继续沿用。

---

## 5. 下一步（把这条债务还清）

| # | 动作 | 说明 |
| --- | --- | --- |
| 1 | 读 `onefoodcannotfeedhalfofapair` 的测试源码 | 看它依赖什么（食物组件/喂养事件/实体查找），`NoSuchElementException` 指向"找不到某个元素"（可能是 `getFirst()` 之类） |
| 2 | 在 264 下最小复现 | 单独跑该测试（`-Dneoforge.enabledGameTestNamespaces` 或用 `--tests` 思路），确认是否与 food 组件变更有关 |
| 3 | 查上游 | 上游 `master` 仍钉 233；若上游也未适配 264，则这条属于"上游未支持"，可暂不跟进 |
| 4 | 决定 | 若只是该测试的断言过时 → 用 L1/L2 修测试；若是引擎行为变化 → 记录为 264 已知问题，等上游 |

---

## 6. 为什么这不算"白做"

- 明确了一个**不确定项的真实边界**：264 不是"升一下就行"，而是有确定性差异；避免了在发布版里埋一条会挂 CI 的升级。
- 留下了可复现的 A/B 记录，下次任何人动版本都能从这一步开始，而不是重跑一遍猜测。

---

## 7. 补充调查（2026-10-21）

### 7.1 第三次复现，并排除了"编译期"因素

复现脚本在 264 下跑：`./gradlew build --rerun-tasks` **因网络失败**（`maven.neoforged.net: Network is unreachable`，拉 `com.eed3si9n.starlark:starlark` 元数据），但随后 `runGameTestServer` 仍然运行并**第三次**在同一测试上失败：

```
[20:46:11] onefoodcannotfeedhalfofapair failed at -14782107, -60, 11459590! java.util.NoSuchElementException
[20:46:20] 1 required tests failed :(
```

→ 这次 jar 是早先 264 编译成功时产出的（或缓存），说明**失败发生在运行期，与编译无关**；而今天的 build 失败只是网络问题（`Network is unreachable`），不是代码问题。

### 7.2 静态分析：`NoSuchElementException` 的两个可能抛点

`PastureBreedingGameTests.oneFoodCannotFeedHalfOfAPair` 的调用链里有两处 `getFirst()`：

| 位置 | 代码 |
| --- | --- |
| 测试本体 `:139` | `Node node = rig.nodes().getFirst();` |
| `Rig.nodes()` 内部 | `Herd.Tally tally = herd.reconcile(view(), front(), new ArrayList<>()).getFirst();` |

两者在**空列表**时都抛同一个 `NoSuchElementException`。也就是说，问题几乎可以锁定为：**264 下牧场群（herd）的 `reconcile(...)` 没有产出任何 tally**（或 `rig.nodes()` 没有产出任何目标），而不是某条断言的期望值不对。

配合 264 上另外出现的 `folkways-patterns` Starlark 装载环错误（§3），更可能是 **264 改变了某些装载/扫描顺序**，导致测试夹具里的牧场没有被识别。

### 7.3 结论与决定（不变）

- 这**不是我们的代码在 264 下的编译问题**，也不是随机偶发：三次运行、三个不同坐标，稳定失败同一测试。
- 上游 `master` 仍钉 **21.1.233**，说明上游本身未声称支持 264；这条更可能是"上游尚未适配"而不是"fork 引入"。
- **保持 233 构建**；264 升级继续挂起（D3）。整合包按 264 运行已由客户端/服务端实测证明，不受影响。
