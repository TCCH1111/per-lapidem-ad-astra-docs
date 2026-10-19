# 03 · Folkways 玩家交互层能力清单

范围：`reference/folkways-67f28b0`（NeoForge 21.1 / MC 1.21.1 / Java 21）的 `front/**`（191 文件）、`library/**`、`plugins/**` 中声明页面/手势的部分、`assets/folkways/{lss,lang}`。
引用约定：路径相对 `mods/core/src/main/java/io/github/izakyl/folkways/`（core 子项目；其它子项目写全 `mods/<子项目>/…`），形如 `front/ui/screen/ColonyShell.java:53`。只读阅读，未改动被审仓库。
结论先行：这是**声明式面板 + 世界内手势 + Ponder 教学**三层结构。玩家的"自由"全部落在四种可写数据上：**Gesture（手势）、Zone/Path（区域与路径）、Delegation+Schema（用途及其设置）、Order/Trade priority（订单与工种优先级）**。除此之外没有任何调度、排班、战斗、图表接口（见 §6）。

---

## 1. 交互入口总览

### 1.1 Colony Book 物品（唯一的行动入口）
- 合成/获得：普通书合成；旧的同类书在首次使用时被 `LegacyBooks.takeUp` 升级（`front/engine/item/ColonyBookItem.java:37,53`）。
- `onItemUseFirst`（右键方块）：先 `takeUp`，若该方块是当前殖民地已登记的 board（`ColonyBoards.firstAt`）→ 打开**方块面板** `ColonyShell.openAt`，否则打开**殖民地面板** `ColonyShell.open`（同上 :39-45）。
- `use`（对空右键）：打开殖民地面板（:50-57）。
- 物品本身不决定归属："书是抵达殖民地的工具，不是让你拥有它的凭证"（:23-24 注释；`folkways.ponder.colony_book.text_1/3`）。
- 手势存在物品数据组件 `FolkwaysDataComponents.BOOK_GESTURE` 上，**每本书各自记忆**；默认 `Shape.Gesture.POINT`（`front/engine/item/BookGestures.java:13`，`ColonyBookItem.gesture/setGesture`）。
- 物品模型按手势切换（model property `folkways:mode` = 0/1/2，`front/client/FolkwaysClientRegistry.java:51-57`），所以"手里这本书现在能干什么"是可见的。
- 死亡保护：绑定过的书在重生时归还一次（`front/engine/item/ColonyBookKeeping.java:20-34`）。
- **权限前置**：所有世界内操作都要求"手里拿着书 + 正在为该书指向的殖民地行动"（`ColonyBookItem.holdsBookFor`，`front/engine/item/HeldBook.java:14-29`，服务端 `front/engine/authority/ColonyAuthority.java:59-73`）。面板本身谁都能开，但页面数据走 `Pages.colonyOf` 的 authority（`front/api/ui/Pages.java:20-31`），无权者看到空页。

### 1.2 手势与左右键语义
| 手势 | 左键 | 右键 | 依据 |
|---|---|---|---|
| `POINT`（点选） | 瞄准方块 → 纳入/移出殖民地；瞄准生物（自家居民）→ 从名册除名 | 打开面板；若瞄准的是区域/路径则打开其设置 | `front/client/FolkwaysClientGameEvents.java:102-144,157-164` |
| `BOX`（圈地） | 两角各点一次成框；潜行+左键丢弃 | 同上；框未确认前右键打开"这片地做什么用"页 | `front/client/ZoneSelection.java:150-179` |
| `LINE`（画线） | 每点一次加一个点；潜行+左键丢弃 | 同上，问"这条路径做什么用" | `front/client/PathSelection.java`、`front/ui/screen/Drawing.java` |
| 手上托着蓝图 | 左键放下；潜行+左键丢弃 | — | `front/client/HeldPlacement.java:108` |

- 手势切换：**潜行 + 滚轮**循环 POINT→BOX→LINE，走 `SetBookGesturePacket` 并回一条动作栏提示 `folkways.book.gesture.*`（`FolkwaysClientGameEvents.java:183-187`）。
- Ctrl/Cmd 与 Alt 是两个独立修饰键，状态由 `onKey` 维护（`FolkwaysClientGameEvents.java:36-59`）；它们在 BOX/LINE/放置三处含义一致，见 §3。
- 手上有待放的蓝图时，左键**优先给放置**，不看当前手势（`FolkwaysClientGameEvents.java:108-110`）。

### 1.3 面板与窗口
- 载体：`ColonyShell implements FolkwaysUI`（`PlayerUIMenuType`，ID `folkways:colony` / 方块面板 `folkways:site`），`front/ui/screen/ColonyShell.java:53-57`。基于 LDLib2 的 `ModularUI` + taffy 布局 + `assets/folkways/lss/desk.lss` 皮肤（:399-403）。
- 结构：标题栏（点标题 = colony 选择器/改名/新建，`front/ui/screen/Chooser.java`）｜左侧导航三组（`folkways.ui.nav.colony` / `production` / `preferences`）｜页面主体。面板默认 500×310，最小 320×200；导航宽 104，正文最小 360，不足则折成汉堡按钮（`ColonyShell.java:61-69,406-460`）。
- 方块面板：只显示该方块的 board 页 + "纳入/移出"一个动作（`ColonyShell.createSiteUI`）。
- **同一面板内的三种形态**：正常页 / 绘制配置（`Drawing`，正在画框或线时）/ 选区设置（`ZoneSettings`），由 TICK 事件切换（`ColonyShell.java:361-374`）。即"右键问用途"其实是在面板里换了一屏。
- 浮动窗口：`Desk` 管理多个 `Window`（可拖动、重叠、`occupiedBoxes` 回传占据区），Esc 先关最上层（`front/ui/screen/Desk.java:110-139`，`front/client/WindowKeys.java:20-28`）。插件 enrollment 里**第一个 PageKind 进导航，其余作为浮动窗口**（`ColonyShell.java:308-322,376-384`；`front/ui/screen/PageKinds.java:31-48`）。
- 独立面板：`LonePanel.open(id, title, w, h, builder)`（蓝图选择器等，`front/api/ui/LonePanel.java`，注册于 `FolkwaysClientRegistry.java:45`）。

### 1.4 快捷键（全模组只有 1 个自有按键）
- `V` = 俯瞰视角 `Overhead.KEY`（`key.folkways.overhead`，注册 `FolkwaysClientRegistry.java:29-32`）。俯瞰要求：手上有绑定书、不在其他界面、相机改为本客户端私有 `Marker` 实体，玩家的 HUD/准星/手持物被隐藏（`front/client/Overhead.java:33-79,184-203`）。
- 俯瞰中：鼠标即准星（射线由相机+鼠标像素算出，`mods/core/src/main/java/io/github/izakyl/folkways/front/client/Overhead.java:113-125`）；左键=书左键、右键=书右键（`OverheadScreen.java:187-191`）；`Tab` 切换手势；`Backspace/Delete` 丢弃在画的框/线/手托的蓝图；WASD 平移、空格升、Shift 降、中键拖动转视角、滚轮沿视线推拉（`Overhead.java:131-160`，`OverheadScreen.java:194-201`）。**注意：俯瞰时潜行键不再是修饰键**（`mods/core/src/main/java/io/github/izakyl/folkways/front/client/FolkwaysClientGameEvents.java:62-64` 显式排除俯瞰）。
- 图层：`ZONES / PATHS / WORKS / RESIDENTS`，每个按钮三态"标记+卡片 → 仅标记 → 隐藏"（`front/client/Layer.java:7-65`）。
- 顶部两行按钮（`mods/core/src/main/java/io/github/izakyl/folkways/front/client/OverheadScreen.java:58-111`）：第一行 4 个图层开关，第二行 3 个手势按钮（图标就是那张书，按手势切换模型），第三行上下文动作——手托形状时=旋转/镜像/丢弃；否则=放置货架（蓝图 `Placing.shelves()`）、框/线画好时=「进行配置」（等价右键问用途）、画线中=「取回一个点」、绘制中=「取消」。
- Esc（面板内）：关最上层浮动窗口。**没有页面数字键、没有快捷栏绑定、没有第二套按键。**

### 1.5 命令
- `/folkways library`（需 GAMEMASTERS）：列出每个 shelf 的条数、来自哪些 pack，以及被拒绝/命名错误的文件（各最多 8 行），点击文件夹路径可直接打开（`library/LibraryCommand.java:26-78`）。
- `/folkways invitation accept|decline <colony uuid>`：接受/拒绝殖民地邀请；聊天里的 `[接受]`/`[拒绝]` 按钮就是执行这条命令（`front/engine/charter/Invitations.java:84-102`）。
- 无其他子命令：**没有任何"模组内开关"型命令**（暂停、加速、导出、调试面板都不存在）。

---

## 2. 面板页面清单

`PageKind(id, nameKey, icon, Optional<lesson>)`（`front/api/panel/PageKind.java`）。核心页在 `front/ui/screen/PageKinds.java:15-26`；插件页由 `Enrollment(…, List<PageKind> pages)` 声明（`front/api/Enrollment.java`）。

| 英文类名 | page id | 中文名（zh_cn） | 玩家能做什么 | 数据来源 |
|---|---|---|---|---|
| `ResidentsPage` | `folkways:residents` | 居民分工（`folkways.tab.residents`） | 每居民×每工种一格：左键允许/禁止、滚轮定优先级 1–4；点名字开个人窗口（改名、当前行为、Bay inlays；搜索框支持译名过滤） | 服务端 `rosterTag/detailTag`（`front/ui/screen/ResidentsPage.java:314-325,346-389`），`Residents.of`；客户端本地按译名过滤（:161-169） |
| `MetricsPage` | `folkways:metrics` | 库存（`folkways.tab.metrics`） | 库存物品图标网格（每页 60 格）带数量角标、`<`/`>` 翻页、刷新；悬停显示物品名与总数 | `ColonyMetrics.of(...).stock()`（`front/engine/colony/ColonyMetrics.java:30-46`，库存来自 `ColonyStocks.tally`）。注意 `residents/idle/members/zones/kinds/goods` 这些字段**没有任何界面使用**，仅 `residents()` 被删除确认文案取用（`front/ui/screen/Razing.java:99`） |
| `MembersPage` | `folkways:members` | 成员（`folkways.tab.members`） | 邀请玩家、撤回邀请、移出成员、转让创建者、交由 FTB 队伍管理（二次确认）、从队伍收回、退出殖民地 | `Charters`/`Charter`（`front/ui/screen/MembersPage.java:100-202`） |
| `LessonsPage` | `folkways:lessons` | 教程（`folkways.tab.lessons`） | 每个插件一个文件夹；单独看一课或"全部连着看" | **纯客户端** `Lessons.folders()`（`front/ui/screen/LessonsPage.java:44-99`） |
| `SettingsPage` | `folkways:settings` | 设置（`folkways.tab.settings`） | 殖民地**工具清单**（Items 选择器）、重置窗口布局、删除殖民地（需输入确认语句，仅创建者） | `CoreSettings`（只有 `tool` 一项，`front/api/CoreSettings.java:22-29`）、`Razing` |
| `BuildPresence`/DomainPage | `folkways:build` | 建造（`folkways.page.build`） | 建造单列表（已建/总格数、受阻原因、轮次）、取消订单 | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/BuildPresence.java:334-360` |
| `BlueprintsPage` | `folkways:blueprints` | 蓝图（`folkways.tab.blueprints`） | 选一张蓝图拿在书上（浮动窗口 + 俯瞰货架） | `Templates.files()` + 玩家本地 `folkways/blueprint`（`mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/HeldBlueprints.java:50-79`） |
| `WaresPresence` | `folkways:wares` | 工坊（`folkways.page.wares`） | 工作站列表、燃料清单（首行，Items 选择器）、"没有燃料" | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/wares/WaresContent.java:52,83-87` |
| `PersonPresence`/`LivingPresence` | `folkways:person` | 人类居民（`folkways.page.person`） | 一行 `Admit` 动作接纳定居者（显示等待人数/上限/下一位倒计时，`mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/person/PersonPresence.java:96-98`）；床位与食物需求清单。**`living` 没有自己的页面**，床位/进食设置作为 schema 合并在这里 | `PersonContent.java:38-40`；`LivingContent.FOOD` |
| `NamesPage` | `folkways:names` | 姓名池（`folkways.tab.names`） | 逐项增删名/姓（浮动窗口） | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/person/name/NamesPage.java` |
| `LooksPage` | `folkways:looks` | 模型池（`folkways.tab.looks`） | 从池中为本殖民地抽取/剔除外观（浮动窗口） | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/person/look/LooksPage.java` |
| `PasturePresence` | `folkways:pasture` | 牧场（`folkways.page.pasture`） | 存栏/目标头数、每栏状态 | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/pasture/PastureContent.java:69` |
| `RailPresence` | `folkways:rail` | 铁路（`folkways.page.rail`） | 列车列表（在途/停靠/缺列车长）、接管 | `mods/create/src/main/java/io/github/izakyl/folkways/create/rail/domain/RailContent.java:41` |
| `DispatchPresence` | `folkways:dispatch` | 调度（`folkways.page.dispatch`） | 物流网络/取货点/邮箱状态、暂停下单原因 | `mods/create/src/main/java/io/github/izakyl/folkways/create/dispatch/DispatchContent.java:48` |
| `OrdersPresence` | `folkways:orders` | 订单（`folkways.panel.orders`） | 按容器分组列出订单、删除订单 | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/orders/OrdersContent.java:40` |

- **没有页面的插件**：`farming`、`fishing`、`groundwork`、`patrol`、`golem`、`fear`——它们只贡献区域/路径用途（Delegation）与设置项，玩家通过手势 + `ZoneSettings` 操作。
- board 的数据通路统一是：`DomainPage.board()` → `ColonyBoards.answering(colony, page.id(), at, ColonyViews.forBoard(...))` → 各 `Facing.board(...)`（`front/ui/screen/DomainPage.java:251-289`；扩展点见 `front/api/Facing.java:15-28`）。board 被序列化成 NBT 同步（figures/rows/acts/heading/whole/meter/told），客户端只负责画。
- act 只有 5 种动词：`Do(actionKey)`、`Edit(settingKey)`、`Open(page)`、`Ping(pos)`、`Admit(labelKey, kind)`（`front/api/panel/Board.java:98-119`）；`Do` 在服务端回到 `Facing.act(page, actionKey, at, view)`（`front/engine/colony/ColonyBoards.java:123-140`）。

---

## 3. 世界内手势清单

**A. 点选（POINT）**
- 操作：左键瞄准方块 → `ToggleColonyMemberPacket`；瞄准生物 → `ToggleColonyResidentPacket`（`FolkwaysClientGameEvents.java:129-144`）。
- 成功反馈：动作栏 `folkways.member.joined` / `folkways.member.left`（`front/engine/colony/MemberToggle.java:74-81`）。
- 失败反馈（`MemberToggle.Refusal`，同文件 :98-101 全部走 `displayClientMessage(..., true)` 动作栏）：`folkways.refusal.member.not_enrollable`（这个方块殖民地用不上）、`…no_block_entity`、`…another_colony`（别的殖民地占着）。
- 先问各插件：`Facing.pointedAt` 可拦截这次点击并给出自己的答复（`mods/core/src/main/java/io/github/izakyl/folkways/front/engine/colony/MemberToggle.java:86-96`）。

**B. 圈地（BOX）**
1. Ctrl/Cmd + 滚轮：调整选取距离 1–100 格，提示 `folkways.zone.reach`。
2. 左键方块落地第一角（`folkways.zone.corner`）；按住 Ctrl 可把角放在该距离的空中（`aimedCell`）。
3. 左键第二角成框，提示 `folkways.zone.marked` + 尺寸/角坐标（`ZoneSelection.java:174-178`）。
4. 成框后滚轮 = 推/拉瞄准的那一面；**Ctrl = 近面，Alt = 远面，两者同按 = 整体平移**（`mods/core/src/main/java/io/github/izakyl/folkways/front/client/ZoneSelection.java:220-228`，`mods/core/src/main/java/io/github/izakyl/folkways/front/client/ZoneSelection.java:181-218`），提示 `folkways.zone.shifted` / `folkways.zone.marked`。
5. 潜行 + 左键：丢弃，提示 `folkways.zone.dropped`（:94-99）。
6. 右键 → 面板切到绘制配置：左边是"这片地能做什么"（各 Delegation 的可绘制项 + 若干"offer"预览），右边是该用途的 Schema 设置（`front/ui/screen/Drawing.java:96-200`）。
7. 确认时才发 `CreateZonePacket`，成功后清空绘制（`front/client/Draft.java:48-58`）。
- 上限：每个用途自带 `Shape.Volume(maxCells)`，超出则确认按钮不可用并显示 `folkways.zoneconfig.cells`（`Drawing.java:296-308`、`Draft.hand()` 的 `extent() > most()` 判定 :314-321）。

**C. 画线（LINE）**
1. 左键逐点加，与上一点相连；右键选用途。
2. 每个点放下后即为"手持点"（`held`），滚轮沿射线把它朝玩家方向推拉（默认前后）；Alt = 向右横移，Ctrl+Alt = 向上；Ctrl/Cmd + 左键可改选另一个已有点，提示 `folkways.path.held/moved/point`（`PathSelection.java:104-179`）。
3. 上限 `CreatePathPacket.MAX_POINTS = 4096`，满则提示 `folkways.path.full`；巡逻用途受配置 `maxPatrolPoints`（默认 32）限制（`mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/patrol/PatrolContent.java:64`）。
4. 潜行 + 左键丢弃，提示 `folkways.path.dropped`。

**D. 蓝图/结构放置**
1. 蓝图页（或俯瞰货架）选一张 → `Placing.hold(Held)`，动作栏 `folkways.placing.held`；蓝图站在准星处，脚点对准所瞄面。
2. Ctrl/Cmd + 滚轮 = 推远拉近 1–100 格（`HeldPlacement` 常量 `MIN_REACH/MAX_REACH`）；Alt + 滚轮 = 90° 旋转；Ctrl+Alt = 镜像翻转（`front/client/HeldPlacement.java:50-63,104-160`）。
3. 左键放下 → 弹 `BlueprintHandoffPanel`：留空格怎么处理（保持原样 / 挖掉）、命名工地，创造模式可"直接建成"（`mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/BlueprintHandoffPanel.java`、`mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/draft/client/DraftPanel.java:169-178,253-269`）。
4. 失败反馈：`folkways.blueprint.handoff.no_book`（另一只手没拿对该殖民地的书）、`folkways.blueprints.too_big_to_send`、`folkways.blueprint.too_large`、`folkways.blueprint.too_many`、`folkways.blueprint.unreadable`。

**E. 巡逻路线**
- 巡逻没有自己的页面或命令：它就是 LINE 手势 + `PatrolContent.BEAT = Shape.Path(maxPatrolPoints)` 这个用途（`mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/patrol/PatrolContent.java:29-65`（上游已新增巡逻页））。战斗行为由 `folkways:fighting` 工种自动触发，玩家只能用"居民分工"页决定谁去巡逻/战斗。

**F. 已有标记的重定向**
- 手里有书、瞄准已存在的区域或路径、右键：不打开殖民地面板，而是打开**该选区的设置窗**（含 Release 删除按钮，危险样式）；判定窗口 2 秒（`mods/core/src/main/java/io/github/izakyl/folkways/front/client/FolkwaysClientGameEvents.java:157-164`、`mods/core/src/main/java/io/github/izakyl/folkways/front/client/ZoneSelection.java:120-129`、`front/ui/screen/ZoneSettings.java:132-148`）。

---

## 4. 信息呈现机制

- **Notice**：`(String key, List<Arg> args≤4, 每参 ≤160 字符)`，`Arg = Literal | Named(另一个翻译键)`，`component()` 交给客户端 `Component.translatable` 解析（`front/api/notice/Notice.java:12-62`，上限常量 :14-16）。`NoticeKind`/`RefusalKind` 只提供 `translationKey()`。
- **Attempt**：服务端动作结果 `Went | Refused(Notice)`（`front/api/notice/Attempt.java`）。世界内失败**统一表现为动作栏消息**：`player.displayClientMessage(notice.component(), true)`——实例见 `mods/core/src/main/java/io/github/izakyl/folkways/front/engine/colony/MemberToggle.java:98-101`、`mods/core/src/main/java/io/github/izakyl/folkways/front/ui/screen/Razing.java:40-47`、`HeldBlueprints`/`Draft.say`（客户端侧 `front/client/Draft.java:96-101`）、`mods/core/src/main/java/io/github/izakyl/folkways/front/engine/charter/Invitations.java:110-113`。成功也是动作栏（`folkways.member.joined` 等）。
- **Line（信息卡行的联合类型）**：`Said(Notice)`｜`Literal`｜`Text(Component)`｜`Blocked(Notice, Optional<Sentence>)`｜`Told(Sentence)`｜`Busy(Doing)`（自动附进度条）｜`Gauge(Meter,value,max)`｜`Bar`｜`Goods(≤8 组物品)`；自带二进制编码与上限（`front/api/notice/Line.java:13-66,114-199`）。这是"头顶信息"的唯一词汇表。
- **Sentence（图示语）**：`Glyph(sprite, otherwise 文字)`｜`Ware(item,count)`｜`Plus`｜`Yields`｜`Word(Notice)`，上限 24 token（`front/api/notice/Sentence.java:24-53`）。例：`Missing:[进食] ✗ 面包`（`front/engine/colony/ColonyLooks.java:66-85`）。精灵约定：doing 用 `<ns>:doing/<path>`，其他用 `<ns>:glyph/<name>`，缺图则退回 `otherwise` 文字。
- **头顶/世界卡片（overhead）**：
  - 逐居民信息卡：`LookLines(entityId, lines≤8)`、每次最多 16 名最近居民（`front/engine/net/LookLines.java:10-11`），客户端每 250 ms 请求、缓存 1 秒（`front/client/ColonyLookState.java:13-14,36-52`）；行由 `ColonyLooks.of` 组装（名字→血量 Gauge→各插件 lookLines→当前行为→阻塞原因→doingLines，`ColonyLooks.java:43-61`）。
  - 区块/路径/牌匾总览：`ColonyOverviewPacket`（members、zones、ghosts、paths、每个 path/zone 的 notes、placards），每 20 tick 请求一次（`front/client/ColonyHighlightState.java:42,77-91`）；绘制距离 outline 160 / fill 128 / card 128 / placard 160 格，卡片采用世界缩放（`CARD_SCALE=0.025`）。
  - 卡片绘制：`ColonyLookCard.rows(Line)→Row`（`front/client/ColonyLookCard.java:26-74`）→`LookCardLayout` 排版→`HoverCard`（俯瞰时贴指针）或 `WorldCards`（世界空间）。颜色区分标题/正文/警告（白/灰/红）。
  - 牌匾 `Placard(UUID, Outline.Box|Path, List<Line>)`（`front/api/Placard.java`），例如施工工地上的"已砌 N 格 / 还需要"。
- **Tooltip 与按键提示**：`Cue(keys, does, held)` + `Cues.on/under(element, …)`（`front/api/ui/Cue.java`、`Cues.java`）；`Cue.Key` 覆盖 CLICK/ALT_CLICK/USE/WHEEL/SNEAK/MODIFIER/ALTERNATE/OVERHEAD/DRAG/ESCAPE/TAB/BACKSPACE/DIGITS/PONDER 等。桌上 tooltip 会被 `LedgerTooltips` 换成"账本纸张"配色（只在 desk 内，物品 tooltip 保持原样，`front/client/LedgerTooltips.java:55-75`）。
- **文本同步纪律（关键约定）**：跨端文本只有两种形态——(a) 翻译键（`Notice`/`Component.translatable`），(b) 序列化成 NBT 的 `Component`，由客户端解析。API 就是 `Pages.text(registries, Component)` / `Pages.readText(registries, Tag)`（`front/api/ui/Pages.java:39-55`，用 `ComponentSerialization.CODEC`+NbtOps）。用于居民名、board 标题/详情/figure/footer、殖民地名、队伍名等（`DomainPage.java:273-343`，`ResidentsPage.java:357,525`）。
- **测试/悬停标识**：`Tokens.name(element, token)` 写元素 id，`Tokens.of(ResourceLocation)` 把 `ns:path/sub` 变成 `ns.path.sub`（`front/api/ui/Tokens.java`）。Ponder 的"悬停页面标签"识别就依赖 `PageKind.nameKey()` 当 token（`front/client/ponder/PonderTabs.java:61-91`）。
- **翻译链路**：`assets/folkways/lang/` 只有 **4 个文件**：`en_us.json`、`zh_cn.json`、`zh_hk.json`、`zh_tw.json`（各约 70 KB / ~896 行）。没有自动生成，新增键必须**四个文件都补**。约定前缀：`folkways.tab.*`（导航页名）、`folkways.page.*`（插件页/教程文件夹名）、`folkways.action.*`、`folkways.keys.*`、`folkways.refusal.*`、`folkways.notice/…`、`folkways.settings.*`、`folkways.sign.as_is`（原样输出一个参数）。

---

## 5. 教学系统（Ponder，基于 Create 的 Ponder）

- 组织：`Scenes.scene(title, board)` 与 `Scenes.folder(id, nameKey, icon, scenes…)`，folder 用 `Ledger.sealedOnceRead` 注册，**空 folder 直接抛异常**（`front/api/ponder/Scenes.java:27-53`）。`Scene.headerKey()` = `<ns>.ponder.<path>.header`，正文键 `<…>.text_N`。
- 注册：`FolkwaysPonderPlugin.registerScenes` 把所有场景挂在**殖民书物品**下（storyboard 名 `<folder>/<scene>`），并把 folder id 与 scene id 都 `Lessons.bind`（`front/client/ponder/FolkwaysPonderPlugin.java:30-44`、`front/client/Lessons.java:41-51`）。
- 顺序：`Lessons.folders()` 把 `basics` 排最前，其余按插件 enrollment 顺序（`Lessons.java:25-39`）。
- 触发（三条路）：
  1. **悬停页面标签并按思索键**（Create 的 ponder 键），进度条画在 tooltip 里，满则播放该页的课；页面标签 token = `PageKind.nameKey()`，目标课 = `kind.lesson().orElse(kind.id())`（`mods/core/src/main/java/io/github/izakyl/folkways/front/client/ponder/PonderTabs.java:61-79`、`mods/core/src/main/java/io/github/izakyl/folkways/front/client/ponder/PonderHint.java:77-93,95-103`）。`lesson()` 可以指向**文件夹**（如 `folkways:basics`）或**单个场景**（如 `folkways:residents`、`folkways:colony_panel`）。
  2. 教程页里点某一课或"全部连着看"（`LessonsPage.java:82-93`）。
  3. 直接对殖民书物品按思索键：所有 folder 依次播放（`mods/core/src/main/java/io/github/izakyl/folkways/front/client/ponder/FolkwaysPonderPlugin.java:30-42`）。
- 覆盖范围（13 个 folder / 14 个场景）：`basics`{colony_book, book_modes, colony_panel}、`build`{building, create_handoff}、`wares`{workshop}、`person`{residents}、`living`{household}、`farming`、`fishing`、`groundwork`、`pasture`、`orders`、`dispatch`、`rail`、`golem`（`plugins/*/…Scene.java`、`front/client/ponder/PonderIntegration.java:25-28`）。
- 强制约定：enrollment 了却没有 folder 的插件会被记 warning（`mods/core/src/main/java/io/github/izakyl/folkways/front/client/ponder/FolkwaysPonderPlugin.java:46-55`）——即"新插件必须配一课"。

---

## 6. 交互层的边界与限制（自由度设计的关键约束）

1. **不能微观指挥单个居民**。玩家对居民唯一的控制是"工种 × 允许/禁止 × 优先级 1–4"（`ResidentsPage.java:305-325`；`standing()` 把 keenness 正负号当允许/禁止，:377-383）。`Board.Act` 只有 Do/Edit/Open/Ping/Admit 五种，不存在"去做 X"的动作类型（`Board.java:98-119`）。居民的行为由规划器派发，玩家只改"可选工作的集合"。
2. **没有排班/作息/轮班系统**。吃睡是自动需求（`mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/person/living/LivingContent.java` 的 FULLNESS/SLEEPING meter），没有"几点上班""休息一天""夜班"的任何数据结构或界面。
3. **没有暂停/倍速**。模组自身没有任何时钟控制；引擎在 `server.tickRateManager().runsNormally()` 为假时直接不跑（`core/engine/labor/Labor.java:62`、`Pipeline.java:173`），即只能靠原版 `/tick`。配置文件 `FolkwaysConfig`（上游已拆为三份） 里全部是速率/上限常数（haste 列表、planHorizon、路径预算），**没有一项是玩家可调的玩法开关**（`FolkwaysConfig.java`）。唯一的"暂停"是调度页显示的自动暂停（物流网络不再满足发货条件时，`folkways.page.dispatch.paused`）。
4. **库存阈值只有一种形态**：每容器一条 `Order(into, what, low, high, standing)`，下限/上限各 1–9999，另有槽位范围 FIRST_SLOT/LAST_SLOT（`mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/orders/Order.java:12-33`、`OrdersContent.java:20-43`）。没有全局配额、没有按类别储备、没有"某区域专用库存"。注意**文档漂移**：教学文本仍写 "Priority from -2 to 2"（`mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/orders/OrdersScene.java:71`），但 `Order`/`DRAFT` 里已经没有 priority 字段。
5. **没有战斗指令**。巡逻只是"一条路径 + 一个工种"（`PatrolContent.java:29-65`（上游已新增巡逻页））；遭遇敌人由 `folkways:fighting` 行为自动触发，被攻击/着火自动逃跑（`residents.text_6`），傀儡则不主动索敌。没有攻击指定目标、守卫某点、编队/阵型、警戒等级的任何界面或数据。
6. **没有图表/历史/统计**。`MetricsPage` 只是实时库存网格 + 翻页 + 刷新；`ColonyMetrics` 里的 idle/members/zones/kinds/goods 字段算了却没有任何界面消费（`front/engine/colony/ColonyMetrics.java:14-58`，全仓唯一消费者是 `Razing.java:99`）。唯一带时间窗的数据是 `PastDay`（24 000 tick 窗口、1200 tick 分桶、按格子记录产出/消耗，`front/api/PastDay.java:29-95`），但它只被当作区域卡片的一行文字用，没有图表、导出、按人统计。
7. **不能排任务队列或手动指派**。计划/排线完全在引擎里（`core/engine/plan/**`），玩家可见的唯一"顺序"信号是订单的槽位范围与居民的工种优先级。
8. **工具策略只有一份全局清单**。设置页的"工具"是殖民地唯一装备门槛，按 item/tag 全有或全无（`CoreSettings.tool/schema:22-39`）；没有按居民、按工种、按区域的装备规则。
9. **权限模型很薄**：只有"成员/创建者/FTB 队伍"三层（`front/engine/charter/Charters.java`、`MembersPage.java:100-153`）；没有"谁能建造/谁能下订单/谁能改设置"的细分权限。
10. **设置项类型是密封的**：`Schema.Setting = Items | Count | Choice | Flag`（`front/api/Schema.java`）。没有曲线、条件、排程、嵌套规则。区域设置窗最多渲染 24 行（`ZoneSettings.SLOTS = 24`）。
11. **界面是硬预算的**：board 每页最多 32 行、每行最多 4 个动作（`DomainPage.ROW_SLOTS=32`，`Board.Row.MAX_ACTS=4`）；信息卡每张最多 8 行、每次最多 16 人（`LookLines`）；`Goods` ≤8、`Sentence` ≤24、`Notice` ≤4 参。任何"大表格 UI"都会被这些上限截断。
12. **一切操作都要手持绑定书**：`HeldBook.bound` + `ColonyBookItem.holdsBookFor` 是世界内操作的唯一门票；没有"远程/无书"控制通道（`HeldBook.java:14-29`，`ColonyAuthority.java:59-73`）。
13. **删除殖民地不可逆，且仅创建者**：需输入 `folkways.metrics.raze.phrase`（"我确认删除这个殖民地"）才执行，警告文案明确"删除后无法恢复"（`front/ui/screen/Razing.java:36-88`，lang `folkways.metrics.raze.warning`）。
14. **没有撤销**：只有"取回上一个点/丢弃正在画的图形"（`PathSelection.undo`、`ZoneSelection.discard`、`HeldPlacement.discard`）；已确认的区域/路径/订单只能靠选区设置里的 Release、订单行的删除动作或重画。
15. **蓝图必须先预览才能开工**：确认按钮仅在 `taking.previewed()` 且 hint/pattern 未变时出现（`mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/draft/client/DraftPanel.java:256-260`）——这是刻意的"先看再建"约束。
16. **无法表达全局意图**：没有"备冬""今天优先防御""集结点""商队路线"这类跨系统的策略对象；玩家能表达的只有区域用途、路径用途、订单、工种优先级四样。

---

## 7. 对我们设计新 UI 的结论

### 7.1 可直接复用的组件
- 版式：`front/api/ui/Rows.java`（`page/table/row/strip/actions/icon/name/value/note/heading/text/fills/box`，常量 `INK/QUIET/GAP/FOOT/ROW_HEIGHT/CONTENT_WIDTH/ICON_SIZE`）；`Rows.page()` + `Rows.fills(Rows.box())` 是每页的标准骨架。
- 声明式页面：`Facing.board(page, colony)` 返回 `Board(figures, rows, whenEmpty, data)` → `DomainPage` 自动渲染、自动 NBT 同步、自动处理 5 类 act；服务端只需实现 `Facing.act(page, actionKey, at, view)`（`front/api/Facing.java`、`front/api/panel/Board.java`、`front/ui/screen/DomainPage.java:251-345,449-491`）。
- 注册四件套：`Registering.enrollment(id, new Enrollment(delegations, schema, pages))` + `Registering.facing(...)` + `RegisteringUi.event.page(newPageId, Factory)` + `front/api/panel/PageKind.boarded(id, nameKey, icon[, lesson])`（`front/api/Registering.java`、`front/api/Enrollment.java`、`front/ui/UiRegistrations.java:31-56`）。注意 `PageKinds.verify()` 会拒绝重复 id，未声明的页会在启动时抛异常。
- 设置 UI：`Schema.Setting` + `SettingsPage.control(player, scope, setting)` 可同时服务殖民地作用域与 `ZoneSettings` 的 `Scope.OnZone/OnPath`（`front/ui/screen/SettingsPage.java:97-120`、`ZoneSettings.java:95-150`）。
- 选择器：`ItemPicker`（支持物品/标签/多选/方块过滤）、`ChoicePicker`、`FilterStacks`、`ItemChoice`、`ItemDrops`（`front/api/ui/**`）。
- 窗口：`Desk`（多窗拖拽+Esc 逐层关闭+占据区回传）、`Window`、`Windows.add(id,title,body)`、`LonePanel`（独立面板）、`Pane`。
- 世界内：`Shape`（Block/Body/Volume/Path）、`Delegation`、`Drawing/Draft` + `BoxOffers/PathOffers`、`Ghost/GhostRenderer/ShapePreview`、`Placing`（货架+手持放置）、`Placard`、`Line/Sentence/Notice`、`Facing.lookLines/doingLines/blockLines/zoneLines/pathLines/placards/ghosts`、`Layer`（俯瞰图层）、`Cues`（按键提示）。
- 递归扩展点：`Inlay` + `Bay` + `Nook` 允许把自家控件塞进别人的居民窗口（`front/api/ui/Inlay.java`、`Bay.RESIDENT`、`Nook`；样例 `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/person/PersonInlay.java`）。

### 7.2 必须遵守的约定
1. **跨端只传键或 Component**：服务端绝不发已翻译字符串。用 `Notice`（含 `Arg.Named` 支持嵌套键）或 `Pages.text/readText`。违反这条会在语言切换时错乱。
2. **四语言同步**：任何新键都要写进 `en_us.json`、`zh_cn.json`、`zh_hk.json`、`zh_tw.json`。
3. **命名**：页面 id `folkways:<name>`，页名键 `folkways.tab.<x>` 或 `folkways.page.<x>`，动作 `folkways.action.*`，拒绝 `folkways.refusal.*`，设置 `folkways.settings.<key>`；doing 精灵 `<ns>:doing/<path>`。
4. **给元素命名**：所有有交互的元素调用 `Tokens.name`（既是 Ponder 悬停识别的依据，也是稳定测试 id）。
5. **布局只用 taffy + Rows 常量**，不要算像素；风格只加 `lss/desk.lss` 里已有的类（`folkways_desk/row/list/card/nav/selected/chosen/priority/link/danger`），新皮肤=新 sprite 目录，不要内联颜色。
6. **反馈必须显式**：拒绝走 `Attempt.Refused(Notice)` 并落成动作栏消息，不要静默失败；成功也用动作栏（现有做法）。
7. **页面数据服务端算、按需同步**（`DataBindingBuilder.tagS2C` + `onSyncReceived`），客户端只做语言相关过滤与排版（`ResidentsPage.java:161-169` 是范例）。
8. **每个新插件配一课**（`Scenes.folder`，folder id = enrollment id），否则启动日志会有 warning，且悬停标签时没有教学。
9. **尊重上限**：32 行/页、4 动作/行、8 行卡、4 参 Notice、8 组物品；需要更多就用"列表 → 详情窗"模式（`ResidentsPage` 的 `select(index)` + `detailTag`）。
10. **不要改 `ColonyShell`**：新玩法通过 enrollment/page/facing 挂进去，它只负责导航、窗口与三种形态切换。

### 7.3 推荐做法（针对"更丰富、更自由"的目标）
- 每加一个子系统，产出一套四件套：`Declaring`（服务端状态）+ `Enrollment`（delegations/schema/pages）+ `Facing`（board/act/lines/placards）+ `Scenes.folder`（教学）。这是仓库里 seven-plugins 的统一写法，最省集成成本。
- **"自由度"必须落成四类可写数据之一**，否则要动引擎：区域/路径用途（Delegation + Schema）、订单（Order）、工种优先级（Licences keenness）、以及设置项（Schema.Setting）。
- 想加"排班/优先级 4 档以上/条件式规则"，唯一干净的落点是**扩展 `Schema.Setting` 密封接口**；这会同时触达 `Schema`、`SettingsPage.control`、`DomainPage.rowTag`、`ZoneSettings`（+`Controls`）四处，是当前架构里最集中的瓶颈，值得作为我们第一个改造点。
- 想加"微观指挥/战斗指令/图表统计"，当前**没有可复用的缝**：`Board.Act` 只能表达 5 种动词，`Line` 只能表达文本/进度/物品，因此必须新增数据与页面，并另外设计一个接受玩家命令的通道（`Facing.act` 是现成的服务端落点，但缺少本地化的动作分类）。
- 信息表达优先用 `Sentence`（图示语）+ `Line.Gauge/Bar/Goods`，这比新造 tooltip 更符合本模组风格，也能直接被头顶卡片/牌匾复用。
- 若要做大表格/统计页，请避开 32 行的 board 上限：直接写 `Draw` 实现（像 `MetricsPage`/`ResidentsPage` 那样自管同步），而不是套 `DomainPage`。