; _("e d")
#include ../_lib/DockA.ahk
#SingleInstance, force
Gui, 1:+LastFound +Resize +LabelForm1_
Gui, 1:Show, w400 h300, Form1
hForm1 := WinExist()

;Gui, 2:+LastFound +Resize +ToolWindow +AlwaysOnTop -Border -Sysmenu
Gui, 2:+AlwaysOnTop -Caption -DPIScale +LastFound -Border
Gui, 2:Margin, 0, 0
Gui, 2:Add, Button, gOnButton,Toggle dock
Gui, 2:Show
hForm2 := WinExist()

DockA(hForm1, hForm2, "x(1,,-200) y(,,5)")
DockA(hForm1), bDockOn := 1

ShowForms(true)
return

Form1_Size:
    DockA( hForm1 )
return

Form1_Close:
    ShowForms(false)
return

Onbutton:
    ; if (bDockOn)
    ;     DockA(hForm1, hForm2, "-")
    ; else DockA(hForm1, hForm2)

    ; bDockOn := !bDockOn
    MsgBox, Hello
return

ShowForms(BShow) {
    global

    if BShow
        DockA(hForm1)

    loop,3
        if BShow
        Gui, %A_Index%:Show
    else Gui, %A_Index%:Hide
    }

F1:: ShowForms(true)
