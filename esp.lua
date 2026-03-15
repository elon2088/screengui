local ESP = {}
ESP.__index = ESP

local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local Camera      = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local CFG = {
    BorderColor    = Color3.fromRGB(0, 255, 255),
    OutlineColor   = Color3.fromRGB(0, 0, 0),
    BorderThick    = 0.9,
    OutlineThick   = 0.9,
    NameColor      = Color3.fromRGB(255, 255, 255),
    NameSize       = 12,
    DistColor      = Color3.fromRGB(255, 255, 255),
    DistSize       = 12,
    HealthWidth    = 1.5,
    HealthGap      = 1.5,
    HealthLerp     = 0.04,
    HealthTextSize = 9,
}

local gui
do
    local existing = (gethui and gethui() or game:GetService("CoreGui")):FindFirstChild("BoxESP")
    if existing then
        gui = existing
    else
        gui                = Instance.new("ScreenGui")
        gui.Name           = "BoxESP"
        gui.ResetOnSpawn   = false
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        gui.IgnoreGuiInset = true
        gui.Parent         = gethui and gethui() or game:GetService("CoreGui")
    end
end

local function healthColor(pct)
    if pct >= 0.5 then
        local t = 1 - (pct - 0.5) / 0.5
        return Color3.fromRGB(math.floor(255 * t), 238, math.floor(144 * (1 - t)))
    else
        local t = pct / 0.5
        return Color3.fromRGB(255, math.floor(200 * t), 0)
    end
end

local function makeFrame(parent, strokeColor, strokeThick)
    local f                  = Instance.new("Frame")
    f.BackgroundTransparency = 1
    f.BorderSizePixel        = 0
    f.Parent                 = parent

    local s        = Instance.new("UIStroke")
    s.Color        = strokeColor
    s.Thickness    = strokeThick
    s.LineJoinMode = Enum.LineJoinMode.Miter
    s.Parent       = f

    return f
end

local Box = {}
Box.__index = Box

function Box.new(features)
    local self      = setmetatable({}, Box)
    self._features  = features
    self._smoothPct = 1

    self._outer  = makeFrame(gui, CFG.OutlineColor, CFG.OutlineThick)
    self._border = makeFrame(gui, CFG.BorderColor,  CFG.BorderThick)
    self._inner  = makeFrame(gui, CFG.OutlineColor, CFG.OutlineThick)

    if features.fill then
        local fill                  = Instance.new("ImageLabel")
        fill.BackgroundTransparency = 1
        fill.BorderSizePixel        = 0
        fill.Size                   = UDim2.fromScale(1, 1)
        fill.Position               = UDim2.fromScale(0, 0)
        fill.Image                  = "rbxassetid://14514194653"
        fill.ImageColor3            = CFG.BorderColor
        fill.ImageTransparency      = 0.4
        fill.ScaleType              = Enum.ScaleType.Stretch
        fill.ZIndex                 = self._border.ZIndex - 1
        fill.Parent                 = self._border
        self._fill                  = fill
    end

    if features.name then
        local name                  = Instance.new("TextLabel")
        name.BackgroundTransparency = 1
        name.BorderSizePixel        = 0
        name.AnchorPoint            = Vector2.new(0.5, 1)
        name.Size                   = UDim2.new(0, 200, 0, CFG.NameSize + 4)
        name.Font                   = Enum.Font.Code
        name.TextSize               = CFG.NameSize
        name.TextColor3             = CFG.NameColor
        name.TextStrokeTransparency = 0
        name.TextStrokeColor3       = CFG.OutlineColor
        name.TextXAlignment         = Enum.TextXAlignment.Center
        name.Text                   = ""
        name.Visible                = false
        name.ZIndex                 = self._border.ZIndex + 1
        name.Parent                 = gui
        self._name                  = name
    end

    if features.distance then
        local dist                  = Instance.new("TextLabel")
        dist.BackgroundTransparency = 1
        dist.BorderSizePixel        = 0
        dist.AnchorPoint            = Vector2.new(0.5, 0)
        dist.Size                   = UDim2.new(0, 200, 0, CFG.DistSize + 4)
        dist.Font                   = Enum.Font.Code
        dist.TextSize               = CFG.DistSize
        dist.TextColor3             = CFG.DistColor
        dist.TextStrokeTransparency = 0
        dist.TextStrokeColor3       = CFG.OutlineColor
        dist.TextXAlignment         = Enum.TextXAlignment.Center
        dist.Text                   = ""
        dist.Visible                = false
        dist.ZIndex                 = self._border.ZIndex + 1
        dist.Parent                 = gui
        self._dist                  = dist
    end

    if features.healthbar then
        local hpBg              = Instance.new("Frame")
        hpBg.BackgroundColor3   = Color3.fromRGB(0, 0, 0)
        hpBg.BorderSizePixel    = 0
        hpBg.Visible            = false
        hpBg.ZIndex             = self._border.ZIndex + 1
        hpBg.Parent             = gui
        self._hpBg              = hpBg

        local hpFill              = Instance.new("Frame")
        hpFill.BackgroundColor3   = Color3.fromRGB(255, 255, 255)
        hpFill.BorderSizePixel    = 0
        hpFill.AnchorPoint        = Vector2.new(0, 0)
        hpFill.Visible            = false
        hpFill.ZIndex             = self._border.ZIndex + 2
        hpFill.Parent             = gui
        self._hpFill              = hpFill

        local grad    = Instance.new("UIGradient")
        grad.Color    = ColorSequence.new({
            ColorSequenceKeypoint.new(0,    Color3.fromRGB(0,   150, 0)),
            ColorSequenceKeypoint.new(0.35, Color3.fromRGB(100, 150, 0)),
            ColorSequenceKeypoint.new(0.65, Color3.fromRGB(170, 80,  0)),
            ColorSequenceKeypoint.new(1,    Color3.fromRGB(150, 0,   0)),
        })
        grad.Rotation = 90
        grad.Parent   = hpFill

        if features.healthtext then
            local hpText                  = Instance.new("TextLabel")
            hpText.BackgroundTransparency = 1
            hpText.BorderSizePixel        = 0
            hpText.AnchorPoint            = Vector2.new(0.5, 1)
            hpText.Size                   = UDim2.new(0, 24, 0, CFG.HealthTextSize + 2)
            hpText.Font                   = Enum.Font.Code
            hpText.TextSize               = CFG.HealthTextSize
            hpText.TextColor3             = Color3.fromRGB(144, 238, 144)
            hpText.TextStrokeTransparency = 0
            hpText.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
            hpText.TextXAlignment         = Enum.TextXAlignment.Center
            hpText.Text                   = ""
            hpText.Visible                = false
            hpText.ZIndex                 = self._border.ZIndex + 3
            hpText.Parent                 = gui
            self._hpText                  = hpText
        end
    end

    self._outer.Visible  = false
    self._border.Visible = false
    self._inner.Visible  = false

    return self
end

function Box:Update(pos, size, displayName, distance, health, maxHealth)
    local x, y, w, h = pos.X, pos.Y, size.X, size.Y
    local f          = self._features

    self._outer.Position  = UDim2.fromOffset(x - 1, y - 1)
    self._outer.Size      = UDim2.fromOffset(w + 2,  h + 2)
    self._outer.Visible   = true

    self._border.Position = UDim2.fromOffset(x, y)
    self._border.Size     = UDim2.fromOffset(w, h)
    self._border.Visible  = true

    self._inner.Position  = UDim2.fromOffset(x + 1, y + 1)
    self._inner.Size      = UDim2.fromOffset(w - 2, h - 2)
    self._inner.Visible   = true

    if f.name and self._name then
        self._name.Position = UDim2.fromOffset(x + w * 0.5, y - 2)
        self._name.Text     = displayName or ""
        self._name.Visible  = true
    end

    if f.distance and self._dist then
        self._dist.Position = UDim2.fromOffset(x + w * 0.5, y + h + 2)
        self._dist.Text     = distance and (math.floor(distance) .. "st") or ""
        self._dist.Visible  = true
    end

    if f.healthbar and self._hpBg and self._hpFill then
        local pct  = (health and maxHealth and maxHealth > 0)
                      and math.clamp(health / maxHealth, 0, 1)
                      or 1

        self._smoothPct = self._smoothPct + (pct - self._smoothPct) * CFG.HealthLerp

        local barW  = CFG.HealthWidth
        local barH  = h + 2
        local barX  = x - CFG.HealthGap - barW - 1
        local barY  = y - 1
        local fillH = barH * self._smoothPct
        local fillY = barY + barH - fillH

        self._hpBg.Position   = UDim2.fromOffset(barX - 1, barY - 1)
        self._hpBg.Size       = UDim2.fromOffset(barW + 2,  barH + 2)
        self._hpBg.Visible    = true

        self._hpFill.Position = UDim2.fromOffset(barX,      fillY)
        self._hpFill.Size     = UDim2.fromOffset(barW,      fillH)
        self._hpFill.Visible  = fillH > 0

        if f.healthtext and self._hpText then
            local textY = math.max(fillY, barY + CFG.HealthTextSize + 2)
            self._hpText.Position   = UDim2.fromOffset(barX + barW * 0.5, textY)
            self._hpText.Text       = tostring(health and math.ceil(health) or 0)
            self._hpText.TextColor3 = healthColor(self._smoothPct)
            self._hpText.Visible    = fillH > 0
        end
    end
end

function Box:Hide()
    self._outer.Visible  = false
    self._border.Visible = false
    self._inner.Visible  = false
    if self._name    then self._name.Visible    = false end
    if self._dist    then self._dist.Visible    = false end
    if self._hpBg    then self._hpBg.Visible    = false end
    if self._hpFill  then self._hpFill.Visible  = false end
    if self._hpText  then self._hpText.Visible  = false end
end

function Box:Destroy()
    self._outer:Destroy()
    self._border:Destroy()
    self._inner:Destroy()
    if self._name    then self._name:Destroy()    end
    if self._dist    then self._dist:Destroy()    end
    if self._hpBg    then self._hpBg:Destroy()    end
    if self._hpFill  then self._hpFill:Destroy()  end
    if self._hpText  then self._hpText:Destroy()  end
end

local OFFSETS = {
    Vector3.new( 1,  1,  1), Vector3.new(-1,  1,  1),
    Vector3.new( 1, -1,  1), Vector3.new(-1, -1,  1),
    Vector3.new( 1,  1, -1), Vector3.new(-1,  1, -1),
    Vector3.new( 1, -1, -1), Vector3.new(-1, -1, -1),
}

local function GetBoundingBox(character)
    local minX, minY =  math.huge,  math.huge
    local maxX, maxY = -math.huge, -math.huge
    local valid      = false

    for _, part in ipairs(character:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            local cf = part.CFrame
            local hX = part.Size.X * 0.5
            local hY = part.Size.Y * 0.5
            local hZ = part.Size.Z * 0.5

            for _, o in ipairs(OFFSETS) do
                local screen, vis = Camera:WorldToViewportPoint(
                    cf * Vector3.new(o.X * hX, o.Y * hY, o.Z * hZ)
                )
                if vis then
                    valid = true
                    if screen.X < minX then minX = screen.X end
                    if screen.Y < minY then minY = screen.Y end
                    if screen.X > maxX then maxX = screen.X end
                    if screen.Y > maxY then maxY = screen.Y end
                end
            end
        end
    end

    if not valid then return nil end
    return Vector2.new(minX, minY), Vector2.new(maxX - minX, maxY - minY)
end

local _activeESP = nil

function ESP.new(features)
    if _activeESP then
        _activeESP:Disable()
    end

    local self = setmetatable({}, ESP)

    self._features = {
        fill        = features.fill        ~= false,
        name        = features.name        ~= false,
        distance    = features.distance    ~= false,
        healthbar   = features.healthbar   ~= false,
        healthtext  = features.healthtext  ~= false,
    }

    if features.BorderColor    then CFG.BorderColor    = features.BorderColor    end
    if features.OutlineColor   then CFG.OutlineColor   = features.OutlineColor   end
    if features.NameColor      then CFG.NameColor      = features.NameColor      end
    if features.DistColor      then CFG.DistColor      = features.DistColor      end
    if features.BorderThick    then CFG.BorderThick    = features.BorderThick    end
    if features.OutlineThick   then CFG.OutlineThick   = features.OutlineThick   end
    if features.HealthWidth    then CFG.HealthWidth    = features.HealthWidth    end
    if features.HealthGap      then CFG.HealthGap      = features.HealthGap      end
    if features.HealthLerp     then CFG.HealthLerp     = features.HealthLerp     end
    if features.NameSize       then CFG.NameSize       = features.NameSize       end
    if features.DistSize       then CFG.DistSize       = features.DistSize       end
    if features.HealthTextSize then CFG.HealthTextSize = features.HealthTextSize end

    self._Box            = function() return Box.new(self._features) end
    self._GetBoundingBox = GetBoundingBox
    self._destroy        = nil

    _activeESP = self
    return self
end

function ESP:Enable()
    if self._destroy then return end

    local PlayerHandler = loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/elon2088/screengui/refs/heads/main/ph.lua"
    ))()

    self._destroy = PlayerHandler.init({
        LocalPlayer    = LocalPlayer,
        Players        = Players,
        RunService     = RunService,
        Box            = { new = self._Box },
        GetBoundingBox = self._GetBoundingBox,
    })

    gui.Enabled = true
end

function ESP:Disable()
    if self._destroy then
        self._destroy()
        self._destroy = nil
    end
    gui.Enabled = false
end

function ESP:Toggle()
    if self._destroy then
        self:Disable()
    else
        self:Enable()
    end
end

function ESP:SetConfig(key, value)
    CFG[key] = value
end

return ESP
