#SingleInstance, Force
SetBatchLines, -1
CoordMode, Mouse , Screen
;-------

Global SwitchedOn := 0
Global IsDebug := 1 ; <<<<<<<<<< DEBUG MODE
Global IsDrawMouseCursor := 1

Global BroadcastWinTitle := "BroadcastWin"
Global BorderWinTitle := "BorderWin"
Global MainWinTitle := "PUT ME SOMEWHERE"

; ----------

Gui, Main: +AlwaysOnTop +resize MinSize200x200
Gui, Main: Show, w600 h600, % MainWinTitle
Gui, Main: Font, cRed s18, verdana
Gui, Main: Add, Text, center, Win+M to start
WinGet, mainWin_id, ID, A

border_thickness = 4
border_color = FFF000

Gosub, DrawBroadcastWin

return

#m::
    if(SwitchedOn){
        SwitchedOn:=0
        WinSet, ExStyle, -0x20,ahk_id %mainWin_id%
        WinSet, Transparent, 255, ahk_id %mainWin_id%
        Gui, Main: -ToolWindow

        Gui, Border: Destroy
    } else {
        SwitchedOn:=1
        WinSet, ExStyle, ^0x20, ahk_id %mainWin_id%
        WinSet, Transparent, 0, ahk_id %mainWin_id%
        Gui, Main: +ToolWindow

        WinGetPos x, y,w,h, ahk_id %mainWin_id%

        cx := px
        if(IsDebug){
            cx+=w
        }
        WinMove, BroadcastWin, , cx, py, w, h

        Gosub, DrawBorderWin
    }
Return

#NumpadDot::
    IsDrawMouseCursor := IsDrawMouseCursor ? 0 : 1
    if(IsDrawMouseCursor){
        SoundBeep, 1500,50
    } else {
        SoundBeep, 600,50
    }

    Gosub, UpdateBroadcastWinTitle
Return

DrawBorderWin:
    WinGetPos, x, y, w, h, ahk_id %mainWin_id%
    if (x="") {
        return
    }

    WinGet, isMaxed , MinMax, ahk_id %mainWin_id%
    if (isMaxed=0)
    {
        ;Gui, Border: +AlwaysOnTop +Lastfound +ToolWindow
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
        Gui, Border: Show, w%w% h%h% x%x% y%y% NoActivate, % BorderWinTitle

    } else {
        WinSet, Region, 0-0 0-0 0-0 0-0 0-0 0-0 0-0 0-0 0-0 0-0
        Gui, Border: Show, w0 h0 x0 y0 NoActivate, % BorderWinTitle
    }
return

DrawBroadcastWin:
    Rx = 256
    Ry = 256
    Gui BroadcastWin: New, +AlwaysOnTop -Caption hwndBroadcastWinHwnd
    Gui BroadcastWin: Margin, 0,0
    Gui BroadcastWin: Show, % "w" Rx " h" Ry " x0 y0"
    Gosub, UpdateBroadcastWinTitle
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
    MouseGetPos, mx, my
    px:=x
    py:=y

    xz := x
    yz := y

    DllCall("gdi32.dll\BitBlt", UInt,hdc_frame, Int,0, Int,0, Int,Rx, Int,Ry
    , UInt,hdd_frame, UInt,xz, UInt,yz, UInt,0xCC0020)

    if(IsDrawMouseCursor){
        mx -= x
        my -= y
        CaptureCursor(hdc_frame, mx, my)
    }
Return

BroadcastWinGuiSize:
    Rx := A_GuiWidth
    Ry := A_GuiHeight
Return

BroadcastWinGuiClose:
    DllCall("gdi32.dll\DeleteDC", UInt,hdc_frame )
    DllCall("gdi32.dll\DeleteDC", UInt,hdd_frame )
Return

CaptureCursor(hDC, posX, posY)
{
    VarSetCapacity(CURSORINFO, A_PtrSize=8?24:20, 0)
    NumPut(A_PtrSize=8?24:20, &CURSORINFO, 0, "UInt")
    DllCall("user32\GetCursorInfo", Ptr,&CURSORINFO)
    vState := NumGet(&CURSORINFO, 4, "UInt") ;flags
    hCursor := NumGet(&CURSORINFO, 8, "UInt") ;hCursor
    vCurX := NumGet(&CURSORINFO, A_PtrSize=8?16:12, "Int") ;ptScreenPos ;x
    vCurY := NumGet(&CURSORINFO, A_PtrSize=8?20:16, "Int") ;ptScreenPos ;y
    if vState && (hCursor := DllCall("user32\CopyIcon", Ptr,hCursor, Ptr))
    {
        VarSetCapacity(ICONINFO, A_PtrSize=8?32:20, 0)
        DllCall("user32\GetIconInfo", Ptr,hCursor, Ptr,&ICONINFO)
        ;vIsIcon := NumGet(&ICONINFO, 0, "Int") ;fIcon
        vHotspotX := NumGet(&ICONINFO, 4, "UInt") ;xHotspot
        vHotspotY := NumGet(&ICONINFO, 8, "UInt") ;yHotspot
        hBMMask := NumGet(&ICONINFO, A_PtrSize=8?16:12, "Ptr") ;hbmMask
        hBMColor := NumGet(&ICONINFO, A_PtrSize=8?24:16, "Ptr") ;hbmColor

        DllCall("user32\DrawIcon", Ptr,hDC, Int,posX, Int,posY, Ptr,hCursor)
        DllCall("user32\DestroyIcon", Ptr,hCursor)
        if hBMMask {
            DllCall("gdi32\DeleteObject", Ptr,hBMMask)
        }
        if hBMColor {
            DllCall("gdi32\DeleteObject", Ptr,hBMColor)
        }
    }
}

UpdateBroadcastWinTitle:
    newTitle:=BroadcastWinTitle
    if(IsDrawMouseCursor){
        newTitle.=" (M)"
    }
    WinSetTitle, % "ahk_id " BroadcastWinHwnd,, %newTitle%
Return

MainGuiClose:
ExitApp
Return
