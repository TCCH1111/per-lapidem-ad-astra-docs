# 08 · 季节 / 温度 / 口渴能否挂到 Folkways 居民身上

调研范围：外部 mod（Cold Sweat / Serene Seasons / Tough As Nails / Thirst Was Taken）的实体级接入面，以及 fork 后 Folkways 侧的挂点。
方法：Modrinth API + GitHub codeload 源码 + 下载 1.21.1 发布 jar 后 `javap` 读真实公开签名。证据分 **A 级**（真实源码/字节码 API 列表）、**B 级**（文档/描述）。

证据位置（临时目录 `.research-tmp/`，可直接删除；上游 URL 见各节）：
- Cold Sweat 源码镜像 `.research-tmp/cs/Cold-Sweat-1.21-FG/`（branch `1.21-FG`，`gradle.properties: mod_version=2.4.4`，与发布版 2.4.4 对应）
- Serene Seasons 源码镜像 `.research-tmp/ss1211/SereneSeasons-1.21.1/`
- 四个发布 jar（`.research-tmp/*.jar`）——本文标 [A] 的签名可用
  `javap -classpath ".research-tmp\ColdSweat-2.4.4.jar" com.momosoftworks.coldsweat.api.util.Temperature` 自行复核。

---

## 0. 一分钟结论

1. **Cold Sweat 不是玩家专用**。它的温度是 NeoForge `AttachmentType`，且**明确为"非玩家 LivingEntity"准备了 `EntityTempCap`**；第三方可用 `EnableTemperatureEvent.setEnabled(true)` 把**任意实体类型**拉进温度系统。这是 A 级结论、也是本次调研最重要的发现。
   - 但：默认只开了 `minecraft:player`；NPC 的更新频率被降到 1/40；"太冷会怎样"的**后果**只有 `DecreaseDrops` / `PreventBreeding` 两个内置实体效果——**数值能挂上，行为要自己写**。
2. **Serene Seasons 的季节是世界（维度）级**，有真正的公开 API（`SeasonHelper.getSeasonState(Level)`），任何实体都能读。**但它 ARR（All rights reserved）**：可以"编译期依赖 + 运行期可选"，不可以拷贝代码、不可以打包分发它的 jar、不可以 fork。
3. **口渴两家都是玩家专用**（`ThirstHelper.getThirst(Player)`；`AttachmentType<PlayerThirst>`）——**纯玩家**，没有任何第三方实体入口。想让小人渴，只能自研。
4. **Folkways 居民的接入面比预期好**：`ResidentEntity extends PathfinderMob`（是 `LivingEntity`），Folkways 自己就在用 NeoForge `AttachmentType`；殖民地级状态走 `ColonyContext`（`urges/tick/closed/watch/share`），而且**已经有一个完整的居民需求先例**（`LivingPresence` + `Hunger`：foodLevel/saturation/exhaustion + `Urge` + NBT）。
   - 但引擎里**没有任何环境感知**（无天气/温度/季节读取），移动速度只来自 `BodyRunner` 的 `PACE * spec().pace()`。
5. **推荐路线 (C) 混合，但分工明确**：外部 mod 只当**世界数据源/传感器**；**居民侧状态（体温、口渴）必须自研在 Folkways 内**，挂在 `ColonyContext` 上，走 `Urge` 驱动行为。
6. **"Serene Seasons + Cold Sweat 能不能整合到小人身上"→ 有条件能**（5 个条件见 §5.4）：数据能挂上，行为必须自己写；SS+CS 是传感器，不是大脑。

---

## 1. Cold Sweat（`cold-sweat`，1.21.1 NeoForge 2.4.4）

上游：<https://github.com/Momo-Softworks/Cold-Sweat>（branch `1.21.1` 对应 `1.21-FG`）、<https://modrinth.com/mod/cold-sweat>、文档 <https://mikul.gitbook.io/cold-sweat/>。
下面凡标 [A] 者，均在 `ColdSweat-2.4.4.jar` 上用 `javap` 复核过签名。

### 1.1 温度挂在哪

| 问题 | 结论 | 证据 |
| --- | --- | --- |
| 挂在什么机制上 | **NeoForge `AttachmentType`**，id `cold_sweat:entity_temperature`，值为 `ITemperatureCap` | [A] `ModDataAttachments.java:24-36`（`AttachmentType.serializable(...)`，`NeoForgeRegistries.ATTACHMENT_TYPES`）。**不是**旧式 Forge Capability（类名叫 Cap 但机制是 attachment） |
| 玩家与 NPC 是否同一份 | 分两份：`PlayerTempCap`（玩家）/ `EntityTempCap`（非玩家 LivingEntity） | [A] `EntityTempCap.java:8-12` 注释原文 "This capability isn't used for players (see PlayerTempCap instead)" |
| 谁能拿到 | `AttachmentType` 的工厂对非玩家实体返回 `null`，除非 `EntityTempManager.isTemperatureEnabled(living)` | [A] `ModDataAttachments.java:29-34` |
| 能挂到任意 `LivingEntity` 吗 | **能，但要显式开启**。默认白名单只有玩家：`TEMPERATURE_ENABLED_ENTITIES = {EntityType.PLAYER}` | [A] `EntityTempManager.java:88` |
| 开启入口 | `EnableTemperatureEvent`（`ICancellableEvent`，有 `setEnabled(boolean)`），在 `ServerConfigsLoadedEvent` 时对 `BuiltInRegistries.ENTITY_TYPE` **每个类型发一次** | [A] `api/event/core/init/EnableTemperatureEvent.java:12-31`；`AddTempAttributes.java:70-107`（:85-89 是 `post` → `setEnabled` → `TEMPERATURE_ENABLED_ENTITIES.add`） |
| 开启后额外做了什么 | 用**反射**写 `CommonHooks.FORGE_ATTRIBUTES`，给该实体类型补 9 个温度属性（`cold_sweat:world_temperature` 等） | [A] `AddTempAttributes.java:48-58, 91-105`（反射 hack，见风险 §5.5） |

**结论**：模型挂在**任意 `LivingEntity` + NeoForge 附件**上，**不是 player 专用**；只要在 `EnableTemperatureEvent` 里点头，Folkways 居民的 `Temperature.get(entity, Trait.WORLD)` 就是真的。

### 1.2 公开 API（[A]，`javap ColdSweat-2.4.4.jar`）

- 读/写体温：`api/util/Temperature.java`
  - `Temperature.get(LivingEntity, Trait)` / `set(...)` / `add(...)`
  - `Temperature.addModifier(LivingEntity, TempModifier, Trait, Placement)` / `removeModifiers(...)` / `getModifier(s)(...)`
  - `Trait`：`WORLD`（环境体感）、`BASE`（自身体温）、`RATE`、`FREEZING_POINT`、`BURNING_POINT`、`HEAT/COLD_RESISTANCE`、`HEAT/COLD_DAMPENING`
  - `Units`：`MC` / `C` / `F`（`Temperature.convert`）
- 环境影响的注册：`api/temperature/modifier/*` —— `TempModifier` 是 `Function<Double,Double> calculate(LivingEntity, Trait)`，**入参就是 `LivingEntity` 而不是 `Player`**，所以自带的环境项（群系温度、海拔、遮蔽、方块热源、周围实体、洞穴、天气…）对 NPC 同样成立。清单见 `api/temperature/modifier/`（Biome/Elevation/Shade/Block/Entities/Cave/Water/Food/ArmorInsulation/Warmth/Frigidness/Waterskin/Mount/SoulLamp…）。
- 方块影响注册：`api/registry/BlockTempRegistry.java`、`api/temperature/block_temp/*`（`SimpleBlockTemp`、`FurnaceBlockTemp`、`NetherPortalBlockTemp`）、`api/spread_rule/*`（`DefaultSpreadRule`、`SmokestackSpreadRule`、`CreatePipeSpreadRule`）。
- 注册表事件：`TempModifierRegisterEvent`、`BlockTempRegisterEvent`、`AddRegistriesEvent`（`api/event/core/registry/*`）。
- 修改变量：`TempModifierEvent.Calculate.Pre/Post`、`Add`、`TemperatureChangedEvent`（`api/event/common/temperautre/*`）。
- 实体查询工具：`EntityTempManager.getTemperatureCap(Entity)`、`isTemperatureEnabled(Entity)`、`hasClimateData(Entity)`、`getAttribute(Trait, LivingEntity)`（[A] `EntityTempManager.java:707-777, 894-911`）。

### 1.3 生态与性能（**关键风险**）

- 更新循环挂在 **`EntityTickEvent.Pre`**（对所有已启用实体类型每 tick 进函数），内部再由各 modifier 的 `tickRate` 降频；非玩家被系统性降频：玩家 ×1、temp-sensitive ×4、其余 ×40（`EntityTempManager.java:135-142, 211-215`）。
- **玩家专属**的部分（NPC 拿不到，需自补）：水/雨/冰冻（`handleWaterFreezingFire`, `PlayerTickEvent.Pre`，:453-489）、睡觉降温（:617-632）、进食温度（`onEatFood`，:669-704）、背包物品温度（`InventoryItemsTempModifier`，:179-180）。
- 有**两套** NPC 模式：
  - 基础：config `Enable Entity Climates = true` + Entity Climate 名单里有该实体 → 装 `EntityClimateTempModifier`（tickRate 200），只判"这环境能不能活"（[A] `EntityTempManager.java:126-132`；`EntitySettingsConfig.java:86-121`）。
  - 高级：config `Use Advanced Entity Climates = true` → 走完整 modifier 链，官方注释自认"大量实体时可能性能有问题"（[A] `EntitySettingsConfig.java:123-128`）。
- 温度**后果**是数据驱动的：注册表路径 `cold_sweat:entity/temp_effects`（[A] `ModRegistries.java:40`），内置 JSON 只有 `default_player.json` 与 `default_entity.json`（后者 `effects: []`，即**默认 NPC 没有任何温度效果**）。内置实体效果只有 2 个：`DecreaseDropsEffect`、`PreventBreedingEffect`（[A] `api/temperature/effect/entity/*`）。→ **"太热就不干活"不会自己发生**。
- KubeJS 集成真实存在：jar 根 `kubejs.plugins.txt` → `KubePlugin`；脚本绑定名 **`coldsweat`**，可 `coldsweat.getTemperature(entity, "world")` / `setTemperature` / `addModifier` / `getTemperatureAt(level,pos)`（[A] `compat/kubejs/KubePlugin.java`、`KubeBindings.java`、`KubeEventHandlers.java:17-25`）。但 `EnableTemperatureEvent` 是 NeoForge 总线事件，**KubeJS 脚本订阅不了** → 纯脚本只能走"config 开 Enable Entity Climates + 把实体写进 climate 名单"这条基础路（`EntityClimateBuilderJS` 类存在；是否真写 `ConfigSettings.ENTITY_CLIMATES` **未验证**）。
- 活跃度：1.21.1 最新 2.4.4（2026-10-16，Modrinth API），**是四个候选里唯一还在活跃维护的**。

### 1.4 许可（**必须人工确认**）

四份声明互相矛盾：

| 来源 | 声明 |
| --- | --- |
| Modrinth API `license` | `GPL-3.0-or-later` |
| 仓库 `LICENSE`（1.21-FG，2064 B） | 只有 "GNU GPL 3.0 - MikulDev" + 截断的 GPL 前言，**没有完整条款、也没有附加条款** |
| `gradle.properties` | `mod_license=LGPL-3.0` |
| jar 内 `META-INF/neoforge.mods.toml` | `license="GNU General Public License v3.1"`（不存在的版本号） |
| `README.md` | "**PLEASE READ THE LICENSE** as there are important amendments … regarding derivative works and mods which use the Cold Sweat API"（B 级警告，但 1.21-FG 的 LICENSE 文件里找不到这些修订） |

处理建议：**按 GPL-3.0-or-later 最保守处理**。含义：可以 `compileOnly` 编译期依赖 + 运行期可选；**fork 它 = 我们的衍生作品必须整体 GPL-3.0**（会传染到链接它的代码）。列入 §6 人工补核。

---

## 2. Serene Seasons（`serene-seasons`，10.1.0.9 beta）

上游：<https://github.com/Glitchfiend/SereneSeasons>（branch `1.21.1`）。以下 [A] 均在 `SereneSeasons-neoforge-1.21.1-10.1.0.9.jar` 上 `javap` 复核。

### 2.1 季节是**世界（维度）级**，不是玩家级

- 状态存在 `SeasonSavedData extends SavedData`（`sereneseasons/season/SeasonSavedData.java`，字段 `public int seasonCycleTicks`）。
- 只在**白名单维度**推进：`SeasonHandler.onLevelTick(TickEvent.Level)` 先判 `ModConfig.seasons.isDimensionWhitelisted(level.dimension())`；再受 gamerule `SSGameRules.RULE_DOSEASONCYCLE` 控制（[A] `SeasonHandler.java:40-48, 52-55`）。
- 温度修正是**注入 `Biome.getTemperature`**（群系级），不是玩家级：`SeasonHooks.getBiomeTemperature(Level/LevelReader, Holder<Biome>, BlockPos)` + `getBiomeTemperatureInSeason(SubSeason, ...)`（[A] `SeasonHooks.java:116-140`，mixin `MixinBiome`）。→ **任何实体都自动受益**。

### 2.2 公开 API（[A]，类在 `sereneseasons.api.*`）

| 目标 | API |
| --- | --- |
| 读当前季节 | `sereneseasons.api.season.SeasonHelper.getSeasonState(Level)` → `ISeasonState`（客户端/服务端都行，源码注释明说） |
| 子季节/天数/时长 | `ISeasonState.getSeason()` / `getSubSeason()` / `getTropicalSeason()` / `getDay()` / `getSeasonCycleTicks()` / `getDayDuration()` / `getSubSeasonDuration()` / `getSeasonDuration()` / `getCycleDuration()` |
| 枚举 | `Season`（SPRING/SUMMER/AUTUMN/WINTER）；`Season.SubSeason`（EARLY_SPRING … LATE_WINTER，12 个）；`Season.TropicalSeason` |
| 群系是否热带季节 | `SeasonHelper.usesTropicalSeasons(Holder<Biome>)` |
| 季节变化通知 | `SeasonChangedEvent.Standard` / `.Tropical`（`getLevel()`、`getPrevSeason()`、`getNewSeason()`） |
| 季节→群系温度 | `SeasonHooks.getBiomeTemperature(...)`（**注意：`sereneseasons.season` 包，不是 `api` 包**，属内部实现，随版本可能变） |

**事件总线的坑**：`SeasonChangedEvent extends glitchcore.event.Event`，由 `glitchcore.event.EventManager.fire(...)` 发出（[A] `SeasonChangedEvent.java:7`；`SeasonHandler.java:116,120`）——**不是 NeoForge 总线**。要监听就得依赖 GlitchCore 的事件系统；不想依赖就每 N tick 轮询 `SeasonHelper.getSeasonState(level)`（便宜，纯算术）。

### 2.3 许可与"编译期依赖 + 运行期可选"

- 仓库 `LICENSE` 全文一行：**"All rights reserved."**（[A]）→ **ARR**，Modrinth 元数据亦为 `LicenseRef-All-Rights-Reserved`（与 `docs/pack/01-modlist.md:92,267` 一致）。
- ARR 下"compileOnly + 运行期可选"意味着：
  1. **可以**：把它的 jar 当 `compileOnly` 编译我们的桥接类；整合包**不打包**它的 jar（让用户/启动器各自获取）。
  2. **不可以**：拷贝它的任何代码/资源进我们的 mod（无授权）；fork 改它；把它打成我们 jar 的 shim/再分发。
  3. **必须**：设计成"没有它也能运行"（否则就是硬依赖一个随时可能拒绝/改版的 ARR 产物，且用户装不上时整个功能崩）。
  4. 整合包分发：`docs/pack/01-modlist.md:267` 已把它列在"必须逐个确认 CF 页面 modpack 许可"的中风险档。
- 另有现实风险：GlitchCore 三载共享（`docs/pack/01-modlist.md:246`），10.1.0.9 是 beta。

---

## 3. 口渴类（Tough As Nails / Thirst Was Taken）

以下全部 [A]（发布 jar `javap`）：

| mod | 版本 | 实体状态挂载 | 公开 API | 能否给 NPC 用 |
| --- | --- | --- | --- | --- |
| **Tough As Nails** | 10.1.0.13（2024-10-22，ARR，依赖 GlitchCore） | 只有玩家 | `toughasnails.api.thirst.ThirstHelper.getThirst(Player)` / `canDrink(Player, boolean)`；`IThirst` 只有 get/set；`TemperatureHelper.getTemperatureForPlayer(Player)`、`getTemperatureData(Player)`、`IPlayerTemperatureModifier.modify(Player, TemperatureLevel)`；tick 入口 `ThirstHandler.onPlayerTick(Player)`、`TemperatureHandler.onPlayerTick(Player)` | **不能**。所有实体入口的类型都是 `Player`。唯一非玩家的是**世界温度查询** `TemperatureHelper.getTemperatureAtPos(Level, BlockPos)`（这个可以当世界数据源用） |
| **Thirst Was Taken** | 1.21.1-2.1.5（MIT） | NeoForge attachment `ModAttachment.PLAYER_THIRST : AttachmentType<PlayerThirst>` | `dev.ghen.thirst.api.ThirstHelper`（只有物品/食物注册、`playerRestoresThirst(ItemStack, Player)`）；`IThirst.tick(Player)` / `addExhaustion(Player, float)` | **不能**。attachment 的持有者语义与全部方法签名都是玩家；无法"劫持"成任意实体 |

补充：Thirst Was Taken 与 Cold Sweat 有互相 compat（`ThirstHelper.shouldUseColdSweatCaps`），但**都停留在玩家**。Cold Sweat 自己的构建里 compat 的其实是另一个 mod `thirst-was-reclaimed`（`build.gradle:126`）——说明这条生态线本身在换代。

**结论**：口渴**必须自研**。好消息是 Folkways 已有可照抄的完整先例（§4.3）。

---

## 4. Folkways 侧接入面（`reference/folkways-master/`）

### 4.1 居民本体与数据挂点

| 事项 | 结论 | 证据（文件:行号） |
| --- | --- | --- |
| 居民是什么 | `ResidentEntity extends PathfinderMob implements Body` → **是 `LivingEntity`**，NeoForge 属性/附件/事件全可用 | `src/main/java/io/github/izakyl/folkways/plugins/person/ResidentEntity.java:49` |
| 实体类型 | `folkways:resident`，`MobCategory.MISC`，0.6×1.95 | `plugins/person/PersonBody.java:34-46` |
| 属性注册 | `EntityAttributeCreationEvent` → `ResidentEntity.createAttributes()` | `plugins/person/PersonBody.java:79-81`；`ResidentEntity.java:89-96` |
| **Folkways 自己就用附件** | `FolkwaysAttachments`：`resident_capabilities`(→`Licences`)、`body_state`(→`BodyState`)、`colony_member`(→`Optional<UUID>`)，全走 `NeoForgeRegistries.ATTACHMENT_TYPES` | `core/api/resident/body/FolkwaysAttachments.java:19-46`，`register(IEventBus)` 在 :51-53 |
| **可扩 vs 不可扩** | `BodyState` 是**包私有 final class**；`FolkwaysAttachments.BODY_STATE` 是**包私有**；`Body.state()` 是 **private** → 第三方**塞不进** BodyState | `core/api/resident/body/BodyState.java:14`；`FolkwaysAttachments.java:29`；`Body.java:28-30` |
| 第三方能用的持久化 | ① 自己 `DeferredRegister<AttachmentType<?>>`（与 Folkways 做法相同，NeoForge 自动随实体存 NBT）；② `Colony.keep(owner, CompoundTag)` 存殖民地级 blob | `core/api/colony/Colony.java:47`（`void keep(ResourceLocation owner, CompoundTag tag)`） |
| `BodyState` 里现在存什么 | `Colony`(UUID) / `Pack` / `Perks`，`serializeNBT` 手工拼 tag | `BodyState.java:16-84` |
| `Licence` 是挂点吗 | **不是**。它只是 `Vocation + Keenness` 的不可变值对象（职业凭证） | `core/api/resident/body/Licence.java:6-22` |
| `Pack` 是什么 | 居民**物品容器**，默认 18 格，自带 `save/load`/`insert`/`countMatching`，可 `applyCapacityMultiplier` 扩容 | `core/api/resident/body/Pack.java:19-44, 167-201` |
| 居民的 NBT | 自己的 `addAdditionalSaveData`/`readAdditionalSaveData` 只存 Look/GivenName/Surname（BodyState 由附件机制独立存） | `plugins/person/ResidentEntity.java:330-356` |

### 4.2 移动 / 寻路是否经过 Locomotion

**没有 `Gait` 类型**（Folkways 无此概念），等价物是 `Locomotion` → `Conveyance`：

- 契约：`Locomotion{ id(); NodeEvaluator newEvaluator(Search); void fit(Mob); Conveyance along(double speed, RefusalKind lost); }` — `core/api/resident/Locomotion.java:8-17`
- 步行实现：`Walking.along(speed, lost) → new OnFoot(speed, lost)`、`Walking.newEvaluator → ResidentNodeEvaluator`（开/关门）— `plugins/person/walk/Walking.java:29-51`
- 实际下单：`OnFoot.repath` → `body.getNavigation().moveTo(path, speed)` — `plugins/person/walk/OnFoot.java:148-154`
- **速度从哪来**：`BodyRunner.setOut`：`double speed = PACE * current.spec().pace();` — `core/engine/labor/BodyRunner.java:520`（`Trip` 在 :521-525 把它交给 `Locomotion.along`）
- 寻路导航被替换成 Folkways 自己的：`ResidentPathNavigation` / `ResidentMoveControl` / `ResidentNodeEvaluator` — `ResidentEntity.java:110-114`；`plugins/person/walk/ResidentPathNavigation.java`、`ResidentNodeEvaluator.java`
- 体力/消耗事件：`WorkExertion.performed(body, workDone, activeTicks, distance)` 在 `OnFoot.release` 发出 — `plugins/person/walk/OnFoot.java:103`；`core/api/work/WorkExertion.java`

**→ "太冷/太热影响行为"有三个互不冲突的旋钮**：
1. **`MOVEMENT_SPEED` 属性 modifier**（Folkways 已用这个手法做 BRISK 技能）— `plugins/person/ResidentEntity.java:288-296`；
2. 改 `BodyRunner:520` 的 `speed`（fork 后，最直接地冻结"走不快"）；
3. 新增一个 `Urge`（如"去烤火/去喝水"），走 `ColonyContext.urges`。
另可在 `ResidentNodeEvaluator` 给雪地/水中加路径代价（fork 后）。

### 4.3 需求系统的现成模板（**最重要的接入面**）

- 声明入口：`ColonyContext{ owner(); colony(); server(); urges(BiFunction<Worker,ColonyView,List<Urge>>); tick(Consumer<MinecraftServer>); closed(...); watch(ResourceLocation, Holding.Watch); share(Object); }` — `core/api/colony/ColonyContext.java:11-23`
- 声明示例（**照抄这个就是新需求系统**）：
  ```java
  declaring.colony(ID, scope -> { scope.share(state); scope.urges(state::urges); scope.tick(state::tick); scope.closed(state::closed); });
  ```
  — `plugins/person/living/LivingContent.java:66-73`
- 现有实现 `LivingPresence`（`plugins/person/living/LivingPresence.java:57`）：
  - 每人一份状态：`Map<UUID, Hunger> bellies`（:86）、`Map<UUID, Rest> wear`（:88）
  - 阈值门：`Watermark hunger = new Watermark(14, 4, Hunger.REGEN_FOOD_LEVEL)`（:81）、`Watermark tiredness`（:83-84）
  - 每 10 tick 结算生命：`step(...)`（:128-164），回血/饿伤直接作用在实体上
  - 从需求产生计划冲动：`urges()` → `eating()` / `sleeping()` → `new Urge(EAT, weight, ..., EatAction)`（:166-184）
  - 工作消耗接入事件：`LivingContent.exerted(WorkExertion)`（`LivingContent.java:75-80`）→ `LivingPresence.exerted`（:142-153）
  - **持久化**：整个 `LivingPresence` 存在 `colony.kept(LivingContent.ID)` 的 blob 里，用 `Reader/Writer` 手写读写（:95、:427-445）；工具类 `core/api/persist/Writer.java`、`Reader.java`
- `Hunger` 本身就是一个"居民生理状态"模型：`foodLevel/saturation/exhaustionLevel` + `stepVitals` + `save/load` — `plugins/person/living/Hunger.java:9-127`

**→ 口渴 = 把 `Hunger` 复制一份改字段名；体温 = 同构但读世界数据。两者都挂 `ColonyContext`，不需要碰 Cold Sweat。**

### 4.4 引擎里有没有现成的环境感知

**没有。** 全仓库 grep `isRaining|isThundering|thunder|getBiome().getTemperature|getTemperature` **零命中**（唯一的"train"类命中来自 Create 快递，无关）。全部环境读取只有三处：

| 读取 | 位置 | 用途 |
| --- | --- | --- |
| `getSkyDarken()` | `core/engine/travel/local/LocalGround.java:329-330`（透传 `watch.level()`）；`plugins/build/Sketch.java:105-106` | 光照/可视性 |
| `getDayTime()` | `plugins/person/PersonPresence.java:49` | 移民节奏（白天 tick 计数） |
| 群系（**透传但不用于温度**） | `LocalGround.java:333-341`（`getBiomeManager()`、`getUncachedNoiseBiome()`） | 因为 `LocalGround implements Ground, LevelReader`，群系/光照/方块状态**已经能从这里拿到**，只是没人算温度 |

**→ 世界侧最省事的挂点**：`LocalGround`（`core/engine/travel/local/LocalGround.java:48`）已经是"世界读取层"，fork 后在这里加"某格的环境温度/热度快照"，即可被寻路与规划同时消费。相关文件：`LocalWatch.java`、`Survey.java`、`Walker.java`、`core/api/ground/Ground.java`。

---

## 5. 三种路线对比与推荐

### 5.1 (A) 集成外部 mod 作为数据源，映射进居民需求系统

| 维度 | 判断 |
| --- | --- |
| 可行性 | **部分可行**：季节 100%（SS 有真实 API）、世界方块温度 ~80%（Cold Sweat 的 `BlockTempRegistry` / TAN 的 `getTemperatureAtPos`）、**实体温度 ~60%**（Cold Sweat 能开给 NPC，但后果要自写）、**口渴 0%**（两家都是 `Player` 专用） |
| 工作量 | 中偏大。桥接代码不多，但要做：可选依赖开关、单位换算、双份语义对齐（Cold Sweat 的 `Trait` vs 我们的需求）、每次它改版都要跟（`maven.modrinth`/Cursemaven 坐标、反射 hack 的兼容） |
| 风险 | **高**：GPL-3.0-or-later（若算链接则传染）、ARR（SS/TAN 不可打包不可拷贝）、TAN 停更 2024-10、SS 是 beta、Cold Sweat 用反射写 `CommonHooks.FORGE_ATTRIBUTES`（NeoForge 内部字段，随时可能变）、NPC 高温模式官方自认有性能问题 |
| 结论 | **不作为主路线**。作为"加了就更好"的传感器 |

### 5.2 (B) Fork 内原生自研季节/温度/口渴作为"世界数据层"

| 维度 | 判断 |
| --- | --- |
| 可行性 | **完全可行且可控**。季节就是 `dayTime` 的算术；温度是群系温度 + 海拔 + 遮蔽 + 方块热源 + 天气 + 活动的加权；口渴是 `Hunger` 的复制品。Folkways 已有 `ColonyContext` + `Hunger` + `Writer/Reader` 全套先例 |
| 工作量 | **季节点小**（1 个 per-level `SavedData` + 一张季节表 + 群系温度修正）；**温度点大**——难点不在模型而在**内容**：保温装备/温度计/冰火方块/衣物识别/热源方块标签，这些是 Cold Sweat 已经做好的几千小时内容 |
| 风险 | 低（技术）。主要是"内容量"与"数值调优"的长期投入；以及我们自研季节与 SS 同时装会打架（`docs/pack/01-modlist.md:92`） |
| 结论 | **居民侧状态必须走这条路**；世界侧内容建议不要全自研 |

### 5.3 (C) 混合 —— **推荐**

**分工原则**：**外部 mod 只提供"世界/方块影响"，居民侧状态与行为 100% 自研。**

- **自研（必需）**：
  1. `ColonyContext` 模块 `folkways:thermal`（体温）与 `folkways:thirst`（口渴），照 `LivingContent.declare`（`LivingContent.java:66-73`）；
  2. 每居民状态存在殖民地 keep blob 或新附件（fork 后建议把 `BodyState`/`FolkwaysAttachments.BODY_STATE` 提为 public 并加字段，见 §7）；
  3. 3 个 `Urge`：DRINK / WARM（去热源、回屋）/ COOL（去阴凉、水边、冰）；
  4. 行为后果用 `MOVEMENT_SPEED` 属性 modifier（照 `ResidentEntity.java:288-296`）+ 工作速率惩罚，**不**改 `BodyRunner` 契约；
  5. 世界温度 = 群系温度 + 海拔 + 遮蔽 + 方块热源（数据包标签）+ 天气 + 活动产热。
- **可选桥接（有更好，没有也能跑）**：
  - 季节：自研 per-level 季节表；若 `ModList.get().isLoaded("sereneseasons")`，改读 `SeasonHelper.getSeasonState(level)`（compileOnly + 反射/独立桥接类，**不打包**它的 jar）。夏季/冬季再叠加我们的温度修正。
  - 温度传感器：若 `ModList.get().isLoaded("cold_sweat")`，订阅 `EnableTemperatureEvent` 给 `folkways:resident` 打开，然后把 `Temperature.get(entity, Trait.WORLD)` 作为我们体温模型的**一个输入项**，并把我们的体温结果通过 `Temperature.add`/`addModifier` 回写（这样玩家的温度计/护甲/热源都仍然生效）。
  - 方块热源/装备保温：若 Cold Sweat 在，直接复用它的 `BlockTempRegistry`/`InsulatorData`（省掉几千小时内容）。
- **工作量**：自研骨架约"再做一个 `LivingPresence`"（+2 个状态类 + 3 个 Urge + 1 个世界温度服务）；桥接每个 mod 1~2 天量级；调优是长期项。
- **风险**：可控。所有外部依赖都收敛到"可选桥接类"里，无外部 mod 时降级为自研季节 + 自研方块热源标签。

### 5.4 直接回答："用 Serene Seasons + Cold Sweat 能不能整合到小人身上"

**有条件能（数据能，行为不能自动）。** 五个条件：

1. **实体必须在 Cold Sweat 打开**：`EnableTemperatureEvent.setEnabled(true)`（[A] `AddTempAttributes.java:85-89`）。**这条要写 Java**（KubeJS 不能监听 NeoForge 事件）；或退而求其次：config `Enable Entity Climates = true` + 把 `folkways:resident` 写进 Entity Climate 名单（基础模式，tickRate 200，只判存活）。
2. **Cold Sweat 必须在运行期存在**：否则 `Temperature.get` 恒返回 `0.0`（[A] `Temperature.java:85-87`：`orElse(0.0)`），必须有降级路径。
3. **Serene Seasons 不影响实体，只影响 `Biome.getTemperature`**；Cold Sweat 读季节靠它的 `SereneSeasonsTempModifier`（[A] `.../api/temperature/modifier/compat/SereneSeasonsTempModifier.java:26-28`，且自己判 `whitelistedDimensions`）。所以 SS 装不装只改**数值来源**，不改结构。
4. **许可约束**：SS 是 ARR → 只能 compileOnly + 运行期可选、不可打包、不可拷贝代码；`SeasonChangedEvent` 走 GlitchCore 总线 → 建议直接轮询 `SeasonHelper`。
5. **行为必须我们写**：Cold Sweat 的内置实体温度效果只有 `DecreaseDrops` / `PreventBreeding`（[A]），"太热就不干活 / 去喝水 / 回屋取暖"要在 Folkways 的 `Urge` 里实现。

> 一句话：**SS + CS 可以当"传感器"，不能当"大脑"。** 挂在居民身上的**数据**没问题，**决策**在我们手里。

### 5.5 已识别的具体技术风险

1. Cold Sweat 用**反射**写 `CommonHooks.FORGE_ATTRIBUTES`（`AddTempAttributes.java:48-58`）——NeoForge 内部字段，升级即可能炸。
2. `TEMPERATURE_ENABLED_ENTITIES` **只在 `ServerConfigsLoadedEvent` 填充一次**（`AddTempAttributes.java:70-89`）→ 监听注册必须早于该事件；运行中动态开启实体**未验证**。
3. Cold Sweat 的实体附件工厂对未启用实体**返回 `null`**（`ModDataAttachments.java:29-34`）→ 必须先 enable 再取，顺序错会拿不到 cap。
4. 居民数量 × 高级实体温度可能踩性能（官方自述，`EntitySettingsConfig.java:123-128`）→ 必须 bench（已有 `docs/pack/03-performance-budget.md`）。
5. 若我们自研季节又与 SS 同装：两套季节会打架（`docs/pack/01-modlist.md:92` 已标）→ 要么不装 SS，要么把 SS 设为唯一季节源。

---

## 6. 未验证清单与人工补核项

| # | 事项 | 为什么重要 | 建议动作 |
| --- | --- | --- | --- |
| 1 | Cold Sweat README 声称的"关于衍生作品与使用 API 的许可修订"具体条款 | 决定"链接它是否传染 GPL"、能否 fork | 1.21-FG 的 LICENSE 文件（2064 B）里**没有**这些条款；去 CurseForge 页面/仓库其他分支读，或直接问作者 |
| 2 | Cold Sweat 是否有公开 maven 坐标 | 决定依赖写法 | `build.gradle:189-199` 只 publish 到本地 `file://repo`；需验证 `maven.modrinth:cold-sweat:<ver>` 或 Cursemaven 可用 |
| 3 | `EntityClimateBuilderJS` 是否真写 `ConfigSettings.ENTITY_CLIMATES` | 决定"纯 KubeJS 能否给 NPC 开温度" | 读 `compat/kubejs/event/builder/EntityClimateBuilderJS.java` 全量源码后实测 |
| 4 | 运行中（`ServerConfigsLoadedEvent` 之后）能否再 enable 新实体 | 决定是否必须静态注册 | 实测：在 server started 后 post `EnableTemperatureEvent` |
| 5 | Serene Seasons `10.1.0.9` 与仓库 `1.21.1` 分支是否严格同源 | 源码 ≠ 发布版时结论会偏 | 我只做了"分支源码 + 发布 jar 的 api 包 javap"交叉验证，未逐类 diff |
| 6 | Serene Seasons / Tough As Nails 的 CF 页面 modpack 许可 | 决定整合包能否列它们 | `docs/pack/01-modlist.md:267` 已标"中风险，必须逐个确认" |
| 7 | Cold Sweat NPC 温度的真实性能开销（几十~上百居民） | 决定高级/基础模式选择 | 用现有 bench profile（`blockwright.toml`）实测 |
| 8 | Folkways `Ground` 接口能否承载"温度快照"而不破契约 | 决定世界层的实现位置 | 读 `core/api/ground/Ground.java` 全量 + `LocalWatch`/`Survey` 调用点 |
| 9 | Thirst Was Taken 与 Cold Sweat 的这类"玩家向"mod 是否值得为**玩家**保留 | 玩家体验 vs 居民模拟 | 设计裁决（属于 PRD 范畴） |

---

## 7. 对设计的直接结论（每条可执行）

1. **宿主自研，外部只做传感器**：温度/口渴的**状态与行为**放在 fork 后的 Folkways 内，用 `Declaring.colony` + `ColonyContext` 声明新模块（照 `plugins/person/living/LivingContent.java:66-73`）。**不要**把状态挂在 Cold Sweat/TAN/TWT 上。
2. **fork 后第一批改动**：把 `FolkwaysAttachments.BODY_STATE`（`FolkwaysAttachments.java:29`）与 `BodyState`（`BodyState.java:14`）提为 `public`，并在 `BodyState.serializeNBT`（:68-77）加 `Thermal` / `Thirst` 段；或注册新附件 `folkways:body_thermals`（NeoForge `AttachmentType.serializable`，与 `FolkwaysAttachments.java:24-46` 同法）。这样体温/口渴随实体存 NBT，不依赖殖民地 blob。
3. **殖民地级模块**：新增 `plugins/person/climate/`（或独立插件）两个 `ColonyContext`：`thermal`、`thirst`。直接复制 `LivingPresence` 骨架：`Watermark` 阈值门 + `Map<UUID, X>` 每人状态 + `tick()` 结算 + `urges()` 产出 `Urge` + `closed()` 清理（`LivingPresence.java:81-88, 113-184`）。
4. **只加 3 个行为冲动**：`folkways:drink`、`folkways:warm`（去热源/回屋）、`folkways:cool`（去阴凉/水/冰），权重复用 `Urge.NOW` / `Urge.SPARE` 的两档（`LivingPresence.java:180-183`）。
5. **行为后果走属性**：太冷/太热 → `MOVEMENT_SPEED` 的 transient modifier + 工作速率乘子。**照抄** `ResidentEntity.refreshPerkEffects`（`ResidentEntity.java:276-297`，含"先 remove 再 add、用固定 ResourceLocation"的正确姿势）。**不要**改 `BodyRunner.setOut`（`BodyRunner.java:518-526`）的速度契约，避免与调度/预测耦合。
6. **世界数据层**：新增 per-level `SavedData` 存季节进度（照 Serene Seasons 的 `SeasonSavedData` 形状），用 `level.getDayTime()` 推进（参考 `PersonPresence.java:49`）；温度用 `LocalGround implements LevelReader` 已暴露的 `getBiomeManager()`（`LocalGround.java:333-341`）读 `Biome.getBaseTemperature`，再加海拔/遮蔽/方块热源标签。
7. **可选桥接做成三个独立、可整体删除的类**（每个都用 `ModList.get().isLoaded(...)` 门控 + 独立 try/catch 降级）：
   - `ColdSweatBridge`：订阅 `EnableTemperatureEvent` 开 `folkways:resident`；读 `Temperature.get(entity, Trait.WORLD)`；把我们的结果用 `Temperature.add(entity, Trait.BASE, delta)` 回写。
   - `SereneSeasonsBridge`：只调 `SeasonHelper.getSeasonState(level)` → 我们的季节枚举；不要订阅 GlitchCore 事件。
   - `ToughAsNailsBridge`（可选）：只用 `TemperatureHelper.getTemperatureAtPos(Level, BlockPos)` 当世界温度参考；**不要**试图用它做居民状态。
8. **许可纪律（写进构建脚本）**：
   - Cold Sweat：按 **GPL-3.0-or-later** 处理；只在 `ColdSweatBridge` 里引用；准备"不带它编译"的 profile；**不 fork 它**。
   - Serene Seasons / Tough As Nails：**ARR** → 仅 `compileOnly`，禁止拷贝代码/资源，禁止打包分发，必须能无它运行。
   - Thirst Was Taken：MIT（可安全依赖），但对 NPC 无用，只当**玩家侧**口渴系统使用（并注意它和 Cold Sweat 的 compat 关系）。
9. **数值不要另造单位**：直接沿用原版 `Biome.getBaseTemperature` 与 Cold Sweat 的 `Trait` 语义（`WORLD` = 环境体感，`BASE` = 自身体温，`FREEZING_POINT`/`BURNING_POINT` = 阈值），玩家装 Cold Sweat 时数字才对得上它的温度计。
10. **设计裁决点（交给设计负责人）**：是否同时装 Serene Seasons。若装 → 它必须是**唯一**季节源（我们只读不算）；若不装 → 我们自研季节表。二选一，不要并存（`docs/pack/01-modlist.md:92` 已警告两套季节打架）。