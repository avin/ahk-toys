#Requires AutoHotkey v2.0
#SingleInstance Force

Persistent
DetectHiddenWindows true

weztermExe := "C:\Program Files\WezTerm\wezterm-gui.exe"
weztermClass := "ahk-wezterm-dropdown"
weztermWindow := 0

StartWezTerm(false)

!Space::ToggleWezTerm()

ToggleWezTerm() {
    global weztermWindow

    if !IsWindow(weztermWindow) {
        if !StartWezTerm(true)
            return
    }

    if DllCall("IsWindowVisible", "Ptr", weztermWindow, "Int") {
        WinHide("ahk_id " weztermWindow)
        return
    }

    WinShow("ahk_id " weztermWindow)

    if WinGetMinMax("ahk_id " weztermWindow) = -1
        WinRestore("ahk_id " weztermWindow)

    WinActivate("ahk_id " weztermWindow)
}

StartWezTerm(showAfterStart := false) {
    global weztermExe, weztermClass, weztermWindow

    if !FileExist(weztermExe) {
        MsgBox("WezTerm not found:`n" weztermExe, "run-wezterm")
        return false
    }

    selector := "ahk_class " weztermClass " ahk_exe wezterm-gui.exe"

    if WinExist(selector) {
        weztermWindow := WinExist(selector)
        if !showAfterStart
            WinHide("ahk_id " weztermWindow)
        return true
    }

    command := '"' weztermExe '" start --always-new-process --class ' weztermClass

    try Run(command, , "Hide")
    catch as error {
        MsgBox("Could not start WezTerm:`n" error.Message, "run-wezterm")
        return false
    }

    weztermWindow := WinWait(selector, , 10)

    if !weztermWindow {
        MsgBox("WezTerm started, but its window was not found.", "run-wezterm")
        return false
    }

    if showAfterStart {
        WinShow("ahk_id " weztermWindow)
        WinActivate("ahk_id " weztermWindow)
    } else {
        WinHide("ahk_id " weztermWindow)
    }

    return true
}

IsWindow(hwnd) {
    return hwnd && DllCall("IsWindow", "Ptr", hwnd, "Int")
}
