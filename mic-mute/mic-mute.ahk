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

; Состояние микрофона и клавиши Right Ctrl.
persistentUnmuted := false
pushToTalkActive := false
rightCtrlDown := false
rightCtrlDownAt := 0
tapTimes := []
currentLiveState := -1

; Состояние оверлея-рамки.
borderFrames := []
borderVisible := false
monitorSignature := ""
audioErrorShown := false

OnExit(HandleExit)
SetLiveState(false)

; Удержание Right Ctrl работает как push-to-talk, если не включен постоянный unmute.
~*RControl:: {
    global rightCtrlDown, rightCtrlDownAt, persistentUnmuted, pushToTalkActive

    if rightCtrlDown {
        return
    }

    rightCtrlDown := true
    rightCtrlDownAt := A_TickCount

    if persistentUnmuted {
        return
    }

    pushToTalkActive := true
    SetLiveState(true)
}

; Отпускание Right Ctrl либо регистрирует tap для triple-tap, либо возвращает mute.
~*RControl Up:: {
    global rightCtrlDown, rightCtrlDownAt, persistentUnmuted, pushToTalkActive, MAX_TAP_HOLD_MS

    if !rightCtrlDown {
        return
    }

    wasTap := (A_TickCount - rightCtrlDownAt) <= MAX_TAP_HOLD_MS
    rightCtrlDown := false

    if wasTap && RegisterRightCtrlTap() {
        return
    }

    if persistentUnmuted {
        return
    }

    pushToTalkActive := false
    SetLiveState(false)
}

; Считает три быстрых отпускания Right Ctrl и переключает постоянный unmute.
RegisterRightCtrlTap() {
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
