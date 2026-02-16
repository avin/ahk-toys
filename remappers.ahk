#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%
;--------------

; Для gInk (требуется убрать хоткей ctrl+alt+g в google-disk)
^MButton::
    SendInput, {CtrlDown}{AltDown}g{CtrlUp}{AltUp}
Return

; ; Переназначаем F1 на Alt+S только для Google Chrome
; F1::
;     IfWinActive, ahk_exe chrome.exe ; Проверяем, активно ли окно Google Chrome
;     {
;         Send, !s ; Отправляем комбинацию Alt+S
;         Return
;     }
;     else ; Если активное окно не Google Chrome, выполняем стандартное действие для F1
;     {
;         Send, {F1}
;         Return
;     }
