---@class UnitDisplayElements
---@field root BitmapElement
---@field image BitmapElement
---@field title TextElement
---@field text TextElement

---@class HUDProcessorUnitDisplayElement
---@field elements UnitDisplayElements
HUDProcessorUnitDisplayElement = {}

HUDProcessorUnitDisplayElement.XML_FILENAME = g_currentModDirectory .. 'xml/hud/MaterialProcessorHUD.xml'

local HUDProcessorUnitDisplayElement_mt = Class(HUDProcessorUnitDisplayElement)

---@return HUDProcessorUnitDisplayElement
---@nodiscard
function HUDProcessorUnitDisplayElement.new()
    ---@type HUDProcessorUnitDisplayElement
    local self = setmetatable({}, HUDProcessorUnitDisplayElement_mt)

    ---@diagnostic disable-next-line: missing-fields
    self.elements = {}

    return self
end

function HUDProcessorUnitDisplayElement:delete()
    self.elements.root:delete()
    ---@diagnostic disable-next-line: missing-fields
    self.elements = {}
end

function HUDProcessorUnitDisplayElement:load()
    local xmlFile = XMLFile.load('materialProcessorHUD', HUDProcessorUnitDisplayElement.XML_FILENAME)

    if xmlFile == nil then
        Logging.error('HUDProcessorUnitDisplayElement:load() Failed to load HUD file: %s', HUDProcessorUnitDisplayElement.XML_FILENAME)
        return
    end

    g_gui:loadProfileSet(xmlFile.handle, 'HUD.GuiProfiles', g_gui.presets)

    self:loadHUDElements(xmlFile, 'HUD')

    xmlFile:delete()
end

---@param xmlFile XMLFile
---@param xmlKey string
---@param parent GuiElement?
function HUDProcessorUnitDisplayElement:loadHUDElements(xmlFile, xmlKey, parent)
    for index = 0, getXMLNumOfChildren(xmlFile.handle, xmlKey) - 1 do
        local key = string.format("%s.*(%i)", xmlKey, index)
        local typeName = getXMLElementName(xmlFile.handle, key)

        if typeName == 'GuiProfiles' then
            continue
        end

        local class = Gui.CONFIGURATION_CLASS_MAPPING[typeName:upper()]

        if class == nil then
            Logging.xmlError(xmlFile, "Invalid HUD element \"%s\" (%s)", tostring(class), key)
            return
        end

        local element = class.new()

        element.typeName = typeName
        element.handleFocus = false
        element.soundDisabled = true

        if parent ~= nil then
            parent:addElement(element)
        end

        element:loadFromXML(xmlFile.handle, key)

        self:loadHUDElements(xmlFile, key, element)

        if element.id ~= nil then
            self.elements[element.id] = element
        end
    end
end

---@param unit ConfigurationUnit
---@param title string
function HUDProcessorUnitDisplayElement:drawUnit(unit, title)
    local valid, x, y, offsetY = unit:getDisplayPosition()

    if valid then
        x = x - self.elements.root.absSize[1] / 2

        self.elements.title:setText(title)
        self.elements.text:setText(unit.fillType.title)
        self.elements.image:setImageFilename(unit.fillType.hudOverlayFilename)

        self.elements.root:setPosition(x, y + offsetY)
        self.elements.root:draw()
    end
end

---@param disabled boolean
function HUDProcessorUnitDisplayElement:setDisabled(disabled)
    self.elements.root:setDisabled(disabled)
end
