---@class ModController
ModController = {}

function ModController:loadMap()
end

---@param self nil
function ModController:loadMods()
    g_interactiveControlExtension:registerFunctions()
end

addModEventListener(ModController)

---@diagnostic disable-next-line: undefined-global
g_onCreateUtil.activateOnCreateFunctions = Utils.appendedFunction(g_onCreateUtil.activateOnCreateFunctions, ModController.loadMods)
