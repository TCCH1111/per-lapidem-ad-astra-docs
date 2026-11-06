# SYNC-015 · fork 的 CI 一直是红的，原因是被漏掉的第五个改名面

```
状态：修复完成（本地 42/42；CI 运行 #49 结果见 §5）
验证者：DSH 会话
验证日期：2026-11-06
关联：ADR-026（改名规则）、VERIFY-047/048、D14、D15
```

---

## 1. 一开始以为"fork 没有 CI"

上一轮接 docs CI 时，我以为代码侧要新写 workflow。查 API 才发现：

> **fork 早就有 CI**（上游带来的 `build.yml`），而且**最近 50 次一直在跑**。

问题是：**移植之后每一次都失败**。

| 运行 | 提交 | 结果 |
| --- | --- | --- |
| #44 | `c456385`（旧 4 模块） | ✅ |
| #45–#48 | `64e35ad` / `5fd2892` / `3ea0f6b` | ❌ **全部失败** |

我们本地一直绿，是因为**从没看过远端 CI**。

---

## 2. 失败面很窄

运行 #48 的作业矩阵：

| 作业 | 结果 |
| --- | --- |
| build | ✅ |
| Client smoke (founding) | ✅ |
| GameTests：core / vanilla / create / cookery / rts / warfare / tacz / firefighting | ✅ **8 个全绿** |
| **GameTests (chiselsandbits)** | ❌ |

日志里两个用例失败：

```
LogTestReporter: rotundadrawsbitsandturns failed at ...! No value present
LogTestReporter: toriidrawsbitsandturns failed at ...! No value present
2 required tests failed :(
```

`No value present` 来自 `Patterns.find(id).orElseThrow()` —— **图案没加载**。

---

## 3. 真正的原因：第五个改名面

ADR-026 的规则列了**四个**改名面：gradle `ext`、`mods.toml`、Java 字符串、`blockwright.toml`。

**漏了第五个**：数据包资源路径 `data/<namespace>/folkways/<shelf>/` 里的 `<namespace>` **就是 modid**。

```
实际：  data/folkways_chiselsandbits/folkways/pattern/torii.star   →  id = folkways_chiselsandbits:torii
测试要：                                  plaa_chiselsandbits:torii   →  找不到
```

更有意思的是**测试自身不一致**：有的地方已经被改名脚本改成 `plaa_chiselsandbits`，有的还是旧名
（改名脚本只替换了完整的 `"folkways_chiselsandbits"` 字面量，`"folkways_chiselsandbits:pavilion"` 这种带冒号的没命中）。

---

## 4. 修法与本地验证

| 步骤 | 内容 |
| --- | --- |
| 1 | `git mv data/folkways_chiselsandbits data/plaa_chiselsandbits` |
| 2 | 6 个测试文件里 8 处 `folkways_chiselsandbits:` → `plaa_chiselsandbits:` |
| 3 | 残留检查：`grep folkways_chiselsandbits` = **0** |
| 4 | Linux 上跑该 profile：**42 / 42 通过**（`-PchiselsTests=true`） |

**为什么本地 1482 条从没发现**：这 42 个用例由 `-PchiselsTests=true` 开关控制，**默认套件不跑**。
它们只会在 CI 的 `chiselsandbits` profile 里出现——**这正是 CI 存在的理由**。

---

## 5. CI 验证

```
提交 1a20c4d → Build #49 → completed/success
```

**11 个作业全部成功**：

| 作业 | 结果 |
| --- | --- |
| build（含 unit / typecheck / 产物上传） | ✅ |
| Client smoke (founding) | ✅ |
| GameTests：core / vanilla / create / cookery / rts / warfare / tacz / firefighting | ✅ |
| **GameTests (chiselsandbits)** | ✅ **（修复前为 ❌）** |
| nightly | ✅ |

这是移植之后**第一次全绿**。

---

## 6. 需要写回规则的两处

| 位置 | 补什么 |
| --- | --- |
| **ADR-026 / d12 §13** | 改名面从四个变成**五个**：加上 `data/<modid>/` 目录 |
| 改名脚本 | 除了整词 `folkways_x`，还要替换 `folkways_x:` 前缀形式 |

---

## 7. 这轮最该记住的

> 我们本地"全绿"了四轮，而远端 CI 红了四轮。
> **本地通过不等于仓库通过**——尤其当某些测试默认不运行时。
