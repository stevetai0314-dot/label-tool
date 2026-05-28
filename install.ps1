$dir = $PSScriptRoot
$desktop = [Environment]::GetFolderPath('Desktop')
$ws = New-Object -ComObject WScript.Shell
$lnkPath = $desktop + '\' + [char]0x958B + [char]0x555F + [char]0x6A19 + [char]0x7C64 + [char]0x7CFB + [char]0x7D71 + '.lnk'
$lnk = $ws.CreateShortcut($lnkPath)
$lnk.TargetPath = 'C:\Windows\explorer.exe'
$lnk.Arguments = 'https://stevetai0314-dot.github.io/label-tool/'
$lnk.IconLocation = $dir + '\icon.ico,0'
$lnk.Description = 'MEO SCAN Label Tool'
$lnk.WindowStyle = 1
$lnk.Save()
Write-Host 'Done! Shortcut created on Desktop.' -ForegroundColor Green
Start-Sleep -Seconds 2
