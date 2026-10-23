local ADDON_NAME = ...

-- <<< EDIT: durability threshold as a decimal (0.5 = 50%)
local THRESHOLD = 0.5

-- <<< EDIT: only change if your icon file isn't named "icon" or isn't in the Media folder
local ICON_PATH = "Interface\\AddOns\\LittleYellowMan\\Media\\icon"

-- <<< EDIT (optional): default icon size, used until you set one with /lym size
local ICON_SIZE = 200

-- <<< EDIT: how many seconds the icon stays visible
local DISPLAY_TIME = 3

-- <<< EDIT: path to your own sound file (.ogg or .mp3) in the Media folder.
-- Set to nil to use the built-in sound below instead.
-- Default is nil. If a sound file is added replace nil with "Interface\\AddOns\\LittleYellowMan\\Media\\alert.ogg" keep the qoutes
local SOUND_FILE = "Interface\\AddOns\\LittleYellowMan\\Media\\alert.ogg"

-- <<< EDIT (optional): built-in WoW sound, used only when SOUND_FILE is nil
-- local SOUND_KIT = SOUNDKIT.RAID_WARNING

local MIN_SIZE, MAX_SIZE = 16, 512

local frame = CreateFrame("Frame", "LittleYellowManFrame", UIParent)
frame:SetSize(ICON_SIZE, ICON_SIZE)

-- <<< EDIT: starting position (X offset, Y offset from screen center)
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)

frame:SetFrameStrata("HIGH")
frame:Hide()

local tex = frame:CreateTexture(nil, "ARTWORK")
tex:SetAllPoints()
tex:SetTexture(ICON_PATH)

-- Shift + drag to reposition (use "/lym move" to keep the icon visible while you do this)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", function(self)
if IsShiftKeyDown() then self:StartMoving() end
    end)
frame:SetScript("OnDragStop", function(self)
self:StopMovingOrSizing()
local point, _, relPoint, x, y = self:GetPoint()
LittleYellowManDB.pos = { point, relPoint, x, y }
end)

local function GetLowestDurability()
    local lowest = 1
    for slot = 1, 19 do
        local current, max = GetInventoryItemDurability(slot)
        if current and max and max > 0 then
            local pct = current / max
            if pct < lowest then
                lowest = pct
            end
        end
    end
    return lowest
end

local showToken = 0       -- used so an old timer can't hide a newer showing
local positioning = false -- true while "/lym move" is active

local function PlayAlert()
    if LittleYellowManDB and LittleYellowManDB.mute then return end
    if SOUND_FILE then
        PlaySoundFile(SOUND_FILE, "Master")
    else
        PlaySound(SOUND_KIT, "Master")
    end
end

local function ShowTemporarily()
    if positioning then return end
    if UnitAffectingCombat("player") then return end   -- never in combat
    if UnitIsDeadOrGhost("player") then return end     -- only when alive
    if GetLowestDurability() >= THRESHOLD then return end

    showToken = showToken + 1
    local myToken = showToken
    frame:Show()
    PlayAlert()
    C_Timer.After(DISPLAY_TIME, function()
        if myToken == showToken and not positioning then
            frame:Hide()
        end
    end)
end

local function HideNow()
    showToken = showToken + 1   -- cancels any pending hide timer
    if not positioning then
        frame:Hide()
    end
end

-- Shows the icon for DISPLAY_TIME seconds so you can see a new size (ignores durability)
local function PreviewIcon()
    if positioning or UnitAffectingCombat("player") then return end
    showToken = showToken + 1
    local myToken = showToken
    frame:Show()
    C_Timer.After(DISPLAY_TIME, function()
        if myToken == showToken and not positioning then
            frame:Hide()
        end
    end)
end

local function ApplySize(size)
    frame:SetSize(size, size)
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_REGEN_DISABLED")  -- entering combat
events:RegisterEvent("PLAYER_REGEN_ENABLED")   -- leaving combat
events:RegisterEvent("PLAYER_ALIVE")           -- resurrected (without releasing)
events:RegisterEvent("PLAYER_UNGHOST")         -- returned to life from ghost form

events:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == ADDON_NAME then
            LittleYellowManDB = LittleYellowManDB or {}
            local pos = LittleYellowManDB.pos
            if pos then
                frame:ClearAllPoints()
                frame:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
            end
            if LittleYellowManDB.size then
                ApplySize(LittleYellowManDB.size)
            end
        end
    elseif event == "PLAYER_REGEN_DISABLED" then
        HideNow()
    else
        -- PLAYER_REGEN_ENABLED, PLAYER_ALIVE, PLAYER_UNGHOST
        ShowTemporarily()
    end
end)

local PREFIX = "|cffffd100Little Yellow Man:|r "

-- <<< EDIT (optional): change "/lym" if you want a different slash command
SLASH_LITTLEYELLOWMAN1 = "/lym"
SlashCmdList["LITTLEYELLOWMAN"] = function(msg)
    msg = strlower(strtrim(msg or ""))
    local cmd, arg = msg:match("^(%S+)%s*(.*)$")

    if cmd == "move" then
        positioning = not positioning
        if positioning then
            frame:Show()
            print(PREFIX .. "move mode ON. Shift+drag the icon, then type /lym move again.")
        else
            frame:Hide()
            print(PREFIX .. "move mode OFF.")
        end

    elseif cmd == "size" then
        if arg == "reset" then
            LittleYellowManDB.size = nil
            ApplySize(ICON_SIZE)
            PreviewIcon()
            print(PREFIX .. "size reset to " .. ICON_SIZE .. ".")
        else
            local n = tonumber(arg)
            if n then
                n = math.max(MIN_SIZE, math.min(MAX_SIZE, n))
                LittleYellowManDB.size = n
                ApplySize(n)
                PreviewIcon()
                print(PREFIX .. "size set to " .. n .. ".")
            else
                local current = LittleYellowManDB.size or ICON_SIZE
                print(PREFIX .. "current size is " .. current .. ". Usage: /lym size <" .. MIN_SIZE .. "-" .. MAX_SIZE .. ">  or  /lym size reset")
            end
        end

    elseif cmd == "sound" then
        if arg == "off" then
            LittleYellowManDB.mute = true
            print(PREFIX .. "sound OFF.")
        elseif arg == "on" then
            LittleYellowManDB.mute = false
            print(PREFIX .. "sound ON.")
        elseif arg == "test" then
            local wasMuted = LittleYellowManDB.mute
            LittleYellowManDB.mute = false
            PlayAlert()
            LittleYellowManDB.mute = wasMuted
        else
            print(PREFIX .. "usage: /lym sound on  |  /lym sound off  |  /lym sound test")
        end

    elseif tonumber(cmd) then
        local n = tonumber(cmd)
        THRESHOLD = n / 100
        print(PREFIX .. "threshold set to " .. n .. "%")

    else
        print(PREFIX .. "usage: /lym <percent>  |  /lym size <number>  |  /lym move  |  /lym sound on/off/test")
    end
end
