------------------------------------------------------------
-- Keeper by Sonaza
-- All rights reserved
-- http://sonaza.com
------------------------------------------------------------

local ADDON_NAME = ...;
local addon = LibStub("AceAddon-3.0"):NewAddon(select(2, ...), ADDON_NAME, "AceEvent-3.0");
_G[ADDON_NAME] = addon;

local LibExtraTip = LibStub("LibExtraTip-1");

local SAVEDVARS = {
	global = {
		["realms"] = {
			["*"] = { -- Realm
				["*"] = { -- Faction
					["*"] = { -- Character
						["owned"]        = false,
						["class"]        = nil,
						
						["equipped"]     = {},
						["inventory"]    = {},
						["bank"]         = {},
						["reagents"]     = {},
						["mail"]         = {},
						["voidstorage"]  = {},
						
						["incomplete"]   = {
							["bank"]        = true,
							["mail"]        = true,
							["voidstorage"] = CanUseVoidStorage(),
						},
						
						["temp"] = {
							["equipped"] = {
								["self"] = {},
								["bank"] = {},
							},
						}
					},
				},
			},
		},
	},
};

local ITEM_STORAGES = {
	["equipped"]    = "Equipped",
	["inventory"]   = "Bags",
	["bank"]        = "Bank",
	["reagents"]    = "Reagent",
	["mail"]        = "Mail",
	["voidstorage"] = "Void",
};

local IGNORED_ITEMS = {
	["1;6948"]      = true, -- Hearthstone
	["1;110560"]    = true, -- Garrison Hearthstone
};

function addon:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("KeeperDB", SAVEDVARS);
end

function addon:OnEnable()
	self:RegisterEvent("NEUTRAL_FACTION_SELECT_RESULT");
	
	local playerData = addon:GetPlayerData();
	playerData.owned = true;
	
	local _, class = UnitClass("player");
	playerData.class = class;
	
	addon:HookTips();
	
	addon.pendingCacheUpdate = true;
	
	if(addon:HasIncompleteDatabase()) then
		self:RegisterEvent("PLAYER_STARTED_MOVING");
	end
end

function addon:RegisterTooltip(tooltip)
	local modified = false;
	
	tooltip:HookScript('OnTooltipCleared', function(self)
		modified = false;
	end)

	tooltip:HookScript('OnTooltipSetItem', function(self)
		if(modified) then return end
		modified = true;
		
		local name, link = self:GetItem();
		if(link and GetItemInfo(link)) then
			addon:AddTooltipInfo(self, link);
		end
	end);
end

function addon:HookTips()
	addon:RegisterTooltip(GameTooltip);
	addon:RegisterTooltip(ItemRefTooltip);
	
	-- LibExtraTip:RegisterTooltip(BattlePetTooltip);
	-- LibExtraTip:RegisterTooltip(FloatingBattlePetTooltip);
	-- LibExtraTip:RegisterTooltip(GameTooltip);
	-- LibExtraTip:RegisterTooltip(ItemRefTooltip);
	
	-- LibExtraTip:AddCallback({
	-- 	type = "battlepet",
	-- 	callback = function(...)
	-- 		-- print(...);
	-- 		addon:AddTooltipInfo(...);
	-- 	end,
	-- });
	
	-- hooksecurefunc(GameTooltip, "SetInboxItem", function(tooltip, mailID, attachmentIndex)
	-- 	local link = GetInboxItemLink(mailID, attachmentIndex or 1);
	-- 	if(link) then
	-- 		addon:AddTooltipInfo(tooltip, link);
	-- 		tooltip:Show();
	-- 	end
	-- end);
	
	-- hooksecurefunc(GameTooltip, "SetRecipeResultItem", function(tooltip, recipeID)
	-- 	local link = C_TradeSkillUI.GetRecipeItemLink(recipeID);
	-- 	if(link) then
	-- 		addon:AddTooltipInfo(tooltip, link);
	-- 		tooltip:Show();
	-- 	end
	-- end);
	
	-- hooksecurefunc(GameTooltip, "SetRecipeReagentItem", function(tooltip, recipeID, reagentIndex)
	-- 	local link = C_TradeSkillUI.GetRecipeReagentItemLink(recipeID, reagentIndex);
	-- 	if(link) then
	-- 		addon:AddTooltipInfo(tooltip, link);
	-- 		tooltip:Show();
	-- 	end
	-- end);
end

function addon:PLAYER_STARTED_MOVING()
	C_Timer.After(1, function()
		addon:DoIncompleteAlert();
	end);
	self:UnregisterEvent("PLAYER_STARTED_MOVING");
end

function addon:HasIncompleteDatabase()
	local playerData = addon:GetPlayerData();
	for storage, isIncomplete in pairs(playerData.incomplete) do
		if(isIncomplete) then return true end
	end
	
	return false;
end

function addon:DoIncompleteAlert()
	local playerData = addon:GetPlayerData();
	
	local missingStorages = {};
	for storage, isIncomplete in pairs(playerData.incomplete) do
		if(isIncomplete) then
			tinsert(missingStorages, ("|cffffec4d%s|r"):format(string.lower(ITEM_STORAGES[storage])));
		end
	end
	
	if(#missingStorages == 0) then return end
	
	local color = addon:GetClassColor(playerData.class).colorStr;
	local name = addon:GetPlayerName();
	
	addon:AddMessage(("Current database for |c%s%s|r is still incomplete."):format(color, name))
	addon:AddMessage(("Missing: %s."):format(table.concat(missingStorages, ", ")));
	addon:AddMessage("Please visit the places in question so the addon can build the database. Thank you!");
end

function addon:MarkComplete(storage)
	local wasIncomplete = addon:HasIncompleteDatabase();
	if(not wasIncomplete) then return end
	
	local playerData = addon:GetPlayerData();
	if(playerData.incomplete[storage] ~= nil) then
		if(playerData.incomplete[storage]) then 
			addon:AddMessage(("%s added to database."):format(ITEM_STORAGES[storage]));
		end
		playerData.incomplete[storage] = false;
	end
	
	if(wasIncomplete and not addon:HasIncompleteDatabase()) then
		addon:AddMessage("Database complete, yay!");
	end
end

local MESSAGE_PATTERN = "|cff2dbcffKeeper|r %s";
function addon:AddMessage(pattern, ...)
	DEFAULT_CHAT_FRAME:AddMessage(MESSAGE_PATTERN:format(string.format(pattern, ...)), 1, 1, 1);
end

function addon:NEUTRAL_FACTION_SELECT_RESULT()
	local realm   = addon:GetHomeRealm();
	local faction = UnitFactionGroup("player");
	local name    = addon:GetPlayerName();
	
	self.db.global.realms[realm][faction][name] = self.db.global.realms[realm]["Neutral"][name];
	self.db.global.realms[realm]["Neutral"][name] = nil;
end

function addon:AddTooltipInfo(tooltip, itemlink)
	addon:UpdateItemCache();
	
	local itemIndex = addon:MakeItemIndex(itemlink);
	
	local itemdata = addon.itemCache[itemIndex];
	if(not itemdata or IGNORED_ITEMS[itemIndex]) then return end
	
	local totalCount = 0;
	local characters = 0;
	
	tooltip:AddLine(" ");
	
	for character, data in pairs(itemdata) do
		local storages = {};
		local characterCount = 0;
		characters = characters + 1;
		
		local color = addon:GetCharacterColor(character);
		
		for storage, storageData in pairs(data) do
			for _, itemString in pairs(storageData) do
				local count = addon:ParseItemString(itemString)
				totalCount     = totalCount + count;
				characterCount = characterCount + count;
				
				tinsert(storages, string.format("%s: %d", ITEM_STORAGES[storage], count));
			end
		end
		
		local characterText = ("|c%s%s|r"):format(color, addon:FormatName(character));
		
		local storageText = "";
		if(#storages > 1) then
			storageText = ("|c%s%d|r |cffc7c7c7(%s)|r"):format(color, characterCount, table.concat(storages, " | "));
		else
			storageText = ("|c%s%s|r"):format(color, storages[1]);
		end
		
		tooltip:AddDoubleLine(characterText, storageText);
	end
	
	-- Only if there was more than one character
	if(characters > 1) then
		tooltip:AddDoubleLine("|cffc7c7c7Total|r", ("|cffc7c7c7%d|r"):format(totalCount));
	end
end

function addon:UpdateItemCache()
	if(not addon.pendingCacheUpdate) then return end
	
	addon.itemCache = {};
	
	local faction = UnitFactionGroup("player");
	
	local realms = addon:GetConnectedRealms();
	for _, realm in ipairs(realms) do
		for character, data in pairs(self.db.global.realms[realm][faction]) do
			local fullname = string.format("%s-%s", character, realm);
			
			for storage, _ in pairs(ITEM_STORAGES) do
				for itemIndex, itemString in pairs(data[storage]) do
					addon.itemCache[itemIndex]                     = addon.itemCache[itemIndex] or {};
					addon.itemCache[itemIndex][fullname]          = addon.itemCache[itemIndex][fullname] or {};
					addon.itemCache[itemIndex][fullname][storage] = addon.itemCache[itemIndex][fullname][storage] or {};
					
					tinsert(addon.itemCache[itemIndex][fullname][storage], itemString);
				end
			end
		end
	end
	
	-- self.db.global.itemCache = addon.itemCache;
	
	collectgarbage("collect");
	addon.pendingCacheUpdate = false;
end

function addon:MarkDirty()
	addon.pendingCacheUpdate = true;
end

SendMailNameEditBox:HookScript("OnTextChanged", function() addon:UpdateRecipientColor() end);
function addon:UpdateRecipientColor()
	local recipient = SendMailNameEditBox:GetText();
	local name, realm = addon:ParseName(recipient);
	local fullname = string.format("%s-%s", name, realm);
	
	local isOwn, data = addon:IsOwnCharacter(fullname);
	if(isOwn) then
		local color = addon:GetClassColor(data.class);
		SendMailNameEditBox:SetTextColor(color.r, color.g, color.b);
	else
		SendMailNameEditBox:SetTextColor(1.0, 1.0, 1.0);
	end
	
	SendMailNameEditBox:SetFont("Fonts\\ARIALN.TTF", 11);
end

function addon:GetClassColor(class)
	return (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class or 'PRIEST'];
end

function addon:GetPlayerName(withRealm)
	local name, realm = UnitFullName("player");
	if(withRealm) then
		return table.concat({n, s}, "-");
	end
	
	return name;
end

function addon:GetHomeRealm()
	local name = string.gsub(GetRealmName(), " ", "");
	return name;
end

function addon:GetConnectedRealms()
	local realms = GetAutoCompleteRealms();
	
	if(realms) then
		return realms;
	else
		return { addon:GetHomeRealm() };
	end
end

function addon:GetConnectedRealmsName()
	return table.concat(addon:GetConnectedRealms(), "-");
end

function addon:GetPlayerInformation()
	local connectedRealm  = addon:GetConnectedRealmsName();
	local homeRealm       = addon:GetHomeRealm();
	local playerFaction   = UnitFactionGroup("player");
	local playerName      = addon:GetPlayerName();
	
	return connectedRealm, homeRealm, playerFaction, playerName;
end

function addon:GetPlayerData(faction)
	local realm   = addon:GetHomeRealm();
	local faction = faction or UnitFactionGroup("player");
	local name    = addon:GetPlayerName();
	
	return self.db.global.realms[realm][faction][name];
end

function addon:ParseName(name)
	if(not name) then return end
	
	local name, realm = string.split("-", name, 2);
	realm = realm or addon:GetHomeRealm();
	return name, realm;
end

function addon:FormatName(name)
	if(not name) then return end
	
	local name, realm = addon:ParseName(name);
	if(realm == addon:GetHomeRealm()) then
		return name;
	end
	
	return string.format("%s-%s", name, string.sub(realm, 1, 3));
end

local factions = {"Alliance", "Horde", "Neutral"};
function addon:IsOwnCharacter(name)
	local name, realm = addon:ParseName(name);
	for _, faction in ipairs(factions) do
		local data = self.db.global.realms[realm][faction][name];
		if(data.owned) then
			return true, data;
		end
	end
	
	return false;
end

function addon:GetCharacterColor(name, faction)
	local faction = faction or UnitFactionGroup("player");
	
	local class = "PRIEST";
	local name, realm = addon:ParseName(name);
	if(name) then
		local data = self.db.global.realms[realm][faction][name];
		class = data.class;
	end
	
	return addon:GetClassColor(class).colorStr;
end

local ITEM_LINK_TYPE_ITEM        = 0x1;
local ITEM_LINK_TYPE_BATTLEPET   = 0x2;
local ITEM_LINK_TYPE_UNKNOWN     = 0xF;

local ITEM_LINK_TYPES = {
	["item"]        = ITEM_LINK_TYPE_ITEM,
	["battlepet"]   = ITEM_LINK_TYPE_BATTLEPET,
	[0]             = ITEM_LINK_TYPE_UNKNOWN,
}

function addon:GetItemLinkInfo(itemLink)
	if(not itemLink) then return end
	local itemType, itemID = itemLink:match("|H(.-):(%d+)");
	return ITEM_LINK_TYPES[itemType or 0] or ITEM_LINK_TYPE_UNKNOWN, tonumber(itemID), itemType;
end

function addon:ParseItemString(itemString)
	if(not itemString) then return end
	
	local count = string.split(";", itemString);
	return tonumber(count) or 0;
end

function addon:MakeItemIndex(itemlink)
	local linkTypeIndex, realItemID, linkType = addon:GetItemLinkInfo(itemlink);
	return ("%s;%d"):format(linkTypeIndex, realItemID);
end

function addon:ParseItemIndex(index)
	local linktype, itemID = string.split(";", itemString);
	return tonumber(linktype) or 1, tonumber(itemID);
end

function addon:AddItemIndex(items, itemlink, count)
	if(not itemlink) then return end
	if(not items or type(items) ~= "table") then return end
	count = count or 1;
	
	local index = addon:MakeItemIndex(itemlink);
	
	if(items[index]) then
		local savedCount = addon:ParseItemString(items[index]);
		count = count + savedCount;
	end
	
	local itemstring = ("%d"):format(count);
	items[index] = itemstring;
	
	return index, itemstring;
end
