local UI = {}

function UI:Create(context)
    local Library = context.Library
    local ESP = context.ESP
    local Config = context.Config

    local Window = Library:CreateWindow({
        Title = "Origin- RBLX",
        Footer = "Dev Koudx",
        Icon = 95816097006870,
        NotifySide = "Right",
        ShowCustomCursor = true,
    })

    local Tabs = {
        Main = Window:AddTab("Principal", "user"),
        UI = Window:AddTab("Configurações UI", "settings"),
    }

    local ESPGroup = Tabs.Main:AddLeftGroupbox("ESP", "eye")

    ESPGroup:AddToggle("ToggleESP_Pro", {
        Text = "Ativar ESP (Box, Nome, Vida)",
        Default = false,
        Callback = function(state)
            ESP:Toggle(state)
        end,
    })

    ESPGroup:AddDivider()

    ESPGroup:AddToggle("ToggleBox", {
        Text = "Mostrar Caixa (Box)",
        Default = true,
        Callback = function(value)
            Config.ESP.DrawBox = value
        end,
    })

    ESPGroup:AddLabel("Cor da Caixa"):AddColorPicker("BoxColor", {
        Default = Config.ESP.BoxColor,
        Title = "Cor da Caixa",

        Callback = function(value)
            Config.ESP.BoxColor = value
            ESP:SetBoxColor(value)
        end,
    })

    ESPGroup:AddToggle("ToggleName", {
        Text = "Mostrar Nome",
        Default = true,
        Callback = function(value)
            Config.ESP.DrawName = value
        end,
    })

    ESPGroup:AddToggle("ToggleHealth", {
        Text = "Mostrar Vida",
        Default = true,
        Callback = function(value)
            Config.ESP.DrawHealth = value
        end,
    })

    ESPGroup:AddToggle("ToggleDistance", {
        Text = "Mostrar Distância (M)",
        Default = true,
        Callback = function(value)
            Config.ESP.DrawDistance = value
        end,
    })

    ESPGroup:AddSlider("MaxDistance", {
        Text = "Alcance Máximo (M)",
        Default = 1000,
        Min = 0,
        Max = 100000,
        Rounding = 0,

        Callback = function(value)
            Config.MaxESP_Dist = value
        end,
    })

    return Window, Tabs
end

return UI
