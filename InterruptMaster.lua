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
    --[31935]     = 15,   --Avenger's Shield
    [183752]    = 15,   --Disrupt (DH)
    [15487]     = 45,   -- Priest Silence
    --[129597]  = 90,   -- Belf Silence
    [202719]    = 90,   -- Actual belf silence
    [187707]    = 15,   --Muzzle - Thanks sluth!
    [351338]    = 40,   --Quell - Drakthir
    [88625]     = 60,   --Chastise - Priest
    [115750]    = 90,  --Blinding Light - Palading
    [119914]    = 30,  --Axe Toss Warlock pet
    [368970]    = 90,  --Tail Swipe Evoker
    --[139]     = 60,   --TEST
    --[527]     = 10,   --TEST
}

local modifyingTalents = {
    [15487] = {id=23137,cdr=15}, -- Last Word
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
        onInstanceChat = false,
        onParty = false
    }
}

local playerName = UnitName("player");

local function barSorter(a, b)
  return a:Get("im:end") > b:Get("im:end") and true or false
end

-- show mover bar to define where bars should appear
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

-- not implemented yet
function f:trackTalent(event)
    if event == "INSPECT_READY" then
        local unitGuid= nil --select(1,...)
        for i,s in ipairs(activeCooldowns) do
            if s:Get("im:sourceGUID") == unitGuid then
                local modifyingTalent = modifyingTalents[s:Get("im:spellID")]
                if modifyingTalent then
                    local refStr = nil
                    if UnitGUID("player") == s:Get("im:sourceGUID") then
                        refStr = "player"
                    else
                        for i=1,GetNumGroupMembers()-1 do 
                            if UnitGUID("party"..i)== s:Get("im:sourceGUID") then 
                                refStr="party"..i
                            end
                        end
                    end
                    if refStr ~= nil then
                        local talentId,selected
                        for t=1,7 do
                            for c=1,3 do
                                talentId,_,_,selected = GetTalentInfo(t,c,GetActiveSpecGroup(true),true, refStr)
                                if talentId == modifyingTalent.id then
                                    if selected then
                                        if not s.trackedTalents then
                                            s.trackedTalents={}
                                        end
                                        if not s.trackedTalents[talentId] then
                                            s.trackedTalents[talentId]=true
                                            s.cooldown=s.cooldown-modifyingTalent.cdr
                                            s.duration=s.cooldown
                                            s.expirationTime=s.expirationTime-modifyingTalent.cdr
                                            s.index=s.duration
                                            s.changed=true
                                            return true
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
--f:RegisterEvent("SPELL_INTERRUPT")
--f:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
--f:RegisterEvent("SPELL_CAST_SUCCESS")

--  On event handler
f:SetScript("OnEvent", function(self, event, arg1, arg2, arg3, arg4)

    if event == "ADDON_LOADED" then
        if arg1 == "InterruptMaster" then
            -- Define settings
            if interrupt_master_pc == nil then
                interrupt_master_pc = defaultConfigs
                f:showMover()
            else 
                if interrupt_master_pc.db.resetPos == nil or interrupt_master_pc.db.resetPos == true then
                    --print("SHOW MOVER FRAME")
                    f:showMover()
                end
            end
        end
        return
    end

    if event == "UNIT_SPELLCAST_INTERRUPTED" then
        --unitTarget = arg1
        --castGUID = arg2
        --spellID = arg3
        name, _ = UnitName(arg1)
        link,  _ = GetSpellLink(arg3)
        --print("Stopped", link, "from", name)

    end
    
    --  Check the combat event:
    local timestamp, combatEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellID, spellName, spellSchool, extraSpellID, extraSpellName = CombatLogGetCurrentEventInfo()
    

    if combatEvent ~= "SPELL_INTERRUPT" and combatEvent ~= "SPELL_CAST_SUCCESS"  then
        --print("Ignored event: ", combatEvent)
        -- We don't care about this combat event.
        return
    end

    if interrupt_master_pc.db.teamOnly and not( UnitInParty(sourceName) or UnitInRaid(sourceName)) and sourceName ~= playerName then 
        -- is from someone outside group and user defined only team
        return 
    end

    local successful = 'no'
    if combatEvent == "SPELL_INTERRUPT" then 
        successful = 'yes'
        if interrupt_master_pc.db.onChat then
            local link,  _ = GetSpellLink(extraSpellID)
            print("Interrupted",link, "successfully!")
        end
        if interrupt_master_pc.db.onInstanceChat then
            inInstance, _ = IsInInstance()
            if inInstance then
                SendChatMessage("Interrupted " .. GetSpellLink(extraSpellID) .. " successfully!", "INSTANCE_CHAT", DEFAULT_CHAT_FRAME.editBox.languageID);
            end
        end
        if interrupt_master_pc.db.onParty then
            SendChatMessage("Interrupted " .. GetSpellLink(extraSpellID) .. " successfully!", "PARTY", DEFAULT_CHAT_FRAME.editBox.languageID);
        end
    end

    --  3.3.2. Check the spell:
    local spell = spellData[spellID]
    if not spell and successful == 'no' then
        --print(combatEvent, spellID, extraSpellName)
        -- We don't care about this spell.
        return
    end

    local timeout = 5
    if spellData[spellID] then
        timeout = spellData[spellID]
    else
        local cd = GetSpellBaseCooldown(spellID)
        if cd > 0 then
            timeout = cd / 1000
        end
    end

    x = self:createBar(sourceName, spellID, timeout, timestamp, successful, sourceGUID)
    if (x == false or x == nil) and lastBarCreate ~= nil then
        -- interrupt was successful, sometimes the spell repeats with both events
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
            bar:ClearAllPoints()
            bar:Hide()
            if prevbar then
                bar:SetPoint("TOP", prevbar, "BOTTOM", 0, 0)
            else
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
function f:createBar(sourceName, spellID, timeout, start, successful, sourceGUID) 

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
    mybar:Set("im:sourceGUID", sourceGUID)
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
    elseif msg == "team" then
        if interrupt_master_pc.db.teamOnly then
            print("|cFFFFFF00Interrupt Master: Team only: |cFF00FF00is active")
        else
            print("|cFFFFFF00Interrupt Master: Team only: |cffff0000is disabled")
        end

    elseif msg == "team on" then
        interrupt_master_pc.db.teamOnly = true
        print("|cFFFFFF00Interrupt Master: |cFF00FF00Team only: |cFF00FF00Enabled")
    elseif msg == "team off" then
        interrupt_master_pc.db.teamOnly = false
        print("|cFFFFFF00Interrupt Master: |cFF00FF00Team only: |cffff0000Disabled")

    elseif msg == "party" then
        if interrupt_master_pc.db.onChat then
            print("|cFFFFFF00Interrupt Master: Announce On /party Chat: |cFF00FF00is active")
        else
            print("|cFFFFFF00Interrupt Master: Announce On /party Chat: |cffff0000is disabled")
        end
    elseif msg == "party on" then
        interrupt_master_pc.db.onParty = true
        print("|cFFFFFF00Interrupt Master: |cFF00FF00Announce on /party chat: |cFF00FF00Enabled")
    elseif msg == "party off" then
        interrupt_master_pc.db.onParty = false
        print("|cFFFFFF00Interrupt Master: |cFF00FF00Announce on /party chat: |cffff0000Disabled")

    elseif msg == "instance" then
        if interrupt_master_pc.db.onChat then
            print("|cFFFFFF00Interrupt Master: Announce On /instance Chat: |cFF00FF00is active")
        else
            print("|cFFFFFF00Interrupt Master: Announce On /instance Chat: |cffff0000is disabled")
        end
    elseif msg == "instance on" then
        interrupt_master_pc.db.onInstanceChat = true
        print("|cFFFFFF00Interrupt Master: |cFF00FF00Announce on /instance chat: |cFF00FF00Enabled")
    elseif msg == "instance off" then
        interrupt_master_pc.db.onInstanceChat = false
        print("|cFFFFFF00Interrupt Master: |cFF00FF00Announce on /instance chat: |cffff0000Disabled")

    elseif msg == "chat" then
        if interrupt_master_pc.db.onChat then
            print("|cFFFFFF00Interrupt Master: Show On Chat: |cFF00FF00is active")
        else
            print("|cFFFFFF00Interrupt Master: Show On Chat: |cffff0000is disabled")
        end
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

        print("|cFFFFFF00Interrupt Master: |cFF00FF00To check announce on /instance chat status type /intm instance")
        print("|cFFFFFF00Interrupt Master: |cFF00FF00To turn on announce on /instance chat type /intm instance on")
        print("|cFFFFFF00Interrupt Master: |cFF00FF00To turn off announce on /instance chat type /intm instance off")

        print("|cFFFFFF00Interrupt Master: |cFF00FF00To check announce on /party chat status type /intm party")
        print("|cFFFFFF00Interrupt Master: |cFF00FF00To turn on announce on /party chat type /intm party on")
        print("|cFFFFFF00Interrupt Master: |cFF00FF00To turn off announce on /party chat type /intm party off")
    end
end

SLASH_INTERRUPTMASTER1 = "/intm"
SlashCmdList["INTERRUPTMASTER"] = handler;

