local BASE_URL = "https://raw.githubusercontent.com/devvcampos/Thekoudz/main/"

local Loader = loadstring(
    game:HttpGet(BASE_URL .. "Loader.lua")
)()

local Dependencies = Loader:Load(BASE_URL)

local Library = Dependencies.Library
local ThemeManager = Dependencies.ThemeManager
local SaveManager = Dependencies.SaveManager
