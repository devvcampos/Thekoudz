return function(LoadModule)
    assert(
        type(LoadModule) == "function",
        "LoadModule inválido"
    )

    ---------------------------------------------------------
    -- DEPENDÊNCIAS
    ---------------------------------------------------------

    local Library =
        LoadModule("Library.lua")

    local ThemeManager =
        LoadModule("addons/ThemeManager.lua")

    local SaveManager =
        LoadModule("addons/SaveManager.lua")

    ---------------------------------------------------------
    -- CONFIG
    ---------------------------------------------------------

    local Config =
        LoadModule("Config.lua")

    ---------------------------------------------------------
    -- MÓDULOS
    ---------------------------------------------------------

    local ESPModule =
        LoadModule("Modules/ESP.lua")

    local DeadBodyModule =
        LoadModule("Modules/DeadBodyChams.lua")

    local UI =
        LoadModule("Ui.lua")

    ---------------------------------------------------------
    -- INICIALIZAÇÃO
    ---------------------------------------------------------

    local ESP =
        ESPModule.Init(Config)

    local DeadBody =
        DeadBodyModule.Init(Config)

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
    }

    ---------------------------------------------------------
    -- UI
    ---------------------------------------------------------

    local Window, Tabs =
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

    SaveManager:IgnoreThemeSettings()

    ThemeManager:ApplyToTab(
        Tabs.UI
    )

    SaveManager:BuildConfigSection(
        Tabs.UI
    )

    SaveManager:LoadAutoloadConfig()

    ---------------------------------------------------------
    -- RESULTADO
    ---------------------------------------------------------

    return {
        Window = Window,
        Tabs = Tabs,

        Config = Config,

        ESP = ESP,
        DeadBody = DeadBody,
    }
end
