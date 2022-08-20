#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%
;----------------

;Добавляем пункт в тей меню для раскрытия окна по клику иконки в трее
Menu, Tray, Add, Show Gui, restore
Menu, Tray, Default, Show Gui
Menu, Tray, Click, 1

;Gui +HwndGuiHwnd
Gui, Font, s15, Consolas
Gui, Add, Edit, w600 Multi r5 -WantReturn vEditContents
;Скрытая кнопка нужна для сабмита формы
Gui, Add, Button, x-10 y-10 w1 h1 +default gGetContents
Gui, +AlwaysOnTop
Gui, +hwndWINID
;Чтоб скрыть крестик закрытия окна
Gui, -SysMenu

;Counter-ы для отслеживания смены состояний скрипта
global lastShift := 1
global isWinActive := 0
global vCtrlF := 0
global vCtrlWithFocus := 0

Return

;Показать окно с gui
restore(){
    isWinActive := 1
    Gui Show,,Notes
    GuiControl Focus, EditContents

    ; Сделим за потерей фокуса и хайдим окно если фокус пропал
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

;Скрыть gui-окно
hide() {
    isWinActive := 0
    SetTimer,TAB,Off
    Gui Hide
}

;По двойному нажатия Ctrl показываем окно
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

;При нажатии Esc только когда открыто окно gui - скрываем его
#IfWinActive, ahk_class AutoHotkeyGUI
~Escape::
    hide()
Return

;Сделать запись в файл (при этом создав папку если нету)
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

;Действие на сабмите по скрытой кнопке, инициализирует процесс записи текста из edit-а в файл
GetContents:
    Gui, Submit, NoHide
    WriteNoteToFile(EditContents)
    GuiControl,,EditContents,
    Gui, hide
Return

GuiClose:
ExitApp
Return
