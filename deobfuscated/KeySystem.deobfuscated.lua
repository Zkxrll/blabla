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

local KeySystem = New("ScreenGui")
KeySystem.ResetOnSpawn = true
KeySystem.Parent = GuiParent
KeySystem.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
KeySystem.Name = ""  -- original name: KeySystem

local Window = New("Frame")
Window.Visible = false
Window.Parent = KeySystem
Window.AnchorPoint = Vector2.new(0.5, 0.5)
Window.BorderSizePixel = 0
Window.Position = UDim2.new(0.5, 0, 0.5, 0)
Window.BackgroundTransparency = 0.1
Window.BackgroundColor3 = Color3.fromRGB(9, 9, 9)
Window.AutomaticSize = Enum.AutomaticSize.Y
Window.Size = UDim2.new(0, 540, 0, 0)
Window.Name = ""  -- original name: Window

local WindowUICorner = New("UICorner")
WindowUICorner.Parent = Window
WindowUICorner.CornerRadius = UDim.new(0, 15)
WindowUICorner.Name = ""  -- original name: UICorner

local IgnoreLayout = New("Folder")
IgnoreLayout.Parent = Window
IgnoreLayout.Name = ""  -- original name: IgnoreLayout

local BackgroundImage = New("ImageLabel")
BackgroundImage.ScaleType = Enum.ScaleType.Crop
BackgroundImage.ImageTransparency = 0.9
BackgroundImage.Parent = IgnoreLayout
BackgroundImage.Image = "rbxassetid://82295031952284"
BackgroundImage.Position = UDim2.new(0, -12, 0, -12)
BackgroundImage.ZIndex = -1
BackgroundImage.BackgroundTransparency = 1
BackgroundImage.Size = UDim2.new(1, 24, 1, 24)
BackgroundImage.Name = ""  -- original name: BackgroundImage

local BackgroundImageUICorner = New("UICorner")
BackgroundImageUICorner.Parent = BackgroundImage
BackgroundImageUICorner.CornerRadius = UDim.new(0, 15)
BackgroundImageUICorner.Name = ""  -- original name: UICorner

local WindowUIStroke = New("UIStroke")
WindowUIStroke.Thickness = 1
WindowUIStroke.Transparency = 0.9
WindowUIStroke.Color = Color3.fromRGB(255, 255, 255)
WindowUIStroke.Parent = Window
WindowUIStroke.LineJoinMode = Enum.LineJoinMode.Round
WindowUIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
WindowUIStroke.Name = ""  -- original name: UIStroke

local Topbar = New("Frame")
Topbar.Position = UDim2.new(0, 0, -0.004, 0)
Topbar.Parent = Window
Topbar.BackgroundTransparency = 1
Topbar.AutomaticSize = Enum.AutomaticSize.Y
Topbar.Size = UDim2.new(1, 0, 0, 0)
Topbar.Name = ""  -- original name: Topbar

local LeftLayout = New("Frame")
LeftLayout.Parent = Topbar
LeftLayout.BackgroundTransparency = 1
LeftLayout.Size = UDim2.new(0.75, 0, 1, 0)
LeftLayout.Name = ""  -- original name: LeftLayout

local LeftLayoutHeader = New("Frame")
LeftLayoutHeader.Parent = LeftLayout
LeftLayoutHeader.BackgroundTransparency = 1
LeftLayoutHeader.AutomaticSize = Enum.AutomaticSize.X
LeftLayoutHeader.Size = UDim2.new(0, 0, 1, 0)
LeftLayoutHeader.Name = ""  -- original name: Header

local LeftLayoutHeaderUIListLayout = New("UIListLayout")
LeftLayoutHeaderUIListLayout.Parent = LeftLayoutHeader
LeftLayoutHeaderUIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
LeftLayoutHeaderUIListLayout.Name = ""  -- original name: UIListLayout

local TitleLabel = New("TextLabel")
TitleLabel.FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextTransparency = 0.2
TitleLabel.Text = "Perseus Key System"
TitleLabel.Parent = LeftLayoutHeader
TitleLabel.TextSize = 20
TitleLabel.AutomaticSize = Enum.AutomaticSize.XY
TitleLabel.BackgroundTransparency = 1
TitleLabel.Name = ""  -- original name: Title

local SubtitleLabel = New("TextLabel")
SubtitleLabel.TextWrapped = true
SubtitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
SubtitleLabel.TextTransparency = 0.4
SubtitleLabel.Text = "Complete the key system to unlock the script"
SubtitleLabel.Parent = LeftLayoutHeader
SubtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
SubtitleLabel.FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
SubtitleLabel.TextSize = 14
SubtitleLabel.AutomaticSize = Enum.AutomaticSize.XY
SubtitleLabel.BackgroundTransparency = 1
SubtitleLabel.Name = ""  -- original name: Subtitle

local RightLayout = New("Frame")
RightLayout.Parent = Topbar
RightLayout.BackgroundTransparency = 1
RightLayout.Size = UDim2.new(0.25, 0, 1, 0)
RightLayout.Name = ""  -- original name: RightLayout

local CloseButton = New("TextButton")
CloseButton.LayoutOrder = 999
CloseButton.Parent = RightLayout
CloseButton.Text = ""
CloseButton.BackgroundTransparency = 1
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Name = ""  -- original name: Button

local CloseButtonUICorner = New("UICorner")
CloseButtonUICorner.Parent = CloseButton
CloseButtonUICorner.CornerRadius = UDim.new(0, 8)
CloseButtonUICorner.Name = ""  -- original name: UICorner

local CloseButtonImageLabel = New("ImageLabel")
CloseButtonImageLabel.ScaleType = Enum.ScaleType.Stretch
CloseButtonImageLabel.ImageTransparency = 0.4
CloseButtonImageLabel.Parent = CloseButton
CloseButtonImageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
CloseButtonImageLabel.Image = "rbxassetid://10747384394"
CloseButtonImageLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
CloseButtonImageLabel.BackgroundTransparency = 1
CloseButtonImageLabel.Size = UDim2.new(0, 16, 0, 16)
CloseButtonImageLabel.Name = ""  -- original name: ImageLabel

local MinimizeButton = New("TextButton")
MinimizeButton.LayoutOrder = 998
MinimizeButton.Parent = RightLayout
MinimizeButton.Text = ""
MinimizeButton.BackgroundTransparency = 1
MinimizeButton.Size = UDim2.new(0, 30, 0, 30)
MinimizeButton.Name = ""  -- original name: Button

local MinimizeButtonUICorner = New("UICorner")
MinimizeButtonUICorner.Parent = MinimizeButton
MinimizeButtonUICorner.CornerRadius = UDim.new(0, 8)
MinimizeButtonUICorner.Name = ""  -- original name: UICorner

local MinimizeButtonImageLabel = New("ImageLabel")
MinimizeButtonImageLabel.LayoutOrder = 0
MinimizeButtonImageLabel.ScaleType = Enum.ScaleType.Stretch
MinimizeButtonImageLabel.ImageTransparency = 0.4
MinimizeButtonImageLabel.Parent = MinimizeButton
MinimizeButtonImageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
MinimizeButtonImageLabel.Image = "rbxassetid://10734896206"
MinimizeButtonImageLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
MinimizeButtonImageLabel.BackgroundTransparency = 1
MinimizeButtonImageLabel.Size = UDim2.new(0, 16, 0, 16)
MinimizeButtonImageLabel.Name = ""  -- original name: ImageLabel

local RightLayoutUIListLayout = New("UIListLayout")
RightLayoutUIListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
RightLayoutUIListLayout.FillDirection = Enum.FillDirection.Horizontal
RightLayoutUIListLayout.Parent = RightLayout
RightLayoutUIListLayout.Padding = UDim.new(0, 6)
RightLayoutUIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
RightLayoutUIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
RightLayoutUIListLayout.Name = ""  -- original name: UIListLayout

local TopbarUIListLayout = New("UIListLayout")
TopbarUIListLayout.FillDirection = Enum.FillDirection.Horizontal
TopbarUIListLayout.Parent = Topbar
TopbarUIListLayout.Padding = UDim.new(0, 0)
TopbarUIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
TopbarUIListLayout.Name = ""  -- original name: UIListLayout

local WindowUIListLayout = New("UIListLayout")
WindowUIListLayout.FillDirection = Enum.FillDirection.Horizontal
WindowUIListLayout.Parent = Window
WindowUIListLayout.Padding = UDim.new(0, 10)
WindowUIListLayout.Wraps = true
WindowUIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
WindowUIListLayout.Name = ""  -- original name: UIListLayout

local WindowUIPadding = New("UIPadding")
WindowUIPadding.PaddingTop = UDim.new(0, 12)
WindowUIPadding.PaddingBottom = UDim.new(0, 12)
WindowUIPadding.Parent = Window
WindowUIPadding.PaddingLeft = UDim.new(0, 12)
WindowUIPadding.PaddingRight = UDim.new(0, 12)
WindowUIPadding.Name = ""  -- original name: UIPadding

local LeftBodySize = UDim2.new(0.5, -12, 0, 0)
local LeftContent = New("Frame")
LeftContent.BackgroundTransparency = 1
LeftContent.Position = UDim2.new(0, 0, 0.177, 0)
LeftContent.Parent = Window
LeftContent.ClipsDescendants = true
LeftContent.AutomaticSize = Enum.AutomaticSize.Y
LeftContent.Size = LeftBodySize
LeftContent.Name = ""  -- original name: LeftContent

local LeftContentUIPadding = New("UIPadding")
LeftContentUIPadding.PaddingBottom = UDim.new(0, 1)
LeftContentUIPadding.Parent = LeftContent
LeftContentUIPadding.PaddingLeft = UDim.new(0, 1)
LeftContentUIPadding.Name = ""  -- original name: UIPadding

local Tutorial = New("Frame")
Tutorial.Parent = LeftContent
Tutorial.BackgroundTransparency = 1
Tutorial.AutomaticSize = Enum.AutomaticSize.Y
Tutorial.Size = UDim2.new(1, 0, 0, 130)
Tutorial.Name = ""  -- original name: Tutorial

local TutorialHeader = New("TextLabel")
TutorialHeader.FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
TutorialHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
TutorialHeader.TextTransparency = 0.4
TutorialHeader.Text = "Guide To Get Key"
TutorialHeader.Parent = Tutorial
TutorialHeader.TextXAlignment = Enum.TextXAlignment.Left
TutorialHeader.TextSize = 17
TutorialHeader.BackgroundTransparency = 1
TutorialHeader.AutomaticSize = Enum.AutomaticSize.Y
TutorialHeader.Size = UDim2.new(1, 0, 0, 0)
TutorialHeader.Name = ""  -- original name: Header

local Step1 = New("TextLabel")
Step1.TextWrapped = true
Step1.TextColor3 = Color3.fromRGB(255, 255, 255)
Step1.TextTransparency = 0.6
Step1.Text = "1. Click on the 'Get Key' button (which will copy a link to your clipboard)"
Step1.Parent = Tutorial
Step1.FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
Step1.TextXAlignment = Enum.TextXAlignment.Left
Step1.TextSize = 14
Step1.BackgroundTransparency = 1
Step1.AutomaticSize = Enum.AutomaticSize.Y
Step1.Size = UDim2.new(1, 0, 0, 0)
Step1.Name = ""  -- original name: Step1

local TutorialUIListLayout = New("UIListLayout")
TutorialUIListLayout.Parent = Tutorial
TutorialUIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
TutorialUIListLayout.Padding = UDim.new(0, 3)
TutorialUIListLayout.Name = ""  -- original name: UIListLayout

local TutorialUIPadding = New("UIPadding")
TutorialUIPadding.PaddingBottom = UDim.new(0, 12)
TutorialUIPadding.PaddingTop = UDim.new(0, 2)
TutorialUIPadding.Parent = Tutorial
TutorialUIPadding.Name = ""  -- original name: UIPadding

local Step2 = New("TextLabel")
Step2.TextWrapped = true
Step2.TextColor3 = Color3.fromRGB(255, 255, 255)
Step2.TextTransparency = 0.6
Step2.Text = "2. Open the copied link in your browser and complete the steps"
Step2.Parent = Tutorial
Step2.FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
Step2.TextXAlignment = Enum.TextXAlignment.Left
Step2.TextSize = 14
Step2.BackgroundTransparency = 1
Step2.AutomaticSize = Enum.AutomaticSize.Y
Step2.Size = UDim2.new(1, 0, 0, 0)
Step2.Name = ""  -- original name: Step2

local Step3 = New("TextLabel")
Step3.TextWrapped = true
Step3.TextColor3 = Color3.fromRGB(255, 255, 255)
Step3.TextTransparency = 0.6
Step3.Text = "3. Once the steps are completed, you'll be rewarded a key that you can use here."
Step3.Parent = Tutorial
Step3.FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
Step3.TextXAlignment = Enum.TextXAlignment.Left
Step3.Position = UDim2.new(-0.004, 0, 0.716, 0)
Step3.TextSize = 14
Step3.BackgroundTransparency = 1
Step3.AutomaticSize = Enum.AutomaticSize.Y
Step3.Size = UDim2.new(1, 0, 0, 0)
Step3.Name = ""  -- original name: Step3

local LeftContentUIListLayout = New("UIListLayout")
LeftContentUIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
LeftContentUIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
LeftContentUIListLayout.Parent = LeftContent
LeftContentUIListLayout.Name = ""  -- original name: UIListLayout

local KeyBox = New("Frame")
KeyBox.Parent = LeftContent
KeyBox.BackgroundTransparency = 0.97
KeyBox.Size = UDim2.new(1, 0, 0, 40)
KeyBox.Name = ""  -- original name: Keybox

local KeyBoxUICorner = New("UICorner")
KeyBoxUICorner.Parent = KeyBox
KeyBoxUICorner.CornerRadius = UDim.new(0, 12)
KeyBoxUICorner.Name = ""  -- original name: UICorner

local KeyBoxUIStroke = New("UIStroke")
KeyBoxUIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
KeyBoxUIStroke.Transparency = 0.94
KeyBoxUIStroke.Color = Color3.fromRGB(255, 255, 255)
KeyBoxUIStroke.Parent = KeyBox
KeyBoxUIStroke.Name = ""  -- original name: UIStroke

local KeyInput = New("TextBox")
KeyInput.FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
KeyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
KeyInput.TextTransparency = 0.2
KeyInput.Text = ""
KeyInput.Parent = KeyBox
KeyInput.PlaceholderColor3 = Color3.fromRGB(200, 200, 200)
KeyInput.BackgroundTransparency = 1
KeyInput.TextXAlignment = Enum.TextXAlignment.Left
KeyInput.TextTruncate = Enum.TextTruncate.AtEnd
KeyInput.PlaceholderText = "Key..."
KeyInput.TextSize = 16
KeyInput.Size = UDim2.new(1, 0, 1, 0)
KeyInput.Name = ""  -- original name: TextBox

local KeyInputUIPadding = New("UIPadding")
KeyInputUIPadding.Parent = KeyInput
KeyInputUIPadding.PaddingRight = UDim.new(0, 12)
KeyInputUIPadding.PaddingLeft = UDim.new(0, 12)
KeyInputUIPadding.Name = ""  -- original name: UIPadding

local EyeButton = New("Frame")
EyeButton.AnchorPoint = Vector2.new(1, 0.5)
EyeButton.Position = UDim2.new(1, -4, 0.5, 0)
EyeButton.Parent = KeyBox
EyeButton.BackgroundTransparency = 0.97
EyeButton.Visible = false
EyeButton.Size = UDim2.new(0, 35, 0, 35)
EyeButton.Name = ""  -- original name: Eye

local EyeButtonUICorner = New("UICorner")
EyeButtonUICorner.Parent = EyeButton
EyeButtonUICorner.CornerRadius = UDim.new(0, 12)
EyeButtonUICorner.Name = ""  -- original name: UICorner

local EyeButtonIcon = New("ImageLabel")
EyeButtonIcon.ScaleType = Enum.ScaleType.Stretch
EyeButtonIcon.ImageTransparency = 0.3
EyeButtonIcon.Parent = EyeButton
EyeButtonIcon.AnchorPoint = Vector2.new(0.5, 0.5)
EyeButtonIcon.Image = "rbxassetid://125696236691873"
EyeButtonIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
EyeButtonIcon.BackgroundTransparency = 1
EyeButtonIcon.Size = UDim2.new(0, 23, 0, 23)
EyeButtonIcon.Name = ""  -- original name: Icon

local KeyBoxUIGradient = New("UIGradient")
KeyBoxUIGradient.Rotation = 90
KeyBoxUIGradient.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0.562)})
KeyBoxUIGradient.Parent = KeyBox
KeyBoxUIGradient.Name = ""  -- original name: UIGradient

local RightBodySize = UDim2.new(0.5, 0, 0, 0)
local RightContent = New("Frame")
RightContent.BackgroundTransparency = 1
RightContent.Position = UDim2.new(0, 0, 0.177, 0)
RightContent.Parent = Window
RightContent.ClipsDescendants = true
RightContent.AutomaticSize = Enum.AutomaticSize.Y
RightContent.Size = RightBodySize
RightContent.Name = ""  -- original name: RightContent

local RightContentUIListLayout = New("UIListLayout")
RightContentUIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
RightContentUIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
RightContentUIListLayout.Parent = RightContent
RightContentUIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
RightContentUIListLayout.Name = ""  -- original name: UIListLayout

local ButtonRow = New("Frame")
ButtonRow.Parent = RightContent
ButtonRow.BackgroundTransparency = 1
ButtonRow.Size = UDim2.new(1, 0, 0, 45)
ButtonRow.Name = ""  -- original name: Buttons

local CheckKeyButton = New("TextButton")
CheckKeyButton.LayoutOrder = 1
CheckKeyButton.Size = UDim2.new(0, 0, 0, 40)
CheckKeyButton.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
CheckKeyButton.Parent = ButtonRow
CheckKeyButton.Text = ""
CheckKeyButton.AutomaticSize = Enum.AutomaticSize.X
CheckKeyButton.AutoButtonColor = false
CheckKeyButton.Name = ""  -- original name: Check

local CheckKeyButtonUICorner = New("UICorner")
CheckKeyButtonUICorner.Parent = CheckKeyButton
CheckKeyButtonUICorner.CornerRadius = UDim.new(0, 12)
CheckKeyButtonUICorner.Name = ""  -- original name: UICorner

local CheckKeyLabel = New("TextLabel")
CheckKeyLabel.FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
CheckKeyLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
CheckKeyLabel.Parent = CheckKeyButton
CheckKeyLabel.Text = "Check Key"
CheckKeyLabel.TextSize = 17
CheckKeyLabel.BackgroundTransparency = 1
CheckKeyLabel.AutomaticSize = Enum.AutomaticSize.X
CheckKeyLabel.Size = UDim2.new(0, 0, 1, 0)
CheckKeyLabel.Name = ""  -- original name: Check

local CheckKeyButtonUIPadding = New("UIPadding")
CheckKeyButtonUIPadding.Parent = CheckKeyButton
CheckKeyButtonUIPadding.PaddingRight = UDim.new(0, 12)
CheckKeyButtonUIPadding.PaddingLeft = UDim.new(0, 12)
CheckKeyButtonUIPadding.Name = ""  -- original name: UIPadding

local GetKeyButton = New("TextButton")
GetKeyButton.Size = UDim2.new(0, 0, 0, 40)
GetKeyButton.BackgroundTransparency = 0.97
GetKeyButton.Parent = ButtonRow
GetKeyButton.Text = ""
GetKeyButton.AutomaticSize = Enum.AutomaticSize.X
GetKeyButton.AutoButtonColor = false
GetKeyButton.Name = ""  -- original name: Keybox

local GetKeyButtonUICorner = New("UICorner")
GetKeyButtonUICorner.Parent = GetKeyButton
GetKeyButtonUICorner.CornerRadius = UDim.new(0, 12)
GetKeyButtonUICorner.Name = ""  -- original name: UICorner

local GetKeyLabel = New("TextLabel")
GetKeyLabel.FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
GetKeyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
GetKeyLabel.TextTransparency = 0.3
GetKeyLabel.Text = "Get Key"
GetKeyLabel.Parent = GetKeyButton
GetKeyLabel.TextSize = 17
GetKeyLabel.BackgroundTransparency = 1
GetKeyLabel.AutomaticSize = Enum.AutomaticSize.X
GetKeyLabel.Size = UDim2.new(0, 0, 1, 0)
GetKeyLabel.Name = ""  -- original name: Check

local GetKeyButtonUIPadding = New("UIPadding")
GetKeyButtonUIPadding.Parent = GetKeyButton
GetKeyButtonUIPadding.PaddingRight = UDim.new(0, 12)
GetKeyButtonUIPadding.PaddingLeft = UDim.new(0, 12)
GetKeyButtonUIPadding.Name = ""  -- original name: UIPadding

local GetKeyButtonUIStroke = New("UIStroke")
GetKeyButtonUIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
GetKeyButtonUIStroke.Transparency = 0.94
GetKeyButtonUIStroke.Color = Color3.fromRGB(255, 255, 255)
GetKeyButtonUIStroke.Parent = GetKeyButton
GetKeyButtonUIStroke.Name = ""  -- original name: UIStroke

local GetKeyButtonUIGradient = New("UIGradient")
GetKeyButtonUIGradient.Rotation = 45
GetKeyButtonUIGradient.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.569), NumberSequenceKeypoint.new(1, 0)})
GetKeyButtonUIGradient.Parent = GetKeyButton
GetKeyButtonUIGradient.Name = ""  -- original name: UIGradient

local ButtonRowUIListLayout = New("UIListLayout")
ButtonRowUIListLayout.FillDirection = Enum.FillDirection.Horizontal
ButtonRowUIListLayout.Parent = ButtonRow
ButtonRowUIListLayout.Padding = UDim.new(0, 8)
ButtonRowUIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ButtonRowUIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
ButtonRowUIListLayout.Name = ""  -- original name: UIListLayout

local DiscordButton = New("TextButton")
DiscordButton.BackgroundTransparency = 0.97
DiscordButton.Position = UDim2.new(-0.041, 0, 0, 0)
DiscordButton.Parent = ButtonRow
DiscordButton.Text = ""
DiscordButton.Size = UDim2.new(0, 40, 0, 40)
DiscordButton.AutoButtonColor = false
DiscordButton.Name = ""  -- original name: Discord

local DiscordButtonUICorner = New("UICorner")
DiscordButtonUICorner.Parent = DiscordButton
DiscordButtonUICorner.CornerRadius = UDim.new(0, 12)
DiscordButtonUICorner.Name = ""  -- original name: UICorner

local DiscordButtonUIStroke = New("UIStroke")
DiscordButtonUIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
DiscordButtonUIStroke.Transparency = 0.94
DiscordButtonUIStroke.Color = Color3.fromRGB(255, 255, 255)
DiscordButtonUIStroke.Parent = DiscordButton
DiscordButtonUIStroke.Name = ""  -- original name: UIStroke

local DiscordButtonIcon = New("ImageLabel")
DiscordButtonIcon.ScaleType = Enum.ScaleType.Stretch
DiscordButtonIcon.ImageTransparency = 0.3
DiscordButtonIcon.Parent = DiscordButton
DiscordButtonIcon.AnchorPoint = Vector2.new(0.5, 0.5)
DiscordButtonIcon.Image = "rbxassetid://111352598650120"
DiscordButtonIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
DiscordButtonIcon.BackgroundTransparency = 1
DiscordButtonIcon.Size = UDim2.new(0, 22, 0, 22)
DiscordButtonIcon.Name = ""  -- original name: Icon

local DiscordButtonUIGradient = New("UIGradient")
DiscordButtonUIGradient.Rotation = 45
DiscordButtonUIGradient.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.569), NumberSequenceKeypoint.new(1, 0)})
DiscordButtonUIGradient.Parent = DiscordButton
DiscordButtonUIGradient.Name = ""  -- original name: UIGradient

local ChangelogScroll = New("ScrollingFrame")
ChangelogScroll.LayoutOrder = -1
ChangelogScroll.ScrollBarImageTransparency = 1
ChangelogScroll.ScrollBarThickness = 3
ChangelogScroll.Parent = RightContent
ChangelogScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
ChangelogScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ChangelogScroll.BackgroundTransparency = 1
ChangelogScroll.BorderSizePixel = 0
ChangelogScroll.Size = UDim2.new(1, 0, 0, 130)
ChangelogScroll.Name = ""  -- original name: Changelogs

local AnnouncementBox = New("Frame")
AnnouncementBox.Parent = ChangelogScroll
AnnouncementBox.BackgroundTransparency = 1
AnnouncementBox.AutomaticSize = Enum.AutomaticSize.Y
AnnouncementBox.Size = UDim2.new(1, 0, 0, 0)
AnnouncementBox.Name = ""  -- original name: Announcement

local AnnouncementBoxHeader = New("TextLabel")
AnnouncementBoxHeader.LayoutOrder = -1
AnnouncementBoxHeader.FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.Medium)
AnnouncementBoxHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
AnnouncementBoxHeader.TextTransparency = 0.4
AnnouncementBoxHeader.Text = "Changelogs"
AnnouncementBoxHeader.Parent = AnnouncementBox
AnnouncementBoxHeader.TextXAlignment = Enum.TextXAlignment.Left
AnnouncementBoxHeader.TextSize = 20
AnnouncementBoxHeader.BackgroundTransparency = 1
AnnouncementBoxHeader.AutomaticSize = Enum.AutomaticSize.Y
AnnouncementBoxHeader.Size = UDim2.new(1, 0, 0, 0)
AnnouncementBoxHeader.Name = ""  -- original name: Header

local AnnouncementBoxHeader2 = New("TextLabel")
AnnouncementBoxHeader2.LayoutOrder = -1
AnnouncementBoxHeader2.FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.Medium)
AnnouncementBoxHeader2.TextColor3 = Color3.fromRGB(255, 255, 255)
AnnouncementBoxHeader2.TextTransparency = 0.4
AnnouncementBoxHeader2.Text = "Key System Update"
AnnouncementBoxHeader2.Parent = AnnouncementBox
AnnouncementBoxHeader2.TextXAlignment = Enum.TextXAlignment.Left
AnnouncementBoxHeader2.TextSize = 17
AnnouncementBoxHeader2.BackgroundTransparency = 1
AnnouncementBoxHeader2.AutomaticSize = Enum.AutomaticSize.Y
AnnouncementBoxHeader2.Size = UDim2.new(1, 0, 0, 0)
AnnouncementBoxHeader2.Name = ""  -- original name: Header2

local AnnouncementBoxChangelog = New("TextLabel")
AnnouncementBoxChangelog.LayoutOrder = 1
AnnouncementBoxChangelog.TextWrapped = false
AnnouncementBoxChangelog.TextColor3 = Color3.fromRGB(255, 255, 255)
AnnouncementBoxChangelog.TextTransparency = 0.6
AnnouncementBoxChangelog.Text = "Key System Update \n\tAdded a dragbar similar to the script ui\n\tAdded key saving\n\tFixed a few bugs\n"
AnnouncementBoxChangelog.Parent = AnnouncementBox
AnnouncementBoxChangelog.FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
AnnouncementBoxChangelog.TextXAlignment = Enum.TextXAlignment.Left
AnnouncementBoxChangelog.Position = UDim2.new(-0.004, 0, 0.716, 0)
AnnouncementBoxChangelog.TextSize = 14
AnnouncementBoxChangelog.BackgroundTransparency = 1
AnnouncementBoxChangelog.AutomaticSize = Enum.AutomaticSize.Y
AnnouncementBoxChangelog.Size = UDim2.new(1, 0, 0, 0)
AnnouncementBoxChangelog.Name = ""  -- original name: Changelog

local AnnouncementBoxHeader22 = New("TextLabel")
AnnouncementBoxHeader22.LayoutOrder = 2
AnnouncementBoxHeader22.FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.Medium)
AnnouncementBoxHeader22.TextColor3 = Color3.fromRGB(255, 255, 255)
AnnouncementBoxHeader22.TextTransparency = 0.4
AnnouncementBoxHeader22.Text = "Rivals Beta Release"
AnnouncementBoxHeader22.Parent = AnnouncementBox
AnnouncementBoxHeader22.TextXAlignment = Enum.TextXAlignment.Left
AnnouncementBoxHeader22.TextSize = 17
AnnouncementBoxHeader22.BackgroundTransparency = 1
AnnouncementBoxHeader22.AutomaticSize = Enum.AutomaticSize.Y
AnnouncementBoxHeader22.Size = UDim2.new(1, 0, 0, 0)
AnnouncementBoxHeader22.Name = ""  -- original name: Header2

local AnnouncementBoxChangelog2 = New("TextLabel")
AnnouncementBoxChangelog2.LayoutOrder = 3
AnnouncementBoxChangelog2.TextWrapped = false
AnnouncementBoxChangelog2.TextColor3 = Color3.fromRGB(255, 255, 255)
AnnouncementBoxChangelog2.TextTransparency = 0.6
AnnouncementBoxChangelog2.Text = "Dashboard\n    Discord invite\n    Script version\n    Executor name\n    Game name\n    Server region\n    Player count\n    Job ID\n    Game ID\n\nPersonalization\n    Theme selection\n    Apply selected theme\n    Corner glow customization:\n        Top Left\n        Top Right\n        Bottom Left\n        Bottom Right\n        Visibility\n        Transparency\n        Color\n    Animation selection\n    Load animation\n    Unload animation\n    Available animation: `Parallax`\n\nBlatant\n\n    Aimbot\n        Enable/disable\n        Quick toggle keybind\n        Team check\n        Wall check\n        Require input hold\n        Input hold keybind\n        Target:\n            Head\n            HumanoidRootPart\n            Random\n        Smoothness: `0–1`\n\n    Triggerbot\n        Enable/disable\n        Quick toggle keybind\n        Team check\n        Katana check\n        Target:\n            Head\n            Body\n            Any\n        Shoot method:\n            Blatant\n            Input\n            Click\n            Hold\n        Delay: `0–1`\n\n    Projectile Aura\n        Enable/disable\n        Team check\n        Maximum pitch angle: `1–90`\n        Pitch override: `-1–90`\n        Y offset: `-10–10`\n\nRagebot\n\n    Magic Bullet\n        Enable/disable\n        Quick toggle keybind\n        Desync\n        Team check\n        Wall check\n        Katana check\n\n    Knife Aura \n        Enable/disable\n        Quick toggle keybind\n        Team check\n        Desync\n        Auto equip knife\n        Auto pick weapons\n        Auto backstab\n\nGame Visuals\n\n    Tracer Effect\n        Enable/disable\n        Local-sided tracers\n        Rainbow tracers\n        Duration: `1–1000`\n        Tracer color\n\n    Hit Sounds\n        Enable/disable\n        Random sounds\n        Volume: `0–1`\n        Sound selection:\n            Neverlose\n            Rust Headshot\n            Sparkle\n            Windows Critical\n            Bow Hit\n            Bonnie Blue\n            Among Us\n\nScreen Effects\n\n    Third Person\n        Enable/disable third-person view\n\n    Anti Flashbang\n        Enable/disable flashbang protection\n\n    Aspect Ratio\n        Enable/disable\n        X ratio: `0–1.2`\n        Y ratio: `0–1.2`\n\n    Crosshair\n        Enable/disable custom crosshair\n        Hide in-game crosshair\n        Spin crosshair\n        Spin speed: `0–20`\n        Line length: `1–50`\n        Line thickness: `1–10`\n        Line gap: `0–30`\n        Top line color\n        Bottom line color\n        Left line color\n        Right line color\n\nESP\n\n    Box ESP\n        Enable/disable\n        Team check\n        Maximum distance: `100–5000`\n        Box gradient\n        Box color 1\n        Box color 2\n        Spin gradient\n        Gradient spin speed: `10–360`\n        Box fill\n        Fill transparency: `0–1`\n        Show names\n        Name color\n        Show distances\n        Distance color\n        Health bar\n\n    Tracer ESP\n        Enable/disable\n        Team check\n        Maximum distance: `100–5000`\n        Tracer origin:\n            Bottom\n            Middle\n            Top\n        Start color\n        End color\n\n    Skeleton ESP\n        Enable/disable\n        Team check\n        Head circle\n        Transparency: `0–1`\n        Maximum distance: `100–5000`\n        Skeleton color\n        Head circle color\n\n    Chams ESP\n        Enable/disable\n        Team check\n        Fill transparency: `0–1`\n        Outline transparency: `0–1`\n        Maximum distance: `100–5000`\n        Fill color\n        Outline color\n\nPlayer\n\n    Player Behaviour\n\n        WalkSpeed\n            Custom WalkSpeed\n            Speed: `0–1000`\n\n        JumpPower\n            Custom JumpPower\n            Power: `0–1000`\n\n        Mass\n            Custom Mass\n            Mass: `-500–500`\n\n        Gravity\n            Custom Gravity\n            Gravity: `1–500`\n\nWorld\n\n    Atmosphere\n        Enable/disable\n        Density: `0–1`\n        Offset: `0–1`\n        Haze: `0–10`\n        Glare: `0–10`\n        Color\n        Decay color\n\n    Lighting\n        Custom lighting\n        Clock time: `0–24`\n        Brightness: `0–10`\n        Exposure compensation: `-5–5`\n        Ambient color\n        Outdoor ambient color\n        Top color shift\n        Bottom color shift\n\n        Bloom Effect\n            Enable/disable\n            Intensity: `0–5`\n            Size: `0–56`\n            Threshold: `0–5`\n\n        Blur Effect\n            Enable/disable\n            Size: `0–56`\n\n        Color Correction\n            Enable/disable\n            Brightness: `-1–1`\n            Contrast: `-1–1`\n            Saturation: `-1–1`\n            Tint color\n\n    Viewmodel\n\n        Left Arm\n            Left arm customization\n            Rainbow colors\n            Arm transparency: `0–1`\n            Shirt transparency: `0–1`\n            Arm color\n            Outline transparency: `0–1`\n            Fill transparency: `0–1`\n            Outline color\n            Fill color\n\n        Right Arm\n            Right arm customization\n            Rainbow colors\n            Arm transparency: `0–1`\n            Shirt transparency: `0–1`\n            Arm color\n            Outline transparency: `0–1`\n            Fill transparency: `0–1`\n            Outline color\n            Fill color\n\n        Gun Viewmodel\n            Gun customization\n            Rainbow colors\n            Gun transparency: `0–1`\n            Gun color\n            Gun material\n            Outline transparency: `0–1`\n            Fill transparency: `0–1`\n            Outline color\n            Fill color\n"
AnnouncementBoxChangelog2.Parent = AnnouncementBox
AnnouncementBoxChangelog2.FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
AnnouncementBoxChangelog2.TextXAlignment = Enum.TextXAlignment.Left
AnnouncementBoxChangelog2.Position = UDim2.new(-0.004, 0, 0.716, 0)
AnnouncementBoxChangelog2.TextSize = 14
AnnouncementBoxChangelog2.BackgroundTransparency = 1
AnnouncementBoxChangelog2.AutomaticSize = Enum.AutomaticSize.Y
AnnouncementBoxChangelog2.Size = UDim2.new(1, 0, 0, 0)
AnnouncementBoxChangelog2.Name = ""  -- original name: Changelog

local AnnouncementBoxUIListLayout = New("UIListLayout")
AnnouncementBoxUIListLayout.Parent = AnnouncementBox
AnnouncementBoxUIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
AnnouncementBoxUIListLayout.Padding = UDim.new(0, 3)
AnnouncementBoxUIListLayout.Name = ""  -- original name: UIListLayout

local AnnouncementBoxUIPadding = New("UIPadding")
AnnouncementBoxUIPadding.PaddingBottom = UDim.new(0, 12)
AnnouncementBoxUIPadding.PaddingTop = UDim.new(0, 2)
AnnouncementBoxUIPadding.Parent = AnnouncementBox
AnnouncementBoxUIPadding.Name = ""  -- original name: UIPadding

local ChangelogScrollUIListLayout = New("UIListLayout")
ChangelogScrollUIListLayout.Parent = ChangelogScroll
ChangelogScrollUIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ChangelogScrollUIListLayout.Padding = UDim.new(0, 0)
ChangelogScrollUIListLayout.Name = ""  -- original name: UIListLayout

local DragBar = New("Frame")
DragBar.Visible = true
DragBar.Active = false
DragBar.Selectable = false
DragBar.AnchorPoint = Vector2.new(0.5, 0)
DragBar.SizeConstraint = Enum.SizeConstraint.RelativeXY
DragBar.ZIndex = 1
DragBar.AutomaticSize = Enum.AutomaticSize.None
DragBar.Size = UDim2.new(0.3, 0, 0, 6)
DragBar.ClipsDescendants = false
DragBar.BorderColor3 = Color3.fromRGB(0, 0, 0)
DragBar.BorderMode = Enum.BorderMode.Outline
DragBar.Parent = IgnoreLayout
DragBar.Ignore = true
DragBar.Rotation = 0
DragBar.Transparency = 0.9
DragBar.Position = UDim2.new(0.5, 0, -0.125, 0)
DragBar.BorderSizePixel = 0
DragBar.BackgroundTransparency = 0.6
DragBar.LayoutOrder = 0
DragBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
DragBar.Name = ""  -- original name: DragBar

local DragBarUICorner = New("UICorner")
DragBarUICorner.Parent = DragBar
DragBarUICorner.CornerRadius = UDim.new(1, 0)
DragBarUICorner.Name = ""  -- original name: UICorner


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
