--!strict

local StarterPlayer = game:GetService("StarterPlayer")
local State = require(StarterPlayer.StarterPlayerScripts.Client.State)

type Indicator = {
	gui: BillboardGui,
	fill: Frame,
	label: TextLabel,
}

local indicators: { [number]: Indicator } = {}

local function findAdornee(entityId: number): BasePart?
	for _, instance in workspace:GetDescendants() do
		if instance:GetAttribute("entityId") == entityId then
			if instance:IsA("BasePart") then
				return instance
			end
			return instance:FindFirstChildWhichIsA("BasePart", true)
		end
	end
	return nil
end

local function createIndicator(entityId: number, adornee: BasePart): Indicator
	local gui = Instance.new("BillboardGui")
	gui.Name = "IngredientProcessIndicator"
	gui.Adornee = adornee
	gui.AlwaysOnTop = true
	gui.Size = UDim2.fromOffset(120, 24)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 2, 0)
	gui.Parent = workspace

	local background = Instance.new("Frame")
	background.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	background.BorderSizePixel = 0
	background.Size = UDim2.fromScale(1, 1)
	background.Parent = gui

	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = Color3.fromRGB(255, 183, 0)
	fill.BorderSizePixel = 0
	fill.Size = UDim2.fromScale(0, 1)
	fill.Parent = background

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Size = UDim2.fromScale(1, 1)
	label.Parent = background

	local indicator = { gui = gui, fill = fill, label = label }
	indicators[entityId] = indicator
	return indicator
end

State.IngredientProcessStates:on(function(states: { [number]: State.IngredientProcessState })
	for entityId, indicator in indicators do
		if not states[entityId] then
			indicator.gui:Destroy()
			indicators[entityId] = nil
		end
	end

	for entityId, processState in states do
		local indicator = indicators[entityId]
		if not indicator then
			local adornee = findAdornee(entityId)
			if adornee then
				indicator = createIndicator(entityId, adornee)
			end
		end
		if indicator then
			indicator.fill.Size = UDim2.fromScale(math.clamp(processState.progress, 0, 1), 1)
			indicator.label.Text = `{math.floor(processState.progress * 100)}%  x{processState.participantCount}`
		end
	end
end)

return {}
