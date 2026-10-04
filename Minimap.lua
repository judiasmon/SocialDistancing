local addon = LibStub("AceAddon-3.0"):NewAddon("SocialDistancing")
SocialDistancingMinimapButton = LibStub("LibDBIcon-1.0")

local miniButton = LibStub("LibDataBroker-1.1"):NewDataObject("SocialDistancing", {
    type = "data source",
    title = "Social Distancing",
    icon = "Interface\\Icons\\Ability_Hunter_FocusedAim",
    OnClick = function(self, btn)
        if btn == "LeftButton" then
            SocialDistancing:ToggleRangeOverlay()
        elseif btn == "RightButton" then
            SocialDistancing:ToggleSettings()
        end
    end,
    OnTooltipShow = function(tooltip)
        if not tooltip or not tooltip.AddLine then
            return
        end

        tooltip:AddLine("Social Distancing\n\nLeft-click: Toggle range overlay\nRight-click: Open Settings", nil, nil, nil, nil)
    end,
})

function addon:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("SocialDistancingMinimapPOS", {
        profile = {
            minimap = {
                hide = false,
            }
        }
    })

    SocialDistancingMinimapButton:Register("SocialDistancing", miniButton, self.db.profile.minimap)
end

SocialDistancingMinimapButton:Show("SocialDistancing")