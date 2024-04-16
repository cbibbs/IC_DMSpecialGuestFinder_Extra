class IC_DMSpecialGuestFinder_Functions
{
    ReadDMSpecialGuest()
    {
        g_SF.Hwnd := WinExist("ahk_exe " . g_UserSettings[ "ExeName" ])
        g_SF.Memory.OpenProcessReader()

        ; Temp memory reads - v503
        if (!IsObject(g_SF.Memory.GameManager.game.gameInstances.StatHandler.DSpec1HeroId)) {
            g_SF.Memory.GameManager.game.gameInstances.StatHandler.DSpec1HeroId := New GameObjectStructure(g_SF.Memory.GameManager.game.gameInstances.StatHandler,"Int", [0x27c])
            g_SF.Memory.GameManager.game.gameInstances.ResetCollections()
        }

        return g_SF.Memory.GameManager.game.gameInstances[g_SF.Memory.GameInstance].StatHandler.DSpec1HeroId.Read()
    }
}
