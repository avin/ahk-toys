#Persistent
;-------

Gui, Main: +AlwaysOnTop +resize MinSize200x200
Gui, Main: Show, w300 h300, DragZone
Gui, Main: Font, cRed s18, verdana
Gui, Main: Add, Text, center, Win+M to start
WinGet, mainWin_id, ID, A

Global SwitchedOn := 0

Gosub, BORDER
return

#m::
    if(SwitchedOn){
        SwitchedOn:=0
        SoundBeep, 300, 200
        WinSet, ExStyle, -0x20,ahk_id %mainWin_id%
        WinSet, Transparent, 255, ahk_id %mainWin_id%
    } else {
        SwitchedOn:=1
        SoundBeep,
        WinSet, ExStyle, ^0x20, ahk_id %mainWin_id%
        WinSet, Transparent, 0, ahk_id %mainWin_id%
    }

Return

BORDER:
    SetTimer, DrawRect, 50
    border_thickness = 4
    border_color = FF0000
Return

DrawRect:
    WinGetPos, x, y, w, h, ahk_id %mainWin_id%
    if (x="") {
        return
    }

    WinGet, isMaxed , MinMax, ahk_id %mainWin_id%
    if (isMaxed=0)
    {

        ; Gui, Border: +Lastfound +AlwaysOnTop +Toolwindow
        Gui, Border: +AlwaysOnTop +Lastfound
        iw:= w + border_thickness
        ih:= h + border_thickness
        w:= w + ( border_thickness * 2 )
        h:= h + ( border_thickness * 2 )
        x:= x - border_thickness
        y:= y - border_thickness
        Gui, Border: Color, FF0000
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
        Gui, Border: Show, w%w% h%h% x%x% y%y% NoActivate, BroadcastZone

    } else {
        WinSet, Region, 0-0 0-0 0-0 0-0 0-0 0-0 0-0 0-0 0-0 0-0
        Gui, Border: Show, w0 h0 x0 y0 NoActivate, BroadcastZone
    }
return

MainGuiClose:
ExitApp
Return
