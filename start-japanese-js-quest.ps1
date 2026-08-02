$ErrorActionPreference = 'Stop'

$gameDirectory = Join-Path $PSScriptRoot 'app\assets\japanese-js-quest'
Set-Location $gameDirectory

Write-Host 'JavaScript Quest: http://localhost:8000' -ForegroundColor Cyan
Write-Host 'Press Ctrl+C in this window to stop the server.' -ForegroundColor DarkGray

if (Get-Command py -ErrorAction SilentlyContinue) {
  & py -m http.server 8000
} elseif (Get-Command python -ErrorAction SilentlyContinue) {
  & python -m http.server 8000
} else {
  throw 'Python was not found. Install Python or make the py/python command available.'
}
