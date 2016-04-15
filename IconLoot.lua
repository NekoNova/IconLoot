----------------------------------------------------------------------------------------------
-- IconLoot
-- Loot notification replacement
-- 
-- Owner: daihenka
-- Developer: Olivar Nax
-----------------------------------------------------------------------------------------------
require "Apollo"
require "Window"
require "Sound"
require "GameLib"

-----------------------------------------------------------------------------------------------
-- functions we copy into the local namespace.
-----------------------------------------------------------------------------------------------
local setmetatable, pairs, ipairs, unpack, Print = setmetatable, pairs, ipairs, unpack, Print

-----------------------------------------------------------------------------------------------
-- Module definition
-----------------------------------------------------------------------------------------------
local IconLoot                  = {}

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
local knMaxEntryData            = 6
local kfMaxItemTime             = 7				-- item display time (seconds)
local kfTimeBetweenItems        = 0.3			-- delay between items; also determines clearing time (seconds)
local kfIconLootUpdate          = 0.1
local knType_Invalid            = 0
local knType_Item               = 1
local kfCashDisplayDuration     = 5.0 		-- cash display timer (s)
local knCompactLootedItemHeight = 42
local knLargeLootedItemHeight   = 58
local kstrChatPrefix            = "IconLoot : "
local ktHarvestItemCategories = {
  [103] = true,
  [107] = true,
  [110] = true,
}
local karItemQuality = 
{
	[Item.CodeEnumItemQuality.Inferior] = {
    	Color = "ItemQuality_Inferior",
    	BarSprite = "CRB_Tooltips:sprTooltip_RarityBar_Silver",
    	HeaderSprite = "CRB_Tooltips:sprTooltip_Header_Silver",
    	SquareSprite = "CRB_Tooltips:sprTooltip_SquareFrame_Silver",
		CompactIcon = "CRB_TooltipSprites:sprTT_HeaderInsetGrey",
		NotifyBorder = "ItemQualityBrackets:sprItemQualityBracket_Silver",
  	},
	[Item.CodeEnumItemQuality.Average] = {
    	Color = "ItemQuality_Average",
    	BarSprite = "CRB_Tooltips:sprTooltip_RarityBar_White",
    	HeaderSprite = "CRB_Tooltips:sprTooltip_Header_White",
    	SquareSprite = "CRB_Tooltips:sprTooltip_SquareFrame_White",
		CompactIcon = "CRB_TooltipSprites:sprTT_HeaderInsetWhite",
		NotifyBorder = "ItemQualityBrackets:sprItemQualityBracket_White",
  	},
	[Item.CodeEnumItemQuality.Good] = {
    	Color = "ItemQuality_Good",
    	BarSprite = "CRB_Tooltips:sprTooltip_RarityBar_Green",
    	HeaderSprite = "CRB_Tooltips:sprTooltip_Header_Green",
    	SquareSprite = "CRB_Tooltips:sprTooltip_SquareFrame_Green",
		CompactIcon = "CRB_TooltipSprites:sprTT_HeaderInsetGreen",
		NotifyBorder = "ItemQualityBrackets:sprItemQualityBracket_Green",
  	},
	[Item.CodeEnumItemQuality.Excellent] = {
    	Color = "ItemQuality_Excellent",
    	BarSprite = "CRB_Tooltips:sprTooltip_RarityBar_Blue",
    	HeaderSprite = "CRB_Tooltips:sprTooltip_Header_Blue",
    	SquareSprite = "CRB_Tooltips:sprTooltip_SquareFrame_Blue",
		CompactIcon = "CRB_TooltipSprites:sprTT_HeaderInsetBlue",
		NotifyBorder = "ItemQualityBrackets:sprItemQualityBracket_Blue",
  	},
	[Item.CodeEnumItemQuality.Superb] = {
    	Color = "ItemQuality_Superb",
    	BarSprite = "CRB_Tooltips:sprTooltip_RarityBar_Purple",
    	HeaderSprite = "CRB_Tooltips:sprTooltip_Header_Purple",
    	SquareSprite = "CRB_Tooltips:sprTooltip_SquareFrame_Purple",
		CompactIcon = "CRB_TooltipSprites:sprTT_HeaderInsetPurple",
		NotifyBorder = "ItemQualityBrackets:sprItemQualityBracket_Purple",
  	},
	[Item.CodeEnumItemQuality.Legendary] = {
    	Color = "ItemQuality_Legendary",
    	BarSprite = "CRB_Tooltips:sprTooltip_RarityBar_Orange",
    	HeaderSprite = "CRB_Tooltips:sprTooltip_Header_Orange",
    	SquareSprite = "CRB_Tooltips:sprTooltip_SquareFrame_Orange",
		CompactIcon = "CRB_TooltipSprites:sprTT_HeaderInsetOrange",
		NotifyBorder = "ItemQualityBrackets:sprItemQualityBracket_Orange",
  	},
	[Item.CodeEnumItemQuality.Artifact]	= {
    	Color = "ItemQuality_Artifact",
    	BarSprite = "CRB_Tooltips:sprTooltip_RarityBar_Pink",
    	HeaderSprite = "CRB_Tooltips:sprTooltip_Header_Pink",
    	SquareSprite = "CRB_Tooltips:sprTooltip_SquareFrame_Pink",
		CompactIcon = "CRB_TooltipSprites:sprTT_HeaderInsetPink",
		NotifyBorder = "ItemQualityBrackets:sprItemQualityBracket_Pink",
  	},
}

-----------------------------------------------------------------------------------------------
-- Constructor
-- 
-- Creates a new instance of the IconLoot class and configures the objects default attributes.
-----------------------------------------------------------------------------------------------
function IconLoot:new(o)
	o = o or {}
  
	setmetatable(o, self)
  	self.__index        = self
  
	self.arEntries = {}
	self.tEntryData = {}
	self.tQueuedEntryData = {}
	self.fLastTimeAdded = 0
	self.bLockToggle = true		-- locked
	self.bCompactMode = false		-- large mode
	self.bGrowDirection = false	  -- down
	self.bBlacklistSigns = false
	self.tQueuedNotifications = {}
	self.bShowNotification = true
	self.fNotificationTimeout = 2
	self.eMinNotifyQuality = Item.CodeEnumItemQuality.Good
	self.bNotifyQuestItems = true
	self.bNotifyHarvestItems = true
	
  	return o
end

-----------------------------------------------------------------------------------------------
-- Init
-- 
-- Initializes IconLoot, registering the addon with Apollo for usage in
-- in the game client.
-----------------------------------------------------------------------------------------------
function IconLoot:Init()
    Apollo.RegisterAddon(self, true, "IconLoot", {})
end

-----------------------------------------------------------------------------------------------
-- OnConfigure
--
-- Called whenever the User clicks on the IconLoot button inside the main menu.
-- Shows the configuration options and test mode.
-----------------------------------------------------------------------------------------------
function IconLoot:OnConfigure()
	self:LockToggle()
end

-----------------------------------------------------------------------------------------------
-- OnLoad
-- 
-- Is called when the Addon Loads itself in the client.
-- We use this to setup the various callback hooks and
-- register the supported commands and events.
-----------------------------------------------------------------------------------------------
function IconLoot:OnLoad()
  	-- Slash command
	Apollo.RegisterSlashCommand("iconloot","OnIconLootCmd",self)

  	-- Events
	Apollo.RegisterEventHandler("ChannelUpdate_Loot","OnLootedItem",self)
	Apollo.RegisterEventHandler("ActivateCCStateStun","OnActivateCCStateStun", self)
	Apollo.RegisterEventHandler("RemoveCCStateStun","OnRemoveCCStateStun",self)
	
	-- Sprites
	Apollo.LoadSprites("ItemQualityBrackets.xml")

	-- Windows and UI
	self.wndIconLoot = Apollo.LoadForm("IconLoot.xml", "IconLootForm", nil, self)
	self.wndNotification = Apollo.LoadForm("IconLoot.xml", "LootNotificationForm", nil, self)
	self.wndCashComplex = self.wndIconLoot:FindChild("CashComplex")
	self.wndCashComplex:Show(false)
	self.wndCashDisplay = self.wndCashComplex:FindChild("CashDisplay")
	
	-- Set the ItemQuality Data
	for k, v in pairs(Item.CodeEnumItemQuality) do
		self.wndIconLoot:FindChild("NotificationOptions:ItemQualities:ItemQuality" .. k .. "Btn"):SetData(v)
	end

	-- Timers
	self.tmrUpdate = ApolloTimer.Create(kfIconLootUpdate, true, "OnUpdate", self)
	self.tmrCash = ApolloTimer.Create(kfCashDisplayDuration, false, "OnCashTimer", self)
	self.tmrHideNotification = ApolloTimer.Create(self.fNotificationTimeout , true, "OnHideNotification", self)

	self.tmrCash:Start()
end

-----------------------------------------------------------------------------------------------
-- OnIconLootCmd
-- 
-- Is triggered when the user types /iconloot in chat.
-----------------------------------------------------------------------------------------------
function IconLoot:OnIconLootCmd(cmd, arg)
	self:LockToggle()
end

-----------------------------------------------------------------------------------------------
-- PerformTest
-- 
-- Performs a dummy test using the players current inventory to simulate the looting of
-- items and make sure the Addon is working.
-----------------------------------------------------------------------------------------------
function IconLoot:PerformTest()
	local unitPlayer = GameLib.GetPlayerUnit()
  
	for key, itemEquipped in pairs(unitPlayer:GetEquippedItems()) do
    	if itemEquipped ~= nil then
      		self:OnLootedItem(Item.CodeEnumLootItemType.AltTable, { itemNew = itemEquipped, nCount = 1 })
    	end
  	end
  
  	self:OnLootedItem(
		Item.CodeEnumLootItemType.Cash, {
            monNew = GameLib.GetPlayerCurrency(1),
            monBalance = GameLib.GetPlayerCurrency(1)
        }
    )
end

-----------------------------------------------------------------------------------------------
-- GrowDirectionToggle
-- 
-- Toggles the direction in which the notifications "flow"
-----------------------------------------------------------------------------------------------
function IconLoot:GrowDirectionToggle(bValue)
	self.bGrowDirection = bValue
end

-----------------------------------------------------------------------------------------------
-- CompactModeToggle
-- 
-- Toggles the Addon between normal mode and compact mode
-----------------------------------------------------------------------------------------------
function IconLoot:CompactModeToggle(bValue)
	self.bCompactMode = bValue
	self:RebuildItemWndList()
	self:UpdateDisplay()
end

-----------------------------------------------------------------------------------------------
-- RecalculateMaxEntries
-- 
-- Calculates the maximum amount of entries we can display at any given time, using the
-- height of the window and the height of the item entries
-----------------------------------------------------------------------------------------------
function IconLoot:RecalculateMaxEntries()
	local nMaxHeight = self.wndIconLoot:FindChild("LootedItemScroll"):GetHeight()
	local nItemHeight = (self.bCompactMode and knCompactLootedItemHeight or knLargeLootedItemHeight)
	knMaxEntryData = math.floor(nMaxHeight / nItemHeight)
end

-----------------------------------------------------------------------------------------------
-- RebuildItemWndList
-- 
-- Rebuilds the entire ItemList window
-----------------------------------------------------------------------------------------------
function IconLoot:RebuildItemWndList()
	if self.bRebuildItemWnd then return end
	
	self.bRebuildItemWnd = true
	
	local wndScroll = self.wndIconLoot:FindChild("LootedItemScroll")
	local strFormName = (self.bCompactMode and "MinLootedItem" or "LootedItem")
	
	self:RecalculateMaxEntries()
	
	-- clear out existing items
	wndScroll:DestroyChildren()
	
	self.arEntries = {}
	
	for idx = 1, knMaxEntryData do
		local wndCurr = Apollo.LoadForm("IconLoot.xml", strFormName, wndScroll, self)
		
		wndCurr:Show(false)
		table.insert(self.arEntries, wndCurr)
	end
	
	wndScroll:ArrangeChildrenVert(0)
	self.bRebuildItemWnd = nil
end

-----------------------------------------------------------------------------------------------
-- PLACEMENT/LOCK FUNCTIONS
-----------------------------------------------------------------------------------------------
function IconLoot:LockToggle()
	self.bLockToggle = (not self.bLockToggle)
	
	self.wndIconLoot:Show(not self.bLockToggle)
	
	if self.bLockToggle then
		self.wndIconLoot:SetStyle("Moveable", false)
		self.wndIconLoot:SetStyle("Sizable", false)
		self.wndIconLoot:SetStyle("IgnoreMouse", true)
	    self.wndIconLoot:FindChild("Anchor"):Show(false)
	    self.wndIconLoot:FindChild("NotificationOptions"):Show(false)
		self.wndIconLoot:FindChild("BlacklistOptions"):Show(false)
	else
		self.wndIconLoot:SetStyle("Moveable", true)
		self.wndIconLoot:SetStyle("Sizable", true)
		self.wndIconLoot:SetStyle("IgnoreMouse", false)
	    self.wndIconLoot:FindChild("Anchor"):Show(true)
	    self.wndIconLoot:FindChild("NotificationOptions"):Show(true)
	    self.wndIconLoot:FindChild("Anchor:Inset:GrowDirectionBtn"):SetCheck(self.bGrowDirection)
	    self.wndIconLoot:FindChild("Anchor:Inset:CompactModeBtn"):SetCheck(self.bCompactMode)
	    self.wndIconLoot:FindChild("NotificationOptions:ShowNotificationBtn"):SetCheck(self.bShowNotification)
	    self.wndIconLoot:FindChild("NotificationOptions:QuestItemBtn"):SetCheck(self.bNotifyQuestItems)
	    self.wndIconLoot:FindChild("NotificationOptions:HarvestItemBtn"):SetCheck(self.bNotifyHarvestItems)
	    self.wndIconLoot:FindChild("NotificationOptions:NotificationTimeoutSlider"):SetValue(self.fNotificationTimeout)
	    self.wndIconLoot:FindChild("NotificationOptions:NotificationTimeoutSlider:NotificationTimeoutLabel"):SetText(string.format("%.1f", self.fNotificationTimeout))
		self.wndIconLoot:FindChild("NotificationOptions:ItemQualities"):FindChildByUserData(self.eMinNotifyQuality):SetCheck(true)
		
		self.wndIconLoot:FindChild("BlacklistOptions"):Show(true)
		self.wndIconLoot:FindChild("BlacklistOptions:BlacklistSigns"):SetCheck(self.bBlacklistSigns)
	end
end

-----------------------------------------------------------------------------------------------
-- ADDON SAVE/RESTORE FUNCTIONS
-----------------------------------------------------------------------------------------------
function IconLoot:OnSave(eLevel)
    if eLevel ~= GameLib.CodeEnumAddonSaveLevel.General then
        return
    end
  
    local tSavedData = {}

    tSavedData.tAnchorOffsets = {self.wndIconLoot:GetAnchorOffsets()}
    tSavedData.bGrowDirection = self.bGrowDirection
    tSavedData.bCompactMode   = self.bCompactMode
	
	-- notification settings
	tSavedData.fNotificationTimeout = self.fNotificationTimeout
	tSavedData.eMinNotifyQuality    = self.eMinNotifyQuality
	tSavedData.bNotifyQuestItems    = self.bNotifyQuestItems
	tSavedData.bNotifyHarvestItems  = self.bNotifyHarvestItems
	tSavedData.tNotifyAnchorOffsets = {self.wndNotification:GetAnchorOffsets()}
    tSavedData.bShowNotification = self.bShowNotification
	tSavedData.bBlacklistSigns = self.bBlacklistSigns
	
	return tSavedData
end

function IconLoot:OnRestore(eLevel, tSavedData)
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.General then
        return
    end
  
	if tSavedData.bGrowDirection ~= nil then
		self.bGrowDirection = tSavedData.bGrowDirection
    end

	if tSavedData.bCompactMode ~= nil then
		self.bCompactMode = tSavedData.bCompactMode
    end

	if tSavedData.tAnchorOffsets then
		self.wndIconLoot:SetAnchorOffsets(unpack(tSavedData.tAnchorOffsets))
	end
	
	if tSavedData.fNotificationTimeout then
		self.fNotificationTimeout = tSavedData.fNotificationTimeout
    end

	if tSavedData.eMinNotifyQuality then 
		self.eMinNotifyQuality = tSavedData.eMinNotifyQuality
    end

	if tSavedData.bNotifyQuestItems ~= nil then 
		self.bNotifyQuestItems = tSavedData.bNotifyQuestItems
    end

	if tSavedData.bNotifyHarvestItems ~= nil then 
		self.bNotifyHarvestItems = tSavedData.bNotifyHarvestItems
    end

	if tSavedData.tNotifyAnchorOffsets then
		self.wndNotification:SetAnchorOffsets(unpack(tSavedData.tNotifyAnchorOffsets))
	end
	
    if tSavedData.bShowNotification ~= nil then
		self.bShowNotification = tSavedData.bShowNotification
	end
	
    if tSavedData.bBlacklistSigns ~= nil then
		self.bBlacklistSigns = tSavedData.bBlacklistSigns
	end
end

function IconLoot:OnActivateCCStateStun()
	self.wndIconLoot:Show(false)
end

function IconLoot:OnRemoveCCStateStun()
	self.wndIconLoot:Show(true)
end

-----------------------------------------------------------------------------------------------
-- OnCashTimer
-- 
-- Called when the IconLoot_CashTimer reaches it's countdown.
-- Reset the windows for money back to invisible
-----------------------------------------------------------------------------------------------
function IconLoot:OnCashTimer()
	self.wndCashComplex:Show(false)
	self.bShowingCash = false
end


-----------------------------------------------------------------------------------------------
-- ITEM FUNCTIONS
-----------------------------------------------------------------------------------------------

-- Speeds up the Queue of which IconLoot processes the updates by 0.1 second.
-- This gets triggered every time a new Item is added the list, to ensure the
-- Item gets processed fast enough.
function IconLoot:ResetQueue()
	if (kfIconLootUpdate > 0.1) then
		kfIconLootUpdate =  0.1

		self.tmrUpdate:Set(kfIconLootUpdate, true, "OnUpdate", self)
	end
end

-- Slows down the Queue of which IconLoot processes updates by 0.1 second.
-- This gets triggered every time an update did not add an item to the Queue.
-- The goal here is to slow down the amount of calls made by the Addon.
function IconLoot:SlowDownQueue()
	if (kfIconLootUpdate < 5.0) then
		kfIconLootUpdate = kfIconLootUpdate + 0.1

		self.tmrUpdate:Set(kfIconLootUpdate, true, "OnUpdate", self)
	end
end
-- OnFrameUpdate
function IconLoot:OnUpdate(strVar, nValue)
	if self.wndIconLoot == nil then return end
	
	local fCurrTime = GameLib.GetGameTime()

	-- remove any old items
	for idx, tEntryData in ipairs(self.tEntryData) do
		if fCurrTime - tEntryData.fTimeAdded >= kfMaxItemTime then
			self:RemoveItem(idx)
		end
	end

	-- add a new item if its time
	if #self.tQueuedEntryData > 0 then
		if fCurrTime - self.fLastTimeAdded >= kfTimeBetweenItems then
			self:AddQueuedItem()
		end
		
		self:ResetQueue()
	else
		self:SlowDownQueue()
	end
	
	--Toggle visibility based on items (Perterter)
	if #self.tEntryData == 0 and not self.bShowingCash then
		self.wndIconLoot:Show(not self.bLockToggle)
	else
		if not self.wndIconLoot:IsShown() then
			self.wndIconLoot:Show(true)
		end
	end
	
	-- update all the items
	self:UpdateDisplay()
	self:UpdateNotification()
end

function IconLoot:UpdateNotification()
	-- cannot do anything while an item is present for notification
	if self.currNotifyItem or #self.tQueuedNotifications == 0 then return end
	
	self.currNotifyItem = table.remove(self.tQueuedNotifications, 1)

    if self.currNotifyItem == nil then return end
	
	local currItem = self.currNotifyItem.itemInstance
	local bGivenQuest  = currItem:GetGivenQuest()
	local eItemQuality = currItem:GetItemQuality() or 1

    self.wndNotification:FindChild("ItemDetails:ItemName"):SetText(currItem:GetName())
	self.wndNotification:FindChild("ItemDetails:ItemType"):SetText(currItem:GetItemTypeName())
	self.wndNotification:FindChild("Icon:IconBorder"):SetSprite(karItemQuality[eItemQuality].NotifyBorder)
	self.wndNotification:FindChild("RarityBar"):SetSprite(karItemQuality[eItemQuality].BarSprite)
	self.wndNotification:FindChild("QuestItem"):Show(bGivenQuest, true)
	
	self.wndNotification:FindChild("ItemCount"):Show(self.currNotifyItem.nCount > 1, true)
	self.wndNotification:FindChild("ItemCount"):SetText("x" .. self.currNotifyItem.nCount)
	
	self.wndNotification:FindChild("Icon"):SetBGColor(CColor.new(1, 1, 1, .8))
	self.wndNotification:FindChild("Icon"):SetSprite(currItem:GetIcon())
	self.wndNotification:FindChild("Icon"):SetTooltipDoc(nil)
	self.wndNotification:FindChild("Icon"):SetData(self.currNotifyItem)

	self.wndNotification:Show(true)
end

-----------------------------------------------------------------------------------------------
-- Called when the OnHideNotification timer exceeds it's timer, removing the
-- big notification window
-----------------------------------------------------------------------------------------------
function IconLoot:OnHideNotification()
	self.currNotifyItem = nil
	self.wndNotification:Show(false)
end

-----------------------------------------------------------------------------------------------
-- OnLootedItem
-- 
-- Called whenever something is looted ingame.
-- Takes eType, which is mapped to Item.CodeEnumItemLootType to check what we looted, and
-- tEventArgs that contains the information we need.
-----------------------------------------------------------------------------------------------
function IconLoot:OnLootedItem(eType, tEventArgs)
    -- If we looted money, then process it this way.
    if eType == Item.CodeEnumLootItemType.Cash then
		self.wndCashDisplay:SetAmount(tEventArgs.monNew:GetAmount())
        self.wndCashComplex:Show(true)
        self.bShowingCash = true
  
        -- Reset our timer so we can clear the loot window
		self.tmrCash:Stop()
		self.tmrCash:Start()
    end
  
    
    -- If we looted an item, process it this way.
    if eType == Item.CodeEnumLootItemType.AltTable then
        -- add this item to the queue to be popped during OnFrameUpdate-
        table.insert(self.tQueuedEntryData, {
            eType = knType_Item,
            itemInstance = tEventArgs.itemNew,
            nCount = tEventArgs.nCount,
            money = nil,
            fTimeAdded = GameLib.GetGameTime()
        })
	
        self.fLastTimeAdded = GameLib.GetGameTime()
	
        -- add item to notification queue if requirements met
        if self:IsValidNotification(tEventArgs.itemNew) and self.bShowNotification then
            table.insert(self.tQueuedNotifications, {
                eType = knType_Item,
                itemInstance = tEventArgs.itemNew,
                nCount = tEventArgs.nCount,
                fTimeAdded = GameLib.GetGameTime()
	        })
        end
    end
end

function IconLoot:IsValidNotification(luaItem)
    if luaItem:GetItemQuality() >= self.eMinNotifyQuality or (self.bNotifyQuestItems and luaItem:GetGivenQuest()) then

        if not self.bNotifyHarvestItems and ktHarvestItemCategories[luaItem:GetItemCategory()] then return end
		if self.bBlacklistSigns and luaItem:GetItemCategory() == 120 then return end
		
		return true
	end
end

function IconLoot:OnNotificationCloseBtn(wndHandler, wndControl)
	self:OnHideNotification()
end

function IconLoot:AddQueuedItem()
	-- gather our entryData we need
	local tQueuedData = self.tQueuedEntryData[1]
	table.remove(self.tQueuedEntryData, 1)
	if tQueuedData == nil then
		return
	end

	if tQueuedData.eType == knType_Item and tQueuedData.nCount == 0 then
		return
	end

	-- ensure there's room
	while #self.tEntryData >= knMaxEntryData do
		if not self:RemoveItem(1) then
			break
		end
	end

	-- push this item on the end of the table
	local fCurrTime = GameLib.GetGameTime()
	local nBtnIdx = #self.tEntryData + 1

    self.tEntryData[nBtnIdx] = tQueuedData
	self.tEntryData[nBtnIdx].fTimeAdded = fCurrTime -- adds a delay for vaccuum looting by switching logged to "shown" time
	self.fLastTimeAdded = fCurrTime
end

function IconLoot:RemoveItem(idx)
	-- validate our inputs
	if idx < 1 or idx > #self.tEntryData then
		return false
	end

	-- remove that item and alert inventory
	table.remove(self.tEntryData, idx)
	return true
end

function IconLoot:UpdateDisplay()
	if self.bRebuildItemWnd then return end

    -- lazy instantiation
	if #self.arEntries == 0 then
		self:RebuildItemWndList()
	end
	
	-- iterate over our entry data updating all the buttons
	for idx, wndEntry in ipairs(self.arEntries) do
		local tCurrEntryData = self.tEntryData[idx]
        local tCurrItem = tCurrEntryData and tCurrEntryData.itemInstance or false

        if tCurrEntryData and tCurrItem then
            if tCurrEntryData.nButton ~= idx then
                wndEntry:FindChild("Block"):SetTooltipDoc(nil)
                wndEntry:FindChild("Block"):SetData(tCurrEntryData)
                wndEntry:FindChild("Name_Text"):SetText(tCurrItem:GetName())
                wndEntry:FindChild("Type_Text"):SetText(tCurrItem:GetItemTypeName())
                wndEntry:FindChild("Count"):SetText("x" .. tCurrEntryData.nCount)

                local bGivenQuest = tCurrItem:GetGivenQuest()
                local eItemQuality = tCurrItem:GetItemQuality() or 1
                local sprItemBG = karItemQuality[eItemQuality].HeaderSprite

                wndEntry:FindChild("Name_Text"):SetTextColor(karItemQuality[eItemQuality].Color)
                wndEntry:FindChild("Type_Text"):SetTextColor(karItemQuality[eItemQuality].Color)
                wndEntry:FindChild("Count"):SetTextColor(karItemQuality[eItemQuality].Color)
                wndEntry:FindChild("ItemBG"):SetSprite(sprItemBG)
                wndEntry:FindChild("ItemBar"):SetSprite(karItemQuality[eItemQuality].BarSprite)
                wndEntry:FindChild("LootIconBorder"):SetSprite(karItemQuality[eItemQuality].SquareSprite)

                if bGivenQuest then
                    wndEntry:FindChild("LootIcon"):SetSprite("sprMM_QuestGiver")
                    wndEntry:FindChild("LootIcon"):SetBGColor("White")
                    wndEntry:FindChild("Count"):SetTextColor("Yellow")
                    wndEntry:FindChild("Name_Text"):SetTextColor("Yellow")
                    wndEntry:FindChild("Type_Text"):SetTextColor("Yellow")
                else
                    wndEntry:FindChild("LootIcon"):SetBGColor(CColor.new(1, 1, 1, .8))
                    wndEntry:FindChild("LootIcon"):SetSprite(tCurrItem:GetIcon())
                end

                tCurrEntryData.nButton = idx
            end

            wndEntry:Show(true)
        else
            wndEntry:FindChild("Block"):SetData(nil)
            wndEntry:FindChild("Block"):SetTooltipDoc(nil)
            wndEntry:Show(false)
        end
    end

	self.wndIconLoot:FindChild("LootedItemScroll"):ArrangeChildrenVert(self.bGrowDirection and 2 or 0)
	
	--Arrange Cash and Item Scroll based on Grow Direction (Perterter)
	self.wndIconLoot:FindChild("LootedItemScroll"):SetAnchorOffsets(0, self.bGrowDirection and 0 or 26, 0, self.bGrowDirection and -26 or 0)
	self.wndIconLoot:FindChild("CashComplex"):SetAnchorPoints(0, self.bGrowDirection and 1 or 0, 1, self.bGrowDirection and 1 or 0)
	self.wndIconLoot:FindChild("CashComplex"):SetAnchorOffsets(0, self.bGrowDirection and -26 or 0, 1, self.bGrowDirection and 0 or 26)
end

---------------------------------------------------------------------------------------------------
-- MinLootedItem Functions
---------------------------------------------------------------------------------------------------
function IconLoot:OnTooltip( wndHandler, wndControl, eToolTipType, x, y )
	if wndHandler ~= wndControl then return end

    local tEntryData = wndHandler:GetData()

    if tEntryData ~= nil and tEntryData.itemInstance ~= nil then
		Tooltip.GetItemTooltipForm(self, wndControl, tEntryData.itemInstance, { bPrimary = true, bSelling = false }, tEntryData.nCount)
	end
end

---------------------------------------------------------------------------------------------------
-- Anchor Form Functions
---------------------------------------------------------------------------------------------------

function IconLoot:OnAnchorLockBtn( wndHandler, wndControl, eMouseButton )
    self:LockToggle()
end

function IconLoot:OnAnchorTestBtn( wndHandler, wndControl, eMouseButton )
    self:PerformTest()
end

function IconLoot:OnAnchorCompactModeToggle( wndHandler, wndControl )
    if wndHandler ~= wndControl then return end
    self:CompactModeToggle(wndControl:IsChecked())
end

function IconLoot:OnAnchorGrowDirectionToggle( wndHandler, wndControl )
    if wndHandler ~= wndControl then return end
    self:GrowDirectionToggle(wndControl:IsChecked())
end

function IconLoot:OnShowNotification( wndHandler, wndControl, eMouseButton )
	if wndHandler ~= wndControl then return end
	self.bShowNotification = wndControl:IsChecked()
end

function IconLoot:OnAnchorNotifyQuestItems(wndHandler, wndControl)
    if wndHandler ~= wndControl then return end
    self.bNotifyQuestItems = wndControl:IsChecked()
end

function IconLoot:OnAnchorNotifyHarvestItems(wndHandler, wndControl)
    if wndHandler ~= wndControl then return end
    self.bNotifyHarvestItems = wndControl:IsChecked()
end

function IconLoot:OnAnchorNotificationItemQuality( wndHandler, wndControl, eMouseButton )
	self.eMinNotifyQuality = wndControl:GetData()
end

function IconLoot:OnNotificationTimeoutSliderChanged( wndHandler, wndControl, fNewValue, fOldValue )
	local wndLabel = self.wndIconLoot:FindChild("NotificationOptions:NotificationTimeoutSlider:NotificationTimeoutLabel")
    wndLabel:SetText(string.format("%.1f", fNewValue))
	self.fNotificationTimeout = fNewValue
end

---------------------------------------------------------------------------------------------------
-- IconLootForm Functions
---------------------------------------------------------------------------------------------------

function IconLoot:OnIconLootWindowResized( wndHandler, wndControl )
	local nOldMaxEntries = knMaxEntryData
	self:RecalculateMaxEntries()
	if nOldMaxEntries ~= knMaxEntryData then
		self:RebuildItemWndList()
	end
end

function IconLoot:OnAddBlacklistItemBtn( wndHandler, wndControl, eMouseButton )

end

function IconLoot:OnBlacklistSigns( wndHandler, wndControl, eMouseButton )
    if wndHandler ~= wndControl then return end
    self.bBlacklistSigns = wndControl:IsChecked()
end

local IconLootInst = IconLoot:new()
IconLootInst:Init()
