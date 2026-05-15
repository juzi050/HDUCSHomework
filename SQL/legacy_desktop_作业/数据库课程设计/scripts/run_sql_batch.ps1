param(
    [Parameter(Mandatory = $true)]
    [string]$ScriptPath,

    [Parameter(Mandatory = $true)]
    [string]$OutputPath,

    [switch]$AllowFailure
)

$container = 'sql2022-lab'
$sqlcmd = '/opt/mssql-tools18/bin/sqlcmd'
$password = 'CodexLab!2026'

$scriptFullPath = (Resolve-Path $ScriptPath).Path
$outputFullPath = [System.IO.Path]::GetFullPath($OutputPath)
$outputDir = Split-Path -Parent $outputFullPath

if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

$scriptContent = [System.IO.File]::ReadAllText($scriptFullPath, [System.Text.Encoding]::UTF8)
if ($scriptContent.Length -gt 0 -and [int][char]$scriptContent[0] -eq 65279) {
    $scriptContent = $scriptContent.Substring(1)
}
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$tempFile = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [System.IO.Path]::GetRandomFileName() + '.sql')
$containerFile = "/tmp/" + [System.IO.Path]::GetFileName($tempFile)

try {
    [System.IO.File]::WriteAllText($tempFile, $scriptContent, $utf8NoBom)

    docker cp $tempFile "${container}:${containerFile}" | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "docker cp failed for $scriptFullPath"
    }

    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processInfo.FileName = 'docker'
    $processInfo.Arguments = "exec $container $sqlcmd -S localhost -U sa -P $password -C -b -f 65001 -i $containerFile"
    $processInfo.RedirectStandardOutput = $true
    $processInfo.RedirectStandardError = $true
    $processInfo.UseShellExecute = $false
    $processInfo.CreateNoWindow = $true

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $processInfo
    $null = $process.Start()

    $stdout = $process.StandardOutput.ReadToEnd()
    $stderr = $process.StandardError.ReadToEnd()
    $process.WaitForExit()

    docker exec -u 0 $container rm -f $containerFile | Out-Null

    $combined = @(
        "=== SCRIPT ==="
        $scriptFullPath
        ""
        "=== STDOUT ==="
        $stdout.TrimEnd()
        ""
        "=== STDERR ==="
        $stderr.TrimEnd()
        ""
        "=== EXIT_CODE ==="
        $process.ExitCode
    ) -join [Environment]::NewLine

    Set-Content -LiteralPath $outputFullPath -Value $combined -Encoding UTF8

    if ($process.ExitCode -ne 0 -and -not $AllowFailure) {
        throw "sqlcmd exited with code $($process.ExitCode). See $outputFullPath"
    }
} finally {
    if (Test-Path $tempFile) {
        Remove-Item -LiteralPath $tempFile -Force
    }
}
