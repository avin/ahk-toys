#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%
;----------------

#F9:: ; Win+F9 - запуск Экранной лупы
    Process, Exist, Magnify.exe

    If (ErrorLevel) {
        Send, #{Esc}
    } Else {
        Run, Magnify.exe
    }
return

#F10:: ; Win+F10 - запуск Экранной клавиатуры
    Process, Exist, osk.exe

    If (ErrorLevel) {
        SendInput, #^o
    } Else {
        Run, osk.exe
    }
return

#F11:: ; Win+F11 - Смена раскладки
V++
M:=mod(V,2)
if M=1
   SetDefaultKeyboard(0x0419) ; Russian
else
   SetDefaultKeyboard(0x0409) ; english-US
return

SetDefaultKeyboard(LocaleID){
	Global
	SPI_SETDEFAULTINPUTLANG := 0x005A
	SPIF_SENDWININICHANGE := 2
	Lan := DllCall("LoadKeyboardLayout", "Str", Format("{:08x}", LocaleID), "Int", 0)
	VarSetCapacity(Lan%LocaleID%, 4, 0)
	NumPut(LocaleID, Lan%LocaleID%)
	DllCall("SystemParametersInfo", "UInt", SPI_SETDEFAULTINPUTLANG, "UInt", 0, "UPtr", &Lan%LocaleID%, "UInt", SPIF_SENDWININICHANGE)
	WinGet, windows, List
	Loop %windows% {
		PostMessage 0x50, 0, %Lan%, , % "ahk_id " windows%A_Index%
	}
}
return
