local BASE_URL = "https://raw.githubusercontent.com/devvcampos/Thekoudz/main/"

local function LoadRemote(path)
    local cacheBuster = tostring(DateTime.now().UnixTimestampMillis)
    local url = BASE_URL .. path .. "?cb=" .. cacheBuster

    local source = game:HttpGet(url)

    local chunk, err = loadstring(source)

    assert(
        chunk,
        "Erro compilando " .. path .. ": " .. tostring(err)
    )

    local result = chunk()

    assert(
        result ~= nil,
        path .. " executou, mas retornou nil"
    )

    return result
end

---------------------------------------------------------
-- Carregar Dependências Principais
---------------------------------------------------------

local Library = LoadRemote("Library.lua")
local ThemeManager = LoadRemote("addons/ThemeManager.lua")
local SaveManager = LoadRemote("addons/SaveManager.lua")

---------------------------------------------------------
-- Carregar Módulos
---------------------------------------------------------

local Config = LoadRemote("Config.lua")
local ESPModule = LoadRemote("Modules/ESP.lua")
local DeadBodyModule =LoadRemote("Modules/DeadBodyChams.lua")
local UI = LoadRemote("Ui.lua")

print("Config carregado:", Config)
print("Config.ESP:", Config.ESP)

---------------------------------------------------------
-- Inicializar ESP
---------------------------------------------------------

local ESP = ESPModule.Init(Config)
local DeadBody = DeadBodyModule.Init(Config)

local ESP =
    ESPModule.Init(Config)

local DeadBody =
    DeadBodyModule.Init(Config)

local Context = {
    Library = Library,
    Config = Config,

    ToggleESP = ESP.Toggle,
    DestroyESP = ESP.Destroy,

    ToggleDeadBodyChams =
        DeadBody.Toggle,

    DestroyDeadBodyChams =
        DeadBody.Destroy,
}

local Window, Tabs = UI.Create(Context)

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
ThemeManager:ApplyToTab(Tabs.UI)
SaveManager:BuildConfigSection(Tabs.UI)
SaveManager:LoadAutoloadConfig()

print(">> Origin-RBLX carregado com sucesso!")
