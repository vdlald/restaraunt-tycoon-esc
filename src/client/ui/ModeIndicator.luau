--!strict

-- Зависимости
local StarterPlayer = game:GetService("StarterPlayer")
local State = require(StarterPlayer.StarterPlayerScripts.Client.State)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local useState = React.useState
local useEffect = React.useEffect

--
-- Компонент
local function ModeIndicator()
	local isBuildMode, setIsBuildMode = useState(State.BuildModeActive:get())

	useEffect(function()
		local disconnect = State.BuildModeActive:on(function(newValue)
			setIsBuildMode(newValue)
		end)

		return function()
			disconnect()
		end
	end, {})

	return React.createElement("TextLabel", {
		Size = UDim2.fromScale(0.2, 0.08),
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.fromScale(0.02, 0.02),
		BackgroundColor3 = isBuildMode and Color3.fromRGB(60, 40, 20) or Color3.fromRGB(30, 30, 30),
		BackgroundTransparency = 0.2,
		TextColor3 = isBuildMode and Color3.fromRGB(255, 180, 80) or Color3.fromRGB(200, 200, 200),
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		Text = isBuildMode and "🔨 Build Mode" or "🎮 Game Mode",
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
	})
end

return ModeIndicator
