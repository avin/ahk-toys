#Requires AutoHotkey v2.0
#SingleInstance Force

CoordMode("Mouse", "Screen")

Main()

Main() {
    global MainGui
    global border_thickness

    MainGui := Gui("+AlwaysOnTop + resize MinSize200x200", "PUT ME SOMEWHERE")
    MainGui.Show("w600 h600")
    MainGui.SetFont("cRed s18", "verdana")
    MainGui.OnEvent("Close", MainGui_Close)
    MainGui_Close(GuiObj) {
        ExitApp()
    }

    MainGui.AddText("center", "Win + M to start")

    ResizeBtn := MainGui.AddButton("", "1920x1080")
    ResizeBtn.OnEvent("Click", HandleSet1920x1080Size)

    border_thickness := 4

    DrawBroadcastWin()
    DetectMinimizeBroadcastWin()
}


#m:: {
    static switchedOn := 0

    if (switchedOn) {
        switchedOn := 0
        WinSetExStyle(-0x20, "ahk_id " MainGui.Hwnd)
        WinSetTransparent(255, "ahk_id " MainGui.Hwnd)

        MainGui.Opt("-ToolWindow")

        BorderGui.Destroy()
    } else {
        switchedOn := 1
        WinSetExStyle(0x20, "ahk_id " MainGui.Hwnd)
        WinSetTransparent(0, "ahk_id " MainGui.Hwnd)

        MainGui.Opt("+ToolWindow")

        WinGetPos(&x, &y, &w, &h, "ahk_id " MainGui.Hwnd)
        BroadcastWin.Move(px, py, w, h)

        DrawBorderWin()
    }
}


DrawBorderWin() {
    global BorderGui

    WinGetPos(&x, &y, &w, &h, "ahk_id " MainGui.Hwnd)
    if (x = "") {
        return
    }

    isMaxed := WinGetMinMax("ahk_id " MainGui.Hwnd)
    if (isMaxed = 0) {
        BorderGui := Gui("+AlwaysOnTop +Lastfound +ToolWindow")
        BorderGui.Title := "BorderWin"

        iw := w + border_thickness
        ih := h + border_thickness
        w := w + (border_thickness * 2)
        h := h + (border_thickness * 2)
        x := x - border_thickness
        y := y - border_thickness

        BorderGui.Opt("-Caption")
        BorderGui.BackColor := "FFF000"

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
    } else {
        WinSetRegion("0-0 0-0 0-0 0-0 0-0 0-0 0-0 0-0 0-0 0-0")
        BorderGui.Show("w0 h0 x0 y0 NoActivate")
    }
}


DrawBroadcastWin() {
    global BroadcastWin
    global hdc_frame
    global hdd_frame
    global Rx
    global Ry

    Rx := 256
    Ry := 256
    BroadcastWin := Gui("+AlwaysOnTop -Caption")
    BroadcastWin.MarginX := 0
    BroadcastWin.MarginY := 0
    BroadcastWin.Show("w" Rx " h" Ry " x0 y0")
    BroadcastWin.Title := "BroadcastWin"

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

    WinSetTransparent(0, "ahk_id " BroadcastWin.Hwnd)

    PrintSourceID := 0
    WinSetExStyle(+0x80020, "ahk_id " BroadcastWin.Hwnd)

    hdd_frame := DllCall("GetDC", "UInt", PrintSourceID)
    hdc_frame := DllCall("GetDC", "UInt", BroadcastWin.Hwnd)

    SetTimer RepaintBroadcastWindow, 16 ; 16=60fps
}


RepaintBroadcastWindow() {
    global px
    global py

    WinGetPos(&x, &y, &w, &h, "ahk_id " MainGui.Hwnd)
    MouseGetPos(&mx, &my)

    px := x
    py := y

    DllCall("gdi32.dll\BitBlt", "UInt", hdc_frame, "Int", 0, "Int", 0, "Int", Rx, "Int", Ry
        , "UInt", hdd_frame, "UInt", x, "UInt", y, "UInt", 0xCC0020)

    mx -= x
    my -= y
    CaptureCursor(hdc_frame, mx, my)
}


HandleSet1920x1080Size(*) {
    SM_CXSIZEFRAME := 32
    SM_CYSIZEFRAME := 33
    SM_CYMENU := 15
    SM_CYCAPTION := 4

    Height := 1080 - (SysGet(SM_CYCAPTION) + SysGet(SM_CYSIZEFRAME) * 2)
    Width := 1920 - (SysGet(SM_CYSIZEFRAME) * 2)

    MainGui.Show("w" Width " h" Height "xCenter yCenter")
}


CaptureCursor(hDC, posX, posY) {
    CURSORINFO := Buffer(A_PtrSize = 8 ? 24 : 20, 0)
    NumPut("UInt", A_PtrSize = 8 ? 24 : 20, CURSORINFO, 0,)
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

DetectMinimizeBroadcastWin() {
    DllCall("RegisterShellHookWindow", "UInt", BroadcastWin.Hwnd)
    MsgNum := DllCall("RegisterWindowMessage", "Str", "SHELLHOOK")
    OnMessage(MsgNum, ShellMessage)
}

ShellMessage(wParam, lParam, msg, hwnd) {
    status := WinGetMinMax("ahk_id " BroadcastWin.Hwnd)

    if (status = -1) {
        WinActivate("ahk_id " BroadcastWin.Hwnd)
    }
}
