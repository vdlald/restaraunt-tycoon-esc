--!strict

local StarterPlayer = game:GetService("StarterPlayer")
local State = require(StarterPlayer.StarterPlayerScripts.Client.State)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local useEffect = React.useEffect
local useState = React.useState

local phaseNames = {
	[0] = "LOBBY — Press P to start",
	[1] = "PREPARATION — Press P to serve",
	[2] = "SERVICE",
	[3] = "VICTORY!",
	[4] = "DEFEAT",
}

local function GameCycleHud()
	local phase, setPhase = useState(State.GamePhase:get())
	local day, setDay = useState(State.GameDay:get())
	local countdown, setCountdown = useState(State.PhaseCountdown:get())
	local guests, setGuests = useState(State.GuestsRemaining:get())
	local serviceTime, setServiceTime = useState(State.ServiceTimeRemaining:get())

	useEffect(function()
		local disconnects = {
			State.GamePhase:on(setPhase),
			State.GameDay:on(setDay),
			State.PhaseCountdown:on(setCountdown),
			State.GuestsRemaining:on(setGuests),
			State.ServiceTimeRemaining:on(setServiceTime),
		}
		return function()
			for _, disconnect in disconnects do
				disconnect()
			end
		end
	end, {})

	local children = {
		Phase = React.createElement("TextLabel", {
			Size = UDim2.fromScale(0.34, 0.055),
			Position = UDim2.fromScale(0.33, 0.03),
			BackgroundTransparency = 0.2,
			BackgroundColor3 = Color3.fromRGB(25, 25, 35),
			TextColor3 = Color3.fromRGB(255, 255, 255),
			Font = Enum.Font.GothamBold,
			TextScaled = true,
			Text = string.format("Day %d/20  |  %s", day, phaseNames[phase] or "UNKNOWN"),
		}),
	}

	if countdown > 0 then
		children.Countdown = React.createElement("TextLabel", {
			Size = UDim2.fromScale(0.2, 0.08),
			Position = UDim2.fromScale(0.4, 0.11),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(255, 220, 90),
			Font = Enum.Font.GothamBlack,
			TextScaled = true,
			Text = tostring(countdown),
		})
	end

	if phase == 2 then
		children.Service = React.createElement("TextLabel", {
			Size = UDim2.fromScale(0.26, 0.05),
			Position = UDim2.fromScale(0.37, 0.11),
			BackgroundTransparency = 0.2,
			BackgroundColor3 = Color3.fromRGB(90, 40, 30),
			TextColor3 = Color3.fromRGB(255, 255, 255),
			Font = Enum.Font.GothamBold,
			TextScaled = true,
			Text = string.format("Guests: %d  |  %ds", guests, serviceTime),
		})
	end

	if phase == 3 or phase == 4 then
		children.Result = React.createElement("TextLabel", {
			Size = UDim2.fromScale(0.5, 0.16),
			Position = UDim2.fromScale(0.25, 0.42),
			BackgroundColor3 = phase == 3 and Color3.fromRGB(40, 120, 55) or Color3.fromRGB(145, 45, 45),
			BackgroundTransparency = 0.1,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			Font = Enum.Font.GothamBlack,
			TextScaled = true,
			Text = phase == 3 and "VICTORY!" or "DEFEAT",
		})
	end

	return React.createElement(React.Fragment, nil, children)
end

return GameCycleHud
