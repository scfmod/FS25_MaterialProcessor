---@class InteractiveFunctions
---@field addFunction fun(name: string, params: InteractiveFunctionsParams)

---@class InteractiveFunctionsParams
---@field posFunc fun(target: MaterialProcessor, data: any, noEventSend: boolean | nil)
---@field negFunc? fun(target: MaterialProcessor, data: any, noEventSend: boolean | nil)
---@field updateFunc? fun(target: MaterialProcessor): boolean | nil
---@field isBlockedFunc? fun(target: MaterialProcessor): boolean

---@class InteractiveControlExtension
InteractiveControlExtension = {}

local InteractiveControlExtension_mt = Class(InteractiveControlExtension)

---@return InteractiveControlExtension
---@nodiscard
function InteractiveControlExtension.new()
    ---@type InteractiveControlExtension
    local self = setmetatable({}, InteractiveControlExtension_mt)

    return self
end

function InteractiveControlExtension:registerFunctions()
    local modName = 'FS25_interactiveControl'

    if g_modIsLoaded[modName] then
        local modEnv = _G[modName]
        ---@type InteractiveFunctions | nil
        local InteractiveFunctions = modEnv['InteractiveFunctions']

        if InteractiveFunctions ~= nil then
            Logging.info('Found "InteractiveFunctions", adding functions')

            self:registerToggleDischargeToGroundFunction(InteractiveFunctions)
            self:registerConfigurationFunction(InteractiveFunctions)
        else
            Logging.warning('Could not find "InteractiveFunctions"')
        end
    end
end

---@param icf InteractiveFunctions
function InteractiveControlExtension:registerConfigurationFunction(icf)
    if icf.addFunction('PROCESSOR_CONTROL_PANEL',
            {
                posFunc = function (target)
                    ---@type MaterialProcessor_spec
                    local spec = target[MaterialProcessor.SPEC_NAME]

                    if spec ~= nil then
                        MaterialProcessor.actionEventOpenDialog(target)
                    end
                end,
                isBlockedFunc = function (target)
                    ---@type MaterialProcessor_spec
                    local spec = target[MaterialProcessor.SPEC_NAME]

                    if spec ~= nil then
                        return #spec.processor.configurations > 0
                    end

                    return false
                end
            }
        ) then
        Logging.info('Registered interactiveControl function "PROCESSOR_CONFIGURATION"')
    end
end

---@param icf InteractiveFunctions
function InteractiveControlExtension:registerToggleDischargeToGroundFunction(icf)
    if icf.addFunction('PROCESSOR_TOGGLE_DISCHARGE_GROUND',
            {
                posFunc = function (target)
                    ---@type MaterialProcessor_spec
                    local spec = target[MaterialProcessor.SPEC_NAME]

                    if spec ~= nil and spec.processor.canToggleDischargeToGround then
                        MaterialProcessor.actionEventToggleDischargeToGround(target)
                    end
                end,
                updateFunc = function (target)
                    ---@type MaterialProcessor_spec
                    local spec = target[MaterialProcessor.SPEC_NAME]

                    if spec ~= nil then
                        return spec.processor.canDischargeToGround
                    end
                end,
                isBlockedFunc = function (target)
                    ---@type MaterialProcessor_spec
                    local spec = target[MaterialProcessor.SPEC_NAME]

                    return spec ~= nil and spec.processor.canToggleDischargeToGround
                end
            }
        ) then
        Logging.info('Registered interactiveControl function "PROCESSOR_TOGGLE_DISCHARGE_GROUND"')
    end
end

---@diagnostic disable-next-line: lowercase-global
g_interactiveControlExtension = InteractiveControlExtension.new()
