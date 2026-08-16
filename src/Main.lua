return function(LoadModule)
    assert(
        type(LoadModule) == "function",
        "LoadModule inválido"
    )

    ---------------------------------------------------------
    -- 1. CARREGAR DEPENDÊNCIAS (Tudo com LoadModule)
    ---------------------------------------------------------
    local Config = LoadModule("Config.lua")
    local Library = LoadModule("Library.lua")
    local ThemeManager = LoadModule("addons/ThemeManager.lua")
    local SaveManager = LoadModule("addons/SaveManager.lua")

    ---------------------------------------------------------
    -- 2. CARREGAR MÓDULOS
    ---------------------------------------------------------
    local ESPModule = LoadModule("Modules/ESP.lua")
    local DeadBodyModule = LoadModule("Modules/DeadBodyChams.lua")
    local AimbotModule = LoadModule("Modules/Aimbot.lua") -- NOVO: Carregando o seu aimbot
    local AimbotModule = LoadModule("Modules/AimProvider.lua")
    local UI = LoadModule("Ui.lua")

    ---------------------------------------------------------
    -- 3. INICIALIZAÇÃO
    ---------------------------------------------------------
    local ESP = ESPModule.Init(Config)
    local DeadBody = DeadBodyModule.Init(Config)
    local AimProvider =AimProviderModule.Init(Config)
    local Aimbot = AimbotModule.Init(Config) -- NOVO: Inicializando o aimbot

    ---------------------------------------------------------
    -- 4. MONTAR O CONTEXT
    ---------------------------------------------------------
    local Context = {
        Library = Library,
        Config = Config,

        ToggleESP = ESP.Toggle,
        DestroyESP = ESP.Destroy,

        ToggleDeadBodyChams = DeadBody.Toggle,
        DestroyDeadBodyChams = DeadBody.Destroy,

        ToggleAimbot = Aimbot.Toggle,          -- NOVO: Expondo o toggle do aimbot
        DestroyAimbot = Aimbot.Destroy,        -- (Opcional, se você tiver uma função de destroy no Aimbot)
    }

    ---------------------------------------------------------
    -- 5. CRIAÇÃO DA UI
    ---------------------------------------------------------
    local Window, Tabs = UI.Create(Context)

    ---------------------------------------------------------
    -- 6. INICIAR ADDONS (ThemeManager e SaveManager)
    ---------------------------------------------------------
    ThemeManager:SetLibrary(Library)
    SaveManager:SetLibrary(Library)
    SaveManager:IgnoreThemeSettings()
    ThemeManager:ApplyToTab(Tabs.UI)
    SaveManager:BuildConfigSection(Tabs.UI)
    SaveManager:LoadAutoloadConfig()

    ---------------------------------------------------------
    -- 7. RESULTADO FINAL
    ---------------------------------------------------------
    return {
        Window = Window,
        Tabs = Tabs,
        Config = Config,
        ESP = ESP,
        DeadBody = DeadBody,
        Aimbot = Aimbot, -- NOVO: Retornando o aimbot para o seu sistema de build
    }
end
