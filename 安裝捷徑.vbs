Dim ws, fso, desk, lnk, scriptDir, iconPath

Set ws  = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
iconPath  = scriptDir & "\icon.ico"
desk      = ws.SpecialFolders("Desktop")

Set lnk = ws.CreateShortcut(desk & "\MEO SCAN.lnk")
lnk.TargetPath   = "C:\Windows\explorer.exe"
lnk.Arguments    = "https://stevetai0314-dot.github.io/label-tool/"
lnk.IconLocation = iconPath & ",0"
lnk.Description  = "MEO SCAN Label Tool"
lnk.WindowStyle  = 1
lnk.Save

MsgBox "Done! MEO SCAN shortcut created on Desktop.", 64, "MEO SCAN"
