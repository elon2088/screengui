
local ESP = {
    Enabled = true,
    Box = true,
    Distance = true,
    Weapon = true,
    FadeTime = 1.5,
    BoxColor = Color3.fromRGB(255, 255, 255),
    WeaponColor = Color3.fromRGB(202, 243, 255),
    DistanceColor = Color3.fromRGB(255, 255, 255),
    Cache = {}
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local Viewmodels = workspace:WaitForChild("Viewmodels")


local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "skidded sonder"
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = (gethui and gethui()) or game:GetService("CoreGui")

local BoxEntry = {}
BoxEntry.__index = BoxEntry

function BoxEntry.new(model)
    local self = setmetatable({}, BoxEntry)
    self.Model = model
    self.IsFading = false
    

    self.Root = Instance.new("Frame")
    self.Root.BackgroundTransparency = 1
    self.Root.Visible = false
    self.Root.Parent = ScreenGui
    

    self.Outline = Instance.new("UIStroke")
    self.Outline.Thickness = 2
    self.Outline.Color = Color3.new(0, 0, 0)
    self.Outline.Parent = self.Root
    
    self.Box = Instance.new("UIStroke")
    self.Box.Thickness = 1
    self.Box.Color = ESP.BoxColor
    self.Box.Parent = self.Root
    
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

function BoxEntry:GetWeapon()
    for _, child in ipairs(self.Model:GetChildren()) do
        if child:IsA("Model") and child:GetAttribute("item_type") then
            return child.Name
        end
    end
    return "None"
end

function BoxEntry:Update()
    if self.IsFading then return end
    

    local head = self.Model:FindFirstChild("head")
    if not head or head:FindFirstChild("Username") then
        self:Fade()
        return
    end

    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
    local foundParts = 0
    
    for _, part in ipairs(self.Model:GetChildren()) do
        if part:IsA("BasePart") then
            local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
            if onScreen then
                foundParts = foundParts + 1
                minX = math.min(minX, screenPos.X)
                minY = math.min(minY, screenPos.Y)
                maxX = math.max(maxX, screenPos.X)
                maxY = math.max(maxY, screenPos.Y)
            end
        end
    end

    if foundParts > 0 then
        local w, h = maxX - minX, maxY - minY
        local dist = (Camera.CFrame.Position - head.Position).Magnitude
        
        self.Root.Position = UDim2.fromOffset(minX, minY)
        self.Root.Size = UDim2.fromOffset(w, h)
        

        self.Box.Enabled = ESP.Box
        self.Outline.Enabled = ESP.Box
        

        self.WeaponLabel.Visible = ESP.Weapon
        self.WeaponLabel.Text = "[" .. self:GetWeapon() .. "]"
        self.WeaponLabel.Position = UDim2.new(0.5, 0, 1, 2)
        

        self.DistanceLabel.Visible = ESP.Distance
        self.DistanceLabel.Text = math.floor(dist) .. "st"
        local distOffset = ESP.Weapon and 14 or 2
        self.DistanceLabel.Position = UDim2.new(0.5, 0, 1, distOffset)
        
        self.Root.Visible = true
    else
        self.Root.Visible = false
    end
end

function BoxEntry:Fade()
    if self.IsFading then return end
    self.IsFading = true
    
    task.spawn(function()
        local start = tick()
        while tick() - start < ESP.FadeTime do
            local alpha = (tick() - start) / ESP.FadeTime
            
            self.Outline.Transparency = alpha
            self.Box.Transparency = alpha
            self.WeaponLabel.TextTransparency = alpha
            self.WeaponLabel.TextStrokeTransparency = alpha
            self.DistanceLabel.TextTransparency = alpha
            self.DistanceLabel.TextStrokeTransparency = alpha
            
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
        if not self.Enabled then 
            for _, entry in pairs(self.Cache) do entry.Root.Visible = false end
            return 
        end
        
        for _, model in ipairs(Viewmodels:GetChildren()) do
            if model:IsA("Model") and model.Name ~= "LocalViewmodel" then
                if not self.Cache[model] then
                    self.Cache[model] = BoxEntry.new(model)
                end
                self.Cache[model]:Update()
            end
        end
        

        for model, entry in pairs(self.Cache) do
            if not model:IsDescendantOf(Viewmodels) then
                entry:Fade()
            end
        end
    end)
end

return ESP
