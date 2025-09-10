source(g_currentModDirectory .. 'scripts/gui/ProcessorDialog.lua')

---@class ModGui
ModGui = {}

ModGui.MOD_SETTINGS_FOLDER = g_currentModSettingsDirectory
ModGui.PROFILES_FILENAME = g_currentModDirectory .. 'xml/guiProfiles.xml'
ModGui.TEXTURE_CONFIG_FILENAME = g_currentModDirectory .. 'textures/ui_elements.xml'


ModGui.L10N_TEXTS = {
    TITLE_INPUT = g_i18n:getText('ui_dialogTitleInput'),
    TITLE_OUTPUT = g_i18n:getText('ui_dialogTitleOutput'),
    INPUT = g_i18n:getText('ui_input'),
    INPUTS = g_i18n:getText('ui_inputs'),
    OUTPUT = g_i18n:getText('ui_output'),
    OUTPUTS = g_i18n:getText('ui_outputs'),
    ENABLE_HUD = g_i18n:getText('action_enableHud'),
    DISABLE_HUD = g_i18n:getText('action_disableHud'),
}


local ModGui_mt = Class(ModGui)

---@return ModGui
---@nodiscard
function ModGui.new()
    ---@type ModGui
    local self = setmetatable({}, ModGui_mt)

    if g_client ~= nil then
        addConsoleCommand('mprocReloadGui', '', 'consoleReloadGui', self)
    end

    return self
end

function ModGui:delete()
    if g_processorDialog.isOpen then
        g_processorDialog:close()
    end

    g_gui:showGui(nil)

    g_processorDialog:delete()
end

function ModGui:load()
    g_gui.currentlyReloading = true

    self:loadProfiles()
    self:loadDialogs()

    g_gui.currentlyReloading = false
end

function ModGui:loadProfiles()
    g_gui:loadProfiles(ModGui.PROFILES_FILENAME)
end

function ModGui:loadDialogs()
    ---@diagnostic disable-next-line: lowercase-global
    g_processorDialog = ProcessorDialog.new()
    g_processorDialog:load()
end

function ModGui:reload()
    local currentProcessor = g_processorDialog.processor

    g_gui.currentlyReloading = true

    self:delete()
    self:load()
    g_modHud:reload()

    g_gui.currentlyReloading = false

    if currentProcessor ~= nil then
        g_processorDialog:show(currentProcessor)
    end
end

function ModGui:consoleReloadGui()
    if g_server ~= nil and not g_currentMission.missionDynamicInfo.isMultiplayer then
        self:reload()

        return 'Reloaded GUI'
    end

    return 'Only available in single player'
end

---@diagnostic disable-next-line: lowercase-global
g_modGui = ModGui.new()
