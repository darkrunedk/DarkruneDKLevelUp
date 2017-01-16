-- Frames
local playerFrame = CreateFrame("Frame", "DLUPlayerFrame");
local professionFrame = CreateFrame("Frame", "DLUProfessionFrame");

-- Variables
local professionsDetected = false;
local maxLevel = GetMaxPlayerLevel();
local class, classFileName = UnitClass("player");
local factionGroup, factionName = UnitFactionGroup("player");

local expansionProgressionTable = {};
expansionProgressionTable[LE_EXPANSION_CLASSIC] = 58;
expansionProgressionTable[LE_EXPANSION_BURNING_CRUSADE] = 68;
expansionProgressionTable[LE_EXPANSION_WRATH_OF_THE_LICH_KING] = 80;
expansionProgressionTable[LE_EXPANSION_CATACLYSM] = 85;
expansionProgressionTable[LE_EXPANSION_MISTS_OF_PANDARIA] = 90;
expansionProgressionTable[LE_EXPANSION_WARLORDS_OF_DRAENOR] = 100;
expansionProgressionTable[LE_EXPANSION_LEGION] = 110;

-- Setting globals
DLU.player.faction = factionName;

-- Settings
local function getSettings()
	DLUSettings = DLUSettings or {
		partyEnabled = false,
		pvpEnabled = false,
		professionsEnabled = false
	}
end

-- Helper functions
local function getFactionColorId(factionName)
	local factionId = nil;
	
	if (factionGroup == "Horde") then
		factionId = 0;
	elseif (factionGroup == "Alliance") then
		factionId = 1;
	end
	
	return factionId;
end

local function getFactionColor(factionName)
	local factionColorId = getFactionColorId(factionName);
	local factionString = nil;
	if (factionColorId ~= nil) then
		factionString = "|cff" .. DLU.RGBPercToHex(PLAYER_FACTION_COLORS[factionColorId].r, PLAYER_FACTION_COLORS[factionColorId].g, PLAYER_FACTION_COLORS[factionColorId].b) .. factionName .. "|r";
	else
		if (factionName ~= "") then
			factionString = factionName;
		else 
			factionString = factionGroup;
		end
	end
	
	return factionString;
end

-- Player info --
local characterInfo = {
	name = UnitName("player"),
	level = UnitLevel("player"),
	gender = DLU.genderTable[UnitSex("player")],
	class = classFileName,
	classWithColor = "|c" .. RAID_CLASS_COLORS[classFileName].colorStr .. class .. "|r",
	race = UnitRace("player"),
	faction = getFactionColor(factionName),
	realm = GetRealmName(),
	professions = {
		main = nil,
		secondary = nil,
		archaeology = nil,
		fishing = nil,
		cooking = nil,
		firstAid = nil
	}
}

-- Functions

local function getExpansionName()
	local expansion = GetExpansionLevel()+1;
	local expansionTable = {"WoW: Vanilla", "WoW: The Burning Crusade", "WoW: Wrath of the Lich King", "WoW: Cataclysm", "WoW: Mists of Pandaria", "WoW: Warlords of Draenor", "WoW: Legion"};
	
	local expansionName = "Unknown";
	if (expansionTable[expansion] ~= nil) then
		expansionName = expansionTable[expansion];
	end
	
	return expansionName;
end

local function loadProfessions()
	characterInfo.main, characterInfo.secondary, characterInfo.archaeology, characterInfo.fishing, characterInfo.cooking, characterInfo.firstAid = GetProfessions();
	for i = 1, #characterInfo.professions do
		local name, _, rank, maxRank, _, _, _, rankModifier = GetProfessionInfo(item);
		print(name);
	end
end

local function HelloPlayer()
	local text = nil;
	
	local factionExpression = characterInfo.faction;
	if (characterInfo.faction ~= "Neutral") then
		factionExpression = "the " .. factionExpression;
	end
	
	if (characterInfo.level < maxLevel) then
		text = string.format("Hello, %s. You are a level %i %s %s %s from %s. Your current max level is %i (%s).", characterInfo.name, characterInfo.level, characterInfo.gender, characterInfo.race, characterInfo.classWithColor, factionExpression, maxLevel, getExpansionName());
	elseif (characterInfo.level == maxLevel and CanUpgradeExpansion()) then
		text = string.format("Hello, %s. You are a %s %s %s from %s, and you are currently at your max level (level %i). You can upgrade the game to continue your leveling adventure...", characterInfo.name, characterInfo.gender, characterInfo.race, characterInfo.classWithColor, factionExpression, characterInfo.level);
	else
		text = string.format("Hello, %s. You are a %s %s %s from %s, and you are currently at your max level (level %i).", characterInfo.name, characterInfo.gender, characterInfo.race, characterInfo.classWithColor, factionExpression, characterInfo.level);
	end
	print(text);
end

local function playerLevelUp(self, event, ...)
	local newLevel = ...;
	characterInfo.level = newLevel;
	
	local text = nil;
	if (characterInfo.level < maxLevel) then
		local unspentTalentPoints = GetNumUnspentTalents();
		if (unspentTalentPoints > 0) then
			text = string.format("Gratz %s, you are now level %i and you have %i unspent talent points.", DLU.getClassColored(characterInfo.name, classFileName), characterInfo.level, unspentTalentPoints);
		else
			text = string.format("Gratz %s, you are now level %i.", DLU.getClassColored(characterInfo.name, classFileName), characterInfo.level);
		end
	else
		text = string.format("Congratulations %s on reaching your currently available max level (%i) :)", DLU.getClassColored(characterInfo.name, classFileName), characterInfo.level);
	end
	
	local expansionLevel = GetExpansionLevel();
	local index = DLU.tableContains(expansionProgressionTable, characterInfo.level);
	
	if (index ~= false and expansionLevel >= 1) then
		text = text .. " You might want to ";
		
		if (characterInfo.level == expansionProgressionTable[0]) then
			text = text .. "go to Outland";
		elseif (characterInfo.level == expansionProgressionTable[1] and expansionLevel >= 2) then
			text = text .. "go to Northrend";
		elseif (characterInfo.level == expansionProgressionTable[2] and expansionLevel >= 3) then
			text = text .. "begin the Cataclysm quests";
		elseif (characterInfo.level == expansionProgressionTable[3] and expansionLevel >= 4) then
			text = text .. "go to Pandaria";
		elseif (characterInfo.level == expansionProgressionTable[4] and expansionLevel >= 5) then
			text = text .. "go to Draenor";
		elseif (characterInfo.level == expansionProgressionTable[5] and expansionLevel >= 6) then
			text = text .. "go to The Broken Isles";
			
			-- Recommend the zones based on professions
			if (DLUSettings.professionsEnabled) then
				prof1, prof2, archaeology, fishing, cooking, firstAid = GetProfessions();
				if (prof1 ~= nil or prof2 ~= nil) then
					info = "profession";
					if (prof1 ~= nil and prof2 ~= nil) then
						info = info .. "s";
					end
					text = text .. ", Azsuna (for your " .. info .. ")";
				end
			end
		end
		
		text = text .. " now ;-)";
	end
	
	print(text);
end

local function professionLoader()
	if (professionsDetected) then
		loadProfessions();
		professionsDetected = true;
	end
end

-- Events
playerFrame:RegisterEvent("PLAYER_LEVEL_UP");
playerFrame:SetScript("OnEvent", playerLevelUp);

-- Startup Event
if (IsAddOnLoaded(DLU.addonName)) then
	HelloPlayer();
end