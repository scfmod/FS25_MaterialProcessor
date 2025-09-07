local function inj_GuiOverlay_loadOverlay(self, superFunc, overlay, ...)
    ---@type Overlay
    local result_overlay = superFunc(self, overlay, ...)

    if overlay ~= nil and result_overlay ~= nil then
        if overlay.filename == 'g_materialProcessorUIFilename' then
            result_overlay.filename = g_materialProcessorUIFilename
        end
    end

    return result_overlay
end

GuiOverlay.loadOverlay = Utils.overwrittenFunction(GuiOverlay.loadOverlay, inj_GuiOverlay_loadOverlay)
