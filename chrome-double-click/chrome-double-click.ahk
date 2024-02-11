#Requires AutoHotkey v2.0
#SingleInstance Force


#HotIf WinActive("ahk_class Chrome_WidgetWin_1")
~LButton::
{
    if (ThisHotkey = A_PriorHotkey && A_TimeSincePriorHotkey < 400) {
        MouseMove(1, 0, 0, "R")
    }
}
