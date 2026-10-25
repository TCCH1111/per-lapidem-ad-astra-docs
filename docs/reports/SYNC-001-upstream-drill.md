# SYNC-001 · 上游同步演练 #1（本地模拟，无网络）

```
状态：通过（演练完成）
验证者：DSH 会话
验证日期：2026-10-26
队列：⑥ 上游同步演练 #1
环境：WSL `~/pla/mod`；GitHub 不可达（fetch upstream 超时 137 s），改用本地基线标签模拟
```

---

## 1. 为什么能在离线做

`fetch upstream` 连不上 GitHub（两次尝试都超时）。但演练要验的是**合并机制与冲突处理**，不是上游有没有新提交——本地有基线标签 `upstream-base-3ce4d88-20261019`，足够造一个"上游侧推进"的场景。

---

## 2. 演练做法（可复现）

```bash
git worktree add -f ~/pla/drill-sync upstream-base-3ce4d88-20261019
cp -f .blockwright/mods.json ~/pla/drill-sync/.blockwright/     # 见 §4
cd ~/pla/drill-sync
sed -i 's/case NO_FREE_HAND -> 0;/case NO_FREE_HAND -> 100;/' \
    mods/core/src/main/java/.../plan/Tours.java                 # 模拟上游改同一文件同一函数
git commit -am "sim(plan): upstream reorders the progress ladder"
git merge main -m "drill: merge our main into the simulated upstream"
./gradlew build --offline --no-daemon --console=plain
```

**为什么选 `Tours.java` 的 `progress()`**：那是我们 **L3 改过**、且上游很可能也会改的地方（枚举排序）。拿它当"最坏情况"的代表。

---

## 3. 结果

| 指标 | 结果 |
| --- | --- |
| `git merge main` 退出码 | **0** |
| 冲突文件数 | **0** |
| `Tours.java` 里 `// PLA:` 标记 | **2 处，仍在** |
| 合并后 `./gradlew build --offline` | **BUILD SUCCESSFUL in 31s** |
| 产物 | `plaa-core-neoforge-1.21.1-0.1.0.jar` 等正常产出 |
| 主工作树影响 | `git status` 0 处改动；worktree 已清理 |

**结论**：我们的改动与"上游在同一函数不同行的改动"可以自动合并；`// PLA:` 标记在合并后仍可检索（这正是 d12 R-FK-4 想要的效果）。

---

## 4. 演练暴露的一个真问题（操作性）

第一次演练**构建失败**：

```
A problem occurred evaluating project ':core'.
> mod emi is missing from .../.blockwright/mods.json; run  npm run setup  first
```

原因：`.blockwright/mods.json` 是**gitignore 的生成物**，新 worktree / 干净克隆里没有。

**处置**：演练时从主树 `cp` 过去即可（无需联网跑 setup）。这条已写进 d12 §6 的同步流程，也应写进 `CONTRIBUTING.md`（若尚未提及）。

**为什么重要**：真同步时若换了机器或新克隆，会卡在这一步；而报错信息指向 `npm run setup`（需要网络 + Node），是个容易误判为"环境坏了"的坑。

---

## 5. 与真实同步的差距（诚实）

| 环节 | 本次演练 | 真实同步 |
| --- | --- | --- |
| 上游提交来源 | 我们伪造的一处改动 | 真实上游提交（可能大改、可能重构） |
| 冲突规模 | 同一函数不同行 | 未知，可能更糟 |
| 网络与远端 | 未涉及 | 必须能连 GitHub |
| 后续（推送、CI） | 未涉及 | 需要 |

**所以这次演练证明的是"机制可用"，不是"下次同步一定顺利"。** 待网络恢复后补一次真实 `fetch upstream`（哪怕上游无新提交，也走一遍流程并记录）。

---

## 6. 下一步

1. 网络恢复后：`git fetch upstream` → 记录 `HEAD..upstream/master` 计数 → 无新提交则记为"同步为 no-op"；
2. 把 `.blockwright/mods.json` 的坑写进 `CONTRIBUTING.md`；
3. 演练 #2 留到上游真有提交时做（那时才有真冲突可看）。