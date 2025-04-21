#Requires AutoHotkey v2.0
#SingleInstance Force

SetTitleMatchMode "Fast"

#HotIf WinActive("Ableton Live")
; Snap drag with mouse wheel
MButton::
{
    Send("{Ctrl down}{Alt down}{LButton down}")
    KeyWait("MButton")
    Send("{LButton up}{Alt up}{Ctrl up}")
}

; Remap Ctrl+Shift+Z to Ctrl+Y (Redo)
^+z::Send("^y")
#HotIf
