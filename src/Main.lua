return function(LoadModule)
    assert(
        type(LoadModule) == "function",
        "LoadModule inválido"
    )

    ---------------------------------------------------------
    -- 1. CARREGAR DEPENDÊNCIAS
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
    -- 2. CARREGAR MÓDULOS
    ---------------------------------------------------------

    local ESPModule =
        LoadModule("Modules/ESP.lua")

    local DeadBodyModule =
        LoadModule("Modules/DeadBodyChams.lua")

    local AimbotModule =
        LoadModule("Modules/Aimbot.lua")

    local AimProviderModule =
        LoadModule("Modules/AimProvider.lua")

    local UI =
        LoadModule("Ui.lua")


    ---------------------------------------------------------
    -- 3. INICIALIZAÇÃO
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
    -- 4. CONTEXT
    ---------------------------------------------------------

    local Context = {
        Library = Library,
        Config = Config,

        -- ESP
        ToggleESP =
            ESP.Toggle,

        DestroyESP =
            ESP.Destroy,

        -- DEAD BODY
        ToggleDeadBodyChams =
            DeadBody.Toggle,

        DestroyDeadBodyChams =
            DeadBody.Destroy,

        -- AIMBOT
        ToggleAimbot =
            Aimbot.Toggle,

        DestroyAimbot =
            Aimbot.Destroy,
    }


    ---------------------------------------------------------
    -- 5. UI
    ---------------------------------------------------------

    local Window,
        Tabs =
        UI.Create(Context)


    ---------------------------------------------------------
    -- 6. ADDONS
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
    -- 7. RESULTADO
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