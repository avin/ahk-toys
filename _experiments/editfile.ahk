#NoEnv
#SingleInstance, force

;----------------------------------------------------------
;  F4 → открыть выделенный файл(ы) в CudaText
;  C:\utils\cudatext\cudatext.exe  — путь к редактору
;----------------------------------------------------------

F4::
{
    selList := Explorer_GetSelected()          ; получаем список путей
    if (selList = "")                          ; ничего не выделено
        return

    Loop Parse, selList, "`n"                  ; перебор каждого пути
        Run, "C:\utils\cudatext\cudatext.exe" "%A_LoopField%"
}
return



;----------------------------------------------------------
;  Функция: Explorer_GetSelected()
;  Возвращает список выделенных элементов в активном
;  окне Проводника или в диалогах «Открыть/Сохранить».
;----------------------------------------------------------
Explorer_GetSelected(hwnd := "")
{
    static shell := ComObjCreate("Shell.Application")
    items := ""

    for window in shell.Windows
    {
        if (hwnd && window.hwnd != hwnd)       ; фильтр по конкретному hwnd
            continue
        if (window.Document)                   ; защита от «пустых» окон
        {
            for item in window.Document.SelectedItems
                items .= item.Path "`n"
            if (items != "")                   ; нашли выделение — хватит
                break
        }
    }
    return RTrim(items, "`n")                  ; убираем лишний перевод строки
}
