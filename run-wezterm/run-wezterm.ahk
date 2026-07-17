#Requires AutoHotkey v2.0
#SingleInstance Force

Persistent
DetectHiddenWindows true

weztermExe := "C:\Program Files\WezTerm\wezterm-gui.exe"
weztermClass := "ahk-wezterm-dropdown"
weztermWindow := 0
registryKey := "HKEY_CURRENT_USER\Software\ahk-toys\run-wezterm"
lastWindowGeometry := ""
trackWindowGeometry := true

StartWezTerm(false)
SetTimer(WatchWezTermWindow, 100)

!Space::ToggleWezTerm()

WatchWezTermWindow() {
    global weztermWindow, trackWindowGeometry

    if !IsWindow(weztermWindow)
        return

    if DllCall("IsWindowVisible", "Ptr", weztermWindow, "Int")
        && DllCall("IsIconic", "Ptr", weztermWindow, "Int")
        WinHide("ahk_id " weztermWindow)
    else if trackWindowGeometry
        RememberWindowGeometry()
}

ToggleWezTerm() {
    global weztermWindow

    if !IsWindow(weztermWindow) {
        StartWezTerm(true)
        return
    }

    if DllCall("IsWindowVisible", "Ptr", weztermWindow, "Int") {
        if WinActive("ahk_id " weztermWindow)
            WinHide("ahk_id " weztermWindow)
        else
            WinActivate("ahk_id " weztermWindow)
        return
    }

    WinShow("ahk_id " weztermWindow)

    if WinGetMinMax("ahk_id " weztermWindow) = -1
        WinRestore("ahk_id " weztermWindow)

    WinActivate("ahk_id " weztermWindow)
}

StartWezTerm(showAfterStart := false) {
    global weztermExe, weztermClass, weztermWindow, trackWindowGeometry

    if !FileExist(weztermExe) {
        MsgBox("WezTerm not found:`n" weztermExe, "run-wezterm")
        return false
    }

    selector := "ahk_class " weztermClass " ahk_exe wezterm-gui.exe"

    if WinExist(selector) {
        weztermWindow := WinExist(selector)
        RememberWindowGeometry()
        if !showAfterStart
            WinHide("ahk_id " weztermWindow)
        return true
    }

    command := '"' weztermExe '" start --always-new-process --class ' weztermClass
    trackWindowGeometry := false

    try Run(command, , "Hide")
    catch as error {
        trackWindowGeometry := true
        MsgBox("Could not start WezTerm:`n" error.Message, "run-wezterm")
        return false
    }

    weztermWindow := WinWait(selector, , 10)

    if !weztermWindow {
        trackWindowGeometry := true
        MsgBox("WezTerm started, but its window was not found.", "run-wezterm")
        return false
    }

    RestoreWindowGeometry()
    trackWindowGeometry := true

    if showAfterStart {
        WinShow("ahk_id " weztermWindow)
        WinActivate("ahk_id " weztermWindow)
    } else {
        WinHide("ahk_id " weztermWindow)
    }

    return true
}

RememberWindowGeometry() {
    global weztermWindow, registryKey, lastWindowGeometry

    if !IsWindow(weztermWindow)
        || !DllCall("IsWindowVisible", "Ptr", weztermWindow, "Int")
        || DllCall("IsIconic", "Ptr", weztermWindow, "Int")
        || DllCall("IsZoomed", "Ptr", weztermWindow, "Int")
        return

    try WinGetPos(&x, &y, &width, &height, "ahk_id " weztermWindow)
    catch
        return

    if width <= 0 || height <= 0
        return

    geometry := x "|" y "|" width "|" height
    if geometry = lastWindowGeometry
        return

    try RegWrite(geometry, "REG_SZ", registryKey, "Geometry")
    catch
        return

    lastWindowGeometry := geometry
}

RestoreWindowGeometry() {
    global weztermWindow, registryKey, lastWindowGeometry

    geometry := RegRead(registryKey, "Geometry", "")
    if !RegExMatch(geometry, "^-?\d+\|-?\d+\|\d+\|\d+$")
        return

    dimensions := StrSplit(geometry, "|")
    x := Number(dimensions[1])
    y := Number(dimensions[2])
    width := Number(dimensions[3])
    height := Number(dimensions[4])

    if width <= 0 || height <= 0
        return

    try WinMove(x, y, width, height, "ahk_id " weztermWindow)
    catch
        return

    lastWindowGeometry := geometry
}

IsWindow(hwnd) {
    return hwnd && DllCall("IsWindow", "Ptr", hwnd, "Int")
}
