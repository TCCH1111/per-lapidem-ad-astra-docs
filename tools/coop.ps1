<#
.SYNOPSIS
  .coop 多模型协作总线的操作入口（任务卡 / 认领 / 报告 / 交叉评审 / 校验）。

.DESCRIPTION
  这是给 agent 用的机械工具：它只做"写文件 + 追加流水 + 结构校验"，不判断内容好坏。
  设计说明见 docs/workflow/08-multi-agent-collaboration.md；总线自身见 .coop/README.md。

.EXAMPLE
  pwsh -File tools/coop.ps1 -Action New -Title "裁决出行预算三方配额" -Source "docs/workflow/07-model-routing-and-escalation.md §1 #2"

.EXAMPLE
  pwsh -File tools/coop.ps1 -Action Claim -Id T-0001 -Owner zcode -Model glm-5.3 -Minutes 240

.EXAMPLE
  pwsh -File tools/coop.ps1 -Action Review -Id T-0001 -Reviewer claude -Via claude -DryRun
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory = $false)]
  [ValidateSet('Help', 'Status', 'List', 'New', 'Claim', 'Release', 'Report', 'Review', 'Verify', 'Show')]
  [string]$Action = 'Help',

  [string]$Id,
  [string]$Title,
  [string]$Source = '',
  [string]$Owner = '',
  [string]$Model = '',
  [string]$Author = '',
  [string]$Reviewer = '',
  [int]$Minutes = 240,
  [ValidateSet('none', 'claude', 'codex')]
  [string]$Via = 'none',
  [switch]$DryRun,
  [string]$Layer = 'L1'
)

$ErrorActionPreference = 'Stop'

# ---- 路径 ----------------------------------------------------------------
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$Coop = Join-Path $RepoRoot '.coop'
$Tasks = Join-Path $Coop 'tasks'
$Reports = Join-Path $Coop 'reports'
$Reviews = Join-Path $Coop 'reviews'
$Locks = Join-Path $Coop 'locks'
$Ledger = Join-Path $Coop 'ledger.md'

foreach ($d in @($Coop, $Tasks, $Reports, $Reviews, $Locks)) {
  if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

function Now { (Get-Date).ToString('yyyy-MM-ddTHH:mm:sszzz') }

function Read-Front([string]$Path) {
  $lines = Get-Content -LiteralPath $Path -Encoding UTF8
  $map = [ordered]@{}
  if ($lines.Count -lt 2 -or $lines[0].Trim() -ne '---') { return $map }
  for ($i = 1; $i -lt $lines.Count; $i++) {
    if ($lines[$i].Trim() -eq '---') { break }
    if ($lines[$i] -match '^\s*([A-Za-z_][A-Za-z0-9_-]*)\s*:\s*(.*)$') {
      $map[$Matches[1]] = $Matches[2].Trim()
    }
  }
  return $map
}

function Set-Front([string]$Path, [hashtable]$Updates) {
  $lines = Get-Content -LiteralPath $Path -Encoding UTF8
  $end = -1
  for ($i = 1; $i -lt $lines.Count; $i++) { if ($lines[$i].Trim() -eq '---') { $end = $i; break } }
  if ($end -lt 0) { throw "front-matter 缺失：$Path" }
  for ($i = 1; $i -lt $end; $i++) {
    if ($lines[$i] -match '^\s*([A-Za-z_][A-Za-z0-9_-]*)\s*:\s*(.*)$') {
      $k = $Matches[1]
      if ($Updates.ContainsKey($k)) { $lines[$i] = "$k" + ': ' + $Updates[$k] }
    }
  }
  Set-Content -LiteralPath $Path -Value $lines -Encoding UTF8
}

function Add-Ledger([string]$Op, [string]$Card, [string]$Who, [string]$Note = '') {
  $row = "| $(Now) | $Op | $Card | $Who | $Note |"
  Add-Content -LiteralPath $Ledger -Value $row -Encoding UTF8
}

function Next-Id {
  $max = 0
  Get-ChildItem $Tasks -Filter 'T-*.md' -ErrorAction SilentlyContinue | ForEach-Object {
    if ($_.BaseName -match 'T-(\d+)') { $n = [int]$Matches[1]; if ($n -gt $max) { $max = $n } }
  }
  'T-{0:D4}' -f ($max + 1)
}

function Get-Cards {
  Get-ChildItem $Tasks -Filter 'T-*.md' -ErrorAction SilentlyContinue | ForEach-Object {
    $fm = Read-Front $_.FullName
    [pscustomobject]@{
      Id      = $_.BaseName
      Status  = $(if ($fm.Contains('status')) { $fm['status'] } else { '?' })
      Owner   = $(if ($fm.Contains('owner')) { $fm['owner'] } else { '?' })
      Model   = $(if ($fm.Contains('model')) { $fm['model'] } else { '?' })
      Title   = $(if ($fm.Contains('title')) { $fm['title'] } else { '' })
      Path    = $_.FullName
      Report  = (Test-Path (Join-Path $Reports ($_.BaseName + '.md')))
      Review  = (Test-Path (Join-Path $Reviews ($_.BaseName + '.md')))
      Lock    = (Test-Path (Join-Path $Locks ($_.BaseName + '.lock')))
    }
  }
}

function Show-Help {
@'
.coop 协作总线（只做机械操作，不判断内容）

  -Action Status                     所有卡的状态一览
  -Action List                       同 Status，但只列未完成的
  -Action Show    -Id T-0001         打印一张卡
  -Action New     -Title "..." [-Source "..."] [-Layer L3]
  -Action Claim   -Id T-0001 -Owner zcode -Model glm-5.3 [-Minutes 240]
  -Action Release -Id T-0001 -Owner zcode
  -Action Report  -Id T-0001 -Author zcode         生成 reports/T-0001.md（六段式骨架）
  -Action Review  -Id T-0001 -Reviewer claude [-Via claude|codex] [-DryRun]
  -Action Verify                     结构校验：front-matter / 锁 / 报告 / 评审 / 流水

典型一轮：
  1) 编排者： New  → 写证据包
  2) 裁决者： Claim → 做判断 → 填 reports/T-xxxx.md（-Action Report 生成骨架）
  3) 另一个模型： Review -Via claude （写者≠评审者）
  4) 编排者： Verify → 采纳结论 → 改文档 → 登记 README
'@ | Write-Host
}

function Assert-Id {
  if ([string]::IsNullOrWhiteSpace($Id)) { throw '需要 -Id T-0001' }
  $p = Join-Path $Tasks ($Id + '.md')
  if (-not (Test-Path $p)) { throw "找不到任务卡：$p" }
  return $p
}

switch ($Action) {

  'Help' { Show-Help }

  'Status' {
    $cards = @(Get-Cards)
    if ($cards.Count -eq 0) { '（还没有任务卡）'; break }
    $cards | Sort-Object Id | Format-Table Id, Status, Owner, Model, Title, Report, Review, Lock -AutoSize | Out-String | Write-Host
  }

  'List' {
    $cards = @(Get-Cards | Where-Object { $_.Status -notin @('done', 'rejected', 'superseded') })
    if ($cards.Count -eq 0) { '（没有未完成的卡）'; break }
    $cards | Sort-Object Id | Format-Table Id, Status, Owner, Title -AutoSize | Out-String | Write-Host
  }

  'Show' {
    $p = Assert-Id
    Get-Content -LiteralPath $p -Encoding UTF8 | Write-Host
  }

  'New' {
    if ([string]::IsNullOrWhiteSpace($Title)) { throw '需要 -Title' }
    $nid = Next-Id
    $tpl = Join-Path $Coop 'templates\task.md'
    $body = Get-Content -LiteralPath $tpl -Raw -Encoding UTF8
    $body = $body -replace 'id: T-0000', "id: $nid"
    $body = $body -replace 'title: 【一句话标题，动词开头】', ("title: " + $Title)
    $body = $body -replace 'created: 2026-10-20T00:00:00\+08:00', ("created: " + (Now))
    $body = $body -replace 'layer: L1            #', ("layer: $Layer            #")
    if ($Source) { $body = $body -replace 'source: docs/workflow/07-model-routing-and-escalation\.md §1 #1', ("source: " + $Source) }
    $path = Join-Path $Tasks ($nid + '.md')
    Set-Content -LiteralPath $path -Value $body -Encoding UTF8
    Add-Ledger 'new' $nid $(if ($Owner) { $Owner } else { 'orchestrator' }) $Title
    "已创建 $path"
  }

  'Claim' {
    $p = Assert-Id
    if ([string]::IsNullOrWhiteSpace($Owner)) { throw '需要 -Owner' }
    $lock = Join-Path $Locks ($Id + '.lock')
    if (Test-Path $lock) {
      $exp = (Get-Content -LiteralPath $lock -Raw -Encoding UTF8)
      if ($exp -match 'expires=(?<t>[^\r\n]+)') {
        $t = [datetimeoffset]::Parse($Matches['t'])
        if ($t -gt [datetimeoffset]::Now) {
          throw "已被占用（$exp）。到期后可抢占，或先 -Action Release。"
        }
      }
    }
    $expires = (Get-Date).AddMinutes($Minutes).ToString('yyyy-MM-ddTHH:mm:sszzz')
    Set-Content -LiteralPath $lock -Value ("owner=$Owner`nmodel=$Model`nexpires=$expires`nclaimed=" + (Now)) -Encoding UTF8
    Set-Front $p @{ status = 'claimed'; owner = $Owner; model = $Model }
    Add-Ledger 'claim' $Id $Owner ("model=$Model; lease=${Minutes}m")
    "已认领 $Id → $Owner（到 $expires）"
  }

  'Release' {
    $p = Assert-Id
    $lock = Join-Path $Locks ($Id + '.lock')
    if (Test-Path $lock) { Remove-Item -LiteralPath $lock -Force }
    Set-Front $p @{ status = 'open'; owner = 'none'; model = 'none' }
    Add-Ledger 'release' $Id $(if ($Owner) { $Owner } else { 'system' }) ''
    "已释放 $Id"
  }

  'Report' {
    $p = Assert-Id
    $rp = Join-Path $Reports ($Id + '.md')
    if (Test-Path $rp) { "报告已存在：$rp"; break }
    $tpl = Get-Content -LiteralPath (Join-Path $Coop 'templates\report.md') -Raw -Encoding UTF8
    $tpl = $tpl -replace 'id: T-0000', "id: $Id"
    $tpl = $tpl -replace 'task: T-0000', "task: $Id"
    $tpl = $tpl -replace 'author: none', ("author: " + $(if ($Author) { $Author } else { 'none' }))
    $tpl = $tpl -replace 'finished: 2026-10-20T00:00:00\+08:00', ("finished: " + (Now))
    Set-Content -LiteralPath $rp -Value $tpl -Encoding UTF8
    Set-Front $p @{ status = 'reported' }
    Add-Ledger 'report' $Id $(if ($Author) { $Author } else { 'unknown' }) '骨架已生成'
    "已生成报告骨架：$rp（请填六段式）"
  }

  'Review' {
    $p = Assert-Id
    $rp = Join-Path $Reports ($Id + '.md')
    if (-not (Test-Path $rp)) { throw "还没有报告：$rp（先 -Action Report）" }
    if ([string]::IsNullOrWhiteSpace($Reviewer)) { throw '需要 -Reviewer' }
    $author = (Read-Front $rp)['author']
    if ($author -and $author -ne 'none' -and $author -eq $Reviewer) {
      throw "写者与评审者相同（$Reviewer）——违反 R-COOP-2，换一个模型。"
    }
    $vp = Join-Path $Reviews ($Id + '.md')
    $prompt = @"
你是交叉评审者。只找茬，不要重写方案。
任务卡：.coop/tasks/$Id.md
交付报告：.coop/reports/$Id.md
作者：$author

请逐条检查：
1) 报告里每条结论是否真有 文件:行号 或文档链接支撑？（列出没有证据的条目）
2) 是否越界（改了卡片"边界"之外的文件/编号）？用 git status --short 判断。
3) 风险段说的"最先在哪暴露"是否可验证？给不出的就是空话。
4) 有没有漏掉的前提？（例如把"编译期依赖"当"运行期依赖"这类）
5) 结论与 docs/00-charter.md 的 ADR 是否冲突？

输出到 .coop/reviews/$Id.md，格式：结论（采纳/退回）+ 问题清单（按严重度）+ 最小修复建议。不要展开成报告。
"@
    $cmdLine = ''
    if ($Via -eq 'claude') { $cmdLine = 'claude -p "' + ($prompt -replace '"', '\"') + '" --add-dir "' + $RepoRoot + '"' }
    elseif ($Via -eq 'codex') { $cmdLine = 'codex exec --cd "' + $RepoRoot + '" "' + ($prompt -replace '"', '\"') + '"' }

    if ($DryRun -or $Via -eq 'none') {
      "（DryRun/未指定 -Via：只生成评审骨架，不调用模型）"
      if ($cmdLine) { "将执行：`n$cmdLine" }
      if (-not (Test-Path $vp)) {
        @"
---
id: $Id
task: $Id
reviewer: $Reviewer
verdict: pending
finished: $(Now)
---

## 结论
（采纳 / 退回）

## 问题清单（按严重度）
| # | 严重度 | 问题 | 位置 |
| --- | --- | --- | --- |
| 1 | 高/中/低 | … | `文件:行号` |

## 最小修复建议
（只写"改哪一句/哪一行"，不要重写方案）
"@ | Set-Content -LiteralPath $vp -Encoding UTF8
      }
      Set-Front $p @{ status = 'reviewed' }
      Add-Ledger 'review' $Id $Reviewer ("via=" + $Via + "; dryrun=" + [bool]$DryRun)
      "已生成评审骨架：$vp"
      break
    }

    if (-not (Get-Command ($(if ($Via -eq 'claude') { 'claude' } else { 'codex' })) -ErrorAction SilentlyContinue)) {
      throw "找不到 CLI：$Via"
    }
    "调用 $Via 进行交叉评审（可能需要 1–3 分钟）…"

    $header = @"
---
id: $Id
task: $Id
reviewer: $Reviewer
verdict: pending
finished: $(Now)
---

"@

    if ($Via -eq 'claude') {
      # -p 把结果打到 stdout；--add-dir 让它在仓库内读写
      $raw = (& claude -p $prompt --add-dir $RepoRoot 2>&1 | Out-String)
      Set-Content -LiteralPath $vp -Value ($header + $raw) -Encoding UTF8
    } else {
      # codex exec 支持 -o 直接把最后一条消息写成文件（推荐）
      & codex exec -C $RepoRoot -o $vp $prompt 2>&1 | Out-String | Write-Host
      if (Test-Path $vp) {
        $body = Get-Content -LiteralPath $vp -Raw -Encoding UTF8
        if ($body -notmatch '^---') { Set-Content -LiteralPath $vp -Value ($header + $body) -Encoding UTF8 }
      } else {
        Set-Content -LiteralPath $vp -Value ($header + "（codex 未产出文件，请重跑或让它按提示词落盘）") -Encoding UTF8
      }
    }

    Set-Front $p @{ status = 'reviewed' }
    Add-Ledger 'review' $Id $Reviewer ("via=" + $Via)
    "评审完成：$vp"
  }

  'Verify' {
    $problems = New-Object System.Collections.Generic.List[string]
    $cards = @(Get-Cards)
    if ($cards.Count -eq 0) { '（没有卡，无需校验）'; break }

    foreach ($c in $cards) {
      $fm = Read-Front $c.Path
      foreach ($k in @('id', 'title', 'status', 'owner', 'model', 'created')) {
        if (-not $fm.Contains($k) -or [string]::IsNullOrWhiteSpace($fm[$k])) { $problems.Add("$($c.Id): front-matter 缺 $k") }
      }
      if ($fm['id'] -and $fm['id'] -ne $c.Id) { $problems.Add("$($c.Id): id 字段与文件名不一致（$($fm['id'])）") }
      $lock = Join-Path $Locks ($c.Id + '.lock')
      if ($fm['status'] -eq 'claimed' -and -not (Test-Path $lock)) { $problems.Add("$($c.Id): status=claimed 但没有锁文件") }
      if ((Test-Path $lock) -and $fm['status'] -notin @('claimed', 'reviewed')) { $problems.Add("$($c.Id): 有锁但状态是 $($fm['status'])") }
      if ($fm['status'] -in @('reported', 'reviewed', 'done') -and -not (Test-Path (Join-Path $Reports ($c.Id + '.md')))) { $problems.Add("$($c.Id): 状态 $($fm['status']) 但没有报告") }

      $rp = Join-Path $Reports ($c.Id + '.md')
      if (Test-Path $rp) {
        $body = Get-Content -LiteralPath $rp -Raw -Encoding UTF8
        foreach ($sec in @('## 1. 结论', '## 2. 依据', '## 3. 取舍', '## 4. 风险', '## 5. 待决', '## 6. 不确定')) {
          if ($body -notmatch [regex]::Escape($sec)) { $problems.Add("$($c.Id): 报告缺章节 '$sec'") }
        }
        if ($fm['status'] -eq 'done' -and $body -match '…') { $problems.Add("$($c.Id): 已标记 done 但报告仍含占位符 '…'") }
      }

      $vp = Join-Path $Reviews ($c.Id + '.md')
      if (Test-Path $vp) {
        $ra = (Read-Front $rp)['author']
        $rv = (Read-Front $vp)['reviewer']
        if ($ra -and $rv -and $ra -ne 'none' -and $ra -eq $rv) { $problems.Add("$($c.Id): 作者与评审者相同（违反 R-COOP-2）") }
      }
    }

    if ($problems.Count -eq 0) { "OK：$($cards.Count) 张卡结构合法。" }
    else { "发现 $($problems.Count) 个问题："; $problems | ForEach-Object { "  - $_" } }
  }

  default { Show-Help }
}
