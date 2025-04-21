#Requires AutoHotkey v2.0

#b:: {
    files := GetClipboardFiles()
    if !files.Length {
        MsgBox 'Нет файлов в буфере обмена.'
        return
    }

    root := GetCommonRoot(files)
    allFiles := []

    for file in files {
        if DirExist(file) {
            Loop Files, file . '\*', 'R'
                allFiles.Push(A_LoopFileFullPath)
        } else {
            allFiles.Push(file)
        }
    }

    nl := "`n"
    xml := '<files>' . nl
    for path in allFiles {
        rel := SubStr(path, StrLen(root) + 1)
        content := GetFileContent(path)
        xml .= '<file path="' . rel . '">' . nl
        xml .= content . nl
        xml .= '</file>' . nl
    }
    xml .= '</files>'

    A_Clipboard := xml
    ClipWait()
    Send '^v'
}

; Получение файлов из буфера обмена (работает с Ctrl+C из Проводника)
GetClipboardFiles() {
    files := []
    CF_HDROP := 15

    if !DllCall("IsClipboardFormatAvailable", "UInt", CF_HDROP)
        return files

    if !DllCall("OpenClipboard", "Ptr", 0)
        return files

    hDrop := DllCall("GetClipboardData", "UInt", CF_HDROP, "Ptr")
    if !hDrop {
        DllCall("CloseClipboard")
        return files
    }

    count := DllCall("shell32\DragQueryFileW", "Ptr", hDrop, "UInt", 0xFFFFFFFF, "Ptr", 0, "UInt", 0)
    loop count {
        len := DllCall("shell32\DragQueryFileW", "Ptr", hDrop, "UInt", A_Index - 1, "Ptr", 0, "UInt", 0)
        buf := Buffer((len + 1) * 2)
        DllCall("shell32\DragQueryFileW", "Ptr", hDrop, "UInt", A_Index - 1, "Ptr", buf, "UInt", len + 1)
        files.Push(StrGet(buf, "UTF-16"))
    }

    DllCall("CloseClipboard")
    return files
}

GetCommonRoot(paths) {
    root := paths[1]
    for index, path in paths {
        if index = 1
            continue
        root := StrCommonPrefix(root, path)
    }
    last := 0
    while pos := InStr(root, '\', false, last + 1)
        last := pos
    return last ? SubStr(root, 1, last) : ''
}

StrCommonPrefix(s1, s2) {
    maxLen := StrLen(s1) < StrLen(s2) ? StrLen(s1) : StrLen(s2)
    i := 1
    while (i <= maxLen && SubStr(s1, i, 1) = SubStr(s2, i, 1))
        i++
    return SubStr(s1, 1, i - 1)
}

GetFileContent(path) {
    try content := FileRead(path, "UTF-8")
    catch
        return 'BINARY_DATA'
    if RegExMatch(content, "\x00")
        return 'BINARY_DATA'
    return content
}
