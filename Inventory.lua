------------------------------------------------------------
-- Keeper by Sonaza
-- All rights reserved
-- http://sonaza.com
------------------------------------------------------------

local ADDON_NAME, addon = ...;
local module = addon:NewModule("inventory", "AceEvent-3.0");

function module:OnEnable()
	self:RegisterEvent("BAG_UPDATE_DELAYED");
end

function module:UpdateContainers()
	local items = {};
	
	for container = 0, NUM_BAG_SLOTS do
		local numSlots = GetContainerNumSlots(container);
		
		for slot = 1, numSlots do
			local _, count, _, quality, readable, lootable, link, isFiltered, noValue, itemID = GetContainerItemInfo(container, slot);
			addon:AddItemIndex(items, link, count);
		end
	end
	
	local playerData = addon:GetPlayerData();
	playerData.inventory = items;
	
	addon:MarkDirty();
end

function module:BAG_UPDATE_DELAYED()
	module:UpdateContainers();
end
