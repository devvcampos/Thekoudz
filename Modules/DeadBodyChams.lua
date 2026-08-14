local DeadBodyChams = {}

function DeadBodyChams.Init(Config)
    local Players = game:GetService("Players")

    local LocalPlayer = Players.LocalPlayer
    local Corpses = workspace:WaitForChild("Corpses")

    local Settings = Config.DeadBodyChams

    local Active = {}
    local Running = false
    local Thread = nil

    -- =============================================
    -- ROOT DO CORPO
    -- =============================================

    local function GetBodyRoot(Model)
        if not Model then
            return nil
        end

        return Model:FindFirstChild("HumanoidRootPart")
            or Model:FindFirstChild("UpperTorso")
            or Model:FindFirstChild("Torso")
            or Model:FindFirstChild("Head")
            or Model.PrimaryPart
    end

    -- =============================================
    -- DISTÂNCIA
    -- =============================================

    local function GetDistance(Model)
        local Character = LocalPlayer.Character

        local LocalRoot =
            Character
            and Character:FindFirstChild("HumanoidRootPart")

        local BodyRoot = GetBodyRoot(Model)

        if not LocalRoot or not BodyRoot then
            return math.huge
        end

        return (
            BodyRoot.Position
            - LocalRoot.Position
        ).Magnitude
    end

    -- =============================================
    -- REMOVER CHAMS
    -- =============================================

    local function RemoveBody(Model)
        local Data = Active[Model]

        if not Data then
            return
        end

        if Data.Highlight then
            Data.Highlight:Destroy()
        end

        if Data.Label then
            Data.Label:Destroy()
        end

        Active[Model] = nil
    end

    -- =============================================
    -- CRIAR CHAMS
    -- =============================================

    local function CreateBody(Model)
        if Active[Model] then
            return Active[Model]
        end

        if not Model:IsA("Model") then
            return nil
        end

        local Root = GetBodyRoot(Model)

        if not Root then
            return nil
        end

        -- =============================================
        -- HIGHLIGHT
        -- =============================================

        local Highlight = Instance.new("Highlight")

        Highlight.Name = "__DeadBodyHighlight"

        Highlight.Adornee = Model

        Highlight.DepthMode =
            Enum.HighlightDepthMode.AlwaysOnTop

        Highlight.FillColor =
            Settings.Color

        Highlight.OutlineColor =
            Settings.Color

        Highlight.FillTransparency =
            Settings.FillTransparency

        Highlight.OutlineTransparency =
            Settings.OutlineTransparency

        Highlight.Parent = Model

        -- =============================================
        -- DEAD BODY LABEL
        -- =============================================

        local Billboard =
            Instance.new("BillboardGui")

        Billboard.Name =
            "__DeadBodyLabel"

        Billboard.Adornee =
            Root

        Billboard.Size =
            UDim2.fromOffset(
                150,
                28
            )

        Billboard.StudsOffset =
            Vector3.new(
                0,
                3.5,
                0
            )

        Billboard.AlwaysOnTop =
            true

        Billboard.Enabled =
            Settings.ShowLabel

        Billboard.Parent =
            Model

        local Text =
            Instance.new("TextLabel")

        Text.Size =
            UDim2.fromScale(
                1,
                1
            )

        Text.BackgroundTransparency =
            1

        Text.Text =
            "Dead body"

        Text.TextColor3 =
            Settings.Color

        Text.TextStrokeTransparency =
            0.25

        Text.Font =
            Enum.Font.GothamBold

        Text.TextScaled =
            true

        Text.Parent =
            Billboard

        Active[Model] = {
            Highlight = Highlight,
            Label = Billboard,
            Text = Text
        }

        return Active[Model]
    end

    -- =============================================
    -- ATUALIZAR CORPO
    -- =============================================

    local function UpdateBody(Model)
        if not Model.Parent then
            RemoveBody(Model)
            return
        end

        local Distance =
            GetDistance(Model)

        -- FORA DO RANGE
        if Distance > Settings.Range then
            RemoveBody(Model)
            return
        end

        local Data =
            Active[Model]
            or CreateBody(Model)

        if not Data then
            return
        end

        -- Atualização dinâmica
        Data.Highlight.FillColor =
            Settings.Color

        Data.Highlight.OutlineColor =
            Settings.Color

        Data.Highlight.FillTransparency =
            Settings.FillTransparency

        Data.Highlight.OutlineTransparency =
            Settings.OutlineTransparency

        Data.Label.Enabled =
            Settings.ShowLabel

        if Data.Text then
            Data.Text.TextColor3 =
                Settings.Color

            Data.Text.Text =
                "Dead body"
        end
    end

    -- =============================================
    -- UPDATE
    -- =============================================

    local function Update()
        if not Settings.Enabled then
            return
        end

        local Seen = {}

        for _, Model in ipairs(
            Corpses:GetChildren()
        ) do

            if Model:IsA("Model") then
                Seen[Model] = true

                UpdateBody(Model)
            end
        end

        -- Limpa referências de corpos removidos
        local RemoveList = {}

        for Model in pairs(Active) do
            if not Seen[Model] then
                table.insert(
                    RemoveList,
                    Model
                )
            end
        end

        for _, Model in ipairs(
            RemoveList
        ) do
            RemoveBody(Model)
        end
    end

    -- =============================================
    -- CORPO ADICIONADO
    -- =============================================

    local CorpseAddedConnection =
        Corpses.ChildAdded:Connect(
            function(Model)

                if not Settings.Enabled then
                    return
                end

                -- Dá um pequeno tempo para
                -- as partes do cadáver replicarem.
                task.defer(function()

                    if
                        Model
                        and Model.Parent == Corpses
                    then
                        UpdateBody(Model)
                    end
                end)
            end
        )

    -- =============================================
    -- CORPO REMOVIDO
    -- =============================================

    local CorpseRemovedConnection =
        Corpses.ChildRemoved:Connect(
            function(Model)
                RemoveBody(Model)
            end
        )

    -- =============================================
    -- TOGGLE
    -- =============================================

    local function Toggle(State)
        Settings.Enabled =
            State == true

        if Settings.Enabled then

            if Thread then
                return
            end

            Running = true

            -- Processa corpos que já existem
            Update()

            Thread =
                task.spawn(function()

                    while
                        Running
                        and Settings.Enabled
                    do
                        Update()

                        -- Só precisamos atualizar
                        -- range/cor algumas vezes por segundo.
                        task.wait(0.20)
                    end

                    Thread = nil
                end)

        else

            Running = false

            local List = {}

            for Model in pairs(Active) do
                table.insert(
                    List,
                    Model
                )
            end

            for _, Model in ipairs(List) do
                RemoveBody(Model)
            end
        end
    end

    -- =============================================
    -- DESTROY
    -- =============================================

    local function Destroy()
        Running = false
        Settings.Enabled = false

        local List = {}

        for Model in pairs(Active) do
            table.insert(
                List,
                Model
            )
        end

        for _, Model in ipairs(List) do
            RemoveBody(Model)
        end

        if CorpseAddedConnection then
            CorpseAddedConnection:Disconnect()
            CorpseAddedConnection = nil
        end

        if CorpseRemovedConnection then
            CorpseRemovedConnection:Disconnect()
            CorpseRemovedConnection = nil
        end

        Thread = nil
    end

    return {
        Toggle = Toggle,
        Destroy = Destroy
    }
end

return DeadBodyChams
