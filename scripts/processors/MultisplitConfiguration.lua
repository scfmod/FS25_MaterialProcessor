---@class MultisplitConfiguration : Configuration
---@field litersPerMs number
---@field inputs ConfigurationUnit[]
---@field outputs ConfigurationUnit[]
---@field superClass fun(): Configuration
MultisplitConfiguration = {}

local MultisplitConfiguration_mt = Class(MultisplitConfiguration, Configuration)

---@param schema XMLSchema
---@param key string
function MultisplitConfiguration.registerXMLPaths(schema, key)
    ConfigurationUnit.registerXMLPaths(schema, key .. '.inputs.input(?)', true)
    ConfigurationUnit.registerXMLPaths(schema, key .. '.outputs.output(?)', true)
end

---@param index number
---@param processor Processor
---@param customMt? table
---@return MultisplitConfiguration
---@nodiscard
function MultisplitConfiguration.new(index, processor, customMt)
    local self = Configuration.new(index, processor, customMt or MultisplitConfiguration_mt)
    ---@cast self MultisplitConfiguration

    self.inputs = {}
    self.outputs = {}

    return self
end

---@param xmlFile XMLFile
---@param key string
---@return boolean
---@nodiscard
function MultisplitConfiguration:load(xmlFile, key)
    self:superClass().load(self, xmlFile, key)

    xmlFile:iterate(key .. '.inputs.input', function (_, unitKey)
        local input = ConfigurationUnit.new(self.processor, self)

        if not input:load(xmlFile, unitKey) then
            Logging.xmlError(xmlFile, 'Failed to load input (%s)', unitKey)
            return
        end

        if input.ratio == 0 then
            Logging.xmlWarning(xmlFile, 'Input ratio is zero (%s)', unitKey .. '#ratio')
        end

        local fillUnitIndex = input.fillUnit.fillUnitIndex

        if self.fillUnitToConfigurationUnit[fillUnitIndex] ~= nil then
            Logging.xmlWarning(xmlFile, 'fillUnitIndex %d already registered (%s)', fillUnitIndex, unitKey .. '#fillUnit')
        end

        table.insert(self.inputs, input)
        self.fillUnitToConfigurationUnit[fillUnitIndex] = input
    end)

    xmlFile:iterate(key .. '.outputs.output', function (_, unitKey)
        local output = ConfigurationUnit.new(self.processor, self)

        if not output:load(xmlFile, unitKey) then
            Logging.xmlError(xmlFile, 'Failed to load output (%s)', unitKey)
            return
        end

        if output.ratio == 0 then
            Logging.xmlWarning(xmlFile, 'Output ratio is zero (%s)', unitKey .. '#ratio')
        end

        local fillUnitIndex = output.fillUnit.fillUnitIndex

        if self.fillUnitToConfigurationUnit[fillUnitIndex] ~= nil then
            Logging.xmlWarning(xmlFile, 'fillUnitIndex %d already registered (%s)', fillUnitIndex, unitKey .. '#fillUnit')
        end

        table.insert(self.outputs, output)
        self.fillUnitToConfigurationUnit[fillUnitIndex] = output
    end)

    return true
end

function MultisplitConfiguration:getUnit()
    return self.inputs[1]
end

function MultisplitConfiguration:getUnitTitle()
    return ModGui.L10N_TEXTS.INPUTS
end

function MultisplitConfiguration:getUnitTypeName()
    return ModGui.L10N_TEXTS.INPUT
end

function MultisplitConfiguration:getUnits()
    return self.outputs
end

function MultisplitConfiguration:getUnitsTitle()
    return ModGui.L10N_TEXTS.OUTPUTS
end

function MultisplitConfiguration:getUnitsTypeName()
    return ModGui.L10N_TEXTS.OUTPUT
end
