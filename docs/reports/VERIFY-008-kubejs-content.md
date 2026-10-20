# VERIFY-008 · 包内 KubeJS 内容管线（并修复 mrpack 打包器漏带 overrides 的 bug）

```
状态：通过
验证者：DSH 会话
验证日期：2026-10-20
关联：VERIFY-004/005（打包与安装链）；k02 §5（KubeJS 边界）
```

---

## 1. 结论

整合包现在有**第一条真实内容**：`pack/kubejs/server_scripts/plaa_bridges.js`。全新实例安装后，KubeJS 报告 **1/1 脚本加载、0 错误 0 警告**，配方管理器 **Added 1 recipes / 0 failed**，服务端 `Done (11.099s)`。

同时修掉一个**打包器 bug**：`tools/pack-mrpack.ps1` 原来只把 `mods/*.jar` 放进 `overrides/`，**`config/` 与 `kubejs/` 会被 .mrpack 丢掉**（此前一直用 packwiz-installer 测试，所以没暴露）。现在所有非元数据文件都会进 overrides。

---

## 2. 内容：这条脚本做什么

```js
ServerEvents.recipes(event => {
  // Create 面粉 -> 农夫乐事面团（对应 FD 自己的 小麦 + 水桶 配方）
  event.shapeless(Item.of('farmersdelight:wheat_dough', 2),
    ['create:wheat_flour', 'minecraft:water_bucket'])
})
```

**为什么是这条**：殖民地如果只建了 Create 的磨粉线，就吃不到农夫乐事的面团链；反过来也一样。这是"两套食物产线互通"的最小桥。水桶靠原版 crafting remainder 自动留下，不消耗水。

**第一版写错的地方（已修，留作教训）**：
- 以为农夫乐事有 `farmersdelight:wheat_flour` → **它没有**（只有 `wheat_dough`）。日志：`Failed to read item stack from farmersdelight:wheat_flour: Item with ID ... not found`。
- 用了 `c:flour` 标签 → Create 的标签其实是 **`c:flours`**。

**教训**：写 KubeJS 前必须先在有 mod 的实例里核对 id；`Item.of('不存在的 id')` 只在**运行时**报错，编写时看不出来。

---

## 3. 证据

| 项 | 输出 |
| --- | --- |
| 脚本加载 | `Loaded script server_scripts:plaa_bridges.js in 0.01 s`<br>`Loaded 1/1 KubeJS server scripts in 0.071 s with 0 errors and 0 warnings` |
| 配方注入 | `Added 1 recipes, removed 0 recipes, modified 0 recipes, with 0 failed recipes` |
| 安装链 | `installer exit=0`，46 个服务端 mod，`Done (11.099s)!` |
| 打包 | `45 个下载条目 + 8 个随包（4 jar + 3 config + 1 js）`，mrpack 内 `files=53`、overrides 8 条 |

---

## 4. 打包器修复（`tools/pack-mrpack.ps1`）

**旧行为**：只遍历 `mods/*.pw.toml`（下载条目）+ `mods/*.jar`（随包）。
**新行为**：`mods/*.jar` + **`pack/` 下所有非元数据文件**（`config/`、`kubejs/`、`resourcepacks/`、未来的 `options.txt` 等）都进 `overrides/`，路径保持相对结构，`downloads = []`、哈希现算。

验证：`files = 53`（45 下载 + 8 随包），zip 内 `overrides/` 8 条，且 `kubejs/server_scripts/plaa_bridges.js` 在列。

---

## 5. 未验证 / 遗留

| # | 项 | 何时补 |
| --- | --- | --- |
| 1 | 客户端是否吃到同一条配方（服务端已验证） | 下次客户端启动看 KubeJS 客户端日志 |
| 2 | 第三方告警：`storagedrawers:personal_key_cofh … Failed to parse recipe @ [ingredients][1]`（KubeJS 警告并回退，非我们脚本） | 观察，必要时向 Storagedrawers 反馈 |
| 3 | `pack/quests/` 仍为空（FTB Quests 能跑但无任务） | 下一轮：第一章 8 条任务 |
| 4 | `pack/kubejs/startup_scripts/` 只有 KubeJS 自带的 `main.js` 示例 | 需要时再写（自定义物品要配模型，别引入新的缺模型告警） |
