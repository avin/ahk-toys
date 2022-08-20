#Include ../_lib/Gdip_All.ahk

Gui, Add, Button, x132 y89 w90 h60 gChange, Change
Gui, Add, Button, x132 y179 w90 h70 , Exit
Gui, Add, Button, x132 y279 w90 h70 gRestore, Restore
; Generated using SmartGUI Creator for SciTE
Gui, Show, w479 h379, Untitled GUI
return

GuiClose:
ExitApp

Change:
    Cursor = %A_scriptdir%\cursor.cur
    CursorHandle := DllCall( "LoadCursorFromFile", Str,Cursor )
    Cursors = 32512,32513,32514,32515,32516,32640,32641,32642,32643,32644,32645,32646,32648,32649,32650,32651
    Loop, Parse, Cursors, `,
    {
        DllCall( "SetSystemCursor", Uint,CursorHandle, Int,A_Loopfield )
    }
    goto, Change2
return

Change2:
LButton::
    MouseGetPos, oVarX, oVarY
    size := 5, ratio := 1
    oVarX1 := oVarX - size * ratio, oVarX2 := oVarX + size * ratio, oVarY1 := oVarY - size, oVarY2 := oVarY + size
    path := A_scriptdir "\"															; define path
    pToken 						:= Gdip_Startup()
    hdc_frame_full 				:= GetDC()
    hdc_buffer_full 			:= CreateCompatibleDC(hdc_frame_full)
    hbm_buffer_full 			:= CreateCompatibleBitmap(hdc_frame_full, oVarX2 - oVarX1, oVarY2 - oVarY1)
    r_full 						:= SelectObject(hdc_buffer_full, hbm_buffer_full)
    BitBlt(hdc_buffer_full, 0, 0, oVarX2 - oVarX1, oVarY2 - oVarY1, hdc_frame_full, oVarX1, oVarY1, 0x00CC0020)
    bitmap_full 				:= Gdip_CreateBitmapFromHBITMAP(hbm_buffer_full, 0)
    DeleteDC(hdc_buffer_full)
    DeleteObject(hbm_buffer_full)
    Formattime,todaydate,a_now, yyyyMMdd_HHmmss
    fl2shwnopth := todaydate "MouseClip.jpg"
    fl2shw := path fl2shwnopth														; add path here
    Gdip_SaveBitmapToFile(bitmap_full, fl2shw, 100)
    Gdip_SetBitmapToClipboard(bitmap_full)
    Gdip_DisposeImage(bitmap_full)
    Gdip_Shutdown(pToken)
    goto, Restore
return

Restore:
    SPI_SETCURSORS := 0x57
    DllCall( "SystemParametersInfo", UInt,SPI_SETCURSORS, UInt,0, UInt,0, UInt,0 )
return

Esc::
ExitApp
