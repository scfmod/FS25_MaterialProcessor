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
            Logging.info('[FS25_materialProcessor] Found "InteractiveFunctions", adding functions')

            self:registerToggleDischargeToGroundFunction(InteractiveFunctions)
            self:registerConfigurationFunction(InteractiveFunctions)
        else
            Logging.warning('Could not find "InteractiveFunctions"')
        end
    end
end

---@param icf InteractiveFunctions
function InteractiveControlExtension:registerConfigurationFunction(icf)
    icf.addFunction('PROCESSOR_CONFIGURATION', {
        posFunc = function (target)
            ---@type MaterialProcessorSpecialization
            local spec = target[MaterialProcessor.SPEC_NAME]

            if spec ~= nil then
                MaterialProcessor.actionEventOpenDialog(target)
            end
        end,
        isBlockedFunc = function (target)
            ---@type MaterialProcessorSpecialization
            local spec = target[MaterialProcessor.SPEC_NAME]

            if spec ~= nil then
                return #spec.processor.configurations > 0
            end

            return false
        end
    })

    Logging.info('Registered interactiveControl function "PROCESSOR_CONFIGURATION"')
end

---@param icf InteractiveFunctions
function InteractiveControlExtension:registerToggleDischargeToGroundFunction(icf)
    icf.addFunction('PROCESSOR_TOGGLE_DISCHARGE_GROUND', {
        posFunc = function (target)
            ---@type MaterialProcessorSpecialization
            local spec = target[MaterialProcessor.SPEC_NAME]

            if spec ~= nil and spec.processor.canToggleDischargeToGround then
                target:setProcessorDischargeNodeToGround(not spec.processor.canDischargeToGround)
            end
        end,
        updateFunc = function (target)
            ---@type MaterialProcessorSpecialization
            local spec = target[MaterialProcessor.SPEC_NAME]

            if spec ~= nil then
                return spec.processor.canDischargeToGround
            end
        end,
        isBlockedFunc = function (target)
            ---@type MaterialProcessorSpecialization
            local spec = target[MaterialProcessor.SPEC_NAME]

            return spec ~= nil and spec.processor.canToggleDischargeToGround
        end
    })

    Logging.info('Registered interactiveControl function "PROCESSOR_TOGGLE_DISCHARGE_GROUND"')
end

---@diagnostic disable-next-line: lowercase-global
g_interactiveControlExtension = InteractiveControlExtension.new()

---@diagnostic disable-next-line: undefined-global
g_onCreateUtil.activateOnCreateFunctions = Utils.appendedFunction(g_onCreateUtil.activateOnCreateFunctions,
    function ()
        g_interactiveControlExtension:registerFunctions()
    end
)
