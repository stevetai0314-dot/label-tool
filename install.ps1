$ws = New-Object -ComObject WScript.Shell
$desktop = $ws.SpecialFolders("Desktop")
$lnkPath = Join-Path $desktop "MEO SCAN.lnk"

$lnk = $ws.CreateShortcut($lnkPath)
$lnk.TargetPath = "C:\Windows\explorer.exe"
$lnk.Arguments = "https://stevetai0314-dot.github.io/label-tool/"
$lnk.IconLocation = $PSScriptRoot + "\icon.ico,0"
$lnk.Description = "MEO SCAN Label Tool"
$lnk.WindowStyle = 1
$lnk.Save()

Write-Host "Created at: $lnkPath" -ForegroundColor Green
Start-Sleep -Seconds 2
