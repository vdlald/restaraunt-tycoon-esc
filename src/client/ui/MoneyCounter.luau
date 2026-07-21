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
local function MoneyCounter()
	local money, setMoney = useState(0)

	useEffect(function()
		-- инициализация текущим значением
		setMoney(State.Coins:get())

		-- подписка на изменения
		local disconnectCoins = State.Coins:on(function(newValue)
			setMoney(newValue)
		end)

		-- очистка при размонтировании компонента
		return function()
			disconnectCoins()
		end
	end, {}) -- пустой массив зависимостей = запустить один раз

	return React.createElement("TextLabel", {
		Size = UDim2.fromScale(0.2, 0.08),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(0.98, 0.02),
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		BackgroundTransparency = 0.2,
		TextColor3 = Color3.fromRGB(255, 215, 0),
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		Text = "💰 " .. tostring(money),
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
	})
end

return MoneyCounter
