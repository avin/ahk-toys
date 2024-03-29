﻿#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%
;----------

DllCall("SetWinEventHook","UInt",0x8005,"UInt",0x8005,"Ptr",0,"Ptr",RegisterCallback("FOCUS_HOOK","F"),"UInt",DllCall("GetCurrentProcessId"),"UInt",0,"UInt",0)

Menu, Tray, Icon, icon.ico

Global Handles := []
Global HandlesPoses := []
Global Transparencies := []
Global Index := 0
Global ThroughMode := 0
Global isSlideTransActive := 0
Global isSlideTransForAllActive := 0
Return

; --------------------------------
; ------- GLOBAL HOTKEYS ---------
; --------------------------------

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
    Gosub, ToggleThroughMode
Return

#XButton1::
    Gosub, ToggleThroughMode
return

#RButton::
    MouseGetPos, MouseX
    isSlideTransForAllActive := 1
    MouseGetPos, prevMouseX
    SetTimer HandleMouseMoveTimer, 10
Return

#RButton Up::
    isSlideTransForAllActive := 0
    SetTimer HandleMouseMoveTimer, OFF
return

; --------------------------------
; -------- IN APP HOTKEYS --------
; --------------------------------

#IfWinActive, ImageOverlayWindow
#[::
    ChangeTransparencyActiveWin(-10)
Return
^#[::
    ChangeTransparencyActiveWin(-250)
Return

#]::
    ChangeTransparencyActiveWin(10)
Return
^#]::
    ChangeTransparencyActiveWin(+250)
Return

Esc::
    WinGet, hwnd, ID, A
    CloseWindowByHwnd(hwnd)
Return

RButton::
    MouseGetPos, MouseX, MouseY, MouseWin, MouseCtl, 2

    isSlideTransActive := 1
    MouseGetPos, prevMouseX
    SetTimer HandleMouseMoveTimer, 10
Return

RButton Up::
    isSlideTransActive := 0
    SetTimer HandleMouseMoveTimer, OFF
return

^z::
    WinGet, hwnd, ID, A

    if (HandlesPoses[hwnd]){
        pose := HandlesPoses[hwnd].pop()

        WinGetPos, x, y, , , A
        IsSamePos := pose[1] == x and pose[2] == y
        if(IsSamePos){
            pose := HandlesPoses[hwnd].pop()
        }

        x := pose[1]
        y := pose[2]
        WinMove, %x%, %y%
    }
Return

~LButton::
    SaveLastPos()
Return
#IfWinActive

; ----------------------------
; ----------------------------
; ----------------------------

ToggleThroughMode:
    if(ThroughMode){
        SoundBeep, 600
        DisableThroughMode()
    } else {
        SoundBeep, 1600
        EnableThroughMode()
    }
Return

HandleMouseMoveTimer:
    MouseGetPos, mouseX
    diff := mouseX - prevMouseX
    if(isSlideTransForAllActive){
        ChangeTransparencyAll(diff)
    } else if (isSlideTransActive) {
        ChangeTransparencyActiveWin(diff)
    }

    prevMouseX := mouseX
Return

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

ChangeTransparency(hwnd, diff){
    if (Handles[hwnd]){
        Transparencies[hwnd] += diff
        Transparencies[hwnd] := Min(Transparencies[hwnd], 255)
        Transparencies[hwnd] := Max(Transparencies[hwnd], 10)
        WinSet, Transparent, % Transparencies[hwnd], ahk_id %hwnd%
    }
}

ChangeTransparencyActiveWin(diff) {
    WinGet, hwnd, ID, A
    ChangeTransparency(hwnd, diff)
}

ChangeTransparencyAll(diff) {
    for hwnd, guiName in Handles {
        ChangeTransparency(hwnd, diff)
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
        Handles.Delete(hwnd)
    }
}

SaveLastPos(){
    WinGet, hwnd, ID, A

    if (Handles[hwnd]){
        WinGetPos, x, y, , , A

        if (HandlesPoses[hwnd]){
            LastValIndex := HandlesPoses[hwnd].MaxIndex()
            LastVal := HandlesPoses[hwnd][LastValIndex]
            IsSamePos := LastVal[1] == x and LastVal[2] == y

            if(!IsSamePos){
                HandlesPoses[hwnd].Push([x,y])
            } else {
                OutputDebug, % 1
            }
        } else {
            HandlesPoses[hwnd] := [[x,y]]
        }
    }

}

WM_MOUSEMOVE( wparam, lparam, msg, hwnd )
{
    if wparam = 1 ; LButton
        PostMessage, 0xA1, 2,,, A ; WM_NCLBUTTONDOWN
}

FOCUS_HOOK(handle,Event,hWnd){
    SaveLastPos()
}

;GuiClose:
;ExitApp
