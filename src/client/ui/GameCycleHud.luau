--!strict

local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")
local State = require(StarterPlayer.StarterPlayerScripts.Client.State)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local GamePhase = require(ReplicatedStorage.Shared.GamePhase)

local useEffect = React.useEffect
local useState = React.useState

local phaseNames = {
	[GamePhase.Lobby] = "LOBBY — Press P to start",
	[GamePhase.Preparation] = "PREPARATION — Press P to serve",
	[GamePhase.Service] = "SERVICE",
	[GamePhase.Victory] = "VICTORY!",
	[GamePhase.Defeat] = "DEFEAT",
}

local function GameCycleHud()
	local phase, setPhase = useState(State.GamePhase:get())
	local day, setDay = useState(State.GameDay:get())
	local countdown, setCountdown = useState(State.PhaseCountdown:get())
	local guests, setGuests = useState(State.GuestsRemaining:get())
	local serviceTime, setServiceTime = useState(State.ServiceTimeRemaining:get())
	local receipt, setReceipt = useState(State.DayReceipt:get())
	local receiptClosed, setReceiptClosed = useState(false)

	useEffect(function()
		local disconnects = {
			State.GamePhase:on(setPhase),
			State.GameDay:on(setDay),
			State.PhaseCountdown:on(setCountdown),
			State.GuestsRemaining:on(setGuests),
			State.ServiceTimeRemaining:on(setServiceTime),
			State.DayReceipt:on(function(nextReceipt)
				setReceipt(nextReceipt)
				setReceiptClosed(false)
			end),
		}
		return function()
			for _, disconnect in disconnects do
				disconnect()
			end
		end
	end, {})

	useEffect(function()
		if not receipt or receiptClosed then
			return function() end
		end

		local connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if not gameProcessed and input.KeyCode == Enum.KeyCode.C then
				setReceiptClosed(true)
			end
		end)
		return function()
			connection:Disconnect()
		end
	end, { phase, receipt, receiptClosed })

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

	if phase == GamePhase.Service then
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

	if receipt and not receiptClosed then
		local receiptLines = {
			Layout = React.createElement("UIListLayout", {
				Padding = UDim.new(0, 5),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			Title = React.createElement("TextLabel", {
				LayoutOrder = 1,
				Size = UDim2.new(1, 0, 0, 34),
				BackgroundTransparency = 1,
				Text = "RESTAURANT RECEIPT",
				TextColor3 = Color3.fromRGB(50, 45, 38),
				Font = Enum.Font.RobotoMono,
				TextSize = 24,
				ZIndex = 4,
			}),
			Day = React.createElement("TextLabel", {
				LayoutOrder = 2,
				Size = UDim2.new(1, 0, 0, 24),
				BackgroundTransparency = 1,
				Text = string.format("Day %d — thank you!", receipt.day),
				TextColor3 = Color3.fromRGB(80, 72, 60),
				Font = Enum.Font.RobotoMono,
				TextSize = 16,
				ZIndex = 4,
			}),
			Divider = React.createElement("Frame", {
				LayoutOrder = 3,
				Size = UDim2.new(1, 0, 0, 1),
				BackgroundColor3 = Color3.fromRGB(110, 100, 85),
				BorderSizePixel = 0,
				ZIndex = 4,
			}),
		}

		for index, line in receipt.dishes do
			receiptLines[`Dish{index}`] = React.createElement("TextLabel", {
				LayoutOrder = 3 + index,
				Size = UDim2.new(1, 0, 0, 24),
				BackgroundTransparency = 1,
				Text = string.format("%dx %-14s %4d coins", line.count, line.dishName, line.earned),
				TextColor3 = Color3.fromRGB(50, 45, 38),
				Font = Enum.Font.RobotoMono,
				TextSize = 17,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 4,
			})
		end

		receiptLines.Total = React.createElement("TextLabel", {
			LayoutOrder = 100,
			Size = UDim2.new(1, 0, 0, 30),
			BackgroundTransparency = 1,
			Text = string.format("TOTAL: %d coins", receipt.total),
			TextColor3 = Color3.fromRGB(35, 100, 55),
			Font = Enum.Font.RobotoMono,
			TextSize = 21,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 4,
		})
		receiptLines.Close = React.createElement("TextButton", {
			LayoutOrder = 101,
			Size = UDim2.new(1, 0, 0, 30),
			BackgroundColor3 = Color3.fromRGB(95, 85, 70),
			BorderSizePixel = 0,
			Text = "CLOSE [C]",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			Font = Enum.Font.RobotoMono,
			TextSize = 17,
			ZIndex = 4,
			[React.Event.Activated] = function()
				setReceiptClosed(true)
			end,
		})

		children.Receipt = React.createElement("Frame", {
			Size = UDim2.fromOffset(390, 270),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(245, 238, 215),
			BorderSizePixel = 0,
			ZIndex = 3,
		}, receiptLines)
	end

	if phase == GamePhase.Victory or phase == GamePhase.Defeat then
		children.Result = React.createElement("TextLabel", {
			Size = UDim2.fromScale(0.5, 0.16),
			Position = UDim2.fromScale(0.25, 0.42),
			BackgroundColor3 = phase == GamePhase.Victory and Color3.fromRGB(40, 120, 55)
				or Color3.fromRGB(145, 45, 45),
			BackgroundTransparency = 0.1,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			Font = Enum.Font.GothamBlack,
			TextScaled = true,
			Text = phase == GamePhase.Victory and "VICTORY!" or "DEFEAT",
		})
	end

	return React.createElement(React.Fragment, nil, children)
end

return GameCycleHud
