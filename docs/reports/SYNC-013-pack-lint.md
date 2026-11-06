# SYNC-013 · `pack-lint`：把重复劳动变成检查

```
状态：通过（68 文件 / 62 个 .pw.toml 全绿）
验证者：DSH 会话
验证日期：2026-11-06
关联：SYNC-010/012、D14（文档/包门禁）
产物：tools/pack-lint.ps1
```

---

## 1. 为什么写它

这个会话里，**同一个问题手工修了两次**：`index.toml` 出现 CRLF → 哈希失效 → `pack.toml` 的索引哈希跟着失效。

> 人记住的事会忘，脚本不会。

---

## 2. 检查什么

| # | 检查 | 失败意味着 |
| --- | --- | --- |
| 1 | `pack/` 每个文件的 sha256 与 `index.toml` 记录一致 | 包内容漂移 |
| 2 | `index.toml` 不多不少（无孤儿条目、无未登记文件） | 索引与磁盘不同步 |
| 3 | `pack.toml` 的 `[index] hash` 等于 `index.toml` 实际哈希 | packwiz 会拒绝加载 |
| 4 | 文本文件**无 CRLF** | Windows 编辑器/脚本会悄悄引入 |
| 5 | 每个 `.pw.toml` 有 `name` / `filename` / `side` 与 `[download]`（url + hash-format + hash） | 条目无法安装 |

只读、不改文件；有问题时**非零退出**（可以直接进 CI）。

---

## 3. 它第一次运行就抓到一个真错误

```
哈希不符: pack.toml
```

原因不是"忘了更新"，而是**结构成环**：

- `index.toml` 记录了 `pack.toml` 的哈希；
- `pack.toml` 又记录 `index.toml` 的哈希。

**两者不可能同时自洽**——改任何一个都会让另一个失效，形成死循环。

**修法**：`index.toml` 排除 `pack.toml`（packwiz 的语义也是如此：pack.toml 是工程元数据，不是被索引的内容）。

| 项 | 之前 | 之后 |
| --- | --- | --- |
| `index.toml` 条目 | 69（含 pack.toml） | **68**（不含） |
| lint | ❌ 哈希不符 | ✅ 全部通过 |

---

## 4. 现在的结果

```
index.toml 记录: 68 个文件
哈希核对: 68 个文件 · .pw.toml: 62 个
pack-lint: 全部通过
```

---

## 5. 用法与后续

```powershell
pwsh -File tools/pack-lint.ps1      # 退出码 0 = 自洽
```

**建议接进 CI**（D14 的一部分）：docs 仓库目前没有 Actions，等能跑时把这条与断链检查一起挂上。

---

## 6. 没变的事

- 发布资产（`v0.2.0` 的 `.mrpack`）**未受影响**：mrpack 不包含 `index.toml` / `pack.toml`，本轮只改了这两个文件的内部一致性；
- **D11（客户端实测）依旧开放**——lint 管的是"包自洽"，管不了"游戏能跑"。
