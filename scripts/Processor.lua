---@class Processor
---@field vehicle MaterialProcessor
---@field isServer boolean
---@field isClient boolean
---@field dirtyFlag number
---
---@field currentConfiguration Configuration
---@field currentConfigurationIndex number
---@field configurations Configuration[]
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
---@field dischargeNodes DischargeNode[]
---@field fillUnitToDischargeNode table<number, DischargeNode>
---@field nodeToDischargeNode table<number, DischargeNode>
Processor = {}

Processor.SEND_NUM_BITS_INDEX = 4
Processor.MAX_NUM_INDEX = 2 ^ Processor.SEND_NUM_BITS_INDEX - 1

---@param schema XMLSchema
---@param key string
function Processor.registerXMLPaths(schema, key)
    schema:register(XMLValueType.STRING, key .. '#type', 'Processor type (split / multisplit / blend)', nil, true)
    schema:register(XMLValueType.BOOL, key .. '#needsToBeTurnedOn', 'Vehicle needs to be turned on in order for processor to work', true)
    schema:register(XMLValueType.BOOL, key .. '#needsToBePoweredOn', 'Vehicle needs to be powered on in order for processor to work', true)
    schema:register(XMLValueType.BOOL, key .. '#defaultCanDischargeToGround', 'Default value for discharging to ground', false)
    schema:register(XMLValueType.BOOL, key .. '#canToggleDischargeToGround', 'Whether player can toggle discharge to ground or not', true)
    schema:register(XMLValueType.BOOL, key .. '#canDischargeToGroundAnywhere', 'Bypass land permissions when discharging to ground', false)
    schema:register(XMLValueType.BOOL, key .. '#canDischargeToAnyObject', 'Bypass vehicle permissions when discharging to object', false)
    schema:register(XMLValueType.FLOAT, key .. '#autoDetectEmptyThreshold', 'Fill level (liters) at or below which the input fillUnit is considered empty for automatic configuration detection and fillType switching', 20)
    schema:register(XMLValueType.BOOL, key .. '#splitAutoSelectConfigurationEnabled', 'Split processor only: automatically switch configuration to match the fillType currently in the input fillUnit', false)

    DischargeNode.registerXMLPaths(schema, key .. '.dischargeNodes.node(?)')
    Configuration.registerXMLPaths(schema, key .. '.configurations.configuration(?)')
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
function Processor.new(vehicle, customMt)
    ---@class Processor
    local self = setmetatable({}, customMt)

    self.vehicle = vehicle
    self.isServer = vehicle.isServer
    self.isClient = vehicle.isClient
    self.dirtyFlag = vehicle[MaterialProcessor.SPEC_NAME].dirtyFlag

    self.configurations = {}
    self.currentConfigurationIndex = 0

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
    self.autoDetectEmptyThreshold = 20
    self.splitAutoSelectConfigurationEnabled = false

    return self
end

function Processor:delete()
    for _, dischargeNode in ipairs(self.dischargeNodes) do
        dischargeNode:delete()
    end

    self.dischargeNodes = {}
end

---@param xmlFile XMLFile
---@param key string
---@return boolean
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
    self.autoDetectEmptyThreshold = xmlFile:getValue(key .. '#autoDetectEmptyThreshold', self.autoDetectEmptyThreshold)
    self.splitAutoSelectConfigurationEnabled = xmlFile:getValue(key .. '#splitAutoSelectConfigurationEnabled', self.splitAutoSelectConfigurationEnabled)

    self:loadConfigurationEntries(xmlFile, key .. '.configurations.configuration')

    if #self.configurations == 0 then
        Logging.xmlError(xmlFile, 'No configurations found (%s)', key .. '.configurations.configuration')
        return false
    end

    xmlFile:iterate(key .. '.dischargeNodes.node', function (_, nodeKey)
        local nodeIndex = #self.dischargeNodes + 1

        if nodeIndex > Processor.MAX_NUM_INDEX then
            Logging.xmlWarning(xmlFile, 'Reached max number of discharge nodes: %i', nodeIndex)
            return false
        end

        local dischargeNode = DischargeNode.new(self, nodeIndex)

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

    if not self:onLoad(xmlFile, key) then
        return false
    end

    if self.isServer then
        self:setConfiguration(1)
    end

    return true
end

---@param xmlFile XMLFile
---@param key string
---@return boolean
---@nodiscard
function Processor:onLoad(xmlFile, key)
    -- void
    return true
end

---@param xmlFile XMLFile
---@param key string
function Processor:loadFromXMLFile(xmlFile, key)
    self.canDischargeToGround = xmlFile:getValue(key .. '#canDischargeToGround', self.canDischargeToGround)

    if #self.configurations > 0 then
        local configurationIndex = xmlFile:getValue(key .. '#configuration')

        if configurationIndex ~= nil and self.configurations[configurationIndex] ~= nil then
            configurationIndex = math.clamp(configurationIndex, 1, #self.configurations)
            self.vehicle:setProcessorConfiguration(configurationIndex)
        end
    end
end

---@param xmlFile XMLFile
---@param key string
function Processor:saveToXMLFile(xmlFile, key)
    xmlFile:setValue(key .. '#canDischargeToGround', self.canDischargeToGround)

    if #self.configurations > 0 and self.currentConfigurationIndex > 0 then
        xmlFile:setValue(key .. '#configuration', self.currentConfigurationIndex)
    end
end

---@param index number
function Processor:setConfiguration(index)
    if self.currentConfigurationIndex ~= index then
        local previous = self.configurations[self.currentConfigurationIndex]
        local configuration = self.configurations[index]

        assert(configuration ~= nil, string.format('Configuration index %d not found', index))

        self.currentConfigurationIndex = index
        self.currentConfiguration = configuration

        if previous ~= nil then
            previous:deactivate()
        end

        configuration:activate()
    end
end

---@param dt number
function Processor:update(dt)
    for _, dischargeNode in ipairs(self.dischargeNodes) do
        dischargeNode:update(dt)
    end
end

---@param dt number
function Processor:updateTick(dt)
    for _, dischargeNode in ipairs(self.dischargeNodes) do
        dischargeNode:updateTick(dt)
    end

    if self.isServer then
        if self.vehicle:getIsProcessingEnabled() then
            self:updateConfigurationUnitFillTypes()

            if self:getCanProcess() then
                self:handleProcessedLiters(self:process(dt))
            end
        else
            for _, dischargeNode in ipairs(self.dischargeNodes) do
                dischargeNode:setDischargeState(Dischargeable.DISCHARGE_STATE_OFF)
            end
        end
    end
end

---@param litersProcessed number
function Processor:handleProcessedLiters(litersProcessed)
    -- void
end

---@return boolean
---@nodiscard
function Processor:getFillUnitIsActive(fillUnitIndex)
    if self.currentConfiguration ~= nil then
        return self.currentConfiguration.fillUnitToConfigurationUnit[fillUnitIndex] ~= nil
    end

    return false
end

--- activate() only runs once, at the moment a configuration is selected. If a unit
--- still held more than autoDetectEmptyThreshold liters at that exact moment, it is
--- left alone (by design, to avoid relabelling/mixing real material) - but nothing
--- else ever re-checks it afterwards. If it is later emptied out (e.g. discharged),
--- it would otherwise stay locked to its old fillType indefinitely, silently
--- rejecting the current configuration's produce. This re-checks every unit the
--- current configuration touches each tick and re-applies activate() to any whose
--- actual fillType no longer matches, now that it is safe to do so.
function Processor:updateConfigurationUnitFillTypes()
    if not self.forceSetFillType and not self.forceSetSupportedFillTypes then
        return
    end

    local configuration = self.currentConfiguration

    if configuration == nil then
        return
    end

    -- SplitProcessor manages its own primary (input) unit every tick with different,
    -- wider semantics while auto-detection is enabled (accepting any configuration's
    -- fillType while empty, not just the current one) - skip it here so this does not
    -- fight with that and immediately re-narrow what it just widened.
    local skipUnit = nil

    if self.splitAutoSelectConfigurationEnabled then
        skipUnit = configuration:getUnit()
    end

    -- Iterate fillUnitToConfigurationUnit rather than getUnit()/getUnits(): the latter
    -- pair does not cover every unit for every configuration type - MultisplitConfiguration
    -- in particular has multiple inputs, but getUnit() only ever returns the first one.
    for _, unit in pairs(configuration.fillUnitToConfigurationUnit) do
        if unit ~= skipUnit then
            self:updateConfigurationUnitFillType(unit)
        end
    end
end

---@param unit ConfigurationUnit
function Processor:updateConfigurationUnitFillType(unit)
    if unit:getFillLevel() > self.autoDetectEmptyThreshold then
        return
    end

    local currentFillType = self.vehicle:getFillUnitFillType(unit.fillUnit.fillUnitIndex)

    if currentFillType ~= unit.fillType.index then
        unit:activate()
    end
end

---@param xmlFile XMLFile
---@param path string
function Processor:loadConfigurationEntries(xmlFile, path)
    Logging.error('Processor:loadConfigurationEntries() must be implemented by inherited class')
    printCallstack()

    return false
end

---@param litersToProcess? number
---@return boolean
---@nodiscard
function Processor:getCanProcess(litersToProcess)
    Logging.error('Processor:getCanProcess() must be implemented by inherited class')
    printCallstack()

    return false
end

---@param dt number
---@return number litersProcessed
function Processor:process(dt)
    Logging.error('Processor:process() must be implemented by inherited class')
    printCallstack()

    return 0
end
