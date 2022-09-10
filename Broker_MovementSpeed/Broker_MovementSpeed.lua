local ldb = LibStub("LibDataBroker-1.1")

local update_frequence = 0.5

local standstill_text = "standstill"

local button_text = standstill_text

--
-- Register broker
--

local BrokerMovementSpeed = ldb:NewDataObject("Broker_MovementSpeed",
	{
		type = "data source",
		text = button_text,
		value = 1,
		icon = "Interface\\Icons\\Ability_Rogue_Sprint.blp",
		label = "Speed"
	}
)

--
-- Debug
--

local debugEnabled = true

local function chatMsg(msg)
     DEFAULT_CHAT_FRAME:AddMessage("Broker_MovementSpeed: "..msg)
end

local function debug(msg)
	if debugEnabled
	then
		chatMsg(msg)
	end
end

--
-- Compute Speed
--

local TimeSlice = 0
local BaseSpeed = 0

function BrokerMovementSpeedComputeButtonText()
	local speed_pct = BaseSpeed*100
	local speed_pct_floored = floor(speed_pct + 0.5)
	if speed_pct_floored == 0
	then
		button_text = standstill_text
	else
		local speed_modified = speed_pct_floored - 100
		if speed_modified == 0
		then
			button_text = "speed: normal"
		elseif speed_modified < 0
		then
			button_text = "speed: "..speed_modified.."%";
		else
			button_text = "speed: +"..speed_modified.."%";
		end
	end
end

function BrokerMovementSpeedOnUpdate(self, elapsed)
	TimeSlice = TimeSlice + elapsed;
	if TimeSlice < update_frequence
	then
		return
	else
		BaseSpeed = (GetUnitSpeed("Player") / 7);
	end
	TimeSlice = 0
	BrokerMovementSpeedComputeButtonText()
	BrokerMovementSpeed.text = button_text
end

local EventFrame = CreateFrame("Frame")
EventFrame:SetScript("OnUpdate", BrokerMovementSpeedOnUpdate)
