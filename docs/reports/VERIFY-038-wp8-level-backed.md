# VERIFY-038 · WP-8 / 第三段：数据在"关卡拥有的殖民地"上（703/703）

```
状态：通过（WP-8 自动化到此为止）
验证者：DSH 会话
验证日期：2026-10-26
关联：VERIFY-036/037、D11
fork 提交：a61f175
```

---

## 1. 结论

用服务端 mint 出一个殖民地、把两个数据源 `keep` 上去，再**按 id 向服务端要回来**读——数据都在。这说明数据活在**关卡拥有的殖民地注册表**上，不是我们手里的对象。

```java
Colony minted = Colonies.mint(server);
minted.keep(SteeringContent.ID, zones.save());
Colonies.of(server, minted.id()).orElseThrow().kept(SteeringContent.ID)   // 读回一致
```

游戏测试：**`All 703 required tests passed`**（702 + 1）。

---

## 2. 为什么自动化到此为止（不是偷懒）

查过：**没有无玩家建殖民地的命令**。命令只有 `invitation accept/decline` 与 `library`；`Colonies.mint` 的调用点只有两处——`Charters:75`（玩家用殖民书）与 `ColonyGround:40`（玩家落地）。

所以"整局存盘 → 停服 → 重启 → 读回"这一环**必须有玩家参与**，gametest 造不出来。

---

## 3. 于是写成人话检查表（发布前必做）

已加入 `docs/ROADMAP.md` 的发布清单：

```
人工验收 · 存档往返（约 6 分钟）
1. Prism 启动 PLAA-test，新建世界（创造，种子随意）
2. 拿殖民书 → 建殖民地；划定一个禁入区；打开作息，选白班并启用
3. /save-all → 退出到标题 → 完全关闭游戏
4. 重新启动，进入同一世界
5. 打开殖民书：区域仍在、作息仍开、班次仍是白班
6. 观察一个工作周期：到点仍有居民停工（说明数据不只是显示，闸门也活着）
7. 若任何一步不符 → 记 BLOCKER，附 latest.log 与截图
```

---

## 4. WP-8 总账

| 段 | 内容 | 状态 |
| --- | --- | --- |
| 一 | 每殖民地隔离 + 卸载摘除 provider | ✅ VERIFY-036 |
| 二 | `keep → kept` 往返（数据层） | ✅ VERIFY-037 |
| 三 | 数据在关卡拥有的殖民地上 | ✅ 本轮 |
| 四 | **进程重启后读回** | ⬜ **人工验收**（无法自动化，原因见 §2） |

→ WP-8 可以按"自动化部分完成 + 人工清单就绪"收口；D11 从"三项未验"缩为"一项人工验收"。