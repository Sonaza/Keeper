------------------------------------------------------------
-- Keeper by Sonaza
-- All rights reserved
-- http://sonaza.com
------------------------------------------------------------

local ADDON_NAME, addon = ...;
local module = addon:NewModule("bankandreagents", "AceEvent-3.0");

function module:OnEnable()
	self:RegisterEvent("BANKFRAME_OPENED");
	self:RegisterEvent("BANKFRAME_CLOSED");
	self:RegisterEvent("BAG_UPDATE_DELAYED");
	self:RegisterEvent("PLAYERBANKSLOTS_CHANGED", "BAG_UPDATE_DELAYED");
	self:RegisterEvent("PLAYERREAGENTBANKSLOTS_CHANGED");
end

function module:UpdateBank()
	local items = {};
	local containers = {-1};
	
	local numBankSlots = GetNumBankSlots() - 1;
	for container = 5, 5 + numBankSlots do
		tinsert(containers, container);
	end
	
	for _, container in ipairs(containers) do
		local numSlots = GetContainerNumSlots(container);
		
		for slot = 1, numSlots do
			local _, count, _, _, _, _, link, _, _, itemID = GetContainerItemInfo(container, slot);
			addon:AddItemIndex(items, link, count);
		end
	end
	
	local playerData = addon:GetPlayerData();
	playerData.bank = items;
	
	addon:MarkDirty();
end

function module:UpdateReagents()
	local items = {};
	
	local container = REAGENTBANK_CONTAINER;
	local numSlots = GetContainerNumSlots(container);
	for slot = 1, numSlots do
		local _, count, _, _, _, _, link, _, _, itemID = GetContainerItemInfo(container, slot);
		addon:AddItemIndex(items, link, count);
	end
	
	local playerData = addon:GetPlayerData();
	playerData.reagents = items;
	
	addon:MarkDirty();
end

function module:BAG_UPDATE_DELAYED()
	if(module.bankOpen) then
		module:UpdateBank();
	end
end

function module:BANKFRAME_OPENED()
	module.bankOpen = true;
	
	module:UpdateBank();
	module:UpdateReagents();
	
	local playerData = addon:GetPlayerData();
	playerData.incomplete.bank = false;
end

function module:BANKFRAME_CLOSED()
	module.bankOpen = true;
end

function module:PLAYERREAGENTBANKSLOTS_CHANGED()
	module:UpdateReagents();
end
