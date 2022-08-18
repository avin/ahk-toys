#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%
;----------------

lastShift := 0

~LShift Up::
    if ((A_TickCount - lastShift) <= 250)
        Send e

    lastShift := A_TickCount
return
