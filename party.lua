-- Variables --
local maxLevel = GetMaxPlayerLevel();
local partyFrame = CreateFrame("Frame", "DarkrunePartyFrame");
local settingsFrame = CreateFrame("Frame", "DarkruneSettingsFrame");

-- Settings
function loadSettings()
	DLUSettings = DLUSettings or {
		partyEnabled = false,
		pvpEnabled = false,
		professionsEnabled = false
	}
end

-- Important functions --
function partyLevelUp(self, event, unitID)
	if (UnitInParty(unitID) and UnitPlayerControlled(unitID) and not UnitIsUnit(unitID, "player") and not IsInRaid() and DLUSettings.partyEnabled) then
		local partyMemberName = UnitName(unitID);
		local InInstanceGroup = IsInGroup(LE_PARTY_CATEGORY_INSTANCE);
		
		local randomCongratz = {"Gratz, %s", "Gz, %s", "Keep it up, %s"};
		
		local congratzString = string.format(randomCongratz[math.random(#randomCongratz)], partyMemberName);
		
		if (InInstanceGroup) then
			SendChatMessage(congratzString, "INSTANCE_CHAT");
		elseif (IsInGroup()) then
			SendChatMessage(congratzString, "PARTY");
		end
	end
end

-- Adding event --
settingsFrame:RegisterEvent("PLAYER_LOGIN");
settingsFrame:SetScript("OnEvent", function()
loadSettings();

partyFrame:RegisterEvent("UNIT_LEVEL");
partyFrame:SetScript("OnEvent", partyLevelUp);

settingsFrame:UnregisterEvent("PLAYER_LOGIN");
end)