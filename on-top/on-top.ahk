; Win+Shift+F5 — закрепить/снять окно (always on top + opacity + click-through)
; Win+Shift+PgUp/PgDn — изменить opacity (только пока окно закреплено)

#Requires AutoHotkey v2.0
#SingleInstance Force

SetWorkingDir(A_ScriptDir)
A_MenuMaskKey := "vkE8"

pinnedWin := 0
pinnedOpacity := 75 ; процент 5–100

IsPinnedActive() {
    global pinnedWin
    return pinnedWin && WinExist("ahk_id " pinnedWin)
}

#+F5:: {
    global pinnedWin, pinnedOpacity
    SuppressWinMenu()

    ; Если уже есть закреплённое окно — снимаем его
    if IsPinnedActive() {
        WinSetAlwaysOnTop(false, pinnedWin)
        WinSetTransparent("Off", pinnedWin)
        WinSetExStyle("-0x20", pinnedWin)
        pinnedWin := 0
        SoundBeep(720, 90)
        SoundBeep(480, 120)
        return
    }

    ; Иначе закрепляем активное окно
    pinnedWin := WinGetID("A")
    pinnedOpacity := 75
    ApplyOpacity(pinnedWin, pinnedOpacity)
    WinSetAlwaysOnTop(true, pinnedWin)
    WinSetExStyle("+0x20", pinnedWin) ; Пропуск кликов
    SoundBeep(480, 90)
    SoundBeep(720, 120)
}

; Хоткеи opacity активны только при закреплённом окне — иначе сочетание не перехватывается
#HotIf IsPinnedActive()

#+PgUp:: {
    SuppressWinMenu()
    ChangeOpacity(5)
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

#HotIf

; Чтобы Win не открывал Пуск после хоткея
SuppressWinMenu() {
    Send("{Blind}{vkE8}")
}

ChangeOpacity(delta) {
    global pinnedWin, pinnedOpacity
    if !IsPinnedActive()
        return
    newOpacity := Min(100, Max(5, pinnedOpacity + delta))
    if newOpacity = pinnedOpacity
        return
    pinnedOpacity := newOpacity
    ApplyOpacity(pinnedWin, pinnedOpacity)
    ; выше на повышение, ниже на понижение
    SoundBeep(delta > 0 ? 880 : 440, 40)
}

ApplyOpacity(winId, pct) {
    ; 100% → 255 (непрозрачно), 0% → 0
    WinSetTransparent(Round(pct / 100 * 255), winId)
}
