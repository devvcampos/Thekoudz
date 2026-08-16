local Config = {
    MaxESP_Dist = 150,

    -- =============================================
    -- ESP
    -- =============================================

    ESP = {
        Enabled = false,

        DrawBox = true,
        DrawName = true,
        DrawHealth = true,
        DrawDistance = true,

        BoxColor = Color3.fromRGB(
            255,
            255,
            255
        ),

        VisibilityCheck = true,

        VisibleBoxColor = Color3.fromRGB(
            0,
            255,
            0
        ),

        VisibilityInterval = 0.10,
        VisibilityJitter = 0.025,
    },

    -- =============================================
    -- DEAD BODY CHAMS
    -- =============================================

    DeadBodyChams = {
        Enabled = false,

        Range = 500,

        Color = Color3.fromRGB(
            255,
            70,
            70
        ),

        FillTransparency = 0.35,
        OutlineTransparency = 0,

        ShowLabel = true,
    },

    -- =============================================
    -- AIMBOT
    -- =============================================

    Aimbot = {
        Enabled = false,

        FOV = 50,

        Smoothness = 12,

        AutoFire = false,

        FireDelay = 0.15,
    },
}

return Config