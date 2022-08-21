#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%
;--------------

; Для gInk (требуется убрать хоткей ctrl+alt+g в google-disk)
^MButton::
    SendInput, {CtrlDown}{AltDown}g{CtrlUp}{AltUp}
Return
