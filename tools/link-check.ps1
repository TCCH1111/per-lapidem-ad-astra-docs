<#
.SYNOPSIS
  检查 docs/ 里所有 Markdown 的本地链接是否都能解析。

.DESCRIPTION
  只查本地链接（http/https 与锚点跳过）。能查 .md、图片、.snbt 等任何带扩展名的相对路径。
  发现问题时以非零码退出，便于直接挂进 CI。

.EXAMPLE
  pwsh -File tools/link-check.ps1
#>
[CmdletBinding()]
param(
    [string]$DocsDir = ''
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
if (-not $DocsDir) { $DocsDir = Join-Path $repo 'docs' }
if (-not (Test-Path $DocsDir)) { throw "找不到文档目录: $DocsDir" }
$DocsDir = (Resolve-Path -LiteralPath $DocsDir).Path.TrimEnd('/', '\')

$broken = New-Object System.Collections.Generic.List[string]
$checked = 0
$files = Get-ChildItem $DocsDir -Recurse -Filter '*.md' -File

foreach ($file in $files) {
    $text = [System.IO.File]::ReadAllText($file.FullName)
    foreach ($m in [regex]::Matches($text, '\]\((?<target>[^)\s]+)\)')) {
        $target = $m.Groups['target'].Value
        if ($target -match '^(https?:|mailto:|#)') { continue }
        # 去掉锚点与查询串
        $path = ($target -split '#')[0]
        if ([string]::IsNullOrWhiteSpace($path)) { continue }
        $candidate = [System.IO.Path]::GetFullPath((Join-Path $file.DirectoryName $path))
        $checked++
        if (-not (Test-Path -LiteralPath $candidate)) {
            $rel = [System.IO.Path]::GetRelativePath($DocsDir, $file.FullName).Replace('\', '/')
            $broken.Add("$rel -> $target")
        }
    }
}

Write-Output ("检查 $($files.Count) 个 Markdown · 本地链接 $checked 条")
if ($broken.Count -eq 0) {
    Write-Output 'link-check: 全部通过'
    exit 0
}
Write-Output ("link-check: $($broken.Count) 条断链")
foreach ($b in $broken) { Write-Output ('  - ' + $b) }
exit 1
