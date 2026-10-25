# VERIFY-037 · WP-8 / 第二段：数据真的走了殖民地仓库（702/702）

```
状态：通过（WP-8 第二段；整局重启仍待）
验证者：DSH 会话
验证日期：2026-10-26
关联：VERIFY-036、D11
fork 提交：72f8ef1
```

---

## 1. 结论

两个插件的数据确实走的是**殖民地自己的 `keeps()` 仓库**，而不是内存里另存一份：

```java
data.keeps().keep(SteeringContent.ID, before.save());   // 写
SteeringState.load(Reader.of(data.keeps().kept(SteeringContent.ID)));   // 读回
```

游戏测试：**`All 702 required tests passed`**（699 + 3）。

---

## 2. 三个测试

| 测试 | 断言 |
| --- | --- |
| `theZonesGoThroughTheColonyBag` | 存两个格子的禁入区 → 读回 1 个区、仍禁那两格、其它格不禁 |
| `theTimetableGoesThroughTheColonyBag` | 开关 + 夜班 + 时钟 → 三项都回来，且 `working()` 与存前一致 |
| `anUntouchedColonyReadsAsEmpty` | 没配置过的殖民地：0 区、作息关闭、**任何时刻都算工作时段** |

第 3 个尤其重要：它证明"新殖民地默认不受约束"，也就是我们插件的**默认零影响**在仓库层也成立。

---

## 3. 这证明了什么、没证明什么

| 已证 | 未证 |
| --- | --- |
| `keep → kept` 往返：我们写的 tag 就是读回的 tag | **整局存盘 → 停服 → 重启 → 读回**（level NBT 的写入与加载） |
| 空仓库的默认语义 | 插件缺席时读到旧档里的 `folkways:steering` 数据（会不会崩） |
| 两个数据源互不干扰 | NBT 结构升级（加字段后老档怎么办） |

**所以 D11 只还了一半**：数据层通过，磁盘层没验。后者需要真实服务端跑一局——`.cache/test-server` 已具备条件，但需要一个能"建殖民地"的玩家，或一条测试命令。

---

## 4. 下一步（具体）

1. 找/加一条 `GameTestServer` 可用的殖民地创建入口（若上游有 `/folkways` 命令可用于建殖民地，服务端冒烟脚本里加一行即可）；
2. 或退一步：用命令方块/函数在测试存档里预置一个殖民地数据（`ColonyData` 的 NBT），验证服务端启动时能读回；
3. 两者都不成，就把"整局重启"记为**发布前人工验收项**（写进 ROADMAP 的发布清单），不硬凑自动化。