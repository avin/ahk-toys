#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%
;---

Gui, Add, Edit, w200 h40 -WantReturn vEditContents
Gui, Add, Button, x-10 y-10 w1 h1 +default gGetContents
Gui Show
Return

GetContents:
    Gui, Submit, NoHide
    MsgBox % EditContents
Return

GuiClose:
ExitApp
Return
