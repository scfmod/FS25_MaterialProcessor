---@class BlendProcessor : Processor
---@field currentConfiguration? BlendConfiguration
BlendProcessor = {}

BlendProcessor.TYPE_NAME = 'blend'

local BlendProcessor_mt = Class(BlendProcessor, Processor)

---@param vehicle MaterialProcessor
---@param customMt? table
---@return BlendProcessor
---@nodiscard
function BlendProcessor.new(vehicle, customMt)
    local self = Processor.new(vehicle, customMt or BlendProcessor_mt)
    ---@cast self BlendProcessor

    return self
end

---@param xmlFile XMLFile
---@param path string
function BlendProcessor:loadConfigurationEntries(xmlFile, path)
    xmlFile:iterate(path, function (_, key)
        local index = #self.configurations + 1

        if index > Processor.MAX_NUM_INDEX then
            Logging.xmlWarning(xmlFile, 'Reached max number of configurations: %i', index)
            return false
        end

        local configuration = BlendConfiguration.new(index, self)

        if configuration:load(xmlFile, key) then
            table.insert(self.configurations, configuration)
        end
    end)
end

---@param litersToProcess? number
---@return boolean
---@nodiscard
function BlendProcessor:getCanProcess(litersToProcess)
    local configuration = self.currentConfiguration

    if configuration == nil then
        return false
    end

    litersToProcess = litersToProcess or (16.66667 * configuration.litersPerMs * 2)

    if configuration.output:getAvailableCapacity() < litersToProcess or not self:getCanUseInputs(litersToProcess) then
        return false
    end

    return true
end

---@param litersToProcess? number
---@return boolean
---@nodiscard
function BlendProcessor:getCanUseInputs(litersToProcess)
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

---@param dt number
---@return number
---@nodiscard
function BlendProcessor:process(dt)
    local configuration = self.currentConfiguration

    if configuration == nil then
        return 0
    end

    local litersToProcess = dt * configuration.litersPerMs

    if not self:getCanProcess(litersToProcess) then
        return 0
    end

    for _, input in ipairs(configuration.inputs) do
        if input.ratio > 0 then
            local targetLiters = litersToProcess * input.ratio
            local _ = input:addFillLevel(-targetLiters)
        end
    end

    return configuration.output:addFillLevel(litersToProcess)
end
