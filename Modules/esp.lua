-- Thekoudz/Modules/ESP.lua
-- =============================================
-- MÓDULO ESP (NÍVEL ELITE + DESIGN ORIGINAL)
-- =============================================

local ESP = {}

function ESP.Init(Config)
    -- Cache de desenhos por jogador
    local ESP_Drawings = {}
    
    -- Verifica suporte do executor aos desenhos
    local UseDrawing = pcall(function() return Drawing.new(Config.textStr) end)
    local UseSquare = pcall(function() return Drawing.new(Config.squareStr) end)

    -- Função de renderização chamada a cada frame
    local function UpdateESP()
        local ESPConfig = Config.ESP
        if not ESPConfig.Enabled then
            for _, data in pairs(ESP_Drawings) do
                if UseDrawing then
                    if data.Box then data.Box.Visible = false end
                    if data.HealthText then data.HealthText.Visible = false end
                    if data.NameText then data.NameText.Visible = false end
                    if data.DistText then data.DistText.Visible = false end
                else
                    if data.Container then data.Container.Enabled = false end
                end
            end
            return
        end

        local LocalPlr = game.Players.LocalPlayer
        local LocalRoot = LocalPlr.Character and LocalPlr.Character:FindFirstChild("HumanoidRootPart")
        local Camera = workspace.CurrentCamera

        for _, plr in pairs(game.Players:GetPlayers()) do
            if plr == LocalPlr or not plr.Character then
                if ESP_Drawings[plr] then
                    if UseDrawing then
                        if ESP_Drawings[plr].Box then ESP_Drawings[plr].Box.Visible = false end
                        if ESP_Drawings[plr].HealthText then ESP_Drawings[plr].HealthText.Visible = false end
                        if ESP_Drawings[plr].NameText then ESP_Drawings[plr].NameText.Visible = false end
                        if ESP_Drawings[plr].DistText then ESP_Drawings[plr].DistText.Visible = false end
                    else
                        if ESP_Drawings[plr].Container then ESP_Drawings[plr].Container.Enabled = false end
                    end
                end
                continue
            end

            local Root = plr.Character:FindFirstChild("HumanoidRootPart")
            local Head = plr.Character:FindFirstChild("Head")
            local Humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
            if not Root or not Head or not Humanoid then continue end

            local Distance = LocalRoot and math.floor((Root.Position - LocalRoot.Position).Magnitude) or 0
            if Distance > _G.MaxESP_Dist then
                if ESP_Drawings[plr] then
                    if UseDrawing then
                        if ESP_Drawings[plr].Box then ESP_Drawings[plr].Box.Visible = false end
                        if ESP_Drawings[plr].HealthText then ESP_Drawings[plr].HealthText.Visible = false end
                        if ESP_Drawings[plr].NameText then ESP_Drawings[plr].NameText.Visible = false end
                        if ESP_Drawings[plr].DistText then ESP_Drawings[plr].DistText.Visible = false end
                    else
                        if ESP_Drawings[plr].Container then ESP_Drawings[plr].Container.Enabled = false end
                    end
                end
                continue
            end

            -- Cálculo da caixa (Box) na tela
            local TopPos, TopVis = Camera:WorldToViewportPoint(Head.Position + Vector3.new(0, 0.5, 0))
            local BotPos, BotVis = Camera:WorldToViewportPoint(Root.Position - Vector3.new(0, 3, 0))
            local CenterPos, CenterVis = Camera:WorldToViewportPoint(Root.Position)

            if not TopVis or not BotVis or not CenterVis then
                if ESP_Drawings[plr] then
                    if UseDrawing then
                        if ESP_Drawings[plr].Box then ESP_Drawings[plr].Box.Visible = false end
                        if ESP_Drawings[plr].HealthText then ESP_Drawings[plr].HealthText.Visible = false end
                        if ESP_Drawings[plr].NameText then ESP_Drawings[plr].NameText.Visible = false end
                        if ESP_Drawings[plr].DistText then ESP_Drawings[plr].DistText.Visible = false end
                    else
                        if ESP_Drawings[plr].Container then ESP_Drawings[plr].Container.Enabled = false end
                    end
                end
                continue
            end

            local Height = math.abs(BotPos.Y - TopPos.Y)
            local Width = Height * 0.6
            local X = CenterPos.X - (Width / 2)
            local Y = TopPos.Y

            -- Cria os desenhos se não existirem
            if not ESP_Drawings[plr] then
                if UseDrawing and UseSquare then
                    local data = {
                        Box = Drawing.new(Config.squareStr),
                        HealthText = Drawing.new(Config.textStr),
                        NameText = Drawing.new(Config.textStr),
                        DistText = Drawing.new(Config.textStr)
                    }
                    data.Box.Thickness = 1
                    data.Box.Filled = false
                    data.Box.Color = ESPConfig.BoxColor

                    data.HealthText.Size = 13
                    data.HealthText.Center = false
                    data.HealthText.Outline = true
                    data.HealthText.Color = Color3.new(1, 1, 1)

                    data.NameText.Size = 14
                    data.NameText.Center = true
                    data.NameText.Outline = true
                    data.NameText.Color = Color3.new(1, 1, 1)

                    data.DistText.Size = 12
                    data.DistText.Center = true
                    data.DistText.Outline = true
                    data.DistText.Color = Color3.new(1, 1, 1)

                    ESP_Drawings[plr] = data
                else
                    -- Fallback GUI (caso o executor não tenha Drawing)
                    local gui = Instance.new("ScreenGui")
                    gui.Name = Config.guiNameStr
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

            -- Atualiza posições e visibilidade
            if UseDrawing and UseSquare then
                data.Box.Visible = ESPConfig.DrawBox
                data.Box.Position = Vector2.new(X, Y)
                data.Box.Size = Vector2.new(Width, Height)
                data.Box.Color = ESPConfig.BoxColor

                data.HealthText.Visible = ESPConfig.DrawHealth
                data.HealthText.Position = Vector2.new(X, Y - 20)
                data.HealthText.Text = string.format("%d/%d", Humanoid.Health, Humanoid.MaxHealth)

                data.NameText.Visible = ESPConfig.DrawName
                data.NameText.Position = Vector2.new(CenterPos.X, Y - 40)
                data.NameText.Text = plr.Name

                data.DistText.Visible = ESPConfig.DrawDistance
                data.DistText.Position = Vector2.new(CenterPos.X, Y + Height + 5)
                data.DistText.Text = Distance .. " M"
            else
                -- Fallback GUI update
                data.Container.Enabled = true
                data.Box.Size = UDim2.new(0, Width, 0, Height)
                data.Box.Position = UDim2.new(0, X, 0, Y)
                data.Box.BorderColor3 = ESPConfig.BoxColor
                data.Box.Visible = ESPConfig.DrawBox

                data.HealthText.Position = UDim2.new(0, X, 0, Y - 20)
                data.HealthText.Visible = ESPConfig.DrawHealth
                data.HealthText.Text = string.format("%d/%d", Humanoid.Health, Humanoid.MaxHealth)

                data.NameText.Position = UDim2.new(0, CenterPos.X - 75, 0, Y - 40)
                data.NameText.Visible = ESPConfig.DrawName
                data.NameText.Text = plr.Name

                data.DistText.Position = UDim2.new(0, CenterPos.X - 75, 0, Y + Height + 5)
                data.DistText.Visible = ESPConfig.DrawDistance
                data.DistText.Text = Distance .. " M"
            end
        end
    end

    -- =============================================
    -- LÓGICA DE LIGAR/DESLIGAR (NÍVEL ELITE)
    -- =============================================
    local ESPThread = nil

    local function ToggleESP(State)
        local ESPConfig = Config.ESP
        ESPConfig.Enabled = State
        
        if State and not ESPThread then
            -- ELITE: thread invisível para getconnections()
            ESPThread = task.spawn(function()
                local RS = game:GetService(Config.runServiceStr)
                while ESPConfig.Enabled do
                    UpdateESP()
                    RS.RenderStepped:Wait()
                end
                ESPThread = nil
            end)
        elseif not State and ESPThread then
            ESPConfig.Enabled = false
            for _, data in pairs(ESP_Drawings) do
                if UseDrawing then
                    if data.Box then data.Box:Remove() end
                    if data.HealthText then data.HealthText:Remove() end
                    if data.NameText then data.NameText:Remove() end
                    if data.DistText then data.DistText:Remove() end
                else
                    if data.Container then data.Container:Destroy() end
                end
            end
            ESP_Drawings = {}
            ESPThread = nil
        end
    end

    -- Retorna a tabela com o método Toggle (API pública do módulo)
    return {
        Toggle = ToggleESP
    }
end

return ESP
