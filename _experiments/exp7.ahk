#NoEnv
#SingleInstance, force

#Include, ../_lib/Dock.ahk

Gui, +hwndGuihwnd
Gui, Font, s13
Gui, Add, Button, gBtn, Dock to Top
Gui, Add, Button, gBtn, Dock to Bottom
Gui, Add, Button, gBtn, Dock to Right
Gui, Add, Button, gBtn, Dock to Left
Gui, Add, Button, gAdd, Add dock
Gui, Add, Button, gAdd, Add dock to Top
Gui, Add, Button, gAdd, Add dock to Bottom
Gui, Add, Button, gAdd, Add dock to Right
Gui, Add, Button, gAdd, Add dock to Left
Gui, Show, xCenter yCenter w300, class Dock Example

exDock := new Dock(Guihwnd, Dock.HelperFunc.Run("notepad.exe"))
; exDock.Position("R")
exDock.MoveWindow(Guihwnd	 	;hwnd
    , 100 	;x
    , 100		;y
    , 100	 	;width
, 100)	 	;height
exDock.CloseCallback := Func("CloseCallback")
Return

Btn:
    exDock.Position(A_GuiControl)
Return

Add:
    exDock.Add(Dock.HelperFunc.Run("notepad.exe"), A_GuiControl)
Return

CloseCallback(self)
{
    WinKill, % "ahk_id " self.hwnd.Client
ExitApp
}

GuiClose:
    Gui, Destroy
