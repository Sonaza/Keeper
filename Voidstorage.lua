------------------------------------------------------------
-- Keeper by Sonaza
-- All rights reserved
-- http://sonaza.com
------------------------------------------------------------

local ADDON_NAME, addon = ...;
local module = addon:NewModule("voidstorage", "AceEvent-3.0");

function module:OnEnable()
	self:RegisterEvent("VOID_STORAGE_OPEN");
	self:RegisterEvent("VOID_STORAGE_CLOSE");
	self:RegisterEvent("VOID_STORAGE_UPDATE");
end

function module:UpdateVoidstorage()
	if(not CanUseVoidStorage() or not module.isOpen) then return end
	
	local items = {};
	for tabIndex = 1, 2 do
		for slot = 1, 80 do
			local link = GetVoidItemHyperlinkString(tabIndex, slot);
			addon:AddItemIndex(items, link);
		end
	end
	
	local playerData = addon:GetPlayerData();
	playerData.voidstorage = items;
	
	addon:MarkDirty();
	addon:MarkComplete("voidstorage");
end

function module:VOID_STORAGE_OPEN()
	module.isOpen = true;
	module:UpdateVoidstorage()
end

function module:VOID_STORAGE_CLOSE()
	module.isOpen = false;
end

function module:VOID_STORAGE_UPDATE()
	module:UpdateVoidstorage()
end
