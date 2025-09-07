---@class SetProcessorConfigurationEvent : Event
---@field vehicle MaterialProcessor
---@field index number
SetProcessorConfigurationEvent = {}

local SetProcessorConfigurationEvent_mt = Class(SetProcessorConfigurationEvent, Event)

InitEventClass(SetProcessorConfigurationEvent, 'SetProcessorConfigurationEvent')

function SetProcessorConfigurationEvent.emptyNew()
    ---@type SetProcessorConfigurationEvent
    local self = Event.new(SetProcessorConfigurationEvent_mt)
    return self
end

---@param vehicle MaterialProcessor
---@param index number
---@return SetProcessorConfigurationEvent
---@nodiscard
function SetProcessorConfigurationEvent.new(vehicle, index)
    local self = SetProcessorConfigurationEvent.emptyNew()

    self.vehicle = vehicle
    self.index = index

    return self
end

---@param streamId number
---@param connection Connection
function SetProcessorConfigurationEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteUIntN(streamId, self.index, Processor.SEND_NUM_BITS_INDEX)
end

---@param streamId number
---@param connection Connection
function SetProcessorConfigurationEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.index = streamReadUIntN(streamId, Processor.SEND_NUM_BITS_INDEX)

    self:run(connection)
end

---@param connection Connection
function SetProcessorConfigurationEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection, self.vehicle)
    end

    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setProcessorConfigurationIndex(self.index, true)
    end
end

---@param vehicle MaterialProcessor
---@param index number
---@param noEventSend boolean | nil
function SetProcessorConfigurationEvent.sendEvent(vehicle, index, noEventSend)
    if not noEventSend then
        local event = SetProcessorConfigurationEvent.new(vehicle, index)

        if g_server ~= nil then
            g_server:broadcastEvent(event)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
