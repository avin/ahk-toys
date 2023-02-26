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

Gui, +HWNDhGui -Caption -DPIScale +LastFound -Border ;  WS_EX_COMPOSITED := E0x02000000  WS_EX_LAYERED := E0x00080000
; Gui, +HWNDhGui +AlwaysOnTop -Caption -DPIScale +LastFound -Border ;  WS_EX_COMPOSITED := E0x02000000  WS_EX_LAYERED := E0x00080000
; Gui, +HWNDhGui +AlwaysOnTop -DPIScale ;  WS_EX_COMPOSITED := E0x02000000  WS_EX_LAYERED := E0x00080000
; Gui, +HWNDhGui -DPIScale +toolwindow -Caption +E0x02000000 +E0x00080000 +E0x20 ;  WS_EX_COMPOSITED := E0x02000000  WS_EX_LAYERED := E0x00080000
Gui, Margin, 0,0
Gui, Show, x100 y100 w800 h600
; OnMessage( 0x200, "WM_MOUSEMOVE" ) ; окно будет драгаться мышкой
; OnMessage(0x0216, "WM_MOVING")
;OnMessage(0x0003, "WM_MOVING")
; WinGet, mainWin_id, ID, A
OnMessage(0x0201, "WM_LBUTTONDOWN")
OnMessage(0x0202, "WM_LBUTTONUP")

DllCall("LoadLibrary", "str", "magnification.dll")
DllCall("magnification.dll\MagInitialize")

WinGetPos x, y,w,h, ahk_id %hGui%
hChildMagnifier := DllCall("CreateWindowEx", "UInt", 0, "Str", "Magnifier", "Str", "MagnifierWindow", "UInt", (WS_CHILD := 0x40000000)|(MS_INVERTCOLORS := 0x0004), "Int", 0, "Int", 0, "Int", w, "Int", h, "Ptr", hGui, "UInt", 0, "Ptr", DllCall("GetWindowLong" (A_PtrSize=8 ? "Ptr" : ""), "Ptr", hGui, "Int", GWL_HINSTANCE := -100 , "ptr"), "UInt", 0, "ptr")
WinShow, ahk_id %hChildMagnifier%
Loop
{
    ;Sleep, 1

    ;VarSetCapacity(RECT, 16)
    ; DllCall("GetWindowInfo", "ptr", hGui, "ptr", &WINDOWINFO)
    ; x := NumGet(WINDOWINFO, 20, "int")
    ; y := NumGet(WINDOWINFO, 8, "int")
    ; w := NumGet(WINDOWINFO, 28, "int") - x
    ; h := NumGet(WINDOWINFO, 32, "int") - y

    ; VarSetCapacity(RECT, 60, 0)
    ; DllCall("GetWindowRect", "Ptr", hGui, "Ptr", &RECT)
    ; x := NumGet(RECT, 0, "int")
    ; y := NumGet(RECT, 4, "int")

    ; WinGetPos x, y,w,h, A

    ; MouseGetPos, x, y

    if (mouse_down) {
        ; Calculate the new position of the window
        MouseGetPos, current_x, current_y
        new_x := x + current_x - mouse_x
        new_y := y + current_y - mouse_y
        ; Move the window
        WinMove, A,, new_x, new_y, w, h
    }

    WinGetPos x, y,w,h, ahk_id %hGui%

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
    ; OutputDebug, 1
}

; LButton::
;     ; Get the position of the window
;     WinGetPos, x, y, w, h, A
;     ; Get the position of the mouse
;     mouse_down := true
;     MouseGetPos, mouse_x, mouse_y
;     ; Capture the mouse
;     ;SetCapture()
; return

; LButtonUp::
;     ; Release the mouse capture
;     mouse_down := false
;     ;ReleaseCapture()
; return

WM_LBUTTONDOWN(wParam, lParam) {
    mouse_down := true
    MouseGetPos, mouse_x, mouse_y
}

WM_LBUTTONUP(wParam, lParam) {
    mouse_down := false
}

WM_MOUSEMOVE( wparam, lparam, msg, hwnd )
{
    if wparam = 1 ; LButton
        PostMessage, 0xA1, 2,,, A ; WM_NCLBUTTONDOWN
}

WM_MOVING(wParam, lParam) {
    ; Extract the x and y coordinates from the lParam
    x := NumGet(lParam, 0, "short")
    y := NumGet(lParam, 4, "short")
    ; Output the coordinates to the debug window
    ;OutputDebug, % lParam
    ; MsgBox, % x
    ; Return 0 to allow the window to continue moving
    return 0
}

Uninitialize:
    DllCall("magnification.dll\MagUninitialize")
ExitApp
return
