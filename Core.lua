SocialDistancing = SocialDistancing or {}

if not SocialDistancingDB then
    SocialDistancingDB = {}
end
SocialDistancingDB.settingsKeys = SocialDistancingDB.settingsKeys or {}
SocialDistancingDB.partyRangeSpellKey = SocialDistancingDB.partyRangeSpellKey or "priest_heal"
SocialDistancingDB.partyRangeSpellKeys = SocialDistancingDB.partyRangeSpellKeys or {}
SocialDistancingDB.targetRangeSpell = SocialDistancingDB.targetRangeSpell or ""
SocialDistancingDB.focusRangeSpell = SocialDistancingDB.focusRangeSpell or ""
SocialDistancingDB.targetFriendlyRangeSpell = SocialDistancingDB.targetFriendlyRangeSpell or ""
SocialDistancingDB.focusFriendlyRangeSpell = SocialDistancingDB.focusFriendlyRangeSpell or ""
if type(SocialDistancingDB.rangeAlertSettings) ~= "table" then
    SocialDistancingDB.rangeAlertSettings = {}
end
if SocialDistancingDB.settingsKeys.showRangeOverlay == nil then
    SocialDistancingDB.settingsKeys.showRangeOverlay = true
end
if SocialDistancingDB.settingsKeys.onlyShowRangeOverlayInParty == nil then
    SocialDistancingDB.settingsKeys.onlyShowRangeOverlayInParty = false
end
if SocialDistancingDB.settingsKeys.syncPartyRanges == nil then
    SocialDistancingDB.settingsKeys.syncPartyRanges = false
end

SocialDistancing.PartyRangeSpells = {
    { key = "priest_heal", label = "Heal (40 yd)", range = 40, class = "PRIEST", spellID = 2050 },
    { key = "priest_flash_heal", label = "Flash Heal (40 yd)", range = 40, class = "PRIEST", spellID = 2061 },
    { key = "priest_greater_heal", label = "Greater Heal (40 yd)", range = 40, class = "PRIEST", spellID = 2060 },
    { key = "priest_shield", label = "Power Word: Shield (40 yd)", range = 40, class = "PRIEST", spellID = 17 },
    { key = "priest_prayer_heal", label = "Prayer of Healing (30 yd)", range = 30, class = "PRIEST", spellID = 596 },
    { key = "paladin_holy_light", label = "Holy Light (40 yd)", range = 40, class = "PALADIN", spellID = 635 },
    { key = "paladin_flash_light", label = "Flash of Light (40 yd)", range = 40, class = "PALADIN", spellID = 19750 },
    { key = "druid_healing_touch", label = "Healing Touch (40 yd)", range = 40, class = "DRUID", spellID = 5185 },
    { key = "druid_regrowth", label = "Regrowth (40 yd)", range = 40, class = "DRUID", spellID = 8936 },
    { key = "druid_rejuvenation", label = "Rejuvenation (40 yd)", range = 40, class = "DRUID", spellID = 774 },
    { key = "shaman_healing_wave", label = "Healing Wave (40 yd)", range = 40, class = "SHAMAN", spellID = 331 },
    { key = "shaman_lesser_healing_wave", label = "Lesser Healing Wave (40 yd)", range = 40, class = "SHAMAN", spellID = 8004 },
    { key = "shaman_chain_heal", label = "Chain Heal (40 yd)", range = 40, class = "SHAMAN", spellID = 1064 },
}
SocialDistancing.PartyRangeSpellByKey = {}
for _, spell in ipairs(SocialDistancing.PartyRangeSpells) do
    SocialDistancing.PartyRangeSpellByKey[spell.key] = spell
end

function SocialDistancing:GetUnitSpellMode(unit)
    if UnitExists(unit) and UnitCanAssist and UnitCanAssist("player", unit) then
        return "friendly"
    end
    return "hostile"
end

function SocialDistancing:GetConfiguredRangeSpell(unit)
    local spellMode = self:GetUnitSpellMode(unit)
    if unit == "target" then
        return spellMode == "friendly" and SocialDistancingDB.targetFriendlyRangeSpell or SocialDistancingDB.targetRangeSpell
    elseif unit == "focus" then
        return spellMode == "friendly" and SocialDistancingDB.focusFriendlyRangeSpell or SocialDistancingDB.focusRangeSpell
    end
end

function SocialDistancing:SetConfiguredRangeSpell(unit, spellMode, spellName)
    if unit == "target" then
        if spellMode == "friendly" then
            SocialDistancingDB.targetFriendlyRangeSpell = spellName
        else
            SocialDistancingDB.targetRangeSpell = spellName
        end
    elseif unit == "focus" then
        if spellMode == "friendly" then
            SocialDistancingDB.focusFriendlyRangeSpell = spellName
        else
            SocialDistancingDB.focusRangeSpell = spellName
        end
    end
end
