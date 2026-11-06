#!/usr/bin/env python3
"""Regenerate docs/SUMMARY-ALL.md.

Why a generator: this file claims to be the one document that answers "what is
this project now", and the earlier hand-maintained copy silently drifted a
dozen reports behind. Anything that can be derived is derived here; only the
judgement sections are written out, and they live in this script so a reviewer
can see what changed.

Usage:  python3 tools/summarize.py            (writes docs/SUMMARY-ALL.md)
"""

import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOCS = os.path.join(ROOT, 'docs')
OUT = os.path.join(DOCS, 'SUMMARY-ALL.md')

DIR_TITLES = [
    ('prd', 'PRD（产品需求）'),
    ('design', '设计'),
    ('pack', '整合包'),
    ('plans', '计划'),
    ('reports', '证据与报告'),
    ('research', '调研'),
    ('workflow', '工作流 / 任务书'),
    ('reference', '参考（未入库）'),
]


def read(path):
    with open(path, encoding='utf-8') as f:
        return f.read()


def title_of(path):
    text = read(path)
    m = re.search(r'(?m)^#\s+(.+)$', text)
    return m.group(1).strip() if m else os.path.basename(path)


def line_count(path):
    return len(read(path).splitlines())


def rel_link(path):
    return os.path.relpath(path, DOCS).replace(os.sep, '/')


def doc_map():
    groups = {}
    for entry in sorted(os.listdir(DOCS)):
        full = os.path.join(DOCS, entry)
        if os.path.isdir(full) and entry != 'reference':
            files = sorted(f for f in os.listdir(full) if f.endswith('.md'))
            if files:
                groups[entry] = files
    top = sorted(f for f in os.listdir(DOCS) if f.endswith('.md') and f != 'SUMMARY-ALL.md')

    out = ['## 2. 文档地图（自动生成；改动后重跑 `tools/summarize.py`）', '']
    out.append('### 根目录')
    out.append('')
    out.append('| 文件 | 标题 | 行数 |')
    out.append('| --- | --- | --- |')
    for f in top:
        p = os.path.join(DOCS, f)
        out.append('| [%s](%s) | %s | %d |' % (f, f, title_of(p), line_count(p)))
    out.append('')
    order = [d for d, _ in DIR_TITLES if d in groups] + [d for d in groups if d not in dict(DIR_TITLES)]
    for d in order:
        out.append('### %s/' % d)
        out.append('')
        out.append('| 文件 | 标题 | 行数 |')
        out.append('| --- | --- | --- |')
        for f in groups[d]:
            p = os.path.join(DOCS, d, f)
            out.append('| [%s](%s) | %s | %d |' % (f, rel_link(p), title_of(p).replace('|', '\\|'), line_count(p)))
        out.append('')
    return out


def adr_table():
    charter = read(os.path.join(DOCS, '00-charter.md'))
    rows = []
    for m in re.finditer(r'(?m)^\| \*{0,2}(ADR-\d+)\*{0,2} \| (.+?) \|', charter):
        summary = m.group(2)
        # 只取第一句，表格里要短
        summary = re.split(r'[：:。]', summary)[0][:80].strip()
        rows.append('| %s | %s |' % (m.group(1), summary))
    out = ['## 3. 关键决策（自动摘取 [00-charter.md](00-charter.md)，共 %d 条）' % len(rows), '']
    out.append('| 编号 | 决定（首句） |')
    out.append('| --- | --- |')
    out.extend(rows)
    out.append('')
    return out


def debt_table():
    roadmap = read(os.path.join(DOCS, 'ROADMAP.md'))
    rows = []
    for line in roadmap.splitlines():
        if not re.match(r'^\| D\d+ \|', line):
            continue
        cells = [c.strip() for c in line.strip().strip('|').split('|')]
        if len(cells) < 3:
            continue
        ident, debt, note = cells[0], cells[1], cells[-1]
        text = debt + ' ' + note
        # 只有「结清条件」一列带 ✅ 才算真的结清；划掉只是说明旧问题不在了，债务本身可能还开着。
        closed = '✅' in note
        mark = '✅' if closed else '⚠️'
        short = re.sub(r'\*\*', '', debt)
        short = short.replace('~~', '')
        short = re.split(r'[：:]', short)[0].strip()[:90]
        rows.append('| %s %s | %s | %s |' % (mark, ident, short, note[:40]))
    out = ['## 4. 债务清单（自动摘取 [ROADMAP.md](ROADMAP.md)，共 %d 条）' % len(rows), '']
    out.append('| 状态 | 债务 | 结清条件 / 说明 |')
    out.append('| --- | --- | --- |')
    out.extend(rows)
    out.append('')
    return out


def stats():
    files = []
    for base, _, names in os.walk(DOCS):
        for n in names:
            if n.endswith('.md'):
                files.append(os.path.join(base, n))
    total_lines = sum(line_count(f) for f in files)
    reports = len([f for f in files if os.sep + 'reports' + os.sep in f])
    out = [
        '## 8. 统计（自动计算）',
        '',
        '| 项 | 值 |',
        '| --- | --- |',
        '| 文档总数 | **%d** |' % len(files),
        '| 总行数 | **%d** |' % total_lines,
        '| 证据报告 | **%d** |' % reports,
        '| 本次生成 | `tools/summarize.py` |',
        '',
        '> 本文件由脚本生成；请勿手改，改脚本或改源文件后重跑。',
        '',
    ]
    return out


HEAD = '''# 汇总：Per Lapidem ad Astra（一页看完）

> 这是**唯一**把项目现状汇总到一个文件里的文档。
> 前半是判断，后半（§2/§3/§4/§8）由 `tools/summarize.py` 从源文件生成，不会与源文件脱节。
> 最后更新：2026-11-06

---

## 1. 项目一句话

> 一个以 **Folkways**（MIT，`IzakyL/folkways`）为基底、面向 **Minecraft 1.21.1 / NeoForge** 的殖民地模拟模组整合包：
> 玩家不是直接操作每个方块，而是给居民**制定规则、划区域、排序任务**，让他们自己把殖民地运转起来——
> 目标是"矮人要塞 / 环世界 / 石炉 / 希克斯之歌"的**人与故事感**，加上 Minecraft 的**建造自由度**。

### 现在的状态

| 维度 | 现状 |
| --- | --- |
| 代码分支 | `main` = `3234812`（十模块，全部 `plaa_*`） |
| 测试 | 本地 **1482** 游戏测试 全绿；unit **140/140** |
| CI | fork **Build #49**：11 个作业全绿；docs 仓库**四道门禁**全绿 |
| 发布物 | **[v0.2.1](https://github.com/TCCH1111/per-lapidem-ad-astra/releases/tag/v0.2.1)**：10 jar + `.mrpack`（62 下载条目） |
| 里程碑 | M0 ✅ · M1 ✅（WP-0/1/4/5/6/8 + CI）· M2 🟡（情绪 N1–N6 ✅、关系切片 R1 ✅） |
| 最大缺口 | **D11：没有任何人真正装过这个整合包并进世界** |

'''

TAIL_SECTIONS = '''## 5. 当前进度

| 里程碑 | 状态 | 说明 |
| --- | --- | --- |
| **M0 基底** | ✅ | 上游端口、许可证、构建、CI、分发四件套 |
| **M1 可玩骨架** | ✅ | 禁限区（含配额/主体/解释）、作息表（默认关）、解释层、诊断 UI 原型、CI 门禁 |
| **M2 张力** | 🟡 进行中 | 情绪 N1–N6 ✅；关系切片 R1 ✅（R2 摩擦已立项，等怨气来源口径）；医疗仅有 PRD |
| **M3 进程** | ⬜ 未开工 | 气体/能源/关押三条**接缝已定**（[d17](design/17-gas-seam.md)/[d18](design/18-power-seam.md)/[d19](design/19-captivity-seam.md)），实现未写 |
| **M4 故事与太空** | ⬜ 未开工 | PRD 与设计已有，代码未动 |
| **v1.0** | ⬜ | 依赖 M2–M4 |

---

## 6. 下一步（按顺序）

1. **D11 客户端实测**：装 [v0.2.1 的 `.mrpack`](https://github.com/TCCH1111/per-lapidem-ad-astra/releases/tag/v0.2.1)，进世界、圈地、开殖民地——所有"能不能玩"的判断都卡在这一步。
2. **M2-R2 摩擦**：等一句口径确认（怨气从哪来：A 旁人在受罪 / B 抢同一个活 / C 随机），[PLAN-008](plans/PLAN-008-m2-r2-friction.md) 已写好。
3. **M2 医疗**：PRD-013 已有 754 行与 API 映射；需要先定"受伤是否影响排班"。
4. **M3 三条接缝落地**：气体 → 能源 → 关押（前两者复用否决权，第三条要加 `CONFINE` 语义）。
5. **D19**：包里三条面粉链是否合并（涉及 Cookery 平衡）。

---

## 7. 建议阅读路线

| 目的 | 读这几份 |
| --- | --- |
| 先知道这是什么 | 本文件 §1 → [README](README.md) → [00-charter.md](00-charter.md) |
| 判断"能不能玩" | [reports/VERIFY-053](reports/VERIFY-053-m2-r1-closed.md) → [reports/SYNC-016](reports/SYNC-016-release-021.md) |
| 想改代码 | [design/12-fork-strategy.md](design/12-fork-strategy.md)（五表面改名规则）→ [workflow/05-m1-task-breakdown.md](workflow/05-m1-task-breakdown.md) |
| 想加玩法 | 对应 PRD → [design/17](design/17-gas-seam.md)（接缝写法范例） |
| 想发版 | [pack/00-pack-spec.md](pack/00-pack-spec.md) → [reports/SYNC-010](reports/SYNC-010-release-020.md) |
| 想知道哪里还欠着 | §4 债务清单 |

---
'''


def main():
    parts = [HEAD]
    parts.append('\n'.join(doc_map()))
    parts.append('\n'.join(adr_table()))
    parts.append('\n'.join(debt_table()))
    parts.append(TAIL_SECTIONS)
    parts.append('\n'.join(stats()))
    text = '\n'.join(parts)
    with open(OUT, 'w', encoding='utf-8', newline='') as f:
        f.write(text)
    print('wrote %s (%d lines)' % (OUT, len(text.splitlines())))
    return 0


if __name__ == '__main__':
    sys.exit(main())
