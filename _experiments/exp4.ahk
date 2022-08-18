#NoEnv
SetBatchLines -1

CoordMode Mouse, Screen
OnExit GuiClose
zoom = 1 ; initial magnification, 1..32
antialize = 0
Rx = 256 ; half vertical/horizontal side of magnifier window
Ry = 256
; GUI to show the magnified image
Gui +AlwaysOnTop +Resize
Gui Show, % "w" Rx " h" Ry " x0 y0", Magnifier
WinGet MagnifierID, id, Magnifier
WinSet Transparent, 255, Magnifier ; makes the window invisible to magnification
WinGet PrintSourceID, ID

hdd_frame := DllCall("GetDC", UInt, PrintSourceID)
hdc_frame := DllCall("GetDC", UInt, MagnifierID)

SetTimer Repaint, 16 ; flow through
Return

Repaint:
    WinGetPos x, y,w,h, Magnifier
    x += w; TODO убрать!

    xz := x
    yz := y

    DllCall("gdi32.dll\StretchBlt", UInt,hdc_frame, Int,0, Int,0, Int,Rx, Int,Ry
    , UInt,hdd_frame, UInt,xz, UInt,yz, Int,Rx, Int,Ry, UInt,0xCC0020) ; SRCCOPY
Return

GuiSize:
    Rx := A_GuiWidth
    Ry := A_GuiHeight
Return

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
