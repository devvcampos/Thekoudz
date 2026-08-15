local M = {}

function M.Init(C)
    local function d(t)
        local s = ""
        for i = 1, #t do
            s = s .. string.char(t[i])
        end
        return s
    end

    local a = game:GetService(d({
        80,108,97,121,101,114,115
    }))

    local b = game:GetService(d({
        82,117,110,83,101,114,118,105,99,101
    }))

    local p = a.LocalPlayer

    local f = workspace:WaitForChild(d({
        67,111,114,112,115,101,115
    }))

    local S = C.DeadBodyChams

    local A = {}
    local R = false
    local T = nil
    local X = nil

    local q = pcall(function()
        local x = Drawing.new(d({
            84,101,120,116
        }))

        x.Visible = false
        x:Remove()
    end)

    local function r(m)
        if not m then
            return nil
        end

        return m:FindFirstChild(d({
            72,117,109,97,110,111,105,100,
            82,111,111,116,80,97,114,116
        }))
        or m:FindFirstChild(d({
            85,112,112,101,114,84,111,114,115,111
        }))
        or m:FindFirstChild(d({
            84,111,114,115,111
        }))
        or m:FindFirstChild(d({
            72,101,97,100
        }))
        or m.PrimaryPart
    end

    local function h(m)
        if not m then
            return nil
        end

        return m:FindFirstChild(d({
            72,101,97,100
        }))
        or m:FindFirstChild(d({
            85,112,112,101,114,84,111,114,115,111
        }))
        or m:FindFirstChild(d({
            84,111,114,115,111
        }))
        or m:FindFirstChild(d({
            72,117,109,97,110,111,105,100,
            82,111,111,116,80,97,114,116
        }))
        or m.PrimaryPart
    end

    local function g(m)
        local c = p.Character

        local l =
            c and c:FindFirstChild(d({
                72,117,109,97,110,111,105,100,
                82,111,111,116,80,97,114,116
            }))

        local z = r(m)

        if not l or not z then
            return math.huge
        end

        return (z.Position - l.Position).Magnitude
    end

    local function x(m)
        local v = A[m]

        if not v then
            return
        end

        if v.H then
            pcall(function()
                v.H:Destroy()
            end)
        end

        if v.T then
            pcall(function()
                v.T:Remove()
            end)
        end

        A[m] = nil
    end

    local function n(m)
        if A[m] then
            return A[m]
        end

        if
            not m
            or not m:IsA(d({
                77,111,100,101,108
            }))
        then
            return nil
        end

        local z = r(m)

        if not z then
            return nil
        end

        local H = Instance.new(d({
            72,105,103,104,108,105,103,104,116
        }))

        H.Name = d({
            95,95,68,101,97,100,66,111,100,121,
            72,105,103,104,108,105,103,104,116
        })

        H.Adornee = m

        H.DepthMode =
            Enum.HighlightDepthMode.AlwaysOnTop

        H.FillColor =
            S.Color

        H.OutlineColor =
            S.Color

        H.FillTransparency =
            S.FillTransparency

        H.OutlineTransparency =
            S.OutlineTransparency

        H.Parent = m

        local L = nil

        if q then
            L = Drawing.new(d({
                84,101,120,116
            }))

            L.Size = 14
            L.Center = true
            L.Outline = true

            L.Color =
                Color3.new(1, 1, 1)

            L.Text = d({
                68,101,97,100,32,98,111,100,121
            })

            L.Visible = false
        end

        A[m] = {
            H = H,
            T = L,
            P = h(m)
        }

        return A[m]
    end

    local function u(m)
        if not m or not m.Parent then
            x(m)
            return
        end

        if g(m) > S.Range then
            x(m)
            return
        end

        local v =
            A[m] or n(m)

        if not v then
            return
        end

        v.H.FillColor =
            S.Color

        v.H.OutlineColor =
            S.Color

        v.H.FillTransparency =
            S.FillTransparency

        v.H.OutlineTransparency =
            S.OutlineTransparency

        if
            not v.P
            or not v.P.Parent
        then
            v.P = h(m)
        end
    end

    local function e()
        if not S.Enabled then
            return
        end

        local seen = {}

        for _, m in ipairs(
            f:GetChildren()
        ) do
            if m:IsA(d({
                77,111,100,101,108
            })) then
                seen[m] = true
                u(m)
            end
        end

        local list = {}

        for m in pairs(A) do
            if not seen[m] then
                list[#list + 1] = m
            end
        end

        for i = 1, #list do
            x(list[i])
        end
    end

    local function y()
        if not S.Enabled then
            return
        end

        local cam =
            workspace.CurrentCamera

        if not cam then
            return
        end

        for m, v in pairs(A) do
            local L = v.T

            if L then
                L.Visible = false

                if
                    S.ShowLabel
                    and m.Parent
                    and g(m) <= S.Range
                then
                    local z = v.P

                    if
                        not z
                        or not z.Parent
                    then
                        z = h(m)
                        v.P = z
                    end

                    if z then
                        local pos, on =
                            cam:WorldToViewportPoint(
                                z.Position
                                + Vector3.new(
                                    0,
                                    1.5,
                                    0
                                )
                            )

                        if
                            on
                            and pos.Z > 0
                        then
                            L.Position =
                                Vector2.new(
                                    pos.X,
                                    pos.Y
                                )

                            L.Text =
                                d({
                                    68,101,97,100,32,
                                    98,111,100,121
                                })

                            L.Size = 14
                            L.Center = true
                            L.Outline = true

                            L.Color =
                                Color3.new(
                                    1,
                                    1,
                                    1
                                )

                            L.Visible = true
                        end
                    end
                end
            end
        end
    end

    local function k()
        local list = {}

        for m in pairs(A) do
            list[#list + 1] = m
        end

        for i = 1, #list do
            x(list[i])
        end
    end

    local c1 =
        f.ChildAdded:Connect(
            function(m)
                if not S.Enabled then
                    return
                end

                task.defer(function()
                    if
                        m
                        and m.Parent == f
                    then
                        u(m)
                    end
                end)
            end
        )

    local c2 =
        f.ChildRemoved:Connect(
            function(m)
                x(m)
            end
        )

    local function Toggle(v)
        S.Enabled = v == true

        if S.Enabled then
            if R then
                return
            end

            R = true

            e()

            if not X then
                X =
                    b.RenderStepped:Connect(
                        y
                    )
            end

            T =
                task.spawn(function()
                    while
                        R
                        and S.Enabled
                    do
                        e()
                        task.wait(0.20)
                    end

                    T = nil
                end)
        else
            R = false

            if X then
                X:Disconnect()
                X = nil
            end

            k()
        end
    end

    local function Destroy()
        R = false
        S.Enabled = false

        if X then
            X:Disconnect()
            X = nil
        end

        if c1 then
            c1:Disconnect()
            c1 = nil
        end

        if c2 then
            c2:Disconnect()
            c2 = nil
        end

        k()

        T = nil
    end

    return {
        Toggle = Toggle,
        Destroy = Destroy
    }
end

return M
