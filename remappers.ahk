#Requires AutoHotkey v2.0
#SingleInstance Force
SendMode "Input"
SetWorkingDir A_ScriptDir
;--------------

; Одиночное нажатие RCtrl → Alt+Ctrl+Shift+Q
~RCtrl Up:: {
    if (A_PriorKey = "RControl")
        SendInput "^!+q"
}

; Pause → Ctrl+Alt+Shift+W
Pause::SendInput "^!+w"
