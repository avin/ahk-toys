#Requires AutoHotkey v2.0
#SingleInstance Force

Persistent()

; Настройки рамки и распознавания triple-tap.
BORDER_THICKNESS := 5
BORDER_OPACITY := Round(255 * 0.75)
BORDER_COLOR := "FF4500"
TRIPLE_TAP_MAX_GAP_MS := 400
MAX_TAP_HOLD_MS := 300
TOPMOST_REFRESH_MS := 250
MICROPHONE_PRIVACY_REGISTRY_KEY := "HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone"

; Состояние микрофона и сочетания LCtrl+Win.
persistentUnmuted := false
pushToTalkActive := false
lCtrlWinDown := false
lCtrlWinDownAt := 0
suppressWinUp := false
tapTimes := []
currentLiveState := -1

; Состояние оверлея-рамки.
borderFrames := []
borderVisible := false
monitorSignature := ""
audioErrorShown := false

OnExit(HandleExit)
SetLiveState(false)

; LCtrl+Win запускает push-to-talk сразу, но только если микрофон сейчас используется приложением.
~*LCtrl:: {
    HandleLCtrlWinDown()
}

~*LWin:: {
    HandleLCtrlWinDown()
}

~*RWin:: {
    HandleLCtrlWinDown()
}

#HotIf suppressWinUp
*LWin Up:: {
    HandleWinUp()
}

*RWin Up:: {
    HandleWinUp()
}
#HotIf

; Отпускание любой клавиши из LCtrl+Win либо регистрирует tap для triple-tap, либо возвращает mute.
~*LCtrl Up:: {
    HandleLCtrlWinUp()
}

HandleLCtrlWinDown() {
    global lCtrlWinDown, lCtrlWinDownAt, suppressWinUp, persistentUnmuted, pushToTalkActive

    if lCtrlWinDown || !IsLCtrlWinDown() {
        return
    }

    lCtrlWinDown := true
    lCtrlWinDownAt := A_TickCount
    suppressWinUp := true

    if persistentUnmuted {
        return
    }

    if IsMicrophoneCaptureActive() {
        pushToTalkActive := true
        SetLiveState(true)
    }
}

HandleLCtrlWinUp() {
    global lCtrlWinDown, lCtrlWinDownAt, persistentUnmuted, pushToTalkActive, MAX_TAP_HOLD_MS

    if !lCtrlWinDown || IsLCtrlWinDown() {
        return
    }

    wasTap := (A_TickCount - lCtrlWinDownAt) <= MAX_TAP_HOLD_MS
    lCtrlWinDown := false

    if wasTap && RegisterLCtrlWinTap() {
        return
    }

    if persistentUnmuted {
        return
    }

    pushToTalkActive := false
    SetLiveState(false)
}

HandleWinUp() {
    HandleLCtrlWinUp()
    ClearWinUpSuppressionIfReleased()
}

ClearWinUpSuppressionIfReleased() {
    global suppressWinUp

    if !GetKeyState("LWin", "P") && !GetKeyState("RWin", "P") {
        suppressWinUp := false
    }
}

IsLCtrlWinDown() {
    return GetKeyState("LCtrl", "P")
        && (GetKeyState("LWin", "P") || GetKeyState("RWin", "P"))
}

; Считает три быстрых отпускания LCtrl+Win и переключает постоянный unmute.
RegisterLCtrlWinTap() {
    global tapTimes, TRIPLE_TAP_MAX_GAP_MS, persistentUnmuted, pushToTalkActive

    now := A_TickCount

    if tapTimes.Length && (now - tapTimes[tapTimes.Length] > TRIPLE_TAP_MAX_GAP_MS) {
        tapTimes := []
    }

    tapTimes.Push(now)

    if tapTimes.Length < 3 {
        return false
    }

    tapTimes := []
    persistentUnmuted := !persistentUnmuted
    pushToTalkActive := false
    SetLiveState(persistentUnmuted)
    return true
}

; Проверяет Windows privacy registry: активный захват обычно имеет LastUsedTimeStop = 0.
IsMicrophoneCaptureActive() {
    global MICROPHONE_PRIVACY_REGISTRY_KEY

    return HasActiveMicrophoneUsage(MICROPHONE_PRIVACY_REGISTRY_KEY)
}

HasActiveMicrophoneUsage(registryKey) {
    if IsRegistryMicrophoneEntryActive(registryKey) {
        return true
    }

    try {
        Loop Reg, registryKey, "K" {
            if HasActiveMicrophoneUsage(registryKey "\" A_LoopRegName) {
                return true
            }
        }
    }

    return false
}

IsRegistryMicrophoneEntryActive(registryKey) {
    startTime := RegReadQword(registryKey, "LastUsedTimeStart", 0)
    stopTime := RegReadQword(registryKey, "LastUsedTimeStop", -1)

    return Integer(startTime) > 0 && Integer(stopTime) == 0
}

; LastUsedTimeStart/Stop хранятся как REG_QWORD, поэтому читаем их через WinAPI.
RegReadQword(registryKey, valueName, defaultValue := 0) {
    rootAndSubkey := SplitRegistryKey(registryKey)
    if !rootAndSubkey {
        return defaultValue
    }

    data := Buffer(8, 0)
    dataSize := 8
    valueType := 0
    status := DllCall("Advapi32\RegGetValueW"
        , "Ptr", rootAndSubkey.Root
        , "Str", rootAndSubkey.Subkey
        , "Str", valueName
        , "UInt", 0x40
        , "UInt*", &valueType
        , "Ptr", data
        , "UInt*", &dataSize
        , "UInt")

    if status != 0 || valueType != 11 || dataSize != 8 {
        return defaultValue
    }

    return NumGet(data, 0, "Int64")
}

SplitRegistryKey(registryKey) {
    rootMap := Map(
        "HKCU", 0x80000001,
        "HKEY_CURRENT_USER", 0x80000001
    )

    separatorPos := InStr(registryKey, "\")
    if !separatorPos {
        return false
    }

    rootName := SubStr(registryKey, 1, separatorPos - 1)
    if !rootMap.Has(rootName) {
        return false
    }

    return {
        Root: rootMap[rootName],
        Subkey: SubStr(registryKey, separatorPos + 1)
    }
}

; Единая точка смены live/muted: звук и визуальная рамка всегда переключаются вместе.
SetLiveState(isLive) {
    global currentLiveState

    isLive := !!isLive
    if currentLiveState == isLive {
        return
    }

    currentLiveState := isLive
    if !SetMicrophoneMuted(!isLive) {
        ShowAudioErrorOnce()
    }
    SetBorderVisible(isLive)
}

; Сначала пробуем стандартное устройство Microphone, затем fallback по устройствам и capture-контролам.
SetMicrophoneMuted(muted) {
    if TrySetDeviceMute(muted, , "Microphone") {
        return true
    }

    controls := ["Microphone", "Capture", 1]
    deviceIndex := 1
    changed := false

    loop {
        try {
            deviceName := SoundGetName(, deviceIndex)
        } catch {
            break
        }

        for control in controls {
            if TrySetDeviceMute(muted, control, deviceIndex) {
                changed := true
            }
        }

        if IsLikelyMicrophoneDevice(deviceName) && TrySetDeviceMute(muted, , deviceIndex) {
            changed := true
        }

        deviceIndex += 1
    }

    return changed
}

; SoundSetMute бросает исключения, если устройство или контрол не поддерживает mute.
TrySetDeviceMute(muted, component?, device?) {
    try {
        if IsSet(component) && IsSet(device) {
            SoundSetMute(muted, component, device)
        } else if IsSet(device) {
            SoundSetMute(muted, , device)
        } else if IsSet(component) {
            SoundSetMute(muted, component)
        } else {
            SoundSetMute(muted)
        }
        return true
    } catch {
        return false
    }
}

; Простая эвристика для fallback-поиска микрофона среди аудиоустройств.
IsLikelyMicrophoneDevice(deviceName) {
    name := StrLower(deviceName)
    return InStr(name, "microphone")
        || InStr(name, "mic")
        || InStr(name, "headset")
        || InStr(name, "array")
}

; Показываем ошибку только один раз, чтобы не спамить уведомлениями при каждом нажатии.
ShowAudioErrorOnce() {
    global audioErrorShown

    if audioErrorShown {
        return
    }

    audioErrorShown := true
    TrayTip("mic-mute", "Failed to change microphone mute state.", 0x11)
}

; Включает или уничтожает рамку и таймер, который удерживает ее поверх окон.
SetBorderVisible(visible) {
    global borderVisible, TOPMOST_REFRESH_MS

    visible := !!visible
    if borderVisible == visible {
        return
    }

    borderVisible := visible
    if visible {
        DrawBorder()
        SetTimer(KeepBorderOnTop, TOPMOST_REFRESH_MS)
    } else {
        SetTimer(KeepBorderOnTop, 0)
        DestroyBorder()
    }
}

; Рамка строится отдельными тонкими GUI-полосами на каждом мониторе.
DrawBorder() {
    global borderFrames, monitorSignature, BORDER_THICKNESS

    DestroyBorder()
    monitorSignature := GetMonitorSignature()

    monitorCount := MonitorGetCount()
    Loop monitorCount {
        MonitorGet(A_Index, &left, &top, &right, &bottom)

        width := right - left
        height := bottom - top
        if width <= 0 || height <= 0 {
            continue
        }

        AddFrame(left, top, width, BORDER_THICKNESS)
        AddFrame(left, bottom - BORDER_THICKNESS, width, BORDER_THICKNESS)
        AddFrame(left, top + BORDER_THICKNESS, BORDER_THICKNESS, height - BORDER_THICKNESS * 2)
        AddFrame(right - BORDER_THICKNESS, top + BORDER_THICKNESS, BORDER_THICKNESS, height - BORDER_THICKNESS * 2)
    }
}

; Одна click-through topmost полоса рамки.
AddFrame(x, y, width, height) {
    global borderFrames, BORDER_COLOR, BORDER_OPACITY

    if width <= 0 || height <= 0 {
        return
    }

    frame := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x80020 +E0x08000000")
    frame.BackColor := BORDER_COLOR
    frame.Show(Format("x{} y{} w{} h{} NoActivate", x, y, width, height))
    WinSetTransparent(BORDER_OPACITY, "ahk_id " frame.Hwnd)
    borderFrames.Push(frame)
}

; Удаляет все GUI-полосы рамки.
DestroyBorder() {
    global borderFrames

    for frame in borderFrames {
        try frame.Destroy()
    }

    borderFrames := []
}

; Периодически переутверждает topmost и пересоздает рамку при смене конфигурации мониторов.
KeepBorderOnTop() {
    global borderVisible, borderFrames, monitorSignature

    if !borderVisible {
        return
    }

    if GetMonitorSignature() != monitorSignature {
        DrawBorder()
        return
    }

    for frame in borderFrames {
        DllCall("user32\SetWindowPos"
            , "Ptr", frame.Hwnd
            , "Ptr", -1
            , "Int", 0
            , "Int", 0
            , "Int", 0
            , "Int", 0
            , "UInt", 0x0013)
    }
}

; Снимок текущей геометрии мониторов для обнаружения переподключения или смены разрешения.
GetMonitorSignature() {
    signature := ""
    monitorCount := MonitorGetCount()

    Loop monitorCount {
        MonitorGet(A_Index, &left, &top, &right, &bottom)
        signature .= A_Index ":" left "," top "," right "," bottom ";"
    }

    return signature
}

; При выходе убираем рамку и возвращаем микрофон в безопасное muted-состояние.
HandleExit(*) {
    SetTimer(KeepBorderOnTop, 0)
    DestroyBorder()
    SetMicrophoneMuted(true)
}
