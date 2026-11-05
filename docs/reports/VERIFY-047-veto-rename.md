# VERIFY-047 · D16 关闭：`Standing → Veto` 改名，并让门禁抓到了一条真回归

```
状态：通过（四件套全绿）
验证者：DSH 会话
验证日期：2026-11-05
关联：SYNC-002（发现撞词）、VERIFY-045（CI 门禁）、D16/D6
fork 提交：c456385
```

---

## 1. 结论

`Standing/Standings` 改名为 **`Veto/Vetoes`**，为移植上游清掉一处**语义撞车**。过程中**门禁抓到一条我自己引入的真回归**——这正是 D6/D7 关掉"没有 CI"之后的第一次实际收益。

```
build ✅ · unit 134/134 ✅ · i18n 7/7 ✅ · gametest 714/714 ✅
```

---

## 2. 为什么要改名

SYNC-002 发现：上游把 **"Standing" 用作 "stand（站位）规划"** 语义（`StandingPlanGameTests`、`StandTravelGameTests`）。我们用 `Standing` 表示"否决权"，同一个词在同一个代码库里指两件事——移植时极易误读。

改名后：
- `core/api/work/Standing.java` → **`Veto.java`**
- `core/api/work/Standings.java` → **`Vetoes.java`**
- 三个测试类跟随：`VetoGameTests`、`VetoesReasonGameTests`、`SteeringVetoGameTests`

---

## 3. 我犯的错，以及它怎么被抓住（两轮）

### 第一轮：`sed` 式全局替换，误伤基底语义

我把 `standing(` / `standingOf` 也一起替换，结果改掉了**基底自己的方法**：

| 被误改 | 真实语义 |
| --- | --- |
| `BodyRunner.standing()` → `veto()` | 身体"站着/空闲"状态 |
| `Tours.standing(seat, spec)` → `veto(...)` | 规划里的**代价函数** |
| 注释 `// Standing orders are reserves` | 常备订单 |
| 语言值 `"Standing"`（构建/订单面板用词） | 玩家可见文案 **被改成 "Veto"** |

编译当场报错（`cannot find symbol`），日志里也一眼看得出 `runner.veto()` 很荒谬。**回滚**。

### 第二轮：终于用对方法——只改代码标识符

写了一个**分词器**：把每行切成"代码段 / 字符串段 / 注释段"，只在代码段里替换 `\bStanding\b`。

- 结果：15 个 Java 文件被改写；
- **语言 JSON 一字未动**（`"Standing"` 作为 UI 用词保留）；
- 基底 `standing(` 方法原样保留（`BodyRunner` 里 5 处）。

**唯一保留的自然语言**是几处注释（`// Standing at a station…`），那是英文原意，正确。

### 我特意没改方法名

`Pipeline.standing(Veto)`、`ColonyLabor.standing(Veto)` 这些方法名**保留**。理由：同一个类里可能已经有基底的 `standing(...)` 重载，逐个改名的风险大于收益；**类型名才是撞车的根源**，改类型已经解决。

---

## 4. 门禁抓到的真回归（本轮最重要的发现）

改完名后跑四件套，`unit` 与 `i18n` 各挂 1 条：

```
not ok 73 - notice and refusal enums have translations for every declared value
  error: '.../plugins/mood/Mood.java: folkways.mood.content'
```

**根因不是我这次改名**，而是 **N6（VERIFY-046）引入的**：`Mood` 一旦 `implements NoticeKind`，i18n 门禁就按 `NoticeKind` 的约定要求**裸键** `folkways.mood.<band>`，而我们只提供了 `folkways.mood.<band>.title` / `.advice`。

**修法**（顺势简化）：

| 之前 | 之后 |
| --- | --- |
| `translationKey()` → `…title`；`titleKey()` → `…title` | `translationKey()` → **裸键** `folkways.mood.<band>`；`titleKey()` 复用裸键 |
| 语言文件 4 档 × `.title` + `.advice` | 4 档 × 裸键 + `.advice`（**少了一层无意义后缀**） |

修完：`unit 134/134`、`i18n 7/7` 恢复。

### 这件事的意义

VERIFY-045 当时"四件套全绿"是真的；但**之后 N6 又引入了回归**，而这次是**门禁自己发现的**，不是我事后回忆出来的。

> 这正是"没有 CI"（D6）值得先还的原因：它今天替我抓到了一个我自己不会去查的错误。

---

## 5. 证据

```
npm run typecheck            → exit 0
npm run test:unit            → # tests 134 / pass 134 / fail 0
npm run test:i18n            → # tests 7   / pass 7   / fail 0
./gradlew build --offline    → BUILD SUCCESSFUL in 10s
./gradlew runGameTestServer  → All 714 required tests passed :)
```

---

## 6. 对移植的意义

- 撞车消除后，`Veto.java`/`Vetoes.java` 这两个文件可以**原样**搬到上游树里，不会与他们的 "standing" 概念混淆；
- 移植预检里的 12 个冲突文件里，`BuiltinPlugins.java`、`Labor.java` 的解冲突会更容易读——因为"否决"现在字面上就叫 Veto。

---

## 7. 下一步

按 SYNC-002 的路线继续：

1. 开 `port/aaac8b8` 分支（本轮已在 `main` 上完成改名与修复，`main` 仍可发布）；
2. 搬 48 个新文件 → 合 24 个干净的 → 逐个解 12 个冲突 → 安置 `Solving.java`；
3. 目标：移植树上四件套同样全绿。
