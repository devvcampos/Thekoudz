-- UI.lua

local UI = {}

function UI:Create(Context)

    local Library = Context.Library
    local Config = Context.Config
    local ESP = Context.ESP

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

    ---------------------------------------------------------
    -- ESP
    ---------------------------------------------------------

    local ESPGroup = Tabs.Main:AddLeftGroupbox("ESP", "eye")

    ESPGroup:AddToggle("ToggleESP", {
        Text = "Ativar ESP",
        Default = false,

        Callback = function(Value)
            ESP.Toggle(Value)
        end,
    })

    ESPGroup:AddDivider()

    ESPGroup:AddToggle("DrawBox", {
        Text = "Mostrar Caixa",
        Default = Config.ESP.DrawBox,

        Callback = function(Value)
            Config.ESP.DrawBox = Value
        end,
    })

    ESPGroup:AddToggle("DrawName", {
        Text = "Mostrar Nome",
        Default = Config.ESP.DrawName,

        Callback = function(Value)
            Config.ESP.DrawName = Value
        end,
    })

    ESPGroup:AddToggle("DrawHealth", {
        Text = "Mostrar Vida",
        Default = Config.ESP.DrawHealth,

        Callback = function(Value)
            Config.ESP.DrawHealth = Value
        end,
    })

    ESPGroup:AddToggle("DrawDistance", {
        Text = "Mostrar Distância",
        Default = Config.ESP.DrawDistance,

        Callback = function(Value)
            Config.ESP.DrawDistance = Value
        end,
    })

    ESPGroup:AddLabel("Cor da Caixa")
        :AddColorPicker("ESP_BoxColor", {

            Default = Config.ESP.BoxColor,

            Callback = function(Color)
                Config.ESP.BoxColor = Color
            end,
        })

    ESPGroup:AddSlider("ESPDistance", {

        Text = "Alcance Máximo",

        Default = Config.MaxESP_Dist,
        Min = 0,
        Max = 100000,
        Rounding = 0,

        Callback = function(Value)
            Config.MaxESP_Dist = Value
        end,
    })

    return Window, Tabs

end

return UI
