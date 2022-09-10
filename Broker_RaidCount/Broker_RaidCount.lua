
local ldb = LibStub("LibDataBroker-1.1")


local BrokerRaidCount = ldb:NewDataObject("Broker_RaidCount", {
	type = "data source",
	text = "solo",
	value = 1,
	icon = "interface\\addons\\Broker_RaidCount\\BuffConsolidation",
	label = "RaidCount"
})

local function updateRaidCountText(self, event, unitID)
    local text;
    if IsInRaid() or IsInGroup()

    then
        local grp_members = GetGroupMemberCounts()

        -- for k, v in pairs(grp_members) do print(k, v) end

        local tanks = grp_members.TANK
        local healer = grp_members.HEALER
        local none = grp_members.NOROLE
        local dds = grp_members.DAMAGER
        local total = tanks + healer + dds + none

        if none == 0
        then
            text = string.format("%u = %u+%u+%u", total, tanks, healer, dds)
        else
            text = string.format("%u = %u+%u+%u+(%u)", total, tanks, healer, dds, none)
        end
    else
        text = "solo";
    end
    BrokerRaidCount.text = text
end


local EventFrame = CreateFrame("Frame")

EventFrame:RegisterEvent("PLAYER_LEAVE_COMBAT"  )
EventFrame:RegisterEvent("PLAYER_REGEN_ENABLED" )
EventFrame:RegisterEvent("GROUP_ROSTER_UPDATE"  )
EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
EventFrame:RegisterEvent("LFG_ROLE_UPDATE"      )
EventFrame:RegisterEvent("ROLE_CHANGED_INFORM"  )

EventFrame:SetScript("OnEvent", updateRaidCountText)
