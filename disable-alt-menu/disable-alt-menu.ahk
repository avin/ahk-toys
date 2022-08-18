#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%
;---

Alt::
    KeyWait, Alt
return

LAlt Up::
    if (A_PriorKey = "Alt")
        return
return
