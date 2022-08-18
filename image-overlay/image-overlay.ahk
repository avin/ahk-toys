#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%
;----------

Menu, Tray, Icon, icon.ico

Global Handles := []
Global Transparencies := []
Global Index := 0
Global ThroughMode := 0
Return

#p::
    Gosub, CreateWindow
Return

#o::
    for hwnd, guiName in Handles {
        ;MsgBox, % guiName
        CloseWindowByHwnd(hwnd)
    }
Return

#\::
    if(ThroughMode){
        SoundBeep, 600
        DisableThroughMode()
    } else {
        SoundBeep, 1600
        EnableThroughMode()
    }
Return

#IfWinActive, ImageOverlayWindow
#[::
    ChangeTransparency(-10)
Return

#]::
    ChangeTransparency(10)
Return

Esc::
    WinGet, hwnd, ID, A
    CloseWindowByHwnd(hwnd)
Return
#IfWinActive

CreateWindow:
    if DllCall("OpenClipboard", "ptr", 0) {
        if DllCall("IsClipboardFormatAvailable", "uint", 2) {
            hBitmap := DllCall("GetClipboardData", "uint", 2, "ptr")
        }
        DllCall("CloseClipboard")
    }

    if(!hBitmap){
        Return
    }

    Index := Index+1
    Gui, %Index% : New , +AlwaysOnTop -Caption -DPIScale +LastFound -Border hwndHwnd
    Handles[hwnd] := Index
    Transparencies[hwnd] := 150
    Gui, %Index% : Margin, 0,0
    Gui, %Index% :Add, Pic, vPic +Border, % "HBITMAP:*" hBitmap
    Gui, %Index% :Show,,ImageOverlayWindow
    WinSet, Transparent, % Transparencies[hwnd]
    OnMessage( 0x200, "WM_MOUSEMOVE" )
Return

ChangeTransparency(diff) {
    WinGet, hwnd, ID, A
    if (Handles[hwnd]){
        Transparencies[hwnd] += diff
        Transparencies[hwnd] := Min(Transparencies[hwnd], 255)
        Transparencies[hwnd] := Max(Transparencies[hwnd], 10)
        WinSet, Transparent, % Transparencies[hwnd], A
    }
}

EnableThroughMode(){
    ThroughMode := 1
    for hwnd, guiName in Handles {
        if (Handles[hwnd]){
            WinSet, ExStyle, +0x80020, ahk_id %hwnd%
        }
    }
}

DisableThroughMode(){
    ThroughMode := 0
    for hwnd, guiName in Handles {
        if (Handles[hwnd]){
            WinSet, ExStyle, -0x20, ahk_id %hwnd%
        }
    }
}

CloseWindowByHwnd(hwnd){
    if (Handles[hwnd]){
        Gui, % Handles[hwnd] ": Destroy"
        ;Handles.Delete(hwnd)
    }
}

WM_MOUSEMOVE( wparam, lparam, msg, hwnd )
{
    if wparam = 1 ; LButton
        PostMessage, 0xA1, 2,,, A ; WM_NCLBUTTONDOWN
}

;GuiClose:
;ExitApp
