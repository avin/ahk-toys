#NoEnv
#SingleInstance, force

;----------------------------------------------------------
;  F4  →  открыть выделенные файлы в CudaText
;  (без COM, только через буфер обмена)
;----------------------------------------------------------
#NoEnv                       ; рекомендуемая директива
#SingleInstance Force
SendMode Input
SetWorkingDir %A_ScriptDir%

editor := "C:\utils\cudatext\cudatext.exe"   ; ← поправьте путь при необходимости


; --- горячая клавиша действует в Проводнике ----------------
#IfWinActive ahk_class CabinetWClass         ; окна Explorer
F4::OpenInEditor()
#IfWinActive

; --- и в стандартных диалогах «Открыть/Сохранить» ----------
#IfWinActive ahk_class #32770                ; диалоги CommonItemDialog
F4::OpenInCuda()
#IfWinActive
; -----------------------------------------------------------


OpenInEditor() {
    global editor

    ClipSaved := ClipboardAll   ; сохраняем текущее содержимое буфера
    Clipboard := ""             ; очищаем

    Send ^c                     ; копируем выделенные объекты
    ClipWait, 1                 ; ждём до 1 с появление данных
    if ErrorLevel {             ; тайм-аут → ничего не скопировалось
        Clipboard := ClipSaved
        return
    }

    selList := Clipboard
    Clipboard := ClipSaved      ; возвращаем прежний буфер
    ClipSaved := ""             ; чистим переменную

    StringReplace, selList, selList, `r,, All   ; убираем CR
    Loop, Parse, selList, `n                    ; перебираем строки
    {
        filePath := A_LoopField
        if filePath =
            continue
        Run, %editor% "%filePath%"
    }
}
