local FadeManager = {}

local Camera     = workspace.CurrentCamera
local RunService = game:GetService("RunService")

local CFG = {
    FadeDuration = 2.5,
}

local fades      = {}
local renderConn = nil

local function startRender()
    if renderConn then return end
    renderConn = RunService.RenderStepped:Connect(function(dt)
        local i = 1
        while i <= #fades do
            local f = fades[i]
            f.elapsed = f.elapsed + dt
            local t   = math.clamp(f.elapsed / CFG.FadeDuration, 0, 1)

            if t >= 1 then
                f.box:Hide()
                f.box:Destroy()
                table.remove(fades, i)
            else
                local screen, vis = Camera:WorldToViewportPoint(f.worldPos)
                local pos, size

                if vis then
                    -- player died on screen — project world pos to get position
                    -- use last known size from when they were alive
                    pos  = Vector2.new(
                        screen.X - f.lastSize.X * 0.5,
                        screen.Y - f.lastSize.Y * 0.5
                    )
                    size = f.lastSize
                    f.lastScreenPos = pos
                else
                    -- off screen — freeze at last known screen position
                    pos  = f.lastScreenPos
                    size = f.lastSize
                end

                if pos then
                    f.box:Update(
                        pos,
                        size,
                        f.name,
                        f.lastDist,
                        0,
                        100,
                        nil
                    )
                    f.box:SetTransparency(t)
                end

                i = i + 1
            end
        end

        if #fades == 0 then
            renderConn:Disconnect()
            renderConn = nil
        end
    end)
end

function FadeManager.trigger(box, worldPos, displayName, lastPos, lastSize, lastDist)
    box:SetTransparency(0)
    table.insert(fades, {
        box           = box,
        worldPos      = worldPos,
        name          = displayName,
        lastPos       = lastPos,
        lastSize      = lastSize,
        lastScreenPos = lastPos,
        lastDist      = lastDist,
        elapsed       = 0,
    })
    startRender()
end

function FadeManager.setConfig(key, value)
    CFG[key] = value
end

function FadeManager.cleanup()
    if renderConn then
        renderConn:Disconnect()
        renderConn = nil
    end
    for _, f in ipairs(fades) do
        f.box:Hide()
        f.box:Destroy()
    end
    table.clear(fades)
end

return FadeManager
