local ClonedFunctions = {}

do
    local functionsToClone = {
        "pcall", "xpcall", "type", "typeof", "tostring", "tonumber",
        "pairs", "ipairs", "next", "select", "unpack", "rawget", "rawset",
        "rawequal", "rawlen", "setmetatable", "getmetatable", "assert", "error"
    }
    
    for _, name in ipairs(functionsToClone) do
        if getgenv()[name] then
            ClonedFunctions[name] = clonefunction(getgenv()[name])
        end
    end
    
    if not ClonedFunctions.unpack then
        ClonedFunctions.unpack = clonefunction(table.unpack or unpack)
    end
    
    ClonedFunctions.tableClone = clonefunction(table.clone)
    ClonedFunctions.tableInsert = clonefunction(table.insert)
    ClonedFunctions.tableRemove = clonefunction(table.remove)
    ClonedFunctions.tableConcat = clonefunction(table.concat)
    ClonedFunctions.tableFind = clonefunction(table.find)
    ClonedFunctions.tableClear = clonefunction(table.clear)
    ClonedFunctions.tableSort = clonefunction(table.sort)
    
    ClonedFunctions.stringFormat = clonefunction(string.format)
    ClonedFunctions.stringMatch = clonefunction(string.match)
    ClonedFunctions.stringFind = clonefunction(string.find)
    ClonedFunctions.stringGsub = clonefunction(string.gsub)
    ClonedFunctions.stringSub = clonefunction(string.sub)
    ClonedFunctions.stringLower = clonefunction(string.lower)
    ClonedFunctions.stringUpper = clonefunction(string.upper)
    ClonedFunctions.stringLen = clonefunction(string.len)
    ClonedFunctions.stringRep = clonefunction(string.rep)
    ClonedFunctions.stringSplit = clonefunction(string.split)
    ClonedFunctions.stringByte = clonefunction(string.byte)
    
    ClonedFunctions.mathFloor = clonefunction(math.floor)
    ClonedFunctions.mathMax = clonefunction(math.max)
    ClonedFunctions.mathMin = clonefunction(math.min)
    ClonedFunctions.mathAbs = clonefunction(math.abs)
    
    ClonedFunctions.coroutineCreate = clonefunction(coroutine.create)
    ClonedFunctions.coroutineResume = clonefunction(coroutine.resume)
    ClonedFunctions.coroutineYield = clonefunction(coroutine.yield)
    ClonedFunctions.coroutineWrap = clonefunction(coroutine.wrap)
    ClonedFunctions.coroutineRunning = clonefunction(coroutine.running)
    ClonedFunctions.coroutineClose = clonefunction(coroutine.close)
    
    ClonedFunctions.taskSpawn = clonefunction(task.spawn)
    ClonedFunctions.taskDefer = clonefunction(task.defer)
    ClonedFunctions.taskDelay = clonefunction(task.delay)
    ClonedFunctions.taskWait = clonefunction(task.wait)
    ClonedFunctions.taskCancel = clonefunction(task.cancel)
    
    ClonedFunctions.osTime = clonefunction(os.time)
    ClonedFunctions.osDate = clonefunction(os.date)
    ClonedFunctions.osClock = clonefunction(os.clock)
end

local pcall = ClonedFunctions.pcall
local xpcall = ClonedFunctions.xpcall
local type = ClonedFunctions.type
local typeof = ClonedFunctions.typeof
local tostring = ClonedFunctions.tostring
local tonumber = ClonedFunctions.tonumber
local pairs = ClonedFunctions.pairs
local ipairs = ClonedFunctions.ipairs
local next = ClonedFunctions.next
local select = ClonedFunctions.select
local rawget = ClonedFunctions.rawget
local rawset = ClonedFunctions.rawset
local rawequal = ClonedFunctions.rawequal
local setmetatable = ClonedFunctions.setmetatable
local getmetatable = ClonedFunctions.getmetatable
local unpack = ClonedFunctions.unpack

local Globals = getgenv()

local AdonisBypassed = false
local ActorInterceptionEnabled = false

local CacheAPI = {}

function CacheAPI.IsAvailable()
    return cache and cache.invalidate and cache.iscached and cache.replace
end

function CacheAPI.Invalidate(object)
    if not CacheAPI.IsAvailable() then return false end
    local success = pcall(function()
        cache.invalidate(object)
    end)
    return success
end

function CacheAPI.IsCached(object)
    if not CacheAPI.IsAvailable() then return nil end
    local success, result = pcall(function()
        return cache.iscached(object)
    end)
    return success and result or nil
end

function CacheAPI.Replace(object, newObject)
    if not CacheAPI.IsAvailable() then return false end
    local success = pcall(function()
        cache.replace(object, newObject)
    end)
    return success
end

local function PatchAdonisDetections()
    pcall(function()
        for _, v in getgc(true) do
            if type(v) == "table" and rawget(v, "indexInstance") then
                for k, det in pairs(v) do
                    if type(det) == "table" and type(det[2]) == "function" then
                        hookfunction(det[2], newcclosure(function()
                            return false
                        end))
                    end
                end
                AdonisBypassed = true
                break
            end
        end
    end)
end

local sc = cloneref(game:GetService("ScriptContext"))
for _, c in getconnections(sc.Error) do
    c:Disconnect()
end

if Globals.BlatantSpyLoaded then
    if Globals.BlatantSpyInstance then
        pcall(function()
            Globals.BlatantSpyInstance:Destroy()
        end)
    end
end
Globals.BlatantSpyLoaded = true

local RequiredFunctions = {
    "hookmetamethod", "newcclosure", "getgc", "getnilinstances",
    "getcallingscript", "cloneref", "getnamecallmethod", "checkcaller",
    "setclipboard", "clonefunction"
}

local MissingFunctions = {}

for _, funcName in ipairs(RequiredFunctions) do
    local found = false
    if Globals[funcName] or getgenv()[funcName] or getfenv()[funcName] then
        found = true
    end
    if not found and funcName == "getinfo" then
        if debug and debug.getinfo then
            found = true
        end
    end
    if not found and funcName ~= "getnilinstances" then
        ClonedFunctions.tableInsert(MissingFunctions, funcName)
    end
end

local function GetExecutorName()
    local success, name = pcall(function()
        if identifyexecutor then
            return identifyexecutor()
        elseif getexecutorname then
            return getexecutorname()
        end
        return "Unknown"
    end)
    return success and name or "Unknown"
end

if #MissingFunctions > 0 then
    local ErrorGui = Instance.new("ScreenGui")
    ErrorGui.Name = "BlatantSpyError"
    ErrorGui.ResetOnSpawn = false
    ErrorGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 400, 0, 160)
    MainFrame.Position = UDim2.new(0.5, -200, 0.5, -80)
    MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
    MainFrame.BackgroundTransparency = 0.05
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ErrorGui
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = MainFrame
    
    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(200, 50, 50)
    Stroke.Thickness = 1
    Stroke.Transparency = 0.5
    Stroke.Parent = MainFrame
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -30, 0, 30)
    Title.Position = UDim2.new(0, 15, 0, 15)
    Title.BackgroundTransparency = 1
    Title.Text = "BLATANTSPY - COMPATIBILITY ERROR"
    Title.TextColor3 = Color3.fromRGB(200, 50, 50)
    Title.TextSize = 16
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = MainFrame
    
    local Desc = Instance.new("TextLabel")
    Desc.Size = UDim2.new(1, -30, 0, 25)
    Desc.Position = UDim2.new(0, 15, 0, 45)
    Desc.BackgroundTransparency = 1
    Desc.Text = GetExecutorName() .. " does not support required functions:"
    Desc.TextColor3 = Color3.fromRGB(180, 180, 180)
    Desc.TextSize = 14
    Desc.Font = Enum.Font.Gotham
    Desc.TextXAlignment = Enum.TextXAlignment.Left
    Desc.Parent = MainFrame
    
    local Missing = Instance.new("TextLabel")
    Missing.Size = UDim2.new(1, -30, 0, 40)
    Missing.Position = UDim2.new(0, 15, 0, 70)
    Missing.BackgroundTransparency = 1
    Missing.Text = ClonedFunctions.tableConcat(MissingFunctions, ", ")
    Missing.TextColor3 = Color3.fromRGB(120, 120, 120)
    Missing.TextSize = 13
    Missing.Font = Enum.Font.RobotoMono
    Missing.TextXAlignment = Enum.TextXAlignment.Left
    Missing.TextWrapped = true
    Missing.Parent = MainFrame
    
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 80, 0, 28)
    CloseBtn.Position = UDim2.new(0.5, -40, 1, -40)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    CloseBtn.BackgroundTransparency = 0.2
    CloseBtn.Text = "CLOSE"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.TextSize = 13
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Parent = MainFrame
    
    local CloseBtnCorner = Instance.new("UICorner")
    CloseBtnCorner.CornerRadius = UDim.new(0, 4)
    CloseBtnCorner.Parent = CloseBtn
    
    CloseBtn.MouseButton1Click:Connect(function()
        ErrorGui:Destroy()
    end)
    
    if syn and syn.protect_gui then
        syn.protect_gui(ErrorGui)
        ErrorGui.Parent = cloneref(game:GetService("CoreGui"))
    elseif gethui then
        ErrorGui.Parent = gethui()
    else
        ErrorGui.Parent = cloneref(game:GetService("CoreGui"))
    end
    
    return
end

local GameRef = cloneref(game)
local Services = {}
do
    local serviceNames = {
        "Players", "TweenService", "UserInputService", 
        "RunService", "HttpService", "CoreGui", "ReplicatedStorage"
    }
    for _, name in ipairs(serviceNames) do
        local success, service = pcall(function()
            return cloneref(GameRef:GetService(name))
        end)
        if success then
            Services[name] = service
        end
    end
end

local LocalPlayer = Services.Players.LocalPlayer

local function ShowAdonisPrompt(callback)
    local PromptGui = Instance.new("ScreenGui")
    PromptGui.Name = "BlatantSpyAdonisPrompt"
    PromptGui.ResetOnSpawn = false
    PromptGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    PromptGui.DisplayOrder = 9999
    
    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 350, 0, 140)
    MainFrame.Position = UDim2.new(0.5, -175, 0.5, -70)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
    MainFrame.BackgroundTransparency = 0.05
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = PromptGui
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = MainFrame
    
    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(0, 122, 204)
    Stroke.Thickness = 1
    Stroke.Transparency = 0.5
    Stroke.Parent = MainFrame
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -20, 0, 30)
    Title.Position = UDim2.new(0, 10, 0, 15)
    Title.BackgroundTransparency = 1
    Title.Text = "BLATANTSPY"
    Title.TextColor3 = Color3.fromRGB(0, 122, 204)
    Title.TextSize = 18
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Center
    Title.Parent = MainFrame
    
    local Question = Instance.new("TextLabel")
    Question.Size = UDim2.new(1, -20, 0, 25)
    Question.Position = UDim2.new(0, 10, 0, 50)
    Question.BackgroundTransparency = 1
    Question.Text = "Patch AdonisDetections?"
    Question.TextColor3 = Color3.fromRGB(220, 220, 220)
    Question.TextSize = 16
    Question.Font = Enum.Font.Gotham
    Question.TextXAlignment = Enum.TextXAlignment.Center
    Question.Parent = MainFrame
    
    local ButtonContainer = Instance.new("Frame")
    ButtonContainer.Size = UDim2.new(1, -40, 0, 36)
    ButtonContainer.Position = UDim2.new(0, 20, 0, 90)
    ButtonContainer.BackgroundTransparency = 1
    ButtonContainer.Parent = MainFrame
    
    local YesBtn = Instance.new("TextButton")
    YesBtn.Size = UDim2.new(0, 120, 0, 36)
    YesBtn.Position = UDim2.new(0, 0, 0, 0)
    YesBtn.BackgroundColor3 = Color3.fromRGB(87, 181, 106)
    YesBtn.BackgroundTransparency = 0.2
    YesBtn.Text = "YES"
    YesBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    YesBtn.TextSize = 14
    YesBtn.Font = Enum.Font.GothamBold
    YesBtn.BorderSizePixel = 0
    YesBtn.Parent = ButtonContainer
    
    local YesBtnCorner = Instance.new("UICorner")
    YesBtnCorner.CornerRadius = UDim.new(0, 6)
    YesBtnCorner.Parent = YesBtn
    
    local NoBtn = Instance.new("TextButton")
    NoBtn.Size = UDim2.new(0, 120, 0, 36)
    NoBtn.Position = UDim2.new(1, -120, 0, 0)
    NoBtn.BackgroundColor3 = Color3.fromRGB(219, 75, 75)
    NoBtn.BackgroundTransparency = 0.2
    NoBtn.Text = "NO"
    NoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    NoBtn.TextSize = 14
    NoBtn.Font = Enum.Font.GothamBold
    NoBtn.BorderSizePixel = 0
    NoBtn.Parent = ButtonContainer
    
    local NoBtnCorner = Instance.new("UICorner")
    NoBtnCorner.CornerRadius = UDim.new(0, 6)
    NoBtnCorner.Parent = NoBtn
    
    if syn and syn.protect_gui then
        syn.protect_gui(PromptGui)
        PromptGui.Parent = cloneref(game:GetService("CoreGui"))
    elseif gethui then
        PromptGui.Parent = gethui()
    else
        PromptGui.Parent = cloneref(game:GetService("CoreGui"))
    end
    
    YesBtn.MouseButton1Click:Connect(function()
        PromptGui:Destroy()
        PatchAdonisDetections()
        callback()
    end)
    
    NoBtn.MouseButton1Click:Connect(function()
        PromptGui:Destroy()
        callback()
    end)
end

local function ShowActorPrompt(callback)
    if not getactors then
        callback(false)
        return
    end
    
    local actors = {}
    pcall(function()
        actors = getactors()
    end)
    
    if #actors == 0 then
        callback(false)
        return
    end
    
    local PromptGui = Instance.new("ScreenGui")
    PromptGui.Name = "BlatantSpyActorPrompt"
    PromptGui.ResetOnSpawn = false
    PromptGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    PromptGui.DisplayOrder = 9999
    
    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 400, 0, 160)
    MainFrame.Position = UDim2.new(0.5, -200, 0.5, -80)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
    MainFrame.BackgroundTransparency = 0.05
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = PromptGui
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = MainFrame
    
    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(255, 165, 0)
    Stroke.Thickness = 1
    Stroke.Transparency = 0.5
    Stroke.Parent = MainFrame
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -20, 0, 30)
    Title.Position = UDim2.new(0, 10, 0, 15)
    Title.BackgroundTransparency = 1
    Title.Text = "BLATANTSPY - ACTOR DETECTED"
    Title.TextColor3 = Color3.fromRGB(255, 165, 0)
    Title.TextSize = 18
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Center
    Title.Parent = MainFrame
    
    local Question = Instance.new("TextLabel")
    Question.Size = UDim2.new(1, -20, 0, 25)
    Question.Position = UDim2.new(0, 10, 0, 50)
    Question.BackgroundTransparency = 1
    Question.Text = "Intercept Actor-Based events? (" .. #actors .. " actors found)"
    Question.TextColor3 = Color3.fromRGB(220, 220, 220)
    Question.TextSize = 15
    Question.Font = Enum.Font.Gotham
    Question.TextXAlignment = Enum.TextXAlignment.Center
    Question.Parent = MainFrame
    
    local SubText = Instance.new("TextLabel")
    SubText.Size = UDim2.new(1, -20, 0, 20)
    SubText.Position = UDim2.new(0, 10, 0, 72)
    SubText.BackgroundTransparency = 1
    SubText.Text = "Actor events will be marked with [ActorCall] prefix"
    SubText.TextColor3 = Color3.fromRGB(150, 150, 150)
    SubText.TextSize = 12
    SubText.Font = Enum.Font.Gotham
    SubText.TextXAlignment = Enum.TextXAlignment.Center
    SubText.Parent = MainFrame
    
    local ButtonContainer = Instance.new("Frame")
    ButtonContainer.Size = UDim2.new(1, -40, 0, 36)
    ButtonContainer.Position = UDim2.new(0, 20, 0, 105)
    ButtonContainer.BackgroundTransparency = 1
    ButtonContainer.Parent = MainFrame
    
    local YesBtn = Instance.new("TextButton")
    YesBtn.Size = UDim2.new(0, 140, 0, 36)
    YesBtn.Position = UDim2.new(0, 0, 0, 0)
    YesBtn.BackgroundColor3 = Color3.fromRGB(87, 181, 106)
    YesBtn.BackgroundTransparency = 0.2
    YesBtn.Text = "YES"
    YesBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    YesBtn.TextSize = 14
    YesBtn.Font = Enum.Font.GothamBold
    YesBtn.BorderSizePixel = 0
    YesBtn.Parent = ButtonContainer
    
    local YesBtnCorner = Instance.new("UICorner")
    YesBtnCorner.CornerRadius = UDim.new(0, 6)
    YesBtnCorner.Parent = YesBtn
    
    local NoBtn = Instance.new("TextButton")
    NoBtn.Size = UDim2.new(0, 140, 0, 36)
    NoBtn.Position = UDim2.new(1, -140, 0, 0)
    NoBtn.BackgroundColor3 = Color3.fromRGB(219, 75, 75)
    NoBtn.BackgroundTransparency = 0.2
    NoBtn.Text = "NO"
    NoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    NoBtn.TextSize = 14
    NoBtn.Font = Enum.Font.GothamBold
    NoBtn.BorderSizePixel = 0
    NoBtn.Parent = ButtonContainer
    
    local NoBtnCorner = Instance.new("UICorner")
    NoBtnCorner.CornerRadius = UDim.new(0, 6)
    NoBtnCorner.Parent = NoBtn
    
    if syn and syn.protect_gui then
        syn.protect_gui(PromptGui)
        PromptGui.Parent = cloneref(game:GetService("CoreGui"))
    elseif gethui then
        PromptGui.Parent = gethui()
    else
        PromptGui.Parent = cloneref(game:GetService("CoreGui"))
    end
    
    YesBtn.MouseButton1Click:Connect(function()
        PromptGui:Destroy()
        ActorInterceptionEnabled = true
        callback(true)
    end)
    
    NoBtn.MouseButton1Click:Connect(function()
        PromptGui:Destroy()
        callback(false)
    end)
end

local Theme = {
    Primary = Color3.fromRGB(30, 30, 30),
    Secondary = Color3.fromRGB(37, 37, 38),
    Tertiary = Color3.fromRGB(45, 45, 45),
    Quaternary = Color3.fromRGB(50, 50, 50),
    
    Accent = Color3.fromRGB(0, 122, 204),
    AccentDark = Color3.fromRGB(0, 100, 180),
    
    Text = Color3.fromRGB(240, 240, 240),
    TextDim = Color3.fromRGB(180, 180, 180),
    TextMuted = Color3.fromRGB(120, 120, 120),
    
    Success = Color3.fromRGB(87, 181, 106),
    Warning = Color3.fromRGB(220, 160, 40),
    Error = Color3.fromRGB(219, 75, 75),
    
    RemoteEvent = Color3.fromRGB(214, 157, 133),
    RemoteFunction = Color3.fromRGB(78, 201, 176),
    BindableEvent = Color3.fromRGB(181, 206, 168),
    BindableFunction = Color3.fromRGB(206, 145, 120),
    UnreliableRemote = Color3.fromRGB(220, 220, 170),
    IncomingEvent = Color3.fromRGB(197, 134, 192),
    ActorCall = Color3.fromRGB(255, 165, 0),
    
    Transparency = 0.05,
    TransparencyLight = 0.1,
    
    CornerSmall = UDim.new(0, 4),
    CornerMedium = UDim.new(0, 6),
    CornerLarge = UDim.new(0, 8)
}

local Utils = {}

function Utils.ToHex(color)
    local r = math.floor(color.R * 255)
    local g = math.floor(color.G * 255)
    local b = math.floor(color.B * 255)
    return string.format("#%02X%02X%02X", r, g, b)
end

function Utils.HighlightLua(code)
    code = code:gsub("&", "&amp;")
    code = code:gsub("<", "&lt;")
    code = code:gsub(">", "&gt;")

    local patterns = {
        {Pattern = "%-%-[^\n]*", Color = "#6A9955"},
        {Pattern = "\"[^\"]*\"", Color = "#CE9178"},
        {Pattern = "'[^']*'", Color = "#CE9178"},
        {Pattern = "%[%[.*%]%]", Color = "#CE9178"},
        {Pattern = "%f[%w]local%f[%W]", Color = "#569CD6"},
        {Pattern = "%f[%w]function%f[%W]", Color = "#569CD6"},
        {Pattern = "%f[%w]end%f[%W]", Color = "#569CD6"},
        {Pattern = "%f[%w]if%f[%W]", Color = "#C586C0"},
        {Pattern = "%f[%w]then%f[%W]", Color = "#C586C0"},
        {Pattern = "%f[%w]else%f[%W]", Color = "#C586C0"},
        {Pattern = "%f[%w]elseif%f[%W]", Color = "#C586C0"},
        {Pattern = "%f[%w]return%f[%W]", Color = "#C586C0"},
        {Pattern = "%f[%w]do%f[%W]", Color = "#C586C0"},
        {Pattern = "%f[%w]while%f[%W]", Color = "#C586C0"},
        {Pattern = "%f[%w]for%f[%W]", Color = "#C586C0"},
        {Pattern = "%f[%w]in%f[%W]", Color = "#C586C0"},
        {Pattern = "%f[%w]repeat%f[%W]", Color = "#C586C0"},
        {Pattern = "%f[%w]until%f[%W]", Color = "#C586C0"},
        {Pattern = "%f[%w]break%f[%W]", Color = "#C586C0"},
        {Pattern = "%f[%w]true%f[%W]", Color = "#569CD6"},
        {Pattern = "%f[%w]false%f[%W]", Color = "#569CD6"},
        {Pattern = "%f[%w]nil%f[%W]", Color = "#569CD6"},
        {Pattern = "%f[%w]and%f[%W]", Color = "#569CD6"},
        {Pattern = "%f[%w]or%f[%W]", Color = "#569CD6"},
        {Pattern = "%f[%w]not%f[%W]", Color = "#569CD6"},
        {Pattern = "%f[%d]%d[%d%.]*", Color = "#B5CEA8"},
        {Pattern = "%f[%w][%a_][%w_]*%s*%(", Color = "#DCDCAA", Offset = 1}
    }

    local replacements = {}
    
    local function addReplacement(startPos, endPos, color, text)
        table.insert(replacements, {s = startPos, e = endPos, c = color, t = text})
    end

    for _, p in ipairs(patterns) do
        local offset = p.Offset or 0
        local pat = p.Pattern
        
        local currentIdx = 1
        while true do
            local s, e = string.find(code, pat, currentIdx)
            if not s then break end
            
            local captured = string.sub(code, s, e - offset)
            addReplacement(s, e - offset, p.Color, captured)
            
            currentIdx = s + 1
        end
    end
    
    table.sort(replacements, function(a, b) return a.s < b.s end)
    
    local result = {}
    local lastPos = 1
    
    for _, r in ipairs(replacements) do
        if r.s >= lastPos then
            if r.s > lastPos then
                table.insert(result, string.sub(code, lastPos, r.s - 1))
            end
            table.insert(result, '<font color="' .. r.c .. '">' .. r.t .. '</font>')
            lastPos = r.e + 1
        end
    end
    
    if lastPos <= #code then
        table.insert(result, string.sub(code, lastPos))
    end
    
    return table.concat(result)
end

function Utils.SafeSet(instance, property, value)
    pcall(function()
        instance[property] = value
    end)
end

function Utils.Create(className, props)
    local success, instance = pcall(function()
        return Instance.new(className)
    end)
    if not success or not instance then
        return nil
    end
    
    local parent = props.Parent
    props.Parent = nil
    
    local text = props.Text
    props.Text = nil
    
    if props.RichText ~= nil then
        pcall(function()
            instance.RichText = props.RichText
        end)
        props.RichText = nil
    end
    
    for prop, value in pairs(props) do
        pcall(function()
            instance[prop] = value
        end)
    end
    
    if text ~= nil then
        pcall(function()
            instance.Text = text
        end)
    end
    
    if parent then
        pcall(function()
            instance.Parent = parent
        end)
    end
    
    return instance
end

function Utils.Corner(parent, radius)
    if not parent then return nil end
    return Utils.Create("UICorner", {
        CornerRadius = radius or Theme.CornerMedium,
        Parent = parent
    })
end

function Utils.Stroke(parent, color, thickness, transparency)
    if not parent then return nil end
    return Utils.Create("UIStroke", {
        Color = color or Theme.Accent,
        Thickness = thickness or 1,
        Transparency = transparency or 0.7,
        Parent = parent
    })
end

function Utils.Padding(parent, padding)
    if not parent then return nil end
    return Utils.Create("UIPadding", {
        PaddingTop = UDim.new(0, padding),
        PaddingBottom = UDim.new(0, padding),
        PaddingLeft = UDim.new(0, padding),
        PaddingRight = UDim.new(0, padding),
        Parent = parent
    })
end

function Utils.Tween(instance, props, duration, style, direction)
    if not instance then return nil end
    local success, tween = pcall(function()
        return Services.TweenService:Create(
            instance,
            TweenInfo.new(
                duration or 0.2,
                style or Enum.EasingStyle.Quad,
                direction or Enum.EasingDirection.Out
            ),
            props
        )
    end)
    if success and tween then
        pcall(function()
            tween:Play()
        end)
        return tween
    end
    return nil
end

function Utils.GetPath(instance)
    if not instance then return "nil" end
    
    local function IsGame(obj)
        return obj == game or (pcall(function() return obj.ClassName end) and obj.ClassName == "DataModel")
    end
    
    if IsGame(instance) then return "game" end
    
    local parts = {}
    local current = instance
    local service = nil
    
    while current do
        local parent = nil
        pcall(function() parent = current.Parent end)
        
        if parent and IsGame(parent) then
            service = current
            break
        end
        
        if not parent then break end
        
        local name = current.Name
        if ClonedFunctions.stringMatch(name, "^[%a_][%w_]*$") then
            ClonedFunctions.tableInsert(parts, 1, "." .. name)
        else
            local escaped = ClonedFunctions.stringGsub(name, '"', '\\"')
            ClonedFunctions.tableInsert(parts, 1, '["' .. escaped .. '"]')
        end
        
        current = parent
    end
    
    if service then
        return 'game:GetService("' .. service.ClassName .. '")' .. ClonedFunctions.tableConcat(parts, "")
    elseif #parts > 0 and current then
        return current.Name .. ClonedFunctions.tableConcat(parts, "")
    else
        return instance.Name or "nil"
    end
end

function Utils.Serialize(value, depth, visited)
    depth = depth or 0
    visited = visited or {}
    
    if depth > 10 then
        return '"[MAX_DEPTH]"'
    end
    
    local valueType = typeof(value)
    
    if valueType == "nil" then
        return "nil"
        
    elseif valueType == "string" then
        local escaped = value
        escaped = ClonedFunctions.stringGsub(escaped, '\\', '\\\\')
        escaped = ClonedFunctions.stringGsub(escaped, '"', '\\"')
        escaped = ClonedFunctions.stringGsub(escaped, '\n', '\\n')
        escaped = ClonedFunctions.stringGsub(escaped, '\r', '\\r')
        escaped = ClonedFunctions.stringGsub(escaped, '\t', '\\t')
        return '"' .. escaped .. '"'
        
    elseif valueType == "number" then
        if value == math.huge then return "math.huge" end
        if value == -math.huge then return "-math.huge" end
        if value ~= value then return "0/0" end
        return tostring(value)
        
    elseif valueType == "boolean" then
        return tostring(value)
        
    elseif valueType == "Instance" then
        return Utils.GetPath(value)
        
    elseif valueType == "Vector3" then
        return ClonedFunctions.stringFormat("Vector3.new(%s, %s, %s)", tostring(value.X), tostring(value.Y), tostring(value.Z))
        
    elseif valueType == "Vector2" then
        return ClonedFunctions.stringFormat("Vector2.new(%s, %s)", tostring(value.X), tostring(value.Y))
        
    elseif valueType == "CFrame" then
        local c = {value:GetComponents()}
        local parts = {}
        for _, v in ipairs(c) do
            ClonedFunctions.tableInsert(parts, tostring(v))
        end
        return "CFrame.new(" .. ClonedFunctions.tableConcat(parts, ", ") .. ")"
        
    elseif valueType == "Color3" then
        return ClonedFunctions.stringFormat("Color3.new(%s, %s, %s)", tostring(value.R), tostring(value.G), tostring(value.B))
        
    elseif valueType == "BrickColor" then
        return 'BrickColor.new("' .. tostring(value) .. '")'
        
    elseif valueType == "UDim" then
        return ClonedFunctions.stringFormat("UDim.new(%s, %s)", tostring(value.Scale), tostring(value.Offset))
        
    elseif valueType == "UDim2" then
        return ClonedFunctions.stringFormat(
            "UDim2.new(%s, %s, %s, %s)",
            tostring(value.X.Scale), tostring(value.X.Offset), tostring(value.Y.Scale), tostring(value.Y.Offset)
        )
        
    elseif valueType == "Ray" then
        return ClonedFunctions.stringFormat(
            "Ray.new(%s, %s)",
            Utils.Serialize(value.Origin, depth + 1, visited),
            Utils.Serialize(value.Direction, depth + 1, visited)
        )
        
    elseif valueType == "Rect" then
        return ClonedFunctions.stringFormat(
            "Rect.new(%s, %s, %s, %s)",
            tostring(value.Min.X), tostring(value.Min.Y), tostring(value.Max.X), tostring(value.Max.Y)
        )
        
    elseif valueType == "NumberSequence" then
        local kps = {}
        for _, kp in ipairs(value.Keypoints) do
            ClonedFunctions.tableInsert(kps, ClonedFunctions.stringFormat(
                "NumberSequenceKeypoint.new(%s, %s, %s)",
                tostring(kp.Time), tostring(kp.Value), tostring(kp.Envelope)
            ))
        end
        return "NumberSequence.new({" .. ClonedFunctions.tableConcat(kps, ", ") .. "})"
        
    elseif valueType == "ColorSequence" then
        local kps = {}
        for _, kp in ipairs(value.Keypoints) do
            ClonedFunctions.tableInsert(kps, ClonedFunctions.stringFormat(
                "ColorSequenceKeypoint.new(%s, %s)",
                tostring(kp.Time), Utils.Serialize(kp.Value, depth + 1, visited)
            ))
        end
        return "ColorSequence.new({" .. ClonedFunctions.tableConcat(kps, ", ") .. "})"
        
    elseif valueType == "EnumItem" then
        return tostring(value)
        
    elseif valueType == "table" then
        if visited[value] then return '"[Cyclic Reference]"' end
        visited[value] = true
        
        local isArray = true
        local count = 0
        for k, _ in pairs(value) do
            count = count + 1
            if type(k) ~= "number" or k < 1 or k ~= ClonedFunctions.mathFloor(k) then
                isArray = false
            end
        end
        
        if isArray and count ~= #value then isArray = false end
        if count == 0 then return "{}" end
        
        local parts = {}
        local indent = ClonedFunctions.stringRep("    ", depth + 1)
        local closeIndent = ClonedFunctions.stringRep("    ", depth)
        
        if isArray then
            for _, v in ipairs(value) do
                ClonedFunctions.tableInsert(parts, indent .. Utils.Serialize(v, depth + 1, visited))
            end
        else
            local keys = {}
            for k in pairs(value) do ClonedFunctions.tableInsert(keys, k) end
            pcall(function() ClonedFunctions.tableSort(keys, function(a, b) return tostring(a) < tostring(b) end) end)
            
            for _, k in ipairs(keys) do
                local v = value[k]
                local keyStr = (type(k) == "string" and ClonedFunctions.stringMatch(k, "^[%a_][%w_]*$")) 
                    and (k .. " = ") 
                    or ("[" .. Utils.Serialize(k, depth + 1, visited) .. "] = ")
                ClonedFunctions.tableInsert(parts, indent .. keyStr .. Utils.Serialize(v, depth + 1, visited))
            end
        end
        
        visited[value] = nil
        return "{\n" .. ClonedFunctions.tableConcat(parts, ",\n") .. "\n" .. closeIndent .. "}"
        
    elseif valueType == "function" then
        local name = "anonymous"
        local source = "unknown"
        local line = 0
        pcall(function()
            if debug and debug.getinfo then
                local info = debug.getinfo(value)
                if info then
                    name = info.name or name
                    source = info.source or source
                    line = info.currentline or line
                end
            end
        end)
        return ClonedFunctions.stringFormat('function() --[[ Name: %s | Source: %s:%d ]] end', name, source, line)
        
    elseif valueType == "userdata" then
        return '"[userdata]"'
        
    elseif valueType == "thread" then
        local status = "unknown"
        pcall(function() status = coroutine.status(value) end)
        return ClonedFunctions.stringFormat('coroutine.create(function() --[[ Status: %s ]] end)', status)
        
    elseif valueType == "buffer" then
        local size = buffer.len(value)
        if size == 0 then return "buffer.create(0)" end
        
        local parts = {}
        for i = 0, size - 1 do
            local b = buffer.readu8(value, i)
            if b >= 32 and b <= 126 and b ~= 34 and b ~= 92 then
                ClonedFunctions.tableInsert(parts, string.char(b))
            else
                ClonedFunctions.tableInsert(parts, ClonedFunctions.stringFormat("\\x%02X", b))
            end
        end
        
        return 'buffer.fromstring("' .. ClonedFunctions.tableConcat(parts) .. '")'
    end
    
    return '"[' .. valueType .. ']"'
end

function Utils.GenerateScript(remoteType, remotePath, args)
    local serializedArgs = {}
    for _, arg in ipairs(args) do
        ClonedFunctions.tableInsert(serializedArgs, Utils.Serialize(arg))
    end
    
    local argsStr = ClonedFunctions.tableConcat(serializedArgs, ", ")
    
    local methods = {
        RemoteEvent = ":FireServer",
        RemoteFunction = ":InvokeServer",
        BindableEvent = ":Fire",
        BindableFunction = ":Invoke",
        UnreliableRemoteEvent = ":FireServer",
        OnClientEvent = "[OnClientEvent]",
        ActorCall_RemoteEvent = ":FireServer",
        ActorCall_RemoteFunction = ":InvokeServer",
        ActorCall_BindableEvent = ":Fire",
        ActorCall_BindableFunction = ":Invoke",
        ActorCall_UnreliableRemoteEvent = ":FireServer"
    }
    
    local method = methods[remoteType] or ":FireServer"
    
    if remoteType == "OnClientEvent" then
        return remotePath .. ".OnClientEvent:Connect(function(" .. argsStr .. ") end)"
    end
    
    if ClonedFunctions.stringFind(remoteType, "ActorCall_", 1, true) then
        return remotePath .. method .. "(" .. argsStr .. ")"
    end
    
    return remotePath .. method .. "(" .. argsStr .. ")"
end

function Utils.GetCallerInfo(level)
    local info = {
        Source = "[Unknown]",
        Name = "[Anonymous]",
        Line = 0,
        FunctionType = "Unknown",
        ScriptPath = "[Unknown]",
        ScriptInstance = nil,
        Arity = 0,
        IsVararg = false,
        CurrentLine = 0,
        NumUpvalues = 0,
        NumParams = 0
    }
    
    level = level or 4
    
    pcall(function()
        local script = getcallingscript()
        if script and typeof(script) == "Instance" then
            info.ScriptInstance = script
            info.ScriptPath = Utils.GetPath(script)
            info.Source = script:GetFullName()
        end
    end)

    pcall(function()
        if debug and debug.getinfo then
             local dinfo = debug.getinfo(level)
             if dinfo then
                 info.Name = dinfo.name or info.Name
                 info.Source = dinfo.source or info.Source
                 info.Line = dinfo.currentline or info.Line
                 info.NumParams = dinfo.nparams or 0
                 info.IsVararg = dinfo.isvararg and true or false
                 info.FunctionType = dinfo.what or "Unknown"
             end
        end
    end)
    
    if not info.ScriptInstance and getnilinstances and info.Source ~= "[Unknown]" then
        pcall(function()
            local nilInst = getnilinstances()
            for _, v in ipairs(nilInst) do
                if v:IsA("LocalScript") or v:IsA("ModuleScript") then
                    if v.Name == info.Name or ClonedFunctions.stringFind(info.Source, v.Name) then
                         info.ScriptInstance = v
                         info.ScriptPath = "[Nil] " .. v:GetFullName()
                         break
                    end
                end
            end
        end)
    end
    
    pcall(function()
        info.StackTrace = {}
        for i = 1, 10 do
            if debug and debug.getinfo then
                 local f = debug.getinfo(level + i)
                 if f then
                     ClonedFunctions.tableInsert(info.StackTrace, {
                         Source = f.source or "?",
                         Name = f.name or "?",
                         Line = f.currentline or 0
                     })
                 end
            end
        end
    end)
    
    return info
end

local LogEntry = {}
LogEntry.__index = LogEntry

function LogEntry.new(data)
    local self = setmetatable({}, LogEntry)
    
    self.Id = data.Id or 0
    self.Remote = data.Remote
    self.RemoteType = data.RemoteType or "Unknown"
    self.RemotePath = data.RemotePath or "Unknown"
    self.Arguments = data.Arguments or {}
    self.CallerInfo = data.CallerInfo or {}
    self.HookType = data.HookType or "__namecall"
    self.Method = data.Method or "Unknown"
    self.Blocked = data.Blocked or false
    self.ActorScript = data.ActorScript or nil
    
    return self
end

function LogEntry:GetColor()
    local colors = {
        RemoteEvent = Theme.RemoteEvent,
        RemoteFunction = Theme.RemoteFunction,
        BindableEvent = Theme.BindableEvent,
        BindableFunction = Theme.BindableFunction,
        UnreliableRemoteEvent = Theme.UnreliableRemote,
        OnClientEvent = Theme.IncomingEvent,
        ActorCall_RemoteEvent = Theme.ActorCall,
        ActorCall_RemoteFunction = Theme.ActorCall,
        ActorCall_BindableEvent = Theme.ActorCall,
        ActorCall_BindableFunction = Theme.ActorCall,
        ActorCall_UnreliableRemoteEvent = Theme.ActorCall
    }
    return colors[self.RemoteType] or Theme.Accent
end

function LogEntry:GetTypeShort()
    local shorts = {
        RemoteEvent = "RE",
        RemoteFunction = "RF",
        BindableEvent = "BE",
        BindableFunction = "BF",
        UnreliableRemoteEvent = "URE",
        OnClientEvent = "IN",
        ActorCall_RemoteEvent = "ACT",
        ActorCall_RemoteFunction = "ACT",
        ActorCall_BindableEvent = "ACT",
        ActorCall_BindableFunction = "ACT",
        ActorCall_UnreliableRemoteEvent = "ACT"
    }
    return shorts[self.RemoteType] or "?"
end

function LogEntry:GetScript()
    return Utils.GenerateScript(self.RemoteType, self.RemotePath, self.Arguments)
end

function LogEntry:GetDetailedInfo()
    local lines = {}
    local H = Utils.ToHex
    
    local function Escape(text)
        text = ClonedFunctions.stringGsub(tostring(text), "&", "&amp;")
        text = ClonedFunctions.stringGsub(text, "<", "&lt;")
        text = ClonedFunctions.stringGsub(text, ">", "&gt;")
        return text
    end
    
    local function Header(text)
        return '<font color="' .. H(Theme.Accent) .. '"><b>' .. Escape(text) .. '</b></font>'
    end
    
    local function Key(text)
        return '<font color="' .. H(Theme.TextDim) .. '">' .. Escape(text) .. '</font>'
    end
    
    local function Value(text)
        return '<font color="' .. H(Theme.Text) .. '">' .. Escape(text) .. '</font>'
    end

    ClonedFunctions.tableInsert(lines, Header("REMOTE INFORMATION"))
    ClonedFunctions.tableInsert(lines, Key("Type: ") .. Value(self.RemoteType))
    ClonedFunctions.tableInsert(lines, Key("Name: ") .. Value(self.Remote.Name))
    ClonedFunctions.tableInsert(lines, Key("Path: ") .. Value(self.RemotePath))
    ClonedFunctions.tableInsert(lines, Key("Hook: ") .. Value(self.HookType))
    ClonedFunctions.tableInsert(lines, Key("Method: ") .. Value(self.Method))
    
    local blockedStatus = self.Blocked and "TRUE" or "false"
    local blockedColor = self.Blocked and Theme.Error or Theme.Text
    ClonedFunctions.tableInsert(lines, Key("Blocked: ") .. '<font color="' .. H(blockedColor) .. '">' .. blockedStatus .. '</font>')
    
    if CacheAPI.IsAvailable() then
        local isCached = CacheAPI.IsCached(self.Remote)
        if isCached ~= nil then
            ClonedFunctions.tableInsert(lines, Key("Cached: ") .. Value(tostring(isCached)))
        end
    end
    
    ClonedFunctions.tableInsert(lines, "")
    
    ClonedFunctions.tableInsert(lines, Header("CALLER INFORMATION"))
    if self.RemoteType == "OnClientEvent" then
        ClonedFunctions.tableInsert(lines, Value("Source: Server (Incoming Network)"))
    elseif ClonedFunctions.stringFind(self.RemoteType, "ActorCall_", 1, true) then
        ClonedFunctions.tableInsert(lines, Value("Source: Actor Thread (Parallel Execution)"))
        ClonedFunctions.tableInsert(lines, Key("[s] Actor Script: ") .. Value(self.CallerInfo.Source or "[Unknown]"))
        if self.ActorScript then
            ClonedFunctions.tableInsert(lines, Key("[s] Actor Script Path: ") .. Value(Utils.GetPath(self.ActorScript)))
        end
    else
        ClonedFunctions.tableInsert(lines, Key("[s] Source: ") .. Value(self.CallerInfo.Source or "[Unknown]"))
        ClonedFunctions.tableInsert(lines, Key("[s] Script Path: ") .. Value(self.CallerInfo.ScriptPath or "[Unknown]"))
        ClonedFunctions.tableInsert(lines, Key("[n] Function Name: ") .. Value(self.CallerInfo.Name or "[Anonymous]"))
        ClonedFunctions.tableInsert(lines, Key("[l] Line: ") .. Value(tostring(self.CallerInfo.Line or 0)))
        ClonedFunctions.tableInsert(lines, Key("[f] Function Type: ") .. Value(self.CallerInfo.FunctionType or "Unknown"))
        ClonedFunctions.tableInsert(lines, Key("[a] Arity: ") .. Value(tostring(self.CallerInfo.NumParams or 0)))
        ClonedFunctions.tableInsert(lines, Key("[a] Is Vararg: ") .. Value(tostring(self.CallerInfo.IsVararg or false)))
        ClonedFunctions.tableInsert(lines, "")
        
        if self.CallerInfo.StackTrace and #self.CallerInfo.StackTrace > 0 then
            ClonedFunctions.tableInsert(lines, Header("STACK TRACE"))
            for i, frame in ipairs(self.CallerInfo.StackTrace) do
                local frameLine = Key("[" .. i .. "] ") .. Value((frame.Source or "?") .. " : " .. (frame.Name or "?") .. " @ line " .. (frame.Line or 0))
                ClonedFunctions.tableInsert(lines, frameLine)
            end
            ClonedFunctions.tableInsert(lines, "")
        end
    end
    
    ClonedFunctions.tableInsert(lines, Header("ARGUMENTS (" .. #self.Arguments .. ")"))
    
    if #self.Arguments == 0 then
        ClonedFunctions.tableInsert(lines, Value("(no arguments)"))
    else
        for i, arg in ipairs(self.Arguments) do
            local argType = typeof(arg)
            local argValue = Utils.Serialize(arg)
            
            ClonedFunctions.tableInsert(lines, Key("[" .. i .. "] &lt;" .. argType .. "&gt;"))
            ClonedFunctions.tableInsert(lines, "    " .. Value(argValue))
        end
    end
    
    ClonedFunctions.tableInsert(lines, "")
    ClonedFunctions.tableInsert(lines, Header("GENERATED SCRIPT"))
    
    local script = self:GetScript()
    
    ClonedFunctions.tableInsert(lines, '<font face="RobotoMono">' .. Value(script) .. '</font>')
    
    return ClonedFunctions.tableConcat(lines, "<br/>")
end

function LogEntry:GetDetailedInfoPlain()
    local lines = {}
    
    ClonedFunctions.tableInsert(lines, "=== REMOTE INFORMATION ===")
    ClonedFunctions.tableInsert(lines, "Type: " .. self.RemoteType)
    ClonedFunctions.tableInsert(lines, "Name: " .. self.Remote.Name)
    ClonedFunctions.tableInsert(lines, "Path: " .. self.RemotePath)
    ClonedFunctions.tableInsert(lines, "Hook: " .. self.HookType)
    ClonedFunctions.tableInsert(lines, "Method: " .. self.Method)
    ClonedFunctions.tableInsert(lines, "Blocked: " .. (self.Blocked and "TRUE" or "false"))
    
    if CacheAPI.IsAvailable() then
        local isCached = CacheAPI.IsCached(self.Remote)
        if isCached ~= nil then
            ClonedFunctions.tableInsert(lines, "Cached: " .. tostring(isCached))
        end
    end
    
    ClonedFunctions.tableInsert(lines, "")
    
    ClonedFunctions.tableInsert(lines, "=== CALLER INFORMATION ===")
    if self.RemoteType == "OnClientEvent" then
        ClonedFunctions.tableInsert(lines, "Source: Server (Incoming Network)")
    elseif ClonedFunctions.stringFind(self.RemoteType, "ActorCall_", 1, true) then
        ClonedFunctions.tableInsert(lines, "Source: Actor Thread (Parallel Execution)")
        ClonedFunctions.tableInsert(lines, "[s] Actor Script: " .. (self.CallerInfo.Source or "[Unknown]"))
        if self.ActorScript then
            ClonedFunctions.tableInsert(lines, "[s] Actor Script Path: " .. Utils.GetPath(self.ActorScript))
        end
    else
        ClonedFunctions.tableInsert(lines, "[s] Source: " .. (self.CallerInfo.Source or "[Unknown]"))
        ClonedFunctions.tableInsert(lines, "[s] Script Path: " .. (self.CallerInfo.ScriptPath or "[Unknown]"))
        ClonedFunctions.tableInsert(lines, "[n] Function Name: " .. (self.CallerInfo.Name or "[Anonymous]"))
        ClonedFunctions.tableInsert(lines, "[l] Line: " .. tostring(self.CallerInfo.Line or 0))
        ClonedFunctions.tableInsert(lines, "[f] Function Type: " .. (self.CallerInfo.FunctionType or "Unknown"))
        ClonedFunctions.tableInsert(lines, "[a] Arity: " .. tostring(self.CallerInfo.NumParams or 0))
        ClonedFunctions.tableInsert(lines, "[a] Is Vararg: " .. tostring(self.CallerInfo.IsVararg or false))
        ClonedFunctions.tableInsert(lines, "")
        
        if self.CallerInfo.StackTrace and #self.CallerInfo.StackTrace > 0 then
            ClonedFunctions.tableInsert(lines, "--- STACK TRACE ---")
            for i, frame in ipairs(self.CallerInfo.StackTrace) do
                ClonedFunctions.tableInsert(lines, "[" .. i .. "] " .. (frame.Source or "?") .. " : " .. (frame.Name or "?") .. " @ line " .. (frame.Line or 0))
            end
            ClonedFunctions.tableInsert(lines, "")
        end
    end
    
    ClonedFunctions.tableInsert(lines, "=== ARGUMENTS (" .. #self.Arguments .. ") ===")
    
    if #self.Arguments == 0 then
        ClonedFunctions.tableInsert(lines, "(no arguments)")
    else
        for i, arg in ipairs(self.Arguments) do
            local argType = typeof(arg)
            local argValue = Utils.Serialize(arg)
            ClonedFunctions.tableInsert(lines, "[" .. i .. "] <" .. argType .. ">")
            ClonedFunctions.tableInsert(lines, "    " .. argValue)
        end
    end
    
    ClonedFunctions.tableInsert(lines, "")
    ClonedFunctions.tableInsert(lines, "=== GENERATED SCRIPT ===")
    ClonedFunctions.tableInsert(lines, self:GetScript())
    
    return ClonedFunctions.tableConcat(lines, "\n")
end

function LogEntry:CanDecompile()
    if self.CallerInfo.ScriptInstance then
        return true
    end
    if self.ActorScript then
        return true
    end
    return false
end

function LogEntry:GetDecompilableScript()
    if self.CallerInfo.ScriptInstance then
        return self.CallerInfo.ScriptInstance
    end
    if self.ActorScript then
        return self.ActorScript
    end
    return nil
end

local BlockList = {}
BlockList.__index = BlockList

function BlockList.new()
    local self = setmetatable({}, BlockList)
    self.Blocked = {}
    return self
end

function BlockList:Add(remote)
    local path = Utils.GetPath(remote)
    self.Blocked[path] = true
    self.Blocked[remote] = true
end

function BlockList:Remove(remote)
    local path = Utils.GetPath(remote)
    self.Blocked[path] = nil
    self.Blocked[remote] = nil
end

function BlockList:IsBlocked(remote)
    local path = Utils.GetPath(remote)
    return self.Blocked[path] == true or self.Blocked[remote] == true
end

local Logger = {}
Logger.__index = Logger

function Logger.new()
    local self = setmetatable({}, Logger)
    
    self.Entries = {}
    self.Groups = {}
    self.EntryId = 0
    self.GroupId = 0
    self.MaxEntries = 1000
    self.MaxEntriesPerGroup = 200
    self.Paused = false
    self.Filter = ""
    self.TypeFilter = "All"
    self.OnGroupUpdated = nil
    
    return self
end

function Logger:Add(data)
    if self.Paused then return nil end
    
    self.EntryId = self.EntryId + 1
    data.Id = self.EntryId
    
    local entry = LogEntry.new(data)
    
    local groupKey = data.RemotePath
    
    if not self.Groups[groupKey] then
        self.GroupId = self.GroupId + 1
        self.Groups[groupKey] = {
            Id = self.GroupId,
            RemotePath = data.RemotePath,
            Remote = data.Remote,
            RemoteType = data.RemoteType,
            Entries = {},
            Count = 0,
            LastEntry = nil,
            Expanded = false
        }
    end
    
    local group = self.Groups[groupKey]
    group.Count = group.Count + 1
    group.LastEntry = entry
    ClonedFunctions.tableInsert(group.Entries, 1, entry)
    
    while #group.Entries > self.MaxEntriesPerGroup do
        ClonedFunctions.tableRemove(group.Entries)
    end
    
    ClonedFunctions.tableInsert(self.Entries, 1, entry)
    
    while #self.Entries > self.MaxEntries do
        ClonedFunctions.tableRemove(self.Entries)
    end
    
    if self.OnGroupUpdated then
        self.OnGroupUpdated(group, entry)
    end
    
    return entry, group
end

function Logger:Clear()
    ClonedFunctions.tableClear(self.Entries)
    ClonedFunctions.tableClear(self.Groups)
    self.GroupId = 0
end

function Logger:GetFilteredGroups()
    local result = {}
    
    for _, group in pairs(self.Groups) do
        local passType = self.TypeFilter == "All" or group.RemoteType == self.TypeFilter
        
        if self.TypeFilter == "RemoteEvent" and group.RemoteType == "OnClientEvent" then
             passType = false
        end
        if self.TypeFilter == "All" and group.RemoteType == "OnClientEvent" then
             passType = true
        end
        
        if self.TypeFilter == "All" and ClonedFunctions.stringFind(group.RemoteType, "ActorCall_", 1, true) then
            passType = true
        end

        local passText = self.Filter == "" or
            ClonedFunctions.stringFind(ClonedFunctions.stringLower(group.RemotePath), ClonedFunctions.stringLower(self.Filter), 1, true) or
            ClonedFunctions.stringFind(ClonedFunctions.stringLower(group.Remote.Name), ClonedFunctions.stringLower(self.Filter), 1, true)
        
        if passType and passText then
            ClonedFunctions.tableInsert(result, group)
        end
    end
    
    ClonedFunctions.tableSort(result, function(a, b)
        if a.LastEntry and b.LastEntry then
            return a.LastEntry.Id > b.LastEntry.Id
        end
        return false
    end)
    
    return result
end

local Decompiler = {}
Decompiler.__index = Decompiler

function Decompiler.new()
    return setmetatable({}, Decompiler)
end

function Decompiler:Process(scriptInstance)
    if not scriptInstance then
        return "No script instance provided"
    end
    
    local result = "-- Script: " .. Utils.GetPath(scriptInstance) .. "\n"
    result = result .. "-- Class: " .. scriptInstance.ClassName .. "\n\n"
    
    if decompile then
        local success, source = pcall(decompile, scriptInstance)
        if success and source then
            return result .. source
        end
    end
    
    if getscriptbytecode then
        local success, bytecode = pcall(getscriptbytecode, scriptInstance)
        if success and bytecode then
            if disassemble then
                local disSuccess, disResult = pcall(disassemble, bytecode)
                if disSuccess then
                    return result .. "-- Disassembled bytecode:\n\n" .. disResult
                end
            end
            return result .. "-- Bytecode retrieved but decompilation unavailable"
        end
    end
    
    return result .. "-- Decompilation not supported by executor"
end

local UI = {}
UI.__index = UI

function UI.new(logger, blockList, decompiler)
    local self = setmetatable({}, UI)
    
    self.Logger = logger
    self.BlockList = blockList
    self.Decompiler = decompiler
    
    self.Gui = nil
    self.Main = nil
    self.LogList = nil
    self.ContentFrame = nil
    self.Toolbar = nil
    self.GroupItems = {}
    self.SelectedEntry = nil
    self.SelectedGroup = nil
    self.SubWindows = {}
    
    self.Minimized = false
    self.MinWindowWidth = 400
    self.MinWindowHeight = 300
    self.ExpandedHeight = 500
    
    self.PendingGroups = {}
    self.UpdateConnection = nil
    
    return self
end

function UI:Build()
    if self.Gui then
        pcall(function()
            self.Gui:Destroy()
        end)
    end
    
    self.Gui = Utils.Create("ScreenGui", {
        Name = "BlatantSpy",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        DisplayOrder = 999
    })
    
    if not self.Gui then return end
    
    if syn and syn.protect_gui then
        pcall(function()
            syn.protect_gui(self.Gui)
        end)
        pcall(function()
            self.Gui.Parent = Services.CoreGui
        end)
    elseif gethui then
        pcall(function()
            self.Gui.Parent = gethui()
        end)
    else
        pcall(function()
            self.Gui.Parent = Services.CoreGui
        end)
    end
    
    Globals.BlatantSpyInstance = self.Gui
    
    self:SetupLoggerCallback()
    self:BuildMain()
    self:BuildHeader()
    self:BuildToolbar()
    self:BuildLogArea()
    self:BuildResizeHandle()
    self:SetupDrag()
    self:AnimateIn()
    self:SetMaxZIndex()
    
    if self.UpdateConnection then
        self.UpdateConnection:Disconnect()
    end
    self.UpdateConnection = Services.RunService.Heartbeat:Connect(function()
        self:ProcessPendingUpdates()
    end)
end

function UI:SetMaxZIndex()
    local function applyZIndex(instance)
        pcall(function()
            if instance:IsA("GuiObject") then
                instance.ZIndex = 999
            end
        end)
    end
    
    pcall(function()
        if self.Main then
            applyZIndex(self.Main)
            for _, desc in ipairs(self.Main:GetDescendants()) do
                applyZIndex(desc)
            end
            
            self.Main.DescendantAdded:Connect(function(desc)
                applyZIndex(desc)
            end)
        end
    end)
    
    pcall(function()
        for _, window in pairs(self.SubWindows) do
            applyZIndex(window)
            for _, desc in ipairs(window:GetDescendants()) do
                applyZIndex(desc)
            end
        end
    end)
end

function UI:BuildMain()
    self.Main = Utils.Create("Frame", {
        Name = "Main",
        Size = UDim2.new(0, 450, 0, 300),
        Position = UDim2.new(0.5, -225, 0.5, -150),
        BackgroundColor3 = Theme.Primary,
        BackgroundTransparency = Theme.Transparency,
        ClipsDescendants = true,
        Parent = self.Gui
    })
    
    if not self.Main then return end
    Utils.Corner(self.Main, Theme.CornerMedium)
    Utils.Stroke(self.Main, Theme.Accent, 1, 0.8)
end

function UI:BuildHeader()
    if not self.Main then return end
    
    local header = Utils.Create("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Theme.Secondary,
        BackgroundTransparency = 0.3,
        Parent = self.Main
    })
    
    if not header then return end
    Utils.Corner(header, Theme.CornerMedium)
    
    Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 8),
        Position = UDim2.new(0, 0, 1, -8),
        BackgroundColor3 = Theme.Secondary,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Parent = header
    })
    
    Utils.Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(0, 150, 1, 0),
        Position = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1,
        Text = "BLATANTSPY",
        TextColor3 = Theme.Text,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header
    })
    
    Utils.Create("TextLabel", {
        Name = "Executor",
        Size = UDim2.new(0, 120, 1, 0),
        Position = UDim2.new(0, 130, 0, 0),
        BackgroundTransparency = 1,
        Text = GetExecutorName(),
        TextColor3 = Theme.TextMuted,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header
    })
    
    local btnContainer = Utils.Create("Frame", {
        Name = "Buttons",
        Size = UDim2.new(0, 80, 0, 28),
        Position = UDim2.new(1, -90, 0.5, -14),
        BackgroundTransparency = 1,
        Parent = header
    })
    
    if btnContainer then
        Utils.Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            Padding = UDim.new(0, 8),
            Parent = btnContainer
        })
        
        self:CreateHeaderButton("_", btnContainer, function()
            self:ToggleMinimize()
        end)
        
        local closeBtn = self:CreateHeaderButton("X", btnContainer, function()
            self:Close()
        end)
        if closeBtn then
            Utils.SafeSet(closeBtn, "BackgroundColor3", Theme.Error)
        end
    end
end

function UI:CreateHeaderButton(text, parent, callback)
    local btn = Utils.Create("TextButton", {
        Size = UDim2.new(0, 28, 0, 28),
        BackgroundColor3 = Theme.Tertiary,
        BackgroundTransparency = 0.3,
        Text = text,
        TextColor3 = Theme.Text,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        Parent = parent
    })
    
    if not btn then return nil end
    Utils.Corner(btn, Theme.CornerSmall)
    
    pcall(function()
        btn.MouseEnter:Connect(function()
            Utils.Tween(btn, {BackgroundTransparency = 0}, 0.1)
        end)
        
        btn.MouseLeave:Connect(function()
            Utils.Tween(btn, {BackgroundTransparency = 0.3}, 0.1)
        end)
        
        btn.MouseButton1Click:Connect(callback)
    end)
    
    return btn
end

function UI:BuildToolbar()
    if not self.Main then return end
    
    self.Toolbar = Utils.Create("Frame", {
        Name = "Toolbar",
        Size = UDim2.new(1, -24, 0, 36),
        Position = UDim2.new(0, 12, 0, 46),
        BackgroundTransparency = 1,
        Parent = self.Main
    })
    
    if not self.Toolbar then return end
    
    local searchBox = Utils.Create("TextBox", {
        Name = "Search",
        Size = UDim2.new(0, 200, 0, 32),
        Position = UDim2.new(0, 0, 0.5, -16),
        BackgroundColor3 = Theme.Tertiary,
        BackgroundTransparency = 0.5,
        Text = "",
        PlaceholderText = "Search...",
        PlaceholderColor3 = Theme.TextMuted,
        TextColor3 = Theme.Text,
        TextSize = 14,
        Font = Enum.Font.Gotham,
        ClearTextOnFocus = false,
        Parent = self.Toolbar
    })
    
    if searchBox then
        Utils.Corner(searchBox, Theme.CornerSmall)
        Utils.Padding(searchBox, 10)
        
        pcall(function()
            searchBox:GetPropertyChangedSignal("Text"):Connect(function()
                self.Logger.Filter = searchBox.Text
                self:RefreshList()
            end)
        end)
    end
    
    local filterContainer = Utils.Create("Frame", {
        Name = "Filters",
        Size = UDim2.new(0, 300, 0, 32),
        Position = UDim2.new(0, 210, 0.5, -16),
        BackgroundTransparency = 1,
        Parent = self.Toolbar
    })
    
    if filterContainer then
        Utils.Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 6),
            Parent = filterContainer
        })
        
        local filters = {"All", "RemoteEvent", "RemoteFunction", "BindableEvent"}
        for _, filterType in ipairs(filters) do
            self:CreateFilterButton(filterType, filterContainer)
        end
    end
    
    local actionContainer = Utils.Create("Frame", {
        Name = "Actions",
        Size = UDim2.new(0, 90, 0, 32),
        Position = UDim2.new(1, -90, 0.5, -16),
        BackgroundTransparency = 1,
        Parent = self.Toolbar
    })
    
    if actionContainer then
        Utils.Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            Padding = UDim.new(0, 6),
            Parent = actionContainer
        })
        
        self:CreateActionButton("||", actionContainer, function(btn)
            self.Logger.Paused = not self.Logger.Paused
            if btn then
                Utils.SafeSet(btn, "Text", self.Logger.Paused and ">" or "||")
            end
        end)
        
        self:CreateActionButton("C", actionContainer, function()
            self.Logger:Clear()
            self:RefreshList()
        end)
    end
end

function UI:CreateFilterButton(filterType, parent)
    local colors = {
        All = Theme.Accent,
        RemoteEvent = Theme.RemoteEvent,
        RemoteFunction = Theme.RemoteFunction,
        BindableEvent = Theme.BindableEvent
    }
    
    local short = filterType == "All" and "ALL" or
        (filterType == "RemoteEvent" and "RE" or
        (filterType == "RemoteFunction" and "RF" or
        (filterType == "BindableEvent" and "BE" or "?")))
    
    local isActive = self.Logger.TypeFilter == filterType
    
    local btn = Utils.Create("TextButton", {
        Name = filterType,
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = isActive and (colors[filterType] or Theme.Accent) or Theme.Tertiary,
        BackgroundTransparency = isActive and 0.3 or 0.6,
        Text = " " .. short .. " ",
        TextColor3 = Theme.Text,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        Parent = parent
    })
    
    if not btn then return nil end
    Utils.Corner(btn, Theme.CornerSmall)
    Utils.Padding(btn, 6)
    
    pcall(function()
        btn.MouseButton1Click:Connect(function()
            self.Logger.TypeFilter = filterType
            
            for _, child in ipairs(parent:GetChildren()) do
                if child:IsA("TextButton") then
                    local col = colors[child.Name] or Theme.Accent
                    local active = child.Name == filterType
                    Utils.SafeSet(child, "BackgroundColor3", active and col or Theme.Tertiary)
                    Utils.SafeSet(child, "BackgroundTransparency", active and 0.3 or 0.6)
                end
            end
            
            self:RefreshList()
        end)
    end)
    
    return btn
end

function UI:CreateActionButton(text, parent, callback)
    local btn = Utils.Create("TextButton", {
        Size = UDim2.new(0, 32, 0, 32),
        BackgroundColor3 = Theme.Tertiary,
        BackgroundTransparency = 0.5,
        Text = text,
        TextColor3 = Theme.Text,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        Parent = parent
    })
    
    if not btn then return nil end
    Utils.Corner(btn, Theme.CornerSmall)
    
    pcall(function()
        btn.MouseEnter:Connect(function()
            Utils.Tween(btn, {BackgroundTransparency = 0.2}, 0.1)
        end)
        
        btn.MouseLeave:Connect(function()
            Utils.Tween(btn, {BackgroundTransparency = 0.5}, 0.1)
        end)
        
        btn.MouseButton1Click:Connect(function()
            callback(btn)
        end)
    end)
    
    return btn
end

function UI:BuildLogArea()
    if not self.Main then return end
    
    self.ContentFrame = Utils.Create("Frame", {
        Name = "LogFrame",
        Size = UDim2.new(1, -24, 1, -100),
        Position = UDim2.new(0, 12, 0, 88),
        BackgroundColor3 = Theme.Secondary,
        BackgroundTransparency = 0.6,
        ClipsDescendants = true,
        Parent = self.Main
    })
    
    if not self.ContentFrame then return end
    Utils.Corner(self.ContentFrame, Theme.CornerSmall)
    
    self.LogList = Utils.Create("ScrollingFrame", {
        Name = "LogList",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Theme.Accent,
        ScrollBarImageTransparency = 0.5,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = self.ContentFrame
    })
    
    if self.LogList then
        Utils.Create("UIListLayout", {
            Padding = UDim.new(0, 3),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = self.LogList
        })
        
        Utils.Padding(self.LogList, 6)
    end
end

function UI:BuildResizeHandle()
    if not self.Main then return end
    
    local resizeHandle = Utils.Create("TextButton", {
        Name = "ResizeHandle",
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -20, 1, -20),
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 0.7,
        Text = "",
        Parent = self.Main
    })
    
    if not resizeHandle then return end
    Utils.Corner(resizeHandle, UDim.new(0, 3))
    
    local resizing = false
    local startPos
    local startSize
    
    pcall(function()
        resizeHandle.MouseEnter:Connect(function()
            Utils.Tween(resizeHandle, {BackgroundTransparency = 0.3}, 0.1)
        end)
        
        resizeHandle.MouseLeave:Connect(function()
            if not resizing then
                Utils.Tween(resizeHandle, {BackgroundTransparency = 0.7}, 0.1)
            end
        end)
        
        resizeHandle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or 
               input.UserInputType == Enum.UserInputType.Touch then
                resizing = true
                startPos = input.Position
                startSize = self.Main.Size
            end
        end)
        
        resizeHandle.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or 
               input.UserInputType == Enum.UserInputType.Touch then
                resizing = false
            end
        end)
        
        Services.UserInputService.InputChanged:Connect(function(input)
            if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or 
               input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - startPos
                local newWidth = ClonedFunctions.mathMax(self.MinWindowWidth, startSize.X.Offset + delta.X)
                local newHeight = ClonedFunctions.mathMax(self.MinWindowHeight, startSize.Y.Offset + delta.Y)
                Utils.SafeSet(self.Main, "Size", UDim2.new(0, newWidth, 0, newHeight))
                self.ExpandedHeight = newHeight
            end
        end)
        
        Services.UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or 
               input.UserInputType == Enum.UserInputType.Touch then
                resizing = false
            end
        end)
    end)
end

function UI:CreateGroupItem(group)
    if not self.LogList then return nil end
    
    local existingItem = self.GroupItems[group.RemotePath]
    if existingItem and existingItem.Frame then
        local parentCheck = pcall(function() return existingItem.Frame.Parent end)
        if parentCheck then
            self:UpdateGroupItem(group)
            return existingItem.Frame
        end
    end
    
    local entry = group.LastEntry
    if not entry then return nil end
    
    local item = Utils.Create("Frame", {
        Name = "Group_" .. tostring(group.Id),
        Size = UDim2.new(1, -10, 0, 50),
        BackgroundColor3 = Theme.Tertiary,
        BackgroundTransparency = 0.7,
        LayoutOrder = -entry.Id,
        ClipsDescendants = true,
        Parent = self.LogList
    })
    
    if not item then return nil end
    Utils.Corner(item, Theme.CornerSmall)
    
    local colorBar = Utils.Create("Frame", {
        Name = "ColorBar",
        Size = UDim2.new(0, 4, 1, -8),
        Position = UDim2.new(0, 4, 0, 4),
        BackgroundColor3 = entry:GetColor(),
        Parent = item
    })
    
    if colorBar then
        Utils.Corner(colorBar, UDim.new(0, 2))
    end
    
    local typeLabel = Utils.Create("TextLabel", {
        Name = "TypeLabel",
        Size = UDim2.new(0, 36, 0, 20),
        Position = UDim2.new(0, 14, 0, 5),
        BackgroundColor3 = entry:GetColor(),
        BackgroundTransparency = 0.7,
        Text = entry:GetTypeShort(),
        TextColor3 = Theme.Text,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        Parent = item
    })
    
    if typeLabel then
        Utils.Corner(typeLabel, UDim.new(0, 3))
    end
    
    local countLabel = Utils.Create("TextLabel", {
        Name = "CountLabel",
        Size = UDim2.new(0, 40, 0, 20),
        Position = UDim2.new(0, 54, 0, 5),
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 0.5,
        Text = "x" .. tostring(group.Count),
        TextColor3 = Theme.Text,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        Parent = item
    })
    
    if countLabel then
        Utils.Corner(countLabel, UDim.new(0, 3))
    end
    
    local isBlocked = self.BlockList:IsBlocked(group.Remote)
    
    local blockedLabel = Utils.Create("TextLabel", {
        Name = "BlockedLabel",
        Size = UDim2.new(0, 60, 0, 20),
        Position = UDim2.new(1, -100, 0, 5),
        BackgroundColor3 = Theme.Error,
        BackgroundTransparency = 0.3,
        Text = "BLOCKED",
        TextColor3 = Theme.Text,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        Visible = isBlocked,
        Parent = item
    })
    
    if blockedLabel then
        Utils.Corner(blockedLabel, UDim.new(0, 3))
    end

    Utils.Create("TextLabel", {
        Name = "NameLabel",
        Size = UDim2.new(1, -180, 0, 20),
        Position = UDim2.new(0, 100, 0, 5),
        BackgroundTransparency = 1,
        Text = entry.Remote.Name,
        TextColor3 = Theme.Text,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = item
    })
    
    Utils.Create("TextLabel", {
        Name = "PathLabel",
        Size = UDim2.new(1, -70, 0, 16),
        Position = UDim2.new(0, 14, 0, 28),
        BackgroundTransparency = 1,
        Text = entry.RemotePath,
        TextColor3 = Theme.TextMuted,
        TextSize = 11,
        Font = Enum.Font.RobotoMono,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = item
    })
    
    local expandBtn = Utils.Create("TextButton", {
        Name = "ExpandBtn",
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(1, -32, 0, 13),
        BackgroundColor3 = Theme.Quaternary,
        BackgroundTransparency = 0.5,
        Text = "▼",
        TextColor3 = Theme.Text,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        Parent = item
    })
    
    if expandBtn then
        Utils.Corner(expandBtn, Theme.CornerSmall)
    end
    
    local entriesContainer = Utils.Create("Frame", {
        Name = "EntriesContainer",
        Size = UDim2.new(1, -20, 0, 0),
        Position = UDim2.new(0, 10, 0, 50),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Visible = false,
        Parent = item
    })
    
    if entriesContainer then
        Utils.Create("UIListLayout", {
            Padding = UDim.new(0, 2),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = entriesContainer
        })
    end
    
    local clickBtn = Utils.Create("TextButton", {
        Name = "ClickBtn",
        Size = UDim2.new(1, -40, 0, 50),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = "",
        Parent = item
    })
    
    if clickBtn then
        pcall(function()
            clickBtn.MouseEnter:Connect(function()
                Utils.Tween(item, {BackgroundTransparency = 0.5}, 0.08)
            end)
            
            clickBtn.MouseLeave:Connect(function()
                if self.SelectedGroup ~= group then
                    Utils.Tween(item, {BackgroundTransparency = 0.7}, 0.08)
                end
            end)
            
            clickBtn.MouseButton1Click:Connect(function()
                self:SelectEntry(entry, item)
            end)
        end)
    end
    
    if expandBtn then
        pcall(function()
            expandBtn.MouseButton1Click:Connect(function()
                group.Expanded = not group.Expanded
                self:ToggleGroupExpansion(group, item, entriesContainer, expandBtn)
            end)
        end)
    end
    
    self.GroupItems[group.RemotePath] = {
        Frame = item,
        CountLabel = countLabel,
        BlockedLabel = blockedLabel,
        EntriesContainer = entriesContainer,
        ExpandBtn = expandBtn,
        Group = group
    }
    
    return item
end

function UI:UpdateGroupItem(group)
    local itemData = self.GroupItems[group.RemotePath]
    if not itemData then return end
    
    pcall(function()
        if itemData.CountLabel then
            itemData.CountLabel.Text = "x" .. tostring(group.Count)
        end
    end)
    
    pcall(function()
        if itemData.BlockedLabel then
            local isBlocked = self.BlockList:IsBlocked(group.Remote)
            itemData.BlockedLabel.Visible = isBlocked
        end
    end)
    
    pcall(function()
        if itemData.Frame and group.LastEntry then
            itemData.Frame.LayoutOrder = -group.LastEntry.Id
            
            local typeLabel = itemData.Frame:FindFirstChild("TypeLabel")
            if typeLabel then
                typeLabel.BackgroundColor3 = group.LastEntry:GetColor()
            end
            
            local colorBar = itemData.Frame:FindFirstChild("ColorBar")
            if colorBar then
                colorBar.BackgroundColor3 = group.LastEntry:GetColor()
            end
        end
    end)
    
    if group.Expanded and itemData.EntriesContainer then
        self:PopulateGroupEntries(group, itemData.EntriesContainer)
        
        local entryHeight = 36
        local containerHeight = #group.Entries * (entryHeight + 2)
        Utils.SafeSet(itemData.EntriesContainer, "Size", UDim2.new(1, -20, 0, containerHeight))
        Utils.Tween(itemData.Frame, {Size = UDim2.new(1, -10, 0, 50 + containerHeight + 10)}, 0.2)
    end
end

function UI:ToggleGroupExpansion(group, item, container, expandBtn)
    if not item or not container or not expandBtn then return end
    
    if group.Expanded then
        Utils.SafeSet(expandBtn, "Text", "▲")
        Utils.SafeSet(container, "Visible", true)
        self:PopulateGroupEntries(group, container)
        
        local entryHeight = 36
        local containerHeight = #group.Entries * (entryHeight + 2)
        
        Utils.SafeSet(container, "Size", UDim2.new(1, -20, 0, containerHeight))
        Utils.Tween(item, {Size = UDim2.new(1, -10, 0, 50 + containerHeight + 10)}, 0.2)
    else
        Utils.SafeSet(expandBtn, "Text", "▼")
        Utils.Tween(item, {Size = UDim2.new(1, -10, 0, 50)}, 0.2)
        ClonedFunctions.taskDelay(0.2, function()
            if not group.Expanded then
                Utils.SafeSet(container, "Visible", false)
                pcall(function()
                    for _, child in ipairs(container:GetChildren()) do
                        if child:IsA("Frame") then
                            child:Destroy()
                        end
                    end
                end)
            end
        end)
    end
end

function UI:PopulateGroupEntries(group, container)
    if not container then return end
    
    pcall(function()
        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextLabel") then
                child:Destroy()
            end
        end
    end)
    
    for i, entry in ipairs(group.Entries) do
        if entry then
            self:CreateSubEntryItem(entry, container, i)
        end
    end
end

function UI:CreateSubEntryItem(entry, parent, index)
    if not parent or not entry then return nil end
    
    local subItem = Utils.Create("Frame", {
        Name = "Entry_" .. tostring(entry.Id),
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Theme.Secondary,
        BackgroundTransparency = 0.5,
        LayoutOrder = index,
        Parent = parent
    })
    
    if not subItem then return nil end
    Utils.Corner(subItem, Theme.CornerSmall)
    
    local colorIndicator = Utils.Create("Frame", {
        Size = UDim2.new(0, 3, 1, -6),
        Position = UDim2.new(0, 3, 0, 3),
        BackgroundColor3 = entry:GetColor(),
        Parent = subItem
    })
    
    if colorIndicator then
        Utils.Corner(colorIndicator, UDim.new(0, 1))
    end
    
    Utils.Create("TextLabel", {
        Size = UDim2.new(0, 30, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = "#" .. tostring(index),
        TextColor3 = Theme.TextDim,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = subItem
    })
    
    Utils.Create("TextLabel", {
        Size = UDim2.new(0, 60, 1, 0),
        Position = UDim2.new(0, 45, 0, 0),
        BackgroundTransparency = 1,
        Text = tostring(#entry.Arguments) .. " args",
        TextColor3 = Theme.TextMuted,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = subItem
    })
    
    local callerName = "[Anonymous]"
    if entry.RemoteType == "OnClientEvent" then
        callerName = "Server"
    elseif ClonedFunctions.stringFind(entry.RemoteType, "ActorCall_", 1, true) then
        callerName = "[ActorCall]"
    else
        callerName = entry.CallerInfo.Name or "[Anonymous]"
    end

    Utils.Create("TextLabel", {
        Size = UDim2.new(1, -180, 1, 0),
        Position = UDim2.new(0, 110, 0, 0),
        BackgroundTransparency = 1,
        Text = callerName .. (entry.RemoteType ~= "OnClientEvent" and not ClonedFunctions.stringFind(entry.RemoteType, "ActorCall_", 1, true) and (" @ line " .. tostring(entry.CallerInfo.Line or 0)) or ""),
        TextColor3 = Theme.TextDim,
                TextSize = 10,
        Font = Enum.Font.RobotoMono,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = subItem
    })
    
    if entry.Blocked then
        Utils.Create("TextLabel", {
            Size = UDim2.new(0, 20, 1, 0),
            Position = UDim2.new(1, -25, 0, 0),
            BackgroundTransparency = 1,
            Text = "B",
            TextColor3 = Theme.Error,
            TextSize = 11,
            Font = Enum.Font.GothamBold,
            Parent = subItem
        })
    end
    
    local clickBtn = Utils.Create("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        Parent = subItem
    })
    
    if clickBtn then
        pcall(function()
            clickBtn.MouseEnter:Connect(function()
                Utils.Tween(subItem, {BackgroundTransparency = 0.3}, 0.08)
            end)
            
            clickBtn.MouseLeave:Connect(function()
                Utils.Tween(subItem, {BackgroundTransparency = 0.5}, 0.08)
            end)
            
            clickBtn.MouseButton1Click:Connect(function()
                self:OpenDetailWindow(entry)
            end)
        end)
    end
    
    return subItem
end

function UI:SelectEntry(entry, item)
    for _, groupData in pairs(self.GroupItems) do
        if groupData.Frame then
            Utils.Tween(groupData.Frame, {BackgroundTransparency = 0.7}, 0.08)
        end
    end
    
    self.SelectedEntry = entry
    Utils.Tween(item, {BackgroundTransparency = 0.4}, 0.08)
    
    self:OpenDetailWindow(entry)
end

function UI:OpenDetailWindow(entry)
    if not entry then return end
    
    local currentBlockedStatus = self.BlockList:IsBlocked(entry.Remote)
    entry.Blocked = currentBlockedStatus
    
    local windowId = "Detail_" .. tostring(entry.Id)
    
    if self.SubWindows[windowId] then
        pcall(function()
            self.SubWindows[windowId]:Destroy()
        end)
    end
    
    local window = Utils.Create("Frame", {
        Name = windowId,
        Size = UDim2.new(0, 600, 0, 500),
        Position = UDim2.new(0.5, -300, 0.5, -250),
        BackgroundColor3 = Theme.Primary,
        BackgroundTransparency = Theme.Transparency,
        Parent = self.Gui
    })
    
    if not window then return end
    Utils.Corner(window, Theme.CornerMedium)
    Utils.Stroke(window, entry:GetColor(), 1, 0.6)
    
    self.SubWindows[windowId] = window
    
    local header = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = entry:GetColor(),
        BackgroundTransparency = 0.7,
        Parent = window
    })
    
    if header then
        Utils.Corner(header, Theme.CornerMedium)
        
        Utils.Create("Frame", {
            Size = UDim2.new(1, 0, 0, 8),
            Position = UDim2.new(0, 0, 1, -8),
            BackgroundColor3 = entry:GetColor(),
            BackgroundTransparency = 0.7,
            BorderSizePixel = 0,
            Parent = header
        })
        
        Utils.Create("TextLabel", {
            Size = UDim2.new(1, -70, 1, 0),
            Position = UDim2.new(0, 12, 0, 0),
            BackgroundTransparency = 1,
            Text = entry:GetTypeShort() .. " | " .. tostring(entry.Remote.Name) .. " | ID: " .. tostring(entry.Id),
            TextColor3 = Theme.Text,
            TextSize = 15,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = header
        })
        
        local closeBtn = Utils.Create("TextButton", {
            Size = UDim2.new(0, 28, 0, 28),
            Position = UDim2.new(1, -36, 0.5, -14),
            BackgroundColor3 = Theme.Error,
            BackgroundTransparency = 0.3,
            Text = "X",
            TextColor3 = Theme.Text,
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            Parent = header
        })
        
        if closeBtn then
            Utils.Corner(closeBtn, Theme.CornerSmall)
            pcall(function()
                closeBtn.MouseButton1Click:Connect(function()
                    window:Destroy()
                    self.SubWindows[windowId] = nil
                end)
            end)
        end
        
        self:SetupWindowDrag(window, header)
    end
    
    local btnFrame = Utils.Create("Frame", {
        Size = UDim2.new(1, -24, 0, 32),
        Position = UDim2.new(0, 12, 0, 42),
        BackgroundTransparency = 1,
        Parent = window
    })
    
    if btnFrame then
        Utils.Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 8),
            Parent = btnFrame
        })
        
        self:CreateDetailButton("COPY SCRIPT", btnFrame, function()
            pcall(function()
                setclipboard(entry:GetScript())
            end)
            self:ShowNotification("Script copied", Theme.Success)
        end)
        
        self:CreateDetailButton("COPY INFO", btnFrame, function()
            pcall(function()
                setclipboard(entry:GetDetailedInfoPlain())
            end)
            self:ShowNotification("Info copied", Theme.Success)
        end)
        
        if entry:CanDecompile() then
            self:CreateDetailButton("DECOMPILE", btnFrame, function()
                self:OpenDecompileWindow(entry)
            end)
        end
        
        local isBlocked = self.BlockList:IsBlocked(entry.Remote)
        self:CreateDetailButton(isBlocked and "UNBLOCK" or "BLOCK", btnFrame, function(btn)
            if self.BlockList:IsBlocked(entry.Remote) then
                self.BlockList:Remove(entry.Remote)
                Utils.SafeSet(btn, "Text", "BLOCK")
                self:ShowNotification("Unblocked", Theme.Success)
            else
                self.BlockList:Add(entry.Remote)
                Utils.SafeSet(btn, "Text", "UNBLOCK")
                self:ShowNotification("Blocked", Theme.Warning)
            end
            
            pcall(function()
                if self.GroupItems[entry.RemotePath] then
                    self:UpdateGroupItem(self.GroupItems[entry.RemotePath].Group)
                end
            end)
        end)

        self:CreateDetailButton("FIRE REMOTE", btnFrame, function()
            ClonedFunctions.taskSpawn(function()
                local args = entry.Arguments
                local rem = entry.Remote
                
                if entry.RemoteType == "OnClientEvent" then
                    if firesignal then
                        pcall(function()
                            firesignal(rem.OnClientEvent, unpack(args))
                        end)
                        self:ShowNotification("Signal Fired!", Theme.Success)
                    elseif replicatesignal then
                        pcall(function()
                            replicatesignal(rem.OnClientEvent, unpack(args))
                        end)
                        self:ShowNotification("Signal Replicated!", Theme.Success)
                    else
                        self:ShowNotification("firesignal not available", Theme.Error)
                    end
                elseif rem:IsA("RemoteEvent") or rem:IsA("UnreliableRemoteEvent") then
                    rem:FireServer(unpack(args))
                    self:ShowNotification("Remote Fired!", Theme.Success)
                elseif rem:IsA("RemoteFunction") then
                    rem:InvokeServer(unpack(args))
                    self:ShowNotification("Remote Fired!", Theme.Success)
                elseif rem:IsA("BindableEvent") then
                    rem:Fire(unpack(args))
                    self:ShowNotification("Remote Fired!", Theme.Success)
                elseif rem:IsA("BindableFunction") then
                    rem:Invoke(unpack(args))
                    self:ShowNotification("Remote Fired!", Theme.Success)
                end
            end)
        end)
        
        if CacheAPI.IsAvailable() then
            self:CreateDetailButton("INVALIDATE", btnFrame, function()
                if CacheAPI.Invalidate(entry.Remote) then
                    self:ShowNotification("Cache invalidated", Theme.Success)
                else
                    self:ShowNotification("Failed to invalidate", Theme.Error)
                end
            end)
        end
    end
    
    local contentFrame = Utils.Create("Frame", {
        Size = UDim2.new(1, -24, 1, -90),
        Position = UDim2.new(0, 12, 0, 80),
        BackgroundColor3 = Theme.Secondary,
        BackgroundTransparency = 0.5,
        ClipsDescendants = true,
        Parent = window
    })
    
    if contentFrame then
        Utils.Corner(contentFrame, Theme.CornerSmall)
        
        local contentScroll = Utils.Create("ScrollingFrame", {
            Size = UDim2.new(1,0, 1, 0),
            BackgroundTransparency = 1,
            ScrollBarThickness = 5,
            ScrollBarImageColor3 = Theme.Accent,
            ScrollBarImageTransparency = 0.3,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Parent = contentFrame
        })
        
        if contentScroll then
            Utils.Padding(contentScroll, 10)
            
            local detailLabel = Instance.new("TextLabel")
            detailLabel.Name = "DetailText"
            detailLabel.Size = UDim2.new(1, -20, 0, 0)
            detailLabel.AutomaticSize = Enum.AutomaticSize.Y
            detailLabel.BackgroundTransparency = 1
            detailLabel.TextColor3 = Theme.Text
            detailLabel.TextSize = 13
            detailLabel.Font = Enum.Font.RobotoMono
            detailLabel.TextXAlignment = Enum.TextXAlignment.Left
            detailLabel.TextYAlignment = Enum.TextYAlignment.Top
            detailLabel.TextWrapped = true
            detailLabel.RichText = true
            detailLabel.Text = entry:GetDetailedInfo()
            detailLabel.Parent = contentScroll
        end
    end
    
    self:SetupSubWindowResize(window)
    
    Utils.SafeSet(window, "Size", UDim2.new(0, 600, 0, 0))
    Utils.Tween(window, {Size = UDim2.new(0, 600, 0, 500)}, 0.25, Enum.EasingStyle.Back)
end

function UI:OpenDecompileWindow(entry)
    if not entry then
        self:ShowNotification("No entry provided", Theme.Error)
        return
    end
    
    local scriptToDecompile = entry:GetDecompilableScript()
    
    if not scriptToDecompile then
        self:ShowNotification("No script to decompile", Theme.Error)
        return
    end
    
    local windowId = "Decompile_" .. tostring(entry.Id)
    
    if self.SubWindows[windowId] then
        pcall(function()
            self.SubWindows[windowId]:Destroy()
        end)
    end
    
    local window = Utils.Create("Frame", {
        Name = windowId,
        Size = UDim2.new(0, 700, 0, 550),
        Position = UDim2.new(0.5, -350, 0.5, -275),
        BackgroundColor3 = Theme.Primary,
        BackgroundTransparency = Theme.Transparency,
        Parent = self.Gui
    })
    
    if not window then return end
    Utils.Corner(window, Theme.CornerMedium)
    Utils.Stroke(window, Theme.Accent, 1, 0.6)
    
    self.SubWindows[windowId] = window
    
    local header = Utils.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 0.7,
        Parent = window
    })
    
    if header then
        Utils.Corner(header, Theme.CornerMedium)
        
        Utils.Create("Frame", {
            Size = UDim2.new(1, 0, 0, 8),
            Position = UDim2.new(0, 0, 1, -8),
            BackgroundColor3 = Theme.Accent,
            BackgroundTransparency = 0.7,
            BorderSizePixel = 0,
            Parent = header
        })
        
        local titleText = "DECOMPILE | " .. tostring(scriptToDecompile.Name)
        if entry.ActorScript then
            titleText = "DECOMPILE [ACTOR] | " .. tostring(scriptToDecompile.Name)
        end
        
        Utils.Create("TextLabel", {
            Size = UDim2.new(1, -70, 1, 0),
            Position = UDim2.new(0, 12, 0, 0),
            BackgroundTransparency = 1,
            Text = titleText,
            TextColor3 = Theme.Text,
            TextSize = 15,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = header
        })
        
        local closeBtn = Utils.Create("TextButton", {
            Size = UDim2.new(0, 28, 0, 28),
            Position = UDim2.new(1, -36, 0.5, -14),
            BackgroundColor3 = Theme.Error,
            BackgroundTransparency = 0.3,
            Text = "X",
            TextColor3 = Theme.Text,
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            Parent = header
        })
        
        if closeBtn then
            Utils.Corner(closeBtn, Theme.CornerSmall)
            pcall(function()
                closeBtn.MouseButton1Click:Connect(function()
                    window:Destroy()
                    self.SubWindows[windowId] = nil
                end)
            end)
        end
        
        self:SetupWindowDrag(window, header)
    end
    
    local decompiled = self.Decompiler:Process(scriptToDecompile)
    
    local copyBtn = Utils.Create("TextButton", {
        Size = UDim2.new(0, 90, 0, 28),
        Position = UDim2.new(0, 12, 0, 42),
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 0.3,
        Text = "COPY",
        TextColor3 = Theme.Text,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        Parent = window
    })
    
    if copyBtn then
        Utils.Corner(copyBtn, Theme.CornerSmall)
        pcall(function()
            copyBtn.MouseButton1Click:Connect(function()
                pcall(function()
                    setclipboard(decompiled)
                end)
                self:ShowNotification("Decompiled script copied", Theme.Success)
            end)
        end)
    end
    
    local contentFrame = Utils.Create("Frame", {
        Size = UDim2.new(1, -24, 1, -90),
        Position = UDim2.new(0, 12, 0, 76),
        BackgroundColor3 = Theme.Secondary,
        BackgroundTransparency = 0.5,
        ClipsDescendants = true,
        Parent = window
    })
    
    if contentFrame then
        Utils.Corner(contentFrame, Theme.CornerSmall)
        
        local contentScroll = Utils.Create("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ScrollBarThickness = 6,
            ScrollBarImageColor3 = Theme.Accent,
            ScrollBarImageTransparency = 0.3,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.XY,
            ScrollingDirection = Enum.ScrollingDirection.XY,
            Parent = contentFrame
        })
        
        if contentScroll then
            Utils.Padding(contentScroll, 10)
            
            Utils.Create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = contentScroll
            })
            
            local lines = ClonedFunctions.stringSplit(decompiled, "\n")
            local totalLines = #lines
            local CHUNK_SIZE = 50
            
            for i = 1, totalLines, CHUNK_SIZE do
                local chunkEnd = ClonedFunctions.mathMin(i + CHUNK_SIZE - 1, totalLines)
                local codeChunk = {}
                local numChunk = {}
                
                for j = i, chunkEnd do
                    ClonedFunctions.tableInsert(codeChunk, lines[j])
                    ClonedFunctions.tableInsert(numChunk, tostring(j))
                end
                
                local codeStr = ClonedFunctions.tableConcat(codeChunk, "\n")
                local highlightedStr = Utils.HighlightLua(codeStr)
                local numStr = ClonedFunctions.tableConcat(numChunk, "\n")
                
                local rowFrame = Utils.Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1,
                    LayoutOrder = i,
                    Parent = contentScroll
                })
                
                if rowFrame then
                    local numLabel = Utils.Create("TextLabel", {
                        Size = UDim2.new(0, 40, 1, 0),
                        Position = UDim2.new(0, 0, 0, 0),
                        BackgroundTransparency = 1,
                        Text = numStr,
                        TextColor3 = Theme.TextMuted,
                        TextSize = 13,
                        Font = Enum.Font.RobotoMono,
                        TextXAlignment = Enum.TextXAlignment.Right,
                        TextYAlignment = Enum.TextYAlignment.Top,
                        TextWrapped = false,
                        Parent = rowFrame
                    })
                    
                    local codeLabel = Utils.Create("TextLabel", {
                        Size = UDim2.new(1, -50, 0, 0),
                        Position = UDim2.new(0, 50, 0, 0),
                        AutomaticSize = Enum.AutomaticSize.XY,
                        BackgroundTransparency = 1,
                        Text = highlightedStr,
                        RichText = true,
                        TextColor3 = Theme.Text,
                        TextSize = 13,
                        Font = Enum.Font.RobotoMono,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextYAlignment = Enum.TextYAlignment.Top,
                        TextWrapped = false,
                        Parent = rowFrame
                    })
                end
            end
        end
    end
    
    self:SetupSubWindowResize(window)
    
    Utils.SafeSet(window, "Size", UDim2.new(0, 700, 0, 0))
    Utils.Tween(window, {Size = UDim2.new(0, 700, 0, 550)}, 0.25, Enum.EasingStyle.Back)
end

function UI:SetupSubWindowResize(window)
    if not window then return end
    
    local resizeHandle = Utils.Create("TextButton", {
        Name = "ResizeHandle",
        Size = UDim2.new(0, 18, 0, 18),
        Position = UDim2.new(1, -18, 1, -18),
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 0.7,
        Text = "",
        Parent = window
    })
    
    if not resizeHandle then return end
    Utils.Corner(resizeHandle, UDim.new(0, 3))
    
    local resizing = false
    local startPos
    local startSize
    
    pcall(function()
        resizeHandle.MouseEnter:Connect(function()
            Utils.Tween(resizeHandle, {BackgroundTransparency = 0.3}, 0.1)
        end)
        
        resizeHandle.MouseLeave:Connect(function()
            if not resizing then
                Utils.Tween(resizeHandle, {BackgroundTransparency = 0.7}, 0.1)
            end
        end)
        
        resizeHandle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or 
               input.UserInputType == Enum.UserInputType.Touch then
                resizing = true
                startPos = input.Position
                startSize = window.Size
            end
        end)
        
        resizeHandle.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or 
               input.UserInputType == Enum.UserInputType.Touch then
                resizing = false
            end
        end)
        
        local connection
        connection = Services.UserInputService.InputChanged:Connect(function(input)
            local parentExists = pcall(function() return window.Parent end)
            if not parentExists then
                connection:Disconnect()
                return
            end
            if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or 
               input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - startPos
                local newWidth = ClonedFunctions.mathMax(300, startSize.X.Offset + delta.X)
                local newHeight = ClonedFunctions.mathMax(200, startSize.Y.Offset + delta.Y)
                Utils.SafeSet(window, "Size", UDim2.new(0, newWidth, 0, newHeight))
            end
        end)
        
        local endConnection
        endConnection = Services.UserInputService.InputEnded:Connect(function(input)
            local parentExists = pcall(function() return window.Parent end)
            if not parentExists then
                endConnection:Disconnect()
                return
            end
            if input.UserInputType == Enum.UserInputType.MouseButton1 or 
               input.UserInputType == Enum.UserInputType.Touch then
                resizing = false
            end
        end)
    end)
end

function UI:CreateDetailButton(text, parent, callback)
    local btn = Utils.Create("TextButton", {
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = Theme.Tertiary,
        BackgroundTransparency = 0.4,
        Text = text,
        TextColor3 = Theme.Text,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        Parent = parent
    })
    
    if not btn then return nil end
    Utils.Corner(btn, Theme.CornerSmall)
    Utils.Padding(btn, 10)
    
    pcall(function()
        btn.MouseEnter:Connect(function()
            Utils.Tween(btn, {BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.2}, 0.1)
        end)
        
        btn.MouseLeave:Connect(function()
            Utils.Tween(btn, {BackgroundColor3 = Theme.Tertiary, BackgroundTransparency = 0.4}, 0.1)
        end)
        
        btn.MouseButton1Click:Connect(function()
            callback(btn)
        end)
    end)
    
    return btn
end

function UI:ShowNotification(message, color)
    local notification = Utils.Create("Frame", {
        Size = UDim2.new(0, 220, 0, 40),
        Position = UDim2.new(1, -230, 1, 10),
        BackgroundColor3 = color or Theme.Accent,
        BackgroundTransparency = 0.15,
        Parent = self.Gui
    })
    
    if not notification then return end
    Utils.Corner(notification, Theme.CornerSmall)
    
    Utils.Create("TextLabel", {
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = message,
        TextColor3 = Theme.Text,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notification
    })
    
    Utils.Tween(notification, {Position = UDim2.new(1, -230, 1, -50)}, 0.2, Enum.EasingStyle.Back)
    
    ClonedFunctions.taskDelay(1.5, function()
        Utils.Tween(notification, {Position = UDim2.new(1, -230, 1, 10)}, 0.15)
        ClonedFunctions.taskWait(0.15)
        pcall(function()
            notification:Destroy()
        end)
    end)
end

function UI:RefreshList()
    for _, itemData in pairs(self.GroupItems) do
        if itemData.Frame then
            pcall(function()
                itemData.Frame:Destroy()
            end)
        end
    end
    self.GroupItems = {}
    
    local filteredGroups = self.Logger:GetFilteredGroups()
    
    for _, group in ipairs(filteredGroups) do
        self:CreateGroupItem(group)
    end
end

function UI:SetupLoggerCallback()
    local selfRef = self
    
    self.Logger.OnGroupUpdated = function(group, entry)
        selfRef.PendingGroups[group] = true
    end
end

function UI:ProcessPendingUpdates()
    if not self.PendingGroups or not next(self.PendingGroups) then return end
    
    local processed = {}
    
    for group, _ in pairs(self.PendingGroups) do
        processed[group] = true
        pcall(function()
            local passType = self.Logger.TypeFilter == "All" or group.RemoteType == self.Logger.TypeFilter
            if self.Logger.TypeFilter == "RemoteEvent" and group.RemoteType == "OnClientEvent" then passType = false end
            if self.Logger.TypeFilter == "All" and group.RemoteType == "OnClientEvent" then passType = true end
            if self.Logger.TypeFilter == "All" and ClonedFunctions.stringFind(group.RemoteType, "ActorCall_", 1, true) then passType = true end

            local passText = self.Logger.Filter == "" or
                ClonedFunctions.stringFind(ClonedFunctions.stringLower(group.RemotePath), ClonedFunctions.stringLower(self.Logger.Filter), 1, true) or
                ClonedFunctions.stringFind(ClonedFunctions.stringLower(group.Remote.Name), ClonedFunctions.stringLower(self.Logger.Filter), 1, true)
            
            if passType and passText then
                if self.GroupItems[group.RemotePath] then
                    self:UpdateGroupItem(group)
                else
                    self:CreateGroupItem(group)
                end
            end
        end)
    end
    
    for group, _ in pairs(processed) do
        self.PendingGroups[group] = nil
    end
end

function UI:SetupDrag()
    local header = self.Main and self.Main:FindFirstChild("Header")
    if not header then return end
    
    local dragging = false
    local dragInput
    local dragStart
    local startPos
    
    pcall(function()
        header.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or 
               input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = self.Main.Position
                
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        
        header.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or 
               input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)
        
        Services.UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                Utils.SafeSet(self.Main, "Position", UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                ))
            end
        end)
    end)
end

function UI:SetupWindowDrag(window, header)
    if not window or not header then return end
    
    local dragging = false
    local dragInput
    local dragStart
    local startPos
    
    pcall(function()
        header.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or 
               input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = window.Position
                
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        
        header.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or 
               input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)
        
        local connection
        connection = Services.UserInputService.InputChanged:Connect(function(input)
            local parentExists = pcall(function() return window.Parent end)
            if not parentExists then
                connection:Disconnect()
                return
            end
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                Utils.SafeSet(window, "Position", UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                ))
            end
        end)
    end)
end

function UI:ToggleMinimize()
    self.Minimized = not self.Minimized
    
    if self.Minimized then
        if self.Toolbar then
            Utils.SafeSet(self.Toolbar, "Visible", false)
        end
        if self.ContentFrame then
            Utils.SafeSet(self.ContentFrame, "Visible", false)
        end
        local resizeHandle = self.Main and self.Main:FindFirstChild("ResizeHandle")
        if resizeHandle then
            Utils.SafeSet(resizeHandle, "Visible", false)
        end
        Utils.Tween(self.Main, {Size = UDim2.new(0, self.Main.Size.X.Offset, 0, 40)}, 0.2)
    else
        Utils.Tween(self.Main, {Size = UDim2.new(0, self.Main.Size.X.Offset, 0, self.ExpandedHeight)}, 0.2)
        ClonedFunctions.taskDelay(0.2, function()
            if not self.Minimized then
                if self.Toolbar then
                    Utils.SafeSet(self.Toolbar, "Visible", true)
                end
                if self.ContentFrame then
                    Utils.SafeSet(self.ContentFrame, "Visible", true)
                end
                local resizeHandle = self.Main and self.Main:FindFirstChild("ResizeHandle")
                if resizeHandle then
                    Utils.SafeSet(resizeHandle, "Visible", true)
                end
            end
        end)
    end
end

function UI:AnimateIn()
    if not self.Main then return end
    Utils.SafeSet(self.Main, "BackgroundTransparency", 1)
    Utils.SafeSet(self.Main, "Size", UDim2.new(0, 750, 0, 0))
    
    Utils.Tween(self.Main, {
        Size = UDim2.new(0, 750, 0, 500),
        BackgroundTransparency = Theme.Transparency
    }, 0.3, Enum.EasingStyle.Back)
end

function UI:Close()
    if self.UpdateConnection then
        self.UpdateConnection:Disconnect()
        self.UpdateConnection = nil
    end

    for _, subWindow in pairs(self.SubWindows) do
        pcall(function()
            subWindow:Destroy()
        end)
    end
    
    if self.Main then
        Utils.Tween(self.Main, {
            Size = UDim2.new(0, 750, 0, 0),
            BackgroundTransparency = 1
        }, 0.2)
    end
    
    ClonedFunctions.taskWait(0.2)
    
    if self.Gui then
        pcall(function()
            self.Gui:Destroy()
        end)
        Globals.BlatantSpyInstance = nil
    end
end

local Core = {}
Core.__index = Core

function Core.new()
    local self = setmetatable({}, Core)
    
    self.Logger = Logger.new()
    self.BlockList = BlockList.new()
    self.Decompiler = Decompiler.new()
    self.UI = nil
    
    self.OriginalNamecall = nil
    self.InHook = false
    self.Active = true
    self.IncomingConnections = {}
    self.ActorHooked = false
    self.ActorChannel = nil
    self.ActorChannelId = nil
    self.ActorScripts = {}
    
    return self
end

function Core:Init()
    self:HookRemotes()
    self:HookIncoming()
    
    if ActorInterceptionEnabled then
        self:HookActors()
    end
    
    self.UI = UI.new(self.Logger, self.BlockList, self.Decompiler)
    self.UI:Build()
    
    if AdonisBypassed then
        ClonedFunctions.taskDelay(0.5, function()
            if self.UI then
                self.UI:ShowNotification("Adonis detections patched!", Theme.Success)
            end
        end)
    end
    
    if ActorInterceptionEnabled then
        ClonedFunctions.taskDelay(0.8, function()
            if self.UI then
                self.UI:ShowNotification("Actor interception enabled!", Theme.Warning)
            end
        end)
    end
    
    if CacheAPI.IsAvailable() then
        ClonedFunctions.taskDelay(1.1, function()
            if self.UI then
                self.UI:ShowNotification("Cache API available!", Theme.Success)
            end
        end)
    end
end

function Core:HookActors()
    if not getactors or not run_on_actor or not create_comm_channel or not get_comm_channel then
        return
    end
    
    local selfRef = self
    
    local r1, r2 = create_comm_channel()
    
    local channel, channelId
    
    if typeof(r1) == "Instance" and r1:IsA("BindableEvent") then
        channel = r1
        channelId = r2
    elseif typeof(r2) == "Instance" and r2:IsA("BindableEvent") then
        channel = r2
        channelId = r1
    elseif type(r1) == "number" then
        channelId = r1
        channel = r2
    elseif type(r2) == "number" then
        channelId = r2
        channel = r1
    end
    
    if not channel or not channelId then
        return
    end
    
    if type(channelId) ~= "number" then
        return
    end
    
    selfRef.ActorChannel = channel
    selfRef.ActorChannelId = channelId
    
    local function handleActorData(data)
        if not selfRef.Active then return end
        if type(data) ~= "table" then return end
        
        local remote = data.Remote
        local remoteType = data.RemoteType
        local args = data.Arguments or {}
        local actorScript = data.ActorScript
        
        if not remote or typeof(remote) ~= "Instance" then return end
        
        local isBlocked = selfRef.BlockList:IsBlocked(remote)
        if isBlocked then return end
        
        local actorRemoteType = "ActorCall_" .. remoteType
        
        local sanitizedArgs = {}
        for i, v in ipairs(args) do
            if typeof(v) == "userdata" then
                sanitizedArgs[i] = tostring(v)
            else
                sanitizedArgs[i] = v
            end
        end
        
        local actorScriptInstance = nil
        if actorScript and typeof(actorScript) == "Instance" then
            actorScriptInstance = actorScript
            selfRef.ActorScripts[remote] = actorScript
        end
        
        selfRef.Logger:Add({
            Remote = remote,
            RemoteType = actorRemoteType,
            RemotePath = Utils.GetPath(remote),
            Arguments = sanitizedArgs,
            CallerInfo = { Source = "[Actor Thread]", Name = "[ActorCall]" },
            HookType = "Actor",
            Method = data.Method or "Unknown",
            Blocked = false,
            ActorScript = actorScriptInstance
        })
    end
    
    if typeof(channel) == "Instance" and channel:IsA("BindableEvent") then
        channel.Event:Connect(handleActorData)
    else
        return
    end
    
    local actorHookScript = string.format([[
local channelId = %d
local channel = get_comm_channel(channelId)

if not channel then 
    return 
end

if getgenv()._BlatantSpyActorHooked then 
    return 
end
getgenv()._BlatantSpyActorHooked = true

local firing = false

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()
    
    if checkcaller() or firing then
        return oldNamecall(self, ...)
    end
    
    if method == "FireServer" or method == "InvokeServer" then
        if typeof(self) == "Instance" then
            local class = self.ClassName
            local remoteType = nil
            
            if method == "FireServer" and class == "RemoteEvent" then
                remoteType = "RemoteEvent"
            elseif method == "FireServer" and class == "UnreliableRemoteEvent" then
                remoteType = "UnreliableRemoteEvent"
            elseif method == "InvokeServer" and class == "RemoteFunction" then
                remoteType = "RemoteFunction"
            end
            
            if remoteType then
                local args = {...}
                local callingScript = nil
                pcall(function()
                    callingScript = getcallingscript()
                end)
                task.defer(function()
                    firing = true
                    pcall(function()
                        channel:Fire({
                            Remote = self,
                            RemoteType = remoteType,
                            Arguments = args,
                            Method = method,
                            ActorScript = callingScript
                        })
                    end)
                    firing = false
                end)
            end
        end
    end
    
    return oldNamecall(self, ...)
end))
]], channelId)
    
    local actors = getactors()
    
    for _, actor in ipairs(actors) do
        pcall(function()
            run_on_actor(actor, actorHookScript)
        end)
    end
    
    selfRef.ActorHooked = true
    
    GameRef.DescendantAdded:Connect(function(desc)
        if desc:IsA("Actor") then
            ClonedFunctions.taskDelay(0.5, function()
                pcall(function()
                    run_on_actor(desc, actorHookScript)
                end)
            end)
        end
    end)
end

function Core:HookIncoming()
    local selfRef = self
    
    local function ConnectRemote(remote)
        if not remote then return end
        if selfRef.IncomingConnections[remote] then return end
        
        selfRef.IncomingConnections[remote] = true
        
        pcall(function()
            remote.OnClientEvent:Connect(function(...)
                if not selfRef.Active then return end
                
                local args = {...}
                
                ClonedFunctions.taskSpawn(function()
                     local isBlocked = selfRef.BlockList:IsBlocked(remote)
                     if isBlocked then return end
                     
                     local sanitizedArgs = {}
                     for i, v in ipairs(args) do
                        if typeof(v) == "userdata" then
                            sanitizedArgs[i] = tostring(v)
                        else
                            sanitizedArgs[i] = v
                        end
                     end
                     
                     selfRef.Logger:Add({
                        Remote = remote,
                        RemoteType = "OnClientEvent",
                        RemotePath = Utils.GetPath(remote),
                        Arguments = sanitizedArgs,
                        CallerInfo = { Name = "Server" },
                        HookType = "OnClientEvent",
                        Method = "OnClientEvent",
                        Blocked = false
                    })
                end)
            end)
        end)
    end
    
    for _, v in ipairs(GameRef:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("UnreliableRemoteEvent") then
            ConnectRemote(v)
        end
    end
    
    GameRef.DescendantAdded:Connect(function(v)
         if v:IsA("RemoteEvent") or v:IsA("UnreliableRemoteEvent") then
            ConnectRemote(v)
        end
    end)
end

function Core:HookRemotes()
    local selfRef = self
    
    self.OriginalNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        
        if selfRef.InHook or checkcaller() then
            return selfRef.OriginalNamecall(self, ...)
        end
        
        if method == "FireServer" or method == "InvokeServer" or method == "Fire" or method == "Invoke" then
            if typeof(self) == "Instance" then
                local class = self.ClassName
                local isEvent = (method == "FireServer" and (class == "RemoteEvent" or class == "UnreliableRemoteEvent"))
                local isFunc = (method == "InvokeServer" and class == "RemoteFunction")
                local isBindEvent = (method == "Fire" and class == "BindableEvent")
                local isBindFunc = (method == "Invoke" and class == "BindableFunction")
                
                if isEvent or isFunc or isBindEvent or isBindFunc then
                    if selfRef.Active then
                        selfRef.InHook = true
                        
                        local isBlocked = selfRef.BlockList:IsBlocked(self)
                        
                        if isBlocked then
                            selfRef.InHook = false
                            return
                        end
                        
                        local args = {...}
                        
                        ClonedFunctions.taskSpawn(function()
                            local remoteType = "Unknown"
                            if isEvent then remoteType = "RemoteEvent" end
                            if isFunc then remoteType = "RemoteFunction" end
                            if isBindEvent then remoteType = "BindableEvent" end
                            if isBindFunc then remoteType = "BindableFunction" end
                            if class == "UnreliableRemoteEvent" then remoteType = "UnreliableRemoteEvent" end
                            
                            local callerInfo = Utils.GetCallerInfo(4)
                            
                            local sanitizedArgs = {}
                            for i, v in ipairs(args) do
                                if typeof(v) == "userdata" then
                                    sanitizedArgs[i] = tostring(v)
                                else
                                    sanitizedArgs[i] = v
                                end
                            end
                            
                            pcall(function()
                                selfRef.Logger:Add({
                                    Remote = self,
                                    RemoteType = remoteType,
                                    RemotePath = Utils.GetPath(self),
                                    Arguments = sanitizedArgs,
                                    CallerInfo = callerInfo,
                                    HookType = "__namecall",
                                    Method = method,
                                    Blocked = false
                                })
                            end)
                        end)
                        
                        selfRef.InHook = false
                    end
                end
            end
        end
        
        return selfRef.OriginalNamecall(self, ...)
    end))
end

function Core:Shutdown()
    self.Active = false
    
    getgenv()._BlatantSpyActorCallback = nil
    getgenv()._BlatantSpyActorHooked = nil
    
    if self.UI then
        self.UI:Close()
    end
end

local function StartBlatantSpy()
    local BlatantSpy = Core.new()
    BlatantSpy:Init()
    
    Globals.BlatantSpy = BlatantSpy
    
    return BlatantSpy
end

ShowAdonisPrompt(function()
    ShowActorPrompt(function(actorEnabled)
        StartBlatantSpy()
    end)
end)
