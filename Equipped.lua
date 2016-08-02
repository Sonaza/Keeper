------------------------------------------------------------
-- Keeper by Sonaza
-- All rights reserved
-- http://sonaza.com
------------------------------------------------------------

local ADDON_NAME, addon = ...;
local module = addon:NewModule("equipped", "AceEvent-3.0");

function module:OnEnable()
	self:RegisterEvent("BAG_UPDATE_DELAYED");
	self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED");
	self:RegisterEvent("BANKFRAME_OPENED");
end

local equipped = {
	["self"] = {},
	["bank"] = {},
};

function module:UpdateSelfEquipped()
	local items = {};
	
	-- Update all items 1-19 and bags 20-23
	for slot = 0, 23 do
		local link = GetInventoryItemLink("player", slot);
		addon:AddItemIndex(items, link);
	end
	
	equipped.self = items;
	module:UpdateCombined();
end

function module:BAG_UPDATE_DELAYED()
	module:UpdateSelfEquipped();
end

function module:PLAYER_EQUIPMENT_CHANGED()
	module:UpdateSelfEquipped();
end

function module:UpdateBankEquipped()
	local items = {};
	
	local numBankSlots = GetNumBankSlots() - 1;
	for container = 5, 5 + numBankSlots do
		local inventoryID = ContainerIDToInventoryID(container);
		local link = GetInventoryItemLink("player", inventoryID);
		addon:AddItemIndex(items, link);
	end
	
	equipped.bank = items;
	module:UpdateCombined();
end

function module:BANKFRAME_OPENED()
	module:UpdateBankEquipped();
end

function module:UpdateCombined()
	local items = equipped.self;
	
	for index, itemString in pairs(equipped.bank) do
		local count = addon:ParseItemString(itemString);
		
		if(items[index]) then
			local savedCount = addon:ParseItemString(items[index]);
			count = count + savedCount;
		end
		
		items[index] = ("%d"):format(count);
	end
	
	local playerData = addon:GetPlayerData();
	playerData.equipped = items;
	
	addon:MarkDirty();
end
