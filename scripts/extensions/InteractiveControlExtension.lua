---@class InteractiveFunctions
---@field addFunction fun(name: string, params: InteractiveFunctionsParams)

---@class InteractiveFunctionsParams
---@field posFunc fun(target: MaterialProcessor, data: any, noEventSend: boolean | nil)
---@field negFunc? fun(target: MaterialProcessor, data: any, noEventSend: boolean | nil)
---@field updateFunc? fun(target: MaterialProcessor): boolean?
---@field isBlockedFunc? fun(target: MaterialProcessor): boolean?

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
                posFunc = function (target, data, noEventSend)
                    if noEventSend then
                        return
                    end

                    if target.isClient and target[MaterialProcessor.SPEC_NAME] ~= nil then
                        MaterialProcessor.actionEventOpenDialog(target)
                    end
                end,
                isBlockedFunc = function (target)
                    if g_client ~= nil and target.getProcessor ~= nil then
                        local processor = target:getProcessor()

                        return #processor.configurations > 0
                    end

                    return nil
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
                posFunc = function (target, data, noEventSend)
                    if noEventSend then
                        return
                    end

                    if target.getProcessor ~= nil then
                        local processor = target:getProcessor()

                        if processor.canToggleDischargeToGround then
                            MaterialProcessor.actionEventToggleDischargeToGround(target)
                        end
                    end
                end,
                updateFunc = function (target)
                    if target.getProcessor ~= nil then
                        local processor = target:getProcessor()

                        return processor.canDischargeToGround
                    end

                    return nil
                end,
                isBlockedFunc = function (target)
                    if target.getProcessor ~= nil then
                        local processor = target:getProcessor()

                        return processor.canToggleDischargeToGround
                    end

                    return nil
                end
            }
        ) then
        Logging.info('Registered interactiveControl function "PROCESSOR_TOGGLE_DISCHARGE_GROUND"')
    end
end

---@diagnostic disable-next-line: lowercase-global
g_interactiveControlExtension = InteractiveControlExtension.new()
