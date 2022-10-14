#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%
;----------------

global isWinActive := 0
global MainWinHwnd := 0

;----------------

Menu, Tray, Icon, icon.ico

Gui Main: New, -SysMenu +AlwaysOnTop hwndMainWinHwnd
Gui Main: Font, s10 bold, Verdana
Gui Main: Add, Button, w300 h40 gonClickAddTime, +5 Min
Gui Main: Font, s24 bold, Verdana
Gui Main: Add, Button, w300 h80 gonClickWork, Work

onClickWork()

SetTimer, Splash1, 500
Sleep, 250
SetTimer, Splash2, 500

Return

;----------------

Splash1:
    Gui Main: Color, 0x137CBD
Return

Splash2:
    Gui Main: Color, 0xEBF1F5
Return

;----------------

onClickAddTime(){
    ; SetTimer, restore, -300000 ; 5 Min
    SetTimer, restore, -3000 ; 3 Sec
    hide()
}

onClickWork(){
    ; SetTimer, restore, -2400000 ; 40 Min
    SetTimer, restore, -10000 ; 10 Sec
    hide()
}

;Показать окно с gui
restore(){
    isWinActive := 1
    winX := A_ScreenWidth-300-40
    Gui Main: Show, x%winX% y40, Time
}

;Скрыть gui-окно
hide() {
    isWinActive := 0
    Gui Main: Hide
}
