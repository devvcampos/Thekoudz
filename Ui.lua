-- Thekoudz/Ui.lua
-- =============================================
-- MÓDULO UI (PAINEL E CONTROLES)
-- =============================================

local UI = {}

function UI.Create(Context)
    local Library = Context.Library
    local Config = Context.Config
    local ToggleESP = Context.ToggleESP

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

    -- =============================================
    -- PAINEL DE CONTROLES DO ESP
    -- =============================================
    local ESPGroup = Tabs.Main:AddLeftGroupbox("ESP", "eye")
    ESPGroup:AddToggle("ToggleESP_Pro", {
        Text = "Ativar ESP (Box, Nome, Vida)",
        Default = false,
        Callback = ToggleESP,
    })
    ESPGroup:AddDivider()
    ESPGroup:AddToggle("ToggleBox", {
        Text = "Mostrar Caixa (Box)",
        Default = true,
        Callback = function(v) Config.ESP.DrawBox = v end,
    })
    ESPGroup:AddLabel("Cor da Caixa"):AddColorPicker("BoxColor", {
        Default = Color3.new(1, 1, 1),
        Title = "Cor da Caixa",
        Callback = function(v) Config.ESP.BoxColor = v end,
    })
    ESPGroup:AddToggle("ToggleName", {
        Text = "Mostrar Nome",
        Default = true,
        Callback = function(v) Config.ESP.DrawName = v end,
    })
    ESPGroup:AddToggle("ToggleHealth", {
        Text = "Mostrar Vida",
        Default = true,
        Callback = function(v) Config.ESP.DrawHealth = v end,
    })
    ESPGroup:AddToggle("ToggleDistance", {
        Text = "Mostrar Distância (M)",
        Default = true,
        Callback = function(v) Config.ESP.DrawDistance = v end,
    })
    ESPGroup:AddSlider("MaxDistance", {
        Text = "Alcance Máximo (M)",
        Default = 1000,
        Min = 0,
        Max = 100000,
        Rounding = 0,
        Callback = function(v) _G.MaxESP_Dist = v end,
    })

    -- =============================================
    -- CONFIGURAÇÕES UI (GRAVADOR DE TECLA E UNLOAD)
    -- =============================================
    local MenuGroup = Tabs.UI:AddLeftGroupbox("Menu", "wrench")

    -- Opção de cursor customizado
    MenuGroup:AddToggle("ShowCustomCursor", {
        Text = "Cursor Customizado",
        Default = Library.ShowCustomCursor,
        Callback = function(v) Library.ShowCustomCursor = v end,
    })

    -- =============================================
    -- GRAVADOR DE TECLA (O que estava faltando)
    -- =============================================
    local menuToggleKey = "RightShift"
    local isRecording = false

    -- Label que mostra a tecla atual
    local keyLabel = MenuGroup:AddLabel("Tecla atual: " .. menuToggleKey)

    -- Botão para gravar nova tecla
    local recordBtn = MenuGroup:AddButton({
        Text = "Gravar Nova Tecla",
        Func = function()
            if isRecording then return end
            isRecording = true
            recordBtn:SetText("Aguardando tecla...")
            keyLabel:SetText("Tecla atual: Aguardando...")
        end,
    })

    -- Lógica de captura de tecla
    local UIS = game:GetService("UserInputService")
    local debounceToggle = false

    UIS.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        -- Se estiver no modo de gravação, captura a tecla pressionada
        if isRecording then
            local pressedKey = ""
            if input.KeyCode ~= Enum.KeyCode.Unknown then
                pressedKey = tostring(input.KeyCode):gsub("Enum.KeyCode.", "")
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                pressedKey = "MB1"
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                pressedKey = "MB2"
            elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
                pressedKey = "MB3"
            else
                return
            end

            menuToggleKey = pressedKey
            keyLabel:SetText("Tecla atual: " .. pressedKey)
            recordBtn:SetText("Gravar Nova Tecla")
            isRecording = false
            print("[DEBUG] Nova tecla de atalho gravada:", pressedKey)
            return
        end

        -- Se não estiver gravando, verifica se a tecla pressionada é a configurada
        local pressedKey = ""
        if input.KeyCode ~= Enum.KeyCode.Unknown then
            pressedKey = tostring(input.KeyCode):gsub("Enum.KeyCode.", "")
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
            pressedKey = "MB1"
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
            pressedKey = "MB2"
        elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
            pressedKey = "MB3"
        else
            return
        end

        if pressedKey == menuToggleKey and not debounceToggle then
            debounceToggle = true
            Window:Toggle()  -- Abre/fecha o painel
            task.wait(0.3)
            debounceToggle = false
        end
    end)

    -- =============================================
    -- BOTÃO DE UNLOAD (DESCARREGAR)
    -- =============================================
    MenuGroup:AddDivider()
    MenuGroup:AddButton({
        Text = "unload",
        DoubleClick = true,
        Func = function()
            ToggleESP(false)
            Library:Unload()
        end,
    })

    return Window, Tabs
end

return UI
