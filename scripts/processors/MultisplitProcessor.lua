---@class MultisplitProcessor : Processor
---@field currentConfiguration? MultisplitConfiguration
---@field superClass fun(): Processor
MultisplitProcessor = {}

MultisplitProcessor.TYPE_NAME = 'multisplit'

local MultisplitProcessor_mt = Class(MultisplitProcessor, Processor)

---@param vehicle MaterialProcessor
---@param customMt? table
---@return MultisplitProcessor
---@nodiscard
function MultisplitProcessor.new(vehicle, customMt)
    local self = Processor.new(vehicle, customMt or MultisplitProcessor_mt)
    ---@cast self MultisplitProcessor

    return self
end

---@param xmlFile XMLFile
---@param key string
function MultisplitProcessor:onLoad(xmlFile, key)
    if #self.dischargeNodes == 0 then
        Logging.xmlWarning(xmlFile, 'No valid discharge nodes registered (%s)', key)
    end

    return true
end

---@param xmlFile XMLFile
---@param path string
function MultisplitProcessor:loadConfigurationEntries(xmlFile, path)
    xmlFile:iterate(path, function (_, key)
        local index = #self.configurations + 1

        if index > Processor.MAX_NUM_INDEX then
            Logging.xmlWarning(xmlFile, 'Reached max number of configurations: %i', index)
            return false
        end

        local configuration = MultisplitConfiguration.new(index, self)

        if configuration:load(xmlFile, key) then
            table.insert(self.configurations, configuration)
        end
    end)
end

---@param litersToProcess? number
---@return boolean
---@nodiscard
function MultisplitProcessor:getCanProcess(litersToProcess)
    local configuration = self.currentConfiguration

    if configuration == nil then
        return false
    end

    litersToProcess = litersToProcess or (16.66667 * configuration.litersPerMs * 2)

    if not self:getCanUseInputs(litersToProcess) then
        return false
    elseif not self:getCanUseOutputs(litersToProcess) then
        return false
    end

    return true
end

---@param litersToProcess? number
---@return boolean
---@nodiscard
function MultisplitProcessor:getCanUseInputs(litersToProcess)
    local configuration = self.currentConfiguration

    if configuration == nil then
        return false
    end

    litersToProcess = litersToProcess or (16.66667 * configuration.litersPerMs * 2)

    for _, input in ipairs(configuration.inputs) do
        if input.ratio > 0 then
            local targetLiters = litersToProcess * input.ratio

            if input:getFillLevel() < targetLiters then
                return false
            end
        end
    end

    return true
end

---@param litersToProcess? number
---@return boolean
---@nodiscard
function MultisplitProcessor:getCanUseOutputs(litersToProcess)
    local configuration = self.currentConfiguration

    if configuration == nil then
        return false
    end

    litersToProcess = litersToProcess or (16.66667 * configuration.litersPerMs * 2)

    for _, output in ipairs(configuration.outputs) do
        if output.ratio > 0 then
            local targetLiters = litersToProcess * output.ratio

            if output:getAvailableCapacity() < targetLiters then
                return false
            end
        end
    end

    return true
end

---@param dt number
---@return number
---@nodiscard
function MultisplitProcessor:process(dt)
    local configuration = self.currentConfiguration

    if configuration == nil then
        return 0
    end

    local litersToProcess = dt * configuration.litersPerMs

    if not self:getCanProcess(litersToProcess) then
        return 0
    end

    for _, output in ipairs(configuration.outputs) do
        if output.ratio > 0 then
            local targetLiters = litersToProcess * output.ratio
            local _ = output:addFillLevel(targetLiters)
        end
    end

    local totalLitersProcessed = 0

    for _, input in ipairs(configuration.inputs) do
        if input.ratio > 0 then
            local targetLiters = litersToProcess * input.ratio
            totalLitersProcessed = totalLitersProcessed + math.abs(input:addFillLevel(-targetLiters))
        end
    end

    return totalLitersProcessed
end
