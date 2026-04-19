--
-- Broker
--
local addonName, namespace = ...
local ldb                  = nil
local hiddenFrame          = CreateFrame("Frame")

--
-- Settings
--

-- `true` for debug output
local debugMode            = false

local chatPrefix           = "RaidCount: "

-- color of text (between 0 and 255 per channel)
local colorRed             = 255
local colorGreen           = 255
local colorBlue            = 255

-- text so show in the specific situation
local soloText             = "solo"
local groupText            = "g "
local raidText             = "r "

-- don't show role composition when not at least one tank/heal/dps
local preferSimpleText     = true

-- show total number
local showTotal            = true

-- whether to show or hide the text fragment for the specific role when it is zero
local showTankWhenZero     = true
local showHealerWhenZero   = true
local showDpsWhenZero      = true
local showUnknownWhenZero  = false

-- suffix for the number
local tankSuffix           = "T"
local healerSuffix         = "H"
local dpsSuffix            = "D"
local unknownSuffix        = "?"


--
-- Helpers
--
local function out(msg)
    if (chatPrefix) then
        DEFAULT_CHAT_FRAME:AddMessage(chatPrefix .. msg)
    else
        DEFAULT_CHAT_FRAME:AddMessage(msg)
    end
end

local function debug(msg)
    if debugMode then
        out("[DEBUG] " .. msg)
    end
end

--
-- Functions
--
local function setText(text)
    if ldb then
        local dataObject = ldb:GetDataObjectByName("Broker_RaidCount")
        if dataObject then
            dataObject.text = string.format("|cff%02x%02x%02x%s|r", colorRed, colorGreen, colorBlue, text)
        end
    end
end


local function onUpdate(self)
    if not IsInRaid() and not IsInGroup() then
        setText(soloText)
        return
    end

    local text = ""

    if IsInRaid() then
        text = text .. raidText
    else
        text = text .. groupText
    end

    local groupMembers = GetGroupMemberCounts()
    if not groupMembers then
        setText("???")
        return
    end

    local tanks = groupMembers.TANK or 0
    local healer = groupMembers.HEALER or 0
    local dps = groupMembers.DAMAGER or 0
    local unknown = groupMembers.NOROLE or 0
    local total = tanks + healer + dps + unknown

    if preferSimpleText and tanks == 0 and healer == 0 and dps == 0 then
        text = text .. unknown
        setText(text)
        return
    end

    if showTotal then
        text = text .. total .. " = "
    end

    local first = true

    if tanks > 0 or showTankWhenZero then
        if first then
            first = false
        else
            text = text .. " + "
        end
        text = text .. tanks .. tankSuffix
    end

    if healer > 0 or showHealerWhenZero then
        if first then
            first = false
        else
            text = text .. " + "
        end
        text = text .. healer .. healerSuffix
    end

    if dps > 0 or showDpsWhenZero then
        if first then
            first = false
        else
            text = text .. " + "
        end
        text = text .. dps .. dpsSuffix
    end

    if unknown > 0 or showUnknownWhenZero then
        if first then
            first = false
        else
            text = text .. " + "
        end
        text = text .. unknown .. unknownSuffix
    end

    setText(text)
end

local function onAddonLoaded(addon)
    if addon ~= addonName then return end

    local success, result = pcall(function()
        return LibStub("LibDataBroker-1.1")
    end)
    if success and result then
        ldb = result
        ldb:NewDataObject("Broker_RaidCount", {
            type = "data source",
            icon = "Interface\\Icons\\Inv_misc_groupneedmore",
            text = string.format(soloText, colorRed, colorGreen, colorBlue),
            label = "RaidCount",
        })
    end
end

local function main()
    hiddenFrame:RegisterEvent("PLAYER_LEAVE_COMBAT")
    hiddenFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    hiddenFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    hiddenFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    hiddenFrame:RegisterEvent("LFG_ROLE_UPDATE")
    hiddenFrame:RegisterEvent("ROLE_CHANGED_INFORM")
    hiddenFrame:RegisterEvent("ADDON_LOADED")

    hiddenFrame:SetScript("OnEvent", function(self, event, addon)
        if event == "ADDON_LOADED"
        then
            debug("ADDON_LOADED")
            onAddonLoaded(addon)
            onUpdate()
        else
            onUpdate()
        end
    end)
end

main()
