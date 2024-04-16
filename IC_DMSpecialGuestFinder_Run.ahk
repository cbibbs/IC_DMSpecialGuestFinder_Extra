#SingleInstance, Force

;=======================
;Script Optimization
;=======================
#HotkeyInterval 1000  ; The default value is 2000 (milliseconds).
#MaxHotkeysPerInterval 70 ; The default value is 70
#NoEnv ; Avoids checking empty variables to see if they are environment variables (recommended for all new scripts). Default behavior for AutoHotkey v2.
SetWorkingDir %A_ScriptDir%
SetWinDelay, 33 ; Sets the delay that will occur after each windowing command, such as WinActivate. (Default is 100)
SetControlDelay, 0 ; Sets the delay that will occur after each control-modifying command. -1 for no delay, 0 for smallest possible delay. The default delay is 20.
;SetKeyDelay, 0 ; Sets the delay that will occur after each keystroke sent by Send or ControlSend. [SetKeyDelay , Delay, PressDuration, Play]
SetBatchLines, -1 ; How fast a script will run (affects CPU utilization).(Default setting is 10ms - prevent the script from using any more than 50% of an idle CPU's time.
                  ; This allows scripts to run quickly while still maintaining a high level of cooperation with CPU sensitive tasks such as games and video capture/playback.
ListLines Off
Process, Priority,, High
CoordMode, Mouse, Client

Gui, MyWindow:New
Gui, MyWindow:+Resize -MaximizeBox
Gui, MyWindow:Add, Text, x15 y15, DM Special Guest Finder is running.
Gui, MyWindow:Add, Text, x15 y+5, When the correct Special Guest is found, this window will close and the script will end.
Gui, MyWindow:Add, Text, x15 y+5, To end the script early, just close this window.
Gui, MyWindow:Add, Text, x15 y+15, What is happening:
Gui, MyWindow:Add, Text, x+5 vDMSpecialGuestFinder_LookingFor w300,
Gui, MyWindow:Add, Text, x+5 vDMSpecialGuestFinder_Status w300,

Gui, MyWindow:Show, x0 y0, Running DM Special Guest Finder...

; Global Stuff
#include %A_LineFile%\..\..\IC_Core\IC_SharedFunctions_Class.ahk
#include %A_LineFile%\..\..\..\ServerCalls\IC_ServerCalls_Class.ahk
global g_SF := new IC_SharedFunctions_Class
global g_UserSettings := g_SF.LoadObjectFromJSON( A_LineFile . "\..\..\..\Settings.json" )
global g_ServerCall

; Util
#include %A_LineFile%\..\IC_DMSpecialGuestFinder_Functions.ahk

args := A_Args[1] ? A_Args[1] : "58 Briv"

splitArray := StrSplit(args, " ",,2)
champId := splitArray[1]
champName := splitArray[2]

if (!champId) {
    MsgBox, No Special Guest was passed in
    ExitApp
}

GuiControl, MyWindow:, DMSpecialGuestFinder_LookingFor, % "Looking for " . champName . " (ID: " . champId . ")"

loopCount := 0
loop
{
    ; Initialize shared functions every loop as we're closing the game
    g_SF.Hwnd := WinExist("ahk_exe " . g_UserSettings[ "ExeName" ])
    existingProcessID := g_userSettings[ "ExeName"]
    Process, Exist, %existingProcessID%
    g_SF.PID := ErrorLevel
    g_SF.Memory.OpenProcessReader()
    g_SF.ResetServerCall()

    if (g_SF.Hwnd AND g_SF.PID)
    {
        currentGuestId := IC_DMSpecialGuestFinder_Functions.ReadDMSpecialGuest()
        ; if (currentGuestId == 0) {
        ;     MsgBox, Failed to read DM Special Guest - have we reset to the wrong adventure? - aborting
        ;     ExitApp
        ; }
        currentGuestName := g_SF.Memory.ReadChampNameByID(currentGuestId)
        if (currentGuestId == champId) {
            MsgBox, The correct guest has been found after %loopCount% attempts
            ExitApp
        }

        GuiControl, MyWindow:, DMSpecialGuestFinder_Status, % "Current Guest: " . currentGuestName . " (ID: " . currentGuestId . ")"

        loopCount := loopCount + 1

        ; if (!IsObject(g_ServerCall)) {
        ;     MsgBox, ServerCall not set - aborting
        ;     ExitApp
        ; }

        ; ; close and re-open
        g_SF.CurrentAdventure := g_SF.Memory.ReadCurrentObjID()

        WinActivate, ahk_exe IdleDragons.exe
        ;MouseClick, Left, 320, 85, 1, 0 ; Complete Adventure
        g_SF.DirectedInput(,,"{r}")
        Sleep, 2000 ; Wait for the dialog
        MouseClick, Left, 550, 550, 1, 0 ; Complete on dialog
        Sleep, 2000 ; Wait for the next page

        ;MsgBox, Should have completed
        ; g_SF.CloseIC("Looking for a Special Guest")
        ; response := g_ServerCall.CallEndAdventure()
        ; OutputDebug, % "EndAdventure: " . response . "`n"
        ; g_SF.SafetyCheck()
        g_SF.CloseIC("Looking for a Special Guest")
        ; OutputDebug, % "Loading " . g_SF.CurrentAdventure . "`n"
        response := g_ServerCall.CallLoadAdventure(g_SF.CurrentAdventure)
        ; OutputDebug, % "LoadAdventure: " . response . "`n"
        g_SF.SafetyCheck()
    }
    else
        GuiControl, MyWindow:, DMSpecialGuestFinder_Status, Waiting for IC open...
    sleep, 250
}

MyWindowGuiClose()
{
    MsgBox 4,, Are you sure you want to `exit?
    IfMsgBox Yes
    ExitApp
    IfMsgBox No
    return True
}