-- Private addon table from the loader. Not a saved variable.
local addonName, SerialWarcraft = ...

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
