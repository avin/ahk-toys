#NoEnv ; Рекомендуется для улучшения совместимости и производительности
SendMode Input ; Рекомендуется для более быстрой и надежной работы скрипта
SetWorkingDir %A_ScriptDir% ; Установка рабочего каталога скрипта

; Переменная для отслеживания, было ли перетаскивание
global dragHappened := false

; Функция для получения размеров рабочего стола с учётом панели задач
Win__GetDesktopPos(ByRef X, ByRef Y, ByRef W, ByRef H)
{
    WinGetPos, TrayX, TrayY, TrayW, TrayH, ahk_class Shell_TrayWnd ; Получение размеров панели задач
    if (TrayW = A_ScreenWidth) ; Проверка, горизонтальная ли панель задач
    {
        X := 0
        Y := TrayY ? 0 : TrayH ; Установка Y в зависимости от положения панели задач
        W := A_ScreenWidth
        H := A_ScreenHeight - TrayH ; Вычитание высоты панели задач из высоты экрана
    }
    else
    {
        ; Вертикальная панель задач
        X := TrayX ? 0 : TrayW ; Установка X в зависимости от положения панели задач
        Y := 0
        W := A_ScreenWidth - TrayW ; Вычитание ширины панели задач из ширины экрана
        H := A_ScreenHeight
    }
}

; Get window position without the invisible border.
WinGetPosEx(byref X:="", byref Y:="", byref W:="", byref H:="", hwnd:="") {
    static DWMWA_EXTENDED_FRAME_BOUNDS := 9
    if (hwnd = "")
        hwnd := WinExist() ; last found window
    if hwnd is not integer
        hwnd := WinExist(hwnd)
    RECTsize := VarSetCapacity(RECT, 16, 0)
    DllCall("dwmapi\DwmGetWindowAttribute"
            , "ptr" , hwnd
            , "uint", DWMWA_EXTENDED_FRAME_BOUNDS
            , "ptr" , &RECT
            , "uint", RECTsize
            , "uint")
    X := NumGet(RECT, 0, "int")
    Y := NumGet(RECT, 4, "int")
    W := NumGet(RECT, 8, "int") - X
    H := NumGet(RECT, 12, "int") - Y
}

; Move window and fix offset from invisible border.
WinMoveEx(X:="", Y:="", W:="", H:="", hwnd:="") {
    if hwnd is not integer
        hwnd := WinExist(hwnd)
    if (hwnd = "")
        hwnd := WinExist()
    ; compare pos and get offset
    WinGetPosEx(fX, fY, fW, fH, hwnd)
    WinGetPos wX, wY, wW, wH, % "ahk_id" hwnd
    xDiff := fX - wX
    hDiff := wH - fH
    nX := nY := nW := nH := ""
    pixel := 1
    ; new X, Y, W, H with offset corrected
    (X!="") && nX := X - xDiff - pixel
    (Y!="") && nY := Y - pixel
    (W!="") && nW := W + (xDiff + pixel) * 2
    (H!="") && nH := H + hDiff + (pixel * 2)
    WinMove % "ahk_id" hwnd,, nX, nY, nW, nH
}

; Функция для перемещения окна на левую половину экрана
Win__HalfLeft()
{
    Win__GetDesktopPos(X, Y, W, H) ; Получение размеров рабочего стола
    hwnd := WinExist("A") ; Получение идентификатора активного окна
    WinMoveEx(X, Y, W//2, H, hwnd)
}

; Функция для перемещения окна на правую половину экрана
Win__HalfRight()
{
    Win__GetDesktopPos(X, Y, W, H) ; Получение размеров рабочего стола
    hwnd := WinExist("A") ; Получение идентификатора активного окна
    WinMoveEx(X + W//2, Y, W//2, H, hwnd)
}

; Обработка нажатия левой кнопки мыши
~LButton::
    ; Сброс флага перетаскивания
    dragHappened := false

    ; Получение начальных координат мыши
    coordmode,mouse,screen
    MouseGetPos, startX, startY
return

; Обработка движения мыши во время удержания левой кнопки
~LButton Up::
    ; Получение конечных координат мыши
    coordmode,mouse,screen
    MouseGetPos, endX, endY

    ; Проверка, было ли движение мыши
    if (startX != endX or startY != endY)
        dragHappened := true

    ; Если было перетаскивание, вывод сообщения
    if (dragHappened) {
        MouseGetPos, x, y, hwnd ; Обновление координат и идентификатора окна
        ; Определение части окна, на которой находится курсор
        SendMessage, 0x84, 0, (x&0xFFFF) | (y&0xFFFF) << 16,, ahk_id %hwnd%
        ; Использование регулярного выражения для определения части окна
        RegExMatch("ERROR TRANSPARENT NOWHERE CLIENT CAPTION SYSMENU SIZE MENU HSCROLL VSCROLL MINBUTTON MAXBUTTON LEFT RIGHT TOP TOPLEFT TOPRIGHT BOTTOM BOTTOMLEFT BOTTOMRIGHT BORDER OBJECT CLOSE HELP", "(?:\w+\s+){" . ErrorLevel+2&0xFFFFFFFF . "}(?<AREA>\w+\b)", HT)
        if htarea!=CAPTION ; Если курсор не на заголовке, прекращение выполнения
            Return

        ; Получение текущих координат мыши
        coordmode,mouse,screen
        MouseGetPos,Mouse_X,Mouse_Y
        if Mouse_X<3
        {
            Win__HalfLeft() ; Перемещение окна на левую половину экрана, если мышь у левого края
        }

        if (Mouse_X > (A_ScreenWidth - 3))
        {
            Win__HalfRight() ; Перемещение окна на правую половину экрана, если мышь у правого края
        }
    }

return
