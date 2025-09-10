source(g_currentModDirectory .. 'scripts/specializations/events/SetDischargeNodeStateEvent.lua')
source(g_currentModDirectory .. 'scripts/specializations/events/SetDischargeNodeToGroundEvent.lua')
source(g_currentModDirectory .. 'scripts/specializations/events/SetProcessorConfigurationEvent.lua')

---@class MaterialProcessor_spec
---@field processor Processor
---@field actionEvents table
---@field dirtyFlag number

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
    Processor.registerXMLPaths(schema, 'vehicle.materialProcessor')
    schema:setXMLSpecializationType()

    ---@type XMLSchema
    local schemaSavegame = Vehicle.xmlSchemaSavegame

    schemaSavegame:setXMLSpecializationType('MaterialProcessor')
    Processor.registerSavegameXMLPaths(schemaSavegame, string.format('vehicles.vehicle(?).%s.materialProcessor', MaterialProcessor.MOD_NAME))
    schemaSavegame:setXMLSpecializationType()
end

function MaterialProcessor.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, 'getIsProcessingEnabled', MaterialProcessor.getIsProcessingEnabled)
    SpecializationUtil.registerFunction(vehicleType, 'getProcessor', MaterialProcessor.getProcessor)
    SpecializationUtil.registerFunction(vehicleType, 'setDischargeNodeState', MaterialProcessor.setDischargeNodeState)
    SpecializationUtil.registerFunction(vehicleType, 'setProcessorConfiguration', MaterialProcessor.setProcessorConfiguration)
    SpecializationUtil.registerFunction(vehicleType, 'setDischargeNodeToGround', MaterialProcessor.setDischargeNodeToGround)
end

function MaterialProcessor.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, 'onLoad', MaterialProcessor)
    SpecializationUtil.registerEventListener(vehicleType, 'onPostLoad', MaterialProcessor)
    SpecializationUtil.registerEventListener(vehicleType, 'onDelete', MaterialProcessor)

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

    ---@type MaterialProcessor_spec
    local spec = self[MaterialProcessor.SPEC_NAME]

    spec.dirtyFlag = self:getNextDirtyFlag()

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
    ---@type MaterialProcessor_spec
    local spec = self[MaterialProcessor.SPEC_NAME]

    if spec.processor ~= nil then
        spec.processor:delete()
    end

    spec.processor = nil
end

function MaterialProcessor:onPostLoad(savegame)
    if self.isServer and savegame ~= nil and savegame.xmlFile.filename ~= nil then
        local key = savegame.key .. '.' .. MaterialProcessor.MOD_NAME .. '.materialProcessor'

        ---@type MaterialProcessor_spec
        local spec = self[MaterialProcessor.SPEC_NAME]

        spec.processor:loadFromXMLFile(savegame.xmlFile, key)
    end
end

---@param xmlFile XMLFile
---@param key string
function MaterialProcessor:saveToXMLFile(xmlFile, key)
    local processor = self:getProcessor()

    if processor ~= nil then
        processor:saveToXMLFile(xmlFile, key)
    end
end

---@return Processor
---@nodiscard
function MaterialProcessor:getProcessor()
    return self[MaterialProcessor.SPEC_NAME].processor
end

function MaterialProcessor:getIsProcessingEnabled()
    local processor = self:getProcessor()

    if processor ~= nil then
        if processor.needsToBePoweredOn and not self:getIsPowered() then
            return false
        elseif processor.needsToBeTurnedOn and not self:getIsTurnedOn() then
            return false
        end

        return true
    end

    return false
end

---@param index number
---@param state number
---@param noEventSend? boolean
function MaterialProcessor:setDischargeNodeState(index, state, noEventSend)
    local processor = self:getProcessor()
    local dischargeNode = processor.dischargeNodes[index]

    if dischargeNode ~= nil then
        dischargeNode:setDischargeState(state, noEventSend)
    end
end

---@param index number
---@param noEventSend? boolean
function MaterialProcessor:setProcessorConfiguration(index, noEventSend)
    local processor = self:getProcessor()

    if processor.configurations[index] ~= nil then
        if processor.currentConfigurationIndex ~= index then
            SetProcessorConfigurationEvent.sendEvent(self, index, noEventSend)

            processor:setConfiguration(index)
        end
    else
        Logging.warning('MaterialProcessor:setProcessorConfiguration() Invalid index: %s', tostring(index))
    end
end

---@param canDischargeToGround boolean
---@param noEventSend boolean | nil
function MaterialProcessor:setDischargeNodeToGround(canDischargeToGround, noEventSend)
    local processor = self:getProcessor()

    if processor.canDischargeToGround ~= canDischargeToGround then
        SetDischargeNodeToGroundEvent.sendEvent(self, canDischargeToGround, noEventSend)

        processor.canDischargeToGround = canDischargeToGround

        for _, node in ipairs(processor.dischargeNodes) do
            node:setDischargeState(Dischargeable.DISCHARGE_STATE_OFF, noEventSend)
        end

        self:requestActionEventUpdate()
    end
end

---@param dt number
function MaterialProcessor:onUpdate(dt)
    local processor = self:getProcessor()

    if processor ~= nil then
        processor:update(dt)
    end
end

---@param dt number
---@param isActiveForInput boolean
---@param isActiveForInputIgnoreSelection boolean
---@param isSelected boolean
function MaterialProcessor:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    local processor = self:getProcessor()

    if processor ~= nil then
        processor:updateTick(dt)
    end
end

function MaterialProcessor:onTurnedOff()
    if self.isServer then
        local processor = self:getProcessor()

        for _, dischargeNode in ipairs(processor.dischargeNodes) do
            dischargeNode:setDischargeState(Dischargeable.DISCHARGE_STATE_OFF)
        end
    end
end

---@param isActiveForInput boolean
---@param isActiveForInputIgnoreSelection boolean
function MaterialProcessor:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
    ---@type MaterialProcessor_spec
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
    ---@type MaterialProcessor_spec
    local spec = self[MaterialProcessor.SPEC_NAME]

    local action = spec.actionEvents[MaterialProcessor.ACTIONS.SELECT_CONFIGURATION]

    if action ~= nil then
        g_inputBinding:setActionEventTextVisibility(action.actionEventId, #spec.processor.configurations > 0)
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
    g_processorDialog:show(self:getProcessor())
end

function MaterialProcessor:actionEventToggleDischargeToGround()
    local processor = self:getProcessor()

    self:setDischargeNodeToGround(not processor.canDischargeToGround)
end

---@param streamId number
---@param connection Connection
function MaterialProcessor:onWriteStream(streamId, connection)
    local processor = self:getProcessor()

    streamWriteUIntN(streamId, processor.currentConfigurationIndex, Processor.SEND_NUM_BITS_INDEX)
    streamWriteBool(streamId, processor.canDischargeToGround)

    for _, dischargeNode in ipairs(processor.dischargeNodes) do
        dischargeNode:writeStream(streamId, connection)
    end
end

---@param streamId number
---@param connection Connection
function MaterialProcessor:onReadStream(streamId, connection)
    local processor = self:getProcessor()

    self:setProcessorConfiguration(streamReadUIntN(streamId, Processor.SEND_NUM_BITS_INDEX), true)

    processor.canDischargeToGround = streamReadBool(streamId)

    for _, dischargeNode in ipairs(processor.dischargeNodes) do
        dischargeNode:readStream(streamId, connection)
    end
end

---@param streamId number
---@param connection Connection
---@param dirtyMask number
function MaterialProcessor:onWriteUpdateStream(streamId, connection, dirtyMask)
    ---@type MaterialProcessor_spec
    local spec = self[MaterialProcessor.SPEC_NAME]

    if not connection:getIsServer() then
        if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
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
    if connection:getIsServer() then
        if streamReadBool(streamId) then
            local processor = self:getProcessor()

            for _, dischargeNode in ipairs(processor.dischargeNodes) do
                dischargeNode:readUpdateStream(streamId, connection)
            end
        end
    end
end
