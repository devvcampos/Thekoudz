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
        VisibleBoxColor = Color3.fromRGB(0, 255, 0)
    }
}

return Config
