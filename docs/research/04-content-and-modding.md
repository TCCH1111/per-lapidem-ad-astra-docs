# 04 · Folkways 内容创作与二次开发能力边界

调研对象：`reference/folkways-67f28b0`（Java 21 / NeoForge 21.1.233 / MC 1.21.1，MIT，status: pre-release）。
方式：只读源码与数据包，未修改任何仓库文件。所有路径以仓库根为基准（省略 `reference/folkways-67f28b0/` 前缀）。

## 0. 一分钟结论

- Folkways 把"内容"抽成了 **shelf（货架）**：`data/<namespace>/folkways/<shelf>/` 的数据包文件，加上游戏目录 `<gamedir>/folkways/<shelf>/`（专用服务器上就是服务端根目录；以 `local` 命名空间装进一个内置 pack，`/reload` 会重读它）。货架共 5 个：`pattern` / `piece` / `blueprint` / `resident_skin` / `resident_model`。`/folkways library` 列出每层货架的内容与来源 pack，以及被拒文件的原因。
- 还有 3 个**数据包注册表**（不是货架）：`resident_look`、`resident_look_set`、`resident_name`，走 NeoForge `DataPackRegistryEvent`。
- 图案是 **Starlark 脚本**（`net.starlark.java`，jar-in-jar），能力很宽：地形勘测、几何造型、模板盖章、分阶段规则、多轮生长、玩家可调旋钮、自带 i18n 字典。但它是**纯函数式"出图"**：只输出方块方案，不落方块、不读容器、不碰 Java 世界对象。
- 纯数据包能覆盖：**建筑图案、结构件、蓝图、居民皮肤/模型、名字池、外观池**。写 Java 才能覆盖：**新职业/居民种类、新工作节点、新 UI 页、新载具 passage、新 Starlark 函数、新集成挂钩**。

## 1. 内容"货架"（shelf）总表

机制代码：`mods/core/src/main/java/io/github/izakyl/folkways/library/Shelves.java`（`Shelf`/`Stock`/`register`）、`LooseFolder.java`（游戏目录文件夹当作一个内置 pack，命名空间常量 `Shelves.NAMESPACE = "local"`，pack id `folkways/library`）、`LibraryCommand.java`（`/folkways library`，需要 `LEVEL_GAMEMASTERS`，每层货架只列前 8 条被拒原因）。
货架在插件 install 时登记：`mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/BuildPlugin.java:24`（pattern/piece/blueprint）、`mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/person/PersonPlugin.java:56`（resident_model/resident_skin）。名称定义在 `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/draft/Patterns.java:23`、`mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/draft/Templates.java:26-27`、`mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/person/look/ModelLibrary.java:39-40`。

| 货架 | 放哪（数据包 / 服务器目录） | 格式 | 加载时机 | 客户端 / 服务端差异 | `/reload` | `/folkways library` |
| --- | --- | --- | --- | --- | --- | --- |
| `pattern` | `data/<ns>/folkways/pattern/<name>.star` / `folkways/pattern/` | UTF-8 Starlark 文本，可 `load()` 别的 `.star` 当库（定义无 `draw`/`grow` 的文件即纯库，如 `materials.star`、`grading.star`） | 服务端 reload 监听器 `Patterns.reload`（`BuildPlugin.java:30`），`/reload` 触发 | 服务端解析一份；客户端靠 `PatternLibraryPacket` 收到**源码文本**再本地解析（`Patterns.acceptFromServer`，同 JVM 时不发）；客户端还额外读自己游戏目录的 `folkways/pattern/` 作为"玩家自己的图案"（`draft/client/LocalPatterns.java`） | 生效 | 列全部条目 + 来源 pack + 拒绝原因 |
| `piece` | `data/<ns>/folkways/piece/<name>.nbt` / `folkways/piece/` | 结构文件 NBT（先试 gzip 压缩，失败再试未压缩），只取 `size`/`palette`(`palettes`)/`blocks`，**air 与 structure_void 被丢弃**（`mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/draft/DraftTemplate.java:36-73`） | 与 pattern 同一次 reload（`Patterns.reload` 里先 `Templates.reload`） | 服务端一份、按 `TemplateLibraryPacket` 发给客户端；客户端另有自己目录里的 piece（`Templates.adoptOwn`） | 生效 | 列条目 + 来源 + 拒绝原因 |
| `blueprint` | `data/<ns>/folkways/blueprint/<name>.nbt` / `folkways/blueprint/` | 同结构 NBT；id 前缀 `blueprint/`，与 piece 同一个 `Templates` 库但互不占名（`Templates.java:32`） | 同上 | 蓝图由玩家在面板 Blueprints 页整栋放置，**图案不能 `template()` 引用蓝图**（`Templates.find` 对 blueprint 直接返回空） | 生效 | 单独一层货架列出 |
| `resident_skin` | `data/<ns>/folkways/resident_skin/<name>.png`（可配同名 `.json`：`arms`=`wide/slim`、`weight`） / `folkways/resident_skin/` | PNG，必须正方形且边长是 64 的倍数；不写 `arms` 时按右臂背面第 55,20 像素透明度自动判 slim（`mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/person/look/ResidentSkins.java:71-119`） | 服务端 reload 监听器 `ResidentModels.rescan`（`PersonPlugin.java:61`）扫描；`/reload` 触发 | **服务端扫描并分片把 PNG 字节发给玩家**（`ModelAssetPacket`），客户端落到 `folkways/.cache/resident_models/` 并由 `ClientResidentModels` 注册成内置资源包（`ClientResidentModels.java:37-84`）→ **玩家无需资源包** | 生效 | 条目按 `skin/...` 前缀归到 `resident_skin` 货架 |
| `resident_model` | `data/<ns>/folkways/resident_model/<模型名>/`，必备 `main.json`（Bedrock geometry）与 `main.animation.json`（其 `animations` 对象至少要有一条动画）、`textures/` 下**直接放**的 `*.png`（不再下钻子目录），可选 `folkways.json`（`idle_animation`/`walk_animation`/`work_animation`/`weight`/`fallback`） / `folkways/resident_model/` | 一套模型＝一个目录；**每个贴图生成一个 look**，id 为 `model/<模型名>/<贴图名>`，运行时映射到 **GeckoLib** 的缓存路径 `geo/resident_models/<名>.geo.json`、`animations/resident_models/<名>.animation.json`、`textures/entity/resident_models/<名>/<贴图>.png`（`ModelLibrary.java:124-190`） | 同上（同一次扫描） | 同上：服务端 `ModelLibraryPacket` 发条目表，客户端发现指纹不同再请求分片资源；缺 GeckoLib 时该类 look 退回玩家皮肤（`mods/vanilla/src/main/resources/META-INF/neoforge.mods.toml:36-42`、`ResidentRenderer.java:25`） | 生效 | 列条目 + 来源 + 拒绝原因（缺 `main.json`/`textures` 为空/动画名对不上/超限等） |

上限与拒绝（做整合包时的硬边界）：

- pattern：单文件 ≤ 131072 字符、服务端最多发 256 个、总量 ≤ 900000 字节（`mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/draft/PatternLibraryPacket.java:17-19`）；解析时执行步数上限 200000（`mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/draft/Pattern.java:45`）。
- piece/blueprint：单个 NBT ≤ 8 MiB（`mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/draft/TemplateLibraryPacket.java:17`）；蓝图另外受 `maxBlueprintVolume`（默认 1048576 格）与 `maxBuildCells`（默认 65536 格）约束。
- 模型/皮肤：单文件 ≤ 8 MiB，整库 ≤ 32 MiB；条目 ≤ 2048、资源 ≤ 1024（`ModelLibrary.java:42-43`、`ModelLibraryPacket.java:23-25`）——**皮肤/模型总量是整合包最容易踩的上限**。
- 文件名必须能当 ResourceLocation path（`LooseFolder.misnamed` 会把不能的挑出来报在 `/folkways library` 的 misnamed 里）。

三个**非货架**的数据包注册表（走 NeoForge 注册表数据加载，不走 shelf 代码，因此 `/folkways library` **看不到**、也不报拒绝原因，出错只进服务器日志）。目录统一是 `data/<pack 命名空间>/<注册表命名空间>/<注册表路径>/`，即 `data/<ns>/folkways/<注册表>/`；它们在世界的注册表访问里读取（`RegistryAccess`），改完通常要重进世界/重启服务器最保险（`/reload` 对注册表数据的重读在 1.20.5+ 之后视版本而定，不要把它当成和货架一样的即时热重载）：

| 注册表 | 文件位置 | 格式 | 谁在管 |
| --- | --- | --- | --- |
| `folkways:resident_look` | `data/<ns>/folkways/resident_look/<name>.json` | `{"type":"skin","texture":"...","arms":"wide"}` 或 `{"type":"model","geometry":...,"animations":...,"texture":...,"idle_animation":...,"walk_animation":...,"work_animation":...,"fallback":{...},"scale":...}`，都可带 `weight`（`mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/person/look/ResidentLook.java`） | `ResidentLooks.registerDataPackRegistry`（`PersonPlugin.java:57`） |
| `folkways:resident_look_set` | `data/<ns>/folkways/resident_look_set/<name>.json` | `{"looks":["folkways:alex_slim", ...]}`（`LookSet.java`） | `LookSet.registerDataPackRegistry`；殖民地可"一键采用"该集合作为外观池（`LookPool.replace`） |
| `folkways:resident_name` | `data/<ns>/folkways/resident_name/<name>.json` | `{"names":[...],"surnames":[...]}`；所有包的名字池按 id 排序合并（`ResidentNames.merged`），名字由居民 UUID 派生，**同名同姓稳定不变** | `ResidentNames.registerDataPackRegistry` |

## 2. Starlark 图案能力矩阵

### 2.1 执行模型

- 解析：`Pattern.parse` → `Starlark.execFile`，`Module.withPredeclared(Vocabulary.predeclared())` 是**唯一**注入的全局环境；语义只开了递归（`-allow_recursion = true`），`load("folkways:xxx.star", "a","b")` 走 `thread.setLoader` 的库加载器（同一 Mutability，`load("folkways:x")` 不带后缀也行）；循环 load 明确报 "a load cycle"，库不存在则 loader 返回 null 由 Starlark 报错（`Pattern.java:49-163`）。另外 `items` 旋钮里默认物品若未装载，只在日志给一条 `needs ..., which this game has not loaded` 警告（`Pattern.java:104-107, 199-205`）。
- 绘制：不跑在服务器 tick 上，跑在专用线程池（2 线程、16 MiB 栈），有秒级超时（`serverconfig` 的 `drawSeconds`，默认 10s），超时中断并以 refusal 返回（`draft/Drafting.java`）。
- 世界视野：`capture` 决定预取范围，默认 `{around:1, up:6, down:6}`（chunk / 16 格子区块；`down:"all"` 可到底），**读视野外的东西会被拒**（`mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/draft/Capture.java:22`、`mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/draft/Pattern.java:215-225`）。
- 尺寸上限：单次绘制包围盒边长 ≤ 512（`mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/draft/Extent.java:10`）；标记 path 最多 4096 点（`mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/draft/Hint.java:18`）。
- 图案接受两种标记：`accepts = ["zone"]` / `["path"]`（`Hint.ZONE/PATH`），别的标记类型不存在。

### 2.2 脚本可声明的全局

| 全局 | 含义 | 依据 |
| --- | --- | --- |
| `draw(site)` **或** `grow(site)` | 二选一，同时写报错 | `Pattern.java:71-73, 94-99` |
| `knobs = [...]` | 玩家可控项：`flag` / `count(min,max,default,icon)` / `choice(options,default)` / `items(...)` / `option(key,icon)` | `Vocabulary.java:967-1076`、`mods/core/src/main/java/io/github/izakyl/folkways/front/api/Schema.java` |
| `lang = {"en_us":{...},"zh_cn":{...}}` | 图案自带 i18n 字典；`title` 是图案名，旋钮按 key 取词，选项按 `<knob>.<option>` 取词；`zh_hk`/`zh_tw`/`zh_cn` 之间会互相回退，最后回退 `en_us` | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/draft/Face.java:13-57`、`Pattern.java:369-392` |
| `accepts = [...]` | 只允许 `zone`/`path` | `Pattern.java:394-408` |
| `phases = [...]` | 声明规则阶段顺序，默认 `["main"]` | `Pattern.java:410-419` |
| `capture = N` 或 `{around,up,down}` | 预取视野 | `Capture.parse` |
| `report(key, value)` | 产出统计（数字累加，其它按值计数），只进日志/计数 | `Vocabulary.java:1115-1125` |

### 2.3 API 清单（`Vocabulary.java` / `DraftSite.java`）

- 站点与勘测（`@StarlarkBuiltin(name="site")`，`DraftSite.java:29-390`）：`kind`、`zone`、`path`、`facing`、`altitude`、`round`、`kept`、`flag(k)`、`count(k)`、`choice(k)`、`items(k)`、`rand(bound)`、`pick(weights)`、`ground(x,z)`、`highest(x,z,of)`、`matches(at,of)`、`probe(...)`、`survey(scope)`（→`min/max/median/water/blocks`）、`settle(scope,at,offset)`；`site.path` → `points/length/every(step,offset)/headings/stretches`。
- 几何/体量：`point`、`split(axis,shares,rest,symmetric,names,snap,tolerance,emit)`、`repeat`、`comp(faces,depth)`、`outline(corners)`、`box`、`hollow(thickness)`、`gable`、`shed`、`hip`、`cylinder`、`cone`、`dome`、`sphere`、`extrude(plan,height)`、`sweep(line,width,height,y,offset)`、`cells`、`under`、`subtract`、`intersect`、`trim`、`arched`、`vault`、`group`。
- 材料与落图：`part(role,region,palette,fit,orient,labels,over,support)`（`fit`=`solid/stepped/layered/connected`）、`clear`、`mix(weights)`、`piece(key,layers)`（脚本内联积木）、`template(id,stretch)`（读 `.nbt`）、`variants`、`stamp(role,piece,scope,swap,fit,parity,overflow,labels,over)`（`fit`=`start/center/end/exact/stretch/tile`）、`blocks(points→state)`（精确方块状态）。
- 地形/条件：`terrain(scope,of)`、`extend(region,direction,until,max,keep)`、`fill_below`、`conform`、`occluded(scope,by)`、`overlaps`、`touches`、`distance(scope,to,within)`、`tally(label)`。
- 规则/流程：`rule(name,fn,phase,priority,label,labels,attrs)`、`attr(name,default)`、`report`、`grown(parts,keep,last)`。
- 拒绝与 i18n：`reject(key, *args)`、`translated(key)`；实参可以是文本/数字/布尔/`translated(...)`，最多 4 个（`Vocabulary.java:67-100`、`mods/core/src/main/java/io/github/izakyl/folkways/front/api/notice/Notice.java`）。
- Create 接缝：`joint(from,to)`（把两段轨道交给游戏自己接成曲线/坡道，**装 Create 才画得出接缝**，否则 `Joints` 是 `NONE` 空实现、不报错也不接轨；`Vocabulary.java:927-935`、`mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/Joints.java:35-72`）。

### 2.4 图案能做的 10 件事（附文件依据）

1. **任意算法**：循环、条件、递归、字典/列表推导、字符串格式化 —— `mods/vanilla/src/main/resources/data/folkways/folkways/pattern/materials.star:52-59`（`"minecraft:%s_planks" % wood` 批量生成）、`mods/vanilla/src/main/resources/data/folkways/folkways/pattern/road.star:70-93`。
2. **地形自适应**：沿路径算剖面、填挖方、桥隧判定 —— `pattern/grading.star`（`profile/earthworks/trace/bed`），`mods/vanilla/src/main/resources/data/folkways/folkways/pattern/road.star:105-120`。
3. **按原地形勘测做决策**：`mods/vanilla/src/main/resources/data/folkways/folkways/pattern/quarry.star:41-61` 用 `site.survey(zone).water` 拒绝水域、用 `ground/highest` 算边界与阶梯地板。
4. **模板盖章＋变形**：`template("folkways:cottage_door")` + `stamp(fit="stretch"|"tile", overflow="clip")`（`Vocabulary.java:743-880`；内置件 `data/folkways/folkways/piece/door.nbt`）。
5. **脚本内联积木**：`piece(key={"w":"minecraft:water"}, layers=[["w"]])`（`mods/vanilla/src/main/resources/data/folkways/folkways/pattern/terraced_field.star:90-95`）。
6. **多阶段规则与标签查询**：`rule(...) + phases + label + tally/overlaps` —— `mods/vanilla/src/main/resources/data/folkways/folkways/pattern/arcade.star:272-277`（frame/roof/dressing 三阶段，`report("framed", tally("bay"))`）。
7. **多轮生长**（跨 tick 的大型工程）：`grow(site)` + `grown(parts, keep={"n":...})` + `site.kept` —— `mods/vanilla/src/main/resources/data/folkways/folkways/pattern/mine.star:490-510`（矿井分层推进），`gametest/.../test_grower.star` 是最小示例。
8. **精确方块状态**：`blocks({point(...): "minecraft:oak_fence_gate[facing=north]"})`（`Vocabulary.java:887-926`、`mods/vanilla/src/main/resources/data/folkways/folkways/pattern/terraced_field.star:94`）。
9. **玩家可选材料槽与需求校验**：`items` 旋钮 + `part(palette=...)`，槽为空就拒绝并本地化报错 —— `mods/vanilla/src/main/resources/data/folkways/folkways/pattern/road.star:7-20, 99-101`。
10. **本地化拒绝与自带字典**：`reject("folkways.draft.error.road.width")`、`translated("folkways.draft.knob."+key)`，四种中文＋英文写在脚本里（`mods/vanilla/src/main/resources/data/folkways/folkways/pattern/road.star:21-66`）。

### 2.5 图案做不到的 10 件事

1. **没有 IO/网络/反射**：predeclared 只有 `Vocabulary`（`Pattern.java:154`），Starlark 无文件与系统能力 → 不能读外部数据、不能拉配置。
2. **不直接改世界**：图案只产出 `part/clear` 方案，由殖民地居民施工（`mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/BuildSite.java`）；"挖"是 `clear(..., terrain(...))` 描述，不是立即破坏。
3. **看不到 capture 之外的世界**：越界读取被拒（`Capture`/`Area`），不能全图扫描、不能跨维度。
4. **不能注册/生成新内容**：不能加方块、物品、实体、配方、标签；只能引用已注册 id（`#c:ores`、`#minecraft:...` 这类 tag 与 `BlockClass` 关键字如 `solid|replaceable|foliage`、`ground`、`rail`）。
5. **不能放置带 NBT 的方块实体**：结构文件里的方块实体数据被忽略，`blocks()`/`piece()` 只有 `BlockState`（`DraftTemplate.pieceOf` 只读 palette/blocks）。
6. **不能读容器、背包、实体**：没有 inventory/world-entity API（`DraftSite` 只有地形与方块类别）。
7. **不能决定材料成本与工时**：成本/需求由 core engine 与 `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/Costs.java` 从 **目标方块本身** 反推（`Costs.of(Footprint)`），图案只能通过选什么方块间接影响供给。
8. **不能持久化自有状态**：唯一的跨轮状态是 `grow` 的 `keep`（`Kept`），随该次委托结束即丢弃；没有全局变量/存档写入。
9. **不能做 UI/音效/粒子/实体**：只能通过方块状态表达；`report` 只写日志与计数。
10. **不能新增标记类型或旋钮类型**：标记只有 `zone`/`path`，旋钮只有 flag/count/choice/items/option（要加就得改 Java，见 3.3）。
11. **不能跨文件定义新全局函数给别的图案用**：`load()` 只能导入被加载文件里的**值**（函数也可以，见 `grading.star` 的 `at/centreline`），但**不能注册新的内置函数名**。

## 3. 第三方 Java 扩展点

安装顺序（`FolkwaysMod.java:105-128`）：`FMLCommonSetupEvent` → `GlobalPerks.install()` + `Ledger.open()` → `ModLoader.postEventWrapContainerInModOrder(new Declaring())` → `Relating` → 校验 → `Enrollments.gather()` → `UiRegistrations.gather()`。三个注册事件在 gather 后**关闭**，再注册会 `IllegalStateException`（`ExtensionGameTests.frontRegistrationWindowsClose`）。

| 想注册什么 | 入口 | 关键类型 / 备注 |
| --- | --- | --- |
| 内容（方块、物品、方块实体、实体、附件、数据组件） | **Folkways 不提供注册表**；用自家 `DeferredRegister`，与 Folkways 无冲突 | 参考 `mods/core/src/main/java/io/github/izakyl/folkways/front/engine/registry/FolkwaysItems.java`、`mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/wares/WaresBlockEntities.java`、`mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/person/PersonBody.java` |
| 插件本体 | 仿 `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/BuiltinPlugins.java` 的 `install(IEventBus)`：订阅 mod bus 与 `NeoForge.EVENT_BUS` | 参考 `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/build/BuildPlugin.java`、`mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/person/PersonPlugin.java` |
| 新货架（自定义数据目录） | `Shelves.register(new Shelves.Shelf("myname"))`（须在 mod 构造期／AddPackFinders 之前） | 会自动创建 `folkways/<name>/`、把游戏目录当 `local` pack、并在 `/folkways library` 出来；**但读取逻辑要自己写**（照抄 `Patterns.reload` 注册 `AddReloadListenerEvent`） |
| 居民种类 | `Declaring.residentKind(ResidentKind)` | `mods/core/src/main/java/io/github/izakyl/folkways/core/api/resident/ResidentKind.java`：`growth`(CLIMBS/Built)、`locomotion`、`embodiment`(如何从任意 Entity 读出 Body)、`participations`、`barehanded` |
| 职业/行业 | `Declaring.vocation(VocationSpec)` + `PerkPool.register(vocation, perk)` | `mods/core/src/main/java/io/github/izakyl/folkways/core/api/vocation/VocationSpec.java`（perks + kit）、`mods/core/src/main/java/io/github/izakyl/folkways/effect/perk/PerkPool.java`（须在 Ledger 写窗口内；`PerkPool.verify` 会检查职业是否被声明） |
| 感知/生理 | `Body`/`BodyState`/`BodyPerks`、`Keenness`(FIRST..FOURTH)、`Licence`/`Licences`、`Pack`/`PackKeeps`、`GlobalPerks`、`WorkExertion` 事件 | `core/api/resident/body/*`；`plugins/person/living/LivingContent.exerted` 是范例 |
| 步态/寻路 | `Declaring.locomotion(Locomotion)` + `Searches.install(Meter)` + `PathfindingLoad.install()` | `core/api/resident/Locomotion(s).java`、`Searches.java`；实现参考 `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/person/walk/Walking.java` |
| 工作/需求来源 | `Declaring.urges(owner, UrgeSource)`、`Declaring.refinement(Refinement)`、`Colony.submit(...)`/`workshop`/`stores`/`rule` | `core/api/work/*`、`mods/core/src/main/java/io/github/izakyl/folkways/core/api/colony/Colony.java`、`Costs.register(Rule)`（给"某种方块要什么材料"加规则） |
| 殖民地级状态与持久化 | `Declaring.colony(owner, ColonyContext)` → `share/tick/closed/watch/urges`；`Colony.keep(owner, CompoundTag)` / `kept(owner)`；`Colony.service(owner, Class)` | `mods/core/src/main/java/io/github/izakyl/folkways/core/api/colony/ColonyContext.java`、`Colony.java`；`/folkways library` 不显示这些，需自建命令/UI |
| 参与度（谁默认会不会做某事） | `Relating.participation(...)` / `defaultParticipation(...)` + `Participations` | `ExtensionGameTests.declareLate` 是活样例 |
| 载具/passage | `Declaring.passage(Passage)` | `mods/core/src/main/java/io/github/izakyl/folkways/core/api/passage/Passage.java`；范例 `mods/core/src/main/java/io/github/izakyl/folkways/core/shell/structure/SablePassage.java`、`mods/create/src/main/java/io/github/izakyl/folkways/create/rail/passage/RailConveyance.java` |
| 面板页 / Front | `Registering.enrollment(owner, Enrollment)`、`Registering.facing(owner, colony -> Optional<Facing>)`、`Registering.admission(owner, residentKind, Admission)` | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/Enrollment.java`（`Delegation`+`Schema`+`PageKind`）、`panel/PageKind.boarded(id,nameKey,icon,lesson)`、`panel/Board.java` |
| UI 页 / 内嵌面板 / 轮廓 | `RegisteringUi.page(id, Supplier<Draw>)`、`inlay(Bay, owner, Supplier<Inlay>)`、`outline(Outline)` | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/ui/RegisteringUi.java`、`ui/Draw.java`（返回 LDLib2 `UIElement`）；范例 `BuildPlugin.java:27`、`PersonPlugin.java:50-55` |
| 教程（Ponder） | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/ponder/Scenes.java` + `PonderScenery`，挂到 `PageKind` 的 `lesson` | 需 jij 的 Ponder（随 jar 分发） |
| notice / refusal | 直接构造 `Notice.of(kind, args)`/`new Notice(key,args)`；自定义 kind 只要实现 `NoticeKind` 或 `RefusalKind`（`Named` 默认按枚举类名生成 `folkways.refusal.<area>.<name>`） | `mods/core/src/main/java/io/github/izakyl/folkways/front/api/notice/Notice.java`、`NoticeKind.java`、`mods/core/src/main/java/io/github/izakyl/folkways/core/api/terms/RefusalKind.java`；**`DraftRefusal`/`BuildRefusal`/`ImmigrationRefusal` 等是包内枚举，不可扩展**，但报错文案可用任意 key |
| mixin 挂钩 | 每个插件自带 mixin 配置 + `IMixinConfigPlugin` 门控（`CoreMixinPlugin/CreateBuildMixinPlugin/DispatchMixinPlugin`（Build 项已改名移至 create）） | `folkways-*.mixins.json`、`FolkwaysMixinPlugin`（缺依赖时降级并记录） |

### 3.3 明确不能扩展的（最影响内容作者）

- **注册新的 Starlark 图案函数**：`Vocabulary.predeclared()` 是硬编码 `ImmutableMap`，唯一的 `@StarlarkBuiltin("folkways")` 单例；`Pattern.execute` 固定用它。第三方**无法**注入新的全局函数/类型 —— 必须 fork 源码或改 `Vocabulary.java`。
- **注册新的图案脚本全局名、旋钮类型、`accepts` 标记类型**：同上（`Pattern.schema/accepts/phases` 都是封闭解析）。
- **替换图案的加载/发送管线**（例如"只允许白名单图案"）：`Patterns`/`PatternLibraryPacket` 是包内实现，不在 API jar 里。
- **API jar 边界**：`mods/core/build.gradle:43-48`（apiJar 仅属 core） 的 `apiJar` 只打包 `core/api/**`、`front/api/**`、`Declaring.class`、`Relating.class`。要复用 `plugins/build/draft/*`（`Vocabulary`、`Patterns`、`Templates`、`Pattern`）或 `BuildPlugin`，必须依赖完整 jar（`compileOnly lib("folkways")`）或 fork——README 也声明"data pack 格式与 Java API 仍可能变"。

### 3.5 存档与版本兼容

- 殖民地存档：`mods/core/src/main/java/io/github/izakyl/folkways/core/engine/colony/ColonyRegistry.java`（`SavedData`，overworld 数据存储，名 `folkways_colonies`），内含 `schemaVersion`（`SaveVersion.CURRENT = 1`，包内类，无任何迁移代码）。
- **唯一的前向保护**：读到 `schemaVersion > CURRENT` 时返回一个 `sealed()`（只读）注册表，**拒绝覆盖原数据并打日志**（`ColonyRegistry.java:109-116`）——降级版本不会毁档，但也读不出殖民地。
- `ColonyData.save` 只存 `colonyId`/`holdings`/`keeps`；工作、计划、路径都是运行时重建。第三方 `keep(owner, tag)` 的 blob 是**不透明**的：插件被移除后数据仍在 NBT 里但无人读取（不会自动清理），殖民地搬迁时按 `Keeps.relocate` 一起搬。
- `razed` 是墓碑 UUID 集合，删殖民地不回收 id。没有跨版本数据修复工具，也没有 Java 侧的注册表校验（`Participations.verify` 只在启动时校验本 Mod 声明的内容）。

## 4. 配置项与难度调节

配置文件：`FolkwaysConfig.java`，在 `FolkwaysMod` 构造器以 `ModConfig.Type.SERVER` 注册 → 每个世界 `serverconfig/folkways-server.toml`（上游已拆为三份 *-server.toml）（README.md:109（上游已拆为三份配置））。全部为**服务端/世界级**，没有客户端配置。

| 段 | 键 | 默认 | 语义 |
| --- | --- | --- | --- |
| planning | `mode` | `DEFAULT` | `SINGLE_THREAD` = 全部在服务器线程算、路线即问即答（测试/测量用，公平但对繁忙服务器昂贵） |
| planning | `solveThreads` | `0` | DEFAULT 模式规划线程数；0 = 自动（核数/4，夹在 2..4） |
| immigration | `enabled` | `true` | 是否允许定居者自行聚集（关掉后仍可用其他方式放置居民） |
| immigration | `foodPerResident` | `8` | 一人份存粮；准入要求存粮 ≥ (人口+1)×该值 |
| immigration | `settlerIntervalTicks` | `2400` | 无人殖民地收一个定居者的白天 tick 数；N 人殖民地 ×(N+1) |
| immigration | `maxWaitingSettlers` | `5` | 单个殖民地等待中的定居者上限 |
| zones | `maxFishCells` / `maxPastureCells` / `maxFarmCells` / `maxGroundworkCells` | 4096 / 1024 / 4096 / 16384 | 玩家可框选的最大格数（每 tick 扫描成本直接相关） |
| zones | `maxPatrolPoints` / `patrolWardRadius` / `patrolWardTicks` | 32 / 16 / 2400 | 巡逻点数、止刷半径、止刷持续 tick |
| blueprints | `maxBuildCells` | `65536` | 一次蓝图/图案可写（含挖）的最大格数——**图案与蓝图的总闸门** |
| blueprints | `maxBlueprintVolume` | `1048576` | 结构文件允许声明的外接体积（防畸形文件） |
| blueprints | `drawSeconds` | `10` | 单个图案绘制超时秒数（唯一压给图案的硬限制） |
| crafting | `refusedRecipes` | 一批"浪费"配方 | 居民永不使用（视同不存在）的配方 id 列表：竹板/竹棍、工具盔甲熔回粒、打蜡铜还原、已染色羊毛/床/地毯再染 |
| perks | `buildingHaste`/`craftingHaste`/`conductingHaste`/`herdingHaste`/`farmingHaste`/`fishingHaste`/`haulingHaste` | `[0.85,0.70,0.55,0.40]` | 各职业"快手"每级对起手时间的乘子（<1 更快，>1 更慢）；列表长度＝该技能级数上限，截短列表＝封顶 |
| perks | `dispatchHaste` | `[0.85,0.72,0.62,0.55]` | 快递员版快手；**刻意做浅**（信使的时间几乎都在走路，陡阶梯几乎买不到收益） |
| perks | `asceticAppetite` | `[0.85,0.70,0.55,0.40]` | ascetic 每级对疲劳速率的乘子（<1 吃得少） |
| labor | `haulReachTicks` / `dispatchReachTicks` / `seatTicks` | 20 / 10 / 8 | 搬运、取件、就座起手 tick |
| labor | `planHorizonTicks` / `planHorizonDepth` | 3000 / 8 | 排程前瞻窗口与"路线已多深才被前瞻裁掉" |
| navigation | `pathSearchBudget` | `8.0` | 居民寻路节点扩展预算乘子（越高越能绕，也越贵） |
| navigation | `travelCeilingMicros` / `travelFloorMicros` | 8000 / 250 | 全服每 tick 可达性计算微秒上限／单殖民地不低于的下限（下限不是画质选项，是防"越省越堵"的自锁） |
| diagnostics | `logPlanHeartbeat` / `heartbeatCycles` | `true` / `10` | 规划/寻路心跳日志与间隔（每 20 tick 计一个 cycle） |

**没有、但整合包作者大概率想要的可调项**：

1. 居民/殖民地**人口上限**、每殖民地居民种类白名单（现在只能在 UI 里逐个种族的参与度上处理）。
2. **作息与工时**（一天干多久、夜间行为、季节/日程表）；现在只有计划前瞻 tick。
3. **工资/税/货币**类经济参数；没有物品经济模型（只有存粮准入）。
4. **按职业的基础工时**（现在只能调"快手"阶梯）；也没有工作进度/经验的全局倍率（`BodyPerks.XP_STEP = 32` 是常量）。
5. **图案/蓝图白名单或权限开关**：任何数据包都能 `data/<ns>/folkways/pattern/` 加图案，玩家也能放自己的图案（`LocalPatterns`），没有 allow/deny 列表，也没有"禁止客户端本地图案"的开关。
6. **蓝图上传/放置的权限与配额**（现在只有 `maxBuildCells`、`maxBlueprintVolume`、每册 64 张/64 单的限制）。
7. **外观池默认集合**：`resident_look_set` 只能由玩家在殖民地 UI 手动"采用"，没有"新殖民地默认用某集合"的配置；Maid 外观默认关闭、只能一个个打开（`LookPool`）。
8. **食物白名单**：`LivingContent.FOOD` 是**殖民地设置**（UI 里选物品），数据包/配置都改不了默认列表。
9. **集成 mod 开关**：Create/Sable/Golems/FTB Teams 等只要装了 mod 就启用，没有配置项可以"装了但不用"。
10. **客户端表现**：ghost 方块渲染、面板键位、提示详细度等没有 config（`ShoulderSurfing` 之类只按 mod 是否加载自动切换）。
11. **存档迁移/清理钩子**：只有版本闸门，没有"移除某插件后清理其 keeps"的机制。

## 5. 集成 mod 的挂钩点

依赖声明见 `mods/core/src/main/resources/META-INF/neoforge.mods.toml:36-74`、`mods/vanilla/src/main/resources/META-INF/neoforge.mods.toml:36-42`、`mods/create/src/main/resources/META-INF/neoforge.mods.toml:44-50`、`mods/modulargolems/src/main/resources/META-INF/neoforge.mods.toml:44-50`（上游已拆为四份 toml）；测试实例见 `blockwright.toml`；代码里的条件加载见 `mods/core/src/main/java/io/github/izakyl/folkways/FolkwaysMod.java:91-95`（Sable）、`mods/modulargolems/src/main/java/io/github/izakyl/folkways/modulargolems/FolkwaysModularGolemsMod.java:11-13`（Golem 已移出）、`FolkwaysMod.fitTheShell`。

| 集成 | 带来什么玩法 | 代码在哪 | 能否用数据包/配置替代 |
| --- | --- | --- | --- |
| **Create**（optional，BOTH） | ① 把 Create 蓝图交给殖民地施工（Create 蓝图工具栏新增一个工具）；② 把组装好的列车交给居民驾驶（车厢座位/时刻表）；③ 从 stock keeper 包裹网络下单/取件；④ 图案 `joint()` 让铺轨自动接曲线与坡道 | `mods/create/src/main/java/io/github/izakyl/folkways/create/build/CreateBlueprintHandoff.java`、`CreateHandoffTool.java`、`mixin/ToolTypeMixin.java`、`mods/create/src/main/java/io/github/izakyl/folkways/create/rail/**`（`RailConveyance`、`ConductorPlanning`）、`mods/create/src/main/java/io/github/izakyl/folkways/create/dispatch/**`（`CreatePackageNetwork.java`、`CreatePorts.java`、`StationBlockEntityMixin`/`PackagePortBlockEntityMixin`/`StockTickerBlockEntityMixin`/`GlobalStationMixin`）、`mods/create/src/main/java/io/github/izakyl/folkways/create/build/CreateJoiner.java`、`CreateTrack.java`（`mods/create/src/main/java/io/github/izakyl/folkways/create/build/CreateBuildPlugin.java:15-16`（上游已移到 create） 里 `CreateMod.loaded()` 才装）、`CreateObstacles.java`（`Structures.install`） | 否。玩法本身在 Java；图案里的 `joint()` 在**没有 Create 时不会报错**，只是接缝画不出来（`Joints.NONE`，`Joints.java:35-72`）——所以图案可以通用，但要曲线轨道就必须带 Create |
| **Sable**（optional，BOTH，含 Create Aeronautics） | 居民能走**上/下** Sable 子层级（飞船甲板）：可达性接入 `WorldSpaces`，上下船是 `SablePassage` | `mods/core/src/main/java/io/github/izakyl/folkways/core/shell/structure/SableSpaces.java`、`SableMoves.java`、`mods/core/src/main/java/io/github/izakyl/folkways/core/shell/mixin/SableAssemblyMixin.java`、`mods/core/src/main/java/io/github/izakyl/folkways/core/shell/structure/SablePassage.java`、`SablePlugin.java`（上游已删除）；探测 `mods/core/src/main/java/io/github/izakyl/folkways/FolkwaysMod.java:92`、`mods/core/src/main/java/io/github/izakyl/folkways/FolkwaysMod.java:92`（Sable 判断移入 core） | 否（纯 Java 挂钩）；无 Sable 时相应 passage 不存在 |
| **Modular Golems**（optional，BOTH） | 傀儡作为**第二种居民**：进名册、接职业、被派工 | `mods/modulargolems/src/main/java/io/github/izakyl/folkways/modulargolems/GolemPlugin.java`、`mods/modulargolems/src/main/java/io/github/izakyl/folkways/modulargolems/domain/GolemContent.java`、`mods/modulargolems/src/main/java/io/github/izakyl/folkways/modulargolems/resident/GolemKinds.java`、`Golems.java` | 否。这是"第三方 mod 用 Folkways 官方扩展点"的**最佳模仿对象**：只用 `Declaring` + `Registering` |
| **GeckoLib**（optional，CLIENT） | 让 `resident_model` 货架的 Bedrock 模型真正渲染出来（含 `idle`/`walk`/`swing_hand` 这类未加密 YSM 动画名回退）；也用于播放 Maid 模型动画 | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/person/ResidentGeoBackend.java`、`ResidentRenderer.java:25`（按 mod 是否加载选择后端）、`ModelLibrary.java:148-152`（`pick` 里的 YSM 动画名回退） | 部分：**模型数据是数据驱动的**，但没有 GeckoLib 时这些 look 静默退回玩家皮肤 |
| **Touhou Little Maid**（optional，BOTH，需 GeckoLib） | 把已安装 Maid 的内置模型借来当居民外观，可逐个或整包启用 | `mods/vanilla/src/main/java/io/github/izakyl/folkways/plugins/person/look/MaidLooks.java`（`MOD = "touhou_little_maid"`，从安装目录读）、`MaidAssets.java`（转成 GeckoLib 几何/动画）、`Molang.java`、`ClientMaidModels.java`（客户端 pack finder） | 否（读的是对方 mod 的资源）；外观池默认**不含** Maid，需玩家在 UI 打开（`LookPool`） |
| **FTB Teams**（optional，BOTH） | 殖民地创建者可把它**交给自己的队伍**：之后队伍成员共同保有，队长代行创始人权限 | `mods/core/src/main/java/io/github/izakyl/folkways/front/engine/charter/FtbTeams.java`（只用 `FTBTeamsAPI`，含 `TeamEvent` 监听）、`Teams.java`、`Charters.java:243-258`；装载点 `mods/core/src/main/java/io/github/izakyl/folkways/front/engine/Front.java:49-50` | 否；未装则 `Teams.partyOf` 恒空，交队功能自然消失 |
| **JEI**（optional，CLIENT） | 让 JEI 里的物品能**拖到**殖民地面板的筛选/需求槽上（落点由 `FilterTargets` 提供），并让 JEI 知道哪些区域属于 Folkways 界面 | `mods/core/src/main/java/io/github/izakyl/folkways/front/client/FolkwaysJeiPlugin.java`（`@JeiPlugin` + `addGhostIngredientHandler`）、`mods/core/src/main/java/io/github/izakyl/folkways/front/client/FilterTargets.java` | 否（无 JEI 时用 Folkways 自带 picker / 手动填槽） |
| **EMI**（optional，CLIENT） | 同上的拖放；额外注册通用屏幕边界 provider，让 EMI 的物品列表与殖民地面板并排而不重叠 | `mods/core/src/main/java/io/github/izakyl/folkways/front/client/FolkwaysEmiPlugin.java`（`@EmiEntrypoint`、`addGenericDragDropHandler`、`addGenericScreenBoundsProvider`，边界取自 `Desk.occupied`） | 否 |
| Shoulder Surfing（optional，CLIENT） | 第三人称相机下 Colony Book 沿准星瞄准 | `mods/core/src/main/java/io/github/izakyl/folkways/front/client/ShoulderAim.java`、`Aim.java:26` | 否 |
| Ponder / Flywheel / LDLib2 | 教程场景、渲染、所有 UI（**LDLib2 是硬依赖**，Ponder/Flywheel 打进 jar） | `mods/core/src/main/java/io/github/izakyl/folkways/front/client/Lessons.java`、`front/api/ponder/*`、`mods/core/src/main/resources/META-INF/neoforge.mods.toml:28-50`（create 块已改写） | 否 |
| Lithostitched / Terralith / Tectonic | 只在 **bench**（性能基准）实例里提供"模组地形"（`blockwright.toml:108-123`、`blockwright.toml:174-178`），**代码里没有任何挂钩**；图案靠 `site.ground/highest/survey` 自适应 | — | 不需要挂钩；数据包层面天然兼容，但"在 Terralith 地形上能不能建成"要靠图案自己的拒绝条件（如 `quarry.star` 的 `size/water` 校验） |

## 6. 结论：纯数据包能走多远 vs 必须写 Java

**纯数据包 / Starlark / 资源包能做的（整合包 90% 的"加内容"）**

1. 新增建筑图案（`.star`），含地形自适应、模板盖章、多轮施工、玩家旋钮、四种中文 i18n；可 `load()` 内置库（`materials.star`/`grading.star`）也能自建库。
2. 新增结构件（`piece/*.nbt`）与整栋蓝图（`blueprint/*.nbt`），可被图案 `template()` 引用（piece）或由玩家整栋放置（blueprint）。
3. 新增居民外观：`resident_skin/*.png`（服务端分发，玩家无需资源包）、`resident_model/<名>/`（Bedrock 模型，需 GeckoLib）、`resident_look` 数据包注册表（含 weight 权重、model 的 fallback 皮肤）。
4. 新增/替换名字池（`resident_name`）与外观集合（`resident_look_set`）。
5. 用 `serverconfig/folkways-server.toml`（上游已拆为三份 *-server.toml） 调节规模上限、性能预算、移民与技能阶梯、禁配配方白名单——**这是整合包"难度调节"的主力**。
6. 通过资源包改名/贴图，通过数据包标签（`data/folkways/tags/block/*` 等）微调分类；发布时用 `/folkways library` 校验加载与拒绝原因。

**必须写 Java 才能做的**

1. 新职业/新行业（`Declaring.vocation` + `PerkPool`）、新居民种类（`Declaring.residentKind`）、新步态/感知/生理。
2. 新工作节点、新 urge 来源、计划重写规则（`Refinement`/`NodeSpec`/`Colony.submit`）、新的材料成本规则（`Costs.register`）。
3. 新的 Starlark 图案函数/类型/旋钮类型/标记类型 —— `Vocabulary.predeclared()` 固定，必须改源码。
4. 新 UI 页、内嵌面板、面板 outline、殖民地 Front/Board、admission 规则（`Registering`/`RegisteringUi`）。
5. 新载具 passage（`Declaring.passage`）、新集成 mod 挂钩（Create/Sable/Golem 式）、新 mixin 门控。
6. 殖民地级状态机与持久化（`ColonyContext.share/tick/closed`、`Colony.keep`），以及任何需要读容器/实体/网络的能力。
7. 新货架或修改发牌逻辑（例如图案白名单、只发部分图案给客户端）——`Patterns`/`PatternLibraryPacket` 不在 API jar 内，需要 fork。
8. 新集成 mod 的"装了就启用"行为开关、面板客户端表现、存档迁移清理 —— 目前都没有配置/数据包入口，只能改 Java。

> 给整合包的实用建议：把 **图案＋结构件＋皮肤/模型＋名字池＋serverconfig** 当作主要内容载体；只把"新职业/新工作/新界面/新集成"留给 Java。任何图案相关的新函数、任何"限制玩家能写什么图案"的需求，都要提前按 fork 或 PR 上游来规划。