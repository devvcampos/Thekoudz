local Aimbot = {}

function Aimbot.Init(
    Config,
    AimProvider
)
    ---------------------------------------------------------
    -- VALIDACAO
    ---------------------------------------------------------

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
        type(AimProvider.ResolveDirection)
            == "function",
        "AimProvider.ResolveDirection inexistente"
    )


    ---------------------------------------------------------
    -- SERVICES
    ---------------------------------------------------------

    local RunService =
        game:GetService(
            "RunService"
        )

    local Workspace =
        game:GetService(
            "Workspace"
        )


    ---------------------------------------------------------
    -- CONFIG
    ---------------------------------------------------------

    local Settings =
        Config.Aimbot


    ---------------------------------------------------------
    -- STATE
    ---------------------------------------------------------

    local Destroyed =
        false

    local CurrentPlayer =
        nil

    local CurrentPart =
        nil

    local CurrentDirection =
        nil

    local CurrentAngle =
        nil

    local Accumulator =
        0

    local Connection =
        nil


    ---------------------------------------------------------
    -- ANGLE
    ---------------------------------------------------------

    local function GetAngle(
        A,
        B
    )
        if
            A.Magnitude <= 0.000001
            or B.Magnitude <= 0.000001
        then
            return math.huge
        end


        local Dot =
            math.clamp(
                A.Unit:Dot(
                    B.Unit
                ),
                -1,
                1
            )


        return math.deg(
            math.acos(
                Dot
            )
        )
    end


    ---------------------------------------------------------
    -- CLEAR
    ---------------------------------------------------------

    local function ClearTarget()
        CurrentPlayer =
            nil

        CurrentPart =
            nil

        CurrentDirection =
            nil

        CurrentAngle =
            nil
    end


    ---------------------------------------------------------
    -- SCAN
    ---------------------------------------------------------

    local function Scan()
        if
            Destroyed
            or not Settings.Enabled
        then
            ClearTarget()

            return
        end


        local Camera =
            Workspace.CurrentCamera


        if not Camera then
            ClearTarget()

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


        if
            not Player
            or not Part
        then
            ClearTarget()

            return
        end


        if
            not Part.Parent
        then
            ClearTarget()

            return
        end


        CurrentPlayer =
            Player


        CurrentPart =
            Part


        CurrentDirection =
            Direction


        CurrentAngle =
            GetAngle(
                NormalDirection,
                Direction
            )
    end


    ---------------------------------------------------------
    -- UPDATE
    ---------------------------------------------------------

    local function Update(dt)
        if Destroyed then
            return
        end


        if not Settings.Enabled then
            return
        end


        Accumulator += dt


        local Interval =
            tonumber(
                Settings.ScanInterval
            )
            or 0.10


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


    ---------------------------------------------------------
    -- TOGGLE
    ---------------------------------------------------------

    local function Toggle(
        State
    )
        if Destroyed then
            return
        end


        Settings.Enabled =
            State == true


        Accumulator =
            0


        if Settings.Enabled then
            Scan()
        else
            ClearTarget()
        end
    end


    ---------------------------------------------------------
    -- GETTERS
    ---------------------------------------------------------

    local function GetTarget()
        return
            CurrentPlayer,
            CurrentPart
    end


    local function GetDirection()
        return
            CurrentDirection
    end


    local function GetAngleCurrent()
        return
            CurrentAngle
    end


    ---------------------------------------------------------
    -- DESTROY
    ---------------------------------------------------------

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


        ClearTarget()
    end


    ---------------------------------------------------------
    -- CONNECTION
    ---------------------------------------------------------

    Connection =
        RunService.Heartbeat:
            Connect(
                Update
            )


    ---------------------------------------------------------
    -- API
    ---------------------------------------------------------

    return {
        Toggle =
            Toggle,

        Destroy =
            Destroy,

        GetTarget =
            GetTarget,

        GetDirection =
            GetDirection,

        GetAngle =
            GetAngleCurrent,

        Scan =
            Scan,
    }
end

return Aimbot
