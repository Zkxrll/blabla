--[[
    Perseus Key System - readable reconstruction of KeySystem.lua
    (original: laeraz/Perseus  General/Library/KeySystem.lua, obfuscated with the WeAreDevs obfuscator v1.0.0)

    HOW THIS WAS PRODUCED
      The obfuscated file is a control-flow-flattened state machine with runtime-decrypted strings, so it was NOT
      decompiled line by line. It was executed inside a locked-down mock Roblox/executor sandbox (no real I/O or
      network, nothing from the script ever touched a real executor) and every call, property write, file operation
      and branch outcome was recorded, then re-driven under many scenarios (every Luarmor status code, saved key /
      no saved key / corrupt file, supported / unsupported game, Studio / executor, drag input, hover, minimise...).
      The code below reproduces that observed behaviour. The UI block is generated mechanically from the trace.

    WHAT IS NOT REPRODUCED
      * The original's anti-tamper block (it probes error()/environment behaviour and throws "Tamper Detected!").
      * Decoy reads of ~40 random-named nonexistent globals (pure noise).
      * `getgenv().protectgui` is read by the original but never called in any observed path, so it is omitted.

    EXTERNAL DEPENDENCIES (what the original fetches at runtime)
      * https://raw.githubusercontent.com/Severitysvc/Overlay-Library/refs/heads/main/Library.lua   (UI/notification lib)
      * https://sdkapi-public.luarmor.net/library.lua                                                (Luarmor SDK)
]]

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Severitysvc/Overlay-Library/refs/heads/main/Library.lua"))()

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

-- where the ScreenGui lives: PlayerGui in Studio, otherwise gethui() if the executor has it, else CoreGui
local GuiParent
if RunService:IsStudio() then
	GuiParent = Players.LocalPlayer:WaitForChild("PlayerGui")
elseif getgenv().gethui then
	GuiParent = getgenv().gethui()
else
	GuiParent = game:GetService("CoreGui")
end
local _ = getgenv().protectgui -- read in the original, never used

Library:SetLibraryDebugs(false)
Library:SetHidden(true)
Library:SetIconPack("solar")

local Luarmor = loadstring(game:HttpGet("https://sdkapi-public.luarmor.net/library.lua"))()

---------------------------------------------------------------------------------------------------------
-- UI (generated from the execution trace). Note: the original assigns each Instance its real Name and
-- immediately blanks it; the "original name" comments below record what it was.
---------------------------------------------------------------------------------------------------------
-- every created instance is remembered (in creation order) so the whole UI can be torn down later
local UIInstances = {}
local function New(className)
	local instance = Instance.new(className)
	UIInstances[#UIInstances + 1] = instance
	return instance
end

--[[UI_BUILDER]]

---------------------------------------------------------------------------------------------------------
-- Constants
---------------------------------------------------------------------------------------------------------
local KEY_FOLDER = "Perseus"
local KEY_FILE = "Perseus/Key.json"

-- Luarmor script id per game. The key is the *universe* id (game.GameId), not game.PlaceId.
-- (6035872082 is the "Rivals" universe; the changelog text in the UI mentions a "Rivals Beta Release".)
local ScriptIds = {
	[6035872082] = "c9596bc6bffaa7ccef69026a5a0df47e",
	[7633926880] = "5ab97c014f9eeb177d62a504bf0a3ce1",
}

local DISCORD_INVITE = "https://discord.gg/b2hbaJHVfF"
local DISCORD_RPC_CODE = "njZMktNrj6" -- NOTE: differs from the code in DISCORD_INVITE (both appear verbatim in the original)

---------------------------------------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------------------------------------
local TWEEN_INFO = function(t)
	return TweenInfo.new(t or 0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, 0)
end

local function Tween(object, goal, t)
	TweenService:Create(object, TWEEN_INFO(t), goal):Play()
end

local function Notify(content)
	task.spawn(function()
		Library:Notify({
			Title = "Perseus",
			CloseType = "Body Click",
			Duration = 5,
			Background = "rbxassetid://82295031952284",
			Content = content,
			Icon = "rbxassetid://134070681746662",
		})
	end)
end

-- Key persistence format: Perseus/Key.json holds a JSON array of numbers,
--   stored[i] = (string.byte(key, i) + 137 + i) % 256        (i is 1-based)
-- "none" is the sentinel that means "no saved key".
local function EncodeKey(key)
	local bytes = {}
	for i = 1, #key do
		bytes[i] = (string.byte(key, i) + 137 + i) % 256
	end
	return bytes
end

local function DecodeKey(bytes)
	local chars = {}
	for i = 1, #bytes do
		chars[i] = string.char((bytes[i] - 137 - i) % 256)
	end
	return table.concat(chars)
end

local function SaveKey(key)
	writefile(KEY_FILE, HttpService:JSONEncode(EncodeKey(key)))
end

-- tears the whole key-system UI down, instance by instance, in creation order
local function DestroyUI()
	for _, instance in ipairs(UIInstances) do
		instance:Destroy()
	end
end

---------------------------------------------------------------------------------------------------------
-- Window dragging (drag the thin bar at the top; the window eases toward the cursor)
---------------------------------------------------------------------------------------------------------
local dragging, dragStart, startPosition, targetPosition, followConnection

local function isPointer(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

DragBar.InputBegan:Connect(function(input)
	if isPointer(input) then
		dragging = true
		dragStart = input.Position
		startPosition = Window.Position
		followConnection = RunService.Heartbeat:Connect(function(dt)
			local alpha = 1 - math.exp(-20 * dt)
			Window.Position = Window.Position:Lerp(targetPosition, alpha)
		end)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		targetPosition = UDim2.new(
			startPosition.X.Scale, startPosition.X.Offset + delta.X,
			startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
		)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if dragging and isPointer(input) then
		dragging = false
		followConnection:Disconnect()
		task.spawn(function()
			Tween(DragBar, { BackgroundTransparency = 0.9 })
		end)
	end
end)

DragBar.MouseEnter:Connect(function()
	task.spawn(function()
		Tween(DragBar, { BackgroundTransparency = 0.2 })
	end)
end)

DragBar.MouseLeave:Connect(function()
	task.spawn(function()
		Tween(DragBar, { BackgroundTransparency = 0.6 })
	end)
end)

---------------------------------------------------------------------------------------------------------
-- Game gate
---------------------------------------------------------------------------------------------------------
if not ScriptIds[game.GameId] then
	Players.LocalPlayer:Kick("Game not supported.")
end

---------------------------------------------------------------------------------------------------------
-- Saved key (Perseus/Key.json)
---------------------------------------------------------------------------------------------------------
if not isfolder(KEY_FOLDER) then
	makefolder(KEY_FOLDER)
end
if not isfile(KEY_FILE) then
	SaveKey("none")
end

readfile(KEY_FILE) -- the original reads the file once here and discards the result

local savedKey
if isfile(KEY_FILE) then
	local ok, bytes = pcall(function()
		return HttpService:JSONDecode(readfile(KEY_FILE))
	end)
	if ok then
		savedKey = DecodeKey(bytes)
	end
end

-- shared by the saved-key path and the "Check Key" button: ask Luarmor about `key`
local function CheckKey(key)
	Luarmor.script_id = ScriptIds[game.GameId]
	getgenv().script_key = key
	return Luarmor.check_key(key)
end

if savedKey and savedKey ~= "none" and savedKey ~= "" then
	local status = CheckKey(savedKey)
	if status.code == "KEY_VALID" then
		DestroyUI()
		Notify("Loaded Saved Key.")
		Luarmor.load_script()
	elseif status.code == "KEY_HWID_LOCKED" then
		Players.LocalPlayer:Kick("The key is set to a different HWID")
	elseif status.code == "KEY_INCORRECT" then
		Notify("Saved key is invalid or expired.")
		SaveKey("none") -- forget the bad key
	else
		Notify("Saved key is invalid or expired")
	end
end

Notify("Complete The KeySystems In Order To Unlock The Scripts.")

shared.Keysystem = Window

---------------------------------------------------------------------------------------------------------
-- Top-right buttons
---------------------------------------------------------------------------------------------------------
CloseButton.MouseButton1Click:Connect(function()
	Library:Notify({
		CloseType = "Body Click",
		Title = "Close Interface",
		Buttons = {
			{
				Title = "Unload Interface",
				Callback = function()
					Library:DisconnectAllConnections()
					Library:DisconnectAllSignals()
					Library:DestroyAll()
				end,
			},
			{
				Title = "Cancel",
				Callback = function() end,
				DestroyOnClick = true,
			},
		},
		Duration = 15,
		Background = "rbxassetid://82295031952284",
		Content = "Are you sure that you want to unload the UI?",
		Icon = "solar:shield-warning-bold",
	})
end)

-- minimise / restore the body of the window
local collapsed = false

local function Collapse()
	LeftBodySize = UDim2.new(LeftBodySize.X.Scale, LeftBodySize.X.Offset, 0, LeftContent.AbsoluteSize.Y)
	LeftContent.Size = LeftBodySize
	RightBodySize = UDim2.new(RightBodySize.X.Scale, RightBodySize.X.Offset, 0, RightContent.AbsoluteSize.Y)
	RightContent.Size = RightBodySize
	LeftContent.AutomaticSize = Enum.AutomaticSize.None
	RightContent.AutomaticSize = Enum.AutomaticSize.None
	RightLayoutUIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	Tween(LeftContent, { Size = UDim2.new(LeftBodySize.X.Scale, LeftBodySize.X.Offset, 0, 0) }, 0.3)
	Tween(DragBar, { Position = UDim2.new(0.5, 0, -0.75, 0) }, 0.2)
	Tween(RightContent, { Size = UDim2.new(RightBodySize.X.Scale, RightBodySize.X.Offset, 0, 0) }, 0.3)
	task.wait(0.31)
	LeftContent.Visible = false
	RightContent.Visible = false
end

local function Expand()
	LeftContent.Visible = true
	RightContent.Visible = true
	RightLayoutUIListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	Tween(LeftContent, { Size = UDim2.new(LeftBodySize.X.Scale, LeftBodySize.X.Offset, 0, LeftContent.AbsoluteSize.Y) }, 0.3)
	Tween(DragBar, { Position = UDim2.new(0.5, 0, -0.125, 0) }, 0.3)
	Tween(RightContent, { Size = UDim2.new(RightBodySize.X.Scale, RightBodySize.X.Offset, 0, RightContent.AbsoluteSize.Y) }, 0.3)
	task.wait(0.32)
	LeftContent.AutomaticSize = Enum.AutomaticSize.Y
	RightContent.AutomaticSize = Enum.AutomaticSize.Y
end

MinimizeButton.MouseButton1Click:Connect(function()
	collapsed = not collapsed
	task.spawn(collapsed and Collapse or Expand)
end)

---------------------------------------------------------------------------------------------------------
-- Hover effects (all tween 0.25s Sine/Out)
---------------------------------------------------------------------------------------------------------
local GetKeyStroke = GetKeyButton:FindFirstChildOfClass("UIStroke")
local DiscordStroke = DiscordButton:FindFirstChildOfClass("UIStroke")
local KeyBoxStroke = KeyBox:FindFirstChildOfClass("UIStroke")
local CloseIcon = CloseButton:FindFirstChildOfClass("ImageLabel")
local MinimizeIcon = MinimizeButton:FindFirstChildOfClass("ImageLabel")

local HoverTargets = {
	{ object = GetKeyButton, enter = { BackgroundTransparency = 0.93 }, leave = { BackgroundTransparency = 0.97 },
	  extra = GetKeyStroke, extraEnter = { Transparency = 0.9 }, extraLeave = { Transparency = 0.94 } },
	{ object = DiscordButton, enter = { BackgroundTransparency = 0.93 }, leave = { BackgroundTransparency = 0.97 },
	  extra = DiscordStroke, extraEnter = { Transparency = 0.9 }, extraLeave = { Transparency = 0.94 } },
	{ object = KeyBox, enter = { BackgroundTransparency = 0.93 }, leave = { BackgroundTransparency = 0.97 },
	  extra = KeyBoxStroke, extraEnter = { Transparency = 0.9 }, extraLeave = { Transparency = 0.94 } },
	{ object = CloseButton, enter = { BackgroundTransparency = 0.95 }, leave = { BackgroundTransparency = 1 },
	  extra = CloseIcon, extraEnter = { ImageTransparency = 0.25 }, extraLeave = { ImageTransparency = 0.4 } },
	{ object = MinimizeButton, enter = { BackgroundTransparency = 0.95 }, leave = { BackgroundTransparency = 1 },
	  extra = MinimizeIcon, extraEnter = { ImageTransparency = 0.25 }, extraLeave = { ImageTransparency = 0.4 } },
	{ object = CheckKeyButton, enter = { BackgroundColor3 = Color3.fromRGB(255, 255, 255) },
	  leave = { BackgroundColor3 = Color3.fromRGB(200, 200, 200) } },
}

-- the original registers every MouseEnter handler first, then every MouseLeave handler
for _, h in ipairs(HoverTargets) do
	task.spawn(function()
		h.object.MouseEnter:Connect(function()
			Tween(h.object, h.enter)
			if h.extra then
				Tween(h.extra, h.extraEnter)
			end
		end)
	end)
end
for _, h in ipairs(HoverTargets) do
	task.spawn(function()
		h.object.MouseLeave:Connect(function()
			Tween(h.object, h.leave)
			if h.extra then
				Tween(h.extra, h.extraLeave)
			end
		end)
	end)
end

---------------------------------------------------------------------------------------------------------
-- "Check Key"
---------------------------------------------------------------------------------------------------------
CheckKeyButton.MouseButton1Click:Connect(function()
	local key = KeyInput.Text:match("^%s*(.-)%s*$") -- trimmed
	if key == "" then
		Notify("Enter a key first!.")
		return
	end

	local status = CheckKey(key)
	if status.code == "KEY_VALID" then
		DestroyUI()
		Notify("Key is correct, Loading the script...")
		SaveKey(key)
		Luarmor.load_script()
	elseif status.code == "KEY_HWID_LOCKED" then
		Players.LocalPlayer:Kick("The key is set to a different HWID")
	elseif status.code == "KEY_INCORRECT" then
		Notify("Key is invalid!")
	else -- KEY_INVALID, KEY_EXPIRED, KEY_BANNED, anything else
		Notify("Key is invalid")
	end
end)

---------------------------------------------------------------------------------------------------------
-- "Get Key" and the Discord button both copy the invite and ask a locally running Discord client to open it
---------------------------------------------------------------------------------------------------------
local function CopyDiscordInvite()
	setclipboard(DISCORD_INVITE)
	Notify("Copied invite to clipboard.")

	-- local Discord RPC endpoint; first available of syn.request / http.request / request
	local request = (syn and syn.request) or (http and http.request) or request
	if request then
		request({
			Url = "http://127.0.0.1:6463/rpc?v=1",
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json",
				Origin = "https://discord.com",
			},
			Body = HttpService:JSONEncode({
				cmd = "INVITE_BROWSER",
				nonce = HttpService:GenerateGUID(false),
				args = { code = DISCORD_RPC_CODE },
			}),
		})
	end
end

DiscordButton.MouseButton1Click:Connect(CopyDiscordInvite)
GetKeyButton.MouseButton1Click:Connect(CopyDiscordInvite)

---------------------------------------------------------------------------------------------------------
-- Intro animation: collapse instantly, then expand with the window made visible
---------------------------------------------------------------------------------------------------------
Window.Visible = false
task.spawn(Collapse)
task.wait(0.31)
task.spawn(Expand)
Window.Visible = true
