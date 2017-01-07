-- variables --
local addOnName = "DarkruneDKLevelUp";
local addOnNameWithColor = GetAddOnMetadata(addOnName, "Title");
local _, _, _, uiVersion = GetBuildInfo();
local mountTable = {
	waterMounts = {},
	pvpMounts = {}
};

local maxLevel = GetMaxPlayerLevel();
local class, classFileName = UnitClass("player");
local factionGroup, factionName = UnitFactionGroup("player");
local genderTable = {"Unknown", "Male", "Female"};

local expansionProgressionTable = {};
expansionProgressionTable[LE_EXPANSION_CLASSIC] = 58;
expansionProgressionTable[LE_EXPANSION_BURNING_CRUSADE] = 68;
expansionProgressionTable[LE_EXPANSION_WRATH_OF_THE_LICH_KING] = 80;
expansionProgressionTable[LE_EXPANSION_CATACLYSM] = 85;
expansionProgressionTable[LE_EXPANSION_MISTS_OF_PANDARIA] = 90;
expansionProgressionTable[LE_EXPANSION_WARLORDS_OF_DRAENOR] = 100;
expansionProgressionTable[LE_EXPANSION_LEGION] = 110;

-- Frames
local playerFrame = CreateFrame("Frame", "DarkrunePlayerFrame");
local settingsFrame = CreateFrame("Frame", "DarkruneSettingsFrame");

-- Settings
function getSettings()
	DLUSettings = DLUSettings or {
		partyEnabled = false,
		pvpEnabled = false,
		professionsEnabled = false
	}
end

function changePartyOption(partyEnabledOption)
	if (partyEnabledOption) then
		DLUSettings.partyEnabled = true;
	 else 
		DLUSettings.partyEnabled = false;
	 end
end

function changePvpOption(pvpEnabledOption)
	if (pvpEnabledOption) then
		DLUSettings.pvpEnabled = true;
	else
		DLUSettings.pvpEnabled = false;
	end
end

function changeProfessionOption(professionsEnabledOption)
	if (professionsEnabledOption) then
		DLUSettings.professionsEnabled = true;
	else
		DLUSettings.professionsEnabled = false
	end
end

function colorizeString(text, colorType)
	if (colorType == "red") then
		return "|cffCC0000" .. text .. "|r";
	elseif (colorType == "green") then
		return "|cff00CC00" .. text .. "|r";
	else
		return text;
	end
end

-- Important functions --
function getFactionColorId(factionName)
	local factionId = nil;
	
	if (factionGroup == "Horde") then
		factionId = 0;
	elseif (factionGroup == "Alliance") then
		factionId = 1;
	end
	
	return factionId;
end

local function RGBPercToHex(r, g, b)
	r = r <= 1 and r >= 0 and r or 0
	g = g <= 1 and g >= 0 and g or 0
	b = b <= 1 and b >= 0 and b or 0
	return string.format("%02x%02x%02x", r*255, g*255, b*255)
end

local function getFactionColor(factionName)
	local factionColorId = getFactionColorId(factionName);
	local factionString = nil;
	if (factionColorId ~= nil) then
		factionString = "|cff" .. RGBPercToHex(PLAYER_FACTION_COLORS[factionColorId].r, PLAYER_FACTION_COLORS[factionColorId].g, PLAYER_FACTION_COLORS[factionColorId].b) .. factionName .. "|r";
	else
		if (factionName ~= "") then
			factionString = factionName;
		else 
			factionString = factionGroup;
		end
	end
	
	return factionString;
end

local function itemColorString(num, text)
	local color = ITEM_QUALITY_COLORS[num];
	local result = color.hex .. text .. "|r";
	return result;
end

-- Player info --
local characterInfo = {
	name = UnitName("player"),
	level = UnitLevel("player"),
	gender = genderTable[UnitSex("player")],
	class = classFileName,
	classWithColor = "|c" .. RAID_CLASS_COLORS[classFileName].colorStr .. class .. "|r",
	race = UnitRace("player"),
	faction = getFactionColor(factionName),
	realm = GetRealmName(),
	prof1 = nil,
	prof1Name = nil,
	prof2 = nil,
	prof2Name = nil
}

-- Function tables --
local function tableContains(tableToCheck, element)
	for i = 0, #tableToCheck do
		if (tableToCheck[i] == element) then
			return i;
		end
	end
	
	return false;
end

-- Semi important functions --
function ArtifactXpLeft()
	local artifactId,_, artifactName, spendPower, power, currentTraits = C_ArtifactUI.GetEquippedArtifactInfo();
	if spendPower ~= nill then
		local _, artifactLink = GetItemInfo(artifactId);
		local traitsWaitingForSpending, currentPower, powerForNextTrait = MainMenuBar_GetNumArtifactTraitsPurchasableFromXP(currentTraits, power);
		local apNeeded = powerForNextTrait - currentPower;
		local apPercentGained = math.floor((currentPower / powerForNextTrait) * 100);
		local apPercentNeeded = 100 - apPercentGained;
		local currentRank = currentTraits + traitsWaitingForSpending;
		local text = "You need " .. apNeeded .. " Artifact Power (" .. apPercentNeeded .. "%) to get " .. artifactLink .. " to rank: " .. (currentRank + 1);
		return text;
	end
	
	return false;
end

function xpLeft()
	local text = nil;
	local expansionLevel = GetExpansionLevel();
	if (characterInfo.level == maxLevel) then
		text = "You are currently the highest level you can be, congratz :)";
	else
		local nextLevel = characterInfo.level+1;
		local xpToNextLevel = (UnitXPMax("player") - UnitXP("player"));
		local xpRested = GetXPExhaustion();
		
		local xpPercentageGained = math.floor((UnitXP("player") / UnitXPMax("player")) * 100);
		local xpPercentageNeeded = 100 - xpPercentageGained;
		
		local xpDisabled = IsXPUserDisabled();
		
		if (xpDisabled) then
			text = "You can't get more xp, because your xp has been disabled.";
		else
			text = "You need " .. xpToNextLevel .. " xp (" .. xpPercentageNeeded .. "%) to get to level " .. nextLevel ..".";
			if (xpRested ~= nil) then
				text = text .. "You have " .. xpRested .. " rested xp already.";
			end
		end
	end
	
	if (expansionLevel >= 6) then
		local apXpLeft = ArtifactXpLeft();
		if (apXpLeft ~= false and characterInfo.level == maxLevel) then
			text = apXpLeft;
		elseif (apXpLeft ~= false) then
			text = text .. "\n" .. apXpLeft;
		end
	end
	
	print(text);
end

local function getClassColored(itemToColor)
	local result = "|c" .. RAID_CLASS_COLORS[classFileName].colorStr .. itemToColor .. "|r";
	return result;
end

local function playerLevelUp(self, event, ...)
	local newLevel = ...;
	characterInfo.level = newLevel;
	
	local text = nil;
	if (characterInfo.level < maxLevel) then
		local unspentTalentPoints = GetNumUnspentTalents();
		if (unspentTalentPoints > 0) then
			text = string.format("Gratz %s, you are now level %i and you have %i unspent talent points.", getClassColored(characterInfo.name), characterInfo.level, unspentTalentPoints);
		else
			text = string.format("Gratz %s, you are now level %i.", getClassColored(characterInfo.name), characterInfo.level);
		end
	else
		text = string.format("Congratulations %s on reaching your currently available max level (%i) :)", getClassColored(characterInfo.name), characterInfo.level);
	end
	
	local expansionLevel = GetExpansionLevel();
	local index = tableContains(expansionProgressionTable, characterInfo.level);
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

local function GameUpgradeable()
	canUpgradeGame = CanUpgradeExpansion();
	return canUpgradeGame;
end

local function getMovementSpeed()
	_, groundSpeed, flightSpeed, swimSpeed = GetUnitSpeed("player");
	
	local playerGroundSpeed = math.floor((groundSpeed / BASE_MOVEMENT_SPEED) * 100);
	local playerFlySpeed = math.floor((flightSpeed / BASE_MOVEMENT_SPEED) * 100);
	local playerSwimSpeed = math.floor((swimSpeed / BASE_MOVEMENT_SPEED) * 100);
	
	print("Ground speed: " .. playerGroundSpeed .. "% | Fly speed: " .. playerFlySpeed .. "% | Swim speed: " .. playerSwimSpeed .. "%");
end

local function getInventoryItemLevels()
	-- Code inspiration from Katoma (http://blackring.net) who made some code which could be used with WeakAura.
	local total, equipped, pvp = GetAverageItemLevel();
	local decimals = 1;
	local iLvl = math.floor((total * 10) + 0.5) / (10^decimals);
	local equippedilvl = math.floor((equipped * 10) + 0.5) / (10^decimals);
	local pvpIlvl = math.floor((pvp * 10) + 0.5) / (10^decimals);
	
	local iLvls = {total = iLvl, equipped = equippedilvl, pvp = pvpIlvl};
	return iLvls;
end

local function getItemLevel()
	local iLvls = getInventoryItemLevels();
	local isInstance, instanceType = IsInInstance()
	if (UnitInBattleground("player")) then
		return iLvls.pvp;
	else
		return iLvls.equipped;
	end
end

local function testIt()
	for i = 1, #mountTable.pvpMounts do
		local mountName = C_MountJournal.GetMountInfoByID(mountTable.pvpMounts[i]);
		print(mountName)
	end
end

local function mountUp()
	local sumMountId = 0;
	local swimming = IsSwimming();
	
	if (swimming and #mountTable.waterMounts > 0) then
		index = random(#mountTable.waterMounts);
		sumMountId = mountTable.waterMounts[index];
		C_MountJournal.SummonByID(sumMountId);
	elseif (UnitInBattleground("player") and #mountTable.pvpMounts > 0) then
		index = random(#mountTable.pvpMounts);
		sumMountId = mountTable.pvpMounts[index];
		C_MountJournal.SummonByID(sumMountId);
	else
		C_MountJournal.SummonByID(sumMountId);
	end
end

local function loadProfessions()
	prof1, prof2, archaeology, fishing, cooking, firstAid = GetProfessions();
	if (prof1 ~= nil) then
		characterInfo.prof1 = prof1;
		characterInfo.prof1Name = GetProfessionInfo(prof1);
	end
	
	if (prof2 ~= nil) then
		characterInfo.prof2 = prof2;
		characterInfo.prof2Name = GetProfessionInfo(prof2);
	end
end

-- legion specific functions
local function checkSuramarManaStatus()
	local manaIncreaseQuests = {
		["Feeding Shal'Aran (quest)"] = 41138,
		["The Valewalker's Burden (quest)"] = 42230,
		["Thalyssra's Abode (quest)"] = 42488,
		["How It's Made: Arcwine (quest)"] = 42833,
		["Make Your Mark (quest)"] = 42792,
		["Kel'danath's Manaflask (item)"] = 42842,
		["Volatile Leyline Crystal (item)"] = 43988,
		["Infinite Stone (item)"] = 43989,
		["Enchanted Burial Urn (item)"] = 43986,
		["Kyrtos's Research Notes (item)"] = 43987
	};
	
	print("Your current completion:");
	local completionAmount = 0;
	local count = 0;
	for name, questId in pairs(manaIncreaseQuests) do
		local completionText = colorizeString("No", "red");
		if (IsQuestFlaggedCompleted(questId)) then
			completionText = colorizeString("Yes", "green");
			completionAmount = completionAmount + 1;
		end
		print(name .. ": " .. completionText);
		count = count + 1;
	end
	print(format("You have completed %i/%i.", completionAmount, count));
end

local function checkLeylineStatus()
	local leylineQuests = {
		["Leyline Feed: Elor'shan"] = 43587,
		["Leyline Feed: Falanaar Arcway"] = 43592,
		["Leyline Feed: Falanaar Depths"] = 43593,
		["Leyline Feed: Halls of the Eclipse"] = 43594,
		["Leyline Feed: Kel'balor"] = 43588,
		["Leyline Feed: Ley Station Aethenar"] = 43591,
		["Leyline Feed: Ley Station Moonfall"] = 43590,
		["Tapping the Leylines (main quest)"] = 40010
	};
	
	print("Your current completion:");
	local completionAmount = 0;
	local count = 0;
	for name, questId in pairs(leylineQuests) do
		local completionText = colorizeString("No", "red");
		if (IsQuestFlaggedCompleted(questId)) then
			completionText = colorizeString("Yes", "green");
			completionAmount = completionAmount + 1;
		end
		print(name .. ": " .. completionText);
		count = count + 1;
	end
	print(format("You have completed %i/%i.", completionAmount, count));
end

-- Addon commands --
SLASH_RELOADUI1 = "/rl";
SlashCmdList.RELOADUI = ReloadUI;

SLASH_XP_LEFT1 = "/dluxpleft";
SlashCmdList.XP_LEFT = function()
	xpLeft();
end;

SLASH_BUILDINFO1 = "/buildinfo";
SlashCmdList.BUILDINFO = function()
	print("UI Version: " .. uiVersion);
end

SLASH_UPGRADEABLE1 = "/dlugu";
SlashCmdList.UPGRADEABLE = function()
	upgradeAble = GameUpgradeable();
	if (upgradeAble) then
		print("Yes it can...");
	else
		print("No it can't.");
	end
end

SLASH_MOVEMENT1 = "/dlums";
SlashCmdList.MOVEMENT = function()
	getMovementSpeed();
end

SLASH_ITEMLEVEL1 = "/dluil";
SlashCmdList.ITEMLEVEL = function()
	local iLvl = getItemLevel();
	local _, _, _, _, _, _, _, _, _, _, _, _, superiorCompleted = GetAchievementInfo(10764);
	local _, _, _, _, _, _, _, _, _, _, _, _, epicCompleted = GetAchievementInfo(10765);
	if (epicCompleted and iLvl > 840) then
		iLvl = itemColorString(4, iLvl);
	elseif (superiorCompleted and iLvl > 820) then
		iLvl = itemColorString(3, iLvl);
	end
	
	print(string.format("Your item level is: %s", iLvl));
end

SLASH_TESTIT1 = "/dlutest";
SlashCmdList.TESTIT = function()
	testIt();
end

SLASH_MOUNTUP1 = "/dlumount";
SlashCmdList.MOUNTUP = function()
	local isOutdoors = IsOutdoors();
	if (isOutdoors) then
		mountUp();
	else
		print("You need to be outdoors to use mounts.");
	end
end

SLASH_XP_HELP1 = "/dluhelp";
SlashCmdList.XP_HELP = function()
	print("Following commands can be used with " .. addOnNameWithColor .. ":");
	print(SLASH_RELOADUI1 .. " (Reload)");
	print(SLASH_XP_LEFT1 .. " (tells how much xp left to next level)");
	print(SLASH_MOVEMENT1 .. " (prints the different movement speed variations)");
	print(SLASH_ITEMLEVEL1 .. " (prints your item level)");
	print(SLASH_SURAMAR_MANA1 .. " (prints out how many ancient mana upgrades you have and what you are missing)");
	print(SLASH_SURAMAR_LEYLINES1 .. " (prints your leyline status in Suramar)");
	print("You can also make macros with the commands, to make the execution easier/faster.");
end

-- Legion specific commands
SLASH_SURAMAR_MANA1 = "/dlusms";
SlashCmdList.SURAMAR_MANA = function()
	checkSuramarManaStatus();
end

SLASH_SURAMAR_LEYLINES1 = "/dlusls";
SlashCmdList.SURAMAR_LEYLINES = function()
	checkLeylineStatus();
end

-- Registering Event --
playerFrame:RegisterEvent("PLAYER_LEVEL_UP");
playerFrame:SetScript("OnEvent", playerLevelUp);

settingsFrame:RegisterEvent("PLAYER_LOGIN");
settingsFrame:SetScript("OnEvent", function() 

getSettings()
SetUpAddonOptions();
loadPlayerMounts();

settingsFrame:UnregisterEvent("PLAYER_LOGIN")
end);

-- Functions --
function HelloPlayer()
	local text = nil;
	
	local factionExpression = characterInfo.faction;
	if (characterInfo.faction ~= "Neutral") then
		factionExpression = "the " .. factionExpression;
	end
	
	if (characterInfo.level < maxLevel) then
		text = string.format("Hello, %s. You are a level %i %s %s %s from %s. Your current max level is %i (%s).", characterInfo.name, characterInfo.level, characterInfo.gender, characterInfo.race, characterInfo.classWithColor, factionExpression, maxLevel, getExpansionName());
	elseif (characterInfo.level == maxLevel and GameUpgradeable()) then
		text = string.format("Hello, %s. You are a %s %s %s from %s, and you are currently at your max level (level %i). You can upgrade the game to continue your leveling adventure...", characterInfo.name, characterInfo.gender, characterInfo.race, characterInfo.classWithColor, factionExpression, characterInfo.level);
	else
		text = string.format("Hello, %s. You are a %s %s %s from %s, and you are currently at your max level (level %i).", characterInfo.name, characterInfo.gender, characterInfo.race, characterInfo.classWithColor, factionExpression, characterInfo.level);
	end
	print(text);
end

function getExpansionName()
	local expansion = GetExpansionLevel()+1;
	local expansionTable = {"WoW: Vanilla", "WoW: The Burning Crusade", "WoW: Wrath of the Lich King", "WoW: Cataclysm", "WoW: Mists of Pandaria", "WoW: Warlords of Draenor", "WoW: Legion"};
	
	local expansionName = "Unknown";
	if (expansionTable[expansion] ~= nil) then
		expansionName = expansionTable[expansion];
	end
	
	return expansionName;
end

function loadPlayerMounts()
	local mountCount = C_MountJournal.GetMountIDs();
	
	for i = 1, #mountCount do
		local _, _, _, _, isUsable, _, _, _, _, _, _, mountID = C_MountJournal.GetMountInfoByID(mountCount[i]);
		if (isUsable == true) then
			-- Water mounts
			if (mountID == 125 or mountID == 449 or mountID == 488) then
				table.insert(mountTable.waterMounts, mountID);
			end
			-- PvP mounts
			if (mountID > 74 and mountID < 83 or mountID == 272 or mountID == 108 or mountID == 162 or mountID == 220 or mountID == 338 or mountID == 305 or mountID > 293 and mountID < 304 or mountID == 330 or mountID == 332 or mountID == 423 or mountID == 555 or mountID == 641 or mountID == 756 or mountID == 784 or mountID > 841 and mountID < 844) then
				table.insert(mountTable.pvpMounts, mountID);
			end
		end
	end
end

-- UI functions
local uniquealyzer = 1;
function createCheckbutton(parent, x_loc, y_loc, displayname)
	uniquealyzer = uniquealyzer + 1;
	
	local checkbutton = CreateFrame("CheckButton", "my_addon_checkbutton_0" .. uniquealyzer, parent, "ChatConfigCheckButtonTemplate");
	checkbutton:ClearAllPoints()
	checkbutton:SetPoint("TOPLEFT", x_loc, y_loc);
	getglobal(checkbutton:GetName() .. 'Text'):SetText(displayname);

	return checkbutton;
end

function createTextRoot(text, parent, x_loc, y_loc, fontType)
	local title = parent:CreateFontString(nil, "ARTWORK", fontType);
	title:SetPoint("TOPLEFT", x_loc, y_loc);
	title:SetText(text);
	return title;
end

function createTextChild(text, parent, below, x_loc, y_loc, fontType)
	local textChildNode = parent:CreateFontString(nil, "ARTWORK", fontType);
	textChildNode:SetPoint("TOPLEFT", below, "BOTTOMLEFT", x_loc, y_loc);
	textChildNode:SetText(text);
	return textChildNode;
end

function createButton(parent, text, width, height, tooltip, x_loc, y_loc)
	local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate");
	button:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", x_loc, y_loc);
    button:SetText(text);
    button.tooltipText = tooltip;
    button:SetWidth(width);
    button:SetHeight(height);
	return button;
end

function SetUpAddonOptions()

	local panel = CreateFrame("Frame", "dluOptionsPanel", InterfaceOptionsFramePanelContainer);
	-- Option panel name
	panel.name = addOnName;
	-- Add info to panel
	local title = createTextRoot(addOnName, panel, 16, -16, "GameFontNormalLarge");
	local authorText = createTextChild("Made by: " .. GetAddOnMetadata(addOnName, "Author"), panel, title, 0, -8, "GameFontHighlightSmall");
	local versionText = createTextChild("Version: ".. GetAddOnMetadata(addOnName, "Version"), panel, authorText, 0, -8, "GameFontHighlightSmall");
	local descriptionText = createTextChild("Description: " .. GetAddOnMetadata(addOnName, "X-Notes"), panel, versionText, 0, -8, "GameFontHighlightSmall");
	local websiteText = createTextChild("Author website: " .. GetAddOnMetadata(addOnName, "X-Website") .. " (it's on Danish)", panel, descriptionText, 0, -8, "GameFontHighlightSmall");
	-- Add help button
	local helpButton = createButton(panel, "Help", 80, 22, "Shows a list of commands, that you can use.", 10, 30);
	helpButton:SetScript("OnClick", function()
		SlashCmdList.XP_HELP();
	end);
	-- Add panel to addon options
	InterfaceOptions_AddCategory(panel);
	
	-- Party panel
	local partyPanel = CreateFrame("Frame", "dluPartyPanel", UIParent);
	partyPanel.name = "Party";
	partyPanel.parent = panel.name;
	InterfaceOptions_AddCategory(partyPanel);
	-- Party panel text
	local partyTitle = createTextRoot(partyPanel.name, partyPanel, 16, -16, "GameFontNormalLarge");
	local partyDescription = createTextChild("This option will congratulate party members, when they level up. This might be changed at some point\nto be less spammy.", partyPanel, partyTitle, 0, -8, "GameFontHighlightSmall");
	-- Party Option
	PartyCheckButton = createCheckbutton(partyPanel, 10, -60, "Party options");
	PartyCheckButton:SetChecked(DLUSettings.partyEnabled);
	
	PartyCheckButton:SetScript("OnClick", 
		function()
			if (PartyCheckButton:GetChecked()) then
				changePartyOption(true);
				print("Party options " .. colorizeString("enabled", "green") .. "!");
			else
				changePartyOption(false);
				print("Party options " .. colorizeString("disabled", "red") .. "!");
			end
		end
	);
	
	-- PvP panel
	local pvpInfoPanel = CreateFrame("Frame", "DarkruneDKPvPInfoChildPanel", UIParent);
	pvpInfoPanel.name = "PvP";
	pvpInfoPanel.parent = panel.name;
	InterfaceOptions_AddCategory(pvpInfoPanel);
	-- PvP panel text
	local pvpTitle = createTextRoot(pvpInfoPanel.name, pvpInfoPanel, 16, -16, "GameFontNormalLarge");
	local pvpDescription = createTextChild("The PVP option will " .. colorizeString("enable", "green") .. " warnings telling nearby players, that a certain class is nearby.\nThis currently happens if you gets stunned by a Rogue or Druid.", pvpInfoPanel, pvpTitle, 0, -8, "GameFontHighlightSmall");
	-- PvP Option
	PvpCheckButton = createCheckbutton(pvpInfoPanel, 10, -80, "PvP options");
	PvpCheckButton:SetChecked(DLUSettings.pvpEnabled);
	
	PvpCheckButton:SetScript("OnClick",
		function()
			if (PvpCheckButton:GetChecked()) then
				changePvpOption(true);
				print("PvP options " .. colorizeString("enabled", "green") .. "!");
			else
				changePvpOption(false);
				print("PvP options " .. colorizeString("disabled", "red") .. "!");
			end
		end
	);
	
	-- Profession panel
	local professionPanel = CreateFrame("Frame", "dluProfessionOptionPanel", UIParent);
	professionPanel.name = "Profession";
	professionPanel.parent = panel.name;
	InterfaceOptions_AddCategory(professionPanel);
	-- Profession panel text
	local profTitle = createTextRoot(professionPanel.name, professionPanel, 16, -16, "GameFontNormalLarge");
	local profDescription = createTextChild("This option will recommend which zone to start in Broken Isles (Legion), based on your professions.", professionPanel, profTitle, 0, -8, "GameFontHighlightSmall");
	-- Profession Option
	ProfessionButton = createCheckbutton(professionPanel, 10, -60, "Suggestions based on professions (Legion)");
	ProfessionButton:SetChecked(DLUSettings.professionsEnabled);
	
	ProfessionButton:SetScript("OnClick",
		function()
			if (ProfessionButton:GetChecked()) then
				changeProfessionOption(true);
				print("Profession options " .. colorizeString("enabled", "green") .. "!");
			else
				changeProfessionOption(false);
				print("Profession options " .. colorizeString("disabled", "red") .. "!");
			end
		end
	);
	
	-- Artifact panel
	local artifactPanel = CreateFrame("Frame", "dluArtifactOptionPanel", UIParent);
	artifactPanel.name = "Artifact";
	artifactPanel.parent = panel.name;
	InterfaceOptions_AddCategory(artifactPanel);
	-- Artifact panel text
	local artiTitle = createTextRoot(artifactPanel.name, artifactPanel, 16, -16, "GameFontNormalLarge");
	local artiDescription = createTextChild("This page will have some buttons to help you track artifact achievements.", artifactPanel, artiTitle, 0, -8, "GameFontHighlightSmall");
	-- Hidden artifact
	local hiddenArtifactAchievementIds = {11152, 11153, 11154};
	-- Dungeon button
	local artiDungeonId = hiddenArtifactAchievementIds[1];
	local artiDungeonTrackText = "Track Dungeons completed";
	local artiDungeonUntrackText = "Untrack Dungeons completed";
	local artiDungeonButton = createButton(artifactPanel, artiDungeonTrackText, 210, 22, "Tracks the (Legion) dungeons you need to complete with your hidden artifact appearance.", 10, 30);
	if (IsTrackedAchievement(artiDungeonId)) then
		artiDungeonButton:SetText(artiDungeonUntrackText);
	end
	artiDungeonButton:SetScript("OnClick", function() 
		local isTracked = IsTrackedAchievement(artiDungeonId);
		if (isTracked) then
			artiDungeonButton:SetText(artiDungeonTrackText);
			RemoveTrackedAchievement(artiDungeonId);
		else
			artiDungeonButton:SetText(artiDungeonUntrackText);
			AddTrackedAchievement(artiDungeonId);
		end
	end);
	-- WQ button
	local artiWQId = hiddenArtifactAchievementIds[2];
	local artiWqTrackText = "Track World Quests completed";
	local artiWqUntrackText = "Untrack World Quests completed";
	local artiWqButton = createButton(artifactPanel, artiWqTrackText, 210, 22, "Tracks the World Quests completed with the hidden artifact appearance.", 220, 30);
	if (IsTrackedAchievement(artiWQId)) then
		artiWqButton:SetText(artiWqUntrackText);
	end
	artiWqButton:SetScript("OnClick", function()
		local isTracked = IsTrackedAchievement(artiWQId);
		if (isTracked) then
			artiWqButton:SetText(artiWqTrackText);
			RemoveTrackedAchievement(artiWQId);
		else
			artiWqButton:SetText(artiWqUntrackText);
			AddTrackedAchievement(artiWQId);
		end
	end);
	-- Pvp Artifact button
	local artiHonorableId = hiddenArtifactAchievementIds[3];
	local hiddenArtifactTrackText = "Track Honorable kills";
	local hiddenArtifactUntrackText = "Untrack Honorable kills";
	local artiHonorButton = createButton(artifactPanel, hiddenArtifactTrackText, 180, 22, "Tracks honorable kills needed to unlock an appearance for your hidden artifact.", 430, 30);
	if (IsTrackedAchievement(artiHonorableId)) then
		artiHonorButton:SetText(hiddenArtifactUntrackText);
	end
	artiHonorButton:SetScript("OnClick", function()
		local isTracked = IsTrackedAchievement(artiHonorableId);
		if (isTracked) then
			artiHonorButton:SetText(hiddenArtifactTrackText);
			RemoveTrackedAchievement(artiHonorableId);
		else
			artiHonorButton:SetText(hiddenArtifactUntrackText);
			AddTrackedAchievement(artiHonorableId);
		end
	end);
	
end

function addonInitialized()
	print(addOnNameWithColor .." initialized... if you need help write " .. SLASH_XP_HELP1 .. ".");
	HelloPlayer();
end

-- Excecute --
if (IsAddOnLoaded(addOnName)) then
	addonInitialized();
end