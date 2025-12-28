#NoEnv
#SingleInstance Force

~Backspace::
    ; Запускаем проверку только если Backspace реально зажат
    ; (чтобы не грузить систему при обычном нажатии)
    if (GetKeyState("Backspace", "P")) 
    {
        ; Запоминаем время старта, чтобы не проверять вечно
        Loop 
        {
            ; Если Backspace отпустили - прекращаем слежку
            if !GetKeyState("Backspace", "P")
                break

            ; Проверяем, зажаты ли Alt и Shift одновременно с Backspace
            if (GetKeyState("Alt", "P") && GetKeyState("Shift", "P"))
            {
                ; --- КОМБИНАЦИЯ ПОЙМАНА ---
                
                ; 1. Ждем, пока вы отпустите все кнопки, чтобы не было конфликтов
                KeyWait, Backspace
                KeyWait, Alt
                KeyWait, Shift

                ; 2. Переключаем язык (с защитой от меню Пуск через vkE8)
                SendInput {LWin Down}{Space}{vkE8}{LWin Up}
                
                ; 3. Выходим из цикла, чтобы не переключить дважды
                return
            }
            
            ; Небольшая пауза для разгрузки процессора
            Sleep, 10
        }
    }
return
