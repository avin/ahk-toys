#SingleInstance Force
SetBatchLines, -1
SetWinDelay, -1
DetectHiddenWindows, On

; Глобальные переменные
global overlayActive := false
global overlayGui := 0
global hTarget := 0
global transparency := LoadTransparency() ; Загружаем сохранённую прозрачность

; Константы
MIN_TRANSPARENCY := 10
MAX_TRANSPARENCY := 255
STEP := 5 ; ~2% от 255

; Win+G — включить/выключить оверлей
#g::
{
    if overlayActive
    {
        overlayActive := false
        Gui, Destroy
        SetTimer, UpdateOverlay, Off
        return
    }

    hTarget := WinExist("A")
    if (!hTarget) {
        return
    }

    overlayActive := true

    Gui, +LastFound +ToolWindow -Caption +AlwaysOnTop +E0x80000 +E0x20
    Gui, Color, White
    overlayGui := WinExist()

    WinSet, Transparent, %transparency%, ahk_id %overlayGui%
    SetTimer, UpdateOverlay, 50
}
return

; Увеличить прозрачность (Win+9)
#9::
{
    transparency += STEP
    if (transparency > MAX_TRANSPARENCY)
        transparency := MAX_TRANSPARENCY

    SaveTransparency(transparency)
    if (overlayActive)
        WinSet, Transparent, %transparency%, ahk_id %overlayGui%
}
return

; Уменьшить прозрачность (Win+8)
#8::
{
    transparency -= STEP
    if (transparency < MIN_TRANSPARENCY)
        transparency := MIN_TRANSPARENCY

    SaveTransparency(transparency)
    if (overlayActive)
        WinSet, Transparent, %transparency%, ahk_id %overlayGui%
}
return

UpdateOverlay:
{
    if (!overlayActive)
    {
        SetTimer, UpdateOverlay, Off
        return
    }

    if !WinExist("ahk_id " . hTarget)
    {
        overlayActive := false
        Gui, Destroy
        SetTimer, UpdateOverlay, Off
        return
    }

    VarSetCapacity(rect, 16, 0)
    if (DllCall("GetWindowRect", "ptr", hTarget, "ptr", &rect))
    {
        left   := NumGet(rect, 0, "int")
        top    := NumGet(rect, 4, "int")
        right  := NumGet(rect, 8, "int")
        bottom := NumGet(rect,12, "int")

        width  := right - left
        height := bottom - top

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

; --- Хелперы для работы с реестром ---

SaveTransparency(val)
{
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\MyOverlayTool, Transparency, %val%
}

LoadTransparency()
{
    RegRead, val, HKEY_CURRENT_USER\Software\MyOverlayTool, Transparency
    if (ErrorLevel || val = "")
        return 64 ; Значение по умолчанию (~25%)
    return val
}
