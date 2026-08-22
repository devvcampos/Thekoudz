-- Thekoudz/Modules/ESP.lua
-- =============================================
-- MÓDULO ESP
-- ESP antigo + cálculo novo da box
-- =============================================

local ESP = {}

function ESP.Init(Config)
    ---------------------------------------------------------
    -- OFUSCAÇÃO
    ---------------------------------------------------------
    local function decode(t)
        local s = ""
        for _, c in ipairs(t) do
            s = s .. string.char(c)
        end
        return s
    end

    local squareStr = decode({83,113,117,97,114,101}) -- Square
    local textStr = decode({84,101,120,116}) -- Text
    local runServiceStr = decode({82,117,110,83,101,114,118,105,99,101}) -- RunService
    local guiNameStr = decode({83,121,115,116,101,109,95,77,101,116,114,105,99,115,95,85,73}) -- System_Metrics_UI

    ---------------------------------------------------------
    -- CONFIG
    ---------------------------------------------------------
    local ESPConfig = Config.ESP
    _G.MaxESP_Dist = tonumber(Config.MaxESP_Dist) or _G.MaxESP_Dist or 150

    ---------------------------------------------------------
    -- SERVICES
    ---------------------------------------------------------
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local RunService = game:GetService(runServiceStr)

    ---------------------------------------------------------
    -- DRAWING CHECK
    ---------------------------------------------------------
    local UseDrawing = pcall(function()
        return Drawing.new(textStr)
    end)

    local UseSquare = pcall(function()
        return Drawing.new(squareStr)
    end)

    ---------------------------------------------------------
    -- STATE
    ---------------------------------------------------------
    local ESP_Drawings = {}
    local ESPThread = nil
    local PlayerRemovingConnection = nil

    ---------------------------------------------------------
    -- VISIBILITY CACHE
    ---------------------------------------------------------
    local VisibilityCache = {}
    local VisibilityParams = RaycastParams.new()
    VisibilityParams.FilterType = Enum.RaycastFilterType.Exclude
    VisibilityParams.IgnoreWater = true
    VisibilityParams.RespectCanCollide = true

    local function GetCachedVisibility(plr, localPlr, character, head, root)
        local interval = tonumber(ESPConfig.VisibilityInterval) or 0.10
        local now = tick()

        local cached = VisibilityCache[plr]
        if cached and (now - cached.Time) < interval then
            return cached.Value
        end

        local localChar = localPlr.Character
        if not localChar then
            return false
        end

        local localRoot = localChar:FindFirstChild("HumanoidRootPart")
        if not localRoot then
            return false
        end

        local ignore = {localChar}
        VisibilityParams.FilterDescendantsInstances = ignore

        local targetPosition = head and head.Position or root.Position
        local direction = targetPosition - localRoot.Position

        local result = Workspace:Raycast(
            localRoot.Position,
            direction,
            VisibilityParams
        )

        local visible = false

        if not result then
            visible = true
        elseif result.Instance and result.Instance:IsDescendantOf(character) then
            visible = true
        end

        VisibilityCache[plr] = {
            Time = now,
            Value = visible
        }

        return visible
    end

    ---------------------------------------------------------
    -- REMOVE
    ---------------------------------------------------------
    local function RemoveESP(plr)
        local data = ESP_Drawings[plr]
        if not data then
            return
        end

        if UseDrawing and UseSquare then
            if data.Box then data.Box:Remove() end
            if data.HealthText then data.HealthText:Remove() end
            if data.NameText then data.NameText:Remove() end
            if data.DistText then data.DistText:Remove() end
        else
            if data.Container then
                data.Container:Destroy()
            end
        end

        ESP_Drawings[plr] = nil
        VisibilityCache[plr] = nil
    end

    ---------------------------------------------------------
    -- HIDE
    ---------------------------------------------------------
    local function HideESP(plr)
        local data = ESP_Drawings[plr]
        if not data then
            return
        end

        if UseDrawing and UseSquare then
            if data.Box then data.Box.Visible = false end
            if data.HealthText then data.HealthText.Visible = false end
            if data.NameText then data.NameText.Visible = false end
            if data.DistText then data.DistText.Visible = false end
        else
            if data.Container then
                data.Container.Enabled = false
            end
        end
    end

    ---------------------------------------------------------
    -- NOVO CÁLCULO DA BOX
    -- usa bounding box real do Character
    ---------------------------------------------------------
    local function GetCharacterScreenBounds(Character, Camera)
        if not Character or not Camera then
            return nil
        end

        local BoundingCFrame, BoundingSize = Character:GetBoundingBox()
        local Half = BoundingSize / 2

        local Corners = {
            Vector3.new(-Half.X, -Half.Y, -Half.Z),
            Vector3.new(-Half.X, -Half.Y,  Half.Z),
            Vector3.new(-Half.X,  Half.Y, -Half.Z),
            Vector3.new(-Half.X,  Half.Y,  Half.Z),

            Vector3.new( Half.X, -Half.Y, -Half.Z),
            Vector3.new( Half.X, -Half.Y,  Half.Z),
            Vector3.new( Half.X,  Half.Y, -Half.Z),
            Vector3.new( Half.X,  Half.Y,  Half.Z),
        }

        local minX = math.huge
        local minY = math.huge
        local maxX = -math.huge
        local maxY = -math.huge
        local hasVisiblePoint = false

        for _, offset in ipairs(Corners) do
            local worldPos = BoundingCFrame:PointToWorldSpace(offset)
            local screenPos = Camera:WorldToViewportPoint(worldPos)

            if screenPos.Z > 0 then
                hasVisiblePoint = true
                minX = math.min(minX, screenPos.X)
                minY = math.min(minY, screenPos.Y)
                maxX = math.max(maxX, screenPos.X)
                maxY = math.max(maxY, screenPos.Y)
            end
        end

        if not hasVisiblePoint then
    warn("[ESP BOUNDS] nenhum ponto visivel")
    return nil
end

        local width = maxX - minX
        local height = maxY - minY

        if width <= 1 or height <= 1 then
    warn(
        "[ESP BOUNDS] box invalida",
        "width:",
        width,
        "height:",
        height
    )

    return nil
end

        return {
            X = minX,
            Y = minY,
            Width = width,
            Height = height,
            CenterX = (minX + maxX) / 2,
            CenterY = (minY + maxY) / 2,
        }
    end

    ---------------------------------------------------------
    -- UPDATE
    ---------------------------------------------------------
    local function UpdateESP()
        if not ESPConfig.Enabled then
            for plr in pairs(ESP_Drawings) do
                HideESP(plr)
            end
            return
        end

        local LocalPlr = Players.LocalPlayer
        local LocalRoot = LocalPlr.Character and LocalPlr.Character:FindFirstChild("HumanoidRootPart")
        local Camera = Workspace.CurrentCamera

        if not Camera then
            return
        end

        for _, plr in pairs(Players:GetPlayers()) do
            if plr == LocalPlr then
                continue
            end

            if not plr.Character then
                RemoveESP(plr)
                continue
            end

            local Character = plr.Character
            local Root = Character:FindFirstChild("HumanoidRootPart")
            local Head = Character:FindFirstChild("Head")
            local Humanoid = Character:FindFirstChildOfClass("Humanoid")

            if not Root or not Head or not Humanoid or Humanoid.Health <= 0 then
                HideESP(plr)
                continue
            end

            local Distance = LocalRoot and math.floor((Root.Position - LocalRoot.Position).Magnitude) or 0
            if Distance > (_G.MaxESP_Dist or 150) then
                HideESP(plr)
                continue
            end

            -------------------------------------------------
            -- VISIBILITY CHECK
            -------------------------------------------------
            local TargetVisible = false
            if ESPConfig.VisibilityCheck then
                TargetVisible = GetCachedVisibility(
                    plr,
                    LocalPlr,
                    Character,
                    Head,
                    Root
                )
            end

            -------------------------------------------------
            -- NOVA BOX
            -------------------------------------------------
            local Bounds = GetCharacterScreenBounds(Character, Camera)
            if not Bounds then
                HideESP(plr)
                continue
            end

            local X = Bounds.X
            local Y = Bounds.Y
            local Width = Bounds.Width
            local Height = Bounds.Height
            local CenterX = Bounds.CenterX

            -------------------------------------------------
            -- CREATE
            -------------------------------------------------
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
                    data.HealthText.Center = true
                    data.HealthText.Outline = true
                    data.HealthText.Color = Color3.new(1, 1, 1)
                    data.HealthText.Visible = false

                    -- NAME
                    data.NameText.Size = 14
                    data.NameText.Center = true
                    data.NameText.Outline = true
                    data.NameText.Color = Color3.new(1, 1, 1)
                    data.NameText.Visible = false

                    -- DIST
                    data.DistText.Size = 12
                    data.DistText.Center = true
                    data.DistText.Outline = true
                    data.DistText.Color = Color3.new(1, 1, 1)
                    data.DistText.Visible = false

                    ESP_Drawings[plr] = data
                else
                    -------------------------------------------------
                    -- FALLBACK GUI
                    -------------------------------------------------
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
                    healthLabel.TextXAlignment = Enum.TextXAlignment.Center
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

            -------------------------------------------------
            -- UPDATE DRAWINGS
            -------------------------------------------------
            if UseDrawing and UseSquare then
                -- BOX
                data.Box.Visible = ESPConfig.DrawBox
                data.Box.Position = Vector2.new(X, Y)
                data.Box.Size = Vector2.new(Width, Height)

                if ESPConfig.VisibilityCheck and TargetVisible then
                    data.Box.Color = ESPConfig.VisibleBoxColor
                else
                    data.Box.Color = ESPConfig.BoxColor
                end

                -- NOME
                data.NameText.Visible = ESPConfig.DrawName
                data.NameText.Position = Vector2.new(CenterX, Y - 40)
                data.NameText.Text = plr.Name

                -- DISTÂNCIA
                data.DistText.Visible = ESPConfig.DrawDistance
                data.DistText.Position = Vector2.new(CenterX, Y - 20)
                data.DistText.Text = Distance .. " M"

                -- VIDA
                data.HealthText.Visible = ESPConfig.DrawHealth
                data.HealthText.Position = Vector2.new(CenterX, Y + Height + 5)
                data.HealthText.Text = string.format(
                    "%d/%d",
                    Humanoid.Health,
                    Humanoid.MaxHealth
                )
            else
                data.Container.Enabled = true

                -- BOX
                data.Box.Size = UDim2.new(0, Width, 0, Height)
                data.Box.Position = UDim2.new(0, X, 0, Y)

                if ESPConfig.VisibilityCheck and TargetVisible then
                    data.Box.BorderColor3 = ESPConfig.VisibleBoxColor
                else
                    data.Box.BorderColor3 = ESPConfig.BoxColor
                end

                data.Box.Visible = ESPConfig.DrawBox

                -- NOME
                data.NameText.Position = UDim2.new(0, CenterX - 75, 0, Y - 40)
                data.NameText.Visible = ESPConfig.DrawName
                data.NameText.Text = plr.Name

                -- DISTÂNCIA
                data.DistText.Position = UDim2.new(0, CenterX - 75, 0, Y - 20)
                data.DistText.Visible = ESPConfig.DrawDistance
                data.DistText.Text = Distance .. " M"

                -- VIDA
                data.HealthText.Position = UDim2.new(0, CenterX - 75, 0, Y + Height + 5)
                data.HealthText.Visible = ESPConfig.DrawHealth
                data.HealthText.TextXAlignment = Enum.TextXAlignment.Center
                data.HealthText.Text = string.format(
                    "%d/%d",
                    Humanoid.Health,
                    Humanoid.MaxHealth
                )
            end
        end
    end

    ---------------------------------------------------------
    -- TOGGLE
    ---------------------------------------------------------
    local function ToggleESP(State)
        ESPConfig.Enabled = State == true

        if State and not ESPThread then
            ESPThread = task.spawn(function()
                while ESPConfig.Enabled do
                    UpdateESP()
                    RunService.RenderStepped:Wait()
                end
                ESPThread = nil
            end)
        elseif not State then
            ESPConfig.Enabled = false

            if ESPThread then
                ESPThread = nil
            end

            for _, data in pairs(ESP_Drawings) do
                if UseDrawing and UseSquare then
                    if data.Box then data.Box.Visible = false end
                    if data.HealthText then data.HealthText.Visible = false end
                    if data.NameText then data.NameText.Visible = false end
                    if data.DistText then data.DistText.Visible = false end
                else
                    if data.Container then
                        data.Container.Enabled = false
                    end
                end
            end
        end
    end

    ---------------------------------------------------------
    -- DESTROY
    ---------------------------------------------------------
    local function Destroy()
        ESPConfig.Enabled = false

        if PlayerRemovingConnection then
            PlayerRemovingConnection:Disconnect()
            PlayerRemovingConnection = nil
        end

        for plr in pairs(ESP_Drawings) do
            RemoveESP(plr)
        end

        ESP_Drawings = {}
        VisibilityCache = {}
        ESPThread = nil
    end

    ---------------------------------------------------------
    -- CONNECTIONS
    ---------------------------------------------------------
    PlayerRemovingConnection = Players.PlayerRemoving:Connect(function(plr)
        RemoveESP(plr)
    end)

    ---------------------------------------------------------
    -- API
    ---------------------------------------------------------
    return {
        Toggle = ToggleESP,
        Destroy = Destroy
    }
end

return ESP