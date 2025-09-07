---@class SetDischargeNodeToGroundEvent : Event
---@field vehicle MaterialProcessor
---@field canDischargeToGround boolean
SetDischargeNodeToGroundEvent = {}

local SetDischargeNodeToGroundEvent_mt = Class(SetDischargeNodeToGroundEvent, Event)

InitEventClass(SetDischargeNodeToGroundEvent, 'SetDischargeNodeToGroundEvent')

function SetDischargeNodeToGroundEvent.emptyNew()
    ---@type SetDischargeNodeToGroundEvent
    local self = Event.new(SetDischargeNodeToGroundEvent_mt)
    return self
end

---@param vehicle any
---@param canDischargeToGround any
---@return SetDischargeNodeToGroundEvent
---@nodiscard
function SetDischargeNodeToGroundEvent.new(vehicle, canDischargeToGround)
    local self = SetDischargeNodeToGroundEvent.emptyNew()

    self.vehicle = vehicle
    self.canDischargeToGround = canDischargeToGround

    return self
end

---@param streamId number
---@param connection Connection
function SetDischargeNodeToGroundEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteBool(streamId, self.canDischargeToGround)
end

---@param streamId number
---@param connection Connection
function SetDischargeNodeToGroundEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.canDischargeToGround = streamReadBool(streamId)

    self:run(connection)
end

---@param connection Connection
function SetDischargeNodeToGroundEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection, self.vehicle)
    end

    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setProcessorDischargeNodeToGround(self.canDischargeToGround, true)
    end
end

---@param vehicle MaterialProcessor
---@param canDischargeToGround boolean
---@param noEventSend boolean | nil
function SetDischargeNodeToGroundEvent.sendEvent(vehicle, canDischargeToGround, noEventSend)
    if not noEventSend then
        local event = SetDischargeNodeToGroundEvent.new(vehicle, canDischargeToGround)

        if g_server ~= nil then
            g_server:broadcastEvent(event)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
