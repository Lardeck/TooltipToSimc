local name = ...

local itemInfo, db
local equipLocToSlot = {
	INVTYPE_HEAD='head',
	INVTYPE_NECK='neck',
	INVTYPE_SHOULDER='shoulder',
	INVTYPE_CLOAK='back',
	INVTYPE_CHEST='chest',
	INVTYPE_ROBE='chest',
	INVTYPE_BODY='shirt',
	INVTYPE_TABARD='tabard',
	INVTYPE_WRIST='wrist',
	INVTYPE_HAND='hands',
	INVTYPE_WAIST='waist',
	INVTYPE_LEGS='legs',
	INVTYPE_FEET='feet',
	INVTYPE_FINGER='finger1',
	INVTYPE_TRINKET='trinket1',
	INVTYPE_WEAPON='main_hand',
	INVTYPE_2HWEAPON='main_hand',
	INVTYPE_RANGED='main_hand',
	INVTYPE_RANGEDRIGHT='main_hand',
	INVTYPE_SHIELD='off_hand',
	INVTYPE_HOLDABLE='off_hand',
}

local oneHandWeapons = {
	[0] = LE_ITEM_WEAPON_AXE1H,
	[4] = LE_ITEM_WEAPON_MACE1H,
	[7] = LE_ITEM_WEAPON_SWORD1H,
	[9] = LE_ITEM_WEAPON_WARGLAIVE,
	[13] = LE_ITEM_WEAPON_UNARMED,
	[15] = LE_ITEM_WEAPON_DAGGER,
}

local function getItemSplit(itemString)
	local itemSplit = {}

	for _, v in ipairs({strsplit(":", itemString)}) do
    	if v == "" then
      		itemSplit[#itemSplit + 1] = 0
    	else
      		itemSplit[#itemSplit + 1] = tonumber(v)
    	end
  	end

  	return itemSplit
end

local function getItemInfo(itemSplit, slot, itemLink)
	local itemInfo = {}
	local gems = {}
	local gemBonuses = {}
	local itemId = itemSplit[1]
	itemInfo[#itemInfo + 1] = ',id=' .. itemId

	--[[ Enchant
	if itemSplit[2] > 0 then
		itemInfo[#itemInfo + 1] = 'enchant_id=' .. itemSplit[2]
	end

	Gems
	for gemOffset = 3, 6 do
		local gemIndex = (gemOffset - 3) + 1
		if itemSplit[gemOffset] > 0 then
			local _, gemLink = GetItemGem(itemLink, gemIndex)
			if gemLink ~= nil then
				local itemId = string.match(gemLink, "item:(%d+)")
				local gemId = itemId and tonumber(itemId) or 0
				if gemId > 0 then
					local gemSplit = getItemSplit(gemLink)
					local bonuses = {}

				    for index=1, gemSplit[13] do
  						bonuses[#bonuses + 1] = gemSplit[13 + index]
					end
					gems[gemIndex] = gemId
					gemBonuses[gemIndex] = #bonuses > 0 and table.concat(bonuses, ":") or 0
				end
			end
		else
			gems[gemIndex] = 0
			gemBonuses[gemIndex] = 0
		end
	end

	-- Remove any trailing zeros from the gems array
	while #gems > 0 and gems[#gems] == 0 do
		table.remove(gems, #gems)
	end

	-- Remove any trailing zeros from the gem bonuses
	while #gemBonuses > 0 and gemBonuses[#gemBonuses] == 0 do
		table.remove(gemBonuses, #gemBonuses)
	end

	if #gems > 0 then
		itemInfo[#itemInfo + 1] = 'gem_id=' .. table.concat(gems, '/')
		if #gemBonuses > 0 then
			itemInfo[#itemInfo + 1] = 'gem_bonus_id=' .. table.concat(gemBonuses, '/')
		end
	end]]

	-- New style item suffix, old suffix style not supported
	if itemSplit[7] ~= 0 then
		itemInfo[#itemInfo + 1] = 'suffix=' .. itemSplit[7]
	end

	local flags = itemSplit[11]

	local bonuses = {}

	for index=1, itemSplit[13] do
		bonuses[#bonuses + 1] = itemSplit[13 + index]
	end

	if #bonuses > 0 then
		itemInfo[#itemInfo + 1] = 'bonus_id=' .. table.concat(bonuses, '/')
	end

	local linkOffset = 13 + #bonuses + 1

	-- Upgrade level
	if bit.band(flags, 0x4) == 0x4 then
		local upgradeId = itemSplit[linkOffset]
		if upgradeTable and upgradeTable[upgradeId] ~= nil and upgradeTable[upgradeId] > 0 then
			itemInfo[#itemInfo + 1] = 'upgrade=' .. upgradeTable[upgradeId]
		end
		linkOffset = linkOffset + 1
	end

	-- Some leveling quest items seem to use this, it'll include the drop level of the item
	if bit.band(flags, 0x200) == 0x200 then
		itemInfo[#itemInfo + 1] = 'drop_level=' .. itemSplit[linkOffset]
		linkOffset = linkOffset + 1
	end

	-- Get item creation context. Can be used to determine unlock/availability of azerite tiers for 3rd parties
	if itemSplit[12] ~= 0 then
		itemInfo[#itemInfo + 1] = 'context=' .. itemSplit[12]
	end

	-- Azerite powers - only run in BfA client
	if itemLoc and AzeriteEmpoweredItem then
		if AzeriteEmpoweredItem.IsAzeriteEmpoweredItem(itemLoc) then
			local azeritePowers = {}
			local powerIndex = 1
			local tierInfo = AzeriteEmpoweredItem.GetAllTierInfo(itemLoc)
			for azeriteTier, tierInfo in pairs(tierInfo) do
				for _, powerId in pairs(tierInfo.azeritePowerIDs) do
					if AzeriteEmpoweredItem.IsPowerSelected(itemLoc, powerId) then
						azeritePowers[powerIndex] = powerId
						powerIndex = powerIndex + 1
					end
				end
			end
			itemInfo[#itemInfo + 1] = 'azerite_powers=' .. table.concat(azeritePowers, '/')
		end

		if AzeriteItem.IsAzeriteItem(itemLoc) then
			itemInfo[#itemInfo + 1] = 'azerite_level=' .. AzeriteItem.GetPowerLevel(itemLoc)
		end
	end

	local str = '# '
	str = str .. slot .. "=" .. table.concat(itemInfo, ',')

	return str
end

local function setupDialogBox()
	if itemInfo and not _G[name .. "ItemInfo"] then
		local itemInfoCF = CreateFrame("ScrollFrame", name .. "ItemInfo", nil, "InputScrollFrameTemplate")
		itemInfoCF:SetMovable(true)
		itemInfoCF:EnableMouse(true)
		itemInfoCF:RegisterForDrag("LeftButton")
		itemInfoCF:SetScript("OnDragStart", itemInfoCF.StartMoving)
		itemInfoCF:SetScript("OnDragStop", itemInfoCF.StopMovingOrSizing)
		itemInfoCF:SetToplevel(true)
		itemInfoCF:SetWidth(450)
		itemInfoCF:SetHeight(65)
		table.insert(UISpecialFrames, name .. "ItemInfo")
		itemInfoCF:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
		itemInfoCF.CharCount:Hide()
		itemInfoCF.EditBox:SetFont("Fonts/FRIZQT__.TTF", 11)
		itemInfoCF.EditBox:SetText(itemInfo)

		if db.off_hand and _G[name.."check_button"]:IsShown() then
			itemInfoCF.EditBox:Insert("\n"..getItemInfo(_G[name.."check_button"].itemSplit, "off_hand", _G[name.."check_button"].itemLink))
		end

		itemInfoCF.EditBox:HighlightText()
		itemInfoCF.EditBox:SetFocus()
		itemInfoCF.EditBox:SetWidth(440)
		itemInfoCF:Show()

		local button = CreateFrame("Button", nil, itemInfoCF, "StaticPopupButtonTemplate")
		button:SetPoint("BOTTOM", itemInfoCF, "BOTTOM",-5)
		button:SetWidth(60)
		button:SetHeight(15)
		button:SetText("Okay")
		button.Text:SetFont("Fonts/FRIZQT__.TTF", 8)
		button:SetScript("OnClick", function() itemInfoCF:Hide() end)
	elseif _G[name .. "ItemInfo"] then
		local itemInfoCF = _G[name .. "ItemInfo"]
		itemInfoCF.EditBox:SetText(itemInfo)

		if db.off_hand and _G[name.."check_button"]:IsShown() then
			itemInfoCF.EditBox:Insert("\n"..getItemInfo(_G[name.."check_button"].itemSplit, "off_hand", _G[name.."check_button"].itemLink))
		end

		itemInfoCF.EditBox:HighlightText()
		itemInfoCF.EditBox:SetFocus()
		itemInfoCF:Show()
	end
end

local function createButton(type, suffix, parent, template)
	local button = CreateFrame(type, name..suffix, parent, template)
	return button
end

local function attachButtonToTooltip(self)
	local itemLink = select(2, self:GetItem())
	if not itemLink then return end
	local equipLoc, _, _, _, subId  = select(9, GetItemInfo(itemLink))

	if equipLoc and equipLoc ~= '' then
		local itemString = string.match(itemLink, "item:([%-?%d:]+)")
		local slot = equipLocToSlot[equipLoc]
		local itemSplit = getItemSplit(itemString)
		itemInfo = getItemInfo(itemSplit, slot, itemLink)

		_G[name.."button"]:SetParent(self)
		_G[name.."button"]:SetPoint("BOTTOM", self, "TOP")
		_G[name.."button"]:Show()

		if equipLoc == "INVTYPE_WEAPON" and oneHandWeapons[subId] then
			_G[name.."check_button"]:SetParent(self)
			_G[name.."check_button"]:SetPoint("LEFT", _G[name.."button"], "RIGHT", 2)
			_G[name.."check_button"].itemSplit = itemSplit
			_G[name.."check_button"].itemLink = itemLink
			_G[name.."check_button"]:Show()
			db.off_hand = _G[name.."check_button"]:GetChecked()
		elseif _G[name.."check_button"]:IsShown() then
			_G[name.."check_button"]:Hide()
		end

	else
		if _G[name.."button"] then
			_G[name.."button"]:Hide()
		end

		if _G[name.."check_button"] then
			_G[name.."check_button"]:Hide()
		end
	end
end


-- Fuck Frames
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, e, a)
	if e == "ADDON_LOADED" and a == name then
		tooltipSimcDB = tooltipSimcDB or {}
		db = tooltipSimcDB 
		if db.off_hand == nil then
			db.off_hand = true
		end

		local button = createButton("Button", "button", nil, "StaticPopupButtonTemplate")
		button:SetWidth(150)
		button:SetHeight(25)
		button:SetText("Generate SimC String")
		button:Hide()
		button:SetScript("OnClick", function() setupDialogBox() end)

		local check_button = createButton("CheckButton", "check_button", nil, "ChatConfigCheckButtonTemplate")
		getglobal(check_button:GetName() .. 'Text'):SetText("Add Off Hand")
		check_button:SetChecked(db.off_hand)
		check_button:SetScript("OnClick", function(self) 
			db.off_hand = self:GetChecked() 
		end)
		check_button:Hide()
	end
end)

ItemRefTooltip:HookScript("OnTooltipSetItem", attachButtonToTooltip)