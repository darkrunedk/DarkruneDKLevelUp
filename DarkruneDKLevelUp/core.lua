-- Globals --
DLU = {
	prefix = "<DLU>",
	addonName = "DarkruneDKLevelUp",
	addonNameColored = addonName,
	addonVersion = "0",
	mountTable = {
		waterMounts = {},
		pvpMounts = {},
		lowLevelMounts = {}
	},
	genderTable = {
		"Unknown",
		"Male",
		"Female"
	},
	player = {
		faction = nil
	}
}
DLU.addonNameColored = GetAddOnMetadata(DLU.addonName, "Title");
DLU.addonVersion = GetAddOnMetadata(DLU.addonName, "Version");

-- variables --
local _, _, _, uiVersion = GetBuildInfo();

-- Frames
local settingsFrame = CreateFrame("Frame", "DLUSettingsFrame");

-- Settings
local function getSettings()
	DLUSettings = DLUSettings or {
		partyEnabled = false,
		pvpEnabled = false,
		professionsEnabled = false
	}
end

local function changePartyOption(partyEnabledOption)
	if (partyEnabledOption) then
		DLUSettings.partyEnabled = true;
	 else 
		DLUSettings.partyEnabled = false;
	 end
end

local function changePvpOption(pvpEnabledOption)
	if (pvpEnabledOption) then
		DLUSettings.pvpEnabled = true;
	else
		DLUSettings.pvpEnabled = false;
	end
end

local function changeProfessionOption(professionsEnabledOption)
	if (professionsEnabledOption) then
		DLUSettings.professionsEnabled = true;
	else
		DLUSettings.professionsEnabled = false
	end
end

-- DLU functions
function DLU.tableContains(tableToCheck, element)
	for i = 0, #tableToCheck do
		if (element == tableToCheck[i]) then
			return tableToCheck[i];
		end
	end
	
	return false;
end

function DLU.tableLength(tableToCheck)
	local count = 0;
	for _ in pairs(tableToCheck) do count = count + 1 end
	return count;
end

function DLU.colorizeString(text, colorType)
	if (colorType == "red") then
		return "|cffCC0000" .. text .. "|r";
	elseif (colorType == "green") then
		return "|cff00CC00" .. text .. "|r";
	elseif (colorType == "orange") then
		return "|cffffa500" .. text .. "|r";
	else
		return text;
	end	
end

function DLU.createErrorMessage(message)
	local errorMessage = DLU.colorizeString(message, "red");
	print(DLU.colorizeString(DLU.prefix, "orange") .. " " .. errorMessage);
end

function DLU.numberFormat(number) -- credit http://richard.warburton.it
	if (number == nil or number <= 0) then
		return 0;
	elseif (number > 0 and number < 1000000) then
		local t = {};
        thousands = ',';
        decimal = '.';
        local int = math.floor(number);
        local rest = number % 1;
        
		if (int == 0) then
            t[#t+1] = 0;
        else
            local digits = math.log10(int);
            local segments = math.floor(digits / 3);
            t[#t+1] = math.floor(int / 1000^segments);
            for i = segments-1, 0, -1 do
                t[#t+1] = thousands;
                t[#t+1] = ("%03d"):format(math.floor(int / 1000^i) % 1000);
            end
        end
        
		if (rest ~= 0) then
            t[#t+1] = decimal;
            rest = math.floor(rest * 10^6);
            while rest % 10 == 0 do
                rest = rest / 10;
            end
            t[#t+1] = rest;
        end
		
        local s = table.concat(t);
        wipe(t);
        return s;
	elseif (number >= 1000000 and number < 1000000000) then
        return format("%.1f|cff93E74F%s|r", number * 0.000001, "m");
    elseif (number >= 1000000000) then
        return format("%.1f|cff93E74F%s|r", number * 0.000000001, "bil");
	end
	
	return number;
end

function DLU.getClassColored(itemToColor, classFileName)
	local result = "|c" .. RAID_CLASS_COLORS[classFileName].colorStr .. itemToColor .. "|r";
	return result;
end

function DLU.RGBPercToHex(r, g, b)
	r = r <= 1 and r >= 0 and r or 0
	g = g <= 1 and g >= 0 and g or 0
	b = b <= 1 and b >= 0 and b or 0
	return string.format("%02x%02x%02x", r*255, g*255, b*255)
end

-- Important functions --
local function itemColorString(num, text)
	local color = ITEM_QUALITY_COLORS[num];
	local result = color.hex .. text .. "|r";
	return result;
end

-- Semi important functions --
local function ArtifactXpLeft()
	local artifactId,_, _, spendPower, power, currentTraits = C_ArtifactUI.GetEquippedArtifactInfo();
	if spendPower ~= nill then
		local traitsText = "trait";
		local _, artifactLink = GetItemInfo(artifactId);
		local traitsWaitingForSpending, currentPower, powerForNextTrait = MainMenuBar_GetNumArtifactTraitsPurchasableFromXP(currentTraits, power);
		local apNeeded = powerForNextTrait - currentPower;
		local apPercentGained = math.floor((currentPower / powerForNextTrait) * 100);
		local apPercentNeeded = 100 - apPercentGained;
		local currentRank = currentTraits + traitsWaitingForSpending;
		local text = "You need %s AP (%i%%) to get %s to rank: %i";
		if (traitsWaitingForSpending > 0) then
			text = text .. " (%i %s upgrade)";
			
			if (traitsWaitingForSpending > 1) then
				traitsText = "traits";
			end
		end
		
		return format(text, DLU.numberFormat(apNeeded), apPercentNeeded, artifactLink, currentRank + 1, traitsWaitingForSpending, traitsText);
	end
	
	return false;
end

local function xpLeft()
	local text = nil;
	local expansionLevel = GetExpansionLevel();
	
	local playerLevel = UnitLevel("player");
	local maxLevel = GetMaxPlayerLevel();
	
	if (playerLevel == maxLevel) then
		text = "You are currently the highest level you can be, congratz :)";
	else
		local nextLevel = playerLevel + 1;
		local xpToNextLevel = (UnitXPMax("player") - UnitXP("player"));
		local xpRested = GetXPExhaustion();
		
		local xpPercentageGained = math.floor((UnitXP("player") / UnitXPMax("player")) * 100);
		local xpPercentageNeeded = 100 - xpPercentageGained;
		
		local xpDisabled = IsXPUserDisabled();
		
		if (xpDisabled) then
			text = "You can't get more xp, because your xp has been disabled.";
		else
			text = "You need %s xp (%i%%) to get to level %i.";
			if (xpRested ~= nil) then
				text = text .. " (currently have %s rested xp)";
			end
		end
		
		text = format(text, DLU.numberFormat(xpToNextLevel), xpPercentageNeeded, nextLevel, itemColorString(3, DLU.numberFormat(xpRested)));
	end
	
	if (expansionLevel >= 6) then
		local apXpLeft = ArtifactXpLeft();
		if (apXpLeft ~= false and playerLevel == maxLevel) then
			text = apXpLeft;
		elseif (apXpLeft ~= false) then
			text = text .. "\n" .. apXpLeft;
		end
	end
	
	print(text);
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
	print(DLU.player.faction);
end

local function mountUp()
	local isOutdoors = IsOutdoors();
	if (isOutdoors) then
		local sumMountId = 0;
		local swimming = IsSwimming();
		local playerLevel = UnitLevel("player");
		
		if (playerLevel < 20 and #DLU.mountTable.lowLevelMounts > 0) then
			index = random(#DLU.mountTable.lowLevelMounts);
			sumMountId = DLU.mountTable.lowLevelMounts[index];
			C_MountJournal.SummonByID(sumMountId);
		elseif (swimming and #DLU.mountTable.waterMounts > 0) then
			index = random(#DLU.mountTable.waterMounts);
			sumMountId = DLU.mountTable.waterMounts[index];
			C_MountJournal.SummonByID(sumMountId);
		elseif (UnitInBattleground("player") and #DLU.mountTable.pvpMounts > 0) then
			index = random(#DLU.mountTable.pvpMounts);
			sumMountId = DLU.mountTable.pvpMounts[index];
			C_MountJournal.SummonByID(sumMountId);
		else
			C_MountJournal.SummonByID(sumMountId);
		end
	else
		DLU.createErrorMessage("You need to be outdoors to use mounts.");
	end
end

local function achievementCompleted(achievementId)
	local _, _, _, _, _, _, _, _, _, _, _, _, wasEarnedByMe = GetAchievementInfo(achievementId);
	return wasEarnedByMe;
end

local function addToTracker(achievementId, button)
	if (achievementCompleted(achievementId)) then
		RemoveTrackedAchievement(achievementId);
		if (button ~= nil) then
			disableButton(button, "Already completed!");
		end
	else
		AddTrackedAchievement(achievementId);
	end
end

local function removeFromTracker(achievementId)
	local isTracked = IsTrackedAchievement(achievementId);
	if (isTracked) then
		RemoveTrackedAchievement(achievementId);
	end
end

local function boolToText(boolValue)
	if (boolValue) then
		return DLU.colorizeString("Yes", "green");
	end
	
	return DLU.colorizeString("No", "red");
end

local function tableStatus(tableToCheck)
	local completionAmount = 0;
	for t, q in pairs(tableToCheck) do
		local completed = IsQuestFlaggedCompleted(q);
		if (completed) then
			completionAmount = completionAmount + 1;
		end
		
		local result = boolToText(completed);
		local text = "%s: %s";
		
		print(format(text, t, result));
	end
	
	print(format("You have completed %i/%i", completionAmount, DLU.tableLength(tableToCheck)));
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
	
	tableStatus(manaIncreaseQuests);
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
	
	tableStatus(leylineQuests);
end

local function addonHelp()
	print("Following commands can be used with " .. DLU.addonNameColored .. ":");
	print(SLASH_RELOADUI1 .. " (Short version of the in-build /reload)");
	print(SLASH_DLU1 .. " xpleft (tells how much xp left to next level)");
	print(SLASH_DLU1 .. " ms (tells the characters different types of movement speed)");
	print(SLASH_DLU1 .. " il or " .. SLASH_DLU1 .. " ilvl (tells you the characters item level)");
	print(SLASH_DLU1 .. " mount (use a mount appropriate for current situation. More info on the Curse page.)");
	-- Legion specific
	print(SLASH_DLU1 .. " sms (tells you how many ancient mana upgrades the characters has and which it needs)");
	print(SLASH_DLU1 .. " sls (tells you how leyline upgrades the characters has and which it needs)");
	print("You can use the commands with macros if you want easier/faster execution.");
end

-- Addon commands --
SLASH_RELOADUI1 = "/rl";
SlashCmdList.RELOADUI = ReloadUI;

SLASH_BUILDINFO1 = "/buildinfo";
SlashCmdList.BUILDINFO = function()
	print("UI Version: " .. uiVersion);
end

SLASH_XP_HELP1 = "/dluhelp";
SlashCmdList.XP_HELP = function()
	print("Please use '/dlu help' for help or use the help button under Interface → Addons → " .. addOnName);
end

SLASH_DLU1 = "/dlu";
SlashCmdList.DLU = function(commandName)
	if (commandName:lower() == "help") then
		addonHelp();
	elseif (commandName:lower() == "test") then
		testIt();
	elseif (commandName:lower() == "il" or commandName:lower() == "ilvl") then
		local iLvl = getItemLevel();
		local _, _, _, _, _, _, _, _, _, _, _, _, superiorCompleted = GetAchievementInfo(10764);
		local _, _, _, _, _, _, _, _, _, _, _, _, epicCompleted = GetAchievementInfo(10765);
		if (epicCompleted and iLvl > 840) then
			iLvl = itemColorString(4, iLvl);
		elseif (superiorCompleted and iLvl > 820) then
			iLvl = itemColorString(3, iLvl);
		end
		
		print(string.format("Your item level is: %s", iLvl));
	elseif (commandName:lower() == "mount") then
		mountUp();
	elseif (commandName:lower() == "xpleft") then
		xpLeft();
	elseif (commandName:lower() == "ms") then
		getMovementSpeed();
	-- Legion specific commands
	elseif (commandName:lower() == "sms") then
		checkSuramarManaStatus();
	elseif (commandName:lower() == "sls") then
		checkLeylineStatus();
	elseif (commandName:lower() == "") then
		-- maybe add something here at a later point
		SlashCmdList.DLU("error");
	else
		DLU.createErrorMessage("Unknown command! Check '/dlu help' if you are uncertain.");
	end
end

-- Functions --
local function loadPlayerMounts()
	local mountCount = C_MountJournal.GetMountIDs();
	
	for i = 1, #mountCount do
		local _, _, _, _, isUsable, _, _, _, _, _, _, mountID = C_MountJournal.GetMountInfoByID(mountCount[i]);
		if (isUsable == true) then
			-- Water mounts
			if (mountID == 449 or mountID == 488) then
				table.insert(DLU.mountTable.waterMounts, mountID);
			end
			-- PvP mounts
			if (mountID > 74 and mountID < 83 or mountID == 272 or mountID == 108 or mountID == 162 or mountID == 220 or mountID == 338 or mountID == 305 or mountID > 293 and mountID < 304 or mountID == 330 or mountID == 332 or mountID == 423 or mountID == 555 or mountID == 641 or mountID == 756 or mountID == 784 or mountID > 841 and mountID < 844) then
				table.insert(DLU.mountTable.pvpMounts, mountID);
			end
			-- Low level mounts
			if (mountID == 679) then
				table.insert(DLU.mountTable.lowLevelMounts, mountID);
			end
		end
	end
end

-- UI functions
local uniquealyzer = 1;
local function createCheckbutton(parent, x_loc, y_loc, displayname)
	uniquealyzer = uniquealyzer + 1;
	
	local checkbutton = CreateFrame("CheckButton", "my_addon_checkbutton_0" .. uniquealyzer, parent, "ChatConfigCheckButtonTemplate");
	checkbutton:ClearAllPoints()
	checkbutton:SetPoint("TOPLEFT", x_loc, y_loc);
	getglobal(checkbutton:GetName() .. 'Text'):SetText(displayname);

	return checkbutton;
end

local function createTextRoot(text, parent, x_loc, y_loc, fontType)
	local title = parent:CreateFontString(nil, "ARTWORK", fontType);
	title:SetPoint("TOPLEFT", x_loc, y_loc);
	title:SetText(text);
	return title;
end

local function createTextChild(text, parent, below, x_loc, y_loc, fontType)
	local textChildNode = parent:CreateFontString(nil, "ARTWORK", fontType);
	textChildNode:SetPoint("TOPLEFT", below, "BOTTOMLEFT", x_loc, y_loc);
	textChildNode:SetText(text);
	return textChildNode;
end

local function createButton(parent, text, width, height, tooltip, x_loc, y_loc)
	local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate");
	button:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", x_loc, y_loc);
    button:SetText(text);
    button.tooltipText = tooltip;
    button:SetWidth(width);
    button:SetHeight(height);
	return button;
end

local function disableButton(button, text)
	button:SetText(text);
	button:Disable();
end

local function SetUpAddonOptions()
	local panel = CreateFrame("Frame", "dluOptionsPanel", InterfaceOptionsFramePanelContainer);
	-- Option panel name
	panel.name = DLU.addonName;
	-- Add info to panel
	local title = createTextRoot(DLU.addonName, panel, 16, -16, "GameFontNormalLarge");
	local authorText = createTextChild("Made by: " .. GetAddOnMetadata(DLU.addonName, "Author"), panel, title, 0, -8, "GameFontHighlightSmall");
	local versionText = createTextChild("Version: ".. DLU.addonVersion, panel, authorText, 0, -8, "GameFontHighlightSmall");
	local descriptionText = createTextChild("Description: " .. GetAddOnMetadata(DLU.addonName, "X-Notes"), panel, versionText, 0, -8, "GameFontHighlightSmall");
	local websiteText = createTextChild("Author website: " .. GetAddOnMetadata(DLU.addonName, "X-Website") .. " (it's on Danish)", panel, descriptionText, 0, -8, "GameFontHighlightSmall");
	-- Add help button
	local helpButton = createButton(panel, "Help", 80, 22, "Shows a list of commands, that you can use.", 10, 30);
	helpButton:SetScript("OnClick", function()
		SlashCmdList.DLU("help");
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
	local pvpDescription = createTextChild("The PVP option will " .. DLU.colorizeString("enable", "green") .. " warnings telling nearby players, that a certain class is nearby.\nThis currently happens if you gets stunned by a Rogue or Druid.", pvpInfoPanel, pvpTitle, 0, -8, "GameFontHighlightSmall");
	-- PvP Option
	PvpCheckButton = createCheckbutton(pvpInfoPanel, 10, -80, "PvP options");
	PvpCheckButton:SetChecked(DLUSettings.pvpEnabled);
	
	PvpCheckButton:SetScript("OnClick",
		function()
			if (PvpCheckButton:GetChecked()) then
				changePvpOption(true);
				print("PvP options " .. DLU.colorizeString("enabled", "green") .. "!");
			else
				changePvpOption(false);
				print("PvP options " .. DLU.colorizeString("disabled", "red") .. "!");
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
	if (achievementCompleted(artiDungeonId)) then
		disableButton(artiDungeonButton, "Already completed!");
	elseif (IsTrackedAchievement(artiDungeonId)) then
		artiDungeonButton:SetText(artiDungeonUntrackText);
	end
	artiDungeonButton:SetScript("OnClick", function()
		local isTracked = IsTrackedAchievement(artiDungeonId);
		if (isTracked) then
			artiDungeonButton:SetText(artiDungeonTrackText);
			removeFromTracker(artiDungeonId);
		else
			artiDungeonButton:SetText(artiDungeonUntrackText);
			addToTracker(artiDungeonId, artiDungeonButton);
		end
	end);
	-- WQ button
	local artiWQId = hiddenArtifactAchievementIds[2];
	local artiWqTrackText = "Track World Quests completed";
	local artiWqUntrackText = "Untrack World Quests completed";
	local artiWqButton = createButton(artifactPanel, artiWqTrackText, 210, 22, "Tracks the World Quests completed with the hidden artifact appearance.", 220, 30);
	if (achievementCompleted(artiWQId)) then
		disableButton(artiWqButton, "Already completed!");
	elseif (IsTrackedAchievement(artiWQId)) then
		artiWqButton:SetText(artiWqUntrackText);
	end
	artiWqButton:SetScript("OnClick", function()
		local isTracked = IsTrackedAchievement(artiWQId);
		if (isTracked) then
			artiWqButton:SetText(artiWqTrackText);
			removeFromTracker(artiWQId);
		else
			artiWqButton:SetText(artiWqUntrackText);
			addToTracker(artiWQId, artiWqButton);
		end
	end);
	-- Pvp Artifact button
	local artiHonorableId = hiddenArtifactAchievementIds[3];
	local hiddenArtifactTrackText = "Track Honorable kills";
	local hiddenArtifactUntrackText = "Untrack Honorable kills";
	local artiHonorButton = createButton(artifactPanel, hiddenArtifactTrackText, 180, 22, "Tracks honorable kills needed to unlock an appearance for your hidden artifact.", 430, 30);
	if (achievementCompleted(artiHonorableId)) then
		disableButton(artiHonorButton, "Already completed!");
	elseif (IsTrackedAchievement(artiHonorableId)) then
		artiHonorButton:SetText(hiddenArtifactUntrackText);
	end
	artiHonorButton:SetScript("OnClick", function()
		local isTracked = IsTrackedAchievement(artiHonorableId);
		if (isTracked) then
			artiHonorButton:SetText(hiddenArtifactTrackText);
			removeFromTracker(artiHonorableId);
		else
			artiHonorButton:SetText(hiddenArtifactUntrackText);
			addToTracker(artiHonorableId, artiHonorButton);
		end
	end);
	
	-- Class specific trackers --
	local artiName;
	
	local palaPanel = CreateFrame("Frame", "DLUPalaPanel", UIParent);
	palaPanel.name = DLU.getClassColored("Paladin", "PALADIN");
	palaPanel.parent = artifactPanel.name;
	InterfaceOptions_AddCategory(palaPanel);
	-- Text
	local palaTitle = createTextRoot(palaPanel.name, palaPanel, 16, -16, "GameFontNormalLarge");
	local name, _, quality = GetItemInfo(139566);
	artiName = itemColorString(quality, name);
	local palaText = createTextChild(format("%s requires Artifact Knowledge level 6 (Retribution).", artiName), palaPanel, palaTitle, 0, -8, "GameFontHighlightSmall");
	-- Button
	local retButton = createButton(palaPanel, format("Check %s status", artiName), 220, 22, "Check how far you are to unlock the Corrupted Ashbringer.", 390, 30);
	retButton:SetScript("OnClick", function()
		DLU.createErrorMessage("Not the exact order!");
		
		local steps = {
			["Talked to Prince Tortheldrin"] = 43682;
		};
		
		if (DLU.player.faction == "Horde") then
			steps["Talked to Bardu"] = 43683;
		else
			steps["Talked to Alexia"] = 43683;
		end
		
		steps["Slime can drop Timolain"] = 43684;
		steps["Shard can be fished up"] = 43685;
		
		tableStatus(steps);
	end);
	
	-- Mage --
	local magePanel = CreateFrame("Frame", "DLUMagePanel", UIParent);
	magePanel.name = DLU.getClassColored("Mage", "MAGE");
	magePanel.parent = artifactPanel.name;
	InterfaceOptions_AddCategory(magePanel);
	-- Text
	local mageTitle = createTextRoot(magePanel.name, magePanel, 16, -16, "GameFontNormalLarge");
	local name, _, quality = GetItemInfo(139558);
	artiName = itemColorString(quality, name);
	local mageText = createTextChild(format("%s required level 6 Artifact Knowledge (Arcane).", artiName), magePanel, mageTitle, 0, -8, "GameFontHighlightSmall");
	-- Button
	local arcButton = createButton(magePanel, format("Check %s status", artiName), 260, 22, "Check how far you are to unlock the Woolomancer's Charge.", 350, 30);
	arcButton:SetScript("OnClick", function()
		local steps = {
			["Aszuna"] = 43787,
			["Stormheim"] = 43789,
			["Val'Sharah"] = 43790,
			["Suramar"] = 43791,
			["High Mountain"] = 43788
		}
		
		tableStatus(steps);
	end);
	
	-- Priest --
	local priestPanel = CreateFrame("Frame", "DLUPriestPanel", UIParent);
	priestPanel.name = DLU.getClassColored("Priest", "PRIEST");
	priestPanel.parent = artifactPanel.name;
	InterfaceOptions_AddCategory(priestPanel);
	-- Text
	local priestTitle = createTextRoot(priestPanel.name, priestPanel, 16, -16, "GameFontNormalLarge");
	local name, _, quality = GetItemInfo(139567);
	artiName = itemColorString(quality, name);
	local priestText = createTextChild(format("%s required Artifact Knowledge 4 (Discipline).", artiName), priestPanel, priestTitle, 0, -8, "GameFontHighlightSmall");
	-- Button
	local discButton = createButton(priestPanel, format("Check %s Status", artiName), 220, 22, "Check how far you are to unlock the Writtings of the End.", 390, 30);
	discButton:SetScript("OnClick", function()
		DLU.createErrorMessage("Not the exact order!");
		
		local steps = {
			["Dalaran - The Violet Citadel"] = 44339,
			["Class Order Hall - Juvess the Duskwhisperer"] = 44340,
			["Northrend - New Hearthglen"] = 44341,
			["Class Order Hall - Archivist Inkforge "] = 44342,
			["Scholomance - Chillheart's Room"] = 44343,
			["Class Order Hall - Meridelle Lightspark"] = 44344,
			["Scarlet Halls - The Flameweaver's library"] = 44345,
			["Azsuna - Chief Bitterbrine Azsuna"] = 44346,
			["Suramar - Artificer Lothaire"] = 44347,
			["Black Rook Hold - Library after First Boss"] = 44348,
			["Karazhan - Guardian's Library"] = 44349,
			["Stormheim - Inquisitor Ernstonbok"] = 44350
		}
		
		tableStatus(steps);
	end);
	
	-- Warrior --
	local warPanel = CreateFrame("Frame", "DLUWarriorPanel", UIParent);
	warPanel.name = DLU.getClassColored("Warrior", "WARRIOR");
	warPanel.parent = artifactPanel.name;
	InterfaceOptions_AddCategory(warPanel);
	-- Text
	local warTitle = createTextRoot(warPanel.name, warPanel, 16, -16, "GameFontNormalLarge");
	local name, _, quality = GetItemInfo(139580);
	artiName = itemColorString(quality, name);
	local warText = createTextChild(format("%s required Artifact Knowledge 5 (Protection).", artiName), warPanel, warTitle, 0, -8, "GameFontHighlightSmall");
	-- Button
	local protButton = createButton(warPanel, format("Check %s Status", artiName), 300, 22, "Check how far you are to unlock the Burning Plate of the Worldbreaker.", 310, 30);
	protButton:SetScript("OnClick", function()
		DLU.createErrorMessage("Has to be available and not denied!");
		
		local steps = {
			["Available"] = 44311,
			["Denied"] = 44312
		}
		
		tableStatus(steps);
	end);
end

local function addonInitialized()
	print(DLU.addonNameColored .." initialized... if you need help write '" .. SLASH_DLU1 .. " help' without the '.");
end

-- Excecute --
if (IsAddOnLoaded(DLU.addonName)) then
	addonInitialized();
end

-- Registering Event --
settingsFrame:RegisterEvent("PLAYER_LOGIN");
settingsFrame:SetScript("OnEvent", function() 

getSettings()
SetUpAddonOptions();
loadPlayerMounts();

settingsFrame:UnregisterEvent("PLAYER_LOGIN")
end);