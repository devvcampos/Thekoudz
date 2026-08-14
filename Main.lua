-- Thekoudz/Main.lua
-- =============================================
-- ENTRY POINT (CARREGAMENTO DIRETO)
-- =============================================
local BASE_URL = "https://raw.githubusercontent.com/devvcampos/Thekoudz/main/"

---------------------------------------------------------
-- Carregar Dependências (Biblioteca e Managers)
---------------------------------------------------------
local Library = loadstring(game:HttpGet(BASE_URL .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(BASE_URL .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(BASE_URL .. "addons/SaveManager.lua"))()

---------------------------------------------------------
-- Carregar Módulos (Config, ESP e UI)
---------------------------------------------------------
local Config = loadstring(game:HttpGet(BASE_URL .. "Config.lua"))()
local ESP_Module = loadstring(game:HttpGet(BASE_URL .. "Modules/ESP.lua"))()
local UI = loadstring(game:HttpGet(BASE_URL .. "Ui.lua"))() -- OBS: Use exatamente "Ui.lua" (U maiúsculo, i minúsculo)

---------------------------------------------------------
-- Inicializar o ESP
---------------------------------------------------------
local ESP_Instance = ESP_Module.Init(Config)

---------------------------------------------------------
-- Contexto para a UI
---------------------------------------------------------
local Context = {
    Library = Library,
    Config = Config,
    ToggleESP = ESP_Instance.Toggle
}

---------------------------------------------------------
-- Criar a Interface
---------------------------------------------------------
local Window, Tabs = UI.Create(Context)

---------------------------------------------------------
-- Configurar Gerenciadores
---------------------------------------------------------
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
ThemeManager:ApplyToTab(Tabs.UI)
SaveManager:BuildConfigSection(Tabs.UI)
SaveManager:LoadAutoloadConfig()

print(">> Origin-RBLX carregado com sucesso!")
