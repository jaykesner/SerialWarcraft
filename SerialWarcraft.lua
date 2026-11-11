-- Private addon table from the loader. Not a saved variable.
local addonName, SerialWarcraft = ...

local DEFAULT_ANGLE = 150
local OLD_DEFAULT_ANGLE = 60
local DEFAULT_COMMUNITY = "SerialWarcraft"
local DEFAULT_CHARACTER = "Ailene Wuornoz"
local DEFAULT_GLOW_TEXTURE = "Ping4"
local DEFAULT_GLOW_SIZE = 28
local DEFAULT_GLOW_OPACITY = 1
local GLOW_SIZE_MIN = 16
local GLOW_SIZE_MAX = 64
local GLOW_TEXTURES = { "Ping4", "Ping5", "star4", "starburst" }

local glowTextureSet = {}
for _, textureName in ipairs(GLOW_TEXTURES) do
	glowTextureSet[textureName] = true
end

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
	if type(SerialWarcraftDB.community) ~= "string" then
		SerialWarcraftDB.community = DEFAULT_COMMUNITY
	end
	if type(SerialWarcraftDB.character) ~= "string" then
		SerialWarcraftDB.character = DEFAULT_CHARACTER
	end
	if not glowTextureSet[SerialWarcraftDB.glowTexture] then
		SerialWarcraftDB.glowTexture = DEFAULT_GLOW_TEXTURE
	end
	local size = SerialWarcraftDB.glowSize
	if type(size) ~= "number" then
		SerialWarcraftDB.glowSize = DEFAULT_GLOW_SIZE
	else
		SerialWarcraftDB.glowSize = math.max(GLOW_SIZE_MIN, math.min(GLOW_SIZE_MAX, math.floor(size + 0.5)))
	end
	local opacity = SerialWarcraftDB.glowOpacity
	if type(opacity) ~= "number" then
		SerialWarcraftDB.glowOpacity = DEFAULT_GLOW_OPACITY
	else
		SerialWarcraftDB.glowOpacity = math.max(0, math.min(1, math.floor(opacity * 100 + 0.5) / 100))
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
glow:SetSize(28, 28)
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
panel:SetSize(300, 340)
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
close:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 4, 4)

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOP", panel, "TOP", -8, -12)
title:SetJustifyH("CENTER")
title:SetText(C_AddOns.GetAddOnMetadata(addonName, "Title") or addonName)

local function MakeLabel(text, x, y)
	local label = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	label:SetPoint("TOPLEFT", panel, "TOPLEFT", x, y)
	label:SetText(text)
	return label
end

local function MakeEditBox()
	local edit = CreateFrame("EditBox", nil, panel, "BackdropTemplate")
	edit:SetSize(268, 22)
	edit:SetAutoFocus(false)
	edit:SetFontObject(GameFontHighlight)
	edit:SetTextInsets(6, 6, 0, 0)
	edit:SetMaxLetters(64)
	edit:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Buttons\\WHITE8X8",
		edgeSize = 1,
	})
	edit:SetBackdropColor(0, 0, 0, 0.65)
	edit:SetBackdropBorderColor(0.45, 0.4, 0.25, 1)
	edit:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
	end)
	edit:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
	end)
	return edit
end

local function StyleSlider(slider)
	slider:SetOrientation("HORIZONTAL")
	if slider.SetObeyStepOnDrag then
		slider:SetObeyStepOnDrag(true)
	end
	slider:SetSize(268, 16)
	slider:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Buttons\\WHITE8X8",
		edgeSize = 1,
	})
	slider:SetBackdropColor(0.08, 0.08, 0.08, 0.9)
	slider:SetBackdropBorderColor(0.45, 0.4, 0.25, 1)
	slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
	local thumb = slider:GetThumbTexture()
	if thumb then
		thumb:SetSize(22, 22)
	end
end

MakeLabel("Community", 16, -40)
local communityEdit = MakeEditBox()
communityEdit:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -58)

MakeLabel("Character", 16, -88)
local characterEdit = MakeEditBox()
characterEdit:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -106)

MakeLabel("Glow", 16, -136)
local glowChecks = {}
for index, textureName in ipairs(GLOW_TEXTURES) do
	local column = (index - 1) % 2
	local row = math.floor((index - 1) / 2)
	local check = CreateFrame("CheckButton", "SerialWarcraftGlow" .. textureName, panel, "UICheckButtonTemplate")
	check:SetPoint("TOPLEFT", panel, "TOPLEFT", 12 + (column * 146), -154 - (row * 34))
	check.textureName = textureName
	local checkLabel = check.Text or _G[check:GetName() .. "Text"]
	if not checkLabel then
		checkLabel = check:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		checkLabel:SetPoint("LEFT", check, "RIGHT", 0, 0)
	end
	checkLabel:SetFontObject(GameFontHighlightSmall)
	checkLabel:SetText(textureName)
	check:SetHitRectInsets(0, -88, 0, 0)
	glowChecks[index] = check
end

MakeLabel("Size", 16, -236)
local sizeValue = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
sizeValue:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -16, -236)
local sizeSlider = CreateFrame("Slider", nil, panel, "BackdropTemplate")
StyleSlider(sizeSlider)
sizeSlider:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -256)
sizeSlider:SetMinMaxValues(GLOW_SIZE_MIN, GLOW_SIZE_MAX)
sizeSlider:SetValueStep(1)

MakeLabel("Opacity", 16, -282)
local opacityValue = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
opacityValue:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -16, -282)
local opacitySlider = CreateFrame("Slider", nil, panel, "BackdropTemplate")
StyleSlider(opacitySlider)
opacitySlider:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -302)
opacitySlider:SetMinMaxValues(0, 1)
opacitySlider:SetValueStep(0.01)

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

local clubId
local memberId
local focusedClubId
local appliedOpacity

local function ConfiguredCommunity()
	if type(SerialWarcraftDB) == "table" and type(SerialWarcraftDB.community) == "string" and SerialWarcraftDB.community ~= "" then
		return SerialWarcraftDB.community
	end
end

local function ConfiguredCharacter()
	if type(SerialWarcraftDB) == "table" and type(SerialWarcraftDB.character) == "string" and SerialWarcraftDB.character ~= "" then
		return SerialWarcraftDB.character
	end
end

local function PrintLine(text)
	local chat = DEFAULT_CHAT_FRAME
	if chat then
		chat:AddMessage("SerialWarcraft: " .. text)
	end
end

local function MemberIdentity(info)
	local memberName = ConfiguredCharacter()
	local name = info and info.name
	if not memberName or type(name) ~= "string" then
		return nil
	end
	if name == memberName then
		return memberName, nil
	end
	local prefix = memberName .. "-"
	if name:sub(1, #prefix) == prefix then
		local realm = name:sub(#prefix + 1)
		if realm ~= "" then
			return memberName, realm
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

local function ApplyGlowStyle()
	local texture = DEFAULT_GLOW_TEXTURE
	local size = DEFAULT_GLOW_SIZE
	local opacity = DEFAULT_GLOW_OPACITY
	if type(SerialWarcraftDB) == "table" then
		if glowTextureSet[SerialWarcraftDB.glowTexture] then
			texture = SerialWarcraftDB.glowTexture
		end
		if type(SerialWarcraftDB.glowSize) == "number" then
			size = SerialWarcraftDB.glowSize
		end
		if type(SerialWarcraftDB.glowOpacity) == "number" then
			opacity = SerialWarcraftDB.glowOpacity
		end
	end
	glow:SetSize(size, size)
	glowTexture:SetTexture("Interface\\Cooldown\\" .. texture)
	local dim = 0.25 * opacity
	glowBrighten:SetFromAlpha(dim)
	glowBrighten:SetToAlpha(opacity)
	glowDim:SetFromAlpha(opacity)
	glowDim:SetToAlpha(dim)
	if glowAnim:IsPlaying() and appliedOpacity ~= opacity then
		glowAnim:Stop()
		glowAnim:Play()
	elseif not glowAnim:IsPlaying() then
		glow:SetAlpha(opacity)
	end
	appliedOpacity = opacity
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
		if club.name == ConfiguredCommunity() then
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
		local community = ConfiguredCommunity()
		if community then
			PrintLine(community .. " community was not found.")
		else
			PrintLine("Community was not found.")
		end
		return
	end
	if not info then
		local character = ConfiguredCharacter()
		if character then
			PrintLine(character .. " was not found.")
		else
			PrintLine("Character was not found.")
		end
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

local syncingPanel = false

local function FormatOpacity(opacity)
	return string.format("%.2f", opacity)
end

local function SyncGlowChecks()
	for _, check in ipairs(glowChecks) do
		check:SetChecked(check.textureName == SerialWarcraftDB.glowTexture)
	end
end

local function SyncPanel()
	if type(SerialWarcraftDB) ~= "table" then
		return
	end
	syncingPanel = true
	communityEdit:SetText(SerialWarcraftDB.community or "")
	characterEdit:SetText(SerialWarcraftDB.character or "")
	SyncGlowChecks()
	sizeSlider:SetValue(SerialWarcraftDB.glowSize or DEFAULT_GLOW_SIZE)
	sizeValue:SetText(tostring(SerialWarcraftDB.glowSize or DEFAULT_GLOW_SIZE))
	opacitySlider:SetValue(SerialWarcraftDB.glowOpacity or DEFAULT_GLOW_OPACITY)
	opacityValue:SetText(FormatOpacity(SerialWarcraftDB.glowOpacity or DEFAULT_GLOW_OPACITY))
	syncingPanel = false
end

communityEdit:SetScript("OnTextChanged", function(self, userInput)
	if syncingPanel or not userInput then
		return
	end
	EnsureDB()
	local text = self:GetText() or ""
	if SerialWarcraftDB.community == text then
		return
	end
	SerialWarcraftDB.community = text
	RefreshMember()
end)

characterEdit:SetScript("OnTextChanged", function(self, userInput)
	if syncingPanel or not userInput then
		return
	end
	EnsureDB()
	local text = self:GetText() or ""
	if SerialWarcraftDB.character == text then
		return
	end
	SerialWarcraftDB.character = text
	RefreshMember()
end)

for _, check in ipairs(glowChecks) do
	check:SetScript("OnClick", function(self)
		EnsureDB()
		for _, other in ipairs(glowChecks) do
			other:SetChecked(other == self)
		end
		if SerialWarcraftDB.glowTexture ~= self.textureName then
			SerialWarcraftDB.glowTexture = self.textureName
			ApplyGlowStyle()
		end
	end)
end

sizeSlider:SetScript("OnValueChanged", function(_, value)
	if syncingPanel then
		return
	end
	EnsureDB()
	local size = math.max(GLOW_SIZE_MIN, math.min(GLOW_SIZE_MAX, math.floor(value + 0.5)))
	sizeValue:SetText(tostring(size))
	if SerialWarcraftDB.glowSize ~= size then
		SerialWarcraftDB.glowSize = size
		ApplyGlowStyle()
	end
end)

opacitySlider:SetScript("OnValueChanged", function(_, value)
	if syncingPanel then
		return
	end
	EnsureDB()
	local opacity = math.max(0, math.min(1, math.floor(value * 100 + 0.5) / 100))
	opacityValue:SetText(FormatOpacity(opacity))
	if SerialWarcraftDB.glowOpacity ~= opacity then
		SerialWarcraftDB.glowOpacity = opacity
		ApplyGlowStyle()
	end
end)

panel:SetScript("OnShow", SyncPanel)
panel:SetScript("OnHide", function()
	communityEdit:ClearFocus()
	characterEdit:ClearFocus()
end)

SerialWarcraft.frame:SetScript("OnEvent", function(_, event, ...)
	if event == "ADDON_LOADED" then
		local name = ...
		if name ~= addonName then
			return
		end
		EnsureDB()
		UpdatePosition()
		ApplyGlowStyle()
		SyncPanel()
		SerialWarcraft.frame:UnregisterEvent("ADDON_LOADED")
		return
	end
	if event == "PLAYER_LOGIN" then
		EnsureDB()
		UpdatePosition()
		ApplyGlowStyle()
		SyncPanel()
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
