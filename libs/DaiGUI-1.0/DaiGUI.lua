-----------------------------------------------------------------------------------------------------------------------
-- GUI Widget Creation Library for WildStar.
-- @author daihenka
-----------------------------------------------------------------------------------------------------------------------
local MAJOR, MINOR = "DaiGUI-1.0", 3
local Lib = Apollo.GetPackage("DaiGUI-1.0") and Apollo.GetPackage("DaiGUI-1.0").tPackage or {}
if Lib and (Lib._VERSION or 0) >= MINOR then
	return -- no upgrade is needed
end

local assert, tostring, error, pcall = assert, tostring, error, pcall
local getmetatable, setmetatable, rawset, rawget, pairs = getmetatable, setmetatable, rawset, rawget, pairs
local type, next = type, next

Lib._VERSION = MINOR
Lib.WidgetRegistry = Lib.WidgetRegistry or {}
Lib.WidgetVersions = Lib.WidgetVersions or {}
 
-- local upvalues
local WidgetRegistry = Lib.WidgetRegistry
local WidgetVersions = Lib.WidgetVersions

-- Create a widget prototype object
-- @param strType (Optional) Widget type.  If not provided it will look at tOptions for 
--                a WidgetType value.  If no widget type is found, defaults to "Window".
-- @param tOptions Options table for the widget (see below usages)
-- @returns (table) Widget Prototype Object
--
-- @usage 
-- local btnProto = DaiGUI:Create("PushButton", { 
--   AnchorCenter = { 100, 30 }, 
--   Text   = "Push Me", 
--   Events = { ButtonSignal = function() Print("You pushed me!") end },
-- })
-- local wndBtn = btnProto:GetInstance()
--
-- @usage #2
-- local myEventHandler = { OnClick = function() Print("You pushed me!") end }
--
-- local btnProto = DaiGUI:Create({ 
--   WidgetType   = "PushButton", 
--   AnchorCenter = { 100, 30 }, 
--   Text   = "Push Me", 
--   Events = { ButtonSignal = "OnClick" },
-- })
-- local wndBtn = btnProto:GetInstance(myEventHandler)
function Lib:Create(strType, tOptions)
  -- check if passed a function to generate the tOptions
  if type(strType) == "function" then
    tOptions = strType()
    strType = tOptions.WidgetType or "Window"
    
  elseif type(strType) == "string" and type(tOptions) == "function" then
    tOptions = tOptions()
    strType = strType or tOptions.WidgetType or "Window"
  
  -- check if passed a table without a strType
  elseif type(strType) == "table" then
    tOptions = strType
    strType = tOptions.WidgetType or "Window"
  end
  
  if type(strType) ~= "string" then
    error(("Usage: Create([strType,] tOptions): 'strType' - string expected got '%s'."):format(type(strType)), 2)
  end
  if type(tOptions) ~= "table" then
    error(("Usage: Create([strType,] tOptions): 'tOptions' - table expected got '%s'."):format(type(tOptions)), 2)
  end
  
  -- check if tOptions is already a widget prototype
  if tOptions.__IsDaiGuiPrototype == true then 
    return tOptions 
  end
  
  strType = strType or "Window"
  
  -- if not, check if the widget type is valid
  if WidgetRegistry[strType] then
    -- create the widget
    local widget = WidgetRegistry[strType]()
    widget.WidgetVersion = WidgetVersions[strType]
    if tOptions ~= nil and type(tOptions) == "table" then
      widget:SetOptions(tOptions)
    end
    widget.__IsDaiGuiPrototype = true
    return widget
  end
end



-- Register a widget constructor that will return a new prototype of the widget
-- @param strType Name of the widget
-- @param fnConstructor Widget constructor function
-- @param nVersion Version of the widget
function Lib:RegisterWidgetType(strType, fnConstructor, nVersion)
  assert(type(fnConstructor) == "function")
  assert(type(nVersion) == "number")
  
  local oldVersion = WidgetVersions[strType]
  if oldVersion and oldVersion >= nVersion then return end
  
  WidgetVersions[strType] = nVersion
  WidgetRegistry[strType] = fnConstructor
end


-- Return the version of the currently registered widget type
-- @param strType Name of the widget
-- @returns (number) Version of the widget
function Lib:GetWidgetVersion(strType)
  return WidgetVersions[strType]
end

function Lib:OnLoad()
end

function Lib:OnDependencyError(strDep, strError)
  return false
end

Apollo.RegisterPackage(Lib, MAJOR, MINOR, {})

--[[------------------------------------------------------------------------------------------------------------------
  (`\ .-') /`       _ .-') _                 ('-.   .-') _     .-')    
   `.( OO ),'      ( (  OO) )              _(  OO) (  OO) )   ( OO ).  
,--./  .--.  ,-.-') \     .'_   ,----.    (,------./     '._ (_)---\_) 
|      |  |  |  |OO),`'--..._) '  .-./-')  |  .---'|'--...__)/    _ |  
|  |   |  |, |  |  \|  |  \  ' |  |_( O- ) |  |    '--.  .--'\  :` `.  
|  |.'.|  |_)|  |(_/|  |   ' | |  | .--, \(|  '--.    |  |    '..`''.) 
|         | ,|  |_.'|  |   / :(|  | '. (_/ |  .--'    |  |   .-._)   \ 
|   ,'.   |(_|  |   |  '--'  / |  '--'  |  |  `---.   |  |   \       / 
'--'   '--'  `--'   `-------'   `------'   `------'   `--'    `-----'       
--]]------------------------------------------------------------------------------------------------------------------
local DaiGUI = Lib

--[[ File: widgets/ControlBase.lua -----------------------------------------------------------------------------------

  Control - Base attributes and settings
  -----------------------------------------------------------------------------------
  | Attribute                | Desc                 | Houston Reference | Data Type |
  -----------------------------------------------------------------------------------
  | Name                     |                      | Window            | String    |
  | Class                    |                      | Window            | String    |
  | BGColor                  |                      | Window            | Color     |
  | Font                     |                      | Window            | String    |
  | Template                 |                      | Window            | String    |
  | Text                     |                      | Window            | String    |
  | TextId                   |                      | Window            | Number    |
  | TextColor                |                      | Window            | Color     |
  | Sprite                   |                      | Window            | Sprite    |
  | LeftAnchorOffset         |                      | Window            | Number    |
  | TopAnchorOffset          |                      | Window            | Number    |
  | RightAnchorOffset        |                      | Window            | Number    |
  | BottomAnchorOffset       |                      | Window            | Number    |
  | LeftAnchorPoint          |                      | Window            | Number    |
  | TopAnchorPoint           |                      | Window            | Number    |
  | RightAnchorPoint         |                      | Window            | Number    |
  | BottomAnchorPoint        |                      | Window            | Number    |
  | LeftEdgeControlsAnchor   |                      | Window            | String    |
  | TopEdgeControlsAnchor    |                      | Window            | String    |
  | RightEdgeControlsAnchor  |                      | Window            | String    |
  | BottomEdgeControlsAnchor |                      | Window            | String    |
  | Visible                  |                      | Window            | Boolean   |
  -----------------------------------------------------------------------------------
  | Moveable                 |                      | Styles            | Boolean   |
  | Border                   |                      | Styles            | Boolean   |
  | Escapable                |                      | Styles            | Boolean   |
  | IgnoreMouse              |                      | Styles            | Boolean   |
  | Picture                  |                      | Styles            | Boolean   |
  | Overlapped               |                      | Styles            | Boolean   |
  | AutoFade                 |                      | Styles            | Boolean   |
  | AutoFadeBG               |                      | Styles            | Boolean   |
  | AutoFadeNC               |                      | Styles            | Boolean   |
  | UseParentOpacity         |                      | Styles            | Boolean   |
  | AutoHideScroll           |                      | Styles            | Boolean   |
  | TabStop                  |                      | Styles            | Boolean   |
  | NeverBringToFront        |                      | Styles            | Boolean   |
  | AutoScaleText            |                      | Styles            | Boolean   |
  | TestAlpha                |                      | Styles            | Boolean   |
  | VScrollLeftSide          |                      | Styles            | Boolean   |
  | UseTemplateBG            |                      | Styles            | Boolean   |
  | DoNotBlockTooltip        |                      | Styles            | Boolean   |
  | UseRadialClipping        |                      | Styles            | Boolean   |
  | BlockOutIfDisabled       |                      | Styles            | Boolean   |
  | IgnoreTooltipDelay       |                      | Styles            | Boolean   |
  | TransitionShowHide       |                      | Styles            | Boolean   |
  | MaintainAspectRatio      |                      | Styles            | Boolean   |
  | ScaleOnShowHide          |                      | Styles            | Boolean   |
  | NoClip                   |                      | Styles            | Boolean   |
  | HScroll                  |                      | Styles            | Boolean   |
  | VScroll                  |                      | Styles            | Boolean   |
  | NotRelative              |                      | Styles            | Boolean   |
  | Sizable                  |                      | Styles            | Boolean   |
  | SwallowMouseClicks       |                      | Styles            | Boolean   |
  | RelativeToClient         |                      | Styles            | Boolean   |
  | CloseOnExternalClick     |                      | Styles            | Boolean   |
  | NewWindowDepth           | Window z-index       | Styles            | Boolean   |
  -----------------------------------------------------------------------------------
  | NewControlDepth          | Control z-index      | Undocumented      | Number    |
  | Scale                    |                      | Undocumented      | Number    |
  | Rotation                 |                      | Undocumented      | Number    |
  | BGOpacity                |                      | Undocumented      | Number    |
  | WindowSoundTemplate      |                      | Undocumented      | String    |
  | PosX                     | Depreciated?         | Undocumented      | Number    |
  | PosY                     | Depreciated?         | Undocumented      | Number    |
  | Width                    | Depreciated?         | Undocumented      | Number    |
  | Height                   | Depreciated?         | Undocumented      | Number    |
  -----------------------------------------------------------------------------------
  | DT_CENTER                |                      | TextFlags         | Boolean   |
  | DT_VCENTER               |                      | TextFlags         | Boolean   |
  | DT_RIGHT                 |                      | TextFlags         | Boolean   |
  | DT_BOTTOM                |                      | TextFlags         | Boolean   |
  | DT_WORDBREAK             |                      | TextFlags         | Boolean   |
  | DT_SINGLELINE            |                      | TextFlags         | Boolean   |
  -----------------------------------------------------------------------------------
  | Tooltip                  |                      | Tooltip           | String    |
  | TooltipColor             |                      | Tooltip           | String    |
  | TooltipId                |                      | Tooltip           | String    |
  | TooltipType              | See eTooltipType     | Tooltip           | String    | 
  -----------------------------------------------------------------------------------
  
  eTooltipType = { "OnCursor", "NavText", "DynamicFloater", "UserDraw" }
  
  
  Control - Events 
  NOTE: The first three parameters for each control (or subclass) event signature are omitted below and in their documentation.  
  The first three parameters should always be: self, wndHandler, wndControl
  e.g. MouseButtonDown will become MouseButtonDown(self, wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation)
  
  - AnimEnded(strAnimDataId)
  - AnimStarted(strAnimDataId)
  - AnimStopped(strAnimDataId)
  - DragDrop(x, y, wndSource, strType, iData, bDragDropHasBeenReset)
  - DragDropCancel(strType, iData, eReason, bDragDropHasBeenReset)
  - DragDropClear()
  - DragDropEnd(strType, iData, bDragDropHasBeenReset)
  - DragDropNothingCursor(strType, iData)
  - DragDropTargetNotify(bMe)
  - GenerateTooltip(eToolTipType, x, y)
  - MouseButtonDown(eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation)
  - MouseButtonUp(eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY)
  - MouseEnter(x, y)
  - MouseExit(x, y)
  - MouseMove(nLastRelativeMouseX, nLastRelativeMouseY)
  - MouseWheel(nLastRelativeMouseX, nLastRelativeMouseY, fScrollAmount, bConsumeMouseWheel)
  - QueryBeginClickStick(x, y, bClickStickStarted)
  - QueryBeginDragDrop(x, y, bDragDropStarted)
  - QueryDragDrop(x, y, wndSource, strType, iData, eResult)
  - WindowClosed()
  - WindowHide()
  - WindowKeyDown(strKeyName, nScanCode, nMetakeys)
  - WindowKeyEscape()
  - WindowKeyReturn()
  - WindowKeyTab()
  - WindowLoad()
  - WindowMove(nOldLeft, nOldTop, nOldRight, nOldBottom)
  - WindowShow()
  - WindowSizeChanged()
  - WindowToFront(bOkToBringToFront)
--]]------------------------------------------------------------------------------------------------------------------
do
DaiGUI.ControlBase = {}
local Control = DaiGUI.ControlBase
local kstrDefaultName = "DaiGUIControl"

local pairs, ipairs, type, unpack, error = pairs, ipairs, type, unpack, error
local setmetatable, tostring = setmetatable, tostring

local ktAnchorPoints = {
 TOPLEFT       = {   0,   0,   0,   0 },
 TOPRIGHT      = {   1,   0,   1,   0 },
 BOTTOMLEFT    = {   0,   1,   0,   1 },
 BOTTOMRIGHT   = {   1,   1,   1,   1 },
 CENTER        = { 0.5, 0.5, 0.5, 0.5 },
 VCENTER       = {   0, 0.5,   0, 0.5 },
 HCENTER       = { 0.5,   0, 0.5,   0 },
 VCENTERRIGHT  = {   1, 0.5,   1, 0.5 },
 HCENTERBOTTOM = { 0.5,   1, 0.5,   1 },
 FILL          = {   0,   0,   1,   1 },
 HFILL         = {   0,   0,   1,   0 },
 VFILL         = {   0,   0,   0,   1 },
 VFILLRIGHT    = {   1,   0,   1,   1 },
 HFILLBOTTOM   = {   0,   1,   1,   1 },
}

local function TranslateAnchorPoint(s, tOptions, v)
  if type(v) == "string" then
    tOptions.LAnchorPoint, tOptions.TAnchorPoint, tOptions.RAnchorPoint, tOptions.BAnchorPoint = unpack(ktAnchorPoints[v])
  elseif type(v) == "table" then
    tOptions.LAnchorPoint, tOptions.TAnchorPoint, tOptions.RAnchorPoint, tOptions.BAnchorPoint = unpack(v)
  end
end

local function SetupWhiteFillMe(self, tOptions, v)
    if v ~= true then return end
    tOptions.Picture = true
    tOptions.Sprite  = "ClientSprites:WhiteFill"
    tOptions.BGColor = "white"
end


local kSpecialFields = {
  AnchorOffsets = function(s, tOptions, v)
    tOptions.LAnchorOffset, tOptions.TAnchorOffset, tOptions.RAnchorOffset, tOptions.BAnchorOffset = unpack(v)
  end,
  
  AnchorPoints = TranslateAnchorPoint,
  Anchor = TranslateAnchorPoint,
  
  IncludeEdgeAnchors = function(s, tOptions, v)
    if type(v) ~= "string" and (s.options.Name == nil or string.len(s.options.Name) == 0) then
      error("IncludeEdgeAnchors requires a string or the control name to be set", 2)
    end
    local strPrefix = ((type(v) == "string") and v or s.options.Name)
    tOptions.LeftEdgeControlsAnchor, tOptions.TopEdgeControlsAnchor, tOptions.RightEdgeControlsAnchor, tOptions.BottomEdgeControlsAnchor = strPrefix .. "_Left", strPrefix .. "_Top", strPrefix .. "_Right", strPrefix .. "_Bottom"
  end,
    
  AnchorCenter = function(s, tOptions, v)
    if type(v) ~= "table" or #v ~= 2 then return end
    local nWidth, nHeight = unpack(v)
    tOptions.LAnchorPoint,  tOptions.TAnchorPoint,  tOptions.RAnchorPoint,  tOptions.BAnchorPoint = unpack(ktAnchorPoints["CENTER"])
    tOptions.LAnchorOffset, tOptions.TAnchorOffset, tOptions.RAnchorOffset, tOptions.BAnchorOffset = nWidth / 2 * -1, nHeight / 2 * -1, nWidth / 2, nHeight / 2
  end,
  
  AnchorFill = function(s, tOptions, v)
    local nPadding = (type(v) == "number") and v or 0
    tOptions.LAnchorPoint, tOptions.TAnchorPoint, tOptions.RAnchorPoint, tOptions.BAnchorPoint = unpack(ktAnchorPoints["FILL"])
    tOptions.LAnchorOffset, tOptions.TAnchorOffset, tOptions.RAnchorOffset, tOptions.BAnchorOffset = nPadding, nPadding, -nPadding, -nPadding
  end,
  
  PosSize = function(s, tOptions, v)
    if type(v) ~= "table" or #v ~= 4 then return end
    local nLeft, nTop, nWidth, nHeight = unpack(v)
    tOptions.LAnchorPoint, tOptions.TAnchorPoint, tOptions.RAnchorPoint, tOptions.BAnchorPoint = unpack(ktAnchorPoints["TOPLEFT"])
    tOptions.LAnchorOffset, tOptions.TAnchorOffset, tOptions.RAnchorOffset, tOptions.BAnchorOffset = nLeft, nTop, nLeft + nWidth, nTop + nHeight
  end,
  
  UserData = function(s, tOptions, v)
    s:SetData(v)
  end,
  LuaData = function(s, tOptions, v)
    s:SetData(v)
  end,  
  Events = function(s, tOptions, v)
    if type(v) == "table" then
      for strEventName, oHandler in pairs(v) do
        if type(strEventName) == "number" and type(oHandler) == "table" then -- handle the old style
          s:AddEvent(unpack(oHandler))
        elseif type(strEventName) == "string" and (type(oHandler) == "string" or type(oHandler) == "function") then
          s:AddEvent(strEventName, oHandler)
        end
      end
    end
  end,
  
  Pixies = function(s, tOptions, v)
    if type(v) == "table" then
      for _, tPixie in ipairs(v) do
        s:AddPixie(tPixie)
      end
    end
  end,
  
  Children = function(s, tOptions, v)
    if type(v) == "table" then
      for _, tChild in ipairs(v) do
        local strWidgetType = "Window"
        if type(tChild.WidgetType) == "string" then
          strWidgetType = tChild.WidgetType
        end
        s:AddChild(DaiGUI:Create(strWidgetType, tChild))
      end
    end
  end,
}


function Control:new(o)
  o = o or {}
  
  o.events = {}
  o.children = {}
  o.pixies = {}
  o.options = {}
  
  setmetatable(o, self)
  self.__index = self
  
  return o
end

-- Set an option on the widget prototype
-- @param strOptionName the option name
-- @param value the value to set
function Control:SetOption(key, value)
  self.options[key] = value
end

-- Set multiple options on the widget prototype
-- @param tOptions the options table
function Control:SetOptions(tOptions)
  for k,v in pairs(tOptions) do
    self.options[k] = v
  end
end

-- pixie mapping table
local ktPixieMapping = {
  strText   = "Text",
  strFont   = "Font",
  bLine     = "Line",
  fWidth    = "Width",
  strSprite = "Sprite",
  cr        = "BGColor",
  crText    = "TextColor",
  fRotation = "Rotation",
  strTextId = "TextId",
  nTextId   = "TextId",
  loc       = { fPoints = "AnchorPoints", nOffsets = "AnchorOffsets" },
  flagsText = { DT_CENTER = "DT_CENTER", DT_VCENTER = "DT_VCENTER", DT_RIGHT = "DT_RIGHT", DT_BOTTOM = "DT_BOTTOM", 
                DT_WORDBREAK = "DT_WORDBREAK", DT_SINGLELINE = "DT_SINGLELINE" },
}

-- Add a pixie to the widget prototype
-- @param tPixie a table with pixie options
function Control:AddPixie(tPixie)
  if tPixie == nil then return end
  
  -- in case someone uses the C++ Window:AddPixie() format.  Preference to the XML format over the C++ Window:AddPixie() format.
  for oldKey, newKey in pairs(ktPixieMapping) do
    if tPixie[oldKey] ~= nil then
      if type(tPixie[oldKey]) == "table" then
        for oldKey2, newKey2 in pairs(tPixie[oldKey]) do
          if tPixie[oldKey][oldKey2] ~= nil then
            tPixie[newKey2] = tPixie[newKey2] or tPixie[oldKey][oldKey2]
          end
        end
      else
        tPixie[newKey] = tPixie[newKey] or tPixie[oldKey]
      end
    end
  end
  
  
  if type(tPixie.AnchorOffsets) == "table" then
    tPixie.LAnchorOffset, tPixie.TAnchorOffset, tPixie.RAnchorOffset, tPixie.BAnchorOffset = unpack(tPixie.AnchorOffsets)
    tPixie.AnchorOffsets = nil
  end
  if tPixie.AnchorPoints ~= nil or tPixie.Anchor ~= nil then
    local tAnchorPoints = tPixie.AnchorPoints or tPixie.Anchor
    if type(tAnchorPoints) == "string" then
      tPixie.LAnchorPoint, tPixie.TAnchorPoint, tPixie.RAnchorPoint, tPixie.BAnchorPoint = unpack(ktAnchorPoints[tAnchorPoints])
    else
      tPixie.LAnchorPoint, tPixie.TAnchorPoint, tPixie.RAnchorPoint, tPixie.BAnchorPoint = unpack(tAnchorPoints)
    end
    tPixie.AnchorPoints = nil
    tPixie.Anchor = nil
  end
  if tPixie.AnchorFill ~= nil then
    tPixie.LAnchorPoint, tPixie.TAnchorPoint, tPixie.RAnchorPoint, tPixie.BAnchorPoint = unpack(ktAnchorPoints["FILL"])
    if type(self.options.AnchorFill) == "number" then
      local nPadding = tPixie.AnchorFill
      tPixie.LAnchorOffset, tPixie.TAnchorOffset, tPixie.RAnchorOffset, tPixie.BAnchorOffset = nPadding, nPadding, -nPadding, -nPadding
    elseif type(self.options.AnchorFill) == "boolean" then
      tPixie.LAnchorOffset, tPixie.TAnchorOffset, tPixie.RAnchorOffset, tPixie.BAnchorOffset = 0,0,0,0
    end
    tPixie.AnchorFill = nil
  end
  if type(tPixie.AnchorCenter) == "table" then
    local nWidth, nHeight = unpack(tPixie.AnchorCenter)
    tPixie.LAnchorPoint, tPixie.TAnchorPoint, tPixie.RAnchorPoint, tPixie.BAnchorPoint = unpack(ktAnchorPoints["CENTER"])
    tPixie.LAnchorOffset, tPixie.TAnchorOffset, tPixie.RAnchorOffset, tPixie.BAnchorOffset = nWidth / 2 * -1, nHeight / 2 * -1, nWidth / 2, nHeight / 2
    tPixie.AnchorCenter = nil
  end
  if type(tPixie.PosSize) == "table" then
    local nLeft, nTop, nWidth, nHeight = unpack(tPixie.PosSize)
    tPixie.LAnchorPoint, tPixie.TAnchorPoint, tPixie.RAnchorPoint, tPixie.BAnchorPoint = unpack(ktAnchorPoints["TOPLEFT"])
    tPixie.LAnchorOffset, tPixie.TAnchorOffset, tPixie.RAnchorOffset, tPixie.BAnchorOffset = nLeft, nTop, nLeft + nWidth, nTop + nHeight
    tPixie.PosSize = nil
  end
  
  tPixie.LAnchorOffset = tPixie.LAnchorOffset or 0
  tPixie.RAnchorOffset = tPixie.RAnchorOffset or 0
  tPixie.TAnchorOffset = tPixie.TAnchorOffset or 0
  tPixie.BAnchorOffset = tPixie.BAnchorOffset or 0
  tPixie.LAnchorPoint  = tPixie.LAnchorPoint  or 0
  tPixie.RAnchorPoint  = tPixie.RAnchorPoint  or 0
  tPixie.TAnchorPoint  = tPixie.TAnchorPoint  or 0
  tPixie.BAnchorPoint  = tPixie.BAnchorPoint  or 0
  
  -- ensure that pixie booleans are properly converted to 1/0
  for k,v in pairs(tPixie) do
    if type(v) == "boolean" then
      tPixie[k] = v and "1" or "0"
    end
  end
  
  table.insert(self.pixies, tPixie)
end

-- Add a child widget prototype to the widget prototype
-- @param tChild The child widget to add -- NOTE: Must be a DaiGUI:Create() blessed prototype
function Control:AddChild(tChild)
  if tChild == nil then return end
  table.insert(self.children, tChild)
end

-- Add an event handler to the widget prototype
-- @param strName The event name to be handled
-- @param strFunction (Optional) The function name on the event handler table
-- @param fnInline (Optional) The anonymous function to handle the event
--
-- @usage myPrototype:AddEvent("ButtonSignal", "OnButtonClick") -- when the event is fired, it will call OnButtonClick on the event handler table
-- @usage myPrototype:AddEvent("ButtonSignal", function() Print("Clicked!") end) -- when the event is fired, the anonymous function will be called
function Control:AddEvent(strName, strFunction, fnInline)
  if type(strFunction) == "function" then
    fnInline = strFunction
    strFunction = "On" .. strName .. tostring(fnInline):gsub("function: ", "_")
  end
  
  table.insert(self.events, {strName = strName, strFunction = strFunction, fnInline = fnInline })
end

-- Set the data the widget is to store
-- @param oData the lua data object
function Control:SetData(oData)
  self.oData = oData
end

-- Parses the options table for the widget
-- Internal use only
function Control:ParseOptions()
  local tOptions = {}
  
  for k, fn in pairs(kSpecialFields) do
    if self.options[k] ~= nil then
      fn(self, tOptions, self.options[k])
    end
  end
  
  for k,v in pairs(self.options) do
    if not kSpecialFields[k] or k == "WhiteFillMe" then
      tOptions[k] = v
    end
  end
  
  SetupWhiteFillMe(self, tOptions, self.options.WhiteFillMe) -- for debug purposes ;)

  -- if picture hasn't been set but a sprite has been, enable picture
  if tOptions.Sprite ~= nil and tOptions.Picture == nil then
    tOptions.Picture = true
  end
  
  for k,v in pairs(tOptions) do
    if type(v) == "boolean" then
      tOptions[k] = v and "1" or "0"
    end
  end
  
  return tOptions
end

-- Creates an XmlDoc Table of the widget prototype
function Control:ToXmlDocTable(bIsForm)
  local tInlineFunctions = {}
  
  local tForm = self:ParseOptions()
  
  -- setup defaults and necessary values
  tForm.__XmlNode            = bIsForm and "Form" or "Control"
  tForm.Font                 = tForm.Font or "Default"
  tForm.Template             = tForm.Template or "Default"
  tForm.TooltipType          = tForm.TooltipType or "OnCursor"
  
  if not tForm.PosX or not tForm.PosY or not tForm.Height or not tForm.Width then
    tForm.TAnchorOffset        = tForm.TAnchorOffset or 0
    tForm.LAnchorOffset        = tForm.LAnchorOffset or 0
    tForm.BAnchorOffset        = tForm.BAnchorOffset or 0
    tForm.RAnchorOffset        = tForm.RAnchorOffset or 0
    
    tForm.BAnchorPoint         = tForm.BAnchorPoint  or 0
    tForm.RAnchorPoint         = tForm.RAnchorPoint  or 0
    tForm.TAnchorPoint         = tForm.TAnchorPoint  or 0
    tForm.LAnchorPoint         = tForm.LAnchorPoint  or 0
  end
 
  if self.AddSubclassFields ~= nil and type(self.AddSubclassFields) == "function" then
    self:AddSubclassFields(tForm)
  end 
  
  tForm.Name                 = tForm.Name or kstrDefaultName
  tForm.Class                = tForm.Class or "Window"
  
  local tAliasEvents = {}
  local tInlineLookup = {}
  for _, tEvent in ipairs(self.events) do
    if tEvent.strName and tEvent.strFunction and tEvent.strName ~= "" then 
      if tEvent.strFunction:match("^Event::") then
        table.insert(tAliasEvents, tEvent)
      elseif tEvent.strFunction ~= "" then
        table.insert(tForm, { __XmlNode = "Event", Function = tEvent.strFunction, Name = tEvent.strName })
        if tEvent.fnInline ~= nil then
          tInlineLookup[tEvent.strName] = tEvent.strFunction
          tInlineFunctions[tEvent.strFunction] = tEvent.fnInline
        end
      end
    end
  end
  
  -- check if an event would like to reference an another event handler's inline function
  for _, tEvent in ipairs(tAliasEvents) do
    local strFunctionName = tInlineLookup[tEvent.strFunction:gsub("^Event::", "")]
    if strFunctionName then
      table.insert(tForm, { __XmlNode = "Event", Function = strFunctionName, Name = tEvent.strName })
    end
  end
  
  for _, tPixie in ipairs(self.pixies) do
    local tPixieNode = { __XmlNode = "Pixie",  }
    for k,v in pairs(tPixie) do
      tPixieNode[k] = v
    end
    table.insert(tForm, tPixieNode)
  end
  
  for _, tChild in ipairs(self.children) do 
    if tChild.ToXmlDocTable and type(tChild.ToXmlDocTable) == "function" then
      local tXd, tIf = tChild:ToXmlDocTable()
      table.insert(tForm, tXd)
      for k,v in pairs(tIf) do
        tInlineFunctions[k] = tInlineFunctions[k] or v
      end
    end
  end
  
  if self.oData ~= nil then
    tForm.__DAIGUI_LUADATA = self.oData
  end
    
  if bIsForm then
    tForm = { __XmlNode = "Forms", tForm }
  end
  
  return tForm, tInlineFunctions
end

-- Collect window name, data and text from the XmlDoc table (recursively)
-- and give each window a unique name for it's layer
local kstrTempName = "DaiGUIWindow."
local function CollectNameData(tXml, tData, strNamespace)
  if type(tXml) ~= "table" then return end
  
  local nCount = 0
  tData = tData or {}
  strNamespace = strNamespace or ""
  
  for i, t in ipairs(tXml) do
    if t.__XmlNode == "Control" then -- only process controls (aka children)
      local strName = t.Name
      local strNS = string.format("%s%s%s", strNamespace, strNamespace:len() > 0 and ":" or "", strName)
      while (strName or "") == "" or tData[strNS] ~= nil do
        -- window name already exists at this child depth, rename it temporarily
        nCount = nCount + 1
        strName = "DaiGUIWindow." .. nCount
        strNS = string.format("%s%s%s", strNamespace, strNamespace:len() > 0 and ":" or "", strName)
      end
      
      local strFinalName = t.Name or strName
      
      -- collect the info for the window/control
      tData[strNS] = { strNS = strNS, strName = strName, strFinalName = strFinalName, luaData = t.__DAIGUI_LUADATA, strText = t.Text, bIsMLWindow = t.Class == "MLWindow" }
      
      -- rename the window to the unique layered name
      t.Name = strName
      
      -- clean up XmlDoc table by removing unnecessary elements
      t.__DAIGUI_LUADATA = nil
      
      CollectNameData(t, tData, strNS)
    elseif t.__XmlNode == "Form" or t.__XmlNode == "Forms" then
      CollectNameData(t, tData, "")
    end
  end
  return tData
end

-- Process each window and it's children and assign data, AML 
-- and rename the window back to what the consumer wants.
local function FinalizeWindow(wnd, tData)
  -- collect a list of keys and sort them in order
  -- of how deep they are overall (# of :) (>^o^)>
  local tChildOrder = {}
  for strNS, _ in pairs(tData) do
    local _, nCount = strNS:gsub(":", "")
    table.insert(tChildOrder, { strNS, nCount })
  end
  table.sort(tChildOrder, function(a,b) return a[2] > b[2] end)
  
  -- process child windows in depth order, setting their data, AML and
  -- renaming them back to what they are intended to be
  for i = 1, #tChildOrder do
    local tWndData = tData[tChildOrder[i][1]]
    local wndChild = wnd:FindChild(tWndData.strNS)
    if wndChild then
      if tWndData.luaData then
        wndChild:SetData(tWndData.luaData)
      end
      if tWndData.bIsMLWindow and tWndData.strText then
        wndChild:SetAML(tWndData.strText)
      end
      if tWndData.strFinalName ~= tWndData.strName then
        wndChild:SetName(tWndData.strFinalName)
      end
    end
  end
end


-- Gets an instance of the widget
-- @param eventHandler The eventHandler of the widget
-- @param wndParent The parent of the widget
-- @returns (userdata) The userdata version of the widget
function Control:GetInstance(eventHandler, wndParent)
  eventHandler = eventHandler or {}
  if type(eventHandler) ~= "table" then
    error("Usage: EventHandler is not valid.  Must be a table.")
  end
  local xdt, tInlines = self:ToXmlDocTable(true)
  
  for k,v in pairs(tInlines) do
    eventHandler[k] = eventHandler[k] or v
  end
  
  -- collect names and reassign them to something generic
  -- collect any lua data and if AML needs to be set
  local tChildData = CollectNameData(xdt)
  
  -- create the XmlDoc and C++ window
  local xd = XmlDoc.CreateFromTable(xdt)
  local strFormName = self.options.Name or kstrDefaultName
  local wnd = Apollo.LoadForm(xd, strFormName, wndParent, eventHandler)
  
  if wnd then
    -- set the lua data and aml followed by name for all child widgets
    FinalizeWindow(wnd, tChildData)
    
    if self.oData then
      wnd:SetData(self.oData)
    end
  else
--    Print("DaiGUI failed to create window")
  end
  
  return wnd
end
end
--[[ File: widgets/Window.lua ----------------------------------------------------------------------------------------
  
  No Specific attributes (inherits Control attributes)
  No Specific events (inherits Control events)

--]]------------------------------------------------------------------------------------------------------------------
do
local WidgetType, Version = "Window", 1

local function Constructor()
  local ctrl = DaiGUI.ControlBase:new()
  ctrl:SetOptions{
    Class             = WidgetType,
    Name              = "DaiGUI" .. WidgetType,
    RelativeToClient  = true,
    Font              = "Default",
    Template          = "Default",
    TooltipType       = "OnCursor",
  }
  return ctrl
end

DaiGUI:RegisterWidgetType(WidgetType, Constructor, Version)
end


--[[ File: widgets/Button.lua ----------------------------------------------------------------------------------------

  Specific attributes (inherits Control attributes)
  ------------------------------------------------------------------------------------
  | Attribute                 | Desc                 | Houston Reference | Data Type |
  ------------------------------------------------------------------------------------
  | Base                      |                      | Button            | Sprite    |
  | ButtonType                |                      | Button            | String    |
  | RadioGroup                |                      | Button            | String    |
  | NormalTextColor           |                      | Button            | Color     |
  | PressedTextColor          |                      | Button            | Color     |
  | PressedFlybyTextColor     |                      | Button            | Color     |
  | FlybyTextColor            |                      | Button            | Color     |
  | DisabledTextColor         |                      | Button            | Color     |
  | ContentType               |                      | Button            | String    |
  | ContentId                 |                      | Button            | Number    |
  | GlobalRadioGroup          |                      | Button            | String    |
  | BuzzerFrequency           |                      | Button            | Number    |
  | SetHotkey                 |                      | Button            | String    |
  | SetMetakey                |                      | Button            | String    |
  ------------------------------------------------------------------------------------
  | CheckboxRight             |                      | StyleEx           | Boolean   |
  | DrawAsCheckbox            |                      | StyleEx           | Boolean   |
  | DrawHotkey                |                      | StyleEx           | Boolean   |
  | DrawClientSprite          |                      | StyleEx           | Boolean   |
  | IfHoldNoSignal            |                      | StyleEx           | Boolean   |
  | RadioDisallowNonSelection |                      | StyleEx           | Boolean   |
  | RadioAlwaysSignal         |                      | StyleEx           | Boolean   |
  | ProcessRightClick         |                      | StyleEx           | Boolean   |
  | UseWindowTextColor        |                      | StyleEx           | Boolean   |
  ------------------------------------------------------------------------------------

  Specific Events (inherits Control events)
  - ButtonCheck(eMouseButton)
  - ButtonDown(eMouseButton)
  - ButtonHoldBegin(eMouseButton)
  - ButtonSignal(eMouseButton)
  - ButtonUncheck(eMouseButton)
  - ButtonUp(eMouseButton)
  - ButtonUpCancel(eMouseButton)
  
--]]------------------------------------------------------------------------------------------------------------------
do
local WidgetType, Version = "Button", 1
local Button = DaiGUI.ControlBase:new()

local function GetTextTheme(strTheme)
  return {
    NormalTextColor       = strTheme .. "Normal",
    PressedTextColor      = strTheme .. "Pressed",
    PressedFlybyTextColor = strTheme .. "PressedFlyby",
    FlybyTextColor        = strTheme .. "Flyby",
    DisabledTextColor     = strTheme .. "Disabled"
  }
end

local function GetTextColorTheme(strColor)
  return {
    NormalTextColor       = strColor,
    PressedTextColor      = strColor,
    PressedFlybyTextColor = strColor,
    FlybyTextColor        = strColor,
    DisabledTextColor     = strColor
  }
end


function Button:SetTextThemeToColor(strColor)
  self:SetOptions(GetTextColorTheme(strColor))
end

function Button:SetTextTheme(strTheme)
  self:SetOptions(GetTextTheme(strTheme))
end

function Button:AddSubclassFields(tForm)
  if self.options.TextThemeColor ~= nil then
    local tTheme = GetTextColorTheme(self.options.TextThemeColor)
    for k,v in pairs(tTheme) do
      tForm[k] = v
    end
    if tForm.TextThemeColor ~= nil then
      tForm.TextThemeColor = nil
    end
  end
  if self.options.TextTheme ~= nil then
    local tTheme = GetTextTheme(self.options.TextTheme)
    for k,v in pairs(tTheme) do
      tForm[k] = v
    end
    if tForm.TextTheme ~= nil then
      tForm.TextTheme = nil
    end
  end
end

local function Constructor()
  local ctrl = Button:new()
  ctrl:SetOptions{
    Name          = "DaiGUI" .. WidgetType,
    Class         = WidgetType,
    ButtonType    = "PushButton",
    RadioGroup    = "",
    Font          = "Thick",
    DT_VCENTER    = true, 
    DT_CENTER     = true,
  }
  return ctrl
end

DaiGUI:RegisterWidgetType(WidgetType, Constructor, Version)
end



--[[ File: widgets/PushButton.lua ------------------------------------------------------------------------------------

  See Button.lua

--]]------------------------------------------------------------------------------------------------------------------
do
local WidgetType, Version = "PushButton", 1

local function Constructor()
  local btn = DaiGUI:Create('Button', {
    Name       = "DaiGUI" .. WidgetType,
    ButtonType = "PushButton",
    DT_VCENTER = true,
    DT_CENTER  = true,
    Base       = "CRB_Basekit:kitBtn_Holo",
    Font       = "CRB_InterfaceMedium",
  })
  btn:SetTextTheme("UI_BtnTextHolo")
  return btn
end

DaiGUI:RegisterWidgetType(WidgetType, Constructor, Version)
end



--[[ File: widgets/Buzzer.lua ----------------------------------------------------------------------------------------

  See Button.lua

--]]------------------------------------------------------------------------------------------------------------------
do
local WidgetType, Version = "Buzzer", 1

local function Constructor()
  local btn = DaiGUI:Create('Button', {
    Name            = "DaiGUI" .. WidgetType,
    ButtonType      = "Buzzer",
    DT_VCENTER      = true,
    DT_CENTER       = true,
    Base            = "CRB_Basekit:kitBtn_Holo",
    Font            = "CRB_InterfaceMedium",
    BuzzerFrequency = 15,
  })
  btn:SetTextTheme("UI_BtnTextHolo")
  return btn
end

DaiGUI:RegisterWidgetType(WidgetType, Constructor, Version)
end



--[[ File: widgets/CheckBox.lua --------------------------------------------------------------------------------------

  See Button.lua

--]]------------------------------------------------------------------------------------------------------------------
do
local WidgetType, Version = "CheckBox", 1

local function Constructor()
  local checkbox = DaiGUI:Create('Button', {
    Name           = "DaiGUI" .. WidgetType,
    DrawAsCheckbox = true,
    DT_CENTER      = false,
    DT_VCENTER     = true,
    ButtonType     = "Check",
    Font           = "CRB_InterfaceMedium",
    Base           = "CRB_Basekit:kitBtn_Holo_RadioRound",
    TextColor      = "White",
  })
  return checkbox
end

DaiGUI:RegisterWidgetType(WidgetType, Constructor, Version)
end



--[[ File: widgets/ActionBarButton.lua -------------------------------------------------------------------------------

  Specific attributes (inherits Control attributes)
  -----------------------------------------------------------------------------------------
  | Attribute                      | Desc                 | Houston Reference | Data Type |
  -----------------------------------------------------------------------------------------
  | DrawAsCheckbox                 |                      | StylesEx          | Boolean   |
  | CheckboxRight                  |                      | StylesEx          | Boolean   |
  | DrawHotkey                     |                      | StylesEx          | Boolean   |
  | DrawClientSprite               |                      | StylesEx          | Boolean   |
  | IfHoldNoSignal                 |                      | StylesEx          | Boolean   |
  | RadioDisallowNonSelection      |                      | StylesEx          | Boolean   |
  | RadioAlwaysSignal              |                      | StylesEx          | Boolean   |
  | ProcessRightClick              |                      | StylesEx          | Boolean   |
  | UseWindowTextColor             |                      | StylesEx          | Boolean   |
  | UseBaseButtonArt               |                      | StylesEx          | Boolean   |
  | DisallowDragDrop               |                      | StylesEx          | Boolean   |
  -----------------------------------------------------------------------------------------
  | ContentType                    |                      | ActionBarButton   | String    |
  | ContentId                      |                      | ActionBarButton   | Number    |
  | Base                           |                      | ActionBarButton   | String    |
  | RechargeBarLAnchorPoint        |                      | ActionBarButton   | Number    |
  | RechargeBarLAnchorOffset       |                      | ActionBarButton   | Number    |
  | RechargeBarTAnchorPoint        |                      | ActionBarButton   | Number    |
  | RechargeBarTAnchorOffset       |                      | ActionBarButton   | Number    |
  | RechargeBarRAnchorPoint        |                      | ActionBarButton   | Number    |
  | RechargeBarRAnchorOffset       |                      | ActionBarButton   | Number    |
  | RechargeBarBAnchorPoint        |                      | ActionBarButton   | Number    |
  | RechargeBarBAnchorOffset       |                      | ActionBarButton   | Number    |
  | RechargeBarEmptyColorAttribute |                      | ActionBarButton   | Color     |
  | RechargeBarFullColorAttribute  |                      | ActionBarButton   | Color     |
  | RechargeBarEmptyAttribute      |                      | ActionBarButton   | String    |
  | RechargeBarFullAttribute       |                      | ActionBarButton   | String    |
  | ShortHotkeyFontAttribute       |                      | ActionBarButton   | String    |
  | LongHotkeyFontAttribute        |                      | ActionBarButton   | String    |
  | CountFontAttribute             |                      | ActionBarButton   | String    |
  | CooldownFontAttribute          |                      | ActionBarButton   | String    |
  | LeftMargin                     |                      | ActionBarButton   | Number    |
  | TopMargin                      |                      | ActionBarButton   | Number    |
  | RightMargin                    |                      | ActionBarButton   | Number    |
  | BottomMargin                   |                      | ActionBarButton   | Number    |
  -----------------------------------------------------------------------------------------

  No Specific events (inherits Window events)
  
  -----------------------------------------------------------------------------------------------------------
  | ContentType       | ContentId | Description                   |                                         |
  -----------------------------------------------------------------------------------------------------------
  | GCBar             |     2     | Innate Ability                |                                         |
  | GCBar             |     8     | Vehicle Dismount              |                                         |
  | GCBar             |    18     | Recall Transmat               | GameLib.CodeEnumRecallCommand.BindPoint |
  | GCBar             |    19     | Recall House                  | GameLib.CodeEnumRecallCommand.House     |
  | GCBar             |    21     | Recall Warplot                | GameLib.CodeEnumRecallCommand.Warplot   |
  -----------------------------------------------------------------------------------------------------------
  | RMSBar            |     0     | Vehicle Bar Button 1          |                                         |
  | RMSBar            |     1     | Vehicle Bar Button 2          |                                         |
  | RMSBar            |     2     | Vehicle Bar Button 3          |                                         |
  | RMSBar            |     3     | Vehicle Bar Button 4          |                                         |
  | RMSBar            |     4     | Vehicle Bar Button 5          |                                         |
  | RMSBar            |     5     | Vehicle Bar Button 6          |                                         |
  -----------------------------------------------------------------------------------------------------------
  | LASBar            |     0     | Limited Action Set Button 1   |                                         |
  | LASBar            |     1     | Limited Action Set Button 2   |                                         |
  | LASBar            |     2     | Limited Action Set Button 3   |                                         |
  | LASBar            |     3     | Limited Action Set Button 4   |                                         |
  | LASBar            |     4     | Limited Action Set Button 5   |                                         |
  | LASBar            |     5     | Limited Action Set Button 6   |                                         |
  | LASBar            |     6     | Limited Action Set Button 7   |                                         |
  | LASBar            |     7     | Limited Action Set Button 8   |                                         |
  | LASBar            |     8     | Gadget Slot                   |                                         |
  | LASBar            |     9     | Path Slot                     |                                         |
  -----------------------------------------------------------------------------------------------------------
  | ABar              |     12    | Action Bar 2 Button 1         |                                         |
  | ABar              |     13    | Action Bar 2 Button 2         |                                         |
  | ABar              |     14    | Action Bar 2 Button 3         |                                         |
  | ABar              |     15    | Action Bar 2 Button 4         |                                         |
  | ABar              |     16    | Action Bar 2 Button 5         |                                         |
  | ABar              |     17    | Action Bar 2 Button 6         |                                         |
  | ABar              |     18    | Action Bar 2 Button 7         |                                         |
  | ABar              |     19    | Action Bar 2 Button 8         |                                         |
  | ABar              |     20    | Action Bar 2 Button 9         |                                         |
  | ABar              |     21    | Action Bar 2 Button 10        |                                         |
  | ABar              |     22    | Action Bar 2 Button 11        |                                         |
  | ABar              |     23    | Action Bar 2 Button 12        |                                         |
  -----------------------------------------------------------------------------------------------------------
  | ABar              |     24    | Action Bar 3 Button 1         |                                         |
  | ABar              |     25    | Action Bar 3 Button 2         |                                         |
  | ABar              |     26    | Action Bar 3 Button 3         |                                         |
  | ABar              |     27    | Action Bar 3 Button 4         |                                         |
  | ABar              |     28    | Action Bar 3 Button 5         |                                         |
  | ABar              |     29    | Action Bar 3 Button 6         |                                         |
  | ABar              |     30    | Action Bar 3 Button 7         |                                         |
  | ABar              |     31    | Action Bar 3 Button 8         |                                         |
  | ABar              |     32    | Action Bar 3 Button 9         |                                         |
  | ABar              |     33    | Action Bar 3 Button 10        |                                         |
  | ABar              |     34    | Action Bar 3 Button 11        |                                         |
  | ABar              |     35    | Action Bar 3 Button 12        |                                         |
  -----------------------------------------------------------------------------------------------------------
  | SBar              |     12    | Pet Command (Attack)          |                                         |
  | SBar              |     13    | Pet Command (Move)            |                                         |
  | SBar              |     15    | Pet Command (Stop)            |                                         |
  -----------------------------------------------------------------------------------------------------------

--]]------------------------------------------------------------------------------------------------------------------
do
local WidgetType, Version = "ActionBarButton", 1

local function Constructor()
  local btn = DaiGUI.ControlBase:new()
  btn:SetOptions{
    Class                          = WidgetType,
    Name                           = "DaiGUI" .. WidgetType,
    Base                           = "ClientSprites:Button_ActionBarBlank",
    RelativeToClient               = true,
    IfHoldNoSignal                 = true,
    DT_VCENTER                     = true,
    DT_CENTER                      = true,
    NeverBringToFront              = true,
    WindowSoundTemplate            = "ActionBarButton",
    ProcessRightClick              = true,
    Font                           = "CRB_InterfaceLarge_O",
    IgnoreTooltipDelay             = true,
    RechargeBarLAnchorPoint        = 1,
    RechargeBarLAnchorOffset       = -8,
    RechargeBarTAnchorPoint        = 0,
    RechargeBarTAnchorOffset       = 4,
    RechargeBarRAnchorPoint        = 1,
    RechargeBarRAnchorOffset       = 4,
    RechargeBarBAnchorPoint        = 1,
    RechargeBarBAnchorOffset       = -14,
    RechargeBarEmptyColorAttribute = "Black",
    RechargeBarFullColorAttribute  = "ffffffff",
    RechargeBarEmptyAttribute      = "WhiteFill",
    RechargeBarFullAttribute       = "sprStalker_VerticalGooPulse",
    TooltipType                    = "DynamicFloater",
    ShortHotkeyFontAttribute       = "CRB_InterfaceLarge_BO",
    LongHotkeyFontAttribute        = "CRB_InterfaceSmall_O",
    CountFontAttribute             = "CRB_InterfaceSmall_O",
    CooldownFontAttribute          = "CRB_HeaderLarge",
  }
  return btn
end

DaiGUI:RegisterWidgetType(WidgetType, Constructor, Version)
end


--[[ File: widgets/TreeControl.lua -----------------------------------------------------------------------------------
  
  Specific attributes (inherits Control attributes)
  ------------------------------------------------------------------------------------
  | Attribute                 | Desc                 | Houston Reference | Data Type |
  ------------------------------------------------------------------------------------
  | NoSelection               |                      | StylesEx          | Boolean   |
  | NoLines                   |                      | StylesEx          | Boolean   |
  | NoButtons                 |                      | StylesEx          | Boolean   |
  | UseNodeColor              |                      | StylesEx          | Boolean   |
  ------------------------------------------------------------------------------------
  | NormalBG                  |                      | Node              | Sprite    |
  | SelectedBG                |                      | Node              | Sprite    |
  | ExpandButton              |                      | Node              | Sprite    |
  | CollapseButton            |                      | Node              | Sprite    |
  | MinimumNodeHeight         |                      | Node              | Number    |
  ------------------------------------------------------------------------------------
  | VLine                     |                      | Line              | Sprite    |
  | NodeLine                  |                      | Line              | Sprite    |
  | LastNodeLine              |                      | Line              | Sprite    |
  ------------------------------------------------------------------------------------
  
  Specific events (inherits Control events)
  - TreeDoubleClick(hNode)
  - TreeNodeCollapse(hNode)
  - TreeNodeExpand(hNode)
  - TreeSelectionChanged(hSelected, hPrevSelected)
  - TreeSelectionChanging(hNode, hSelected, bAllowed)
 
--]]------------------------------------------------------------------------------------------------------------------
do
local WidgetType, Version = "TreeControl", 1

local function Constructor()
  local wnd = DaiGUI.ControlBase:new()
  wnd:SetOptions{
    Class            = WidgetType,
    Name             = "DaiGUI" .. WidgetType,
    Font             = "CRB_Pixel",
    Template         = "CRB_Hologram",
    UseTemplateBG    = true,
    Picture          = true,
    Border           = true,
    
    RelativeToClient = true,
  }
  return wnd
end

DaiGUI:RegisterWidgetType(WidgetType, Constructor, Version)
end



--[[ File: widgets/ComboBox.lua --------------------------------------------------------------------------------------
  
  Specific attributes (inherits Control attributes)
  ----------------------------------------------------------------------------------
  | Attribute               | Desc                 | Houston Reference | Data Type |
  ----------------------------------------------------------------------------------
  | AllowTextEditing        | Broken               | StylesEx          | Boolean   |
  | NoScrollbar             |                      | StylesEx          | Boolean   |
  | AutoSize                |                      | StylesEx          | Boolean   |
  ----------------------------------------------------------------------------------
  | UseTheme                | Skins the combobox   | Added by DaiGUI   | Boolean   |
  | DropdownBtnBase         | Base kit for button  | Added by DaiGUI   | Sprite    |
  | DropdownBtnWidth        | Width of button      | Added by DaiGUI   | Sprite    |
  ----------------------------------------------------------------------------------

  Specific events (inherits Control events)
  - ComboBoxSelectionChanged(iRow)
  - ComboBoxSelectionChanging(iRow, iOldRow)
  
--]]------------------------------------------------------------------------------------------------------------------
do
local WidgetType, Version = "ComboBox", 1

local ComboBox = DaiGUI.ControlBase:new()
function ComboBox:AddSubclassFields(tForm)
  if self.options.UseTheme == true then
    -- if windowload is set, it will respect that
    -- apply the theme then call the windowload set 
    -- by the consumer.  Otherwise it will setup
    -- its own windowload event
    
    -- todo: probably needs a refactor
    local windowLoadEvent
    for k,v in pairs(self.events) do
      if v.strName == "WindowLoad" then
        windowLoadEvent = v
        break
      end
    end
  
    if windowLoadEvent ~= nil then
      local strFont = self.options.Font or "CRB_InterfaceMedium"
      local strBtnBase = self.options.DropdownBtnBase or "Collections_TEMP:sprCollections_TEMP_RightAlignDropdown"
      local nBtnWidth = self.options.DropdownBtnWidth
      
      local fOldWindowLoad = windowLoadEvent.fnInline
      local strOldWindowLoad = windowLoadEvent.strFunction
      if windowLoadEvent.fnInline == nil then
        fOldWindowLoad = windowLoadEvent.strFunction
      end
      
      local fNewWindowLoad = function(self, wndHandler, wndControl)
        if wndHandler == wndControl then 
          
          local cbBtnSkin = DaiGUI:Create({ Class="Button", Base=strBtnBase }):GetInstance()
          if nBtnWidth then
            wndControl:GetButton():SetAnchorOffsets(-nBtnWidth,0,0,0)
          end
          
          wndControl:GetButton():ChangeArt(cbBtnSkin)
          wndControl:GetGrid():SetStyle("AutoHideScroll",     true)
          wndControl:GetGrid():SetStyle("TransitionShowHide", true)
          wndControl:GetGrid():SetFont(strFont)
        end
        
        if type(fOldWindowLoad) == "function" then
          fOldWindowLoad(self, wndHandler, wndControl)
        elseif type(fOldWindowLoad) == "string" and type(self[fOldWindowLoad]) == "function" then
          self[fOldWindowLoad](self, wndHandler, wndControl)
        end
      end
      
      windowLoadEvent.fnInline = fNewWindowLoad
      windowLoadEvent.strFunction = "OnWindowLoad_" .. tostring(windowLoadEvent.fnInline):gsub("function: ", "_")
    end
    
    if tForm.UseTheme ~= nil then
      tForm.UseTheme = nil
    end
  end
end

local function Constructor()
  local cbo = ComboBox:new()
  cbo:SetOptions{
    Class              = WidgetType,
    Name               = "DaiGUI" .. WidgetType,
    Font               = "CRB_InterfaceMedium",
    DT_VCENTER         = true,
    RelativeToClient   = true,
    Overlapped         = true,
    AutoSize           = true,
    Template           = "HologramControl2",
    UseTemplateBG      = true,
    Picture            = true,
    Border             = true,
    UseTheme           = true,
--    DropdownBtnBase    = "CRB_Basekit:kitBtn_ScrollHolo_DownLarge",
--    DropdownBtnWidth   = 20,
  }
  return cbo
end

DaiGUI:RegisterWidgetType(WidgetType, Constructor, Version)
end



--[[ File: widgets/Slider.lua ----------------------------------------------------------------------------------------
  
  Specific attributes (inherits Control attributes)
  ------------------------------------------------------------------------------------
  | Attribute                 | Desc                 | Houston Reference | Data Type |
  ------------------------------------------------------------------------------------
  | DiscreteTicks             |                      | StylesEx          | Boolean   |
  | DrawTicks                 |                      | StylesEx          | Boolean   |
  | InstantMouseReact         |                      | StylesEx          | Boolean   |
  | UseButtons                |                      | StylesEx          | Boolean   |
  ------------------------------------------------------------------------------------
  | LeftCap                   |                      | Sprites           | Sprite    |
  | RightCap                  |                      | Sprites           | Sprite    |
  | Middle                    |                      | Sprites           | Sprite    |
  | Thumb                     |                      | Sprites           | Sprite    |
  | Tick                      |                      | Sprites           | Sprite    |
  | IncButton                 |                      | Sprites           | Sprite    |
  | DecButton                 |                      | Sprites           | Sprite    |
  ------------------------------------------------------------------------------------
  | Min                       |                      | Other Attributes  | Number    |
  | Max                       |                      | Other Attributes  | Number    |
  | TickAmount                |                      | Other Attributes  | Number    |
  | InitialValue              |                      | Other Attributes  | Number    |
  ------------------------------------------------------------------------------------
  
  Specific events (inherits Control events)
  - SliderBarChanged(fNewValue, fOldValue)
  - SliderBarChanging(fNewValue, fOldValue, bAllowed)
  
--]]------------------------------------------------------------------------------------------------------------------
do
local WidgetType, Version = "SliderBar", 1

local function Constructor()
  local ctrl = DaiGUI.ControlBase:new()
  ctrl:SetOptions{
    Class            = WidgetType,
    Name             = "DaiGUI" .. WidgetType,
    Template         = "CRB_Scroll_HoloLarge",
    Middle           = "CRB_Basekit:kitScrollbase_Horiz_Holo",
    UseButtons       = true,
    Min              = 1,
    Max              = 100,
    TickAmount       = 1,
    RelativeToClient = true,
  }
  return ctrl
end

DaiGUI:RegisterWidgetType(WidgetType, Constructor, Version)
end



--[[ File: widgets/ProgressBar.lua -----------------------------------------------------------------------------------
  
  Specific attributes (inherits Control attributes)
  ------------------------------------------------------------------------------------
  | Attribute                 | Desc                 | Houston Reference | Data Type |
  ------------------------------------------------------------------------------------
  | SetTextToProgress         |                      | StylesEx          | Boolean   |
  | UseValues                 |                      | StylesEx          | Boolean   |
  | IgnoreMax                 |                      | StylesEx          | Boolean   |
  | UsePercent                |                      | StylesEx          | Boolean   |
  | DrawTextOnFlyby           |                      | StylesEx          | Boolean   |
  | EdgeGlow                  |                      | StylesEx          | Boolean   |
  | NoClipEdgeGlow            |                      | StylesEx          | Boolean   |
  | DrawTicks                 |                      | StylesEx          | Boolean   |
  | VerticallyAlign           |                      | StylesEx          | Boolean   |
  | BRtoLT                    |                      | StylesEx          | Boolean   |
  | UseTextRect               |                      | StylesEx          | Boolean   |
  | PolygonalClipping         |                      | StylesEx          | Boolean   |
  | RadialBar                 |                      | StylesEx          | Boolean   |
  | Clockwise                 |                      | StylesEx          | Boolean   |
  ------------------------------------------------------------------------------------
  | AutoSetText               |                      | Undocumented      | Boolean   |
  ------------------------------------------------------------------------------------
  | BarColor                  |                      | Bar Color         | Color     |
  ------------------------------------------------------------------------------------
  | ProgressEmpty             |                      | Other Sprites     | Sprite    |
  | ProgressEdgeGlow          |                      | Other Sprites     | Sprite    |
  | ProgressFill              |                      | Other Sprites     | Sprite    |
  | ProgressFull              |                      | Other Sprites     | Sprite    |
  | TickOn                    |                      | Other Sprites     | Sprite    |
  | TickOff                   |                      | Other Sprites     | Sprite    |
  ------------------------------------------------------------------------------------
  | TextX                     |                      | Text Rect         | Number    |
  | TextY                     |                      | Text Rect         | Number    |
  | TextWidth                 |                      | Text Rect         | Number    |
  | TextHeight                |                      | Text Rect         | Number    |
  ------------------------------------------------------------------------------------
  | x0                        |                      | Points            | Number    |
  | y0                        |                      | Points            | Number    |
  | x1                        |                      | Points            | Number    |
  | y1                        |                      | Points            | Number    |
  | x2                        |                      | Points            | Number    |
  | y2                        |                      | Points            | Number    |
  | x3                        |                      | Points            | Number    |
  | y3                        |                      | Points            | Number    |
  ------------------------------------------------------------------------------------
  | RadialMin                 | degrees              | Radial Bar Range  | Number    |
  | RadialMax                 | degrees              | Radial Bar Range  | Number    |
  ------------------------------------------------------------------------------------
  
  No Specific events (inherits Control events)
  
--]]------------------------------------------------------------------------------------------------------------------
do
local WidgetType, Version = "ProgressBar", 1

local function Constructor()
  local ctrl = DaiGUI.ControlBase:new()
  ctrl:SetOptions{
    Class             = WidgetType,
    Name              = "DaiGUI" .. WidgetType,
    ProgressEmpty     = "BlackFill",
    ProgressFull      = "CRB_Raid:sprRaid_ShieldProgBar",
    UseTemplateBG     = true,
    Template          = "CRB_Hologram",
    Border            = true,
    Picture           =  true,
    BarColor          = "white",
    Font              = "CRB_InterfaceMedium_BO",
    UseValues         = true,
    RelativeToClient  = true,
    SetTextToProgress = true,
    DT_CENTER         = true,
    DT_VCENTER        = true,
  }
  return ctrl
end

DaiGUI:RegisterWidgetType(WidgetType, Constructor, Version)
end



--[[ File: widgets/EditBox.lua ---------------------------------------------------------------------------------------
  
  Specific attributes (inherits Control attributes)
  -----------------------------------------------------------------------------------
  | Attribute                | Desc                 | Houston Reference | Data Type |
  -----------------------------------------------------------------------------------
  | MultiLine                |                      | StylesEx          | Boolean   |
  | ReadOnly                 |                      | StylesEx          | Boolean   |
  | DefaultTarget            |                      | StylesEx          | Boolean   |
  | Password                 |                      | StylesEx          | Boolean   |
  | WantTab                  |                      | StylesEx          | Boolean   |
  | WantReturn               |                      | StylesEx          | Boolean   |
  | SizeToFit                |                      | StylesEx          | Boolean   |
  | KeepStringList           |                      | StylesEx          | Boolean   |
  | ClearOnEscape            |                      | StylesEx          | Boolean   |
  | NoSelectOnFocus          |                      | StylesEx          | Boolean   |
  | LoseFocusOnExternalClick |                      | StylesEx          | Boolean   |
  -----------------------------------------------------------------------------------

  Specific events (inherits Control events)
  - EditBoxChanged(strText)
  - EditBoxChanging(strNewText, strOldText, bAllowed)
  - EditBoxEscape()
  - EditBoxReturn(strText)
  - EditBoxTab(strText)
  
--]]------------------------------------------------------------------------------------------------------------------
do
local WidgetType, Version = "EditBox", 1

local function Constructor()
  local ctrl = DaiGUI.ControlBase:new()
  ctrl:SetOptions{
    Class            = WidgetType,
    Name             = "DaiGUI" .. WidgetType,
    TabStop          = true,
    Font             = "CRB_InterfaceMedium",
    RelativeToClient = true,
    DT_VCENTER       = true,
    Template         = "HologramControl2",
    UseTemplateBG    = true,
    Border           = true,
    Picture          = true,
  }
  return ctrl
end

DaiGUI:RegisterWidgetType(WidgetType, Constructor, Version)
end



--[[ File: widgets/Grid.lua ------------------------------------------------------------------------------------------
  
  Specific attributes (inherits Control attributes)
  -----------------------------------------------------------------------------------
  | Attribute                | Desc                 | Houston Reference | Data Type |
  -----------------------------------------------------------------------------------
  | MultiColumn              |                      | StylesEx          | Boolean   |
  | HeaderRow                |                      | StylesEx          | Boolean   |
  | VariableHeight           |                      | StylesEx          | Boolean   |
  | SelectWholeRow           |                      | StylesEx          | Boolean   |
  | MultiSelect              |                      | StylesEx          | Boolean   |
  | FocusOnMouseOver         |                      | StylesEx          | Boolean   |
  | AutoSizeX                |                      | StylesEx          | Boolean   |
  | AutoSizeY                |                      | StylesEx          | Boolean   |
  | FocusOnClick             |                      | StylesEx          | Boolean   |
  -----------------------------------------------------------------------------------
  | CellBGBase               |                      | Grid              | Sprite    |
  | HeaderBG                 |                      | Grid              | Sprite    |
  | HeaderFont               |                      | Grid              | String    |
  | HeaderHeight             |                      | Grid              | Number    |
  | RowHeight                |                      | Grid              | Number    |
  | HorzRowMargin            |                      | Grid              | Number    |
  | HorzCellMargin           |                      | Grid              | Number    |
  | VertRowMargin            |                      | Grid              | Number    |
  | ImageTextSpacing         |                      | Grid              | Number    |
  -----------------------------------------------------------------------------------
  | TextNormalColor          |                      | Grid - Text Color | Color     |
  | TextSelectedColor        |                      | Grid - Text Color | Color     |
  | TextNormalFocusColor     |                      | Grid - Text Color | Color     |
  | TextSelectedFocusColor   |                      | Grid - Text Color | Color     |
  | TextDisabledColor        |                      | Grid - Text Color | Color     |
  -----------------------------------------------------------------------------------
  | CellBGNormalColor        |                      | Grid - Cell Color | Color     |
  | CellBGSelectedColor      |                      | Grid - Cell Color | Color     |
  | CellBGNormalFocusColor   |                      | Grid - Cell Color | Color     |
  | CellBGSelectedFocusColor |                      | Grid - Cell Color | Color     |
  | CellBGDisabledColor      |                      | Grid - Cell Color | Color     |
  -----------------------------------------------------------------------------------

  Column Attributes
  ----------------------------------------------------------------
  | Attribute                | Description            | DataType |
  ----------------------------------------------------------------
  | Name                     | Text to be displayed   | String   |
  | Width                    | Column width           | Number   |
  | TextColor                | Text color             | Color    |
  | Image                    | Image                  | Sprite   |
  | MinWidth                 | Minimum Column Width   | Number   |
  | MaxWidth                 | Maximum Column Width   | Number   |
  | MergeLeft                | Merge Left             | Boolean  |
  | SimpleSort               | Simple Sort            | Boolean  |
  | DT_CENTER                | Center Text Flag       | Boolean  |
  | DT_VCENTER               | Vert. Center Text Flag | Boolean  |
  | DT_RIGHT                 | Right Align Text Flag  | Boolean  |
  | DT_BOTTOM                | Bottom Align Text Flag | Boolean  |
  | DT_WORDBREAK             | Word Break Text Flag   | Boolean  |
  | DT_SINGLELINE            | Single Line Text Flag  | Boolean  |
  ----------------------------------------------------------------

  Specific events (inherits Control events)
  - GridSelChange(iRow, iCol)
  - GridDoubleClick(iRow, iCol)
  - GridSelChanging(iRow, iCol, iCurrRow, iCurrCol, bAllowChange)
  - GridSort(iCol)
  
--]]------------------------------------------------------------------------------------------------------------------
do
local WidgetType, Version = "Grid", 1

local Grid = DaiGUI.ControlBase:new()

function Grid:AddColumn(tColumn)
  self.columns = self.columns or {}
  
  tColumn.TextColor = tColumn.TextColor or "White"
  if tColumn.SimpleSort == nil then
    tColumn.SimpleSort = true
  end
  
  table.insert(self.columns, tColumn)
end

function Grid:AddSubclassFields(tForm)
  if self.options.Columns ~= nil then
    for i = 1, #self.options.Columns do
      self:AddColumn(self.options.Columns[i])
    end
    if tForm.Columns ~= nil then
      tForm.Columns = nil
    end
  end
  
  if self.columns ~= nil then
    for i = #self.columns, 1, -1 do
      local tColumn = self.columns[i]
      local tNode = { __XmlNode = "Column",  }
      for k,v in pairs(tColumn) do
        tNode[k] = v
      end
      table.insert(tForm, tNode)
    end
  end
end

local function Constructor()
  local ctrl = Grid:new()
  ctrl:SetOptions{
    Class                  = WidgetType,
    Name                   = "DaiGUI" .. WidgetType,
    IgnoreMouse            = true,
    Template               = "CRB_Hologram",
    UseTemplateBG          = true,
    Picture                = true,
    Border                 = true,
    HeaderFont             = "CRB_Pixel",
    HeaderBG               = "CRB_Basekit:kitBtn_List_HoloDisabled",
    HeaderHeight           = 26,
    
    Font                   = "CRB_Pixel",
    CellBGBase             = "CRB_Basekit:kitBtn_List_HoloNormal",
    RowHeight              = 26,
    
    MultiColumn            = true,
    FocusOnMouseOver       = true,
    SelectWholeRow         = true,
    RelativeToClient       = true,
    VariableHeight         = true,
    HeaderRow              = true,
    
    TextNormalColor        = "white",
    TextSelectedColor      = "ff31fcf6",
    TextNormalFocusColor   = "white",
    TextSelectedFocusColor = "ff31fcf6",
    TextDisabledColor      = "9d666666",
    
    DT_VCENTER             = true,
    VScroll                = true,
    AutoHideScroll         = true,
  }
  return ctrl
end

DaiGUI:RegisterWidgetType(WidgetType, Constructor, Version)
end



--[[ File: widgets/MLWindow.lua --------------------------------------------------------------------------------------
  
  No Specific attributes (inherits Control attributes)
  
  Specific events (inherits Control events)
  - MLNodeClick(strNode, tAttributes, eButton)

--]]------------------------------------------------------------------------------------------------------------------
do
local WidgetType, Version = "MLWindow", 1
 
local function Constructor()
  local ctrl = DaiGUI:Create("Window", {
    Class         = "MLWindow",
    Name          = "DaiGUI" .. WidgetType,
    Font          = "CRB_InterfaceSmall",
  })
  return ctrl
end

DaiGUI:RegisterWidgetType(WidgetType, Constructor, Version)
end



--[[ File: widgets/TabWindow.lua -------------------------------------------------------------------------------------
  
  Specific attributes (inherits Control attributes)
  ------------------------------------------------------------------------------------
  | Attribute                 | Desc                 | Houston Reference | Data Type |
  ------------------------------------------------------------------------------------
  | TabTextMarginLeft         |                      | Tab               | Number    |
  | TabTextMarginTop          |                      | Tab               | Number    |
  | TabTextMarginRight        |                      | Tab               | Number    |
  | TabTextMarginBottom       |                      | Tab               | Number    |
  ------------------------------------------------------------------------------------
  
  No Specific events (inherits Control events)
  
--]]------------------------------------------------------------------------------------------------------------------
do
local WidgetType, Version = "TabWindow", 1

local function Constructor()
  local ctrl = DaiGUI.ControlBase:new()
  ctrl:SetOptions{
    Class              = WidgetType,
    Name               = "DaiGUI" .. WidgetType,
    Template           = "CRB_ChatWindow",
    Font               = "CRB_InterfaceMedium",
    Moveable           = true,
    Border             = true,
    AutoFadeNC         = true,
    AudoFadeBG         = true,
    Picture            = true,
    Sizable            = true,
    Overlapped         = true,
    DT_CENTER          = true,
    DT_VCENTER         = true,
    UseTemplateBG      = true,
    RelativeToClient   = true,
    TabTextMarginLeft  = 10,
    TabTextMarginRight = 10,
  }
  return ctrl
end

DaiGUI:RegisterWidgetType(WidgetType, Constructor, Version)
end



--[[ File: widgets/AbilityItemWindow.lua -----------------------------------------------------------------------------

  Specific attributes (inherits Control attributes)
  ------------------------------------------------------------------------------------
  | Attribute                 | Desc                 | Houston Reference | Data Type |
  ------------------------------------------------------------------------------------
  | ListItem                  |                      | StylesEx          | Boolean   |
  ------------------------------------------------------------------------------------
  | Overlay                   |                      | Ability Item Wnd  | Sprite    |
  ------------------------------------------------------------------------------------

  Specific events (inherits Window events)
  - AbilitySelected()
  
--]]------------------------------------------------------------------------------------------------------------------
do
local WidgetType, Version = "AbilityItemWindow", 1

local function Constructor()
  local ctrl = DaiGUI.ControlBase:new()
  ctrl:SetOptions{
    Class              = WidgetType,
    Name               = "DaiGUI" .. WidgetType,
    IgnoreTooltipDelay = true,
    RelativeToClient   = true,
    DT_CENTER          = true,
    DT_VCENTER         = true,
    ListItem           = true,
    IgnoreMouse        = true,
  }
  return ctrl
end

DaiGUI:RegisterWidgetType(WidgetType, Constructor, Version)
end



--[[ File: widgets/ActionConfirmButton.lua ---------------------------------------------------------------------------
  
  No Specific attributes (inherits Window attributes)

  Specific events (inherits Window events)
  - DeleteItemRequested()
  - EmailSent()
  - SalvageItemRequested()
  
--]]------------------------------------------------------------------------------------------------------------------
do
local WidgetType, Version = "ActionConfirmButton", 1

local function Constructor()
  local ctrl = DaiGUI.ControlBase:new()
  ctrl:SetOptions{
    Class            = WidgetType,
    Name             = "DaiGUI" .. WidgetType,
    Font             = "Default",
    RelativeToClient = true,
  }
  return ctrl
end

DaiGUI:RegisterWidgetType(WidgetType, Constructor, Version)
end



--[[ File: widgets/BagWindow.lua -------------------------------------------------------------------------------------
  
  Specific attributes (inherits Window attributes)
  ----------------------------------------------------------------------------
  | Attribute             | Desc             | Houston Reference | Data Type |
  ----------------------------------------------------------------------------
  | BoxesPerRow           | Boxes Per Row    | Bag Window        | Number    |
  | SquareSize            | Box Size         | Bag Window        | Number    |
  | NewQuestOverlaySprite | New Quest Sprite | Bag Window        | Sprite    |
  ----------------------------------------------------------------------------

  Specific events (inherits Window events)
  - AbilitySelected()
  
--]]------------------------------------------------------------------------------------------------------------------
do
local WidgetType, Version = "BagWindow", 1

local function Constructor()
  local ctrl = DaiGUI.ControlBase:new()
  ctrl:SetOptions{
    Class                 = WidgetType,
    Name                  = "DaiGUI" .. WidgetType,
    SwallowMouseClicks    = true,
    IgnoreTooltipDelay    = true,
    Sprite                = "CRB_UIKitSprites:spr_baseframe",
    Template              = "CRB_Normal",
    NoClip                = true,
    UseTemplateBG         = true,
    NewQuestOverlaySprite = "ClientSprites:sprItem_NewQuest",
    SquareSize            = 50,
    BoxesPerRow           = 5,

  }
  return ctrl
end

DaiGUI:RegisterWidgetType(WidgetType, Constructor, Version)
end



--[[ File: widgets/BuffWindow.lua ------------------------------------------------------------------------------------
  
  Specific attributes (inherits Window attributes)
  ----------------------------------------------------------------------------------
  | Attribute               | Desc                 | Houston Reference | Data Type |
  ----------------------------------------------------------------------------------
  | BeneficialBuffs         |                      | StylesEx          | Boolean   |
  | HarmfulBuffs            |                      | StylesEx          | Boolean   |
  | Hero                    |                      | StylesEx          | Boolean   |
  | PulseWhenExpiring       |                      | StylesEx          | Boolean   |
  | BuffDispellable         |                      | StylesEx          | Boolean   |
  | BuffNonDispellable      |                      | StylesEx          | Boolean   |
  | DebuffDispellable       |                      | StylesEx          | Boolean   |
  | DebuffNonDispellable    |                      | StylesEx          | Boolean   |
  | BuffNonDispelRightClick |                      | StylesEx          | Boolean   |
  | DoNotShowTimeRemaining  |                      | StylesEx          | Boolean   |
  | ShowMS                  |                      | StylesEx          | Boolean   |
  ----------------------------------------------------------------------------------
  | BuffIndex               | Buff Index (1-based) | Buff Window       | Number    |
  ----------------------------------------------------------------------------------

  Specific events (inherits Window events)
  - BuffRemoved()
  
--]]------------------------------------------------------------------------------------------------------------------
do
local WidgetType, Version = "BuffWindow", 1

local function Constructor()
  local ctrl = DaiGUI.ControlBase:new()
  ctrl:SetOptions{
    Class              = WidgetType,
    Name               = "DaiGUI" .. WidgetType,
    NoClip             = true,
    HarmfulBuffs       = true,
    BuffIndex          = 1,
    IgnoreTooltipDelay = true,

  }
  return ctrl
end

DaiGUI:RegisterWidgetType(WidgetType, Constructor, Version)
end



--[[ File: widgets/BuffContainerWindow.lua ---------------------------------------------------------------------------
  
  Specific attributes (inherits Window attributes)
  ----------------------------------------------------------------------------------
  | Attribute               | Desc                 | Houston Reference | Data Type |
  ----------------------------------------------------------------------------------
  | BeneficialBuffs         |                      | StylesEx          | Boolean   |
  | HarmfulBuffs            |                      | StylesEx          | Boolean   |
  | Hero                    |                      | StylesEx          | Boolean   |
  | PulseWhenExpiring       |                      | StylesEx          | Boolean   |
  | BuffDispellable         |                      | StylesEx          | Boolean   |
  | BuffNonDispellable      |                      | StylesEx          | Boolean   |
  | DebuffDispellable       |                      | StylesEx          | Boolean   |
  | DebuffNonDispellable    |                      | StylesEx          | Boolean   |
  | BuffNonDispelRightClick |                      | StylesEx          | Boolean   |
  | DoNotShowTimeRemaining  |                      | StylesEx          | Boolean   |
  | ShowMS                  |                      | StylesEx          | Boolean   |
  | AutoAddBuffs            |                      | StylesEx          | Boolean   |
  | AlignBuffsRight         |                      | StylesEx          | Boolean   |
  ----------------------------------------------------------------------------------

  No Specific events (inherits Window events)
  
--]]------------------------------------------------------------------------------------------------------------------
do
local WidgetType, Version = "BuffContainerWindow", 1

local function Constructor()
  local ctrl = DaiGUI.ControlBase:new()
  ctrl:SetOptions{
    Class              = WidgetType,
    Name               = "DaiGUI" .. WidgetType,
    RelativeToClient   = true,
    Font               = "Default",
  }
  return ctrl
end

DaiGUI:RegisterWidgetType(WidgetType, Constructor, Version)
end



--[[ File: widgets/CashWindow.lua ------------------------------------------------------------------------------------
  
  Specific attributes (inherits Control attributes)
  ----------------------------------------------------------------------------------
  | Attribute               | Desc                 | Houston Reference | Data Type |
  ----------------------------------------------------------------------------------
  | AllowEditing            |                      | StylesEx          | Boolean   |
  | SkipZeroes              |                      | StylesEx          | Boolean   |
  ----------------------------------------------------------------------------------

  Specific events (inherits Control events)
  - CashWindowAmountChanged()
  
--]]------------------------------------------------------------------------------------------------------------------
do
local WidgetType, Version = "CashWindow", 1

local function Constructor()
  local ctrl = DaiGUI.ControlBase:new()
  ctrl:SetOptions{
    Class            = WidgetType,
    Name             = "DaiGUI" .. WidgetType,
    Font             = "CRB_InterfaceSmall",
    DT_RIGHT         = true,
    RelativeToClient = true,

  }
  return ctrl
end

DaiGUI:RegisterWidgetType(WidgetType, Constructor, Version)
end



--[[ File: widgets/CharacterFrame.lua --------------------------------------------------------------------------------
  
  No Specific attributes (inherits Control attributes)
  No Specific events (inherits Control events)
  
--]]------------------------------------------------------------------------------------------------------------------
do
local WidgetType, Version = "CharacterFrame", 1

local function Constructor()
  local ctrl = DaiGUI.ControlBase:new()
  ctrl:SetOptions{
    Class              = WidgetType,
    Name               = "DaiGUI" .. WidgetType,
    RelativeToClient   = true,
    Overlapped         = true,
    TestAlpha          = true,
    TransitionShowHide = true,
    SwallowMouseClicks = true,
    Font               = "Default",

  }
  return ctrl
end

DaiGUI:RegisterWidgetType(WidgetType, Constructor, Version)
end



--[[ File: widgets/CostumeWindow.lua ---------------------------------------------------------------------------------
  
  Specific attributes (inherits Control attributes)
  -----------------------------------------------------------------------------------
  | Attribute                | Desc                 | Houston Reference | Data Type |
  -----------------------------------------------------------------------------------
  | Animated                 |                      | Costume Window    | Boolean   |
  | Camera                   | See eCamera          | Costume Window    | String    |
  | Mask                     | Mask Filename        | Costume Window    | String    |
  | Overlay                  | Overlay Filename     | Costume Window    | String    |
  | Quality                  |                      | Costume Window    | Number    |
  | Speed                    |                      | Costume Window    | Number    |
  | Frame                    |                      | Costume Window    | Number    |
  -----------------------------------------------------------------------------------
  eCamera = { "Cinematic", "Cinematic_01", "Cinematic_02", ..., "Cinematic_20", "Datachron", "FaceEditor", "Paperdoll", "Portrait", "Quest", "Target" }
  
  No Specific events (inherits Control events)

--]]------------------------------------------------------------------------------------------------------------------
do
local WidgetType, Version = "CostumeWindow", 1

local function Constructor()
  local ctrl = DaiGUI.ControlBase:new()
  ctrl:SetOptions{
    Class              = WidgetType,
    Name               = "DaiGUI" .. WidgetType,
    RelativeToClient   = true,
    Font               = "Default",
    Camera             = "Paperdoll",
    Animated           = true,

  }
  return ctrl
end

DaiGUI:RegisterWidgetType(WidgetType, Constructor, Version)
end



--[[ File: widgets/IconButton.lua ------------------------------------------------------------------------------------
  
  Specific attributes (inherits Control attributes)
  ------------------------------------------------------------------------------------
  | Attribute                 | Desc                 | Houston Reference | Data Type |
  ------------------------------------------------------------------------------------
  | Base                      |                      | Undocumented      | Sprite    |
  | UseBaseButtonArt          |                      | Undocumented      | Boolean   |
  | LeftMargin                |                      | IconButton        | Number    |
  | TopMargin                 |                      | IconButton        | Number    |
  | RightMargin               |                      | IconButton        | Number    |
  | BottomMargin              |                      | IconButton        | Number    |
  | ContentType               |                      | IconButton        | String    |
  | ContentId                 |                      | IconButton        | Number    |
  | UnderTemplate             |                      | IconButton        | ??????    |
  | OverTemplate              |                      | IconButton        | ??????    |
  ------------------------------------------------------------------------------------
  | CheckboxRight             |                      | StyleEx           | Boolean   |
  | DrawAsCheckbox            |                      | StyleEx           | Boolean   |
  | DrawHotkey                |                      | StyleEx           | Boolean   |
  | DrawClientSprite          |                      | StyleEx           | Boolean   |
  | IfHoldNoSignal            |                      | StyleEx           | Boolean   |
  | RadioDisallowNonSelection |                      | StyleEx           | Boolean   |
  | RadioAlwaysSignal         |                      | StyleEx           | Boolean   |
  | ProcessRightClick         |                      | StyleEx           | Boolean   |
  | UseWindowTextColor        |                      | StyleEx           | Boolean   |
  ------------------------------------------------------------------------------------
  
  No Specific events (inherits Control events)

--]]------------------------------------------------------------------------------------------------------------------
do
local WidgetType, Version = "IconButton", 1

local function Constructor()
  local ctrl = DaiGUI.ControlBase:new()
  ctrl:SetOptions{
    Class              = WidgetType,
    Name               = "DaiGUI" .. WidgetType,
    RelativeToClient   = true,
    NoClip             = true,
  }
  return ctrl
end

DaiGUI:RegisterWidgetType(WidgetType, Constructor, Version)
end



--[[ File: widgets/ItemSlotWindow.lua --------------------------------------------------------------------------------
  
  Specific attributes (inherits Control attributes)
  ------------------------------------------------------------------------------------
  | Attribute                 | Desc                 | Houston Reference | Data Type |
  ------------------------------------------------------------------------------------
  | WhenEmpty                 | Sprite When Empty    | Item Slot Window  | Sprite    |
  | ItemFrame                 | Item Frame Sprite    | Item Slot Window  | Sprite    |
  | LockedItem                | Locked Icon Sprite   | Item Slot Window  | Sprite    |
  | EquipementSlot            | Item Slot            | Item Slot Window  | Number    |
  ------------------------------------------------------------------------------------
  
  Specific events (inherits Control events)
  - MenuSelection(iOption)
  
--]]------------------------------------------------------------------------------------------------------------------
do
local WidgetType, Version = "ItemSlotWindow", 1

local function Constructor()
  local ctrl = DaiGUI.ControlBase:new()
  ctrl:SetOptions{
    Class              = WidgetType,
    Name               = "DaiGUI" .. WidgetType,
    RelativeToClient   = true,
    WhenEmpty          = "btn_Armor_HeadNormal",
    EquipmentSlot      = 2,
    IgnoreTooltipDelay = true,

  }
  return ctrl
end

DaiGUI:RegisterWidgetType(WidgetType, Constructor, Version)
end



--[[ File: widgets/LootWindow.lua ------------------------------------------------------------------------------------
  
  Specific attributes (inherits Control attributes)
  ------------------------------------------------------------------------------------
  | Attribute                 | Desc                 | Houston Reference | Data Type |
  ------------------------------------------------------------------------------------
  | BoxesPerRow               | Boxes Per Row        | Bag Window        | Number    |
  | SquareSize                | Box Size             | Bag Window        | Number    |
  | NewQuestOverlaySprite     | New Quest Sprite     | Bag Window        | Sprite    |
  ------------------------------------------------------------------------------------
  
  No Specific events (inherits Control events)

--]]------------------------------------------------------------------------------------------------------------------
do
local WidgetType, Version = "LootWindow", 1

local function Constructor()
  local ctrl = DaiGUI.ControlBase:new()
  ctrl:SetOptions{
    Class                 = WidgetType,
    Name                  = "DaiGUI" .. WidgetType,
    Font                  = "CRB_InterfaceMedium",
    SwallowMouseClicks    = true,
    IgnoreTooltipDelay    = true,
    Sprite                = "CRB_UIKitSprites:spr_baseframe",
    Template              = "CRB_Normal",
    NoClip                = true,
    UseTemplateBG         = true,
    NewQuestOverlaySprite = "ClientSprites:sprItem_NewQuest",
    SquareSize            = 50,
    BoxesPerRow           = 3,
    NewControlDepth       = 1,

  }
  return ctrl
end

DaiGUI:RegisterWidgetType(WidgetType, Constructor, Version)
end



--[[ File: widgets/MannequinSlotWindow.lua ---------------------------------------------------------------------------
  
  Specific attributes (inherits Control attributes)
  ------------------------------------------------------------------------------------
  | Attribute                 | Desc                 | Houston Reference | Data Type |
  ------------------------------------------------------------------------------------
  | WhenEmpty                 | Sprite When Empty    | Item Slot Window  | Sprite    |
  | ItemFrame                 | Item Frame Sprite    | Item Slot Window  | Sprite    |
  | LockedItem                | Locked Icon Sprite   | Item Slot Window  | Sprite    |
  | EquipementSlot            | Item Slot            | Item Slot Window  | Number    |
  ------------------------------------------------------------------------------------
  
  No Specific events (inherits Control events)

--]]------------------------------------------------------------------------------------------------------------------
do
local WidgetType, Version = "MannequinSlotWindow", 1

local function Constructor()
  local ctrl = DaiGUI.ControlBase:new()
  ctrl:SetOptions{
    Class              = WidgetType,
    Name               = "DaiGUI" .. WidgetType,
    RelativeToClient   = true,
    WhenEmpty          = "btn_Armor_HeadNormal",
    EquipmentSlot      = 2,
    IgnoreTooltipDelay = true,

  }
  return ctrl
end

DaiGUI:RegisterWidgetType(WidgetType, Constructor, Version)
end



--[[ File: widgets/MiniMapWindow.lua ---------------------------------------------------------------------------------
  
  Specific attributes (inherits Control attributes)
  ------------------------------------------------------------------------------------
  | Attribute                 | Desc                 | Houston Reference | Data Type |
  ------------------------------------------------------------------------------------
  | Mask                      | Mask Filename        | Mini Map          | String    |
  | ItemRadius                |                      | Mini Map          | Number    |
  | MapOrientation            | See eMapOrientation  | Mini Map          | Number    |
  ------------------------------------------------------------------------------------
  | CircularItems             |                      | Undocumented      | Boolean   |
  ------------------------------------------------------------------------------------
  
  eMapOrientation = { 0 = North, 1 = Player, 2 = Camera }
  
  No Specific events (inherits Control events)

--]]------------------------------------------------------------------------------------------------------------------
do
local WidgetType, Version = "MiniMapWindow", 1

local function Constructor()
  local ctrl = DaiGUI.ControlBase:new()
  ctrl:SetOptions{
    Class              = WidgetType,
    Name               = "DaiGUI" .. WidgetType,
    RelativeToClient   = true,
    Font               = "Default",
    Template           = "Default",
    NewControlDepth    = 2,
    Mask               = [[ui\textures\UI_CRB_HUD_MiniMap_Mask.tex]],
    CircularItems      = true,
    ItemRadius         = 0.7,
    IgnoreMouse        = true,
    MapOrientation     = 0,
  }
  return ctrl
end

DaiGUI:RegisterWidgetType(WidgetType, Constructor, Version)
end



--[[ File: widgets/ProtostarMapWindow.lua ----------------------------------------------------------------------------
  
  No Specific attributes (inherits Control attributes)
  No Specific events (inherits Control events)

--]]------------------------------------------------------------------------------------------------------------------
do
local WidgetType, Version = "ProtostarMapWindow", 1

local function Constructor()
  local ctrl = DaiGUI.ControlBase:new()
  ctrl:SetOptions{
    Class              = WidgetType,
    Name               = "DaiGUI" .. WidgetType,
    Template           = "CRB_Normal",
    NewControlDepth    = 1,
    SwallowMouseClicks = true,
    IgnoreTooltipDelay = true,
    NoClip             = true,
  }
  return ctrl
end

DaiGUI:RegisterWidgetType(WidgetType, Constructor, Version)
end



--[[ File: widgets/SendEmailButton.lua -------------------------------------------------------------------------------
  
  No Specific attributes (inherits Control attributes)
  
  Specific events (inherits Control events)
  - EmailSent()

--]]------------------------------------------------------------------------------------------------------------------
do
local WidgetType, Version = "SendEmailButton", 1

local function Constructor()
  local ctrl = DaiGUI.ControlBase:new()
  ctrl:SetOptions{
    Class              = WidgetType,
    Name               = "DaiGUI" .. WidgetType,
    RelativeToClient   = true,
  }
  return ctrl
end

DaiGUI:RegisterWidgetType(WidgetType, Constructor, Version)
end



--[[ File: widgets/TradeCommitButton.lua -----------------------------------------------------------------------------
  
  No Specific attributes (inherits Control attributes)
  No Specific events (inherits Control events)

--]]------------------------------------------------------------------------------------------------------------------
do
local WidgetType, Version = "TradeCommitButton", 1

local function Constructor()
  local ctrl = DaiGUI.ControlBase:new()
  ctrl:SetOptions{
    Class              = WidgetType,
    Name               = "DaiGUI" .. WidgetType,
    RelativeToClient   = true,
  }
  return ctrl
end

DaiGUI:RegisterWidgetType(WidgetType, Constructor, Version)
end



--[[ File: widgets/WorldFixedWindow.lua ------------------------------------------------------------------------------
  
  Specific attributes (inherits Control attributes)
  ------------------------------------------------------------------------------------
  | Attribute                 | Desc                 | Houston Reference | Data Type |
  ------------------------------------------------------------------------------------
  | AutoDestroyWithUnit       |                      | StylesEx          | Boolean   |
  ------------------------------------------------------------------------------------
  
  Specific events (inherits Control events)
  - UnitOcclusionChanged(bOccluded)
  - WorldLocationOnScreen(bOnScreen)

--]]------------------------------------------------------------------------------------------------------------------
do
local WidgetType, Version = "WorldFixedWindow", 1

local function Constructor()
  local ctrl = DaiGUI.ControlBase:new()
  ctrl:SetOptions{
    Class              = WidgetType,
    Name               = "DaiGUI" .. WidgetType,
    RelativeToClient   = true,
    Font               = "Default",
    Template           = "Default",
    SwallowMouseClicks = true,
    Overlapped         = true,
    IgnoreMouse        = true,
  }
  return ctrl
end

DaiGUI:RegisterWidgetType(WidgetType, Constructor, Version)
end



--[[ File: widgets/ZoneMapWindow.lua ---------------------------------------------------------------------------------
  
  Specific attributes (inherits Control attributes)
  ------------------------------------------------------------------------------------
  | Attribute                 | Desc                 | Houston Reference | Data Type |
  ------------------------------------------------------------------------------------
  | DisableWheelZoom          |                      | StylesEx          | Boolean   |
  | DisableMousePan           |                      | StylesEx          | Boolean   |
  ------------------------------------------------------------------------------------
  | DrawObjectsOnContinent    |                      | Undocumented      | Boolean   |
  ------------------------------------------------------------------------------------
  
  Specific events (inherits Control events)
  - ZoneMapWindowChange()
  - ZoneMapWindowModeChange()

--]]------------------------------------------------------------------------------------------------------------------
do
local WidgetType, Version = "ZoneMapWindow", 1

local function Constructor()
  local ctrl = DaiGUI.ControlBase:new()
  ctrl:SetOptions{
    Class                  = WidgetType,
    Name                   = "DaiGUI" .. WidgetType,
    RelativeToClient       = true,
    Template               = "CRB_HologramFramedThick",
    UseTemplateBG          = true,
    IgnoreTooltipDelay     = true,
    DrawObjectsOnContinent = true,
  }
  return ctrl
end

DaiGUI:RegisterWidgetType(WidgetType, Constructor, Version)
end