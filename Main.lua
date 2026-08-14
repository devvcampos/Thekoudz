-- Thekoudz/main.lua
-- =============================================
-- ENTRY POINT
-- =============================================

local BASE_URL = "https://raw.githubusercontent.com/devvcampos/Thekoudz/main/"

---------------------------------------------------------
-- Loader
---------------------------------------------------------

local Loader = loadstring(
    game:HttpGet(BASE_URL .. "Loader.lua")
)()

---------------------------------------------------------
-- Config
---------------------------------------------------------

local Config = loadstring(
    game:HttpGet(BASE_URL .. "Config.lua")
)()

---------------------------------------------------------
-- ESP Module
---------------------------------------------------------

local ESPModule = loadstring(
    game:HttpGet(BASE_URL .. "Modules/ESP.lua")
)()

---------------------------------------------------------
-- UI
---------------------------------------------------------

local UI = loadstring(
    game:HttpGet(BASE_URL .. "Ui.lua")
)()

---------------------------------------------------------
-- Dependencies
---------------------------------------------------------

local Dependencies = Loader:Load(BASE_URL)

local Library = Dependencies.Library
local ThemeManager = Dependencies.ThemeManager
local SaveManager = Dependencies.SaveManager

---------------------------------------------------------
-- Initialize ESP
---------------------------------------------------------

local ESP = ESPModule.Init(Config)

---------------------------------------------------------
-- Context
---------------------------------------------------------

local Context = {
    Library = Library,

    ThemeManager = ThemeManager,
    SaveManager = SaveManager,

    Config = Config,

    ESP = ESP,
}

---------------------------------------------------------
-- Create UI
---------------------------------------------------------

local Window, Tabs = UI:Create(Context)

---------------------------------------------------------
-- Theme Manager
---------------------------------------------------------

ThemeManager:SetLibrary(Library)

---------------------------------------------------------
-- Save Manager
---------------------------------------------------------

SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()

---------------------------------------------------------
-- UI Settings
---------------------------------------------------------

ThemeManager:ApplyToTab(Tabs.UI)

SaveManager:BuildConfigSection(Tabs.UI)

SaveManager:LoadAutoloadConfig()
