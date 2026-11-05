# SYNC-003 · 移植第一阶段：改动已落到 aaac8b8，剩 8 个冲突

```
状态：进行中（检查点已推送到 origin/port/aaac8b8）
验证者：DSH 会话
验证日期：2026-11-05
关联：SYNC-002（预检）、VERIFY-047（改名）、D15
main：c456385（四件套全绿，未受影响）
移植分支：port/aaac8b8 → 8c6820a（**尚不能构建**）
```

---

## 1. 一句话结论

我们的改动已经**落到上游 aaac8b8 上**：48 个新增文件全数就位、24 个修改文件三方合并干净、4 个语言文件用并集解开。**还剩 8 个冲突**，其中 2 个是代码（`Labor.java`、`BuiltinPlugins.java`），6 个是配置与文档。

---

## 2. 做法（可复现）

```bash
git worktree add -f --detach ~/pla/port refs/remotes/upstream/master
cd ~/pla/port && git switch -c port/aaac8b8
cp .blockwright/mods.json ~/pla/port/.blockwright/    # 构建必需（gitignore）

# 逐文件：A 类直接复制；M 类 git apply --3way
git -C ~/pla/mod diff --name-status 3ce4d88 HEAD | while read -r status path; do ... done
```

---

## 3. 第一阶段结果

| 类别 | 数量 | 状态 |
| --- | --- | --- |
| 新增文件（我们新建的类与测试） | **48** | ✅ 全数复制，**零路径冲突** |
| 修改文件 · 三方合并干净 | **24** | ✅ |
| 修改文件 · 冲突 | **12** | 4 已解（语言）· **8 待解** |
| 修改文件 · 上游已删除 | **1** | ⬜ `Solving.java` 需重定位 |
| 其它失败 | 0 | — |

### 3.1 已解开的 4 个：语言文件（并集）

上游在同一位置追加了 cookery / combat 等一大段键，我们的 fork 也追加了 steering / hours / explain / mood 的键。解法是**保留两边**（上游块尾补逗号）：

```python
# 冲突块 ours=上游 theirs=我们 → 依次拼接，末尾补逗号
out.extend(ours); out.extend(theirs)
json.loads(text)   # 每个文件都重新解析验证
```

四个文件（`en_us` / `zh_cn` / `zh_hk` / `zh_tw`）均 **JSON 校验通过**，键数从 1312+166 合并为 1478 行。

### 3.2 待解的 8 个

| 文件 | 性质 | 备注 |
| --- | --- | --- |
| `blockwright.toml`（2 块） | **modid 命名** | 上游 `folkways_core` vs 我们 `plaa_core` |
| `build.gradle`（1） | 构建配置 | 同上 |
| `META-INF/neoforge.mods.toml`（1） | mod 元数据 | 同上 |
| `.github/workflows/build.yml`（2） | CI | 我们的节流/分支名 vs 上游流程 |
| `CONTRIBUTING.md`（1） | 文档 | 我们的 fork 说明 vs 上游新版 |
| `README.md`（1） | 文档 | 同上（上游新增大量可选集成） |
| **`Labor.java`（1）** | **代码 · 我们的 L3** | 否决权接入 labor service |
| **`BuiltinPlugins.java`（1）** | **代码 · 我们的注册** | steering / hours / mood 注册 |

---

## 4. 关键数据：命名成本很小

| 项 | 数 |
| --- | --- |
| 我们树里 `plaa_` 出现的文件 | **18** |
| 上游树里 `plaa_` 出现的文件 | **0** |
| 改名来源提交 | `7344f9d feat(b2): rename modids to plaa_*` |

**结论**：坚持 `plaa_*` 的代价是**每次移植改 18 个文件**（本次冲突里的 3 个配置就是它们）。这个成本可接受，因此**不推翻 ADR-023**。

另外：上游新增的 `cookery / combat / wares / farming …` 都是 **`mods/vanilla` 里的包**，不是独立模块——它们会随移植**自然带过来**，不需要我们额外工作。这是本轮最省心的发现。

---

## 5. 诚实边界

- 该分支**目前不能构建**：8 个冲突未解，`Solving.java` 未重定位；
- **`main` 未受影响**：仍在 `c456385`，四件套全绿；
- 移植分支已推送（`origin/port/aaac8b8`），进度不会丢。

---

## 6. 下一步（按顺序）

1. **配置 3 件套**（`blockwright.toml` / `build.gradle` / `mods.toml`）：保留上游结构 + 改回 `plaa_*`；
2. **CI 与两份文档**：取上游新版为底、补我们的 fork 说明；
3. **`Labor.java`**：把否决权接入上游重构后的 labor service（语义冲突，最需要小心）；
4. **`BuiltinPlugins.java`**：注册 steering / hours / mood 三个插件；
5. **`Solving.java`**：找上游等价位置重新安置测试夹具改动；
6. 构建 → 四件套 → 目标 714 全过 → 再决定 `main` 如何前进。
