#Requires AutoHotkey v2.0
#SingleInstance Force
#Include "../_lib/JXON_ahk2.ahk"

global ChatGptOptions := Map(
    "Proxy", IniRead("config.ini", "ChatGpt", "Proxy"),
    "ApiKey", IniRead("config.ini", "ChatGpt", "ApiKey"),
)


ProcessTextWithChatGpt(content, maxTokens := 300, temperature := 0.5) {
    if (!ChatGptOptions["ApiKey"]) {
        OutputDebug("ChatGpt ApiKey required")
        return
    }
    data := Map(
        "model", "gpt-3.5-turbo",
        "messages", [
            Map(
                "role", "user",
                "content", content
            )
        ],
        "temperature", temperature,
        "max_tokens", maxTokens
    )

    url := "https://api.proxyapi.ru/openai/v1/chat/completions"
    jsonData := Jxon_dump(data, 4)

    whr := ComObject("WinHttp.WinHttpRequest.5.1")
    if (ChatGptOptions["Proxy"]) {
        whr.SetProxy(2, ChatGptOptions["Proxy"])
    }
    whr.Open("POST", url, False)
    whr.SetRequestHeader("Content-Type", "application/json")
    whr.SetRequestHeader("Authorization", "Bearer " . ChatGptOptions["ApiKey"])
    whr.Send(jsonData)


    stream := ComObject("ADODB.Stream")
    stream.Type := 1 ; Binary
    stream.Open()
    stream.Write(whr.ResponseBody)
    stream.Position := 0
    stream.Type := 2 ; Text
    stream.Charset := "UTF-8" ; Установите кодировку ответа здесь
    response := stream.ReadText()
    stream.Close()

    OutputDebug(response)
    OutputDebug("----")

    obj := jxon_load(&response)

    try
    {
        return obj["choices"][1]["message"]["content"]
    }
    catch as e
    {
        OutputDebug(e.Message)
        return
    }
}

TranslateTextIntoEnglish(text) {
    return result := ProcessTextWithChatGpt(
        "Translate text into English. The answer should only contain the translation: \n" . text,
        300, 0.0
    )
}

TranslateTextIntoRussian(text) {
    return result := ProcessTextWithChatGpt(
        "Translate text into Russian. The answer should only contain the translation: \n" . text,
        300, 0.0
    )
}

FixGrammar(text) {
    return result := ProcessTextWithChatGpt(
        "Correct the grammar and punctuation. You should not remove or add words. The text should be constructed in its original execution and original language: \n" . text,
        300, 0.0
    )
}

; ---------------------------------------------------------------------------------------------

; Показ меню с действиями над выделенным текстом (Если текст не выделен, то предварительно будет прожата Ctrl+A)
#HotIf !WinActive("ahk_exe PathOfExileSteam.exe")
^RButton:: ; Ctrl+RightMouseButton
AppsKey:: ; MenuKey
^+x:: ; Ctrl+Shift+X
{
    ProcessSelected(ItemName, *) {
        A_Clipboard := ""
        Send "^x"
        if !ClipWait(0.1)
        {
            Send "^a"
            Send "^x"
            if !ClipWait(0.1)
            {
                return
            }
        }
        result := ""
        if (ItemName == "Исправить") {
            result := FixGrammar(A_Clipboard)
        }
        if (ItemName == "Перевести") {
            result := TranslateTextIntoEnglish(A_Clipboard)
        }

        if (result) {
            A_Clipboard := result
            Send "^v"
        } else {
            SoundBeep(, 100)
        }
    }

    MyMenu := Menu()
    MyMenu.Add("Исправить", ProcessSelected)
    MyMenu.Add("Перевести", ProcessSelected)

    MyMenu.Show()
}


; Перевод выделенного текста
+RButton:: ; Shift+RightMouseButton
{
    if WinActive("ahk_exe PathOfExileSteam.exe")
        return

    A_Clipboard := ""
    Send "^c"
    if !ClipWait(0.25)
    {
        SoundBeep(, 100)
        return
    }

    MyGui := Gui("+Resize -MaximizeBox -Resize", "Перевод")

    EditBox := MyGui.AddEdit("w500 Multi r20 BackgroundFFFFFF -WantReturn ReadOnly", "...")
    EditBox.SetFont("s15", "Consolas")

    ; Фейковая кнока чтоб перевести на неё фокус с инпута
    Button := MyGui.AddButton("x0 y0 w0 h0", "ZZ")
    Button.Focus()

    MyGui.Show()

    CoordMode "Mouse", "Screen"
    MouseGetPos(&xpos, &ypos)
    MyGui.Move(xpos, ypos)

    EditBox.Text := TranslateTextIntoRussian(A_Clipboard)

    SetTimer checkWinFocusLost, 100

    checkWinFocusLost()
    {
        If (!WinActive("ahk_id" MyGui.Hwnd))
        {
            MyGui.Destroy()
            SetTimer checkWinFocusLost, 0
        }
    }
}
#HotIf
