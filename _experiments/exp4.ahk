#NoEnv
SetBatchLines -1

CoordMode Mouse, Screen
OnExit GuiClose

Rx = 600
Ry = 600
Gui -Caption +AlwaysOnTop
Gui Margin, 0,0
Gui Show, % "w" Rx " h" Ry " x0 y0", Magnifier
WinGet MagnifierID, id, Magnifier
WinSet Transparent, 255, Magnifier ; makes the window invisible to magnification
WinGet PrintSourceID, ID
OnMessage( 0x200, "WM_MOUSEMOVE" )

hdd_frame := DllCall("GetDC", UInt, PrintSourceID)
hdc_frame := DllCall("GetDC", UInt, MagnifierID)

SetTimer Repaint, 16 ; flow through
Return

Repaint:
    WinGetPos x, y,w,h, Magnifier
    x += w ; TODO убрать!

    xz := x
    yz := y

    DllCall("gdi32.dll\StretchBlt", UInt,hdc_frame, Int,0, Int,0, Int,Rx, Int,Ry
    , UInt,hdd_frame, UInt,xz, UInt,yz, Int,Rx, Int,Ry, UInt,0xCC0020) ; SRCCOPY
Return

GuiSize:
    Rx := A_GuiWidth
    Ry := A_GuiHeight
Return

WM_MOUSEMOVE( wparam, lparam, msg, hwnd )
{
    if wparam = 1 ; LButton
        PostMessage, 0xA1, 2,,, A ; WM_NCLBUTTONDOWN
}

#x::
GuiClose:
    DllCall("gdi32.dll\DeleteDC", UInt,hdc_frame )
    DllCall("gdi32.dll\DeleteDC", UInt,hdd_frame )
ExitApp

In(x,a,b) { ; closest number to x in [a,b]
IfLess x,%a%, Return a
IfLess b,%x%, Return b
Return x
}
