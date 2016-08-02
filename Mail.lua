------------------------------------------------------------
-- Keeper by Sonaza
-- All rights reserved
-- http://sonaza.com
------------------------------------------------------------

local ADDON_NAME, addon = ...;
local module = addon:NewModule("mail", "AceEvent-3.0");

function module:OnEnable()
	self:RegisterEvent("MAIL_INBOX_UPDATE");
	hooksecurefunc("SendMail", function(...) module:SendMailHook(...) end);
end

function module:SendMailHook(recipient)
	local isOwn, data = addon:IsOwnCharacter(recipient);
	if(not isOwn) then return end
	
	local items = data.mail;
	
	for itemIndex = 1, ATTACHMENTS_MAX_RECEIVE do
		local link = GetSendMailItemLink(itemIndex);
		if(link) then
			local _, _, _, count = GetSendMailItem(itemIndex);
			addon:AddItemIndex(items, link, count);
		end
	end
end

function module:MAIL_INBOX_UPDATE()
	local items = {};
	
	local numInboxItems = GetInboxNumItems();
	for mailIndex = 1, numInboxItems do
		local _, _, sender, _, _, _, _, itemCount = GetInboxHeaderInfo(mailIndex);
		if(itemCount and itemCount > 0) then
			for itemIndex = 1, ATTACHMENTS_MAX_RECEIVE do
				local link = GetInboxItemLink(mailIndex, itemIndex);
				if(link) then
					local _, _, _, count = GetInboxItem(mailIndex, itemIndex);
					addon:AddItemIndex(items, link, count);
				end
			end
		end
	end
	
	local playerData = addon:GetPlayerData();
	playerData.mail = items;
	
	addon:MarkDirty();
	addon:MarkComplete("mail");
end
