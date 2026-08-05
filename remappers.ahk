#Requires AutoHotkey v2.0
#SingleInstance Force
SendMode "Input"
SetWorkingDir A_ScriptDir
;--------------

; Одиночное нажатие RCtrl → Alt+Ctrl+Shift+Q
~RCtrl Up:: {
    if (A_PriorKey = "RControl")
        SendInput "^!+q"
}

; ; Для gInk (требуется убрать хоткей ctrl+alt+g в google-disk)
; ^MButton:: {
;     SendInput "{Ctrl down}{Alt down}g{Ctrl up}{Alt up}"
; }

; ; Переназначаем F1 на Alt+S только для Google Chrome
; F1:: {
;     if WinActive("ahk_exe chrome.exe") {
;         Send "!s"
;     } else {
;         Send "{F1}"
;     }
; }
