local Aimbot = {}

function Aimbot.Init(
    Config,
    AimProvider
)
    assert(
        type(Config) == "table",
        "Config invalido"
    )

    assert(
        type(Config.Aimbot) == "table",
        "Config.Aimbot inexistente"
    )

    assert(
        type(AimProvider) == "table",
        "AimProvider nao recebido"
    )

    assert(
        type(AimProvider.ResolveDirection) == "function",
        "ResolveDirection inexistente"
    )


    local RunService =
        game:GetService("RunService")

    local Workspace =
        game:GetService("Workspace")


    local Settings =
        Config.Aimbot


    local Destroyed =
        false

    local Connection =
        nil

    local Accumulator =
        0


    local CurrentPlayer =
        nil

    local CurrentPart =
        nil

    local CurrentDirection =
        nil


    local function Clear()
        CurrentPlayer =
            nil

        CurrentPart =
            nil

        CurrentDirection =
            nil
    end


    local function Scan()
        if
            Destroyed
            or not Settings.Enabled
        then
            Clear()
            return
        end


        local Camera =
            Workspace.CurrentCamera

        if not Camera then
            Clear()
            return
        end


        local Origin =
            Camera.CFrame.Position

        local NormalDirection =
            Camera.CFrame.LookVector


        local Direction,
            Player,
            Part =
            AimProvider.ResolveDirection(
                Origin,
                NormalDirection
            )


        CurrentDirection =
            Direction

        CurrentPlayer =
            Player

        CurrentPart =
            Part


        if Player and Part then
            print(
                "[AIM TARGET]",
                Player.Name,
                Part.Name,
                "distance:",
                math.floor(
                    (
                        Part.Position
                        - Origin
                    ).Magnitude
                )
            )
        else
            print(
                "[AIM TARGET] nenhum"
            )
        end
    end


    local function Update(dt)
        if
            Destroyed
            or not Settings.Enabled
        then
            return
        end


        Accumulator += dt


        local Interval =
            tonumber(
                Settings.ScanInterval
            )
            or 0.25


        if
            Accumulator
            < Interval
        then
            return
        end


        Accumulator =
            0

        Scan()
    end


    local function Toggle(
        State
    )
        if Destroyed then
            return
        end


        Settings.Enabled =
            State == true


        if Settings.Enabled then
            print(
                "[AIM] ENABLED"
            )

            Scan()
        else
            print(
                "[AIM] DISABLED"
            )

            Clear()
        end
    end


    local function GetTarget()
        return
            CurrentPlayer,
            CurrentPart
    end


    local function GetDirection()
        return
            CurrentDirection
    end


    local function Destroy()
        if Destroyed then
            return
        end


        Destroyed =
            true

        Settings.Enabled =
            false


        if Connection then
            Connection:
                Disconnect()

            Connection =
                nil
        end


        Clear()
    end


    Connection =
        RunService.Heartbeat:
            Connect(
                Update
            )


    return {
        Toggle =
            Toggle,

        Destroy =
            Destroy,

        Scan =
            Scan,

        GetTarget =
            GetTarget,

        GetDirection =
            GetDirection,
    }
end


return Aimbot