local DeadBodyChams = {}

function DeadBodyChams.Init(Config)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")

    local LocalPlayer = Players.LocalPlayer
    local Corpses = workspace:WaitForChild("Corpses")

    local Settings = Config.DeadBodyChams

   local Active = {}
   local Running = false
   local Thread = nil
   local RenderConnection = nil

   local UseDrawingText = pcall(function()
   local test = Drawing.new("Text")
   test.Visible = false
   test:Remove()
   end)

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

    local function GetBodyAnchor(Model)
       if not Model then
           return nil
       end

    return Model:FindFirstChild("Head")
        or Model:FindFirstChild("UpperTorso")
        or Model:FindFirstChild("Torso")
        or Model:FindFirstChild("HumanoidRootPart")
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
           pcall(function()
                Data.Highlight:Destroy()
            end)
        end

        if Data.Text then
            pcall(function()
               Data.Text:Remove()
             end)
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
-- DEAD BODY TEXT
-- MESMO ESTILO DO ESP PRINCIPAL
-- =============================================

local Text = nil

if UseDrawingText then
    Text = Drawing.new("Text")

    Text.Size = 14
    Text.Center = true
    Text.Outline = true

    -- Igual ao nome do ESP principal
    Text.Color = Color3.new(1, 1, 1)

    Text.Text = "Dead body"
    Text.Visible = false
end

Active[Model] = {
    Highlight = Highlight,
    Text = Text,
    Anchor = GetBodyAnchor(Model)
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

Data.Highlight.FillColor =
    Settings.Color

Data.Highlight.OutlineColor =
    Settings.Color

Data.Highlight.FillTransparency =
    Settings.FillTransparency

Data.Highlight.OutlineTransparency =
    Settings.OutlineTransparency

if
    not Data.Anchor
    or not Data.Anchor.Parent
then
    Data.Anchor =
        GetBodyAnchor(Model)
end

-- FECHA UpdateBody(Model)
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
-- RENDER DO TEXTO DEAD BODY
-- =============================================

local function RenderLabels()
    if not Settings.Enabled then
        return
    end

    local Camera = workspace.CurrentCamera

    if not Camera then
        return
    end

    for Model, Data in pairs(Active) do
        local Text = Data.Text

        if not Text then
            continue
        end

        -- Texto desligado pelo painel
        if not Settings.ShowLabel then
            Text.Visible = false
            continue
        end

        -- Corpo já foi removido
        if not Model.Parent then
            Text.Visible = false
            continue
        end

        -- Fora do alcance
        local Distance = GetDistance(Model)

        if Distance > Settings.Range then
            Text.Visible = false
            continue
        end

        -- Recupera anchor se necessário
        local Anchor = Data.Anchor

        if
            not Anchor
            or not Anchor.Parent
        then
            Anchor = GetBodyAnchor(Model)
            Data.Anchor = Anchor
        end

        if not Anchor then
            Text.Visible = false
            continue
        end

        -- Posição um pouco acima da cabeça
        local WorldPosition =
            Anchor.Position
            + Vector3.new(0, 1.5, 0)

        local ScreenPosition, OnScreen =
            Camera:WorldToViewportPoint(
                WorldPosition
            )

        if
            not OnScreen
            or ScreenPosition.Z <= 0
        then
            Text.Visible = false
            continue
        end

        -- =============================================
        -- MESMO VISUAL DO ESP
        -- =============================================

        Text.Position =
            Vector2.new(
                ScreenPosition.X,
                ScreenPosition.Y
            )

        Text.Text = "Dead body"

        Text.Size = 14
        Text.Center = true
        Text.Outline = true
        Text.Color = Color3.new(1, 1, 1)

        Text.Visible = true
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
    Settings.Enabled = State == true

    if Settings.Enabled then
        if Thread then
            return
        end

        Running = true

        -- Processa corpos que já existem
        Update()

        Thread = task.spawn(function()
            while Running and Settings.Enabled do
                Update()

                task.wait(0.20)
            end

            Thread = nil
        end)

        -- Texto acompanha a câmera
        if not RenderConnection then
            RenderConnection =
                RunService.RenderStepped:Connect(
                    RenderLabels
                )
        end

    else
        Running = false

        -- Para atualização do texto
        if RenderConnection then
            RenderConnection:Disconnect()
            RenderConnection = nil
        end

        -- Remove todos os chams/textos
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

    -- =============================================
    -- RENDER CONNECTION
    -- =============================================

    if RenderConnection then
        RenderConnection:Disconnect()
        RenderConnection = nil
    end

    -- =============================================
    -- LIMPAR CORPOS
    -- =============================================

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

    -- =============================================
    -- DESCONECTAR EVENTOS
    -- =============================================

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

-- =============================================
-- EXPORT
-- =============================================

return {
    Toggle = Toggle,
    Destroy = Destroy
}

end

return DeadBodyChams
