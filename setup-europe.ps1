# Europe Game - one-click setup (downloads all scripts)
$base = "https://raw.githubusercontent.com/yagubiskenderov483-code/bot.py/cursor/roblox-europe-strategy-8ce4/roblox-europe"

$game = Join-Path $env:USERPROFILE "Desktop\EuropeGame"
if (-not (Test-Path (Join-Path $env:USERPROFILE "Desktop"))) {
    $game = Join-Path $env:USERPROFILE "OneDrive\Desktop\EuropeGame"
}
New-Item -ItemType Directory -Force -Path $game | Out-Null

$files = @(
    "src\ReplicatedStorage\Modules\EuropeCountries.lua",
    "src\ReplicatedStorage\Modules\EuropeGrid.lua",
    "src\ServerScriptService\Bootstrap.server.lua",
    "src\ServerScriptService\CountryState.lua",
    "src\ServerScriptService\WorldMapGenerator.server.lua",
    "src\ServerScriptService\WarAndEconomyServer.server.lua",
    "src\StarterPlayer\StarterPlayerScripts\TopBarClient.client.lua",
    "src\StarterPlayer\StarterPlayerScripts\ActionPanelsClient.client.lua"
)

foreach ($f in $files) {
    $local = Join-Path $game ($f -replace '/', '\')
    New-Item -ItemType Directory -Force -Path (Split-Path $local) | Out-Null
    $url = "$base/" + ($f -replace '\\', '/')
    Write-Host "Downloading $f ..."
    Invoke-WebRequest -Uri $url -OutFile $local -UseBasicParsing
}

$json = @'
{
  "name": "Europe",
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": {
      "$className": "ReplicatedStorage",
      "Modules": {
        "$className": "Folder",
        "$path": "src/ReplicatedStorage/Modules"
      },
      "Remotes": {
        "$className": "Folder"
      }
    },
    "ServerScriptService": {
      "$className": "ServerScriptService",
      "$path": "src/ServerScriptService"
    },
    "StarterPlayer": {
      "$className": "StarterPlayer",
      "StarterPlayerScripts": {
        "$className": "StarterPlayerScripts",
        "$path": "src/StarterPlayer/StarterPlayerScripts"
      }
    }
  }
}
'@
$enc = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText((Join-Path $game "default.project.json"), $json, $enc)

Write-Host ""
Write-Host "=== GOTOWO / DONE ==="
Write-Host "Folder: $game"
Write-Host ""
Write-Host "Now run:"
Write-Host "  cd `"$game`""
Write-Host "  C:\Users\ф\Downloads\rojo-7.7.0-windows-x86_64\rojo.exe serve"
Write-Host ""
explorer $game
