#SingleInstance Force
SetBatchLines -1
SetWinDelay -1
OnExit, Uninitialize

global x := 0
global y := 0
global w := 0
global h := 0

Gui, +HWNDhGui +AlwaysOnTop -Caption -DPIScale +LastFound +Border
Gui, Margin, 0,0
Gui, Show, x1080 y870 w1380 h430

OnMessage(0x0201, "WM_LBUTTONDOWN")
OnMessage(0x0202, "WM_LBUTTONUP")
OnMessage(WM_KEYDOWN := 0x100, "ON_KEYDOWN")

DllCall("LoadLibrary", "str", "magnification.dll")
DllCall("magnification.dll\MagInitialize")

WinGetPos x, y,w,h, ahk_id %hGui%

WinSet, AlwaysOnTop, On, ahk_id %hGui%
WinSet, Transparent, 255, ahk_id %hGui%
WinSet, ExStyle, ^0x20, ahk_id %hGui%

hChildMagnifier := DllCall("CreateWindowEx", "UInt", 0, "Str", "Magnifier", "Str", "MagnifierWindow", "UInt", (WS_CHILD := 0x40000000), "Int", 0, "Int", 0, "Int", w, "Int", h, "Ptr", hGui, "UInt", 0, "Ptr", DllCall("GetWindowLong" (A_PtrSize=8 ? "Ptr" : ""), "Ptr", hGui, "Int", GWL_HINSTANCE := -100 , "ptr"), "UInt", 0, "ptr")
WinShow, ahk_id %hChildMagnifier%

Matrix := "" ; ---------- INVERT
    . "-1| 0| 0| 0| 0|"
    . " 0|-1| 0| 0| 0|"
    . " 0| 0|-1| 0| 0|"
    . " 0| 0| 0| 1| 0|"
    . " 1| 1| 1| 0| 1"

VarSetCapacity(MAGCOLOREFFECT, 100, 0)
Loop, Parse, Matrix, |
{
    NumPut(A_LoopField, MAGCOLOREFFECT, (A_Index - 1) * 4, "float")
}

DllCall("magnification.dll\MagSetColorEffect", "ptr", hChildMagnifier, "ptr", &MAGCOLOREFFECT)

Loop
{

    CoordMode, Pixel, Screen
    PixelGetColor, color, 960, 1282

    if (color = "0xADAAAD") ;
    {
        WinSet, Transparent, 255, ahk_id %hGui%
    }
    else
    {
        WinSet, Transparent, 0, ahk_id %hGui%
    }

    WinGetPos x, y,w,h, ahk_id %hGui%

    x := x+1 ; компенсация для Border
    y := y+1

    if (A_PtrSize = 8)
    {
        VarSetCapacity(RECT, 16, 0)
        NumPut(x, RECT, 0, "Int")
        NumPut(y, RECT, 4, "Int")
        NumPut(w, RECT, 8, "Int")
        NumPut(h, RECT, 12, "Int")
        DllCall("magnification.dll\MagSetWindowSource", "Ptr", hChildMagnifier, "Ptr", &RECT)
    }
    else {
        DllCall("magnification.dll\MagSetWindowSource", "Ptr", hChildMagnifier, "Int", x, "Int", y, "Int", w, "Int", h)
    }

    ; Выход по Esc;
    if GetKeyState("Escape", "P"){
        break
    }
}

Uninitialize:
    DllCall("magnification.dll\MagUninitialize")
ExitApp
return
