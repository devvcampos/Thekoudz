-- Thekoudz/Modules/ESP.lua
-- =============================================
-- MÓDULO ESP
-- =============================================

local ESP = {}

function ESP.Init(Config)
    -- Função de ofuscação
    local function decode(t)
        local s = ""
        for _, c in ipairs(t) do
            s = s .. string.char(c)
        end
        return s
    end

    -- Strings ofuscadas
    local drawingStr = decode({68,114,97,119,105,110,103})
    local squareStr = decode({83,113,117,97,114,101})
    local textStr = decode({84,101,120,116})
    local runServiceStr = decode({82,117,110,83,101,114,118,105,99,101})
    local guiNameStr = decode({
        83,121,115,116,101,109,95,77,101,116,114,105,99,115,95,85,73
    })

    _G.MaxESP_Dist = 150

    -- Config compartilhada com a UI
    local ESPConfig = Config.ESP

    -- Verificação do Drawing
    local UseDrawing = pcall(function()
        local test = Drawing.new(textStr)
        test.Visible = false
        test:Remove()
    end)

    local UseSquare = pcall(function()
        local test = Drawing.new(squareStr)
        test.Visible = false
        test:Remove()
    end)

    local ESP_Drawings = {}

    -- =============================================
    -- LIMPEZA DE UM PLAYER
    -- =============================================

    local function RemoveESP(plr)
        local data = ESP_Drawings[plr]

        if not data then
            return
        end

        if UseDrawing and UseSquare then
            if data.Box then
                data.Box:Remove()
            end

            if data.HealthText then
                data.HealthText:Remove()
            end

            if data.NameText then
                data.NameText:Remove()
            end

            if data.DistText then
                data.DistText:Remove()
            end
        else
            if data.Container then
                data.Container:Destroy()
            end
        end

        ESP_Drawings[plr] = nil
    end

    -- =============================================
    -- PLAYER SAIU DO SERVIDOR
    -- =============================================

    local Players = game:GetService("Players")

    Players.PlayerRemoving:Connect(function(plr)
        RemoveESP(plr)
    end)

    -- =============================================
    -- UPDATE ESP
    -- =============================================

    local function UpdateESP()
        if not ESPConfig.Enabled then
            for _, data in pairs(ESP_Drawings) do
                if UseDrawing and UseSquare then
                    if data.Box then
                        data.Box.Visible = false
                    end

                    if data.HealthText then
                        data.HealthText.Visible = false
                    end

                    if data.NameText then
                        data.NameText.Visible = false
                    end

                    if data.DistText then
                        data.DistText.Visible = false
                    end
                else
                    if data.Container then
                        data.Container.Enabled = false
                    end
                end
            end

            return
        end

        local LocalPlr = Players.LocalPlayer
        local LocalRoot = LocalPlr.Character
            and LocalPlr.Character:FindFirstChild("HumanoidRootPart")

        local Camera = workspace.CurrentCamera

        if not Camera then
            return
        end

        for _, plr in pairs(Players:GetPlayers()) do

            -- Ignora o próprio jogador
            if plr == LocalPlr then
                continue
            end

            -- =============================================
            -- PLAYER SEM CHARACTER
            -- =============================================

            if not plr.Character then
                RemoveESP(plr)
                continue
            end

            local Root = plr.Character:FindFirstChild("HumanoidRootPart")
            local Head = plr.Character:FindFirstChild("Head")
            local Humanoid = plr.Character:FindFirstChildOfClass("Humanoid")

            -- Se alguma peça necessária desaparecer,
            -- limpa o ESP antigo.
            if not Root or not Head or not Humanoid then
                RemoveESP(plr)
                continue
            end

            -- =============================================
            -- DISTÂNCIA
            -- =============================================

            local Distance =
                LocalRoot
                and math.floor((Root.Position - LocalRoot.Position).Magnitude)
                or 0

            if Distance > _G.MaxESP_Dist then
                if ESP_Drawings[plr] then
                    if UseDrawing and UseSquare then
                        if ESP_Drawings[plr].Box then
                            ESP_Drawings[plr].Box.Visible = false
                        end

                        if ESP_Drawings[plr].HealthText then
                            ESP_Drawings[plr].HealthText.Visible = false
                        end

                        if ESP_Drawings[plr].NameText then
                            ESP_Drawings[plr].NameText.Visible = false
                        end

                        if ESP_Drawings[plr].DistText then
                            ESP_Drawings[plr].DistText.Visible = false
                        end
                    else
                        if ESP_Drawings[plr].Container then
                            ESP_Drawings[plr].Container.Enabled = false
                        end
                    end
                end

                continue
            end

            -- =============================================
            -- CÁLCULO DA BOX
            -- =============================================

            local TopPos, TopVis =
                Camera:WorldToViewportPoint(
                    Head.Position + Vector3.new(0, 0.5, 0)
                )

            local BotPos, BotVis =
                Camera:WorldToViewportPoint(
                    Root.Position - Vector3.new(0, 3, 0)
                )

            local CenterPos, CenterVis =
                Camera:WorldToViewportPoint(Root.Position)

            -- Fora da renderização da câmera:
            -- apenas esconde, NÃO destrói.
            if not TopVis or not BotVis or not CenterVis then
                if ESP_Drawings[plr] then
                    if UseDrawing and UseSquare then
                        if ESP_Drawings[plr].Box then
                            ESP_Drawings[plr].Box.Visible = false
                        end

                        if ESP_Drawings[plr].HealthText then
                            ESP_Drawings[plr].HealthText.Visible = false
                        end

                        if ESP_Drawings[plr].NameText then
                            ESP_Drawings[plr].NameText.Visible = false
                        end

                        if ESP_Drawings[plr].DistText then
                            ESP_Drawings[plr].DistText.Visible = false
                        end
                    else
                        if ESP_Drawings[plr].Container then
                            ESP_Drawings[plr].Container.Enabled = false
                        end
                    end
                end

                continue
            end

            local Height = math.abs(BotPos.Y - TopPos.Y)
            local Width = Height * 0.6
            local X = CenterPos.X - (Width / 2)
            local Y = TopPos.Y

            -- =============================================
            -- CRIA OS DESENHOS
            -- =============================================

            if not ESP_Drawings[plr] then

                if UseDrawing and UseSquare then

                    local data = {
                        Box = Drawing.new(squareStr),
                        HealthText = Drawing.new(textStr),
                        NameText = Drawing.new(textStr),
                        DistText = Drawing.new(textStr)
                    }

                    -- BOX
                    data.Box.Thickness = 1
                    data.Box.Filled = false
                    data.Box.Color = ESPConfig.BoxColor
                    data.Box.Visible = false

                    -- HEALTH
                    data.HealthText.Size = 13
                    data.HealthText.Center = false
                    data.HealthText.Outline = true
                    data.HealthText.Color = Color3.new(1, 1, 1)
                    data.HealthText.Visible = false

                    -- NAME
                    data.NameText.Size = 14
                    data.NameText.Center = true
                    data.NameText.Outline = true
                    data.NameText.Color = Color3.new(1, 1, 1)
                    data.NameText.Visible = false

                    -- DISTANCE
                    data.DistText.Size = 12
                    data.DistText.Center = true
                    data.DistText.Outline = true
                    data.DistText.Color = Color3.new(1, 1, 1)
                    data.DistText.Visible = false

                    ESP_Drawings[plr] = data

                else

                    -- =============================================
                    -- FALLBACK GUI
                    -- =============================================

                    local gui = Instance.new("ScreenGui")
                    gui.Name = guiNameStr
                    gui.Parent = LocalPlr:WaitForChild("PlayerGui")
                    gui.Enabled = true

                    local boxFrame = Instance.new("Frame")
                    boxFrame.Size = UDim2.new(0, 0, 0, 0)
                    boxFrame.BackgroundTransparency = 1
                    boxFrame.BorderSizePixel = 1
                    boxFrame.BorderColor3 = ESPConfig.BoxColor
                    boxFrame.Parent = gui

                    local nameLabel = Instance.new("TextLabel")
                    nameLabel.Size = UDim2.new(0, 150, 0, 20)
                    nameLabel.BackgroundTransparency = 1
                    nameLabel.TextColor3 = Color3.new(1, 1, 1)
                    nameLabel.TextStrokeTransparency = 0.5
                    nameLabel.Font = Enum.Font.GothamBold
                    nameLabel.TextScaled = true
                    nameLabel.Parent = gui

                    local distLabel = Instance.new("TextLabel")
                    distLabel.Size = UDim2.new(0, 150, 0, 20)
                    distLabel.BackgroundTransparency = 1
                    distLabel.TextColor3 = Color3.new(1, 1, 1)
                    distLabel.TextStrokeTransparency = 0.5
                    distLabel.Font = Enum.Font.Gotham
                    distLabel.TextScaled = true
                    distLabel.Parent = gui

                    local healthLabel = Instance.new("TextLabel")
                    healthLabel.Size = UDim2.new(0, 150, 0, 20)
                    healthLabel.BackgroundTransparency = 1
                    healthLabel.TextColor3 = Color3.new(1, 1, 1)
                    healthLabel.TextStrokeTransparency = 0.5
                    healthLabel.Font = Enum.Font.Gotham
                    healthLabel.TextScaled = true
                    healthLabel.TextXAlignment = Enum.TextXAlignment.Left
                    healthLabel.Parent = gui

                    ESP_Drawings[plr] = {
                        Box = boxFrame,
                        NameText = nameLabel,
                        DistText = distLabel,
                        HealthText = healthLabel,
                        Container = gui
                    }
                end
            end

            local data = ESP_Drawings[plr]

            -- =============================================
            -- ATUALIZA DESENHOS
            -- =============================================

            if UseDrawing and UseSquare then

data.NameText.Position = UDim2.new(0, CenterPos.X - 75, 0, Y - 40)
data.NameText.Visible = ESPConfig.DrawName
data.NameText.Text = plr.Name

data.DistText.Position = UDim2.new(0, CenterPos.X - 75, 0, Y - 20)
data.DistText.Visible = ESPConfig.DrawDistance
data.DistText.Text = Distance .. " M"

data.HealthText.Position = UDim2.new(0, CenterPos.X - 75, 0, Y + Height + 5)
data.HealthText.Visible = ESPConfig.DrawHealth
data.HealthText.Text = string.format("%d/%d", Humanoid.Health, Humanoid.MaxHealth)

            else

                data.Container.Enabled = true

                data.Box.Size =
                    UDim2.new(0, Width, 0, Height)

                data.Box.Position =
                    UDim2.new(0, X, 0, Y)

                data.Box.BorderColor3 =
                    ESPConfig.BoxColor

                data.Box.Visible =
                    ESPConfig.DrawBox

                data.HealthText.Position =
                    UDim2.new(0, X, 0, Y - 20)

                data.HealthText.Visible =
                    ESPConfig.DrawHealth

                data.HealthText.Text =
                    string.format(
                        "%d/%d",
                        Humanoid.Health,
                        Humanoid.MaxHealth
                    )

                data.NameText.Position =
                    UDim2.new(
                        0,
                        CenterPos.X - 75,
                        0,
                        Y - 40
                    )

                data.NameText.Visible =
                    ESPConfig.DrawName

                data.NameText.Text =
                    plr.Name

                data.DistText.Position =
                    UDim2.new(
                        0,
                        CenterPos.X - 75,
                        0,
                        Y + Height + 5
                    )

                data.DistText.Visible =
                    ESPConfig.DrawDistance

                data.DistText.Text =
                    Distance .. " M"
            end
        end
    end

    -- =============================================
    -- LÓGICA DE LIGAR/DESLIGAR
    -- =============================================

    local ESPThread = nil

    local function ToggleESP(State)
        ESPConfig.Enabled = State

        if State and not ESPThread then

            ESPThread = task.spawn(function()
                local RS = game:GetService(runServiceStr)

                while ESPConfig.Enabled do
                    UpdateESP()
                    RS.RenderStepped:Wait()
                end

                ESPThread = nil
            end)

        elseif not State and ESPThread then

            ESPConfig.Enabled = false

            -- Limpa todos os ESPs existentes
            for plr in pairs(ESP_Drawings) do
                RemoveESP(plr)
            end

            ESPThread = nil
        end
    end

    -- API pública
    return {
        Toggle = ToggleESP
    }
end

return ESP
