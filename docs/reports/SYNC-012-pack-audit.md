# SYNC-012 · 整合包内容审计：桥接配方有效，配置已过时（已刷新）

```
状态：通过（内容侧）；安装与客户端仍未测
验证者：DSH 会话
验证日期：2026-11-06
关联：SYNC-010/011、pack §12、D11
```

---

## 1. 结论

十模块进来之后，`pack/` 里有两样东西**需要复核**：KubeJS 桥接配方、三份服务端配置。

| 项 | 结论 |
| --- | --- |
| KubeJS 桥接的两个 id | ✅ **在真实 jar 里都存在** |
| 新增的重叠 | ⚠️ 包里现在有**三条面粉链**（Create / Farmer's Delight / Kaleidoscope Cookery），我们只桥接了前两条 |
| 三份服务端配置 | ❌ **是 4 模块时代的旧文件**（含已不存在的键）→ ✅ **已用 10 模块服务端生成的新文件替换** |

---

## 2. KubeJS 桥接：id 有效

`pack/kubejs/server_scripts/plaa_bridges.js` 把 Create 的面粉接到 FD 的面团。用**下载下来的真实 jar** 核对：

| id | 证据（jar 内路径） |
| --- | --- |
| `create:wheat_flour` | `assets/create/models/item/wheat_flour.json`、`data/create/recipe/splashing/wheat_flour.json` |
| `farmersdelight:wheat_dough` | `assets/farmersdelight/models/item/wheat_dough.json`、`data/farmersdelight/recipe/wheat_dough_from_water.json` |

**所以桥接不是猜的**，两个 id 都真实存在。

---

## 3. 新问题：三条面粉链（未改，留待你定）

Kaleidoscope Cookery 自带一套：`kaleidoscope_cookery:flour`、`raw_dough`（还有 `chopping_board/raw_dough` 模型）。

于是包里现在有：

| 链 | 来源 |
| --- | --- |
| Create 磨粉 → FD 面团 | 我们的桥接配方 |
| Cookery 自己的面粉 → 面团 | Cookery 自带 |
| 原版小麦 → FD 面团 | FD 自带 |

**它们不冲突**（都能存在），但玩家会看到**重复配方**。要不要把 Cookery 也桥进来，取决于该 mod 的平衡设计——**我不替你决定**，已记作待定项。

---

## 4. 配置陈旧：真的错，已修

审计发现（`pack/config/` 里三份文件来自 0.1.0 的 4 模块构建）：

| 文件 | 旧 | 新（来自 10 模块服务端生成） |
| --- | --- | --- |
| `plaa_core-server.toml` | 11 键，含 **`travelFloorMicros`（代码里已不存在）** | **9 键**（旧键消失） |
| `plaa_vanilla-server.toml` | 21 键（代码定义 35，其余靠默认） | **41 键**（完整） |
| `plaa_create-server.toml` | 4 键 | 4 键 |
| `plaa_chiselsandbits-server.toml` | 不存在 | **新增 6 键** |

**做法**：用 10 模块服务端启动时 NeoForge **自动生成**的那份覆盖（`srv-port/config/plaa_*-server.toml`）——那是"当前代码认为的正确默认值"，不是手写猜的。

> 为什么不能手改：那份文件里还有 `haulingHaste`（代码里只是**方法名**，不是配置键），
> 手工判断哪个键还活着，比让程序生成一份更危险。

---

## 5. 产物同步

| 项 | 结果 |
| --- | --- |
| `pack/index.toml` | 重算（**69 个文件**） |
| `pack/pack.toml` | index 哈希同步 |
| `.mrpack` | 重打：**62 下载 + 6 随包**（4 配置 + 任务书 + KubeJS） |
| release 资产 | **已替换**（15,735 字节）——请知悉：这是**改动已发布资产**，不是新版本号 |

---

## 6. 没验的

- **客户端安装与进游戏**仍未做（D11）；
- 桥接配方在游戏里是否真的生效，只有 KubeJS 加载后才能确认（属 D11 一并验）；
- 三条面粉链要不要合并成一条：待你定。
