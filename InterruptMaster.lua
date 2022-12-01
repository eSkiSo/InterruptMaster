-- Set addon name
local name = "Interrupt Master"

local candy = LibStub("LibCandyBar-3.0")

local f = CreateFrame("Frame")

local spellData = {
    [47528]     = 15,   --Mind Freeze
    [91802]     = 30,   --Shambling Rush
    [96231]     = 15,   --Rebuke
    [6552]      = 15,   --Pummel
    [106839]    = 15,   --Skull Bash
    [119910]    = 24,   --Spell lock sac
    [19647]     = 24,   --spell lock
    [119911]    = 24,   --Optical Blast
    [115781]    = 24,   --Optical blast
    [132409]    = 24,   --sac spell lock
    [171138]    = 24,   --shadow lock
    [171139]    = 24,   -- ^^
    [171140]    = 24,   -- ^^
    [57994]     = 12,   --Wind shear
    [147362]    = 24,   --Counter Shot
    [2139]      = 24,   -- Counterspell
    [1766]      = 15,   --Kick
    [116705]    = 15,   --Spear hand strike
    [97547]     = 60,   --Solar Beam
    [78675]     = 60,   --extra solar
    [31935]     = 15,   --Avenger's Shield
    [183752]    = 15,   --Disrupt (DH)
    [15487]     = 45,   -- Priest Silence
    --[129597]  = 90,   -- Belf Silence
    [202719]    = 90,   -- Actual belf silence
    [187707]    = 15,   --Muzzle - Thanks sluth!
    [351338]    = 40,   --Quell - Drakthir
    [88625]     = 60,   --Chastise - Priest
    [115750]     = 90,  --Blinding Light - Palading
    [119914]     = 30,  --Axe Toss Warlock pet
    [368970]     = 90,  --Tail Swipe Evoker
    --[139]     = 60,   --TEST
    --[527]     = 10,   --TEST
}

local defaultConfigs = {
    db = {
        font = "Fonts\\2002.TTF",
        fontSize = 16,
        resetPos = true,
        texture = "Interface\\AddOns\\InterruptMaster\\textures\\BantoBar",
        player = UnitName("player"),
        pos = "CENTER",
        posx = 0, -- -528, 
        posy = 0, ---315,
        barWidth = 190, 
        barHeight = 25,
        teamOnly = false,
        onChat = true,
    }
}

local playerName = UnitName("player");

local function barSorter(a, b)
  return a:Get("im:end") > b:Get("im:end") and true or false
end

function f:showMover()
    local f = CreateFrame("Frame",nil,UIParent)
    f:SetFrameStrata("BACKGROUND")
    f:SetWidth(180) -- Set these to whatever height/width is needed 
    f:SetHeight(25) -- for your Texture

    local t = f:CreateTexture(nil,"BACKGROUND")
    t:SetTexture("Interface\\AddOns\\InterruptMaster\\textures\\BantoBar")
    t:SetAllPoints(f)
    f.texture = t

    f:SetPoint("CENTER",0,0)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetMovable(true)
    f:CreateFontString(nil,"ARTWORK") 
    f.text = f:CreateFontString(nil,"ARTWORK") 
    f.text:SetFont("Fonts\\ARIALN.ttf", 13, "OUTLINE")
    f.text:SetPoint("CENTER",0,0)
    f.text:SetText("Interrupt Master")
    f:SetScript("OnDragStart", function(self) self:StartMoving() self:ClearAllPoints() end)
    f:SetScript("OnDragStop", 
      function(self)
        self:StopMovingOrSizing()
        local from, _, to, x, y = self:GetPoint()
        interrupt_master_pc.db.pos = from; 
        interrupt_master_pc.db.posx = x; 
        interrupt_master_pc.db.posy = y;
        interrupt_master_pc.db.resetPos = false;
        f:Hide()
        end)
    f:Show()
end

f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

--  3.3. Tell the frame what to do when the event happens:
f:SetScript("OnEvent", function(self, event, arg1)

    if event == "ADDON_LOADED" then
        if arg1 == "InterruptMaster" then
            -- Define settings
            if interrupt_master_pc == nil then
                interrupt_master_pc = defaultConfigs
                f:showMover()
            else 
                if interrupt_master_pc.db.resetPos == nil or interrupt_master_pc.db.resetPos == true then
                    print("SHOW MOVER FRAME")
                    f:showMover()
                end
            end
        end
        return
    end

    --  Check the combat event:
    local timestamp, combatEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellID, spellName, spellSchool, extraSpellID, extraSpellName = CombatLogGetCurrentEventInfo()

    if combatEvent ~= "SPELL_INTERRUPT" and combatEvent ~= "SPELL_CAST_SUCCESS"  then
        -- We don't care about this combat event.
        return
    end

    local successful = 'no'
    if combatEvent == "SPELL_INTERRUPT" then 
        successful = 'yes'
        --print(sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellID, spellName, spellSchool, extraSpellID, extraSpellName)
        if interrupt_master_pc.db.onChat then
            print("Interrupted ",extraSpellName, " with success!")
        end
    end

    if interrupt_master_pc.db.teamOnly and not( UnitInParty(sourceName) or UnitInRaid(sourceName)) and sourceName ~= playerName then 
        --print("Outsider interrupt")
        return 
    end

    --  3.3.2. Check the spell:
    --print("Check SpellID ", spellID)
    local spell = spellData[spellID]
    if not spell then
        --print("Not found")
        --print(combatEvent, spellID, extraSpellName)
        -- We don't care about this spell.
        return
    end

    local timeout = 5
    if spellData[spellID] then
        timeout = spellData[spellID] --+ (timestamp - GetTime())
    end

    x = self:createBar(sourceName, spellID, timeout, timestamp, successful)
    if (x == false or x == nil) and lastBarCreate ~= nil then
        lastBarCreate:SetLabel(sourceName .. " [!]")
    elseif x ~= false and x ~= nil then
        if x:Get("im:spellID") == spellID then
            x:SetLabel(sourceName .. " [!]")
        end
    end

end)

local activeCooldowns = {}
local lastBarCreate = nil
local doingRearrange = false

function f:rearrangeActiveCoolDowns(stoppedBar)
    --local barName = stoppedBar:Get("im:name")
    --activeCooldowns[barName] = nil
    --print("Called by ", barName)
    if doingRearrange then
        return
    end
    local tmp = {}
    local attachpoint
    doingRearrange = true

    local totalbar=0
    for _, bar in next, activeCooldowns do
        tmp[#tmp + 1] = bar
        totalbar = totalbar+1
    end

    table.sort(tmp, barSorter)
    local numbartmp = 1
    local prevbar = false
    lastBarCreate = nil
    for _, bar in next, tmp do 
        if bar ~= nil then
            --print(bar:Get("im:name"))
            bar:ClearAllPoints()
            bar:Hide()
            if prevbar then
                --print("Existted")
                bar:SetPoint("TOP", prevbar, "BOTTOM", 0, 0)
            else
                --print("Did not exits")
                bar:SetPoint(interrupt_master_pc.db.pos, interrupt_master_pc.db.posx, interrupt_master_pc.db.posy)
            end
            prevbar = bar
            bar:Show()
            numbartmp=numbartmp+1
        end
    end
    lastBarCreate = prevbar
    doingRearrange = false
end

local isCreatingBar = false
function f:createBar(sourceName, spellID, timeout, start, successful) 

    if isCreatingBar then
        return false
    end
    isCreatingBar = true
    if sourceName == nil then
        sourceName = "NO SOURCE"
    end
    local class, _, _ = UnitClass(sourceName);
    local color = nil
    --print("class", class)
    if class ~= nil then
        if class == "Demon Hunter" then
            class = "DEMONHUNTER"
        elseif class == "Death Knight" then
            class = "DEATHKNIGHT"
        end
        color = RAID_CLASS_COLORS[string.upper(class)]
    end
    local msg = "%s - %s"
    --sourceName = sourceName.."-TESTE"
    sourceName = gsub(sourceName, "%-[^|]+", "")
    --local mybar = candy:New("Interface\\TARGETINGFRAME\\UI-StatusBar", 170, 25) --16
    local definedBarName = tostring(spellID)..sourceName..start

    if activeCooldowns[definedBarName] then 
        isCreatingBar = false
        return activeCooldowns[definedBarName]
    end

    local mybar = candy:New(interrupt_master_pc.db.texture, interrupt_master_pc.db.barWidth or 190, interrupt_master_pc.db.barHeight or 25) --16
    mybar.candyBarLabel:SetFont(interrupt_master_pc.db.font, interrupt_master_pc.db.fontSize)

    mybar:SetFrameStrata("MEDIUM")
    local _, _, icon, _, _, _, _, _ = GetSpellInfo(spellID)
    mybar:SetIcon(icon)

    local cc = color or {r=0.5; g=0.5; b=0.5}
    mybar:SetColor(cc.r,cc.g,cc.b,1)

    mybar:SetClampedToScreen(true)
    if lastBarCreate ~= nil then
        mybar:SetPoint("TOP", lastBarCreate, "BOTTOM", 0, 0)
    else
        mybar:SetPoint(interrupt_master_pc.db.pos, interrupt_master_pc.db.posx, interrupt_master_pc.db.posy)
    end

    
    if successful == 'yes' then 
        labelToAdd = sourceName .. " [!]"
        --mybar:SetShadowColor(0,1,0,0.4)
    else
        labelToAdd = sourceName
    end
    mybar:SetLabel(labelToAdd)
    mybar:SetDuration(timeout)
    mybar:EnableMouse(true)
    mybar:SetScript("OnMouseDown", function(self, event) f.clearBar(definedBarName) end)
    
    mybar:Set("im:spellID", spellID)
    mybar:Set("im:name", definedBarName)
    mybar:Set("im:start", start)
    mybar:Set("im:end", GetTime() + timeout)
    mybar:Start()
    --print("Started ", GetTime())

    activeCooldowns[definedBarName] = mybar
    lastBarCreate = mybar
    isCreatingBar = false
    --if f:antiSpam(0.2) then
    f:rearrangeActiveCoolDowns(lastBarCreate)
    --end
end

local function barstopped( callback, bar )
    local barName = bar:Get("im:name")
    if activeCooldowns[barName] then
        activeCooldowns[barName] = nil
    end
    --if f:antiSpam(0.2) then
        f:rearrangeActiveCoolDowns(bar)
    --end
end

function f.clearBar(barName)
    activeCooldowns[barName]:Stop()
end

local lastAntiSpam

function f:antiSpam(time)
  if GetTime() - (lastAntiSpam or 0) > (time or 2.5) then
    lastAntiSpam = GetTime()
    return true
  else
    return false
  end
end

LibStub("LibCandyBar-3.0"):RegisterCallback("LibCandyBar_Stop", barstopped)

-- |cFF00FF00   green
-- |cffff0000   red
-- |cFFFFFF00   yellow
local function handler(msg)
    if msg == "move" then
        print("|cFFFFFF00Interrupt Master: |cFF00FF00Open Mover")
        f:showMover()
    elseif msg == "cooldown" then

    elseif msg == "skip" then
        f:getQuestStatus()
    elseif msg == "team" then
        if interrupt_master_pc.db.teamOnly then
            print("|cFFFFFF00Interrupt Master: Team only: |cFF00FF00is active")
        else
            print("|cFFFFFF00Interrupt Master: Team only: |cffff0000is disabled")
        end
    elseif msg == "chat" then
        if interrupt_master_pc.db.onChat then
            print("|cFFFFFF00Interrupt Master: Show On Chat: |cFF00FF00is active")
        else
            print("|cFFFFFF00Interrupt Master: Show On Chat: |cffff0000is disabled")
        end
    elseif msg == "team on" then
        interrupt_master_pc.db.teamOnly = true
        print("|cFFFFFF00Interrupt Master: |cFF00FF00Team only: |cFF00FF00Enabled")
    elseif msg == "team off" then
        interrupt_master_pc.db.teamOnly = false
        print("|cFFFFFF00Interrupt Master: |cFF00FF00Team only: |cffff0000Disabled")
    elseif msg == "chat on" then
        interrupt_master_pc.db.onChat = true
        print("|cFFFFFF00Interrupt Master: |cFF00FF00Show on Chat: |cFF00FF00Enabled")
    elseif msg == "chat off" then
        interrupt_master_pc.db.onChat = false
        print("|cFFFFFF00Interrupt Master: |cFF00FF00Show on Chat: |cffff0000Disabled")
    elseif msg == "reset" then
        interrupt_master_pc = defaultConfigs
        print("|cFFFFFF00Interrupt Master: |cFF00FF00Player profile reset")
    elseif type(tonumber(msg)) == "number" then
        local spellName, _, _, _, _, _, spellID = GetSpellInfo(msg)
        local cd = GetSpellBaseCooldown(msg)
        if cd > 0 then
            cd = cd / 1000
        end
        print("Spell ", spellName, " has a cooldown of ",cd, " seconds")
    else
        print("|cFFFFFF00Interrupt Master: |cFF00FF00To move IM type /intm move")
        print("|cFFFFFF00Interrupt Master: |cFF00FF00To check show only team status type /intm team")
        print("|cFFFFFF00Interrupt Master: |cFF00FF00To turn on show only team type /intm team on")
        print("|cFFFFFF00Interrupt Master: |cFF00FF00To turn off show only team type /intm team off")
        print("|cFFFFFF00Interrupt Master: |cFF00FF00To check show on chat status type /intm chat")
        print("|cFFFFFF00Interrupt Master: |cFF00FF00To turn on show on chat type /intm chat on")
        print("|cFFFFFF00Interrupt Master: |cFF00FF00To turn off show on chat type /intm chat off")
    end
end

SLASH_INTERRUPTMASTER1 = "/intm"
SlashCmdList["INTERRUPTMASTER"] = handler;

