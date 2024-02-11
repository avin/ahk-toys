#Requires AutoHotkey v2.0
#SingleInstance Force
;---

; Win+F9 - запуск Экранной лупы
#F9:: {
    if (PID := ProcessExist("Magnify.exe")) {
        Send("#{Esc}")
    } else {
        Run("magnify.exe")
    }
}

; Win+F10 - запуск Экранной клавиатуры
#F10:: {
    if (PID := ProcessExist("osk.exe")) {
        SendInput("#^o")
    } Else {
        Run("osk.exe")
    }
}

; Win+F11 - Смена раскладки
#F11:: {
    if (GetKeyboardLanguage(WinActive("A")) = 0x0409) {
        SetDefaultKeyboard(0x0419) ; Russian
    } else {
        SetDefaultKeyboard(0x0409) ; english-US
    }
}

SetDefaultKeyboard(localeID) {
    static SPI_SETDEFAULTINPUTLANG := 0x005A
    static SPIF_SENDWININICHANGE := 2

    Lan := DllCall("LoadKeyboardLayout", "Str", Format("{:08x}", LocaleID), "Int", 0)
    binaryLocaleID := Buffer(4, 0)
    NumPut("UInt", LocaleID, binaryLocaleID)
    DllCall("SystemParametersInfo", "UInt", SPI_SETDEFAULTINPUTLANG, "UInt", 0, "Ptr", binaryLocaleID, "UInt", SPIF_SENDWININICHANGE)
    for hwnd in WinGetList() {
        try {
            PostMessage 0x50, 0, Lan, , hwnd
        }
    }
}

GetKeyboardLanguage(_hWnd := 0) {
    if !_hWnd {
        ThreadId := 0
    } else {
        if !ThreadId := DllCall("user32.dll\GetWindowThreadProcessId", "Ptr", _hWnd, "UInt", 0, "UInt") {
            return false
        }
    }

    if !KBLayout := DllCall("user32.dll\GetKeyboardLayout", "UInt", ThreadId, "UInt") {
        return false
    }

    return KBLayout & 0xFFFF
}
