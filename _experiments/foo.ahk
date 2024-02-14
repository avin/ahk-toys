#Requires AutoHotkey v2.0

; Создаем новый GUI
guiMain := Gui()

; Добавляем текстовое поле для ввода
UserInput := guiMain.Add("Edit", "w300")

; Добавляем кнопку, которая будет выполнять действие CopyText
guiMain.Add("Button", "Default", "Копировать в буфер и закрыть").OnEvent("Click", CopyText)

; Показываем GUI пользователю
guiMain.Show("w400 h100")

; Функция для копирования текста в буфер обмена и закрытия GUI
CopyText(guiCtrl, eventInfo) {
    ; Копируем текст в буфер обмена
    Clipboard := UserInput.Value

}

; Запускаем цикл обработки сообщений для GUI
; guiMain.Run()
