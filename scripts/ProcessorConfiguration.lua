---@class ProcessorConfiguration
---@field index number
---@field processor Processor
---@field name string
---@field litersPerSecond number
---@field litersPerMs number
---@field fillUnitToUnit table<number, ProcessorUnit>
ProcessorConfiguration = {}

---@param schema XMLSchema
---@param key string
function ProcessorConfiguration.registerXMLPaths(schema, key)
    schema:register(XMLValueType.L10N_STRING, key .. '#name', 'Name to display in GUI')
    schema:register(XMLValueType.INT, key .. '#litersPerSecond', 'Liters processed per second', 400, true)
end

---@param index number
---@param processor Processor
---@param customMt table
---@return ProcessorConfiguration
function ProcessorConfiguration.new(index, processor, customMt)
    ---@type ProcessorConfiguration
    local self = setmetatable({}, customMt)

    self.name = string.format('Configuration #%i', index)
    self.index = index
    self.processor = processor
    self.litersPerSecond = 400
    self.litersPerMs = self.litersPerSecond / 1000
    self.fillUnitToUnit = {}

    return self
end

---@param xmlFile XMLFile
---@param key string
function ProcessorConfiguration:load(xmlFile, key)
    local name = xmlFile:getValue(key .. '#name', nil, self.processor.vehicle.customEnvironment)

    if name ~= nil then
        self.name = name
    end

    local litersPerSecond = xmlFile:getValue(key .. '#litersPerSecond')

    if litersPerSecond == nil then
        Logging.xmlWarning(xmlFile, 'Missing "litersPerSecond" in configuration, using default (%i): %s', self.litersPerSecond, key .. '#litersPerSecond')
    else
        self.litersPerSecond = litersPerSecond
        self.litersPerMs = self.litersPerSecond / 1000
    end
end

function ProcessorConfiguration:activate()
    -- Implemented by inherited class
end

function ProcessorConfiguration:deactivate()
    -- Implemented by inherited class
end

---@return ProcessorUnit
---@nodiscard
function ProcessorConfiguration:getPrimaryUnit()
    -- Implemented by inherited class
    ---@diagnostic disable-next-line: missing-return
end

---@return string
---@nodiscard
function ProcessorConfiguration:getPrimaryUnitTypeName()
    -- Implemented by inherited class
    return 'Primary unit'
end

---@return ProcessorUnit[]
---@nodiscard
function ProcessorConfiguration:getSecondaryUnits()
    -- Implemented by inherited class
    return {}
end

---@return string
---@nodiscard
function ProcessorConfiguration:getSecondaryUnitsTypeName()
    -- Implemented by inherited class
    return 'Secondary units'
end

---@return string
---@nodiscard
function ProcessorConfiguration:getDialogTitle()
    -- Implemented by inherited class
    return 'Dialog title'
end

---@return string
---@nodiscard
function ProcessorConfiguration:getUnitsListTitle()
    -- Implemented by inherited class
    return 'List title'
end
