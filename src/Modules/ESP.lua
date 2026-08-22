-- Thekoudz/Modules/ESP.lua
-- =============================================
-- ESP NATIVO
-- ScreenGui + Frame + UIStroke
-- =============================================

local ESP = {}

function ESP.Init(Config)

    ---------------------------------------------------------
    -- SERVICES
    ---------------------------------------------------------

    local Players =
        game:GetService("Players")

    local RunService =
        game:GetService("RunService")

    local Workspace =
        game:GetService("Workspace")


    ---------------------------------------------------------
    -- CONFIG
    ---------------------------------------------------------

    local LocalPlayer =
        Players.LocalPlayer

    local ESPConfig =
        Config.ESP

    local MaxDistance =
        tonumber(ESPConfig.MaxDistance)
        or tonumber(_G.MaxESP_Dist)
        or 150


    ---------------------------------------------------------
    -- STATE
    ---------------------------------------------------------

    local ESPObjects = {}

    local RenderConnection = nil
    local PlayerRemovingConnection = nil

    local Destroyed = false


    ---------------------------------------------------------
    -- SCREEN GUI
    ---------------------------------------------------------

    local PlayerGui =
        LocalPlayer:WaitForChild("PlayerGui")

    local OldGui =
        PlayerGui:FindFirstChild(
            "Thekoudz_ESP"
        )

    if OldGui then
        OldGui:Destroy()
    end


    local ScreenGui =
        Instance.new("ScreenGui")

    ScreenGui.Name =
        "Thekoudz_ESP"

    ScreenGui.IgnoreGuiInset =
        true

    ScreenGui.ResetOnSpawn =
        false

    ScreenGui.DisplayOrder =
        999

    ScreenGui.ZIndexBehavior =
        Enum.ZIndexBehavior.Sibling

    ScreenGui.Parent =
        PlayerGui


    ---------------------------------------------------------
    -- BODY PART CHECK
    ---------------------------------------------------------

    local function IsBodyPart(Part)
        if not Part:IsA("BasePart") then
            return false
        end


        -- Não deixa acessórios aumentarem a box
        local Accessory =
            Part:FindFirstAncestorWhichIsA(
                "Accessory"
            )

        if Accessory then
            return false
        end


        -- Não deixa armas/tools aumentarem a box
        local Tool =
            Part:FindFirstAncestorWhichIsA(
                "Tool"
            )

        if Tool then
            return false
        end


        return true
    end


    ---------------------------------------------------------
    -- PROJETA UMA PEÇA 3D
    ---------------------------------------------------------

    local function ProjectPart(
        Part,
        Camera,
        Bounds
    )
        local Half =
            Part.Size * 0.5


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


        for _, Offset in ipairs(Corners) do

            local WorldPosition =
                Part.CFrame:
                    PointToWorldSpace(
                        Offset
                    )


            local ScreenPosition =
                Camera:
                    WorldToViewportPoint(
                        WorldPosition
                    )


            -- Só considera pontos na frente da câmera
            if ScreenPosition.Z > 0 then

                Bounds.HasPoint =
                    true


                Bounds.MinX =
                    math.min(
                        Bounds.MinX,
                        ScreenPosition.X
                    )


                Bounds.MinY =
                    math.min(
                        Bounds.MinY,
                        ScreenPosition.Y
                    )


                Bounds.MaxX =
                    math.max(
                        Bounds.MaxX,
                        ScreenPosition.X
                    )


                Bounds.MaxY =
                    math.max(
                        Bounds.MaxY,
                        ScreenPosition.Y
                    )
            end
        end
    end


    ---------------------------------------------------------
    -- CALCULA BOX REAL DO PERSONAGEM
    ---------------------------------------------------------

    local function GetCharacterBounds(
        Character,
        Camera
    )
        local Bounds = {
            MinX = math.huge,
            MinY = math.huge,

            MaxX = -math.huge,
            MaxY = -math.huge,

            HasPoint = false,
        }


        for _, Object in ipairs(
            Character:GetDescendants()
        ) do

            if IsBodyPart(Object) then
                ProjectPart(
                    Object,
                    Camera,
                    Bounds
                )
            end
        end


        if not Bounds.HasPoint then
            return nil
        end


        local Viewport =
            Camera.ViewportSize


        -- Personagem completamente fora da tela
        if
            Bounds.MaxX < 0
            or Bounds.MinX > Viewport.X
            or Bounds.MaxY < 0
            or Bounds.MinY > Viewport.Y
        then
            return nil
        end


        -- Pequena margem para a box não colar na pele
        local Padding =
            tonumber(ESPConfig.BoxPadding)
            or 2


        local MinX =
            Bounds.MinX - Padding

        local MinY =
            Bounds.MinY - Padding

        local MaxX =
            Bounds.MaxX + Padding

        local MaxY =
            Bounds.MaxY + Padding


        -- Limita à viewport
        MinX =
            math.clamp(
                MinX,
                0,
                Viewport.X
            )

        MinY =
            math.clamp(
                MinY,
                0,
                Viewport.Y
            )

        MaxX =
            math.clamp(
                MaxX,
                0,
                Viewport.X
            )

        MaxY =
            math.clamp(
                MaxY,
                0,
                Viewport.Y
            )


        local Width =
            MaxX - MinX

        local Height =
            MaxY - MinY


        if
            Width <= 1
            or Height <= 1
        then
            return nil
        end


        return {
            X = MinX,
            Y = MinY,

            Width = Width,
            Height = Height,

            CenterX =
                MinX + Width / 2,

            CenterY =
                MinY + Height / 2,
        }
    end


    ---------------------------------------------------------
    -- TEXTO
    ---------------------------------------------------------

    local function CreateTextLabel(
        Parent,
        Font,
        Size
    )
        local Label =
            Instance.new("TextLabel")


        Label.BackgroundTransparency =
            1

        Label.BorderSizePixel =
            0

        Label.TextColor3 =
            Color3.new(1, 1, 1)

        Label.TextStrokeColor3 =
            Color3.new(0, 0, 0)

        Label.TextStrokeTransparency =
            0.35

        Label.Font =
            Font

        Label.TextSize =
            Size

        Label.TextWrapped =
            false

        Label.ZIndex =
            12

        Label.Parent =
            Parent


        return Label
    end


    ---------------------------------------------------------
    -- CRIA ESP PARA PLAYER
    ---------------------------------------------------------

    local function CreateESP(Player)

        if ESPObjects[Player] then
            return ESPObjects[Player]
        end


        -----------------------------------------------------
        -- CONTAINER
        -----------------------------------------------------

        local Container =
            Instance.new("Frame")


        Container.Name =
            "ESP_"
            .. tostring(Player.UserId)

        Container.BackgroundTransparency =
            1

        Container.BorderSizePixel =
            0

        Container.Visible =
            false

        Container.ClipsDescendants =
            false

        Container.ZIndex =
            10

        Container.Parent =
            ScreenGui


        -----------------------------------------------------
        -- BOX
        -----------------------------------------------------

        local Box =
            Instance.new("Frame")


        Box.Name =
            "Box"

        Box.Size =
            UDim2.fromScale(1, 1)

        Box.Position =
            UDim2.fromOffset(0, 0)

        Box.BackgroundTransparency =
            1

        Box.BorderSizePixel =
            0

        Box.ZIndex =
            10

        Box.Parent =
            Container


        local Stroke =
            Instance.new("UIStroke")


        Stroke.Name =
            "BoxStroke"

        Stroke.ApplyStrokeMode =
            Enum.ApplyStrokeMode.Border

        Stroke.LineJoinMode =
            Enum.LineJoinMode.Miter

        Stroke.Thickness =
            tonumber(
                ESPConfig.BoxThickness
            )
            or 1


        Stroke.Color =
            ESPConfig.BoxColor
            or Color3.new(1, 1, 1)

        Stroke.Transparency =
            0

        Stroke.Parent =
            Box


        -----------------------------------------------------
        -- NAME
        -----------------------------------------------------

        local NameText =
            CreateTextLabel(
                Container,
                Enum.Font.GothamBold,
                14
            )


        NameText.Name =
            "Name"

        NameText.AnchorPoint =
            Vector2.new(0.5, 1)

        NameText.Size =
            UDim2.fromOffset(
                200,
                20
            )

        NameText.Position =
            UDim2.new(
                0.5,
                0,
                0,
                -4
            )

        NameText.TextXAlignment =
            Enum.TextXAlignment.Center


        -----------------------------------------------------
        -- DISTANCE
        -----------------------------------------------------

        local DistanceText =
            CreateTextLabel(
                Container,
                Enum.Font.Gotham,
                12
            )


        DistanceText.Name =
            "Distance"

        DistanceText.AnchorPoint =
            Vector2.new(0.5, 0)

        DistanceText.Size =
            UDim2.fromOffset(
                200,
                18
            )

        DistanceText.Position =
            UDim2.new(
                0.5,
                0,
                1,
                4
            )

        DistanceText.TextXAlignment =
            Enum.TextXAlignment.Center


        -----------------------------------------------------
        -- HEALTH
        -----------------------------------------------------

        local HealthText =
            CreateTextLabel(
                Container,
                Enum.Font.Gotham,
                12
            )


        HealthText.Name =
            "Health"

        HealthText.AnchorPoint =
            Vector2.new(1, 0)

        HealthText.Size =
            UDim2.fromOffset(
                75,
                18
            )

        HealthText.Position =
            UDim2.new(
                0,
                -5,
                0,
                0
            )

        HealthText.TextXAlignment =
            Enum.TextXAlignment.Right


        -----------------------------------------------------
        -- SAVE
        -----------------------------------------------------

        local Data = {
            Container = Container,

            Box = Box,
            Stroke = Stroke,

            NameText = NameText,
            DistanceText = DistanceText,
            HealthText = HealthText,
        }


        ESPObjects[Player] =
            Data


        return Data
    end


    ---------------------------------------------------------
    -- REMOVE
    ---------------------------------------------------------

    local function RemoveESP(Player)

        local Data =
            ESPObjects[Player]


        if not Data then
            return
        end


        if Data.Container then
            Data.Container:
                Destroy()
        end


        ESPObjects[Player] =
            nil
    end


    ---------------------------------------------------------
    -- HIDE
    ---------------------------------------------------------

    local function HideESP(Player)

        local Data =
            ESPObjects[Player]


        if
            Data
            and Data.Container
        then
            Data.Container.Visible =
                false
        end
    end


    ---------------------------------------------------------
    -- UPDATE DE UM PLAYER
    ---------------------------------------------------------

    local function UpdatePlayer(
        Player,
        Camera,
        LocalRoot
    )
        if Player == LocalPlayer then
            return
        end


        local Character =
            Player.Character


        if not Character then
            HideESP(Player)
            return
        end


        local Root =
            Character:
                FindFirstChild(
                    "HumanoidRootPart"
                )


        local Humanoid =
            Character:
                FindFirstChildOfClass(
                    "Humanoid"
                )


        if
            not Root
            or not Humanoid
            or Humanoid.Health <= 0
        then
            HideESP(Player)
            return
        end


        -----------------------------------------------------
        -- DISTANCE
        -----------------------------------------------------

        local Distance = 0


        if LocalRoot then
            Distance =
                math.floor(
                    (
                        Root.Position
                        - LocalRoot.Position
                    ).Magnitude
                )
        end


        if Distance > MaxDistance then
            HideESP(Player)
            return
        end


        -----------------------------------------------------
        -- SCREEN BOUNDS
        -----------------------------------------------------

        local Bounds =
            GetCharacterBounds(
                Character,
                Camera
            )


        if not Bounds then
            HideESP(Player)
            return
        end


        -----------------------------------------------------
        -- GET / CREATE UI
        -----------------------------------------------------

        local Data =
            CreateESP(Player)


        -----------------------------------------------------
        -- POSITION + SIZE
        -----------------------------------------------------

        Data.Container.Position =
            UDim2.fromOffset(
                math.floor(Bounds.X),
                math.floor(Bounds.Y)
            )


        Data.Container.Size =
            UDim2.fromOffset(
                math.ceil(Bounds.Width),
                math.ceil(Bounds.Height)
            )


        Data.Container.Visible =
            true


        -----------------------------------------------------
        -- BOX
        -----------------------------------------------------

        Data.Box.Visible =
            ESPConfig.DrawBox ~= false


        Data.Stroke.Color =
            ESPConfig.BoxColor
            or Color3.new(1, 1, 1)


        Data.Stroke.Thickness =
            tonumber(
                ESPConfig.BoxThickness
            )
            or 1


        -----------------------------------------------------
        -- NAME
        -----------------------------------------------------

        Data.NameText.Visible =
            ESPConfig.DrawName ~= false


        Data.NameText.Text =
            Player.Name


        -----------------------------------------------------
        -- DISTANCE
        -----------------------------------------------------

        Data.DistanceText.Visible =
            ESPConfig.DrawDistance ~= false


        Data.DistanceText.Text =
            tostring(Distance)
            .. " M"


        -----------------------------------------------------
        -- HEALTH
        -----------------------------------------------------

        Data.HealthText.Visible =
            ESPConfig.DrawHealth ~= false


        Data.HealthText.Text =
            string.format(
                "%d/%d",
                math.floor(Humanoid.Health),
                math.floor(Humanoid.MaxHealth)
            )
    end


    ---------------------------------------------------------
    -- UPDATE GERAL
    ---------------------------------------------------------

    local function UpdateESP()

        if
            Destroyed
            or not ESPConfig.Enabled
        then
            return
        end


        local Camera =
            Workspace.CurrentCamera


        if not Camera then
            return
        end


        local LocalCharacter =
            LocalPlayer.Character


        local LocalRoot =
            LocalCharacter
            and LocalCharacter:
                FindFirstChild(
                    "HumanoidRootPart"
                )


        for _, Player in ipairs(
            Players:GetPlayers()
        ) do

            UpdatePlayer(
                Player,
                Camera,
                LocalRoot
            )
        end
    end


    ---------------------------------------------------------
    -- HIDE ALL
    ---------------------------------------------------------

    local function HideAll()

        for _, Data in pairs(
            ESPObjects
        ) do

            if Data.Container then
                Data.Container.Visible =
                    false
            end
        end
    end


    ---------------------------------------------------------
    -- TOGGLE
    ---------------------------------------------------------

    local function ToggleESP(State)

        if Destroyed then
            return
        end


        ESPConfig.Enabled =
            State == true


        if ESPConfig.Enabled then

            ScreenGui.Enabled =
                true


            if not RenderConnection then

                RenderConnection =
                    RunService.RenderStepped:
                        Connect(
                            UpdateESP
                        )
            end


            UpdateESP()

        else

            if RenderConnection then

                RenderConnection:
                    Disconnect()

                RenderConnection =
                    nil
            end


            HideAll()


            ScreenGui.Enabled =
                false
        end
    end


    ---------------------------------------------------------
    -- PLAYER REMOVING
    ---------------------------------------------------------

    PlayerRemovingConnection =
        Players.PlayerRemoving:
            Connect(
                RemoveESP
            )


    ---------------------------------------------------------
    -- DESTROY
    ---------------------------------------------------------

    local function Destroy()

        if Destroyed then
            return
        end


        Destroyed =
            true

        ESPConfig.Enabled =
            false


        if RenderConnection then

            RenderConnection:
                Disconnect()

            RenderConnection =
                nil
        end


        if PlayerRemovingConnection then

            PlayerRemovingConnection:
                Disconnect()

            PlayerRemovingConnection =
                nil
        end


        for Player in pairs(
            ESPObjects
        ) do
            RemoveESP(Player)
        end


        if ScreenGui then
            ScreenGui:
                Destroy()
        end
    end


    ---------------------------------------------------------
    -- AUTO INIT
    ---------------------------------------------------------

    if ESPConfig.Enabled then
        ToggleESP(true)
    end


    ---------------------------------------------------------
    -- API
    ---------------------------------------------------------

    return {
        Toggle =
            ToggleESP,

        Destroy =
            Destroy,
    }
end


return ESP