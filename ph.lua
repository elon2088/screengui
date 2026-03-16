local PlayerHandler = {}

function PlayerHandler.init(ctx)
    local LocalPlayer    = ctx.LocalPlayer
    local Players        = ctx.Players
    local RunService     = ctx.RunService
    local Box            = ctx.Box
    local GetBoundingBox = ctx.GetBoundingBox

    local boxes       = {}
    local connections = {}
    local localRoot   = nil

    local function updateLocalRoot()
        local char = LocalPlayer.Character
        localRoot  = char and char:FindFirstChild("HumanoidRootPart")
    end

    updateLocalRoot()
    table.insert(connections, LocalPlayer.CharacterAdded:Connect(function()
        task.defer(updateLocalRoot)
    end))

    local function Add(player)
        if player == LocalPlayer then return end
        if boxes[player] then return end
        local box = Box.new()
        boxes[player] = {
            box  = box,
            conn = player.CharacterAdded:Connect(function()
                box:Hide()
            end)
        }
    end

    local function Remove(player)
        local entry = boxes[player]
        if entry then
            entry.conn:Disconnect()
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
            local box  = entry.box
            local char = player.Character
            if not char then box:Hide() continue end

            local hum  = char:FindFirstChildOfClass("Humanoid")
            local root = char:FindFirstChild("HumanoidRootPart")

            if hum and hum.Health > 0 and root then
                local pos, size = GetBoundingBox(char)
                if pos then
                    local dist = localRoot
                        and (localRoot.Position - root.Position).Magnitude
                        or nil
                    box:Update(pos, size, player.DisplayName, dist, hum.Health, hum.MaxHealth, char)
                else
                    box:Hide()
                end
            else
                box:Hide()
            end
        end
    end)

    return function()
        renderConn:Disconnect()
        for _, conn in ipairs(connections) do conn:Disconnect() end
        for player, entry in next, boxes do
            entry.conn:Disconnect()
            entry.box:Destroy()
            boxes[player] = nil
        end
    end
end

return PlayerHandler
