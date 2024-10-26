#SingleInstance Force
#WinActivateForce
SetWorkingDir A_ScriptDir

; Global variables
global ClientWindowID := 0
global StatusGui := ""
global StatusText := ""
global CurrentStatus := ""
global ActionCount := Map(
    "Stun", 0,
    "LastTargetAttack", 0,
    "Alch", 0,
    "AlchTarget", 0,
    "Failed Searches", 0,
    "Cycle Time", 0
)

; Function to find Sprites folder by searching up directories
FindSpritesFolder() {
    currentDir := A_ScriptDir
    maxLevels := 5  
    
    Loop maxLevels {
        if DirExist(currentDir "\Sprites") {
            return currentDir "\Sprites\"
        }
        
        parentDir := SubStr(currentDir, 1, InStr(currentDir, "\", , -1, -1) - 1)
        if !parentDir
            break
            
        if DirExist(parentDir "\Sprites") {
            return parentDir "\Sprites\"
        }
        
        currentDir := parentDir
    }
    
    throw Error("Sprites folder not found within " maxLevels " parent directories")
}

; Initialize global SpritesPath variable
global SpritesPath := ""
try {
    SpritesPath := FindSpritesFolder()
} catch Error as err {
    MsgBox "Error: " err.Message
    ExitApp
}

; Helper Functions with optimized timeouts
TimedImageSearch(x1, y1, x2, y2, imagePath, timeout := 20000) {
    result := []
    result.Length := 3
    startTime := A_TickCount
    
    while (A_TickCount - startTime < timeout) {
        try {
            if ImageSearch(&foundX, &foundY, x1, y1, x2, y2, "*32 " SpritesPath imagePath) {
                result[1] := true
                result[2] := foundX
                result[3] := foundY
                return result
            }
        }
        Sleep 25
    }
    
    result[1] := false
    result[2] := 0
    result[3] := 0
    return result
}


TimedPixelSearch(x1, y1, x2, y2, color, variation := 0, timeout := 1000) {  ; Reduced timeout to 1 second
    result := []
    result.Length := 3
    startTime := A_TickCount
    while (A_TickCount - startTime < timeout) {
        try {
            if PixelSearch(&foundX, &foundY, x1, y1, x2, y2, color, variation) {
                result[1] := true
                result[2] := foundX
                result[3] := foundY
                return result
            }
        }
        Sleep 25  ; Reduced sleep between attempts
    }
    result[1] := false
    result[2] := 0
    result[3] := 0
    return result
}

; Optimized HumanMouseMove for faster movement while maintaining natural appearance
HumanMouseMove(targetX, targetY) {
    Static smooth := 1.2  ; Reduced smoothness for faster movement
    MouseGetPos(&startX, &startY)
    
    distance := Sqrt((targetX - startX) ** 2 + (targetY - startY) ** 2)
    steps := Min(15, Max(8, distance / 25))  ; Reduced steps for faster movement
    
    controlX1 := startX + (targetX - startX) / 3 + Random(-20, 20)
    controlY1 := startY + (targetY - startY) / 3 + Random(-20, 20)
    controlX2 := startX + (targetX - startX) * 2/3 + Random(-20, 20)
    controlY2 := startY + (targetY - startY) * 2/3 + Random(-20, 20)
    
    t_step := 1 / steps
    
    Loop steps {
        t := A_Index * t_step
        invT := 1 - t
        invT2 := invT * invT
        invT3 := invT2 * invT
        t2 := t * t
        t3 := t2 * t
        
        newX := invT3 * startX + 
                3 * t * invT2 * controlX1 + 
                3 * t2 * invT * controlX2 + 
                t3 * targetX
        newY := invT3 * startY + 
                3 * t * invT2 * controlY1 + 
                3 * t2 * invT * controlY2 + 
                t3 * targetY
        
        newX += Random(-1, 1)
        newY += Random(-1, 1)
        
        stepSpeed := 1.8 * (1 - smooth + (smooth * Sin(t * 3.14159)))  ; Reduced base speed
        
        MouseMove(Round(newX), Round(newY), 0)
        Sleep(Round(stepSpeed))
    }
    
    MouseMove(targetX, targetY, 0)
    Sleep(25)  ; Reduced final pause
}

; Optimized action functions
Stun() {
    Send "{f4}"
    Sleep 35  ; Reduced initial sleep
    
    try {
        searchResult := TimedImageSearch(521, 192, 765, 525, "StandardBook.png")
        if searchResult[1] {
            stunResult := TimedImageSearch(521, 192, 765, 525, "Stun.png")
            if stunResult[1] {
                HumanMouseMove(stunResult[2] + Random(1, 5), stunResult[3] + Random(1, 5))
                Sleep Random(25, 35)  ; Optimized click delay
                Click
                Sleep 35
                ActionCount["Stun"]++
                return true
            }
        }
        ActionCount["Failed Searches"]++
        return false
    } catch Error as err {
        UpdateStatus("Stun Error: " err.Message)
        return false
    }
}

LastTargetAttack() {
    try {
        searchResult := TimedPixelSearch(18, 32, 526, 361, 0x00FFFF, 1)
        if searchResult[1] {
            pxStart := searchResult[2]
            pyStart := searchResult[3]
            
            pixelWidth := 0
            pixelHeight := 0
            
            startTime := A_TickCount
            while (A_TickCount - startTime < 500) {  ; Reduced timeout for width scanning
                if !PixelSearch(&px, &py, pxStart + pixelWidth, pyStart, 
                              pxStart + pixelWidth, pyStart, 0x00FFFF, 1)
                    break
                pixelWidth++
                Sleep 5  ; Reduced scan delay
            }
            
            startTime := A_TickCount
            while (A_TickCount - startTime < 500) {  ; Reduced timeout for height scanning
                if !PixelSearch(&px, &py, pxStart, pyStart + pixelHeight,
                              pxStart, pyStart + pixelHeight, 0x00FFFF, 1)
                    break
                pixelHeight++
                Sleep 5  ; Reduced scan delay
            }
            
            targetX := pxStart + (pixelWidth // 2)
            targetY := pyStart + (pixelHeight // 2)
            targetX += Random(-1, 1)
            targetY += Random(-1, 1)
            
            targetX := Clamp(targetX, 18, 526)
            targetY := Clamp(targetY, 32, 361)
            
            HumanMouseMove(targetX, targetY)
            Sleep Random(25, 35)  ; Optimized click delay
            Click
            Sleep 35
            ActionCount["LastTargetAttack"]++
            return true
        }
        return false
    } catch Error as err {
        UpdateStatus("LastTargetAttack Error: " err.Message)
        return false
    }
}

Alch() {
    Send "{f4}"
    Sleep 35  ; Reduced initial sleep
    
    try {
        bookResult := TimedImageSearch(521, 192, 765, 525, "StandardBook.png")
        if bookResult[1] {
            Sleep 25  ; Reduced intermediate sleep
            alchResult := TimedImageSearch(521, 192, 765, 525, "Alch.png")
            if alchResult[1] {
                HumanMouseMove(alchResult[2] + Random(1, 5), alchResult[3] + Random(1, 5))
                Sleep Random(25, 35)  ; Optimized click delay
                Click
                Sleep 35
                ActionCount["Alch"]++
                return true
            }
        }
        ActionCount["Failed Searches"]++
        return false
    } catch Error as err {
        UpdateStatus("Alch Error: " err.Message)
        return false
    }
}

AlchTarget() {
    Send "{f1}"
    Sleep 35  ; Reduced initial sleep
    
    try {
        tabResult := TimedImageSearch(521, 192, 765, 525, "InventoryTab.png")
        if tabResult[1] {
            Sleep 25  ; Reduced intermediate sleep
            pixelResult := TimedPixelSearch(521, 192, 765, 525, 0xFF0000, 2)
            if pixelResult[1] {
                targetX := Clamp(pixelResult[2] + Random(0, 1), 521, 765)
                targetY := Clamp(pixelResult[3] + Random(0, 1), 192, 525)
                
                HumanMouseMove(targetX, targetY)
                Sleep Random(25, 35)  ; Optimized click delay
                Click
                Sleep 35
                ActionCount["AlchTarget"]++
                return true
            }
        }
        ActionCount["Failed Searches"]++
        return false
    } catch Error as err {
        UpdateStatus("AlchTarget Error: " err.Message)
        return false
    }
}

; GUI and utility functions remain mostly unchanged
CreateStatusGui() {
    global StatusGui, StatusText
    StatusGui := Gui("-Caption +ToolWindow +E0x08000000")
    StatusGui.SetFont("s10", "Consolas")
    StatusText := StatusGui.Add("Text", "w300 h200", "Waiting to start...")
    StatusGui.Show("x0 y0 NoActivate")
    
    if WinExist("ahk_id " ClientWindowID)
        WinActivate("ahk_id " ClientWindowID)
}

UpdateStatus(status) {
    global CurrentStatus, StatusText
    CurrentStatus := status
    UpdateGui()
}

UpdateGui() {
    global StatusText, CurrentStatus, ActionCount
    stats := "Current Action: " CurrentStatus "`n`n"
    stats .= "Statistics:`n"
    stats .= "───────────────────`n"
    for action, count in ActionCount
        stats .= action ": " count "`n"
    
    StatusText.Value := stats
    
    if WinExist("ahk_id " ClientWindowID)
        WinActivate("ahk_id " ClientWindowID)
}

Clamp(value, min, max) {
    if (value < min)
        return min
    if (value > max)
        return max
    return value
}

; Optimized main loop
3:: {
    CreateStatusGui()
    
    ClientWindowID := WinGetID("A")
    if !ClientWindowID {
        UpdateStatus("Error: No active window found!")
        return
    }
    
    UpdateStatus("Script Started")
    WinActivate("ahk_id " ClientWindowID)
    
    Loop {
        cycleStart := A_TickCount
        
        if !WinExist("ahk_id " ClientWindowID) {
            UpdateStatus("Error: Target window lost!")
            return
        }
        
        UpdateStatus("Running Stun")
        Stun()
        Sleep 25  ; Reduced inter-action delay
        
        UpdateStatus("Running LastTargetAttack")
        LastTargetAttack()
        Sleep 25  ; Reduced inter-action delay
        
        UpdateStatus("Checking for magexpdrop")
        try {
            searchResult := TimedImageSearch(18, 32, 526, 361, "magexpdrop.png")
            if searchResult[1] {
                UpdateStatus("Found magexpdrop - Starting Alch sequence")
                Sleep 35
                
                if Alch() {
                    Sleep 50
                    AlchTarget()
                }
                
                Sleep 35
            }
        } catch Error as err {
            UpdateStatus("Magexpdrop check error: " err.Message)
        }
        
        cycleTime := A_TickCount - cycleStart
        sleepTime := Random(3000, 3100) - cycleTime
        
        if (sleepTime > 0)
            Sleep sleepTime
            
        ActionCount["Cycle Time"] := cycleTime + sleepTime
        
        UpdateGui()
        WinActivate("ahk_id " ClientWindowID)
    }
}

; Hotkeys
1::ExitApp
8::Reload
