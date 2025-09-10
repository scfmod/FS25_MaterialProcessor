---@class BlendConfiguration : Configuration
---@field output ConfigurationUnit
---@field inputs ConfigurationUnit[]
---@field superClass fun(): Configuration
BlendConfiguration = {}

local BlendConfiguration_mt = Class(BlendConfiguration, Configuration)

---@param schema XMLSchema
---@param key string
function BlendConfiguration.registerXMLPaths(schema, key)
    ConfigurationUnit.registerXMLPaths(schema, key .. '.output', false)
    ConfigurationUnit.registerXMLPaths(schema, key .. '.output.input(?)', true)
end

---@param index number
---@param processor Processor
---@param customMt? table
---@return BlendConfiguration
---@nodiscard
function BlendConfiguration.new(index, processor, customMt)
    local self = Configuration.new(index, processor, customMt or BlendConfiguration_mt)
    ---@cast self BlendConfiguration

    self.inputs = {}

    return self
end

---@param xmlFile XMLFile
---@param key string
---@return boolean
---@nodiscard
function BlendConfiguration:load(xmlFile, key)
    self:superClass().load(self, xmlFile, key)

    self.output = ConfigurationUnit.new(self.processor, self)

    if not self.output:load(xmlFile, key .. '.output') then
        Logging.xmlError(xmlFile, 'Failed to load output (%s)', key .. '.output')
        return false
    end

    self.fillUnitToConfigurationUnit[self.output.fillUnit.fillUnitIndex] = self.output

    xmlFile:iterate(key .. '.output.input', function (_, unitKey)
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

    return true
end

function BlendConfiguration:getUnit()
    return self.output
end

function BlendConfiguration:getUnitTitle()
    return ModGui.L10N_TEXTS.OUTPUTS
end

function BlendConfiguration:getUnitTypeName()
    return ModGui.L10N_TEXTS.OUTPUT
end

function BlendConfiguration:getUnits()
    return self.inputs
end

function BlendConfiguration:getUnitsTitle()
    return ModGui.L10N_TEXTS.INPUTS
end

function BlendConfiguration:getUnitsTypeName()
    return ModGui.L10N_TEXTS.INPUT
end
