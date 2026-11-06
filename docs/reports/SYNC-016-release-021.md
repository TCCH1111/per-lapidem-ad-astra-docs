# SYNC-016 · v0.2.1：把带缺陷的 v0.2.0 替换掉

```
状态：通过（11 个资产，URL 200；安装仍未实测）
验证者：DSH 会话
验证日期：2026-11-06
关联：SYNC-015（缺陷根因）、D11
产物：https://github.com/TCCH1111/per-lapidem-ad-astra/releases/tag/v0.2.1
```

---

## 1. 为什么要发新版本

v0.2.0 的 10 个 jar **构建于修复之前**，因此 `plaa-chiselsandbits` 里：

```
data/folkways_chiselsandbits/folkways/pattern/*.star   ← 旧命名空间
```

而代码查的是 `plaa_chiselsandbits:*` → **七个雕刻图案在游戏里全部找不到**（torii / rotunda / pavilion 等）。

这不是"文档没更新"，是**已发布的包里有个功能是坏的**。所以出 v0.2.1。

---

## 2. 发布内容

| 项 | 值 |
| --- | --- |
| tag | `v0.2.1`（指向 `main` = `1a20c4d`） |
| 资产 | **11 个**：10 jar + `PerLapidemAdAstra-0.2.1.mrpack`（15,740 字节） |
| 版本号 | `mod_version` 0.2.0 → **0.2.1** |
| URL 抽检 | `plaa-chiselsandbits` / `plaa-core` / `.mrpack` **全部 200** |

---

## 3. 整合包同步

| 文件 | 改动 |
| --- | --- |
| 10 个 `plaa-*.pw.toml` | URL → `v0.2.1`，`filename` 与 **sha256** 全部重算 |
| `pack/pack.toml` | `version` → `0.2.1+mc1.21.1+neoforge21.1.264` |
| `pack/index.toml` | 由 `pack-lint -Fix` 重建（68 条），哈希同步 |
| `.mrpack` | 重打：**62 下载 + 6 随包**（4 配置 + 任务书 + KubeJS） |

`pack-lint` 结果：**68 文件 / 62 条目 · 全部通过**。

---

## 4. 与 v0.2.0 的关系

| | v0.2.0 | v0.2.1 |
| --- | --- | --- |
| 十模块 | ✅ | ✅ |
| C&B 图案 | ❌ 坏 | ✅ 修好（CI 42/42 证明） |
| 整合包条目 | 62 | 62（URL 更新） |

**v0.2.0 的 mrpack 资产已不再指向当前代码**：装它仍然能跑，但 C&B 图案不可用。建议一律用 v0.2.1。

---

## 5. 仍然没验的

- **客户端安装与进世界**（D11）；
- 7 个图案在游戏里**实际画得出来**（CI 只证明 42 条测试通过，其中包含图案绘制断言）。

---

## 6. 教训（与 SYNC-015 连起来看）

> 缺陷被 CI 抓到 → 修在 main → **但已经发出去的包不会自己变好**。

发版与修复是两件事：**代码修好只影响下一次构建**。这也是为什么版本号必须往前走，而不是"改同一个 release 的资产"（SYNC-012 那次改资产的做法，这次不再用）。
