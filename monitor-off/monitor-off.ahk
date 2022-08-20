#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%
;---

; Pause - Выключить монитор
Pause Up::SendMessage,0x112,0xF170,2,,Program Manager
