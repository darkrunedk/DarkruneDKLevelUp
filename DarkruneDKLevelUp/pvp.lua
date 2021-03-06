-- Variables --
local rogueAbilities = {408, 703, 1833, 6770};
local rogueAbilitiesNum = #rogueAbilities;
local rogueAbilitiesNames = {};

local druidAbilities = {1822, 22570}
local druidAbilitiesNum = #druidAbilities;
local druidAbilitiesNames = {};

local pvpFrame = CreateFrame("Frame", "DarkrunePVPFrame");
local settingsFrame = CreateFrame("Frame", "DarkruneSettingsFrame");
local shouted = false;
local expiration = nil;

local prefix = "DLU";
local chatprefix = "<" .. prefix .."> ";

-- Settings functions
local function loadAbilityNames(abilityNum, abilities, abilityNames)
	for i = 1, abilityNum do
		local name = GetSpellInfo(abilities[i]);
		abilityNames[i] = name;
	end
end

-- Settings
local function loadSettings()
	DLUSettings = DLUSettings or {
		partyEnabled = false,
		pvpEnabled = false,
		professionsEnabled = false
	}
end

local function loadTables()
	loadAbilityNames(rogueAbilitiesNum, rogueAbilities, rogueAbilitiesNames);
	loadAbilityNames(druidAbilitiesNum, druidAbilities, druidAbilitiesNames);
end

-- functions
local function checkForDebuffRogue()
	for i = 1, rogueAbilitiesNum do
		if (UnitDebuff("player", rogueAbilitiesNames[i])) then
			local _, _, _, _, _, _, expirationTime, _, _, _, spellId = UnitDebuff("player", rogueAbilitiesNames[i]);
			expiration = expirationTime;
			link = GetSpellLink(spellId);
			
			if (shouted == false) then
				SendChatMessage(chatprefix .. "Rogue detected! (got hit by " .. link ..")", "YELL");
				shouted = true;
			end
		end
	end
	
	if (expiration == GetTime()) then
		shouted = false;
		expiration = nil;
	end
end

local function checkForDebuffDruid()
	for i = 1, druidAbilitiesNum do
		if (UnitDebuff("player", druidAbilitiesNames[i])) then
			local _, _, _, _, _, _, expirationTime, _, _, _, spellId = UnitDebuff("player", druidAbilitiesNames[i]);
			expiration = expirationTime;
			link = GetSpellLink(spellId);
			
			if (shouted == false) then
				SendChatMessage(chatprefix .. "Druid detected! (got hit by " .. link ..")", "YELL");
				shouted = true;
			end
		end
	end
	
	if (expiration == GetTime()) then
		shouted = false;
		expiration = nil;
	end
end

local function checkForDebuffs()
	if (DLUSettings.pvpEnabled and UnitInBattleground("player")) then
		checkForDebuffDruid();
		checkForDebuffRogue();
	end
end

-- Adding event --
settingsFrame:RegisterEvent("PLAYER_LOGIN");
settingsFrame:SetScript("OnEvent", function()
loadSettings();
loadTables();

pvpFrame:RegisterEvent("UNIT_AURA");
pvpFrame:SetScript("OnEvent", checkForDebuffs);

settingsFrame:UnregisterEvent("PLAYER_LOGIN");
end)