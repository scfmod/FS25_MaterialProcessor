---@class MaterialProcessorSpecialization
---@field processor Processor
---@field state number
---@field dirtyFlagState number
---@field actionEvents table
---@field dirtyFlagDischarge number

source(g_currentModDirectory .. 'scripts/specializations/events/SetDischargeNodeStateEvent.lua')
source(g_currentModDirectory .. 'scripts/specializations/events/SetDischargeNodeToGroundEvent.lua')
source(g_currentModDirectory .. 'scripts/specializations/events/SetProcessorConfigurationEvent.lua')

---@class MaterialProcessor : VehicleObject
MaterialProcessor = {}

---@type string
MaterialProcessor.SPEC_NAME = 'spec_' .. g_currentModName .. '.materialProcessor'
MaterialProcessor.MOD_NAME = g_currentModName

MaterialProcessor.ACTIONS = {
    SELECT_CONFIGURATION = 'SELECT_CONFIGURATION'
}

function MaterialProcessor.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(FillUnit, specializations)
end

function MaterialProcessor.initSpecialization()
    ---@type XMLSchema
    local schema = Vehicle.xmlSchema

    schema:setXMLSpecializationType('MaterialProcessor')

    schema:register(XMLValueType.STRING, 'vehicle.materialProcessor#type', 'Processor type (split / blend)', nil, true)

    Processor.registerXMLPaths(schema, 'vehicle.materialProcessor')
    SplitProcessor.registerXMLPaths(schema, 'vehicle.materialProcessor')
    BlendProcessor.registerXMLPaths(schema, 'vehicle.materialProcessor')

    schema:setXMLSpecializationType()

    ---@type XMLSchema
    local schemaSavegame = Vehicle.xmlSchemaSavegame

    schemaSavegame:setXMLSpecializationType('MaterialProcessor')

    Processor.registerSavegameXMLPaths(schemaSavegame, string.format('vehicles.vehicle(?).%s.materialProcessor', MaterialProcessor.MOD_NAME))

    schemaSavegame:setXMLSpecializationType()
end

function MaterialProcessor.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, 'getCanProcess', MaterialProcessor.getCanProcess)
    SpecializationUtil.registerFunction(vehicleType, 'getProcessor', MaterialProcessor.getProcessor)
    SpecializationUtil.registerFunction(vehicleType, 'setProcessorDischargeNodeState', MaterialProcessor.setProcessorDischargeNodeState)
    SpecializationUtil.registerFunction(vehicleType, 'setProcessorDischargeNodeToGround', MaterialProcessor.setProcessorDischargeNodeToGround)
    SpecializationUtil.registerFunction(vehicleType, 'getProcessorState', MaterialProcessor.getProcessorState)
    SpecializationUtil.registerFunction(vehicleType, 'setProcessorConfigurationIndex', MaterialProcessor.setProcessorConfigurationIndex)
    SpecializationUtil.registerFunction(vehicleType, 'setProcessorState', MaterialProcessor.setProcessorState)
end

function MaterialProcessor.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, 'onLoad', MaterialProcessor)
    SpecializationUtil.registerEventListener(vehicleType, 'onPostLoad', MaterialProcessor)
    SpecializationUtil.registerEventListener(vehicleType, 'onDelete', MaterialProcessor)

    SpecializationUtil.registerEventListener(vehicleType, 'onTurnedOn', MaterialProcessor)
    SpecializationUtil.registerEventListener(vehicleType, 'onTurnedOff', MaterialProcessor)

    SpecializationUtil.registerEventListener(vehicleType, 'onUpdate', MaterialProcessor)
    SpecializationUtil.registerEventListener(vehicleType, 'onUpdateTick', MaterialProcessor)

    SpecializationUtil.registerEventListener(vehicleType, 'onRegisterActionEvents', MaterialProcessor)

    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", MaterialProcessor)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", MaterialProcessor)
    SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", MaterialProcessor)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", MaterialProcessor)
end

function MaterialProcessor:onLoad()
    ---@type XMLFile
    local xmlFile = self.xmlFile

    ---@type MaterialProcessorSpecialization
    local spec = self[MaterialProcessor.SPEC_NAME]

    spec.state = Processor.STATE_OFF
    spec.dirtyFlagState = self:getNextDirtyFlag()
    spec.dirtyFlagDischarge = self:getNextDirtyFlag()

    local processorTypeName = xmlFile:getValue('vehicle.materialProcessor#type')

    if processorTypeName == SplitProcessor.TYPE_NAME then
        spec.processor = SplitProcessor.new(self)
    elseif processorTypeName == BlendProcessor.TYPE_NAME then
        spec.processor = BlendProcessor.new(self)
    else
        Logging.xmlError(xmlFile, 'Missing or invalid materialProcessor type "%s": vehicle.materialProcessor#type', tostring(processorTypeName))
        self.loadingState = VehicleLoadingState.ERROR
        return
    end

    spec.processor:load(xmlFile, 'vehicle.materialProcessor')
end

function MaterialProcessor:onDelete()
    ---@type MaterialProcessorSpecialization
    local spec = self[MaterialProcessor.SPEC_NAME]

    if spec.processor ~= nil then
        spec.processor:delete()
    end

    spec.processor = nil
end

function MaterialProcessor:onPostLoad(savegame)
    if self.isServer and savegame ~= nil and savegame.xmlFile.filename ~= nil then
        local key = savegame.key .. '.' .. MaterialProcessor.MOD_NAME .. '.materialProcessor'

        ---@type MaterialProcessorSpecialization
        local spec = self[MaterialProcessor.SPEC_NAME]

        spec.processor:loadFromXMLFile(savegame.xmlFile, key)
    end
end

---@param xmlFile XMLFile
---@param key string
function MaterialProcessor:saveToXMLFile(xmlFile, key)
    ---@type MaterialProcessorSpecialization
    local spec = self[MaterialProcessor.SPEC_NAME]

    spec.processor:saveToXMLFile(xmlFile, key)
end

---@return Processor
---@nodiscard
function MaterialProcessor:getProcessor()
    ---@type MaterialProcessorSpecialization
    local spec = self[MaterialProcessor.SPEC_NAME]

    return spec.processor
end

---@return number
---@nodiscard
function MaterialProcessor:getProcessorState()
    ---@type MaterialProcessorSpecialization
    local spec = self[MaterialProcessor.SPEC_NAME]

    return spec.state
end

---@param state number
function MaterialProcessor:setProcessorState(state)
    ---@type MaterialProcessorSpecialization
    local spec = self[MaterialProcessor.SPEC_NAME]

    if spec.state ~= state then
        spec.state = state

        if state == Processor.STATE_OFF then
            for _, node in ipairs(spec.processor.dischargeNodes) do
                node:setDischargeState(Dischargeable.DISCHARGE_STATE_OFF, g_server == nil)
            end
        end

        if self.isServer then
            self:raiseDirtyFlags(spec.dirtyFlagState)
        end
    end
end

---@return boolean
---@nodiscard
function MaterialProcessor:getCanProcess()
    ---@type MaterialProcessorSpecialization
    local spec = self[MaterialProcessor.SPEC_NAME]

    if spec.processor.needsToBePoweredOn and not self:getIsPowered() then
        return false
    elseif spec.processor.needsToBeTurnedOn and not self:getIsTurnedOn() then
        return false
    end

    return true
end

---@param index number
---@param state number
---@param noEventSend boolean | nil
function MaterialProcessor:setProcessorDischargeNodeState(index, state, noEventSend)
    ---@type MaterialProcessorSpecialization
    local spec = self[MaterialProcessor.SPEC_NAME]

    local node = spec.processor.dischargeNodes[index]

    if node ~= nil then
        node:setDischargeState(state, noEventSend)
    end
end

---@param index number
---@param noEventSend boolean | nil
function MaterialProcessor:setProcessorConfigurationIndex(index, noEventSend)
    ---@type MaterialProcessorSpecialization
    local spec = self[MaterialProcessor.SPEC_NAME]

    if spec.processor.configurations[index] ~= nil then
        if spec.processor.configurationIndex ~= index then
            SetProcessorConfigurationEvent.sendEvent(self, index, noEventSend)

            spec.processor:setConfiguration(index)
        end
    else
        Logging.warning('MaterialProcessor:setProcessorConfigurationIndex() Invalid index: %s', tostring(index))
    end
end

---@param canDischargeToGround boolean
---@param noEventSend boolean | nil
function MaterialProcessor:setProcessorDischargeNodeToGround(canDischargeToGround, noEventSend)
    ---@type MaterialProcessorSpecialization
    local spec = self[MaterialProcessor.SPEC_NAME]

    if spec.processor.canDischargeToGround ~= canDischargeToGround then
        SetDischargeNodeToGroundEvent.sendEvent(self, canDischargeToGround, noEventSend)

        spec.processor.canDischargeToGround = canDischargeToGround

        for _, node in ipairs(spec.processor.dischargeNodes) do
            node:setDischargeState(Dischargeable.DISCHARGE_STATE_OFF, noEventSend)
        end

        self:requestActionEventUpdate()
    end
end

---@param dt number
function MaterialProcessor:onUpdate(dt)
    ---@type MaterialProcessorSpecialization
    local spec = self[MaterialProcessor.SPEC_NAME]

    if spec.processor ~= nil then
        spec.processor:update(dt)
    end
end

---@param dt number
---@param isActiveForInput boolean
---@param isActiveForInputIgnoreSelection boolean
---@param isSelected boolean
function MaterialProcessor:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    ---@type MaterialProcessorSpecialization
    local spec = self[MaterialProcessor.SPEC_NAME]

    if spec.processor ~= nil then
        spec.processor:updateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    end
end

function MaterialProcessor:onTurnedOn()
    ---@type MaterialProcessorSpecialization
    local spec = self[MaterialProcessor.SPEC_NAME]

    if self.isServer and spec.processor.needsToBeTurnedOn then
        self:setProcessorState(Processor.STATE_ON)
    end
end

function MaterialProcessor:onTurnedOff()
    ---@type MaterialProcessorSpecialization
    local spec = self[MaterialProcessor.SPEC_NAME]

    if self.isServer and spec.processor.needsToBeTurnedOn then
        self:setProcessorState(Processor.STATE_OFF)
    end
end

---@param isActiveForInput boolean
---@param isActiveForInputIgnoreSelection boolean
function MaterialProcessor:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
    ---@type MaterialProcessorSpecialization
    local spec = self[MaterialProcessor.SPEC_NAME]

    if self.isClient then
        self:clearActionEventsTable(spec.actionEvents)

        if isActiveForInputIgnoreSelection then
            local _, actionId = self:addActionEvent(spec.actionEvents, InputAction.IMPLEMENT_EXTRA4, self, MaterialProcessor.actionEventOpenDialog, false, true, false, true)
            g_inputBinding:setActionEventTextPriority(actionId, GS_PRIO_NORMAL)
            g_inputBinding:setActionEventText(actionId, g_i18n:getText('action_changeConfiguration'))

            if spec.processor.canToggleDischargeToGround then
                _, actionId = self:addPoweredActionEvent(spec.actionEvents, InputAction.TOGGLE_TIPSTATE_GROUND, self, MaterialProcessor.actionEventToggleDischargeToGround, false, true, false, true, nil)
                g_inputBinding:setActionEventTextPriority(actionId, GS_PRIO_NORMAL)
            end

            MaterialProcessor.updateActionEvents(self)
        end
    end
end

function MaterialProcessor:updateActionEvents()
    ---@type MaterialProcessorSpecialization
    local spec = self[MaterialProcessor.SPEC_NAME]

    local action = spec.actionEvents[MaterialProcessor.ACTIONS.SELECT_CONFIGURATION]

    if action ~= nil then
        g_inputBinding:setActionEventTextVisibility(action.actionEventId, spec.processor:getHasConfigurations())
    end

    action = spec.actionEvents[InputAction.TOGGLE_TIPSTATE_GROUND]

    if action ~= nil then
        g_inputBinding:setActionEventTextVisibility(action.actionEventId, spec.processor.canToggleDischargeToGround == true)

        if spec.processor.canDischargeToGround then
            g_inputBinding:setActionEventText(action.actionEventId, g_i18n:getText('action_stopTipToGround'))
        else
            g_inputBinding:setActionEventText(action.actionEventId, g_i18n:getText('action_startTipToGround'))
        end
    end
end

function MaterialProcessor:actionEventOpenDialog()
    ---@type MaterialProcessorSpecialization
    local spec = self[MaterialProcessor.SPEC_NAME]

    g_processorConfigurationDialog:show(spec.processor)
end

function MaterialProcessor:actionEventToggleDischargeToGround()
    ---@type MaterialProcessorSpecialization
    local spec = self[MaterialProcessor.SPEC_NAME]

    self:setProcessorDischargeNodeToGround(not spec.processor.canDischargeToGround)
end

---@param streamId number
---@param connection Connection
function MaterialProcessor:onWriteStream(streamId, connection)
    ---@type MaterialProcessorSpecialization
    local spec = self[MaterialProcessor.SPEC_NAME]

    streamWriteUIntN(streamId, spec.state, Processor.SEND_NUM_BITS_STATE)
    streamWriteUIntN(streamId, spec.processor.configurationIndex, Processor.SEND_NUM_BITS_INDEX)
    streamWriteBool(streamId, spec.processor.canDischargeToGround)

    for _, dischargeNode in ipairs(spec.processor.dischargeNodes) do
        dischargeNode:writeStream(streamId, connection)
    end
end

---@param streamId number
---@param connection Connection
function MaterialProcessor:onReadStream(streamId, connection)
    ---@type MaterialProcessorSpecialization
    local spec = self[MaterialProcessor.SPEC_NAME]

    self:setProcessorState(streamReadUIntN(streamId, Processor.SEND_NUM_BITS_STATE))
    self:setProcessorConfigurationIndex(streamReadUIntN(streamId, Processor.SEND_NUM_BITS_INDEX), true)

    spec.processor.canDischargeToGround = streamReadBool(streamId)

    for _, dischargeNode in ipairs(spec.processor.dischargeNodes) do
        dischargeNode:readStream(streamId, connection)
    end
end

---@param streamId number
---@param connection Connection
---@param dirtyMask number
function MaterialProcessor:onWriteUpdateStream(streamId, connection, dirtyMask)
    ---@type MaterialProcessorSpecialization
    local spec = self[MaterialProcessor.SPEC_NAME]

    if not connection:getIsServer() then
        if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlagState) ~= 0) then
            streamWriteUIntN(streamId, spec.state, Processor.SEND_NUM_BITS_STATE)
        end

        if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlagDischarge) ~= 0) then
            for _, dischargeNode in ipairs(spec.processor.dischargeNodes) do
                dischargeNode:writeUpdateStream(streamId, connection)
            end
        end
    end
end

---@param streamId number
---@param timestamp number
---@param connection Connection
function MaterialProcessor:onReadUpdateStream(streamId, timestamp, connection)
    ---@type MaterialProcessorSpecialization
    local spec = self[MaterialProcessor.SPEC_NAME]

    if connection:getIsServer() then
        if streamReadBool(streamId) then
            self:setProcessorState(streamReadUIntN(streamId, Processor.SEND_NUM_BITS_STATE))
        end

        if streamReadBool(streamId) then
            for _, dischargeNode in ipairs(spec.processor.dischargeNodes) do
                dischargeNode:readUpdateStream(streamId, connection)
            end
        end
    end
end
