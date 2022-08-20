#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%
;----------

Gui, MainGui: New, hwndMainWindow

Gui, MainGui: Add, Button, w500 ,Hello and die
Gui, MainGui: Add, Text, vMyText, azzzzz
GuiControl,,MyText, FOOO
Gui, MainGui: Add, Button, w80 h24 HWNDhButtonX, Button X

Gui, MainGui: Show

Global isTransGuiActive := 0
Global transValue := 150
Global prevMouseX := 0
Return

show_result:
    GuiControlGet, result , , TransSlider,

    ; GuiControl,,MyText, % transValue
    GuiControl, MainGui:,MyText,% transValue
    ; SoundBeep, 500
return

~RButton::
    MouseGetPos, MouseX, MouseY, MouseWin, MouseCtl, 2

    If (MouseWin = MainWindow) {
        ; Gui, TransControlGui: New, +AlwaysOnTop +Caption +Border, TransGui
        ; Gui, TransControlGui: Add, Slider, w200 vTransSlider AltSubmit Range1-255 TickInterval10, % transValue
        ; Gui, TransControlGui: Show
        ; WinActivate, TransGui

        isTransGuiActive := 1
        MouseGetPos, prevMouseX
        SetTimer HandleMouseMove, 50
    }
return

~RButton Up::
    MouseGetPos, MouseX, MouseY, MouseWin, MouseCtl, 2

    ; Gui, TransControlGui: Destroy
    isTransGuiActive := 0
    SetTimer HandleMouseMove, OFF
return

HandleMouseMove:
    if(isTransGuiActive){
        MouseGetPos, mouseX
        diff := mouseX - prevMouseX
        transValue += diff
        transValue := Min(transValue, 255)
        transValue := Max(transValue, 10)
        if(mouseX != prevMouseX){

        }
        prevMouseX := mouseX

        Gosub, show_result
    }
Return

; ~RButton::
;     MouseGetPos, MouseX, MouseY, MouseWin, MouseCtl, 2

;     If (MouseCtl = hButtonX) {
;         Gui, TransControlGui: New, +AlwaysOnTop +Caption +Border, TransGui
;         Gui, TransControlGui: Add, Slider, w200 vTransSlider AltSubmit Range1-255 TickInterval10
;         Gui, TransControlGui: Show
;         WinActivate, TransGui
;     }
; return

GuiClose:
ExitApp,
