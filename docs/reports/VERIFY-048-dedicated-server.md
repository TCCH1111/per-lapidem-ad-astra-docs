# VERIFY-048 · 十模块**打包后的 jar** 能在真实专用服务端启动

```
状态：通过
验证者：DSH 会话
验证日期：2026-11-05
关联：SYNC-007（1467/1467）、SYNC-008（测试包）、D15
验证对象：port/aaac8b8 @ 1ea1dac 的 10 个 plaa-*.jar
```

---

## 1. 为什么需要单独验这一步

`runGameTestServer` 跑的是**开发态 classes**，不是 jar。而这次移植改动过：

- `ext.modName`（决定 **jar 名**）
- `mods.toml` 的 modid 与依赖声明
- `chiselsandbits` 的 **jarjar 嵌套**（scena / api / core）

这些只在**打包后的 jar** 里才成立。所以必须用真实专用服务端验一次。

---

## 2. 做法

```bash
# 1) 复用已装好 NeoForge 21.1.264 的服务端骨架
cp -r .cache/test-server-b2/libraries ~/pla/srv-port/

# 2) 放入 10 个 plaa-*.jar + 必要集成（31 个 jar）
java @user_jvm_args.txt @libraries/net/neoforged/neoforge/21.1.264/unix_args.txt nogui
```

---

## 3. 结果

```
[22:20:35] [Server thread/INFO] [minecraft/DedicatedServer]: Done (4.511s)! For help, type "help"
FATAL 行数: 0
```

**十个 modid 全部出现在日志中**：

```
plaa_chiselsandbits  plaa_cookery  plaa_core  plaa_create  plaa_firefighting
plaa_modulargolems   plaa_rts      plaa_tacz  plaa_vanilla plaa_warfare
```

世界目录正常生成（`t4world`），配置目录（`config` / `defaultconfigs`）正常。

---

## 4. 16 条 ERROR 的分类（没有一条来自我们的代码）

| 日志 | 性质 |
| --- | --- |
| `Attempted to load class net/minecraft/client/... ClientLevel for invalid dist DEDICATED_SERVER` | 客户端专属类在服务端被触摸——NeoForge 的**标准噪音**，不影响启动 |
| `loot_table modulargolems:golem_guide - No component with type 'patchouli:book'` | Modular Golems 的可选 Patchouli 图鉴，本包没装 Patchouli |
| `Couldn't load tag carryon:block_blacklist` | Carry On 未安装，标签为空 |
| `Couldn't load tag kaleidoscope_cookery:cookery_mod_items` | 厨房物品标签引用缺失项 |
| `Curios API: feet is not a registered slot type!` | Curios 插槽类型未注册 |

**它们是"可选集成缺失"的正常提示**，与 modid 改名、与我们的插件都无关。

---

## 5. 两个踩到的坑（写下来省下次）

| 坑 | 说明 |
| --- | --- |
| `ldlib2` / `ponder` **不在夹具集里** | 它们是运行期依赖，由构建下载到 `build/deps/`；服务端必须从那里取，否则 `plaa_core` 报缺 |
| `chisels-and-bits-neoforge-*.jar` 的**命名** | 不是 `chiselsandbits-*`；按名字匹配会漏，漏了报 `plaa_chiselsandbits requires chiselsandbits 21.1.33` |

---

## 6. 证明了什么 / 没证明什么

| 已证 | 未证 |
| --- | --- |
| 打包后的 10 个 jar 能一起加载 | **客户端**（模组列表、界面、显卡） |
| 十个 modid 注册正确 | 殖民书圈地、开殖民地 |
| jarjar 嵌套（chiselsandbits）可用 | 禁区 / 作息 / 心情三处界面 |
| 真实服务端 `Done` 4.5s | `serverconfig/plaa_*-server.toml` 是否按新 modid 生成 |

**客户端仍需你的屏幕**（SYNC-008 的测试包）。
