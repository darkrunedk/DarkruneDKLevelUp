-- variables --
local addOnName = "DarkruneDKLevelUp";
local addOnNameWithColor = GetAddOnMetadata(addOnName, "Title");
local version, internalVersion, date, uiVersion = GetBuildInfo();

local maxLevel = GetMaxPlayerLevel();
local class, classFileName = UnitClass("player");
local factionGroup, factionName = UnitFactionGroup("player");

--local expansionInfoTable = {60, 70, 80, 85, 90, 100, 110};

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
function getGender(genderId)
	local genderName = nil;
	if (genderId == 1) then
		genderName = "Unknown";
	elseif (genderId == 2) then
		genderName = "Male";
	elseif (genderId == 3) then
		genderName = "Female";
	end
	
	return genderName;
end

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

-- Player info --
local characterInfo = {
	name = UnitName("player"),
	level = UnitLevel("player"),
	gender = getGender(UnitSex("player")),
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

-- Semi important functions --

function xpLeft()
	local text = nil;
	if (characterInfo["level"] == maxLevel) then
		text = "You are currently the highest level you can be, congratz :)";
	else
		local nextLevel = characterInfo["level"]+1;
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
				text = text .. " You have " .. xpRested .. " rested xp already.";
			end
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
	if (characterInfo.level == 58 or characterInfo.level == 68 or characterInfo.level == 80 or characterInfo.level == 85 or characterInfo.level == 90 or characterInfo.level == 100) then
		text = text .. " You might want to ";
		
		if (expansionLevel >= 1) then		
			if (characterInfo.level == 58 and expansionLevel >= 1) then
				text = text .. "go to Outland";
			elseif (characterInfo.level == 68 and expansionLevel >= 2) then
				text = text .. "go to Northrend";
			elseif (characterInfo.level == 80 and expansionLevel >= 3) then
				text = text .. "begin the Cataclysm quests";
			elseif (characterInfo.level == 85 and expansionLevel >= 4) then
				text = text .. "go to Pandaria";
			elseif (characterInfo.level == 90 and expansionLevel >= 5) then
				text = text .. "go to Draenor";
			elseif (characterInfo.level == 100 and expansionLevel >= 6) then
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

local function getItemLevel()
	total, equipped, pvp = GetAverageItemLevel();
	isInstance, instanceType = IsInInstance()
	if (isInstance and instanceType == "arena" or instanceType == "pvp") then
		return math.floor(pvp);
	else
		return math.floor(equipped);
	end
end

--[[
local function testIt()
	for i = 1, #expansionInfoTable, 1 do
		print(expansionInfoTable[i]);
	end
end
]]

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

-- Adding a quick command for reloading the game --
SLASH_RELOADUI1 = "/rl";
SlashCmdList.RELOADUI = ReloadUI;

SLASH_XP_LEFT1 = "/dluxpleft";
SlashCmdList.XP_LEFT = function()
	xpLeft();
end;

SLASH_BUILDINFO1 = "/buildinfo";
SlashCmdList.BUILDINFO = function()
	print("Internal version: " .. internalVersion .. " | UI Version: " .. uiVersion);
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
	print("Item Level: " .. getItemLevel());
end

SLASH_TESTIT1 = "/dlutest";
SlashCmdList.TESTIT = function()
	--testIt();
	print(characterInfo.prof1);
	print(characterInfo.prof2);
end

SLASH_XP_HELP1 = "/dluhelp";
SlashCmdList.XP_HELP = function()
	print("Following commands can be used with " .. addOnNameWithColor .. ":");
	print(SLASH_RELOADUI1 .. " (Reload)");
	print(SLASH_XP_LEFT1 .. " (tells how much xp left to next level)");
	print(SLASH_BUILDINFO1 .. " (Build info)");
	print(SLASH_UPGRADEABLE1 .. " (can the game be upgraded?)");
	print(SLASH_MOVEMENT1 .. " (prints the different movement speed variations)");
	print(SLASH_ITEMLEVEL1 .. " (prints your item level)");
	print("You can also make macros with the commands, to make the execution easier/faster.");
end

-- Registering Event --
playerFrame:RegisterEvent("PLAYER_LEVEL_UP");
playerFrame:SetScript("OnEvent", playerLevelUp);

settingsFrame:RegisterEvent("PLAYER_LOGIN");
settingsFrame:SetScript("OnEvent", function() 
getSettings()

SetUpAddonOptions();

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
	local expansion = GetExpansionLevel();
	local expansionName = "Unknown";
	if (expansion == 0) then
		expansionName = "WoW: Vanilla";
	elseif (expansion == 1) then
		expansionName = "WoW: The Burning Crusade";
	elseif (expansion == 2) then
		expansionName = "WoW: Wrath of the Lich King";
	elseif (expansion == 3) then
		expansionName = "WoW: Cataclysm";
	elseif (expansion == 4) then
		expansionName = "WoW: Mists of Pandaria";
	elseif (expansion == 5) then
		expansionName = "WoW: Warlords of Draenor";
	elseif (expansion == 6) then
		expansionName = "WoW: Legion";
	end
	
	return expansionName;
end

-- UI functions
local uniquealyzer = 1;
function createCheckbutton(parent, x_loc, y_loc, displayname)
	uniquealyzer = uniquealyzer + 1;
	
	local checkbutton = CreateFrame("CheckButton", "my_addon_checkbutton_0" .. uniquealyzer, parent, "ChatConfigCheckButtonTemplate");
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
	local descriptionText = createTextChild("Description: " .. GetAddOnMetadata(addOnName, "Notes"), panel, versionText, 0, -8, "GameFontHighlightSmall");
	local websiteText = createTextChild("Author website: " .. GetAddOnMetadata(addOnName, "X-Website") .. " (it's on Danish)", panel, descriptionText, 0, -8, "GameFontHighlightSmall");
	-- Add help button
	local helpButton = createButton(panel, "Help", 80, 22, "Shows a list of commands, that you can use.", 10, 30);
	helpButton:SetScript("OnClick", function()
		SlashCmdList.XP_HELP();
	end);
	
	-- Add panel to addon options
	InterfaceOptions_AddCategory(panel);
	
	-- Children options
	local optionPanel = CreateFrame("Frame", "DarkruneDKChildPanel", UIParent);
	optionPanel.name = "Options";
	optionPanel.parent = panel.name;
	InterfaceOptions_AddCategory(optionPanel);
	
	-- Party Option
	PartyCheckButton = createCheckbutton(optionPanel, 10, -10, "Party options");
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
	
	-- PvP Option
	PvpCheckButton = createCheckbutton(optionPanel, 10, -30, "PvP options");
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
	
	-- Profession Option
	ProfessionButton = createCheckbutton(optionPanel, 10, -50, "Suggestions based on professions (Legion)");
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
end

function addonInitialized()
	print(addOnNameWithColor .." initialized... if you need help write " .. SLASH_XP_HELP1 .. ".");
	HelloPlayer();
end

-- Excecute --
if (IsAddOnLoaded(addOnName)) then
	addonInitialized();
end