#Requires AutoHotkey v2.0
#SingleInstance Force


Global oVoice := ComObject("SAPI.SpVoice")
Global voices := oVoice.GetVoices()


speak(phrase, voiceNumber := 1, rate := -2.5, vol := 100) {
    oVoice.Volume := vol, oVoice.Rate := rate
    oVoice.Voice := voices.Item(voiceNumber - 1)
    oVoice.WaitUntilDone(True)
    oVoice.Speak(phrase, 1)
}

F2:: {
    A_Clipboard := ""
    Send "^c"
    if ClipWait(0.1)
    {
        speak(A_Clipboard, VOICENUMBER := 2)
    }
}

F3:: {
    oVoice.Skip("Sentence", 2147483647)
}
