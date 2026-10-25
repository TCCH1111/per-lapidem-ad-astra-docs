# VERIFY-025 · WP-5 / T4：作息页面与两个开关（686/686）

```
状态：通过（T4 完成；T3 白名单测试与 T6 登记待做）
验证者：DSH 会话
验证日期：2026-10-25
关联：PLAN-004（T4）、VERIFY-024（684 基线）
fork 提交：d0bfaf4
```

---

## 1. 结论

作息现在**玩家可开可调**：页面里一个开关（默认关）+ 一个班次选择，页面本身显示"当前班次 / 还有几秒切换"。全量测试 **686/686**（684 + 2）。

---

## 2. 交付

| 文件 | 层 | 内容 |
| --- | --- | --- |
| `HoursContent.java` | L1 | `ENABLED`/`PRESET` 键、`SETTINGS`（`Flag` + `Choice`）、`enroll(...)`（页面 + facing）、tick 里把设置抄进 `HoursState` |
| `HoursFacing.java` | L1 | 一行：时钟图标 + "当前：白班 · 6000 秒后切换"；未启用时显示"殖民地未设作息" |
| `HoursPreset.named` | L1 | 兼容枚举名**与物品路径**（`daylight_detector` → 白班） |
| 四个语言文件 | L2（各 +10 行） | 页面标题/状态/切换/未启用/四班次/两个设置名，JSON 均已重新解析 |

---

## 3. 一个不得不做的妥协（写清楚）

基底 `Schema.Setting` 只有 `Flag / Count / Choice / Items`，**没有"时段"类型**。`Choice` 的选项是 `ResourceLocation`，实际显示的是**物品名**。

于是四个班次借用四个读得懂名字的物品：

| 物品 | 班次 |
| --- | --- |
| `minecraft:clock` | 自由（默认） |
| `minecraft:daylight_detector` | 白班 |
| `minecraft:lantern` | 夜班 |
| `minecraft:iron_sword` | 戒严 |

**代价**：选项标签是物品名（"Clock"/"Daylight Detector"…），不是"白班/夜班"。真正的 24h 条带需要新增 `Schema.Setting` 类型 = L3，w05 也把它列在 WP-5 的"时段设置类型"里——留给体验轮。

---

## 4. 两个测试

| 测试 | 断言 |
| --- | --- |
| `thePickIsTheItemThatStandsForIt` | 四个物品路径 → 四个班次；未知值回退自由 |
| `everyWordThePageShowsResolves` | 页面/设置共 **10 个键**全部能在运行时语言表里解析 |

```
./gradlew build --offline   → SUCCESSFUL in 13s
[21:16:06] All 686 required tests passed :)
```

---

## 5. 遗留

| # | 项 | 去向 |
| --- | --- | --- |
| 1 | 选项标签是物品名，不是"白班/夜班" | 需新 `Setting` 类型（L3），体验轮 |
| 2 | 需求（吃饭/如厕/睡觉）不受作息影响——按设计，但**尚无测试固定** | T3 |
| 3 | 时钟仍取主世界 `dayTime` | 多维殖民地会跟随主世界 |
| 4 | WP-5 的 T6（登记 + AC 勾选） | 收口时做 |