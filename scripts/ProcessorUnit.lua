---@class ProcessorUnit
---@field processor Processor
---@field ratio number
---@field fillUnit FillUnitObject
---@field fillType FillTypeObject
---@field config ProcessorConfiguration
---@field hudNode number | nil
---@field hidden boolean
ProcessorUnit = {}

local ProcessorUnit_mt = Class(ProcessorUnit)

---@param schema XMLSchema
---@param key string
---@param requireRatio boolean
function ProcessorUnit.registerXMLPaths(schema, key, requireRatio)
    schema:register(XMLValueType.FLOAT, key .. '#ratio', 'Processing unit ratio', 0, requireRatio)
    schema:register(XMLValueType.INT, key .. '#fillUnitIndex', 'Vehicle fillUnitIndex', nil, true)
    schema:register(XMLValueType.STRING, key .. '#fillType', 'Filltype name', nil, true)
    schema:register(XMLValueType.NODE_INDEX, key .. '#hudNode', 'Set custom node for HUD display position', nil, false)
    schema:register(XMLValueType.BOOL, key .. '#hidden', 'Hide in HUD and GUI', false)
end

---@param processor Processor
---@param config ProcessorConfiguration
---@param customMt table | nil
---@return ProcessorUnit
---@nodiscard
function ProcessorUnit.new(processor, config, customMt)
    ---@type ProcessorUnit
    local self = setmetatable({}, customMt or ProcessorUnit_mt)

    self.processor = processor
    self.config = config
    self.ratio = 0
    self.hidden = false

    return self
end

---@param xmlFile XMLFile
---@param key string
---@return boolean
---@nodiscard
function ProcessorUnit:load(xmlFile, key)
    self.hidden = xmlFile:getValue(key .. '#hidden', self.hidden)
    ---@diagnostic disable-next-line: assign-type-mismatch
    self.ratio = MathUtil.round(xmlFile:getValue(key .. '#ratio', self.ratio), 4)

    local fillUnitIndex = xmlFile:getValue(key .. '#fillUnitIndex')

    if fillUnitIndex == nil then
        Logging.xmlError(xmlFile, 'fillUnitIndex is not set: %s', key .. '#fillUnitIndex')
        return false
    end

    local fillUnit = self.processor:getFillUnitByIndex(fillUnitIndex)

    if fillUnit == nil then
        Logging.xmlError(xmlFile, 'Could not find fillUnit by index %i: %s', fillUnitIndex, key .. '#fillUnitIndex')
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

    local hudNodeIndex = xmlFile:getString(key .. '#hudNode')

    if hudNodeIndex ~= nil then
        local vehicle = self.processor.vehicle

        self.hudNode = I3DUtil.indexToObject(vehicle.components, hudNodeIndex, vehicle.i3dMappings)

        if self.hudNode == nil then
            Logging.xmlWarning(xmlFile, 'Could not find node index "%s": %s', hudNodeIndex, key .. '#hudNode')
        end
    end

    return true
end

function ProcessorUnit:activate()
    if self.processor.forceSetSupportedFillTypes then
        self.fillUnit.supportedFillTypes = {}
        self.fillUnit.supportedFillTypes[self.fillType.index] = true
    end

    if self.processor.isServer then
        if self.processor.forceSetFillType then
            self.processor:setFillUnitFillTypeIndex(self.fillUnit.fillUnitIndex, self.fillType.index)
        end
    end
end

function ProcessorUnit:deactivate()
    if self.processor.isServer then
        local dischargeNode = self.processor:getFillUnitDischargeNode(self:getFillUnitIndex())

        if dischargeNode ~= nil then
            dischargeNode:setDischargeState(Dischargeable.DISCHARGE_STATE_OFF)
        end
    end
end

function ProcessorUnit:addFillLevel(fillLevelDelta)
    return self.processor:addFillUnitFillLevel(self.fillUnit.fillUnitIndex, fillLevelDelta, self.fillType.index)
end

---@return number
---@nodiscard
function ProcessorUnit:getTotalCapacity()
    return self.processor:getFillUnitCapacity(self.fillUnit.fillUnitIndex)
end

---@return number
---@nodiscard
function ProcessorUnit:getAvailableCapacity()
    return self.processor:getFillUnitFreeCapacity(self.fillUnit.fillUnitIndex)
end

function ProcessorUnit:getFillPercentage()
    return self.processor:getFillUnitPercentage(self.fillUnit.fillUnitIndex)
end

---@return number
---@nodiscard
function ProcessorUnit:getFillLevel()
    return self.processor:getFillUnitFillLevel(self.fillUnit.fillUnitIndex)
end

---@return number
---@nodiscard
function ProcessorUnit:getFillUnitIndex()
    return self.fillUnit.fillUnitIndex
end

---@return FillUnitObject
---@nodiscard
function ProcessorUnit:getFillUnit()
    return self.fillUnit
end

---@return number
---@nodiscard
function ProcessorUnit:getFillTypeIndex()
    return self.fillType.index
end

---@return FillTypeObject
---@nodiscard
function ProcessorUnit:getFillType()
    return self.fillType
end

---@return number | nil node
---@return number yOffset
---@nodiscard
function ProcessorUnit:getHudNode()
    local yOffset = 0.02

    if self.hudNode ~= nil then
        return self.hudNode, yOffset
    end

    local fillUnitIndex = self.fillUnit.fillUnitIndex
    local dischargeNode = self.processor.fillUnitToDischargeNode[fillUnitIndex]

    if dischargeNode ~= nil then
        return dischargeNode.node, yOffset
    end

    return self.processor.vehicle:getFillUnitRootNode(fillUnitIndex), yOffset
end
