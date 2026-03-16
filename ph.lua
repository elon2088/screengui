local PlayerHandler = {}

function PlayerHandler.init(ctx)
    local LocalPlayer    = ctx.LocalPlayer
    local Players        = ctx.Players
    local RunService     = ctx.RunService
    local Box            = ctx.Box
    local GetBoundingBox = ctx.GetBoundingBox

    local FadeManager = loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/elon2088/screengui/refs/heads/main/fade.lua"
    ))()

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
        local lastRoot = nil

        local deathConn = nil
        local function setupHum(char)
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not hum then return end
            if deathConn then deathConn:Disconnect() end
            deathConn = hum.Died:Connect(function()
                local root = char:FindFirstChild("HumanoidRootPart")
                local wp   = root and root.Position or lastRoot
                if wp then
                    local fadeBox = Box.new()
                    FadeManager.trigger(fadeBox, wp, player.DisplayName)
                end
                box:Hide()
            end)
        end

        setupHum(player.Character)

        local charConn = player.CharacterAdded:Connect(function(char)
            box:Hide()
            task.defer(function()
                setupHum(char)
            end)
        end)

        boxes[player] = {
            box      = box,
            charConn = charConn,
            getRoot  = function()
                local char = player.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root then lastRoot = root.Position end
                return root
            end,
            cleanup = function()
                charConn:Disconnect()
                if deathConn then deathConn:Disconnect() end
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
            local box  = entry.box
            local char = player.Character
            if not char then box:Hide() continue end

            local hum  = char:FindFirstChildOfClass("Humanoid")
            local root = entry.getRoot()

            if hum and hum.Health > 0 and root then
                local pos, size = GetBoundingBox(char)
                if pos then
                    local dist = localRoot
                        and (localRoot.Position - root.Position).Magnitude
                        or nil
                    box:Update(pos, size, player.DisplayName, dist, hum.Health, hum.MaxHealth, char)
                    box:SetTransparency(0)
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
            entry.cleanup()
            entry.box:Destroy()
            boxes[player] = nil
        end
        FadeManager.cleanup()
    end
end

return PlayerHandler
