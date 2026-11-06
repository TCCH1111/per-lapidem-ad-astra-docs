<#
.SYNOPSIS
  检查验收检查（AC）编号的一致性。

.DESCRIPTION
  AC 有两种定义写法：
    - 任务书表格行：`| AC-21 | ... |`
    - PRD 清单项：  `- [ ] AC-36 **成瘾形成**：...`
  先把两种都收成定义集，再逐行扫描其它出现（跳过定义行本身），
  报告"引用了但全仓没有定义"的编号。只读；有问题时非零退出。

.EXAMPLE
  pwsh -File tools/ac-check.ps1
#>
[CmdletBinding()]
param(
    [string]$DocsDir = ''
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
if (-not $DocsDir) { $DocsDir = Join-Path $repo 'docs' }
$DocsDir = (Resolve-Path -LiteralPath $DocsDir).Path

$definitionPatterns = @(
    '^\|\s*\**?(AC-\d+)\**?\s*\|',
    '^\s*-\s*\[[ xX]\]\s*\**?(AC-\d+)\**?',
    '^#{2,4}\s*\**?(AC-\d+)\**?\s'
)

$defined = @{}
$files = Get-ChildItem $DocsDir -Recurse -Filter '*.md' -File
foreach ($file in $files) {
    $lines = [System.IO.File]::ReadAllLines($file.FullName)
    foreach ($line in $lines) {
        foreach ($pattern in $definitionPatterns) {
            $m = [regex]::Match($line, $pattern)
            if ($m.Success) { $defined[$m.Groups[1].Value] = $true }
        }
    }
}
Write-Output ("定义的 AC: " + $defined.Count)

$unknown = @{}
$checked = 0
foreach ($file in $files) {
    $lines = [System.IO.File]::ReadAllLines($file.FullName)
    $rel = [System.IO.Path]::GetRelativePath($DocsDir, $file.FullName).Replace('\', '/')
    foreach ($line in $lines) {
        $isDefinition = $false
        foreach ($pattern in $definitionPatterns) {
            if ([regex]::IsMatch($line, $pattern)) { $isDefinition = $true; break }
        }
        if ($isDefinition) { continue }
        foreach ($m in [regex]::Matches($line, '\bAC-\d+\b')) {
            $checked++
            if (-not $defined.ContainsKey($m.Value)) {
                $key = "$($m.Value) @ $rel"
                if (-not $unknown.ContainsKey($key)) { $unknown[$key] = $true }
            }
        }
    }
}

Write-Output ("引用的 AC: $checked 次")
if ($unknown.Count -eq 0) {
    Write-Output 'ac-check: 全部一致'
    exit 0
}
Write-Output ("ac-check: $($unknown.Count) 处引用了未定义的编号")
foreach ($k in ($unknown.Keys | Sort-Object)) { Write-Output ('  - ' + $k) }
exit 1
