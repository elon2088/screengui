local FadeManager = {}

local Camera     = workspace.CurrentCamera
local RunService = game:GetService("RunService")

local CFG = {
    FadeDuration = 2.5,   -- seconds to fully fade out
    FadeSize     = Vector2.new(50, 100), -- fixed screen size of ghost box
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
                if vis then
                    local pos = Vector2.new(
                        screen.X - CFG.FadeSize.X * 0.5,
                        screen.Y - CFG.FadeSize.Y * 0.5
                    )
                    f.box:Update(pos, CFG.FadeSize, f.name, nil, 0, 100, nil)
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

function FadeManager.trigger(box, worldPos, displayName)
    box:SetTransparency(0)
    table.insert(fades, {
        box      = box,
        worldPos = worldPos,
        name     = displayName,
        elapsed  = 0,
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
