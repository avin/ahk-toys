; =============================================================================
; on-top — «прозрачное окно поверх всех»
;
; Закрепляет одно окно: always-on-top + полупрозрачность + клики проходят сквозь
; (WS_EX_TRANSPARENT). Повторное закрепление снимает предыдущее, даже если фокус
; уже на другом окне.
;
; Хоткеи:
;   Win+Shift+F5       — закрепить активное / снять закреплённое
;   Win+Shift+PgUp     — opacity +5%  (только пока есть закреплённое окно)
;   Win+Shift+PgDn     — opacity −5%  (иначе сочетание не перехватывается)
;
; Удержание PgUp/PgDn повторяет шаг. Звуки: ↑↓ две ноты на pin/unpin,
; одна нота на смену opacity.
; =============================================================================

#Requires AutoHotkey v2.0
#SingleInstance Force ; одна копия скрипта; перезапуск заменяет старую

SetWorkingDir(A_ScriptDir)
A_MenuMaskKey := "vkE8" ; маска, чтобы Win-хоткеи не открывали меню Пуск

; --- состояние ---
pinnedWin := 0          ; HWND закреплённого окна (0 = ничего не закреплено)
pinnedOpacity := 75     ; текущая прозрачность в % (диапазон 5–100)

; Есть ли живое закреплённое окно?
IsPinnedActive() {
    global pinnedWin
    return pinnedWin && WinExist("ahk_id " pinnedWin)
}

; --- Win+Shift+F5: toggle закрепления ---
#+F5:: {
    global pinnedWin, pinnedOpacity
    SuppressWinMenu()

    ; Уже что-то закреплено → снимаем (независимо от текущего фокуса)
    if IsPinnedActive() {
        WinSetAlwaysOnTop(false, pinnedWin)
        WinSetTransparent("Off", pinnedWin)
        WinSetExStyle("-0x20", pinnedWin) ; убрать click-through
        pinnedWin := 0
        SoundBeep(720, 90)  ; две ноты вниз — выключение
        SoundBeep(480, 120)
        return
    }

    ; Иначе закрепляем окно под фокусом
    pinnedWin := WinGetID("A")
    pinnedOpacity := 75
    ApplyOpacity(pinnedWin, pinnedOpacity)
    WinSetAlwaysOnTop(true, pinnedWin)
    WinSetExStyle("+0x20", pinnedWin) ; click-through: клики идут в окна под ним
    SoundBeep(480, 90)  ; две ноты вверх — включение
    SoundBeep(720, 120)
}

; --- opacity: хоткеи живут только при активном pin ---
#HotIf IsPinnedActive()

#+PgUp:: {
    SuppressWinMenu()
    ChangeOpacity(5)
    ; Короткое нажатие: KeyWait успевает до таймаута → выход
    ; Удержание: после 0.3 с крутим шаг, пока клавиша зажата
    if KeyWait("PgUp", "T0.3") {
        SuppressWinMenu()
        return
    }
    while GetKeyState("PgUp", "P") {
        if !IsPinnedActive()
            break
        ChangeOpacity(5)
        Sleep(100)
    }
    SuppressWinMenu()
}

#+PgDn:: {
    SuppressWinMenu()
    ChangeOpacity(-5)
    if KeyWait("PgDn", "T0.3") {
        SuppressWinMenu()
        return
    }
    while GetKeyState("PgDn", "P") {
        if !IsPinnedActive()
            break
        ChangeOpacity(-5)
        Sleep(100)
    }
    SuppressWinMenu()
}

#HotIf ; снять условие — дальше обычные хоткеи/код

; Погасить «одиночный Win» после хоткея (иначе Windows открывает Пуск)
SuppressWinMenu() {
    Send("{Blind}{vkE8}")
}

; Сдвиг opacity на delta процентов (±5) с клампом и звуком
ChangeOpacity(delta) {
    global pinnedWin, pinnedOpacity
    if !IsPinnedActive()
        return
    newOpacity := Min(100, Max(5, pinnedOpacity + delta))
    if newOpacity = pinnedOpacity
        return ; упирались в край диапазона — ничего не делаем
    pinnedOpacity := newOpacity
    ApplyOpacity(pinnedWin, pinnedOpacity)
    SoundBeep(delta > 0 ? 880 : 440, 40) ; выше = +, ниже = −
}

; Процент 0–100 → WinSetTransparent 0–255 (255 = полностью непрозрачно)
ApplyOpacity(winId, pct) {
    WinSetTransparent(Round(pct / 100 * 255), winId)
}
