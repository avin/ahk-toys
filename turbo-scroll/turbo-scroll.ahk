#NoEnv
#SingleInstance, Force
SendMode, Input
SetBatchLines, -1
SetWorkingDir, %A_ScriptDir%



$rbutton::
    KeyWait, rbutton, T0.2
    If ErrorLevel
    {
        rbutton & wheelup::
        Sendinput, {WheelUp 4}
        return

        rbutton & wheeldown::
        Sendinput, {WheelDown 4}
        return
    }

    Click Right
Return
