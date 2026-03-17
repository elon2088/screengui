local PlayerHandler = {}

function PlayerHandler.init(ctx)
    local LocalPlayer    = ctx.LocalPlayer
    local Players        = ctx.Players
    local RunService     = ctx.RunService
    local Box            = ctx.Box
    local GetBoundingBox = ctx.GetBoundingBox
    local FadeDuration   = ctx.FadeDuration or 2.5

    local FadeManager = loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/elon2088/screengui/refs/heads/main/fade.lua"
    ))()

    FadeManager.setConfig("FadeDuration", FadeDuration)

    local boxes       = {}
    local connections = {}
    local localRoot   = nil

    local function updateLocalRoot()
        local char = LocalPlayer.Character
        localRoot  = char and char:FindFirstChild("HumanoidRootPart")
    end

    local OFFSETS = {
        Vector3.new( 1,  1,  1), Vector3.new(-1,  1,  1),
        Vector3.new( 1, -1,  1), Vector3.new(-1, -1,  1),
        Vector3.new( 1,  1, -1), Vector3.new(-1,  1, -1),
        Vector3.new( 1, -1, -1), Vector3.new(-1, -1, -1),
    }

    local function getWorldCorners(character)
        local corners = {}
        for _, part in ipairs(character:GetChildren()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                local cf = part.CFrame
                local hX = part.Size.X * 0.5
                local hY = part.Size.Y * 0.5
                local hZ = part.Size.Z * 0.5
                for _, o in ipairs(OFFSETS) do
                    table.insert(corners, cf * Vector3.new(o.X * hX, o.Y * hY, o.Z * hZ))
                end
            end
        end
        return corners
    end

    updateLocalRoot()
    table.insert(connections, LocalPlayer.CharacterAdded:Connect(function()
        task.defer(updateLocalRoot)
    end))

    local function Add(player)
        if player == LocalPlayer then return end
        if boxes[player] then return end

        local box           = Box.new()
        local lastPos       = nil
        local lastSize      = nil
        local lastDist      = nil
        local lastRoot      = nil
        local lastCorners   = {}
        local wasDead       = false
        local fadedThisDeath = false

        local charConn = player.CharacterAdded:Connect(function()
            box:Hide()
            lastPos          = nil
            lastSize         = nil
            lastDist         = nil
            lastCorners      = {}
            wasDead          = false
            fadedThisDeath   = false
        end)

        boxes[player] = {
            box     = box,
            cleanup = function()
                charConn:Disconnect()
            end,
            update  = function()
                local char = player.Character
                if not char then box:Hide() return end

                local hum  = char:FindFirstChildOfClass("Humanoid")
                local root = char:FindFirstChild("HumanoidRootPart")

                if root then
                    lastRoot    = root.Position
                    lastCorners = getWorldCorners(char)
                end

                local isDead = not hum or hum.Health <= 0

                if not isDead then
                    -- Player is alive
                    wasDead        = false
                    fadedThisDeath = false

                    local pos, size = GetBoundingBox(char)
                    if pos then
                        local dist = localRoot
                            and root
                            and (localRoot.Position - root.Position).Magnitude
                            or nil

                        lastPos  = pos
                        lastSize = size
                        lastDist = dist

                        box:Update(pos, size, player.DisplayName, dist, hum.Health, hum.MaxHealth, char)
                        box:SetTransparency(0)
                    else
                        box:Hide()
                    end
                else
                    -- Player just died — trigger fade once
                    if not wasDead and not fadedThisDeath then
                        wasDead        = true
                        fadedThisDeath = true
                        if lastPos and lastSize and #lastCorners > 0 then
                            local fadeBox = Box.new()
                            FadeManager.trigger(
                                fadeBox,
                                lastRoot,
                                player.DisplayName,
                                lastPos,
                                lastSize,
                                lastDist,
                                lastCorners
                            )
                        end
                    end
                    box:Hide()
                end
            end
        }
    end

    local function Remove(player)
        local entry = boxes[player]
        if entry then
            entry.cleanup()
            entry.box:Destroy()
            boxes[player] = nil
        end
    end

    for _, p in ipairs(Players:GetPlayers()) do Add(p) end
    table.insert(connections, Players.PlayerAdded:Connect(Add))
    table.insert(connections, Players.PlayerRemoving:Connect(Remove))

    local renderConn = RunService.RenderStepped:Connect(function()
        if not localRoot then updateLocalRoot() end
        for player, entry in next, boxes do
            entry.update()
        end
    end)

    return function()
        renderConn:Disconnect()
        for _, conn in ipairs(connections) do conn:Disconnect() end
        for player, entry in next, boxes do
            entry.cleanup()
            entry.box:Destroy()
            boxes[player] = nil
        end
        FadeManager.cleanup()
    end
end

return PlayerHandler
