; Ctrl+Space. Поднимает окно на верх и делает ему opacity 75%
^SPACE::
WinGet, id1, ID, A

WinGet, ExStyle, ExStyle, ahk_id %id1%
if (ExStyle & 0x20) {
    ; Если свойства включены, отключаем их
    WinSet, AlwaysOnTop, OFF, ahk_id %id1%
    WinSet, Transparent, OFF, ahk_id %id1%
    WinSet, ExStyle, -0x20, ahk_id %id1%
} else {
    ; Если свойства выключены, включаем их
    WinSet, AlwaysOnTop, ON, ahk_id %id1%
    WinSet, Transparent, 192, ahk_id %id1% ; Прозрачность 75%
    WinSet, ExStyle, +0x20, ahk_id %id1% ; Пропуск кликов
}
