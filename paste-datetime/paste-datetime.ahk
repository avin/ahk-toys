#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%
;--------

#t::
    FormatTime, T, %A_Now%, yyyy-MM-dd_hh-mm-ss
    SendInput, %T%
return
