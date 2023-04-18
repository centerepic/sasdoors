--getgenv().statdeck = "M6teFrRIBSR98So-000234"
--game:HttpGet(string.format("https://statsdeck.hypernite.xyz/API/deckit?public_key=%s&exploit=%s&user=%s", getgenv().statdeck, (syn and not is_sirhurt_closure and not pebc_execute and not gethui and "syn") or (OXYGEN_LOADED and "oxy") or (KRNL_LOADED and "krnl") or (gethui and "sw") or (fluxus and fluxus.request and "flux") or (is_comet_function and "comet") or ("uns"), game.Players.LocalPlayer.Name))

-- < [1] Load in modules/libraries. >

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/vozoid/ui-libraries/main/drawing/void/source.lua"))()
local httprequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

local Options = {
    DebugMode = true
}

Debug = function(Text)
    if Options.DebugMode == true then
        warn(Text)
    end
end

local Version = "1.5"
local StartTick = tick()

-- < [2] Load services. >

local LocalPlayer = game:GetService("Players").LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")
local Autothickness = true
local MainGame = require(LocalPlayer.PlayerGui.MainUI.Initiator["Main_Game"])
local CurrentRooms = workspace.CurrentRooms
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EntityInfo = ReplicatedStorage:WaitForChild("EntityInfo")
local VirtualInputManager = game:GetService("VirtualInputManager")
local MotorReplication = EntityInfo.MotorReplication
local Heartbeating = false
local Camera = workspace.CurrentCamera
local Watermark
local AnticheatBypassed = false

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local InfoFrame = Drawing.new("Square")

InfoFrame.Thickness = 0
InfoFrame.Size = Vector2.new(0.4, 0.05) * workspace.CurrentCamera.ViewportSize
InfoFrame.Position = Vector2.new(workspace.CurrentCamera.ViewportSize.X/2, InfoFrame.Size.Y/2) - (InfoFrame.Size/2)
InfoFrame.Filled = true
InfoFrame.Visible = false
InfoFrame.ZIndex = 1
InfoFrame.Transparency = 1
InfoFrame.Color = Color3.new(0.074509, 0.070588, 0.074509)


local Text = Drawing.new("Text")

Text.Text = ""
Text.Size = 40
Text.Center = true
Text.Color = Color3.new(0.788235, 0.788235, 0.788235)
Text.Position = (InfoFrame.Position + InfoFrame.Size/2) - Vector2.new(0, Text.TextBounds.Y/2)
Text.Visible = false
Text.Font = 3
Text.ZIndex = 2
Text.Transparency = 1

local ESPIcons = {
    ["CrucifixIcon.png"] = 'https://raw.githubusercontent.com/centerepic/DoorsGUIV2/main/CrucifixIconHQ.png',
    ["FlashlightIcon.png"] = 'https://github.com/centerepic/DoorsGUIV2/raw/main/FlashlightIconHQ.png',
    ["KeyIcon.png"] = 'https://github.com/centerepic/DoorsGUIV2/raw/main/KeyMarkerHQ.png',
    ["LighterIcon.png"] = 'https://github.com/centerepic/DoorsGUIV2/raw/main/LighterIconHQ.png',
    ["LockpickIcon.png"] = 'https://github.com/centerepic/DoorsGUIV2/raw/main/LockpickIconHQ.png'
}

local ESPLookupTable = {
    ["Flashlight"] = "FlashlightIcon.png",
    ["Lighter"] = "LighterIcon.png",
    ["Lockpick"] = "LockpickIcon.png",
    ["Crucifix"] = "CrucifixIcon.png"
}

local ESPObjects = {}

Debug("Downloading ESP images...")

local FolderName = "saswareDoorsAssets_new"

if not isfolder(FolderName) then
    makefolder(FolderName)
    for i,v in pairs(ESPIcons) do
        if httprequest then
            ESPIcons[i] = httprequest({Url = v:sub(1, -5) .. "_Alternate.png",Method = "GET"}).Body
        else
            ESPIcons[i] = game:HttpGet(v:sub(1, -5) .. "_Alternate.png")
        end
        writefile(FolderName .. "\\" .. i, ESPIcons[i])
    end
else
    for i,v in pairs(ESPIcons) do
        local File
        if isfile(FolderName .. "\\" .. i) then
            File = readfile(FolderName .. "\\" .. i)
        else
            delfolder(FolderName)
            error("Missing files, please restart.")
        end

        if File then
            ESPIcons[i] = File
        end
    end
end

local EntityNames = {
    ["RushMoving"] = {Hide = true, Message = "Hide! Rush has spawned."},
    ["AmbushMoving"] = {Hide = true, Message = "Hide! Ambush has spawned."},
    ["Snare"] = {Hide = false},
    ["A60"] = {Hide = true, Message = "Hide! A60 has spawned."},
    ["A120"] = {Hide = false, Message = "Hide! A120 has spawned."},
    ["Dread"] = {Hide = true, Message = "Hide! Dread has spawned."},
}

Debug("Finding modules & scripts...")

local RequiredLocalScripts = {
    ["Heartbeat"] = LocalPlayer.PlayerGui:WaitForChild("MainUI"):WaitForChild("Initiator"):WaitForChild("Main_Game"):WaitForChild("Heartbeat"),
    ["Movement"] = LocalPlayer.PlayerGui:WaitForChild("MainUI"):WaitForChild("Initiator"):WaitForChild("Main_Game"):WaitForChild("Movement")
}

Debug("Finding remotes...")

local RequiredRemotes = {
    ["ClutchHeartbeat"] = ReplicatedStorage:WaitForChild("EntityInfo"):WaitForChild("ClutchHeartbeat")
}

Debug("Remotes found!")

local ValidScripts = 0
for _,v in pairs(RequiredLocalScripts) do
    if v ~= nil then
        ValidScripts += 1
    end
end

Debug(tostring(ValidScripts) .. "/2 found.")

if ValidScripts < #RequiredLocalScripts then
    warn("WARNING! Not all functions required for script found. Please report this to a developer.")
end

Debug("Getting screech connections...")

local ScreechConnections = {}

for _,v in pairs(getconnections(EntityInfo.Screech.OnClientEvent)) do
    table.insert(ScreechConnections,v)
end

Debug("Found " .. tostring(#ScreechConnections .. " connections."))

-- < [3] Create functions. >

local function GetDistanceFromCharacter(Position)
    return (Camera.CFrame.Position - Position).Magnitude
end

local function SetPopup(Visible,Input)
    if Visible then
        InfoFrame.Visible = true
        Text.Visible = true
        Text.Text = Input
    elseif Visible == false then
        InfoFrame.Visible = false
        Text.Visible = false
    end
end

local IsFlooring = false

local function isVisible(model)
    local character = game.Players.LocalPlayer.Character
    if character == nil then
        return false
    end

    local head = character:FindFirstChild("Head")
    if head == nil then
        return false
    end

    local origin = head.CFrame.p
    local direction = (model.PrimaryPart.CFrame.p - origin).unit
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {character}
    local hitResult = game.Workspace:Raycast(origin, direction, raycastParams)

    if hitResult and hitResult.Instance:IsDescendantOf(model) then
        return true
    end

    return false
end

local function findClosestModel(models)
    local character = game.Players.LocalPlayer.Character
    if character == nil then
        return nil
    end

    local head = character:FindFirstChild("Head")
    if head == nil then
        return nil
    end

    local origin = head.CFrame.p
    local closestModel = nil
    local closestDistance = math.huge

    for _, model in pairs(models) do
        if model:IsA("Model") and model ~= character then
            local distance = (model.PrimaryPart.CFrame.p - origin).magnitude
            if distance < closestDistance then
                closestModel = model
                closestDistance = distance
            end
        end
    end

    return closestModel
end


local FloorSelfBind

local function FloorSelf(Bool)
    local Character = LocalPlayer.Character
    if Bool then
        IsFlooring = true
        if FloorSelfBind then
            FloorSelfBind:Disconnect()
            FloorSelfBind = nil
        end
        workspace.Gravity = 0
        local TargetCF = CFrame.new(Character.HumanoidRootPart.Position - Vector3.new(0,8.5,0))
        FloorSelfBind = RunService.Heartbeat:Connect(function()
            Character:PivotTo(TargetCF)
        end)
    else
        IsFlooring = false
        if FloorSelfBind then
            FloorSelfBind:Disconnect()
            FloorSelfBind = nil
        end
        workspace.Gravity = 90
        Character:PivotTo(CFrame.new(Character.HumanoidRootPart.Position + Vector3.new(0,8.5,0)))
    end
end

local function SetHeadlight(Character,Enabled)
    if not Character.Head:FindFirstChild("SpotLight") then
        local Headlight = Instance.new("SpotLight")
        Headlight.Brightness = 1
        Headlight.Face = Enum.NormalId.Front
        Headlight.Range = 90
        Headlight.Parent = game.Players.LocalPlayer.Character.Head
        Headlight.Enabled = Enabled
    else
        Character.Head.SpotLight.Enabled = Enabled
    end
end

local function EntityHandler(Child)
    wait()
    if EntityNames[Child.Name] and Child.PrimaryPart then
        local FalseFlag = Child.PrimaryPart.Position.Y < 1000
        if Library.flags.EntityNotifications and EntityNames[Child.Name].Message and not FalseFlag then
            Library:Notify(EntityNames[Child.Name].Message,5)
        end
        if Library.flags.AntiEntity and EntityNames[Child.Name].Hide and not FalseFlag then
            FloorSelf(true)
            Child.Destroying:Wait()
            FloorSelf(false)
        end
    end
    if Child.Name == "BananaPeel" and Library.flags.DisableBannanaFlag then
        task.spawn(function()
            local TouchInterest = Child:WaitForChild("TouchInterest")
            wait()
            TouchInterest:Destroy()
        end)
    end
    if Child.Name == "JeffTheKiller" and Library.flags.AntiJeff then
        wait(0.1)
        for i,v in pairs(Child:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = false
            end
            if v:IsA("TouchTransmitter") then
                v:Destroy()
            end
        end
    end
end

local function NewLine(Color)
    local line = Drawing.new("Line")
    line.Visible = false
    line.From = Vector2.new(0, 0)
    line.To = Vector2.new(1, 1)
    line.Color = Color
    line.Thickness = 2
    line.Transparency = 1
    return line
end

local function _3DBoxESP(object,Tag,Color)
    Debug("Adding 3D ESP Object.")

    local MainSelf = {}

    MainSelf.Enabled = Library.flags[Tag]
    MainSelf.Tag = Tag

    local part = object

    --// Lines for 3D box

    local lines = {
        line1 = NewLine(Color),
        line2 = NewLine(Color),
        line3 = NewLine(Color),
        line4 = NewLine(Color),
        line5 = NewLine(Color),
        line6 = NewLine(Color),
        line7 = NewLine(Color),
        line8 = NewLine(Color),
        line9 = NewLine(Color),
        line10 = NewLine(Color),
        line11 = NewLine(Color),
        line12 = NewLine(Color)
    }

    local SelfDestructCoro
    SelfDestructCoro = coroutine.create(function()
        while wait(1) do
            if not table.find(ESPObjects,MainSelf) then
                pcall(function()
                    for i,v in pairs(lines) do
                        v:Remove()
                    end
                end)
                coroutine.close(SelfDestructCoro)
            end
        end
    end)

    coroutine.resume(SelfDestructCoro)

    function MainSelf:Destroy()
        Debug("Removing 3D ESP Object.")
        table.remove(ESPObjects,table.find(ESPObjects,self))
        wait(0.1)
        for i,v in pairs(lines) do
            v:Remove()
        end
        self = nil
    end

    --// Updates ESP (lines) in render loop
    function MainSelf:Update()
        if self.Enabled then
            local partpos, onscreen = Camera:WorldToViewportPoint(part.Position)
            if onscreen then
                local size_X = part.Size.X/2
                local size_Y = part.Size.Y/2
                local size_Z = part.Size.Z/2
                
                local Top1 = Camera:WorldToViewportPoint((part.CFrame * CFrame.new(-size_X, size_Y, -size_Z)).p)
                local Top2 = Camera:WorldToViewportPoint((part.CFrame * CFrame.new(-size_X, size_Y, size_Z)).p)
                local Top3 = Camera:WorldToViewportPoint((part.CFrame * CFrame.new(size_X, size_Y, size_Z)).p)
                local Top4 = Camera:WorldToViewportPoint((part.CFrame * CFrame.new(size_X, size_Y, -size_Z)).p)

                local Bottom1 = Camera:WorldToViewportPoint((part.CFrame * CFrame.new(-size_X, -size_Y, -size_Z)).p)
                local Bottom2 = Camera:WorldToViewportPoint((part.CFrame * CFrame.new(-size_X, -size_Y, size_Z)).p)
                local Bottom3 = Camera:WorldToViewportPoint((part.CFrame * CFrame.new(size_X, -size_Y, size_Z)).p)
                local Bottom4 = Camera:WorldToViewportPoint((part.CFrame * CFrame.new(size_X, -size_Y, -size_Z)).p)

                --// Top:
                lines.line1.From = Vector2.new(Top1.X, Top1.Y)
                lines.line1.To = Vector2.new(Top2.X, Top2.Y)

                lines.line2.From = Vector2.new(Top2.X, Top2.Y)
                lines.line2.To = Vector2.new(Top3.X, Top3.Y)

                lines.line3.From = Vector2.new(Top3.X, Top3.Y)
                lines.line3.To = Vector2.new(Top4.X, Top4.Y)

                lines.line4.From = Vector2.new(Top4.X, Top4.Y)
                lines.line4.To = Vector2.new(Top1.X, Top1.Y)

                --//Bottom:
                lines.line5.From = Vector2.new(Bottom1.X, Bottom1.Y)
                lines.line5.To = Vector2.new(Bottom2.X, Bottom2.Y)

                lines.line6.From = Vector2.new(Bottom2.X, Bottom2.Y)
                lines.line6.To = Vector2.new(Bottom3.X, Bottom3.Y)

                lines.line7.From = Vector2.new(Bottom3.X, Bottom3.Y)
                lines.line7.To = Vector2.new(Bottom4.X, Bottom4.Y)

                lines.line8.From = Vector2.new(Bottom4.X, Bottom4.Y)
                lines.line8.To = Vector2.new(Bottom1.X, Bottom1.Y)

                --//Sides:
                lines.line9.From = Vector2.new(Bottom1.X, Bottom1.Y)
                lines.line9.To = Vector2.new(Top1.X, Top1.Y)

                lines.line10.From = Vector2.new(Bottom2.X, Bottom2.Y)
                lines.line10.To = Vector2.new(Top2.X, Top2.Y)

                lines.line11.From = Vector2.new(Bottom3.X, Bottom3.Y)
                lines.line11.To = Vector2.new(Top3.X, Top3.Y)

                lines.line12.From = Vector2.new(Bottom4.X, Bottom4.Y)
                lines.line12.To = Vector2.new(Top4.X, Top4.Y)

                if Autothickness then
                    local distance = (Camera.CFrame.Position - part.Position).magnitude
                    local value = math.clamp(1/distance*100, 0.1, 4) --0.1 is min thickness, 6 is max
                    for u, x in pairs(lines) do
                        x.Thickness = value
                    end
                else 
                    for u, x in pairs(lines) do
                        x.Thickness = 2
                    end
                end

                for u, x in pairs(lines) do
                    x.Visible = true
                end
            else 
                for u, x in pairs(lines) do
                    x.Visible = false
                end
                if part == nil or part.Parent == nil then
                    self:Destroy()
                end
            end
        else
            for u, x in pairs(lines) do
                x.Visible = false
            end
        end
    end
    table.insert(ESPObjects,MainSelf)
    return MainSelf
end

local function AddItemESP(BasePart,IconName,Tag)
    local DrawingObject = {}

    Debug("AddItemESP called for " .. IconName)

    if not BasePart then
        return
    end

    DrawingObject.Tag = Tag
    DrawingObject.Enabled = Library.flags[Tag]

    DrawingObject.Drawing = Drawing.new("Image")
    DrawingObject.Drawing.Data = readfile(FolderName .. "\\" .. IconName)
    DrawingObject.Drawing.Size = Vector2.new(50,50)

    function DrawingObject:Destroy()
        Debug("Removing drawing object for " .. "IconName")
        table.remove(ESPObjects,table.find(ESPObjects,self))
        delay(0.1,function()
            DrawingObject.Drawing:Remove()
        end)
    end

    function DrawingObject:Update()
        if self.Drawing ~= nil and self.Enabled then
            if BasePart == nil or BasePart.Parent == nil then
                self:Destroy()
            end
    
            local ViewportPoint,Visible = Camera:WorldToViewportPoint(BasePart.Position)
            local Depth = ViewportPoint.Z
            if Visible and Depth >= 0 then
                self.Drawing.Visible = true
                ViewportPoint = Vector2.new(ViewportPoint.X - DrawingObject.Drawing.Size.X / 2, ViewportPoint.Y - DrawingObject.Drawing.Size.Y / 2) 
                self.Drawing.Position = ViewportPoint
            else
                self.Drawing.Visible = false
            end
        end
    end

    local SelfDestructCoro
    SelfDestructCoro = coroutine.create(function()
        while wait(1) do
            if not table.find(ESPObjects,DrawingObject) then
                pcall(function()
                    DrawingObject.Drawing:Remove()
                end)
                coroutine.close(SelfDestructCoro)
            end
        end
    end)

    coroutine.resume(SelfDestructCoro)

    Debug("AdditemESP completed initializing fully.")

    table.insert(ESPObjects,DrawingObject)
end

local BoxPoints = {
    "PointA",
    "PointB",
    "PointC",
    "PointD"
}

local function NewBox(Part,Tag,Color)

    local MainSelf = {
        Box = Drawing.new("Quad"),
        Size = Part.Size,
        Tag = Tag
    }

    MainSelf.Box.Thickness = 1.5
    MainSelf.Box.Color = Color

    MainSelf.Enabled = Library.flags[Tag]

    function MainSelf:Destroy()
        self.Box:Remove()
        table.remove(ESPObjects,table.find(ESPObjects,self))
        return 1
    end

    local SelfDestructCoro
    SelfDestructCoro = coroutine.create(function()
        while wait(1) do
            if not table.find(ESPObjects,MainSelf) then
                pcall(function()
                    MainSelf.Box:Remove()
                end)
                coroutine.close(SelfDestructCoro)
            end
        end
    end)

    coroutine.resume(SelfDestructCoro)

    function MainSelf:Update()
        if Part.Parent == nil or Part == nil then
            self:Destroy()
            return 1
        end

        local PrimaryCFrame = Part.CFrame

        if self.Enabled then
            local BoxDepth = 0
            local BoxIsVisible = false

            local Corners = {
                PrimaryCFrame * CFrame.new(-self.Size.X/2,self.Size.Y/2,0),
                PrimaryCFrame * CFrame.new(self.Size.X/2,self.Size.Y/2,0),
                PrimaryCFrame * CFrame.new(self.Size.X/2,-self.Size.Y/2,0),
                PrimaryCFrame * CFrame.new(-self.Size.X/2,-self.Size.Y/2,0)
            }

            for i,v in ipairs(BoxPoints) do
                local Vector,Visible = Camera:WorldToViewportPoint(Corners[i].Position)
                if Vector.Z < BoxDepth then
                    BoxDepth = Vector.Z
                end
                BoxIsVisible = Visible
                Vector = Vector2.new(Vector.X,Vector.Y)
                self.Box[v] = Vector
            end

            if BoxIsVisible and BoxDepth >= 0 then
                self.Box.Visible = true
            else
                self.Box.Visible = false
            end
        end
    end

    table.insert(ESPObjects,MainSelf)

    return MainSelf
end

local function DecipherCode()
    local Paper = LocalPlayer.Character:FindFirstChild("LibraryHintPaper") or LocalPlayer.Backpack:FindFirstChild("LibraryHintPaper")
    local Hints = LocalPlayer.PlayerGui:FindFirstChild("PermUI",1):FindFirstChild("Hints",1)
    
    local code = {"#","#","#","#","#"}
    
    if Paper and Hints then
        for _, paper_ui in pairs(Paper.UI:GetChildren()) do
            if paper_ui:IsA("ImageLabel") and paper_ui.Name ~= "Image" then
                for _, hint in pairs(Hints:GetChildren()) do
                    if hint:IsA("ImageLabel") and paper_ui.ImageRectOffset == hint.ImageRectOffset and hint.Visible then
                        code[tonumber(paper_ui.Name)] = hint:FindFirstChild("TextLabel").Text
                    end
                end
            end
        end
    end
        
    return table.concat(code, "")
end

local function SetupRoom(Room)
    Debug("Setting up room " .. tostring(Room))

    if Room.Name == "51" and Library.flags.AutoLibraryCode then
        task.spawn(function()
            LocalPlayer.Character:WaitForChild("LibraryHintPaper")
            SetPopup(true,"Library Code - #####")
            local Code = "#####"
            repeat 
                Code = DecipherCode() 
                SetPopup(true,"Library Code - " .. Code) 
                wait(1)
            until not string.find(Code,"#") or not Library.flags.AutoLibraryCode
            wait(30)
            SetPopup(false,"")
        end)
    end

    task.defer(function()
        local Door = Room:WaitForChild("Door",3):WaitForChild("Door",1)

        if Door then
            local DoorDrawing = NewBox(Door, "Door", Color3.new(0,1,0))

            local DCon

            DCon = Door:GetPropertyChangedSignal("CanCollide"):Connect(function()
                if Door.CanCollide == false and DoorDrawing then
                    DoorDrawing:Destroy()
                    DoorDrawing = nil
                    DCon:Disconnect()
                end
            end)

            local DACon
            DACon = Door.AncestryChanged:Connect(function()
                if not Door:IsDescendantOf(Room) and DoorDrawing then
                    DoorDrawing:Destroy()
                    DoorDrawing = nil
                    DACon:Disconnect()
                end
            end)
        end
    end)

    task.defer(function()
        if Library.flags.NoSeek then
            local Trigger = Room:WaitForChild("TriggerEventCollision",2)
                
            if Trigger then
                Trigger:Destroy() 
            end
        end
    end)

    for _,Child in pairs(Room:WaitForChild("Assets",5):GetDescendants()) do

        if Library.flags.NoDarkRooms and Child:IsA("Light") then
            if Child.Enabled == false then
                Child.Enabled = true
                pcall(function()
                    Child.Parent.Parent.Material = Enum.Material.Neon
                end)
            end
        end

        if Child.Name == "KeyObtain" then
            wait(0.1)
            Debug("Found Key, adding to ESP.")
            AddItemESP(Child:WaitForChild("Hitbox"),"KeyIcon.png","Key")
        end

        if Child:IsA("Model") and (Child:GetAttribute("Pickup") or Child:GetAttribute("PropType")) then
            Debug("Found Item, adding to ESP.")
            local Handle = (Child:FindFirstChild("Handle") or Child:FindFirstChild("Prop"))
            if ESPLookupTable[Child.Name] then
                AddItemESP(Handle,ESPLookupTable[Child.Name],"Item")
            end
        end

        if Child:IsA("Model") and Child.Name == "LiveHintBook" then
            Debug("Found Book, adding to ESP.")
            local Drawing = _3DBoxESP(Child.PrimaryPart,"Book",Color3.new(0, 0.6, 1))
            Child.AncestryChanged:Connect(function()
                if not Child:IsDescendantOf(Room) then
                    Drawing:Destroy()
                    Drawing = nil
                end
            end)
        end

        if Child:IsA("Model") and Child.Name == "LeverForGate" then
            Debug("Found Lever, adding to ESP.")
            local Drawing = _3DBoxESP(Child.PrimaryPart,"Lever",Color3.new(1, 0.4, 0))
            Child.PrimaryPart:WaitForChild("SoundToPlay").Played:Once(function()
                if Drawing then
                    Drawing:Destroy()
                    Drawing = nil
                end
            end)
            Child.AncestryChanged:Connect(function()
                if not Child:IsDescendantOf(Room) and Drawing then
                    Drawing:Destroy()
                    Drawing = nil
                end
            end)
        end

        if Child.Name == "DoorNormal" then
            local DoorIgnoreLink = Instance.new("PathfindingModifier",Child:WaitForChild("Door",5))
            DoorIgnoreLink.PassThrough = true
        end

        if Child.Name == "Gate" then
            local ThingToOpen = Child:WaitForChild("ThingToOpen", 5)
            if ThingToOpen then
                ThingToOpen.CanCollide = false
                local DoorIgnoreLink = Instance.new("PathfindingModifier", ThingToOpen)
                DoorIgnoreLink.PassThrough = true
            end
        end
    end

    local CACON
    CACON = Room.Assets.DescendantAdded:Connect(function(Child)

        if Child.Name == "DoorNormal" then
            local DoorIgnoreLink = Instance.new("PathfindingModifier",Child:WaitForChild("Door",5))
            DoorIgnoreLink.PassThrough = true
        end

        if Child.Name == "Gate" then
            local ThingToOpen = Child:WaitForChild("ThingToOpen", 5)
            if ThingToOpen then
                ThingToOpen.CanCollide = false
                local DoorIgnoreLink = Instance.new("PathfindingModifier", ThingToOpen)
                DoorIgnoreLink.PassThrough = true
            end
        end

        if Library.flags.NoDarkRooms and Child:IsA("Light") then
            wait()
            if Child.Enabled == false then
                Child.Enabled = true
                pcall(function()
                    Child.Parent.Parent.Material = Enum.Material.Neon
                end)
            end
        end

        if Library.flags.NoSeekObstacles then
            wait()
            if Child.Name == "ChandelierObstruction" then
                Child:Remove()
            elseif Child.Name == "Seek_Arm" then
                Child:Remove()
            end
        end

        if Child.Name == "KeyObtain" then
            wait(0.1)
            Debug("Key Found. [DA]")
            AddItemESP(Child:WaitForChild("Hitbox"),"KeyIcon.png","Key")
        end

        if Child:IsA("Model") and (Child:GetAttribute("Pickup") or Child:GetAttribute("PropType")) then
            Debug("Found Item [" .. Child.Name .. "], adding to ESP. [DA]")
            wait()
            local Handle = (Child:WaitForChild("Handle",1) or Child:WaitForChild("Prop",1))
            if ESPLookupTable[Child.Name] and Handle then
                AddItemESP(Handle,ESPLookupTable[Child.Name],"Item")
            else
                Debug("Pickup found, but no valid handle found or cannot be found in the Lookup Table.")
            end
        end

        if Child:IsA("Model") and Child.Name == "LiveHintBook" then
            Debug("Found Book, adding to ESP. [DA]")
            wait()
            local Drawing = _3DBoxESP(Child.PrimaryPart,"Book",Color3.new(0, 0.6, 1))
            Child.AncestryChanged:Connect(function()
                if not Child:IsDescendantOf(Room) then
                    Drawing:Destroy()
                end
            end)
        end

        if Child:IsA("Model") and Child.Name == "LeverForGate" then
            Debug("Found Lever, adding to ESP. [DA]")
            wait()
            local Drawing = _3DBoxESP(Child.PrimaryPart,"Lever",Color3.new(1, 0.4, 0))
            local SCon
            local ACon
            SCon = Child.PrimaryPart:WaitForChild("SoundToPlay").Played:Connect(function()
                wait(math.random(1,10)/50)
                if Drawing then
                    Drawing:Destroy()
                    Drawing = nil
                    SCon:Disconnect()
                    ACon:Disconnect()
                end
            end)
            ACon = Child.AncestryChanged:Connect(function()
                wait(math.random(1,10)/50)
                if not Child:IsDescendantOf(Room) and Drawing then
                    Drawing:Destroy()
                    Drawing = nil
                    SCon:Disconnect()
                    ACon:Disconnect()
                end
            end)
        end
    end)

    Room.Destroying:Once(function()
        CACON:Disconnect()
    end)
end

local function Round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

local function OnHeartbeatMinigameStart()
    Debug("AutoHeartbeat started.")
    if Library.flags.AutoHeartbeat and not Heartbeating then

        Heartbeating = true
        local HeartbeatMinigameFrame = LocalPlayer.PlayerGui.MainUI.MainFrame.Heartbeat
        local MainHeart = HeartbeatMinigameFrame.Heart
        local ChildConnection

        ChildConnection = MainHeart.ChildAdded:Connect(function(Child)
            if Child.Name == 'LiveHalf' then
                local ImageEqual = Child.Image == 'rbxassetid://8428304451'
                local RandX = math.random(20,25)
                repeat RunService.RenderStepped:wait() until math.abs(Child.AbsolutePosition.X - MainHeart.AbsolutePosition.X) <= RandX
                local NewKeyCode = ImageEqual and Enum.KeyCode.Q or Enum.KeyCode.E
                if not Child:GetAttribute("KeyPressed") == true then
                    print(math.abs(Child.AbsolutePosition.X - MainHeart.AbsolutePosition.X))
                    Child:SetAttribute("KeyPressed",true)
                    VirtualInputManager:SendKeyEvent(true,NewKeyCode,false,game)
                    VirtualInputManager:SendKeyEvent(false,NewKeyCode,false,game)
                end
            end
        end)

        local VisibleConnection
        VisibleConnection = HeartbeatMinigameFrame.Changed:Connect(function()
            if HeartbeatMinigameFrame.Visible == false then
                Debug("AutoHeartbeatEnded")
                Heartbeating = false
                VisibleConnection:Disconnect()
                ChildConnection:Disconnect()
            end
        end)

    end
end

local function PlayGlobalSound(ID)
    local Sound = Instance.new("Sound",workspace)
    Sound.SoundId = ID
    Sound.Volume = 1
    Sound:Play()
    Sound.Ended:Once(function()
        wait()
        Sound:Destroy()
    end)
end

local VisualPointsFolder = Instance.new("Folder",workspace)
VisualPointsFolder.Name = "VisualPoints"

local RoomNodes = {
    ["Hotel_PreLibraryEntrance"] = {
        Vector3.new(0, 0, -3.845785140991211),
        Vector3.new(-1.6612396240234375, 0, -13.02124309539795),
        Vector3.new(-0.546905517578125, 0, -32.218448638916016),
        Vector3.new(1.1776580810546875, 0, -46.614173889160156),
        Vector3.new(7.051445007324219, 0, -48.653968811035156),
        Vector3.new(15.525882720947266, 0, -49.897499084472656),
        Vector3.new(27.587413787841797, 0, -50.475799560546875),
        Vector3.new(36.673118591308594, 0, -48.31147766113281),
        Vector3.new(41.19118118286133, 0, -47.28938293457031),
        Vector3.new(44.839866638183594, 0, -49.95335388183594),
        Vector3.new(43.878509521484375, 0, -55.965171813964844),
        Vector3.new(43.21472930908203, 0, -64.9736328125),
        Vector3.new(41.343135833740234, 0, -69.84690856933594),
        Vector3.new(41.343135833740234, 0, -78.04531860351562),
        Vector3.new(43.541969299316406, 0, -84.85281372070312),
        Vector3.new(44.98603439331055, 0, -95.1502914428711),
    },
    ["Hotel_SkinnyHallway"] = {
        Vector3.new(0, 0, -3.845785140991211),
        Vector3.new(-1.6612396240234375, 0, -13.02124309539795),
        Vector3.new(-0.546905517578125, 0, -32.218448638916016),
        Vector3.new(1.1776580810546875, 0, -46.614173889160156),
        Vector3.new(7.051445007324219, 0, -48.653968811035156),
        Vector3.new(15.525882720947266, 0, -49.897499084472656),
        Vector3.new(27.587413787841797, 0, -50.475799560546875),
        Vector3.new(36.673118591308594, 0, -48.31147766113281),
        Vector3.new(41.19118118286133, 0, -47.28938293457031),
        Vector3.new(44.839866638183594, 0, -49.95335388183594),
        Vector3.new(43.878509521484375, 0, -55.965171813964844),
        Vector3.new(43.21472930908203, 0, -64.9736328125),
        Vector3.new(41.343135833740234, 0, -69.84690856933594),
        Vector3.new(41.343135833740234, 0, -78.04531860351562),
        Vector3.new(43.541969299316406, 0, -84.85281372070312),
        Vector3.new(44.98603439331055, 0, -95.1502914428711),
    },
}

local function CreatePathfindingLinks(part, positions)
	local attachments = {}

	for i, position in ipairs(positions) do
		local attachment = Instance.new("Attachment")
		attachment.Name = "Attachment" .. tostring(i)
		attachment.Position = position
		attachment.Parent = part
		attachment.Visible = true
		table.insert(attachments, attachment)
	end

	for i = 1, #attachments - 1 do
		local link = Instance.new("PathfindingLink")
		link.Name = "PathfindingLink" .. tostring(i)
		link.Attachment0 = attachments[i]
		link.Attachment1 = attachments[i+1]
		link.IsBidirectional = true
		link.Label = "NodeLink"
		link.Parent = part
	end
end

local function CreateVisualPoint(Position)
    local A = Instance.new("Part",VisualPointsFolder)
	local B = Instance.new("SelectionSphere")
	A.Anchored = true
	A.CanCollide = false
	A.Size = Vector3.new(0.001,0.001,0.001)
    A.Name = tostring(Position)
	A.Position = Position + Vector3.new(0,2,0)
	A.Transparency = 1
	B.Transparency = 0
	B.Parent = A
	B.Adornee = A
	B.Color3 = Color3.new(1, 0.984313, 0)
    return A
end

local function UpdateVisualPoint(Point,ColorOrDestroy)
    local VisualPoint = Point:FindFirstChild("SelectionSphere")
    assert(VisualPoint, "[871] Missing SelectionSphere")

    if ColorOrDestroy == true then
        Point:Destroy()
    elseif typeof(ColorOrDestroy) == "Color3" then
        VisualPoint.Color3 = ColorOrDestroy
    end
end

local function ClearVisualPoints()
    VisualPointsFolder:ClearAllChildren()
end

local function GeneratePath(Position)

    Debug("Generating path...")

    local Path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 6,
        AgentCanJump = false,
        AgentCanClimb = true,
        Costs = {
            NodeLink = 1
        }
    })

    Path:ComputeAsync(LocalPlayer.Character.HumanoidRootPart.Position,Position)
    
    if Path.Status == Enum.PathStatus.Success then
        return Path
    end

    return Path
end

local function GetBannanas()
    local Bannanas = {}
    for i,v in pairs(workspace:GetChildren()) do
        if v.Name == "BananaPeel" then
            table.insert(Bannanas, v)
        end
    end
    return Bannanas
end

local function GetRandomPlayer()
    local Players = game.Players:GetPlayers()
    local PlayersExcludingMyself = {}

    for i,v in pairs(Players) do
        if v ~= LocalPlayer then
            table.insert(PlayersExcludingMyself, v)
        end
    end

    return PlayersExcludingMyself[math.random(1,#PlayersExcludingMyself)]
end

local function IsPartMoving(Part)
    local OldPosition = Part.Position
    task.wait(0.1)
    
    if (OldPosition - Part.Position).Magnitude < 0.1 then
        return false
    else
        return true
    end
end

local function FindShortestPathToWardrobeOrLocker()
    local ShortestPath = nil
    local ShortestPathLength = math.huge
    local Rooms = CurrentRooms:GetChildren()
    for _, Room in ipairs(Rooms) do
        local WardrobeOrLockerAssets = Room.Assets:GetChildren()
        for _, Asset in ipairs(WardrobeOrLockerAssets) do
            if Asset.Name == "Wardrobe" or Asset.Name == "Locker" then
                local Path = GeneratePath(Asset.PrimaryPart.Position)
                if Path then
                    local PathLength = 0
                    local Waypoints = Path:GetWaypoints()
                    for i = 2, #Waypoints do
                        PathLength = PathLength + (Waypoints[i].Position - Waypoints[i-1].Position).Magnitude
                    end
                    if PathLength < ShortestPathLength then
                        ShortestPathLength = PathLength
                        ShortestPath = Path
                    end
                end
            end
        end
    end
    return ShortestPath
end

local function MoveCharacterToPoint(TargetPoint, Speed, MaxRadius)
    local Character = LocalPlayer.Character
    local CurrentPosition = Character.HumanoidRootPart.Position
    local DistanceToTarget = (TargetPoint - CurrentPosition).Magnitude
    local TimeToReachTarget = DistanceToTarget / Speed

    local StartTime = tick()
    local EndTime = StartTime + TimeToReachTarget

    if MaxRadius then
        while tick() < EndTime and (Character.HumanoidRootPart.Position - TargetPoint).Magnitude < MaxRadius do
            if IsFlooring then
                Debug("IsFlooring | Yielding MoveCharacterToPoint.")
                repeat wait(0.1) until not IsFlooring
                wait(1)
                MoveCharacterToPoint(TargetPoint,Speed,MaxRadius)
                break
            end
            local ElapsedTime = tick() - StartTime
            local LerpAmount = ElapsedTime / TimeToReachTarget
            Character:PivotTo(CFrame.new(CurrentPosition:Lerp(TargetPoint, LerpAmount)))
            RunService.Heartbeat:Wait()
        end
    else
        while tick() < EndTime do
            if IsFlooring then
                Debug("IsFlooring | Yielding MoveCharacterToPoint.")
                repeat wait(0.1) until not IsFlooring
                wait(1)
                MoveCharacterToPoint(TargetPoint,Speed)
                break
            end
            local ElapsedTime = tick() - StartTime
            local LerpAmount = ElapsedTime / TimeToReachTarget
            Character:PivotTo(CFrame.new(CurrentPosition:Lerp(TargetPoint, LerpAmount)))
            RunService.Heartbeat:Wait()
        end
    end
end

local function AutoPilotHandler(RoomValue)
    if Library.flags.AutoPilot then

        local Room = CurrentRooms:WaitForChild(tostring(RoomValue),5)

        ClearVisualPoints()

        wait(1)

        local RoomName = Room:GetAttribute("OriginalName")

        local Exit = Room:WaitForChild("RoomExit",3)
        
        local Checkpoints = RoomNodes[RoomName]

        if Checkpoints then
            Debug("Building Manual Nodes.")
            CreatePathfindingLinks(Room.PrimaryPart,Checkpoints)
        end

        local CameraScript = LocalPlayer.PlayerGui.MainUI.Initiator["Main_Game"].Camera
        local Character = LocalPlayer.Character
        local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
        local Humanoid = Character:FindFirstChild("Humanoid")

        assert(HumanoidRootPart, "HumanoidRootPart cannot be found.")
        assert(Humanoid, "Humanoid cannot be found.")

        if Room and Exit then
            if (Character.HumanoidRootPart.Position - Room.RoomEntrance.Position).Magnitude > 10 then
                Debug("CurrentRoom is not actually current room? Yielding.")
                repeat wait() until (Character.HumanoidRootPart.Position - Room.RoomEntrance.Position).Magnitude < 10
            end

            local Door = Room:WaitForChild("Door",3)

            local Exclusion = Instance.new("PathfindingModifier",Door.Collision)
            Exclusion.PassThrough = true

            assert(Door,"A valid door cannot be found! Room #" .. tostring(RoomValue))
            local Lock = Door:FindFirstChild("Lock")

            local TargetKey = false
            local RoomObstructed = false

            for i,v in pairs(Room:GetDescendants()) do
                if v.Name == "KeyObtain" then
                    TargetKey = v
                end
                if v.Name == "DoorNormal" then
                    local DoorIgnoreLink = Instance.new("PathfindingModifier",v.Door)
                    DoorIgnoreLink.PassThrough = true
                end
                if v.Name == "LiveObstructionNew" then
                    RoomObstructed = true
                end
            end

            local Path = GeneratePath(Exit.Position)

            if Path and Path.Status == Enum.PathStatus.Success then

                CameraScript.Disabled = true

                local Waypoints = Path:GetWaypoints()

                --Make visual points
                for Index, Waypoint in pairs(Waypoints) do
                    CreateVisualPoint(Waypoint.Position)
                end

                -- Main pathing loop
                for Index, Waypoint in pairs(Waypoints) do
                    CreateVisualPoint(Waypoint.Position)
                    Debug("Updating Visual Points...")
                    local LastVisualPoint = Waypoints[Index - 1]
                    UpdateVisualPoint(VisualPointsFolder:FindFirstChild(tostring(Waypoint.Position)),Color3.new(0.082352, 1, 0))
                    
                    if LastVisualPoint then
                        local PhysicalPoint = VisualPointsFolder:FindFirstChild(tostring(LastVisualPoint.Position))
                        if PhysicalPoint then
                            UpdateVisualPoint(PhysicalPoint,true)
                        end
                    end

                    Debug("Pathing to " .. tostring(Waypoint.Position))

                    RunService:BindToRenderStep("CamLockBind", 500, function()
                        LocalPlayer.Character:PivotTo(CFrame.new(Character.PrimaryPart.Position,Vector3.new(Waypoint.Position.X,HumanoidRootPart.Position.Y,Waypoint.Position.Z)))
                        Camera.CFrame = CFrame.new(Character.Head.Position,Vector3.new(Waypoint.Position.X,Character.Head.Position.Y,Waypoint.Position.Z))
                    end)

                    while (HumanoidRootPart.Position * Vector3.new(1,0,1) - Waypoint.Position * Vector3.new(1,0,1)).Magnitude > 3 and Library.flags.AutoPilot do
                        RunService.Heartbeat:Wait()
                        Humanoid:MoveTo(Waypoint.Position)
                        local CharacterMoving = IsPartMoving(HumanoidRootPart)
                        if not CharacterMoving and not IsFlooring then
                            Debug("Possibly stuck. | Yielding and checking movement for next second.")
                            local Moved = false
                            for i = 10,1,-1 do
                                if IsPartMoving(HumanoidRootPart) then
                                    Moved = true
                                    break
                                end
                            end
                            if not Moved then
                                Debug("Character not moving. Skipping to waypoint.")
                                Character:PivotTo(CFrame.new(Waypoint.Position + Vector3.new(0,4,0)))
                            end
                        end
                    end

                    RunService:UnbindFromRenderStep("CamLockBind")
                end

                CameraScript.Disabled = false
                local NextRoom = CurrentRooms:WaitForChild(tostring(RoomValue + 1),5)

                if Lock and NextRoom and not NextRoom.Door:FindFirstChild("Lock") then
                    Door:Destroy()
                    Debug("Skipping locked door. RIP BOZO!")
                    ReplicatedStorage.GameData.LatestRoom.Value = ReplicatedStorage.GameData.LatestRoom.Value + 1
                end
            else
                Debug("Unable to find path. | " .. tostring(Path.Status))
                if RoomObstructed then
                    LocalPlayer.Character:PivotTo(CFrame.new(LocalPlayer.Character.HumanoidRootPart.Position + Vector3.new(0,6,0)))
                    MoveCharacterToPoint(Room.RoomExit.Position + Vector3.new(0,4,0), 12)
                else
                    MoveCharacterToPoint(Room.RoomExit.Position, 12)
                end
            end

        end
    end
end

function Library:Notify(Text,Duration)
    if not Watermark then
        Watermark = Library:Watermark(Text)
    end
    if Duration then
        delay(Duration,function()
            Library.watermarkobject:Remove()
            Watermark = nil
        end)
    else
        return Watermark
    end
end

local SuperHardMode = false
if LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game.RemoteListener:FindFirstChild("Jumpscare_Fools") then
    SuperHardMode = true
end

if game.PlaceId == 6516141723 then
    Library:Notify("Please execute in game, not the lobby!",3)
    return
end

local Main = Library:Load{
    Name = "sasware | Doors | v" .. Version,
    SizeX = 600,
    SizeY = 650,
    Theme = "Midnight",
    Extension = "json",
    Folder = "saswareDoors"
}

local MainTab = Main:Tab("Main")

local AssistSection = MainTab:Section{
    Name = "Assists",
    Side = "Left"
}

AssistSection:Toggle{
    Name = "Autopilot [BETA]",
    Flag = "AutoPilot",
    Callback = function(Bool)
        if Bool then
            PlayGlobalSound("rbxassetid://4611349448")
        else
            PlayGlobalSound("rbxassetid://4611347355")
        end
    end
}

AssistSection:Toggle{
    Name = "Auto Heartbeat",
    Flag = "AutoHeartbeat"
}

AssistSection:Toggle{
    Name = "No Dark Rooms",
    Flag = "NoDarkRooms"
}

AssistSection:Toggle{
    Name = "Disable Screech",
    Flag = "NoScreech",
    Callback  = function(bool)
        if bool == false then
            for i,v in pairs(ScreechConnections) do
                v:Enable()
            end
        else
            for i,v in pairs(ScreechConnections) do
                v:Disable()
            end
        end
    end
}

AssistSection:Toggle{
    Name = "Auto Library Code",
    Flag = "AutoLibraryCode"
}

AssistSection:Toggle{
    Name = "Disable Eyes",
    Flag = "DisableEyes"
}

AssistSection:Button{
    Name = "Restart Run",
    Callback = function()
        EntityInfo:WaitForChild("PlayAgain"):FireServer()
    end
}

local CharacterSection = MainTab:Section{
    Name = "Character",
    Side = "Right"
}

CharacterSection:Separator("Miscellaneous")

CharacterSection:Toggle{
    Name = "Headlight",
    Flag = "Headlight",
    Callback  = function(bool)
        SetHeadlight(LocalPlayer.Character,bool)
    end
}

CharacterSection:Separator("Movement")

local TargetWalkspeed = 0

CharacterSection:Slider{
    Text = "Speed Boost | [value]/5",
    Default = 0,
    Min = 0,
    Max = 5,
    Float = 0.05,
    Flag = "SpeedSlider",
    Callback = function(value)
        TargetWalkspeed = value
    end
}

local BlatantSection = MainTab:Section{
    Name = "Blatant",
    Side = "Left"
}

BlatantSection:Button{
    Name = "Anticheat Bypass [Use in Elevator]",
    Callback = function()
        AnticheatBypassed = true
        local FakePre = EntityInfo.PreRunShop:Clone()
        EntityInfo.PreRunShop:Destroy()
        FakePre.Parent = EntityInfo
        LocalPlayer.PlayerGui.MainUI.Initiator["Main_Game"].RemoteListener.Disabled = true
        for i,v in pairs(getconnections(LocalPlayer.PlayerGui.MainUI.ItemShop.Confirm.MouseButton1Down)) do
            v:Fire(0,0)
        end
        local StarterElevator = workspace.CurrentRooms["0"].StarterElevator
        
        StarterElevator.DoorHitbox.BillboardGui.Enabled = false

        StarterElevator.DoorHitbox.DoorBell:Play()
        wait(StarterElevator.DoorHitbox.DoorBell.TimeLength - 1.7)
        StarterElevator.DoorHitbox.DoorMove:Play()
        for i,v in pairs(StarterElevator:GetChildren()) do
            if v:IsA("PrismaticConstraint") then
                v.TargetPosition = 5
            end
        end
        StarterElevator.DoorHitbox.CanCollide = false
        wait(StarterElevator.DoorHitbox.DoorMove.TimeLength * 0.35)
        for i,v in pairs(StarterElevator:GetChildren()) do
            if v:IsA("PrismaticConstraint") then
                v.TargetPosition = 0
            end
        end
    end
}

BlatantSection:Toggle{
    Name = "Disable Seek Chase",
    Flag = "NoSeek"
}

BlatantSection:Toggle{
    Name = "Disable Seek Arms/Fire",
    Flag = "NoSeekObstacles"
}


BlatantSection:Toggle{
    Name = "Instant Interact",
    Flag = "InstantInteract"
}

BlatantSection:Toggle{
    Name = "Anti-Ambush/Rush",
    Flag = "AntiEntity"
}

if SuperHardMode then

    BlatantSection:Toggle{
        Name = "Jeff The Killer Disabler",
        Flag = "AntiJeff"
    }

    BlatantSection:Toggle{
        Name = "Disable Bannanas",
        Flag = "DisableBannanaFlag"
    }

    BlatantSection:Toggle{
        Name = "Spam trip others",
        Flag = "SpamBannanaFlag"
    }

end

local VisualsTab = Main:Tab("Visuals")

local NotificationSection = VisualsTab:Section{
    Name = "Notifications",
    Side = "Right"
}

NotificationSection:Toggle{
    Name = "Entity Notifications",
    Flag = "EntityNotifications",
    Default = true
}

local ESPSection = VisualsTab:Section{
    Name = "ESP",
    Side = "Left"
}

ESPSection:Toggle{
    Name = "ESP Enabled",
    Flag = "ESPFlag",
    Default = true,
    Callback = function(Bool)
        for i,v in pairs(ESPObjects) do
            v.Drawing.Visible = Bool
        end
    end
}

ESPSection:Toggle{
    Name = "Item ESP",
    Flag = "Item",
    Default = true,
    Callback = function(Bool)
        for i,v in pairs(ESPObjects) do
            if v.Tag == "Item" then
                v.Enabled = Bool
            end
        end
    end
}

ESPSection:Toggle{
    Name = "Book ESP",
    Flag = "Book",
    Default = true,
    Callback = function(Bool)
        for i,v in pairs(ESPObjects) do
            if v.Tag == "Book" then
                v.Enabled = Bool
            end
        end
    end
}

ESPSection:Toggle{
    Name = "Key ESP",
    Flag = "Key",
    Default = true,
    Callback = function(Bool)
        for i,v in pairs(ESPObjects) do
            if v.Tag == "Key" then
                v.Enabled = Bool
                v.Drawing.Visible = false
            end
        end
    end
}

ESPSection:Toggle{
    Name = "Lever ESP",
    Flag = "Lever",
    Default = true,
    Callback = function(Bool)
        for i,v in pairs(ESPObjects) do
            if v.Tag == "Lever" then
                v.Enabled = Bool
            end
        end
    end
}

ESPSection:Toggle{
    Name = "Door ESP",
    Flag = "Door",
    Default = false,
    Callback = function(Bool)
        for i,v in pairs(ESPObjects) do
            if v.Tag == "Door" then
                v.Enabled = Bool
            end
        end
    end
}

local Configs = Main:Tab("Configuration")

local Themes = Configs:Section{Name = "Theme", Side = "Left"}

local ThemePickers = {}

local ThemeList = Themes:Dropdown{
    Name = "Theme",
    Default = Library.currenttheme,
    Content = Library:GetThemes(),
    Flag = "Theme Dropdown",
    Callback = function(option)
        if option then
            Library:SetTheme(option)

            for option, picker in next, ThemePickers do
                picker:Set(Library.theme[option])
            end
        end
    end
}

Library:ConfigIgnore("Theme Dropdown")

local NameBox = Themes:Box{
    Name = "Custom Theme Name",
    Placeholder = "Custom Theme",
    Flag = "Custom Theme"
}

Library:ConfigIgnore("Custom Theme")

Themes:Button{
    Name = "Save Custom Theme",
    Callback = function()
        if Library:SaveCustomTheme(Library.flags["Custom Theme"]) then
            ThemeList:Refresh(Library:GetThemes())
            ThemeList:Set(Library.flags["Custom Theme"])
            NameBox:Set("")
        end
    end
}

local CustomTheme = Configs:Section{Name = "Custom Theme", Side = "Right"}

ThemePickers["Accent"] = CustomTheme:ColorPicker{
    Name = "Accent",
    Default = Library.theme["Accent"],
    Flag = "Accent",
    Callback = function(color)
        Library:ChangeThemeOption("Accent", color)
    end
}

Library:ConfigIgnore("Accent")

ThemePickers["Window Background"] = CustomTheme:ColorPicker{
    Name = "Window Background",
    Default = Library.theme["Window Background"],
    Flag = "Window Background",
    Callback = function(color)
        Library:ChangeThemeOption("Window Background", color)
    end
}

Library:ConfigIgnore("Window Background")

ThemePickers["Window Border"] = CustomTheme:ColorPicker{
    Name = "Window Border",
    Default = Library.theme["Window Border"],
    Flag = "Window Border",
    Callback = function(color)
        Library:ChangeThemeOption("Window Border", color)
    end
}

Library:ConfigIgnore("Window Border")

ThemePickers["Tab Background"] = CustomTheme:ColorPicker{
    Name = "Tab Background",
    Default = Library.theme["Tab Background"],
    Flag = "Tab Background",
    Callback = function(color)
        Library:ChangeThemeOption("Tab Background", color)
    end
}

Library:ConfigIgnore("Tab Background")

ThemePickers["Tab Border"] = CustomTheme:ColorPicker{
    Name = "Tab Border",
    Default = Library.theme["Tab Border"],
    Flag = "Tab Border",
    Callback = function(color)
        Library:ChangeThemeOption("Tab Border", color)
    end
}

Library:ConfigIgnore("Tab Border")

ThemePickers["Tab Toggle Background"] = CustomTheme:ColorPicker{
    Name = "Tab Toggle Background",
    Default = Library.theme["Tab Toggle Background"],
    Flag = "Tab Toggle Background",
    Callback = function(color)
        Library:ChangeThemeOption("Tab Toggle Background", color)
    end
}

Library:ConfigIgnore("Tab Toggle Background")

ThemePickers["Section Background"] = CustomTheme:ColorPicker{
    Name = "Section Background",
    Default = Library.theme["Section Background"],
    Flag = "Section Background",
    Callback = function(color)
        Library:ChangeThemeOption("Section Background", color)
    end
}

Library:ConfigIgnore("Section Background")

ThemePickers["Section Border"] = CustomTheme:ColorPicker{
    Name = "Section Border",
    Default = Library.theme["Section Border"],
    Flag = "Section Border",
    Callback = function(color)
        Library:ChangeThemeOption("Section Border", color)
    end
}

Library:ConfigIgnore("Section Border")

ThemePickers["Text"] = CustomTheme:ColorPicker{
    Name = "Text",
    Default = Library.theme["Text"],
    Flag = "Text",
    Callback = function(color)
        Library:ChangeThemeOption("Text", color)
    end
}

Library:ConfigIgnore("Text")

ThemePickers["Disabled Text"] = CustomTheme:ColorPicker{
    Name = "Disabled Text",
    Default = Library.theme["Disabled Text"],
    Flag = "Disabled Text",
    Callback = function(color)
        Library:ChangeThemeOption("Disabled Text", color)
    end
}

Library:ConfigIgnore("Disabled Text")

ThemePickers["Object Background"] = CustomTheme:ColorPicker{
    Name = "Object Background",
    Default = Library.theme["Object Background"],
    Flag = "Object Background",
    Callback = function(color)
        Library:ChangeThemeOption("Object Background", color)
    end
}

Library:ConfigIgnore("Object Background")

ThemePickers["Object Border"] = CustomTheme:ColorPicker{
    Name = "Object Border",
    Default = Library.theme["Object Border"],
    Flag = "Object Border",
    Callback = function(color)
        Library:ChangeThemeOption("Object Border", color)
    end
}

Library:ConfigIgnore("Object Border")

ThemePickers["Dropdown Option Background"] = CustomTheme:ColorPicker{
    Name = "Dropdown Option Background",
    Default = Library.theme["Dropdown Option Background"],
    Flag = "Dropdown Option Background",
    Callback = function(color)
        Library:ChangeThemeOption("Dropdown Option Background", color)
    end
}

Library:ConfigIgnore("Dropdown Option Background")

local Configsection = Configs:Section{Name = "Configs", Side = "Left"}

local configlist = Configsection:Dropdown{
    Name = "Configs",
    Content = Library:GetConfigs(), -- GetConfigs(true) if you want universal Configs
    Flag = "Config Dropdown"
}

Library:ConfigIgnore("Config Dropdown")

Configsection:Button{
    Name = "Load Config",
    Callback = function()
        Library:LoadConfig(Library.flags["Config Dropdown"]) -- LoadConfig(Library.flags["Config Dropdown"], true)  if you want universal Configs
    end
}

Configsection:Button{
    Name = "Delete Config",
    Callback = function()
        Library:DeleteConfig(Library.flags["Config Dropdown"]) -- DeleteConfig(Library.flags["Config Dropdown"], true)  if you want universal Configs
        configlist:Refresh(Library:GetConfigs())
    end
}


Configsection:Box{
    Name = "Config Name",
    Placeholder = "Config Name",
    Flag = "Config Name"
}

Library:ConfigIgnore("Config Name")

Configsection:Button{
    Name = "Save Config",
    Callback = function()
        Library:SaveConfig(Library.flags["Config Dropdown"] or Library.flags["Config Name"]) -- SaveConfig(Library.flags["Config Name"], true) if you want universal Configs
        configlist:Refresh(Library:GetConfigs())
    end
}

local keybindsection = Configs:Section{Name = "UI Toggle Keybind", Side = "Left"}

local libopen = true

keybindsection:Keybind{
    Name = "UI Toggle",
    Flag = "UI Toggle",
    Default = Enum.KeyCode.RightShift,
    Blacklist = {Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2, Enum.UserInputType.MouseButton3},
    Callback = function(_, fromsetting)
        if not fromsetting then
            Library:Close()
        end
    end
}

RequiredRemotes.ClutchHeartbeat.OnClientEvent:Connect(OnHeartbeatMinigameStart)

RunService.Heartbeat:Connect(function(deltaTime)
    local Multiplier = 1
    if AnticheatBypassed then
        Multiplier = 3
    end

    LocalPlayer.Character:TranslateBy(LocalPlayer.Character.Humanoid.MoveDirection * TargetWalkspeed * deltaTime * Multiplier)

    if Library.flags.SpamBannanaFlag then
        local Bannanas = GetBannanas()

        for _, Bannana in next, Bannanas do
            Bannana.Velocity = Vector3.new(0,-5,0)
        end

        for _, Bannana in next, Bannanas do
            if isnetworkowner(Bannana) then
                Bannana.CFrame = GetRandomPlayer().Character.PrimaryPart.CFrame
            end
        end
    end
    
end)

RunService.RenderStepped:Connect(function(deltaTime)
    if Library.flags.ESPFlag then
        for i,v in pairs(ESPObjects) do
            v:Update()
        end
    end
end)

ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
    if Library.flags.InstantInteract then
        fireproximityprompt(prompt)
    end
end)

workspace.ChildAdded:Connect(EntityHandler)

ReplicatedStorage.GameData.LatestRoom.Changed:Connect(AutoPilotHandler)

CurrentRooms.ChildAdded:Connect(SetupRoom)

for i,v in pairs(CurrentRooms:GetChildren()) do
    SetupRoom(v)
end

local oldnamecall; oldnamecall = hookmetamethod(game, '__namecall', function(self, ...)
    local Args = {...}

    if Library.flags.DisableEyes and game.FindFirstChild(workspace, "Eyes") and self == MotorReplication then
        Args[2] = -65
        return oldnamecall(self, table.unpack(Args))
    end
    
    return oldnamecall(self, ...)
end)

Library:Notify("Loaded all features in " .. tostring(Round(tick() - StartTick,2)) .. " seconds.",3)
