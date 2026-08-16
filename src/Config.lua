local Config = {
    MaxESP_Dist = 150,

    ESP = {
        Enabled = false,

        DrawBox = true,
        DrawName = true,
        DrawHealth = true,
        DrawDistance = true,

        -- Cor normal da Box
        BoxColor = Color3.fromRGB(255, 255, 255),

        -- Visibility Check
        VisibilityCheck = true,

        -- Cor quando o alvo estiver visível
        VisibleBoxColor = Color3.fromRGB(0, 255, 0),

        -- Intervalo base do cache de raycast
        VisibilityInterval = 0.10,

        -- Variação aplicada ao intervalo
        -- Ex.: 0.10 ± 0.025
        VisibilityJitter = 0.025,
    },

    DeadBodyChams = {
        Enabled = false,

        Range = 500,

        Color = Color3.fromRGB(255, 70, 70),

        FillTransparency = 0.35,
        OutlineTransparency = 0,

        ShowLabel = true,
    }
}

    Aimbot = {
        Enabled = false,
        FOV = 50,              -- Ângulo máximo para ativar (graus)
        Smoothness = 12,       -- Quantos passos de mouse (quanto maior, mais lento/humano)
        AutoFire = false,      -- Atirar automaticamente quando mirar?
        FireDelay = 0.15       -- Delay mínimo entre tiros automáticos
    }
}

return Config
