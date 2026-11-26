#Requires AutoHotkey v2.0
#SingleInstance Force
#Include UIA.ahk

CoordMode("Mouse", "Screen")

doubleClickTime := DllCall("GetDoubleClickTime", "UInt")
doubleClickHalfWidth := DllCall("GetSystemMetrics", "Int", 36, "Int") / 2
doubleClickHalfHeight := DllCall("GetSystemMetrics", "Int", 37, "Int") / 2
lastTrayClick := false

#HotIf IsClaudeTrayIconUnderPointer()
*LButton::HandleClaudeTrayClick()
#HotIf

~*LButton:: {
    global lastTrayClick
    lastTrayClick := false
}

IsClaudeTrayIconUnderPointer() {
    MouseGetPos(&x, &y, &window, &control, 2)
    try {
        if !control || WinGetClass(control) != "ToolbarWindow32"
            return false
        if !RegExMatch(WinGetClass(window), "^(Shell_(Secondary)?TrayWnd|NotifyIconOverflowWindow)$")
            return false

        icon := UIA.ElementFromPoint(x, y, , 0)
        return icon.Name = "Claude" && icon.Type = UIA.Type.Button
    }
    return false
}

HandleClaudeTrayClick() {
    global lastTrayClick, doubleClickTime, doubleClickHalfWidth, doubleClickHalfHeight
    clickedAt := A_TickCount
    MouseGetPos(&x, &y, &window)
    click := lastTrayClick
    if click && window = click.window && clickedAt - click.time <= doubleClickTime
        && Abs(x - click.x) <= doubleClickHalfWidth && Abs(y - click.y) <= doubleClickHalfHeight {
        lastTrayClick := false
        KeyWait("LButton")
        OpenClaude()
    } else {
        lastTrayClick := {x: x, y: y, window: window, time: clickedAt}
    }
}

OpenClaude() {
    ; Both Claude windows have the same title. Only the main window has WS_THICKFRAME.
    DetectHiddenWindows(true)
    mainWindow := 0
    for hwnd in WinGetList("Claude ahk_class Chrome_WidgetWin_1 ahk_exe claude.exe") {
        if WinGetStyle(hwnd) & 0x40000 {
            mainWindow := hwnd
            break
        }
    }
    DetectHiddenWindows(false)

    Run("shell:AppsFolder\Claude_pzs8sxrjxfjjc!Claude")
    if mainWindow && WinWait(mainWindow, , 2)
        WinActivate(mainWindow)
}
