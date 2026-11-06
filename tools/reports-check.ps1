<#
.SYNOPSIS
  检查 docs/reports/ 下每份报告都登记在 docs/README.md 里。

.DESCRIPTION
  本项目的规矩是"每轮产出可复现证据"，而证据要被找到才算数。
  这个脚本确认 reports 目录里的每个文件都出现在 README 中（按文件名匹配）。
  只读；有问题时非零退出，可挂 CI。

.EXAMPLE
  pwsh -File tools/reports-check.ps1
#>
[CmdletBinding()]
param(
    [string]$DocsDir = ''
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
if (-not $DocsDir) { $DocsDir = Join-Path $repo 'docs' }
$DocsDir = (Resolve-Path -LiteralPath $DocsDir).Path

$readme = Join-Path $DocsDir 'README.md'
if (-not (Test-Path $readme)) { throw "找不到 docs/README.md" }
$readmeText = [System.IO.File]::ReadAllText($readme)

$reports = Get-ChildItem (Join-Path $DocsDir 'reports') -Filter '*.md' -File | Sort-Object Name
$missing = @()
foreach ($r in $reports) {
    if ($readmeText -notmatch [regex]::Escape($r.Name)) {
        $missing += $r.Name
    }
}

Write-Output ("报告 $($reports.Count) 份 · 未登记 $($missing.Count)")
if ($missing.Count -eq 0) {
    Write-Output 'reports-check: 全部通过'
    exit 0
}
Write-Output 'reports-check: 以下报告没有出现在 docs/README.md'
foreach ($m in $missing) { Write-Output ('  - ' + $m) }
exit 1
