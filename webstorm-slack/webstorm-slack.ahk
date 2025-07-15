#NoEnv
#SingleInstance Force
#Persistent
SendMode Input
SetWorkingDir %A_ScriptDir%

global SlackToken
IniRead, SlackToken, config.ini, Slack, Token, ""

; WebStorm Git Branch Monitor
; ������������� ����������� �������� ���� ������ 5 ������

; ���������� ���������� ��� ����������� ���� � ������������ recentProjects.xml
currentRecentProjectsPath := ""

; ���������� ��� ������������ ���������� ������������� �������
lastProcessedProject := ""

; ��������� ������ ��� �������� ������ 5 ������ (5000 ��)
SetTimer, CheckActiveWindow, 5000

CheckActiveWindow:
    ; �������� ���������� �� �������� ����
    WinGet, activeProcess, ProcessName, A
    WinGetTitle, activeTitle, A

    ; ���������, �������� �� �������� ���������� WebStorm
    if (activeProcess = "webstorm64.exe" or activeProcess = "webstorm.exe") {
        ; �������� PID ��������� ����
        WinGet, activePID, PID, A

        ; �������� ���� � ������� WebStorm
        projectPath := GetWebStormProjectPath(activePID)

        if (projectPath != "") {
            ; ���������, �� ������������ �� �� ��� ���� ������ �������
            if (projectPath != lastProcessedProject) {
                ; �������� �������� git �����
                gitBranch := GetGitBranch(projectPath)

                if (gitBranch != "") {
                    ; ��������� ������ ����� � ��������� LETTERS-NUMBERS
                    taskId := ExtractTaskIdFromBranch(gitBranch)

                    if (taskId != "") {
                        ; ��������� ������ � Slack
                        UpdateSlackStatus(taskId)

                        ; ���������� ������������ ������
                        lastProcessedProject := projectPath
                    }
                }
            }
        }
    } else {
        ; ���� �������� ���� �� WebStorm, ���������� lastProcessedProject
        lastProcessedProject := ""
    }
return

; ������� ��� ���������� LETTERS-NUMBERS �� �������� �����
ExtractTaskIdFromBranch(branchName) {
    try {
        ; ��������� ������ feature/LETTERS-NUMBERS
        if (RegExMatch(branchName, "i)^feature/([A-Z]+-\d+)", match)) {
            return match1
        }
        return ""
    } catch e {
        return ""
    }
}

; ������� ��� ���������� ������� � Slack
UpdateSlackStatus(taskId) {
    try {
        ; ������ WinHTTP ������
        http := ComObjCreate("WinHttp.WinHttpRequest.5.1")

        ; ����������� ������
        http.Open("POST", "https://slack.com/api/users.profile.set", false)

        ; ������������� ���������
        http.SetRequestHeader("Authorization", "Bearer " . SlackToken)
        http.SetRequestHeader("Content-Type", "application/json; charset=utf-8")

        ; ��������� JSON (������� ���������������� �����)
        jsonBody := "{""profile"":{""status_text"":""������� ��� " . taskId . """,""status_emoji"":"":technologist:"",""status_expiration"":0}}"

        ; ���������� ������
        http.Send(jsonBody)

        ; �������� ����� (��� ������ ���������)
        responseText := http.ResponseText
        statusCode := http.Status

    } catch e {
        ; ������������ ������ �����
    }
}

; ������� ��� ������ ������ �������� ����� recentProjects.xml
FindLatestRecentProjectsFile() {
    try {
        jetbrainsPath := A_AppData . "\JetBrains"

        if (!FileExist(jetbrainsPath)) {
            return ""
        }

        latestFile := ""
        latestTime := 0

        ; ���� ��� ����� ������������ � "WebStorm"
        Loop, Files, %jetbrainsPath%\WebStorm*, D
        {
            recentProjectsFile := A_LoopFileFullPath . "\options\recentProjects.xml"

            if (FileExist(recentProjectsFile)) {
                FileGetTime, fileTime, %recentProjectsFile%, M

                ; ���������� ����� �����������
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

; ������� ��� ��������� ������������� ���� � recentProjects.xml � ���������
GetCurrentRecentProjectsPath() {
    ; ���� ���� ��� ������, ���������� ���
    if (currentRecentProjectsPath != "" and FileExist(currentRecentProjectsPath)) {
        return currentRecentProjectsPath
    }

    ; ����� ���������� �����
    currentRecentProjectsPath := FindLatestRecentProjectsFile()
    return currentRecentProjectsPath
}

; ������� ��� ��������� ���� � ������� WebStorm ����� ������������� �������� ������� � frameTitle
GetWebStormProjectPath(pid) {
    try {
        ; �������� ��������� ��������� ����
        WinGetTitle, windowTitle, A

        ; ��������� ��� ������� (������ ����� �� ������)
        projectName := ExtractProjectNameFromTitle(windowTitle)
        if (projectName = "") {
            return ""
        }

        ; ���� ������ � recentProjects.xml �� frameTitle
        projectPath := FindProjectByFrameTitle(projectName)

        return projectPath

    } catch e {
        return ""
    }
}

; ������� ��� ���������� ����� ������� �� ��������� ���� (������ �����)
ExtractProjectNameFromTitle(windowTitle) {
    try {
        ; ���� ������ ������ �� ������
        spacePos := InStr(windowTitle, " ")

        if (spacePos > 0) {
            projectName := Trim(SubStr(windowTitle, 1, spacePos - 1))
            return projectName
        } else {
            ; ���� �������� ���, ���������� ���� ���������
            return Trim(windowTitle)
        }

    } catch e {
        return ""
    }
}

; ������� ��� ������ ������� �� frameTitle � recentProjects.xml
FindProjectByFrameTitle(projectName) {
    try {
        configPath := GetCurrentRecentProjectsPath()

        if (configPath = "" or !FileExist(configPath)) {
            return ""
        }

        FileRead, configContent, %configPath%

        ; ���� ��� RecentProjectMetaInfo ������ � ����� ������
        allMatches := []
        pos := 1
        while (pos := RegExMatch(configContent, "i)<RecentProjectMetaInfo[^>]*frameTitle=""([^""]*)""\s+[^>]*>", match, pos)) {
            frameTitle := match1

            ; ��������� ������ ����� �� frameTitle
            spacePos := InStr(frameTitle, " ")
            frameTitleFirstWord := ""
            if (spacePos > 0) {
                frameTitleFirstWord := Trim(SubStr(frameTitle, 1, spacePos - 1))
            } else {
                frameTitleFirstWord := Trim(frameTitle)
            }

            ; ���������, ��������� �� ������ ����� frameTitle � ������ �������
            if (frameTitleFirstWord = projectName) {
                ; ���� ��������������� entry key (���� � �������) ����� ���� �����
                beforeMatch := SubStr(configContent, 1, pos - 1)

                ; ���� ��������� entry key ����� ����� RecentProjectMetaInfo
                if (RegExMatch(beforeMatch, "i).*<entry key=""([^""]+)""", pathMatch)) {
                    projectPath := pathMatch1
                    if (FileExist(projectPath)) {
                        allMatches.Push({path: projectPath, pos: pos})
                    }
                }
            }

            pos += StrLen(match)
        }

        ; ���������� ��������� (����� ������) ��������� ������
        if (allMatches.Length() > 0) {
            lastMatch := allMatches[allMatches.Length()]
            return lastMatch.path
        }

        return ""

    } catch e {
        return ""
    }
}

; ������� ��� ��������� ���������� ��������� ������� �� ������������ WebStorm
GetRecentWebStormProject() {
    try {
        configPath := GetCurrentRecentProjectsPath()

        if (configPath = "" or !FileExist(configPath)) {
            return ""
        }

        FileRead, configContent, %configPath%

        ; ���� ��� ������� � �������
        lastProject := ""
        pos := 1
        while (pos := RegExMatch(configContent, "i)<entry key=""([^""]+)""", projectMatch, pos)) {
            lastProject := projectMatch1
            pos += StrLen(projectMatch)
        }

        ; ���������� ��������� ��������� ������
        if (lastProject != "" and FileExist(lastProject)) {
            return lastProject
        }

        return ""
    } catch e {
        return ""
    }
}

; ������� ��� ��������� �������� git �����
GetGitBranch(projectPath) {
    try {
        ; ���������, ���������� �� .git ����������
        if (!FileExist(projectPath . "\.git")) {
            return ""
        }

        ; ��������� git ������� ��� ��������� ������� �����
        RunWait, %ComSpec% /c cd /d "%projectPath%" && git branch --show-current > "%A_Temp%\git_branch.tmp", , Hide

        ; ������ ��������� �� ���������� �����
        FileRead, gitBranch, %A_Temp%\git_branch.tmp

        ; ������� ��������� ����
        FileDelete, %A_Temp%\git_branch.tmp

        ; ������� �� ������ ��������
        gitBranch := Trim(gitBranch, " `t`n`r")

        ; ���� ������� ���� �� ���������, ������� �������������� ������
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

; ������� ��� ���������� ����� ������� �� ����
GetProjectName(projectPath) {
    ; ������� ����������� ���� ���� ����
    projectPath := RTrim(projectPath, "\")

    ; ��������� ��������� ���� � ����� ��� ��� �������
    SplitPath, projectPath, projectName

    return projectName
}
