#NoEnv
#Persistent
OnExit, Uninitialize

Gui, +E0x80000
; Gui, +AlwaysOnTop
Gui, Show, w640 h480, MagnifierWindowAHK
Gui, +LastFound
Gui, Add, Text, 0xE w640 h480 hwndhPic
WinGet, guiHwnd, Id

WinSet, Transparent, 255

hDC := DllCall("GetDC", "Ptr", 0)
hMemDC := DllCall("CreateCompatibleDC", "UInt", hDC)
hOldBitmap := DllCall("SelectObject", "UInt", hMemDC, "UInt", hBitmap)

hInstance := DllCall("GetWindowLong", "Ptr", guiHwnd, "Int", GWL_HINSTANCE:=(-6))

DllCall("LoadLibrary", "Str", "magnification.dll")
DllCall("magnification.dll\MagInitialize")

WS_CHILD := 0x40000000
WS_VISIBLE := 0x10000000
MS_SHOWMAGNIFIEDCURSOR := 0x1

magHwnd := DllCall("CreateWindowEx", "UInt", 0, "Str", "Magnifier", "Str", "MagnifierWindow", "UInt", WS_CHILD | MS_SHOWMAGNIFIEDCURSOR | WS_VISIBLE, "Int", 0, "Int", 0, "Int", 640, "Int", 480, "UInt", guiHwnd, "UInt", 0, "UInt", hInstance, "UInt", 0)

; Magnification transform matrix
Matrix := "1|0|0|0|" . "0|1|0|0|" . "0|0|1|0|"
StringSplit, Matrix, Matrix, |
VarSetCapacity(magMatrix, 48, 0)
Loop, 12
{
    NumPut(Matrix, magMatrix, (A_Index-1)*4, "float")
}

DllCall("magnification.dll\MagSetWindowTransform", "UInt", magHwnd, "Ptr", &magMatrix)
DllCall("magnification.dll\MagSetWindowSource", "UInt", magHwnd, "Int", 0, "Int", 0, "Int", 640, "Int", 480)

; Return

Loop
{
    ; Получаем позицию и размер окна
    WinGetPos, WinX, WinY, WinWidth, WinHeight, A

    ; Определяем размер лупы, который будет использоваться для получения изображения
    MagWidth := 640
    MagHeight := 480

    ; Определяем область, которая будет отображаться в лупе
    MagX := (WinX + WinWidth/2) - MagWidth/2 + 100
    MagY := (WinY + WinHeight/2) - MagHeight/2 + 100

    ; Устанавливаем область лупы
    DllCall("magnification.dll\MagSetWindowSource", "UInt", magHwnd, "Int", MagX, "Int", MagY, "Int", MagWidth, "Int", MagHeight)

    ; Получаем изображение из лупы
    DllCall("magnification.dll\MagGetDesktopImageRect", "UInt", magHwnd, "UInt", &MagRect)

    ; Создаем копию полученного изображения и инвертируем цвета
    DllCall("CreateCompatibleDC", "UInt", 0)
    hBitmap := DllCall("CreateCompatibleBitmap", "UInt", A_ScreenDC, "Int", 640, "Int", 480)
    hOldBitmap := DllCall("SelectObject", "UInt", A_HDC, "UInt", hBitmap)
    DllCall("magnification.dll\MagGetDesktopImage", "UInt", magHwnd, "Int", MagRect.Left, "Int", MagRect.Top, "Int", MagWidth, "Int", MagHeight, "UInt", hBitmap, "UInt", MagWidth, "UInt", MagHeight)
    DllCall("InvertRect", "UInt", A_HDC, "Int", 0, "Int", 0, "Int", 640, "Int", 480)

    ; Отображаем полученное изображение на окне
    ; Gui, 2:Destroy
    ; Gui, 2:+E0x80000
    ; Gui, 2:Color, FFFFFF
    ; Gui, 2:Show, w640 h480, Inverted Magnifier
    ; Gui, 2:+LastFound
    ; Gui, Add, Picture, % "hwnd" hBitmap
    ; SendMessage, 0x172, 0, hBitmap, , ahk_id %hPic%
    Gui, Add, Pic, +Border, % "HBITMAP:*" hBitmap
    ; Gui, Show
    ; WinSet, Transparent, 255, Inverted Magnifier


    Sleep, 10
}

Return

Uninitialize:
    Gui, Destroy
    DllCall("magnification.dll\MagUninitialize")
ExitApp
