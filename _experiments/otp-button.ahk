#NoEnv
#SingleInstance Force
SetWorkingDir %A_ScriptDir%
CoordMode, Mouse, Screen

; Переменные для хранения состояния
global ButtonHwnd := 0
global CurrentWindow := 0

; Создаём таймер для отслеживания активных окон
SetTimer, CheckActiveWindow, 100

; Основная функция отслеживания
CheckActiveWindow:
    WinGet, ActiveHwnd, ID, A
    WinGetTitle, ActiveTitle, ahk_id %ActiveHwnd%

    ; Проверяем, начинается ли заголовок с "TurboWin"
    if (InStr(ActiveTitle, "TurboWin") = 1)
    {
        ; Если это новое окно TurboWin или окно изменилось
        if (ActiveHwnd != CurrentWindow)
        {
            CurrentWindow := ActiveHwnd
            CreateFloatingButton()
        }
        else
        {
            ; Обновляем позицию кнопки, если окно переместилось
            UpdateButtonPosition()
        }
    }
    else
    {
        ; Если активное окно не TurboWin, скрываем кнопку
        if (ButtonHwnd)
        {
            Gui, FloatingButton:Hide
            CurrentWindow := 0
        }
    }
return

; Создание плавающей кнопки
CreateFloatingButton()
{
    ; Уничтожаем предыдущую кнопку, если она существует
    if (ButtonHwnd)
    {
        Gui, FloatingButton:Destroy
    }

    ; Создаём новое GUI окно для кнопки
    Gui, FloatingButton:New, +AlwaysOnTop -Caption +ToolWindow +Owner%CurrentWindow% +HwndButtonHwnd
    Gui, FloatingButton:Color, 0x2196F3
    Gui, FloatingButton:Font, s10 cWhite Bold
    Gui, FloatingButton:Add, Text, x0 y0 w100 h20 Center gButtonClick, Generate OTP

    ; Устанавливаем начальную позицию
    UpdateButtonPosition()

    ; Показываем кнопку
    Gui, FloatingButton:Show, NoActivate
}

; Обновление позиции кнопки
UpdateButtonPosition()
{
    if (!ButtonHwnd || !CurrentWindow)
        return

    ; Получаем позицию окна TurboWin
    WinGetPos, WinX, WinY, WinWidth, WinHeight, ahk_id %CurrentWindow%

    ; Проверяем, что окно существует и видимо
    if (WinX = "" || WinY = "")
        return

    ; Позиционируем кнопку по центру сверху окна
    ButtonX := WinX + (WinWidth - 100) // 2
    ButtonY := WinY - 20

    ; Перемещаем кнопку
    Gui, FloatingButton:Show, x%ButtonX% y%ButtonY% w100 h20 NoActivate
}

; Обработчик клика по кнопке
ButtonClick:
    ; Запускаем батник
    Run, C:\utils\otp\run.bat, C:\utils\otp\, Hide
return

; Обработка перемещения мыши для эффекта наведения
#If (ButtonHwnd)
~LButton::
    MouseGetPos, , , WinUnderMouse
    if (WinUnderMouse = ButtonHwnd)
    {
        Gui, FloatingButton:Color, 0x1976D2
        SetTimer, RestoreButtonColor, 100
    }
return

RestoreButtonColor:
    SetTimer, RestoreButtonColor, Off
    MouseGetPos, , , WinUnderMouse
    if (WinUnderMouse != ButtonHwnd)
    {
        Gui, FloatingButton:Color, 0x2196F3
    }
return
#If

; Выход из скрипта
^Esc::ExitApp
