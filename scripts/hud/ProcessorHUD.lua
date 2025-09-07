---@class HUDElements
---@field root BitmapElement
---@field image BitmapElement
---@field title TextElement
---@field text TextElement

---@class ProcessorHUD
---@field processor Processor | nil
---@field elements HUDElements
ProcessorHUD = {}

ProcessorHUD.XML_FILENAME = g_currentModDirectory .. 'xml/hud/ProcessorUnitHUD.xml'

local ProcessorHUD_mt = Class(ProcessorHUD)

function ProcessorHUD.new()
    ---@type ProcessorHUD
    local self = setmetatable({}, ProcessorHUD_mt)

    ---@diagnostic disable-next-line: missing-fields
    self.elements = {}

    BaseMission.onStartMission = Utils.appendedFunction(BaseMission.onStartMission, function ()
        if g_client ~= nil then
            self:activate()
        end
    end)

    return self
end

function ProcessorHUD:load()
    ---@type XMLFile | nil
    local xmlFile = XMLFile.load('processorUnitHUD', ProcessorHUD.XML_FILENAME)

    if xmlFile == nil then
        Logging.error('ProcessorHUD:load() Failed to load HUD file: %s', ProcessorHUD.XML_FILENAME)
        return
    end

    g_gui:loadProfileSet(xmlFile.handle, 'HUD.GuiProfiles', g_gui.presets)
    self:loadHUDElements(xmlFile, 'HUD', nil, self, true)

    xmlFile:delete()

    if self.elements.root == nil then
        Logging.xmlError(xmlFile, 'Failed to find root element in HUD file: %s', ProcessorHUD.XML_FILENAME)
        return
    end

    self.elements.root:onGuiSetupFinished()
end

function ProcessorHUD:activate()
    g_currentMission:addUpdateable(self)
    g_currentMission:addDrawable(self)
end

function ProcessorHUD:deactivate()
    g_currentMission:removeUpdateable(self)
    g_currentMission:removeDrawable(self)

    self.processor = nil
end

function ProcessorHUD:delete()
    self:deactivate()

    if self.elements.root ~= nil then
        self.elements.root:delete()
    end

    ---@diagnostic disable-next-line: missing-fields
    self.elements = {}
end

function ProcessorHUD:reload()
    Logging.info('Reloading HUD ..')

    self:delete()
    self:load()

    self:activate()
end

---@param xmlFile XMLFile
---@param xmlKey string
---@param parent GuiElement | nil
---@param target table
---@param isRoot boolean
function ProcessorHUD:loadHUDElements(xmlFile, xmlKey, parent, target, isRoot)
    for index = 0, getXMLNumOfChildren(xmlFile.handle, xmlKey) - 1 do
        local key = string.format("%s.*(%i)", xmlKey, index)
        local typeName = getXMLElementName(xmlFile.handle, key)
        local class = Gui.CONFIGURATION_CLASS_MAPPING[typeName:upper()]

        if class == nil then
            Logging.xmlError(xmlFile, "Invalid HUD element \"%s\" (%s)", tostring(class), key)
            return
        end

        ---@type GuiElement
        local element = class.new()
        local profileName = xmlFile:getString(key .. '#profile')

        element.typeName = typeName
        element.handleFocus = false
        element.soundDisabled = true

        if parent ~= nil then
            parent:addElement(element)
        end

        element:loadFromXML(xmlFile.handle, key)

        self:loadHUDElements(xmlFile, key, element, target, false)

        local onCreateFunc = xmlFile:getString(key .. '#onCreate')

        if onCreateFunc ~= nil and typeof(target[onCreateFunc]) == 'function' then
            self[onCreateFunc](self, element)
        end
    end
end

---@param element GuiElement
function ProcessorHUD:onCreateElement(element)
    if element.id ~= nil and self[element.id] == nil then
        self.elements[element.id] = element
    end
end

function ProcessorHUD:update()
    local vehicle = g_localPlayer:getCurrentVehicle()
    ---@cast vehicle MaterialProcessor | nil

    if vehicle ~= nil and vehicle.getProcessor ~= nil then
        self.processor = vehicle:getProcessor()
    elseif self.processor ~= nil then
        self.processor = nil
    end
end

function ProcessorHUD:draw()
    if not g_processorGui.enableHud or self.processor == nil or self.elements.root == nil then
        return
    end

    local config = self.processor:getConfiguration()

    if config == nil then
        return
    end

    self.elements.root:setDisabled(false)
    self:drawUnit(config:getPrimaryUnit(), config:getPrimaryUnitTypeName())
    self.elements.root:setDisabled(true)

    local title = config:getSecondaryUnitsTypeName()

    for _, unit in ipairs(config:getSecondaryUnits()) do
        if not unit.hidden then
            self:drawUnit(unit, title)
        end
    end
end

---@param unit ProcessorUnit
---@param title string
function ProcessorHUD:drawUnit(unit, title)
    local valid, x, y = self:getUnitNodePosition(unit)
    local yOffset = 0.04

    if valid then
        x = x - self.elements.root.absSize[1] / 2

        self.elements.title:setText(title)
        self.elements.text:setText(unit.fillType.title)
        self.elements.image:setImageFilename(unit.fillType.hudOverlayFilename)

        self.elements.root:setPosition(x, y + yOffset)
        self.elements.root:draw()
    end
end

---@param unit ProcessorUnit
---@return boolean valid
---@return number x
---@return number y
function ProcessorHUD:getUnitNodePosition(unit)
    if unit == nil then
        return false, 0, 0
    end

    local node = unit:getHudNode()

    if node ~= nil then
        local x, y, z = getWorldTranslation(node)
        local sx, sy, sz = project(x, y, z)

        if sx > -1 and sx < 2 and sy > -1 and sy < 2 and sz <= 1 then
            return true, sx, sy
        end
    end

    return false, 0, 0
end
