#Requires AutoHotkey v2.0
#SingleInstance Force
#Include UIA.ahk

CoordMode("Mouse", "Screen")

doubleClickTime := DllCall("GetDoubleClickTime", "UInt")
doubleClickHalfWidth := DllCall("GetSystemMetrics", "Int", 36, "Int") / 2
doubleClickHalfHeight := DllCall("GetSystemMetrics", "Int", 37, "Int") / 2
dragWidth := DllCall("GetSystemMetrics", "Int", 68, "Int")
dragHeight := DllCall("GetSystemMetrics", "Int", 69, "Int")
lastTrayClick := false
trayPress := false

#HotIf IsClaudeTrayIconUnderPointer()
*LButton:: {
    global trayPress
    MouseGetPos(&x, &y, &window)
    trayPress := {x: x, y: y, window: window, time: A_TickCount, dragging: false}
    SetTimer(TrackClaudeTrayDrag, 10)
}
#HotIf trayPress
*LButton Up::FinishClaudeTrayPress()
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

TrackClaudeTrayDrag() {
    global trayPress, dragWidth, dragHeight
    Critical()
    MouseGetPos(&x, &y)
    press := trayPress
    if Abs(x - press.x) <= dragWidth && Abs(y - press.y) <= dragHeight
        return

    SetTimer(TrackClaudeTrayDrag, 0)
    press.dragging := true
    ; Replay the press at the icon and let Explorer handle the drag.
    SetMouseDelay(-1)
    SendEvent("{Blind}{Click " press.x " " press.y " 0}{LButton down}{Click " x " " y " 0}")
}

FinishClaudeTrayPress() {
    global trayPress, lastTrayClick, doubleClickTime, doubleClickHalfWidth, doubleClickHalfHeight
    SetTimer(TrackClaudeTrayDrag, 0)
    press := trayPress
    trayPress := false
    if press.dragging {
        lastTrayClick := false
        SendEvent("{Blind}{LButton up}")
        return
    }

    click := lastTrayClick
    if click && press.window = click.window && press.time - click.time <= doubleClickTime
        && Abs(press.x - click.x) <= doubleClickHalfWidth && Abs(press.y - click.y) <= doubleClickHalfHeight {
        lastTrayClick := false
        OpenClaude()
    } else {
        lastTrayClick := press
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
