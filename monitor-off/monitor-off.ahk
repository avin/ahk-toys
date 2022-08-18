#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%
;---

; Win+F1 Выключить монитор
#F1::SendMessage,0x112,0xF170,2,,Program Manager
