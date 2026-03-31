local ESP = {}
ESP.__index = ESP

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera     = workspace.CurrentCamera

local CFG = {
    BoxColor         = Color3.fromRGB(255, 255, 255),
    OutlineColor     = Color3.fromRGB(0, 0, 0),
    WeaponColor      = Color3.fromRGB(202, 243, 255),
    TextSize         = 11,
    Font             = Enum.Font.Code,
    FadeDuration     = 1.0, 
    FillTransparency = 0.7
}

local gui
do
    local existing = (gethui and gethui() or game:GetService("CoreGui")):FindFirstChild("Sonder_Final_ESP")
    if existing then
        gui = existing
    else
        gui                = Instance.new("ScreenGui")
        gui.Name           = "Sonder_Final_ESP"
        gui.ResetOnSpawn   = false
        gui.IgnoreGuiInset = true
        gui.Parent         = gethui and gethui() or game:GetService("CoreGui")
    end
end

local Box = {}
Box.__index = Box

function Box.new()
    local self = setmetatable({}, Box)
    
    self.Main = Instance.new("Frame")
    self.Main.BackgroundColor3 = Color3.new(1, 1, 1)
    self.Main.BackgroundTransparency = CFG.FillTransparency
    self.Main.BorderSizePixel = 0
    self.Main.Visible = false
    self.Main.Parent = gui
    

    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 160, 160))
    })
    grad.Rotation = 90
    grad.Parent = self.Main


    self.Stroke = Instance.new("UIStroke")
    self.Stroke.Thickness = 1
    self.Stroke.Color = CFG.BoxColor
    self.Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    self.Stroke.Parent = self.Main
    

    self.Outline = Instance.new("UIStroke")
    self.Outline.Thickness = 2
    self.Outline.Color = CFG.OutlineColor
    self.Outline.Transparency = 0.3
    self.Outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    self.Outline.Parent = self.Main
    

    self.WeaponLabel = Instance.new("TextLabel")
    self.WeaponLabel.BackgroundTransparency = 1
    self.WeaponLabel.Font = CFG.Font
    self.WeaponLabel.TextSize = CFG.TextSize
    self.WeaponLabel.TextColor3 = CFG.WeaponColor
    self.WeaponLabel.TextStrokeTransparency = 0
    self.WeaponLabel.AnchorPoint = Vector2.new(0.5, 1)
    self.WeaponLabel.Parent = self.Main


    self.DistLabel = Instance.new("TextLabel")
    self.DistLabel.BackgroundTransparency = 1
    self.DistLabel.Font = CFG.Font
    self.DistLabel.TextSize = CFG.TextSize
    self.DistLabel.TextColor3 = Color3.new(1, 1, 1)
    self.DistLabel.TextStrokeTransparency = 0
    self.DistLabel.AnchorPoint = Vector2.new(0.5, 0)
    self.DistLabel.Parent = self.Main
    
    self.LastVisibleTime = tick()
    return self
end

function Box:Update(pos, size, weaponName, distance, isAlive)
    if isAlive then
        self.LastVisibleTime = tick()
        self.Main.BackgroundTransparency = CFG.FillTransparency
        self.Stroke.Transparency = 0
        self.Outline.Transparency = 0.3
        self.WeaponLabel.TextTransparency = 0
        self.DistLabel.TextTransparency = 0
    else

        local elapsed = tick() - self.LastVisibleTime
        local alpha = math.clamp(1 - (elapsed / CFG.FadeDuration), 0, 1)
        
        self.Main.BackgroundTransparency = 1 - (alpha * (1 - CFG.FillTransparency))
        self.Stroke.Transparency = 1 - alpha
        self.Outline.Transparency = 1 - (alpha * 0.7)
        self.WeaponLabel.TextTransparency = 1 - alpha
        self.DistLabel.TextTransparency = 1 - alpha
        
        if alpha <= 0 then
            self.Main.Visible = false
            return
        end
    end

    self.Main.Position = UDim2.fromOffset(pos.X, pos.Y)
    self.Main.Size = UDim2.fromOffset(size.X, size.Y)
    
    self.WeaponLabel.Position = UDim2.new(0.5, 0, 0, -2)
    self.WeaponLabel.Text = "[" .. (weaponName or "None") .. "]"
    
    self.DistLabel.Position = UDim2.new(0.5, 0, 1, 2)
    self.DistLabel.Text = math.floor(distance) .. "st"
    
    self.Main.Visible = true
end


local OFFSETS = {
    Vector3.new(1, 1, 1), Vector3.new(-1, 1, 1),
    Vector3.new(1, -1, 1), Vector3.new(-1, -1, 1),
    Vector3.new(1, 1, -1), Vector3.new(-1, 1, -1),
    Vector3.new(1, -1, -1), Vector3.new(-1, -1, -1),
}

local function GetBoundingBox(model)
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    local onScreen = false

    for _, part in ipairs(model:GetChildren()) do
        if part:IsA("BasePart") then
            local cf = part.CFrame
            local size = part.Size * 0.5
            for _, offset in ipairs(OFFSETS) do
                local screenPos, vis = Camera:WorldToViewportPoint(cf * (offset * size))
                if vis then
                    onScreen = true
                    minX = math.min(minX, screenPos.X)
                    minY = math.min(minY, screenPos.Y)
                    maxX = math.max(maxX, screenPos.X)
                    maxY = math.max(maxY, screenPos.Y)
                end
            end
        end
    end
    if not onScreen then return nil end
    return Vector2.new(minX, minY), Vector2.new(maxX - minX, maxY - minY)
end

function ESP.init()
    local Viewmodels = workspace:WaitForChild("Viewmodels")
    local cache = {}

    RunService.RenderStepped:Connect(function()
        for _, model in ipairs(Viewmodels:GetChildren()) do
            if model:IsA("Model") and model.Name ~= "LocalViewmodel" then
                if not cache[model] then cache[model] = Box.new() end
                
                local pos, size = GetBoundingBox(model)
                local isAlive = model:FindFirstChild("HumanoidRootPart") ~= nil
                
                if pos and size then
                    local dist = (Camera.CFrame.Position - model:GetBoundingBox().Position).Magnitude
                    local weapon = model:GetAttribute("EquippedWeapon") or "AK12"
                    cache[model]:Update(pos, size, weapon, dist, isAlive)
                end
            end
        end
    end)
end

return ESP
