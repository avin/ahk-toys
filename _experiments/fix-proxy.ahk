#SingleInstance Force
#Persistent   ; держать скрипт запущенным в фоне

SetTimer, ApplyProxy, 10000   ; каждые 10 секунд
ApplyProxy:                   ; вызывается и по таймеру, и при старте
    ; Включить прокси и задать параметры
    ; ProxyEnable = 1 (DWORD)
    RegWrite, REG_DWORD, HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings, ProxyEnable, 1

    ; ProxyServer = "127.0.0.1:7890"
    RegWrite, REG_SZ, HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings, ProxyServer, 127.0.0.1:7890

    ; ProxyOverride = "localhost;127.0.0.1"
    RegWrite, REG_SZ, HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings, ProxyOverride, localhost;127.0.0.1

    ; BypassProxyOnLocal = 1 (для систем, которые это читают)
    RegWrite, REG_DWORD, HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings, ProxySettingsPerUser, 1

    ; Сообщить приложениям, что настройки прокси обновлены (WM_SETTINGCHANGE, lParam = "Internet Settings")
    ; VarSetCapacity(psz, 32, 0)
    ; StrPut("Internet Settings", &psz, "UTF-16")
    ; SendMessage, 0x1A, 0, &psz,, ahk_id 0xFFFF  ; HWND_BROADCAST
return

; Применить сразу при запуске
Gosub, ApplyProxy
