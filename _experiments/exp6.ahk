DllCall("SetWinEventHook","UInt",0x8005,"UInt",0x8005,"Ptr",0,"Ptr",RegisterCallback("THE_HOOK","F"),"UInt",DllCall("GetCurrentProcessId"),"UInt",0,"UInt",0)
CoordMode ToolTip,Client
Gui Add,Edit
Gui Add,Button,,OK
Gui Show
TT_Off:
    ToolTip
Esc::
GuiClose:
ExitApp
THE_HOOK(handle,Event,hWnd){
    GuiControlGet Pos,Pos,%hWnd%
    ToolTip Focus received!,PosX,PosY-20
    SetTimer TT_Off,-250
}
