--
-- Settings
--

local start_time   = 0
local elapsed_time = 0.0
local combatzone   = nil

local color_red   = 1
local color_green = 1
local color_blue  = 1

local SEC_TO_MINUTE_FACTOR = 1/60;
local SEC_TO_HOUR_FACTOR = SEC_TO_MINUTE_FACTOR*SEC_TO_MINUTE_FACTOR;

local LDB
local LDBo

--
-- Register events
--

local hiddenFrame = CreateFrame("Frame")

hiddenFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
hiddenFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
hiddenFrame:RegisterEvent("ADDON_LOADED");

--
-- Debug
--

local debug_mode = false

local function chatMsg(msg)
    DEFAULT_CHAT_FRAME:AddMessage("Broker_CombatTime: "..msg)
end

local function debug(msg)
    if debug_mode then
        chatMsg(msg)
    end
end

--
-- Timing
--

function BrokerCombatTimeUpdateText(elapsed)
    if elapsed
    then -- optimize away unnecessary updates
        elapsed_time = elapsed_time + elapsed
        if elapsed_time < 0.25
        then
            return
        end
    else
        elapsed_time = 0.0
    end
    local total_time = GetTime() - start_time;
    local hour = min(floor(total_time*SEC_TO_HOUR_FACTOR), 99);
    local minute = mod(total_time*SEC_TO_MINUTE_FACTOR, 60);
    local second = mod(total_time, 60);

    local status
    if hour == 0
    then
        status = string.format("%02d:%02d", minute, second)
    else
        status = string.format("%02d:%02d:%02d", hour, minute, second)
    end

    debug(status)

    if LDBo then
        LDBo.text = string.format("ct: |cff%02x%02x%02x%s|r", color_red*255, color_green*255, color_blue*255, status)
    end
end

function BrokerCombatTimeOnUpdate(self, elapsed)
    BrokerCombatTimeUpdateText(elapsed);
end

function BrokerCombatTimeOnEventEnterCombat()
    combatzone = GetRealZoneText()
    debug("Entering combat in "..combatzone)
	-- start the timer
	start_time = GetTime()
    hiddenFrame:SetScript("OnUpdate", BrokerCombatTimeOnUpdate);
    BrokerCombatTimeUpdateText();
end

function BrokerCombatTimeOnEventExitCombat()
    debug("Exiting combat")
    hiddenFrame:SetScript("OnUpdate", nil);
	BrokerCombatTimeUpdateText()
end


--
-- Broker
--


local function BrokerCombatTimeSetupLDB()
    if LDB
    then -- LDBo is already initialized
        return
    end

    if AceLibrary and AceLibrary:HasInstance("LibDataBroker-1.1")
    then
        LDB = AceLibrary("LibDataBroker-1.1")
    elseif LibStub
    then
        LDB = LibStub:GetLibrary("LibDataBroker-1.1",true)
    end

    -- initialize LDBo if LDP has been initialized
    if LDB
    then
        debug("Registering LDBo")
        LDBo = LDB:NewDataObject("CombatTime",
            {
                type = "data source",
                text = string.format("ct: |cff%02x%02x%02x00:00|r", color_red*255, color_green*255, color_blue*255),
                label = "CombatTime",
                icon = "Interface\\Icons\\Ability_DualWield",
                OnTooltipShow =
                    function(tooltip)
                        if tooltip and tooltip.AddLine
                        then
                                tooltip:SetText("CombatTime")
                                tooltip:Show()
                        end
                    end
            }
        )
   end
end

--
-- Event listener
--

function BrokerCombatTimeOnEvent(frame, event)
    if event == "PLAYER_REGEN_ENABLED"
    then
        -- This event is called when the player exits combat
        debug("PLAYER_REGEN_ENABLED")
        BrokerCombatTimeOnEventExitCombat()
    elseif event == "PLAYER_REGEN_DISABLED"
    then
        -- This event is called when we enter combat
        debug("PLAYER_REGEN_DISABLED")
        BrokerCombatTimeOnEventEnterCombat()
    elseif event == "ADDON_LOADED"
    then
        debug("ADDON_LOADED")
        BrokerCombatTimeSetupLDB()
    end
end

hiddenFrame:SetScript("OnEvent", BrokerCombatTimeOnEvent)
