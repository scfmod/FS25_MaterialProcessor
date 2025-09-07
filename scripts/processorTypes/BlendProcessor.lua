---@class BlendProcessor : Processor
---@field config BlendProcessorConfiguration | nil
---
---@field superClass fun(): Processor
BlendProcessor = {}

BlendProcessor.TYPE_NAME = 'blend'

local BlendProcessor_mt = Class(BlendProcessor, Processor)

---@param schema XMLSchema
---@param key string
function BlendProcessor.registerXMLPaths(schema, key)
    BlendProcessorConfiguration.registerXMLPaths(schema, key .. '.configurations.configuration(?)')
end

---@param vehicle MaterialProcessor
---@param customMt table | nil
function BlendProcessor.new(vehicle, customMt)
    ---@type BlendProcessor
    ---@diagnostic disable-next-line: assign-type-mismatch
    local self = Processor.new(vehicle, customMt or BlendProcessor_mt)

    return self
end

---@param xmlFile XMLFile
---@param key string
function BlendProcessor:load(xmlFile, key)
    self:superClass().load(self, xmlFile, key)

    xmlFile:iterate(key .. '.configurations.configuration', function(_, configKey)
        local index = #self.configurations + 1

        if index > Processor.MAX_NUM_INDEX then
            Logging.xmlWarning(xmlFile, 'Reached max number of configurations: %i', index)
            return false
        end

        local config = BlendProcessorConfiguration.new(index, self)

        config:load(xmlFile, configKey)

        table.insert(self.configurations, config)
    end)

    assert(#self.configurations > 0, string.format('No configurations found: %s', key))

    self:setConfiguration(1)

    self.canToggleDischargeToGround = false
end

---@return boolean
---@nodiscard
function BlendProcessor:getIsAvailable()
    if self.config == nil then
        return false
    elseif self.config.output:getFillPercentage() > 0.99 then
        return false
    end

    if #self.config.inputs == 0 then
        return false
    end

    for _, input in ipairs(self.config.inputs) do
        if input:getFillPercentage() < 0.01 then
            return false
        end
    end

    return true
end

---@param dt number
---@return number
---@nodiscard
function BlendProcessor:process(dt)
    if self.config == nil then
        return 0
    end

    local output = self.config.output

    if output == nil then
        return 0
    end

    local outputChunkSize = dt * self.config.litersPerMs
    local outputCapacity = output:getAvailableCapacity()

    if outputCapacity < outputChunkSize then
        return 0
    end

    ---@type table<ProcessorUnit, number>
    local inputChunkSize = {}

    local totalInputChunkSize = 0

    for _, input in ipairs(self.config.inputs) do
        local fillLevel = input:getFillLevel()
        local chunkSize = outputChunkSize * input.ratio

        if fillLevel < chunkSize then
            return 0
        end

        inputChunkSize[input] = chunkSize
        totalInputChunkSize = totalInputChunkSize + chunkSize
    end

    if totalInputChunkSize < outputChunkSize then
        return 0
    end

    local processedLiters = 0

    for _, input in ipairs(self.config.inputs) do
        local fillLevelDelta = self:addFillUnitFillLevel(input.fillUnit.fillUnitIndex, 0 - inputChunkSize[input], input.fillType.index)
        processedLiters = processedLiters + math.abs(fillLevelDelta)
    end

    return self:addFillUnitFillLevel(output.fillUnit.fillUnitIndex, processedLiters, output.fillType.index)
end
