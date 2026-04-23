--
-- Broker
--
local addonName, namespace = ...
local ldb = nil
local hiddenFrame = CreateFrame("Frame")


--
-- Settings
--

-- `true` for debug output
local debugMode                        = false

local outOfCombatText                  = "ooc"
local inCombatPrefix                   = "ct "

local chatPrefix                       = "CombatTime: "

-- color of text (between 0 and 255 per channel)
local colorRed                         = 255
local colorGreen                       = 255
local colorBlue                        = 255

-- threshold to report long combat (in seconds) or `nil` to disable
local reportLongCombatThresholdSeconds = 60

--
-- State
--
local inCombat                         = false
local startTimestamp                   = 0
local accumulatedElapsedTime           = 0.0

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
        out("[DEBUG] "..msg)
    end
end

local function splitDuration(duration)
    if not duration then
        return 0, 0, 0
    else
        local seconds = mod(duration, 60);
        local fullMinutes = (duration - seconds) / 60
        local minutes = mod(fullMinutes, 60)
        local hours = (fullMinutes - minutes) / 60
        return hours, minutes, seconds
    end
end

local function formatDuration(hours, minutes, seconds)
    if hours == 0
    then
        return string.format("%02d:%02d", minutes, seconds)
    else
        return string.format("%02d:%02d:%02d", hours, minutes, seconds)
    end
end

--
-- Functions
--
local function setText(text)
    if ldb then
        local dataObject = ldb:GetDataObjectByName("Broker_CombatTime")
        if dataObject then
            dataObject.text = string.format("|cff%02x%02x%02x%s|r", colorRed, colorGreen, colorBlue, text)
        end
    end
end


local function onUpdate(self, elapsed)
    if not inCombat then
        return
    end

    if elapsed
    then -- optimize away unnecessary updates
        accumulatedElapsedTime = accumulatedElapsedTime + elapsed
        if accumulatedElapsedTime < 0.5
        then
            return
        end
    else
        accumulatedElapsedTime = 0.0
    end

    local duration = GetTime() - startTimestamp
    local text = formatDuration(splitDuration(duration))

    debug(text)
    setText(inCombatPrefix..text)
end

local function onEnterCombat()
    inCombat = true
    startTimestamp = GetTime()
    debug("Entering combat at " .. date("%H:%M:%S"))
    hiddenFrame:SetScript("OnUpdate", onUpdate);
    onUpdate();
end

local function onExitCombat()
    inCombat = false
    local duration = GetTime() - startTimestamp
    local durationText = formatDuration(splitDuration(duration))
    local message = "Exiting combat after "..durationText

    if reportLongCombatThresholdSeconds and duration > reportLongCombatThresholdSeconds then
        out(message)
    end

    debug(message)

    setText(outOfCombatText)

    hiddenFrame:SetScript("OnUpdate", nil);
end


local function onAddonLoaded(addon)
    if addon ~= addonName then return end

    local success, result = pcall(function()
        return LibStub("LibDataBroker-1.1")
    end)
    if success and result then
        ldb = result
        ldb:NewDataObject("Broker_CombatTime", {
            type = "data source",
            icon = "Interface\\Icons\\Ability_DualWield",
            text = string.format("|cff%02x%02x%02x%s|r", colorRed, colorGreen, colorBlue, outOfCombatText),
            label = "CombatTime",
        })
    end
end

local function main()
    hiddenFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    hiddenFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    hiddenFrame:RegisterEvent("ADDON_LOADED");

    hiddenFrame:SetScript("OnEvent", function(self, event, addon)
        if event == "PLAYER_REGEN_ENABLED"
        then
            -- This event is called when the player exits combat
            debug("PLAYER_REGEN_ENABLED")
            onExitCombat()
        elseif event == "PLAYER_REGEN_DISABLED"
        then
            -- This event is called when we enter combat
            debug("PLAYER_REGEN_DISABLED")
            onEnterCombat()
        elseif event == "ADDON_LOADED"
        then
            debug("ADDON_LOADED")
            onAddonLoaded(addon)
        end
    end)
end

main()
