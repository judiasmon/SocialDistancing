local rangeFrame = CreateFrame("Frame", "SocialDistancingRangeFrame", UIParent, "BasicFrameTemplateWithInset")
rangeFrame:SetSize(340, 205)
rangeFrame:SetPoint("TOP", UIParent, "TOP", 0, -150)
rangeFrame:SetFrameStrata("HIGH")
rangeFrame:SetClampedToScreen(true)
rangeFrame.TitleBg:SetHeight(26)
rangeFrame.title = rangeFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
rangeFrame.title:SetPoint("TOPLEFT", rangeFrame.TitleBg, "TOPLEFT", 5, -3)
rangeFrame.title:SetText("Range Check")
rangeFrame:EnableMouse(true)
rangeFrame:SetMovable(true)
rangeFrame:RegisterForDrag("LeftButton")
rangeFrame:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)
rangeFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
end)

local rangeText = rangeFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
rangeText:SetPoint("TOPLEFT", rangeFrame, "TOPLEFT", 14, -38)
rangeText:SetWidth(310)
rangeText:SetJustifyH("LEFT")
rangeText:SetJustifyV("TOP")

local specializationNames = {
    [65] = "Holy Paladin",
    [66] = "Protection Paladin",
    [70] = "Retribution Paladin",
    [102] = "Balance Druid",
    [103] = "Feral Druid",
    [104] = "Guardian Druid",
    [105] = "Restoration Druid",
    [256] = "Discipline Priest",
    [257] = "Holy Priest",
    [258] = "Shadow Priest",
    [262] = "Elemental Shaman",
    [263] = "Enhancement Shaman",
    [264] = "Restoration Shaman",
}
local healerSpecializations = {
    [65] = true,
    [105] = true,
    [256] = true,
    [257] = true,
    [264] = true,
}
local previousRangeStates = {}

local function TrackRangeState(key, inRange)
    if inRange == nil then
        return false
    end

    local wasInRange = previousRangeStates[key]
    previousRangeStates[key] = inRange
    return wasInRange == true and inRange == false
end

local specializationByGUID = {}
local inspectQueue = {}
local inspectPendingGUID
local inspectPendingUnit
local inspectPendingTimeout = 0
local inspectRequestCooldown = 0
local inspectScanElapsed = 0

local function QueuePartyInspections()
    inspectQueue = {}
    if IsInRaid() then
        return
    end

    local memberCount = GetNumSubgroupMembers and GetNumSubgroupMembers() or 0
    for index = 1, memberCount do
        local unit = "party" .. index
        local guid = UnitGUID(unit)
        if guid and guid ~= inspectPendingGUID and specializationByGUID[guid] == nil then
            inspectQueue[#inspectQueue + 1] = unit
        end
    end
end

local function ClearPendingInspection()
    local clearInspect = _G["ClearInspectPlayer"]
    if clearInspect then
        pcall(clearInspect)
    end
    inspectPendingGUID = nil
    inspectPendingUnit = nil
    inspectPendingTimeout = 0
end

local function HandleInspectReady(guid)
    if not guid or guid ~= inspectPendingGUID then
        return
    end

    local specializationAPI = _G["C_SpecializationInfo"]
    local getInspectSpecialization = _G["GetInspectSpecialization"]
        or (specializationAPI and specializationAPI.GetInspectSpecialization)
    local success, specializationID
    if getInspectSpecialization and inspectPendingUnit then
        success, specializationID = pcall(getInspectSpecialization, inspectPendingUnit)
    end

    if success and specializationID and specializationID > 0 then
        specializationByGUID[guid] = specializationID
    else
        specializationByGUID[guid] = 0
    end

    ClearPendingInspection()
    SocialDistancing:UpdateRangeOverlay()
end

function SocialDistancing:UpdateRangeOverlay()
    if not SocialDistancingDB.settingsKeys.showRangeOverlay then
        rangeFrame:Hide()
        return
    end

    if type(SocialDistancingDB.rangeAlertSettings) ~= "table" then
        SocialDistancingDB.rangeAlertSettings = {}
    end
    local rangeAlertSettings = SocialDistancingDB.rangeAlertSettings

    local rows = {}
    local shouldPlayRangeAlert = false
    local spellRangeCheck = _G["IsSpellInRange"]
    local spellAPI = _G["C_Spell"]
    spellRangeCheck = spellRangeCheck or (spellAPI and spellAPI.IsSpellInRange)
    local targetMode = self:GetUnitSpellMode("target")
    local targetSpell = self:GetConfiguredRangeSpell("target") or ""
    if UnitExists("target") then
        if targetSpell ~= "" and spellRangeCheck then
            local success, inRange = pcall(spellRangeCheck, targetSpell, "target")
            if success and (inRange == 1 or inRange == true) then
                local guid = UnitGUID("target") or UnitName("target") or "target"
                local alertKey = "target:" .. targetMode .. ":" .. targetSpell
                shouldPlayRangeAlert = (TrackRangeState("target:" .. guid .. ":" .. targetSpell, true) and rangeAlertSettings[alertKey]) or shouldPlayRangeAlert
                rows[#rows + 1] = "Target: |cff00ff00IN RANGE|r (" .. targetSpell .. ")"
            elseif success and (inRange == 0 or inRange == false) then
                local guid = UnitGUID("target") or UnitName("target") or "target"
                local alertKey = "target:" .. targetMode .. ":" .. targetSpell
                shouldPlayRangeAlert = (TrackRangeState("target:" .. guid .. ":" .. targetSpell, false) and rangeAlertSettings[alertKey]) or shouldPlayRangeAlert
                rows[#rows + 1] = "Target: |cffff4040OUT OF RANGE|r (" .. targetSpell .. ")"
            else
                rows[#rows + 1] = "Target: |cffffcc00Range unknown for " .. targetSpell .. "|r"
            end
        else
            rows[#rows + 1] = "Target: Choose a ranged spell for this unit in Settings"
        end
    else
        rows[#rows + 1] = "Target: No target"
    end

    local focusMode = self:GetUnitSpellMode("focus")
    local focusSpell = self:GetConfiguredRangeSpell("focus") or ""
    if UnitExists("focus") then
        if focusSpell ~= "" and spellRangeCheck then
            local success, inRange = pcall(spellRangeCheck, focusSpell, "focus")
            if success and (inRange == 1 or inRange == true) then
                local guid = UnitGUID("focus") or UnitName("focus") or "focus"
                local alertKey = "focus:" .. focusMode .. ":" .. focusSpell
                shouldPlayRangeAlert = (TrackRangeState("focus:" .. guid .. ":" .. focusSpell, true) and rangeAlertSettings[alertKey]) or shouldPlayRangeAlert
                rows[#rows + 1] = "Focus: |cff00ff00IN RANGE|r (" .. focusSpell .. ")"
            elseif success and (inRange == 0 or inRange == false) then
                local guid = UnitGUID("focus") or UnitName("focus") or "focus"
                local alertKey = "focus:" .. focusMode .. ":" .. focusSpell
                shouldPlayRangeAlert = (TrackRangeState("focus:" .. guid .. ":" .. focusSpell, false) and rangeAlertSettings[alertKey]) or shouldPlayRangeAlert
                rows[#rows + 1] = "Focus: |cffff4040OUT OF RANGE|r (" .. focusSpell .. ")"
            else
                rows[#rows + 1] = "Focus: |cffffcc00Range unknown for " .. focusSpell .. "|r"
            end
        else
            rows[#rows + 1] = "Focus: Choose a ranged spell for this unit in Settings"
        end
    else
        rows[#rows + 1] = "Focus: No focus"
    end

    rows[#rows + 1] = "Party member ranges:"
    local healerWarnings = {}

    if IsInRaid() then
        rows[#rows + 1] = "Party yard checks are unavailable in raids"
    else
        local playerX, playerY, _, playerMap
        if UnitPosition then
            playerX, playerY, _, playerMap = UnitPosition("player")
        end
        local memberCount = GetNumSubgroupMembers and GetNumSubgroupMembers() or 0
        if memberCount == 0 then
            rows[#rows + 1] = "Not in a party"
        else
            for index = 1, memberCount do
                local unit = "party" .. index
                local name = UnitName(unit) or unit
                local className = UnitClass(unit)
                local guid = UnitGUID(unit)
                local spellKey
                if SocialDistancingDB.settingsKeys.syncPartyRanges then
                    spellKey = SocialDistancingDB.partyRangeSpellKey
                else
                    spellKey = (guid and SocialDistancingDB.partyRangeSpellKeys[guid]) or SocialDistancingDB.partyRangeSpellKey
                end
                local partySpell = SocialDistancing.PartyRangeSpellByKey[spellKey] or SocialDistancing.PartyRangeSpells[1]
                local specializationID = guid and specializationByGUID[guid]
                local specializationName = specializationNames[specializationID]
                local isHealer = healerSpecializations[specializationID]
                local roleLabel = specializationName or (className or "Unknown class")
                    .. (specializationID == 0 and "; spec unknown" or "; checking spec")
                local memberX, memberY, _, memberMap
                if UnitPosition then
                    memberX, memberY, _, memberMap = UnitPosition(unit)
                end

                local distance
                local inRange
                if playerX and memberX and playerMap == memberMap then
                    local deltaX = memberX - playerX
                    local deltaY = memberY - playerY
                    distance = math.sqrt(deltaX * deltaX + deltaY * deltaY)
                    inRange = distance <= partySpell.range + 3
                elseif partySpell.range == 40 then
                    local unitInRange = _G["UnitInRange"]
                    if unitInRange then
                        local success, withinRange, checkedRange = pcall(unitInRange, unit)
                        if success and checkedRange then
                            inRange = withinRange
                        end
                    end
                end

                local rangeKey = guid and ("party:" .. guid .. ":" .. partySpell.key)
                if rangeKey then
                    local alertConfigKey
                    if SocialDistancingDB.settingsKeys.syncPartyRanges then
                        alertConfigKey = "party:shared:" .. partySpell.key
                    else
                        alertConfigKey = "party:" .. guid .. ":" .. partySpell.key
                    end
                    shouldPlayRangeAlert = (TrackRangeState(rangeKey, inRange) and rangeAlertSettings[alertConfigKey]) or shouldPlayRangeAlert
                end

                if inRange ~= nil then
                    local status = inRange and "IN RANGE" or "OUT OF RANGE"
                    local color = inRange and "ff00ff00" or "ffff4040"
                    if not inRange and isHealer then
                        status = "OUT OF HEALER RANGE"
                        healerWarnings[#healerWarnings + 1] = name .. " (" .. roleLabel .. ")"
                    elseif specializationID == 0 then
                        roleLabel = (className or "Unknown class") .. "; spec unknown"
                    end
                    local distanceLabel = distance and string.format("%.1f yd", distance) or "40 yd check"
                    rows[#rows + 1] = string.format("%s (%s): |c%s%s|r (%s)", name, roleLabel, color, status, distanceLabel)
                else
                    if specializationID == 0 then
                        roleLabel = (className or "Unknown class") .. "; spec unknown"
                    end
                    rows[#rows + 1] = name .. " (" .. roleLabel .. "): |cffaaaaaaDistance unavailable here|r"
                end
            end
        end
    end

    for _, healer in ipairs(healerWarnings) do
        rows[#rows + 1] = "|cffff4040OUT OF HEALER RANGE: " .. healer .. "|r"
    end
    rows[#rows + 1] = "Exact party yards are outdoor-only; 40 yd range checks also work indoors."
    rangeText:SetText(table.concat(rows, "\n"))
    rangeFrame:Show()

    if shouldPlayRangeAlert then
        PlaySound(3407)
    end
end

SocialDistancing:UpdateRangeOverlay()

local rangeUpdateFrame = CreateFrame("Frame")
rangeUpdateFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
rangeUpdateFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
rangeUpdateFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
rangeUpdateFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
rangeUpdateFrame:RegisterEvent("INSPECT_READY")
rangeUpdateFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "INSPECT_READY" then
        HandleInspectReady(...)
        return
    end

    if event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
        QueuePartyInspections()
    end
    SocialDistancing:UpdateRangeOverlay()
end)

local rangeUpdateElapsed = 0
rangeUpdateFrame:SetScript("OnUpdate", function(_, elapsed)
    rangeUpdateElapsed = rangeUpdateElapsed + elapsed
    if rangeUpdateElapsed >= 0.25 then
        rangeUpdateElapsed = 0
        if rangeFrame:IsShown() then
            SocialDistancing:UpdateRangeOverlay()
        end
    end

    if inspectRequestCooldown > 0 then
        inspectRequestCooldown = math.max(0, inspectRequestCooldown - elapsed)
    end

    if inspectPendingGUID then
        inspectPendingTimeout = inspectPendingTimeout - elapsed
        if inspectPendingTimeout <= 0 then
            ClearPendingInspection()
        end
    end

    inspectScanElapsed = inspectScanElapsed + elapsed
    if inspectScanElapsed >= 10 then
        inspectScanElapsed = 0
        QueuePartyInspections()
    end

    if not inspectPendingGUID and inspectRequestCooldown == 0 and #inspectQueue > 0 then
        local inCombat = _G["InCombatLockdown"]
        if inCombat and inCombat() then
            return
        end

        local unit = table.remove(inspectQueue, 1)
        local guid = UnitGUID(unit)
        local canInspect = _G["CanInspect"]
        local notifyInspect = _G["NotifyInspect"]
        if guid and notifyInspect and (not canInspect or canInspect(unit)) then
            local success = pcall(notifyInspect, unit)
            if success then
                inspectPendingGUID = guid
                inspectPendingUnit = unit
                inspectPendingTimeout = 5
                inspectRequestCooldown = 1.5
            end
        end
    end
end)

SLASH_SOCIALDISTANCING1 = "/socialdistancing"
SLASH_SOCIALDISTANCING2 = "/sd"
SlashCmdList["SOCIALDISTANCING"] = function()
    SocialDistancing:ToggleRangeOverlay()
end

table.insert(UISpecialFrames, "SocialDistancingRangeFrame")

function SocialDistancing:ToggleRangeOverlay()
    if rangeFrame:IsShown() then
        rangeFrame:Hide()
    else
        SocialDistancing:UpdateRangeOverlay()
    end
end