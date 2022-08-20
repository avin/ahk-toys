#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%
;----------------

;��������� ����� � ��� ���� ��� ��������� ���� �� ����� ������ � ����
Menu, Tray, Add, Show Gui, restore
Menu, Tray, Default, Show Gui
Menu, Tray, Click, 1

;Gui +HwndGuiHwnd
Gui, Font, s15, Consolas
Gui, Add, Edit, w600 Multi r5 -WantReturn vEditContents
;������� ������ ����� ��� ������� �����
Gui, Add, Button, x-10 y-10 w1 h1 +default gGetContents
Gui, +AlwaysOnTop
Gui, +hwndWINID
;���� ������ ������� �������� ����
Gui, -SysMenu

;Counter-� ��� ������������ ����� ��������� �������
global lastShift := 1
global isWinActive := 0
global vCtrlF := 0
global vCtrlWithFocus := 0

Return

;�������� ���� � gui
restore(){
    isWinActive := 1
    Gui Show,,Notes
    GuiControl Focus, EditContents

    ; ������ �� ������� ������ � ������ ���� ���� ����� ������
    GuiControlGet, vCtrlWithFocus, FocusV
    SetTimer,TAB,100
}

TAB:
    Sleep, 100
    GuiControlGet, vCtrlF, FocusV
    if(vCtrlF!=vCtrlWithFocus){
        hide()
    }
Return

;������ gui-����
hide() {
    isWinActive := 0
    SetTimer,TAB,Off
    Gui Hide
}

;�� �������� ������� Ctrl ���������� ����
~RCtrl Up::
    diff := A_TickCount - lastShift
    if (diff <= 250){
        restore()
    }
    lastShift := A_TickCount
return

#Space::
    restore()
return

; XButton1::
;     restore()
; Return

;��� ������� Esc ������ ����� ������� ���� gui - �������� ���
#IfWinActive, ahk_class AutoHotkeyGUI
~Escape::
    hide()
Return

;������� ������ � ���� (��� ���� ������ ����� ���� ����)
WriteNoteToFile(content)
{
    FormatTime, Time,, HH:mm:ss
    FormatTime, Date,, yyyy-MM-dd
    FormatTime, MonthDate,, yyyy-MM

    dir:="C:\tmp\notes\" MonthDate
    If !FileExist(dir) {
        FileCreateDir, %dir%
    }

    FileAppend, [%Time%]`n%content%`n`n`n, %dir%\%Date% - %A_DDDD%.txt
}

;�������� �� ������� �� ������� ������, �������������� ������� ������ ������ �� edit-� � ����
GetContents:
    Gui, Submit, NoHide
    WriteNoteToFile(EditContents)
    GuiControl,,EditContents,
    Gui, hide
Return

GuiClose:
ExitApp
Return
