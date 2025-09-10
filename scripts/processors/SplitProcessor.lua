---@class SplitProcessor : Processor
---@field currentConfiguration? SplitConfiguration
---@field superClass fun(): Processor
SplitProcessor = {}

SplitProcessor.TYPE_NAME = 'split'

local SplitProcessor_mt = Class(SplitProcessor, Processor)

---@param vehicle MaterialProcessor
---@param customMt? table
---@return SplitProcessor
---@nodiscard
function SplitProcessor.new(vehicle, customMt)
    local self = Processor.new(vehicle, customMt or SplitProcessor_mt)
    ---@cast self SplitProcessor

    return self
end

---@param xmlFile XMLFile
---@param key string
---@return boolean
function SplitProcessor:onLoad(xmlFile, key)
    if #self.dischargeNodes == 0 then
        Logging.xmlWarning(xmlFile, 'No valid discharge nodes registered (%s)', key)
    end

    return true
end

---@param xmlFile XMLFile
---@param path string
function SplitProcessor:loadConfigurationEntries(xmlFile, path)
    xmlFile:iterate(path, function (_, key)
        local index = #self.configurations + 1

        if index > Processor.MAX_NUM_INDEX then
            Logging.xmlWarning(xmlFile, 'Reached max number of configurations: %i', index)
            return false
        end

        local configuration = SplitConfiguration.new(index, self)

        if configuration:load(xmlFile, key) then
            table.insert(self.configurations, configuration)
        end
    end)
end

---@param litersToProcess? number
---@return boolean
---@nodiscard
function SplitProcessor:getCanProcess(litersToProcess)
    local configuration = self.currentConfiguration

    if configuration == nil then
        return false
    end

    litersToProcess = litersToProcess or (16.66667 * configuration.litersPerMs * 2)

    if configuration.input:getFillLevel() < litersToProcess or not self:getCanUseOutputs(litersToProcess) then
        return false
    end

    return true
end

---@param litersToProcess? number
---@return boolean
---@nodiscard
function SplitProcessor:getCanUseOutputs(litersToProcess)
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
function SplitProcessor:process(dt)
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

    return configuration.input:addFillLevel(-litersToProcess)
end
