#Singleinstance, force
SetWorkingDir, %A_ScriptDir%
#NoEnv
SetBatchLines -1
Menu, Tray, Icon, Shell32.dll, 23

CoordMode Mouse, Screen
OnExit GuiClose
zoom = 1                ; initial magnification, 1..32
antialize = 0
Rx = 128                ; half vertical/horizontal side of magnifier window
Ry = 128
Zx := Rx/zoom           ; frame x/y size
Zy := Ry/zoom
                        ; GUI to show the magnified image
Gui +AlwaysOnTop +Resize +ToolWindow
Gui Show, % "w" 2*Rx " h" 2*Ry " x0 y0", Magnifier
WinGet MagnifierID, id,  Magnifier
WinSet Transparent, 255, Magnifier ; makes the window invisible to magnification
WinGet PrintSourceID, ID

hdd_frame := DllCall("GetDC", UInt, PrintSourceID)
hdc_frame := DllCall("GetDC", UInt, MagnifierID)

SetTimer Repaint, 50    ; flow through

Repaint:
   ; MouseGetPos x, y
   WinGetPos, x, y, Width, Height, A

   xz := x ; keep the frame on screen
   yz := y
  ; WinMove Frame,,%xz%, %yz%, % 2*Zx, % 2*Zy
   DllCall("gdi32.dll\StretchBlt", UInt,hdc_frame, Int,0, Int,0, Int,2*Rx, Int,2*Ry
   , UInt,hdd_frame, UInt,xz, UInt,yz, Int,2*Zx, Int,2*Zy, UInt,0xCC0020) ; SRCCOPY
Return


GuiSize:
   Rx := A_GuiWidth/2
   Ry := A_GuiHeight/2
   Zx := Rx/zoom
   Zy := Ry/zoom
   ; TrayTip,,% "Frame  =  " Round(2*Zx) " × " Round(2*Zy) "`nMagnified to = " A_GuiWidth "×" A_GuiHeight
Return

#a::
  antialize := !antialize
  DllCall( "gdi32.dll\SetStretchBltMode", "uint", hdc_frame, "int", 4*antialize )  ; Antializing ?
  TrayTip, Zoom, Antializing %antialize%, 20, 17
Return

#x::
GuiClose:
   DllCall("gdi32.dll\DeleteDC", UInt,hdc_frame )
   DllCall("gdi32.dll\DeleteDC", UInt,hdd_frame )
ExitApp

In(x,a,b) {                      ; closest number to x in [a,b]
   IfLess x,%a%, Return a
   IfLess b,%x%, Return b
   Return x
}
