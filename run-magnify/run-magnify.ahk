#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%
;----------------

#F9:: ; Win+F9
    Process, Exist, Magnify.exe

    If (ErrorLevel) {
        Send, #{Esc}
    } Else {
        Run, Magnify.exe
    }
return
