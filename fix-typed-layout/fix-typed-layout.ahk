#Requires AutoHotkey v2.0
#SingleInstance Force

#Include ..\codex-model-changer\Lib\UIA.ahk

idleMs := 3000
layouts := Map()
count := DllCall("GetKeyboardLayoutList", "Int", 0, "Ptr", 0, "Int")
handles := Buffer(count * A_PtrSize)
Loop DllCall("GetKeyboardLayoutList", "Int", count, "Ptr", handles, "Int") {
    layout := NumGet(handles, (A_Index - 1) * A_PtrSize, "Ptr")
    layouts[layout & 0xFFFF] := layout
}
if !layouts.Has(0x0409) || !layouts.Has(0x0419)
    throw Error("Для исправления текста нужны раскладки English (US) и Русская.")

fragment := 0
input := InputHook("V I1")
input.KeyOpt("{All}", "N")
input.OnKeyDown := TrackInput
input.Start()

~*LButton::ResetFragment()
~*RButton::ResetFragment()
~*MButton::ResetFragment()
~*XButton1::ResetFragment()
~*XButton2::ResetFragment()

#HotIf HasRecentFragment()
$^Left:: {
    Critical()
    lastWindow := WinExist("A")
    if !CorrectFragment() && WinExist("A") = lastWindow
        Send("^{Left}")
}
#HotIf

HasRecentFragment() {
    global fragment, idleMs
    return fragment && A_TickCount - fragment.tick < idleMs
        && fragment.typed !== fragment.corrected && WinActive("ahk_id " fragment.window)
}

ResetFragment() {
    global fragment
    fragment := 0
    SetTimer(ResetFragment, 0)
}

TrackInput(hook, vk, sc) {
    global fragment, idleMs, layouts
    Critical()

    ; Нажатие модификатора само по себе не меняет набранный текст.
    if vk = 0x10 || vk = 0x11 || vk = 0x12 || vk = 0x14
        || vk = 0x5B || vk = 0x5C || (vk >= 0xA0 && vk <= 0xA5)
        return

    if GetKeyState("Ctrl") || GetKeyState("Alt") || GetKeyState("LWin") || GetKeyState("RWin") {
        ResetFragment()
        return
    }

    window := WinExist("A")
    thread := DllCall("GetWindowThreadProcessId", "Ptr", window, "Ptr", 0, "UInt")
    focus := FocusedWindow(thread)
    layout := ThreadLayout(thread)
    tick := A_TickCount
    if fragment && (fragment.focus != focus || fragment.window != window
        || fragment.layout != layout || tick - fragment.tick >= idleMs)
        ResetFragment()

    language := layout & 0xFFFF
    if !focus || (language != 0x0409 && language != 0x0419) {
        ResetFragment()
        return
    }

    if vk = 0x08 && !GetKeyState("Shift") {
        if !fragment
            return
        fragment.typed := SubStr(fragment.typed, 1, -1)
        fragment.corrected := SubStr(fragment.corrected, 1, -1)
        if fragment.typed = "" {
            ResetFragment()
            return
        }
    } else {
        target := layouts[language = 0x0409 ? 0x0419 : 0x0409]
        state := Buffer(256, 0)
        NumPut("UChar", GetKeyState("Shift") ? 0x80 : 0, state, 0x10)
        NumPut("UChar", GetKeyState("CapsLock", "T"), state, 0x14)
        typed := LayoutCharacter(sc, vk, state, layout)
        targetVk := DllCall("MapVirtualKeyExW", "UInt", sc, "UInt", 1, "Ptr", target, "UInt")
        corrected := LayoutCharacter(sc, targetVk, state, target)
        if typed = "" || corrected = "" {
            ResetFragment()
            return
        }
        if !fragment {
            if typed = " "
                return
            fragment := {window: window, focus: focus, thread: thread, layout: layout,
                target: target, typed: "", corrected: ""}
        }
        fragment.typed .= typed
        fragment.corrected .= corrected
    }

    fragment.tick := tick
    SetTimer(ResetFragment, -idleMs)
}

LayoutCharacter(sc, vk, state, layout) {
    chars := Buffer(8, 0)
    ; Флаг 4 сохраняет состояние преобразования клавиш Windows.
    length := DllCall("ToUnicodeEx", "UInt", vk, "UInt", sc, "Ptr", state,
        "Ptr", chars, "Int", 4, "UInt", 4, "Ptr", layout, "Int")
    return length = 1 && NumGet(chars, "UShort") >= 32 ? StrGet(chars, 1, "UTF-16") : ""
}

CorrectFragment() {
    global fragment
    entry := fragment
    ResetFragment()
    if !entry || !ContextMatches(entry, entry.layout)
        return false

    ; Выделяем диапазон только после сверки текста перед курсором через UI Automation.
    try {
        field := UIA.GetFocusedElement()
        if field.IsPassword || !field.IsEnabled
            return false
        selections := field.TextPattern.GetSelection()
        if selections.Length != 1
            return false
        range := selections[1]
        if range.CompareEndpoints("Start", range, "End") != 0
            return false
        length := StrLen(entry.typed)
        if range.MoveEndpointByUnit("Start", "Character", -length) != -length
            || range.GetText() !== entry.typed || range.GetAttributeValue(UIA.TextAttribute.IsReadOnly) !== 0
            return false

        if !ContextMatches(entry, entry.layout)
            return false
        PostMessage(0x0050, 0, entry.target, , "ahk_id " entry.focus) ; WM_INPUTLANGCHANGEREQUEST
        deadline := A_TickCount + 150
        while ThreadLayout(entry.thread) != entry.target && A_TickCount < deadline
            Sleep(5)
        if !ContextMatches(entry, entry.target) || !UIA.CompareElements(field, UIA.GetFocusedElement())
            return false

        selections := field.TextPattern.GetSelection()
        if selections.Length != 1 || selections[1].CompareEndpoints("Start", selections[1], "End") != 0
            || range.CompareEndpoints("End", selections[1], "Start") != 0
            return false
        range.Select()
        ; Chrome применяет выделение асинхронно.
        deadline := A_TickCount + 150
        loop {
            selections := field.TextPattern.GetSelection()
            if selections.Length = 1 && range.Compare(selections[1]) && selections[1].GetText() == entry.typed
                break
            if A_TickCount >= deadline
                return false
            Sleep(5)
        }
        if !ContextMatches(entry, entry.target) || !UIA.CompareElements(field, UIA.GetFocusedElement())
            return false
        SendText(entry.corrected)
        return true
    } catch {
        return false
    }
}

ContextMatches(entry, layout) {
    return WinActive("ahk_id " entry.window) && FocusedWindow(entry.thread) = entry.focus
        && ThreadLayout(entry.thread) = layout
}

FocusedWindow(thread) {
    if !thread
        return 0
    info := Buffer(8 + 6 * A_PtrSize + 16, 0) ; GUITHREADINFO
    NumPut("UInt", info.Size, info)
    return DllCall("GetGUIThreadInfo", "UInt", thread, "Ptr", info) ? NumGet(info, 8 + A_PtrSize, "Ptr") : 0
}

ThreadLayout(thread) => DllCall("GetKeyboardLayout", "UInt", thread, "Ptr")
