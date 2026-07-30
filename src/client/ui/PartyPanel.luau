--!strict

local StarterPlayer = game:GetService("StarterPlayer")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetClient = require(StarterPlayer.StarterPlayerScripts.Client.NetClient)
local State = require(StarterPlayer.StarterPlayerScripts.Client.State)
local React = require(ReplicatedStorage.Packages.React)

local useEffect = React.useEffect
local useState = React.useState

local function PartyPanel()
	local party, setParty = useState(State.Party:get())
	local friends, setFriends = useState(State.PartyFriends:get())
	local invites, setInvites = useState(State.PartyInvites:get())
	local message, setMessage = useState(State.PartyMessage:get())
	local startPending, setStartPending = useState(State.PartyStartPending:get())

	useEffect(function()
		local disconnects = {
			State.Party:on(setParty),
			State.PartyFriends:on(setFriends),
			State.PartyInvites:on(setInvites),
			State.PartyMessage:on(setMessage),
			State.PartyStartPending:on(setStartPending),
		}
		return function()
			for _, disconnect in disconnects do
				disconnect()
			end
		end
	end, {})

	local children = {
		Layout = React.createElement(
			"UIListLayout",
			{ Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }
		),
		Title = React.createElement("TextLabel", {
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 0, 30),
			BackgroundTransparency = 1,
			Text = party.inParty and `PARTY ({#party.members}/4)` or "PARTY",
			TextColor3 = Color3.new(1, 1, 1),
			Font = Enum.Font.GothamBold,
			TextSize = 20,
		}),
	}

	if not party.inParty then
		children.Create = React.createElement("TextButton", {
			LayoutOrder = 2,
			Size = UDim2.new(1, 0, 0, 30),
			BackgroundColor3 = Color3.fromRGB(55, 135, 80),
			Text = "CREATE PARTY",
			TextColor3 = Color3.new(1, 1, 1),
			Font = Enum.Font.GothamBold,
			TextSize = 14,
			[React.Event.Activated] = function()
				NetClient:CreateParty()
			end,
		})
	end

	for index, member in party.members do
		children[`Member{index}`] = React.createElement("TextLabel", {
			LayoutOrder = 10 + index,
			Size = UDim2.new(1, 0, 0, 24),
			BackgroundTransparency = 1,
			Text = (member.isLeader and "★ " or "• ") .. member.displayName,
			TextColor3 = Color3.fromRGB(230, 230, 230),
			Font = Enum.Font.Gotham,
			TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		if party.canKick and not member.isLeader then
			children[`Kick{index}`] = React.createElement("TextButton", {
				LayoutOrder = 30 + index,
				Size = UDim2.new(1, 0, 0, 24),
				BackgroundColor3 = Color3.fromRGB(135, 60, 60),
				Text = `REMOVE {member.displayName}`,
				TextColor3 = Color3.new(1, 1, 1),
				Font = Enum.Font.Gotham,
				TextSize = 12,
				[React.Event.Activated] = function()
					NetClient:KickFromParty(member.userId)
				end,
			})
		end
	end

	if party.canStart then
		children.Start = React.createElement("TextButton", {
			LayoutOrder = 50,
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundColor3 = if startPending then Color3.fromRGB(80, 95, 85) else Color3.fromRGB(50, 145, 85),
			Text = if startPending then "STARTING..." else "START MATCH",
			Active = not startPending,
			TextColor3 = Color3.new(1, 1, 1),
			Font = Enum.Font.GothamBold,
			TextSize = 15,
			[React.Event.Activated] = function()
				if State.PartyStartPending:get() then
					return
				end
				State.PartyStartPending:set(true)
				NetClient:StartPartyMatch()
			end,
		})
	end
	if party.canLeave then
		children.Leave = React.createElement("TextButton", {
			LayoutOrder = 51,
			Size = UDim2.new(1, 0, 0, 28),
			BackgroundColor3 = Color3.fromRGB(115, 70, 70),
			Text = "LEAVE PARTY",
			TextColor3 = Color3.new(1, 1, 1),
			Font = Enum.Font.Gotham,
			TextSize = 13,
			[React.Event.Activated] = function()
				NetClient:LeaveParty()
			end,
		})
	end

	if party.canInvite then
		for index, friend in friends do
			if friend.canInvite then
				children[`Friend{index}`] = React.createElement("TextButton", {
					LayoutOrder = 60 + index,
					Size = UDim2.new(1, 0, 0, 26),
					BackgroundColor3 = Color3.fromRGB(55, 80, 125),
					Text = `INVITE {friend.displayName}`,
					TextColor3 = Color3.new(1, 1, 1),
					Font = Enum.Font.Gotham,
					TextSize = 12,
					[React.Event.Activated] = function()
						NetClient:InviteToParty(friend.userId)
					end,
				})
			end
		end
	end

	for index, invite in invites do
		children[`Invite{index}`] = React.createElement("TextButton", {
			LayoutOrder = 100 + index,
			Size = UDim2.new(1, 0, 0, 28),
			BackgroundColor3 = Color3.fromRGB(90, 85, 155),
			Text = `JOIN {invite.inviterDisplayName}'S PARTY`,
			TextColor3 = Color3.new(1, 1, 1),
			Font = Enum.Font.Gotham,
			TextSize = 12,
			[React.Event.Activated] = function()
				NetClient:AcceptPartyInvite(invite.partyId)
			end,
		})
		children[`Decline{index}`] = React.createElement("TextButton", {
			LayoutOrder = 120 + index,
			Size = UDim2.new(1, 0, 0, 22),
			BackgroundColor3 = Color3.fromRGB(90, 60, 60),
			Text = "DECLINE",
			TextColor3 = Color3.new(1, 1, 1),
			Font = Enum.Font.Gotham,
			TextSize = 11,
			[React.Event.Activated] = function()
				NetClient:DeclinePartyInvite(invite.partyId)
			end,
		})
	end
	if message ~= "" then
		children.Message = React.createElement("TextLabel", {
			LayoutOrder = 200,
			Size = UDim2.new(1, 0, 0, 30),
			BackgroundTransparency = 1,
			Text = message,
			TextColor3 = Color3.fromRGB(255, 225, 125),
			Font = Enum.Font.Gotham,
			TextSize = 12,
			TextWrapped = true,
		})
	end

	return React.createElement("Frame", {
		Size = UDim2.fromOffset(260, 430),
		Position = UDim2.new(0, 18, 0, 85),
		BackgroundColor3 = Color3.fromRGB(25, 27, 38),
		BackgroundTransparency = 0.12,
		BorderSizePixel = 0,
	}, children)
end

return PartyPanel
