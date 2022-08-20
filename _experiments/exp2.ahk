coordmode,tooltip,screen

Global hWnd

Gui, New, hwndhWnd
Gui, Add, Button,,Azzzzzzzzzzzzzzzzzzz
Gui, Show
;hWnd := WinExist()
DllCall( "RegisterShellHookWindow", UInt,hWnd )
MsgNum := DllCall( "RegisterWindowMessage", Str,"SHELLHOOK" )
OnMessage( MsgNum, "ShellMessage" )
Return

ShellMessage( wParam,lParam ) {
    WinGet, status,MinMax,ahk_id %hwnd%
    OutputDebug, % status

    if(status = -1){
        SoundBeep,
        WinActivate, ahk_id %hwnd%
    }

}
