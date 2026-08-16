local Aimbot = {}

function Aimbot.Init(Config)
    local cloneref = (cloneref or clonereference or function(i) return i end)
    local Players = cloneref(game:GetService("Players"))
    local RunService = cloneref(game:GetService("RunService"))
    local UserInputService = cloneref(game:GetService("UserInputService"))
    local Workspace = cloneref(game:GetService("Workspace"))
    local Camera = Workspace.CurrentCamera
    local LocalPlayer = Players.LocalPlayer

    local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
    -- Troque o nome "Fire" pelo que o jogo usar (Shoot, Remote, etc)
    local RemoteEvent = ReplicatedStorage:FindFirstChild("Fire") or ReplicatedStorage:FindFirstChild("Shoot") or ReplicatedStorage:FindFirstChild("Remote")
    
    local AimbotConfig = Config.Aimbot
    local AimThread = nil
    local LastFireTime = 0
    
    -- TRAVA DE SEGURANÇA: Evita chamar o movimento enquanto ele já está rodando
    local isAiming = false

    -- 1. Cálculo matemático do ângulo (FOV)
    local function angleToTarget(cameraPos, cameraDir, targetPos)
        local toTarget = (targetPos - cameraPos).Unit
        local dot = math.clamp(cameraDir:Dot(toTarget), -1, 1)
        return math.deg(math.acos(dot))
    end

    -- 2. Função para pegar o inimigo mais próximo dentro do FOV e Distância
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
                    local distance = (camPos - head.Position).Magnitude
                    
                    -- Verifica FOV e Distância Máxima
                    if angle < AimbotConfig.FOV and angle < closestAngle and distance < AimbotConfig.MaxDistance then
                        closest = player
                        closestAngle = angle
                    end
                end
            end
        end
        return closest
    end

    -- 3. Curva de Movimento Humanizada (Mousemoverel) + Trava de Conflito
    local function moveMouseHumanized(targetX, targetY)
        -- Evita conflitos
        if isAiming then return end
        isAiming = true

        local startX, startY = UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y
        
        -- Calcula a distância em pixels na tela
        local dx = targetX - startX
        local dy = targetY - startY
        local distance = math.sqrt(dx * dx + dy * dy)

        -- Se o mouse já está muito próximo (< 3px), não faz nada e libera
        if distance < 3 then
            isAiming = false
            return
        end
        
        -- Adiciona ruído humano no ponto final (erro de ~1.2px)
        local accuracyNoise = 1.2
        local finalX = targetX + (math.random() * 2 - 1) * accuracyNoise
        local finalY = targetY + (math.random() * 2 - 1) * accuracyNoise
        
        dx = finalX - startX
        dy = finalY - startY
        distance = math.sqrt(dx * dx + dy * dy)
        
        -- Define o número de passos baseado na distância e suavidade
        local steps = math.floor(AimbotConfig.Smoothness + distance * 0.05)
        steps = math.max(AimbotConfig.Smoothness, math.min(steps, 80))
        
        for i = 1, steps do
            local t = i / steps
            local progress = t * t * (3 - 2 * t) -- Função smoothstep (acelera/desacelera)
            
            local x = startX + dx * progress
            local y = startY + dy * progress
            
            -- Adiciona "tremedeira" no meio do caminho (jitter)
            local jitterStrength = math.sin(math.pi * t) * 0.6
            x = x + (math.random() * 2 - 1) * jitterStrength
            y = y + (math.random() * 2 - 1) * jitterStrength
            
            -- Executa o movimento do mouse via Madium
            local relX = x - startX
            local relY = y - startY
            if mousemoverel then
                mousemoverel(relX, relY)
            elseif mousemoveabs then -- fallback
                mousemoveabs(x, y)
            end
            
            startX, startY = x, y
            
            -- Delay variável (humanizado) entre cada passo
            task.wait(0.008 + math.random() * 0.006)
        end
        
        -- Libera a trava
        isAiming = false
    end

    -- 4. Lógica do Disparo via RemoteEvent (Com ruído 3D para o servidor)
    local function TryFireRemote(TargetPlayer)
        if not AimbotConfig.AutoFire then return end
        if not RemoteEvent then return end
        
        local currentTime = tick()
        if currentTime - LastFireTime < AimbotConfig.FireDelay + (math.random() * 0.05) then return end
        
        if TargetPlayer and TargetPlayer.Character then
            local head = TargetPlayer.Character:FindFirstChild("Head")
            if head then
                -- Ruído 3D para o servidor não ver um tiro perfeito (entre 0.2 e 0.8 studs de erro)
                local noiseVec = Vector3.new(
                    math.random() * 2 - 1,
                    math.random() * 2 - 1,
                    math.random() * 2 - 1
                ) * 0.5
                
                RemoteEvent:FireServer(head.Position + noiseVec)
                LastFireTime = currentTime
            end
        end
    end

    -- 5. Loop Principal do Aimbot (Mira -> Move -> Atira)
    local function RunAimbotLoop()
        while AimbotConfig.Enabled do
            local target = GetClosestPlayerInFOV()
            
            if target then
                local head = target.Character and target.Character:FindFirstChild("Head")
                if head then
                    -- Converte posição 3D para 2D (tela)
                    local screenPos, onScreen, depth = Camera:WorldToViewportPoint(head.Position)
                    
                    -- Só mira se estiver na frente da tela (depth > 0)
                    if onScreen and depth > 0 then
                        -- 1º PASSO: Realiza o movimento do mouse
                        moveMouseHumanized(screenPos.X, screenPos.Y)
                        
                        -- 2º PASSO: Só dispara DEPOIS que o movimento terminou (ponto crítico de segurança)
                        TryFireRemote(target)
                    end
                end
            end
            
            -- Pequena pausa para não sobrecarregar a CPU e simular o "tempo de reação"
            task.wait(0.03)
        end
    end

    -- 6. API pública de Ligar/Desligar
    local function ToggleAimbot(State)
        AimbotConfig.Enabled = State
        if State and not AimThread then
            AimThread = task.spawn(RunAimbotLoop)
        elseif not State and AimThread then
            isAiming = false -- Garante que a trava seja liberada se desligar no meio do movimento
            AimThread = nil
        end
    end

    -- Se quiser uma função Destroy para limpar a thread
    local function DestroyAimbot()
        ToggleAimbot(false)
    end

    return { Toggle = ToggleAimbot, Destroy = DestroyAimbot }
end

return Aimbot