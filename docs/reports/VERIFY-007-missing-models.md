# VERIFY-007 · 41 条缺模型告警的根因定位与修复尝试

```
状态：根因已定位；修复方案均受限，待人类裁决（保留 / 移除 / 等上游修）
验证者：DSH 会话
验证日期：2026-10-20
关联：VERIFY-006（客户端实测）
```

---

## 1. 结论

那 41 条 `Unable to load model: 'minecraft:<名字>'` **全部来自 Born in Chaos**（`born_in_chaos_[Neoforge]_1.21.1_1.7.6.jar`，ARR）。根因是 mod 内部 **31 个 `models/custom/*.json` 写了自引用的裸 parent**（如 `"parent": "grudbone"`）——Minecraft 会把裸名字解析到 `minecraft:` 命名空间，于是去找不存在的 `minecraft:models/grudbone.json`，模型加载失败并级联到引用它的方块模型。

**修复尝试失败**：我们做了覆盖资源包（31 个去掉 parent 的模型 + `pack.mcmeta`），装进实例 `resourcepacks/` 并在 `options.txt` 启用；资源包确实进入了加载栈（日志可见 `file/plaa-bic-fix.zip`），但**告警数仍是 41**。原因是 NeoForge 的 `mod/born_in_chaos_v1` 在该栈中位于用户资源包**之后**（优先级更高），**mod 资源无法被用户资源包覆盖**。

---

## 2. 证据

| 项 | 证据 |
| --- | --- |
| 归属 | 在客户端 50 个 jar 中按 8 个物品名（nuthammer/skullbreaker/executionersgreatax/soulsaber/nightmarescythe/shellmace/spiderbite/pitchfork）检索，**全部命中同一个 jar**：Born in Chaos |
| 根因 | 扫描该 jar 的 `models/**`：**461 个模型用无命名空间 parent**（大多数合法，如 `block/cube`）；其中 **31 个是自引用裸名**（`custom/boncolerstaf.json → parent=boncolerstaf` 等） |
| 级联 | 告警 `referenced from` 的 12 个唯一值都是 `born_in_chaos_v1:block/*`（gnawed_bones / hound_trap / cobweb_cover / tombstone_* …） |
| 修复尝试 | 生成 `plaa-bic-fix.zip`（36.8 KB，31 个模型 + `pack.mcmeta`，`pack_format: 34`），实例 `resourcePacks:["vanilla","file/plaa-bic-fix.zip"]` |
| 失败证据 | 重载后日志：`Reloading ResourceManager: vanilla, KubeJS…, file/plaa-bic-fix.zip, …, mod_resources, mod/sodium, …, mod/born_in_chaos_v1, …`；告警仍 **41** 条（18:14:31 那一批） |

---

## 3. 可选处置（需要人类拍板）

| 方案 | 代价 | 效果 |
| --- | --- | --- |
| **A. 保留并记录**（当前状态） | 0 | 31 个装饰物/陷阱方块在客户端不可见；其余内容正常 |
| **B. 从包中移除 Born in Chaos** | 少一个威胁内容源（k01 曾把它列为"采用"） | 41 条告警消失，包更干净；威胁来源仍有 `mowzies-mobs` + 自研事件怪 |
| **C. 向作者反馈 / 等上游修** | 等 | 根治，但不在我们控制内 |
| **D. patch jar** | ❌ 不可选 | Born in Chaos 是 **ARR**，改包再分发违反许可 |

> 我的建议：**B 或 A**。若你重视"恐怖生物"这层氛围，选 A（只是几个陷阱/墓碑不可见）；若更在意"零告警、可维护"，选 B——反正威胁系统的主线是 PRD-004 的自研事件与势力，不依赖这个 mod。

---

## 4. 顺带学到的两条平台事实（已可复用）

1. **用户资源包改不了 mod 资源**：NeoForge 的 `mod/<id>` 包在资源栈中优先级高于 `resourcepacks/`（本次实测），所以"给第三方 mod 打美术补丁"不能靠随包资源包，只能改 jar（许可不允许时即无解）。
2. **KubeJS 的三个虚拟包**（Before Mods / Internal / After Mods）确实存在，但本次未验证能否压过 mod 资源；若将来需要"运行时改资源"，这是唯一还没试的口子（值得单独立项验证）。

---

## 5. 处置结果（2026-10-20，用户裁决：移除）

按方案 **B** 执行：从 pack/mods/ 删除 orninchaos.pw.toml（索引 53 → 52 个受管文件，.mrpack 重建为 45 下载 + 4 随包 = 49 条目），并从客户端实例删除该 jar。

**复验**（Prism 实例重载，49 个 mod）：

```
Unable to load model: 0
born_in_chaos 相关日志: 0
FATAL / ModLoadingException: 0
```

→ 41 条告警**全部消失**，且未引入新的加载错误。威胁内容仍由 mowzies-mobs 与 PRD-004 的自研事件/势力承担。
