# VERIFY-013 · WP-1 / T2：`PresenceViews`（饥饿与床位只读视图，655/655 通过）

```
状态：通过
验证者：DSH 会话
验证日期：2026-10-24
关联：PLAN-002（T2）、PLAN-002-inventory（2.2）、VERIFY-012（T3）
fork 提交：77a3885
```

---

## 1. 结论

T2 完成：新增同包 public 门面 `PresenceViews`，把殖民地级服务 `LivingPresence` 里的**饥饿**与**床位占用**以不可变 record 暴露给诊断层。`LivingPresence` 只增加了 **2 个包内只读句柄**（`// PLA:` 标记），无行为改动、无 mutator 外泄。

游戏测试：**`All 655 required tests passed`**（653 + 新增 2）。

---

## 2. 改了什么

| 文件 | 图层 | 内容 |
| --- | --- | --- |
| `mods/vanilla/.../plugins/person/living/LivingPresence.java` | **L2（2 个方法，9 行含注释）** | `Hunger bellyOf(UUID)`、`Beds bedClaims()`，都是包内可见，标 `// PLA:` |
| `mods/vanilla/.../plugins/person/living/PresenceViews.java` | **L1（新文件）** | `hunger(Colony, UUID) → Optional<HungerView>`、`bed(Colony, UUID) → BedView` |
| `mods/vanilla/src/gametest/.../living/PresenceViewsGameTests.java` | **L1（新文件）** | 2 个 gametest |

**取得路径**（照抄上游既有写法，`LivingContent.java:75`）：

```java
colony.service(LivingContent.ID, LivingPresence.class)   // Optional<LivingPresence>
```

`LivingPresence` 是 `LivingContent.declare(...)` 里 `scope.share(state)` 注册的**殖民地级服务**，`Colony.service(...)` 是公开 API（`Colony.java:91`）。门面与它同包，因此能读 `bellies`/`beds`，对外只交 record。

**没有做的事**：没有把 `LivingPresence`/`Hunger`/`Beds` 提权；没有暴露 `Map`/`List` 本体；没有调用 `sweep`/`house`/`claim`（只读，不占床）。

---

## 3. 两个 gametest

| 测试 | 断言 |
| --- | --- |
| `aFreshBellyReadsAsFull` | `new Hunger()` → `foodLevel == MAX_FOOD_LEVEL`、`maxFoodLevel` 一致、`fullness == 1.0`、`starving == false` |
| `anUnclaimedBedReadsAsNone` | `BedView.none()` → `hasBed == false`、`bed` 为空 |

`viewOf(Hunger)` 是包内方法，测试因此不必构造整个殖民地；**殖民地查找路径本身未被 gametest 覆盖**（见 §5）。

---

## 4. 证据

```
$ ./gradlew build --offline                → BUILD SUCCESSFUL in 12s
$ ./gradlew runGameTestServer --offline
[15:19:54] All 655 required tests passed :)
```

（653 → 655：新增 2 个测试确实被注册并运行。）

---

## 5. 未验证 / 遗留

| # | 项 | 说明 |
| --- | --- | --- |
| 1 | **`colony.service(...)` 这条真实路径未测** | 测试只覆盖映射；真实路径与 `LivingContent.exerted` 同一写法，风险低但未证。等 WP-6 诊断层接入时用真实殖民地补一次 |
| 2 | `BedView` 只给"床位坐标"，没给"是否被占" | `Beds.bedFor` 是按居民查，占用关系已隐含；若要"某床被谁占"需另加 `residentsByBed` 读点（T2 未做，按需再加） |
| 3 | `HungerView` 没有 `saturation`/`exhaustion` | `Hunger` 这两个字段无 getter；要展示"饱食度"再补 2 行 getter（L2） |
| 4 | 行尾 | 编辑 `LivingPresence.java` 时曾整文件变 CRLF，已 sed 回 LF；`git status` 干净、无 EOL 噪声提交 |

---

## 6. WP-1 进度

| 任务 | 状态 |
| --- | --- |
| T1 盘点 | ✅ |
| T2 Hunger/Beds | ✅（本轮，655/655） |
| T3 BodyState | ✅（VERIFY-012，653/653） |
| T5 Urges | ⬜ 需 `ColonyLabor` 1 行包内 getter |
| T6 登记 | ⬜ 收尾时一次性登记（d12 表 + 变更清单） |
