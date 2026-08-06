local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local UIListLayout = Instance.new("UIListLayout")

ScreenGui.Name = "DeltaSimpleGui"
ScreenGui.Parent = (gethui and gethui()) or LocalPlayer:WaitForChild("PlayerGui")

MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
MainFrame.Position = UDim2.new(0.05, 0, 0.1, 0)
MainFrame.Size = UDim2.new(0, 180, 0, 130)
MainFrame.Active = true
MainFrame.Draggable = true

Title.Name = "Title"
Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Font = Enum.Font.SourceSansBold
Title.Text = "Delta Simple Script"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16.000

UIListLayout.Parent = MainFrame
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 5)

local function createButton(name, text, layoutOrder)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Parent = MainFrame
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    button.Size = UDim2.new(0.9, 0, 0, 35)
    button.Position = UDim2.new(0.05, 0, 0, 0)
    button.Font = Enum.Font.SourceSans
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 14.000
    button.LayoutOrder = layoutOrder
    return button
end

local speedEnabled = false
local jumpEnabled = false

local speedButton = createButton("SpeedBtn", "Speed: OFF (Normal)", 1)
local jumpButton = createButton("JumpBtn", "Jump: OFF (Normal)", 2)

speedButton.MouseButton1Click:Connect(function()
    speedEnabled = not speedEnabled
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    
    if humanoid then
        if speedEnabled then
            humanoid.WalkSpeed = 50
            speedButton.Text = "Speed: ON (Fast)"
            speedButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        else
            humanoid.WalkSpeed = 16
            speedButton.Text = "Speed: OFF (Normal)"
            speedButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        end
    end
end)

jumpButton.MouseButton1Click:Connect(function()
    jumpEnabled = not jumpEnabled
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    
    if humanoid then
        if jumpEnabled then
            humanoid.JumpPower = 100
            jumpButton.Text = "Jump: ON (High)"
            jumpButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        else
            humanoid.JumpPower = 50
            jumpButton.Text = "Jump: OFF (Normal)"
            jumpButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        end
    end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    local humanoid = char:WaitForChild("Humanoid")
    if speedEnabled then humanoid.WalkSpeed = 50 end
    if jumpEnabled then humanoid.JumpPower = 100 end
end)