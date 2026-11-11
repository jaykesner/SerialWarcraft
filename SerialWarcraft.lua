-- Private addon table from the loader. Not a saved variable.
local addonName, SerialWarcraft = ...

local DEFAULT_ANGLE = 150
local OLD_DEFAULT_ANGLE = 60

SerialWarcraft.frame = CreateFrame("Frame")

local function PrintLoaded()
	local version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "0.1.0"
	local chat = DEFAULT_CHAT_FRAME
	if chat then
		chat:AddMessage("SerialWarcraft " .. version .. " loaded.")
	end
end

SLASH_SERIALWARCRAFT1 = "/swc"
SLASH_SERIALWARCRAFT2 = "/serialwarcraft"

SlashCmdList["SERIALWARCRAFT"] = function()
	PrintLoaded()
end

local function EnsureDB()
	if type(SerialWarcraftDB) ~= "table" then
		SerialWarcraftDB = {}
	end
	local angle = SerialWarcraftDB.angle
	if type(angle) ~= "number" or angle == OLD_DEFAULT_ANGLE then
		SerialWarcraftDB.angle = DEFAULT_ANGLE
	end
end

local button = CreateFrame("Button", nil, Minimap)
button:SetSize(31, 31)
button:SetFrameStrata("MEDIUM")
button:SetFrameLevel(Minimap:GetFrameLevel() + 8)
button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
button:RegisterForDrag("LeftButton")
button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight", "ADD")
SerialWarcraft.button = button

local icon = button:CreateTexture(nil, "BACKGROUND")
icon:SetSize(20, 20)
icon:SetPoint("TOPLEFT", 7, -5)
icon:SetTexture("Interface\\AddOns\\" .. addonName .. "\\Media\\icon-face")

local border = button:CreateTexture(nil, "OVERLAY")
border:SetSize(53, 53)
border:SetPoint("TOPLEFT")
border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

local glow = CreateFrame("Frame", nil, button)
glow:SetSize(46, 46)
glow:SetPoint("CENTER", icon, "CENTER", 0, 0)
glow:SetFrameLevel(button:GetFrameLevel() + 1)
glow:Hide()
local glowTexture = glow:CreateTexture(nil, "OVERLAY")
glowTexture:SetAllPoints()
glowTexture:SetTexture("Interface\\Cooldown\\Ping4")
glowTexture:SetBlendMode("ADD")
glowTexture:SetVertexColor(1, 0.82, 0.35)
local glowAnim = glow:CreateAnimationGroup()
glowAnim:SetLooping("REPEAT")
local glowBrighten = glowAnim:CreateAnimation("Alpha")
glowBrighten:SetOrder(1)
glowBrighten:SetFromAlpha(0.25)
glowBrighten:SetToAlpha(1)
glowBrighten:SetDuration(0.8)
glowBrighten:SetSmoothing("IN_OUT")
local glowDim = glowAnim:CreateAnimation("Alpha")
glowDim:SetOrder(2)
glowDim:SetFromAlpha(1)
glowDim:SetToAlpha(0.25)
glowDim:SetDuration(0.8)
glowDim:SetSmoothing("IN_OUT")

local panel = CreateFrame("Frame", "SerialWarcraftPanel", UIParent, "BackdropTemplate")
panel:SetSize(176, 36)
panel:SetPoint("CENTER")
panel:SetFrameStrata("DIALOG")
panel:EnableMouse(true)
panel:SetClampedToScreen(true)
panel:SetBackdrop({
	bgFile = "Interface\\Buttons\\WHITE8X8",
	edgeFile = "Interface\\Buttons\\WHITE8X8",
	edgeSize = 1,
})
panel:SetBackdropColor(0, 0, 0, 0.85)
panel:SetBackdropBorderColor(0.78, 0.64, 0.25, 1)
panel:Hide()
SerialWarcraft.panel = panel

local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
close:SetPoint("RIGHT", panel, "RIGHT", 2, 0)

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
title:SetPoint("LEFT", 12, 0)
title:SetPoint("RIGHT", close, "LEFT", 4, 0)
title:SetJustifyH("CENTER")
title:SetText(C_AddOns.GetAddOnMetadata(addonName, "Title") or addonName)

table.insert(UISpecialFrames, "SerialWarcraftPanel")

local function UpdatePosition()
	local angle = DEFAULT_ANGLE
	if type(SerialWarcraftDB) == "table" and type(SerialWarcraftDB.angle) == "number" then
		angle = SerialWarcraftDB.angle
	end
	local rad = math.rad(angle)
	local radius = (Minimap:GetWidth() / 2) + 5
	button:ClearAllPoints()
	button:SetPoint("CENTER", Minimap, "CENTER", math.cos(rad) * radius, math.sin(rad) * radius)
end

local function TogglePanel()
	if panel:IsShown() then
		panel:Hide()
	else
		panel:Show()
	end
end

button:SetScript("OnMouseDown", function(self, mouseButton)
	if mouseButton == "LeftButton" then
		self.wasDragged = false
	end
end)

button:SetScript("OnDragStart", function(self)
	self.wasDragged = true
	EnsureDB()
	self:SetScript("OnUpdate", function()
		local mx, my = Minimap:GetCenter()
		if not mx or not my then
			return
		end
		local scale = Minimap:GetEffectiveScale()
		local cx, cy = GetCursorPosition()
		cx, cy = cx / scale, cy / scale
		SerialWarcraftDB.angle = math.deg(math.atan2(cy - my, cx - mx)) % 360
		UpdatePosition()
	end)
end)

button:SetScript("OnDragStop", function(self)
	self:SetScript("OnUpdate", nil)
end)

local CLUB_NAME = "SerialWarcraft"
local MEMBER_NAME = "Ailene Wuornoz"
local clubId
local memberId
local focusedClubId

local function PrintLine(text)
	local chat = DEFAULT_CHAT_FRAME
	if chat then
		chat:AddMessage("SerialWarcraft: " .. text)
	end
end

local function MemberIdentity(info)
	local name = info and info.name
	if type(name) ~= "string" then
		return nil
	end
	if name == MEMBER_NAME then
		return MEMBER_NAME, nil
	end
	local prefix = MEMBER_NAME .. "-"
	if name:sub(1, #prefix) == prefix then
		local realm = name:sub(#prefix + 1)
		if realm ~= "" then
			return MEMBER_NAME, realm
		end
	end
end

local function InviteName(info)
	local name, realm = MemberIdentity(info)
	if not name then
		return nil
	end
	if realm then
		return name .. "-" .. realm
	end
	return name
end

local function IsInOurGroup(info)
	local name, realm = MemberIdentity(info)
	if not name then
		return false
	end
	if UnitInParty(name) or UnitInRaid(name) then
		return true
	end
	if realm then
		local fullName = name .. "-" .. realm
		if UnitInParty(fullName) or UnitInRaid(fullName) then
			return true
		end
	end
	local function UnitMatches(unit)
		if not UnitExists(unit) then
			return false
		end
		local unitName, unitRealm = UnitName(unit)
		if unitName ~= name then
			return false
		end
		if realm and unitRealm and unitRealm ~= "" and unitRealm ~= realm then
			return false
		end
		return true
	end
	if IsInRaid() then
		for i = 1, GetNumGroupMembers() do
			if UnitMatches("raid" .. i) then
				return true
			end
		end
	else
		for i = 1, GetNumSubgroupMembers() do
			if UnitMatches("party" .. i) then
				return true
			end
		end
	end
	return false
end

local function IsOnline(info)
	if not info or not Enum or not Enum.ClubMemberPresence then
		return false
	end
	local presence = info.presence
	return presence == Enum.ClubMemberPresence.Online or presence == Enum.ClubMemberPresence.OnlineMobile
end

local function MemberInfo()
	if not clubId or not memberId or not C_Club or not C_Club.GetMemberInfo then
		return nil
	end
	return C_Club.GetMemberInfo(clubId, memberId)
end

local function UpdateGlow()
	local info = MemberInfo()
	if info and IsOnline(info) and not IsInOurGroup(info) then
		glow:Show()
		if not glowAnim:IsPlaying() then
			glowAnim:Play()
		end
	else
		glowAnim:Stop()
		glow:Hide()
	end
end

local function FindClub()
	if not C_Club or not C_Club.GetSubscribedClubs then
		return nil
	end
	local clubs = C_Club.GetSubscribedClubs()
	if not clubs then
		return nil
	end
	for _, club in ipairs(clubs) do
		if club.name == CLUB_NAME then
			return club.clubId
		end
	end
end

local function FindMember(id)
	if not C_Club.GetClubMembers or not C_Club.GetMemberInfo then
		return nil
	end
	local members = C_Club.GetClubMembers(id)
	if not members then
		return nil
	end
	for _, idInClub in ipairs(members) do
		local info = C_Club.GetMemberInfo(id, idInClub)
		if MemberIdentity(info) then
			return idInClub
		end
	end
end

local function RefreshMember()
	local foundClub = FindClub()
	clubId = foundClub
	SerialWarcraft.clubId = foundClub
	if not foundClub then
		memberId = nil
		SerialWarcraft.memberId = nil
		UpdateGlow()
		return
	end
	-- One subscribe so member and presence events arrive. Not a poll.
	if focusedClubId ~= foundClub and C_Club.FocusMembers then
		C_Club.FocusMembers(foundClub)
		focusedClubId = foundClub
	end
	local foundMember = FindMember(foundClub)
	memberId = foundMember
	SerialWarcraft.memberId = foundMember
	UpdateGlow()
end

local function InviteMember(info)
	local unit = InviteName(info)
	if not unit then
		return
	end
	if C_PartyInfo and C_PartyInfo.InviteUnit then
		C_PartyInfo.InviteUnit(unit)
	else
		InviteUnit(unit)
	end
end

local function ToggleLoot()
	if not UnitIsGroupLeader("player") then
		PrintLine("Only the group leader can change loot.")
		return
	end
	if not C_PartyInfo or not C_PartyInfo.GetLootMethod or not C_PartyInfo.SetLootMethod or not Enum or not Enum.LootMethod then
		return
	end
	local method = C_PartyInfo.GetLootMethod()
	if method == Enum.LootMethod.Group then
		C_PartyInfo.SetLootMethod(Enum.LootMethod.Freeforall)
	elseif method == Enum.LootMethod.Freeforall then
		C_PartyInfo.SetLootMethod(Enum.LootMethod.Group)
	end
end

local function LeftClick()
	if not clubId or not memberId then
		RefreshMember()
	end
	local info = MemberInfo()
	if not clubId then
		PrintLine("SerialWarcraft community was not found.")
		return
	end
	if not info then
		PrintLine("Ailene Wuornoz was not found.")
		return
	end
	if not IsInOurGroup(info) then
		InviteMember(info)
		return
	end
	ToggleLoot()
end

button:SetScript("OnClick", function(self, mouseButton)
	if mouseButton == "RightButton" then
		TogglePanel()
		return
	end
	if mouseButton ~= "LeftButton" then
		return
	end
	if self.wasDragged then
		self.wasDragged = false
		return
	end
	LeftClick()
end)

SerialWarcraft.frame:SetScript("OnEvent", function(_, event, ...)
	if event == "ADDON_LOADED" then
		local name = ...
		if name ~= addonName then
			return
		end
		EnsureDB()
		UpdatePosition()
		SerialWarcraft.frame:UnregisterEvent("ADDON_LOADED")
		return
	end
	if event == "PLAYER_LOGIN" then
		EnsureDB()
		UpdatePosition()
		RefreshMember()
		SerialWarcraft.frame:UnregisterEvent("PLAYER_LOGIN")
		return
	end
	if event == "GROUP_ROSTER_UPDATE" then
		UpdateGlow()
		return
	end
	if event == "CLUB_MEMBER_PRESENCE_UPDATED" then
		local eventClubId, eventMemberId = ...
		if clubId and memberId and eventClubId == clubId and eventMemberId == memberId then
			UpdateGlow()
		elseif not memberId then
			RefreshMember()
		end
		return
	end
	local eventClubId, eventMemberId = ...
	if event == "CLUB_MEMBER_REMOVED" and clubId and eventClubId == clubId and eventMemberId == memberId then
		memberId = nil
		SerialWarcraft.memberId = nil
	end
	if not clubId or not eventClubId or eventClubId == clubId then
		RefreshMember()
	end
end)
SerialWarcraft.frame:RegisterEvent("ADDON_LOADED")
SerialWarcraft.frame:RegisterEvent("PLAYER_LOGIN")
SerialWarcraft.frame:RegisterEvent("CLUB_STREAMS_LOADED")
SerialWarcraft.frame:RegisterEvent("CLUB_MEMBER_ADDED")
SerialWarcraft.frame:RegisterEvent("CLUB_MEMBER_REMOVED")
SerialWarcraft.frame:RegisterEvent("CLUB_MEMBER_UPDATED")
SerialWarcraft.frame:RegisterEvent("CLUB_MEMBER_PRESENCE_UPDATED")
SerialWarcraft.frame:RegisterEvent("GROUP_ROSTER_UPDATE")

UpdatePosition()
Minimap:HookScript("OnSizeChanged", UpdatePosition)
