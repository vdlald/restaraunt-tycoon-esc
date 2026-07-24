--!strict

local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local State = require(StarterPlayer.StarterPlayerScripts.Client.State)
local NetClient = require(StarterPlayer.StarterPlayerScripts.Client.NetClient)
local React = require(ReplicatedStorage.Packages.React)
local GamePhase = require(ReplicatedStorage.Shared.GamePhase)
local FurnitureCatalog = require(ReplicatedStorage.Shared.FurnitureCatalog)

local useEffect = React.useEffect
local useState = React.useState

local reasonMessages = {
	[FurnitureCatalog.PurchaseResultReason.NotPreparation] = "Furniture can only be bought during preparation.",
	[FurnitureCatalog.PurchaseResultReason.CountdownActive] = "The service countdown has already started.",
	[FurnitureCatalog.PurchaseResultReason.InsufficientCoins] = "Not enough coins.",
	[FurnitureCatalog.PurchaseResultReason.InvalidFurniture] = "This furniture is unavailable.",
	[FurnitureCatalog.PurchaseResultReason.PlacementActive] = "Finish placing the current furniture first.",
	[FurnitureCatalog.PurchaseResultReason.PlacementFailed] = "Could not start furniture placement.",
}

local function FurnitureStore()
	local isOpen, setIsOpen = useState(State.IsFurnitureStoreOpen:get())
	local phase, setPhase = useState(State.GamePhase:get())
	local countdown, setCountdown = useState(State.PhaseCountdown:get())
	local coins, setCoins = useState(State.Coins:get())
	local message, setMessage = useState("")

	useEffect(function()
		local disconnects = {
			State.IsFurnitureStoreOpen:on(setIsOpen),
			State.GamePhase:on(setPhase),
			State.PhaseCountdown:on(setCountdown),
			State.Coins:on(setCoins),
			State.FurniturePurchaseResult:on(function(result)
				if result and not result.success then
					setMessage(reasonMessages[result.reason] or "Purchase failed.")
				end
			end),
		}
		return function()
			for _, disconnect in disconnects do
				disconnect()
			end
		end
	end, {})

	useEffect(function()
		local connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed or input.KeyCode ~= Enum.KeyCode.B then
				return
			end
			if phase == GamePhase.Preparation and countdown == 0 and State.MovingFurnitureEntity:get() == 0 then
				setMessage("")
				State.IsFurnitureStoreOpen:set(not State.IsFurnitureStoreOpen:get())
			end
		end)
		return function()
			connection:Disconnect()
		end
	end, { phase, countdown })

	if not isOpen or phase ~= GamePhase.Preparation or countdown > 0 then
		return nil
	end

	local products = {
		Layout = React.createElement("UIListLayout", {
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		Title = React.createElement("TextLabel", {
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 0, 34),
			BackgroundTransparency = 1,
			Text = "FURNITURE STORE [B]",
			TextColor3 = Color3.fromRGB(255, 222, 130),
			Font = Enum.Font.GothamBold,
			TextSize = 21,
		}),
	}

	for index, product in FurnitureCatalog.Products do
		local canAfford = coins >= product.Price
		products[product.Id] = React.createElement("TextButton", {
			LayoutOrder = index + 1,
			Size = UDim2.new(1, -16, 0, 38),
			BackgroundColor3 = canAfford and Color3.fromRGB(54, 92, 67) or Color3.fromRGB(75, 55, 55),
			BorderSizePixel = 0,
			Text = string.format("%s — %d coins", product.Name, product.Price),
			TextColor3 = canAfford and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(190, 190, 190),
			Font = Enum.Font.Gotham,
			TextSize = 17,
			AutoButtonColor = canAfford,
			Active = canAfford,
			[React.Event.Activated] = function()
				if canAfford then
					setMessage("")
					NetClient:RequestFurniturePurchase(product.Id)
				end
			end,
		})
	end

	products.Message = React.createElement("TextLabel", {
		LayoutOrder = 100,
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundTransparency = 1,
		Text = message,
		TextWrapped = true,
		TextColor3 = Color3.fromRGB(255, 165, 130),
		Font = Enum.Font.Gotham,
		TextSize = 14,
	})

	return React.createElement("Frame", {
		Size = UDim2.fromOffset(310, 350),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		BackgroundColor3 = Color3.fromRGB(29, 35, 42),
		BorderSizePixel = 0,
	}, products)
end

return FurnitureStore
