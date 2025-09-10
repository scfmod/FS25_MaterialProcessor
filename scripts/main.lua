g_overlayManager:addTextureConfigFile(g_currentModDirectory .. 'textures/ui_elements.xml', 'materialProcessor', nil)

source(g_currentModDirectory .. 'scripts/ModGui.lua')
source(g_currentModDirectory .. 'scripts/ModHud.lua')
source(g_currentModDirectory .. 'scripts/ModSettings.lua')

source(g_currentModDirectory .. 'scripts/Configuration.lua')
source(g_currentModDirectory .. 'scripts/ConfigurationUnit.lua')
source(g_currentModDirectory .. 'scripts/DischargeNode.lua')
source(g_currentModDirectory .. 'scripts/Processor.lua')
source(g_currentModDirectory .. 'scripts/ProcessorUtils.lua')

source(g_currentModDirectory .. 'scripts/processors/BlendProcessor.lua')
source(g_currentModDirectory .. 'scripts/processors/BlendConfiguration.lua')
source(g_currentModDirectory .. 'scripts/processors/SplitProcessor.lua')
source(g_currentModDirectory .. 'scripts/processors/SplitConfiguration.lua')

source(g_currentModDirectory .. 'scripts/extensions/InteractiveControlExtension.lua')

if g_client ~= nil then
    g_modSettings:loadUserSettings()
    g_modGui:load()
    g_modHud:load()
end

source(g_currentModDirectory .. 'scripts/ModController.lua')
