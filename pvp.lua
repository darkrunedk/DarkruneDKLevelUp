-- Variables --
local rogueAbilities = {6770, 408, 1833};
local rogueAbilitiesNum = #rogueAbilities;
local rogueAbilitiesNames = {};

for i = 1, rogueAbilitiesNum do
	local name = GetSpellInfo(rogueAbilities[i]);
	rogueAbilitiesNames[i] = name;
end

local pvpFrame = CreateFrame("Frame", "DarkrunePVPFrame");
local settingsFrame = CreateFrame("Frame", "DarkruneSettingsFrame");
local shouted = false;
local expiration = nil;

-- Settings
function loadSettings()
	DLUSettings = DLUSettings or {
		partyEnabled = false,
		pvpEnabled = false,
		professionsEnabled = false
	}
end

-- functions
function checkForDebuff()
	if (DLUSettings.pvpEnabled) then
		for i = 1, rogueAbilitiesNum do
			if (UnitDebuff("player", rogueAbilitiesNames[i])) then
				local _, _, _, _, _, _, expirationTime = UnitDebuff("player", rogueAbilitiesNames[i]);
				expiration = expirationTime;
				
				if (shouted == false) then
					SendChatMessage("Rogue nearby!", "YELL");
					shouted = true;
				end
			end
		end
		
		if (expiration == GetTime()) then
			shouted = false;
			expiration = nil;
		end
	end
end

-- Adding event --
settingsFrame:RegisterEvent("PLAYER_LOGIN");
settingsFrame:SetScript("OnEvent", function()
loadSettings();

pvpFrame:RegisterEvent("UNIT_AURA");
pvpFrame:SetScript("OnEvent", checkForDebuff);

settingsFrame:UnregisterEvent("PLAYER_LOGIN");
end)