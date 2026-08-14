local Config = {
    MaxESP_Dist = 150,

    ESP = {
        Enabled = false,

        DrawBox = true,
        DrawName = true,
        DrawHealth = true,
        DrawDistance = true,

        -- Cor normal, inclusive atrás de paredes
        BoxColor = Color3.new(1, 1, 1),

        -- Raycast de visibilidade
        VisibilityCheck = true,

        -- Cor quando o alvo estiver visível
        VisibleBoxColor = Color3.fromRGB(0, 255, 0)
    }
}

return Config
