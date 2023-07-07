#NoEnv
#SingleInstance, Force
SendMode, Input
SetBatchLines, -1
SetWorkingDir, %A_ScriptDir%

#If WinActive("ahk_class Chrome_WidgetWin_1")
  ~LButton::
    if (A_TimeSincePriorHotkey < 400) and (A_TimeSincePriorHotkey <> -1)
      MouseMove, 1, 0, 0, R
    return
#If
