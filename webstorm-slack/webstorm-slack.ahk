#NoEnv
#SingleInstance Force
#Persistent
SendMode Input
SetWorkingDir %A_ScriptDir%

global SlackToken
global WorkStartHour
global WorkEndHour
global lastProcessedProject
global currentRecentProjectsPath
global lastWorkingStatus ; для отслеживания смены рабочего/нерабочего времени

; Читаем настройки из конфигурационного файла
IniRead, SlackToken, config.ini, Slack, Token, ""
IniRead, WorkStartHour, config.ini, WorkingHours, StartHour, 10
IniRead, WorkEndHour, config.ini, WorkingHours, EndHour, 19

; WebStorm Git Branch Monitor
; Автоматически отслеживает активное окно каждые 5 секунд
; Обновляет статус в Slack только в рабочие часы

; Глобальная переменная для кэширования пути к конфигурации recentProjects.xml
currentRecentProjectsPath := ""

; Переменная для отслеживания последнего обработанного проекта
lastProcessedProject := ""

; Переменная для отслеживания последнего статуса рабочего времени
lastWorkingStatus := IsWorkingHours()

; Инициализация при запуске
Gosub, InitializeScript

; Запускаем таймер для проверки каждые 5 секунд (5000 мс)
SetTimer, CheckActiveWindow, 5000

; Дополнительный таймер для проверки смены рабочего времени каждую минуту
SetTimer, CheckWorkingHoursChange, 60000

; Инициализация скрипта при запуске
InitializeScript:
    if (!IsWorkingHours()) {
        ; Если запускаемся в нерабочее время - сбрасываем статус
        ClearSlackStatus()
    }
return

; Проверка смены рабочего времени
CheckWorkingHoursChange:
    currentWorkingStatus := IsWorkingHours()

    ; Если статус рабочего времени изменился
    if (currentWorkingStatus != lastWorkingStatus) {
        if (!currentWorkingStatus) {
            ; Если перешли в нерабочее время - сбрасываем статус
            ClearSlackStatus()
            lastProcessedProject := "" ; Сбрасываем кэш проекта
        }
        lastWorkingStatus := currentWorkingStatus
    }
return

CheckActiveWindow:
    ; Проверяем, находимся ли мы в рабочее время
    if (!IsWorkingHours()) {
        ; Если нерабочее время - ничего не делаем
        return
    }

    ; Получаем информацию об активном окне
    WinGet, activeProcess, ProcessName, A
    WinGetTitle, activeTitle, A

    ; Проверяем, является ли активное приложение WebStorm
    if (activeProcess = "webstorm64.exe" or activeProcess = "webstorm.exe") {
        ; Получаем PID активного окна
        WinGet, activePID, PID, A

        ; Получаем путь к проекту WebStorm
        projectPath := GetWebStormProjectPath(activePID)

        if (projectPath != "") {
            ; Проверяем, не обрабатывали ли мы уже этот проект недавно
            if (projectPath != lastProcessedProject) {
                ; Получаем название git ветки
                gitBranch := GetGitBranch(projectPath)

                if (gitBranch != "") {
                    ; Проверяем формат ветки и извлекаем LETTERS-NUMBERS
                    taskId := ExtractTaskIdFromBranch(gitBranch)

                    if (taskId != "") {
                        ; Обновляем статус в Slack
                        UpdateSlackStatus(taskId)

                        ; Запоминаем обработанный проект
                        lastProcessedProject := projectPath
                    }
                }
            }
        }
    }
return

; Функция для проверки рабочего времени
IsWorkingHours() {
    try {
        FormatTime, currentHour, , HH
        currentHour := currentHour + 0 ; Конвертируем в число

        return (currentHour >= WorkStartHour and currentHour < WorkEndHour)
    } catch e {
        return false
    }
}

; Функция для сброса статуса в Slack
ClearSlackStatus() {
    try {
        ; Создаём WinHTTP объект
        http := ComObjCreate("WinHttp.WinHttpRequest.5.1")

        ; Настраиваем запрос
        http.Open("POST", "https://slack.com/api/users.profile.set", false)

        ; Устанавливаем заголовки
        http.SetRequestHeader("Authorization", "Bearer " . SlackToken)
        http.SetRequestHeader("Content-Type", "application/json; charset=utf-8")

        ; Формируем JSON для сброса статуса
        jsonBody := "{""profile"":{""status_text"":"""",""status_emoji"":"""",""status_expiration"":0}}"

        ; Отправляем запрос
        http.Send(jsonBody)

        ; Получаем ответ (без вывода сообщений)
        responseText := http.ResponseText
        statusCode := http.Status

    } catch e {
        ; Обрабатываем ошибки молча
    }
}

; Функция для извлечения LETTERS-NUMBERS из названия ветки
ExtractTaskIdFromBranch(branchName) {
    try {
        ; Проверяем формат feature/LETTERS-NUMBERS
        if (RegExMatch(branchName, "i)^feature/([A-Z]+-\d+)", match)) {
            return match1
        }
        return ""
    } catch e {
        return ""
    }
}

; Функция для обновления статуса в Slack
UpdateSlackStatus(taskId) {
    try {
        ; Создаём WinHTTP объект
        http := ComObjCreate("WinHttp.WinHttpRequest.5.1")

        ; Настраиваем запрос
        http.Open("POST", "https://slack.com/api/users.profile.set", false)

        ; Устанавливаем заголовки
        http.SetRequestHeader("Authorization", "Bearer " . SlackToken)
        http.SetRequestHeader("Content-Type", "application/json; charset=utf-8")

        ; Формируем JSON (простое конкатенирование строк)
        jsonBody := "{""profile"":{""status_text"":""Работаю над " . taskId . """,""status_emoji"":"":technologist:"",""status_expiration"":0}}"

        ; Отправляем запрос
        http.Send(jsonBody)

        ; Получаем ответ (без вывода сообщений)
        responseText := http.ResponseText
        statusCode := http.Status

    } catch e {
        ; Обрабатываем ошибки молча
    }
}

; Функция для поиска самого позднего файла recentProjects.xml
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

; Функция для получения кэшированного пути к recentProjects.xml с проверкой
GetCurrentRecentProjectsPath() {
    ; Если путь уже найден, возвращаем его
    if (currentRecentProjectsPath != "" and FileExist(currentRecentProjectsPath)) {
        return currentRecentProjectsPath
    }

    ; Иначе производим поиск
    currentRecentProjectsPath := FindLatestRecentProjectsFile()
    return currentRecentProjectsPath
}

; Функция для получения пути к проекту WebStorm через идентификацию названия проекта и frameTitle
GetWebStormProjectPath(pid) {
    try {
        ; Получаем заголовок активного окна
        WinGetTitle, windowTitle, A

        ; Извлекаем имя проекта (первое слово из тайтла)
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
        ; Ищем первый пробел до дефиса
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

        ; Ищем все RecentProjectMetaInfo записи с таким именем
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
                ; Ищем соответствующий entry key (путь к проекту) перед этим тегом
                beforeMatch := SubStr(configContent, 1, pos - 1)

                ; Ищем последний entry key перед нашим RecentProjectMetaInfo
                if (RegExMatch(beforeMatch, "i).*<entry key=""([^""]+)""", pathMatch)) {
                    projectPath := pathMatch1
                    if (FileExist(projectPath)) {
                        allMatches.Push({path: projectPath, pos: pos})
                    }
                }
            }

            pos += StrLen(match)
        }

        ; Возвращаем последний (самый свежий) найденный проект
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

        ; Ищем все проекты в порядке
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

; Функция для получения названия git ветки
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
    ; Убираем завершающий слэш если есть
    projectPath := RTrim(projectPath, "\")

    ; Извлекаем последний путь в папке как имя проекта
    SplitPath, projectPath, projectName

    return projectName
}
