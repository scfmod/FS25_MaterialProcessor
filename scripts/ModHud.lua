source(g_currentModDirectory .. 'scripts/hud/HUDProcessorUnitDisplayElement.lua')

---@class ModHud
---@field unitDisplay HUDProcessorUnitDisplayElement
---@field currentProcessor Processor?
ModHud = {}

local ModHud_mt = Class(ModHud)

---@return ModHud
---@nodiscard
function ModHud.new()
    ---@type ModHud
    local self = setmetatable({}, ModHud_mt)

    self.unitDisplay = HUDProcessorUnitDisplayElement.new()

    if g_client ~= nil then
        g_messageCenter:subscribeOneshot(MessageType.CURRENT_MISSION_START, function ()
            self:activate()
        end)
    end

    return self
end

function ModHud:delete()
    self:deactivate()

    self.unitDisplay:delete()
end

function ModHud:load()
    g_gui.currentlyReloading = true
    self.unitDisplay:load()
    g_gui.currentlyReloading = false
end

function ModHud:reload()
    self:delete()
    self.unitDisplay = HUDProcessorUnitDisplayElement.new()
    self:load()
    self:activate()
end

function ModHud:activate()
    g_currentMission:addUpdateable(self)
    g_currentMission:addDrawable(self)
end

function ModHud:deactivate()
    g_currentMission:removeUpdateable(self)
    g_currentMission:removeDrawable(self)

    self.processor = nil
end

---@param dt number
function ModHud:update(dt)
    local vehicle = g_localPlayer:getCurrentVehicle()
    ---@cast vehicle MaterialProcessor | nil

    if vehicle ~= nil and vehicle.getProcessor ~= nil then
        self.currentProcessor = vehicle:getProcessor()
    else
        self.currentProcessor = nil
    end
end

function ModHud:draw()
    if g_modSettings.enableHud and self.currentProcessor ~= nil then
        local configuration = self.currentProcessor.currentConfiguration

        if configuration ~= nil then
            self.unitDisplay:setDisabled(false)
            self.unitDisplay:drawUnit(configuration:getUnit(), configuration:getUnitTypeName())
            self.unitDisplay:setDisabled(true)

            local title = configuration:getUnitsTypeName()

            for _, unit in ipairs(configuration:getUnits()) do
                if unit.visible then
                    self.unitDisplay:drawUnit(unit, title)
                end
            end
        end
    end
end

---@diagnostic disable-next-line: lowercase-global
g_modHud = ModHud.new()
