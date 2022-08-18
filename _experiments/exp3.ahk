#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%
;-------

;OnMessage(0x84, "WM_NCHITTEST")
;OnMessage(0x83, "WM_NCCALCSIZE")
gui, color, 000000

Gui +hwndgui2id
Gui +LastFound +ToolWindow +AlwaysOnTop
WinSet, Transparent, 100

Gui, +resize MinSize200x200
Gui, Show, w300 h300, FooBar
WinGet, active_id, ID, FooBar
;WinSet, Style, ^0x40000, ahk_id %active_id%
return

; Gui, Show, x800 y20, Transparent Help Menu
; WinGet, active_id, ID, Transparent Help Menu
; WinSet, AlwaysOnTop, On, ahk_id %active_id%
; WinSet, Transparent, 190, ahk_id %active_id%
; WinSet, ExStyle, +0x80020,ahk_id %active_id%

esc::
exitapp

#m::
    SoundBeep,
    ; WinSet, ExStyle, +E0x20, ahk_id %gui2id%
    ; MsgBox, %active_id%
    WinSet, ExStyle, +0x80020,ahk_id %active_id%
Return

!#m::
    SoundBeep, 300, 200
    ; WinSet, ExStyle, +E0x20, ahk_id %gui2id%
    ; MsgBox, %active_id%
    WinSet, ExStyle, -0x20,ahk_id %active_id%
Return

WM_NCCALCSIZE()
{
    if A_Gui {
        return 0 ; Sizes the client area to fill the entire window.
    }
}

; Redefine where the sizing borders are.  This is necessary since
; returning 0 for WM_NCCALCSIZE effectively gives borders zero size.

WM_NCHITTEST(wParam, lParam)
{
    static border_size = 6

    if !A_Gui {
        return
    }

    WinGetPos, gX, gY, gW, gH

    x := lParam<<48>>48, y := lParam<<32>>48

    hit_left := x < gX+border_size
    hit_right := x >= gX+gW-border_size
    hit_top := y < gY+border_size
    hit_bottom := y >= gY+gH-border_size

    if hit_top
    {
        if hit_left {
            return 0xD
        } else if hit_right {
            return 0xE
        } else {
            return 0xC
        }

    }
    else if hit_bottom
    {
        if hit_left {
            return 0x10
        } else if hit_right {
            return 0x11
        } else {
            return 0xF
        }
    }
    else if hit_left {
        return 0xA
    } else if hit_right {
        return 0xB
    }

    ; else let default hit-testing be done
}
