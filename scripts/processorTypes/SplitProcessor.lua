---@class SplitProcessor : Processor
---@field config SplitProcessorConfiguration | nil
---
---@field superClass fun(): Processor
SplitProcessor = {}

SplitProcessor.TYPE_NAME = 'split'

local SplitProcessor_mt = Class(SplitProcessor, Processor)

---@param schema XMLSchema
---@param key string
function SplitProcessor.registerXMLPaths(schema, key)
    SplitProcessorConfiguration.registerXMLPaths(schema, key .. '.configurations.configuration(?)')
end

---@param vehicle MaterialProcessor
---@param customMt table | nil
---@return SplitProcessor
---@nodiscard
function SplitProcessor.new(vehicle, customMt)
    ---@type SplitProcessor
    ---@diagnostic disable-next-line: assign-type-mismatch
    local self = Processor.new(vehicle, customMt or SplitProcessor_mt)

    return self
end

---@param xmlFile XMLFile
---@param key string
function SplitProcessor:load(xmlFile, key)
    self:superClass().load(self, xmlFile, key)

    xmlFile:iterate(key .. '.configurations.configuration', function(_, configKey)
        local index = #self.configurations + 1

        if index > Processor.MAX_NUM_INDEX then
            Logging.xmlWarning(xmlFile, 'Reached max number of configurations: %i', index)
            return false
        end

        local config = SplitProcessorConfiguration.new(index, self)

        config:load(xmlFile, configKey)

        table.insert(self.configurations, config)
    end)

    assert(#self.configurations > 0, string.format('No configurations found: %s', key))

    if #self.dischargeNodes == 0 then
        Logging.xmlWarning(xmlFile, 'No valid discharge nodes found: %s', key)
    end

    self:setConfiguration(1)
end

---@return boolean
---@nodiscard
function SplitProcessor:getIsAvailable()
    if self.config == nil then
        return false
    end

    local input = self.config.input

    if input == nil then
        return false
    elseif input:getFillLevel() < 0.0001 then
        return false
    end

    for _, output in ipairs(self.config.outputs) do
        if output:getFillPercentage() >= 0.99 then
            local node = self.fillUnitToDischargeNode[output:getFillUnitIndex()]

            if node == nil or (not node:getCanDischargeToObject() and not node:getCanDischargeToGround()) then
                return false
            end
        end
    end

    return true
end

---@param dt number
---@return number
---@nodiscard
function SplitProcessor:process(dt)
    if self.config == nil then
        return 0
    end

    local input = self.config.input

    if input == nil then
        return 0
    end

    local fillLevel = input:getFillLevel()

    if fillLevel == nil or fillLevel == 0 then
        return 0
    end

    local chunkSize = dt * self.config.litersPerMs
    local liters = math.min(chunkSize, fillLevel)

    liters = self:getAvailableOutputCapacityFromLiters(liters)

    if liters == 0 then
        return 0
    end

    local processedLiters = 0

    for _, output in ipairs(self.config.outputs) do
        local delta = output:addFillLevel(liters * output.ratio)
        processedLiters = processedLiters + delta
    end

    if processedLiters == 0 then
        return 0
    end

    return self:addFillUnitFillLevel(input.fillUnit.fillUnitIndex, -processedLiters, input.fillType.index)
end

---@param liters number
---@return number availableOutputCapacity
---@nodiscard
function SplitProcessor:getAvailableOutputCapacityFromLiters(liters)
    local config = self.config

    if config == nil then
        return 0
    end

    local minimumInputThresholdRatio = 1

    for _, output in ipairs(config.outputs) do
        local availableInputCapacity, availableInputCapacityWithRatio, inputThresholdRatio = self:getAvailableInputCapacity(output, liters)

        if availableInputCapacity == 0 or availableInputCapacityWithRatio == 0 then
            return 0
        end

        minimumInputThresholdRatio = math.min(minimumInputThresholdRatio, inputThresholdRatio)
    end

    return liters * minimumInputThresholdRatio
end

---@param unit ProcessorUnit
---@param inputLiters number
function SplitProcessor:getAvailableInputCapacity(unit, inputLiters)
    local availableCapacity = unit:getAvailableCapacity()
    local availableInputCapacity = availableCapacity * unit.ratio
    local litersFromRatio = inputLiters * unit.ratio

    if availableInputCapacity < litersFromRatio then
        local inputThresholdRatio = availableInputCapacity / litersFromRatio
        local inputThresholdLiters = inputLiters * inputThresholdRatio

        return inputThresholdLiters / unit.ratio, inputThresholdLiters, inputThresholdRatio
    end

    return availableCapacity, availableInputCapacity, 1
end
