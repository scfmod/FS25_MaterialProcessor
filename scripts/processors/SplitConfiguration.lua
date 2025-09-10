---@class SplitConfiguration : Configuration
---@field litersPerMs number
---@field input ConfigurationUnit
---@field outputs ConfigurationUnit[]
---@field superClass fun(): Configuration
SplitConfiguration = {}

local SplitConfiguration_mt = Class(SplitConfiguration, Configuration)

---@param schema XMLSchema
---@param key string
function SplitConfiguration.registerXMLPaths(schema, key)
    ConfigurationUnit.registerXMLPaths(schema, key .. '.input', false)
    ConfigurationUnit.registerXMLPaths(schema, key .. '.input.output(?)', true)
end

---@param index number
---@param processor Processor
---@param customMt? table
---@return SplitConfiguration
---@nodiscard
function SplitConfiguration.new(index, processor, customMt)
    local self = Configuration.new(index, processor, customMt or SplitConfiguration_mt)
    ---@cast self SplitConfiguration

    self.outputs = {}

    return self
end

---@param xmlFile XMLFile
---@param key string
---@return boolean
---@nodiscard
function SplitConfiguration:load(xmlFile, key)
    self:superClass().load(self, xmlFile, key)

    self.input = ConfigurationUnit.new(self.processor, self)

    if not self.input:load(xmlFile, key .. '.input') then
        Logging.xmlError(xmlFile, 'Failed to load input (%s)', key .. '.input')
        return false
    end

    self.fillUnitToConfigurationUnit[self.input.fillUnit.fillUnitIndex] = self.input

    xmlFile:iterate(key .. '.input.output', function (_, unitKey)
        -- Legacy compatibility
        if xmlFile:getBool(unitKey .. '#discard') == true then
            return
        end

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

function SplitConfiguration:getUnit()
    return self.input
end

function SplitConfiguration:getUnitTitle()
    return ModGui.L10N_TEXTS.INPUTS
end

function SplitConfiguration:getUnitTypeName()
    return ModGui.L10N_TEXTS.INPUT
end

function SplitConfiguration:getUnits()
    return self.outputs
end

function SplitConfiguration:getUnitsTitle()
    return ModGui.L10N_TEXTS.OUTPUTS
end

function SplitConfiguration:getUnitsTypeName()
    return ModGui.L10N_TEXTS.OUTPUT
end
