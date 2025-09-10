---@class ModSettings
---@field enableHud boolean
ModSettings = {}

ModSettings.MOD_SETTINGS_FOLDER = g_currentModSettingsDirectory
ModSettings.XML_FILENAME_USER_SETTINGS = g_currentModSettingsDirectory .. 'userSettings.xml'

local ModSettings_mt = Class(ModSettings)

---@return ModSettings
---@nodiscard
function ModSettings.new()
    ---@type ModSettings
    local self = setmetatable({}, ModSettings_mt)

    self.enableHud = true

    return self
end

---@param enabled boolean
function ModSettings:setEnableHud(enabled)
    self.enableHud = enabled

    self:saveUserSettings()
end

function ModSettings:loadUserSettings()
    if g_client ~= nil then
        ---@type XMLFile | nil
        local xmlFile = XMLFile.loadIfExists('userSettings', ModSettings.XML_FILENAME_USER_SETTINGS)

        if xmlFile ~= nil then
            self.enableHud = xmlFile:getBool('userSettings.enableHud', self.enableHud)

            xmlFile:delete()
        end
    end
end

function ModSettings:saveUserSettings()
    if g_client ~= nil then
        createFolder(ModSettings.MOD_SETTINGS_FOLDER)

        ---@type XMLFile | nil
        local xmlFile = XMLFile.create('userSettings', ModSettings.XML_FILENAME_USER_SETTINGS, 'userSettings')

        if xmlFile ~= nil then
            xmlFile:setBool('userSettings.enableHud', self.enableHud)

            xmlFile:save()
            xmlFile:delete()
        end
    end
end

---@diagnostic disable-next-line: lowercase-global
g_modSettings = ModSettings.new()
