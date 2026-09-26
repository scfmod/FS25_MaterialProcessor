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

            if not output:getCanReceiveFillType() then
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

---@param dt number
function SplitProcessor:updateTick(dt)
    if self.splitAutoSelectConfigurationEnabled then
        self:updateSupportedInputFillTypes()

        if self.isServer then
            self:autoSelectConfiguration()
        end
    end

    self:superClass().updateTick(self, dt)
end

--- Keeps the input fillUnit's supportedFillTypes in sync with what is actually inside
--- it: while empty, every crop any configuration knows how to process is accepted, so
--- a fresh load of a different crop is not rejected and can be auto-detected. As soon
--- as it is non-empty, supportedFillTypes is narrowed to only the crop already inside,
--- so a different (but otherwise still "known") crop cannot be tipped in on top and
--- silently relabel the whole tank.
function SplitProcessor:updateSupportedInputFillTypes()
    if not self.forceSetSupportedFillTypes then
        return
    end

    local configuration = self.currentConfiguration

    if configuration == nil then
        return
    end

    local inputUnit = configuration:getUnit()

    if inputUnit == nil or inputUnit.fillUnit == nil then
        return
    end

    local fillUnit = inputUnit.fillUnit
    local fillLevel = self.vehicle:getFillUnitFillLevel(fillUnit.fillUnitIndex) or 0

    fillUnit.supportedFillTypes = {}

    if fillLevel <= self.autoDetectEmptyThreshold then
        for _, otherConfiguration in ipairs(self.configurations) do
            local unit = otherConfiguration:getUnit()

            if unit ~= nil and unit.fillType ~= nil then
                fillUnit.supportedFillTypes[unit.fillType.index] = true
            end
        end
    else
        local currentFillType = self.vehicle:getFillUnitFillType(fillUnit.fillUnitIndex)

        if currentFillType ~= nil and currentFillType ~= FillType.UNKNOWN then
            fillUnit.supportedFillTypes[currentFillType] = true
        elseif inputUnit.fillType ~= nil then
            fillUnit.supportedFillTypes[inputUnit.fillType.index] = true
        end
    end
end

--- Automatically switches to whichever configuration's input fillType matches what is
--- currently sitting in the input fillUnit, so the player does not need to manually
--- select a configuration when a different crop is tipped into the hopper.
function SplitProcessor:autoSelectConfiguration()
    local configuration = self.currentConfiguration

    if configuration == nil then
        return
    end

    local inputUnit = configuration:getUnit()

    if inputUnit == nil or inputUnit.fillUnit == nil or inputUnit.fillType == nil then
        return
    end

    local fillUnitIndex = inputUnit.fillUnit.fillUnitIndex
    local currentFillType = self.vehicle:getFillUnitFillType(fillUnitIndex)

    if currentFillType == nil or currentFillType == FillType.UNKNOWN then
        return
    end

    if currentFillType == inputUnit.fillType.index then
        return
    end

    for index, otherConfiguration in ipairs(self.configurations) do
        if index ~= self.currentConfigurationIndex then
            local otherUnit = otherConfiguration:getUnit()

            if otherUnit ~= nil and otherUnit.fillType ~= nil and otherUnit.fillType.index == currentFillType then
                self.vehicle:setProcessorConfiguration(index)
                return
            end
        end
    end
end
