#NoEnv
#SingleInstance Force
SendMode Input
SetWorkingDir %A_ScriptDir%

; WebStorm Git Branch Checker
; Горячая клавиша: Win + F9

; Глобальная переменная для кэширования пути к актуальному recentProjects.xml
currentRecentProjectsPath := ""

#F9::
    ; Получаем информацию об активном окне
    WinGet, activeProcess, ProcessName, A
    WinGetTitle, activeTitle, A

    ; Проверяем, является ли активный процесс WebStorm
    if (activeProcess = "webstorm64.exe" or activeProcess = "webstorm.exe") {
        ; Получаем PID активного окна
        WinGet, activePID, PID, A

        ; Получаем путь к проекту WebStorm
        projectPath := GetWebStormProjectPath(activePID)

        if (projectPath != "") {
            ; Получаем активную git ветку
            gitBranch := GetGitBranch(projectPath)

            if (gitBranch != "") {
                ; Получаем имя проекта из пути
                projectName := GetProjectName(projectPath)

                ; Выводим результат
                MsgBox, 64, Git Branch Info, Проект: %projectName%`nПуть: %projectPath%`nАктивная ветка: %gitBranch%
            } else {
                MsgBox, 48, Git Branch Info, Git репозиторий не найден в проекте или произошла ошибка при получении информации о ветке.
            }
        } else {
            MsgBox, 48, Git Branch Info, Не удалось определить путь к проекту WebStorm.
        }
    } else {
        MsgBox, 48, Git Branch Info, Активное окно не относится к процессу WebStorm.`nТекущий процесс: %activeProcess%
    }
return

; Функция для поиска самого актуального файла recentProjects.xml
FindLatestRecentProjectsFile() {
    try {
        jetbrainsPath := A_AppData . "\JetBrains"

        if (!FileExist(jetbrainsPath)) {
            return ""
        }

        latestFile := ""
        latestTime := 0

        ; Ищем все папки начинающиеся с "WebStorm"
        Loop, Files, %jetbrainsPath%\WebStorm*, D
        {
            recentProjectsFile := A_LoopFileFullPath . "\options\recentProjects.xml"

            if (FileExist(recentProjectsFile)) {
                FileGetTime, fileTime, %recentProjectsFile%, M

                ; Сравниваем время модификации
                if (fileTime > latestTime) {
                    latestTime := fileTime
                    latestFile := recentProjectsFile
                }
            }
        }

        return latestFile

    } catch e {
        return ""
    }
}

; Функция для получения актуального пути к recentProjects.xml с кэшированием
GetCurrentRecentProjectsPath() {
    ; Если путь уже найден, возвращаем его
    if (currentRecentProjectsPath != "" and FileExist(currentRecentProjectsPath)) {
        return currentRecentProjectsPath
    }

    ; Ищем актуальный файл
    currentRecentProjectsPath := FindLatestRecentProjectsFile()
    return currentRecentProjectsPath
}

; Функция для получения пути к проекту WebStorm через сопоставление заголовка окна с frameTitle
GetWebStormProjectPath(pid) {
    try {
        ; Получаем заголовок активного окна
        WinGetTitle, windowTitle, A

        ; Извлекаем имя проекта (первое слово до тире)
        projectName := ExtractProjectNameFromTitle(windowTitle)
        if (projectName = "") {
            return ""
        }

        ; Ищем проект в recentProjects.xml по frameTitle
        projectPath := FindProjectByFrameTitle(projectName)

        return projectPath

    } catch e {
        return ""
    }
}

; Функция для извлечения имени проекта из заголовка окна (первое слово)
ExtractProjectNameFromTitle(windowTitle) {
    try {
        ; Берем первое слово до пробела
        spacePos := InStr(windowTitle, " ")

        if (spacePos > 0) {
            projectName := Trim(SubStr(windowTitle, 1, spacePos - 1))
            return projectName
        } else {
            ; Если пробелов нет, возвращаем весь заголовок
            return Trim(windowTitle)
        }

    } catch e {
        return ""
    }
}

; Функция для поиска проекта по frameTitle в recentProjects.xml
FindProjectByFrameTitle(projectName) {
    try {
        configPath := GetCurrentRecentProjectsPath()

        if (configPath = "" or !FileExist(configPath)) {
            return ""
        }

        FileRead, configContent, %configPath%

        ; Ищем все RecentProjectMetaInfo записи с конца файла
        allMatches := []
        pos := 1
        while (pos := RegExMatch(configContent, "i)<RecentProjectMetaInfo[^>]*frameTitle=""([^""]*)""\s+[^>]*>", match, pos)) {
            frameTitle := match1

            ; Извлекаем первое слово из frameTitle
            spacePos := InStr(frameTitle, " ")
            frameTitleFirstWord := ""
            if (spacePos > 0) {
                frameTitleFirstWord := Trim(SubStr(frameTitle, 1, spacePos - 1))
            } else {
                frameTitleFirstWord := Trim(frameTitle)
            }

            ; Проверяем, совпадает ли первое слово frameTitle с именем проекта
            if (frameTitleFirstWord = projectName) {
                ; Ищем соответствующий entry key (путь к проекту) перед этой записью
                beforeMatch := SubStr(configContent, 1, pos - 1)

                ; Ищем последний entry key перед нашей RecentProjectMetaInfo
                if (RegExMatch(beforeMatch, "i).*<entry key=""([^""]+)""", pathMatch)) {
                    projectPath := pathMatch1
                    if (FileExist(projectPath)) {
                        allMatches.Push({path: projectPath, pos: pos})
                    }
                }
            }

            pos += StrLen(match)
        }

        ; Возвращаем последний (самый поздний) найденный проект
        if (allMatches.Length() > 0) {
            lastMatch := allMatches[allMatches.Length()]
            return lastMatch.path
        }

        return ""

    } catch e {
        return ""
    }
}

; Функция для получения последнего открытого проекта из конфигурации WebStorm
GetRecentWebStormProject() {
    try {
        configPath := GetCurrentRecentProjectsPath()

        if (configPath = "" or !FileExist(configPath)) {
            return ""
        }

        FileRead, configContent, %configPath%

        ; Ищем все проекты в списке
        lastProject := ""
        pos := 1
        while (pos := RegExMatch(configContent, "i)<entry key=""([^""]+)""", projectMatch, pos)) {
            lastProject := projectMatch1
            pos += StrLen(projectMatch)
        }

        ; Возвращаем последний найденный проект
        if (lastProject != "" and FileExist(lastProject)) {
            return lastProject
        }

        return ""
    } catch e {
        return ""
    }
}

; Функция для получения активной git ветки
GetGitBranch(projectPath) {
    try {
        ; Проверяем, существует ли .git директория
        if (!FileExist(projectPath . "\.git")) {
            return ""
        }

        ; Выполняем git команду для получения текущей ветки
        RunWait, %ComSpec% /c cd /d "%projectPath%" && git branch --show-current > "%A_Temp%\git_branch.tmp", , Hide

        ; Читаем результат из временного файла
        FileRead, gitBranch, %A_Temp%\git_branch.tmp

        ; Удаляем временный файл
        FileDelete, %A_Temp%\git_branch.tmp

        ; Очищаем от лишних символов
        gitBranch := Trim(gitBranch, " `t`n`r")

        ; Если команда выше не сработала, пробуем альтернативный способ
        if (gitBranch = "") {
            RunWait, %ComSpec% /c cd /d "%projectPath%" && git rev-parse --abbrev-ref HEAD > "%A_Temp%\git_branch2.tmp", , Hide
            FileRead, gitBranch, %A_Temp%\git_branch2.tmp
            FileDelete, %A_Temp%\git_branch2.tmp
            gitBranch := Trim(gitBranch, " `t`n`r")
        }

        return gitBranch

    } catch e {
        return ""
    }
}

; Функция для извлечения имени проекта из пути
GetProjectName(projectPath) {
    ; Удаляем завершающий слэш если есть
    projectPath := RTrim(projectPath, "\")

    ; Находим последний слэш и берем все после него
    SplitPath, projectPath, projectName

    return projectName
}
