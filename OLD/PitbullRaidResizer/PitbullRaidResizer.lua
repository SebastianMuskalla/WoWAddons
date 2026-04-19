--
-- Settings
--

-- set to true for verbose output in chat window
local debug_mode = false


-- group name for the Tank group that is set in pitbull
local tank_group_name               = "Raid Tanks"
-- standard width in percent of the layout value (for 1 tank)
local tank_default_width_pct        = 100
-- standard height in percent of the layout value
local tank_default_height_pct       = 100
-- standard units per row (it says "column" cause ... Pitbull)
local tank_default_units_per_column = 40

-- specifiying for each tank count a tuple consisting of
--          {width in percent, height in percent, units per row}
local tank_map =
    {
--        [1] = {100, 100, 40},
--        [2] = {90, 100, 40},
--        [3] = {80, 100, 40},
--        [4] = {70, 100, 40},
    }

-- minimum width (can be set to "nil")
local tank_min_width_pct = nil


-- the tool proceeds as follows
-- * compute the number of tanks
-- * look up this number in the tank map
--   - if it exists: take width, height and units per row from there
--   - if it does not exist:
--       . take default width divided by the number of texts, and default height, and default units per column
--       . if the computed width is smaller than the minimum width, set the width to the minimum width
--             (unless the minimum width is "nil")


-- similar for healers
local healer_group_name               = "Raid Healer"
local healer_default_width_pct        = 100
local healer_default_height_pct       = 100
local healer_default_units_per_column = 40
local healer_min_width_pct           = nil
local healer_map = {}


-- similar for dps and others
local dps_group_name               = "Raid DPS"
local dps_default_width_pct        = 100
local dps_default_height_pct       = 100
local dps_default_units_per_column = 40
local dps_min_width_pct            = nil
local dps_map =
    {                                  -- rows*cols
         [1] = { (100/1),     100, 1}, -- 1*1
         [2] = { (100/1),     100, 1}, -- 2*1
         [3] = { (100/1),     100, 1}, -- 3*1
         [4] = { (100/2),     100, 2}, -- 2*2
         [5] = { (100/2),     100, 2}, -- 3*2
         [6] = { (100/2),     100, 2}, -- 3*2
         [7] = { (100/3),     100, 3}, -- 3*3
         [8] = { (100/3),     100, 3}, -- 3*3
         [9] = { (100/3),     100, 3}, -- 3*3
        [10] = { (100/4),     100, 4}, -- 3*4
        [11] = { (100/4),     100, 4}, -- 3*4
        [12] = { (100/4),     100, 4}, -- 3*4
        [13] = { (100/5),     100, 5}, -- 3*5
        [14] = { (100/5),     100, 5}, -- 3*5
        [15] = { (100/5),     100, 5}, -- 3*5
        [16] = { (100/6),     100, 6}, -- 3*6
        [17] = { (100/6),     100, 6}, -- 3*6
        [18] = { (100/6),     100, 6}, -- 3*6
        [19] = { (100/5), (300/4), 5}, -- 4*5
        [20] = { (100/5), (300/4), 5}, -- 4*5
        [21] = { (100/6), (300/4), 6}, -- 4*6
        [22] = { (100/6), (300/4), 6}, -- 4*6
        [23] = { (100/6), (300/4), 6}, -- 4*6
        [24] = { (100/6), (300/4), 6}, -- 4*6
        [25] = { (100/5), (300/5), 5}, -- 5*5
        [26] = { (100/6), (300/5), 6}, -- 5*6
        [27] = { (100/6), (300/5), 6}, -- 5*6
        [28] = { (100/6), (300/5), 6}, -- 5*6
        [29] = { (100/6), (300/5), 6}, -- 5*6
        [30] = { (100/6), (300/5), 6}, -- 5*6
        [31] = { (100/7), (300/5), 7}, -- 5*5
        [32] = { (100/7), (300/5), 7}, -- 5*7
        [33] = { (100/7), (300/5), 7}, -- 5*7
        [34] = { (100/7), (300/5), 7}, -- 5*7
        [35] = { (100/7), (300/5), 7}, -- 5*7
        [36] = { (100/8), (300/5), 8}, -- 5*8
        [37] = { (100/8), (300/5), 8}, -- 5*8
        [38] = { (100/8), (300/5), 8}, -- 5*8
        [39] = { (100/8), (300/5), 8}, -- 5*8
        [40] = { (100/8), (300/5), 8}  -- 5*8
    }

--
-- Debugging
--

local function chatMsg(msg)
    DEFAULT_CHAT_FRAME:AddMessage("PRR: "..msg)
end

local function debug(msg)
    if debug_mode then
        chatMsg(msg)
    end
end

--
-- Internal Data
--

local test_mode = false

local tank_count            = 0
local tank_width_pct        = tank_default_width_pct
local tank_height_pct       = tank_default_height_pct
local tank_units_per_column = tank_default_units_per_column

local healer_count            = 0
local healer_width_pct        = healer_default_width_pct
local healer_height_pct       = healer_default_height_pct
local healer_units_per_column = healer_default_units_per_column

local dps_count            = 0
local dps_width_pct        = dps_default_width_pct
local dps_height_pct       = dps_default_height_pct
local dps_units_per_column = dps_default_units_per_column


--
-- Implementation
--


--- Get healer and tank count
local fetchCounts =
    function()

        local new_tank_count
        local new_healer_count
        local new_dps_count

        if test_mode and not IsInGroup()
        then

            new_tank_count   = tank_count + 1
            new_healer_count = healer_count + 1
            new_dps_count    = dps_count + 1

            if new_tank_count > 10
            then
                new_tank_count = 1
            end

            if new_healer_count > 10
            then
                new_healer_count = 1
            end

            if new_dps_count > 40
            then
                new_dps_count = 1
            end

        else
            local grp_members = GetGroupMemberCounts()
            new_tank_count = grp_members.TANK
            new_healer_count = grp_members.HEALER
            new_dps_count = grp_members.DAMAGER + grp_members.NOROLE
        end

        debug("old #tank: "..tank_count)
        debug("old #heal: "..healer_count)
        debug("old #dps : "..dps_count)
        debug("new #tank: "..new_tank_count)
        debug("new #heal: "..new_healer_count)
        debug("new #dps : "..new_dps_count)

        if new_tank_count == tank_count and new_healer_count == healer_count and new_dps_count == dps_count
        then
            debug("counts unchanged")
            return false
        else
            dps_count = new_dps_count
            tank_count = new_tank_count
            healer_count = new_healer_count
            return true
        end
    end


local recomputeValues =
    function()
        local tank_count_normalized   = max(tank_count,   1)
        local healer_count_normalized = max(healer_count, 1)
        local dps_count_normalized    = max(dps_count,    1)

        if tank_map[tank_count_normalized]
        then
            tank_width_pct         = tank_map[tank_count_normalized][1]
            tank_height_pct        = tank_map[tank_count_normalized][2]
            tank_units_per_column  = tank_map[tank_count_normalized][3]
        else
            tank_width_pct        = tank_default_width_pct / tank_count_normalized
            tank_height_pct       = tank_default_height_pct
            tank_units_per_column = tank_default_units_per_column

            if tank_min_width_pct then
                tank_width_pct = max (tank_width_pct, tank_min_width_pct)
            end
        end

        if healer_map[healer_count_normalized]
        then
            healer_width_pct         = healer_map[healer_count_normalized][1]
            healer_height_pct        = healer_map[healer_count_normalized][2]
            healer_units_per_column  = healer_map[healer_count_normalized][3]
        else
            healer_width_pct        = healer_default_width_pct / healer_count_normalized
            healer_height_pct       = healer_default_height_pct
            healer_units_per_column = healer_default_units_per_column

            if healer_min_width_pct then
                healer_width_pct = max (healer_width_pct, healer_min_width_pct)
            end
        end

        if dps_map[dps_count_normalized]
        then
            dps_width_pct         = dps_map[dps_count_normalized][1]
            dps_height_pct        = dps_map[dps_count_normalized][2]
            dps_units_per_column  = dps_map[dps_count_normalized][3]
        else
            dps_width_pct        = dps_default_width_pct / dps_count_normalized
            dps_height_pct       = dps_default_height_pct
            dps_units_per_column = dps_default_units_per_column

            if dps_min_width_pct then
                dps_width_pct = max (dps_width_pct, dps_min_width_pct)
            end
        end


    end


local setValues =
    function()
        PitBull4.db.profile.groups[tank_group_name].size_x           = tank_width_pct / 100
        PitBull4.db.profile.groups[tank_group_name].size_y           = tank_height_pct / 100
        PitBull4.db.profile.groups[tank_group_name].units_per_column = tank_units_per_column

        PitBull4.db.profile.groups[healer_group_name].size_x           = healer_width_pct / 100
        PitBull4.db.profile.groups[healer_group_name].size_y           = healer_height_pct / 100
        PitBull4.db.profile.groups[healer_group_name].units_per_column = healer_units_per_column

        PitBull4.db.profile.groups[dps_group_name].size_x           = dps_width_pct / 100
        PitBull4.db.profile.groups[dps_group_name].size_y           = dps_height_pct / 100
        PitBull4.db.profile.groups[dps_group_name].units_per_column = dps_units_per_column

        for header in PitBull4:IterateHeadersForName(tank_group_name)
        do
            header:RefreshLayout()
            header:RefreshGroup()
        end

        for header in PitBull4:IterateHeadersForName(healer_group_name)
        do
            header:RefreshLayout()
            header:RefreshGroup()
        end

        for header in PitBull4:IterateHeadersForName(dps_group_name)
        do
            header:RefreshLayout()
            header:RefreshGroup()
        end
    end

local process =
    function()
        debug("process begin")
        if fetchCounts()
        then
            recomputeValues()
            setValues()
        end
        debug("process end")
    end

local processIfNotInCombat =
    function()
        debug("processIfNotInCombat begin")

        if not InCombatLockdown()
        then
            process()
        else
            debug("Can't update because in combat")
        end

        debug("processIfNotInCombat end")
    end

--
-- Slash commands
--

local printInfo =
    function(arg)
        processIfNotInCombat()
        print ("PRR: tank: #: "..tank_count..", w: "..tank_width_pct.."%, h: "..tank_height_pct.."%, "..tank_units_per_column.."/col")
        print ("PRR: heal: #: "..healer_count..", w: "..healer_width_pct.."%, h: "..healer_height_pct.."%, "..healer_units_per_column.."/col")
        print ("PRR: dps : #: "..dps_count..", w: "..dps_width_pct.."%, h: "..dps_height_pct.."%, "..dps_units_per_column.."/col")
    end

local doTest =
    function(arg)
        test_mode = true
        printInfo()
        test_mode = false
    end

SLASH_SHOWINFO1 = "/resizeinfo"
SLASH_TEST1 = "/resizetest"
SlashCmdList["SHOWINFO"] = printInfo
SlashCmdList["TEST"] = doTest

--
-- Events
--

local PRR = select(2, ...)
PRR = LibStub("AceAddon-3.0"):NewAddon(PRR, "PitbullFrameResizer", "AceEvent-3.0")

PRR:RegisterEvent("PLAYER_LEAVE_COMBAT"  , processIfNotInCombat)
PRR:RegisterEvent("PLAYER_REGEN_ENABLED" , processIfNotInCombat)
PRR:RegisterEvent("GROUP_ROSTER_UPDATE"  , processIfNotInCombat)
PRR:RegisterEvent("PLAYER_ENTERING_WORLD", processIfNotInCombat)
PRR:RegisterEvent("LFG_ROLE_UPDATE"      , processIfNotInCombat)
PRR:RegisterEvent("ROLE_CHANGED_INFORM"  , processIfNotInCombat)
