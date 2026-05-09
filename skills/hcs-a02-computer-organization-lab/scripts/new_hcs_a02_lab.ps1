[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Destination,

    [string]$ModuleName = "top",

    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ($ModuleName -notmatch '^[A-Za-z_][A-Za-z0-9_]*$') {
    throw "ModuleName must be a valid Verilog identifier."
}

$templateRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\assets\templates\lab")).ProviderPath
$templatePrefix = $templateRoot
if (-not $templatePrefix.EndsWith([System.IO.Path]::DirectorySeparatorChar)) {
    $templatePrefix += [System.IO.Path]::DirectorySeparatorChar
}

$destinationRoot = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Destination)
$templateFiles = Get-ChildItem -LiteralPath $templateRoot -Recurse -File

$copyPlan = foreach ($file in $templateFiles) {
    $relativePath = $file.FullName.Substring($templatePrefix.Length)
    [PSCustomObject]@{
        Source = $file.FullName
        Target = Join-Path $destinationRoot $relativePath
    }
}

if (-not $Force) {
    $conflicts = $copyPlan | Where-Object { Test-Path -LiteralPath $_.Target }
    if ($conflicts) {
        $conflictList = ($conflicts | ForEach-Object { $_.Target }) -join [Environment]::NewLine
        throw "Refusing to overwrite existing files. Re-run with -Force to replace them:$([Environment]::NewLine)$conflictList"
    }
}

New-Item -ItemType Directory -Force -Path $destinationRoot | Out-Null

foreach ($item in $copyPlan) {
    $targetDirectory = Split-Path -Parent $item.Target
    New-Item -ItemType Directory -Force -Path $targetDirectory | Out-Null

    $content = Get-Content -LiteralPath $item.Source -Raw
    $content = $content.Replace("__MODULE_NAME__", $ModuleName)
    [System.IO.File]::WriteAllText($item.Target, $content, [System.Text.Encoding]::ASCII)
}

Write-Host "Created HCS-A02 lab template at $destinationRoot"
Write-Host "Top module: $ModuleName"
