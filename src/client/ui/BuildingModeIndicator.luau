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
local function BuildingModeIndicator()
	local isEnabled, setIsEnabled = useState(State.IsInBuildingMode:get())

	useEffect(function()
		local disconnect = State.IsInBuildingMode:on(function(newValue)
			setIsEnabled(newValue)
		end)

		return function()
			disconnect()
		end
	end, {})

	if not isEnabled then
		return nil
	end

	return React.createElement("TextLabel", {
		Size = UDim2.fromScale(0.2, 0.05),
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.fromScale(0.02, 0.12),
		BackgroundColor3 = Color3.fromRGB(30, 100, 30),
		BackgroundTransparency = 0.2,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		Text = "BUILD MODE",
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
	})
end

return BuildingModeIndicator
