---@class SetDischargeNodeStateEvent : Event
---@field vehicle MaterialProcessor
---@field nodeIndex number
---@field state number
SetDischargeNodeStateEvent = {}

local SetDischargeNodeStateEvent_mt = Class(SetDischargeNodeStateEvent, Event)

InitEventClass(SetDischargeNodeStateEvent, 'SetDischargeNodeStateEvent')

---@return SetDischargeNodeStateEvent
function SetDischargeNodeStateEvent.emptyNew()
    ---@type SetDischargeNodeStateEvent
    local self = Event.new(SetDischargeNodeStateEvent_mt)
    return self
end

---@param vehicle MaterialProcessor
---@param nodeIndex number
---@param state number
---@return SetDischargeNodeStateEvent
function SetDischargeNodeStateEvent.new(vehicle, nodeIndex, state)
    local self = SetDischargeNodeStateEvent.emptyNew()

    self.vehicle = vehicle
    self.nodeIndex = nodeIndex
    self.state = state

    return self
end

---@param streamId number
---@param connection Connection
function SetDischargeNodeStateEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteUIntN(streamId, self.nodeIndex, ProcessorDischargeNode.SEND_NUM_BITS_INDEX)
    streamWriteUIntN(streamId, self.state, Processor.SEND_NUM_BITS_STATE)
end

---@param streamId number
---@param connection Connection
function SetDischargeNodeStateEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.nodeIndex = streamReadUIntN(streamId, ProcessorDischargeNode.SEND_NUM_BITS_INDEX)
    self.state = streamReadUIntN(streamId, Processor.SEND_NUM_BITS_STATE)

    self:run(connection)
end

---@param connection Connection
function SetDischargeNodeStateEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection, self.vehicle)
    end

    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setProcessorDischargeNodeState(self.nodeIndex, self.state, true)
    end
end

---@param vehicle MaterialProcessor
---@param nodeIndex number
---@param state number
---@param noEventSend boolean | nil
function SetDischargeNodeStateEvent.sendEvent(vehicle, nodeIndex, state, noEventSend)
    if not noEventSend then
        local event = SetDischargeNodeStateEvent.new(vehicle, nodeIndex, state)

        if g_server ~= nil then
            g_server:broadcastEvent(event)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
