--
-- Broker
--
local addonName, namespace = ...
local ldb = nil
local hiddenFrame = CreateFrame("Frame")

--
-- Constants`
--
local BROKER_NAME = "Broker_CombatTime_MoveSpeed"

--
-- Settings
--

-- `true` for debug output
local debugMode                        = false

local combatTimePrefix                 = "ct "
local movementSpeedPrefix              = "s "
local secretText           = "secret"
local initialText = "loading..."

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
local startTimestamp                   = nil

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
        local dataObject = ldb:GetDataObjectByName(BROKER_NAME)
        if dataObject then
            dataObject.text = string.format("|cff%02x%02x%02x%s|r", colorRed, colorGreen, colorBlue, text)
        end
    end
end


local function onUpdateCombatTime()
    if not startTimestamp then
        debug("Entering combat at " .. date("%H:%M:%S"))
        startTimestamp = GetTime()
    end
    local duration = GetTime() - startTimestamp
    local text = formatDuration(splitDuration(duration))

    debug(text)
    setText(combatTimePrefix .. text)
end

local function onUpdateMovementSpeed()
    local speed = GetUnitSpeed("player")

    -- This shouldn't happen while we are out of combat, but we check to be on the safe side.
    if issecretvalue and issecretvalue(speed) then
        setText(movementSpeedPrefix .. secretText)
        return
    end

    local text

    -- Check if skyriding information is available
    if C_PlayerInfo and C_PlayerInfo.GetGlidingInfo then
        local isGliding, _, forwardSpeed = C_PlayerInfo.GetGlidingInfo()

        if issecretvalue(isGliding) or issecretvalue(forwardSpeed) then
            setText(movementSpeedPrefix .. secretText)
            return
        end

        -- If we are skyriding, show gliding speed in addition to normal movement speed
        if isGliding then
            local glidingSpeed = forwardSpeed
            local fullSpeed = isGliding and forwardSpeed or speed
            local fullSpeedRounded = Round(fullSpeed / BASE_MOVEMENT_SPEED * 100)
            text = string.format("%.0f%% [%.0f%%]", fullSpeedRounded, glidingSpeed)
        else
            text = string.format("%.0f", speed / BASE_MOVEMENT_SPEED * 100) .. "%"
        end
    else
        text = string.format("%.0f", speed / BASE_MOVEMENT_SPEED * 100) .. "%"
    end

    debug(text)
    setText(movementSpeedPrefix .. text)
end


local function onUpdate(self, elapsed)
    if InCombatLockdown() then
        onUpdateCombatTime()
        return
    else
        if startTimestamp then
            local duration = GetTime() - startTimestamp
            startTimestamp = nil

            local durationText = formatDuration(splitDuration(duration))
            local message = "Exiting combat after " .. durationText

            if reportLongCombatThresholdSeconds and duration > reportLongCombatThresholdSeconds then
                out(message)
            end

            debug(message)
        end

        onUpdateMovementSpeed()
        return
    end
end

local function onAddonLoaded(addon)
    if addon ~= addonName then return end

    local success, result = pcall(function()
        return LibStub("LibDataBroker-1.1")
    end)
    if success and result then
        ldb = result
        ldb:NewDataObject(BROKER_NAME, {
            type = "data source",
            icon = "Interface\\Icons\\Ability_DualWield",
            text = string.format("|cff%02x%02x%02x%s|r", colorRed, colorGreen, colorBlue, initialText),
            label = "CombatTime/RunSpeed",
        })
    end
end

local function main()
    hiddenFrame:SetScript("OnUpdate", onUpdate)

    hiddenFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    hiddenFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    hiddenFrame:RegisterEvent("ADDON_LOADED");

    hiddenFrame:SetScript("OnEvent", function(self, event, addon)
        if event == "ADDON_LOADED"
        then
            debug("ADDON_LOADED")
            onAddonLoaded(addon)
        else
            onUpdate()
        end
    end)
end

main()
