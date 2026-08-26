#Requires AutoHotkey v2.0
#SingleInstance Force

#include Lib\UIA.ahk

; ============================================================
; Codex model / effort presets
;
; F1 -> 5.6 Luna + Max
; F2 -> 5.6 Sol  + Medium
;
; Hotkeys работают только когда активно окно процесса ChatGPT.exe.
; Исходное нажатие F1/F2 блокируется только в этом окне.
; ============================================================


; ------------------------------------------------------------
; Настройки
; ------------------------------------------------------------

global UIA_TIMEOUT := 2000
global SWITCH_IN_PROGRESS := false


#HotIf WinActive("ahk_exe ChatGPT.exe")

F1::SwitchPreset("5.6 Luna", "Max")
F2::SwitchPreset("5.6 Sol", "Medium")

#HotIf


; ============================================================
; MAIN
; ============================================================

SwitchPreset(modelName, effortName)
{
    global SWITCH_IN_PROGRESS

    ; Сигнализируем, что обработчик хоткея запустился.
    SoundBeep(880, 100)

    ; Не даём двум переключениям выполняться одновременно.
    if SWITCH_IN_PROGRESS
        return

    SWITCH_IN_PROGRESS := true

    try
    {
        hwnd := WinExist("A")

        if !hwnd
            throw Error("Не удалось получить HWND активного окна Codex.")

        pid := WinGetPID(hwnd)

        ; UIA root конкретного окна Codex.
        codex := UIA.ElementFromHandle(hwnd)

        ; Desktop root нужен потому, что Radix popup/submenu
        ; может жить не внутри UIA subtree основного HWND.
        desktop := UIA.GetRootElement()


        ; ====================================================
        ; 0. Ищем основную кнопку:
        ;
        ; "5.6 Sol Medium"
        ; "5.6 Luna Max"
        ; и т.д.
        ;
        ; AutomationId намеренно НЕ используем:
        ; radix-_r_..._ может меняться.
        ; ====================================================

        modelButton := WaitUIA(
            codex,
            {
                Type: "Button",
                Name: "5.6 ",
                mm: "Substring",
                IsOffscreen: false
            },
            "кнопка выбора Model/Effort"
        )


        ; Если нужный preset уже выбран — ничего делать не надо.
        try
        {
            expectedName := modelName " " effortName

            if modelButton.Name = expectedName
            {
                ShowStatus("Уже выбран: " expectedName)
                return
            }
        }


        ; ====================================================
        ; 1. Открываем главное меню
        ; ====================================================

        ActivateUIA(modelButton)


        ; ====================================================
        ; 2. Находим:
        ;
        ; MenuItem
        ; Name: "Model 5.6 Sol"
        ;
        ; или после переключения:
        ; Name: "Model 5.6 Luna"
        ; ====================================================

        modelMenuItem := WaitUIA(
            desktop,
            {
                ProcessId: pid,
                Type: "MenuItem",
                Name: "Model ",
                mm: "Substring",
                IsOffscreen: false,
                IsEnabled: true
            },
            "пункт меню Model"
        )

        ActivateUIA(modelMenuItem)


        ; ====================================================
        ; 3. Выбираем модель
        ;
        ; F1 -> "5.6 Luna"
        ; F2 -> "5.6 Sol"
        ; ====================================================

        targetModel := WaitUIA(
            desktop,
            {
                ProcessId: pid,
                Type: "MenuItem",
                Name: modelName,
                IsOffscreen: false,
                IsEnabled: true
            },
            "модель " modelName
        )

        ActivateUIA(targetModel)


        ; ====================================================
        ; 4. После выбора модели главное меню остаётся открыто.
        ;
        ; Ищем:
        ;
        ; "Effort Medium"
        ; "Effort Max"
        ; и т.д.
        ; ====================================================

        effortMenuItem := WaitUIA(
            desktop,
            {
                ProcessId: pid,
                Type: "MenuItem",
                Name: "Effort ",
                mm: "Substring",
                IsOffscreen: false,
                IsEnabled: true
            },
            "пункт меню Effort"
        )

        ActivateUIA(effortMenuItem)


        ; ====================================================
        ; 5. Выбираем Effort
        ;
        ; F1 -> Max
        ; F2 -> Medium
        ; ====================================================

        targetEffort := WaitUIA(
            desktop,
            {
                ProcessId: pid,
                Type: "MenuItem",
                Name: effortName,
                IsOffscreen: false,
                IsEnabled: true
            },
            "Effort " effortName
        )

        ActivateUIA(targetEffort)


        ; ====================================================
        ; Успех
        ; ====================================================

        ShowStatus(modelName " / " effortName)
    }
    catch as err
    {
        ; Если что-то пошло не так и меню осталось открытым —
        ; закрываем его.
        try Send "{Esc}"

        ShowError(err)
    }
    finally
    {
        SWITCH_IN_PROGRESS := false
    }
}


; ============================================================
; UIA HELPERS
; ============================================================

WaitUIA(rootElement, condition, description := "UIA element")
{
    global UIA_TIMEOUT

    startTime := A_TickCount
    lastError := ""

    while (A_TickCount - startTime) < UIA_TIMEOUT
    {
        try
        {
            return rootElement.FindElement(condition)
        }
        catch as err
        {
            lastError := err.Message
        }

        Sleep 30
    }

    message := "Не найден UIA-элемент:`n" description

    if lastError
        message .= "`n`nПоследняя ошибка UIA:`n" lastError

    throw Error(message)
}


ActivateUIA(element)
{
    ; Сначала пробуем семантический UIA Invoke.
    ;
    ; Для Button / MenuItem это предпочтительнее,
    ; потому что реальный курсор мыши вообще не нужен.

    try
    {
        element.Invoke()
        return
    }
    catch
    {
    }


    ; Некоторые accessibility-элементы Chromium/Radix
    ; не предоставляют InvokePattern.
    ;
    ; Тогда UIA-v2 сам кликает по текущему BoundingRectangle
    ; найденного элемента.
    ;
    ; Это НЕ статические координаты:
    ; позиция каждый раз получается через UIA.

    try
    {
        element.Click()
        return
    }
    catch as err
    {
        throw Error(
            "Не удалось активировать UIA-элемент."
            . "`n"
            . "`nName: " GetElementName(element)
            . "`n"
            . "`n" err.Message
        )
    }
}


GetElementName(element)
{
    try
        return element.Name
    catch
        return "<unknown>"
}


; ============================================================
; UI FEEDBACK
; ============================================================

ShowStatus(text)
{
    ToolTip "Codex preset: " text

    SetTimer(
        () => ToolTip(),
        -1200
    )
}


ShowError(err)
{
    text :=
        "Codex preset switch failed"
        . "`n"
        . "`n"
        . err.Message

    ToolTip text

    SetTimer(
        () => ToolTip(),
        -4000
    )
}
