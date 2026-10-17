--!nocheck
-- ============================================================
-- FTAP Mobile Hub (Обновленная версия)
-- ============================================================
if _G.FTAP_HUB_LOADED then return warn("[FTAP] Хаб уже запущен") end
_G.FTAP_HUB_LOADED = true

local Players     = game:GetService("Players")
local UIS         = game:GetService("UserInputService")
local RunService  = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui     = game:GetService("CoreGui")
local LP          = Players.LocalPlayer

-- Безопасный вызов функций (защита от вылетов)
local function safe(fn, ...)
    local ok, res = pcall(fn, ...)
    if not ok then warn("[FTAP]", res) end
    return ok and res
end
local function getChar()
    return LP.Character or LP.CharacterAdded:Wait()
end
local function getHRP()
    local c = LP.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = LP.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

-- Загрузка UI Fluent
local Fluent
pcall(function()
    Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/actualslash/Fluent-RobloxUI/master/src/loader.lua"))()
end)
if not Fluent then
    _G.FTAP_HUB_LOADED = false
    return warn("[FTAP] UI не загрузился (нет интернета?)")
end

-- Создание окна
local Win = Fluent:CreateWindow({
    Title = "FTAP Hub • Mobile",
    SubTitle = "Delta Build",
    TabWidth = 140,
    Size = UDim2.fromOffset(420, 300),
    Acrylic = true,
    Theme = "Dark",
})
local Tabs = {
    Main  = Win:AddTab({ Title = "Главное",  Icon = "flame" }),
    Auto  = Win:AddTab({ Title = "Авто",     Icon = "cpu" }),
    Local = Win:AddTab({ Title = "Персонаж", Icon = "user" }),
    TP    = Win:AddTab({ Title = "Телепорт", Icon = "map-pin" }),
}

-- Плавающая кнопка
local parentGui = (gethui and gethui()) or CoreGui
local Float = Instance.new("TextButton")
Float.Size = UDim2.fromOffset(50, 50)
Float.Position = UDim2.new(1, -70, 0, 70)
Float.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
Float.Text = "≡"
Float.TextColor3 = Color3.new(1, 1, 1)
Float.TextScaled = true
Float.Font = Enum.Font.GothamBold
Float.BorderSizePixel = 0
Float.Parent = parentGui
Float.MouseButton1Click:Connect(function()
    safe(function() Fluent:Toggle() end)
end)

-- ============================================================
-- ВКЛАДКА 1: ГЛАВНОЕ (Fling Features)
-- ============================================================
_G.FTAP_THROW_MULT = 1

-- Перехват ремоутов для Super Throw
local mt = getrawmetatable and getrawmetatable(game)
if mt and setreadonly and getnamecallmethod and checkcaller and newcclosure then
    local oldNamecall = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        if getnamecallmethod() == "FireServer" and checkcaller() then
            local n = self.Name:lower()
            if n:find("throw") or n:find("grab") or n:find("fling") then
                local args = {...}
                for i, v in ipairs(args) do
                    if typeof(v) == "Vector3" then args[i] = v * _G.FTAP_THROW_MULT end
                end
                return oldNamecall(self, unpack(args))
            end
        end
        return oldNamecall(self, ...)
    end)
    setreadonly(mt, true)
end

Tabs.Main:CreateSlider({
    Title = "Super Throw (множитель)",
    Range = {1, 20}, Increment = 1, Default = 1,
    Callback = function(v) _G.FTAP_THROW_MULT = v end,
})

-- Anti-Grab (отключение веревок/захватов)
local antiGrab = false
Tabs.Main:CreateToggle({
    Title = "Anti-Grab", Default = false,
    Callback = function(v)
        antiGrab = v
        task.spawn(function()
            while antiGrab and task.wait(0.15) do
                safe(function()
                    local c = LP.Character
                    if not c then return end
                    for _, d in ipairs(c:GetDescendants()) do
                        if d:IsA("RopeConstraint") or d:IsA("SpringConstraint") then d:Destroy() end
                    end
                end)
            end
        end)
    end,
})

-- Anti-Explosion (удаление взрывов)
local antiExp = false
Tabs.Main:CreateToggle({
    Title = "Anti-Explosion", Default = false,
    Callback = function(v)
        antiExp = v
        task.spawn(function()
            while antiExp and task.wait(0.2) do
                safe(function()
                    for _, v2 in ipairs(workspace:GetDescendants()) do
                        if v2:IsA("Explosion") then v2:Destroy() end
                    end
                end)
            end
        end)
    end,
})

-- ============================================================
-- ВКЛАДКА 2: АВТОМАТИЗАЦИЯ
-- ============================================================
local autoClaim = false
Tabs.Auto:CreateToggle({
    Title = "Auto Claim Cash", Default = false,
    Callback = function(v)
        autoClaim = v
        task.spawn(function()
            while autoClaim and task.wait(1) do
                safe(function()
                    local hrp = getHRP()
                    if not hrp then return end
                    for _, v2 in ipairs(workspace:GetDescendants()) do
                        if v2:IsA("BasePart") and (v2.Name:lower():find("cash") or v2.Name:lower():find("coin")) then
                            if firetouchinterest then
                                firetouchinterest(hrp, v2, 0)
                                firetouchinterest(hrp, v2, 1)
                            end
                        end
                    end
                end)
            end
        end)
    end,
})

local antiAFK = true
Tabs.Auto:CreateToggle({
    Title = "Anti-AFK", Default = true,
    Callback = function(v) antiAFK = v end,
})
LP.Idled:Connect(function()
    if antiAFK then
        safe(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)

-- ============================================================
-- ВКЛАДКА 3: ПЕРСОНАЖ (Speed, Jump, Fly, Noclip)
-- ============================================================
local speed = 16
Tabs.Local:CreateSlider({
    Title = "WalkSpeed", Range = {16, 200}, Increment = 1, Default = 16,
    Callback = function(v)
        speed = v
        local h = getHum(); if h then h.WalkSpeed = v end
    end,
})

local jpow = 50
Tabs.Local:CreateSlider({
    Title = "JumpPower", Range = {50, 300}, Increment = 5, Default = 50,
    Callback = function(v)
        jpow = v
        local h = getHum()
        if h then h.UseJumpPower = true; h.JumpPower = v end
    end,
})

local infJump = false
Tabs.Local:CreateToggle({
    Title = "Infinite Jump", Default = false,
    Callback = function(v) infJump = v end,
})
UIS.JumpRequest:Connect(function()
    if infJump then
        local h = getHum()
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- Noclip (проход сквозь стены)
local noclip = false
Tabs.Local:CreateToggle({
    Title = "Noclip (Ноклип)", Default = false,
    Callback = function(v) noclip = v end,
})
RunService.Stepped:Connect(function()
    if noclip then
        safe(function()
            local c = LP.Character
            if c then
                for _, part in ipairs(c:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end
end)

-- Fly (Полёт)
local flying = false
local flySpeed = 50
local flyConnection

local function stopFly()
    flying = false
    if flyConnection then flyConnection:Disconnect() end
    local hrp = getHRP()
    if hrp then
        local bv = hrp:FindFirstChild("FlyBV")
        if bv then bv:Destroy() end
    end
end

Tabs.Local:CreateSlider({
    Title = "Fly Speed", Range = {10, 200}, Increment = 10, Default = 50,
    Callback = function(v) flySpeed = v end,
})

Tabs.Local:CreateToggle({
    Title = "Fly (Полёт)", Default = false,
    Callback = function(v)
        flying = v
        if flying then
            local hrp = getHRP()
            if not hrp then return end
            local bv = Instance.new("BodyVelocity")
            bv.Name = "FlyBV"
            bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            bv.Velocity = Vector3.zero
            bv.Parent = hrp
            
            flyConnection = RunService.RenderStepped:Connect(function()
                safe(function()
                    if not flying or not hrp or not hrp.Parent then return stopFly() end
                    local cam = workspace.CurrentCamera
                    local moveDir = Vector3.zero
                    
                    if UIS:IsKeyDown(Enum.KeyCode.W) then moveDir += cam.CFrame.LookVector end
                    if UIS:IsKeyDown(Enum.KeyCode.S) then moveDir -= cam.CFrame.LookVector end
                    if UIS:IsKeyDown(Enum.KeyCode.A) then moveDir -= cam.CFrame.RightVector end
                    if UIS:IsKeyDown(Enum.KeyCode.D) then moveDir += cam.CFrame.RightVector end
                    if UIS:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.new(0,1,0) end
                    
                    if moveDir.Magnitude > 0 then
                        bv.Velocity = moveDir.Unit * flySpeed
                    else
                        bv.Velocity = Vector3.zero
                    end
                end)
            end)
        else
            stopFly()
        end
    end,
})

-- Godmode
local god = false
Tabs.Local:CreateToggle({
    Title = "Godmode", Default = false,
    Callback = function(v)
        god = v
        task.spawn(function()
            while god and task.wait(0.3) do
                safe(function()
                    local h = getHum()
                    if h then
                        h.Health = h.MaxHealth
                        h:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
                    end
                end)
            end
        end)
    end,
})

LP.CharacterAdded:Connect(function(char)
    local h = char:WaitForChild("Humanoid")
    h.WalkSpeed = speed
    h.UseJumpPower = true
    h.JumpPower = jpow
end)

-- ============================================================
-- ВКЛАДКА 4: ТЕЛЕПОРТЫ
-- ============================================================
local function tpTo(v3)
    safe(function()
        local hrp = getHRP()
        if hrp and v3 then hrp.CFrame = CFrame.new(v3) end
    end)
end
Tabs.TP:CreateButton({ Title = "Спавн",       Callback = function() tpTo(Vector3.new(0, 10, 0))   end })
Tabs.TP:CreateButton({ Title = "Фабрика",     Callback = function() tpTo(Vector3.new(120, 15, -80)) end })
Tabs.TP:CreateButton({ Title = "Автоматы",    Callback = function() tpTo(Vector3.new(-60, 12, 45)) end })
Tabs.TP:CreateButton({ Title = "Безопасная",  Callback = function() tpTo(Vector3.new(0, 30, 200)) end })

Win:SelectTab("Главное")
