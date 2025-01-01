#SingleInstance Force
SetBatchLines, -1
SetWinDelay, -1
DetectHiddenWindows, On

; Глобальные переменные
global overlayActive := false
global overlayGui := 0
global hTarget := 0

; Нажимаем Win+I, чтобы включить/выключить белую полупрозрачную маску
#g::
{
    if overlayActive
    {
        ; Если маска уже включена, убираем
        overlayActive := false
        Gui, Destroy
        return
    }

    ; Создаём поверх активного окна
    hTarget := WinExist("A")
    if (!hTarget) {
        return
    }

    overlayActive := true

    ; Создаём окно без рамки, всегда сверху, клики по нему «пробивают» насквозь
    ; WS_EX_LAYERED (0x80000) и WS_EX_TRANSPARENT (0x20) вместе дают «кликабельность сквозь».
    Gui, +LastFound +ToolWindow -Caption +AlwaysOnTop +E0x80000 +E0x20
    Gui, Color, White
    overlayGui := WinExist()

    ; Делаем окно полупрозрачным (25%).
    ; Допустимые значения: 0 (полностью прозрачно) ... 255 (полностью непрозрачно).
    ; Примерно 64 = 25% непрозрачности.
    WinSet, Transparent, 64, ahk_id %overlayGui%

    ; Запускаем цикл для отслеживания изменения позиции окна
    SetTimer, UpdateOverlay, 50
}
return

UpdateOverlay:
{
    if (!overlayActive)
    {
        SetTimer, UpdateOverlay, Off
        return
    }

    ; Проверяем, не закрыли ли целевое окно
    if !WinExist("ahk_id " . hTarget)
    {
        overlayActive := false
        Gui, Destroy
        SetTimer, UpdateOverlay, Off
        return
    }

    ; Получаем координаты целевого окна
    VarSetCapacity(rect, 16, 0)
    if (DllCall("GetWindowRect", "ptr", hTarget, "ptr", &rect))
    {
        left   := NumGet(rect, 0, "int")
        top    := NumGet(rect, 4, "int")
        right  := NumGet(rect, 8, "int")
        bottom := NumGet(rect,12, "int")

        width  := right - left
        height := bottom - top

        ; Если окно не свернуто (h>0, w>0), позиционируем оверлей
        if (width > 0 && height > 0)
        {
            WinMove, ahk_id %overlayGui%,, left, top, width, height
            WinShow, ahk_id %overlayGui%
        }
        else
        {
            WinHide, ahk_id %overlayGui%
        }
    }
}
return

; При выходе из скрипта корректно закрываем всё
Esc::ExitApp
