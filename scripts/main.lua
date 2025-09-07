---@diagnostic disable-next-line: lowercase-global
g_materialProcessorUIFilename = g_currentModDirectory .. 'textures/ui_elements.png'

---@param path string
local function load(path)
    source(g_currentModDirectory .. 'scripts/' .. path)
end

---@diagnostic disable-next-line: lowercase-global
g_debugMaterialProcessor = fileExists(g_currentModDirectory .. 'scripts/debug.lua')

local generateSchema = false

if generateSchema then
    load('schema.lua')
end

-- Utils
load('utils/ProcessorUtils.lua')

-- Base classes
load('Processor.lua')
load('ProcessorConfiguration.lua')
load('ProcessorDischargeNode.lua')
load('ProcessorUnit.lua')

-- Processor types
load('processorTypes/BlendProcessor.lua')
load('processorTypes/BlendProcessorConfiguration.lua')
load('processorTypes/SplitProcessor.lua')
load('processorTypes/SplitProcessorConfiguration.lua')

-- GUI
load('gui/ProcessorGUI.lua')
load('gui/dialogs/ProcessorConfigurationDialog.lua')

-- HUD
load('hud/ProcessorHUD.lua')

-- Base game extensions
load('extensions/GuiOverlayExtension.lua')
load('extensions/InteractiveControlExtension.lua')

---@diagnostic disable-next-line: lowercase-global
g_processorGui = ProcessorGUI.new()

---@diagnostic disable-next-line: lowercase-global
g_processorHud = ProcessorHUD.new()

if g_client ~= nil then
    g_processorGui:load()
    g_processorHud:load()
end
