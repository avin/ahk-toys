#Requires AutoHotkey v2.0
#SingleInstance Force
#Include ..\codex-model-changer\Lib\UIA.ahk

Persistent
SetTitleMatchMode(2)
outlookSelector := " - Outlook ahk_class rctrl_renwnd32 ahk_exe OUTLOOK.EXE"
closeButtons := Map()
RegWrite(1, "REG_DWORD", "HKEY_CURRENT_USER\Software\Microsoft\Office\16.0\Outlook\Preferences", "MinToTray")
if !ProcessExist("OUTLOOK.EXE")
    Run('"C:\Program Files\Microsoft Office\Office16\OUTLOOK.EXE"')
if !WinWait(outlookSelector, , 30) {
    MsgBox("Outlook started, but its main window was not found.", "outlook-to-tray")
    ExitApp()
}
RefreshCloseButtons()
for hwnd in WinGetList(outlookSelector)
    WinMinimize(hwnd)
SetTimer(RefreshCloseButtons, 100)

; Office draws its own caption buttons. Read their rectangles outside the
; mouse hook so calls into Office cannot block delivery of the click.
RefreshCloseButtons() {
    global outlookSelector, closeButtons
    for hwnd in WinGetList(outlookSelector) {
        if WinGetMinMax(hwnd) = -1
            continue
        try {
            button := UIA.ElementFromHandle(hwnd).FindElement({Name: "Закрыть", Type: "Button"})
            rect := button.BoundingRectangle
            if rect.r > rect.l && rect.b > rect.t
                closeButtons[hwnd] := rect
        }
    }
    for hwnd in closeButtons.Clone()
        if !DllCall("IsWindow", "Ptr", hwnd, "Int")
            closeButtons.Delete(hwnd)
}

OutlookCloseUnderPointer() {
    global closeButtons
    point := Buffer(8)
    DllCall("GetCursorPos", "Ptr", point)
    child := DllCall("WindowFromPoint", "Int64", NumGet(point, 0, "Int64"), "Ptr")
    hwnd := DllCall("GetAncestor", "Ptr", child, "UInt", 2, "Ptr")
    if !closeButtons.Has(hwnd)
        return 0
    rect := closeButtons[hwnd]
    x := NumGet(point, 0, "Int")
    y := NumGet(point, 4, "Int")
    return x >= rect.l && x < rect.r && y >= rect.t && y < rect.b ? hwnd : 0
}

#HotIf OutlookCloseUnderPointer()
LButton:: {
    hwnd := OutlookCloseUnderPointer()
    if hwnd
        WinMinimize(hwnd)
}
#HotIf WinActive(outlookSelector)
!F4::WinMinimize("A")
#HotIf
