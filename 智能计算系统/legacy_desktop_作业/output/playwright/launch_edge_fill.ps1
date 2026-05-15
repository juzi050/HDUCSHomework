$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Url = "https://www.icourse163.org/learn/HDU-1472771170?tid=1476670444#/learn/quiz?id=1247839085"
$Port = 9222
$Endpoint = "http://127.0.0.1:$Port"
$Profile = Join-Path $Root "icourse163\edge-cdp-profile"

$EdgeCandidates = @(
  "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
  "${env:ProgramFiles}\Microsoft\Edge\Application\msedge.exe"
)

$Edge = $EdgeCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $Edge) {
  throw "Cannot find Microsoft Edge executable."
}

New-Item -ItemType Directory -Force -Path $Profile | Out-Null

function Test-CdpReady {
  try {
    Invoke-WebRequest -Uri "$Endpoint/json/version" -UseBasicParsing -TimeoutSec 1 | Out-Null
    return $true
  } catch {
    return $false
  }
}

$EdgeArgs = @(
  "--remote-debugging-port=$Port",
  "--user-data-dir=$Profile",
  "--no-first-run",
  "--new-window",
  $Url
)

Start-Process -FilePath $Edge -ArgumentList $EdgeArgs -WorkingDirectory $Root

for ($i = 0; $i -lt 30; $i++) {
  if (Test-CdpReady) {
    break
  }
  Start-Sleep -Seconds 1
}

if (-not (Test-CdpReady)) {
  throw "Edge CDP endpoint did not become ready: $Endpoint"
}

Push-Location $Root
try {
  node .\icourse163_quiz_assist.js fill --cdp=$Endpoint --poll-ready --no-final-prompt --keep-open
} finally {
  Pop-Location
}
