#include %A_LineFile%\..\IC_DMSpecialGuestFinder_Functions.ahk
#include %A_LineFile%\..\..\..\SharedFunctions\CSharpRNG.ahk

GUIFunctions.AddTab("DM")

Gui, ICScriptHub:Tab, DM
Gui, ICScriptHub:Font, w700
Gui, ICScriptHub:Add, Text, x15 y80, DM Special Guest Finder
Gui, ICScriptHub:Font, w400
Gui, ICScriptHub:Add, Text, x15 y+5 w450 wrap, This AddOn will launch a seaparte script that will reload an adventure until the selected special guest for DM is found
Gui, ICScriptHub:Add, Text, x15 y+15, Select the Champion you would like to bring in with DM

Gui, ICScriptHub:Add, ComboBox, xp+15 yp+15 w300 vDMSpecialGuestComboBoxID

Gui, ICScriptHub:Add, Button, x15 y+15 w75 vButtonDMSpecialGuestFinderRun, Run
runFinder := Func("IC_DMSpecialGuestFinder_Component.Run")
GuiControl, ICScriptHub: +g, ButtonDMSpecialGuestFinderRun, % runFinder

Gui, ICScriptHub:Add, Button, x15 y+10 w160 gDMSpecialGuestFinder_Predict, Predict

DMSpecialGuestFinder_Predict()
{
    global
    g_SF.Hwnd := WinExist("ahk_exe " . g_UserSettings[ "ExeName" ])
    g_SF.Memory.OpenProcessReader()

    local currentGuestId := IC_DMSpecialGuestFinder_Functions.ReadDMSpecialGuest()
    local currentGuestName := g_SF.Memory.ReadChampNameByID(currentGuestId)
    Gui, ICScriptHub:Add, Text, x15 y+15, % "Current Guest " currentGuestName " (" currentGuestId ")"

    local seed := g_SF.Memory.GameManager.game.gameInstances[g_SF.Memory.GameInstance].Controller.userData.StatHandler.Resets.Read()
    local rand := new CSharpRNG(seed - 1)

    ; Work out available seats
    local size = g_SF.Memory.GameManager.game.gameInstances[g_SF.Memory.GameInstance].HeroHandler.allowHeroPurchase.size.Read()
    MsgBox, % "Seats: " size
    local i = 0
    loop, %size% {
        local allowed := g_SF.GameManager.game.gameInstances[g_SF.Memory.GameInstance].HeroHandler.allowHeroPurchase[i].Read()
        local heroId := g_SF.GameManager.game.gameInstances[g_SF.Memory.GameInstance].HeroHandler.allowHeroPurchase["key", i].Read()
        MsgBox, % "Index: " i " HeroId: " heroId " Allowed: " allowed
        i++
    }
}

IC_DMSpecialGuestFinder_Component.ReadChamps()

class IC_DMSpecialGuestFinder_Component
{
    ReadChamps()
    {
        g_SF.Hwnd := WinExist("ahk_exe " . g_UserSettings[ "ExeName" ])
        g_SF.Memory.OpenProcessReader()

        size := g_SF.Memory.ReadChampListSize()
        comboBoxOptions := "|"
        if (!size OR size > 3000 OR size < 0)
        {
            comboBoxOptions .= "-- Error Reading Champions --"
            GuiControl,ICScriptHub:, DMSpecialGuestComboBoxID, %comboBoxOptions%
            return
        }
        loop, %size%
        {
            champID := this.IndexToChampId(A_Index)
            if (champId > 0 and g_SF.Memory.ReadHeroIsOwned(champID)) {
                champName := g_SF.Memory.ReadChampNameByID(champID)
                comboBoxOptions .= champID . " " . champName . "|"
            }
        }
        GuiControl,ICScriptHub:, DMSpecialGuestComboBoxID, %comboBoxOptions%
    }

    IndexToChampId(index)
    {
        if (index < 107)
            return index
        if (index < 134)
            return index + 1
        return index + 2
   }

   Run()
   {
    global
    Gui,ICScriptHub:Submit, NoHide

    if (!IC_DMSpecialGuestFinder_Functions.ReadDMSpecialGuest()) {
        MsgBox % "No current special guest found - verify you are on a restricted adventure"
        return
    }

    scriptLocation := A_LineFile . "\..\IC_DMSpecialGuestFinder_Run.ahk"
    Run, %A_AhkPath% "%scriptLocation%" "%DMSpecialGuestComboBoxID%"
   }
}
