local ESP = {
    Enabled = true,
    Box = true,
    Fill = true,
    Distance = true,
    Weapon = true,
    
    BoxColor = Color3.fromRGB(255, 255, 255),
    GradientColor = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 150, 150))
    }),
    FillTransparency = 0.7,
    
    WeaponColor = Color3.fromRGB(202, 243, 255),
    DistanceColor = Color3.fromRGB(255, 255, 255),
    
    FadeTime = 1.0,
    Cache = {}
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local Viewmodels = workspace:WaitForChild("Viewmodels")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Sonder_ESP_V5"
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = (gethui and gethui()) or game:GetService("CoreGui")

local BoxEntry = {}
BoxEntry.__index = BoxEntry

function BoxEntry.new(model)
    local self = setmetatable({}, BoxEntry)
    self.Model = model
    self.IsFading = false
    self.DeathPos = nil

    self.Root = Instance.new("Frame")
    self.Root.BorderSizePixel = 0
    self.Root.BackgroundTransparency = 1
    self.Root.Visible = false
    self.Root.Parent = ScreenGui
    

    self.Gradient = Instance.new("UIGradient")
    self.Gradient.Color = ESP.GradientColor
    self.Gradient.Rotation = 90
    self.Gradient.Parent = self.Root

    self.Box = Instance.new("UIStroke")
    self.Box.Thickness = 1
    self.Box.Color = ESP.BoxColor
    self.Box.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    self.Box.Parent = self.Root
    
    self.Outline = Instance.new("UIStroke")
    self.Outline.Thickness = 2
    self.Outline.Color = Color3.new(0, 0, 0)
    self.Outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    self.Outline.Parent = self.Root
    
    self.WeaponLabel = Instance.new("TextLabel")
    self.WeaponLabel.BackgroundTransparency = 1
    self.WeaponLabel.Font = Enum.Font.Code
    self.WeaponLabel.TextSize = 11
    self.WeaponLabel.TextColor3 = ESP.WeaponColor
    self.WeaponLabel.TextStrokeTransparency = 0
    self.WeaponLabel.AnchorPoint = Vector2.new(0.5, 0)
    self.WeaponLabel.Parent = self.Root
    
    self.DistanceLabel = Instance.new("TextLabel")
    self.DistanceLabel.BackgroundTransparency = 1
    self.DistanceLabel.Font = Enum.Font.Code
    self.DistanceLabel.TextSize = 11
    self.DistanceLabel.TextColor3 = ESP.DistanceColor
    self.DistanceLabel.TextStrokeTransparency = 0
    self.DistanceLabel.AnchorPoint = Vector2.new(0.5, 0)
    self.DistanceLabel.Parent = self.Root
    
    return self
end


local function GetPerfectBox(model)
    local cf, size = model:GetBoundingBox()
    local corners = {
        cf * CFrame.new(size.X/2, size.Y/2, size.Z/2),
        cf * CFrame.new(-size.X/2, size.Y/2, size.Z/2),
        cf * CFrame.new(size.X/2, -size.Y/2, size.Z/2),
        cf * CFrame.new(-size.X/2, -size.Y/2, size.Z/2),
        cf * CFrame.new(size.X/2, size.Y/2, -size.Z/2),
        cf * CFrame.new(-size.X/2, size.Y/2, -size.Z/2),
        cf * CFrame.new(size.X/2, -size.Y/2, -size.Z/2),
        cf * CFrame.new(-size.X/2, -size.Y/2, -size.Z/2)
    }

    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
    local visible = false

    for _, corner in ipairs(corners) do
        local screenPos, onScreen = Camera:WorldToViewportPoint(corner.Position)
        if onScreen then visible = true end
        minX = math.min(minX, screenPos.X)
        minY = math.min(minY, screenPos.Y)
        maxX = math.max(maxX, screenPos.X)
        maxY = math.max(maxY, screenPos.Y)
    end

    return visible, Vector2.new(minX, minY), Vector2.new(maxX - minX, maxY - minY)
end

function BoxEntry:Update()
    if self.IsFading then return end
    
    local head = self.Model:FindFirstChild("head")
    if not head or head:FindFirstChild("Username") then
        self:Fade()
        return
    end

    local onScreen, pos, size = GetPerfectBox(self.Model)

    if onScreen then
        self.Root.Position = UDim2.fromOffset(pos.X, pos.Y)
        self.Root.Size = UDim2.fromOffset(size.X, size.Y)
        
        self.Root.BackgroundTransparency = ESP.Fill and ESP.FillTransparency or 1
        self.Root.BackgroundColor3 = Color3.new(1,1,1)
        
        self.WeaponLabel.Text = "[" .. (self.Model:GetAttribute("item_type") or "None") .. "]"
        self.WeaponLabel.Position = UDim2.new(0.5, 0, 1, 4)
        
        local dist = (Camera.CFrame.Position - head.Position).Magnitude
        self.DistanceLabel.Text = math.floor(dist) .. "st"
        self.DistanceLabel.Position = UDim2.new(0.5, 0, 1, ESP.Weapon and 16 or 4)
        
        self.Root.Visible = true
    else
        self.Root.Visible = false
    end
end

function BoxEntry:Fade()
    if self.IsFading then return end
    self.IsFading = true
    

    local cf, _ = self.Model:GetBoundingBox()
    local lastWorldPos = cf.Position
    
    task.spawn(function()
        local start = tick()
        while tick() - start < ESP.FadeTime do
            local alpha = (tick() - start) / ESP.FadeTime
            

            local sPos, onScreen = Camera:WorldToViewportPoint(lastWorldPos)
            if onScreen then
                self.Root.Position = UDim2.fromOffset(sPos.X - (self.Root.Size.X.Offset/2), sPos.Y - (self.Root.Size.Y.Offset/2))
                self.Root.Visible = true
            else
                self.Root.Visible = false
            end
            
            local trans = ESP.FillTransparency + (alpha * (1 - ESP.FillTransparency))
            self.Root.BackgroundTransparency = math.clamp(trans, 0, 1)
            self.Box.Transparency = alpha
            self.Outline.Transparency = alpha
            self.WeaponLabel.TextTransparency = alpha
            self.DistanceLabel.TextTransparency = alpha
            
            RunService.RenderStepped:Wait()
        end
        self:Destroy()
    end)
end

function BoxEntry:Destroy()
    self.Root:Destroy()
    ESP.Cache[self.Model] = nil
end

function ESP:Init()
    RunService.RenderStepped:Connect(function()
        if not self.Enabled then return end
        for _, model in ipairs(Viewmodels:GetChildren()) do
            if model:IsA("Model") and model.Name ~= "LocalViewmodel" then
                if not self.Cache[model] then self.Cache[model] = BoxEntry.new(model) end
                self.Cache[model]:Update()
            end
        end
        for model, entry in pairs(self.Cache) do
            if not model:IsDescendantOf(Viewmodels) then entry:Fade() end
        end
    end)
end

return ESP
