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
button:RegisterForClicks("LeftButtonUp")
button:RegisterForDrag("LeftButton")
button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight", "ADD")
SerialWarcraft.button = button

local icon = button:CreateTexture(nil, "BACKGROUND")
icon:SetSize(20, 20)
icon:SetPoint("TOPLEFT", 7, -5)
icon:SetTexture("Interface\\AddOns\\" .. addonName .. "\\Media\\icon")

local border = button:CreateTexture(nil, "OVERLAY")
border:SetSize(53, 53)
border:SetPoint("TOPLEFT")
border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

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

button:SetScript("OnClick", function(self)
	if self.wasDragged then
		self.wasDragged = false
		return
	end
	TogglePanel()
end)

SerialWarcraft.frame:SetScript("OnEvent", function(_, event, name)
	if event == "ADDON_LOADED" then
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
		SerialWarcraft.frame:UnregisterEvent("PLAYER_LOGIN")
	end
end)
SerialWarcraft.frame:RegisterEvent("ADDON_LOADED")
SerialWarcraft.frame:RegisterEvent("PLAYER_LOGIN")

UpdatePosition()
Minimap:HookScript("OnSizeChanged", UpdatePosition)
