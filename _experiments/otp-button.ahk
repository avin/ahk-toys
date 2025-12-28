#NoEnv
#SingleInstance Force
SetWorkingDir %A_ScriptDir%
CoordMode, Mouse, Screen

global ButtonHwnd := 0
global CurrentWindow := 0

SetTimer, CheckActiveWindow, 100

CheckActiveWindow:
    WinGet, ActiveHwnd, ID, A
    WinGetTitle, ActiveTitle, ahk_id %ActiveHwnd%

    if (InStr(ActiveTitle, "TurboWin") = 1)
    {
        if (ActiveHwnd != CurrentWindow)
        {
            CurrentWindow := ActiveHwnd
            CreateFloatingButton()
        }
        else
        {
            UpdateButtonPosition()
        }
    }
    else
    {
        if (ButtonHwnd)
        {
            Gui, FloatingButton:Hide
            CurrentWindow := 0
        }
    }
return

CreateFloatingButton()
{
    if (ButtonHwnd)
    {
        Gui, FloatingButton:Destroy
    }

    Gui, FloatingButton:New, +AlwaysOnTop -Caption +ToolWindow +Owner%CurrentWindow% +HwndButtonHwnd
    Gui, FloatingButton:Color, 0x2196F3
    Gui, FloatingButton:Font, s10 cWhite Bold
    Gui, FloatingButton:Add, Text, x0 y0 w100 h20 Center gButtonClick, Generate OTP

    UpdateButtonPosition()

    Gui, FloatingButton:Show, NoActivate
}

UpdateButtonPosition()
{
    if (!ButtonHwnd || !CurrentWindow)
        return

    WinGetPos, WinX, WinY, WinWidth, WinHeight, ahk_id %CurrentWindow%

    if (WinX = "" || WinY = "")
        return

    ButtonX := WinX + (WinWidth - 110)
    ButtonY := WinY + 30

    Gui, FloatingButton:Show, x%ButtonX% y%ButtonY% w100 h20 NoActivate
}

ButtonClick:
    Run, C:\utils\otp\run.bat, C:\utils\otp\
return

#If (ButtonHwnd)
~LButton::
    MouseGetPos, , , WinUnderMouse
    if (WinUnderMouse = ButtonHwnd)
    {
        Gui, FloatingButton:Color, 0x1976D2
        SetTimer, RestoreButtonColor, 100
    }
return

RestoreButtonColor:
    SetTimer, RestoreButtonColor, Off
    MouseGetPos, , , WinUnderMouse
    if (WinUnderMouse != ButtonHwnd)
    {
        Gui, FloatingButton:Color, 0x2196F3
    }
return
#If

^Esc::ExitApp
