---@class ProcessorGUI
---@field enableHud boolean
ProcessorGUI = {}

ProcessorGUI.PROFILES_FILENAME = g_currentModDirectory .. 'xml/guiProfiles.xml'
ProcessorGUI.USER_SETTINGS_FILENAME = g_currentModSettingsDirectory .. 'userSettings.xml'
ProcessorGUI.MOD_SETTINGS_FOLDER = g_currentModSettingsDirectory
ProcessorGUI.TEXTURE_CONFIG_FILENAME = g_currentModDirectory .. 'textures/ui_elements.xml'

ProcessorGUI.L10N_TEXTS = {
    TITLE_INPUT = g_i18n:getText('ui_dialogTitleInput'),
    TITLE_OUTPUT = g_i18n:getText('ui_dialogTitleOutput'),
    INPUT = g_i18n:getText('ui_input'),
    INPUTS = g_i18n:getText('ui_inputs'),
    OUTPUT = g_i18n:getText('ui_output'),
    OUTPUTS = g_i18n:getText('ui_outputs'),
    ENABLE_HUD = g_i18n:getText('action_enableHud'),
    DISABLE_HUD = g_i18n:getText('action_disableHud'),
}

local ProcessorGUI_mt = Class(ProcessorGUI)

function ProcessorGUI.new()
    ---@type ProcessorGUI
    local self = setmetatable({}, ProcessorGUI_mt)

    self.enableHud = true

    if g_debugMaterialProcessor then
        addConsoleCommand('procReloadGui', '', 'consoleReloadGui', self)
        addConsoleCommand('procToggleOption', '', 'consoleToggleOption', self)
    end

    return self
end

function ProcessorGUI:consoleReloadGui()
    self:reload()

    return 'GUI reloaded'
end

function ProcessorGUI:consoleToggleOption(name)
    local processor

    if g_processorConfigurationDialog.isOpen then
        processor = g_processorConfigurationDialog.processor
    end

    if processor == nil then
        return 'Active processor not found'
    end

    if name == 'canDischargeToAnyObject' then
        processor.canDischargeToAnyObject = not processor.canDischargeToAnyObject
        return 'canDischargeToAnyObject: ' .. tostring(processor.canDischargeToAnyObject)
    elseif name == 'canDischargeToGroundAnywhere' then
        processor.canDischargeToGroundAnywhere = not processor.canDischargeToGroundAnywhere
        return 'canDischargeToGroundAnywhere: ' .. tostring(processor.canDischargeToGroundAnywhere)
    end

    return 'Unknown option, available options: canDischargeToAnyObject, canDischargeToGroundAnywhere'
end

---@param enabled boolean
function ProcessorGUI:setEnableHUD(enabled)
    if self.enableHud ~= enabled then
        self.enableHud = enabled

        self:saveUserSettings()
    end
end

function ProcessorGUI:load()
    g_overlayManager.textureConfigs['materialProcessor'] = nil
    g_overlayManager:addTextureConfigFile(ProcessorGUI.TEXTURE_CONFIG_FILENAME, 'materialProcessor')

    g_gui.currentlyReloading = true

    self:loadProfiles()
    self:loadDialogs()

    g_gui.currentlyReloading = false

    self:loadUserSettings()
end

function ProcessorGUI:delete()
    if g_processorConfigurationDialog.isOpen then
        g_processorConfigurationDialog:close()
    end

    g_processorConfigurationDialog:delete()
end

function ProcessorGUI:reload()
    Logging.info('Reloading GUI ..')

    local selectedProcessor

    if g_processorConfigurationDialog.isOpen then
        selectedProcessor = g_processorConfigurationDialog.processor
    end

    g_gui.currentlyReloading = true

    self:delete()
    self:loadProfiles()
    self:loadDialogs()

    g_gui.currentlyReloading = false

    g_processorHud:reload()

    if selectedProcessor then
        g_processorConfigurationDialog:show(selectedProcessor)
    end
end

function ProcessorGUI:loadProfiles()
    if not g_gui:loadProfiles(ProcessorGUI.PROFILES_FILENAME) then
        Logging.error('Failed to load profiles: %s', ProcessorGUI.PROFILES_FILENAME)
    end
end

function ProcessorGUI:loadDialogs()
    ---@diagnostic disable-next-line: lowercase-global
    g_processorConfigurationDialog = ProcessorConfigurationDialog.new()
    g_processorConfigurationDialog:load()
end

function ProcessorGUI:loadUserSettings()
    ---@type XMLFile | nil
    local xmlFile = XMLFile.loadIfExists('materialProcessorUserSettings', ProcessorGUI.USER_SETTINGS_FILENAME)

    if xmlFile ~= nil then
        self.enableHud = xmlFile:getBool('userSettings.enableHud', self.enableHud)

        xmlFile:delete()
    end
end

function ProcessorGUI:saveUserSettings()
    createFolder(ProcessorGUI.MOD_SETTINGS_FOLDER)

    ---@type XMLFile | nil
    local xmlFile = XMLFile.create('materialProcessorUserSettings', ProcessorGUI.USER_SETTINGS_FILENAME, 'userSettings')

    if xmlFile ~= nil then
        xmlFile:setBool('userSettings.enableHud', self.enableHud)

        xmlFile:save()
        xmlFile:delete()
    end
end
