; Win+Shift+F5 — закрепить/снять окно (always on top + opacity + click-through)
; Win+Shift+PgUp/PgDn — изменить opacity (только пока окно закреплено)

pinnedWin := 0
pinnedOpacity := 75 ; процент 5–100

#+F5::
global pinnedWin, pinnedOpacity

; Если уже есть закреплённое окно — снимаем его
if (pinnedWin && WinExist("ahk_id " . pinnedWin)) {
    WinSet, AlwaysOnTop, OFF, ahk_id %pinnedWin%
    WinSet, Transparent, OFF, ahk_id %pinnedWin%
    WinSet, ExStyle, -0x20, ahk_id %pinnedWin%
    pinnedWin := 0
    SoundBeep, 720, 90
    SoundBeep, 480, 120
    return
}

; Иначе закрепляем активное окно
WinGet, id1, ID, A
pinnedOpacity := 75
ApplyOpacity(id1, pinnedOpacity)
WinSet, AlwaysOnTop, ON, ahk_id %id1%
WinSet, ExStyle, +0x20, ahk_id %id1% ; Пропуск кликов
pinnedWin := id1
SoundBeep, 480, 90
SoundBeep, 720, 120
return

; Хоткеи opacity активны только при закреплённом окне — иначе сочетание не перехватывается
#If pinnedWin && WinExist("ahk_id " . pinnedWin)

#+PgUp::
ChangeOpacity(5)
KeyWait, PgUp, T0.3
if (ErrorLevel = 0)
    return
While GetKeyState("PgUp", "P") {
    if (!(pinnedWin && WinExist("ahk_id " . pinnedWin)))
        break
    ChangeOpacity(5)
    Sleep, 100
}
return

#+PgDn::
ChangeOpacity(-5)
KeyWait, PgDn, T0.3
if (ErrorLevel = 0)
    return
While GetKeyState("PgDn", "P") {
    if (!(pinnedWin && WinExist("ahk_id " . pinnedWin)))
        break
    ChangeOpacity(-5)
    Sleep, 100
}
return

#If

ChangeOpacity(delta) {
    global pinnedWin, pinnedOpacity
    if (!(pinnedWin && WinExist("ahk_id " . pinnedWin)))
        return
    newOpacity := pinnedOpacity + delta
    if (newOpacity > 100)
        newOpacity := 100
    if (newOpacity < 5)
        newOpacity := 5
    if (newOpacity = pinnedOpacity)
        return
    pinnedOpacity := newOpacity
    ApplyOpacity(pinnedWin, pinnedOpacity)
    ; выше на повышение, ниже на понижение
    if (delta > 0)
        SoundBeep, 880, 40
    else
        SoundBeep, 440, 40
}

ApplyOpacity(winId, pct) {
    ; 100% → 255 (непрозрачно), 0% → 0
    level := Round(pct / 100 * 255)
    WinSet, Transparent, %level%, ahk_id %winId%
}
