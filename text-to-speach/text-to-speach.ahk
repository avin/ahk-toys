#Requires AutoHotkey v2.0
#SingleInstance Force

Global oVoice := ComObject("SAPI.SpVoice")
Global voices := oVoice.GetVoices()
Global speaking := false

speak(phrase, voiceNumber := 1, rate := -2.5, vol := 100) {
    global speaking
    speaking := true
    oVoice.Volume := vol, oVoice.Rate := rate
    oVoice.Voice := voices.Item(voiceNumber - 1)
    oVoice.WaitUntilDone(True)
    oVoice.Speak(phrase, 1)
    SetTimer CheckSpeaking, 100 ; Запускаем таймер для проверки, закончил ли говорить
}

CheckSpeaking() {
    global speaking
    if (oVoice.Status.RunningState = 1) {
        speaking := false
        SetTimer CheckSpeaking, 0 ; Выключаем таймер после завершения речи
    }
}


; Начать озвучивание при нажатии Win
XButton1:: {
    global speaking
    if (speaking) {
        speaking := false
        oVoice.Skip("Sentence", 2147483647)
        return
    }
    A_Clipboard := ""
    Send "^c"
    if ClipWait(0.1)
    {
        speak(A_Clipboard, VOICENUMBER := 2)
    }
}
