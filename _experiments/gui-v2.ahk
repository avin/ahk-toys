; Created by:   AHK_User,
; Date:         2021-10-20
; This Gui is based on gui example of TheDewd
; Thanks to Viv for fixing the tooltip issue and testing

#Requires AutoHotkey v2.0-beta.1
#SingleInstance Force ; Replace with new instance if script is running

; Tray definition =================================================================
Tray := A_TrayMenu
Application := { Name: "Menu Interface", Version: "0.1" }
TraySetIcon("Shell32.dll", 174)
TrayTip(Application.Name)
; Tray.Delete()
Tray.Add("Exit", (*) => ExitApp())

SettingsGui()

SettingsGui(){
    OnMessage(0x200, WM_MOUSEMOVE) ; Calling Function when moving the mouse inside the gui

    ; Define parameters of Gui
    Window := {Width: 600, Height: 400, Title: Application.Name}
    MenuWidth := 100
    Navigation := {Label: ["General", "Advanced", "Language", "Theme", "---", "Help", "About"]}

    myGui := Gui()
    myGui.OnEvent("Close", Gui_Escape)
    myGui.OnEvent("Escape", Gui_Escape)
    MyGui.OnEvent("Size", Gui_Size)
    myGui.Opt("+LastFound +Resize MinSize400x300")
    myGui.BackColor := "FFFFFF"

    Tab := myGui.Add("Tab2", "x-999 y-999 w0 h0 -Wrap +Theme vTabControl")
    myGui.Tabs := Tab
    Tab.UseTab() ; Exclude future controls from any tab control

    myGui.TabPicSelect := myGui.AddText("x0 y0 w4 h32 vpMenuSelect Background0x0078D7") ; Using a text control to create a colored rectangle
    myGui.TabPicHover := myGui.AddText("x0 y0 w4 h32 vpMenuHover Background0xCCE8FF Hidden") ; Using a text control to create a colored rectangle

    myGui.TabTitle := myGui.Add("Text", "x" MenuWidth+10 " y" 0 " w" (Window.Width-MenuWidth)-10 " h" 30 " +0x200 vPageTitle", "")
    myGui.TabTitle.SetFont("s14 ", "Segoe UI") ; Set Font Options

    Loop Navigation.Label.Length {
        Tab.Add([Navigation.Label[A_Index]])
        If (Navigation.Label[A_Index] = "---") {
            Continue
        }
        ogcTextMenuItem := myGui.Add("Text", "x0 y" (32*A_Index)-32 " h32 w" MenuWidth " +0x200 BackgroundTrans vMenuItem" . A_Index, " " Navigation.Label[A_Index])
        ogcTextMenuItem.SetFont("s9 c808080", "Segoe UI") ; Set Font Options
        ogcTextMenuItem.OnEvent("Click", Gui_Menu)
        ogcTextMenuItem.Index := A_Index
        if (A_Index = 1) {
            ogcTextMenuItem.SetFont("c000000")
            myGui.ActiceTab := ogcTextMenuItem
            myGui.TabTitle.Value := trim(ogcTextMenuItem.text)
        }
    }

    ogchDividerLine := myGui.AddText("x" MenuWidth+10 " y32 w" Window.Width-MenuWidth-10*2 " h1 Section BackgroundD8D8D8") ; Using a text control to create a colored rectangle
    ogchDividerLine.LeftMargin := 10

    ; Start of defining the custom controls

    Tab.UseTab(1) ; Future controls are owned by the specified tab

    myGui.Add("Text", "xs ys+10 BackgroundWhite", "Select your primary button")
    myGui.Add("DropDownList", "vPrimaryButton Choose1", ["Left", "Right"])
    myGui.Add("Text", "yp+40", "Cursor Speed")
    myGui.Add("Slider", "vMySlider NoTicks", 50)
    myGui.Add("Text", "yp+40 ", "Roll the mouse wheel to scroll")
    myDropDownList := myGui.Add("DropDownList", "w150 vRollMW Choose1", ["Multiple lines at a time", "On screen at a time"])
    myDropDownList.ToolTip := "test"

    myCheckbox := myGui.Add("Checkbox", "yp+40 vCheckboxExample", "Checkbox Example")
    myCheckbox.Tooltip := "This Checkbox has a tooltip"

    Tab.UseTab(2) ; Future controls are owned by the specified tab
    ogcListView := myGui.Add("ListView", "x" MenuWidth+10 " y45 w" (Window.Width-MenuWidth+10)-14, ["Col1", "Col2"])
    ogcListView.Add("", "ListView", "Example")
    ogcListView.ModifyCol()
    ogcListView.LeftMargin := "10"
    ogcListView.BottomMargin := "40"

    Tab.UseTab(3) ; Future controls are owned by the specified tab
    myGui.Add("MonthCal", "xs ys+10 ")

    Tab.UseTab(4) ; Future controls are owned by the specified tab
    myGui.Add("DateTime", "xs ys+10 ", "LongDate")

    Tab.UseTab(5) ; Future controls are owned by the specified tab

    Tab.UseTab(6) ; Future controls are owned by the specified tab
    ogcGroupbox := myGui.Add("GroupBox", "xs ys+10 " " w" (Window.Width-MenuWidth -10)-14, "GroupBox")
    ogcGroupbox.LeftMargin := "10"
    ogcGroupbox.BottomMargin := "40"

    Tab.UseTab(7) ; Future controls are owned by the specified tab
    myGui.Add("DateTime", "xs ys+10 ", "LongDate")

    Tab.UseTab("")

    ogcButtonOK := myGui.Add("Button", "x" (Window.Width - 170) - 10 " y" (Window.Height - 24) - 10 " w80 h24 vButtonOK", "OK")
    ogcButtonOK.OnEvent("Click", ButtonOK)
    ogcButtonOK.LeftDistance := "10"
    ogcButtonOK.BottomDistance := "10"
    ogcButtonCancel := myGui.Add("Button", "x" (Window.Width - 80) - 10 " y" (Window.Height - 24) - 10 " w80 h24 vButtonCancel", "Cancel")
    ogcButtonCancel.OnEvent("Click", Gui_Escape)
    ogcButtonCancel.LeftDistance := "100"
    ogcButtonCancel.BottomDistance := "10"

    myGui.Title := Window.Title
    myGui.Show(" w" Window.Width " h" Window.Height)

    return

    ; Nested Functions ==============================================================================
    ButtonOK(*){
        Saved := MyGui.Submit(0)
        MsgBox("CheckboxExample`t[" Saved.CheckboxExample "]`n")
        ExitApp()
    }

    Gui_Escape(*){
        ExitApp() ; Terminate the script unconditionally
    }

    Gui_Menu(guiCtrlObj, info, *){
        ; Called when clicking the menu
        thisGui := guiCtrlObj.Gui
        thisGui.ActiceTab.SetFont("c808080")
        thisGui.Tabs.Choose(trim(guiCtrlObj.text))
        thisGui.TabTitle.Value := trim(GuiCtrlObj.text)
        thisGui.ActiceTab := GuiCtrlObj
        guiCtrlObj.SetFont("c000000")
        thisGui.TabPicSelect.Move(0, (32*GuiCtrlObj.Index) - 32)
        return
    }

    Gui_Size(thisGui, MinMax, Width, Height) {
        if MinMax = -1	; The window has been minimized. No action needed.
            return
        DllCall("LockWindowUpdate", "Uint", thisGui.Hwnd)
        For Hwnd, GuiCtrlObj in thisGui{
            if GuiCtrlObj.HasProp("LeftMargin"){
                GuiCtrlObj.GetPos(&cX, &cY, &cWidth, &cHeight)
                GuiCtrlObj.Move(, , Width-cX-GuiCtrlObj.LeftMargin,)
            }
            if GuiCtrlObj.HasProp("LeftDistance") {
                GuiCtrlObj.GetPos(&cX, &cY, &cWidth, &cHeight)
                GuiCtrlObj.Move(Width -cWidth - GuiCtrlObj.LeftDistance, , , )
            }
            if GuiCtrlObj.HasProp("BottomDistance") {
                GuiCtrlObj.GetPos(&cX, &cY, &cWidth, &cHeight)
                GuiCtrlObj.Move(, Height - cHeight - GuiCtrlObj.BottomDistance, , )
            }
            if GuiCtrlObj.HasProp("BottomMargin") {
                GuiCtrlObj.GetPos(&cX, &cY, &cWidth, &cHeight)
                GuiCtrlObj.Move(, , , Height -cY - GuiCtrlObj.BottomMargin)
            }
        }
        DllCall("LockWindowUpdate", "Uint", 0)
    }

    WM_MOUSEMOVE(wParam, lParam, Msg, Hwnd) {
        static PrevHwnd := 0
        static HoverControl := 0
        currControl := GuiCtrlFromHwnd(Hwnd)
        ; Setting the highlighting of the hovered menu
        if currControl {
            thisGui := currControl.Gui
            if thisGui.HasProp("TabPicHover"){
                If (InStr(currControl.Name, "MenuItem") and currControl != thisGui.ActiceTab) {
                    thisGui.TabPicHover.Visible := true
                    thisGui.TabPicHover.Move(0, (32 * currControl.Index) - 32)
                } else {
                    thisGui.TabPicHover.Visible := false
                }
            }
        } else {
            thisGui := GuiFromHwnd(Hwnd)
            if (isObject(thisGui) and thisGui.HasProp("TabPicHover")) {
                thisGui.TabPicHover.Visible := false
            }
        }

        ; Setting the tooltips for controls with a property tooltip
        if (Hwnd != PrevHwnd){
            Text := "", ToolTip()	; Turn off any previous tooltip.
            if CurrControl{
                if !CurrControl.HasProp("ToolTip")
                    return	; No tooltip for this control.
                SetTimer(CheckHoverControl, 50)	; Checks if hovered control is still the same
                SetTimer(DisplayToolTip, -500)
            }
            PrevHwnd := Hwnd
        }
        return

        CheckHoverControl(){
            If hwnd != prevHwnd {
                SetTimer(DisplayToolTip, 0), SetTimer(CheckHoverControl, 0)
            }
        }
        DisplayToolTip(){
            ToolTip(CurrControl.ToolTip)
            SetTimer(CheckHoverControl, 0)
        }
    }
}
