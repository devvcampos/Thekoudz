return function(LoadModule)
    assert(
        type(LoadModule) == "function",
        "LoadModule invalido"
    )

    ---------------------------------------------------------
    -- DEPENDENCIAS
    ---------------------------------------------------------

    local Config =
        LoadModule("Config.lua")

    local Library =
        LoadModule("Library.lua")

    local ThemeManager =
        LoadModule("addons/ThemeManager.lua")

    local SaveManager =
        LoadModule("addons/SaveManager.lua")


    ---------------------------------------------------------
    -- MODULOS
    ---------------------------------------------------------

    local ESPModule =
        LoadModule("Modules/ESP.lua")

    local DeadBodyModule =
        LoadModule("Modules/DeadBodyChams.lua")

    local AimProviderModule =
        LoadModule("Modules/AimProvider.lua")

    local AimbotModule =
        LoadModule("Modules/Aimbot.lua")

    local UI =
        LoadModule("Ui.lua")


    ---------------------------------------------------------
    -- INIT
    ---------------------------------------------------------

    local ESP =
        ESPModule.Init(Config)

    local DeadBody =
        DeadBodyModule.Init(Config)

    local AimProvider =
        AimProviderModule.Init(Config)

    local Aimbot =
        AimbotModule.Init(
            Config,
            AimProvider
        )


    ---------------------------------------------------------
    -- CONTEXT
    ---------------------------------------------------------

    local Context = {
        Library = Library,
        Config = Config,

        ToggleESP =
            ESP.Toggle,

        DestroyESP =
            ESP.Destroy,

        ToggleDeadBodyChams =
            DeadBody.Toggle,

        DestroyDeadBodyChams =
            DeadBody.Destroy,

        ToggleAimbot =
            Aimbot.Toggle,

        DestroyAimbot =
            Aimbot.Destroy,

        GetAimTarget =
            Aimbot.GetTarget,

        GetAimDirection =
            Aimbot.GetDirection,
    }


    ---------------------------------------------------------
    -- UI
    ---------------------------------------------------------

    local Window,
        Tabs =
        UI.Create(Context)


    ---------------------------------------------------------
    -- ADDONS
    ---------------------------------------------------------

    ThemeManager:SetLibrary(
        Library
    )

    SaveManager:SetLibrary(
        Library
    )

    SaveManager:
        IgnoreThemeSettings()

    ThemeManager:
        ApplyToTab(
            Tabs.UI
        )

    SaveManager:
        BuildConfigSection(
            Tabs.UI
        )

    SaveManager:
        LoadAutoloadConfig()


    ---------------------------------------------------------
    -- RETURN
    ---------------------------------------------------------

    return {
        Window = Window,
        Tabs = Tabs,

        Config = Config,

        ESP = ESP,
        DeadBody = DeadBody,

        AimProvider =
            AimProvider,

        Aimbot =
            Aimbot,
    }
end
