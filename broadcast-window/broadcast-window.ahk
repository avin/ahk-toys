#SingleInstance, Force
SetBatchLines, -1
CoordMode, Mouse , Screen
;-------

Gui, Main: +AlwaysOnTop +resize MinSize200x200
Gui, Main: Show, w600 h600, DragZone
Gui, Main: Font, cRed s18, verdana
Gui, Main: Add, Text, center, Win+M to start
WinGet, mainWin_id, ID, A

Global SwitchedOn := 0
Global IsDebug := 0 ; <<<<<<<<<< DEBUG MODE

border_thickness = 4
border_color = FFF000

Gosub, DrawBroadcastWin
return

#m::
    if(SwitchedOn){
        SwitchedOn:=0
        WinSet, ExStyle, -0x20,ahk_id %mainWin_id%
        WinSet, Transparent, 255, ahk_id %mainWin_id%

        Gui, Border: Destroy
    } else {
        SwitchedOn:=1
        WinSet, ExStyle, ^0x20, ahk_id %mainWin_id%
        WinSet, Transparent, 0, ahk_id %mainWin_id%

        WinGetPos x, y,w,h, ahk_id %mainWin_id%

        cx := px
        if(IsDebug){
            cx+=w
        }
        WinMove, BroadcastWin, , cx, py, w, h

        Gosub, DrawBorderWin
    }

Return

DrawBorderWin:
    WinGetPos, x, y, w, h, ahk_id %mainWin_id%
    if (x="") {
        return
    }

    WinGet, isMaxed , MinMax, ahk_id %mainWin_id%
    if (isMaxed=0)
    {
        Gui, Border: +AlwaysOnTop +Lastfound +ToolWindow
        iw:= w + border_thickness
        ih:= h + border_thickness
        w:= w + ( border_thickness * 2 )
        h:= h + ( border_thickness * 2 )
        x:= x - border_thickness
        y:= y - border_thickness
        Gui, Border: Color, % border_color
        Gui, Border: -Caption

        ; outer rectangle
        o1a := 0
        o1b := 0
        o2a := w
        o2b := 0
        o3a := w
        o3b := h
        o4a := 0
        o4b := h
        o5a := 0
        o5b := 0

        ; inner rectangle
        i1a := border_thickness
        i1b := border_thickness
        i2a := iw
        i2b := border_thickness
        i3a := iw
        i3b := ih
        i4a := border_thickness
        i4b := ih
        i5a := border_thickness
        i5b := border_thickness

        ; Draw outer & inner window(s)
        WinSet, Region, %o1a%-%o1b% %o2a%-%o2b% %o3a%-%o3b% %o4a%-%o4b% %o5a%-%o5b% %i1a%-%i1b% %i2a%-%i2b% %i3a%-%i3b% %i4a%-%i4b% %i5a%-%i5b%
        Gui, Border: Show, w%w% h%h% x%x% y%y% NoActivate, BorderWin

    } else {
        WinSet, Region, 0-0 0-0 0-0 0-0 0-0 0-0 0-0 0-0 0-0 0-0
        Gui, Border: Show, w0 h0 x0 y0 NoActivate, BorderWin
    }
return

DrawBroadcastWin:
    Rx = 256
    Ry = 256
    Gui BroadcastWin: New, -Caption +AlwaysOnTop hwndBroadcastWinHwnd
    Gui BroadcastWin: Margin, 0,0
    Gui BroadcastWin: Show, % "w" Rx " h" Ry " x0 y0", BroadcastWin
    WinSet Transparent, 0, ahk_id %BroadcastWinHwnd% ; makes the window invisible to magnification
    if(IsDebug){
        WinSet Transparent, 255, ahk_id %BroadcastWinHwnd%
    }
    WinGet PrintSourceID, ID
    WinSet, ExStyle, +0x80020, ahk_id %BroadcastWinHwnd%

    hdd_frame := DllCall("GetDC", UInt, PrintSourceID)
    hdc_frame := DllCall("GetDC", UInt, BroadcastWinHwnd)

    SetTimer RepaintBroadcastWindow, 16 ; 16=60fps
Return

RepaintBroadcastWindow:
    WinGetPos x, y,w,h, ahk_id %mainWin_id%
    px:=x
    py:=y

    xz := x
    yz := y

    DllCall("gdi32.dll\BitBlt", UInt,hdc_frame, Int,0, Int,0, Int,Rx, Int,Ry
    , UInt,hdd_frame, UInt,xz, UInt,yz, UInt,0xCC0020)
Return

BroadcastWinGuiSize:
    Rx := A_GuiWidth
    Ry := A_GuiHeight
Return

BroadcastWinGuiClose:
    DllCall("gdi32.dll\DeleteDC", UInt,hdc_frame )
    DllCall("gdi32.dll\DeleteDC", UInt,hdd_frame )
Return

MainGuiClose:
ExitApp
Return
