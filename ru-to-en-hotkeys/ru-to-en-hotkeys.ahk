#Requires AutoHotkey v2.0
#SingleInstance Force

SendMode("Input")

; [] — применять во всех программах.
;
; Только для определённых программ:
; TARGET_EXES := ["blender.exe", "SomeProgram.exe"]
;
; Имя процесса можно посмотреть:
; Диспетчер задач → Подробности → Имя образа.

TARGET_EXES := ["opencode.exe"]

; Английская раскладка США — 00000409.
; KLF_SUBSTITUTE_OK = 0x00000002.

ENGLISH_HKL := DllCall(
    "user32\LoadKeyboardLayoutW",
    "WStr", "00000409",
    "UInt", 0x00000002,
    "Ptr"
)

; Запасное стандартное значение HKL для English (US).
if !ENGLISH_HKL
    ENGLISH_HKL := 0x04090409

sessionActive := false
targetHwnd := 0
originalHKL := 0

OnExit(RestoreLayoutOnExit)


ShouldFixShortcut() {
    global TARGET_EXES

    ; Не вмешиваемся в AltGr.
    ; В Windows AltGr часто определяется как Ctrl + Right Alt.
    if GetKeyState("RAlt", "P")
        return false

    hasModifier :=
        GetKeyState("Ctrl", "P")
        || GetKeyState("Alt", "P")
        || GetKeyState("LWin", "P")
        || GetKeyState("RWin", "P")

    if !hasModifier
        return false

    ; Пустой список означает работу во всех приложениях.
    if TARGET_EXES.Length = 0
        return true

    try activeExe := StrLower(WinGetProcessName("A"))
    catch
        return false

    for targetExe in TARGET_EXES {
        if activeExe = StrLower(targetExe)
            return true
    }

    return false
}


; ---------------------------------------------------------------------------
; Физические клавиши QWERTY.
;
; Слева scan code — положение клавиши.
; Справа virtual-key английской буквы.
;
; Работают сочетания:
; Ctrl + буква
; Alt + буква
; Win + буква
; Ctrl + Shift + буква
; Ctrl + Alt + буква
; и другие комбинации модификаторов.
; ---------------------------------------------------------------------------

#HotIf ShouldFixShortcut()

; Верхний ряд: Q W E R T Y U I O P
$*sc010::ForwardEnglishKey("51", "010") ; Q / Й
$*sc011::ForwardEnglishKey("57", "011") ; W / Ц
$*sc012::ForwardEnglishKey("45", "012") ; E / У
$*sc013::ForwardEnglishKey("52", "013") ; R / К
$*sc014::ForwardEnglishKey("54", "014") ; T / Е
$*sc015::ForwardEnglishKey("59", "015") ; Y / Н
$*sc016::ForwardEnglishKey("55", "016") ; U / Г
$*sc017::ForwardEnglishKey("49", "017") ; I / Ш
$*sc018::ForwardEnglishKey("4F", "018") ; O / Щ
$*sc019::ForwardEnglishKey("50", "019") ; P / З

; Средний ряд: A S D F G H J K L
$*sc01E::ForwardEnglishKey("41", "01E") ; A / Ф
$*sc01F::ForwardEnglishKey("53", "01F") ; S / Ы
$*sc020::ForwardEnglishKey("44", "020") ; D / В
$*sc021::ForwardEnglishKey("46", "021") ; F / А
$*sc022::ForwardEnglishKey("47", "022") ; G / П
$*sc023::ForwardEnglishKey("48", "023") ; H / Р
$*sc024::ForwardEnglishKey("4A", "024") ; J / О
$*sc025::ForwardEnglishKey("4B", "025") ; K / Л
$*sc026::ForwardEnglishKey("4C", "026") ; L / Д

; Нижний ряд: Z X C V B N M
$*sc02C::ForwardEnglishKey("5A", "02C") ; Z / Я
$*sc02D::ForwardEnglishKey("58", "02D") ; X / Ч
$*sc02E::ForwardEnglishKey("43", "02E") ; C / С
$*sc02F::ForwardEnglishKey("56", "02F") ; V / М
$*sc030::ForwardEnglishKey("42", "030") ; B / И
$*sc031::ForwardEnglishKey("4E", "031") ; N / Т
$*sc032::ForwardEnglishKey("4D", "032") ; M / Ь

#HotIf


ForwardEnglishKey(vkHex, scHex) {
    global sessionActive
    global targetHwnd
    global originalHKL
    global ENGLISH_HKL

    hwnd := WinExist("A")

    if !hwnd
        return

    ; Если окно изменилось во время активной сессии,
    ; сначала возвращаем раскладку предыдущему окну.
    if sessionActive && hwnd != targetHwnd
        RestoreLayoutNow()

    if !sessionActive {
        targetHwnd := hwnd
        originalHKL := GetWindowKeyboardLayout(hwnd)

        currentLanguage := originalHKL & 0xFFFF
        englishLanguage := ENGLISH_HKL & 0xFFFF

        if currentLanguage != englishLanguage
            SwitchWindowLayout(hwnd, ENGLISH_HKL)

        sessionActive := true
        SetTimer(RestoreLayoutWhenDone, 10)
    }

    ; Blind сохраняет физически зажатые Ctrl, Shift, Alt и Win.
    ;
    ; Одновременно передаём английский virtual-key
    ; и физический scan code клавиши.
    SendInput("{Blind}{vk" vkHex "sc" scHex "}")
}


RestoreLayoutWhenDone() {
    global sessionActive

    if !sessionActive {
        SetTimer(RestoreLayoutWhenDone, 0)
        return
    }

    modifiersAreDown :=
        GetKeyState("Ctrl", "P")
        || GetKeyState("Alt", "P")
        || GetKeyState("LWin", "P")
        || GetKeyState("RWin", "P")

    if modifiersAreDown
        return

    RestoreLayoutNow()
}


RestoreLayoutNow() {
    global sessionActive
    global targetHwnd
    global originalHKL

    SetTimer(RestoreLayoutWhenDone, 0)

    hwnd := targetHwnd
    oldHKL := originalHKL

    sessionActive := false
    targetHwnd := 0
    originalHKL := 0

    if hwnd && oldHKL && WinExist("ahk_id " hwnd)
        SwitchWindowLayout(hwnd, oldHKL)
}


RestoreLayoutOnExit(*) {
    global sessionActive

    if sessionActive
        RestoreLayoutNow()
}


GetWindowKeyboardLayout(hwnd) {
    threadId := DllCall(
        "user32\GetWindowThreadProcessId",
        "Ptr", hwnd,
        "Ptr", 0,
        "UInt"
    )

    if !threadId
        return 0

    return DllCall(
        "user32\GetKeyboardLayout",
        "UInt", threadId,
        "Ptr"
    )
}


SwitchWindowLayout(hwnd, hkl) {
    if !hwnd || !hkl
        return false

    ; WM_INPUTLANGCHANGEREQUEST = 0x0050.
    try PostMessage(0x0050, 0, hkl, , "ahk_id " hwnd)
    catch
        return false

    targetLanguage := hkl & 0xFFFF

    ; Ждём применения раскладки максимум около 100 мс.
    Loop 20 {
        Sleep(5)

        currentHKL := GetWindowKeyboardLayout(hwnd)

        if currentHKL && (currentHKL & 0xFFFF) = targetLanguage
            return true
    }

    return false
}
