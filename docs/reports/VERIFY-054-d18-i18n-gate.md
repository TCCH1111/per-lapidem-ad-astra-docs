# VERIFY-054 · D18 关闭：i18n 枚举键门禁恢复（unit 140/140）

```
状态：通过（D18 关闭）
验证者：DSH 会话
验证日期：2026-11-06
关联：VERIFY-052 §5（缺口发现）、VERIFY-045/047（旧版门禁）、D18
分支：port/aaac8b8 → 64e35ad
```

---

## 1. 结论

移植时丢掉的 **"每个 `NoticeKind` / `RefusalKind.Named` 值都必须有译文"** 检查**补回来了**，
而且比原来严：**四种语言都查**，不只是英文。

```
npm run test:unit → 140 / 140（原 138 + 2）
gametest          → 1479 / 1479（未受影响）
```

---

## 2. 这条门禁怎么工作

| 步骤 | 规则 |
| --- | --- |
| 找枚举 | 扫 `mods/*/src/main/**/*.java`，找 `enum X implements NoticeKind`（或 `RefusalKind.Named`） |
| 推前缀 | 必须写成 `"前缀" + name().toLowerCase(Locale.ROOT)`；`RefusalKind.Named` 按类名推 |
| 验译文 | 每个常量 → `前缀 + 常量小写`，**必须在 en_us / zh_cn / zh_hk / zh_tw 四份语言表里都存在** |
| 防退化 | 断言"检查过的键 ≥ 100 个"，避免正则失效后**静默通过** |

---

## 3. 它立刻抓到了我们自己的代码

装上门禁的第一次运行，它**拒绝了我们刚写的 `Companion`**：

```
an enum that spells its own keys cannot be checked;
use "prefix" + name().toLowerCase(Locale.ROOT)
```

原因：`Companion` 用的是两个写死的键，门禁无法按规则推导 → 判为"不可检查"。

**处理方式：改代码，不改门禁。**

| 之前 | 之后 |
| --- | --- |
| `Companion.TOGETHER` / `TOGETHER_ADVICE`，键写死 | `Relate.COMPANION` / `COMPANION_ADVICE`，键由规则生成 |
| `folkways.relate.companion` / `...companion.advice` | `folkways.relate.companion` / **`folkways.relate.companion_advice`** |

四份语言表的键同步改名，JSON 逐个重新解析验证。

**如果当时选择"放宽测试"，这条门禁就白补了**——这正是 D18 存在的原因。

---

## 4. 全仓体检结果

```
枚举: 29 个 · 检查键: 116 次 · 无法推导前缀: 0 · 缺键: 0
```

---

## 5. 交付

| 文件 | 内容 |
| --- | --- |
| `tests/i18n/notice-keys.test.ts` | 2 个测试（规则检查、四语检查） |
| `plugins/relate/Relate.java` | 取代 `Companion`，键由规则生成 |
| `RelateFacing.java` / 测试 / 四语言表 | 跟随改名 |

它随 `npm run test:unit` 自动运行（`tests/**/*.test.ts`），所以**CI 里也已经生效**。

---

## 6. 债务变化

| 编号 | 变化 |
| --- | --- |
| **D18** | ✅ **关闭**：门禁已恢复且更严（四语） |
