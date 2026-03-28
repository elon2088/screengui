local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local Req = (syn and syn.request) or request or http_request or (http and http.request)
if not Req then return end

local wsFolder = "RobloxMusicPlayer"
if makefolder then pcall(function() makefolder(wsFolder) end) end

local downloadTrack;
local libPath = wsFolder .. "/library.json"

local function loadLibrary()
    if isfile(libPath) then
        local raw = readfile(libPath)
        local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
        if ok and type(data) == "table" then return data end
    end
    return {}
end
local function saveLibrary(data)
    pcall(function() writefile(libPath, HttpService:JSONEncode(data)) end)
end

local myLibrary = loadLibrary()
local function GetAsync(url)
    local ok, res = pcall(function() return Req({Url=url, Method="GET"}) end)
    if ok and res and res.StatusCode == 200 then return res.Body end
    return nil
end

local SC_CLIENT_ID = nil
local function getSCClientId()
    local html = GetAsync("https://soundcloud.com")
    if not html then return end
    for src in html:gmatch('<script[^>]+src="(https://a%-v2%.sndcdn%.com/assets/[^"]+%.js)"') do
        local js = GetAsync(src)
        if js then
            local cid = js:match('client_id%s*:%s*"([%w]+)"') or js:match('clientId%s*:%s*"([%w]+)"')
            if cid and #cid > 20 then return cid end
        end
    end
end

local function searchSoundcloud(query)
    if not SC_CLIENT_ID then SC_CLIENT_ID = getSCClientId() end
    if not SC_CLIENT_ID then return nil end
    local sUrl = "https://api-v2.soundcloud.com/search/tracks?q=" .. HttpService:UrlEncode(query) .. "&client_id=" .. SC_CLIENT_ID .. "&limit=20"
    local raw = GetAsync(sUrl)
    if raw then
        local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
        if ok and data and data.collection then return data.collection end
    end
    return nil
end

local function fetchLyrics(artist, title)
    title, artist = HttpService:UrlEncode(title or ""), HttpService:UrlEncode(artist or "")
    local url = "https://lrclib.net/api/search?track_name="..title.."&artist_name="..artist
    local raw = GetAsync(url)
    if raw then
        local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
        if ok and data[1] and data[1].syncedLyrics then return data[1].syncedLyrics end
    end
    return nil
end

local function parseLRC(lrc)
    local lines = {}
    for line in lrc:gmatch("[^\n\r]+") do
        local min, sec, text = line:match("%[(%d+):([%d%.]+)%](.*)")
        if min and sec then
            local t = text:match("^%s*(.-)%s*$")
            if t and t ~= "" then table.insert(lines, {time = tonumber(min)*60 + tonumber(sec), text = t}) end
        end
    end
    table.sort(lines, function(a, b) return a.time < b.time end)
    return lines
end

local C_TEXT, C_TEXT_DIM = Color3.fromRGB(245, 245, 245), Color3.fromRGB(160, 160, 160)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name, ScreenGui.ResetOnSpawn = "RobloxMusicPlayer", false
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui") end

local function makeDraggable(handle, object)
    local dragging, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging, dragStart, startPos = true, input.Position, object.Position
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            object.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UIS.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
end

local MainContainer = Instance.new("Frame", ScreenGui)
MainContainer.Name, MainContainer.Size, MainContainer.Position, MainContainer.BackgroundTransparency = "MainContainer", UDim2.new(0, 310, 0, 480), UDim2.new(0.5, -155, 0.5, -240), 1
makeDraggable(MainContainer, MainContainer)

local MainFrame = Instance.new("Frame", MainContainer)
MainFrame.Name, MainFrame.Size, MainFrame.BackgroundColor3, MainFrame.BorderSizePixel, MainFrame.ClipsDescendants, MainFrame.ZIndex = "MainFrame", UDim2.new(1, 0, 1, 0), Color3.fromRGB(20, 20, 20), 0, true, 5
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 24)

local BgContainer = Instance.new("CanvasGroup", MainFrame)
BgContainer.Size, BgContainer.BackgroundTransparency, BgContainer.ZIndex = UDim2.new(1, 0, 1, 0), 1, 5
Instance.new("UICorner", BgContainer).CornerRadius = UDim.new(0, 24)

local BgImage = Instance.new("ImageLabel", BgContainer)
BgImage.Size, BgImage.Position, BgImage.BackgroundTransparency, BgImage.ImageTransparency, BgImage.ScaleType, BgImage.ZIndex = UDim2.new(2, 0, 2, 0), UDim2.new(-0.5, 0, -0.5, 0), 1, 0.5, Enum.ScaleType.Crop, 5

local BgGradMask = Instance.new("Frame", BgContainer)
BgGradMask.Size, BgGradMask.BackgroundColor3, BgGradMask.BackgroundTransparency, BgGradMask.ZIndex = UDim2.new(1, 0, 1, 0), Color3.fromRGB(20,20,20), 0.2, 6
Instance.new("UICorner", BgGradMask).CornerRadius = UDim.new(0, 24)

local MovingGrad = Instance.new("UIGradient", BgGradMask)
MovingGrad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(30,30,30)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100,100,100)), ColorSequenceKeypoint.new(1, Color3.fromRGB(30,30,30))})
MovingGrad.Rotation = 45
RunService.RenderStepped:Connect(function() MovingGrad.Rotation = (MovingGrad.Rotation + 0.1) % 360 end)

local TopSection = Instance.new("Frame", MainFrame)
TopSection.Size, TopSection.BackgroundTransparency, TopSection.ZIndex = UDim2.new(1, 0, 0, 80), 1, 10

-- [[ Continuation of Source_Final.lua ]] --

local CoverArt = Instance.new("ImageLabel", TopSection)
CoverArt.Size, CoverArt.Position, CoverArt.BackgroundColor3, CoverArt.ZIndex = UDim2.new(0, 64, 0, 64), UDim2.new(0, 16, 0, 12), Color3.fromRGB(30, 30, 30), 12
Instance.new("UICorner", CoverArt).CornerRadius = UDim.new(0, 12)

local TitleContainer = Instance.new("Frame", TopSection)
TitleContainer.Position, TitleContainer.Size, TitleContainer.BackgroundTransparency, TitleContainer.ClipsDescendants, TitleContainer.ZIndex = UDim2.new(0, 92, 0, 20), UDim2.new(1, -110, 0, 22), 1, true, 12

local TitleLabel = Instance.new("TextLabel", TitleContainer)
TitleLabel.Size, TitleLabel.BackgroundTransparency, TitleLabel.Font, TitleLabel.Text, TitleLabel.TextColor3, TitleLabel.TextSize, TitleLabel.TextXAlignment, TitleLabel.AutomaticSize, TitleLabel.ZIndex = UDim2.new(0, 0, 1, 0), 1, Enum.Font.GothamBold, "Not Playing", C_TEXT, 15, Enum.TextXAlignment.Left, Enum.AutomaticSize.X, 13

local ArtistLabel = Instance.new("TextLabel", TopSection)
ArtistLabel.Position, ArtistLabel.Size, ArtistLabel.BackgroundTransparency, ArtistLabel.Font, ArtistLabel.Text, ArtistLabel.TextColor3, ArtistLabel.TextSize, ArtistLabel.TextXAlignment, ArtistLabel.ZIndex = UDim2.new(0, 92, 0, 44), UDim2.new(1, -110, 0, 16), 1, Enum.Font.GothamMedium, "No Artist", C_TEXT_DIM, 13, Enum.TextXAlignment.Left, 12

local BottomSection = Instance.new("Frame", MainFrame)
BottomSection.Size, BottomSection.Position, BottomSection.AnchorPoint, BottomSection.BackgroundTransparency, BottomSection.ZIndex = UDim2.new(1, 0, 0, 150), UDim2.new(0, 0, 1, 0), Vector2.new(0, 1), 1, 10

local ProgressBarBg = Instance.new("Frame", BottomSection)
ProgressBarBg.Name, ProgressBarBg.Size, ProgressBarBg.Position, ProgressBarBg.BackgroundColor3, ProgressBarBg.BackgroundTransparency, ProgressBarBg.ZIndex = "ProgressBarBg", UDim2.new(1, -32, 0, 4), UDim2.new(0, 16, 0, 80), Color3.fromRGB(60, 60, 60), 0.5, 11
Instance.new("UICorner", ProgressBarBg).CornerRadius = UDim.new(0, 2)

local ProgressBarFill = Instance.new("Frame", ProgressBarBg)
ProgressBarFill.Name, ProgressBarFill.Size, ProgressBarFill.BackgroundColor3, ProgressBarFill.ZIndex = "ProgressBarFill", UDim2.new(0, 0, 1, 0), C_TEXT, 12
Instance.new("UICorner", ProgressBarFill).CornerRadius = UDim.new(0, 2)

local activeSound = nil
local function playTrack(entry, index)
    if activeSound then activeSound:Destroy() end
    activeSound = Instance.new("Sound", game:GetService("SoundService"))
    activeSound.SoundId, activeSound.Volume = getcustomasset(entry.audioPath), 1
    activeSound:Play()
    TitleLabel.Text, ArtistLabel.Text = entry.title, entry.artist
    local art = (entry.artPath and isfile(entry.artPath)) and getcustomasset(entry.artPath) or ""
    CoverArt.Image, BgImage.Image = art, art
end

local function renderLibraryUI()
    for _, child in ipairs(LibraryScroll:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    for i, entry in ipairs(myLibrary) do
        local btn = Instance.new("TextButton", LibraryScroll)
        btn.Size, btn.BackgroundTransparency, btn.Text = UDim2.new(1, 0, 0, 45), 1, ""
        btn.MouseButton1Click:Connect(function() playTrack(entry, i) end)
    end
end

renderLibraryUI()

