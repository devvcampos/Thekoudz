-- Thekoudz/main.lua (Versão Simplificada e Robusta)
-- =============================================
-- ENTRY POINT
-- =============================================

local BASE_URL = "https://raw.githubusercontent.com/devvcampos/Thekoudz/main/"

---------------------------------------------------------
-- Carregar Dependências Principais
---------------------------------------------------------
local Library = loadstring(game:HttpGet(BASE_URL .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(BASE_URL .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(BASE_URL .. "addons/SaveManager.lua"))()

---------------------------------------------------------
-- Carregar Módulos do Projeto
---------------------------------------------------------
local Config = loadstring(game:HttpGet(BASE_URL .. "Config.lua"))()
local ESPModule = loadstring(game:HttpGet(BASE_URL .. "Modules/ESP.lua"))()
local UI = loadstring(game:HttpGet(BASE_URL .. "Ui.lua"))()

---------------------------------------------------------
-- Inicializar o ESP
---------------------------------------------------------
local ESP = ESPModule.Init(Config)

---------------------------------------------------------
-- Criar o Contexto para a UI
---------------------------------------------------------
local Context = {
    Library = Library,
    Config = Config,
    ToggleESP = ESP.Toggle -- Passa apenas a função de ligar/desligar
}

---------------------------------------------------------
-- Criar Interface
---------------------------------------------------------
local Window, Tabs = UI.Create(Context)

---------------------------------------------------------
-- Configuração dos Managers (Tema e Salvar)
---------------------------------------------------------
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
ThemeManager:ApplyToTab(Tabs.UI)
SaveManager:BuildConfigSection(Tabs.UI)
SaveManager:LoadAutoloadConfig()

print(">> Origin-RBLX carregado com sucesso!")
