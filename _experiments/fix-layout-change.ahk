#NoEnv
#SingleInstance Force

#MaxThreadsPerHotkey 2

; Комбинация: Сначала зажат Backspace, потом добавляем Alt
Backspace & Alt::
    ; Переменная-флаг: был ли нажат Shift?
    sawShift := false

    ; Запускаем цикл: пока Backspace физически зажат...
    While GetKeyState("Backspace", "P")
    {
        ; ...проверяем, не нажал ли пользователь Shift в любой момент удержания
        if GetKeyState("Shift", "P")
            sawShift := true
        
        ; Небольшая пауза для разгрузки процессора
        Sleep, 10
    }

    ; --- СЮДА ПОПАДАЕМ, КОГДА BACKSPACE УЖЕ ОТПУЩЕН ---

    ; Ждем, чтобы пользователь отпустил и остальные клавиши (Alt и Shift),
    ; чтобы они не смешались с командой смены языка.
    KeyWait, Alt
    KeyWait, Shift

    ; Если Shift был замечен в процессе удержания — меняем язык
    if (sawShift)
    {
        ; Отправляем Win+Space + "фиктивная" клавиша vkE8, чтобы не вылез Пуск
        SendInput {LWin Down}{Space}{vkE8}{LWin Up}
    }
return

; Сохраняем обычную работу Backspace (срабатывает при отпускании, если не было комбинаций)
Backspace::Send {Backspace}
