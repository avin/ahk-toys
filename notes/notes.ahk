#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%
;----------------

global lastShift := 1
global isWinActive := 0
global vCtrlF := 0
global vCtrlWithFocus := 0
global rootDir := A_MyDocuments . "\notes\"

;Добавляем пункт в тей меню для раскрытия окна по клику иконки в трее
Menu, Tray, Add, Show Gui, restore
Menu, Tray, Default, Show Gui
Menu, Tray, Click, 1

Gui, Margin, 8, 8
Gui, Font, s15, Consolas
Gui, Add, Edit, w600 Multi r5 -WantReturn vEditContents
;Скрытая кнопка нужна для сабмита формы
Gui, Add, Button, x-10 y-10 w1 h1 +default gGetContents
Gui, +hwndMainWinHwnd -SysMenu +AlwaysOnTop

restore()
hide()

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
    if(vCtrlF!=vCtrlWithFocus) {
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
    if (diff <= 250) {
        restore()
    }
    lastShift := A_TickCount
return

#Space::
    if isWinActive {
        hide()
    } else {
        restore()
    }

return

;При нажатии Esc только когда открыто окно gui - скрываем его
#IfWinActive, ahk_class AutoHotkeyGUI
~Escape::
    hide()
Return

#IfWinActive, ahk_class AutoHotkeyGUI
^e::
    filePath:=GetFilePath()
    Run, notepad.exe %filePath%
    hide()
Return

GetDirPath(){
    FormatTime, MonthDate,, yyyy-MM

    dirPath := rootDir . MonthDate
    OutputDebug, % dirPath

return dirPath
}

GetFilePath(){
    FormatTime, Date,, yyyy-MM-dd
    dirPath := GetDirPath()
    filePath := dirPath . "\" . Date . " - " . A_DDDD . ".txt"
return filePath
}

;Сделать запись в файл (при этом создав папку если нету)
WriteNoteToFile(content)
{
    FormatTime, Time,, HH:mm:ss

    dirPath:=GetDirPath()
    If !FileExist(dirPath) {
        FileCreateDir, %dirPath%
    }

    filePath:=GetFilePath()

    FileAppend, [%Time%]`n%content%`n`n`n, %filePath%
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
