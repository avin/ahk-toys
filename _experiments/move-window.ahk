#NoEnv

Win__GetDesktopPos(ByRef X, ByRef Y, ByRef W, ByRef H)
{
    WinGetPos, TrayX, TrayY, TrayW, TrayH, ahk_class Shell_TrayWnd
    if (TrayW = A_ScreenWidth)
    {
        ; Horizontal Taskbar
        X := 0
        Y := TrayY ? 0 : TrayH
        W := A_ScreenWidth
        H := A_ScreenHeight - TrayH
    }
    else
    {
        ; Vertical Taskbar
        X := TrayX ? 0 : TrayW
        Y := 0
        W := A_ScreenWidth - TrayW
        H := A_ScreenHeight
    }
}

Win__HalfLeft()
{
    count+=1

    Win__GetDesktopPos(X, Y, W, H)
    WinMove, A,, X, Y, W/2, H
}

Win__HalfRight()
{
    Win__GetDesktopPos(X, Y, W, H)
    winMove, A,, X + W/2, Y, W/2, H
}

Win__FullSize()
{
    Win__GetDesktopPos(X, Y, W, H)
    WinMove, A,, X, Y, W, H
}

*~LButton::
    CoordMode, Mouse, Screen
    MouseGetPos, x, y, hwnd
    SendMessage, 0x84, 0, (x&0xFFFF) | (y&0xFFFF) << 16,, ahk_id %hwnd%
    RegExMatch("ERROR TRANSPARENT NOWHERE CLIENT CAPTION SYSMENU SIZE MENU HSCROLL VSCROLL MINBUTTON MAXBUTTON LEFT RIGHT TOP TOPLEFT TOPRIGHT BOTTOM BOTTOMLEFT BOTTOMRIGHT BORDER OBJECT CLOSE HELP", "(?:\w+\s+){" . ErrorLevel+2&0xFFFFFFFF . "}(?<AREA>\w+\b)", HT)
    if htarea!=CAPTION
        Return
    MouseGetPos,_x,_y

    ;Wait until user begins dragging
    While GetKeyState("LButton","P") && x=_x && y=_y {
        MouseGetPos,_x,_y
    }

    While GetKeyState("LButton","P") ;Show ToolTip while dragging
    {

        keywait,lbutton
        coordmode,mouse,screen
        MouseGetPos,Mouse_X,Mouse_Y
        if Mouse_X<3
        {
            Win__HalfLeft()
        }

        if (Mouse_X > (A_ScreenWidth - 3))
        {
            Win__HalfRight()
        }

    }
Return

~^s::
    sleep 100
    reload
