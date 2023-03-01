#SingleInstance Force
SetBatchLines -1
SetWinDelay -1
OnExit, Uninitialize

global x := 0
global y := 0
global w := 0
global h := 0
global mouse_down := false
global mouse_x := 0
global mouse_y := 0

Gui, +HWNDhGui +AlwaysOnTop -Caption -DPIScale +LastFound +Border
Gui, Margin, 0,0
Gui, Show, x100 y100 w1000 h300

OnMessage(0x0201, "WM_LBUTTONDOWN")
OnMessage(0x0202, "WM_LBUTTONUP")

DllCall("LoadLibrary", "str", "magnification.dll")
DllCall("magnification.dll\MagInitialize")

WinGetPos x, y,w,h, ahk_id %hGui%

; Matrix := ""  ; ---------- INVERT
;     . "-1| 0| 0| 0| 0|"
;     . " 0|-1| 0| 0| 0|"
;     . " 0| 0|-1| 0| 0|"
;     . " 0| 0| 0| 1| 0|"
;     . " 1| 1| 1| 0| 1"

Matrix := "" ; ------------- WORK! RED is WHITE
    . " 1| 0| 0| -1.5| 0|"
    . " 0| 1| 0| 0| 0|"
    . " 0| 0| 1| 0| 0|"
    . " 0|0 | 0| 1| 0|"
    . " 0| 0| 0| 0| 0"

VarSetCapacity(MAGCOLOREFFECT, 100, 0)
Loop, Parse, Matrix, |
{
    NumPut(A_LoopField, MAGCOLOREFFECT, (A_Index - 1) * 4, "float")
}

hChildMagnifier := DllCall("CreateWindowEx", "UInt", 0, "Str", "Magnifier", "Str", "MagnifierWindow", "UInt", (WS_CHILD := 0x40000000), "Int", 0, "Int", 0, "Int", w, "Int", h, "Ptr", hGui, "UInt", 0, "Ptr", DllCall("GetWindowLong" (A_PtrSize=8 ? "Ptr" : ""), "Ptr", hGui, "Int", GWL_HINSTANCE := -100 , "ptr"), "UInt", 0, "ptr")
DllCall("magnification.dll\MagSetColorEffect", "ptr", hChildMagnifier, "ptr", &MAGCOLOREFFECT)
WinShow, ahk_id %hChildMagnifier%
Loop
{

    if (mouse_down) {
        MouseGetPos, current_x, current_y
        new_x := x + current_x - mouse_x
        new_y := y + current_y - mouse_y
        WinMove, A,, new_x, new_y, w, h
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

WM_LBUTTONDOWN(wParam, lParam) {
    mouse_down := true
    MouseGetPos, mouse_x, mouse_y
}

WM_LBUTTONUP(wParam, lParam) {
    mouse_down := false
}

Uninitialize:
    DllCall("magnification.dll\MagUninitialize")
ExitApp
return
