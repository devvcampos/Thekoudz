-- Thekoudz/Loader.lua

local Loader = {}

function Loader:Load(baseUrl)
    local Library = loadstring(
        game:HttpGet(baseUrl .. "Library.lua")
    )()

    local ThemeManager = loadstring(
        game:HttpGet(baseUrl .. "addons/ThemeManager.lua")
    )()

    local SaveManager = loadstring(
        game:HttpGet(baseUrl .. "addons/SaveManager.lua")
    )()

    return {
        Library = Library,
        ThemeManager = ThemeManager,
        SaveManager = SaveManager,
    }
end

return Loader
