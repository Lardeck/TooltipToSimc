local name, tpSimc = ...

local hooked, db = false
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

local nyalothaCorruptions = {
	--[[
	[itemId] = bonusId
	]]
	[172187] = 6539, -- Devastation's Hour
	[172189] = 6548, -- Eyestalk of Il'gynoth
	[172191] = 6567, -- An'zig Vra
	[172193] = 6568, -- Whispering Eldritch Bow
	[172196] = 6541, -- Vorzz Yoq'al
	[172197] = 6569, -- Unguent Caress
	[172198] = 6570, -- Mar'kowa, the Mindpiercer
	[172199] = 6571, -- Faralos, Empire's Dream
	[172200] = 6572, -- Sk'shuul Vaz
	[172227] = 6544, -- Shard of the Black Empire
	[174106] = 6550, -- Qwor N'lyeth
	[174108] = 6553, -- Shgla'yos, Astral Malignity
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

local function getItemInfo(itemSplit, slot, itemLink, itemLevel)
	-- code mostly copied from the Simulationcraft AddOn
	-- https://www.curseforge.com/wow/addons/simulationcraft
	
	local itemInfo = {}
	local itemId = itemSplit[1]
	itemInfo[#itemInfo + 1] = ',id=' .. itemId

	-- New style item suffix, old suffix style not supported
	if itemSplit[7] ~= 0 then
		itemInfo[#itemInfo + 1] = 'suffix=' .. itemSplit[7]
	end

	local bonuses = {}
	for index=1, itemSplit[13] do
		bonuses[#bonuses + 1] = itemSplit[13 + index]
	end

	if nyalothaCorruptions[itemId] and itemSplit[14] == 3524 then
		bonuses[#bonuses + 1] = nyalothaCorruptions[itemId]
	end

	if #bonuses > 0 then
		itemInfo[#itemInfo + 1] = 'bonus_id=' .. table.concat(bonuses, '/')
	end

	-- Get item creation context. Can be used to determine unlock/availability of azerite tiers for 3rd parties
	if itemSplit[12] ~= 0 then
		itemInfo[#itemInfo + 1] = 'context=' .. itemSplit[12]
	end

	local linkOffset = 13 + #bonuses + 1
	local craftedStats = {}
	local numPairs = itemSplit[linkOffset]
	for index=1, numPairs do
	  local pairOffset = 1 + linkOffset + (2 * (index - 1))
	  local pairType = itemSplit[pairOffset]
	  local pairValue = itemSplit[pairOffset + 1]
	  if pairType == 9 then
		itemInfo[#itemInfo + 1] = 'drop_level=' .. pairValue
	  elseif pairType == 29 or pairType == 30 then
		craftedStats[#craftedStats + 1] = pairValue
	  end
	end
  
	if #craftedStats > 0 then
		itemInfo[#itemInfo + 1] = 'crafted_stats=' .. table.concat(craftedStats, '/')
	end

	if itemLevel then
		itemInfo[#itemInfo + 1] = 'ilevel=' .. itemLevel
	end

	local str = '# '
	str = str .. slot .. "=" .. table.concat(itemInfo, ',')

	return str
end

local function setupDialogBox(itemInfo)
	local text
	if itemInfo then
		local itemInfoCF =  tpSimc.itemInfo or CreateFrame("ScrollFrame", name .. "ItemInfo", nil, "InputScrollFrameTemplate")
		if not tpSimc.itemInfo then
			tpSimc.itemInfo = itemInfoCF
			itemInfoCF:SetMovable(true)
			itemInfoCF:EnableMouse(true)
			itemInfoCF:RegisterForDrag("LeftButton")
			itemInfoCF:SetScript("OnDragStart", itemInfoCF.StartMoving)
			itemInfoCF:SetScript("OnDragStop", itemInfoCF.StopMovingOrSizing)
			itemInfoCF:SetToplevel(true)
			itemInfoCF:SetWidth(450)
			itemInfoCF:SetHeight(60)
			itemInfoCF:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

			itemInfoCF.CharCount:Hide()
			itemInfoCF.EditBox:SetFont("Fonts/FRIZQT__.TTF", 9)
			itemInfoCF.EditBox:SetPoint("TOPLEFT", 1, -2)

			local button = CreateFrame("Button", nil, itemInfoCF, "StaticPopupButtonTemplate")
			button:SetPoint("BOTTOM", itemInfoCF, "BOTTOM",-5)
			button:SetWidth(60)
			button:SetHeight(15)
			button:SetText("Okay")
			button.Text:SetFont("Fonts/FRIZQT__.TTF", 8)
			button:SetScript("OnClick", function() itemInfoCF:Hide() end)
		end

		if db.offHand and tpSimc.addOffHand:IsShown() then
			local offHandInfo = tpSimc.addOffHand.itemInfo
			text = itemInfo .. "\n" .. offHandInfo
		else
			text = itemInfo
		end

		itemInfoCF.EditBox:SetText(text)
		itemInfoCF.EditBox:HighlightText()
		itemInfoCF.EditBox:SetFocus()
		itemInfoCF.EditBox:SetSize(itemInfoCF:GetWidth(), itemInfoCF:GetHeight()-10)
		itemInfoCF.EditBox:SetScript("OnEscapePressed", function(self) itemInfoCF:Hide() end)

		itemInfoCF:Show()
	end

	if tpSimc.itemInfo then
		tpSimc.itemInfo.EditBox:HookScript("OnTextChanged", function(self)
			self:SetText(text)
			self:HighlightText()
			self:SetFocus()
		end)
	end
end

local function createButton(type, suffix, parent, template)
	local button = CreateFrame(type, name..suffix, parent, template)
	return button
end

local function getTooltipItem(tooltip, button)
	local locItemName, itemLink = tooltip:GetItem()
	if not itemLink then return end
	local equipLoc, _, _, _, subId  = select(9, GetItemInfo(itemLink))
	local item = Item:CreateFromItemLink(itemLink)
	if item:IsItemEmpty() then return end
	local itemLevel = item:GetCurrentItemLevel()

	if equipLoc and equipLoc ~= '' then
		local itemString = string.match(itemLink, "item:([%-?%d:]+)")
		local slot = equipLocToSlot[equipLoc]
		local itemSplit = getItemSplit(itemString)
		local itemInfo = getItemInfo(itemSplit, slot, itemLink, itemLevel)

		return equipLoc, itemLink, itemLevel, subId, itemInfo, locItemName, itemSplit
	end
end

local function createSimc(itemInfo, itemName)
	
	if not db.onlyItem then
		if SimcFrame and SimcFrame:IsShown() then
			SimcFrame:Hide()
		end

		setupDialogBox(itemInfo)
	else
		if tpSimc.itemInfo and tpSimc.itemInfo:IsShown() then
			tpSimc.itemInfo:Hide()
		end

		SlashCmdList["ACECONSOLE_SIMC"]("")

		local item = "#\n"
		item = item .. "# " .. itemName .. "\n"
		item = item .. itemInfo

		if db.offHand and tpSimc.addOffHand and tpSimc.addOffHand:IsShown() then
			local offHandInfo = tpSimc.addOffHand.itemInfo
			item = item .. "\n#\n"
			item = item .. "# " .. itemName .. "\n"
			item = item .. offHandInfo
		end

		if SimcEditBox then
			hooked = true
			local text = SimcEditBox:GetText()
			SimcEditBox:SetCursorPosition(SimcEditBox:GetNumLetters())
			SimcEditBox:HighlightText(0,0)
			SimcEditBox:Insert(item)
			SimcEditBox:HighlightText()
			SimcEditBox:SetFocus()
			SimcEditBox:HookScript("OnTextChanged", function(self) 
				if hooked then
					self:SetText(text .. item)
					self:HighlightText()
				end
			end)

			SimcEditBox:HookScript("OnHide", function(self)
				hooked = false
			end)
		end
	end
end

local function buttonAboveTooltip(self, link)
	local tooltipType = string.match(link,"^(%a+):")
	if tooltipType and tooltipType == "item" then
		local equipLoc, itemLink, itemLevel, subId, itemInfo, itemName, itemSplit = getTooltipItem(self)

		if equipLoc and equipLoc ~= "" then

			tpSimc.button:SetScript("OnClick", function() createSimc(itemInfo, itemName) end)
			tpSimc.button:SetParent(self)
			tpSimc.button:SetPoint("BOTTOM", self, "TOP")
			tpSimc.button:Show()

			tpSimc.onlyItem:SetParent(tpSimc.button)
			tpSimc.onlyItem:SetPoint("LEFT", tpSimc.button, "RIGHT", 2)
			tpSimc.onlyItem:Show()

			if equipLoc == "INVTYPE_WEAPON" and oneHandWeapons[subId] then
				tpSimc.addOffHand:SetParent(tpSimc.button)
				tpSimc.addOffHand:SetPoint("BOTTOM", tpSimc.onlyItem, "TOP")
				tpSimc.addOffHand.itemInfo = getItemInfo(itemSplit, "off_hand", itemLink, itemLevel)
				tpSimc.addOffHand:Show()
				db.offHand = tpSimc.addOffHand:GetChecked()
			elseif tpSimc.addOffHand:IsShown() then
				tpSimc.addOffHand:Hide()
			end
		elseif tpSimc.button:IsShown() then
			tpSimc.button:Hide()
		end
	else
		tpSimc.button:Hide()
	end
end

function tpSimcCurrentTooltip()
	if GameTooltip then
		local itemInfo, itemName = select(5, getTooltipItem(GameTooltip, false))
		if itemInfo then
			createSimc(itemInfo, itemName)
		end
	end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, e, a)
	if e == "ADDON_LOADED" and a == name then
		local default = {
			offHand = true,
			onlyItem = true
		}

		tooltipToSimcDB = tooltipToSimcDB or default
		db = tooltipToSimcDB 

		local button = createButton("Button", "button", nil, "StaticPopupButtonTemplate")
		tpSimc.button = button
		button:SetWidth(150)
		button:SetHeight(25)
		button:SetText("Generate SimC String")
		button:Hide()

		local addOffHand = createButton("CheckButton", "addOffHandButton", nil, "ChatConfigCheckButtonTemplate")
		tpSimc.addOffHand = addOffHand
		addOffHand.Text:SetText("+ Off Hand")
		addOffHand:SetChecked(db.offHand)
		addOffHand:Hide()
		addOffHand:SetScript("OnClick", function(self) 
			db.offHand = self:GetChecked() 
		end)


		if IsAddOnLoaded("Simulationcraft") then
			local onlyItem = createButton("CheckButton", "onlyItemButton", nil, "ChatConfigCheckButtonTemplate")
			tpSimc.onlyItem = onlyItem
			onlyItem.Text:SetText("Simc Integration")
			onlyItem:SetChecked(db.onlyItem)
			onlyItem:Hide()
			onlyItem:SetScript("OnClick", function(self)
				db.onlyItem = self:GetChecked()
			end)
		else
			db.onlyItem = true
		end
	end
end)

BINDING_HEADER_TOOLTIPSIMC1 = "TooltipToSimc"
hooksecurefunc(ItemRefTooltip, "SetHyperlink", buttonAboveTooltip)

-- WeakAuras :(
hooksecurefunc(ItemRefTooltip, "ClearLines", function() if tpSimc.button and tpSimc.button:IsShown() then tpSimc.button:Hide() end end)
