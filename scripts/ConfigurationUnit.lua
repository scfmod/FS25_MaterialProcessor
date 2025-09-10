---@class ConfigurationUnit
---@field processor Processor
---@field configuration Configuration
---@field vehicle VehicleObject
---
---@field ratio number
---@field fillUnit FillUnitObject
---@field fillType FillTypeObject
---@field displayNode? number
---@field displayNodeOffsetY number
---@field visible boolean
ConfigurationUnit = {}

local ConfigurationUnit_mt = Class(ConfigurationUnit)

---@param schema XMLSchema
---@param key string
---@param requireRatio boolean
function ConfigurationUnit.registerXMLPaths(schema, key, requireRatio)
    schema:register(XMLValueType.FLOAT, key .. '#ratio', 'Processing unit ratio', 0, requireRatio)
    schema:register(XMLValueType.INT, key .. '#fillUnit', 'Vehicle fillUnitIndex', nil, true)
    schema:register(XMLValueType.STRING, key .. '#fillType', 'Filltype name', nil, true)
    schema:register(XMLValueType.NODE_INDEX, key .. '#displayNode', 'Set custom node for HUD display position', nil, false)
    schema:register(XMLValueType.FLOAT, key .. '#displayNodeOffsetY', 'Offset Y position for display node')
    schema:register(XMLValueType.BOOL, key .. '#visible', 'Show in HUD and GUI', true)
end

---@param processor Processor
---@param configuration Configuration
---@param customMt? table
---@return ConfigurationUnit
---@nodiscard
function ConfigurationUnit.new(processor, configuration, customMt)
    ---@type ConfigurationUnit
    local self = setmetatable({}, customMt or ConfigurationUnit_mt)

    self.processor = processor
    self.vehicle = processor.vehicle
    self.configuration = configuration
    self.visible = true
    self.ratio = 0
    self.displayNodeOffsetY = 0

    return self
end

---@param xmlFile XMLFile
---@param key string
---@return boolean
---@nodiscard
function ConfigurationUnit:load(xmlFile, key)
    self.ratio = xmlFile:getValue(key .. '#ratio', self.ratio)
    self.visible = xmlFile:getValue(key .. '#visible', self.visible)
    self.displayNodeOffsetY = xmlFile:getValue(key .. '#displayNodeOffsetY', self.displayNodeOffsetY)

    -- Legacy config check
    if xmlFile:getBool(key .. '#hidden') == true then
        self.visible = false
    end

    local fillUnitIndex = xmlFile:getValue(key .. '#fillUnit', xmlFile:getInt(key .. '#fillUnitIndex'))

    if fillUnitIndex == nil then
        Logging.xmlError(xmlFile, 'Missing property: %s', key .. '#fillUnit')
        return false
    end

    local fillUnit = self.vehicle:getFillUnitByIndex(fillUnitIndex)

    if fillUnit == nil then
        Logging.xmlError(xmlFile, 'Could not find fillUnit index %i (%s)', fillUnitIndex, key .. '#fillUnitIndex')
        return false
    end

    self.fillUnit = fillUnit

    local fillTypeName = xmlFile:getValue(key .. '#fillType')

    if fillTypeName == nil then
        Logging.xmlError(xmlFile, 'fillType is not set: %s', key .. '#fillType')
        return false
    end

    local fillType = g_fillTypeManager:getFillTypeByName(fillTypeName)

    if fillType == nil then
        Logging.xmlError(xmlFile, 'Could not find fillType by name "%s": %s', fillTypeName, key .. '#fillType')
        return false
    end

    self.fillType = fillType

    local displayNodeIndex = xmlFile:getString(key .. '#displayNode', xmlFile:getString(key .. '#hudNode'))

    if displayNodeIndex ~= nil then
        local vehicle = self.vehicle

        self.displayNode = I3DUtil.indexToObject(vehicle.components, displayNodeIndex, vehicle.i3dMappings)

        if self.displayNode == nil then
            Logging.xmlWarning(xmlFile, 'Could not find node index "%s": %s', displayNodeIndex, key .. '#displayNode')
        end
    end

    return true
end

function ConfigurationUnit:activate()
    if self.processor.forceSetSupportedFillTypes then
        self.fillUnit.supportedFillTypes = {}
        self.fillUnit.supportedFillTypes[self.fillType.index] = true
    end

    if self.vehicle.isServer then
        if self.processor.forceSetFillType then
            self.vehicle:setFillUnitFillType(self.fillUnit.fillUnitIndex, self.fillType.index)
        end
    end
end

function ConfigurationUnit:deactivate()
    if self.vehicle.isServer then
        local dischargeNode = self.processor.fillUnitToDischargeNode[self.fillUnit.fillUnitIndex]

        if dischargeNode ~= nil then
            dischargeNode:setDischargeState(Dischargeable.DISCHARGE_STATE_OFF)
        end
    end
end

---@param fillLevelDelta number
---@return number
---@nodiscard
function ConfigurationUnit:addFillLevel(fillLevelDelta)
    return self.vehicle:addFillUnitFillLevel(self.vehicle:getOwnerFarmId(), self.fillUnit.fillUnitIndex, fillLevelDelta, self.fillType.index, ToolType.UNDEFINED)
end

---@return number
---@nodiscard
function ConfigurationUnit:getFillLevel()
    return self.vehicle:getFillUnitFillLevel(self.fillUnit.fillUnitIndex) or 0
end

---@return number
---@nodiscard
function ConfigurationUnit:getAvailableCapacity()
    return self.vehicle:getFillUnitFreeCapacity(self.fillUnit.fillUnitIndex) or 0
end

---@return number? node
---@return number yOffset
---@nodiscard
function ConfigurationUnit:getDisplayNode()
    if self.displayNode ~= nil then
        return self.displayNode, self.displayNodeOffsetY
    end

    local fillUnitIndex = self.fillUnit.fillUnitIndex
    local dischargeNode = self.processor.fillUnitToDischargeNode[fillUnitIndex]

    if dischargeNode ~= nil then
        return dischargeNode.node, self.displayNodeOffsetY
    end

    return self.vehicle:getFillUnitRootNode(fillUnitIndex), self.displayNodeOffsetY
end

---@return boolean isValid
---@return number x
---@return number y
---@return number offsetY
function ConfigurationUnit:getDisplayPosition()
    local node, offsetY = self:getDisplayNode()

    if node ~= nil then
        local x, y, z = getWorldTranslation(node)
        local sx, sy, sz = project(x, y, z)

        if sx > -1 and sx < 2 and sy > -1 and sy < 2 and sz <= 1 then
            return true, sx, sy, offsetY
        end
    end

    return false, 0, 0, offsetY
end
