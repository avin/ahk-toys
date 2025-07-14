#NoEnv
#SingleInstance Force
SetWorkingDir %A_ScriptDir%
CoordMode, Mouse, Screen

; ���������� ��� �������� ���������
global ButtonHwnd := 0
global CurrentWindow := 0

; ������ ������ ��� ������������ �������� ����
SetTimer, CheckActiveWindow, 100

; �������� ������� ������������
CheckActiveWindow:
    WinGet, ActiveHwnd, ID, A
    WinGetTitle, ActiveTitle, ahk_id %ActiveHwnd%

    ; ���������, ���������� �� ��������� � "TurboWin"
    if (InStr(ActiveTitle, "TurboWin") = 1)
    {
        ; ���� ��� ����� ���� TurboWin ��� ���� ����������
        if (ActiveHwnd != CurrentWindow)
        {
            CurrentWindow := ActiveHwnd
            CreateFloatingButton()
        }
        else
        {
            ; ��������� ������� ������, ���� ���� �������������
            UpdateButtonPosition()
        }
    }
    else
    {
        ; ���� �������� ���� �� TurboWin, �������� ������
        if (ButtonHwnd)
        {
            Gui, FloatingButton:Hide
            CurrentWindow := 0
        }
    }
return

; �������� ��������� ������
CreateFloatingButton()
{
    ; ���������� ���������� ������, ���� ��� ����������
    if (ButtonHwnd)
    {
        Gui, FloatingButton:Destroy
    }

    ; ������ ����� GUI ���� ��� ������
    Gui, FloatingButton:New, +AlwaysOnTop -Caption +ToolWindow +Owner%CurrentWindow% +HwndButtonHwnd
    Gui, FloatingButton:Color, 0x2196F3
    Gui, FloatingButton:Font, s10 cWhite Bold
    Gui, FloatingButton:Add, Text, x0 y0 w100 h20 Center gButtonClick, Generate OTP

    ; ������������� ��������� �������
    UpdateButtonPosition()

    ; ���������� ������
    Gui, FloatingButton:Show, NoActivate
}

; ���������� ������� ������
UpdateButtonPosition()
{
    if (!ButtonHwnd || !CurrentWindow)
        return

    ; �������� ������� ���� TurboWin
    WinGetPos, WinX, WinY, WinWidth, WinHeight, ahk_id %CurrentWindow%

    ; ���������, ��� ���� ���������� � ������
    if (WinX = "" || WinY = "")
        return

    ; ������������� ������ �� ������ ������ ����
    ButtonX := WinX + (WinWidth - 100) // 2
    ButtonY := WinY - 20

    ; ���������� ������
    Gui, FloatingButton:Show, x%ButtonX% y%ButtonY% w100 h20 NoActivate
}

; ���������� ����� �� ������
ButtonClick:
    ; ��������� ������
    Run, C:\utils\otp\run.bat, C:\utils\otp\, Hide
return

; ��������� ����������� ���� ��� ������� ���������
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

; ����� �� �������
^Esc::ExitApp
