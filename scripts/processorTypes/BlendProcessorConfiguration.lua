---@class BlendProcessorConfiguration : ProcessorConfiguration
---@field inputs ProcessorUnit[]
---@field output ProcessorUnit
---
---@field superClass fun(): ProcessorConfiguration
BlendProcessorConfiguration = {}

local BlendProcessorConfiguration_mt = Class(BlendProcessorConfiguration, ProcessorConfiguration)

---@param schema XMLSchema
---@param key string
function BlendProcessorConfiguration.registerXMLPaths(schema, key)
    ProcessorUnit.registerXMLPaths(schema, key .. '.output', false)
    ProcessorUnit.registerXMLPaths(schema, key .. '.output.input(?)', true)
end

---@param index number
---@param processor BlendProcessor
---@param customMt table | nil
---@return BlendProcessorConfiguration
function BlendProcessorConfiguration.new(index, processor, customMt)
    ---@type BlendProcessorConfiguration
    ---@diagnostic disable-next-line: assign-type-mismatch
    local self = ProcessorConfiguration.new(index, processor, customMt or BlendProcessorConfiguration_mt)

    self.inputs = {}

    return self
end

---@param xmlFile XMLFile
---@param key string
function BlendProcessorConfiguration:load(xmlFile, key)
    self:superClass().load(self, xmlFile, key)

    self.output = ProcessorUnit.new(self.processor, self)

    assert(self.output:load(xmlFile, key .. '.output'), string.format('Failed to load output: %s', key .. '.output'))

    self.fillUnitToUnit[self.output:getFillUnitIndex()] = self.output

    local totalRatio = 0

    xmlFile:iterate(key .. '.output.input', function(_, unitKey)
        local input = ProcessorUnit.new(self.processor, self)

        assert(input:load(xmlFile, unitKey), string.format('Failed to load input: %s', unitKey))
        assert(input.ratio ~= nil, string.format('Input ratio is undefined: %s', unitKey))

        local fillUnitIndex = input:getFillUnitIndex()

        if self.fillUnitToUnit[fillUnitIndex] ~= nil then
            Logging.xmlWarning(xmlFile, 'fillUnitIndex %d already in use: %s', fillUnitIndex, unitKey)
        end

        table.insert(self.inputs, input)

        self.fillUnitToUnit[fillUnitIndex] = input

        totalRatio = totalRatio + input.ratio
    end)

    assert(#self.inputs > 0, string.format('Could not find any inputs: %s', key))

    if totalRatio ~= 1.0 then
        Logging.xmlWarning(xmlFile, 'The total ratio of inputs (%s) does not add up to 1.0: %s', tostring(totalRatio), key .. '.output.input(?)')
    end
end

function BlendProcessorConfiguration:activate()
    self.output:activate()

    for _, input in ipairs(self.inputs) do
        input:activate()
    end
end

function BlendProcessorConfiguration:deactivate()
    self.output:deactivate()

    for _, input in ipairs(self.inputs) do
        input:deactivate()
    end
end

function BlendProcessorConfiguration:getPrimaryUnit()
    return self.output
end

function BlendProcessorConfiguration:getPrimaryUnitTypeName()
    return ProcessorGUI.L10N_TEXTS.OUTPUT
end

function BlendProcessorConfiguration:getSecondaryUnits()
    return self.inputs
end

function BlendProcessorConfiguration:getSecondaryUnitsTypeName()
    return ProcessorGUI.L10N_TEXTS.INPUT
end

function BlendProcessorConfiguration:getDialogTitle()
    return ProcessorGUI.L10N_TEXTS.TITLE_OUTPUT
end

function BlendProcessorConfiguration:getUnitsListTitle()
    return ProcessorGUI.L10N_TEXTS.INPUTS
end
