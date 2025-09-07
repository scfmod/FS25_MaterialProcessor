---@class Processor
---@field vehicle MaterialProcessor
---@field configurations ProcessorConfiguration[]
---@field configurationIndex number
---@field config ProcessorConfiguration | nil
---
---@field dischargeNodes ProcessorDischargeNode[]
---@field fillUnitToDischargeNode table<number, ProcessorDischargeNode>
---@field nodeToDischargeNode table<number, ProcessorDischargeNode>
---
---@field needsToBePoweredOn boolean
---@field needsToBeTurnedOn boolean
---@field defaultCanDischargeToGround boolean
---@field canToggleDischargeToGround boolean
---@field canDischargeToGroundAnywhere boolean
---@field canDischargeToGround boolean
---@field canDischargeToAnyObject boolean
---@field forceSetFillType boolean
---@field forceSetSupportedFillTypes boolean
---
---@field isClient boolean
---@field isServer boolean
Processor = {}

Processor.STATE_OFF = 0
Processor.STATE_ON = 1
Processor.SEND_NUM_BITS_STATE = 1
Processor.SEND_NUM_BITS_INDEX = 4
Processor.MAX_NUM_INDEX = 2 ^ Processor.SEND_NUM_BITS_INDEX - 1

---@param schema XMLSchema
---@param key string
function Processor.registerXMLPaths(schema, key)
    schema:register(XMLValueType.BOOL, key .. '#needsToBeTurnedOn', 'Vehicle needs to be turned on in order for processor to work', true)
    schema:register(XMLValueType.BOOL, key .. '#needsToBePoweredOn', 'Vehicle needs to be powered on in order for processor to work', true)
    schema:register(XMLValueType.BOOL, key .. '#defaultCanDischargeToGround', 'Default value for discharging to ground', false)
    schema:register(XMLValueType.BOOL, key .. '#canToggleDischargeToGround', 'Whether player can toggle discharge to ground or not', true)
    schema:register(XMLValueType.BOOL, key .. '#canDischargeToGroundAnywhere', 'Bypass land permissions when discharging to ground', false)
    schema:register(XMLValueType.BOOL, key .. '#canDischargeToAnyObject', 'Bypass vehicle permissions when discharging to object', false)

    ProcessorDischargeNode.registerXMLPaths(schema, key .. '.dischargeNodes.node(?)')
    ProcessorConfiguration.registerXMLPaths(schema, key .. '.configurations.configuration(?)')
end

---@param schema XMLSchema
---@param key string
function Processor.registerSavegameXMLPaths(schema, key)
    schema:register(XMLValueType.BOOL, key .. '#canDischargeToGround')
    schema:register(XMLValueType.INT, key .. '#configuration')
end

---@param vehicle MaterialProcessor
---@param customMt table
---@return Processor
---@nodiscard
function Processor.new(vehicle, customMt)
    ---@type Processor
    local self = setmetatable({}, customMt)

    self.vehicle = vehicle
    self.isClient = vehicle.isClient
    self.isServer = vehicle.isServer

    self.configurations = {}
    self.configurationIndex = 0

    self.dischargeNodes = {}
    self.fillUnitToDischargeNode = {}
    self.nodeToDischargeNode = {}

    self.forceSetFillType = true
    self.forceSetSupportedFillTypes = true
    self.needsToBePoweredOn = true
    self.needsToBeTurnedOn = true
    self.defaultCanDischargeToGround = false
    self.canToggleDischargeToGround = true
    self.canDischargeToGroundAnywhere = false
    self.canDischargeToGround = false
    self.canDischargeToAnyObject = false

    return self
end

function Processor:delete()
    for _, node in ipairs(self.dischargeNodes) do
        node:delete()
    end

    self.dischargeNodes = {}
end

---@param xmlFile XMLFile
---@param key string
function Processor:load(xmlFile, key)
    self.needsToBeTurnedOn = xmlFile:getValue(key .. '#needsToBeTurnedOn', self.needsToBeTurnedOn)

    if self.vehicle.getIsTurnedOn == nil then
        if self.needsToBeTurnedOn and xmlFile:hasProperty(key .. '#needsToBeTurnedOn') then
            Logging.xmlWarning(xmlFile, 'needsToBeTurnedOn is set to true, but vehicle does not have TurnOnVehicle specialization')
        end

        self.needsToBeTurnedOn = false
    end

    self.needsToBePoweredOn = xmlFile:getValue(key .. '#needsToBePoweredOn', self.needsToBePoweredOn)
    self.defaultCanDischargeToGround = xmlFile:getValue(key .. '#defaultCanDischargeToGround', self.defaultCanDischargeToGround)
    self.canToggleDischargeToGround = xmlFile:getValue(key .. '#canToggleDischargeToGround', self.canToggleDischargeToGround)
    self.canDischargeToGroundAnywhere = xmlFile:getValue(key .. '#canDischargeToGroundAnywhere', self.canDischargeToGroundAnywhere)
    self.canDischargeToGround = self.defaultCanDischargeToGround
    self.canDischargeToAnyObject = xmlFile:getValue(key .. '#canDischargeToAnyObject', self.canDischargeToAnyObject)

    xmlFile:iterate(key .. '.dischargeNodes.node', function (_, nodeKey)
        local nodeIndex = #self.dischargeNodes + 1

        if nodeIndex > Processor.MAX_NUM_INDEX then
            Logging.xmlWarning(xmlFile, 'Reached max number of discharge nodes: %i', nodeIndex)
            return false
        end

        local dischargeNode = ProcessorDischargeNode.new(nodeIndex, self)

        if dischargeNode:load(xmlFile, nodeKey) then
            if self.nodeToDischargeNode[dischargeNode.node] ~= nil then
                Logging.xmlError(xmlFile, 'Duplicate discharge node entry: %s', nodeKey)
            elseif self.fillUnitToDischargeNode[dischargeNode.fillUnitIndex] ~= nil then
                Logging.xmlError(xmlFile, 'Duplicate fillUnitIndex entry: %s', nodeKey)
            else
                table.insert(self.dischargeNodes, dischargeNode)
                self.nodeToDischargeNode[dischargeNode.node] = dischargeNode
                self.fillUnitToDischargeNode[dischargeNode.fillUnitIndex] = dischargeNode
            end
        end
    end)

    if #self.dischargeNodes > 0 and SpecializationUtil.hasSpecialization(Dischargeable, self.vehicle.specializations) then
        Logging.xmlWarning(xmlFile, 'Vehicle has Dischargeable specialization, this can result in bugs/errors combined with processor dischargeNodes.')
    end
end

---@param xmlFile XMLFile
---@param key string
function Processor:loadFromXMLFile(xmlFile, key)
    self.canDischargeToGround = xmlFile:getValue(key .. '#canDischargeToGround', self.canDischargeToGround)

    if self:getHasConfigurations() then
        local configurationIndex = xmlFile:getValue(key .. '#configuration')

        if configurationIndex ~= nil and self.configurations[configurationIndex] ~= nil then
            configurationIndex = math.clamp(configurationIndex, 1, #self.configurations)
            self.vehicle:setProcessorConfigurationIndex(configurationIndex)
        end
    end
end

---@param xmlFile XMLFile
---@param key string
function Processor:saveToXMLFile(xmlFile, key)
    xmlFile:setValue(key .. '#canDischargeToGround', self.canDischargeToGround)

    if self:getHasConfigurations() and self.configurationIndex > 0 then
        xmlFile:setValue(key .. '#configuration', self.configurationIndex)
    end
end

function Processor:handleProcessedLiters(liters)
    local state = self.vehicle:getProcessorState()

    if liters > 0 and state == Processor.STATE_OFF then
        self.vehicle:setProcessorState(Processor.STATE_ON)
    end
end

---@param dt number
---@return number
---@nodiscard
function Processor:process(dt)
    -- Implemented by inherited class
    return 0
end

---@param dt number
function Processor:update(dt)
    for _, node in ipairs(self.dischargeNodes) do
        node:update(dt)
    end
end

---@param dt number
---@param isActiveForInput boolean
---@param isActiveForInputIgnoreSelection boolean
---@param isSelected boolean
function Processor:updateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    for _, node in ipairs(self.dischargeNodes) do
        node:updateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    end

    if self.isServer and self.vehicle:getCanProcess() then
        if self:getIsAvailable() then
            local processedLiters = self:process(dt)
            self:handleProcessedLiters(processedLiters)
        else
            for _, node in ipairs(self.dischargeNodes) do
                node:setDischargeState(Dischargeable.DISCHARGE_STATE_OFF)
            end
        end
    end
end

---@return boolean
---@nodiscard
function Processor:getIsAvailable()
    -- Implemented by inherited class
    return false
end

---@param fillUnitIndex number
---@return FillUnitObject | nil
---@nodiscard
function Processor:getFillUnitByIndex(fillUnitIndex)
    return self.vehicle:getFillUnitByIndex(fillUnitIndex)
end

---@param fillUnitIndex number
---@return number
---@nodiscard
function Processor:getFillUnitFillTypeIndex(fillUnitIndex)
    return self.vehicle:getFillUnitFillType(fillUnitIndex) or FillType.UNKNOWN
end

---@param fillUnitIndex number
---@return number
---@nodiscard
function Processor:getFillUnitFillLevel(fillUnitIndex)
    return self.vehicle:getFillUnitFillLevel(fillUnitIndex) or 0
end

---@param fillUnitIndex number
---@return ProcessorDischargeNode | nil
---@nodiscard
function Processor:getFillUnitDischargeNode(fillUnitIndex)
    return self.fillUnitToDischargeNode[fillUnitIndex]
end

---@param fillUnitIndex any
---@param fillLevelDelta any
---@param fillTypeIndex any
---@param unloadInfo any
---@return number
---@nodiscard
function Processor:addFillUnitFillLevel(fillUnitIndex, fillLevelDelta, fillTypeIndex, unloadInfo)
    return self.vehicle:addFillUnitFillLevel(
        self.vehicle:getOwnerFarmId(),
        fillUnitIndex,
        fillLevelDelta,
        fillTypeIndex,
        ToolType.UNDEFINED,
        unloadInfo
    )
end

---@param fillUnitIndex number
---@param fillTypeIndex number
function Processor:setFillUnitFillTypeIndex(fillUnitIndex, fillTypeIndex)
    self.vehicle:setFillUnitFillType(fillUnitIndex, fillTypeIndex)
end

---@param fillUnitIndex number
---@return number
---@nodiscard
function Processor:getFillUnitCapacity(fillUnitIndex)
    return self.vehicle:getFillUnitCapacity(fillUnitIndex) or 0
end

---@param fillUnitIndex number
---@return number
---@nodiscard
function Processor:getFillUnitFreeCapacity(fillUnitIndex)
    return self.vehicle:getFillUnitFreeCapacity(fillUnitIndex) or 0
end

---@param fillUnitIndex number
---@return number
---@nodiscard
function Processor:getFillUnitPercentage(fillUnitIndex)
    return self.vehicle:getFillUnitFillLevelPercentage(fillUnitIndex) or 0
end

---@return boolean
---@nodiscard
function Processor:getFillUnitIsActive(fillUnitIndex)
    if self.config ~= nil then
        return self.config.fillUnitToUnit[fillUnitIndex] ~= nil
    end

    return false
end

---@return boolean
---@nodiscard
function Processor:getHasConfigurations()
    return #self.configurations > 0
end

---@param index number
function Processor:setConfiguration(index)
    if self.configurationIndex ~= index then
        local previousConfiguration = self.configurations[self.configurationIndex]
        local configuration = self.configurations[index]

        assert(configuration ~= nil, string.format('Configuration index not found: %i', index))

        self.configurationIndex = index
        self.config = configuration

        self:onConfigurationChanged(configuration, previousConfiguration)
    end
end

---@param config ProcessorConfiguration
---@param previousConfig ProcessorConfiguration|nil
function Processor:onConfigurationChanged(config, previousConfig)
    if previousConfig ~= nil then
        previousConfig:deactivate()
    end

    config:activate()
end

---@return ProcessorConfiguration | nil
function Processor:getConfiguration()
    return self.config
end
