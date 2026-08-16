local Aimbot = {}

function Aimbot.Init(Config)
    -- Carrega serviços com cloneref para segurança
    local cloneref = (cloneref or clonereference or function(i) return i end)
    local Players = cloneref(game:GetService("Players"))
    local RunService = cloneref(game:GetService("RunService"))
    local UserInputService = cloneref(game:GetService("UserInputService"))
    local Workspace = cloneref(game:GetService("Workspace"))
    local Camera = Workspace.CurrentCamera
    local LocalPlayer = Players.LocalPlayer

    -- Tenta achar o RemoteEvent (ajuste o nome conforme o jogo, ex: "Fire", "Shoot", "Remote")
    -- Se o jogo usar um nome específico, altere "Fire" aqui.
    local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
    local RemoteEvent = ReplicatedStorage:FindFirstChild("Fire") or ReplicatedStorage:FindFirstChild("Shoot") or ReplicatedStorage:FindFirstChild("Remote")
    
    -- Variáveis de estado
    local AimbotConfig = Config.Aimbot
    local AimThread = nil
    local LastFireTime = 0

    -- 1. Cálculo matemático do ângulo
    local function angleToTarget(cameraPos, cameraDir, targetPos)
        local toTarget = (targetPos - cameraPos).Unit
        local dot = math.clamp(cameraDir:Dot(toTarget), -1, 1)
        return math.deg(math.acos(dot))
    end

    -- 2. Função para pegar o inimigo mais próximo dentro do FOV
    local function GetClosestPlayerInFOV()
        local closest = nil
        local closestAngle = math.huge
        
        local camPos = Camera.CFrame.Position
        local camDir = Camera.CFrame.LookVector
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local head = player.Character:FindFirstChild("Head")
                if head then
                    local angle = angleToTarget(camPos, camDir, head.Position)
                    if angle < AimbotConfig.FOV and angle < closestAngle then
                        closest = player
                        closestAngle = angle
                    end
                end
            end
        end
        return closest
    end

    -- 3. A Curva de Aceleração (Smoothstep) + Jitter + MouseMoveRel
    local function moveMouseHumanized(targetX, targetY)
        -- Obtém a posição atual do mouse
        local startX, startY = UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y
        
        -- Adiciona ruído (erro humano) no alvo final
        local accuracyNoise = 1.2
        local finalX = targetX + (math.random() * 2 - 1) * accuracyNoise
        local finalY = targetY + (math.random() * 2 - 1) * accuracyNoise
        
        -- Calcula a distância
        local dx = finalX - startX
        local dy = finalY - startY
        local distance = math.sqrt(dx * dx + dy * dy)
        
        -- Define o número de passos baseado na distância e na suavidade configurada
        local steps = math.floor(AimbotConfig.Smoothness + distance * 0.05)
        steps = math.max(AimbotConfig.Smoothness, math.min(steps, 80))
        
        for i = 1, steps do
            local t = i / steps
            local progress = t * t * (3 - 2 * t) -- Smoothstep
            
            local x = startX + dx * progress
            local y = startY + dy * progress
            
            -- Adiciona "tremedeira" no meio do caminho (Simula pulso humano)
            local jitterStrength = math.sin(math.pi * t) * 0.6
            x = x + (math.random() * 2 - 1) * jitterStrength
            y = y + (math.random() * 2 - 1) * jitterStrength
            
            -- Executa o movimento RELATIVO no executor
            local relX = x - startX
            local relY = y - startY
            
            -- Se for Madium, geralmente é mousemoverel ou mousemoveabs
            if mousemoverel then
                mousemoverel(relX, relY)
            elseif mousemoveabs then
                mousemoveabs(x, y)
            end
            
            startX, startY = x, y
            
            -- Delay variável (humano) entre cada micro-movimento
            task.wait(0.008 + math.random() * 0.006)
        end
    end

    -- 4. Lógica do Disparo via RemoteEvent (Fire)
    local function TryFireRemote(TargetPlayer)
        if not AimbotConfig.AutoFire then return end
        if not RemoteEvent then return end
        
        local currentTime = tick()
        if currentTime - LastFireTime < AimbotConfig.FireDelay + (math.random() * 0.05) then return end
        
        -- !!! SEGURANÇA EXTREMA !!!
        -- O servidor valida a posição do tiro. Envie UMA POSIÇÃO IMPERFEITA (erro de 0.2 a 0.8 studs).
        if TargetPlayer and TargetPlayer.Character then
            local head = TargetPlayer.Character:FindFirstChild("Head")
            if head then
                -- Adiciona um ruído 3D na posição enviada ao servidor
                local noiseVec = Vector3.new(
                    math.random() * 2 - 1,
                    math.random() * 2 - 1,
                    math.random() * 2 - 1
                ) * 0.6 -- Margem de erro pra não parecer perfeito
                
                -- Chama o RemoteEvent com o alvo alterado
                RemoteEvent:FireServer(head.Position + noiseVec)
                
                LastFireTime = currentTime
            end
        end
    end

    -- 5. Loop Principal do Aimbot
    local function RunAimbotLoop()
        while AimbotConfig.Enabled do
            local target = GetClosestPlayerInFOV()
            
            if target then
                local head = target.Character and target.Character:FindFirstChild("Head")
                if head then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                    
                    if onScreen then
                        -- Move o mouse com curva humanizada para a tela
                        moveMouseHumanized(screenPos.X, screenPos.Y)
                        
                        -- Tenta atirar via RemoteEvent
                        TryFireRemote(target)
                    end
                end
            end
            
            task.wait(0.016) -- Roda a cada frame aproximadamente (60 FPS)
        end
    end

    -- 6. API pública de Ligar/Desligar
    local function ToggleAimbot(State)
        AimbotConfig.Enabled = State
        if State and not AimThread then
            AimThread = task.spawn(RunAimbotLoop)
        elseif not State and AimThread then
            AimThread = nil
        end
    end

    return { Toggle = ToggleAimbot }
end

return Aimbot