#Requires AutoHotkey v2.0
#SingleInstance Force

#include Lib\UIA.ahk

; F8:
; скопировать свойства UIA-элемента прямо под курсором.
F8::
{
    try
    {
        el := UIA.ElementFromPoint()

        text := el.Dump()

        A_Clipboard := text

        ToolTip(
            "UIA element copied to clipboard`n`n"
            . GetShortInfo(el)
        )

        SetTimer(() => ToolTip(), -2500)
    }
    catch as err
    {
        ToolTip(
            "UIA error:`n"
            . err.Message
        )

        SetTimer(() => ToolTip(), -3000)
    }
}

; F9:
; скопировать всё UIA-поддерево элемента под курсором.
F9::
{
    try
    {
        el := UIA.ElementFromPoint()

        text := el.DumpAll()

        A_Clipboard := text

        ToolTip("UIA subtree copied to clipboard")

        SetTimer(() => ToolTip(), -2500)
    }
    catch as err
    {
        ToolTip(
            "UIA error:`n"
            . err.Message
        )

        SetTimer(() => ToolTip(), -3000)
    }
}

GetShortInfo(el)
{
    result := ""

    try result .= "Name: " el.Name "`n"
    try result .= "Type: " el.LocalizedType "`n"
    try result .= "AutomationId: " el.AutomationId "`n"
    try result .= "ClassName: " el.ClassName

    return result
}