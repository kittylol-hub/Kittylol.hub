local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"

local Library = loadstring(game:HttpGet(repo.."Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo.."addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo.."addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local Stats = cloneref(game:GetService("Stats"))
local Lighting = cloneref(game:GetService("Lighting"))
local ws = cloneref(game:GetService("Workspace"))
local lp = Players.LocalPlayer
local cam = ws.CurrentCamera

local Window = Library:CreateWindow({
    Title = "Kittylol",
    Footer = "v1.0",
    Icon = 121663636062758,
    CornerElements = false,
    NotifySide = "Right",
    ShowCustomCursor = true,
    AutoShow = true,
})

local Tabs = {
    Combat = Window:AddTab("Combat", "swords"),
    Visuals = Window:AddTab("Visuals", "eye"),
    Game = Window:AddTab("Game", "gamepad-2"),
    ModGun = Window:AddTab("Mod Gun", "crosshair"),
    Unlock = Window:AddTab("Unlock", "lock-open"),
    Player = Window:AddTab("Player", "user"),
    Settings = Window:AddTab("UI Settings", "settings"),

}

local function newPage(tab)
    return {
        _tab = tab,
        _groups = {},
        Section = function(self, cfg)
            local side = cfg.Side or 1
            local key = side == 2 and "right" or "left"
            local g = self._groups[key]
            if not g then
                g = side == 2 and self._tab:AddRightGroupbox(cfg.Name) or self._tab:AddLeftGroupbox(cfg.Name)
                self._groups[key] = g
            end
            return g
        end,
    }
end

local CompatPages = {
    Aimbot = newPage(Tabs.Combat),
    Silent = newPage(Tabs.Combat),
    Rage = newPage(Tabs.Combat),
    Wallbang = newPage(Tabs.Combat),
    HitSound = newPage(Tabs.Combat),
    FOV = newPage(Tabs.Visuals),
    Camera = newPage(Tabs.Game),
    Misc = newPage(Tabs.Game),
    Skybox = newPage(Tabs.Game),
}

local WindowCompat = {}
function WindowCompat:Category() end
function WindowCompat:Page(cfg)
    local map = {Aimbot=CompatPages.Aimbot,["Silent Aim"]=CompatPages.Silent,Ragebot=CompatPages.Rage,Wallbang=CompatPages.Wallbang,["Hit Sound"]=CompatPages.HitSound,FOV=CompatPages.FOV,Camera=CompatPages.Camera,Misc=CompatPages.Misc,Skybox=CompatPages.Skybox}
    return map[cfg.Name]
end
function WindowCompat:Init() end
local CompatWindow = WindowCompat

local function compatLabel(group, text)
    local label = group:AddLabel(text)
    function label:Colorpicker(cfg)
        return self:AddColorPicker(cfg.Name or "Color", {Default = cfg.Default, Transparency = cfg.Transparency or 0, Callback = cfg.Callback})
    end
    return label
end

local function compatDefault(v)
    if type(v) == "table" then return v[1] end
    return v
end

local function patchGroup(group)
    function group:Toggle(cfg)
        return self:AddToggle(cfg.Flag, {Text=cfg.Name, Default=cfg.Default or false, Callback=cfg.Callback})
    end
    function group:Slider(cfg)
        return self:AddSlider(cfg.Flag, {Text=cfg.Name, Min=cfg.Min, Max=cfg.Max, Default=cfg.Default, Rounding=cfg.Rounding or 0, Suffix=cfg.Suffix, Callback=cfg.Callback})
    end
    function group:Dropdown(cfg)
        return self:AddDropdown(cfg.Flag, {Text=cfg.Name, Values=cfg.Items, Default=compatDefault(cfg.Default), Multi=cfg.Multi or false, Searchable=cfg.Searchable or false, Callback=cfg.Callback})
    end
    function group:Button(cfg)
        return self:AddButton({Text=cfg.Name, Func=cfg.Callback, DoubleClick=cfg.DoubleClick or false})
    end
    function group:Label(text)
        return compatLabel(self, text)
    end
    return group
end

for _, page in pairs(CompatPages) do
    local mt = getmetatable(page)
    for _, group in pairs(page._groups) do
        patchGroup(group)
    end
end

local function patchPage(page)
    local old = page.Section
    function page:Section(cfg)
        local g = old(self, cfg)
        return patchGroup(g)
    end
end
for _, page in pairs(CompatPages) do patchPage(page) end

local function notify(title, desc, dur)
    Library:Notify({Title=title, Description=desc, Time=dur or 2})
end

local CosmeticUnlocker = {
    Enabled = false,
    _active = false,
}

getgenv()._ZX_SetupCosmeticUnlocker = function()
    local _plrs    = game:GetService("Players")
    local _rs      = game:GetService("ReplicatedStorage")
    local _http    = game:GetService("HttpService")
    local _lp      = _plrs.LocalPlayer
    local _pscripts = _lp.PlayerScripts
    local _ctrl    = _pscripts:WaitForChild("Controllers", 30)
    local _mods    = _rs:WaitForChild("Modules", 30)

    local _enumLib = require(_mods:WaitForChild("EnumLibrary", 10))
    if _enumLib then pcall(function() _enumLib:WaitForEnumBuilder() end) end

    local _cosLib  = require(_mods:WaitForChild("CosmeticLibrary", 10))
    local _itmLib  = require(_mods:WaitForChild("ItemLibrary", 10))
    local _datCtrl = require(_ctrl:WaitForChild("PlayerDataController", 10))

    local _eq, _favs = {}, {}
    local _buildingWep, _viewProf = nil, nil
    local _lastWep = nil

    local function _mkCosmetic(nm, ctype, opts)
        local _base = _cosLib.Cosmetics[nm]
        if not _base then return nil end
        local _d = {}
        for k, v in pairs(_base) do _d[k] = v end
        _d.Name = nm
        _d.Type = _d.Type or ctype
        _d.Seed = _d.Seed or math.random(1, 1000000)
        if _enumLib then
            local _s, _eid = pcall(_enumLib.ToEnum, _enumLib, nm)
            if _s and _eid then
                _d.Enum = _eid
                _d.ObjectID = _d.ObjectID or _eid
            end
        end
        if opts then
            if opts.inverted ~= nil then _d.Inverted = opts.inverted end
            if opts.favoritesOnly ~= nil then _d.OnlyUseFavorites = opts.favoritesOnly end
        end
        return _d
    end

    local _cfgFile = "rivals_unlocker_config.json"
    local _saveLock = false

    local function _stripForSave()
        local _out = {}
        for wn, cos in pairs(_eq) do
            _out[wn] = {}
            for ct, cd in pairs(cos) do
                if cd and cd.Name then
                    _out[wn][ct] = {
                        Name = cd.Name,
                        Inverted = cd.Inverted,
                        OnlyUseFavorites = cd.OnlyUseFavorites
                    }
                end
            end
        end
        return { equipped = _out, favorites = _favs }
    end

    local function _loadCfg()
        if not isfile or not readfile then return end
        local _ok1, _ex = pcall(isfile, _cfgFile)
        if not _ok1 or not _ex then return end
        local _ok2, _raw = pcall(readfile, _cfgFile)
        if not _ok2 or not _raw or _raw == "" then return end
        local _ok3, _dec = pcall(_http.JSONDecode, _http, _raw)
        if not _ok3 or not _dec then return end
        if _dec.favorites then _favs = _dec.favorites end
        if _dec.equipped then
            _eq = {}
            for wn, cos in pairs(_dec.equipped) do
                _eq[wn] = {}
                for ct, sd in pairs(cos) do
                    if sd and sd.Name and _cosLib.Cosmetics[sd.Name] then
                        local _cloned = _mkCosmetic(sd.Name, ct, {
                            inverted = sd.Inverted,
                            favoritesOnly = sd.OnlyUseFavorites
                        })
                        if _cloned then _eq[wn][ct] = _cloned end
                    end
                end
                if not next(_eq[wn]) then _eq[wn] = nil end
            end
        end
    end

    local function _saveCfg()
        if not writefile or _saveLock then return end
        _saveLock = true
        task.spawn(function()
            task.wait(1)
            local _payload = _stripForSave()
            local _ok, _enc = pcall(_http.JSONEncode, _http, _payload)
            if _ok then pcall(writefile, _cfgFile, _enc) end
            _saveLock = false
        end)
    end

    _loadCfg()

    local _cosTypes = {"Skin","Wrap","Charm","Dance","Emote"}
    local function _isCosType(cosObj)
        if not cosObj then return false end
        for _, t in ipairs(_cosTypes) do
            if cosObj.Type == t then return true end
        end
        return false
    end

    _cosLib.OwnsCosmeticNormally = function(self, inv, nm, wep)
        local c = _cosLib.Cosmetics[nm]
        if c and c.Type == "Skin" then return true end
        return false
    end
    _cosLib.OwnsCosmeticUniversally = function(self, inv, nm, wep)
        local c = _cosLib.Cosmetics[nm]
        if c and c.Type == "Skin" then return true end
        return false
    end
    _cosLib.OwnsCosmeticForWeapon = function(self, inv, nm, wep)
        local c = _cosLib.Cosmetics[nm]
        if c and c.Type == "Skin" then return true end
        return false
    end

    local _origOwns = _cosLib.OwnsCosmetic
    _cosLib.OwnsCosmetic = function(self, inv, nm, wep)
        if nm:find("MISSING_") or nm == "Bubble Gun" then
            return _origOwns(self, inv, nm, wep)
        end
        local c = _cosLib.Cosmetics[nm]
        if c and _isCosType(c) then return true end
        return _origOwns(self, inv, nm, wep)
    end

    local _origGet = _datCtrl.Get
    _datCtrl.Get = function(self, key)
        local _val = _origGet(self, key)
        if key == "CosmeticInventory" then
            local _prx = {}
            if _val then
                for k, v in pairs(_val) do
                    local c = _cosLib.Cosmetics[k]
                    if c and _isCosType(c) then _prx[k] = v end
                end
            end
            return setmetatable(_prx, {
                __index = function(t, k)
                    local c = _cosLib.Cosmetics[k]
                    if c and _isCosType(c) then return true end
                    return nil
                end
            })
        end
        if key == "FavoritedCosmetics" then
            local _res = _val and table.clone(_val) or {}
            for wep, fv in pairs(_favs) do
                _res[wep] = _res[wep] or {}
                for nm, isFav in pairs(fv) do
                    local c = _cosLib.Cosmetics[nm]
                    if c and _isCosType(c) then
                        _res[wep][nm] = isFav
                    end
                end
            end
            return _res
        end
        return _val
    end

    local _origGetWep = _datCtrl.GetWeaponData
    _datCtrl.GetWeaponData = function(self, wn)
        local _d = _origGetWep(self, wn)
        if not _d then return nil end
        local _m = {}
        for k, v in pairs(_d) do _m[k] = v end
        _m.Name = wn
        if _eq[wn] then
            for ct, cd in pairs(_eq[wn]) do
                _m[ct] = cd
            end
        end
        return _m
    end

    local _fightCtrl
    pcall(function()
        _fightCtrl = require(_ctrl:WaitForChild("FighterController", 10))
    end)

    if hookmetamethod then
        local _remotes   = _rs:FindFirstChild("Remotes")
        local _dataRem   = _remotes and _remotes:FindFirstChild("Data")
        local _equipRem  = _dataRem and _dataRem:FindFirstChild("EquipCosmetic")
        local _favRem    = _dataRem and _dataRem:FindFirstChild("FavoriteCosmetic")
        local _repRem    = _remotes and _remotes:FindFirstChild("Replication")
        local _fightRem  = _repRem and _repRem:FindFirstChild("Fighter")
        local _useItmRem = _fightRem and _fightRem:FindFirstChild("UseItem")

        if _equipRem then
            local _onc
            _onc = hookmetamethod(game, "__namecall", function(self, ...)
                if getnamecallmethod() ~= "FireServer" then
                    return _onc(self, ...)
                end
                local _a = {...}

                if _useItmRem and self == _useItmRem then
                    local _oid = _a[1]
                    if _fightCtrl then
                        pcall(function()
                            local _f = _fightCtrl:GetFighter(_lp)
                            if _f and _f.Items then
                                for _, itm in pairs(_f.Items) do
                                    if itm:Get("ObjectID") == _oid then
                                        _lastWep = itm.Name
                                        break
                                    end
                                end
                            end
                        end)
                    end
                end

                if self == _equipRem then
                    local _wn   = _a[1]
                    local _ct   = _a[2]
                    local _cn   = _a[3]
                    local _opts = _a[4] or {}
                    if _cn and _cn ~= "None" and _cn ~= "" then
                        local _inv = _datCtrl:Get("CosmeticInventory")
                        if _inv and rawget(_inv, _cn) then
                            return _onc(self, ...)
                        end
                    end
                    _eq[_wn] = _eq[_wn] or {}
                    if not _cn or _cn == "None" or _cn == "" then
                        _eq[_wn][_ct] = nil
                        if not next(_eq[_wn]) then _eq[_wn] = nil end
                    else
                        local _cloned = _mkCosmetic(_cn, _ct, {
                            inverted = _opts.IsInverted,
                            favoritesOnly = _opts.OnlyUseFavorites
                        })
                        if _cloned then _eq[_wn][_ct] = _cloned end
                    end
                    task.defer(function()
                        pcall(function() _datCtrl.CurrentData:Replicate("WeaponInventory") end)
                    end)
                    _saveCfg()
                    return
                end

                if self == _favRem then
                    local _cos = _cosLib.Cosmetics[_a[2]]
                    if _cos then
                        _favs[_a[1]] = _favs[_a[1]] or {}
                        _favs[_a[1]][_a[2]] = _a[3] or nil
                        task.spawn(function()
                            pcall(function() _datCtrl.CurrentData:Replicate("FavoritedCosmetics") end)
                        end)
                        _saveCfg()
                    end
                    return
                end

                return _onc(self, ...)
            end)
        end
    end

    local _cliItem
    pcall(function()
        _cliItem = require(_lp.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem)
    end)

    if _cliItem and _cliItem._CreateViewModel then
        local _origCVM = _cliItem._CreateViewModel
        _cliItem._CreateViewModel = function(self, vmRef)
            local _wn  = self.Name
            local _wp  = self.ClientFighter and self.ClientFighter.Player
            _buildingWep = (_wp == _lp) and _wn or nil
            if _wp == _lp and _eq[_wn] then
                local _dk = self:ToEnum("Data")
                if vmRef[_dk] then
                    if _eq[_wn].Skin then
                        vmRef[_dk][self:ToEnum("Skin")] = _eq[_wn].Skin
                        vmRef[_dk][self:ToEnum("Name")] = _eq[_wn].Skin.Name
                    end
                    if _eq[_wn].Charm then vmRef[_dk][self:ToEnum("Charm")] = _eq[_wn].Charm end
                    if _eq[_wn].Wrap  then vmRef[_dk][self:ToEnum("Wrap")]  = _eq[_wn].Wrap  end
                elseif vmRef.Data then
                    if _eq[_wn].Skin  then vmRef.Data.Skin  = _eq[_wn].Skin; vmRef.Data.Name = _eq[_wn].Skin.Name end
                    if _eq[_wn].Charm then vmRef.Data.Charm = _eq[_wn].Charm end
                    if _eq[_wn].Wrap  then vmRef.Data.Wrap  = _eq[_wn].Wrap  end
                end
            end
            local _r = _origCVM(self, vmRef)
            _buildingWep = nil
            return _r
        end
    end

    local _vmMod = _lp.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem:FindFirstChild("ClientViewModel")
    if _vmMod then
        local _CVM = require(_vmMod)
        local _origNew = _CVM.new
        _CVM.new = function(repData, cliItm)
            local _wp  = cliItm.ClientFighter and cliItm.ClientFighter.Player
            local _wn  = _buildingWep or cliItm.Name
            if _wp == _lp and _eq[_wn] then
                local _RC  = require(_rs.Modules.ReplicatedClass)
                local _dk  = _RC:ToEnum("Data")
                repData[_dk] = repData[_dk] or {}
                local _cos = _eq[_wn]
                if _cos.Skin  then repData[_dk][_RC:ToEnum("Skin")]  = _cos.Skin  end
                if _cos.Charm then repData[_dk][_RC:ToEnum("Charm")] = _cos.Charm end
                if _cos.Wrap  then repData[_dk][_RC:ToEnum("Wrap")]  = _cos.Wrap  end
            end
            return _origNew(repData, cliItm)
        end
    end

    CosmeticUnlocker._active = true
end

getgenv()._startCosmeticUnlocker = function()
    if not CosmeticUnlocker._active then
        getgenv()._ZX_SetupCosmeticUnlocker()
    end
end
getgenv().CosmeticUnlocker = CosmeticUnlocker

local UnlockTab = Tabs.Unlock
local UnlockBox = UnlockTab:AddLeftGroupbox("Unlock All")

UnlockBox:AddToggle("UnlockAllCosmetics", {
    Text = "Unlock All Cosmetics",
    Default = false,
    Tooltip = "Unlocks cosmetic ownership locally.",
    Callback = function(value)
        if value then
            task.spawn(function()
                local ok, err = pcall(function()
                    if getgenv()._startCosmeticUnlocker then
                        getgenv()._startCosmeticUnlocker()
                    end
                end)

                if ok then
                    Library:Notify({
                        Title = "Unlock All",
                        Description = "All cosmetics unlocked locally.",
                        Time = 3
                    })
                else
                    Library:Notify({
                        Title = "Unlock All",
                        Description = "Failed to start: " .. tostring(err),
                        Time = 4
                    })
                end
            end)
        end
    end,
})

UnlockBox:AddButton({
    Text = "Clear Saved Unlock Config",
    Func = function()
        pcall(function()
            if isfile and isfile("rivals_unlocker_config.json") and delfile then
                delfile("rivals_unlocker_config.json")
            end
        end)

        Library:Notify({
            Title = "Unlock All",
            Description = "Saved unlock config cleared.",
            Time = 3
        })
    end
})

local function getFlag(key, default)
    local t = Toggles[key]
    if t then return t.Value end
    local o = Options[key]
    if o then return o.Value end
    return default
end

-- Player tab
local PlayerTab = Tabs.Player
local PlayerMovementBox = PlayerTab:AddLeftGroupbox("Movement")
local PlayerVisualBox = PlayerTab:AddRightGroupbox("Player Visuals")

local speedEnabled = false
local speedAmount = 50
local infiniteJumpEnabled = false

PlayerMovementBox:AddToggle("PlayerSpeedHack", {
    Text = "Speed Hack",
    Default = false,
    Callback = function(value)
        speedEnabled = value
        if not value then
            local char = lp.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                local v = root.AssemblyLinearVelocity
                root.AssemblyLinearVelocity = Vector3.new(0, v.Y, 0)
            end
            if hum then
                hum.WalkSpeed = 16
            end
        end
    end,
})

PlayerMovementBox:AddSlider("PlayerSpeedAmount", {
    Text = "Speed",
    Min = 16,
    Max = 150,
    Default = 50,
    Rounding = 0,
    Callback = function(value)
        speedAmount = value
    end,
})

PlayerMovementBox:AddToggle("PlayerInfiniteJump", {
    Text = "Infinite Jump",
    Default = false,
    Callback = function(value)
        infiniteJumpEnabled = value
    end,
})

local espEnabled = false
local esp = {}

local function removeESP(player)
    local draw = esp[player]
    if not draw then return end
    pcall(function() draw.name:Remove() end)
    pcall(function() draw.health:Remove() end)
    esp[player] = nil
end

local function createESP(player)
    if player == lp or esp[player] then return end
    if not Drawing or not Drawing.new then return end

    local ok, result = pcall(function()
        local name = Drawing.new("Text")
        name.Size = 13
        name.Center = true
        name.Outline = true
        name.Color = Color3.fromRGB(255, 105, 180)

        local health = Drawing.new("Line")
        health.Thickness = 3
        health.Color = Color3.fromRGB(255, 105, 180)

        return {name = name, health = health}
    end)

    if ok then
        esp[player] = result
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    createESP(player)
end

Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(removeESP)

PlayerVisualBox:AddToggle("PlayerESP", {
    Text = "Player ESP",
    Default = false,
    Callback = function(value)
        espEnabled = value
        if not value then
            for _, draw in pairs(esp) do
                draw.name.Visible = false
                draw.health.Visible = false
            end
        end
    end,
})

local gunTrackerEnabled = false
local gunTracker

if Drawing and Drawing.new then
    pcall(function()
        gunTracker = Drawing.new("Line")
        gunTracker.Thickness = 2
        gunTracker.Color = Color3.fromRGB(0, 255, 0)
        gunTracker.Visible = false
    end)
end

PlayerVisualBox:AddToggle("GunTracker", {
    Text = "Gun Tracker",
    Default = false,
    Callback = function(value)
        gunTrackerEnabled = value
        if not value and gunTracker then
            gunTracker.Visible = false
        end
    end,
})

local function getClosestVisibleRoot()
    local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
    local closest, closestDistance = nil, math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lp then
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if root and hum and hum.Health > 0 then
                local pos, visible = cam:WorldToViewportPoint(root.Position)
                if visible then
                    local distance = (center - Vector2.new(pos.X, pos.Y)).Magnitude
                    if distance < closestDistance then
                        closestDistance = distance
                        closest = root
                    end
                end
            end
        end
    end

    return closest
end

RunService.Heartbeat:Connect(function()
    if not speedEnabled then return end

    local char = lp.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return end

    local move = hum.MoveDirection
    local current = root.AssemblyLinearVelocity
    root.AssemblyLinearVelocity = Vector3.new(move.X * speedAmount, current.Y, move.Z * speedAmount)
end)

UserInputService.JumpRequest:Connect(function()
    if not infiniteJumpEnabled then return end
    local char = lp.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

RunService.RenderStepped:Connect(function()
    for player, draw in pairs(esp) do
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")

        if espEnabled and root and hum and hum.Health > 0 then
            local pos, visible = cam:WorldToViewportPoint(root.Position)
            if visible then
                draw.name.Text = player.Name
                draw.name.Position = Vector2.new(pos.X, pos.Y - 20)
                draw.name.Visible = true

                local maxHealth = math.max(hum.MaxHealth, 1)
                local hp = math.clamp(hum.Health / maxHealth, 0, 1)
                draw.health.From = Vector2.new(pos.X - 20, pos.Y + 20)
                draw.health.To = Vector2.new(pos.X - 20, pos.Y + 20 - (40 * hp))
                draw.health.Visible = true
            else
                draw.name.Visible = false
                draw.health.Visible = false
            end
        else
            draw.name.Visible = false
            draw.health.Visible = false
        end
    end

    if not gunTrackerEnabled or not gunTracker then
        if gunTracker then gunTracker.Visible = false end
        return
    end

    local target = getClosestVisibleRoot()
    if target then
        local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
        local pos, visible = cam:WorldToViewportPoint(target.Position)
        if visible then
            gunTracker.From = center
            gunTracker.To = Vector2.new(pos.X, pos.Y)
            gunTracker.Visible = true
        else
            gunTracker.Visible = false
        end
    else
        gunTracker.Visible = false
    end
end)

local ModGunTab = Tabs.ModGun
local GunBox = ModGunTab:AddLeftGroupbox("Gun Mods")

local BulletTracerEnabled = true
local BulletTracerRainbow = true
local BulletTracerColor = Color3.fromRGB(255, 105, 180)
local BulletTracerLifetime = 3
local BulletTracerFadeTime = 0.5
local BulletTracerSize = 1
local BulletTracers = {}
local BulletTracerHooked = false
local BulletTracerHue = 0

local BulletTracerToggle = GunBox:AddToggle("BulletTracerEnabled", {
    Text = "Bullet Tracer",
    Default = true,
    Callback = function(v)
        BulletTracerEnabled = v

        if not v then
            for i = #BulletTracers, 1, -1 do
                local tr = BulletTracers[i]
                pcall(function() tr.Line:Remove() end)
                if tr.Outline then
                    pcall(function() tr.Outline:Remove() end)
                end
                pcall(function() tr.Line:Remove() end)
                table.remove(BulletTracers, i)
            end
        end
    end,
})

BulletTracerToggle:AddColorPicker("BulletTracerColor", {
    Default = BulletTracerColor,
    Title = "Tracer Color",
    Transparency = false,
    Callback = function(v)
        BulletTracerColor = v
    end,
})

GunBox:AddToggle("BulletTracerRainbow", {
    Text = "Rainbow Color",
    Default = true,
    Callback = function(v)
        BulletTracerRainbow = v
    end,
})

local function getBulletTracerColor()
    if BulletTracerRainbow then
        return Color3.fromHSV(BulletTracerHue % 1, 0.85, 1)
    end
    return BulletTracerColor
end

local function BulletTracerMuzzle()
    local vm = workspace:FindFirstChild("ViewModels")
    local fp = vm and vm:FindFirstChild("FirstPerson")

    if fp then
        for _, model in ipairs(fp:GetChildren()) do
            if model:IsA("Model") and model.Name:find("^" .. lp.Name) then
                local iv = model:FindFirstChild("ItemVisual")
                local body = iv and iv:FindFirstChild("Body")
                local bp = body and body:FindFirstChild("BodyPrimary")
                local muzzle = bp and bp:FindFirstChild("_muzzle")

                if muzzle and muzzle:IsA("Attachment") then
                    return muzzle.WorldPosition
                end
            end
        end
    end

    local character = lp.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root then
        return root.Position
    end

    local camera = workspace.CurrentCamera
    return camera and camera.CFrame.Position or nil
end

local function BulletMakeTracer(startPos, endPos)
    if not BulletTracerEnabled or not startPos or not endPos then
        return
    end

    local line = Drawing.new("Line")
    line.Thickness = 2 * BulletTracerSize
    line.Color = getBulletTracerColor()
    line.Transparency = 1
    line.Visible = false

    BulletTracers[#BulletTracers + 1] = {
        Line = line,
        StartPos = startPos,
        EndPos = endPos,
        Created = tick(),
    }
end

RunService.RenderStepped:Connect(function(dt)
    BulletTracerHue = (BulletTracerHue + dt * 0.30) % 1

    local camera = workspace.CurrentCamera
    if not camera then return end

    local now = tick()

    for i = #BulletTracers, 1, -1 do
        local tr = BulletTracers[i]
        local age = now - tr.Created

        if age >= BulletTracerLifetime or not BulletTracerEnabled then
            pcall(function() tr.Line:Remove() end)
            pcall(function() tr.Outline:Remove() end)
            table.remove(BulletTracers, i)
        else
            local fade = 1

            if BulletTracerFadeTime > 0
                and age >= BulletTracerLifetime - BulletTracerFadeTime then
                fade = 1 - math.clamp(
                    (age - (BulletTracerLifetime - BulletTracerFadeTime))
                    / BulletTracerFadeTime,
                    0,
                    1
                )
            end

            local s, sVisible = camera:WorldToViewportPoint(tr.StartPos)
            local e, eVisible = camera:WorldToViewportPoint(tr.EndPos)

            if sVisible and eVisible and s.Z > 0 and e.Z > 0 then
                tr.Line.From = Vector2.new(s.X, s.Y)
                tr.Line.To = Vector2.new(e.X, e.Y)
                tr.Line.Transparency = fade
                tr.Line.Color = getBulletTracerColor()
                tr.Line.Visible = true
            else
                tr.Line.Visible = false
            end
        end
    end
end)

local function HookBulletTracer()
    if BulletTracerHooked then
        return true
    end

    local ok = pcall(function()
        local modulesFolder = lp.PlayerScripts:FindFirstChild("Modules")
        local tracerModule = modulesFolder and modulesFolder:FindFirstChild("TracerEffect")

        if not tracerModule then
            return false
        end

        local TracerEffect = require(tracerModule)
        if type(TracerEffect.Play) ~= "function" then
            return false
        end

        if TracerEffect.__PinkTracerHooked then
            BulletTracerHooked = true
            return true
        end

        local oldPlay = TracerEffect.Play

        TracerEffect.Play = function(self, tracerData, config, extraData)
            if BulletTracerEnabled and tracerData then
                local isLocal = tracerData.IsLocal
                if isLocal == nil or isLocal == true then
                    local muzzle = BulletTracerMuzzle()
                    local results = tracerData.RaycastResults

                    if muzzle and results then
                        for _, result in ipairs(results) do
                            if result and result.Position then
                                BulletMakeTracer(muzzle, result.Position)
                            end
                        end
                    elseif muzzle and tracerData.Position then
                        BulletMakeTracer(muzzle, tracerData.Position)
                    end
                end
            end

            return oldPlay(self, tracerData, config, extraData)
        end

        TracerEffect.__PinkTracerHooked = true
        BulletTracerHooked = true
        return true
    end)

    return ok
end

task.spawn(function()
    for _ = 1, 60 do
        if HookBulletTracer() then
            break
        end
        task.wait(0.5)
    end
end)

local function toggleTableAttribute(attribute,value)
    for _,gcVal in pairs(getgc(true)) do
        if type(gcVal) == "table" and rawget(gcVal,attribute) ~= nil then
            gcVal[attribute] = value
        end
    end
end
GunBox:AddToggle("ModGun",{
    Text = "Mod Gun",
    Default = false,
    Callback = function(v)
        if v then
            toggleTableAttribute("ShootCooldown",0)
            toggleTableAttribute("ShootSpread",0)
            toggleTableAttribute("ShootRecoil",0)
        end
    end
})

    local function safeRequire(path)
        local ok, r = pcall(require, path)
        return ok and r or nil
    end

    local CameraController  = safeRequire(lp.PlayerScripts:WaitForChild("Controllers",10):WaitForChild("CameraController",10))
    local FighterController = safeRequire(lp.PlayerScripts:WaitForChild("Controllers",10):WaitForChild("FighterController",10))
    local util              = safeRequire(ReplicatedStorage:WaitForChild("Modules",10):WaitForChild("Utility",10))
    local enums             = safeRequire(ReplicatedStorage:WaitForChild("Modules",10):WaitForChild("EnumLibrary",10))
    local GunModule         = safeRequire(lp.PlayerScripts.Modules.ItemTypes.Gun)
    local DebugController   = safeRequire(lp.PlayerScripts:WaitForChild("Controllers",10):WaitForChild("DebugController",10))

    local RB = ReplicatedStorage:WaitForChild("Remotes",10)
    local RBF = RB:WaitForChild("Replication",10):WaitForChild("Fighter",10)

    local UseItemRemote     = RBF:WaitForChild("UseItem",10)
    local PickWeaponsRemote = RBF:WaitForChild("PickWeapons",10)
    local VoteRemote        = RB:WaitForChild("Duels",10):WaitForChild("Vote",10)
    local QueueRemote       = RB:WaitForChild("Matchmaking",10):WaitForChild("JoinQueue",10)

    pcall(function()
        if DebugController then DebugController:SetHandicapsEnabled(true) end
    end)

    local PRIMARY_WEAPONS = {
        "Distortion","Permafrost","Energy Rifle","Flamethrower",
        "Grenade Launcher","Minigun","Paintball","Assault Rifle",
        "Bow","Burst Rifle","Crossbow","Gunblade","RPG","Shotgun","Sniper",
    }
    local SECONDARY_WEAPONS = {
        "Warper","Energy Pistols","Exogun","Slingshot","Daggers",
        "Flare Gun","Handgun","Revolver","Shorty","Spray","Uzi",
    }
    local MELEE_WEAPONS = {
        "Maul","Spear","Trowel","Battle Axe","Chainsaw","Fist",
        "Katana","Knife","Riot Shield","Scythe",
    }
    local UTILITY_WEAPONS = {
        "Grappler","Medkit","Subspace Tripmine","Warpstone",
        "Flashbang","Freeze Ray","Grenade","Jump Pad",
        "Molotov","Satchel","Smoke Grenade","War Horn",
    }
    local MAPS = {
        "Arena","Big Arena","Backrooms","Big Backrooms","Legacy Backrooms",
        "Baseplate","Battleground","Legacy Battleground","Bridge","Chess",
        "Construction","Crossroads","Big Crossroads","Legacy Crossroads",
        "Dimensions","Docks","Legacy Docks","Graveyard","Big Graveyard",
    }
    local QUEUE_MODES = {"1v1","2v2","3v3","4v4","5v5"}

    local HIT_SOUNDS = {
        ["Rust"]          = "rbxassetid://4764109000",
        ["Click"]         = "rbxassetid://6042053626",
        ["Click 2"]       = "rbxassetid://5153644999",
        ["Beep"]          = "rbxassetid://9120386436",
        ["Ding"]          = "rbxassetid://4612375109",
        ["Pop"]           = "rbxassetid://5982421855",
        ["Punch"]         = "rbxassetid://386946753",
        ["Headshot"]      = "rbxassetid://4612378735",
        ["Bone Crack"]    = "rbxassetid://5801253825",
        ["Minecraft Hit"] = "rbxassetid://131070686",
        ["Minecraft"]     = "rbxassetid://135478009117226",
        ["Neverlose"]     = "rbxassetid://82938206376993",
        ["Skibidi"]       = "rbxassetid://18723913",
        ["Bruh"]          = "rbxassetid://9120253754",
        ["Oof"]           = "rbxassetid://5997174966",
        ["Vine Boom"]     = "rbxassetid://7293984919",
        ["Metal Hit"]     = "rbxassetid://10734947730",
        ["Wet"]           = "rbxassetid://4768489490",
        ["Arrow"]         = "rbxassetid://4612394498",
        ["Laser"]         = "rbxassetid://5992660828",
        ["Squeak"]        = "rbxassetid://1300087530",
        ["Cash"]          = "rbxassetid://4612379547",
        ["Among Us"]      = "rbxassetid://6936643745",
    }
    local HIT_SOUND_LIST = {}
    for k in pairs(HIT_SOUNDS) do table.insert(HIT_SOUND_LIST,k) end
    table.sort(HIT_SOUND_LIST)

    local SKYBOXES = {
        ["Default"] = {
            SkyboxBk="rbxassetid://159454299",SkyboxDn="rbxassetid://159454296",
            SkyboxFt="rbxassetid://159454293",SkyboxLf="rbxassetid://159454286",
            SkyboxRt="rbxassetid://159454300",SkyboxUp="rbxassetid://159454295",
        },
        ["Night Sky"] = {
            SkyboxBk="rbxassetid://3095606289",SkyboxDn="rbxassetid://3095606289",
            SkyboxFt="rbxassetid://3095606294",SkyboxLf="rbxassetid://3095606292",
            SkyboxRt="rbxassetid://3095606291",SkyboxUp="rbxassetid://3095606290",isNight=true,
        },
        ["Bliss"] = {
            SkyboxBk="rbxassetid://6444884337",SkyboxDn="rbxassetid://6422644718",
            SkyboxFt="rbxassetid://6444884344",SkyboxLf="rbxassetid://6444884341",
            SkyboxRt="rbxassetid://6444884348",SkyboxUp="rbxassetid://6444884351",
        },
        ["Sunset"] = {
            SkyboxBk="rbxassetid://2708786809",SkyboxDn="rbxassetid://2708786814",
            SkyboxFt="rbxassetid://2708786816",SkyboxLf="rbxassetid://2708786812",
            SkyboxRt="rbxassetid://2708786819",SkyboxUp="rbxassetid://2708786821",
        },
        ["Space"] = {
            SkyboxBk="rbxassetid://159454299",SkyboxDn="rbxassetid://159454296",
            SkyboxFt="rbxassetid://159454293",SkyboxLf="rbxassetid://159454286",
            SkyboxRt="rbxassetid://159454300",SkyboxUp="rbxassetid://159454295",isSpace=true,
        },
    }
    local SKYBOX_LIST = {"Default","Night Sky","Bliss","Sunset","Space"}
    local PARTS = {"Head","HumanoidRootPart","UpperTorso","LowerTorso","Body","Random"}
    local PMAP = {
        ["Head"]={"Head"},["HumanoidRootPart"]={"HumanoidRootPart"},
        ["UpperTorso"]={"UpperTorso","Torso","HumanoidRootPart"},
        ["LowerTorso"]={"LowerTorso","Torso","HumanoidRootPart"},
        ["Body"]={"UpperTorso","LowerTorso","Torso","HumanoidRootPart"},
        ["Random"]={"Random"},
    }

    local function bPart(char,s)
        local pr=PMAP[s] or {"Head"}
        if pr[1]=="Random" then
            local av={}
            for _,n in ipairs({"Head","UpperTorso","LowerTorso","HumanoidRootPart"}) do
                local p=char:FindFirstChild(n);if p then table.insert(av,p) end
            end
            return #av>0 and av[math.random(1,#av)] or nil
        end
        for _,n in ipairs(pr) do
            local p=char:FindFirstChild(n);if p then return p end
        end
    end

    local function scr()
        return Vector2.new(cam.ViewportSize.X/2,cam.ViewportSize.Y/2)
    end

    local function getMouse()
        return UserInputService:GetMouseLocation()
    end

    local function sameTm(p)
        local r=false
        pcall(function()
            local a=lp:GetAttribute("TeamID");local b=p:GetAttribute("TeamID")
            if a~=nil and b~=nil then r=(a==b) end
        end)
        return r
    end

    local vpRp=RaycastParams.new()
    vpRp.FilterType=Enum.RaycastFilterType.Exclude

    local function isVis(orig,part)
        if not part then return false end
        local ok,res=pcall(function()
            vpRp.FilterDescendantsInstances={lp.Character,part.Parent}
            local d=part.Position-orig
            local h=ws:Raycast(orig,d,vpRp)
            return h==nil or h.Instance:IsDescendantOf(part.Parent)
        end)
        return ok and res or false
    end

    local function inFov(part,fovSz)
        if not part then return false end
        local sp,on=cam:WorldToViewportPoint(part.Position)
        if not on then return false end
        return (Vector2.new(sp.X,sp.Y)-scr()).Magnitude<=fovSz
    end

    local function angDiff(f,t)
        local d=t-f
        return ((d+math.pi)%(math.pi*2))-math.pi
    end

    local function isValidTarget(player)
        if not player or not player:IsA("Player") then return false end
        if player==lp then return false end
        local char=player.Character
        if not char or not char:IsDescendantOf(workspace) then return false end
        local hum=char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health<=0 then return false end
        if hum:GetState()==Enum.HumanoidStateType.Dead then return false end
        if not char:FindFirstChild("HumanoidRootPart") then return false end
        local myChar=lp.Character
        if myChar then
            local myHRP=myChar:FindFirstChild("HumanoidRootPart")
            local hrp=char:FindFirstChild("HumanoidRootPart")
            if myHRP and hrp and (myHRP.Position-hrp.Position).Magnitude>3000 then
                return false
            end
        end
        return true
    end

    local function notify(title,desc,dur)
        Library:Notification({Title=title,Description=desc,Duration=dur or 2,Icon="73789337996373"})
    end


getgenv().InstanceModuleCache = getgenv().InstanceModuleCache or {}

local function instanceSafeRequire(moduleRef, timeoutSec)
    local cache = getgenv().InstanceModuleCache
    local key = typeof(moduleRef) == "Instance" and moduleRef:GetFullName() or tostring(moduleRef)
    if cache[key] ~= nil then return cache[key] end
    local deadline = timeoutSec and (os.clock() + timeoutSec) or math.huge
    local lastErr
    while os.clock() < deadline do
        if typeof(moduleRef) == "Instance" and not moduleRef.Parent then
            task.wait(0.1)
        else
            local ok, result = pcall(require, moduleRef)
            if ok then
                cache[key] = result
                return result
            end
            lastErr = result
            task.wait(0.1)
        end
    end
    error("[instance] module load failed: " .. key .. " (" .. tostring(lastErr) .. ")")
end

getgenv().InstanceRequire = instanceSafeRequire


local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local Workspace         = game:GetService("Workspace")
local Camera            = workspace.CurrentCamera
local UserInputService  = game:GetService("UserInputService")
local Utility           = instanceSafeRequire(ReplicatedStorage.Modules.Utility)
local EnumLibrary       = instanceSafeRequire(ReplicatedStorage.Modules.EnumLibrary)
local LocalPlayer       = Players.LocalPlayer

_G.AspectRatioSettings = _G.AspectRatioSettings or {
    Enabled = false,
    X = 13,
    Y = 10,
}

local function getAspectStretch()
    local s = _G.AspectRatioSettings
    if s and s.Enabled then
        return s.X / s.Y
    end
    return 1
end

local function applyAspectToViewport(screenVec, cam)
    local stretch = getAspectStretch()
    if stretch == 1 then
        return screenVec
    end
    cam = cam or workspace.CurrentCamera
    if not cam then
        return screenVec
    end
    local centerY = cam.ViewportSize.Y * 0.5
    return Vector3.new(screenVec.X, centerY + (screenVec.Y - centerY) * stretch, screenVec.Z)
end

local function worldToScreen(worldPos, cam)
    cam = cam or workspace.CurrentCamera
    if not cam or not worldPos then
        return nil, false
    end
    local v, onScreen = cam:WorldToViewportPoint(worldPos)
    if not onScreen or v.Z <= 0 then
        return v, false
    end
    return applyAspectToViewport(v, cam), true
end

local function screenAnchor(xNorm, yNorm, cam)
    cam = cam or workspace.CurrentCamera
    if not cam then
        return Vector2.zero
    end
    local vs = cam.ViewportSize
    local stretch = getAspectStretch()
    local centerY = vs.Y * 0.5
    local y = centerY + (vs.Y * yNorm - centerY) * stretch
    return Vector2.new(vs.X * xNorm, y)
end

local function screenCenter(cam)
    return screenAnchor(0.5, 0.5, cam)
end

local function getUnstretchedCameraCFrame(cam)
    cam = cam or workspace.CurrentCamera
    if not cam then
        return nil
    end
    local cf = cam.CFrame
    if getAspectStretch() == 1 then
        return cf
    end
    local pos = cf.Position
    local look = cf.LookVector
    local right = cf.RightVector
    local up = right:Cross(look).Unit
    return CFrame.fromMatrix(pos, right, up, -look)
end

getgenv().InstanceGetAspectStretch = getAspectStretch
getgenv().InstanceWorldToScreen = worldToScreen
getgenv().InstanceScreenAnchor = screenAnchor
getgenv().InstanceScreenCenter = screenCenter
getgenv().InstanceGetUnstretchedCameraCFrame = getUnstretchedCameraCFrame

_G.Features = _G.Features or {}
_G.Features.CrossbowSoundId = "rbxassetid://165946246"
getgenv().InstanceCombatLastShotAt = getgenv().InstanceCombatLastShotAt or 0

local function markCombatShot()
    getgenv().InstanceCombatLastShotAt = tick()
end
getgenv().InstanceMarkCombatShot = markCombatShot

getgenv().InstanceWorldToScreenEsp = function(worldPos, cam)
    return worldToScreen(worldPos, cam)
end


local HitGroup
local damageBillboardInfoCache = setmetatable({}, { __mode = "k" })
local getDamageBillboardInfo
local startProjectileBypass
local stopProjectileBypass

local silentAimBox      = Tabs.Combat:AddLeftGroupbox('silent aim')
local silentCustBox     = Tabs.Combat:AddLeftGroupbox('silent customization')
local aimbotBox         = Tabs.Combat:AddRightGroupbox('aimbot')
local aimbotCustBox     = Tabs.Combat:AddRightGroupbox('aimbot customization')

local textureAssets, soundsassets, HPlist, restricteditems

do
    restricteditems = {
        "Flamethrower","Fists","Battle Axe","Chainsaw","Katana","Knife",
        "Riot Shield","Scythe","Maul","Trowel","Grenade","Flashbang",
        "Jump Pad","Molotov","Satchel","Smoke Grenade","War Horn",
        "Medkit","Subspace Tripmine","Warpstone"
    }

    textureAssets = {
        ["Line"]      = "",
        ["Beam"]      = "rbxassetid://12781852245",
        ["Lightning"] = "rbxassetid://446111271",
        ["Heartrate"] = "rbxassetid://5830549480",
        ["Chain"]     = "rbxassetid://9632168658",
        ["Glitch"]    = "rbxassetid://8089467613",
        ["Swirl"]     = "rbxassetid://5638168605",
        ["Neon"]      = "rbxassetid://6361963422",
        ["Plasma"]    = "rbxassetid://8993645509",
        ["Laser"]     = "rbxassetid://14549123968",
    }

    soundsassets = {
        ["Rust HS"]           = "rbxassetid://5043539486",
        ["Neverlose"]         = "rbxassetid://97643101798871",
        ["Minecraft Bow"]     = "rbxassetid://3442683707",
        ["Minecraft Hit"]     = "rbxassetid://8766809464",
        ["CSGO"]              = "rbxassetid://5764885315",
        ["Bubble"]            = "rbxassetid://6534947588",
        ["Lazer"]             = "rbxassetid://130791043",
        ["Pick"]              = "rbxassetid://1347140027",
        ["Pop"]               = "rbxassetid://198598793",
        ["Rust"]              = "rbxassetid://1255040462",
        ["Sans"]              = "rbxassetid://3188795283",
        ["Fart"]              = "rbxassetid://130833677",
        ["Big"]               = "rbxassetid://5332005053",
        ["Vine"]              = "rbxassetid://5332680810",
        ["UwU"]               = "rbxassetid://8679659744",
        ["Bruh"]              = "rbxassetid://4578740568",
        ["Skeet"]             = "rbxassetid://5633695679",
        ["Fatality"]          = "rbxassetid://6534947869",
        ["Bonk"]              = "rbxassetid://5766898159",
        ["Minecraft"]         = "rbxassetid://5869422451",
        ["Gamesense"]         = "rbxassetid://4817809188",
        ["RIFK7"]             = "rbxassetid://9102080552",
        ["Bamboo"]            = "rbxassetid://3769434519",
        ["Crowbar"]           = "rbxassetid://546410481",
        ["Weeb"]              = "rbxassetid://6442965016",
        ["Beep"]              = "rbxassetid://8177256015",
        ["Bambi"]             = "rbxassetid://8437203821",
        ["Stone"]             = "rbxassetid://3581383408",
        ["Old Fatality"]      = "rbxassetid://6607142036",
        ["Click"]             = "rbxassetid://8053704437",
        ["Ding"]              = "rbxassetid://7149516994",
        ["Snow"]              = "rbxassetid://6455527632",
        ["Laser"]             = "rbxassetid://7837461331",
        ["Mario"]             = "rbxassetid://2815207981",
        ["Steve"]             = "rbxassetid://4965083997",
        ["Call of Duty"]      = "rbxassetid://5952120301",
        ["Bat"]               = "rbxassetid://3333907347",
        ["TF2 Critical"]      = "rbxassetid://296102734",
        ["Saber"]             = "rbxassetid://8415678813",
        ["Baimware"]          = "rbxassetid://3124331820",
        ["Osu"]               = "rbxassetid://7149255551",
        ["TF2"]               = "rbxassetid://2868331684",
        ["Slime"]             = "rbxassetid://6916371803",
        ["Among Us"]          = "rbxassetid://5700183626",
        ["One"]               = "rbxassetid://7380502345",
        ["Soft Bell"]         = "rbxassetid://9114487369",
        ["Minecraft Bow Hit"] = "rbxassetid://1053296915",
    }

    HPlist = {
        "Head","HumanoidRootPart","Torso","UpperTorso","LowerTorso",
        "Left Arm","LeftHand","LeftLowerArm","LeftUpperArm",
        "Right Arm","RightHand","RightLowerArm","RightUpperArm",
        "Left Leg","LeftFoot","LeftLowerLeg","LeftUpperLeg",
        "Right Leg","RightFoot","RightLowerLeg","RightUpperLeg",
        "Neck","Back","Front","Closest","Random"
    }
end


local antikatana = false
local katanausers = {}

local function detectkatana()
    local lp = Players.LocalPlayer
    if not lp:FindFirstChild("PlayerScripts") then
        lp.PlayerScriptsAdded:Wait()
    end
    task.spawn(function()
        local katana, attempts = nil, 0
        while attempts < 10 do
            pcall(function()
                local m = lp.PlayerScripts.Modules.Items:FindFirstChild("Katana", true)
                if m then katana = require(m) end
            end)
            if not katana then
                for _, m in pairs(lp.PlayerScripts:GetDescendants()) do
                    if m.Name == "Katana" and m:IsA("ModuleScript") then
                        local ok, res = pcall(require, m)
                        if ok then katana = res; break end
                    end
                end
            end
            if katana and type(katana) == "table" and katana.StartAiming then break end
            attempts += 1
            task.wait(1)
        end
        if katana and type(katana) == "table" and katana.StartAiming then
            local old = katana.StartAiming
            katana.StartAiming = function(self, force)
                local fighter = self.ClientFighter
                local player  = fighter and fighter.Player
                if player then
                    katanausers[player] = true
                    local dur = self.Info.DeflectDuration or 0.6
                    task.delay(dur, function() katanausers[player] = nil end)
                end
                return old(self, force)
            end
        end
    end)
end
detectkatana()

local function katanadeflect(player)
    return katanausers[player] == true
end


local function weaponstricted(weaponName)
    if not weaponName then return false end
    for _, w in ipairs(restricteditems) do
        if weaponName == w then return true end
    end
    return false
end

local cachedWeapon = nil
local function curweap2()
    if cachedWeapon then return cachedWeapon end
    local vm = Workspace:FindFirstChild("ViewModels")
    if not vm then return nil end
    local fp = vm:FindFirstChild("FirstPerson")
    if not fp then return nil end
    for _, child in ipairs(fp:GetChildren()) do
        local name = child.Name
        local dash = name:find("-")
        if dash then
            cachedWeapon = name:sub(dash + 1):match("^%s*(.-)%s*$")
            return cachedWeapon
        end
    end
    return nil
end
local function resetWeaponCache() cachedWeapon = nil end
task.spawn(function()
    local vm = Workspace:FindFirstChild("ViewModels")
    if vm then
        vm.DescendantAdded:Connect(resetWeaponCache)
        vm.DescendantRemoving:Connect(resetWeaponCache)
    end
end)


local fovScreenGui = Instance.new("ScreenGui")
fovScreenGui.Name            = "FOVScreenGui"
fovScreenGui.DisplayOrder    = INSTANCE_GAMEPLAY_OVERLAY_ORDER
fovScreenGui.ResetOnSpawn    = false
fovScreenGui.IgnoreGuiInset  = true
fovScreenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
pcall(function() fovScreenGui.Parent = game:GetService("CoreGui") end)


local function buildfov(name, cfg)
    local container = Instance.new("Frame")
    container.Name                   = name
    container.BackgroundTransparency = 1
    container.BorderSizePixel        = 0
    container.Visible                = false
    container.Parent                 = fovScreenGui

    local fill = Instance.new("Frame")
    fill.Size                   = UDim2.new(1, 0, 1, 0)
    fill.BackgroundColor3       = Color3.new(1, 1, 1)
    fill.BackgroundTransparency = cfg.FilledTransparency
    fill.BorderSizePixel        = 0
    fill.Visible                = false
    fill.ZIndex                 = 1
    fill.Parent                 = container

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent       = fill

    local fillgrad = Instance.new("UIGradient")
    fillgrad.Color    = ColorSequence.new({
        ColorSequenceKeypoint.new(0, cfg.FilledColor1),
        ColorSequenceKeypoint.new(1, cfg.FilledColor2),
    })
    fillgrad.Rotation = cfg.FilledRotation
    fillgrad.Parent   = fill

    local outline = Instance.new("Frame")
    outline.Size                   = UDim2.new(1, 0, 1, 0)
    outline.BackgroundTransparency = 1
    outline.BorderSizePixel        = 0
    outline.ZIndex                 = 2
    outline.Parent                 = container

    local outlineCorner = Instance.new("UICorner")
    outlineCorner.CornerRadius = UDim.new(1, 0)
    outlineCorner.Parent       = outline

    local stroke = Instance.new("UIStroke")
    stroke.Color           = Color3.new(1, 1, 1)
    stroke.Thickness       = cfg.OutlineThickness
    stroke.Transparency    = cfg.OutlineTransparency
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent          = outline

    local strokegrad = Instance.new("UIGradient")
    strokegrad.Color    = ColorSequence.new({
        ColorSequenceKeypoint.new(0, cfg.OutlineColor1),
        ColorSequenceKeypoint.new(1, cfg.OutlineColor2),
    })
    strokegrad.Rotation = cfg.OutlineRotation
    strokegrad.Parent   = stroke

    return {
        container      = container,
        fill           = fill,
        fillgrad   = fillgrad,
        stroke         = stroke,
        strokegrad = strokegrad,
    }
end


local silentFOVCfg = {
    OutlineColor1       = Color3.fromRGB(255, 255, 255),
    OutlineColor2       = Color3.fromRGB(255, 255, 255),
    OutlineRotation     = 0,
    OutlineThickness    = 1.5,
    OutlineTransparency = 0,
    FilledEnabled       = false,
    FilledColor1        = Color3.fromRGB(255, 255, 255),
    FilledColor2        = Color3.fromRGB(0, 0, 0),
    FilledRotation      = 0,
    FilledTransparency  = 0.7,
    FilledAnimated      = false,
    FilledSpeed         = 1,
    SpinOn              = false,
    SpinSpd             = 1,
}

local sFOV                = buildfov("SilentFOV", silentFOVCfg)
local silentFOVContainer  = sFOV.container
local silentFOVFill       = sFOV.fill
local silentFOVFillGrad   = sFOV.fillgrad
local silentFOVStroke     = sFOV.stroke
local silentFOVStrokeGrad = sFOV.strokegrad

local function silentlinegrad()
    silentFOVStrokeGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, silentFOVCfg.OutlineColor1),
        ColorSequenceKeypoint.new(1, silentFOVCfg.OutlineColor2),
    })
end
local function updsilentgrad()
    silentFOVFillGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, silentFOVCfg.FilledColor1),
        ColorSequenceKeypoint.new(1, silentFOVCfg.FilledColor2),
    })
end


local aimbotFOVCfg = {
    OutlineColor1       = Color3.fromRGB(255, 255, 255),
    OutlineColor2       = Color3.fromRGB(255, 255, 255),
    OutlineRotation     = 0,
    OutlineThickness    = 1.5,
    OutlineTransparency = 0,
    FilledEnabled       = false,
    FilledColor1        = Color3.fromRGB(255, 255, 255),
    FilledColor2        = Color3.fromRGB(0, 0, 0),
    FilledRotation      = 0,
    FilledTransparency  = 0.7,
    FilledAnimated      = false,
    FilledSpeed         = 1,
    SpinOn              = false,
    SpinSpd             = 1,
}

local aFOV                = buildfov("AimbotFOV", aimbotFOVCfg)
local aimbotFOVContainer  = aFOV.container
local aimbotFOVFill       = aFOV.fill
local aimbotFOVFillGrad   = aFOV.fillgrad
local aimbotFOVStroke     = aFOV.stroke
local aimbotFOVStrokeGrad = aFOV.strokegrad

local function updaimbotoutlinegrad()
    aimbotFOVStrokeGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, aimbotFOVCfg.OutlineColor1),
        ColorSequenceKeypoint.new(1, aimbotFOVCfg.OutlineColor2),
    })
end
local function updaimbotfillgrad()
    aimbotFOVFillGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, aimbotFOVCfg.FilledColor1),
        ColorSequenceKeypoint.new(1, aimbotFOVCfg.FilledColor2),
    })
end


local bulletTracer = { enabled=false, color=Color3.fromRGB(255,255,255), style="Line", glow=0, size=1, duration=3, fadeTime=0.5 }

local DISABLE_TRACERS = false
local hitSound     = { enabled=false, style="Rust HS", volume=0.5, pitch=1.0 }
local localHitTargets = setmetatable({}, { __mode = "k" })
local silentAim    = { enabled=false, hitPart="Head", fovRadius=100, autoShoot=false, followMuzzle=false, followTarget=false, followTargetSmoothness=0, hitChance=100 }
local aimbot       = {
    enabled = false,
    masterEnabled = false,
    keyMode = "always",
    showFov = false,
    targetPart = "Head",
    fovRadius = 500,
    smoothness = 2,
    aimCurve = "Linear",
    followMuzzle = false,
    followTarget = false,
    followTargetSmoothness = 5,
    lockedTarget = nil,
    smoothCF = nil,
    wallCheck = false,
}
local backshoot    = { enabled=false, connection=nil, target=nil, origCFrame=nil }

local bulletTracers    = {}
local lastShotTime     = 0
local lastShootSoundAt = 0
local shootCooldown    = 0.1
local curtarget    = nil
local targetlasthp = setmetatable({}, { __mode = "k" })
local lastHitTime      = 0

Players.PlayerRemoving:Connect(function(player)
    targetlasthp[player] = nil
end)


local function muzzlepos()
    local vm = Workspace:FindFirstChild("ViewModels")
    if not vm then return nil end
    local fp = vm:FindFirstChild("FirstPerson")
    if not fp then return nil end
    local pn = LocalPlayer.Name
    for _, model in pairs(fp:GetChildren()) do
        if model:IsA("Model") and model.Name:find("^"..pn) then
            local iv = model:FindFirstChild("ItemVisual")
            if iv then
                local b = iv:FindFirstChild("Body")
                if b then
                    local bp = b:FindFirstChild("BodyPrimary")
                    if bp then
                        local muzzle = bp:FindFirstChild("_muzzle")
                        if muzzle and muzzle:IsA("Attachment") then
                            return muzzle.WorldPosition
                        end
                    end
                end
            end
        end
    end
    return nil
end

local function screenpos2(worldPos)
    if not worldPos then return nil end
    local sp, ok = worldToScreen(worldPos, Camera)
    if not ok then return nil end
    return Vector2.new(sp.X, sp.Y)
end

local function getRagebotTarget()
    return getgenv().InstanceRagebotTarget
end

local function targetScreenPos(target)
    if not target then return nil end
    local hrp = target:IsA("Player") and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
        or target:FindFirstChild("HumanoidRootPart")
        or target:IsA("BasePart") and target
    if not hrp then return nil end
    return screenpos2(hrp.Position)
end

getgenv().getBestTargetScreenPos = function()
    local s
    if type(aimbot) == "table" and aimbot.lockedTarget then
        s = targetScreenPos(aimbot.lockedTarget)
        if s then return s end
    end
    local rageTarget = getRagebotTarget()
    if rageTarget then
        s = targetScreenPos(rageTarget)
        if s then return s end
    end
    if curtarget then
        s = targetScreenPos(curtarget)
        if s then return s end
    end
    local cam = Camera or workspace.CurrentCamera
    if not cam then return nil end
    local best, bestDist = nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and root then
                local pos, onScreen = worldToScreen(root.Position, cam)
                if onScreen then
                    local dx = pos.X - cam.ViewportSize.X * 0.5
                    local dy = pos.Y - cam.ViewportSize.Y * 0.5
                    local dist = dx * dx + dy * dy
                    if dist < bestDist then
                        bestDist = dist
                        best = pos
                    end
                end
            end
        end
    end
    if best then return Vector2.new(best.X, best.Y) end
    return nil
end
local getBestTargetScreenPos = getgenv().getBestTargetScreenPos

local function silentfovcenter()
    if silentAim.followTarget then
        local s = getBestTargetScreenPos()
        if s then return s end
    end
    if silentAim.followMuzzle then
        local s = screenpos2(muzzlepos())
        if s then return s end
    end
    return screenCenter(Camera)
end

local function aimbotfovcenter()
    if aimbot.followTarget then
        local s = getBestTargetScreenPos()
        if s then return s end
    end
    if aimbot.followMuzzle then
        local s = screenpos2(muzzlepos())
        if s then return s end
    end
    return screenCenter(Camera)
end


local function makebullettracer(pos3, endPos, isHit)
    if DISABLE_TRACERS then return nil end
    if isHit then
        local mp = muzzlepos()
        if mp then pos3 = mp end
    end
    local cfg = bulletTracer

    if isHit and cfg.style == "Line" then
        local dir    = endPos - pos3
        local dist   = dir.Magnitude
        local segs   = {}
        local segLen = 5
        for i = 1, math.ceil(dist/segLen) do
            local s  = pos3 + dir.Unit*((i-1)*segLen)
            local e  = pos3 + dir.Unit*math.min(i*segLen, dist)
            local ln = Drawing.new("Line")
            ln.Thickness    = 2*cfg.size
            ln.Color        = cfg.color
            ln.Transparency = 1
            ln.Visible      = false
            table.insert(segs, {Line=ln, StartPos=s, EndPos=e})
        end
        local t = {
            Segments      = segs,
            Lifetime      = cfg.duration,
            CreatedTime   = tick(),
            IsHitTracer   = true,
            Is2D          = true,
            FadeStartTime = tick()+cfg.duration-cfg.fadeTime,
            StartPos      = pos3,
            EndPos        = endPos,
        }
        table.insert(bulletTracers, t)
        return t
    end

    local a0   = Instance.new("Attachment"); a0.Parent = workspace.Terrain
    local a1   = Instance.new("Attachment"); a1.Parent = workspace.Terrain
    local beam = Instance.new("Beam")
    beam.Attachment0 = a0
    beam.Attachment1 = a1
    beam.Color       = ColorSequence.new(cfg.color)
    local bw = cfg.style=="Laser" and 0.02 or (cfg.style=="Line" and 0.05 or 0.15)
    beam.Width0        = bw*cfg.size
    beam.Width1        = bw*cfg.size
    beam.Transparency  = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.8, 0.1),
        NumberSequenceKeypoint.new(1, 0.5),
    })
    beam.FaceCamera    = false
    beam.LightEmission = cfg.glow
    beam.LightInfluence = 1-cfg.glow
    local glow = nil
    if cfg.glow > 0.3 then
        glow            = Instance.new("PointLight")
        glow.Brightness = cfg.glow*2
        glow.Range      = 10*cfg.size
        glow.Color      = cfg.color
        glow.Parent     = a1
    end
    if cfg.style == "Line" then
        beam.Texture       = ""
        beam.TextureLength = 1
        beam.TextureSpeed  = 0
    elseif textureAssets[cfg.style] then
        beam.Texture       = textureAssets[cfg.style]
        beam.TextureLength = 4
        beam.TextureSpeed  = 1
    else
        beam.Texture = ""
    end
    beam.Parent        = workspace.Terrain
    a0.WorldPosition   = pos3
    a1.WorldPosition   = endPos
    local t = {
        Line          = beam,
        Attachment0   = a0,
        Attachment1   = a1,
        Light         = glow,
        Lifetime      = cfg.duration,
        CreatedTime   = tick(),
        IsHitTracer   = isHit,
        Is2D          = false,
        FadeStartTime = tick()+cfg.duration-cfg.fadeTime,
    }
    table.insert(bulletTracers, t)
    return t
end

local function updateTracerGlow()
    for _, tr in ipairs(bulletTracers) do
        if tr and not tr.Is2D and tr.Line then
            local age = tick()-tr.CreatedTime
            local cfg = bulletTracer
            if age >= tr.FadeStartTime then
                local fp = math.clamp((age-tr.FadeStartTime)/cfg.fadeTime, 0, 1)
                tr.Line.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, fp),
                    NumberSequenceKeypoint.new(0.8, fp+0.1),
                    NumberSequenceKeypoint.new(1, 1),
                })
                if tr.Line.LightEmission > 0 then
                    tr.Line.LightEmission = cfg.glow*(1-fp)
                end
                if tr.Light then
                    tr.Light.Brightness = tr.Light.Brightness*(1-fp)
                end
            end
        end
    end
end

local function findShotMuzzlePosition()
    local myChar = LocalPlayer.Character
    if not myChar then
        local cam = workspace.CurrentCamera
        return cam and (cam.CFrame.Position + cam.CFrame.LookVector * 4) or Vector3.zero
    end

    local vm = Workspace:FindFirstChild("ViewModels")
    if vm then
        local fp = vm:FindFirstChild("FirstPerson")
        if fp then
            for _, model in ipairs(fp:GetChildren()) do
                if not model:IsA("Model") then
                    continue
                end
                local muzzle = model:FindFirstChild("Muzzle")
                    or model:FindFirstChild("MuzzleFlash")
                    or model:FindFirstChild("Barrel")
                    or model:FindFirstChild("GunTip")
                    or model:FindFirstChild("Flash")
                    or model:FindFirstChild("Fire")
                    or model:FindFirstChild("Tip")
                if muzzle then
                    if muzzle:IsA("Attachment") then
                        return muzzle.WorldPosition
                    end
                    if muzzle:IsA("BasePart") then
                        return muzzle.Position
                    end
                end
                for _, part in ipairs(model:GetChildren()) do
                    if part:IsA("BasePart") then
                        local pn = part.Name:lower()
                        if pn:find("tip") or pn:find("barrel") or pn:find("muzzle") or pn:find("flash") or pn:find("fire") or pn:find("gun") then
                            return part.Position
                        end
                    end
                end
                local pp = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
                if pp then
                    return pp.Position
                end
            end
        end
    end

    local cam = workspace.CurrentCamera
    if cam then
        return cam.CFrame.Position + cam.CFrame.LookVector * 4
    end
    local root = myChar:FindFirstChild("HumanoidRootPart")
    return root and root.Position or Vector3.zero
end

local trackedAmmo = nil
local bulletDetectConn = nil
local projectileDetectConn = nil
local vmSoundConn = nil

_G.Features = _G.Features or {}
_G.Features.DisableGunSounds = _G.Features.DisableGunSounds or false

local function shootSoundsActive()
    return _G.Features.DisableGunSounds == true
end

local function restoreGunSoundVolumes()
    local function tryRestore(root)
        if not root then return end
        for _, d in ipairs(root:GetDescendants()) do
            if d:IsA("Sound") and isRivalsGunSound(d) and not d:GetAttribute("InstanceShootSound") then
                pcall(function()
                    if d.Volume <= 0 then
                        d.Volume = 1
                    end
                end)
            elseif d:IsA("SoundGroup") then
                pcall(function()
                    if d.Volume <= 0 then
                        d.Volume = 1
                    end
                end)
            end
        end
    end
    tryRestore(workspace:FindFirstChild("ViewModels"))
    local cam = workspace.CurrentCamera
    if cam then
        tryRestore(cam)
    end
    local char = LocalPlayer.Character
    if char then
        tryRestore(char)
    end
end

local function bulletFeedbackActive()
    return bulletTracer.enabled
end

local function getFighterController()
    local ps = LocalPlayer:FindFirstChild("PlayerScripts")
    if not ps then
        return nil
    end
    local controllers = ps:FindFirstChild("Controllers")
    if not controllers then
        return nil
    end
    local fighterModule = controllers:FindFirstChild("FighterController")
    if not fighterModule or not fighterModule:IsA("ModuleScript") then
        return nil
    end
    local ok, ctrl = pcall(require, fighterModule)
    if ok then
        return ctrl
    end
    return nil
end

local function getLocalEquippedAmmo()
    local ctrl = getFighterController()
    if ctrl and ctrl.LocalFighter and ctrl.LocalFighter.EquippedItem then
        local item = ctrl.LocalFighter.EquippedItem
        local current = item:Get("CurrentAmmo")
        if current == nil then
            current = item:Get("Ammo")
        end
        if current == nil then
            current = item:Get("Bullets")
        end
        local maxAmmo = item:Get("MaxAmmo") or item:Get("MaxBullets") or 0
        if current ~= nil then
            return current, maxAmmo
        end
    end

    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if pg then
        for _, v in ipairs(pg:GetDescendants()) do
            if v:IsA("Frame") and v.Visible then
                local reserve = v:FindFirstChild("Reserve")
                if reserve and v:FindFirstChild("Icon") and v:FindFirstChild("ItemName") then
                    local ammoLabel = reserve:FindFirstChild("Ammo")
                    if ammoLabel then
                        local current = tonumber(ammoLabel.Text:match("%d+")) or 0
                        return current, current
                    end
                end
            end
        end
    end

    return nil, nil
end

local function isProjectilePartName(name)
    if not name then
        return false
    end
    return name == "Slingshot"
        or name == "CoreProjectile"
        or name == "OuterProjectile"
        or name:find("Projectile", 1, true) ~= nil
end

local function isLikelyLocalProjectile(inst)
    if not inst then
        return false
    end

    local part = inst:IsA("BasePart") and inst or inst:FindFirstChildWhichIsA("BasePart")
    if not part then
        if inst:IsA("Model") then
            part = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart")
        end
    end
    if not part then
        return false
    end

    if not isProjectilePartName(inst.Name) and not isProjectilePartName(part.Name) then
        local namedChild = inst:FindFirstChild("CoreProjectile", true)
            or inst:FindFirstChild("OuterProjectile", true)
            or inst:FindFirstChild("Slingshot", true)
        if not namedChild then
            return false
        end
        part = namedChild:IsA("BasePart") and namedChild or namedChild:FindFirstChildWhichIsA("BasePart") or part
    end

    local muzzle = findShotMuzzlePosition()
    if (part.Position - muzzle).Magnitude <= 45 then
        return true
    end

    local cam = workspace.CurrentCamera
    if cam and (part.Position - cam.CFrame.Position).Magnitude <= 45 then
        return true
    end

    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if myRoot and (part.Position - myRoot.Position).Magnitude <= 45 then
        return true
    end

    return false
end

local function isRivalsGunSound(sound)
    if typeof(sound) ~= "Instance" or not sound:IsA("Sound") then
        return false
    end
    if sound:GetAttribute("InstanceShootSound") then
        return false
    end

    local parent = sound.Parent
    if not parent then
        return false
    end

    local vm = workspace:FindFirstChild("ViewModels")
    if vm and sound:IsDescendantOf(vm) then
        return true
    end

    local cam = workspace.CurrentCamera
    if cam and sound:IsDescendantOf(cam) then
        return true
    end

    local char = LocalPlayer.Character
    if char and sound:IsDescendantOf(char) then
        local n = sound.Name:lower()
        if n:find("gun") or n:find("fire") or n:find("shoot") or n:find("weapon")
            or n:find("muzzle") or n:find("shell") or n:find("reload")
            or n:find("bolt") or n:find("chamber") or n:find("rifle")
            or n:find("pistol") or n:find("shotgun") or n:find("bullet") then
            return true
        end
    end

    return false
end

local function silenceRivalsGunSound(sound)
    if not isRivalsGunSound(sound) then
        return
    end
    pcall(function()
        sound:Stop()
    end)
    sound.Volume = 0
end

local function bindGunSoundMuteGuard(sound)
    if typeof(sound) ~= "Instance" or not sound:IsA("Sound") or sound:GetAttribute("InstanceShootSound") then
        return
    end
    if not sound:GetAttribute("InstanceGunMuteBound") then
        sound:SetAttribute("InstanceGunMuteBound", true)
        sound:GetPropertyChangedSignal("Volume"):Connect(function()
            if shootSoundsActive() and isRivalsGunSound(sound) then
                pcall(function()
                    sound.Volume = 0
                end)
            end
        end)
        sound:GetPropertyChangedSignal("Playing"):Connect(function()
            if not sound.Playing or not isRivalsGunSound(sound) then
                return
            end
            task.defer(function()
                if bulletFeedbackActive() then
                    handleLocalShot(true)
                else
                    registerLocalShot(true)
                end
            end)
            if shootSoundsActive() then
                silenceRivalsGunSound(sound)
            end
        end)
    end
    if shootSoundsActive() then
        silenceRivalsGunSound(sound)
    end
end

local function refreshGunSoundMute()
    if not shootSoundsActive() then
        return
    end

    local vm = workspace:FindFirstChild("ViewModels")
    if vm then
        for _, d in ipairs(vm:GetDescendants()) do
            if d:IsA("Sound") or d:IsA("SoundGroup") then
                if d:IsA("Sound") then
                    bindGunSoundMuteGuard(d)
                else
                    d.Volume = 0
                end
            end
        end
    end

    local cam = workspace.CurrentCamera
    if cam then
        for _, d in ipairs(cam:GetDescendants()) do
            if d:IsA("Sound") then
                bindGunSoundMuteGuard(d)
            end
        end
    end
end

getgenv().InstanceRefreshGunSoundMute = refreshGunSoundMute

local function registerLocalShot(bypassCooldown)
    local cw = curweap2()
    if not cw or weaponstricted(cw) then
        return
    end

    local now = tick()
    if not bypassCooldown and now - lastShotTime < shootCooldown then
        return
    end
    lastShotTime = now
    markCombatShot()
end

local function handleLocalShot(bypassCooldown)
    registerLocalShot(bypassCooldown)

    local muzzlePos = findShotMuzzlePosition()
    local endPos
    local hitInstance

    if muzzlePos then
        local camCFrame = Camera.CFrame
        endPos = camCFrame.Position + camCFrame.LookVector * 1000
        local params = RaycastParams.new()
        params.FilterDescendantsInstances = { LocalPlayer.Character }
        params.FilterType = Enum.RaycastFilterType.Blacklist
        local res = workspace:Raycast(muzzlePos, (endPos - muzzlePos).Unit * 1000, params)
        if res then
            endPos = res.Position
            hitInstance = res.Instance
        end
    end

    if hitInstance then
        notifyProjectileImpact(hitInstance)
    end

    if not bulletTracer.enabled or not muzzlePos then
        return
    end

    makebullettracer(muzzlePos, endPos, hitInstance ~= nil)
end

getgenv().InstanceHandleLocalShot = handleLocalShot

local function startAmmoBulletDetection()
    if bulletDetectConn then
        return
    end
    local nextAmmoCheck = 0
    bulletDetectConn = RunService.Heartbeat:Connect(function()
        local now = tick()
        if now < nextAmmoCheck then
            return
        end
        nextAmmoCheck = now + 0.25

        pcall(function()
            if shootSoundsActive() then
                refreshGunSoundMute()
            end

            local ammoNow = getLocalEquippedAmmo()
            if ammoNow == nil then
                trackedAmmo = nil
                return
            end

            if trackedAmmo ~= nil and ammoNow < trackedAmmo then
                local fired = math.floor(trackedAmmo - ammoNow)
                for i = 1, fired do
                    if bulletFeedbackActive() then
                        handleLocalShot(true)
                    else
                        registerLocalShot(true)
                    end
                end
            end

            trackedAmmo = ammoNow
        end)
    end)
end

local function bindProjectileImpactDetection(projectile)
    if not projectile then
        return
    end

    local handled = false
    local playerFromHitPartFn = getPlayerFromHitPart
    local notifyImpactFn = notifyProjectileImpact

    local function onTouched(hit)
        if handled or not hit or not hit.Parent then
            return
        end
        if type(notifyImpactFn) == "function" then
            notifyImpactFn(hit)
        end

        if type(playerFromHitPartFn) ~= "function" then
            return
        end
        local plr, hum = playerFromHitPartFn(hit)
        if not plr or not hum or plr == player then
            handled = true
            return
        end
        handled = true
    end

    local function bindPart(part)
        if not part or not part:IsA("BasePart") then
            return
        end
        part.Touched:Connect(onTouched)
    end

    bindPart(projectile)
    for _, child in ipairs(projectile:GetDescendants()) do
        bindPart(child)
    end
end

local function startProjectileBulletDetection()
    if projectileDetectConn then
        return
    end
    projectileDetectConn = workspace.DescendantAdded:Connect(function(d)
        if not isLikelyLocalProjectile(d) then
            return
        end

        task.defer(function()
            if bulletFeedbackActive() then
                handleLocalShot(true)
            else
                registerLocalShot(true)
            end
            bindProjectileImpactDetection(d)
        end)
    end)
end

local function bindCombatShotSounds(root)
    if not root then
        return
    end
    for _, d in ipairs(root:GetDescendants()) do
        if d:IsA("Sound") then
            bindGunSoundMuteGuard(d)
        end
    end
end

local realShotHookInstalled = false

local function setupShootDetection()
    if realShotHookInstalled then
        return
    end
    realShotHookInstalled = true

    startAmmoBulletDetection()
    startProjectileBulletDetection()

    local vm = workspace:FindFirstChild("ViewModels")
    if not vm then
        vm = workspace:WaitForChild("ViewModels", 10)
    end
    if vm and not vmSoundConn then
        bindCombatShotSounds(vm)
        vmSoundConn = vm.DescendantAdded:Connect(function(d)
            if d:IsA("Sound") then
                bindGunSoundMuteGuard(d)
            elseif d:IsA("SoundGroup") and shootSoundsActive() then
                pcall(function()
                    d.Volume = 0
                end)
            end
        end)
    end

    local cam = workspace.CurrentCamera
    if cam then
        bindCombatShotSounds(cam)
    end

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then
            return
        end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
            return
        end
        if UserInputService:GetFocusedTextBox() then
            return
        end

        if bulletFeedbackActive() then
            handleLocalShot(false)
        else
            registerLocalShot(false)
        end
    end)

    refreshGunSoundMute()
end

task.defer(setupShootDetection)

local function playHS()
    local id = soundsassets[hitSound.style]
    if not id then return end
    local snd    = Instance.new("Sound")
    snd.SoundId  = id
    snd.Volume   = hitSound.volume
    snd.Pitch    = hitSound.pitch
    local cam    = workspace.CurrentCamera
    if cam then
        local att = Instance.new("Attachment")
        att.Parent = cam
        snd.Parent = att
    else
        snd.Parent = workspace
    end
    snd:Play()
    game:GetService("Debris"):AddItem(snd, 5)
    if snd.Parent then
        game:GetService("Debris"):AddItem(snd.Parent, 5)
    end
end

local function checkForHit()
    if not curtarget then return end
    local char = curtarget
    if not char or not char.Parent then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local tp = Players:GetPlayerFromCharacter(char)
    if not tp then return end
    local lastHp = targetlasthp[tp] or hum.Health
    if hum.Health < lastHp then
        local myChar = LocalPlayer.Character
        if myChar and myChar:FindFirstChild("HumanoidRootPart") then
            local tr = char:FindFirstChild("HumanoidRootPart")
            if tr then
                local dist = (myChar.HumanoidRootPart.Position - tr.Position).Magnitude
                if dist <= 1500 then
                    local dir    = (tr.Position - myChar.HumanoidRootPart.Position).Unit
                    local params = RaycastParams.new()
                    params.FilterDescendantsInstances = {myChar, char}
                    params.FilterType = Enum.RaycastFilterType.Exclude
                    local res     = workspace:Raycast(myChar.HumanoidRootPart.Position, dir*dist, params)
                    local visible = true
                    if res then
                        local hp = res.Instance.Parent
                        if hp ~= char and hp.Parent ~= char then visible = false end
                    end
                    if visible and tick()-lastHitTime > 0.05 then
                        lastHitTime = tick()
                        if hitSound.enabled then task.spawn(playHS) end
                    end
                end
            end
        end
    end
    targetlasthp[tp] = hum.Health
end


local silentFOVSmoothPos = Vector2.new(0, 0)
local aimbotFOVSmoothPos = Vector2.new(0, 0)
local silentFOVSmoothInit = false
local aimbotFOVSmoothInit = false

RunService.RenderStepped:Connect(function()
    local showSilentFOV = silentFOVContainer.Visible
    local showAimbotFOV = aimbotFOVContainer.Visible
    local hasTracers     = #bulletTracers > 0
    if not showSilentFOV and not showAimbotFOV and not hasTracers then
        return
    end

    if showSilentFOV then
        local c = silentfovcenter()
        local r = silentAim.fovRadius
        silentFOVContainer.Size = UDim2.fromOffset(r*2, r*2)
        if silentAim.followTarget and silentAim.followTargetSmoothness > 0 then
            local smooth = silentAim.followTargetSmoothness * 10
            local alpha = math.clamp(1 / math.max(smooth, 1), 0, 1)
            if not silentFOVSmoothInit then
                silentFOVSmoothPos = c
                silentFOVSmoothInit = true
            end
            silentFOVSmoothPos = silentFOVSmoothPos:Lerp(c, alpha)
            silentFOVContainer.Position = UDim2.fromOffset(silentFOVSmoothPos.X - r, silentFOVSmoothPos.Y - r)
        else
            silentFOVSmoothInit = false
            silentFOVContainer.Position = UDim2.fromOffset(c.X - r, c.Y - r)
        end
        if silentFOVCfg.FilledAnimated then
            silentFOVFillGrad.Rotation = math.sin(tick()*silentFOVCfg.FilledSpeed)*180 + silentFOVCfg.FilledRotation
        elseif silentFOVCfg.SpinOn then
            silentFOVFillGrad.Rotation = silentFOVCfg.FilledRotation + (tick() * silentFOVCfg.SpinSpd * 90) % 360
        end
        if silentFOVCfg.SpinOn then
            silentFOVStrokeGrad.Rotation = silentFOVCfg.OutlineRotation + (tick() * silentFOVCfg.SpinSpd * 90) % 360
        end
    end

    if showAimbotFOV then
        local c = aimbotfovcenter()
        local r = aimbot.fovRadius
        aimbotFOVContainer.Size = UDim2.fromOffset(r*2, r*2)
        if aimbot.followTarget and aimbot.followTargetSmoothness > 0 then
            local smooth = aimbot.followTargetSmoothness * 10
            local alpha = math.clamp(1 / math.max(smooth, 1), 0, 1)
            if not aimbotFOVSmoothInit then
                aimbotFOVSmoothPos = c
                aimbotFOVSmoothInit = true
            end
            aimbotFOVSmoothPos = aimbotFOVSmoothPos:Lerp(c, alpha)
            aimbotFOVContainer.Position = UDim2.fromOffset(aimbotFOVSmoothPos.X - r, aimbotFOVSmoothPos.Y - r)
        else
            aimbotFOVSmoothInit = false
            aimbotFOVContainer.Position = UDim2.fromOffset(c.X - r, c.Y - r)
        end
        if aimbotFOVCfg.FilledAnimated then
            aimbotFOVFillGrad.Rotation = math.sin(tick()*aimbotFOVCfg.FilledSpeed)*180 + aimbotFOVCfg.FilledRotation
        elseif aimbotFOVCfg.SpinOn then
            aimbotFOVFillGrad.Rotation = aimbotFOVCfg.FilledRotation + (tick() * aimbotFOVCfg.SpinSpd * 90) % 360
        end
        if aimbotFOVCfg.SpinOn then
            aimbotFOVStrokeGrad.Rotation = aimbotFOVCfg.OutlineRotation + (tick() * aimbotFOVCfg.SpinSpd * 90) % 360
        end
    end

    if hasTracers then
        updateTracerGlow()
        local now   = tick()
        local cam   = Camera
        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local myPos  = myRoot and myRoot.Position

        for _, tr in ipairs(bulletTracers) do
            if tr and tr.Is2D and tr.Segments then
                local age = now - tr.CreatedTime
                for _, seg in ipairs(tr.Segments) do
                    local show = false
                    local from, to
                    local ss, ssOk = worldToScreen(seg.StartPos, cam)
                    local se, seOk = worldToScreen(seg.EndPos, cam)
                    if ssOk and seOk then
                        if not myPos or ((seg.StartPos - myPos).Magnitude >= 2 and (seg.EndPos - myPos).Magnitude >= 2) then
                            if math.abs(ss.X) <= 20000 and math.abs(ss.Y) <= 20000 and math.abs(se.X) <= 20000 and math.abs(se.Y) <= 20000 then
                                from = Vector2.new(ss.X, ss.Y)
                                to   = Vector2.new(se.X, se.Y)
                                local len = (to - from).Magnitude
                                if len > 0.1 and len < 3000 then
                                    show = true
                                end
                            end
                        end
                    end

                    if show then
                        seg.Line.From = from
                        seg.Line.To   = to
                        seg.Line.Visible = true
                        local ft = bulletTracer.fadeTime
                        if age >= tr.Lifetime - ft then
                            seg.Line.Transparency = 1 - math.clamp((age - (tr.Lifetime - ft)) / ft, 0, 1)
                        else
                            seg.Line.Transparency = 1
                        end
                    else
                        seg.Line.Visible = false
                    end
                end
            end
        end

        for i = #bulletTracers, 1, -1 do
            local tr = bulletTracers[i]
            if tr and now - tr.CreatedTime >= tr.Lifetime then
                if tr.Is2D and tr.Segments then
                    for _, seg in ipairs(tr.Segments) do
                        if seg.Line then seg.Line:Remove() end
                    end
                elseif tr.Line then
                    tr.Line:Destroy()
                end
                if tr.Attachment0 then tr.Attachment0:Destroy() end
                if tr.Attachment1 then tr.Attachment1:Destroy() end
                if tr.Light then tr.Light:Destroy() end
                table.remove(bulletTracers, i)
            end
        end
    end
    checkForHit()
end)

local function hitpartfromname(target, partName)
    local fc = function(n) return target:FindFirstChild(n) end
    if     partName == "Head"             then return fc("Head")
    elseif partName == "HumanoidRootPart" then return fc("HumanoidRootPart")
    elseif partName == "Torso"            then return fc("Torso") or fc("UpperTorso")
    elseif partName == "UpperTorso"       then return fc("UpperTorso")
    elseif partName == "LowerTorso"       then return fc("LowerTorso")
    elseif partName == "Left Arm"         then return fc("Left Arm") or fc("LeftUpperArm")
    elseif partName == "LeftHand"         then return fc("LeftHand") or fc("Left Arm")
    elseif partName == "LeftLowerArm"     then return fc("LeftLowerArm")
    elseif partName == "LeftUpperArm"     then return fc("LeftUpperArm")
    elseif partName == "Right Arm"        then return fc("Right Arm") or fc("RightUpperArm")
    elseif partName == "RightHand"        then return fc("RightHand") or fc("Right Arm")
    elseif partName == "RightLowerArm"    then return fc("RightLowerArm")
    elseif partName == "RightUpperArm"    then return fc("RightUpperArm")
    elseif partName == "Left Leg"         then return fc("Left Leg") or fc("LeftUpperLeg")
    elseif partName == "LeftFoot"         then return fc("LeftFoot") or fc("Left Leg")
    elseif partName == "LeftLowerLeg"     then return fc("LeftLowerLeg")
    elseif partName == "LeftUpperLeg"     then return fc("LeftUpperLeg")
    elseif partName == "Right Leg"        then return fc("Right Leg") or fc("RightUpperLeg")
    elseif partName == "RightFoot"        then return fc("RightFoot") or fc("Right Leg")
    elseif partName == "RightLowerLeg"    then return fc("RightLowerLeg")
    elseif partName == "RightUpperLeg"    then return fc("RightUpperLeg")
    elseif partName == "Neck"             then return fc("Neck")
    elseif partName == "Back"             then return fc("Back") or fc("HumanoidRootPart")
    elseif partName == "Front"            then return fc("Front") or fc("HumanoidRootPart")
    elseif partName == "Closest" then
        local camPos  = Camera.CFrame.Position
        local camLook = Camera.CFrame.LookVector
        local best, bestD = nil, math.huge
        for _, part in pairs(target:GetChildren()) do
            if part:IsA("BasePart") then
                local d = 1 - camLook:Dot((part.Position-camPos).Unit)
                if d < bestD then bestD=d; best=part end
            end
        end
        return best or fc("HumanoidRootPart")
    elseif partName == "Random" then
        local list = {}
        for _, part in pairs(target:GetChildren()) do
            if part:IsA("BasePart") then table.insert(list, part) end
        end
        if #list > 0 then return list[math.random(1, #list)] end
    end
    return target:FindFirstChild("HumanoidRootPart")
end

local function shouldHitTarget()
    if silentAim.hitChance >= 100 then return true end
    if silentAim.hitChance <= 0   then return false end
    return math.random(1, 100) <= silentAim.hitChance
end

local fovLastScan = 0
local fovScanInterval = 0.08
local fovCached = nil
local function closestinfov(radius, center)
    local now = tick()
    if now - fovLastScan < fovScanInterval and fovCached then
        local hum = fovCached:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then return fovCached end
    end
    fovLastScan = now
    local closest, closestDist = nil, math.huge
    local cam = Camera
    local radiusSq = radius * radius
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 and not char:FindFirstChildOfClass("ForceField") then
                    local root = char:FindFirstChild("HumanoidRootPart")
                    if root then
                        local pos, onScreen = worldToScreen(root.Position, cam)
                        if onScreen then
                            local dx = pos.X - center.X
                            local dy = pos.Y - center.Y
                            local distSq = dx*dx + dy*dy
                            if distSq <= radiusSq and distSq < closestDist then
                                closest = char
                                closestDist = distSq
                            end
                        end
                    end
                end
            end
        end
    end
    fovCached = closest
    return closest
end

local function closestplayerinfov(radius)
    local c = closestinfov(radius, silentfovcenter())
    curtarget = c
    return c
end


local localFighter   = nil
local lastFireTime   = 0
local fireCooldown   = 0

local function firesilent()
    if not silentAim.enabled then return end
    local cw = curweap2()
    if cw and weaponstricted(cw) then return end
    local now = tick()
    if now - lastFireTime < fireCooldown then return end
    local closest = closestplayerinfov(silentAim.fovRadius)
    if not closest then return end
    local tp = Players:GetPlayerFromCharacter(closest)
    if antikatana and tp and katanadeflect(tp) then return end
    local part = hitpartfromname(closest, silentAim.hitPart)
    if not part then return end
    local myChar = LocalPlayer.Character
    local root   = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local equipped = localFighter and localFighter.EquippedItem
    if not equipped then return end
    local objId = equipped:Get("ObjectID")
    if not objId then return end
    lastFireTime  = now
    local cam = workspace.CurrentCamera
    local shootPos  = cam and cam.CFrame.Position or root.Position
    local targetPos = part.Position
    local hitRoll = shouldHitTarget()
    if not hitRoll then
        if cam then
            local missOffset = Vector3.new(
                (math.random() - 0.5) * 20,
                (math.random() - 0.5) * 20,
                (math.random() - 0.5) * 10
            )
            targetPos = cam.CFrame.Position + cam.CFrame.LookVector * 100 + missOffset
        end
    end
    local aimDir = (targetPos - shootPos).Unit
    local aimCFrame = CFrame.lookAt(shootPos, shootPos + aimDir)
    local data = {
        [utf8.char(1)] = {
            [utf8.char(0)] = Utility:EncodeCFrame(aimCFrame),
            [utf8.char(1)] = Utility:EncodeCFrame(aimCFrame),
            [utf8.char(2)] = part,
            [utf8.char(3)] = Utility:EncodeCFrame(CFrame.new(0.43, 0.25, 0.42)),
        },
    }
    pcall(function()
        ReplicatedStorage.Remotes.Replication.Fighter.UseItem:FireServer(
            objId,
            EnumLibrary:ToEnum("StartShooting"),
            data,
            nil
        )
    end)
end

RunService.Heartbeat:Connect(function()
    if silentAim.enabled then
        if getgenv()._rageDelayActive then return end
        if config and config.target and config.target.enabled and not getgenv()._rageCanShoot then return end
        if silentAim.autoShoot or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            firesilent()
        end
    end
end)


repeat task.wait() until game:IsLoaded() and LocalPlayer.Parent and LocalPlayer:FindFirstChild("PlayerScripts")

local camController
pcall(function()
    local ctrl = LocalPlayer.PlayerScripts:WaitForChild("Controllers", 10)
    local cm   = ctrl:FindFirstChild("CameraController")
    if cm and cm:IsA("ModuleScript") then camController = require(cm) end
    local fm   = ctrl:FindFirstChild("FighterController")
    if fm and fm:IsA("ModuleScript") then
        local fc   = require(fm)
        localFighter = fc.LocalFighter
    end
end)

local function clearAimbotLock()
    aimbot.lockedTarget = nil
    aimbot.smoothCF = nil
end

local function getAimbotScreenPoint()
    if aimbot.followTarget or aimbot.followMuzzle then
        return aimbotfovcenter()
    end
    local loc = UserInputService:GetMouseLocation()
    return Vector2.new(loc.X, loc.Y)
end

local function closesttocursor()
    local best, bestDist = nil, aimbot.fovRadius
    local mp = getAimbotScreenPoint()
    if not mp then
        return nil
    end
    local cam = workspace.CurrentCamera or Camera
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myPos = myRoot and myRoot.Position
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local part = p.Character:FindFirstChild(aimbot.targetPart)
            if part and part:IsDescendantOf(workspace) then
                if aimbot.wallCheck and myPos then
                    local params = RaycastParams.new()
                    params.FilterDescendantsInstances = { myChar }
                    params.FilterType = Enum.RaycastFilterType.Exclude
                    local dir = part.Position - myPos
                    local result = workspace:Raycast(myPos, dir, params)
                    if result then
                        local hitPart = result.Instance
                        local hitModel = hitPart and hitPart:FindFirstAncestorOfClass("Model")
                        local hitPlayer = hitModel and Players:GetPlayerFromCharacter(hitModel)
                        if not hitPlayer or hitPlayer ~= p then
                            continue
                        end
                    end
                end
                local scr, on = worldToScreen(part.Position, cam)
                if on then
                    local dx = scr.X - mp.X
                    local dy = scr.Y - mp.Y
                    local dist = math.sqrt(dx * dx + dy * dy)
                    if dist < bestDist then
                        bestDist = dist
                        best = part
                    end
                end
            end
        end
    end
    return best
end

local function getAimbotLerpAlpha(dt)
    local smoothness = math.clamp(tonumber(aimbot.smoothness) or 2, 0.1, 10)
    local curve = aimbot.aimCurve or "Linear"
    local speed = 6 / smoothness

    if curve == "Instant" then
        return 1
    elseif curve == "Expo" then
        return 1 - math.exp(-(4 / smoothness) * dt)
    elseif curve == "EaseIn" then
        local t = math.clamp(speed * dt, 0, 1)
        return t * t
    elseif curve == "EaseOut" then
        local t = math.clamp(speed * dt, 0, 1)
        return 1 - (1 - t) * (1 - t)
    elseif curve == "EaseInOut" then
        local t = math.clamp(speed * dt, 0, 1)
        if t < 0.5 then
            return 2 * t * t
        end
        return 1 - ((-2 * t + 2) ^ 2) / 2
    elseif curve == "Cubic" then
        local t = math.clamp(speed * dt, 0, 1)
        return t * t * t
    end

    return math.clamp(speed * dt, 0, 1)
end

local AIMBOT_RENDER_BIND = "InstanceAimbotUpdate"
local aimbotConnection
local aimbotUsingBind = false

local function stepAimbot(dt)
    dt = dt or (1 / 240)
    if not aimbot.enabled then
        clearAimbotLock()
        return
    end

    local cam = workspace.CurrentCamera
    if not cam then
        return
    end
    Camera = cam

    if not aimbot.lockedTarget then
        aimbot.lockedTarget = closesttocursor()
        aimbot.smoothCF = getUnstretchedCameraCFrame(cam)
        if not aimbot.lockedTarget then
            return
        end
    end

    if not aimbot.lockedTarget.Parent or not aimbot.lockedTarget:IsDescendantOf(workspace) then
        clearAimbotLock()
        return
    end

    if aimbot.wallCheck then
        local myChar2 = LocalPlayer.Character
        local myRoot2 = myChar2 and myChar2:FindFirstChild("HumanoidRootPart")
        if myRoot2 then
            local params = RaycastParams.new()
            params.FilterDescendantsInstances = { myChar2 }
            params.FilterType = Enum.RaycastFilterType.Exclude
            local dir = aimbot.lockedTarget.Position - myRoot2.Position
            local result = workspace:Raycast(myRoot2.Position, dir, params)
            if result then
                local hitPart = result.Instance
                local hitModel = hitPart and hitPart:FindFirstAncestorOfClass("Model")
                local hitPlayer = hitModel and Players:GetPlayerFromCharacter(hitModel)
                local targetPlayer = Players:GetPlayerFromCharacter(aimbot.lockedTarget:FindFirstAncestorOfClass("Model"))
                if not hitPlayer or hitPlayer ~= targetPlayer then
                    clearAimbotLock()
                    return
                end
            end
        end
    end

    local myChar = LocalPlayer.Character
    if not myChar then
        return
    end
    local myHead = myChar:FindFirstChild("Head")
    if not myHead then
        clearAimbotLock()
        return
    end
    if not camController then
        return
    end

    if not aimbot.smoothCF then
        aimbot.smoothCF = getUnstretchedCameraCFrame(cam)
    end

    local lookCF = CFrame.lookAt(cam.CFrame.Position, aimbot.lockedTarget.Position)
    local alpha = getAimbotLerpAlpha(dt)
    aimbot.smoothCF = aimbot.smoothCF:Lerp(lookCF, alpha)

    if camController and camController.MimicRotation then
        pcall(function()
            camController:MimicRotation(aimbot.smoothCF)
        end)
    end
end

local function updaimbot()
    if aimbotConnection then
        aimbotConnection:Disconnect()
        aimbotConnection = nil
    end
    if aimbotUsingBind then
        pcall(function()
            RunService:UnbindFromRenderStep(AIMBOT_RENDER_BIND)
        end)
        aimbotUsingBind = false
    end

    aimbotFOVContainer.Visible = aimbot.showFov
    if not aimbot.enabled then
        clearAimbotLock()
        return
    end

    local ok = pcall(function()
        RunService:UnbindFromRenderStep(AIMBOT_RENDER_BIND)
        RunService:BindToRenderStep(AIMBOT_RENDER_BIND, Enum.RenderPriority.Camera.Value + 1, stepAimbot)
    end)
    if ok then
        aimbotUsingBind = true
    else
        aimbotConnection = RunService.RenderStepped:Connect(stepAimbot)
    end
end


local function closestplayerbs()
    local best, bestD = nil, math.huge
    local sc = screenCenter(Camera)
    for _, player in Players:GetPlayers() do
        if player ~= LocalPlayer and player.Character then
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local pos, on = worldToScreen(root.Position, Camera)
                if on then
                    local d = (sc - Vector2.new(pos.X, pos.Y)).Magnitude
                    if d < bestD then best=player.Character; bestD=d end
                end
            end
        end
    end
    return best
end

local function backshoot2()
    if backshoot.connection then backshoot.connection:Disconnect() end
end

local function stopbs()
    if backshoot.connection then backshoot.connection:Disconnect(); backshoot.connection=nil end
end

local backshootCheckConn = nil
local function startBackshootMonitor()
    if backshootCheckConn then return end
    backshootCheckConn = RunService.Heartbeat:Connect(function()
        if not backshoot.target then
            if backshootCheckConn then
                backshootCheckConn:Disconnect()
                backshootCheckConn = nil
            end
            return
        end
        local hum = backshoot.target:FindFirstChild("Humanoid")
        if not hum or hum.Health <= 0 then
            local myChar = LocalPlayer.Character
            if myChar and myChar:FindFirstChild("HumanoidRootPart") and backshoot.origCFrame then
                myChar.HumanoidRootPart.CFrame = backshoot.origCFrame
            end
            backshoot.target = nil
            stopbs()
            if backshootCheckConn then
                backshootCheckConn:Disconnect()
                backshootCheckConn = nil
            end
        end
    end)
end

LocalPlayer.CharacterRemoving:Connect(function()
    stopbs()
    backshoot.target    = nil
    backshoot.origCFrame = nil
    if backshootCheckConn then
        backshootCheckConn:Disconnect()
        backshootCheckConn = nil
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if backshoot.target and player.Character == backshoot.target then
        local myChar = LocalPlayer.Character
        if myChar and myChar:FindFirstChild("HumanoidRootPart") and backshoot.origCFrame then
            myChar.HumanoidRootPart.CFrame = backshoot.origCFrame
        end
        backshoot.target = nil
        stopbs()
        if backshootCheckConn then
            backshootCheckConn:Disconnect()
            backshootCheckConn = nil
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(5)
        pcall(function()
            local cam = workspace.CurrentCamera
            if cam then
                for _, child in ipairs(cam:GetChildren()) do
                    if child:IsA("BillboardGui") and child.Name == "FortniteDamageNumber" then
                        if not child.Adornee or not child.Adornee.Parent then
                            child:Destroy()
                        end
                    end
                end
                
                if game:GetService("Workspace") and game:GetService("Workspace").Terrain then
                    local terrain = game:GetService("Workspace").Terrain
                    for _, child in ipairs(terrain:GetChildren()) do
                        if child:IsA("Attachment") then
                            local beams = child:FindFirstChildWhichIsA("Beam")
                            if not beams then
                                local allBeamsGone = true
                                for _, thing in ipairs(child.Parent:GetChildren()) do
                                    if thing:IsA("Beam") then
                                        allBeamsGone = false
                                        break
                                    end
                                end
                                if allBeamsGone then
                                    pcall(function() child:Destroy() end)
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
end)


silentAimBox:AddToggle("SilentAim", {
    Text     = "enable",
    Default  = false,
    Callback = function(val)
        silentAim.enabled = val
        if not val then curtarget = nil end
    end
})

silentAimBox:AddToggle("BackshootToggle", {
    Text     = "backshoot",
    Default  = false,
    Callback = function(val)
        backshoot.enabled = val
        if val and backshoot.target then
            backshoot2()
            startBackshootMonitor()
        else
            stopbs()
            if backshoot.target and backshoot.origCFrame then
                local mc = LocalPlayer.Character
                if mc and mc:FindFirstChild("HumanoidRootPart") then
                    mc.HumanoidRootPart.CFrame = backshoot.origCFrame
                end
            end
            if backshootCheckConn then
                backshootCheckConn:Disconnect()
                backshootCheckConn = nil
            end
        end
    end
})

silentAimBox:AddToggle("AntiKatana", {
    Text     = "anti katana",
    Default  = false,
    Callback = function(val) antikatana = val end
})

silentAimBox:AddSlider("HitChance", {
    Text     = "hit chance",
    Default  = 100,
    Min      = 0,
    Max      = 100,
    Rounding = 0,
    Compact  = true,
    Callback = function(val) silentAim.hitChance = tonumber(val) or 100 end
})

silentAimBox:AddDropdown("HitPartDropdown", {
    Text     = "hit part",
    Default  = "Head",
    Values   = HPlist,
    Callback = function(val) silentAim.hitPart = val end
})


silentCustBox:AddToggle("ShowFOV", {
    Text     = "show fov",
    Default  = false,
    Callback = function(val) silentFOVContainer.Visible = val end
}):AddColorPicker("FOVOutlineColor1", {
    Default  = Color3.fromRGB(255, 255, 255),
    Title    = "outline color 1",
    Callback = function(val) silentFOVCfg.OutlineColor1 = val; silentlinegrad() end
}):AddColorPicker("FOVOutlineColor2", {
    Default  = Color3.fromRGB(255, 255, 255),
    Title    = "outline color 2",
    Callback = function(val) silentFOVCfg.OutlineColor2 = val; silentlinegrad() end
})

silentCustBox:AddToggle("SilentFOVFilled", {
    Text     = "fov fill",
    Default  = false,
    Callback = function(val) silentFOVCfg.FilledEnabled = val; silentFOVFill.Visible = val end
}):AddColorPicker("SilentFOVFillColor1", {
    Default  = Color3.fromRGB(255, 255, 255),
    Title    = "fill color 1",
    Callback = function(val) silentFOVCfg.FilledColor1 = val; updsilentgrad() end
}):AddColorPicker("SilentFOVFillColor2", {
    Default  = Color3.fromRGB(0, 0, 0),
    Title    = "fill color 2",
    Callback = function(val) silentFOVCfg.FilledColor2 = val; updsilentgrad() end
})

silentCustBox:AddToggle("SilentFOVFillAnimated", {
    Text     = "animated fill",
    Default  = false,
    Callback = function(val)
        silentFOVCfg.FilledAnimated = val
        if not val then silentFOVFillGrad.Rotation = silentFOVCfg.FilledRotation end
    end
})

silentCustBox:AddSlider("FOVRadius", {
    Text     = "fov radius",
    Default  = 100,
    Min      = 10,
    Max      = 750,
    Rounding = 1,
    Compact  = true,
    Callback = function(val) silentAim.fovRadius = val end
})

silentCustBox:AddSlider("SilentFOVOutlineThickness", {
    Text     = "outline thickness",
    Default  = 1.5,
    Min      = 0.5,
    Max      = 5,
    Rounding = 1,
    Compact  = true,
    Callback = function(val) silentFOVCfg.OutlineThickness = val; silentFOVStroke.Thickness = val end
})

silentCustBox:AddSlider("SilentFOVOutlineTransparency", {
    Text     = "outline transparency",
    Default  = 0,
    Min      = 0,
    Max      = 1,
    Rounding = 2,
    Compact  = true,
    Callback = function(val) silentFOVCfg.OutlineTransparency = val; silentFOVStroke.Transparency = val end
})

silentCustBox:AddSlider("SilentFOVOutlineRotation", {
    Text     = "outline rotation",
    Default  = 0,
    Min      = 0,
    Max      = 360,
    Rounding = 0,
    Compact  = true,
    Callback = function(val) silentFOVCfg.OutlineRotation = val; silentFOVStrokeGrad.Rotation = val end
})

silentCustBox:AddSlider("SilentFOVFillTransparency", {
    Text     = "fill transparency",
    Default  = 0.7,
    Min      = 0,
    Max      = 1,
    Rounding = 2,
    Compact  = true,
    Callback = function(val) silentFOVCfg.FilledTransparency = val; silentFOVFill.BackgroundTransparency = val end
})

silentCustBox:AddSlider("SilentFOVFillRotation", {
    Text     = "fill rotation",
    Default  = 0,
    Min      = 0,
    Max      = 360,
    Rounding = 0,
    Compact  = true,
    Callback = function(val)
        silentFOVCfg.FilledRotation = val
        if not silentFOVCfg.FilledAnimated then silentFOVFillGrad.Rotation = val end
    end
})

silentCustBox:AddSlider("SilentFOVFillSpeed", {
    Text     = "fill speed",
    Default  = 1,
    Min      = 0.1,
    Max      = 10,
    Rounding = 1,
    Compact  = true,
    Callback = function(val) silentFOVCfg.FilledSpeed = val end
})

silentCustBox:AddToggle("SilentFOVSpin", {
    Text     = "fov spin",
    Default  = false,
    Callback = function(val)
        silentFOVCfg.SpinOn = val
        if not val then
            silentFOVStrokeGrad.Rotation = silentFOVCfg.OutlineRotation
            if not silentFOVCfg.FilledAnimated then
                silentFOVFillGrad.Rotation = silentFOVCfg.FilledRotation
            end
        end
    end
})

silentCustBox:AddSlider("SilentFOVSpinSpd", {
    Text     = "spin speed",
    Default  = 1,
    Min      = 0.1,
    Max      = 10,
    Rounding = 1,
    Compact  = true,
    Callback = function(val) silentFOVCfg.SpinSpd = val end
})

silentCustBox:AddToggle("SilentFOVFollowMuzzle", {
    Text     = "follow muzzle",
    Default  = false,
    Callback = function(val) silentAim.followMuzzle = val end
})

silentCustBox:AddToggle("SilentFOVFollowTarget", {
    Text     = "follow target",
    Default  = false,
    Callback = function(val) silentAim.followTarget = val end
})

silentCustBox:AddSlider("SilentFOVFollowSmooth", {
    Text     = "follow smoothness",
    Default  = 0,
    Min      = 0,
    Max      = 15,
    Rounding = 0,
    Suffix   = '',
    Callback = function(val) silentAim.followTargetSmoothness = val end
})

aimbotBox:AddToggle("AimbotToggle", {
    Text = "enable",
    Default = false,
    Callback = function(val)
        aimbot.masterEnabled = val
        aimbot.enabled = val
        if not val then
            clearAimbotLock()
        end
        updaimbot()
    end
}):AddKeyPicker("AimbotKey", {
    Text = "Aimbot",
    Default = "None",
    Mode = "Toggle",
    NoUI = true,
    SyncToggleState = false,
    Modes = { "Toggle", "Hold" },
    Callback = function(state)
        if not aimbot.masterEnabled then return end
        aimbot.enabled = state
        if not state then
            clearAimbotLock()
        end
        updaimbot()
    end
})

aimbotBox:AddToggle("AimbotWallCheck", {
    Text = "wall check",
    Default = false,
    Callback = function(val)
        aimbot.wallCheck = val
    end
})

aimbotBox:AddSlider("AimbotSmoothness", {
    Text = "smoothness",
    Default = 2,
    Min = 0.1,
    Max = 10,
    Rounding = 2,
    Compact = true,
    Callback = function(val)
        aimbot.smoothness = math.clamp(val, 0.1, 10)
    end
})

aimbotBox:AddDropdown("AimbotCurve", {
    Text = "aim curve",
    Default = "Linear",
    Values = { "Linear", "Expo", "EaseIn", "EaseOut", "EaseInOut", "Cubic", "Instant" },
    Callback = function(val)
        aimbot.aimCurve = val
    end
})

aimbotBox:AddDropdown("AimbotHitPart", {
    Text="hit part", Default="Head",
    Values={"Head","HumanoidRootPart","Torso","UpperTorso","LowerTorso"},
    Callback=function(val) aimbot.targetPart=val end
})


aimbotCustBox:AddToggle("ShowAimbotFOV", {
    Text="show fov", Default=false,
    Callback=function(val)
        aimbot.showFov=val
        aimbotFOVContainer.Visible=val
    end
}):AddColorPicker("AimbotFOVOutlineColor1", {
    Default=Color3.fromRGB(255,255,255), Title="outline color 1",
    Callback=function(val) aimbotFOVCfg.OutlineColor1=val; updaimbotoutlinegrad() end
}):AddColorPicker("AimbotFOVOutlineColor2", {
    Default=Color3.fromRGB(255,255,255), Title="outline color 2",
    Callback=function(val) aimbotFOVCfg.OutlineColor2=val; updaimbotoutlinegrad() end
})

aimbotCustBox:AddToggle("AimbotFOVFilled", {
    Text="fov fill", Default=false,
    Callback=function(val) aimbotFOVCfg.FilledEnabled=val; aimbotFOVFill.Visible=val end
}):AddColorPicker("AimbotFOVFillColor1", {
    Default=Color3.fromRGB(255, 255, 255), Title="fill color 1",
    Callback=function(val) aimbotFOVCfg.FilledColor1=val; updaimbotfillgrad() end
}):AddColorPicker("AimbotFOVFillColor2", {
    Default=Color3.fromRGB(0,0,0), Title="fill color 2",
    Callback=function(val) aimbotFOVCfg.FilledColor2=val; updaimbotfillgrad() end
})

aimbotCustBox:AddToggle("AimbotFOVFillAnimated", {
    Text="animated fill", Default=false,
    Callback=function(val)
        aimbotFOVCfg.FilledAnimated=val
        if not val then aimbotFOVFillGrad.Rotation=aimbotFOVCfg.FilledRotation end
    end
})

aimbotCustBox:AddSlider("AimbotFOV", {
    Text="fov radius", Default=500, Min=10, Max=1000, Rounding=0, Compact=true,
    Callback=function(val) aimbot.fovRadius=val end
})

aimbotCustBox:AddSlider("AimbotFOVOutlineThickness", {
    Text="outline thickness", Default=1.5, Min=0.5, Max=5, Rounding=1, Compact=true,
    Callback=function(val) aimbotFOVCfg.OutlineThickness=val; aimbotFOVStroke.Thickness=val end
})

aimbotCustBox:AddSlider("AimbotFOVOutlineTransparency", {
    Text="outline transparency", Default=0, Min=0, Max=1, Rounding=2, Compact=true,
    Callback=function(val) aimbotFOVCfg.OutlineTransparency=val; aimbotFOVStroke.Transparency=val end
})

aimbotCustBox:AddSlider("AimbotFOVOutlineRotation", {
    Text="outline rotation", Default=0, Min=0, Max=360, Rounding=0, Compact=true,
    Callback=function(val) aimbotFOVCfg.OutlineRotation=val; aimbotFOVStrokeGrad.Rotation=val end
})

aimbotCustBox:AddSlider("AimbotFOVFillTransparency", {
    Text="fill transparency", Default=0.7, Min=0, Max=1, Rounding=2, Compact=true,
    Callback=function(val) aimbotFOVCfg.FilledTransparency=val; aimbotFOVFill.BackgroundTransparency=val end
})

aimbotCustBox:AddSlider("AimbotFOVFillRotation", {
    Text="fill rotation", Default=0, Min=0, Max=360, Rounding=0, Compact=true,
    Callback=function(val)
        aimbotFOVCfg.FilledRotation=val
        if not aimbotFOVCfg.FilledAnimated then aimbotFOVFillGrad.Rotation=val end
    end
})

aimbotCustBox:AddSlider("AimbotFOVFillSpeed", {
    Text="fill speed", Default=1, Min=0.1, Max=10, Rounding=1, Compact=true,
    Callback=function(val) aimbotFOVCfg.FilledSpeed=val end
})

aimbotCustBox:AddToggle("AimbotFOVSpin", {
    Text="fov spin", Default=false,
    Callback=function(val)
        aimbotFOVCfg.SpinOn=val
        if not val then
            aimbotFOVStrokeGrad.Rotation=aimbotFOVCfg.OutlineRotation
            if not aimbotFOVCfg.FilledAnimated then
                aimbotFOVFillGrad.Rotation=aimbotFOVCfg.FilledRotation
            end
        end
    end
})

aimbotCustBox:AddSlider("AimbotFOVSpinSpd", {
    Text="spin speed", Default=1, Min=0.1, Max=10, Rounding=1, Compact=true,
    Callback=function(val) aimbotFOVCfg.SpinSpd=val end
})

aimbotCustBox:AddToggle("AimbotFOVFollowMuzzle", {
    Text="follow muzzle", Default=false,
    Callback=function(val) aimbot.followMuzzle=val end
})

aimbotCustBox:AddToggle("AimbotFOVFollowTarget", {
    Text="follow target", Default=false,
    Callback=function(val) aimbot.followTarget=val end
})

aimbotCustBox:AddSlider("AimbotFOVFollowSmooth", {
    Text="follow smoothness", Default=0,
    Min=0, Max=15, Rounding=0, Suffix='',
    Callback=function(val) aimbot.followTargetSmoothness=val end
})

updaimbot()
setupShootDetection()


local LeftGroup = Tabs.Combat:AddLeftGroupbox("gun")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

getgenv().CombatMods = {
    RapidFire = false,
    RapidFireCooldown = -0.05,
    NoSpread = false,
    NoRecoil = false,
    MaxAccuracy = false,
    RapidAttack = false,
    GunModule = nil,
    MeleeModule = nil,
    OriginalGunStartShooting = nil,
    OriginalMeleeStartShooting = nil,
    OriginalGetSpread = nil,
    OriginalRecoil = nil,
    NoReload = false,
    ReloadTime = 0,
    ProjectileSpeed = false,
    ProjectileSpeedValue = 9999999999999999,
    EquipCooldown = false,
    EquipCooldownValue = 0,
}

task.spawn(function()
    local success, GunModule = pcall(function()
        return require(LocalPlayer.PlayerScripts.Modules.ItemTypes.Gun)
    end)
    
    if success and GunModule then
        getgenv().CombatMods.GunModule = GunModule
        
        if GunModule.StartShooting then
            getgenv().CombatMods.OriginalGunStartShooting = GunModule.StartShooting
            
            GunModule.StartShooting = function(self, p26, p27)
                local oldShootCooldown
                local oldProjectileSpeed
                local oldEquipCooldown
                if getgenv().CombatMods.RapidFire then
                    oldShootCooldown = self.Info.ShootCooldown
                    self.Info.ShootCooldown = getgenv().CombatMods.RapidFireCooldown or -0.05
                end
                if getgenv().CombatMods.ProjectileSpeed then
                    pcall(function()
                        oldProjectileSpeed = self.Info.ProjectileSpeed
                        self.Info.ProjectileSpeed = getgenv().CombatMods.ProjectileSpeedValue
                    end)
                end
                if getgenv().CombatMods.EquipCooldown then
                    pcall(function()
                        oldEquipCooldown = self.Info.EquipCooldown
                        self.Info.EquipCooldown = getgenv().CombatMods.EquipCooldownValue
                    end)
                end
                if getgenv().CombatMods.NoReload then
                    pcall(function()
                        self.Info.ReloadTime = getgenv().CombatMods.ReloadTime
                    end)
                end
                
                local result = { getgenv().CombatMods.OriginalGunStartShooting(self, p26, p27) }
                
                if getgenv().CombatMods.RapidFire then
                    self.Info.ShootCooldown = oldShootCooldown
                end
                if getgenv().CombatMods.ProjectileSpeed and oldProjectileSpeed then
                    self.Info.ProjectileSpeed = oldProjectileSpeed
                end
                if getgenv().CombatMods.EquipCooldown and oldEquipCooldown then
                    self.Info.EquipCooldown = oldEquipCooldown
                end
                
                return unpack(result)
            end
        end
        
        if GunModule._Recoil then
            getgenv().CombatMods.OriginalRecoil = GunModule._Recoil
            
            GunModule._Recoil = function(self, multiplier)
                if getgenv().CombatMods.NoRecoil then
                    return
                end
                return getgenv().CombatMods.OriginalRecoil(self, multiplier)
            end
        end
    end
end)

local function ModifyGunModule()
    local gunMod = getgenv().CombatMods and getgenv().CombatMods.GunModule
    if gunMod and gunMod.Info then
        if getgenv().CombatMods.RapidFire then
            gunMod.Info.ShootCooldown = getgenv().CombatMods.RapidFireCooldown or -0.05
        end
        if getgenv().CombatMods.NoRecoil then
            gunMod.Info.Recoil = 0
        end
        if getgenv().CombatMods.NoSpread then
            gunMod.Info.Spread = 0
        end
    end
end

task.spawn(function()
    while task.wait(0.5) do
        if getgenv().CombatMods and (getgenv().CombatMods.RapidFire or getgenv().CombatMods.NoRecoil or getgenv().CombatMods.NoSpread) then
            ModifyGunModule()
        end
    end
end)

task.spawn(function()
    local success, GameplayUtility = pcall(function()
        return require(RS.Modules.GameplayUtility)
    end)
    
    if success and GameplayUtility and GameplayUtility.GetSpread then
        getgenv().CombatMods.GameplayUtility = GameplayUtility
        getgenv().CombatMods.OriginalGetSpread = GameplayUtility.GetSpread
        
        GameplayUtility.GetSpread = function(spread, aimMultiplier, isAiming, isCrouching, pelletIndex, totalPellets, consistent)
            if getgenv().CombatMods.NoSpread or getgenv().CombatMods.MaxAccuracy then
                return CFrame.new()
            end
            return getgenv().CombatMods.OriginalGetSpread(spread, aimMultiplier, isAiming, isCrouching, pelletIndex, totalPellets, consistent)
        end
    end
end)

task.spawn(function()
    local success, MeleeModule = pcall(function()
        return require(LocalPlayer.PlayerScripts.Modules.ItemTypes.Melee)
    end)
    
    if success and MeleeModule then
        getgenv().CombatMods.MeleeModule = MeleeModule
        
        if MeleeModule.StartShooting then
            getgenv().CombatMods.OriginalMeleeStartShooting = MeleeModule.StartShooting
            
            MeleeModule.StartShooting = function(self, p26, p27)
                local oldAttackCooldown
                
                if getgenv().CombatMods.RapidAttack then
                    oldAttackCooldown = self.Info.AttackCooldown
                    self.Info.AttackCooldown = 0
                end
                
                local result = { getgenv().CombatMods.OriginalMeleeStartShooting(self, p26, p27) }
                
                if getgenv().CombatMods.RapidAttack and oldAttackCooldown then
                    self.Info.AttackCooldown = oldAttackCooldown
                end
                
                return unpack(result)
            end
        end
    end
end)

local muzzleflashconn = nil

local function nomuzzleflash()
    local viewModels = Workspace:FindFirstChild("ViewModels")
    if viewModels then
        local firstPerson = viewModels:FindFirstChild("FirstPerson")
        if firstPerson then
            for _, model in pairs(firstPerson:GetChildren()) do
                if model:IsA("Model") then
                    local itemVisual = model:FindFirstChild("ItemVisual")
                    if itemVisual then
                        local body = itemVisual:FindFirstChild("Body")
                        if body then
                            local bodyPrimary = body:FindFirstChild("BodyPrimary")
                            if bodyPrimary then
                                local muzzle = bodyPrimary:FindFirstChild("_muzzle")
                                if muzzle then
                                    local spotlight = muzzle:FindFirstChild("SpotLight")
                                    if spotlight then
                                        spotlight:Destroy()
                                    end
                                    for _, child in pairs(muzzle:GetChildren()) do
                                        if child:IsA("ParticleEmitter") and child.Name == "ParticleEmiter" then
                                            child:Destroy()
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

LeftGroup:AddToggle("NoCooldown", {
    Text = "rapid fire",
    Default = false,
    Callback = function(val)
        getgenv().CombatMods.RapidFire = val
    end
})

LeftGroup:AddSlider("RapidFireValue", {
    Text = "rapid fire value",
    Default = -20,
    Min = -100,
    Max = 0,
    Rounding = 1,
    Compact = true,
    Callback = function(val)
        getgenv().CombatMods.RapidFireCooldown = val
    end
})

LeftGroup:AddToggle("NoSpread", {
    Text = "no spread",
    Default = false,
    Callback = function(val)
        getgenv().CombatMods.NoSpread = val
    end
})

LeftGroup:AddToggle("NoRecoil", {
    Text = "no recoil",
    Default = false,
    Callback = function(val)
        getgenv().CombatMods.NoRecoil = val
    end
})

LeftGroup:AddToggle("MaxAccuracy", {
    Text = "max accuracy",
    Default = false,
    Callback = function(val)
        getgenv().CombatMods.MaxAccuracy = val
    end
})

LeftGroup:AddToggle("RapidAttack", {
    Text = "rapid attack",
    Default = false,
    Callback = function(val)
        getgenv().CombatMods.RapidAttack = val
    end
})

LeftGroup:AddToggle("NoMuzzleFlash", {
    Text = "no muzzle flash",
    Default = false,
    Callback = function(val)
        if val then
            nomuzzleflash()
            if muzzleflashconn then
                muzzleflashconn:Disconnect()
            end
            muzzleflashconn = RunService.RenderStepped:Connect(nomuzzleflash)
        else
            if muzzleflashconn then
                muzzleflashconn:Disconnect()
                muzzleflashconn = nil
            end
        end
    end
})
end

getDamageBillboardInfo = function(obj)
    local cached = damageBillboardInfoCache[obj]
    if cached ~= nil then
        return cached
    end

    if not obj:IsA("BillboardGui") then
        return
    end

    if obj.Name == "FortniteDamageNumber" then
        return
    end

    local lbl = obj:FindFirstChildWhichIsA("TextLabel", true)
    if not lbl then
        return
    end

    local dmg = tonumber(lbl.Text)
    if not (dmg and dmg > 0) then
        return
    end

    local adornee = obj.Adornee or (obj.Parent and obj.Parent:IsA("BasePart") and obj.Parent)
    if not adornee then
        return
    end

    local info = {
        lbl = lbl,
        dmg = dmg,
        adornee = adornee,
    }
    damageBillboardInfoCache[obj] = info
    return info
end

;(function()

local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local fonts = {}
local instanceUIFont = getgenv().InstanceUIFont
fonts.main = (typeof(instanceUIFont) == "Font" and instanceUIFont) or (instanceUIFont and Font.fromEnum(instanceUIFont)) or Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Black)
local hitEffectEnabled = false
local hitEffectColor = Color3.fromRGB(159, 133, 195)
local hitEffectStyle = {Particles = true}
local hitEffectFloatSpeed = 7
local hitEffectAliveTime = 2.8

local ragebot = {}

do

local replicatedstorage = cloneref(game:GetService("ReplicatedStorage"))
local players = cloneref(game:GetService("Players"))
local runsvc = cloneref(game:GetService("RunService"))
local userinput = cloneref(game:GetService("UserInputService"))
local workspace = cloneref(game:GetService("Workspace"))

local player = players.LocalPlayer
local camera = workspace.CurrentCamera

local modules = {
    enums = instanceSafeRequire(replicatedstorage.Modules.EnumLibrary),
    fighter = instanceSafeRequire(player.PlayerScripts.Controllers.FighterController),
    camcontrol = instanceSafeRequire(player.PlayerScripts.Controllers.CameraController),
    utility = instanceSafeRequire(replicatedstorage.Modules.Utility)
}

local MATCH_ID_ATTRS = {"MatchId", "DuelId", "RoundId", "GameId", "MatchUUID", "ArenaId", "InstanceId"}
local DUEL_STATE_ATTRS = {"InDuel", "InMatch", "InRound", "InGame", "InFight", "IsInMatch", "IsInDuel", "MatchActive", "Fighting"}
local SPAWN_SAFE_ATTRS = {"InSpawn", "InLobby", "IsSpectating", "InSafeZone", "InIntermission", "IsRespawning"}

local function inLive(targetPlr)
    if not targetPlr then return false end
    local live = workspace:FindFirstChild("Live")
    if not live then return false end
    if live:FindFirstChild(targetPlr.Name) then return true end
    if live:FindFirstChild(tostring(targetPlr.UserId)) then return true end
    for _, child in ipairs(live:GetChildren()) do
        if child.Name == targetPlr.Name or child.Name == tostring(targetPlr.UserId) then
            return true
        end
    end
    local char = targetPlr.Character
    if char and (char.Parent == live or char:IsDescendantOf(live)) then
        return true
    end
    local fc = modules.fighter
    if fc and type(fc.GetFighter) == "function" then
        local ok, fighter = pcall(fc.GetFighter, fc, targetPlr)
        if ok and fighter and fighter.Entity and fighter.Entity.Parent then
            if fighter.Entity.Parent == live or fighter.Entity:IsDescendantOf(live) then
                return true
            end
        end
    end
    return false
end

local function plrMid(targetPlr)
    if not targetPlr then return nil end
    for _, key in ipairs(MATCH_ID_ATTRS) do
        local v = targetPlr:GetAttribute(key)
        if v ~= nil and v ~= "" and v ~= 0 and v ~= false then
            return tostring(v)
        end
    end
    local char = targetPlr.Character
    if char then
        for _, key in ipairs(MATCH_ID_ATTRS) do
            local v = char:GetAttribute(key)
            if v ~= nil and v ~= "" and v ~= 0 and v ~= false then
                return tostring(v)
            end
        end
    end
    return nil
end

local function liveMatch()
    local lp = player
    if not lp then return false end
    for _, key in ipairs(SPAWN_SAFE_ATTRS) do
        local v = lp:GetAttribute(key)
        if v == true or v == 1 or v == "true" then
            return false
        end
    end
    local char = lp.Character
    if not char then return false end
    for _, key in ipairs(SPAWN_SAFE_ATTRS) do
        local cv = char:GetAttribute(key)
        if cv == true or cv == 1 or cv == "true" then
            return false
        end
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local myRoot = char:FindFirstChild("HumanoidRootPart")
    if not hum or hum.Health <= 0 or not myRoot then return false end
    for _, key in ipairs(DUEL_STATE_ATTRS) do
        local v = lp:GetAttribute(key)
        if v == true or v == 1 or v == "true" then
            return true
        end
        local cv = char:GetAttribute(key)
        if cv == true or cv == 1 or cv == "true" then
            return true
        end
    end
    if inLive(lp) then
        return true
    end
    local fc = modules.fighter
    if fc and fc.LocalFighter and fc.LocalFighter.Entity and fc.LocalFighter.Entity.Parent then
        return true
    end
    local myMatchId = plrMid(lp)
    if myMatchId then
        for _, plr in players:GetPlayers() do
            if plr ~= lp and plrMid(plr) == myMatchId then
                return true
            end
        end
    end
    if fc then
        for _, list in ipairs({ fc.Fighters, fc.AllFighters }) do
            if list then
                for _, f in pairs(list) do
                    if f and f.Player and f.Player ~= lp and (f.IsEnemy or f.Enemy) then
                        local fChar = f.Player.Character
                        local fHum = fChar and fChar:FindFirstChildOfClass("Humanoid")
                        if fHum and fHum.Health > 0 then
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end

local _instanceLobbyCache = { t = 0, v = true }
local function lobbyCache()
    local now = os.clock()
    if now - _instanceLobbyCache.t < 0.15 then
        return _instanceLobbyCache.v
    end
    _instanceLobbyCache.t = now
    _instanceLobbyCache.v = not liveMatch()
    return _instanceLobbyCache.v
end

getgenv().InstanceIsInActiveMatch = liveMatch
getgenv().InstanceIsInLobby = lobbyCache

local config = {
    target = {
        enabled = false,
        character = nil,
        auto = false,
        autoshoot = true,
        shootAttempts = 1,
        hitpart = "Head",
        lastchar = nil,
        lastplayer = nil,
        manualkey = false,
        immune = false,
        attackPosition = "default",
        attackCustomEnabled = false,
        weaponPick = "primary",
        forceWeapon = true,
        rageMasterOn = false,
        rightClickKnife = false,
        meleeFeetDrop = 3.5,
        underOffset = 4,
        customHeight = 2,
        customFront = 0,
        customSide = 0,
        customVertical = 0,
        customRadius = 0,
        targetSort = "nearest",
        teamCheck = true,
        wallCheck = false,
        maxDistance = 0,
        autoSwitch = true,
        safeHP = 0,
        holdKey = false,
    },
    prediction = {
        enabled = false,
        multiplier = 1.2,
        velocity = Vector3.new(0, 0, 0),
        acceleration = Vector3.new(0, 0, 0),
        lastposition = nil,
        lasttime = 0,
        velbuffer = {},
        posbuffer = {},
        maxvelsamples = 15,
        maxpossamples = 5
    },
    orbit = {
        active = false,
        angle = 0,
        serverpos = nil,
        connection = nil,
        speed = 9000,
        orbitSpeed = 9000,
        height = 1,
        radius = 0,
        originalpos = nil
    },
    state = {
        reloading = false,
        outofammo = false,
        csyncactive = false,
        reloadStartedAt = 0,
    },
    voidhide = {
        enabled = true,
        originalPosition = nil,
        active = false,
        connection = nil
    },
    voidspam = {
        enabled = false,
        shoot_min = 1,
        shoot_max = 1,
        hide_min = 1,
        hide_max = 1,
        phase = nil,
        lastswitch = 0,
        currentduration = 0,
        bypassMode = "Extreme Networking"
    },
    backstab = {
        enabled = false,
        camera = false,
    },
    visualizer = {
        enabled = true,
        tracer = {
            color = Color3.fromRGB(0, 186, 255),
            thickness = 1,
            transparency = 1,
            start_point = "cursor",
            outline = true,
            outline_color = Color3.fromRGB(0, 0, 0),
            outline_thickness = 1
        },
        indicator = {
            display_options = {"name", "position", "hit reg"},
            color = Color3.fromRGB(255, 255, 255),
            accent_color = Color3.fromRGB(0, 186, 255)
        }
    },
    hitNotifications = {
        enabled = true,
        color = Color3.fromRGB(235, 235, 235),
        textSize = 14,
        maxVisible = 8,
        duration = 3,
        stackGap = 6,
        position = "Top Left",
        offsetX = 12,
        offsetY = 12,
        inAnimation = "fade bounce",
        outAnimation = "fade",
        animInDuration = 0.52,
        animOutDuration = 0.38,
        uiNotif = false,
    },
    ragestatus = {
        enabled = false,
        mode = "static",
        color = Color3.fromRGB(235, 235, 235),
        staticOffsetX = 0,
        staticOffsetY = 40,
        showAmmo = true,
        hideOnReload = true,
        textSize = 15,
        lineGap = 15,
        fontName = "gotham",
        showKills = true,
    },
    kills = {
        count = 0,
        streak = 0,
        lastKillAt = 0,
    },
}

local ragePerf = {
    lastAttackTick = 0,
    hitPartByPlayer = {},
    lastHitAtByPlayer = {},
    targetHudAt = 0,
    rageStatusAt = 0,
    restoreVisualAt = 0,
    killStartAt = nil,
    rageStatusCacheAt = 0,
    cachedRageStatusLine = "",
    cachedRageStatusDetail = "",
    lastRageStatusText = "",
    lastRageDetailText = "",
    lastRageAmmoText = "",
    lastRageColor = nil,
    targetAcquiredAt = 0,
    shootDelay = 0.3,
    delayActive = false,
    delayTask = nil,
    shootCooldown = 0,
    shootReadyAt = nil,
    canShoot = false,
}

local vhState = {
    active = false,
    hrp = nil,
    mainConnection = nil,
    restoreConnection = nil,
    currentVoidPos = nil,
    lastTeleportTime = 0
}

local localfighter = modules.fighter.LocalFighter
local oldpos

local indicator = Drawing.new("Circle")
indicator.Thickness = 1.5
pcall(function() indicator.NumSides = 36 end)
indicator.Filled = false
indicator.Transparency = 1
indicator.Visible = false
indicator.Radius = 12
indicator.Color = Color3.fromRGB(255, 50, 50)

local indicatoroutline = Drawing.new("Circle")
indicatoroutline.Thickness = 4
pcall(function() indicatoroutline.NumSides = 36 end)
indicatoroutline.Filled = false
indicatoroutline.Transparency = 1
indicatoroutline.Visible = false
indicatoroutline.Radius = 12
indicatoroutline.Color = Color3.fromRGB(0, 0, 0)

local tracerline = Drawing.new("Line")
tracerline.Visible = false
tracerline.Thickness = 2
tracerline.Transparency = 1
tracerline.Color = Color3.fromRGB(0, 186, 255)

local traceroutline = Drawing.new("Line")
traceroutline.Visible = false
traceroutline.Thickness = 4
traceroutline.Transparency = 1
traceroutline.Color = Color3.fromRGB(0, 0, 0)

local lastdamagetime = {}

local function getweapon()
    local viewmodels = workspace:FindFirstChild("ViewModels")
    if not viewmodels then return nil end
    local firstperson = viewmodels:FindFirstChild("FirstPerson")
    if not firstperson then return nil end
    for _, child in ipairs(firstperson:GetChildren()) do
        local parts = {}
        for part in child.Name:gmatch("[^-]+") do
            table.insert(parts, part:match("^%s*(.-)%s*$"))
        end
        if #parts >= 2 then
            return parts[2]
        end
    end
    return nil
end

local function muzzlepos()
    local viewModels = workspace:FindFirstChild("ViewModels")
    if not viewModels then return nil end
    local firstPerson = viewModels:FindFirstChild("FirstPerson")
    if not firstPerson then return nil end
    for _, model in pairs(firstPerson:GetChildren()) do
        if model.Name:find(player.Name) then
            local itemVisual = model:FindFirstChild("ItemVisual")
            if itemVisual then
                local body = itemVisual:FindFirstChild("Body")
                if body then
                    local bodyPrimary = body:FindFirstChild("BodyPrimary")
                    if bodyPrimary then
                        local muzzle = bodyPrimary:FindFirstChild("_muzzle")
                        if muzzle then
                            return muzzle.WorldPosition
                        end
                    end
                end
            end
        end
    end
    return nil
end

local SLOTS = { primary = 1, secondary = 2, melee = 3 }
local MELEE_NMS = {
    ["Battle Axe"] = true, ["Chainsaw"] = true, ["Daggers"] = true, ["Fists"] = true,
    ["Gunblade"] = true, ["Katana"] = true, ["Knife"] = true,
    ["Scythe"] = true, ["Trowel"] = true,
}
local INFINITE_AMMO_WEAPONS = {
    ["Energy Rifle"] = true,
    ["Energy Pistols"] = true,
}

local function isInfiniteWeapon()
    local w = getweapon()
    if not w then return false end
    return INFINITE_AMMO_WEAPONS[w] == true
end

local function wantSlot()
    return SLOTS[config.target.weaponPick or "primary"] or 1
end

local function pickMelee()
    return (config.target.weaponPick or "primary") == "melee"
end

local function getammo()
    if isInfiniteWeapon() then return nil, nil, false end
    local success, controller = pcall(function()
        return instanceSafeRequire(player.PlayerScripts.Controllers.FighterController)
    end)
    if success and controller and controller.LocalFighter and controller.LocalFighter.EquippedItem then
        local item = controller.LocalFighter.EquippedItem
        local itemName, current, maxAmmo = "", 0, 0
        local isMelee = false
        local ok = pcall(function()
            itemName = tostring(item:Get("Name") or item.Name or "")
            current = item:Get("CurrentAmmo") or item:Get("Ammo") or 0
            maxAmmo = item:Get("MaxAmmo") or item:Get("MaxBullets") or current
            if type(itemName) == "string" and itemName:lower():find("melee", 1, true) then
                isMelee = true
            end
            if MELEE_NMS[itemName] then isMelee = true end
        end)
        if not ok then
            return 0, 0, pickMelee()
        end
        if pickMelee() then isMelee = true end
        return tonumber(current) or 0, tonumber(maxAmmo) or 0, isMelee
    end
    return 0, 0, pickMelee()
end

local function meleeNm(nm)
    if type(nm) ~= "string" or nm == "" then return false end
    if nm:lower():find("melee", 1, true) then return true end
    return MELEE_NMS[nm] == true
end

local function itemMelee(item)
    if not item then return false end
    local nm = item:Get("Name") or item.Name
    if meleeNm(nm) then return true end
    local t = item:Get("ItemType") or item:Get("Type") or item:Get("Category")
    return type(t) == "string" and t:lower():find("melee", 1, true) ~= nil
end

local function isSling(weapon)
    return weapon and weapon:lower():find("slingshot", 1, true) ~= nil
end

local function lfItems()
    local lf = modules.fighter and modules.fighter.LocalFighter
    if not lf then return nil end
    return lf.Items
end

local function slotItem(slotIdx)
    local items = lfItems()
    if not items then return nil end
    if items[slotIdx] then return items[slotIdx] end
    if items[tostring(slotIdx)] then return items[tostring(slotIdx)] end
    for key, it in pairs(items) do
        if it and typeof(it) == "table" then
            local s = tonumber(it:Get("Slot") or it:Get("Index") or it:Get("ItemSlot") or key)
            if s == slotIdx then return it end
            local t = it:Get("ItemType") or it:Get("Type")
            if slotIdx == 3 and (t == "Melee" or (type(t) == "string" and t:lower():find("melee", 1, true))) then
                return it
            end
            if slotIdx == 1 and (t == "Primary" or t == 1 or t == "1") then return it end
            if slotIdx == 2 and (t == "Secondary" or t == 2 or t == "2") then return it end
        end
    end
    local ordered = {}
    for _, it in pairs(items) do
        if it then ordered[#ordered + 1] = it end
    end
    table.sort(ordered, function(a, b)
        local sa = tonumber(a:Get("Slot") or a:Get("Index")) or 99
        local sb = tonumber(b:Get("Slot") or b:Get("Index")) or 99
        return sa < sb
    end)
    return ordered[slotIdx]
end

local function whichSlot(item)
    if not item then return nil end
    local items = lfItems()
    local oid = item:Get("ObjectID")
    if items and oid then
        for idx = 1, 3 do
            local it = items[idx] or items[tostring(idx)]
            if it and it:Get("ObjectID") == oid then return idx end
        end
        for key, it in pairs(items) do
            if it and it:Get("ObjectID") == oid then
                local n = tonumber(key)
                if n and n >= 1 and n <= 3 then return n end
            end
        end
    end
    if itemMelee(item) then return 3 end
    return nil
end

local rageLastSlotForce = 0

local function pressSlot(slotIdx)
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        local kc = ({ Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three })[slotIdx]
        if not kc then return end
        vim:SendKeyEvent(true, kc, false, game)
        task.wait(0.02)
        vim:SendKeyEvent(false, kc, false, game)
    end)
    if keypress then
        pcall(keypress, ({ 0x31, 0x32, 0x33 })[slotIdx])
        task.wait(0.02)
        if keyrelease then pcall(keyrelease, ({ 0x31, 0x32, 0x33 })[slotIdx]) end
    end
end

local function rageOn()
    if Toggles and Toggles.TargetOn then
        return Toggles.TargetOn.Value == true
    end
    return config.target.rageMasterOn == true
end

local function eqSlot()
    if not rageOn() then return end
    local want = wantSlot()
    local lf = modules.fighter and modules.fighter.LocalFighter
    if not lf then return end
    local eq = lf.EquippedItem
    if eq and whichSlot(eq) == want then return end
    local now = tick()
    if now - rageLastSlotForce < 0.06 then return end
    rageLastSlotForce = now
    local item = slotItem(want)
    local oid = item and item:Get("ObjectID")
    if oid then
        local rm = replicatedstorage.Remotes.Replication.Fighter.UseItem
        for _, en in ipairs({ "Equip", "Switch", "Select", "EquipItem", "ChangeItem" }) do
            pcall(function()
                local ev = modules.enums:ToEnum(en)
                if ev then rm:FireServer(oid, ev, nil, nil) end
            end)
        end
    end
    pcall(function()
        if lf.EquipItem then lf:EquipItem(want) end
        if lf.Equip then lf:Equip(want) end
        if lf.SwitchToSlot then lf:SwitchToSlot(want) end
    end)
    pcall(function()
        local fc = modules.fighter
        if fc.EquipItem then fc:EquipItem(want) end
        if fc.SwitchItem then fc:SwitchItem(want) end
    end)
    pressSlot(want)
end

local function itemReload()
    if isInfiniteWeapon() then return false end
    local lf = modules.fighter and modules.fighter.LocalFighter
    if not lf or not lf.EquippedItem then return false end
    local result = false
    pcall(function()
        local item = lf.EquippedItem
        for _, key in ipairs({ "Reloading", "IsReloading", "IsReload" }) do
            local value = item:Get(key)
            if value == true or value == 1 or value == "true" then
                result = true
                return
            end
        end
    end)
    if result then return true end
    local started = config.state.reloadStartedAt or 0
    return started > 0 and (tick() - started) < 1.75
end

local function tickAmmo()
    if isInfiniteWeapon() then
        config.state.outofammo = false
        config.state.reloading = false
        config.state.reloadStartedAt = 0
        return
    end
    local current, maxAmmo, melee = getammo()
    local wasOutOfAmmo = config.state.outofammo
    if melee then
        config.state.outofammo = false
    else
        config.state.outofammo = (tonumber(current) or 0) <= 0
    end
    local reloading = itemReload()
    if reloading and not config.state.reloading then
        config.state.reloadStartedAt = tick()
    elseif not reloading then
        config.state.reloadStartedAt = 0
    end
    config.state.reloading = reloading
    if config.state.outofammo and not wasOutOfAmmo then
        if isSling(getweapon()) then
            config.voidspam.phase = "hide"
        end
    elseif not config.state.outofammo and wasOutOfAmmo then
        if config.voidspam.enabled then
            config.voidspam.phase = "shoot"
            config.voidspam.lastswitch = tick()
        else
            config.voidspam.phase = nil
        end
    end
end

local function reloadHide(sling)
    if not (config.state.reloading and config.ragestatus.hideOnReload) then
        return false
    end
    local hrp = voidHrp()
    if hrp and not sling then
        clrVoidSnap()
        config.orbit.serverpos = Vector3.new(-43242003453, 312391923195534, -94523844823534)
        pcall(function()
            hrp.CFrame = CFrame.new(config.orbit.serverpos)
        end)
        return true
    end
    local randomX = math.random(-10000, 10000)
    local randomZ = math.random(-10000, 10000)
    config.orbit.serverpos = Vector3.new(randomX, -99999999999, randomZ)
    if sling and localfighter and localfighter.Entity and localfighter.Entity.RootPart then
        pcall(function()
            localfighter.Entity.RootPart.CFrame = CFrame.new(config.orbit.serverpos)
        end)
    end
    return true
end

local function isteammate(targetplayer)
    if not targetplayer then return false end
    return player:GetAttribute("TeamID") == targetplayer:GetAttribute("TeamID")
end

local function valid(char)
    if not char or not char.Parent then return false end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    if not char:FindFirstChild("HumanoidRootPart") then return false end
    local targetplayer = players:GetPlayerFromCharacter(char)
    if not targetplayer then return false end
    if config.target.teamCheck and isteammate(targetplayer) then return false end
    return true
end

local function wallcheck(fromPos, toPos)
    if not config.target.wallCheck then return true end
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {player.Character}
    params.FilterType = Enum.RaycastFilterType.Exclude
    local dir = toPos - fromPos
    local result = workspace:Raycast(fromPos, dir, params)
    if not result then return true end
    local hitPart = result.Instance
    if not hitPart then return true end
    local hitChar = hitPart:FindFirstAncestorOfClass("Model")
    if hitChar then
        local hitPlayer = players:GetPlayerFromCharacter(hitChar)
        if hitPlayer then return true end
    end
    return false
end

local function nearest()
    local sortMode = config.target.targetSort or "nearest"
    local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local myPos = myRoot and myRoot.Position or Vector3.zero
    local candidates = {}

    for _, targetplayer in players:GetPlayers() do
        if targetplayer == player then continue end
        if config.target.teamCheck and isteammate(targetplayer) then continue end
        local char = targetplayer.Character
        if not char then continue end
        if not valid(char) then continue end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then continue end

        local dist = (root.Position - myPos).Magnitude
        if config.target.maxDistance > 0 and dist > config.target.maxDistance then continue end

        if config.target.wallCheck then
            local cam = workspace.CurrentCamera
            local eyePos = cam and cam.CFrame.Position or myPos
            if not wallcheck(eyePos, root.Position) then continue end
        end

        local hum = char:FindFirstChildOfClass("Humanoid")
        local hp = hum and hum.Health or 0

        table.insert(candidates, {
            char = char,
            root = root,
            dist = dist,
            hp = hp,
            player = targetplayer,
        })
    end

    if #candidates == 0 then return nil end

    if sortMode == "farthest" then
        local best = nil
        for _, c in ipairs(candidates) do
            if not best or c.dist > best.dist then best = c end
        end
        return best and best.char
    elseif sortMode == "lowest hp" then
        local best = nil
        for _, c in ipairs(candidates) do
            if not best or c.hp < best.hp then best = c end
        end
        return best and best.char
    elseif sortMode == "highest hp" then
        local best = nil
        for _, c in ipairs(candidates) do
            if not best or c.hp > best.hp then best = c end
        end
        return best and best.char
    elseif sortMode == "closest to cursor" then
        local cursorpos = userinput:GetMouseLocation()
        local best, bestdist = nil, math.huge
        for _, c in ipairs(candidates) do
            local wts = getgenv().InstanceWorldToScreen or worldToScreen
            local screenpos, onscreen = wts(c.root.Position, camera)
            if onscreen and screenpos then
                local d = (Vector2.new(screenpos.X, screenpos.Y) - cursorpos).Magnitude
                if d < bestdist then
                    bestdist = d
                    best = c
                end
            end
        end
        return best and best.char
    elseif sortMode == "random" then
        return candidates[math.random(1, #candidates)].char
    else
        local best, bestdist = nil, math.huge
        for _, c in ipairs(candidates) do
            if c.dist < bestdist then
                bestdist = c.dist
                best = c
            end
        end
        return best and best.char
    end
end

local function hitpartfromname(character, partname)
    if not character then return nil end
    if partname == "Closest" then
        local mypos = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not mypos then return character:FindFirstChild("Head") end
        local closest, dist = nil, math.huge
        for _, part in pairs(character:GetChildren()) do
            if part:IsA("BasePart") then
                local d = (part.Position - mypos.Position).Magnitude
                if d < dist then
                    dist = d
                    closest = part
                end
            end
        end
        return closest or character:FindFirstChild("Head")
    elseif partname == "Random" then
        local parts = {"Head", "HumanoidRootPart", "UpperTorso"}
        return character:FindFirstChild(parts[math.random(#parts)]) or character:FindFirstChild("Head")
    else
        return character:FindFirstChild(partname) or character:FindFirstChild("Head")
    end
end

local function updatevel()
    if not config.target.character or not config.prediction.enabled then
        config.prediction.velocity = Vector3.new(0, 0, 0)
        config.prediction.lastposition = nil
        return
    end
    local root = config.target.character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local now = tick()
    local dt = now - config.prediction.lasttime
    if dt > 0 and dt < 0.1 then
        local currentpos = root.Position
        if config.prediction.lastposition then
            local instantvel = (currentpos - config.prediction.lastposition) / dt
            config.prediction.velocity = config.prediction.velocity:Lerp(instantvel, 0.6)
        end
        config.prediction.lastposition = currentpos
        config.prediction.lasttime = now
    end
end

local function predict(targetpart, origin)
    if not config.prediction.enabled or not targetpart then
        return targetpart and targetpart.Position or Vector3.new()
    end
    local basepos = targetpart.Position
    local distance = (basepos - origin).Magnitude
    local ping = 0
    pcall(function()
        ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() / 1000
    end)
    local traveltime = distance / 3000
    local totaltime = (traveltime + ping) * config.prediction.multiplier
    return basepos + (config.prediction.velocity * totaltime)
end

local function canuse()
    local char = player.Character
    if not char then return false end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    if config.target.safeHP > 0 and humanoid.Health < config.target.safeHP then return false end
    if isInfiniteWeapon() then return true end
    local current, _, melee = getammo()
    if current == nil then return true end
    return current > 0 or melee
end

local function clampVs(v)
    return math.clamp(tonumber(v) or 1, 0.1, 2)
end

local function randVs(minT, maxT)
    local a = clampVs(minT)
    local b = clampVs(maxT)
    if b < a then
        a, b = b, a
    end
    if a == b then
        return a
    end
    return a + math.random() * (b - a)
end

local vfrLim, vfrDead = 2147483646, 1147483646
local vfrSnap = { cf = nil, lv = nil, av = nil }

local function clrVoidSnap()
    vfrSnap.cf, vfrSnap.lv, vfrSnap.av = nil, nil, nil
end

local function voidHrp()
    local char = player.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function rndSkip(mi, ma, dmi, dma)
    local val = math.random(mi, ma)
    while val >= dmi and val <= dma do
        val = math.random(mi, ma)
    end
    return val
end

local function snapVoid(hrp)
    if not hrp then return end
    if lobbyCache() then return end
    vfrSnap.cf = hrp.CFrame
    vfrSnap.lv = hrp.AssemblyLinearVelocity
    vfrSnap.av = hrp.AssemblyAngularVelocity
    local lim, dead = vfrLim, vfrDead
    local p = Vector3.new(rndSkip(-lim, lim, -dead, dead), rndSkip(-lim, lim, -dead, dead), rndSkip(-lim, lim, -dead, dead))
    local mode = config.voidspam.bypassMode or "Extreme Networking"
    pcall(function()
        if mode == "Velocity" then
            local v = Vector3.new(rndSkip(-lim, lim, -dead, dead), rndSkip(-lim, lim, -dead, dead), rndSkip(-lim, lim, -dead, dead))
            hrp.CFrame = CFrame.new(p) * CFrame.Angles(math.pi, math.pi, math.pi)
            hrp.AssemblyLinearVelocity = v
            hrp.AssemblyAngularVelocity = v
        elseif mode == "CFrame only" then
            hrp.CFrame = CFrame.new(p) * CFrame.Angles(math.pi, math.pi, math.pi)
        elseif mode == "Hybrid" then
            hrp.CFrame = CFrame.new(p) * CFrame.Angles(math.pi, math.pi, math.pi)
            hrp.AssemblyLinearVelocity = Vector3.new(0, 0.01, 0)
        elseif mode == "Physics Bypass" then
            hrp.CFrame = CFrame.new(p) * CFrame.Angles(math.pi, math.pi, math.pi)
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        else
            hrp.CFrame = CFrame.new(p) * CFrame.Angles(math.pi, math.pi, math.pi)
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
    end)
end

runsvc:BindToRenderStep("vfr_csync", Enum.RenderPriority.First.Value, function()
    if not vfrSnap.cf then return end
    local hrp = voidHrp()
    if not hrp then return end
    pcall(function()
        hrp.CFrame = vfrSnap.cf
        hrp.AssemblyLinearVelocity = vfrSnap.lv
        hrp.AssemblyAngularVelocity = vfrSnap.av
    end)
end)

local function atkCfg()
    if pickMelee() and not config.target.attackCustomEnabled then
        local drop = tonumber(config.target.meleeFeetDrop) or 3.5
        return {
            height = 0,
            front = 0,
            side = 0,
            vertical = -drop,
            radius = 0,
        }
    end
    if config.target.attackCustomEnabled then
        return {
            height = config.target.customHeight or 2,
            front = config.target.customFront or 0,
            side = config.target.customSide or 0,
            vertical = config.target.customVertical or 0,
            radius = config.target.customRadius or 0,
        }
    end
    local mode = config.target.attackPosition or "default"
    local weapon = getweapon()
    if mode == "under" then
        return {
            height = 0,
            front = 0,
            side = 0,
            vertical = -(config.target.underOffset or 4),
            radius = 0,
        }
    end
    return {
        height = (weapon and weapon:lower():find("sniper")) and 8 or 2,
        front = 0,
        side = 0,
        vertical = 0,
        radius = 0,
    }
end

local function setOrbH(weapon)
    local settings = atkCfg()
    config.orbit.height = settings.height
end

local function orbBase(root)
    if not root then
        return Vector3.zero
    end
    local settings = atkCfg()
    local pos = root.Position
    local look = root.CFrame.LookVector
    local right = root.CFrame.RightVector
    return pos
        + (look * settings.front)
        + (right * settings.side)
        + Vector3.new(0, settings.vertical, 0)
end

local function setOrbR()
    local settings = atkCfg()
    config.orbit.radius = settings.radius or 0
end

local function refreshAtk()
    setOrbH(getweapon())
    setOrbR()
end

local function stopsync()
    if not config.state.csyncactive then return end
    if config.orbit.connection then
        config.orbit.connection:Disconnect()
        config.orbit.connection = nil
    end
    config.state.csyncactive = false
    config.orbit.active = false
    clrVoidSnap()
    config.voidspam.phase = nil
    if config.orbit.savedpos and localfighter and localfighter.Entity and localfighter.Entity.RootPart and not getgenv().InstanceUndergroundEnabled then
        local ok, pos = pcall(function() return config.orbit.savedpos end)
        if ok and pos then
            local currentPos = localfighter.Entity.RootPart.CFrame
            local distance = (currentPos.Position - pos.Position).Magnitude
            pcall(function()
                localfighter.Entity.RootPart.CFrame = pos
            end)
        end
    end
    config.orbit.serverpos = nil
    config.orbit.savedpos = nil
    config.voidspam.phase = nil
    oldpos = nil
end

local function isHidingPhase()
    return config.voidspam.enabled and config.voidspam.phase == "hide"
end

local function tickVoidSpam()
    if not config.voidspam.enabled then return end
    local now = tick()
    local elapsed = now - config.voidspam.lastswitch
    if config.voidspam.phase == "shoot" then
        if elapsed >= config.voidspam.currentduration then
            config.voidspam.phase = "hide"
            config.voidspam.currentduration = randVs(config.voidspam.hide_min, config.voidspam.hide_max)
            config.voidspam.lastswitch = now
        end
    elseif config.voidspam.phase == "hide" then
        if elapsed >= config.voidspam.currentduration then
            config.voidspam.phase = "shoot"
            config.voidspam.currentduration = randVs(config.voidspam.shoot_min, config.voidspam.shoot_max)
            config.voidspam.lastswitch = now
        end
    else
        config.voidspam.phase = "shoot"
        config.voidspam.currentduration = randVs(config.voidspam.shoot_min, config.voidspam.shoot_max)
        config.voidspam.lastswitch = now
    end
end

local function voidOk(sling)
    if not sling then return false end
    return config.voidspam.enabled or config.state.outofammo
end

local function tickVoid(sling, root)
    if sling then
        clrVoidSnap()
        return false
    end
    if not voidOk(sling) then
        clrVoidSnap()
        return false
    end
    local isHiding = config.state.outofammo or (config.voidspam.enabled and config.voidspam.phase == "hide")
    if isHiding then
        if config.voidspam.enabled and config.voidspam.phase == "hide" and not config.state.outofammo then
            local elapsed = tick() - config.voidspam.lastswitch
            if elapsed >= config.voidspam.currentduration then
                config.voidspam.phase = "shoot"
                config.voidspam.currentduration = randVs(config.voidspam.shoot_min, config.voidspam.shoot_max)
                config.voidspam.lastswitch = tick()
    clrVoidSnap()
    vhState.active = false
                return false
            end
        end
        clrVoidSnap()
        local hrp = voidHrp()
        if hrp then
            snapVoid(hrp)
        else
            if config.state.csyncactive then
                return true
            end
            local randomX = math.random(-10000, 10000)
            local randomZ = math.random(-10000, 10000)
            config.orbit.serverpos = Vector3.new(randomX, -99999999999, randomZ)
        end
        return true
    end
    if config.voidspam.enabled and config.voidspam.phase == "shoot" then
        local elapsed = tick() - config.voidspam.lastswitch
        if elapsed >= config.voidspam.currentduration then
            config.voidspam.phase = "hide"
            config.voidspam.currentduration = randVs(config.voidspam.hide_min, config.voidspam.hide_max)
            config.voidspam.lastswitch = tick()
        end
    end
    clrVoidSnap()
    return false
end

local function hideShot()
    if not config.voidspam.enabled then return end
    if isSling(getweapon()) then return end
end

local function applyBypassMode(rootPart, targetPos)
    if not rootPart then return end
    local mode = config.voidspam.bypassMode or "Extreme Networking"
    pcall(function()
        if mode == "Velocity" then
            rootPart.AssemblyLinearVelocity = (targetPos - rootPart.Position) * 100
        elseif mode == "CFrame only" then
            rootPart.CFrame = CFrame.new(targetPos)
        elseif mode == "Hybrid" then
            rootPart.CFrame = CFrame.new(targetPos)
            rootPart.AssemblyLinearVelocity = Vector3.new(0, 0.01, 0)
        else
            rootPart.CFrame = CFrame.new(targetPos)
            rootPart.AssemblyLinearVelocity = Vector3.zero
            rootPart.AssemblyAngularVelocity = Vector3.zero
        end
    end)
end

local function applyBypassModeCF(rootPart, targetCFrame)
    if not rootPart then return end
    local mode = config.voidspam.bypassMode or "Extreme Networking"
    pcall(function()
        if mode == "Velocity" then
            rootPart.AssemblyLinearVelocity = (targetCFrame.Position - rootPart.Position) * 100
        elseif mode == "CFrame only" then
            rootPart.CFrame = targetCFrame
        elseif mode == "Hybrid" then
            rootPart.CFrame = targetCFrame
            rootPart.AssemblyLinearVelocity = Vector3.new(0, 0.01, 0)
        else
            rootPart.CFrame = targetCFrame
            rootPart.AssemblyLinearVelocity = Vector3.zero
            rootPart.AssemblyAngularVelocity = Vector3.zero
        end
    end)
end

local function startsync()
    if config.state.csyncactive then return end
    if config.target.immune then return end
    if not config.target.character or not valid(config.target.character) then return end
    eqSlot()
    config.state.csyncactive = true
    config.orbit.active = true
    local weapon = getweapon()
    setOrbH(weapon)
    setOrbR()
    if not config.orbit.savedpos then
        if localfighter and localfighter.Entity and localfighter.Entity.RootPart then
            config.orbit.savedpos = localfighter.Entity.RootPart.CFrame
        end
    end
    config.orbit.connection = runsvc.Heartbeat:Connect(function(dt)
        if not config.state.csyncactive then return end
        if config.target.immune then stopsync() return end
        if not config.target.character or not valid(config.target.character) then stopsync() return end
        if not localfighter or not localfighter.Entity or not localfighter.Entity.RootPart then stopsync() return end

        if config.target.immune then stopsync() return end

        setOrbR()
        oldpos = localfighter.Entity.RootPart.CFrame

        local function isQuickSwapActive()
            if pickMelee() then return false end
            local lf = modules.fighter and modules.fighter.LocalFighter
            if not lf or not lf.EquippedItem then return false end
            local name = tostring(lf.EquippedItem:Get("Name") or ""):lower()
            return name:find("fist", 1, true) or name:find("utility", 1, true)
        end

        local _weapon = getweapon()
        local checksling = isSling(_weapon)

        if isQuickSwapActive() then return end

        if not ragePerf.delayActive then
            eqSlot()
        end

        if reloadHide(checksling) then return end

        if not checksling and config.voidspam.enabled and not config.target.immune then
            tickVoidSpam()
            if config.voidspam.phase == "hide" then
                local randomX = math.random(-10000, 10000)
                local randomZ = math.random(-10000, 10000)
                config.orbit.serverpos = Vector3.new(randomX, -99999999999, randomZ)
                local rp = localfighter and localfighter.Entity and localfighter.Entity.RootPart
                if rp then applyBypassMode(rp, config.orbit.serverpos) end
                return
            end
        end

        if not config.target.character then stopsync() return end
        local root = config.target.character:FindFirstChild("HumanoidRootPart")
        if not root then stopsync() return end

        if not checksling and isHidingPhase() then
            local randomX = math.random(-10000, 10000)
            local randomZ = math.random(-10000, 10000)
            config.orbit.serverpos = Vector3.new(randomX, -99999999999, randomZ)
            local rp = localfighter and localfighter.Entity and localfighter.Entity.RootPart
            if rp then applyBypassMode(rp, config.orbit.serverpos) end
            return
        end

        if checksling then
            if vhState and vhState.active then
                local trg = config.target.character:FindFirstChild("HumanoidRootPart")
                if trg then
                    local flat = Vector3.new(trg.CFrame.LookVector.X, 0, trg.CFrame.LookVector.Z).Unit
                    config.orbit.serverpos = trg.Position + Vector3.new(0, 15, 0) + (flat * 5)
                end
            end
        end

        if config.state.outofammo and not checksling and _weapon and not isInfiniteWeapon() then
            local hrp = voidHrp()
            if hrp then
                snapVoid(hrp)
            else
                local randomX = math.random(-10000, 10000)
                local randomZ = math.random(-10000, 10000)
                config.orbit.serverpos = Vector3.new(randomX, -99999999999, randomZ)
                local rp = localfighter and localfighter.Entity and localfighter.Entity.RootPart
                if rp then applyBypassMode(rp, config.orbit.serverpos) end
            end
            return
        end

        if not config.state.reloading and not config.state.outofammo and not checksling and not config.voidspam.enabled and rageActive() and config.target.enabled and config.target.character then
            local randomX = math.random(-10000, 10000)
            local randomZ = math.random(-10000, 10000)
            config.orbit.serverpos = Vector3.new(randomX, -99999999999, randomZ)
            local rp = localfighter and localfighter.Entity and localfighter.Entity.RootPart
            if rp then applyBypassMode(rp, config.orbit.serverpos) end
            return
        end

        local targetpos = orbBase(root)
        config.orbit.angle = config.orbit.angle + (config.orbit.orbitSpeed * dt)
        local offset = Vector3.new(
            math.cos(config.orbit.angle) * config.orbit.radius,
            config.orbit.height,
            math.sin(config.orbit.angle) * config.orbit.radius
        )
        config.orbit.serverpos = targetpos + offset

        if not getgenv().InstanceUndergroundEnabled then
            local rp = localfighter and localfighter.Entity and localfighter.Entity.RootPart
            if rp then
                local currentPos = rp.CFrame
                local newPos = CFrame.new(config.orbit.serverpos)
                local distance = (newPos.Position - currentPos.Position).Magnitude
                if distance < 2000 then
                    applyBypassModeCF(rp, newPos)
                    config.orbit.savedpos = currentPos
                end
            end
        end
    end)
end

local function autoshoot()
    if not isSling(getweapon()) and config.voidspam.enabled and config.voidspam.phase == "hide" then return end
    if not config.target.enabled or not config.target.character or not config.target.autoshoot then return end
    if config.target.immune then return end
    if not ragePerf.canShoot then return end
    if ragePerf.shootReadyAt and tick() < ragePerf.shootReadyAt then return end
    if not isSling(getweapon()) and config.voidspam.enabled and config.voidspam.phase == "hide" then return end
    if config.voidspam.enabled and config.voidspam.phase == "hide" then return end
    local weapon = getweapon()
    local checksling = isSling(weapon)
    eqSlot()
    local lf = modules.fighter and modules.fighter.LocalFighter
    if not lf or not lf.EquippedItem then return end
    if not isInfiniteWeapon() then
        if config.state.reloading or config.state.outofammo then return end
        if not canuse() then return end
    end
    if config.target.rightClickKnife and weapon == "Knife" then
        task.spawn(function()
            local vim = game:GetService("VirtualInputManager")
            local mousePos = game:GetService("UserInputService"):GetMouseLocation()
            vim:SendMouseButtonEvent(mousePos.X, mousePos.Y, 1, true, game, 0)
            task.wait(0.01)
            vim:SendMouseButtonEvent(mousePos.X, mousePos.Y, 1, false, game, 0)
        end)
        return
    end
    local targetChar = config.target.character
    if not valid(targetChar) then return end
    local hitPart = hitpartfromname(targetChar, config.target.hitpart)
    if not hitPart then return end
    local shootPos
    local targetPos
    if vhState and vhState.active and checksling then
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		shootPos = root and root.Position or Vector3.new()
		targetPos = predict(hitPart, shootPos)
	else
        if vhState and vhState.active then
			local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			shootPos = myRoot and myRoot.Position or Vector3.new()
        elseif config.state.csyncactive and config.orbit.serverpos then
            shootPos = config.orbit.serverpos
        else
            local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            shootPos = root and root.Position or Vector3.new()
        end
        targetPos = predict(hitPart, shootPos)
    end
    local data = {
        [utf8.char(1)] = {
            [utf8.char(0)] = modules.utility:EncodeCFrame(CFrame.new(shootPos, targetPos)),
            [utf8.char(1)] = modules.utility:EncodeCFrame(CFrame.new(shootPos, targetPos)),
            [utf8.char(2)] = hitPart,
            [utf8.char(3)] = modules.utility:EncodeCFrame(CFrame.new(0.43, 0.25, 0.42)),
        },
    }
    local equipped = lf.EquippedItem
    if equipped and equipped:Get("ObjectID") then
        ragePerf.lastAttackTick = tick()
        local attempts = math.floor(tonumber(config.target.shootAttempts) or 1)
        for _ = 1, attempts do
            pcall(function()
                replicatedstorage.Remotes.Replication.Fighter.UseItem:FireServer(
                    equipped:Get("ObjectID"),
                    modules.enums:ToEnum("StartShooting"),
                    data,
                    nil
                )
            end)
        end
        hideShot()
    end
end

local oldcamupdate = modules.camcontrol.Update
modules.camcontrol.Update = function(...)
    if getgenv().InstanceUndergroundEnabled then
        return oldcamupdate(...)
    elseif config.state.csyncactive and localfighter and localfighter.Entity and localfighter.Entity.RootPart and oldpos then
        localfighter.Entity.RootPart.CFrame = oldpos
    end
    local results = {oldcamupdate(...)}
    return unpack(results)
end

local immuneList = {}
local onImmune = {}
local onVulnerable = {}

local function bindimmune(callback)
    table.insert(onImmune, callback)
end

local function bindvulnerable(callback)
    table.insert(onVulnerable, callback)
end

runsvc.Heartbeat:Connect(function()
    for _, plr in pairs(players:GetPlayers()) do
        if plr == player then continue end
        local char = plr.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local immune = root and root:FindFirstChild("Attachment") ~= nil
        if immune and not immuneList[plr.Name] then
            immuneList[plr.Name] = true
            for _, cb in pairs(onImmune) do cb(plr) end
        elseif not immune and immuneList[plr.Name] then
            immuneList[plr.Name] = nil
            for _, cb in pairs(onVulnerable) do cb(plr) end
        end
    end
end)

bindimmune(function(plr)
    if config.target.lastplayer == plr then
        config.target.immune = true
        config.voidspam.phase = nil
        clrVoidSnap()
        indicator.Color = Color3.fromRGB(180, 0, 255)
        stopsync()
    end
end)

bindvulnerable(function(plr)
    if config.target.lastplayer == plr then
        config.target.immune = false
        indicator.Color = Color3.fromRGB(255, 50, 50)
        if config.target.enabled and config.target.character and valid(config.target.character) then
            startsync()
        end
    end
end)

local function cleartarget()
    config.target.enabled = false
    stopsync()
    config.target.character = nil
    getgenv().InstanceRagebotTarget = nil
    config.target.lastchar = nil
    config.target.lastplayer = nil
    config.target.manualkey = false
    config.target.immune = false
    if ragePerf.delayTask then task.cancel(ragePerf.delayTask) ragePerf.delayTask = nil end
    ragePerf.delayActive = false
    ragePerf.canShoot = false
    ragePerf.shootReadyAt = nil
    getgenv()._rageCanShoot = false
    getgenv()._rageDelayActive = false
    indicator.Color = Color3.fromRGB(255, 50, 50)
end

local function trackKill(targetPlayer)
    if not targetPlayer then return end
    config.kills.count = config.kills.count + 1
    config.kills.streak = config.kills.streak + 1
    config.kills.lastKillAt = tick()
end

local function settarget(char)
    if not char then return end
    clrVoidSnap()
    vhState.active = false
    local targetplr = players:GetPlayerFromCharacter(char)
    config.target.enabled = true
    config.target.character = char
    getgenv().InstanceRagebotTarget = char
    config.target.lastchar = char
    config.target.lastplayer = targetplr
    config.target.immune = false
    ragePerf.targetAcquiredAt = tick()
    ragePerf.canShoot = false
    getgenv()._rageCanShoot = false
    if ragePerf.delayTask then task.cancel(ragePerf.delayTask) end
    ragePerf.delayActive = true
    getgenv()._rageDelayActive = true
    indicator.Color = Color3.fromRGB(255, 50, 50)
    local root = char:FindFirstChild("HumanoidRootPart")
    local isImmune = root and root:FindFirstChild("Attachment")
    if isImmune then
        config.target.immune = true
        indicator.Color = Color3.fromRGB(180, 0, 255)
    end
    ragePerf.delayTask = task.spawn(function()
        task.wait(ragePerf.shootDelay)
        if not config.target.enabled or config.target.character ~= char then return end
        ragePerf.delayActive = false
        getgenv()._rageDelayActive = false
        if not isImmune then
            eqSlot()
            startsync()
        end
        ragePerf.shootReadyAt = tick() + ragePerf.shootCooldown
        ragePerf.canShoot = true
        getgenv()._rageCanShoot = true
    end)
end

local sling = {
    enabled = false,
    connections = {}
}

local function checksling()
    return isSling(getweapon())
end

local function nearplr()
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local found, best = nil, math.huge
    for _, p in ipairs(players:GetPlayers()) do
        if p == player or not p.Character then continue end
        local head = p.Character:FindFirstChild("HitboxHead") or p.Character:FindFirstChild("Head")
        if not head then continue end
        local d = (head.Position - root.Position).Magnitude
        if d < best then
            found = head
            best = d
        end
    end
    return found
end

local function slingshotTP()
    if sling.connections.touch then return end
    sling.connections.touch = workspace.DescendantAdded:Connect(function(d)
        if d:IsA("BasePart") or d:IsA("Model") then
            if d.Name == "Slingshot" or d.Name == "CoreProjectile" or d.Name == "OuterProjectile" then
                task.spawn(function()
					task.wait(0.06)
					local part = d:IsA("BasePart") and d or d:FindFirstChildWhichIsA("BasePart")
					if not part then return end
					part.CanTouch = true
					for i = 1, 60 do
						if not part.Parent or not part:IsDescendantOf(workspace) then break end
						local target = nearplr()
						if target and target:IsA("BasePart")
							and target.Parent
							and target:IsDescendantOf(workspace)
						then
							pcall(firetouchinterest, target, part, 0)
							pcall(firetouchinterest, target, part, 1)
						end
						task.wait()
					end
				end)
            end
        end
    end)
end

local function stopslingTP()
    if sling.connections.touch then
        sling.connections.touch:Disconnect()
        sling.connections.touch = nil
    end
end

local function targetpos()
    if not config.target.character then return nil end
    local root = config.target.character:FindFirstChild("HumanoidRootPart")
    return root and root.Position
end

local function updatesling()
    local slingon = checksling()
    local hastarget = config.target.enabled and config.target.character ~= nil
    if slingon then
        if not sling.enabled then
            sling.enabled = true
            slingshotTP()
        end
        if getgenv().InstanceSetUnderground then
            getgenv().InstanceSetUnderground(true)
        end
        vhState.active = hastarget
        if hastarget and not config.state.csyncactive then
            startsync()
        elseif not hastarget and config.state.csyncactive and not config.target.enabled then
            stopsync()
        end
    else
        if sling.enabled then
            sling.enabled = false
            stopslingTP()
        end
        if Toggles.AntiAimUnderground and not Toggles.AntiAimUnderground.Value then
            if getgenv().InstanceSetUnderground then
                getgenv().InstanceSetUnderground(false)
            end
        end
        vhState.active = false
    end
end

local function fflag()
    local hastarget = config.target.enabled and config.target.character and valid(config.target.character)
    local slingon = checksling()
    if hastarget and slingon then
        pcall(function()
            setfflag("TargetTimeDelayFacctorTenths", "999999")
        end)
    else
        pcall(function()
            setfflag("TargetTimeDelayFacctorTenths", "1")
        end)
    end
end

local targetHudAnimLast = tick()
runsvc.RenderStepped:Connect(function()
    local inLobby = getgenv().InstanceIsInLobby and getgenv().InstanceIsInLobby()
    local hudNeeded = config.visualizer.enabled
        or (config.ragestatus and config.ragestatus.enabled)
        or (config.hitNotifications and config.hitNotifications.enabled)
        or (config.target.enabled and config.target.character and config.prediction.enabled)
    if inLobby and not hudNeeded then
        return
    end
    if shouldSuppressGameplayOverlays() then
        tracerline.Visible = false
        traceroutline.Visible = false
        if ragebot.hideRageStatus then
            ragebot.hideRageStatus()
        end
        if ragebot.updateHitNotifications then
            ragebot.updateHitNotifications(0)
        end
        return
    end
    local now = tick()
    local hudDt = math.clamp(now - targetHudAnimLast, 0, 0.05)
    targetHudAnimLast = now
    if config.ragestatus and config.ragestatus.enabled and ragebot.drawStatus then
        ragebot.drawStatus()
    elseif ragebot.hideRageStatus then
        ragebot.hideRageStatus()
    end
    if ragebot.updateHitNotifications then
        ragebot.updateHitNotifications(hudDt)
    end
    if config.target.enabled and config.target.character and config.prediction.enabled then
        updatevel()
    end
end)

runsvc.Heartbeat:Connect(function()
    pcall(fflag)
    pcall(updatesling)
    pcall(tickAmmo)
    if config.target.auto and not config.target.manualkey then
        local myChar = player.Character
        local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
        if config.target.safeHP > 0 and myHum and myHum.Health < config.target.safeHP then
            if config.target.enabled then cleartarget() end
            return
        end
        local current, _, melee = getammo()
        local hasammo = current == nil or current > 0 or melee
        if hasammo and not config.state.reloading then
            if not config.target.enabled or not config.target.character or not valid(config.target.character) then
                local newtarget = nearest()
                if newtarget then
                    if config.target.enabled then stopsync() end
                    settarget(newtarget)
                else
                    -- no target, no action
                end
            end
        end
    end
    if config.target.enabled and config.target.character then
        if not valid(config.target.character) then
            if config.target.lastplayer then
                trackKill(config.target.lastplayer)
            end
            if config.target.autoSwitch then
                local newtarget = nearest()
                if newtarget then
                    cleartarget()
                    settarget(newtarget)
                    return
                end
            end
            cleartarget()
            return
        end
        if not ragePerf.delayActive then
            eqSlot()
        end
        if config.target.autoshoot and not config.target.immune then
            autoshoot()
        end
    end
end)

ragebot.config = config
ragebot.nearest = nearest
ragebot.settarget = settarget
ragebot.cleartarget = cleartarget
ragebot.vhState = vhState
ragebot.ragePerf = ragePerf
ragebot.getammo = getammo
ragebot.muzzlepos = muzzlepos
ragebot.valid = valid
ragebot.player = player
ragebot.eqSlot = eqSlot
ragebot.refreshAtk = refreshAtk

do
local config = ragebot.config
local ragePerf = ragebot.ragePerf
local getammo = ragebot.getammo
local muzzlepos = ragebot.muzzlepos
local valid = ragebot.valid
local player = ragebot.player
local vhState = ragebot.vhState
local camera = workspace.CurrentCamera

local function mkStatusLbl()
    local label = getgenv().InstanceTrackDrawingText(Drawing.new("Text"))
    label.Size = config.ragestatus.textSize or 13
    label.Font = 2
    label.Outline = true
    label.Center = true
    label.Visible = false
    label.Color = config.ragestatus.color
    pcall(function()
        label.OutlineColor = Color3.fromRGB(0, 0, 0)
    end)
    return label
end

local rageStatusLine1 = mkStatusLbl()
local rageStatusLine2 = mkStatusLbl()

local function styleStatusLbl(label)
    label.Size = config.ragestatus.textSize or 13
    label.Font = 2
    label.Outline = true
    label.Color = config.ragestatus.color
    pcall(function()
        label.OutlineColor = Color3.fromRGB(0, 0, 0)
    end)
end

local function statusAnchor()
    if config.ragestatus.mode == "muzzle" then
        local mp = muzzlepos and muzzlepos()
        if mp then
            local wts = getgenv().InstanceWorldToScreen or worldToScreen
            local screenPos, onScreen = wts(mp, camera)
            if onScreen and screenPos then
                return Vector2.new(screenPos.X, screenPos.Y)
            end
        end
    end
    local cam = camera or workspace.CurrentCamera
    if not cam then
        return Vector2.zero
    end
    return (cam.ViewportSize / 2) + Vector2.new(
        config.ragestatus.staticOffsetX or 0,
        config.ragestatus.staticOffsetY or 0
    )
end

local function rageActive()
    return config.target.enabled or config.target.auto or config.voidspam.enabled
end

local function killNm()
    if config.target.lastplayer then
        return config.target.lastplayer.Name
    end
    if config.target.character then
        local tp = game:GetService("Players"):GetPlayerFromCharacter(config.target.character)
        if tp then
            return tp.Name
        end
    end
    return "target"
end

local function inVoid()
    if vhState.active then return true end
    if config.voidspam.enabled and config.voidspam.phase == "hide" and isSling(getweapon()) then
        return true
    end
    if config.state.reloading and config.ragestatus.hideOnReload ~= false then
        return true
    end
    return false
end

local function isKilling()
    if not rageActive() then
        return false
    end
    if config.state.reloading or inVoid() then
        return false
    end
    if config.target.immune then
        return false
    end
    if not config.target.enabled or not config.target.character or not valid(config.target.character) then
        return false
    end
    if config.state.csyncactive then
        return true
    end
    if config.voidspam.enabled and config.voidspam.phase == "shoot" and isSling(getweapon()) then
        return true
    end
    if tick() - (ragePerf.lastAttackTick or 0) < math.max(ragePerf.shootCooldown, 0.05) then
        return true
    end
    return false
end

local function hudAmmo()
    if isInfiniteWeapon() then return "∞" end
    local cur, maxAmmo, melee = getammo()
    if cur == nil then return "∞" end
    if melee then return "melee" end
    return string.format("%d/%d", math.floor(cur or 0), math.max(math.floor(maxAmmo or 0), 0))
end

local function fmtVsTime(minT, maxT)
    local a = clampVs(minT)
    local b = clampVs(maxT)
    if b < a then
        a, b = b, a
    end
    if math.abs(a - b) < 0.05 then
        return string.format("%.1fs", a)
    end
    return string.format("%.1f-%.1fs", a, b)
end

local function vsDetail()
    if not config.voidspam.enabled then
        return ""
    end
    local vs = config.voidspam
    return string.format(
        "void %s atk · %s hide",
        fmtVsTime(vs.shoot_min, vs.shoot_max),
        fmtVsTime(vs.hide_min, vs.hide_max)
    )
end

local function getEnemyHealth()
    if not config.target.character then return "?" end
    local hum = config.target.character:FindFirstChildOfClass("Humanoid")
    if not hum then return "?" end
    return string.format("%.0f", hum.Health)
end

local function rageLines()
    local now = tick()
    if isKilling() then
        if not ragePerf.killStartAt then
            ragePerf.killStartAt = now
        end
    else
        ragePerf.killStartAt = nil
    end
    if config.state.reloading then
        return "ragebot: reloading..."
    end
    if inVoid() then
        return "ragebot: void"
    end
    if isKilling() then
        local name = killNm()
        return string.format("ragebot: killing %s...", name)
    end
    if rageActive() and config.target.enabled and config.target.character then
        return "ragebot: waiting..."
    end
    return "ragebot: idle"
end

local function drawStatus()
    if not config.ragestatus.enabled or shouldSuppressGameplayOverlays() then
        rageStatusLine1.Visible = false
        rageStatusLine2.Visible = false
        return
    end
    local anchor = statusAnchor()
    local gap = config.ragestatus.lineGap or 14
    if ragePerf.lastRageColor ~= config.ragestatus.color then
        ragePerf.lastRageColor = config.ragestatus.color
        styleStatusLbl(rageStatusLine1)
        styleStatusLbl(rageStatusLine2)
    end
    local mainLine = rageLines()
    local cur, maxAmmo = getammo()
    local ammoStr = cur ~= nil and string.format("%d/%d", math.floor(cur), math.max(math.floor(maxAmmo or 0), 0)) or "?/?"
    local hp = getEnemyHealth()
    local killStr = config.ragestatus.showKills and string.format(" [%d]", config.kills.count) or ""
    local line2Text = string.format("%s/%s%s", ammoStr, hp, killStr)
    local lineCount = 2
    local topOffset = -(lineCount - 1) * (gap / 2)
    if mainLine ~= ragePerf.lastRageStatusText then
        ragePerf.lastRageStatusText = mainLine
        rageStatusLine1.Text = mainLine
    end
    rageStatusLine1.Position = anchor + Vector2.new(0, topOffset)
    rageStatusLine1.Visible = config.ragestatus.enabled
    local nextY = topOffset + gap
    if line2Text ~= ragePerf.lastRageDetailText then
        ragePerf.lastRageDetailText = line2Text
        rageStatusLine2.Text = line2Text
    end
    rageStatusLine2.Position = anchor + Vector2.new(0, nextY)
    rageStatusLine2.Visible = config.ragestatus.enabled
end

ragebot.drawStatus = drawStatus
ragebot.hideRageStatus = function()
    rageStatusLine1.Visible = false
    rageStatusLine2.Visible = false
end
ragebot.clrVoidSnap = clrVoidSnap

end

do
local config = ragebot.config
local nearest = ragebot.nearest
local settarget = ragebot.settarget
local cleartarget = ragebot.cleartarget

local function togglekey()
    if config.target.auto then return end
    if config.target.enabled and config.target.character then
        cleartarget()
    else
        local target = nearest()
        if target then
            config.target.manualkey = true
            settarget(target)
        end
    end
end

local rageui = {
    ragebotBox = Tabs.Combat:AddRightGroupbox('ragebot'),
    ragebotvisualBox = Tabs.Combat:AddRightGroupbox('ragebot visualizer'),
}

rageui.ragebotBox:AddToggle("TargetOn", {
    Text = "enable",
    Default = false,
    Callback = function(val)
        config.target.rageMasterOn = val
        if config.target.auto then return end
        if val then
            local target = nearest()
            if target then
                config.target.manualkey = true
                settarget(target)
            end
        else
            cleartarget()
        end
    end
}):AddKeyPicker("TargetKey", {
    Text = "Ragebot",
    Default = "None",
    Mode = "Toggle",
    Callback = function() togglekey() end
})

rageui.ragebotBox:AddToggle("AutoTarget", {
    Text = "auto target",
    Default = false,
    Callback = function(val) config.target.auto = val end
})

rageui.ragebotBox:AddToggle("RightClickKnife", {
    Text = "right click knife",
    Default = false,
    Callback = function(val) config.target.rightClickKnife = val end
})

rageui.ragebotBox:AddSlider("TargetDelay", {
    Text = "target delay change",
    Default = 0.3,
    Min = 0,
    Max = 2.5,
    Rounding = 2,
    Suffix = "s",
    Callback = function(val)
        ragePerf.shootDelay = val
        if ragePerf.delayActive then
            if ragePerf.delayTask then task.cancel(ragePerf.delayTask) end
            ragePerf.delayTask = task.delay(val, function() ragePerf.delayActive = false getgenv()._rageDelayActive = false end)
        end
    end
})

rageui.ragebotBox:AddSlider("ShootCooldown", {
    Text = "delay shoot",
    Default = 0,
    Min = 0,
    Max = 2.5,
    Rounding = 2,
    Suffix = "s",
    Callback = function(val)
        ragePerf.shootCooldown = val
    end
})

local attackUnderVisGate = { Type = "Toggle", Value = false }
local attackCustomVisGate = { Type = "Toggle", Value = false }

local function syncAtkDeps()
    local mode = config.target.attackPosition or "default"
    local custom = config.target.attackCustomEnabled == true
    attackUnderVisGate.Value = (mode == "under" and not custom)
    attackCustomVisGate.Value = custom
    if attackUnderDep and attackUnderDep.Update then
        attackUnderDep:Update()
    end
    if attackCustomDep and attackCustomDep.Update then
        attackCustomDep:Update()
    end
end

local attackPosDropdown = rageui.ragebotBox:AddDropdown("AutoTargetAttackPos", {
    Text = "attack position",
    Default = "default",
    Values = { "default", "under" },
    Callback = function(val)
        config.target.attackPosition = val
        syncAtkDeps()
        if config.state.csyncactive and ragebot.refreshAtk then
            ragebot.refreshAtk()
        end
    end,
})

rageui.ragebotBox:AddToggle("AttackCustomOverride", {
    Text = "attack position",
    Default = false,
    Tooltip = "overrides attack position dropdown when enabled",
    Callback = function(val)
        config.target.attackCustomEnabled = val
        syncAtkDeps()
        if config.state.csyncactive and ragebot.refreshAtk then
            ragebot.refreshAtk()
        end
    end,
})

local attackUnderDep = rageui.ragebotBox:AddDependencyBox()

attackUnderDep:AddSlider("UnderAttackOffset", {
    Text = "under offset",
    Default = config.target.underOffset,
    Min = 1,
    Max = 25,
    Rounding = 1,
    Compact = true,
    Callback = function(val)
        config.target.underOffset = val
        if config.target.attackPosition == "under"
            and not config.target.attackCustomEnabled
            and config.state.csyncactive
            and ragebot.refreshAtk then
            ragebot.refreshAtk()
        end
    end,
})

attackUnderDep:SetupDependencies({
    { attackUnderVisGate, true },
})

local attackCustomDep = rageui.ragebotBox:AddDependencyBox()

local function onAtkCustom()
    if config.target.attackCustomEnabled and config.state.csyncactive and ragebot.refreshAtk then
        ragebot.refreshAtk()
    end
end

attackCustomDep:AddSlider("CustomAttackHeight", {
    Text = "orbit height",
    Default = config.target.customHeight,
    Min = -25,
    Max = 30,
    Rounding = 1,
    Compact = true,
    Callback = function(val)
        config.target.customHeight = val
        onAtkCustom()
    end,
})

attackCustomDep:AddSlider("CustomAttackFront", {
    Text = "front offset",
    Default = config.target.customFront,
    Min = -20,
    Max = 20,
    Rounding = 1,
    Compact = true,
    Callback = function(val)
        config.target.customFront = val
        onAtkCustom()
    end,
})

attackCustomDep:AddSlider("CustomAttackSide", {
    Text = "side offset",
    Default = config.target.customSide,
    Min = -20,
    Max = 20,
    Rounding = 1,
    Compact = true,
    Callback = function(val)
        config.target.customSide = val
        onAtkCustom()
    end,
})

attackCustomDep:AddSlider("CustomAttackVertical", {
    Text = "vertical offset",
    Default = config.target.customVertical,
    Min = -25,
    Max = 30,
    Rounding = 1,
    Compact = true,
    Callback = function(val)
        config.target.customVertical = val
        onAtkCustom()
    end,
})

attackCustomDep:AddSlider("CustomAttackRadius", {
    Text = "orbit radius",
    Default = config.target.customRadius,
    Min = 0,
    Max = 25,
    Rounding = 1,
    Compact = true,
    Callback = function(val)
        config.target.customRadius = val
        onAtkCustom()
    end,
})

attackCustomDep:SetupDependencies({
    { attackCustomVisGate, true },
})

syncAtkDeps()
task.defer(syncAtkDeps)

rageui.ragebotBox:AddDropdown("RageWeaponPick", {
    Text = "weapon",
    Default = config.target.weaponPick or "primary",
    Values = { "primary", "secondary", "melee" },
    Callback = function(val)
        config.target.weaponPick = val
        if config.state.csyncactive and ragebot.refreshAtk then
            ragebot.refreshAtk()
        end
        if ragebot.eqSlot then
            ragebot.eqSlot()
        end
    end,
})

rageui.ragebotBox:AddSlider("ShootAttempts", {
    Text = "shoot attempts",
    Default = 1,
    Min = 1,
    Max = 20,
    Rounding = 0,
    Suffix = "x",
    Callback = function(val)
        config.target.shootAttempts = math.floor(tonumber(val) or 1)
    end,
})

rageui.ragebotBox:AddDropdown("TargetPart", {
    Text = "hit part",
    Default = "Head",
    Values = {"Head", "HumanoidRootPart", "Torso", "UpperTorso", "Closest", "Random"},
    Callback = function(val) config.target.hitpart = val end
})

rageui.ragebotBox:AddDropdown("TargetSort", {
    Text = "target sort",
    Default = "nearest",
    Values = {"nearest", "farthest", "lowest hp", "highest hp", "closest to cursor", "random"},
    Callback = function(val) config.target.targetSort = val end
})

rageui.ragebotBox:AddToggle("TeamCheck", {
    Text = "team check",
    Default = true,
    Callback = function(val) config.target.teamCheck = val end
})

rageui.ragebotBox:AddToggle("WallCheck", {
    Text = "wall check",
    Default = false,
    Callback = function(val) config.target.wallCheck = val end
})

rageui.ragebotBox:AddSlider("MaxDistance", {
    Text = "max distance",
    Default = 0,
    Min = 0,
    Max = 5000,
    Rounding = 0,
    Suffix = " studs",
    Compact = true,
    Callback = function(val) config.target.maxDistance = val end
})

rageui.ragebotBox:AddSlider("SafeHP", {
    Text = "safe hp",
    Default = 0,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Suffix = " hp",
    Compact = true,
    Callback = function(val) config.target.safeHP = val end
})

rageui.ragebotBox:AddToggle("AutoSwitch", {
    Text = "auto switch target",
    Default = true,
    Callback = function(val) config.target.autoSwitch = val end
})

rageui.ragebotBox:AddToggle("PredictT", {
    Text = "prediction",
    Default = false,
    Callback = function(val) config.prediction.enabled = val end
})

rageui.ragebotBox:AddSlider("PredictMul", {
    Text = "prediction mult",
    Default = 1.2,
    Min = 0.1,
    Max = 3.0,
    Rounding = 1,
    Callback = function(val) config.prediction.multiplier = val end
})

rageui.ragebotBox:AddToggle("VoidSpam", {
    Text = "voidspam",
    Default = false,
    Callback = function(val)
        config.voidspam.enabled = val
        if val then
            if config.target.immune then
                config.voidspam.phase = nil
                return
            end
            if isSling(getweapon()) then
                config.voidspam.lastswitch = tick()
                config.voidspam.phase = "shoot"
                config.voidspam.currentduration = randVs(config.voidspam.shoot_min, config.voidspam.shoot_max)
            else
                config.voidspam.phase = nil
            end
        else
            config.voidspam.phase = nil
            if ragebot.clrVoidSnap then
                ragebot.clrVoidSnap()
            end
        end
    end
})

rageui.ragebotBox:AddSlider('VoidShootTime', {
    Default = 1,
    Text = "attack",
    Min = 0.1,
    Max = 2,
    Rounding = 1,
    Compact = true,
    Callback = function(val)
        val = clampVs(val)
        config.voidspam.shoot_min = val
        config.voidspam.shoot_max = val
    end
})
rageui.ragebotBox:AddSlider('VoidHideTime', {
    Default = 1,
    Text = "hide",
    Min = 0.1,
    Max = 2,
    Rounding = 1,
    Compact = true,
    Callback = function(val)
        val = clampVs(val)
        config.voidspam.hide_min = val
        config.voidspam.hide_max = val
    end
})

rageui.ragebotBox:AddDropdown("VoidBypassMode", {
    Text = "void bypass",
    Default = "Extreme Networking",
    Values = {"None","Velocity","CFrame only","Hybrid","Physics Bypass","Extreme Networking"},
    Callback = function(val) config.voidspam.bypassMode = val end
})

rageui.ragebotBox:AddSlider("OrbitSpeed", {
    Text = "orbit speed",
    Default = 9000,
    Min = 100,
    Max = 50000,
    Rounding = 0,
    Compact = true,
    Callback = function(val)
        config.orbit.orbitSpeed = val
        config.orbit.speed = val
    end
})

rageui.ragebotBox:AddToggle("ShowKills", {
    Text = "show kills",
    Default = true,
    Callback = function(val) config.ragestatus.showKills = val end
})

rageui.ragebotBox:AddToggle("ResetKills", {
    Text = "reset kill counter",
    Default = false,
    Callback = function(val)
        if val then
            config.kills.count = 0
            config.kills.streak = 0
        end
    end
})

do
local backstabPlayers = cloneref(game:GetService("Players"))
local backstabPlayer = backstabPlayers.LocalPlayer
local backstabOriginalFuncs = {}

local function startBackstab()
    config.backstab.enabled = true

    pcall(function()
        local knife = require(backstabPlayer.PlayerScripts.Modules.ItemTypes.Knife)
            or require(backstabPlayer.PlayerScripts.Modules.ItemTypes.Melee)
        if knife then
            for _, fname in ipairs({"IsBackstab", "CheckBackstab", "GetHitType", "CanBackstab"}) do
                if rawget(knife, fname) and type(knife[fname]) == "function" then
                    local old = knife[fname]
                    backstabOriginalFuncs[fname] = old
                    knife[fname] = function(...)
                        if config.backstab.enabled then return true end
                        return old(...)
                    end
                    break
                end
            end
        end
    end)

    pcall(function()
        for _, v in ipairs(getgc(true)) do
            if type(v) == "table" then
                if rawget(v, "StartShooting") and rawget(v, "IsKnife") then
                    local old = v.StartShooting
                    backstabOriginalFuncs[v] = old
                    v.StartShooting = function(self2, ...)
                        local results = {old(self2, ...)}
                        if results[3] and type(results[3]) == "table" then
                            results[3].IsBackstab = true
                            results[3].Backstab = true
                        end
                        return unpack(results)
                    end
                end
            end
        end
    end)

end

local function stopBackstab()
    config.backstab.enabled = false
    for fname, oldFunc in pairs(backstabOriginalFuncs) do
        pcall(function()
            local knife = require(backstabPlayer.PlayerScripts.Modules.ItemTypes.Knife)
                or require(backstabPlayer.PlayerScripts.Modules.ItemTypes.Melee)
            if knife and rawget(knife, fname) then
                knife[fname] = oldFunc
            end
        end)
    end
    for tbl, oldFunc in pairs(backstabOriginalFuncs) do
        if type(tbl) == "table" and rawget(tbl, "StartShooting") then
            tbl.StartShooting = oldFunc
        end
    end
    backstabOriginalFuncs = {}
end

rageui.ragebotBox:AddToggle("Backstab", {
    Text = "always backstab",
    Default = false,
    Callback = function(val)
        config.backstab.enabled = val
        if getgenv().InstanceConfigLoading then return end
        if val then
            startBackstab()
        else
            stopBackstab()
        end
    end,
})

rageui.ragebotBox:AddToggle("BackstabCamera", {
    Text = "backstab cam",
    Default = false,
    Callback = function(val)
        config.backstab.camera = val
    end,
})
end

local rageStatusToggle = rageui.ragebotvisualBox:AddToggle("RageStatus", {
    Text = "rage status",
    Default = config.ragestatus.enabled,
    Callback = function(val)
        config.ragestatus.enabled = val
        if val then
            if ragebot.drawStatus then
                ragebot.drawStatus()
            end
        else
            if ragebot.hideRageStatus then
                ragebot.hideRageStatus()
            end
        end
    end,
}):AddColorPicker("RageStatusColor", {
    Title = "text color",
    Default = config.ragestatus.color,
    Callback = function(val)
        config.ragestatus.color = val
        if ragebot.ragePerf then
            ragebot.ragePerf.lastRageColor = nil
        end
    end,
})

local rageStatusDep = rageui.ragebotvisualBox:AddDependencyBox()
rageStatusDep:SetupDependencies({
    { rageStatusToggle, true },
})

rageStatusDep:AddDropdown("RageStatusMode", {
    Text = "position",
    Default = "static",
    Values = { "static", "muzzle" },
    Callback = function(val)
        config.ragestatus.mode = val
    end,
})

rageStatusDep:AddSlider("RageStatusStaticX", {
    Text = "static x",
    Default = config.ragestatus.staticOffsetX,
    Min = -500,
    Max = 500,
    Rounding = 0,
    Compact = true,
    Callback = function(val)
        config.ragestatus.staticOffsetX = val
    end,
})

rageStatusDep:AddSlider("RageStatusStaticY", {
    Text = "static y",
    Default = config.ragestatus.staticOffsetY,
    Min = -500,
    Max = 500,
    Rounding = 0,
    Compact = true,
    Callback = function(val)
        config.ragestatus.staticOffsetY = val
    end,
})

rageStatusDep:AddToggle("RageStatusAmmo", {
    Text = "show ammo line",
    Default = true,
    Callback = function(val)
        config.ragestatus.showAmmo = val
    end,
})

rageStatusDep:AddToggle("RageStatusReloadHide", {
    Text = "hide while reloading",
    Default = true,
    Callback = function(val)
        config.ragestatus.hideOnReload = val
    end,
})

rageStatusDep:AddSlider("RageStatusTextSize", {
    Text = "text size",
    Default = 15,
    Min = 10,
    Max = 30,
    Rounding = 0,
    Compact = true,
    Callback = function(val)
        config.ragestatus.textSize = val
        ragePerf.lastRageColor = nil
    end,
})

rageStatusDep:AddSlider("RageStatusLineGap", {
    Text = "line gap",
    Default = 15,
    Min = 5,
    Max = 40,
    Rounding = 0,
    Compact = true,
    Callback = function(val)
        config.ragestatus.lineGap = val
    end,
})

rageui.ragebotvisualBox:AddToggle("VisEnabled", {
    Text = "enable",
    Default = false,
    Callback = function(val) config.visualizer.enabled = val end
})

rageui.ragebotvisualBox:AddToggle("VisTracerEnabled", {
    Text = "tracer",
    Default = false,
    Callback = function(val) config.visualizer.tracer.enabled = val end
}):AddColorPicker("VisTracerColor", {
    Default = config.visualizer.tracer.color,
    Callback = function(val) config.visualizer.tracer.color = val end
})

rageui.ragebotvisualBox:AddDropdown("VisTracerStart", {
    Text = "tracer start",
    Default = "cursor",
    Values = {"cursor", "muzzle"},
    Callback = function(val) config.visualizer.tracer.start_point = val end
})

rageui.ragebotvisualBox:AddToggle("VisTracerOutline", {
    Text = "tracer outline",
    Default = true,
    Callback = function(val) config.visualizer.tracer.outline = val end
})

rageui.ragebotvisualBox:AddSlider("VisTracerThickness", {
    Text = "tracer thickness",
    Default = 1,
    Min = 0.1,
    Max = 3,
    Rounding = 1,
    Callback = function(val) config.visualizer.tracer.thickness = val end
})
end
end

do
local config = ragebot.config
local ragePerf = ragebot.ragePerf
local isRageEnabled = ragebot.isRageEnabled
local players = cloneref(game:GetService("Players"))
local player = players.LocalPlayer
local TextService = game:GetService("TextService")
local UserInputService = cloneref(game:GetService("UserInputService"))

local hitNotifEntries = {}
local hitNotifHpTrack = {}
local hitNotifHumConn = {}
local hitNotifCharConn = {}
local hitNotifResolveQueues = {}
local hitNotifResolveBusy = {}

local HIT_NOTIF_ANIM_STYLES = {
    "fade",
    "slide left",
    "slide right",
    "slide down",
    "bounce",
    "fade bounce",
    "scale",
}

local HIT_NOTIF_STACK_WIDTH = 300

local hitNotifRoot = Library:Create("Frame", {
    Name = "HitNotifications",
    BackgroundTransparency = 1,
    Size = UDim2.new(0, HIT_NOTIF_STACK_WIDTH, 1, -24),
    Position = UDim2.fromOffset(12, 12),
    ZIndex = 250,
    Parent = Library.ScreenGui,
})

local function getHitNotifScreenPosition()
    local hn = config.hitNotifications
    local preset = hn.position or "Top Left"
    if preset == "Custom" then
        return Vector2.new(hn.offsetX or 12, hn.offsetY or 12)
    end

    local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
    local margin = 12
    local stackH = 280
    local centerX = vp.X * 0.5 - HIT_NOTIF_STACK_WIDTH * 0.5

    local presets = {
        ["Top Left"] = Vector2.new(margin, margin),
        ["Top Center"] = Vector2.new(centerX, margin),
        ["Top Right"] = Vector2.new(vp.X - HIT_NOTIF_STACK_WIDTH - margin, margin),
        ["Center Left"] = Vector2.new(margin, vp.Y * 0.5 - stackH * 0.5),
        ["Center"] = Vector2.new(centerX, vp.Y * 0.5 - stackH * 0.5),
        ["Center Right"] = Vector2.new(vp.X - HIT_NOTIF_STACK_WIDTH - margin, vp.Y * 0.5 - stackH * 0.5),
        ["Bottom Left"] = Vector2.new(margin, vp.Y - stackH - margin),
        ["Bottom Center"] = Vector2.new(centerX, vp.Y - stackH - margin),
        ["Bottom Right"] = Vector2.new(vp.X - HIT_NOTIF_STACK_WIDTH - margin, vp.Y - stackH - margin),
    }
    return presets[preset] or presets["Top Left"]
end

local function applyHitNotifRootPosition()
    local pos = getHitNotifScreenPosition()
    hitNotifRoot.Position = UDim2.fromOffset(math.floor(pos.X), math.floor(pos.Y))
end

local function hnEaseOutCubic(t)
    return 1 - (1 - t) ^ 3
end

local function hnEaseInCubic(t)
    return t * t * t
end

local function hnEaseOutBack(t)
    local c1 = 1.70158
    return 1 + (c1 + 1) * (t - 1) ^ 3 + c1 * (t - 1) ^ 2
end

local HIT_NOTIF_IN_SAMPLERS = {}
local HIT_NOTIF_OUT_SAMPLERS = {}

HIT_NOTIF_IN_SAMPLERS.fade = function(t)
    return hnEaseOutCubic(t), 0, 0, 1
end
HIT_NOTIF_IN_SAMPLERS["slide left"] = function(t)
    local e = hnEaseOutCubic(t)
    return e, (1 - e) * -52, 0, 1
end
HIT_NOTIF_IN_SAMPLERS["slide right"] = function(t)
    local e = hnEaseOutCubic(t)
    return e, (1 - e) * 52, 0, 1
end
HIT_NOTIF_IN_SAMPLERS["slide down"] = function(t)
    local e = hnEaseOutCubic(t)
    return e, 0, (1 - e) * -32, 1
end
HIT_NOTIF_IN_SAMPLERS.bounce = function(t)
    return math.clamp(t * 6, 0, 1), 0, 0, hnEaseOutBack(t)
end
HIT_NOTIF_IN_SAMPLERS["fade bounce"] = function(t)
    return hnEaseOutCubic(t), 0, 0, 0.78 + hnEaseOutBack(t) * 0.28
end
HIT_NOTIF_IN_SAMPLERS.scale = function(t)
    local e = hnEaseOutCubic(t)
    return e, 0, 0, 0.62 + e * 0.38
end

HIT_NOTIF_OUT_SAMPLERS.fade = function(t)
    local e = hnEaseInCubic(t)
    return 1 - e, 0, 0, 1
end
HIT_NOTIF_OUT_SAMPLERS["slide left"] = function(t)
    local e = hnEaseInCubic(t)
    return 1 - e, e * -52, 0, 1
end
HIT_NOTIF_OUT_SAMPLERS["slide right"] = function(t)
    local e = hnEaseInCubic(t)
    return 1 - e, e * 52, 0, 1
end
HIT_NOTIF_OUT_SAMPLERS["slide down"] = function(t)
    local e = hnEaseInCubic(t)
    return 1 - e, 0, e * 32, 1
end
HIT_NOTIF_OUT_SAMPLERS.bounce = function(t)
    local e = hnEaseInCubic(t)
    return 1 - e, 0, 0, 1 - e * 0.1 + math.sin(t * math.pi) * 0.09 * (1 - e)
end
HIT_NOTIF_OUT_SAMPLERS["fade bounce"] = function(t)
    local e = hnEaseInCubic(t)
    return 1 - e, 0, 0, 1 - e * 0.08 + math.sin(t * math.pi * 1.5) * 0.07 * (1 - t)
end
HIT_NOTIF_OUT_SAMPLERS.scale = function(t)
    local e = hnEaseInCubic(t)
    return 1 - e, 0, 0, 1 - e * 0.4
end

local function sampleHitNotifAnim(style, t, isOut)
    t = math.clamp(t, 0, 1)
    local map = isOut and HIT_NOTIF_OUT_SAMPLERS or HIT_NOTIF_IN_SAMPLERS
    local fn = map[string.lower(style or "fade")] or map.fade
    local a, ox, oy, sc = fn(t)
    return math.clamp(a, 0, 1), ox, oy, math.clamp(sc, 0.01, 1.35)
end

local function applyHitNotifVisual(entry, alpha, ox, oy, scale)
    local tr = 1 - math.clamp(alpha, 0, 1)
    entry.outer.BackgroundTransparency = tr
    entry.inner.BackgroundTransparency = tr
    entry.label.TextTransparency = tr
    if entry.uiScale then
        entry.uiScale.Scale = scale
    end
    local y = (entry.displayY or entry.targetY or 0) + oy
    entry.outer.Position = UDim2.fromOffset(math.floor(ox + 0.5), math.floor(y + 0.5))
end

local function measureHitNotifBox(text, textSize)
    local bounds = TextService:GetTextSize(text, textSize, Enum.Font.Code, Vector2.new(1000, 40))
    return math.clamp(bounds.X + 20, 200, 540), math.max(bounds.Y + 12, 26)
end

local function removeHitNotifEntry(index)
    local entry = hitNotifEntries[index]
    if entry and entry.outer then
        pcall(function()
            entry.outer:Destroy()
        end)
    end
    table.remove(hitNotifEntries, index)
end

local function formatHitNotifLine(targetName, dmg, bodyPart)
    return string.format(
        "hit %s for %d in the %s",
        targetName,
        math.floor(dmg + 0.5),
        bodyPart or "Body"
    )
end

local function createHitNotifBox(text)
    local hn = config.hitNotifications
    local textSize = hn.textSize or 14
    local boxW, boxH = measureHitNotifBox(text, textSize)

    local outer = Library:Create("Frame", {
        Name = "HitNotifOuter",
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.OutlineColor,
        BorderMode = Enum.BorderMode.Inset,
        Size = UDim2.fromOffset(boxW, boxH),
        Position = UDim2.fromOffset(0, 0),
        BackgroundTransparency = 1,
        ZIndex = 251,
        Parent = hitNotifRoot,
    })
    Library:AddToRegistry(outer, {
        BackgroundColor3 = "MainColor",
        BorderColor3 = "OutlineColor",
    }, true)

    local uiScale = Instance.new("UIScale")
    uiScale.Scale = 0.75
    uiScale.Parent = outer

    local inner = Library:Create("Frame", {
        Name = "HitNotifInner",
        BackgroundColor3 = Library.BackgroundColor,
        BorderColor3 = Library.OutlineColor,
        BorderMode = Enum.BorderMode.Inset,
        Position = UDim2.fromOffset(1, 1),
        Size = UDim2.new(1, -2, 1, -2),
        BackgroundTransparency = 1,
        ZIndex = 252,
        Parent = outer,
    })
    Library:AddToRegistry(inner, {
        BackgroundColor3 = "BackgroundColor",
        BorderColor3 = "OutlineColor",
    }, true)

    local label = Library:CreateLabel({
        Size = UDim2.new(1, -12, 1, 0),
        Position = UDim2.fromOffset(6, 0),
        Text = text,
        Font = Enum.Font.Code,
        TextSize = textSize,
        TextColor3 = hn.color or Library.FontColor,
        TextTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 254,
        Parent = inner,
    }, false)

    return {
        outer = outer,
        inner = inner,
        label = label,
        uiScale = uiScale,
        boxW = boxW,
        boxH = boxH,
    }
end

local function pushHitNotification(targetName, dmg, bodyPart)
    if not config.hitNotifications.enabled or dmg <= 0 then
        return
    end

    local hn = config.hitNotifications
    if hn.uiNotif then
        local msg = formatHitNotifLine(targetName, dmg, bodyPart)
        pcall(function() Library:Notify(msg, hn.duration or 3) end)
        return
    end

    local now = tick()
    applyHitNotifRootPosition()
    hitNotifRoot.Visible = true

    local parts = createHitNotifBox(formatHitNotifLine(targetName, dmg, bodyPart))
    table.insert(hitNotifEntries, 1, {
        outer = parts.outer,
        inner = parts.inner,
        label = parts.label,
        uiScale = parts.uiScale,
        boxW = parts.boxW,
        boxH = parts.boxH,
        start = now,
        phaseStart = now,
        phase = "in",
        duration = hn.duration or 3,
        targetY = 0,
        displayY = 0,
    })

    while #hitNotifEntries > math.clamp(hn.maxVisible or 8, 1, 25) do
        removeHitNotifEntry(#hitNotifEntries)
    end
end

local function getPlayerFromHitPart(hitPart)
    if not hitPart then
        return nil, nil, nil
    end
    local char = hitPart:FindFirstAncestorOfClass("Model")
    if not char and hitPart.Parent and hitPart.Parent:IsA("Model") then
        char = hitPart.Parent
    end
    if not char then
        return nil, nil, nil
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local plr = players:GetPlayerFromCharacter(char)
    return plr, hum, hitPart.Name
end

local function shouldNotifyPlayerHit(plr)
    if not config.hitNotifications.enabled or plr == player then
        return false
    end

    local lastShot = getgenv().InstanceCombatLastShotAt or 0
    if tick() - lastShot < 4 then
        return true
    end

    if config.target.lastplayer == plr then
        return true
    end
    if config.target.enabled and config.target.character then
        local tp = players:GetPlayerFromCharacter(config.target.character)
        if tp == plr then
            return true
        end
    end
    local lastHit = ragePerf.lastHitAtByPlayer[plr]
    return lastHit ~= nil and tick() - lastHit < 4
end

local function tryClaimHitDamage(plr, hum, bodyPart, allowFallback)
    if not hum or not hum.Parent then
        return false
    end

    local last = hitNotifHpTrack[plr]
    if last == nil then
        last = hum.Health
        hitNotifHpTrack[plr] = last
    end

    local cur = hum.Health
    local dmg = last - cur
    if dmg >= 0.01 then
        pushHitNotification(plr.Name, dmg, bodyPart or ragePerf.hitPartByPlayer[plr] or config.target.hitpart or "Body")
        hitNotifHpTrack[plr] = cur
        ragePerf.lastHitAtByPlayer[plr] = tick()
        return true
    end

    if allowFallback then
        pushHitNotification(plr.Name, 1, bodyPart or ragePerf.hitPartByPlayer[plr] or config.target.hitpart or "Body")
        ragePerf.lastHitAtByPlayer[plr] = tick()
        return true
    end

    return false
end

local function resolveQueuedHitNotif(plr, job)
    local hum = job.hum
    local bodyPart = job.bodyPart
    if not hum or not hum.Parent then
        return
    end

    if tryClaimHitDamage(plr, hum, bodyPart, false) then
        return
    end

    for _ = 1, 15 do
        task.wait(0)
        if tryClaimHitDamage(plr, hum, bodyPart, false) then
            return
        end
    end

    for _ = 1, 8 do
        task.wait(0.03)
        if tryClaimHitDamage(plr, hum, bodyPart, false) then
            return
        end
    end

    tryClaimHitDamage(plr, hum, bodyPart, true)
end

local function enqueueHitNotifResolve(plr, hum, bodyPart)
    hitNotifResolveQueues[plr] = hitNotifResolveQueues[plr] or {}
    table.insert(hitNotifResolveQueues[plr], {
        hum = hum,
        bodyPart = bodyPart,
        queuedAt = tick(),
    })

    if hitNotifResolveBusy[plr] then
        return
    end

    hitNotifResolveBusy[plr] = true
    task.spawn(function()
        while hitNotifResolveQueues[plr] and #hitNotifResolveQueues[plr] > 0 do
            local job = table.remove(hitNotifResolveQueues[plr], 1)
            resolveQueuedHitNotif(plr, job)
        end
        hitNotifResolveBusy[plr] = false
    end)
end

local function pollHitNotifHealth()
    if not config.hitNotifications.enabled then
        return
    end

    for _, plr in ipairs(players:GetPlayers()) do
        if plr == player then
            continue
        end
        if not shouldNotifyPlayerHit(plr) then
            continue
        end

        local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
        if not hum then
            continue
        end

        local last = hitNotifHpTrack[plr]
        if last == nil then
            hitNotifHpTrack[plr] = hum.Health
            continue
        end

        local cur = hum.Health
        if cur < last - 0.01 then
            local bodyPart = ragePerf.hitPartByPlayer[plr] or config.target.hitpart or "Body"
            pushHitNotification(plr.Name, last - cur, bodyPart)
            hitNotifHpTrack[plr] = cur
            ragePerf.lastHitAtByPlayer[plr] = tick()
            if cur <= 0 then
                local tryKill = getgenv().InstanceTryKillSound
                if tryKill then
                    tryKill(plr, last, cur)
                end
            end
        elseif cur > last then
            hitNotifHpTrack[plr] = cur
        end
    end
end

local function recordLocalHitTarget(plr, hum, bodyPart)
    if not plr or not hum or plr == player then
        return
    end
    localHitTargets[hum] = {
        plr = plr,
        bodyPart = bodyPart,
        hitAt = tick(),
        lastHp = hum.Health,
    }
end

local function notifyProjectileImpact(hitPart)
    if not hitPart then
        return
    end

    local plr, hum, bodyPart = getPlayerFromHitPart(hitPart)
    if not plr or not hum or plr == player then
        return
    end

    ragePerf.hitPartByPlayer[plr] = bodyPart
    ragePerf.lastHitAtByPlayer[plr] = tick()
    recordLocalHitTarget(plr, hum, bodyPart)

    if not config.hitNotifications.enabled then
        return
    end

    if not shouldNotifyPlayerHit(plr) then
        return
    end

    enqueueHitNotifResolve(plr, hum, bodyPart)
end

ragebot.notifyProjectileImpact = notifyProjectileImpact

local function onTargetHealthChanged(plr, newHp)
    if not config.hitNotifications.enabled then
        return
    end
    if hitNotifHpTrack[plr] == nil then
        hitNotifHpTrack[plr] = newHp
        return
    end
    if newHp > (hitNotifHpTrack[plr] or newHp) then
        hitNotifHpTrack[plr] = newHp
    end
end

local function unbindHitNotifPlayer(plr)
    if hitNotifHumConn[plr] then
        hitNotifHumConn[plr]:Disconnect()
        hitNotifHumConn[plr] = nil
    end
    if hitNotifCharConn[plr] then
        hitNotifCharConn[plr]:Disconnect()
        hitNotifCharConn[plr] = nil
    end
    hitNotifHpTrack[plr] = nil
    hitNotifResolveQueues[plr] = nil
    hitNotifResolveBusy[plr] = nil
end

local function bindHitNotifCharacter(plr, char)
    if plr == player or not char then
        return
    end
    if hitNotifHumConn[plr] then
        hitNotifHumConn[plr]:Disconnect()
        hitNotifHumConn[plr] = nil
    end
    local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 8)
    if not hum then
        return
    end
    hitNotifHpTrack[plr] = hum.Health
    hitNotifHumConn[plr] = hum.HealthChanged:Connect(function(newHp)
        local localHit = localHitTargets and localHitTargets[hum]
        if newHp <= 0 and localHit and localHit.plr and localHit.plr ~= player and not config.hitNotifications.enabled then
            local tryKill2 = getgenv().InstanceTryKillSound
            if tryKill2 then
                tryKill2(localHit.plr, hitNotifHpTrack[plr] or 0, newHp)
            end
            if localHitTargets then
                localHitTargets[hum] = nil
            end
        end

        if not config.hitNotifications.enabled then
            local last = hitNotifHpTrack[plr]
            if last == nil or newHp > last then
                hitNotifHpTrack[plr] = newHp
            end
            return
        end

        local last = hitNotifHpTrack[plr]
        if last == nil then
            hitNotifHpTrack[plr] = newHp
            return
        end

        if newHp < last - 0.01 then
            if shouldNotifyPlayerHit(plr) then
                local bodyPart = ragePerf.hitPartByPlayer[plr] or config.target.hitpart or "Body"
                pushHitNotification(plr.Name, last - newHp, bodyPart)
                ragePerf.lastHitAtByPlayer[plr] = tick()
            end
            if newHp <= 0 then
                local tryKill = getgenv().InstanceTryKillSound
                if tryKill then
                    tryKill(plr, last, newHp)
                end
            end
            hitNotifHpTrack[plr] = newHp
        elseif newHp > last then
            hitNotifHpTrack[plr] = newHp
        end
    end)

    hum.Died:Connect(function()
        local last = hitNotifHpTrack[plr]
        local tryKill = getgenv().InstanceTryKillSound
        if tryKill and last and last > 0 then
            tryKill(plr, last, 0)
        end

        local localHit = localHitTargets and localHitTargets[hum]
        if localHit then
            if not config.hitNotifications.enabled then
                local tryKill2 = getgenv().InstanceTryKillSound
                if tryKill2 and localHit.plr and localHit.plr ~= player then
                    tryKill2(localHit.plr, last or 0, 0)
                end
            end
            if localHitTargets then
                localHitTargets[hum] = nil
            end
        end
    end)
end

local function bindHitNotifPlayer(plr)
    if plr == player then
        return
    end
    if hitNotifCharConn[plr] then
        hitNotifCharConn[plr]:Disconnect()
    end
    hitNotifCharConn[plr] = plr.CharacterAdded:Connect(function(char)
        bindHitNotifCharacter(plr, char)
    end)
    if plr.Character then
        bindHitNotifCharacter(plr, plr.Character)
    end
end

players.PlayerAdded:Connect(bindHitNotifPlayer)
players.PlayerRemoving:Connect(unbindHitNotifPlayer)
for _, plr in players:GetPlayers() do
    bindHitNotifPlayer(plr)
end

local function updateHitNotifications(dt)
    local hn = config.hitNotifications
    if not hn.enabled or shouldSuppressGameplayOverlays() then
        hitNotifRoot.Visible = false
        if not hn.enabled then
            for i = #hitNotifEntries, 1, -1 do
                removeHitNotifEntry(i)
            end
        end
        return
    end

    pollHitNotifHealth()

    hitNotifRoot.Visible = #hitNotifEntries > 0
    applyHitNotifRootPosition()

    dt = dt or 0
    local now = tick()
    local inDur = math.clamp(hn.animInDuration or 0.52, 0.15, 2)
    local outDur = math.clamp(hn.animOutDuration or 0.38, 0.15, 2)
    local totalDur = hn.duration or 3
    local gap = hn.stackGap or 6
    local inStyle = hn.inAnimation or "fade bounce"
    local outStyle = hn.outAnimation or "fade"

    local y = 0
    for _, entry in ipairs(hitNotifEntries) do
        entry.targetY = y
        entry.displayY = entry.displayY or y
        if dt > 0 then
            entry.displayY = entry.displayY + (entry.targetY - entry.displayY) * (1 - math.exp(-dt * 14))
        else
            entry.displayY = entry.targetY
        end
        y = y + (entry.boxH or 26) + gap
    end

    local i = 1
    while i <= #hitNotifEntries do
        local entry = hitNotifEntries[i]
        local age = now - entry.start

        if entry.phase == "in" then
            local t = (now - entry.phaseStart) / inDur
            if t >= 1 then
                entry.phase = "hold"
                entry.phaseStart = now
                t = 1
            end
            local a, ox, oy, sc = sampleHitNotifAnim(inStyle, t, false)
            applyHitNotifVisual(entry, a, ox, oy, sc)
        elseif entry.phase == "hold" then
            applyHitNotifVisual(entry, 1, 0, 0, 1)
            if age >= totalDur - outDur then
                entry.phase = "out"
                entry.phaseStart = now
            end
        elseif entry.phase == "out" then
            local t = (now - entry.phaseStart) / outDur
            if t >= 1 then
                removeHitNotifEntry(i)
                continue
            end
            local a, ox, oy, sc = sampleHitNotifAnim(outStyle, t, true)
            applyHitNotifVisual(entry, a, ox, oy, sc)
        else
            entry.phase = "in"
            entry.phaseStart = now
        end

        i = i + 1
    end
end

ragebot.updateHitNotifications = updateHitNotifications
ragebot.clearHitNotifications = function()
    for i = #hitNotifEntries, 1, -1 do
        removeHitNotifEntry(i)
    end
    if hitNotifRoot then
        hitNotifRoot.Visible = false
    end
end
ragebot.hitNotifAnimStyles = HIT_NOTIF_ANIM_STYLES
ragebot.applyHitNotifRootPosition = applyHitNotifRootPosition
end


do

local runservice = game:GetService("RunService")
local players = game:GetService("Players")
local localplayer = players.LocalPlayer
local workspace = game:GetService("Workspace")

local settings = {
    enabled = false,
    yawtype = "none",
    pitchtype = "none",
    angletype = "none",
    bodyyaw = "none",
    pitchpreset = "none",
    customangle = 0,
    minspeed = 10,
    maxspeed = 20,
    minangle = 30,
    maxangle = 60,
    randomangle = false,
    spindirection = 1,
    fakelag = false,
    fakelagstuds = 4,
    desync = false,
    desyncstuds = 3,
    microjitter = false,
    microstrength = 25,
    velocitybreaker = false,
    camerarandomize = 0,
    camerarandomizeenabled = false,
    cameraspin = false,
    cameraspinspeed = 50,
}

local statemanager = {
    lastupdate = tick(),
    invertstate = false,
    smoothyaw = 0,
    smoothpitch = 0,
    smoothroll = 0,
    framecounter = 0
}

local utils = {
    getrandominrange = function(min, max)
        return min + math.random() * (max - min)
    end
}


local headBackwardsMotors = {}
local headBackwardsOrigC0 = {}
local camRemote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Replication") and ReplicatedStorage.Remotes.Replication:FindFirstChild("Fighter") and ReplicatedStorage.Remotes.Replication.Fighter:FindFirstChild("UpdateCameraRotation")
local encodeCameraRotation = function(vec2)
    if not Utility or not Utility.EncodeCameraRotation then return nil end
    return Utility:EncodeCameraRotation(vec2)
end

local function updateHeadBackwardsMotors()
    headBackwardsMotors = {}
    headBackwardsOrigC0 = {}
    local character = LocalPlayer.Character
    if not character then return end
    for _, v in pairs(character:GetDescendants()) do
        if v:IsA("Motor6D") then
            headBackwardsMotors[v.Name] = v
            headBackwardsOrigC0[v] = v.C0
        end
    end
end

local function applyHeadBackwards()
    if not LocalPlayer.Character or not headBackwardsMotors["Neck"] then return end
    local neckMotor = headBackwardsMotors["Neck"]
    if neckMotor and neckMotor.Parent then
        neckMotor.C0 = neckMotor.C0 * CFrame.Angles(math.pi * 0.85, math.pi, 0)
    end
    if camRemote then
        pcall(function()
            local encoded = encodeCameraRotation(Vector2.new(512, 0))
            if encoded then
                camRemote:FireServer(encoded, nil)
            end
        end)
    end
end

local function resetHeadBackwardsMotors()
    for motor, origC0 in pairs(headBackwardsOrigC0) do
        if motor and motor.Parent then
            motor.C0 = origC0
        end
    end
end

local function curweap2()
    local viewModels = workspace:FindFirstChild("ViewModels")
    if not viewModels then return nil end
    local firstPerson = viewModels:FindFirstChild("FirstPerson")
    if not firstPerson then return nil end
    for _, child in ipairs(firstPerson:GetChildren()) do
        local childName = child.Name
        local parts = {}
        for part in childName:gmatch("[^-]+") do
            table.insert(parts, part:match("^%s*(.-)%s*$"))
        end
        if #parts >= 2 then
            return parts[2]
        end
    end
    return nil
end

local fighter_controller = instanceSafeRequire(game:GetService("Players").LocalPlayer.PlayerScripts.Controllers.FighterController)
local local_fighter = fighter_controller.LocalFighter
local underground_enabled = false
local camera_controller = instanceSafeRequire(game:GetService("Players").LocalPlayer.PlayerScripts.Controllers.CameraController)

local underground_oldpos

local function getFloorBelowPosition(pos)
    local rayOrigin = pos
    local rayDirection = Vector3.new(0, -500, 0)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    if local_fighter and local_fighter.Entity and local_fighter.Entity.RootPart then
        raycastParams.FilterDescendantsInstances = {local_fighter.Entity.RootPart.Parent}
    end
    local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    if result then
        return CFrame.new(Vector3.new(pos.X, result.Position.Y - 2, pos.Z))
    end
    return nil
end

local old_underground_camera_controller = camera_controller.Update
camera_controller.Update = function(...)
    local arguments = {...}
    if underground_enabled and local_fighter and local_fighter.Entity and local_fighter.Entity.RootPart and underground_oldpos then
        local_fighter.Entity.RootPart.CFrame = underground_oldpos
    end
    return old_underground_camera_controller(table.unpack(arguments))
end

game:GetService("RunService").Heartbeat:Connect(function()
    if getgenv().InstanceConfigLoading then
        return
    end
    if not underground_enabled then
        underground_oldpos = nil
        return
    end
    
    local curweap = curweap2()
    if not curweap then
        underground_oldpos = nil
        return
    end
    
    if local_fighter and local_fighter.Entity and local_fighter.Entity.RootPart then
        underground_oldpos = local_fighter.Entity.RootPart.CFrame
        local currentPos = local_fighter.Entity.RootPart.Position
        local floorCFrame = getFloorBelowPosition(currentPos)
        if floorCFrame then
            local_fighter.Entity.RootPart.CFrame = floorCFrame
        end
    end
end)

local antiaim = {
    calculateyaw = function(deltatime)
        local yaw = 0
        local currenttime = tick()
        
        if settings.yawtype == "jitter" then
            local minangle = math.rad(settings.minangle)
            local maxangle = math.rad(settings.maxangle)
            
            if settings.randomangle then
                yaw = utils.getrandominrange(-maxangle, maxangle)
            else
                yaw = math.random() > 0.5 and minangle or -minangle
            end
            
        elseif settings.yawtype == "spinbot" then
            local speed = utils.getrandominrange(
                settings.minspeed / 10,
                settings.maxspeed / 10
            )
            yaw = (currenttime * speed) % (2 * math.pi)
            
        elseif settings.yawtype == "random" then
            if statemanager.framecounter % 30 == 0 then
                yaw = utils.getrandominrange(
                    -math.rad(settings.maxangle),
                    math.rad(settings.maxangle)
                )
            else
                yaw = statemanager.smoothyaw
            end
        end
        
        return yaw
    end,
    
    calculatepitch = function()
        local pitch = 0
        
        if settings.pitchtype == "jitter" then
            local minangle = math.rad(settings.minangle)
            local maxangle = math.rad(settings.maxangle)
            
            if settings.randomangle then
                pitch = utils.getrandominrange(-maxangle, maxangle)
            else
                pitch = math.random() > 0.5 and minangle or -minangle
            end
            
        elseif settings.pitchtype == "spinbot" then
            pitch = math.sin(tick() * (settings.maxspeed / 10)) * math.rad(settings.maxangle)
            
        elseif settings.pitchtype == "random" then
            if statemanager.framecounter % 20 == 0 then
                pitch = utils.getrandominrange(math.rad(-89), math.rad(89))
            else
                pitch = statemanager.smoothpitch
            end
        end
        
        return pitch
    end,
    
    calculateroll = function()
        local roll = 0
        
        if settings.angletype == "tilt 45" then
            roll = math.rad(45)
        elseif settings.angletype == "tilt 90" then
            roll = math.rad(90)
        elseif settings.angletype == "upside down" then
            roll = math.rad(180)
        elseif settings.angletype == "custom" then
            roll = math.rad(settings.customangle)
        end
        
        return roll
    end
}

local function updantiaim(deltatime)
    if not settings.enabled then return end
    if getgenv().InstanceConfigLoading then return end
    if getgenv().InstanceConfigLoading == nil then return end
    if settings.yawtype == "none" and settings.pitchtype == "none" and settings.angletype == "none" then
        return
    end
    
    local curweap = curweap2()
    if not curweap then return end
    
    local character = localplayer.Character
    if not character then return end
    
    local rootpart = character:FindFirstChild("HumanoidRootPart")
    if not rootpart then return end
    
    statemanager.framecounter = statemanager.framecounter + 1

    local calculatedyaw = antiaim.calculateyaw(deltatime)
    local calculatedpitch = antiaim.calculatepitch()
    local calculatedroll = antiaim.calculateroll()
    
    local rotationcframe = CFrame.Angles(calculatedpitch, calculatedyaw, calculatedroll)
    rootpart.CFrame = rootpart.CFrame * rotationcframe

    if settings.camerarandomizeenabled and settings.camerarandomize > 0 and camRemote then
        local strength = settings.camerarandomize / 100
        local iterations = math.max(1, math.floor(settings.camerarandomize))
        for _ = 1, iterations do
            local randX = utils.getrandominrange(-180 * strength, 180 * strength)
            local randY = utils.getrandominrange(-89 * strength, 89 * strength)
            pcall(function()
                local encoded = encodeCameraRotation(Vector2.new(randX, randY))
                if encoded then
                    camRemote:FireServer(encoded, nil)
                end
            end)
        end
    end
end

local function flushAntiAimMovementState()
    underground_oldpos = nil
    statemanager.framecounter = 0
    statemanager.smoothyaw = 0
    statemanager.smoothpitch = 0
    statemanager.smoothroll = 0
    resetHeadBackwardsMotors()

    local char = localplayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        pcall(function()
            hrp.AssemblyAngularVelocity = Vector3.zero
        end)
    end
end

getgenv().InstanceFlushMovementState = function()
    flushAntiAimMovementState()
    if getgenv().InstanceCleanupMovement then
        pcall(getgenv().InstanceCleanupMovement)
    else
        _G.keyheldcframe = false
        _G.keyheldcframefly = false
    end
end

getgenv().InstanceSyncAfterConfigLoad = function()
    if getgenv().InstanceFlushMovementState then
        pcall(getgenv().InstanceFlushMovementState)
    end

    _G.keyheldcframe = false
    _G.keyheldcframefly = false

    if Toggles and Toggles.AntiAimEnable then
        settings.enabled = Toggles.AntiAimEnable.Value == true
    else
        settings.enabled = false
    end

    if Toggles and Toggles.AntiAimUnderground then
        underground_enabled = Toggles.AntiAimUnderground.Value == true
        getgenv().InstanceUndergroundEnabled = underground_enabled
        if not underground_enabled then
            underground_oldpos = nil
        end
    else
        underground_enabled = false
        getgenv().InstanceUndergroundEnabled = false
        underground_oldpos = nil
    end

    if Options and Options.AntiAimYaw then
        settings.yawtype = Options.AntiAimYaw.Value or "none"
    end
    if Options and Options.AntiAimPitch then
        settings.pitchtype = Options.AntiAimPitch.Value or "none"
    end
    if Options and Options.AntiAimAngle then
        settings.angletype = Options.AntiAimAngle.Value or "none"
    end

    if Toggles and Toggles.cameraRandomizeToggle then
        settings.camerarandomizeenabled = Toggles.cameraRandomizeToggle.Value == true
    end
    if Options and Options.camerarandomize then
        settings.camerarandomize = Options.camerarandomize.Value or 0
    end
    if Toggles and Toggles.cameraSpinToggle then
        settings.cameraspin = Toggles.cameraSpinToggle.Value == true
    end
    if Options and Options.cameraSpinSpeed then
        settings.cameraspinspeed = Options.cameraSpinSpeed.Value or 50
    end

    if not settings.enabled or (settings.yawtype == "none" and settings.pitchtype == "none" and settings.angletype == "none") then
        flushAntiAimMovementState()
        underground_oldpos = nil
    end
end

localplayer.CharacterAdded:Connect(function()
    task.defer(flushAntiAimMovementState)
end)

local antiaimbox = Tabs.Combat:AddLeftGroupbox('anti aim')

antiaimbox:AddToggle("AntiAimEnable", {
    Text = "enable",
    Default = false,
    Callback = function(value)
        settings.enabled = value
        if getgenv().InstanceConfigLoading then return end
        if not value then
            flushAntiAimMovementState()
        end
    end
})

antiaimbox:AddDropdown("AntiAimYaw", {
    Values = {"none", "jitter", "spinbot", "random"},
    Default = "none",
    Text = "yaw",
    Callback = function(value)
        settings.yawtype = value
    end
})

antiaimbox:AddDropdown("AntiAimPitch", {
    Values = {"none", "jitter", "spinbot", "random"},
    Default = "none",
    Text = "pitch",
    Callback = function(value)
        settings.pitchtype = value
    end
})

antiaimbox:AddDropdown("AntiAimAngle", {
    Values = {"none", "tilt 45", "tilt 90", "upside down", "custom"},
    Default = "none",
    Text = "angle",
    Callback = function(value)
        settings.angletype = value
    end
})

antiaimbox:AddSlider("AntiAimCustomAngle", {
    Text = "custom angle",
    Default = 0,
    Min = 0,
    Max = 360,
    Rounding = 1,
    Suffix = '°',
    Callback = function(value)
        settings.customangle = value
    end
})

antiaimbox:AddSlider('speedslider', {
    Text = 'min speed',
    Default = 10,
    Min = 1,
    Max = 50,
    Rounding = 1,
    Suffix = '',
    Callback = function(value)
        settings.minspeed = value
    end
})
antiaimbox:AddSlider('angleslider', {
    Text = 'max speed',
    Default = 20,
    Min = 1,
    Max = 100,
    Rounding = 1,
    Suffix = '',
    Callback = function(value)
        settings.maxspeed = value
    end
})

antiaimbox:AddSlider('minangleslider', {
    Text = 'min angle',
    Default = 30,
    Min = 1,
    Max = 180,
    Rounding = 1,
    Suffix = '°',
    Callback = function(value)
        settings.minangle = value
    end
})
antiaimbox:AddSlider('maxangleslider', {
    Text = 'max angle',
    Default = 60,
    Min = 1,
    Max = 180,
    Rounding = 1,
    Suffix = '°',
    Callback = function(value)
        settings.maxangle = value
    end
})

antiaimbox:AddToggle("randomangle", {
    Text = "random angle",
    Default = false,
    Callback = function(value)
        settings.randomangle = value
    end
})

antiaimbox:AddSlider('camerarandomize', {
    Text = 'camera randomize',
    Default = 0,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Suffix = '%',
    Callback = function(value)
        settings.camerarandomize = value
    end
})

antiaimbox:AddToggle("cameraRandomizeToggle", {
    Text = "enable camera randomize",
    Default = false,
    Callback = function(value)
        settings.camerarandomizeenabled = value
    end
})

antiaimbox:AddToggle("cameraSpinToggle", {
    Text = "camera spin",
    Default = false,
    Callback = function(value)
        settings.cameraspin = value
    end
})

antiaimbox:AddSlider('cameraSpinSpeed', {
    Text = 'spin speed',
    Default = 50,
    Min = 1,
    Max = 500,
    Rounding = 0,
    Suffix = '',
    Callback = function(value)
        settings.cameraspinspeed = value
    end
})

antiaimbox:AddToggle("AntiAimUnderground", {
    Text = "underground",
    Default = false,
    Callback = function(value)
        underground_enabled = value
            getgenv().InstanceUndergroundEnabled = value
            if getgenv().InstanceConfigLoading then return end
            if not value then
            underground_oldpos = nil
        end
    end
})

getgenv().InstanceSetUnderground = function(val)
    underground_enabled = val
    getgenv().InstanceUndergroundEnabled = val
    if not val then
        underground_oldpos = nil
    end
end

runservice.Heartbeat:Connect(updantiaim)

local cameraSpinAngle = 0
runservice.RenderStepped:Connect(function(dt)
    if settings.cameraspin and camRemote then
        local speed = tonumber(settings.cameraspinspeed) or 50
        cameraSpinAngle = (cameraSpinAngle + speed * dt * 60) % 360
        local spinVal = cameraSpinAngle <= 180 and cameraSpinAngle or cameraSpinAngle - 360
        pcall(function()
            local encoded = encodeCameraRotation(Vector2.new(0, spinVal))
            if encoded then
                camRemote:FireServer(encoded, nil)
            end
        end)
    elseif settings.camerarandomizeenabled and settings.camerarandomize > 0 and camRemote then
        local strength = settings.camerarandomize / 100
        local iterations = math.max(1, math.floor(settings.camerarandomize))
        for _ = 1, iterations do
            local randX = utils.getrandominrange(-180 * strength, 180 * strength)
            local randY = utils.getrandominrange(-89 * strength, 89 * strength)
            pcall(function()
                local encoded = encodeCameraRotation(Vector2.new(randX, randY))
                if encoded then
                    camRemote:FireServer(encoded, nil)
                end
            end)
        end
    end
end)

task.spawn(function()
    while true do
        if config and config.backstab and config.backstab.camera then
            local cw = curweap2()
            if cw == "Knife" then
                local myChar = LocalPlayer.Character
                local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                if myRoot then
                    local closestChar, closestDist = nil, math.huge
                    for _, player in ipairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer then
                            local char = player.Character
                            if char then
                                local hum = char:FindFirstChildOfClass("Humanoid")
                                local root = char:FindFirstChild("HumanoidRootPart")
                                if hum and hum.Health > 0 and root then
                                    local dist = (root.Position - myRoot.Position).Magnitude
                                    if dist < closestDist then
                                        closestDist = dist
                                        closestChar = char
                                    end
                                end
                            end
                        end
                    end
                    if closestChar then
                        local targetRoot = closestChar:FindFirstChild("HumanoidRootPart")
                        if targetRoot then
                            local behindPos = targetRoot.Position - targetRoot.CFrame.LookVector * 3
                            myRoot.CFrame = CFrame.new(myRoot.Position, Vector3.new(behindPos.X, myRoot.Position.Y, behindPos.Z))
                            if camRemote then
                                pcall(function()
                                    local lookVec = (behindPos - myRoot.Position).Unit
                                    local yaw = math.deg(math.atan2(-lookVec.X, -lookVec.Z))
                                    local encoded = encodeCameraRotation(Vector2.new(yaw, 0))
                                    if encoded then
                                        camRemote:FireServer(encoded, nil)
                                    end
                                end)
                            end
                        end
                    end
                end
            end
            task.wait()
        else
            task.wait(0.1)
        end
    end
end)

-- ============================================================
-- KNIFE RAGEBOT — Anti-Knife Translocation (Combat Tab)
-- ============================================================

do
    local KnifeRagebot = {
        enabled         = false,
        range           = 8,
        cooldown        = 0.25,
        lastTrigger     = 0,
        behindDistance  = 5,
        verticalOffset  = 2,
        facingThreshold = 0.65,
        connection      = nil,
    }

    local MELEE_WEAPONS = {
        ["Knife"] = true, ["Katana"] = true, ["Battle Axe"] = true,
        ["Chainsaw"] = true, ["Daggers"] = true, ["Scythe"] = true,
        ["Maul"] = true, ["Trowel"] = true, ["Fists"] = true,
        ["Gunblade"] = true, ["Spear"] = true,
    }

    local function kr_getEquippedWeapon(player)
        if not player or not player.Character then return nil end
        local viewModels = Workspace:FindFirstChild("ViewModels")
        if not viewModels then return nil end
        local fp = viewModels:FindFirstChild("FirstPerson")
        if not fp then return nil end
        local pName = player.Name
        for _, child in ipairs(fp:GetChildren()) do
            local parts = {}
            for part in child.Name:gmatch("[^-]+") do
                parts[#parts + 1] = part:match("^%s*(.-)%s*$")
            end
            if #parts >= 2 and parts[1] == pName then
                return parts[2]
            end
        end
        return nil
    end

    local function kr_isMeleeThreat(player)
        local weapon = kr_getEquippedWeapon(player)
        if not weapon then return false end
        return MELEE_WEAPONS[weapon] == true
    end

    local function kr_getThreat()
        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then return nil end
        local myPos      = myRoot.Position
        local bestThreat = nil
        local bestDist   = math.huge
        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            local char = player.Character
            if not char then continue end
            local hum  = char:FindFirstChildOfClass("Humanoid")
            local root = char:FindFirstChild("HumanoidRootPart")
            if not hum or hum.Health <= 0 or not root then continue end
            if char:FindFirstChildOfClass("ForceField") then continue end
            local dist = (root.Position - myPos).Magnitude
            if dist > KnifeRagebot.range or dist >= bestDist then continue end
            if not kr_isMeleeThreat(player) then continue end
            local lookVec = root.CFrame.LookVector
            local toMe    = (myPos - root.Position).Unit
            local dot     = lookVec:Dot(toMe)
            if dot > KnifeRagebot.facingThreshold then
                bestThreat = { player = player, root = root, dist = dist, lookVec = lookVec }
                bestDist   = dist
            end
        end
        return bestThreat
    end

    local function kr_translocateBehind(threat)
        if not threat or not threat.root then return false end
        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then return false end
        local enemyRoot = threat.root
        local behindPos = enemyRoot.Position - (threat.lookVec * KnifeRagebot.behindDistance)
        behindPos       = behindPos + Vector3.new(0, KnifeRagebot.verticalOffset, 0)
        pcall(function()
            myRoot.CFrame                  = CFrame.new(behindPos, enemyRoot.Position)
            myRoot.AssemblyLinearVelocity  = Vector3.zero
            myRoot.AssemblyAngularVelocity = Vector3.zero
        end)
        return true
    end

    local function kr_tick()
        if not KnifeRagebot.enabled then return end
        local now = tick()
        if now - KnifeRagebot.lastTrigger < KnifeRagebot.cooldown then return end
        local threat = kr_getThreat()
        if threat and kr_translocateBehind(threat) then
            KnifeRagebot.lastTrigger = now
        end
    end

    local function kr_start()
        if KnifeRagebot.connection then return end
        KnifeRagebot.connection = RunService.Heartbeat:Connect(kr_tick)
    end

    local function kr_stop()
        if KnifeRagebot.connection then
            KnifeRagebot.connection:Disconnect()
            KnifeRagebot.connection = nil
        end
    end

    getgenv().KnifeRagebot      = KnifeRagebot
    getgenv().StartKnifeRagebot = kr_start
    getgenv().StopKnifeRagebot  = kr_stop

    local knifeBox = Tabs.Combat:AddLeftGroupbox('knife ragebot')

    knifeBox:AddToggle('KnifeRagebotEnabled', {
        Text = 'enable', Default = false,
        Callback = function(val)
            KnifeRagebot.enabled = val
            if val then kr_start() else kr_stop() end
        end
    })
    knifeBox:AddSlider('KnifeRagebotRange', {
        Text = 'trigger range', Default = 8, Min = 4, Max = 15,
        Rounding = 1, Suffix = ' studs', Compact = true,
        Callback = function(val) KnifeRagebot.range = val end
    })
    knifeBox:AddSlider('KnifeRagebotCooldown', {
        Text = 'cooldown', Default = 0.25, Min = 0.05, Max = 1.0,
        Rounding = 2, Suffix = 's', Compact = true,
        Callback = function(val) KnifeRagebot.cooldown = val end
    })
    knifeBox:AddSlider('KnifeRagebotBehindDist', {
        Text = 'behind distance', Default = 5, Min = 2, Max = 10,
        Rounding = 1, Suffix = ' studs', Compact = true,
        Callback = function(val) KnifeRagebot.behindDistance = val end
    })
    knifeBox:AddSlider('KnifeRagebotFacing', {
        Text = 'facing threshold', Default = 65, Min = 30, Max = 95,
        Rounding = 0, Suffix = '%', Compact = true,
        Callback = function(val) KnifeRagebot.facingThreshold = val / 100 end
    })
end


    CompatWindow:Category("Visuals")
    local FOVPage = CompatWindow:Page({Name="FOV", Icon="138827881557940"})

    CompatWindow:Category("Game")
    local CamPage = CompatWindow:Page({Name="Camera", Icon="138827881557940"})
    local MiscPage = CompatWindow:Page({Name="Misc", Icon="138827881557940"})
    local SkyPage = CompatWindow:Page({Name="Skybox", Icon="138827881557940"})

    local FOVMain = FOVPage:Section({Name="Aimbot FOV", Side=1})
    local FOVSil = FOVPage:Section({Name="Silent FOV", Side=2})
    local CamMain = CamPage:Section({Name="Camera", Side=1})
    local CamAdv = CamPage:Section({Name="Sensitivity & VM", Side=2})
    local MLoad = MiscPage:Section({Name="Loadout", Side=1})
    local MQueue = MiscPage:Section({Name="Queue & Vote", Side=2})
    local SkyMain = SkyPage:Section({Name="Skybox", Side=1})

        hsCfg.soundId=HIT_SOUNDS[sel] or hsCfg.soundId
        if hsCfg.enabled then applyHS(hsCfg.soundId,hsCfg.volume,hsCfg.pitch) end
    end})
    HSMain:Slider({Name="Volume",Flag="HSVol",Min=1,Max=100,Default=100,Suffix="%",Callback=function(v) hsCfg.volume=v/100;if hsCfg.enabled then applyHS(hsCfg.soundId,hsCfg.volume,hsCfg.pitch) end end})
    HSMain:Slider({Name="Pitch",Flag="HSPitch",Min=1,Max=30,Default=10,Suffix="x0.1",Callback=function(v) hsCfg.pitch=v*0.1;if hsCfg.enabled then applyHS(hsCfg.soundId,hsCfg.volume,hsCfg.pitch) end end})

    local fovChangerConn=nil
    CamMain:Toggle({Name="FOV Changer",Flag="FovChanger",Default=false,Callback=function(v)
        if v then fovChangerConn=RunService.RenderStepped:Connect(function()
            pcall(function() if CameraController then CameraController._base_fov=getFlag("FovVal",80) end end)
        end)
        else if fovChangerConn then fovChangerConn:Disconnect();fovChangerConn=nil end
            pcall(function() if CameraController then CameraController._base_fov=80;ws.CurrentCamera.FieldOfView=80 end end)
        end
    end})
    CamMain:Slider({Name="FOV",Flag="FovVal",Min=30,Max=120,Default=80,Callback=function(v)
        if getFlag("FovChanger",false) then pcall(function() if CameraController then CameraController._base_fov=v end end) end
    end})

    local noShakeConn=nil
    CamMain:Toggle({Name="No Camera Shake",Flag="NoShake",Default=false,Callback=function(v)
        if v then noShakeConn=RunService.RenderStepped:Connect(function()
            pcall(function() if CameraController then CameraController._shake_enabled=false;CameraController.ShakeCFrame=CFrame.identity end end)
        end)
        else if noShakeConn then noShakeConn:Disconnect();noShakeConn=nil end
            pcall(function() if CameraController then CameraController._shake_enabled=true end end)
        end
    end})

    local noSwayConn=nil
    CamMain:Toggle({Name="No Weapon Sway",Flag="NoSway",Default=false,Callback=function(v)
        if v then noSwayConn=RunService.RenderStepped:Connect(function()
            pcall(function() if CameraController then CameraController._sway_spring.Value=Vector2.zero;CameraController._sway_spring.Target=Vector2.zero end end)
        end)
        else if noSwayConn then noSwayConn:Disconnect();noSwayConn=nil end end
    end})

    local noBobConn=nil
    CamMain:Toggle({Name="No Bobbing",Flag="NoBob",Default=false,Callback=function(v)
        if v then noBobConn=RunService.RenderStepped:Connect(function()
            pcall(function()
                if CameraController then
                    CameraController._bobbing_speed_spring.Target=0;CameraController._bobbing_speed_spring.Value=0
                    CameraController._bobbing_value_spring.Target=0;CameraController._bobbing_value_spring.Value=0
                end
            end)
        end)
        else if noBobConn then noBobConn:Disconnect();noBobConn=nil end end
    end})

    local noJumpConn=nil
    CamMain:Toggle({Name="No Jump Effect",Flag="NoJump",Default=false,Callback=function(v)
        if v then noJumpConn=RunService.RenderStepped:Connect(function()
            pcall(function() if CameraController then CameraController._jump_spring.Target=0;CameraController._jump_spring.Value=0 end end)
        end)
        else if noJumpConn then noJumpConn:Disconnect();noJumpConn=nil end end
    end})

    local noSlideConn=nil
    CamMain:Toggle({Name="No Slide Tilt",Flag="NoSlide",Default=false,Callback=function(v)
        if v then noSlideConn=RunService.RenderStepped:Connect(function()
            pcall(function() if CameraController then CameraController._sliding_spring.Target=0;CameraController._sliding_spring.Value=0 end end)
        end)
        else if noSlideConn then noSlideConn:Disconnect();noSlideConn=nil end end
    end})

    local crossConn=nil
    CamMain:Toggle({Name="Force Crosshair",Flag="ForceCross",Default=false,Callback=function(v)
        if v then crossConn=RunService.RenderStepped:Connect(function()
            pcall(function() if CameraController then CameraController._crosshair_disabled=false end end)
        end)
        else if crossConn then crossConn:Disconnect();crossConn=nil end
            pcall(function() if CameraController then CameraController:_UpdateSettings() end end)
        end
    end})

    local sensConn=nil
    CamAdv:Toggle({Name="Override Sensitivity",Flag="SensOn",Default=false,Callback=function(v)
        if v then sensConn=RunService.RenderStepped:Connect(function()
            pcall(function()
                if not CameraController then return end
                CameraController._camera_sensitivity=getFlag("SensVal",100)/100
                CameraController._camera_sensitivity_ads_multiplier=getFlag("SensADS",100)/100
                CameraController._camera_sensitivity_ads_multiplier_scoped=getFlag("SensScoped",100)/100
                CameraController._camera_sensitivity_x=getFlag("SensX",100)/100
                CameraController._camera_sensitivity_y=getFlag("SensY",100)/100
            end)
        end)
        else if sensConn then sensConn:Disconnect();sensConn=nil end
            pcall(function() if CameraController then CameraController:_UpdateSettings() end end)
        end
    end})
    CamAdv:Slider({Name="Sensitivity",Flag="SensVal",Min=1,Max=500,Default=100,Suffix="%",Callback=function(_) end})
    CamAdv:Slider({Name="ADS",Flag="SensADS",Min=1,Max=500,Default=100,Suffix="%",Callback=function(_) end})
    CamAdv:Slider({Name="Scoped",Flag="SensScoped",Min=1,Max=500,Default=100,Suffix="%",Callback=function(_) end})
    CamAdv:Slider({Name="X Axis",Flag="SensX",Min=1,Max=500,Default=100,Suffix="%",Callback=function(_) end})
    CamAdv:Slider({Name="Y Axis",Flag="SensY",Min=1,Max=500,Default=100,Suffix="%",Callback=function(_) end})

    local vmConn=nil;local vmCfg={x=0,y=0,z=0}
    CamAdv:Toggle({Name="Custom Viewmodel",Flag="VMOn",Default=false,Callback=function(v)
        if v then vmConn=RunService.RenderStepped:Connect(function()
            pcall(function() if CameraController then CameraController.ViewModelOffsetCFrame=CFrame.new(vmCfg.x,vmCfg.y,vmCfg.z) end end)
        end)
        else if vmConn then vmConn:Disconnect();vmConn=nil end
            pcall(function() if CameraController then CameraController.ViewModelOffsetCFrame=CFrame.identity end end)
        end
    end})
    CamAdv:Slider({Name="X Offset",Flag="VMX",Min=-50,Max=50,Default=0,Suffix="x0.1",Callback=function(v) vmCfg.x=v*0.1 end})
    CamAdv:Slider({Name="Y Offset",Flag="VMY",Min=-50,Max=50,Default=0,Suffix="x0.1",Callback=function(v) vmCfg.y=v*0.1 end})
    CamAdv:Slider({Name="Z Offset",Flag="VMZ",Min=-50,Max=50,Default=0,Suffix="x0.1",Callback=function(v) vmCfg.z=v*0.1 end})

    local lCfg={primary=PRIMARY_WEAPONS[1],secondary=SECONDARY_WEAPONS[1],melee=MELEE_WEAPONS[1],utility=UTILITY_WEAPONS[1]}

    MLoad:Dropdown({Name="Primary",Flag="LPrimary",Default={PRIMARY_WEAPONS[1]},Items=PRIMARY_WEAPONS,Multi=false,Callback=function(v) lCfg.primary=type(v)=="table" and v[1] or v end})
    MLoad:Dropdown({Name="Secondary",Flag="LSecondary",Default={SECONDARY_WEAPONS[1]},Items=SECONDARY_WEAPONS,Multi=false,Callback=function(v) lCfg.secondary=type(v)=="table" and v[1] or v end})
    MLoad:Dropdown({Name="Melee",Flag="LMelee",Default={MELEE_WEAPONS[1]},Items=MELEE_WEAPONS,Multi=false,Callback=function(v) lCfg.melee=type(v)=="table" and v[1] or v end})
    MLoad:Dropdown({Name="Utility",Flag="LUtility",Default={UTILITY_WEAPONS[1]},Items=UTILITY_WEAPONS,Multi=false,Callback=function(v) lCfg.utility=type(v)=="table" and v[1] or v end})
    MLoad:Button({Name="Apply Loadout",Callback=function()
        pcall(function() PickWeaponsRemote:FireServer({lCfg.primary,lCfg.secondary,lCfg.melee,lCfg.utility});notify("Loadout","Applied!") end)
    end})
    MLoad:Toggle({Name="Auto Apply On Spawn",Flag="AutoLoadout",Default=false,Callback=function(_) end})

    lp.CharacterAdded:Connect(function()
        if getFlag("AutoLoadout",false) then
            task.wait(1)
            pcall(function() PickWeaponsRemote:FireServer({lCfg.primary,lCfg.secondary,lCfg.melee,lCfg.utility}) end)
        end
    end)

    MQueue:Dropdown({Name="Queue Mode",Flag="QMode",Default={"1v1"},Items=QUEUE_MODES,Multi=false,Callback=function(_) end})
    MQueue:Button({Name="Join Queue",Callback=function()
        pcall(function()
            local m=getFlag("QMode","1v1")
            QueueRemote:InvokeServer(m);notify("Queue","Joined "..m.."!")
        end)
    end})
    MQueue:Dropdown({Name="Vote Map",Flag="VMap",Default={MAPS[1]},Items=MAPS,Multi=false,Callback=function(_) end})
    MQueue:Button({Name="Vote Map",Callback=function()
        pcall(function()
            local m=getFlag("VMap",MAPS[1])
            VoteRemote:FireServer(m);notify("Vote","Voted "..m.."!")
        end)
    end})

    local autoVoteOn=false
    MQueue:Toggle({Name="Auto Vote",Flag="AutoVote",Default=false,Callback=function(v)
        autoVoteOn=false;task.wait(0.05)
        if v then
            autoVoteOn=true
            task.spawn(function()
                while autoVoteOn do
                    pcall(function() VoteRemote:FireServer(getFlag("VMap",MAPS[1])) end)
                    task.wait(2)
                end
            end)
        end
    end})

    local origSky=nil;local skyOn=false
    local function getSky() return ws.Terrain:FindFirstChildOfClass("Sky") end
    local function getAtmo() return ws.Terrain:FindFirstChildOfClass("Atmosphere") end
    local function saveSky()
        if origSky then return end;local sky=getSky();if not sky then return end
        origSky={SkyboxBk=sky.SkyboxBk,SkyboxDn=sky.SkyboxDn,SkyboxFt=sky.SkyboxFt,SkyboxLf=sky.SkyboxLf,SkyboxRt=sky.SkyboxRt,SkyboxUp=sky.SkyboxUp}
    end
    local function applySky(name)
        local data=SKYBOXES[name];if not data then return end;saveSky()
        local sky=getSky();if not sky then sky=Instance.new("Sky");sky.Parent=ws.Terrain end
        sky.SkyboxBk=data.SkyboxBk;sky.SkyboxDn=data.SkyboxDn;sky.SkyboxFt=data.SkyboxFt
        sky.SkyboxLf=data.SkyboxLf;sky.SkyboxRt=data.SkyboxRt;sky.SkyboxUp=data.SkyboxUp
        local atmo=getAtmo()
        if data.isNight then Lighting.ClockTime=0;Lighting.Ambient=Color3.fromRGB(30,30,60);if atmo then atmo.Density=0.8;atmo.Color=Color3.fromRGB(0,0,30) end
        elseif data.isSpace then Lighting.ClockTime=0;Lighting.Ambient=Color3.fromRGB(10,10,20);Lighting.Brightness=0;if atmo then atmo.Density=0 end
        else Lighting.ClockTime=14;Lighting.Ambient=Color3.fromRGB(70,70,70);Lighting.Brightness=2;if atmo then atmo.Density=0.395;atmo.Color=Color3.fromRGB(199,170,0) end end
    end
    local function restoreSky()
        if not origSky then return end;local sky=getSky();if not sky then return end
        sky.SkyboxBk=origSky.SkyboxBk;sky.SkyboxDn=origSky.SkyboxDn;sky.SkyboxFt=origSky.SkyboxFt
        sky.SkyboxLf=origSky.SkyboxLf;sky.SkyboxRt=origSky.SkyboxRt;sky.SkyboxUp=origSky.SkyboxUp;origSky=nil
    end

    SkyMain:Toggle({Name="Enable Skybox",Flag="SkyOn",Default=false,Callback=function(v)
        skyOn=v
        if v then applySky(getFlag("SkySel","Default"));notify("Skybox","Applied!")
        else restoreSky();notify("Skybox","Restored!") end
    end})
    SkyMain:Dropdown({Name="Skybox",Flag="SkySel",Default={"Default"},Items=SKYBOX_LIST,Multi=false,Callback=function(v)
        if skyOn then applySky(type(v)=="table" and v[1] or v) end
    end})
    SkyMain:Button({Name="Apply Now",Callback=function()
        if not skyOn then notify("Skybox","Enable first!",2);return end
        applySky(getFlag("SkySel","Default"));notify("Skybox","Applied!")
    end})
    SkyMain:Button({Name="Restore",Callback=function() restoreSky();notify("Skybox","Restored!") end})

    local _fps=0;local _ping=0
    local _frameCount=0;local _frameTimer=tick()

    RunService.Heartbeat:Connect(function()
        _frameCount+=1
        if tick()-_frameTimer>=1 then
            _fps=_frameCount;_frameTimer=tick();_frameCount=0
        end
    end)

    task.spawn(function()
        while true do
            task.wait(0.5)
            pcall(function()
                _ping=math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
            end)
            Library:Watermark({
                "Rivals Hub","v2.2",
                120959262762131,
                "FPS: ".._fps.." | Ping: ".._ping.."ms"
            })
        end
    end)

    RunService.RenderStepped:Connect(function(dt)
        cam=ws.CurrentCamera

        if AB.on and CameraController then
            if abDoReact then
                abReactT=abReactT-dt
                if abReactT<=0 then abDoReact=false end
            end
            if not abDoReact then
                if abTgt and not abTgtValid(abTgt) then
                    abTgt=nil;abLockT=0;abPrevPos=nil;abCurveStart=nil;abCurveProgress=0
                end
                if not abTgt then
                    abTgt=abFind()
                    if abTgt then
                        abLockT=0;abDoReact=true;abReactT=AB.reactTime/1000
                        abPrevPos=nil;abCurveStart=nil;abCurveProgress=0
                    end
                end
                if abTgt then
                    abLockT+=dt
                    if abLockT>AB.maxLock then
                        abTgt=nil;abLockT=0;abPrevPos=nil;abCurveStart=nil;abCurveProgress=0
                    elseif inFov(abTgt,abEffFov()) then
                        pcall(function()
                            local aimPos=getPredictedPos(abTgt)
                            local du=(aimPos-cam.CFrame.Position).Unit
                            local tRot=Vector2.new(math.asin(math.clamp(du.Y,-1,1)),math.atan2(-du.X,-du.Z))
                            local cur=CameraController.Rotation
                            local sp,_=cam:WorldToViewportPoint(aimPos)
                            local sd=(Vector2.new(sp.X,sp.Y)-scr()).Magnitude
                            local newRot=applySmartLock(tRot,cur,dt,sd,abEffFov())
                            CameraController:ApplyRotationDelta(Vector2.new(newRot.X-cur.X,angDiff(cur.Y,newRot.Y)))
                        end)
                    else
                        abTgt=nil;abLockT=0;abPrevPos=nil;abCurveStart=nil;abCurveProgress=0
                    end
                end
            end
        end

        if not fovCfg.visible then
            fovCircle.Visible=false;fovHalf.Visible=false;abCirc.Visible=false
        else
            local center=fovCfg.useCenter and scr() or getMouse()
            fovCircle.Visible=true;fovCircle.Color=fovCfg.color;fovCircle.Position=center
            local myRoot=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
            local orig=myRoot and myRoot.Position or cam.CFrame.Position
            fovCircle.Radius=abTgt and (isVis(orig,abTgt) and fovCfg.onTarget or fovCfg.onBarrier) or fovCfg.fovSize
            if fovCfg.half then fovHalf.Visible=true;fovHalf.Color=fovCfg.color;fovHalf.Position=center;fovHalf.Radius=fovCircle.Radius*0.5
            else fovHalf.Visible=false end
            abCirc.Position=center;abCirc.Radius=abEffFov();abCirc.Visible=AB.on
        end

        if not silentCfg.enabled or not silentCfg.circleVisible then
            silentCircle.Visible=false
        else
            local center=silentCfg.useCenter and scr() or getMouse()
            silentCircle.Visible=true;silentCircle.Radius=silentCfg.fovSize
            silentCircle.Thickness=silentCfg.circleThick;silentCircle.Position=center
            local myRoot=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
            local orig=myRoot and myRoot.Position or cam.CFrame.Position
            silentCircle.Color=getSilentTarget(orig) and silentCfg.targetColor or silentCfg.circleColor
        end
    end)


-- Advanced hook support
if getrawmetatable and setreadonly and newcclosure then
    local mt = getrawmetatable(game)
    local old_index = mt.__index
    local old_namecall = mt.__namecall

    setreadonly(mt, false)

    mt.__index = newcclosure(function(t, k)
        if not checkcaller() then
            if t == game:GetService("Players").LocalPlayer and k == "Level" then
                return 1
            end
        end
        return old_index(t, k)
    end)

    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if not checkcaller() then
            if method == "FireServer" and self.Name == "UpdateCameraRotation" then
                -- Intentionally left unchanged; forwards the original call.
            end
        end
        return old_namecall(self, ...)
    end)

    setreadonly(mt, true)
end

local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu")
MenuGroup:AddToggle("KeybindMenuOpen", {Default = Library.KeybindFrame.Visible, Text = "Open Keybind Menu", Callback = function(v) Library.KeybindFrame.Visible = v end})
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {Default="RightShift", NoUI=true, Text="Menu keybind"})
MenuGroup:AddButton("Unload", function() Library:Unload() end)
Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"MenuKeybind"})
ThemeManager:SetFolder("RivalsHub")
SaveManager:SetFolder("RivalsHub/configs")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:AddThemeOptions(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

notify("Rivals Hub", "v2.2 Loaded!", 5)
