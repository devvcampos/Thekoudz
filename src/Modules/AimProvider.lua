local AimProvider = {}

function AimProvider.Init(Config)
    local Players =
        game:GetService("Players")

    local Workspace =
        game:GetService("Workspace")

    local LocalPlayer =
        Players.LocalPlayer

    local Settings =
        Config.Aimbot


    local RayParams =
        RaycastParams.new()

    RayParams.FilterType =
        Enum.RaycastFilterType.Exclude

    RayParams.IgnoreWater =
        true


    local IgnoreList = {}


    local function UpdateFilter()
        table.clear(IgnoreList)

        if LocalPlayer.Character then
            table.insert(
                IgnoreList,
                LocalPlayer.Character
            )
        end

        RayParams.FilterDescendantsInstances =
            IgnoreList
    end


    local function GetPart(Character)
        if not Character then
            return nil
        end

        if Settings.TargetPart == "Body" then
            return
                Character:FindFirstChild("UpperTorso")
                or Character:FindFirstChild("Torso")
                or Character:FindFirstChild("HumanoidRootPart")
        end

        return Character:FindFirstChild("Head")
    end


    local function IsAlive(Character)
        local Humanoid =
            Character
            and Character:FindFirstChildOfClass(
                "Humanoid"
            )

        return
            Humanoid ~= nil
            and Humanoid.Health > 0
    end


    local function GetAngle(A, B)
        if
            A.Magnitude <= 0.000001
            or B.Magnitude <= 0.000001
        then
            return math.huge
        end

        local Dot =
            math.clamp(
                A.Unit:Dot(B.Unit),
                -1,
                1
            )

        return math.deg(
            math.acos(Dot)
        )
    end


    local function Visible(
        Origin,
        Character,
        Part
    )
        if Settings.VisibilityCheck == false then
            return true
        end

        UpdateFilter()

        local Result =
            Workspace:Raycast(
                Origin,
                Part.Position - Origin,
                RayParams
            )

        if not Result then
            return true
        end

        return
            Result.Instance
            and Result.Instance:IsDescendantOf(
                Character
            )
    end


    local function FindTarget(
        Origin,
        Direction
    )
        local BestPlayer = nil
        local BestPart = nil

        local BestAngle =
            tonumber(Settings.FOV)
            or 50


        for _, Player in ipairs(
            Players:GetPlayers()
        ) do
            if Player == LocalPlayer then
                continue
            end


            local Character =
                Player.Character


            if
                not Character
                or not IsAlive(Character)
            then
                continue
            end


            local Part =
                GetPart(Character)

            if not Part then
                continue
            end


            local ToTarget =
                Part.Position - Origin


            local Angle =
                GetAngle(
                    Direction,
                    ToTarget
                )


            if Angle >= BestAngle then
                continue
            end


            if
                not Visible(
                    Origin,
                    Character,
                    Part
                )
            then
                continue
            end


            BestPlayer =
                Player

            BestPart =
                Part

            BestAngle =
                Angle
        end


        return
            BestPlayer,
            BestPart,
            BestAngle
    end


    local function ResolveDirection(
        Origin,
        NormalDirection
    )
        if not Settings.Enabled then
            return NormalDirection, nil, nil
        end


        local Player,
            Part =
            FindTarget(
                Origin,
                NormalDirection
            )


        if not Part then
            return NormalDirection, nil, nil
        end


        local Delta =
            Part.Position - Origin


        if Delta.Magnitude <= 0 then
            return NormalDirection, nil, nil
        end


        return
            Delta.Unit,
            Player,
            Part
    end


    return {
        ResolveDirection =
            ResolveDirection,

        FindTarget =
            FindTarget,
    }
end

return AimProvider