# 内容作者手册

```
状态：草稿
负责人：整合包维护者 + 内容作者代表
最后更新：2026-10-18
上游依据：docs/pack/02-config-and-datapack.md（43 个货架、KubeJS 边界、R-CD-9/12/13）、
          docs/design/11-freedom-design.md（D1–D3 三级改写能力）、
          docs/design/12-fork-strategy.md（图层与 `// PLA:` 标记）、
          docs/prd/00-prd-template.md（§12 双语与 Component 规则）
下游影响：所有货架的作者文档、docs/workflow/03-test-and-acceptance.md（内容校验）、未来的社区模板仓库
```

> 一句话：**这本手册负责让"别人真的能写"**。
> 支柱 **P6「一切可被改写」** 与 [ADR-017](../00-charter.md)（KubeJS 为内容层）只有在"第三方照着文档就能写出一个能加载、能诊断、双语齐全、不卡的内容条目"时才成立。现在 43 个货架的规则散在 15 份 PRD 里，缺的正是这一份**面向作者**的入口。

---

## 0. 先搞清楚你在哪一层

[自由度设计](../design/11-freedom-design.md) 把"改规则"分成三级，**本手册只服务 D2**：

| 级别 | 谁 | 能改什么 | 手段 | 热重载 |
| --- | --- | --- | --- | --- |
| **D1 玩家** | 普通玩家 | 难度、叙述者、经济系数、时代门槛、界面 | `serverconfig` / 游戏内设置 | 部分（重启/新世界） |
| **D2 数据包作者** | **本手册的读者** | 新需求、新事件、新剧本、新势力、新图案、新药品、新气体告示… | **数据包 + KubeJS** | **是（`/reload`）** |
| **D3 程序作者** | 会写 Java 的人 | 新货架、新工作类型、新 UI 页、新实体、新维度 | 基底 `core/api`、`front/api` | 否 |

**本手册的承诺**：读完 §1–§7，你能写出一个**可加载、可被诊断解释、双语齐全、不拖慢服务器**的条目。
**本手册不承诺**：货架 schema 的字段名在 1.21.1 内**仍可能变动**（我们还处在 PRD 草稿阶段）。凡是"以 schema 为准"的地方，本文都会用 ⚠️ 标出来，并告诉你**怎么用自检命令当场确认**——这比背字段名可靠。

三句话记住边界：

1. **能改数值与文案的，一定不要写脚本。**
2. **能写数据的，一定不要写 Java。**
3. **玩法规则永远不在脚本里**（[R-CD-12](02-config-and-datapack.md)）——否则不可测试、不可诊断，删脚本就等于改规则。

---

## 1. 五分钟上手

### 1.1 最小目录树

一个能被加载的最小内容包，长这样（以"新增一条需求"为例）：

```
datapacks/
  my-content/
    pack.mcmeta
    data/
      my_content/
        folkways/
          need/
            cleanliness.json      # 一条需求定义
    assets/
      my_content/
        lang/
          zh_cn.json              # 需求的名称与描述
          en_us.json
```

三个要点：

- **`folkways/` 这一层是货架目录**，不能改名、不能多一层、不能换成 `incidents/`（复数）——加载器按**货架名**找目录，写错就是静默 0 条。
- **`my_content` 是你自己的命名空间**；`plaa` 是核心团队的，`folkways` 是上游的，**都不要用**（§2.1）。
- **`assets/` 是给客户端看的文案**，放在同一个数据包里也可以（数据包能带 `assets`），但更规范的是做成资源包随包分发。

### 1.2 一个最小的条目（只写必需字段）

```json
{
  "id": "my_content:cleanliness",
  "kind": "variant",
  "form": "state",
  "decay": 2.5,
  "mood_map": [
    { "below": 16, "mood": -25 },
    { "below": 41, "mood": -10 },
    { "below": 71, "mood": 0 },
    { "below": 101, "mood": 6 }
  ],
  "default_weight": 3,
  "satisfiers": ["wash_at:washbasin", "bathe_at:tub"],
  "icon": "my_content:textures/need/cleanliness.png"
}
```

加两份文案（键的推导规则见 §6）：

```json
{
  "my_content.need.cleanliness.name": "洁净",
  "my_content.need.cleanliness.desc": "身体、衣物与餐具的清洁程度。"
}
```

这就是全部。**没有脚本、没有 Java、没有配置项**——它已经能进需求栏、能衰减、能影响情绪了（§8.1 是它的完整版，多了专注度、特质加权与替换关系）。

> ⚠️ `mood_map` 的写法这里用"四段阈值 + 值"的数组表示。**具体编码以货架 schema 为准**（[PRD-001 §4.3](../prd/PRD-001-needs-mood-memory.md) 定义的是"四段映射"这一语义）。用 `/<ns> content keys` 可以看到你的条目缺了哪些键。

### 1.3 放哪、怎么加载、怎么自检

| 步骤 | 做法 | 说明 |
| --- | --- | --- |
| 1 放 | 玩家：`<存档>/datapacks/`；整合包作者：整合包根 `datapacks/` | 整合包自带的放根目录，玩家自制的放存档内（[R-PACK-6](00-pack-spec.md)：更新时不覆盖玩家改动） |
| 2 加载 | 进世界后 `/reload` | 新世界首次进入也会自动加载 |
| 3 看有没有进 | `/folkways library`（需 op2） | 列出条目、**来源 pack**、**被拒原因**（[R-CD-8](02-config-and-datapack.md)） |
| 4 看引用全不全 | `/<ns> content`（我们的自检命令） | 条目/拒绝原因/引用完整性（事件引用的物品、需求、势力是否都存在） |
| 5 看文案 | `/<ns> content keys` | 列出你缺的语言键与占位符不一致的键 |

**这三条自检命令是我们的，不是上游的**（⚠️ 命令名在实现阶段可能微调；以 `/<ns> help` 输出为准）。上游的 `/folkways library` 在我们 fork 之后**也覆盖新货架**（[F1 路线](02-config-and-datapack.md)），所以两边都要看一遍。

### 1.4 出错时先看哪里

- **日志**：`logs/latest.log`，搜 `plaa` 或 `folkways`。拒绝信息必须带**三样东西**：货架名、条目 id、原因对象（[R-CD-8](02-config-and-datapack.md)）。
- **不要在游戏里猜**：我们的纪律是"**错误必须在加载期就报出来**，不许运行才知道错"（[R-CD-9/R-CD-10](02-config-and-datapack.md)）。
- **别改 jar**：整合包内容一律通过**数据包 + 配置 + KubeJS** 分发（[R-CD-2](02-config-and-datapack.md)）。

---

## 2. 命名、路径与版本纪律

### 2.1 命名空间

| 命名空间 | 谁用 | 你能用吗 |
| --- | --- | --- |
| `minecraft` | 原版 | 引用可以，定义不行 |
| `folkways` | 上游基底既有内容 | ❌ 不要往里加东西（升级会冲突） |
| `plaa` | **核心团队**（我们的 fork） | ❌ 不要占用；要覆盖我们的条目，用"同 id 覆盖"而不是抢命名空间（§10 OQ-2） |
| `<你的 ns>` | 你 | ✅ 就用这个 |

### 2.2 一个硬契约：货架读取**所有命名空间**

**R-AUTH-1**：货架扫描的是**所有已加载数据包里**的 `data/<任意 ns>/folkways/<货架>/`；不是只读 `data/plaa/`。
理由：如果只读 `plaa`，第三方内容会**静默失效**——而"静默失效"比"报错"恶劣得多，因为它会让作者以为是自己写错了。

> ⚠️ 这条是**对实现的要求**，不是对现状的描述。若自检命令里看到自己的条目没被列出，先确认这一条是否已实现（把它当 bug 报，不要改自己的目录迁就）。

### 2.3 路径与文件名

```
data/<ns>/folkways/<货架>/<文件名>.json
```

- **文件名 = 条目 id 的 path**（`cleanliness.json` ↔ `my_content:cleanliness`）。不一致会在加载期被拒（§7.2 第 3 条）。
- 文件名 `snake_case`，只用小写字母、数字、下划线。
- 一个文件一条记录。**不要**把多条塞进一个数组——货架是逐条解析的，塞数组会得到"1 条"或"0 条"。

### 2.4 id 不可变

**R-AUTH-2**：**已发布的 id 不得改名、不得复用**。
存档会引用 id（事件引用需求、剧本引用货架、编年史引用事件），改名 = 老存档里的引用变成悬空（[PRD-002 R-DATA-2](../prd/PRD-002-incidents-and-narrator.md)）。

要废弃一个条目，**不要删文件**：

```json
{
  "id": "my_content:old_need",
  "deprecated": true,
  "deprecated_since": "2026-10-18",
  "replaced_by": "my_content:cleanliness"
}
```

保留至少**一个小版本**，让老存档有时间被迁移（§10 OQ-3）。

### 2.5 版本与 `pack_format`

| 项 | 规则 |
| --- | --- |
| `pack_format` | 必须与 **1.21.1** 匹配（以 `SharedConstants` 的当前值为准，**不在文档里写死数字**，避免跟着版本漂移） |
| 我们的数据包版本 | 独立于 `pack_format`，在 `pack.mcmeta` 的 `description` 里写明作者与版本 |
| 兼容声明 | 可写 `supported_formats` 放宽范围，但**只在你真的测过**的范围内写 |

### 2.6 分包与三档裁剪

整合包内容按模块分包（`plaa-core` / `plaa-needs` / `plaa-incidents` / `plaa-threats` / `plaa-ages` / `plaa-trade`），便于三档裁剪（[OQ-CD-4 未定](02-config-and-datapack.md)）。
**你的内容包不要依赖我们的分包结构**——只依赖货架与 id。

---

## 3. 43 个货架：作者视角

不要背 PRD 的表格，按"**你需要什么才能改它**"来分。

### 3.1 一张表看完

| 货架 | 作者能改什么 | 你需要 | 归属 |
| --- | --- | --- | --- |
| `need` | 需求名称、衰减、情绪/专注度映射、满足路径 | 纯数据 | [PRD-001](../prd/PRD-001-needs-mood-memory.md) |
| `addiction` | 物质类别、剂量、耐受、戒断曲线、过量阈值 | 纯数据 | PRD-001 / [PRD-013](../prd/PRD-013-medical-and-surgery.md) |
| `focus_source` | 专注度的来源与侵蚀速度 | 纯数据 | PRD-001 |
| `duty_priority` | 工作优先级的两级语义与打断规则 | 纯数据 | PRD-001 |
| `memory` | 记忆类别、权重、衰减、情绪挂钩 | 纯数据 | PRD-001 |
| `incident` | 事件模板：条件、权重、前兆、选项、后果 | 纯数据 | [PRD-002](../prd/PRD-002-incidents-and-narrator.md) |
| `narrator` | 叙述者预设（风格/频率/强度） | 纯数据 | PRD-002 |
| `season` | 季节曲线（温度、降水、日照） | 纯数据 | [PRD-003](../prd/PRD-003-season-temperature-thirst-nutrition.md) |
| `climate` | 气候档案（风土组合） | 纯数据 | PRD-003 |
| `threat_profile` | 威胁等级、波次、敌人组成 | 纯数据 | [PRD-004](../prd/PRD-004-threats-and-defence.md) |
| `scenario` | 开局条件 + 规则覆盖 + 目标 | 纯数据 | [PRD-007](../prd/PRD-007-scenarios.md) |
| `relation_kind` | 关系类型（师徒/挚友/仇敌…） | 纯数据 | [PRD-008](../prd/PRD-008-relationships-and-social.md) |
| `social_activity` | 社交活动（共餐/闲聊/庆典）与效果 | 纯数据 | PRD-008 |
| `grudge_cause` | 恩怨成因与强度 | 纯数据 | PRD-008 |
| `life_stage` | 生命阶段边界与能力 | 纯数据 | [PRD-009](../prd/PRD-009-generations-and-legacy.md) |
| `upbringing` | 教养路线与产出 | 纯数据 | PRD-009 |
| `ritual` | 仪式（含葬礼）流程与效果 | 纯数据 + 方块 | PRD-009 |
| `faction` | 势力档案（性格、偏好、军事） | 纯数据 | [PRD-010](../prd/PRD-010-diplomacy-and-trade.md) |
| `trade_goods` | 贸易品与基础价格 | 纯数据 | PRD-010 |
| `caravan` | 商队配置（规模、货物、间隔） | 纯数据 | PRD-010 |
| `age` | 时代门槛（材料 ∧ 知识 ∧ 选择） | 纯数据 | [PRD-011](../prd/PRD-011-progression-knowledge-and-space.md) |
| `knowledge` | 洞见（名字、来源、获得途径） | 纯数据 | PRD-011 |
| `burden` | 时代压力（每时代的新麻烦） | 纯数据 | PRD-011 |
| `gas_kind` | 气体种类与危害参数 | 纯数据 | [d13](../design/13-gases-pollution-and-cycles.md) |
| `gas_source` | 排放源（气体、速率、条件、朝向） | 纯数据 + 方块 | d13 |
| `gas_sink` | 吸收源（过滤、藻池、植物） | 纯数据 + 方块 | d13 |
| `gas_reactor` | 气体转化（电解、燃烧、光合） | 纯数据 + 方块 | d13 |
| `gas_barrier` | 密封屏障（决定泄漏与连通） | 纯数据 + 方块 | d13 |
| `gas_vent` | 通风口（开关、朝向、速率） | 纯数据 + 方块 | d13 |
| `pollution_rule` | 剂量→后果（作物/疾病/情绪） | 纯数据 | d13 |
| `body_part` | 部位树与内脏槽位 | 纯数据 + 模型 | PRD-013 |
| `injury_kind` | 伤病类型、严重度、出血/感染概率 | 纯数据 | PRD-013 |
| `surgery` | 手术（前置、风险、并发症） | 纯数据 + 方块（手术台） | PRD-013 |
| `prosthetic` | 义体分级与能力 | 纯数据 + 物品 | PRD-013 |
| `medicine` | 药品（效力、副作用、成瘾） | 纯数据 + 物品 | PRD-013 |
| `prisoner_state` | 关押状态与表现 | 纯数据 | [PRD-015](../prd/PRD-015-captivity-and-prisoners.md) |
| `captivity_action` | 处置类型（劳役/赎金/释放/处决） | 纯数据 | PRD-015 |
| `sentence` | 处置令语义与文案 | 纯数据 | PRD-015 |
| `power_adapter` | 外部能量 → E 的换算与速率 | 纯数据 + 方块 | [d15](../design/15-power-and-mechanical-residents.md) |
| `power_generator` | 发电机（产出曲线、燃料、排放） | 纯数据 + 方块 | d15 |
| `power_storage` | 储能（容量、往返损耗、风险） | 纯数据 + 方块 | d15 |
| `machine_drive` | 机械族驱动形态（效率/续航/维护） | 纯数据 | d15 |
| `womb_recipe` | 人造子宫的两类配方与失败表 | 纯数据 + 方块 | d15 |

**读法**："纯数据 + 方块/物品"的意思是：**规则是纯数据，但要让它在世界里出现，你得先用已有方块或物品来表达它**（例如 `gas_source` 必须绑在一个放得下的方块上）。你**不能**用数据包创建新方块——那是 Java（§3.4）。

### 3.2 判定：我该走哪条路

1. **改数值/文案/权重/条件** → 货架 JSON（纯数据）。
2. **加配方、标签、跨 mod 物品映射** → KubeJS（§5）。
3. **让某个已有方块"会排烟/会耗电/会被当成床"** → 先看货架是否接受"方块 tag"；能接就纯数据，接不了就是 Java。
4. **要一个游戏里原本没有的东西**（新方块、新物品、新实体、新维度） → Java（D3）。
5. **要一个新的"货架名"** → Java（而且是核心团队的 L2 改动，见 §3.4 第 1 条）。

### 3.3 你必须认识的两个上限

- **需求栏 ≤ 8 行/卡**（[PRD-001](../prd/PRD-001-needs-mood-memory.md)、[d09 §6](../design/09-interaction-and-ui.md)）→ 所以**不要试图给每个场景加一条核心需求**；用"变体替换"（同 `replace_group`）而不是"再加一条"。
- **每页 32 行、每行 4 个动作、信息卡 8 行**（[d09 §6](../design/09-interaction-and-ui.md)）→ 你的条目越多，玩家的面板越难读。**内容不是越多越好**。

### 3.4 作者不能做的 5 件事（做了会白费力气）

| # | 做不到 | 为什么 | 正确路径 |
| --- | --- | --- | --- |
| 1 | **新增一个货架名** | 货架注册表在 fork 里（L2 改动，[R-CD-11](02-config-and-datapack.md)），不在数据包里 | 提需求给核心团队；或复用最接近的已有货架 + 字段扩展 |
| 2 | **让图案读容器/实体，或持久化自己的状态** | 基底图案是"纯函数式施工方案"，只出方案、由居民施工（[R-CD-7](02-config-and-datapack.md)） | 改成"居民来搬/来做"的行为，或走 Java |
| 3 | **用 KubeJS 写玩法规则** | 不可测、不可诊断、删脚本等于改规则（[R-CD-12](02-config-and-datapack.md)）；成瘾规则尤其被点名（[R-CD-13](02-config-and-datapack.md)） | 阈值/曲线进 `data/<ns>/folkways/<shelf>/` |
| 4 | **让内容只在装了某个可选 mod 时可用** | 违反 [R-PACK-8](00-pack-spec.md)：可选 mod 只能加速/扩展，不能是唯一通路 | 做两套：无 mod 的基线 + 有 mod 的增强（增强包可整套删除） |
| 5 | **改规则引擎行为**（规划器、调度节拍、拒绝语义） | 那是 L3/L4，且违反 R-F2「微观控制只注入约束，不替换规划器」 | 用约束/偏好（禁限区、优先级、库存规则）表达你的意图 |

---

## 4. 图案与能力上限

### 4.1 图案能造什么

道路、拱桥、城墙、码头、矿场、采石场、梯田、铁路、拱廊——以及任何**能用"逐格决定放什么方块"描述的东西**。
它支持：地形自适应、几何、部件盖章（`template()`）、多阶段施工、多轮生长、玩家旋钮、内嵌 i18n。

### 4.2 硬上限（背下来，不要试）

| 限制 | 数值 | 出处 |
| --- | --- | --- |
| 单次绘制包围盒边长 | **≤ 512** | `draft/Extent.java:10`（[r04](../research/04-content-and-modding.md) §3） |
| 标记 path 点数 | **≤ 4096** | `draft/Hint.java:18` |
| 单文件大小 | **≤ 131072 字符** | `draft/PatternLibraryPacket.java:17-19` |
| 服务端图案总数 | **≤ 256 个** | 同上 |
| 图案库总量 | **≤ 900000 字节** | 同上 |
| 解析执行步数 | **≤ 200000 步** | `draft/Pattern.java` |
| 绘制时长 | `drawSeconds` 默认 **10 秒**（配置） | `folkways-server.toml` |

### 4.3 八个"看起来能写、其实会卡/会坏"的反模式

| # | 写法 | 实际后果 | 改法 |
| --- | --- | --- | --- |
| 1 | 一次性铺一个边长接近 512 的巨型图案 | 施工队列与寻路同时爆，多人不同步 | 拆成**多阶段**：先围墙、再铺地、最后盖顶 |
| 2 | 每一格都 `template()` 一个部件 | 解析步数与方块数双爆（200k 步很容易超） | 一个部件覆盖一片，用循环决定位置而不是位置决定部件 |
| 3 | 在图案里做"每格重判断"的复杂逻辑 | 超解析步数上限，静默失败 | 先算规则（少量分支），再用几何批量放 |
| 4 | 想让图案产出流体/容器/实体 | 做不到（[R-CD-7](02-config-and-datapack.md)） | 用方块 + 居民行为表达 |
| 5 | 把 256 个图案名额塞满 | 后加的图案被拒，玩家自制内容被挤掉 | 内容按模块分包，按档位裁剪 |
| 6 | 直接写死某个 mod 的方块 id | 缺 mod 时静默出错、或整条图案不可用 | 用**标签**（`#minecraft:logs`）而不是具体 id |
| 7 | 为了铺更大范围把 `drawSeconds` 调大 | 玩家体感卡顿、多人不同步 | 保持 10 秒，改多阶段 |
| 8 | 图案反复重绘玩家改过的地方 | 覆盖玩家改动，玩家会骂人 | 只在**空位**施工（跳过非空方块） |

### 4.4 四个写作习惯

1. **先画边界，再填空**：先定包围盒，再决定内部几何——反着写最容易超步数。
2. **能用标签就不用 id**：兼容性靠标签，不靠"我装了哪些 mod"。
3. **一个图案只做一件事**：城墙不要顺便铺路，否则玩家没法只铺一半。
4. **给玩家旋钮**：宽度/密度/材质做成参数，比写死五个变体更划算。

---

## 5. KubeJS 的边界

### 5.1 能做与不能做

| 该做 | 不该做 |
| --- | --- |
| 增删改配方（含 Create 系） | 定义事件/需求/剧本（属于货架） |
| 调整标签（方块/物品分类） | 实现玩法逻辑（不可测、不可诊断） |
| 跨 mod 桥接（把 A 的物品接进 B 的配方） | 存长期状态 |
| 发布前的临时平衡试错 | 依赖顺序敏感的启动逻辑 |
| **物品 ↔ 物质 id 的映射**（把某 mod 的酒映射到我们的 `alcohol`） | **成瘾阈值/曲线**（必须在货架里，[R-CD-13](02-config-and-datapack.md)） |

### 5.2 判定流程（照着走）

```
你要加的东西是……
├─ 一条规则/阈值/曲线/权重/条件？
│    → 数据包货架（不是脚本）
├─ 一个配方、一个标签、一次物品映射？
│    → KubeJS
├─ 让外部 mod 的机器接进我们的系统（排放源/能量适配器）？
│    ├─ 它能不能用"方块 tag + 参数"描述？ → 能 → 货架 JSON
│    └─ 不能（要读运行时对象/状态） → 脚本调用我们的注册 API（⚠️ API 未冻结，先问核心团队）
├─ 需要每 tick 扫一遍？
│    → 不是脚本的事：走 `Cadence` 相位（找核心团队），脚本做每 tick 扫描是性能自杀
└─ 一个全新的系统（新货架/新工作/新 UI）？
     → Java（D3）
```

### 5.3 脚本的可测性要求

**R-AUTH-3**：脚本必须能被**静态检查**（语法 + 引用的 id 是否存在），不允许"运行才知道错"（[R-CD-9](02-config-and-datapack.md)）。
**R-AUTH-4**：脚本里**不许出现魔法常量**（剂量、阈值、倍率）。凡是会影响平衡的数字，都必须出现在货架或配置里，脚本只做"读它、用它"。反例（会被打回）：`if (item.id == 'create:vodka') event.player.addEffect('plaa:drunk', 600)` —— 时长写死在脚本里，改平衡要改代码，且无法被诊断系统解释。

---

## 6. 文案与双语

### 6.1 两份，不是四份

**我们新增的键只做 `zh_cn` + `en_us`**（[ADR-017](../00-charter.md)）。基底既有的四语言文件保留不动；缺键时**回退 `en_us`**。
你的内容包如果面向社区，可以自己加更多语言——但**必须**先有这两份，否则会被 CI 拦下（[k02 §6](02-config-and-datapack.md)）。

### 6.2 三条格式规则

| 规则 | 正确 | 错误 |
| --- | --- | --- |
| 文本到达客户端前保持 `Component` | `Component.translatable(key, args)` | 先在服务端拼成字符串再发 |
| 参数用 `%s`，需要重排用 `%1$s` | `"你给了 %1$s 一块 %2$s"` | 用 `+` 拼接 |
| 字面百分号写 `%%` | `"命中率 50%%"` | `"命中率 50%"`（会被当格式符） |

### 6.3 不许拼接句子（这是最容易翻车的地方）

中文和英文的语序不同，**任何用字符串相加拼出来的句子，换一种语言就坏**：

| 反例 | 为什么坏 | 正确做法 |
| --- | --- | --- |
| `"你" + 名字 + "饿了"` | 英文是 `"%s is hungry"`，语序完全不同 | 整句做成一个键，名字作参数 |
| `"找到 " + n + " 个"` | 英文要复数（`1 item` / `2 items`） | 拆成两个键（单/复）或换句式 |
| `"她" / "他"` 动态替换 | 英文没有性别代词区分，且"它"另说 | 用中性句式（"该居民"） |
| `"第" + n + "天"` | 英文是 `Day %s` | 整个句式进语言文件 |
| `"把" + 物品名 + "放进箱子"` | 英文介词结构不同 | 用 `%1$s → %2$s` 这种**名词化**句式 |

**R-AUTH-5**：**一个句子 = 一个键**。允许参数，不允许拼接。

### 6.4 对象名必须来自数据

物品、方块、需求、势力的名字**都要用它们自己的翻译键**，不许在文案里写死中文：

| 错误 | 正确 |
| --- | --- |
| `"你需要木板"` | `Component.translatable("need.boards", stack.getHoverName())` |
| `"喂他吃面包"` | 句子里用 `%s`，参数传物品的 `getHoverName()` |

### 6.5 三个禁止

1. 禁止在 lang 文件里写 `§` 颜色码（颜色属于样式，不属于文本）。
2. 禁止把数值格式化成字符串再塞进句子（用整数参数，或提前算好再作为参数）。
3. 禁止在文案里指代"玩家"（用"殖民地"/"你"，且不要出现"玩家"二字——见 [d03 术语表](../design/03-glossary.md)）。

---

## 7. 校验与发布

### 7.1 三道闸

| 闸 | 何时 | 查什么 | 谁跑 |
| --- | --- | --- | --- |
| **静态** | 不开世界（CI） | 语法、id 存在性、键集、占位符、引用完整性 | CI（[R-CD-10](02-config-and-datapack.md)） |
| **加载期** | `/reload` | 解析、拒绝原因、自检命令 | 你 |
| **运行期** | 玩的时候 | 诊断（D-1…D-31）能否解释"为什么没发生" | 你 + 玩家 |

### 7.2 加载期被拒 Top 10（按出现频率排）

| # | 原因 | 你会看到 | 修法 |
| --- | --- | --- | --- |
| 1 | 目录名不是货架名（`incidents/` vs `incident/`） | 条目 0 条，无报错 | 改目录名；用 `/<ns> content` 确认 |
| 2 | `pack.mcmeta` 的 `pack_format` 与 1.21.1 不匹配 | 整个包不加载 | 改成当前值（§2.5） |
| 3 | 文件名与 `id` 的 path 不一致 | "id 与文件名不匹配" | 让两者一致 |
| 4 | `id` 没有命名空间（`"cleanliness"`） | "非法 id" | 写成 `my_content:cleanliness` |
| 5 | 缺必填字段 | "缺字段 X" | 对照货架 schema 补齐 |
| 6 | 引用了不存在的 id（物品/需求/势力） | "引用不存在：X" | 先建被引用的条目，或改用标签 |
| 7 | 数值越界（负衰减、权重 0、概率 >1） | "越界" | 按 §7.3 的范围改 |
| 8 | 语言键缺失或占位符数量不一致 | `/<ns> content keys` 列出 | 补齐两份语言文件 |
| 9 | 两个包给了同一个 id | **后加载的静默覆盖**（最危险） | 改 id；或明确用"同 id 覆盖"语义（§10 OQ-2） |
| 10 | 条件表达式语法错（`has_trait:` 后面空着） | "条件无法解析" | 补全值；用静态检查提前发现 |

### 7.3 静态检查能提前抓到的八类问题

1. JSON 语法错。
2. 未知字段（拼写错误最常见）。
3. 必填字段缺失。
4. 数值越界与类型错（字符串当数字）。
5. 引用完整性（事件→需求/物品/势力；剧本→货架 id；图案→部件）。
6. 语言键缺失 / 占位符数量不一致 / 多余参数。
7. id 重复与非法命名空间。
8. 违反不变量（§9）：例如 `satisfiers` 少于 2 条、儿童内容标记缺失。

### 7.4 发布前清单

- [ ] `pack.mcmeta` 的 `pack_format` 与 1.21.1 一致。
- [ ] 所有目录名 = 货架名，所有文件名 = id 的 path。
- [ ] `/<ns> content` 里**零拒绝**。
- [ ] `/<ns> content keys` 里**零缺失**。
- [ ] 两份语言文件齐全，占位符一致。
- [ ] 包里**没有**依赖可选 mod 的唯一通路（[R-PACK-8](00-pack-spec.md)）。
- [ ] 没有改名/复用已发布的 id。
- [ ] 图案在 8×8、64×64 两档都试过。
- [ ] 事件模板有前兆、有"不作为"选项、后果写回记忆/关系。
- [ ] 新增的数值都在数据/配置里，脚本里没有魔法常量。
- [ ] 如果新增了诊断相关的拒绝理由，已在 PRD-006 的拒绝键里登记（覆盖率 ≥95%）。
- [ ] 内容**可整套删除**：删掉你的包，世界仍能进入。

---

## 8. 三个完整示例

### 8.1 新增一条需求：「洁净」

**意图**：某些居民（洁癖）对"脏"比"难看"更敏感；洁净度低会提高患病风险。它是一个**变体需求**——**替换「美感」**，而不是新增第 9 条（需求栏只有 8 行）。

完整定义：

```json
{
  "id": "my_content:cleanliness",
  "kind": "variant",
  "form": "state",
  "decay": 2.5,
  "mood_map": [
    { "below": 16, "mood": -25 },
    { "below": 41, "mood": -10 },
    { "below": 71, "mood": 0 },
    { "below": 101, "mood": 6 }
  ],
  "focus_map": [
    { "below": 16, "focus": -12 },
    { "below": 41, "focus": -4 },
    { "below": 71, "focus": 0 },
    { "below": 101, "focus": 5 }
  ],
  "default_weight": 3,
  "trait_weight": { "my_content:fastidious": 1.6 },
  "replace_group": "aesthetic_group",
  "replace_when": "has_trait:my_content:fastidious",
  "satisfiers": ["wash_at:washbasin", "bathe_at:tub", "change_clothes:wardrobe"],
  "refusal_keys": ["no_water", "no_washbasin"],
  "icon": "my_content:textures/need/cleanliness.png"
}
```

文案：

```json
{
  "my_content.need.cleanliness.name": "洁净",
  "my_content.need.cleanliness.desc": "身体、衣物与餐具的清洁程度。脏了会难受，也更容易生病。",
  "my_content.refusal.no_water": "附近没有可用的水。",
  "my_content.refusal.no_washbasin": "没有洗手台。"
}
```

逐条解释：

| 字段 | 为什么这么填 |
| --- | --- |
| `kind: variant` | 它是"替换某个核心需求"的变体，不是人人都有的核心需求 |
| `form: state` | 状态式（0–100 的值），不是计量式（如厕那种多条计量） |
| `decay: 2.5` | 每小时掉 2.5 点 → 约 40 游戏小时从满到空（比饥饿慢，比美感快） |
| `mood_map` / `focus_map` | **分开写**：不难受 ≠ 很专注（[PRD-001 §4.3](../prd/PRD-001-needs-mood-memory.md) 的要求） |
| `trait_weight` | 洁癖者把这件事看得更重要（矮人要塞式的人格加权） |
| `replace_group` + `replace_when` | 同槽位互斥：有 `fastidious` 的人用「洁净」**顶替**「美感」，两人不会同时有这两条 |
| `satisfiers` | **至少两条**路径（[d05 R-N-2](../design/05-settlement-and-residents.md)），否则居民会因为唯一设施被占而永久痛苦 |
| `refusal_keys` | 拒绝理由必须能被诊断解释（[PRD-006](../prd/PRD-006-stock-rules-and-diagnosis.md) 的覆盖率要求） |

**它与别的系统怎么咬合**：洁净度低 → 与 [PRD-003](../prd/PRD-003-season-temperature-thirst-nutrition.md) 的疾病风险挂钩（作者只需在 `pollution_rule` 或疾病条件里读这个值；**不要**在需求条目里写死疾病概率）。
**别踩的坑**：不要给它 `kind: core` —— 那会让所有人的需求栏多一行，把 8 行预算挤爆（§3.3）。

### 8.2 新增一个事件模板：「井水发苦」

**意图**：夏天，水井开始有异味。玩家可以选择封井（花时间）、煮沸（花燃料），或者什么都不做（等疫病）。这是"有前兆、有代价、有不作为路径"的标准结构。

```json
{
  "id": "my_content:bitter_well",
  "weight": 12,
  "category": "environment",
  "cooldown_days": 20,
  "herald_days": 3,
  "conditions": {
    "min_population": 6,
    "season": ["summer"],
    "requires": ["colony:has_well"]
  },
  "slots": {
    "victim": { "role": "drinker", "count": 1 },
    "witness": { "role": "any", "count": 1 }
  },
  "herald": {
    "text_key": "my_content.incident.bitter_well.herald",
    "signal": "water_tint"
  },
  "options": [
    {
      "id": "seal",
      "text_key": "my_content.incident.bitter_well.seal",
      "preview_key": "my_content.incident.bitter_well.seal.preview",
      "effects": [
        { "kind": "work", "value": "seal_well" },
        { "kind": "mood", "target": "all", "value": -4 },
        { "kind": "memory", "target": "witness", "value": "my_content:bitter_taste" }
      ]
    },
    {
      "id": "boil",
      "text_key": "my_content.incident.bitter_well.boil",
      "preview_key": "my_content.incident.bitter_well.boil.preview",
      "effects": [
        { "kind": "goods", "item": "minecraft:coal", "count": 20 },
        { "kind": "work", "value": "boil_water" },
        { "kind": "mood", "target": "victim", "value": -2 }
      ]
    },
    {
      "id": "ignore",
      "text_key": "my_content.incident.bitter_well.ignore",
      "preview_key": "my_content.incident.bitter_well.ignore.preview",
      "effects": [
        { "kind": "risk", "target": "victim", "value": "my_content:dysentery", "chance": 0.35 },
        { "kind": "relation", "from": "witness", "to": "victim", "delta": -3 },
        { "kind": "follow_up", "arc": "my_content:bad_water", "stage": 2 }
      ]
    }
  ]
}
```

文案（两份，各四条）：

```json
{
  "my_content.incident.bitter_well.herald": "井水泛起一层白沫，喝起来有点苦。已经持续 %s 天了。",
  "my_content.incident.bitter_well.seal": "封井，改去远处的河取水",
  "my_content.incident.bitter_well.seal.preview": "取水路程变长，但能立即止损。",
  "my_content.incident.bitter_well.boil": "照常取水，但每桶都煮沸",
  "my_content.incident.bitter_well.boil.preview": "消耗燃料；如果燃料不够，部分家庭会省掉这一步。",
  "my_content.incident.bitter_well.ignore": "先不管，等它自己好",
  "my_content.incident.bitter_well.ignore.preview": "有相当概率出现痢疾，并可能引出下一阶段。"
}
```

要点：

1. **`herald_days` 必须给玩家留时间**（默认 2，这里给 3）。没有前兆的事件 = 偷袭，违反 [PRD-002](../prd/PRD-002-incidents-and-narrator.md) 的核心承诺。
2. **必须有不作为路径**（`ignore`）。不选也是一种选择，但要**显示后果预览**。
3. **后果要写回记忆/关系**，否则玩家的选择不会留下痕迹（[d11 R-N-3](../design/11-freedom-design.md)）。
4. **`follow_up` 是事件链**：连续两次不作为，疫病会真的来。
5. **不要在事件里写死"谁生病"**——用 `slots` 的角色槽位，让同一模板在不同居民身上产生不同故事（[d11 R-N-2](../design/11-freedom-design.md)）。

> ⚠️ `effects` 的 `kind` 取值以 [PRD-002 §3.1](../prd/PRD-002-incidents-and-narrator.md) 的六类为准（物资/情绪/记忆/关系/世界/后续）；上面用的是**形态示例**，字段名在 PRD-002 定稿时会与货架 schema 对齐。

### 8.3 给外部 mod 接一个排放源（Create 的炉子 → 烟）

**意图**：玩家装了 Create，用炉子烧东西。我们希望它的烟**真的进我们的气体层**，而不是只有我们自己的烟囱会冒烟。

```json
{
  "id": "my_content:create_furnace_smoke",
  "gas": "plaa:smoke",
  "rate": 2.0,
  "rate_unit": "mB_per_tick",
  "condition": "block_state:create:lit_blaze_burner",
  "position": "block",
  "facing": "up",
  "requires_barrier": "plaa:airtight",
  "max_rate_per_second": 8.0,
  "notes": "只有点燃时排烟；朝上排，所以把它建在菜地上风处会后悔。"
}
```

要点：

1. **`condition` 用"状态谓词"而不是脚本**：`block_state:` 是数据可表达的；一旦你要读"这个方块里烧的是什么燃料"，那就是运行时对象，只能走脚本调 API（⚠️ API 未冻结）。
2. **`facing` 是必须的**（[d13 §4.2](../design/13-gases-pollution-and-cycles.md)）：烟囱方向决定"谁的菜地被熏"，这是玩家会后悔的具体决定，也是叙事材料。
3. **`rate` 必须能给上限**（`max_rate_per_second`）：否则玩家叠 100 台炉子，气体层直接被压垮（性能与漏洞两条线都要防）。
4. **`requires_barrier`** 让"密封"成为有意义的概念：不密封的房间，烟会漏到隔壁。
5. **可整套删除**：删掉你的包，炉子只是"不冒烟"，世界不会崩（[ADR-010](../00-charter.md)）。

**同构的另一个例子**：如果要做能量适配器，`power_adapter` 的形态一样——只是字段换成 `source`（`fe` / `eu` / `rotation` / `steam`）、`conversion`、`rate_cap`（[d15 §3](../design/15-power-and-mechanical-residents.md)）。

---

## 9. 作者不得破坏的 8 条不变量

| # | 不变量 | 破坏了会怎样 | 谁在守 |
| --- | --- | --- | --- |
| 1 | **所有命名空间都被读取**（§2.2） | 第三方内容静默消失 | 实现 + 自检命令 |
| 2 | **不能凭空空愈/凭空受益** | 删包 = 改规则；成瘾者删 mod 就痊愈（[R-NM-27](../prd/PRD-001-needs-mood-memory.md)） | 货架数据源唯一 |
| 3 | **不能绕过权限** | 多人服务器被内容包提权（[PRD-012](../prd/PRD-012-multiplayer-and-permissions.md) 是唯一入口） | 权限门面 |
| 4 | **儿童不进入成人/成瘾/关押内容** | 内容分级失效（PRD-001/009/015 的硬禁） | 加载期标记 + 运行时校验 |
| 5 | **不能制造无限资源/无限能量** | 经济与难度崩（[d13 §3.4](../design/13-gases-pollution-and-cycles.md)、[d15 §3.4](../design/15-power-and-mechanical-residents.md) 的漏洞清单） | 速率上限 + 守恒检查 |
| 6 | **可选 mod 不能是唯一通路** | 两套玩法、缺 mod 就残废（[R-PACK-8](00-pack-spec.md)） | 分包审查 |
| 7 | **已发布 id 不可改名/复用** | 老存档悬空（§2.4） | 静态检查 |
| 8 | **不能"运行才知道错"** | 玩家替你发现 bug（[R-CD-9/10](02-config-and-datapack.md)） | 静态检查 + 加载期拒绝 |

---

## 10. 开放问题

| 编号 | 问题 | 影响 | 何时定 |
| --- | --- | --- | --- |
| OQ-1 | 是否提供**官方模板仓库**（最小可运行的数据包骨架 + 三个示例）？ | 上手成本 | M1 前 |
| OQ-2 | 作者能否用**同 id 覆盖**核心货架条目？还是必须新 id + 引用？ | 内容治理与升级冲突 | M1 前 |
| OQ-3 | 版本迁移时，`deprecated` 条目保留多久、是否自动迁移引用？ | 老存档兼容 | M2 前 |
| OQ-4 | 是否需要**内容签名/白名单**（服务器只加载受信内容）？ | 服务器安全（与 [OQ-CD-5](02-config-and-datapack.md) 相关） | M2 前 |
| OQ-5 | 是否提供 `/<ns> content export`（把当前货架导出成文档/示例）？ | 作者学习曲线 | M2 前 |
| OQ-6 | 图案能否自带贴图（依赖作者资源包）？ | 内容表现力 | M2 前 |
| OQ-7 | 第三方货架是否需要"实验性/稳定"分级标注？ | 作者预期管理 | M2 前 |
| OQ-8 | 是否允许脚本注册新货架（目前**禁止**，因为需要 L2 改动）？ | 生态上限 | M3 前 |
| OQ-9 | 数据包与剧本的覆盖优先级在第三方场景怎么算（剧本 > serverconfig > 包默认）？ | 冲突时的可预期性 | M1 前 |
| OQ-10 | 本手册是否要出英文版（面向国际作者）？ | 社区规模 | M2 前 |

---

## 11. 变更记录

| 日期 | 版本 | 变更 |
| --- | --- | --- |
| 2026-10-18 | 草稿 v1 | 首次成文：五分钟上手、43 货架作者视角、图案上限与 8 条反模式、KubeJS 判定流程、双语与拼接禁令、加载期 Top 10、三个完整示例、8 条不变量、10 条 OQ |
