---@class SplitProcessorConfiguration : ProcessorConfiguration
---@field input ProcessorUnit
---@field outputs ProcessorUnit[]
---
---@field superClass fun(): ProcessorConfiguration
SplitProcessorConfiguration = {}

local SplitProcessorConfiguration_mt = Class(SplitProcessorConfiguration, ProcessorConfiguration)

---@param schema XMLSchema
---@param key string
function SplitProcessorConfiguration.registerXMLPaths(schema, key)
    ProcessorUnit.registerXMLPaths(schema, key .. '.input', false)
    ProcessorUnit.registerXMLPaths(schema, key .. '.input.output(?)', true)
end

---@param index number
---@param processor Processor
---@param customMt table | nil
---@return SplitProcessorConfiguration
function SplitProcessorConfiguration.new(index, processor, customMt)
    ---@type SplitProcessorConfiguration
    ---@diagnostic disable-next-line: assign-type-mismatch
    local self = ProcessorConfiguration.new(index, processor, customMt or SplitProcessorConfiguration_mt)

    self.outputs = {}

    return self
end

---@param xmlFile XMLFile
---@param key string
function SplitProcessorConfiguration:load(xmlFile, key)
    self:superClass().load(self, xmlFile, key)

    self.input = ProcessorUnit.new(self.processor, self)

    assert(self.input:load(xmlFile, key .. '.input'), string.format('Failed to load input: %s', key .. '.input'))

    self.fillUnitToUnit[self.input:getFillUnitIndex()] = self.input

    local totalRatio = 0

    xmlFile:iterate(key .. '.input.output', function(_, unitKey)
        local output = ProcessorUnit.new(self.processor, self)

        assert(output:load(xmlFile, unitKey), string.format('Failed to load output: %s', unitKey))
        assert(output.ratio ~= nil, string.format('Output ratio is undefined: %s', unitKey))

        local fillUnitIndex = output:getFillUnitIndex()

        if self.fillUnitToUnit[fillUnitIndex] ~= nil then
            Logging.xmlWarning(xmlFile, 'fillUnitIndex %d already in use: %s', fillUnitIndex, unitKey)
        end

        table.insert(self.outputs, output)

        self.fillUnitToUnit[fillUnitIndex] = output

        totalRatio = totalRatio + output.ratio
    end)

    assert(#self.outputs > 0, string.format('Could not find any outputs: %s', key .. '.input'))

    if totalRatio ~= 1.0 then
        Logging.xmlWarning(xmlFile, 'The total ratio of outputs (%s) does not add up to 1.0: %s', tostring(totalRatio), key .. '.input.output(?)')
    end
end

function SplitProcessorConfiguration:activate()
    self.input:activate()

    for _, output in ipairs(self.outputs) do
        output:activate()
    end
end

function SplitProcessorConfiguration:deactivate()
    self.input:deactivate()

    for _, output in ipairs(self.outputs) do
        output:deactivate()
    end
end

function SplitProcessorConfiguration:getPrimaryUnit()
    return self.input
end

function SplitProcessorConfiguration:getPrimaryUnitTypeName()
    return ProcessorGUI.L10N_TEXTS.INPUT
end

function SplitProcessorConfiguration:getSecondaryUnits()
    return self.outputs
end

function SplitProcessorConfiguration:getSecondaryUnitsTypeName()
    return ProcessorGUI.L10N_TEXTS.OUTPUT
end

function SplitProcessorConfiguration:getDialogTitle()
    return ProcessorGUI.L10N_TEXTS.TITLE_INPUT
end

function SplitProcessorConfiguration:getUnitsListTitle()
    return ProcessorGUI.L10N_TEXTS.OUTPUTS
end
