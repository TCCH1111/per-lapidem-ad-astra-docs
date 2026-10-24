# VERIFY-019 · WP-4 / T6：禁限区页面（列表 + 删除）

```
状态：通过（T6 部分完成；T6b 画区接线待做）
验证者：DSH 会话
验证日期：2026-10-24
关联：PLAN-003（T6）、VERIFY-018（668 基线）
fork 提交：c1a9bcf
```

---

## 1. 结论

禁限区进了殖民书：新增 `SteeringFacing`（实现 `Facing`），页面列出每个区域的**类型与格数**，每行一个"删除"动作。**没有新增 `Board.Act` 动词**——用的是通用的 `Do(actionKey, labelKey)`。

游戏测试：**`All 668 required tests passed`**（无新增测试，页面靠编译 + 既有回归保护）。

---

## 2. 交付

| 文件 | 层 | 内容 |
| --- | --- | --- |
| `plugins/steering/SteeringFacing.java` | L1 | `board(...)`：标题 + 每区一行（图标 `barrier`、名称、`kind` + 格数、`Do(steering.remove:<id>)`）；空态一行提示；`act(...)` 解析 key → `state.remove(uuid)`，格式错则 `Attempt.refused(SteeringRefusal.FORBIDDEN)` |
| `SteeringContent.java` | L1（改） | `ZONE` 委托 id、`REMOVE` 前缀、`PAGE`（`PageKind.boarded`）、`enroll(Registering)`：注册 `facing` + `enrollment`（`Delegation(ZONE, Shape.Volume(maxFarmCells()), barrier)`） |
| `SteeringPlugin.java` | L1（改） | 增加 `Registering` 监听 |

**界面上限**：每行 1 个动作（基底允许 4），无新增图表；空态占 1 行。

---

## 3. 证据

```
$ ./gradlew build --offline    → BUILD SUCCESSFUL in 13s
$ ./gradlew runGameTestServer --offline
[23:26:24] onefoodcannotfeedhalfofapair failed …      ← 已知偶发
[23:30:22] All 668 required tests passed :)            ← 同一份代码复跑
```

---

## 4. 明确未做（T6b）

| # | 项 | 为什么现在做不了 |
| --- | --- | --- |
| 1 | **把玩家画的体积接成 `ZoneRule`** | 需要在 tick 里读 `colony.blocks(ZONE)` 并 upsert；本轮先保证页面可用，避免把"画区"半成品塞进主线 |
| 2 | **删除区域时清掉已画格子** | 基底 `Delegation` 只有"声明形状"，没找到"擦除已画格"的 API；不清的话删除后下一 tick 会被重新 adopt，需要先找到擦除方式或加"忽略签名"机制 |
| 3 | 面板端到端手工验证（进游戏翻书） | 需客户端实测；下一轮与 T7 一起做 |

---

## 5. 流程问题登记（新增债务）

本轮的偶发测试 **再次** 命中（近两次改动各命中一次，约 50%）：

```
onefoodcannotfeedhalfofapair … java.util.NoSuchElementException
```

它已经不只是"偶发"，而是**挡住了"全绿"这条证据仪式**——每次都要复跑。已记入 ROADMAP 债务（D7），候选处理：
1. 上游若修好就跟进；
2. 把该测试标为非必过（若引擎支持 per-test `required=false`）；
3. 在 CI 脚本里对**仅此一条**失败做一次自动重试并记录（不掩盖其他失败）。