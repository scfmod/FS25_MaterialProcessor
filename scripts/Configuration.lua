---@class Configuration
---@field processor Processor
---@field index number
---
---@field displayName string
---@field litersPerSecondText? string
---@field litersPerSecond number
---@field litersPerMs number
---@field fillUnitToConfigurationUnit table<number, ConfigurationUnit>
Configuration = {}

---@param schema XMLSchema
---@param key string
function Configuration.registerXMLPaths(schema, key)
    schema:register(XMLValueType.L10N_STRING, key .. '#name', 'Name to display in GUI')
    schema:register(XMLValueType.INT, key .. '#litersPerSecond', 'Liters processed per second', 400, true)
    schema:register(XMLValueType.L10N_STRING, key .. '#litersPerSecondText', 'Set custom text in GUI')

    BlendConfiguration.registerXMLPaths(schema, key)
    SplitConfiguration.registerXMLPaths(schema, key)
end

---@param index number
---@param processor Processor
---@param customMt table
---@return Configuration
---@nodiscard
function Configuration.new(index, processor, customMt)
    ---@type Configuration
    local self = setmetatable({}, customMt)

    self.index = index
    self.processor = processor

    self.displayName = string.format('Configuration #%i', index)

    self.litersPerSecond = 400
    self.litersPerMs = self.litersPerSecond / 1000

    self.fillUnitToConfigurationUnit = {}

    return self
end

---@param xmlFile XMLFile
---@param key string
function Configuration:load(xmlFile, key)
    local displayName = xmlFile:getValue(key .. '#name', nil, self.processor.vehicle.customEnvironment)

    if displayName ~= nil then
        self.displayName = displayName
    end

    local litersPerSecond = xmlFile:getValue(key .. '#litersPerSecond')

    if litersPerSecond == nil then
        Logging.xmlWarning(xmlFile, 'Missing "litersPerSecond" in configuration, using default (%i): %s', self.litersPerSecond, key .. '#litersPerSecond')
    else
        self.litersPerSecond = litersPerSecond
        self.litersPerMs = self.litersPerSecond / 1000
    end

    self.litersPerSecondText = xmlFile:getValue(key .. '#litersPerSecondText', nil, self.processor.vehicle.customEnvironment)
end

function Configuration:activate()
    self:getUnit():activate()

    for _, unit in ipairs(self:getUnits()) do
        unit:activate()
    end
end

function Configuration:deactivate()
    self:getUnit():deactivate()

    for _, unit in ipairs(self:getUnits()) do
        unit:deactivate()
    end
end

---@return ConfigurationUnit
---@nodiscard
function Configuration:getUnit()
    -- void
    ---@diagnostic disable-next-line: missing-return
end

---@return string
---@nodiscard
function Configuration:getUnitTitle()
    -- void
    ---@diagnostic disable-next-line: missing-return
end

---@return string
---@nodiscard
function Configuration:getUnitTypeName()
    -- void
    ---@diagnostic disable-next-line: missing-return
end

---@return ConfigurationUnit[]
---@nodiscard
function Configuration:getUnits()
    -- void
    ---@diagnostic disable-next-line: missing-return
end

---@return string
---@nodiscard
function Configuration:getUnitsTitle()
    -- void
    ---@diagnostic disable-next-line: missing-return
end

---@return string
---@nodiscard
function Configuration:getUnitsTypeName()
    -- void
    ---@diagnostic disable-next-line: missing-return
end
