#Requires AutoHotkey v2.0
#SingleInstance Force

CoordMode("Mouse", "Screen")
;-------

SwitchedOn := 0
IsDrawMouseCursor := 1
BroadcastWinTitle := "BroadcastWin"
BorderWinTitle := "BorderWin"
MainWinTitle := "PUT ME SOMEWHERE"

px:=0

; ----------

MainGui := Gui("+AlwaysOnTop + resize MinSize200x200", MainWinTitle)
MainGui.Show("w600 h600")
MainGui.SetFont("cRed s18", "verdana")
MainGui.OnEvent("Close", MainGui_Close)
MainGui_Close(GuiObj) {
    ExitApp()
}

MainGui.AddText("center", "Win + M to start")

Btn := MainGui.AddButton("", "1920x1080")
Btn.OnEvent("Click", HandleSet1920x1080Size)  ; Call

mainWin_id := WinGetID("A")

border_thickness := 4
border_color := "FFF000"

DrawBroadcastWin()
DetectMinimizeBroadcastWin()

return

#m:: {
    global
    if (SwitchedOn) {
        SwitchedOn := 0
        WinSetExStyle(-0x20, "ahk_id " mainWin_id)
        WinSetTransparent(255, "ahk_id " mainWin_id)

        MainGui.Opt("-ToolWindow")

        BorderGui.Destroy()
    } else {
        SwitchedOn := 1
        WinSetExStyle(0x20, "ahk_id " mainWin_id)
        WinSetTransparent(0, "ahk_id " mainWin_id)

        MainGui.Opt("+ToolWindow")


        WinGetPos(&x, &y, &w, &h, "ahk_id " mainWin_id)

        BroadcastWin.Move(px, py, w, h)

        DrawBorderWin()
    }
}


#NumpadDot:: {
    global
    IsDrawMouseCursor := IsDrawMouseCursor ? 0 : 1
    if (IsDrawMouseCursor) {
        SoundBeep(1500, 50)
    } else {
        SoundBeep(600, 50)
    }

    UpdateBroadcastWinTitle()
}

DrawBorderWin() {
    global
    WinGetPos(&x, &y, &w, &h, "ahk_id " mainWin_id)
    if (x = "") {
        return
    }

    isMaxed := WinGetMinMax("ahk_id " mainWin_id)
    if (isMaxed = 0) {
        BorderGui := Gui("+AlwaysOnTop +Lastfound +ToolWindow")

        iw := w + border_thickness
        ih := h + border_thickness
        w := w + (border_thickness * 2)
        h := h + (border_thickness * 2)
        x := x - border_thickness
        y := y - border_thickness

        BorderGui.Opt("-Caption")
        ; BorderGui.SetColor(border_color)
        BorderGui.BackColor := border_color

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
        WinSetRegion(o1a "-" o1b " " o2a "-" o2b " " o3a "-" o3b " " o4a "-" o4b " " o5a "-" o5b " " i1a "-" i1b " " i2a "-" i2b " " i3a "-" i3b " " i4a "-" i4b " " i5a "-" i5b)
        BorderGui.Show("w" w " h" h " x" x " y" y " NoActivate")
        BorderGui.Title := BorderWinTitle
    } else {
        WinSetRegion("0-0 0-0 0-0 0-0 0-0 0-0 0-0 0-0 0-0 0-0")
        BorderGui.Show("w0 h0 x0 y0 NoActivate", BorderWinTitle)
        BorderGui.Title := BorderWinTitle
    }

}

DrawBroadcastWin() {
    global

    Rx := 256
    Ry := 256
    BroadcastWin := Gui("+AlwaysOnTop -Caption")
    BroadcastWinHwnd := BroadcastWin.Hwnd
    BroadcastWin.MarginX := 0
    BroadcastWin.MarginY := 0
    BroadcastWin.Show("w" Rx " h" Ry " x0 y0")

    BroadcastWin.OnEvent("Size", BroadcastWin_Size)
    BroadcastWin_Size(GuiObj, MinMax, Width, Height) {
        Rx := Width
        Ry := Height
    }

    BroadcastWin.OnEvent("Close", BroadcastWin_Close)
    BroadcastWin_Close(GuiObj) {
        DllCall("gdi32.dll\DeleteDC", "UInt", hdc_frame)
        DllCall("gdi32.dll\DeleteDC", "UInt", hdd_frame)
    }

    UpdateBroadcastWinTitle()

    WinSetTransparent(0, "ahk_id " BroadcastWinHwnd)

    PrintSourceID := 0
    WinSetExStyle(+0x80020, "ahk_id " BroadcastWinHwnd)

    hdd_frame := DllCall("GetDC", "UInt", PrintSourceID)
    hdc_frame := DllCall("GetDC", "UInt", BroadcastWinHwnd)

    SetTimer RepaintBroadcastWindow, 16 ; 16=60fps
}


RepaintBroadcastWindow() {
    global
    WinGetPos(&x, &y, &w, &h, "ahk_id " mainWin_id)
    MouseGetPos(&mx, &my)

    px := x
    py := y

    xz := x
    yz := y

    DllCall("gdi32.dll\BitBlt", "UInt", hdc_frame, "Int", 0, "Int", 0, "Int", Rx, "Int", Ry
        , "UInt", hdd_frame, "UInt", xz, "UInt", yz, "UInt", 0xCC0020)

    if (IsDrawMouseCursor) {
        mx -= x
        my -= y
        CaptureCursor(hdc_frame, mx, my)
    }
}


HandleSet1920x1080Size(*) {
    global
    SM_CXSIZEFRAME := 32
    SM_CYSIZEFRAME := 33
    SM_CYMENU := 15
    SM_CYCAPTION := 4

    Height := 1080 - (SysGet(SM_CYCAPTION) + SysGet(SM_CYSIZEFRAME) * 2)
    Width := 1920 - (SysGet(SM_CYSIZEFRAME) * 2)

    MainGui.Show("w" Width " h" Height "xCenter yCenter")
}


CaptureCursor(hDC, posX, posY) {
    global
    CURSORINFO := Buffer(A_PtrSize=8?24:20, 0)
    NumPut("UInt", A_PtrSize=8?24:20, CURSORINFO, 0,)
    DllCall("user32\GetCursorInfo", "Ptr", CURSORINFO)
    vState := NumGet(CURSORINFO, 4, "UInt") ;flags
    hCursor := NumGet(CURSORINFO, 8, "UInt") ;hCursor
    vCurX := NumGet(CURSORINFO, A_PtrSize = 8 ? 16 : 12, "Int") ;ptScreenPos ;x
    vCurY := NumGet(CURSORINFO, A_PtrSize = 8 ? 20 : 16, "Int") ;ptScreenPos ;y
    if vState && (hCursor := DllCall("user32\CopyIcon", "Ptr", hCursor, "Ptr"))
    {
        ICONINFO := Buffer(A_PtrSize = 8 ? 32 : 20, 0)
        DllCall("user32\GetIconInfo", "Ptr", hCursor, "Ptr", ICONINFO)
        vHotspotX := NumGet(ICONINFO, 4, "UInt") ;xHotspot
        vHotspotY := NumGet(ICONINFO, 8, "UInt") ;yHotspot
        hBMMask := NumGet(ICONINFO, A_PtrSize = 8 ? 16 : 12, "Ptr") ;hbmMask
        hBMColor := NumGet(ICONINFO, A_PtrSize = 8 ? 24 : 16, "Ptr") ;hbmColor

        DllCall("user32\DrawIcon", "Ptr", hDC, "Int", posX, "Int", posY, "Ptr", hCursor)
        DllCall("user32\DestroyIcon", "Ptr", hCursor)
        if hBMMask {
            DllCall("gdi32\DeleteObject", "Ptr", hBMMask)
        }
        if hBMColor {
            DllCall("gdi32\DeleteObject", "Ptr", hBMColor)
        }
    }
}

UpdateBroadcastWinTitle() {
    global
    newTitle := BroadcastWinTitle
    if (IsDrawMouseCursor) {
        newTitle .= " (M)"
    }
    WinSetTitle(newTitle, "ahk_id " BroadcastWinHwnd)
}


DetectMinimizeBroadcastWin() {
    global
    DllCall("RegisterShellHookWindow", "UInt", BroadcastWinHwnd)
    MsgNum := DllCall("RegisterWindowMessage", "Str", "SHELLHOOK")
    OnMessage(MsgNum, ShellMessage)
}

ShellMessage(wParam, lParam, msg, hwnd) {
    global
    status := WinGetMinMax("ahk_id " BroadcastWinHwnd)

    if (status = -1) {
        WinActivate("ahk_id " BroadcastWinHwnd)
    }
}
