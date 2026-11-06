# SYNC-009 · 移植落到 `main`（用户决定：跳过客户端实测）

```
状态：已执行（**未做客户端实测**，风险见 §5）
验证者：DSH 会话
验证日期：2026-11-06
关联：SYNC-002..008、ADR-026、D11/D15
决定：用户口头决定「跳过按 A 切」
```

---

## 1. 决定与执行

用户选择 **方案 A**：`main` 直接切到移植分支，**不做客户端实测**。

| 步骤 | 结果 |
| --- | --- |
| 旧 `main` 打标签 | **`pre-port-main-20261106`** → `c456385`（4 模块 / 714 测试时的最后状态） |
| `main` 重置到移植分支 | `64e35ad`（10 模块 / 1479 测试） |
| 推送 | `--force-with-lease`：`c456385...64e35ad main -> main`（历史被替换是**预期**的，上游重写过历史，两者无共同祖先） |
| 远端确认 | `refs/heads/main = 64e35ad…`、`refs/tags/pre-port-main-20261106 = b6f7315…` |
| 清理 | 移除 `port` 与 `upstream-clean` 工作树；分支 `port/aaac8b8` 保留（与 main 同点） |

**旧历史没有丢失**：`git checkout pre-port-main-20261106` 可取回。

---

## 2. 在 `main` 工作树上重新验证（不是只在移植工作树里验过）

| 项 | 结果 |
| --- | --- |
| `npm run setup` | 38 个夹具 |
| `./gradlew build` | **BUILD SUCCESSFUL in 50s**，产出 **10 个 jar** |
| `./gradlew runGameTestServer` | **All 1479 required tests passed** |
| `npm run test:unit` | **140 / 140**（含恢复的 i18n 枚举键门禁） |

---

## 3. 切换时遇到的一个坑（已修）

`npm run setup` 首次失败：

```
Error: failed to create store /home/tcch1111/pla/mod/.blockwright-store
Caused by: File exists (os error 17)
```

原因：`.blockwright-store` 变成了**指向自己的符号链接**（之前给移植工作树做符号链接时误伤主树）。

**处置**：删除该链接 → 重新 `npm run setup` → store 重建成功、38 个夹具就绪。
**教训**：给工作树做符号链接时要确认 cwd；`ln -sfn 源 .目标` 在源目录里执行会形成自环。

---

## 4. 现在的仓库形态

| 分支/标签 | 指向 | 含义 |
| --- | --- | --- |
| `main` | `64e35ad` | **10 模块、全套 `plaa_*`、1479/1479** |
| `port/aaac8b8` | `64e35ad` | 移植执行分支（与 main 同点，保留作记录） |
| `pre-port-main-20261106` | `c456385` | 移植前的旧历史 |
| `upstream-base-3ce4d88-20261019` | 旧上游基线 | 历史参考 |

---

## 5. 风险声明（必须写在最显眼处）

**本次切换没有做过任何客户端实测。**

| 已证（机器） | 未证（人眼） |
| --- | --- |
| 十模块打包后能在真实专用服务端启动（VERIFY-048：`Done 4.511s`、0 FATAL） | **客户端能否进主菜单、模组列表是否 10 个 `plaa_*`** |
| 1479 条游戏测试、140 条 unit | 殖民书能圈地、能开殖民地 |
| 服务端加载十个 modid | 禁区 / 作息 / 心情 / **关系卡片两行** 的界面观感 |
| — | `serverconfig/plaa_*-server.toml` 是否按新 modid 生成 |

**因此 D11 不只是保持开启，而是变大了**：现在它涵盖"10 模块客户端 + 关系卡片 + 演示脚本 19 点"。
**下次发版前必须先补这一项**——测试包见 [SYNC-008](SYNC-008-test-package.md)（`.mrpack` 216 MB）。

---

## 6. 下一步

1. `pack/` 改成 10 模块口径（换 10 个 jar + 补 7 个 `.pw.toml`，规格见 [pack §12](../pack/00-pack-spec.md)）；
2. 重打 `.mrpack`、发 v0.2.0；
3. 补 D11（客户端实测）；
4. 回 M2-R2（摩擦，[PLAN-008](../plans/PLAN-008-m2-r2-friction.md)，等拍板怨气来源）。
