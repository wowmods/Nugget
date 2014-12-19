local _, NUGGET = ...
local L = NUGGET.L

local msq, msqGroups = nil, {}
if LibStub then
	msq = LibStub("Masque",true)
	if msq then
		msqGroups = {
			Nuggets = msq:Group("Nugget","Nuggets"),
		}
	end
end

local GREEN		= "|cFF00FF00"
local WHITE		= "|cFFFFFFFF"
local ORANGE		= "|cFFFF7F00"
local TEAL		= "|cFF00FF9A"

local NuggetDataDefaults = {
	X = 0,
	Y = -UIParent:GetHeight() / 5,
	HideInCombat = true,
}

function Nugget_Initialize()
	if NuggetData == nil then
		NuggetData = NuggetDataDefaults
	else
		for k, v in pairs(NuggetDataDefaults) do
			if NuggetData[k] == nil then NuggetData[k] = v end
		end
	end

	NuggetLockOption:SetChecked(NuggetData.ToolsLocked)
	NuggetMessagesOption:SetChecked(NuggetData.PrintScannerMessages)
	NuggetSoundsOption:SetChecked(NuggetData.PlayScannerSounds)
	NuggetPortalsOption:SetChecked(NuggetData.ShowPortals)
	NuggetHideInCombatOption:SetChecked(NuggetData.HideInCombat)
	NuggetStockTipOption:SetChecked(NuggetData.ShowStockTip)

	NuggetSeedIconOption:SetChecked(NuggetData.ShowVeggieIconsForSeeds)
	NuggetBagIconOption:SetChecked(NuggetData.ShowVeggieIconsForBags)
	
	Nugget_UpdateMiscToolsCheckboxes()
	
	if not NuggetData.ShowStockTip then UIDropDownMenu_DisableDropDown(Nugget.StockTipPositionDropdown) end
	
	if NuggetData.StockTipPosition == "BELOW" then
		UIDropDownMenu_SetText(Nugget.StockTipPositionDropdown, L["Below Normal Tooltip"])
	else
		UIDropDownMenu_SetText(Nugget.StockTipPositionDropdown, L["Right of Normal Tooltip"])
	end
	
	for Seed, Veggie in pairs(NUGGET.VeggiesBySeed) do --Attempt to pre-cache item info
		GetItemInfo(Seed)
		GetItemInfo(Veggie)
	end

	--print("Intial X="..NuggetData.X.." Y="..NuggetData.Y)
	Nugget:SetPoint("Center",UIParent,"Center",NuggetData.X,NuggetData.Y)
	
	NuggetSeeds.Update = Nugget_UpdateBar
	NuggetTools.Update = Nugget_UpdateBar
	NuggetPortals.Update = Nugget_UpdateBar
	
	hooksecurefunc("MerchantItemButton_OnEnter", Nugget_MerchantButtonOnEnter)
	
end

function Nugget_UpdateMiscToolsCheckboxes()
	local AllChecked = true
	local Choices = NuggetData.ShowMiscTools or {}
	for _, v in ipairs(NUGGET.MiscTools) do
		local btn = _G["NuggetMiscToolsOption"..v]
		if btn then
			btn:SetChecked(Choices[v] or false)
			AllChecked = AllChecked and Choices[v] or false
		end
	end
	btn = _G["NuggetMiscToolsOption"]
	btn:SetChecked(AllChecked)
end

function Nugget_MerchantEvent(MerchantOpen)
	NUGGET.MerchantOpen = MerchantOpen
end

local itemCounts = {}
local itemCountsLabels = {	L["Bags"], L["Bank"], L["AH"], L["Mail"] }
local function AddCharacterCountLine(character, searchedID)
	itemCounts[1], itemCounts[2] = DataStore:GetContainerItemCount(character, searchedID)
	itemCounts[3] = DataStore:GetAuctionHouseItemCount(character, searchedID)
	itemCounts[4] = DataStore:GetMailItemCount(character, searchedID)
	
	local charCount = 0
	for _, v in pairs(itemCounts) do
		charCount = charCount + v
	end
	
	if charCount > 0 then
		local account, _, char = strsplit(".", character)
		local name = DataStore:GetColoredCharacterName(character) or char		-- if for any reason this char isn't in DS_Characters.. use the name part of the key
		
		local t = {}
		for k, v in pairs(itemCounts) do
			if v > 0 then	-- if there are more than 0 items in this container
				table.insert(t, WHITE .. itemCountsLabels[k] .. ": "  .. TEAL .. v)
			end
		end

		-- charInfo should look like 	(Bags: 4, Bank: 8, Equipped: 1, Mail: 7), table concat takes care of this
		Nugget.StockTip:AddDoubleLine(name, format("%s (%s%s)", ORANGE .. charCount .. WHITE, table.concat(t, WHITE..", "), WHITE))
	end
end

function Nugget_MerchantButtonOnEnter(button)
	if ( MerchantFrame.selectedTab == 1 ) and NuggetData.ShowStockTip and NUGGET.MerchantOpen then
		local link = GetMerchantItemLink(button:GetID())
		if link == nil then return end
		local _, _, ItemID = string.find(link, "|?c?f?f?%x*|?H?[^:]*:?(%d+):?%d*:?%d*:?%d*:?%d*:?%d*:?%-?%d*:?%-?%d*:?%d*:?%d*|?h?%[?[^%[%]]*]?|?h?|?r?")
		if ItemID == nil then return end
		ItemID = tonumber(ItemID)
		local VeggieID = NUGGET.VeggiesBySeed[ItemID]
		if VeggieID == nil then
			ItemID = NUGGET.SeedsBySeedBag[ItemID]
			if ItemID == nil then return end
			VeggieID = NUGGET.VeggiesBySeed[ItemID]
		end
		if VeggieID then
			local veggieName = GetItemInfo(VeggieID)
			local onHand = GetItemCount(VeggieID,false)
			local inBank = GetItemCount(VeggieID,true) - onHand

			local icon = GetItemIcon(VeggieID)
			icon = icon and "|T"..icon..":14:14:0:0:32:32:3:29:3:29|t" or "??"
			veggieName = veggieName and icon.." "..veggieName or icon.." ".."ItemID: "..VeggieID
			--print(VeggieID, veggieName, onHand, inBank,icon)
			Nugget.StockTip:SetOwner(button:GetParent(), "ANCHOR_NONE");
			Nugget.StockTip:ClearAllPoints();
			if NuggetData.StockTipPosition == "BELOW" then
				Nugget.StockTip:SetPoint("TopLeft", button:GetParent(), "TopRight", 0, 0);
			else
				Nugget.StockTip:SetPoint("BottomLeft", button, "TopRight", GameTooltip:GetWidth(), 0);
			end
			Nugget.StockTip:AddDoubleLine(L["Produces"],veggieName,0,255,0)

			if DataStore then

				Nugget.StockTip:AddLine(" ")
				
				local ThisChar = DataStore:GetCharacter()
				
				AddCharacterCountLine(ThisChar,VeggieID)

				Nugget.StockTip:AddLine(" ")
				
				for name, character in pairs(DataStore:GetCharacters(GetRealmName(), "Default")) do
					if name ~= UnitName("player") and DataStore:GetCharacterFaction(character) == UnitFactionGroup("player") then
						AddCharacterCountLine(character, VeggieID)
					end
				end

				Nugget.StockTip:AddLine(" ")

				for guildName, guildKey in pairs(DataStore:GetGuilds(GetRealmName())) do				-- this realm only
					guildCount = DataStore:GetGuildBankItemCount(guildKey, VeggieID) or 0
					if guildCount > 0 then
						Nugget.StockTip:AddDoubleLine(GREEN..guildName, format("%s(%s: %s%s)", WHITE, "Guild Bank", TEAL..guildCount, WHITE))
					end
				end

			else
				Nugget.StockTip:AddDoubleLine(L["On Hand"],onHand,0,255,0,255,255,255)
				Nugget.StockTip:AddDoubleLine(L["In Bank"],inBank,0,255,0,255,255,255)
				NuggetMerchantStockTipTextRight2:ClearAllPoints()
				NuggetMerchantStockTipTextRight2:SetPoint("TopLeft",NuggetMerchantStockTipTextRight1,"BottomLeft",0,-2)
				NuggetMerchantStockTipTextRight3:ClearAllPoints()
				NuggetMerchantStockTipTextRight3:SetPoint("TopLeft",NuggetMerchantStockTipTextRight2,"BottomLeft",0,-2)
			end

			if TipTac then TipTac:AddModifiedTip(Nugget.StockTip) end
			Nugget.StockTip:Show()
			if not button.NuggetHooked then
				button:HookScript("OnLeave",function(button)
					Nugget.StockTip:Hide()
				end)
				button.NuggetHooked = true
			end
		end
	end
end

function Nugget_ZoneChanged()

	local Zone, SubZone = GetZoneText(), GetSubZoneText()

	local InSunsong = SubZone == L["Sunsong Ranch"]
	local InMarket = SubZone == L["The Halfhill Market"]
	local InHalfhill = InSunsong or InMarket or SubZone == L["Halfhill"] or Zone == L["Halfhill"]
	
	if not InHalfhill and not NUGGET.InHalfhill then return end

	local LeavingHalfhill = not InHalfhill and NUGGET.InHalfhill

	local EnteringSunsong = InSunsong and not NUGGET.InSunsong
	local LeavingSunsong = not InSunsong and NUGGET.InSunsong

	local EnteringMarket = InMarket and not NUGGET.InMarket
	local LeavingMarket = not InMarket and NUGGET.InMarket
	
	
	if (LeavingSunsong or LeavingMarket) and not (EnteringSunsong or EnteringMarket) then
		--print("Leaving Sunsong area. Hiding Nugget")
		Nugget:UnregisterEvent("BAG_UPDATE")
		Nugget:UnregisterEvent("MERCHANT_SHOW")
		Nugget:UnregisterEvent("MERCHANT_CLOSED")
		Nugget:UnregisterEvent("MERCHANT_UPDATE")
		NuggetSeeds:Hide()
		NuggetTools:Hide()
		NuggetPortals:Hide()
		Nugget:Hide()
		UnregisterStateDriver(Nugget,"visibility")
	end
	
	if (EnteringSunsong or EnteringMarket) and not (NUGGET.InSunsong or NUGGET.InMarket) then
		--print("Entering Sunsong area. Updating Nugget.")
		Nugget:RegisterEvent("BAG_UPDATE")
		Nugget:RegisterEvent("MERCHANT_SHOW")
		Nugget:RegisterEvent("MERCHANT_CLOSED")
		Nugget:RegisterEvent("MERCHANT_UPDATE")
		NuggetSeeds:Show()
		Nugget:Show()

		if NuggetData.HideInCombat then
			RegisterStateDriver(Nugget,"visibility","[combat]hide;show")
		end
		
	end
	
	if EnteringSunsong then
		NuggetTools:Show()
		if NuggetData.ShowPortals then NuggetPortals:Show() end
		Nugget:RegisterEvent("BAG_UPDATE_COOLDOWN")
	elseif LeavingSunsong then
		Nugget:UnregisterEvent("BAG_UPDATE_COOLDOWN")
		NuggetTools:Hide()
		NuggetPortals:Hide()
	end
	
	if EnteringSunsong or EnteringMarket then
		Nugget:Show()
		Nugget_Update()
	end
	
	if LeavingHalfhill then
		Nugget_DropTools()
	end
	
	NUGGET.InHalfhill = InHalfhill
	NUGGET.InMarket = InMarket
	NUGGET.InSunsong = InSunsong
	
end

function Nugget_ItemPreClick(Button,MouseButton,Down)
	if Down and not InCombatLockdown() then
		local Bag, Slot = Nugget_FindItemInBags(Button.ItemID)
		if IsShiftKeyDown() then
			Button:SetAttribute("type",nil)
		elseif NUGGET.InSunsong and Button.ItemType == "Seed" and UnitName("target") ~= L["Tilled Soil"] then
			Button:SetAttribute("type","macro")
			Button:SetAttribute("macrotext","/targetexact "..L["Tilled Soil"].."\n/use "..Bag.." "..Slot)
		else
			Button:SetAttribute("type","item")
			Button:SetAttribute("item",Bag.." "..Slot)
		end
	end
end

function Nugget_ItemPostClick(Button,MouseButton,Down)
	if Down then return end
	if not InCombatLockdown() then
		Button:SetAttribute("type","item")
		Button:SetAttribute("item","item:"..Button.ItemID)
		Button:SetAttribute("shift-item*","")
	end
end

function Nugget_ItemOnEnter(Button)
	if NUGGET.MerchantOpen and Button.ItemType == "Seed" then
		ShowContainerSellCursor(Button.Bag,Button.Slot)
	end
	GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
	GameTooltip:SetBagItem(Button.Bag,Button.Slot)
	GameTooltip:Show()
end

function Nugget_ItemOnLeave(Button)
	if NUGGET.MerchantOpen and Button.ItemType == "Seed" then
		ResetCursor()
	end
	GameTooltip_Hide()
end

function Nugget_ButtonOnMouseDown(Button, MouseButton)
	if IsShiftKeyDown() and MouseButton == "LeftButton" and not Nugget.isMoving then
		_,_,_, Nugget.InitialOffsetX, Nugget.InitialOffsetY = Nugget:GetPoint(1)
--		print("InitialOffsetX: "..Nugget.InitialOffsetX.." InitialOffsetY: "..Nugget.InitialOffsetY)
		Nugget:StartMoving()
		_,_,_, Nugget.PickupOffsetX, Nugget.PickupOffsetY = Nugget:GetPoint(1)
--		print("PickupOffsetX: "..Nugget.PickupOffsetX.." PickupOffsetY: "..Nugget.PickupOffsetY)
		Nugget.isMoving = true
	elseif MouseButton == "RightButton" and Nugget.isMoving then
		Nugget:StopMovingOrSizing()
		Nugget.isMoving = false
		NuggetData.X, NuggetData.Y = 0, - UIParent:GetHeight() / 5
		Nugget_RunAfterCombat(Nugget_ResetAnchors)
	end
end

function Nugget_ButtonOnMouseUp(Button, MouseButton)
	if MouseButton == "LeftButton" and Nugget.isMoving then
		local _,_,_, DropOffsetX, DropOffsetY = Nugget:GetPoint(1)
--		print("DropOffsetX: "..DropOffsetX.." DropOffsetY: "..DropOffsetY)
		Nugget:StopMovingOrSizing()
		Nugget.isMoving = false
		NuggetData.X = DropOffsetX - Nugget.PickupOffsetX + Nugget.InitialOffsetX
		NuggetData.Y = DropOffsetY - Nugget.PickupOffsetY + Nugget.InitialOffsetY
--		print("FinalOffsetX: "..NuggetData.X.." FinalOffsetY: "..NuggetData.Y)
		Nugget_RunAfterCombat(Nugget_ResetAnchors)
   end
end

function Nugget_ResetAnchors()
	Nugget:ClearAllPoints()
	Nugget:SetPoint("Center",UIParent,NuggetData.X,NuggetData.Y)
end

function Nugget_ButtonOnHide()
	if InCombatLockdown() then 
		Nugget_RunAfterCombat(Nugget_ButtonOnHide)
		return
	end
	if Nugget.isMoving then
		Nugget:StopMovingOrSizing()
		Nugget.isMoving = false
		Nugget_RunAfterCombat(Nugget_ResetAnchors)
	end
end

function Nugget_SetHideInCombatOption(Value)
	NuggetData.HideInCombat = Value
	if Value and Nugget:IsShown() then
		RegisterStateDriver(Nugget,"visibility","[combat]hide;show")
	else
		UnregisterStateDriver(Nugget,"visibility")
	end
end

function Nugget_SetBagIconOption(Value)
	NuggetData.ShowVeggieIconsForBags = Value
	Nugget_UpdateButtonIcons(NuggetSeeds)
end

function Nugget_SetSeedIconOption(Value)
	NuggetData.ShowVeggieIconsForSeeds = Value
	Nugget_UpdateButtonIcons(NuggetSeeds)
end
	
function Nugget_SetStockTipOption(Value)
	NuggetData.ShowStockTip = Value

	if NuggetData.ShowStockTip then
		UIDropDownMenu_EnableDropDown(Nugget.StockTipPositionDropdown)
	else
		UIDropDownMenu_DisableDropDown(Nugget.StockTipPositionDropdown)
	end

end

function Nugget_InitializeStockTipDropdown(frame, level, menuList)
	local info = UIDropDownMenu_CreateInfo()
	info.func = Nugget_SetStockTipPosition

	info.text = L["Below Normal Tooltip"]
	info.value = "BELOW"
	info.checked = NuggetData and NuggetData.StockTipPosition == "BELOW" or NuggetData == nil and false
	UIDropDownMenu_AddButton(info)

	info.text = L["Right of Normal Tooltip"]
	info.value = "RIGHT"
	info.checked = NuggetData and NuggetData.StockTipPosition == "RIGHT"
	UIDropDownMenu_AddButton(info)
end

function Nugget_SetStockTipPosition(info)
	NuggetData.StockTipPosition = info.value
	if NuggetData.StockTipPosition == "BELOW" then
		UIDropDownMenu_SetText(Nugget.StockTipPositionDropdown, L["Below Normal Tooltip"])
	else
		UIDropDownMenu_SetText(Nugget.StockTipPositionDropdown, L["Right of Normal Tooltip"])
	end
end

function Nugget_SetLockToolsOption(Value)
	NuggetData.ToolsLocked = Value
end

function Nugget_SetMessagesOption(Value)
	NuggetData.PrintScannerMessages = Value
end

function Nugget_SetSoundsOption(Value)
	NuggetData.PlayScannerSounds = Value
end

function Nugget_SetPortalsOption(Value)
	NuggetData.ShowPortals = Value
	if Value then
		if NUGGET.InSunsong then 
			NuggetPortals:Show()
		else
			NuggetPortals:Hide()
		end
	else
		NuggetPortals:Hide()
	end
end

function Nugget_SetMiscToolsOption(Value, ItemID)
	if ItemID == nil then
		if Value then
			NuggetData.ShowMiscTools = NuggetData.ShowMiscTools or {}
			for _, v in ipairs(NUGGET.MiscTools) do
				NuggetData.ShowMiscTools[v] = true
			end
		else
			NuggetData.ShowMiscTools = nil
		end
	else
		if Value then
			NuggetData.ShowMiscTools = NuggetData.ShowMiscTools or {}
			NuggetData.ShowMiscTools[ItemID] = true
		else
			if NuggetData.ShowMiscTools then
				NuggetData.ShowMiscTools[ItemID] = nil
			end
		end
	end
	Nugget_UpdateMiscToolsCheckboxes()
	Nugget_Update()
end

function Nugget_UpdateButtonIcons(Bar)
	for _, Button in ipairs(Bar.Buttons) do
		local Icon, SmallIcon
		if Button.ItemType == "Seed" then
			Icon = select(10,GetItemInfo(NuggetData.ShowVeggieIconsForSeeds and (NUGGET.VeggiesBySeed[Button.ItemID] or Button.ItemID) or Button.ItemID))
			Button.Icon:SetTexture(Icon)
		elseif Button.ItemType == "SeedBag" then
			Icon = NuggetData.ShowVeggieIconsForBags and (NUGGET.VeggiesBySeed[NUGGET.SeedsBySeedBag[Button.ItemID]] or NUGGET.SeedsBySeedBag[Button.ItemID]) or Button.ItemID
			Icon = select(10,GetItemInfo(Icon))
			SmallIcon = NuggetData.ShowVeggieIconsForBags and select(10,GetItemInfo(Button.ItemID))
			Button.Icon:SetTexture(Icon)
			Button.SmallIcon:SetTexture(SmallIcon)
		else
			if Button.Bag and Button.Slot then
				Icon = GetContainerItemInfo(Button.Bag,Button.Slot)
				Button.Icon:SetTexture(Icon)
				Button.SmallIcon:SetTexture(nil)
			end
		end
	end
end

function Nugget_UpdateBar(Bar)
	local Last
	local Shown = 0
	local ButtonSpacing = 6
	local MiscTools = NuggetData.ShowMiscTools or {}
	
	--print("UpdateBar "..Bar:GetName().." with "..#Bar.Buttons.." items.")

	for _, Button in ipairs(Bar.Buttons) do
		local ItemCount = GetItemCount(Button.ItemID,false,true)
		if ItemCount > 0 or Button.ItemType == "CropScanner" then
			if Button.ItemType ~= "MiscTool" or MiscTools[Button.ItemID] then

				if Shown % 8 == 0 then
					local Row = math.floor(Shown/8)
					Button:SetPoint("TopLeft",Bar,"TopLeft", ButtonSpacing/2, -ButtonSpacing/2 - Row*Button:GetHeight() - Row*ButtonSpacing)
					Last = Button
				else
					Button:SetPoint("TopLeft",Last,"TopRight",ButtonSpacing,0)
					Last = Button
				end
				if Button.ItemID then
					Button.Bag, Button.Slot = Nugget_FindItemInBags(Button.ItemID)
					if Bar.ShowItemCount then
						if ItemCount > 999 then
							Button.Count:SetText("***")
						else
							Button.Count:SetText(ItemCount)
						end
					end
				end
				Button:Show()
				Shown = Shown + 1
			else
				Button:Hide()
			end
		else
			Button:Hide()
		end
	end
	
	Nugget_UpdateButtonIcons(Bar)

	if msqGroups[Bar:GetName()] then msqGroups[Bar:GetName()]:ReSkin() end

	local Width, Height
	if Last then
		Width = math.min(8,Shown) * (Last:GetWidth() + ButtonSpacing) 
		Height = math.ceil(Shown/8) * (Last:GetHeight() + ButtonSpacing)
	end
	Bar:SetWidth(Width or (32 + ButtonSpacing))
	Bar:SetHeight(Height or (32 + ButtonSpacing))
end

function Nugget_UpdateSeedBagCharges()
	for _, Button in ipairs(NuggetSeeds.Buttons) do
		local ItemCount = GetItemCount(Button.ItemID,false,true)
		if ItemCount > 999 then
			Button.Count:SetText("***")
		else
			Button.Count:SetText(ItemCount)
		end
	end
end

function Nugget_Update()

	NuggetSeeds:Update()
	NuggetTools:Update()
	NuggetPortals:Update()
	
	local SBH = NuggetSeeds:GetHeight() * NuggetSeeds:GetScale()
	local TBH = NuggetTools:GetHeight() * NuggetTools:GetScale()
	local PBH = NuggetPortals:GetHeight() * NuggetPortals:GetScale()
	local NUGGETH = SBH + TBH + PBH -- + Nugget.Backdrop:GetBackdrop().insets.top + Nugget.Backdrop:GetBackdrop().insets.bottom
	Nugget:SetHeight(NUGGETH)
	
	local SBW = NuggetSeeds:GetWidth() * NuggetSeeds:GetScale()
	local TBW = NuggetTools:GetWidth() * NuggetTools:GetScale()
	local PBW = NuggetPortals:GetWidth() * NuggetPortals:GetScale()
	local NUGGETW = max(SBW,TBW,PBW) -- + Nugget.Backdrop:GetBackdrop().insets.left + Nugget.Backdrop:GetBackdrop().insets.right
	Nugget:SetWidth(NUGGETW)

end

function Nugget_CropScannerPreClick(Button,MouseButton,Down)
	if Down and not InCombatLockdown() then
		if IsShiftKeyDown() then
			Button:SetAttribute("type",nil)
		else
			Button:SetAttribute("type","click")
		end
	end
end

function Nugget_CropScannerCheckForTarget()
	if UnitExists("target") then
		CropName = UnitName("target")
		Icon = ICON_LIST[GetRaidTargetIndex("target")] and ICON_LIST[GetRaidTargetIndex("target")].."0|t" or ""
		local msg = L["Crop Scanner found:"].." "..Icon.." "..CropName
		tinsert(NuggetScanButton.ScannerOutput,1,msg)
	end
end

function Nugget_CropScannerPostClick(Button,MouseButton,Down)
	if Down then return end
	if not Button:GetAttribute("type") then 
		if not InCombatLockdown() then
			Button:SetAttribute("type","click")
		end
		return 
	end
	if #Button.ScannerOutput == 0 then
		if NuggetData.PrintScannerMessages then
			print(L["Crop Scanner finished."].." "..L["The crops are looking good!"])
			RaidNotice_AddMessage(RaidBossEmoteFrame,L["The crops are looking good!"], ChatTypeInfo["RAID_BOSS_EMOTE"])
		end
		if NuggetData.PlayScannerSounds then
			PlaySound("QUESTCOMPLETED","SFX")
		end
	else
		if NuggetData.PrintScannerMessages then
			for _, msg in ipairs(Button.ScannerOutput) do
				print(msg)
			end
			RaidNotice_AddMessage(RaidBossEmoteFrame,L["Some crops need attention!"], ChatTypeInfo["RAID_BOSS_EMOTE"])
		end
		if NuggetData.PlayScannerSounds then
			PlaySound("igQuestFailed","SFX")
		end
		wipe(Button.ScannerOutput)
	end
end

function Nugget_ScanButtonOnEnter()
	GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
	GameTooltip:ClearLines()
	GameTooltip:AddLine(L["Crop Scanner"],0,255,0,false)
	GameTooltip:AddLine(L["Scan your farm for crops or soil that need attention."],255,255,255,true)
	GameTooltip:Show()
end

function Nugget_ScanButtonOnLeave()
	GameTooltip_Hide()
end

function Nugget_DropTools()
	if NuggetData.ToolsLocked then
		print(L["Leaving Halfhill."].." "..L["Tools are Locked."])
	else
		ClearCursor()
		for _, ItemID in ipairs(NUGGET.Tools) do
			local Bag, Slot = Nugget_FindItemInBags(ItemID)
			if Bag and Slot then
				PickupContainerItem(Bag,Slot)
				if CursorHasItem() then
					local _, ID, Link = GetCursorInfo()
					if ID == ItemID then
						print(L["Leaving HalNUGGETill."].." "..L["Dropping"].." "..Link..".")
						DeleteCursorItem()
					end
				end
			end
		end
	end
end

function Nugget_FindItemInBags(ItemID)
	local NumSlots
	for Container = 0, NUM_BAG_SLOTS do
		NumSlots = GetContainerNumSlots(Container)
		if NumSlots then
			for Slot = 1, NumSlots do
				if ItemID == GetContainerItemID(Container, Slot) then
					return Container, Slot
				end
			end
		end
	end
end

NUGGET.PostCombatQueue = {}
function Nugget_RunAfterCombat(Func,Args)
	if InCombatLockdown() then
		Nugget:RegisterEvent("PLAYER_REGEN_ENABLED")
		tinsert(NUGGET.PostCombatQueue,{Func=Func,Args=Args})
		return
	else
		Func(unpack(Args or {}))
	end
end
function Nugget_CombatEnded()
	for _, Item in ipairs(NUGGET.PostCombatQueue) do
		Item.Func(unpack(Item.Args or {}))
	end
	wipe(NUGGET.PostCombatQueue)
end
