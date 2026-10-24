# VERIFY-018 · WP-4 / T5：`SteeringRefusal` 与四语文案（668/668）

```
状态：通过（T5 完成；T6/T7 待做）
验证者：DSH 会话
验证日期：2026-10-24
关联：PLAN-003（T5）、VERIFY-017（665 基线）
fork 提交：6ac1327
```

---

## 1. 结论

禁限区有了**玩家能读到的理由**：`SteeringRefusal` 用基底 `RefusalKind.Named` 的命名规则自动得到 `folkways.refusal.steering.*` 键，**不需要改上游**；四个语言文件都补了三条文案。

游戏测试：**`All 668 required tests passed`**（665 + 3）。

---

## 2. 交付

| 文件 | 层 | 内容 |
| --- | --- | --- |
| `plugins/steering/SteeringRefusal.java` | L1 | `FORBIDDEN / ONLY_FOR_OTHERS / QUOTA_FULL`；`of(Verdict)`；`lasting()` |
| `core/src/main/resources/assets/folkways/lang/{en_us,zh_cn,zh_hk,zh_tw}.json` | **L2（各 +3 行）** | `folkways.refusal.steering.*` |
| `gametest/.../SteeringRefusalGameTests.java` | L1 | 3 个测试 |

**`lasting()` 的语义**（给诊断层用）：

| 取值 | 含义 |
| --- | --- |
| `FORBIDDEN` / `ONLY_FOR_OTHERS` → `true` | 等不会好，玩家必须改区 |
| `QUOTA_FULL` → `false` | 人走开就自动恢复 |

---

## 3. 证据

```
$ ./gradlew build --offline            → BUILD SUCCESSFUL in 14s
$ ./gradlew runGameTestServer --offline
[22:25:27] onefoodcannotfeedhalfofapair failed … java.util.NoSuchElementException   ← 已知跨版本偶发
[22:27:44] All 668 required tests passed :)                                          ← 同一份代码复跑
```

**关于那次失败**：就是 VERIFY-010 §8 记录过的偶发测试（233 与 264 都抽到过），与本轮改动无关；复跑即全绿。这也再次印证了"它不是 264 回归"的更正。

四份 lang JSON 都用 `ConvertFrom-Json` 解析验证过，**无语法错误**。

---

## 4. 遗留

| # | 项 | 何时补 |
| --- | --- | --- |
| 1 | `zh_hk`/`zh_tw` 目前用的是与简体相同的措辞，未做港台用词差异 | 双语润色轮 |
| 2 | `Unassigned.Reason.ZONE_FORBIDDEN` → `SteeringRefusal` 的**运行时映射**尚未接到面板/`/plaa why` | T7 |
| 3 | `QUOTA_FULL` 还没有运行时计数来源（`insideCount`） | T6/T7 |