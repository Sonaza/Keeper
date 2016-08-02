------------------------------------------------------------
-- Keeper by Sonaza
-- All rights reserved
-- http://sonaza.com
------------------------------------------------------------

local ADDON_NAME, addon = ...;
local module = addon:NewModule("voidstorage", "AceEvent-3.0");

function module:OnEnable()
	self:RegisterEvent("VOID_STORAGE_OPEN");
	self:RegisterEvent("VOID_STORAGE_UPDATE");
end

function module:UpdateVoidstorage()
	if(not CanUseVoidStorage()) then return end
	
	local items = {};
	for tabIndex = 1, 2 do
		for slot = 1, 80 do
			local itemID = GetVoidItemInfo(tabIndex, slot);
			if(itemID) then
				local _, link = GetItemInfo(itemID);
				addon:AddItemIndex(items, link);
			end
		end
	end
	
	local playerData = addon:GetPlayerData();
	playerData.voidstorage = items;
	
	addon:MarkDirty();
	
	local playerData = addon:GetPlayerData();
	playerData.incomplete.voidstorage = false;
end

function module:VOID_STORAGE_OPEN()
	module:UpdateVoidstorage()
end

function module:VOID_STORAGE_UPDATE()
	module:UpdateVoidstorage()
end
