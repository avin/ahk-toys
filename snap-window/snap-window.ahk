#Requires AutoHotkey v2.0
#SingleInstance Force
;---

; Переменная для отслеживания, было ли перетаскивание
global dragHappened := false

; Функция для получения размеров рабочего стола с учётом панели задач
Win__GetDesktopPos(&X, &Y, &W, &H) {
    WinGetPos &TrayX, &TrayY, &TrayW, &TrayH, "ahk_class Shell_TrayWnd"
    if (TrayW = A_ScreenWidth) ; Проверка, горизонтальная ли панель задач
    {
        X := 0
        Y := TrayY ? 0 : TrayH ; Установка Y в зависимости от положения панели задач
        W := A_ScreenWidth
        H := A_ScreenHeight - TrayH - 1 ; Вычитание высоты панели задач из высоты экрана
    }
    else
    {
        ; Вертикальная панель задач
        X := TrayX ? 0 : TrayW ; Установка X в зависимости от положения панели задач
        Y := 0
        W := A_ScreenWidth - TrayW ; Вычитание ширины панели задач из ширины экрана
        H := A_ScreenHeight - 1
    }
}

; Get window position without the invisible border.
WinGetPosEx(&X := "", &Y := "", &W := "", &H := "", hwnd := "") {
    static DWMWA_EXTENDED_FRAME_BOUNDS := 9
    if (hwnd = "") {
        hwnd := WinExist() ; last found window
    }
    if (!isInteger(hwnd)) {
        hwnd := WinExist(hwnd)
    }
    RECT := Buffer(16)
    DllCall("dwmapi\DwmGetWindowAttribute"
        , "ptr", hwnd
        , "uint", DWMWA_EXTENDED_FRAME_BOUNDS
        , "ptr", RECT
        , "uint", RECT.Size
        , "uint")
    X := NumGet(RECT, 0, "int")
    Y := NumGet(RECT, 4, "int")
    W := NumGet(RECT, 8, "int") - X
    H := NumGet(RECT, 12, "int") - Y
}

; Move window and fix offset from invisible border.
WinMoveEx(X := "", Y := "", W := "", H := "", hwnd := "") {
    if (!isInteger(hwnd)) {
        hwnd := WinExist(hwnd)
    }
    if (hwnd = "") {
        hwnd := WinExist()
    }
    ; compare pos and get offset
    WinGetPosEx(&fX, &fY, &fW, &fH, hwnd)
    WinGetPos &wX, &wY, &wW, &wH, "ahk_id " hwnd
    xDiff := fX - wX
    hDiff := wH - fH
    nX := nY := nW := nH := ""
    pixel := 1
    ; new X, Y, W, H with offset corrected
    (X != "") && nX := X - xDiff - pixel
    (Y != "") && nY := Y - pixel
    (W != "") && nW := W + (xDiff + pixel) * 2
    (H != "") && nH := H + hDiff + (pixel * 2)
    WinMove(nX, nY, nW, nH, "ahk_id" hwnd)
}

; Функция для перемещения окна на левую половину экрана
Win__HalfLeft() {
    Win__GetDesktopPos(&X, &Y, &W, &H) ; Получение размеров рабочего стола
    hwnd := WinExist("A") ; Получение идентификатора активного окна
    WinMoveEx(X, Y, W // 2, H, hwnd)
}

; Функция для перемещения окна на правую половину экрана
Win__HalfRight() {
    Win__GetDesktopPos(&X, &Y, &W, &H) ; Получение размеров рабочего стола
    hwnd := WinExist("A") ; Получение идентификатора активного окна
    WinMoveEx(X + W // 2, Y, W // 2, H, hwnd)
}

; Обработка нажатия левой кнопки мыши
~LButton:: {
    global dragHappened
    global startX
    global startY

    ; Сброс флага перетаскивания
    dragHappened := false

    ; Получение начальных координат мыши
    CoordMode "Mouse", "Screen"
    MouseGetPos &startX, &startY
}

; Обработка движения мыши во время удержания левой кнопки
~LButton Up:: {
    global dragHappened
    global startX
    global startY

    ; Получение конечных координат мыши
    CoordMode "Mouse", "Screen"
    MouseGetPos &endX, &endY

    ; Проверка, было ли движение мыши
    if (startX != endX or startY != endY) {
        dragHappened := true
    }

    ; Если было перетаскивание, вывод сообщения
    if (dragHappened) {
        MouseGetPos &x, &y, &hwnd ; Обновление координат и идентификатора окна
        ; Определение части окна, на которой находится курсор
        ErrorLevel := SendMessage(0x84, 0, (x & 0xFFFF) | (y & 0xFFFF) << 16, , "ahk_id " hwnd)
        ; Использование регулярного выражения для определения части окна
        RegExMatch("ERROR TRANSPARENT NOWHERE CLIENT CAPTION SYSMENU SIZE MENU HSCROLL VSCROLL MINBUTTON MAXBUTTON LEFT RIGHT TOP TOPLEFT TOPRIGHT BOTTOM BOTTOMLEFT BOTTOMRIGHT BORDER OBJECT CLOSE HELP", "(?:\w+\s+){" . ErrorLevel + 2 & 0xFFFFFFFF . "}(?<AREA>\w+\b)", &HT)

        ; Если курсор не на заголовке, прекращение выполнения
        if (HT["AREA"] != "CAPTION") {
            Return
        }

        ; Получение текущих координат мыши
        CoordMode "Mouse", "Screen"
        MouseGetPos &Mouse_X, &Mouse_Y
        if (Mouse_X < 10) {
            Win__HalfLeft() ; Перемещение окна на левую половину экрана, если мышь у левого края
        }

        if (Mouse_X > (A_ScreenWidth - 10)) {
            Win__HalfRight() ; Перемещение окна на правую половину экрана, если мышь у правого края
        }
    }
}
