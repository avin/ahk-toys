#Requires AutoHotkey v2.0
#SingleInstance Force

lastHwnd := 0

SetTimer(CheckActiveWindow, 100)

CheckActiveWindow() {
    global lastHwnd

    hwnd := WinExist("A")
    if !hwnd
        return

    if hwnd = lastHwnd
        return

    lastHwnd := hwnd

    try processName := WinGetProcessName("ahk_id " hwnd)
    catch
        return

    if processName ~= "i)^(webstorm64\.exe|webstrom64\.exe)$" {
        SetTimer(SendWebStormHotkey, -200)
    }
}

SendWebStormHotkey() {
    hwnd := WinExist("A")
    if !hwnd
        return

    try processName := WinGetProcessName("ahk_id " hwnd)
    catch
        return

    if processName ~= "i)^(webstorm64\.exe|webstrom64\.exe)$" {
        Send "^!y"
    }
}
