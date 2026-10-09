SocialDistancingDB = SocialDistancingDB or {}
SocialDistancingDB.settingsKeys = SocialDistancingDB.settingsKeys or {}
SocialDistancingDB.partyRangeSpellKeys = SocialDistancingDB.partyRangeSpellKeys or {}
SocialDistancingDB.targetFriendlyRangeSpell = SocialDistancingDB.targetFriendlyRangeSpell or ""
SocialDistancingDB.focusFriendlyRangeSpell = SocialDistancingDB.focusFriendlyRangeSpell or ""
if type(SocialDistancingDB.rangeAlertSettings) ~= "table" then
    SocialDistancingDB.rangeAlertSettings = {}
end

local function GetRangeAlertSettings()
    if type(SocialDistancingDB.rangeAlertSettings) ~= "table" then
        SocialDistancingDB.rangeAlertSettings = {}
    end
    return SocialDistancingDB.rangeAlertSettings
end

local settingsFrame = CreateFrame("Frame", "SocialDistancingSettingsFrame", UIParent, "BasicFrameTemplateWithInset")
settingsFrame:SetSize(420, 560)
settingsFrame:SetPoint("CENTER")
settingsFrame.TitleBg:SetHeight(30)
settingsFrame.title = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
settingsFrame.title:SetPoint("TOPLEFT", settingsFrame.TitleBg, "TOPLEFT", 0, -3)
settingsFrame.title:SetText("Social Distancing Settings")
settingsFrame:Hide()
settingsFrame:EnableMouse(true)
settingsFrame:SetMovable(true)
settingsFrame:RegisterForDrag("LeftButton")
settingsFrame:SetScript("OnDragStart", function (self)
    self:StartMoving()
end)
settingsFrame:SetScript("OnDragStop", function (self)
    self:StopMovingOrSizing()
end)

local settings = {
    {
        settingText = "Show target and party range overlay",
        settingKey = "showRangeOverlay",
        settingTooltip = "Show target spell range and party spell-range distances",
        defaultValue = true
    },
    {
        settingText = "Only show overlay while grouped",
        settingKey = "onlyShowRangeOverlayInParty",
        settingTooltip = "Hide the range overlay while solo (also applies to raids)",
        defaultValue = false
    },
    {
        settingText = "Sync one range across the party",
        settingKey = "syncPartyRanges",
        settingTooltip = "Use one healing range preset for every party member",
        defaultValue = false
    }
}

local checkboxes = 0
local settingCheckboxes = {}
local RefreshPartySelectors
local RefreshSpellAlertCheckboxes

function SocialDistancing:RefreshOverlaySettingCheckbox()
    local checkbox = settingCheckboxes.showRangeOverlay
    if checkbox then
        checkbox:SetChecked(SocialDistancingDB.settingsKeys.showRangeOverlay)
    end
end

local function CreateCheckbox(checkboxText, key, checkboxTooltip, defaultValue)
    local checkbox = CreateFrame("CheckButton", "SocialDistancingCheckboxID" .. checkboxes, settingsFrame, "UICheckButtonTemplate")
    checkbox.Text:SetText(checkboxText)
    checkbox:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 10, ((checkboxes + 1) * -30))

    if SocialDistancingDB.settingsKeys[key] == nil then
        if defaultValue == nil then
            SocialDistancingDB.settingsKeys[key] = true
        else
            SocialDistancingDB.settingsKeys[key] = defaultValue
        end
    end

    checkbox:SetChecked(SocialDistancingDB.settingsKeys[key])
    settingCheckboxes[key] = checkbox

    checkbox:SetScript("OnEnter", function (self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(checkboxTooltip, nil, nil, nil, nil, true)
    end)

    checkbox:SetScript("OnLeave", function (self)
        GameTooltip:Hide()
    end)

    checkbox:SetScript("OnClick", function (self)
        SocialDistancingDB.settingsKeys[key] = self:GetChecked()
        if key == "showRangeOverlay" or key == "onlyShowRangeOverlayInParty" then
            SocialDistancing:UpdateRangeOverlay()
        elseif key == "syncPartyRanges" then
            if RefreshPartySelectors then
                RefreshPartySelectors()
            end
            SocialDistancing:UpdateRangeOverlay()
        end
    end)

    checkboxes = checkboxes + 1

    return checkbox
end

local partyMemberLabel = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
partyMemberLabel:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 15, -125)
partyMemberLabel:SetText("Party member:")

local partyRangeLabel = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
partyRangeLabel:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 15, -185)
partyRangeLabel:SetText("Range spell for selected member:")

local function CreateDropdown(name, yOffset, prompt, optionsProvider, selectedValue, onSelect, includeEmpty)
    local dropdown = CreateFrame("Frame", name, settingsFrame, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", -5, yOffset)

    local setText = _G["UIDropDownMenu_SetText"]
    local createInfo = _G["UIDropDownMenu_CreateInfo"]
    local addButton = _G["UIDropDownMenu_AddButton"]
    _G["UIDropDownMenu_SetWidth"](dropdown, 250)
    function dropdown.SetDisplayValue(value)
        local selectedText = prompt
        if value ~= "" then
            for _, option in ipairs(optionsProvider()) do
                if option.value == value then
                    selectedText = option.selectedText or option.text
                    break
                end
            end
        end
        setText(dropdown, selectedText)
    end
    dropdown.SetDisplayValue(selectedValue)

    _G["UIDropDownMenu_Initialize"](dropdown, function(_, level)
        if includeEmpty ~= false then
            local emptyInfo = createInfo()
            emptyInfo.text = prompt
            emptyInfo.value = ""
            emptyInfo.func = function()
                onSelect("")
                dropdown.SetDisplayValue("")
                if RefreshSpellAlertCheckboxes then
                    RefreshSpellAlertCheckboxes()
                end
                SocialDistancing:UpdateRangeOverlay()
            end
            addButton(emptyInfo, level)
        end

        for _, option in ipairs(optionsProvider()) do
            local optionValue = option.value
            local optionText = option.menuText or option.text
            local info = createInfo()
            info.text = optionText
            info.value = optionValue
            info.icon = option.icon
            info.disabled = option.disabled
            info.tCoordLeft = option.tCoordLeft
            info.tCoordRight = option.tCoordRight
            info.tCoordTop = option.tCoordTop
            info.tCoordBottom = option.tCoordBottom
            info.func = function()
                onSelect(optionValue)
                dropdown.SetDisplayValue(optionValue)
                if RefreshSpellAlertCheckboxes then
                    RefreshSpellAlertCheckboxes()
                end
                SocialDistancing:UpdateRangeOverlay()
            end
            addButton(info, level)
        end
    end)

    return dropdown
end

local function GetClassIconMarkup(classToken)
    if not classToken then
        return ""
    end
    local classColor = _G["C_ClassColor"]
    local getClassAtlas = classColor and classColor.GetClassAtlas
    local atlas = getClassAtlas and getClassAtlas(classToken)
    atlas = atlas or ("classicon-" .. string.lower(classToken))
    return "|A:" .. atlas .. ":16:16|a"
end

local classIconFallbackCoords = {
    DRUID = { 0.75, 1, 0, 0.25 },
    HUNTER = { 0, 0.25, 0.25, 0.5 },
    MAGE = { 0.25, 0.5, 0, 0.25 },
    PALADIN = { 0, 0.25, 0.5, 0.75 },
    PRIEST = { 0.5, 0.75, 0.25, 0.5 },
    ROGUE = { 0.5, 0.75, 0, 0.25 },
    SHAMAN = { 0.25, 0.5, 0.25, 0.5 },
    WARLOCK = { 0.75, 1, 0.25, 0.5 },
    WARRIOR = { 0, 0.25, 0, 0.25 },
}

local function GetClassIconData(classToken)
    local coords = (_G["CLASS_ICON_TCOORDS"] and _G["CLASS_ICON_TCOORDS"][classToken])
        or classIconFallbackCoords[classToken]
    return "Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES", coords
end

local function GetSpellTexture(spellID)
    local spellAPI = _G["C_Spell"]
    local getSpellTexture = spellAPI and spellAPI.GetSpellTexture or _G["GetSpellTexture"]
    if getSpellTexture then
        local success, texture = pcall(getSpellTexture, spellID)
        if success then
            return texture
        end
    end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function GetSpellIconMarkup(spellID)
    return "|T" .. GetSpellTexture(spellID) .. ":16:16|t"
end

local selectedPartyGUID = SocialDistancingDB.partySettingsMemberGUID or ""

local function GetRelevantPartyClasses()
    local classes = {}
    local _, playerClass = UnitClass("player")
    if playerClass then
        classes[playerClass] = true
    end

    local memberCount = GetNumSubgroupMembers and GetNumSubgroupMembers() or 0
    for index = 1, memberCount do
        local unit = "party" .. index
        local guid = UnitGUID(unit)
        if (SocialDistancingDB.settingsKeys.syncPartyRanges and guid) or guid == selectedPartyGUID then
            local _, classToken = UnitClass(unit)
            if classToken then
                classes[classToken] = true
            end
        end
    end
    return classes
end

local function GetPartyRangeOptions()
    local options = {}
    local relevantClasses = GetRelevantPartyClasses()
    for _, spell in ipairs(SocialDistancing.PartyRangeSpells) do
        if relevantClasses[spell.class] then
            local classTexture, coords = GetClassIconData(spell.class)
            local spellLabel = GetSpellIconMarkup(spell.spellID) .. " " .. spell.label
            options[#options + 1] = {
                value = spell.key,
                text = spellLabel,
                menuText = spellLabel,
                icon = classTexture,
                tCoordLeft = coords and coords[1],
                tCoordRight = coords and coords[2],
                tCoordTop = coords and coords[3],
                tCoordBottom = coords and coords[4],
            }
        end
    end
    if #options == 0 then
        options[1] = {
            value = "",
            text = "No healing presets for these classes",
            menuText = "No healing presets for these classes",
        }
    end
    return options
end

local partyRangeSpellDropdown

local function GetPartyMemberOptions()
    local options = {}
    local memberCount = GetNumSubgroupMembers and GetNumSubgroupMembers() or 0
    for index = 1, memberCount do
        local unit = "party" .. index
        local guid = UnitGUID(unit)
        if guid then
            local name = UnitName(unit) or unit
            local className, classToken = UnitClass(unit)
            options[#options + 1] = {
                value = guid,
                text = GetClassIconMarkup(classToken) .. " " .. name .. " (" .. (className or "?") .. ")",
            }
        end
    end
    if #options == 0 then
        options[1] = { value = "__no_party__", text = "Not in a party", disabled = true }
    end
    return options
end

local function GetMemberPartySpellKey(guid)
    if SocialDistancingDB.settingsKeys.syncPartyRanges then
        return SocialDistancingDB.partyRangeSpellKey or "priest_heal"
    end
    if guid and guid ~= "" then
        return SocialDistancingDB.partyRangeSpellKeys[guid] or SocialDistancingDB.partyRangeSpellKey or "priest_heal"
    end
    return SocialDistancingDB.partyRangeSpellKey or "priest_heal"
end

partyRangeSpellDropdown = CreateDropdown(
    "SocialDistancingPartyRangeSpellDropdown",
    -205,
    "Choose a class spell range",
    GetPartyRangeOptions,
    GetMemberPartySpellKey(selectedPartyGUID),
    function(value)
        if value ~= "" then
            if SocialDistancingDB.settingsKeys.syncPartyRanges then
                SocialDistancingDB.partyRangeSpellKey = value
            elseif selectedPartyGUID ~= "" then
                SocialDistancingDB.partyRangeSpellKeys[selectedPartyGUID] = value
            end
        end
    end,
    false
)

local partyMemberDropdown = CreateDropdown(
    "SocialDistancingPartyMemberDropdown",
    -145,
    "Choose a party member",
    GetPartyMemberOptions,
    selectedPartyGUID,
    function(value)
        selectedPartyGUID = value
        SocialDistancingDB.partySettingsMemberGUID = value
        partyRangeSpellDropdown.SetDisplayValue(GetMemberPartySpellKey(value))
    end,
    false
)

local targetHostileSpellLabel, targetHostileSpellDropdown
local targetFriendlySpellLabel, targetFriendlySpellDropdown
local focusHostileSpellLabel, focusHostileSpellDropdown
local focusFriendlySpellLabel, focusFriendlySpellDropdown
local targetHostileAlertCheckbox, targetFriendlyAlertCheckbox
local focusHostileAlertCheckbox, focusFriendlyAlertCheckbox, partyAlertCheckbox
local SetPartyControlsEnabled

RefreshPartySelectors = function()
    local options = GetPartyMemberOptions()
    local hasParty = #options > 0 and not options[1].disabled
    local selectedExists = false
    for _, option in ipairs(options) do
        if option.value == selectedPartyGUID then
            selectedExists = true
            break
        end
    end
    if not hasParty then
        selectedPartyGUID = ""
        SocialDistancingDB.partySettingsMemberGUID = ""
    elseif not selectedExists then
        selectedPartyGUID = options[1].value
        SocialDistancingDB.partySettingsMemberGUID = selectedPartyGUID
    end

    local syncRanges = hasParty and SocialDistancingDB.settingsKeys.syncPartyRanges
    if syncRanges then
        partyMemberLabel:Hide()
        partyMemberDropdown:Hide()
        partyRangeLabel:SetText("Shared party range spell:")
        partyRangeLabel:ClearAllPoints()
        partyRangeLabel:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 15, -125)
        partyRangeSpellDropdown:ClearAllPoints()
        partyRangeSpellDropdown:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", -5, -145)
        targetHostileSpellLabel:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 15, -185)
        targetHostileSpellDropdown:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", -5, -205)
        targetFriendlySpellLabel:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 15, -245)
        targetFriendlySpellDropdown:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", -5, -265)
        focusHostileSpellLabel:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 15, -305)
        focusHostileSpellDropdown:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", -5, -325)
        focusFriendlySpellLabel:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 15, -365)
        focusFriendlySpellDropdown:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", -5, -385)
        partyAlertCheckbox:ClearAllPoints()
        partyAlertCheckbox:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 285, -145)
        targetHostileAlertCheckbox:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 285, -205)
        targetFriendlyAlertCheckbox:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 285, -265)
        focusHostileAlertCheckbox:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 285, -325)
        focusFriendlyAlertCheckbox:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 285, -385)
    else
        partyMemberLabel:Show()
        partyMemberDropdown:Show()
        partyRangeLabel:SetText("Range spell for selected member:")
        partyRangeLabel:ClearAllPoints()
        partyRangeLabel:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 15, -185)
        partyRangeSpellDropdown:ClearAllPoints()
        partyRangeSpellDropdown:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", -5, -205)
        targetHostileSpellLabel:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 15, -245)
        targetHostileSpellDropdown:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", -5, -265)
        targetFriendlySpellLabel:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 15, -305)
        targetFriendlySpellDropdown:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", -5, -325)
        focusHostileSpellLabel:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 15, -365)
        focusHostileSpellDropdown:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", -5, -385)
        focusFriendlySpellLabel:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 15, -425)
        focusFriendlySpellDropdown:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", -5, -445)
        partyAlertCheckbox:ClearAllPoints()
        partyAlertCheckbox:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 285, -205)
        targetHostileAlertCheckbox:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 285, -265)
        targetFriendlyAlertCheckbox:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 285, -325)
        focusHostileAlertCheckbox:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 285, -385)
        focusFriendlyAlertCheckbox:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 285, -445)
    end
    partyMemberDropdown.SetDisplayValue(hasParty and selectedPartyGUID or "__no_party__")
    partyRangeSpellDropdown.SetDisplayValue(GetMemberPartySpellKey(selectedPartyGUID))
    if RefreshSpellAlertCheckboxes then
        RefreshSpellAlertCheckboxes()
    end
    SetPartyControlsEnabled(hasParty)
end

targetHostileSpellLabel = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
targetHostileSpellLabel:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 15, -245)
targetHostileSpellLabel:SetText("Target hostile spell:")

targetFriendlySpellLabel = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
targetFriendlySpellLabel:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 15, -305)
targetFriendlySpellLabel:SetText("Target friendly spell:")

focusHostileSpellLabel = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
focusHostileSpellLabel:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 15, -365)
focusHostileSpellLabel:SetText("Focus hostile spell:")

focusFriendlySpellLabel = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
focusFriendlySpellLabel:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 15, -425)
focusFriendlySpellLabel:SetText("Focus friendly spell:")

local function GetKnownSpellOptions(spellMode)
    local spells = {}
    local seen = {}
    local spellAPI = _G["C_Spell"]
    local isFriendly = spellMode == "friendly"
    local spellCheck
    local legacySpellCheck
    if isFriendly then
        spellCheck = spellAPI and spellAPI.IsSpellHelpful
        legacySpellCheck = _G["IsHelpfulSpell"]
    else
        spellCheck = spellAPI and spellAPI.IsSpellHarmful
        legacySpellCheck = _G["IsHarmfulSpell"]
    end

    local function HasExplicitRange(spellID, spellName)
        local maxRange
        if spellAPI and spellAPI.GetSpellInfo then
            local success, spellInfo = pcall(spellAPI.GetSpellInfo, spellID or spellName)
            if success and type(spellInfo) == "table" then
                maxRange = spellInfo.maxRange
            end
        end

        if maxRange == nil and _G["GetSpellInfo"] then
            local success, _, _, _, _, _, legacyMaxRange = pcall(_G["GetSpellInfo"], spellID or spellName)
            if success then
                maxRange = legacyMaxRange
            end
        end

        return type(maxRange) == "number" and maxRange > 0
    end

    local function AddSpell(spellName, spellID, slot, spellBank)
        local usableOnUnit = false
        if spellCheck and spellID then
            local success, result = pcall(spellCheck, spellID)
            usableOnUnit = success and result
        elseif legacySpellCheck and slot then
            local success, result = pcall(legacySpellCheck, slot, spellBank)
            usableOnUnit = success and result
        end

        if usableOnUnit and HasExplicitRange(spellID, spellName) and spellName and spellName ~= "" and not seen[spellName] then
            seen[spellName] = true
            local spellTexture = GetSpellTexture(spellID or spellName)
            spells[#spells + 1] = {
                value = spellName,
                text = GetSpellIconMarkup(spellID or spellName) .. " " .. spellName,
                menuText = spellName,
                icon = spellTexture,
            }
        end
    end

    local spellBook = _G["C_SpellBook"]
    if spellBook and spellBook.GetNumSpellBookSkillLines and spellBook.GetSpellBookSkillLineInfo and spellBook.GetSpellBookItemName then
        local enum = _G["Enum"]
        local spellBank = enum and enum.SpellBookSpellBank and enum.SpellBookSpellBank.Player or 0
        local spellItemType = enum and enum.SpellBookItemType and enum.SpellBookItemType.Spell or 1
        for tab = 1, spellBook.GetNumSpellBookSkillLines() do
            local skillLine = spellBook.GetSpellBookSkillLineInfo(tab)
            if skillLine then
                local firstSlot = (skillLine.itemIndexOffset or 0) + 1
                local lastSlot = firstSlot + (skillLine.numSpellBookItems or 0) - 1
                for slot = firstSlot, lastSlot do
                    local spellName = spellBook.GetSpellBookItemName(slot, spellBank)
                    local itemType, _, spellID = spellBook.GetSpellBookItemType(slot, spellBank)
                    if itemType == spellItemType then
                        AddSpell(spellName, spellID, slot, spellBank)
                    end
                end
            end
        end
    else
        local getNumTabs = _G["GetNumSpellTabs"]
        local getTabInfo = _G["GetSpellTabInfo"]
        local getItemName = _G["GetSpellBookItemName"]
        local getItemInfo = _G["GetSpellBookItemInfo"]
        if not getNumTabs or not getTabInfo or not getItemName then
            return spells
        end

        local bookType = _G["BOOKTYPE_SPELL"] or "spell"
        for tab = 1, getNumTabs() do
            local _, _, offset, spellCount = getTabInfo(tab)
            for slot = (offset or 0) + 1, (offset or 0) + (spellCount or 0) do
                local spellName = getItemName(slot, bookType)
                local spellID
                if getItemInfo then
                    local _, itemID = getItemInfo(slot, bookType)
                    spellID = itemID
                end
                AddSpell(spellName, spellID, slot, bookType)
            end
        end
    end

    table.sort(spells, function(left, right)
        return left.text < right.text
    end)
    return spells
end

targetHostileSpellDropdown = CreateDropdown(
    "SocialDistancingTargetHostileSpellDropdown",
    -265,
    "Choose a ranged spell",
    function()
        return GetKnownSpellOptions("hostile")
    end,
    SocialDistancingDB.targetRangeSpell or "",
    function(value)
        SocialDistancingDB.targetRangeSpell = value
    end
)

targetFriendlySpellDropdown = CreateDropdown(
    "SocialDistancingTargetFriendlySpellDropdown",
    -325,
    "Choose a ranged spell",
    function()
        return GetKnownSpellOptions("friendly")
    end,
    SocialDistancingDB.targetFriendlyRangeSpell or "",
    function(value)
        SocialDistancingDB.targetFriendlyRangeSpell = value
    end
)

focusHostileSpellDropdown = CreateDropdown(
    "SocialDistancingFocusHostileSpellDropdown",
    -385,
    "Choose a ranged spell",
    function()
        return GetKnownSpellOptions("hostile")
    end,
    SocialDistancingDB.focusRangeSpell or "",
    function(value)
        SocialDistancingDB.focusRangeSpell = value
    end
)

focusFriendlySpellDropdown = CreateDropdown(
    "SocialDistancingFocusFriendlySpellDropdown",
    -445,
    "Choose a ranged spell",
    function()
        return GetKnownSpellOptions("friendly")
    end,
    SocialDistancingDB.focusFriendlyRangeSpell or "",
    function(value)
        SocialDistancingDB.focusFriendlyRangeSpell = value
    end
)

local function GetRangeAlertKey(unit, mode, spell)
    return spell ~= "" and (unit .. ":" .. mode .. ":" .. spell) or nil
end

local function GetTargetHostileAlertKey()
    return GetRangeAlertKey("target", "hostile", SocialDistancingDB.targetRangeSpell or "")
end

local function GetTargetFriendlyAlertKey()
    return GetRangeAlertKey("target", "friendly", SocialDistancingDB.targetFriendlyRangeSpell or "")
end

local function GetFocusHostileAlertKey()
    return GetRangeAlertKey("focus", "hostile", SocialDistancingDB.focusRangeSpell or "")
end

local function GetFocusFriendlyAlertKey()
    return GetRangeAlertKey("focus", "friendly", SocialDistancingDB.focusFriendlyRangeSpell or "")
end

local function GetPartyAlertKey()
    if not GetNumSubgroupMembers or GetNumSubgroupMembers() == 0 then
        return nil
    end
    local spellKey = GetMemberPartySpellKey(selectedPartyGUID)
    if not spellKey or spellKey == "" then
        return nil
    end
    if SocialDistancingDB.settingsKeys.syncPartyRanges then
        return "party:shared:" .. spellKey
    end
    if selectedPartyGUID ~= "" then
        return "party:" .. selectedPartyGUID .. ":" .. spellKey
    end
end

SetPartyControlsEnabled = function(enabled)
    local enableDropdown = _G["UIDropDownMenu_EnableDropDown"]
    local disableDropdown = _G["UIDropDownMenu_DisableDropDown"]
    if enabled then
        if enableDropdown then
            enableDropdown(partyMemberDropdown)
            enableDropdown(partyRangeSpellDropdown)
        else
            partyMemberDropdown:Enable()
            partyRangeSpellDropdown:Enable()
        end
        partyMemberLabel:SetTextColor(1, 0.82, 0)
        partyRangeLabel:SetTextColor(1, 0.82, 0)
        partyAlertCheckbox:Enable()
        partyAlertCheckbox.Text:SetTextColor(1, 0.82, 0)
        if settingCheckboxes.syncPartyRanges then
            settingCheckboxes.syncPartyRanges:Enable()
            settingCheckboxes.syncPartyRanges.Text:SetTextColor(1, 0.82, 0)
        end
    else
        if disableDropdown then
            disableDropdown(partyMemberDropdown)
            disableDropdown(partyRangeSpellDropdown)
        else
            partyMemberDropdown:Disable()
            partyRangeSpellDropdown:Disable()
        end
        partyMemberLabel:SetTextColor(0.5, 0.5, 0.5)
        partyRangeLabel:SetTextColor(0.5, 0.5, 0.5)
        partyAlertCheckbox:Disable()
        partyAlertCheckbox.Text:SetTextColor(0.5, 0.5, 0.5)
        if settingCheckboxes.syncPartyRanges then
            settingCheckboxes.syncPartyRanges:Disable()
            settingCheckboxes.syncPartyRanges.Text:SetTextColor(0.5, 0.5, 0.5)
        end
    end
end

local function CreateRangeAlertCheckbox(name, keyProvider, yOffset)
    local checkbox = CreateFrame("CheckButton", name, settingsFrame, "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 285, yOffset)
    checkbox.Text:SetText("Alert")
    checkbox:SetScript("OnClick", function(self)
        local key = keyProvider()
        if key then
            GetRangeAlertSettings()[key] = self:GetChecked()
        end
    end)
    return checkbox
end

targetHostileAlertCheckbox = CreateRangeAlertCheckbox("SocialDistancingTargetHostileRangeAlert", GetTargetHostileAlertKey, -265)
targetFriendlyAlertCheckbox = CreateRangeAlertCheckbox("SocialDistancingTargetFriendlyRangeAlert", GetTargetFriendlyAlertKey, -325)
focusHostileAlertCheckbox = CreateRangeAlertCheckbox("SocialDistancingFocusHostileRangeAlert", GetFocusHostileAlertKey, -385)
focusFriendlyAlertCheckbox = CreateRangeAlertCheckbox("SocialDistancingFocusFriendlyRangeAlert", GetFocusFriendlyAlertKey, -445)
partyAlertCheckbox = CreateRangeAlertCheckbox("SocialDistancingPartyRangeAlert", GetPartyAlertKey, -205)

local function RefreshAlertCheckbox(checkbox, key)
    if key then
        checkbox:Enable()
        checkbox:SetChecked(GetRangeAlertSettings()[key] == true)
    else
        checkbox:Disable()
        checkbox:SetChecked(false)
    end
end

RefreshSpellAlertCheckboxes = function()
    RefreshAlertCheckbox(targetHostileAlertCheckbox, GetTargetHostileAlertKey())
    RefreshAlertCheckbox(targetFriendlyAlertCheckbox, GetTargetFriendlyAlertKey())
    RefreshAlertCheckbox(focusHostileAlertCheckbox, GetFocusHostileAlertKey())
    RefreshAlertCheckbox(focusFriendlyAlertCheckbox, GetFocusFriendlyAlertKey())
    RefreshAlertCheckbox(partyAlertCheckbox, GetPartyAlertKey())
end

local eventListenerFrame = CreateFrame("Frame", "SocialDistancingEventListenerFrame", UIParent)

eventListenerFrame:RegisterEvent("PLAYER_LOGIN")
eventListenerFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventListenerFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

eventListenerFrame:SetScript("OnEvent", function (self, event)
    if event == "PLAYER_LOGIN" then
        for _, setting in pairs(settings) do
            CreateCheckbox(setting.settingText, setting.settingKey, setting.settingTooltip, setting.defaultValue)
        end
    end
    if event == "PLAYER_LOGIN" or event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
        RefreshPartySelectors()
    end
end)

function SocialDistancing:ToggleSettings()
    if settingsFrame:IsShown() then
        settingsFrame:Hide()
    else
        settingsFrame:Show()
    end
end
