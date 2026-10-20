# VERIFY-009 · 任务书第一章（FTB Quests 数据手写并验证零解析错误）

```
状态：通过（服务端解析 0 错误；客户端未点开书）
验证者：DSH 会话
验证日期：2026-10-20
关联：k04（任务书与剧情引导）、ROADMAP 队列 ①
```

---

## 1. 结论

`pack/config/ftbquests/quests/chapters/plaa_chapter_1.snbt` 上线：**1 章 / 8 条任务**，安装器端到端后服务端报告

```
[FTB Quests/]: Loading quests from …/config/ftbquests/quests
[FTB Quests/]: loaded translation tables for 1 language(s)
[FTB Quests/]: Loaded 1 chapter groups, 1 chapters, 8 quests, 0 reward tables
```

归一化后的章节文件里 **`missing_item` 出现 0 次**、`checkmark` 2 个、`item` 6 个——即没有任何"不可完成"的任务。

---

## 2. 章节内容（k04 的"第一章 · 落脚"）

| # | 任务 | 类型 | 判据 |
| --- | --- | --- | --- |
| 1 | 砍够 16 个原木（任意木头） | **checkmark** | 玩家自证（tag 任务在本版本不可用，见 §4） |
| 2 | 工作台 | item | `minecraft:crafting_table` ×1 |
| 3 | 四个箱子 | item | `minecraft:chest` ×4 |
| 4 | 铺好第一张床（任意颜色） | **checkmark** | 玩家自证 |
| 5 | 16 个火把 | item | `minecraft:torch` ×16 |
| 6 | 8 个小麦种子 | item | `minecraft:wheat_seeds` ×8 |
| 7 | 4 个面包（第一批存粮） | item | `minecraft:bread` ×4 |
| 8 | 拿到殖民书 | item | `folkways:colony_book` ×1 |

任务链为单线依赖（1→2→…→8），坐标 `(0, 0…10.5)`，章图标 `minecraft:oak_sapling`。

---

## 3. 关键机制（这轮学到的 FTB 事实）

1. **文本会被外置**：首次加载后，`title`/`description` 从章节文件移到 `config/ftbquests/quests/lang/en_us.snbt`，章节文件里 `title` 计数变成 0。**这正常**，不代表文本丢了。
2. **FTB 会自动补齐结构**：我们只放了 chapter 文件，它自己生成了 `chapter_groups.snbt`、`data.snbt`、`lang/en_us.snbt`。
3. **任务 id 是 16 位十六进制字符串**（`3F1A000000000101` 这类），依赖用同一串引用。
4. **`item` 任务用扁平字符串**：`item: "minecraft:crafting_table"` 可用；写成对象（`item: { id: … }`）会变成 `missing_item`。

---

## 4. 踩坑：`#tag` 任务在这个版本不可用

为做"任意木头/任意床"，我先试了三种 tag 写法，一次安装同时验证：

| 写法 | 归一化结果 |
| --- | --- |
| `item: "#minecraft:logs"` | `ftbquests:missing_item`（component 保留 `#minecraft:logs`） |
| `item: { tag: "minecraft:logs", count: 1 }` | `ftbquests:missing_item`（空 component） |
| `item: { id: "#minecraft:logs", count: 1 }` | `ftbquests:missing_item`（空 component） |
| `item: { item: "minecraft:oak_log", count: 1 }` | `ftbquests:missing_item`（空 component） |

**结论**：FTB Quests **2101.1.36** 的 item 任务只接受具体物品 id；要"任意同类物"，用 **`CheckmarkTask`**（玩家自证），这也是本版里最稳的做法。

---

## 5. 产物

- `pack/` 受管文件 **54**（45 下载 + 9 随包：4 jar + 3 config + 1 KubeJS + 1 任务章节）
- `.mrpack` 同步为 **54 条目**，`config/ftbquests/quests/chapters/plaa_chapter_1.snbt` 在 overrides 内
- 服务端冒烟：`installer exit=0`、`Done (10.915s)`

---

## 6. 未验证 / 遗留

| # | 项 | 何时补 |
| --- | --- | --- |
| 1 | **客户端能否翻开书看到这 8 条**（服务端已解析，客户端 UI 未点） | 下次客户端实测（可顺带截图） |
| 2 | 任务奖励（`rewards`）全部为空——目前只做引导，不给奖励 | 内容阶段按 k04 设计补 |
| 3 | 章节标题/描述在 `lang/en_us.snbt` 里只有英文源；中文需补 `zh_cn`（FTB 支持多语言表） | 双语内容阶段 |
| 4 | 任务书入口：玩家如何拿到 `folkways:colony_book`（模组自带获取方式未核） | 与上游行为核对后写进任务描述 |
