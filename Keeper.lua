------------------------------------------------------------
-- Keeper by Sonaza
-- All rights reserved
-- http://sonaza.com
------------------------------------------------------------

local ADDON_NAME = ...;
local Addon = LibStub("AceAddon-3.0"):NewAddon(select(2, ...), ADDON_NAME, "AceEvent-3.0");
_G[ADDON_NAME] = Addon;

local savedvars = {
	global {
		["*"] = { -- Realm
			["*"] = { -- Character
				["equipped"]     = {},
				["inventory"]    = {},
				["bank"]         = {},
				["reagents"]     = {},
				["mail"]         = {},
				["voidstorage"]  = {},
			},
		},
	},
};

function Addon:OnInitialize()
	
end

function Addon:OnEnable()
	
end

function Addon:GetPlayerName()
	local n, s = UnitFullName("player");
	return table.concat({n, s}, "-");
end

function Addon:GetHomeRealm()
	local name = string.gsub(GetRealmName(), " ", "");
	return name;
end

function Addon:GetConnectedRealms()
	local realms = GetAutoCompleteRealms();
	
	if(realms) then
		return realms;
	else
		return { Addon:GetHomeRealm() };
	end
end

function Addon:GetConnectedRealmsName()
	return table.concat(Addon:GetConnectedRealms(), "-");
end

function Addon:GetPlayerInformation()
	local connectedRealm  = Addon:GetConnectedRealmsName();
	local homeRealm       = Addon:GetHomeRealm();
	local playerFaction   = UnitFactionGroup("player");
	local playerName      = Addon:GetPlayerName();
	
	return connectedRealm, homeRealm, playerFaction, playerName;
end
