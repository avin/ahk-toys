#Requires AutoHotkey v2.0
#SingleInstance Force

SetTitleMatchMode "Fast"

#HotIf WinActive("Ableton Live")
MButton::
{
    Send("{Ctrl down}{Alt down}{LButton down}")
    KeyWait("MButton")
    Send("{LButton up}{Alt up}{Ctrl up}")
}
#HotIf
