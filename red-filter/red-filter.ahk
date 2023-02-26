#SingleInstance Force
SetBatchLines -1
SetWinDelay -1
OnExit, Uninitialize

Status = 0
x := 550
y := 256
w := 260
h := 260

; Gui, +HWNDhGui +AlwaysOnTop
; DllCall("GetWindowBand", "ptr", hGui, "uint*", band)
; Gui, Destroy

; Gui, +HWNDhGui -DPIScale -Caption +AlwaysOnTop +E0x02000000 +E0x00080000 +E0x20 ;  WS_EX_COMPOSITED := E0x02000000  WS_EX_LAYERED := E0x00080000
; Gui, +HWNDhGui +AlwaysOnTop ;  WS_EX_COMPOSITED := E0x02000000  WS_EX_LAYERED := E0x00080000
Gui, +HWNDhGui +AlwaysOnTop -Caption -DPIScale +LastFound -Border ;  WS_EX_COMPOSITED := E0x02000000  WS_EX_LAYERED := E0x00080000
Gui, Margin, 0,0
Gui, Show, x100 y100 w800 h600
OnMessage( 0x200, "WM_MOUSEMOVE" )
; WinGet, mainWin_id, ID, A
DllCall("LoadLibrary", "str", "magnification.dll")
DllCall("magnification.dll\MagInitialize")
; WinGetPos x, y,w,h, ahk_id %mainWin_id%
WinGetPos x, y,w,h, ahk_id %hGui%
hChildMagnifier := DllCall("CreateWindowEx", "UInt", 0, "Str", "Magnifier", "Str", "MagnifierWindow", "UInt", (WS_CHILD := 0x40000000)|(MS_INVERTCOLORS := 0x0004), "Int", 0, "Int", 0, "Int", w, "Int", h, "Ptr", hGui, "UInt", 0, "Ptr", DllCall("GetWindowLong" (A_PtrSize=8 ? "Ptr" : ""), "Ptr", hGui, "Int", GWL_HINSTANCE := -100 , "ptr"), "UInt", 0, "ptr")
WinShow, ahk_id %hChildMagnifier%
Loop
{
    Sleep, 10

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
}

WM_MOUSEMOVE( wparam, lparam, msg, hwnd )
{
    if wparam = 1 ; LButton
        PostMessage, 0xA1, 2,,, A ; WM_NCLBUTTONDOWN
}

Uninitialize:
    DllCall("magnification.dll\MagUninitialize")
ExitApp
return
