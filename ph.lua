local PlayerHandler = {}

function PlayerHandler.init(ctx)
    local LocalPlayer    = ctx.LocalPlayer
    local Players        = ctx.Players
    local RunService     = ctx.RunService
    local Box            = ctx.Box
    local GetBoundingBox = ctx.GetBoundingBox

    local boxes = {}

    local function Add(player)
        if player == LocalPlayer then return end
        boxes[player] = Box.new()
    end

    local function Remove(player)
        if boxes[player] then
            boxes[player]:Destroy()
            boxes[player] = nil
        end
    end

    for _, p in ipairs(Players:GetPlayers()) do Add(p) end
    local addedConn   = Players.PlayerAdded:Connect(Add)
    local removedConn = Players.PlayerRemoving:Connect(Remove)

    local renderConn = RunService.RenderStepped:Connect(function()
        local localChar = LocalPlayer.Character
        local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")

        for player, box in pairs(boxes) do
            local char = player.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")

            if char and hum and hum.Health > 0 then
                local pos, size = GetBoundingBox(char)
                if pos then
                    local dist = (localRoot and root)
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
        addedConn:Disconnect()
        removedConn:Disconnect()
        for player, box in pairs(boxes) do
            box:Destroy()
            boxes[player] = nil
        end
    end
end

return PlayerHandler
