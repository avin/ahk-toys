#Requires AutoHotkey v2.0
#SingleInstance Force
;---

#t:: {
    Time := FormatTime(A_Now, "yyyy-MM-dd_hh-mm-ss")
    SendInput Time
}
