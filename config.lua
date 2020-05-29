local name = ...
    
local frame = CreateFrame("Frame", name .. "ConfigFrame", InterfaceOptionsFramePanelContainer)
frame.name = name
frame:Hide()
frame:SetScript("OnShow", function(frame)
    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("tooltipSimc Configuration")

    local offHandConfig = CreateFrame("CheckButton", name .. "addOffHandButtonConfig", frame, "ChatConfigCheckButtonTemplate")
    offHandConfig.Text:SetText("+ Off Hand")
    offHandConfig:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -15)
    offHandConfig:SetChecked(tooltipSimcDB.offHand)
    offHandConfig:SetScript("OnClick", function(self) 
        tooltipToSimcDB.offHand = self:GetChecked() 
    end)

    
    if IsAddOnLoaded("Simulationcraft") then
        local onlyItemConfig = CreateFrame("CheckButton", name.."onlyItemButtonConfig", frame, "ChatConfigCheckButtonTemplate")
        onlyItemConfig.Text:SetText("SimC Integration")
        onlyItemConfig:SetPoint("TOPLEFT", offHandConfig, "BOTTOMLEFT", 0, -5)
        onlyItemConfig:SetChecked(tooltipSimcDB.onlyItem)
        onlyItemConfig:SetScript("OnClick", function(self)
            tooltipToSimcDB.onlyItem = self:GetChecked()
        end)
    else
        tooltipToSimcDB.onlyItem = true
    end
end)

InterfaceOptions_AddCategory(frame)
