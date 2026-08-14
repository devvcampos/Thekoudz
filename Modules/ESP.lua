local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ESP = {}

function ESP.Init(Config)
    local ESPConfig = Config.ESP
    local ESPObjects = {}

    local function RemoveESP(player)
        local data = ESPObjects[player]
        if not data then
            return
        end

        if data.Box then
            data.Box:Destroy()
        end

        if data.NameText then
            data.NameText:Destroy()
        end

        if data.HealthText then
            data.HealthText:Destroy()
        end

        if data.DistText then
            data.DistText:Destroy()
        end

        if data.Container then
            data.Container:Destroy()
        end

        ESPObjects[player] = nil
    end

    -- Remove imediatamente quando o Player deixa o servidor.
    Players.PlayerRemoving:Connect(function(player)
        RemoveESP(player)
    end)

    local function UpdateESP()
        if not ESPConfig.Enabled then
            for _, data in pairs(ESPObjects) do
                if data.Container then
                    data.Container.Enabled = false
                end
            end
            return
        end

        local localPlayer = Players.LocalPlayer
        local localCharacter = localPlayer.Character
        local localRoot = localCharacter
            and localCharacter:FindFirstChild("HumanoidRootPart")

        local camera = workspace.CurrentCamera
        if not camera then
            return
        end

        for _, player in ipairs(Players:GetPlayers()) do
            if player == localPlayer then
                continue
            end

            local character = player.Character

            -- Character desapareceu: destruir o ESP antigo.
            if not character then
                RemoveESP(player)
                continue
            end

            local root = character:FindFirstChild("HumanoidRootPart")
            local head = character:FindFirstChild("Head")
            local humanoid = character:FindFirstChildOfClass("Humanoid")

            if not root or not head or not humanoid then
                RemoveESP(player)
                continue
            end

            if humanoid.Health <= 0 then
                RemoveESP(player)
                continue
            end

            local distance = localRoot
                and math.floor((root.Position - localRoot.Position).Magnitude)
                or 0

            if distance > (ESPConfig.MaxDistance or 150) then
                if ESPObjects[player] and ESPObjects[player].Container then
                    ESPObjects[player].Container.Enabled = false
                end
                continue
            end

            local topPos, topVisible =
                camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))

            local bottomPos, bottomVisible =
                camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))

            local centerPos, centerVisible =
                camera:WorldToViewportPoint(root.Position)

            if not topVisible or not bottomVisible or not centerVisible then
                if ESPObjects[player] and ESPObjects[player].Container then
                    ESPObjects[player].Container.Enabled = false
                end
                continue
            end

            local height = math.abs(bottomPos.Y - topPos.Y)
            local width = height * 0.6
            local x = centerPos.X - width / 2
            local y = topPos.Y

            if not ESPObjects[player] then
                local container = Instance.new("ScreenGui")
                container.Name = "ESP_" .. player.UserId
                container.ResetOnSpawn = false
                container.IgnoreGuiInset = true
                container.Parent = localPlayer:WaitForChild("PlayerGui")

                local box = Instance.new("Frame")
                box.BackgroundTransparency = 1
                box.BorderSizePixel = 1
                box.Parent = container

                local nameText = Instance.new("TextLabel")
                nameText.BackgroundTransparency = 1
                nameText.Size = UDim2.fromOffset(150, 20)
                nameText.TextColor3 = Color3.new(1, 1, 1)
                nameText.TextStrokeTransparency = 0.5
                nameText.Font = Enum.Font.GothamBold
                nameText.TextScaled = true
                nameText.Parent = container

                local healthText = Instance.new("TextLabel")
                healthText.BackgroundTransparency = 1
                healthText.Size = UDim2.fromOffset(150, 20)
                healthText.TextColor3 = Color3.new(1, 1, 1)
                healthText.TextStrokeTransparency = 0.5
                healthText.Font = Enum.Font.Gotham
                healthText.TextScaled = true
                healthText.Parent = container

                local distText = Instance.new("TextLabel")
                distText.BackgroundTransparency = 1
                distText.Size = UDim2.fromOffset(150, 20)
                distText.TextColor3 = Color3.new(1, 1, 1)
                distText.TextStrokeTransparency = 0.5
                distText.Font = Enum.Font.Gotham
                distText.TextScaled = true
                distText.Parent = container

                ESPObjects[player] = {
                    Container = container,
                    Box = box,
                    NameText = nameText,
                    HealthText = healthText,
                    DistText = distText,
                }
            end

            local data = ESPObjects[player]

            data.Container.Enabled = true

            data.Box.Position = UDim2.fromOffset(x, y)
            data.Box.Size = UDim2.fromOffset(width, height)
            data.Box.BorderColor3 = ESPConfig.BoxColor
            data.Box.Visible = ESPConfig.DrawBox

            data.NameText.Position =
                UDim2.fromOffset(centerPos.X - 75, y - 40)
            data.NameText.Text = player.Name
            data.NameText.Visible = ESPConfig.DrawName

            data.HealthText.Position =
                UDim2.fromOffset(x, y - 20)
            data.HealthText.Text =
                string.format("%d/%d", humanoid.Health, humanoid.MaxHealth)
            data.HealthText.Visible = ESPConfig.DrawHealth

            data.DistText.Position =
                UDim2.fromOffset(centerPos.X - 75, y + height + 5)
            data.DistText.Text = distance .. " M"
            data.DistText.Visible = ESPConfig.DrawDistance
        end
    end

    local running = false
    local connection

    local function ToggleESP(state)
        ESPConfig.Enabled = state

        if state and not running then
            running = true

            connection = RunService.RenderStepped:Connect(function()
                if ESPConfig.Enabled then
                    UpdateESP()
                end
            end)

        elseif not state and running then
            running = false

            if connection then
                connection:Disconnect()
                connection = nil
            end

            for player in pairs(ESPObjects) do
                RemoveESP(player)
            end
        end
    end

    return {
        Toggle = ToggleESP
    }
end

return ESP
