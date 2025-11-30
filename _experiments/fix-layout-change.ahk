#NoEnv
#SingleInstance Force

!+Backspace::
    ; Отправляет системе сообщение WM_INPUTLANGCHANGEREQUEST (0x50)
    ; Параметр 2 (INPUTLANGCHANGE_FORWARD) переключает на следующую раскладку
    PostMessage, 0x50, 2, 0,, A
Return
