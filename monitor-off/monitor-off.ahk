#Requires AutoHotkey v2.0
#SingleInstance Force
;---

; Pause - Выключить монитор
Pause Up:: {
    SendMessage(0x112, 0xF170, 2, , "Program Manager")
}
