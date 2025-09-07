---@class ProcessorDischargeNode : DischargeNodeProperties
---@field index number
---@field processor Processor
---@field vehicle MaterialProcessor
---@field fillUnitIndex number
---@field node number
---@field isClient boolean
---@field isServer boolean
ProcessorDischargeNode = {}

ProcessorDischargeNode.RAYCAST_COLLISION_MASK = CollisionFlag.FILLABLE + CollisionFlag.VEHICLE + CollisionFlag.TERRAIN
ProcessorDischargeNode.SEND_NUM_BITS_INDEX = 4

local ProcessorDischargeNode_mt = Class(ProcessorDischargeNode)

---@param schema XMLSchema
---@param key string
function ProcessorDischargeNode.registerXMLPaths(schema, key)
    schema:register(XMLValueType.NODE_INDEX, key .. '#node', 'Vehicle discharge node', nil, true)

    schema:register(XMLValueType.INT, key .. '#fillUnitIndex', 'Vehicle fillUnitIndex', nil, true)

    schema:register(XMLValueType.BOOL, key .. '#stopDischargeIfNotPossible')

    schema:register(XMLValueType.INT, key .. '#unloadInfoIndex', 'Unload info index', 1)
    schema:register(XMLValueType.FLOAT, key .. '#effectTurnOffThreshold', 'After this time has passed and nothing has been harvested the effects are turned off', 0.25)
    schema:register(XMLValueType.FLOAT, key .. '#maxDistance', 'Max discharge distance', 10)
    schema:register(XMLValueType.INT, key .. '#emptySpeed', 'Discharge speed in liters/second', 250)

    -- Discharge info
    schema:register(XMLValueType.NODE_INDEX, key .. ".info#node", "Discharge info node", "Discharge node")
    schema:register(XMLValueType.FLOAT, key .. '.info#width', '', 1)
    schema:register(XMLValueType.FLOAT, key .. '.info#length', '', 1)
    schema:register(XMLValueType.FLOAT, key .. '.info#zOffset', '', 1)
    schema:register(XMLValueType.FLOAT, key .. '.info#yOffset', '', 1)
    schema:register(XMLValueType.BOOL, key .. '.info#limitToGround', '', true)
    schema:register(XMLValueType.BOOL, key .. '.info#useRaycastHitPosition', '', false)

    -- Discharge raycast
    schema:register(XMLValueType.NODE_INDEX, key .. ".raycast#node", "Raycast node", "Discharge node")
    schema:register(XMLValueType.FLOAT, key .. ".raycast#yOffset", "Y Offset", 0)
    schema:register(XMLValueType.FLOAT, key .. ".raycast#maxDistance", "Max. raycast distance", 10)
    schema:register(XMLValueType.BOOL, key .. ".raycast#useWorldNegYDirection", "Use world negative Y Direction", false)

    -- Discharge triggers
    schema:register(XMLValueType.NODE_INDEX, key .. ".trigger#node", "Discharge trigger node")
    schema:register(XMLValueType.NODE_INDEX, key .. ".activationTrigger#node", "Discharge activation trigger node")

    -- Discharge ObjectChanges
    schema:register(XMLValueType.FLOAT, key .. ".distanceObjectChanges#threshold", "Defines at which raycast distance the object changes", 0.5)
    ObjectChangeUtil.registerObjectChangeXMLPaths(schema, key .. '.distanceObjectChanges')
    ObjectChangeUtil.registerObjectChangeXMLPaths(schema, key .. ".stateObjectChanges")
    ObjectChangeUtil.registerObjectChangeXMLPaths(schema, key .. ".nodeActiveObjectChanges")

    -- Discharge effects, animations
    schema:register(XMLValueType.NODE_INDEX, key .. '#soundNode', 'Sound node index path')
    schema:register(XMLValueType.BOOL, key .. '#playSound', 'Whether to play sounds', true)
    EffectManager.registerEffectXMLPaths(schema, key .. ".effects")
    SoundManager.registerSampleXMLPaths(schema, key, "dischargeSound")
    SoundManager.registerSampleXMLPaths(schema, key, "dischargeStateSound(?)")
    schema:register(XMLValueType.BOOL, key .. ".dischargeSound#overwriteSharedSound", "Overwrite shared discharge sound with sound defined in discharge node", false)
    AnimationManager.registerAnimationNodesXMLPaths(schema, key .. ".animationNodes")
end

function ProcessorDischargeNode.new(index, processor)
    ---@type ProcessorDischargeNode
    local self = setmetatable({}, ProcessorDischargeNode_mt)

    self.index = index
    self.processor = processor
    self.vehicle = processor.vehicle

    self.isClient = self.vehicle.isClient
    self.isServer = self.vehicle.isServer

    self.toolType = g_toolTypeManager:getToolTypeIndexByName('dischargable')
    self.lineOffset = 0
    self.litersToDrop = 0
    self.dischargeHitTerrain = false
    self.dischargeDistance = 0
    self.dischargeDistanceSent = 0
    self.dischargeHit = false
    self.sentHitDistance = 0
    self.isEffectActive = false
    self.isEffectActiveSent = false
    self.currentDischargeState = Dischargeable.DISCHARGE_STATE_OFF
    self.emptySpeed = 250

    return self
end

function ProcessorDischargeNode:delete()
    g_effectManager:deleteEffects(self.effects)
    g_soundManager:deleteSample(self.sample)
    g_soundManager:deleteSample(self.dischargeSample)
    g_soundManager:deleteSamples(self.dischargeStateSamples)
    g_animationManager:deleteAnimations(self.animationNodes)

    if self.trigger.node ~= nil then
        removeTrigger(self.trigger.node)
    end

    if self.activationTrigger.node ~= nil then
        removeTrigger(self.activationTrigger.node)
    end
end

---@param object table
function ProcessorDischargeNode:onDeleteDischargeTriggerObject(object)
    if self.trigger.objects[object] ~= nil then
        self.trigger.objects[object] = nil
        self.trigger.numObjects = self.trigger.numObjects - 1
    end
end

---@param object table
function ProcessorDischargeNode:onDeleteActivationTriggerObject(object)
    if self.activationTrigger.objects[object] ~= nil then
        self.activationTrigger.objects[object] = nil
        self.activationTrigger.numObjects = self.activationTrigger.numObjects - 1
    end
end

---@param xmlFile XMLFile
---@param key string
---@return boolean
---@nodiscard
function ProcessorDischargeNode:load(xmlFile, key)
    self.fillUnitIndex = xmlFile:getValue(key .. '#fillUnitIndex')

    if self.fillUnitIndex == nil then
        Logging.xmlError(xmlFile, 'Missing fillUnitIndex attribute: %s', key .. '#fillUnitIndex')
        return false
    end

    if self.vehicle:getFillUnitByIndex(self.fillUnitIndex) == nil then
        Logging.xmlError(xmlFile, 'FillUnit index "%i" not found: %s', self.fillUnitIndex, key .. '#fillUnitIndex')
        return false
    end

    self.node = xmlFile:getValue(key .. '#node', nil, self.vehicle.components, self.vehicle.i3dMappings)

    if self.node == nil then
        local nodePath = xmlFile:getString(key .. '#node')
        Logging.xmlError(xmlFile, 'Could not find node "%s": %s', tostring(nodePath), key .. '#node')
        return false
    end

    self.effectTurnOffThreshold = xmlFile:getValue(key .. '#effectTurnOffThreshold', 0.25)
    self.stopDischargeIfNotPossible = xmlFile:getValue(key .. '#stopDischargeIfNotPossible', xmlFile:hasProperty(key .. '.trigger#node'))
    self.emptySpeed = xmlFile:getValue(key .. '#emptySpeed', 250)

    ProcessorUtils.loadDischargeInfo(self, xmlFile, key)
    ProcessorUtils.loadDischargeRaycast(self, xmlFile, key)
    ProcessorUtils.loadDischargeTriggers(self, xmlFile, key)
    ProcessorUtils.loadDischargeEffects(self, xmlFile, key)
    ProcessorUtils.loadDischargeObjectChanges(self, xmlFile, key)

    return true
end

---@param state number
---@param noEventSend boolean | nil
function ProcessorDischargeNode:setDischargeState(state, noEventSend)
    if state ~= self.currentDischargeState then
        SetDischargeNodeStateEvent.sendEvent(self.vehicle, self.index, state, noEventSend)

        self.currentDischargeState = state

        if state == Dischargeable.DISCHARGE_STATE_OFF then
            if self.isServer then
                self:setDischargeEffectActive(false)
            end

            g_animationManager:stopAnimations(self.animationNodes)
        else
            g_animationManager:startAnimations(self.animationNodes)
        end

        if self.stateObjectChanges ~= nil then
            ObjectChangeUtil.setObjectChanges(self.stateObjectChanges, state ~= Dischargeable.DISCHARGE_STATE_OFF, self.vehicle, self.vehicle.setMovingToolDirty)
        end

        if self.vehicle.setDashboardsDirty ~= nil then
            self.vehicle:setDashboardsDirty()
        end
    end
end

function ProcessorDischargeNode:getDischargeState()
    return self.currentDischargeState
end

---@return FillUnit
---@return number
---@nodiscard
function ProcessorDischargeNode:getDischargeTargetObject()
    return self.dischargeObject, self.dischargeFillUnitIndex
end

function ProcessorDischargeNode:setDischargeEffectActive(isActive, force, fillTypeIndex)
    if isActive then
        if not self.isEffectActiveSent then
            if fillTypeIndex == nil then
                fillTypeIndex = self.processor:getFillUnitFillTypeIndex(self.fillUnitIndex)
            end

            g_effectManager:setFillType(self.effects, fillTypeIndex)
            g_effectManager:startEffects(self.effects)
            g_animationManager:startAnimations(self.animationNodes)

            self.isEffectActive = true
        end

        self.stopEffectTime = nil
    elseif not force then
        if self.stopEffectTime == nil then
            self.stopEffectTime = g_time + self.effectTurnOffThreshold
            self.vehicle:raiseActive()
        end
    elseif self.isEffectActive then
        g_effectManager:stopEffects(self.effects)
        g_animationManager:stopAnimations(self.animationNodes)

        self.isEffectActive = false
    end

    if self.isServer and self.isEffectActive ~= self.isEffectActiveSent then
        ---@type MaterialProcessorSpecialization
        local spec = self.vehicle[MaterialProcessor.SPEC_NAME]

        self.vehicle:raiseDirtyFlags(spec.dirtyFlagDischarge)

        self.isEffectActiveSent = self.isEffectActive
    end
end

---@param distance number
function ProcessorDischargeNode:setDischargeEffectDistance(distance)
    if self.isEffectActive and self.effects ~= nil and distance ~= math.huge then
        for _, effect in pairs(self.effects) do
            if effect.setDistance ~= nil then
                effect:setDistance(distance, g_terrainNode)
            end
        end
    end
end

---@return boolean
---@nodiscard
function ProcessorDischargeNode:getCanDischargeToGround()
    if not self.processor.canDischargeToGround then
        return false
    elseif not self.dischargeHitTerrain then
        return false
    elseif not self.processor:getFillUnitIsActive(self.fillUnitIndex) then
        return false
    end

    if self.processor:getFillUnitFillLevel(self.fillUnitIndex) > 0 then
        local fillTypeIndex = self.processor:getFillUnitFillTypeIndex(self.fillUnitIndex)

        if fillTypeIndex == nil or not DensityMapHeightUtil.getCanTipToGround(fillTypeIndex) then
            return false
        end
    end

    if not self:getCanDischargeToLand() then
        return false
    elseif not self:getCanDischargeAtPosition() then
        return false
    end

    return true
end

---@return boolean
---@nodiscard
function ProcessorDischargeNode:getCanDischargeToLand()
    if self.processor.canDischargeToGroundAnywhere then
        return true
    end

    local sx, _, sz = localToWorld(self.info.node, -self.info.width, 0, self.info.zOffset)
    local ex, _, ez = localToWorld(self.info.node, self.info.width, 0, self.info.zOffset)
    local activeFarm = self.vehicle:getActiveFarm()

    if not g_currentMission.accessHandler:canFarmAccessLand(activeFarm, sx, sz) then
        return false
    end

    if not g_currentMission.accessHandler:canFarmAccessLand(activeFarm, ex, ez) then
        return false
    end

    return true
end

---@return boolean
---@nodiscard
function ProcessorDischargeNode:getCanDischargeAtPosition()
    if self.processor:getFillUnitFillLevel(self.fillUnitIndex) > 0 then
        local sx, sy, sz = localToWorld(self.info.node, -self.info.width, 0, self.info.zOffset)
        local ex, ey, ez = localToWorld(self.info.node, self.info.width, 0, self.info.zOffset)

        if self.currentDischargeState == Dischargeable.DISCHARGE_STATE_OFF or self.currentDischargeState == Dischargeable.DISCHARGE_STATE_GROUND then
            sy = sy + self.info.yOffset
            ey = ey + self.info.yOffset

            if self.info.limitToGround then
                sy = math.max(getTerrainHeightAtWorldPos(g_terrainNode, sx, 0, sz) + 0.1, sy)
                ey = math.max(getTerrainHeightAtWorldPos(g_terrainNode, ex, 0, ez) + 0.1, ey)
            end

            local fillType = self.processor:getFillUnitFillTypeIndex(self.fillUnitIndex)

            if fillType == nil then
                return false
            end

            local testDrop = g_densityMapHeightManager:getMinValidLiterValue(fillType)

            if not DensityMapHeightUtil.getCanTipToGroundAroundLine(self, testDrop, fillType, sx, sy, sz, ex, ey, ez, self.info.length, nil, self.lineOffset, true, nil, true) then
                return false
            end
        end
    end

    return true
end

---@return boolean
---@nodiscard
function ProcessorDischargeNode:getCanDischargeToObject()
    ---@type FillUnit
    local object = self.dischargeObject

    if object == nil then
        return false
    elseif not self.processor:getFillUnitIsActive(self.fillUnitIndex) then
        return false
    end

    local fillTypeIndex = self.processor:getFillUnitFillTypeIndex(self.fillUnitIndex)

    if not object:getFillUnitSupportsFillType(self.dischargeFillUnitIndex, fillTypeIndex) then
        return false
    end

    local allowFillType = object:getFillUnitAllowsFillType(self.dischargeFillUnitIndex, fillTypeIndex)

    if not allowFillType then
        return false
    end

    local activeFarmId = self.vehicle:getActiveFarm()

    if object.getFillUnitFreeCapacity ~= nil and object:getFillUnitFreeCapacity(self.dischargeFillUnitIndex, nil, activeFarmId) <= 0 then
        return false
    end

    if not self.processor.canDischargeToAnyObject and object.getIsFillAllowedFromFarm ~= nil and not object:getIsFillAllowedFromFarm(activeFarmId) then
        return false
    end

    if self.vehicle.getMountObject ~= nil then
        local mounter = self.vehicle:getDynamicMountObject() or self.vehicle:getMountObject()

        if mounter ~= nil and not self.processor.canDischargeToAnyObject and not g_currentMission.accessHandler:canFarmAccess(mounter:getActiveFarm(), self.vehicle, true) then
            return false
        end
    end

    return true
end

---@param dischargedLiters number
---@param minDropReached boolean
---@param hasMinDropFillLevel boolean
function ProcessorDischargeNode:handleDischarge(dischargedLiters, minDropReached, hasMinDropFillLevel)
    if self.currentDischargeState == Dischargeable.DISCHARGE_STATE_GROUND then
        -- void
    elseif self.stopDischargeIfNotPossible and dischargedLiters == 0 then
        self:setDischargeState(Dischargeable.DISCHARGE_STATE_OFF)
    end
end

---@param object table | nil
---@param shape any | nil
---@param distance number | nil
---@param fillUnitIndex number | nil
---@param hitTerrain boolean | nil
function ProcessorDischargeNode:handleDischargeRaycast(object, shape, distance, fillUnitIndex, hitTerrain)
    if object == nil and self.currentDischargeState == Dischargeable.DISCHARGE_STATE_OBJECT then
        self:setDischargeState(Dischargeable.DISCHARGE_STATE_OFF)
    elseif object == nil and self.processor:getIsAvailable() and self:getCanDischargeToGround() then
        self:setDischargeState(Dischargeable.DISCHARGE_STATE_GROUND)
    end

    if self.distanceObjectChanges ~= nil then
        ObjectChangeUtil.setObjectChanges(self.distanceObjectChanges, self.distanceObjectChangeThreshold < distance or self.currentDischargeState ~= Dischargeable.DISCHARGE_STATE_OFF, self.vehicle, self.vehicle.setMovingToolDirty)
    end
end

function ProcessorDischargeNode:handleFoundDischargeObject()
    if self.processor:getIsAvailable() then
        self:setDischargeState(Dischargeable.DISCHARGE_STATE_OBJECT)
    end
end

function ProcessorDischargeNode:handleDischargeOnEmpty()
    self:setDischargeState(Dischargeable.DISCHARGE_STATE_OFF, true)
end

function ProcessorDischargeNode:finishDischargeRaycast()
    self:handleDischargeRaycast(self.lastDischargeObject)
    self.isAsyncRaycastActive = false
end

---@param emptyLiters number
---@return number dischargedLiters
---@return boolean minDropReached
---@return boolean hasMinDropFillLevel
---@nodiscard
function ProcessorDischargeNode:discharge(emptyLiters)
    local dischargedLiters = 0
    local minDropReached = true
    local hasMinDropFillLevel = true

    local object, fillUnitIndex = self:getDischargeTargetObject()

    self.currentDischargeObject = nil

    if object ~= nil then
        if self.currentDischargeState == Dischargeable.DISCHARGE_STATE_OBJECT then
            dischargedLiters = self:dischargeToObject(emptyLiters, object, fillUnitIndex)
        end
    elseif self.dischargeHitTerrain and self.currentDischargeState == Dischargeable.DISCHARGE_STATE_GROUND then
        dischargedLiters, minDropReached, hasMinDropFillLevel = self:dischargeToGround(emptyLiters)
    end

    return dischargedLiters, minDropReached, hasMinDropFillLevel
end

---@param emptyLiters number
---@return number dischargedLiters
---@return boolean minDropReached
---@return boolean hasMinDropFillLevel
---@nodiscard
function ProcessorDischargeNode:dischargeToGround(emptyLiters)
    if emptyLiters == 0 then
        return 0, false, false
    end

    local fillTypeIndex = self.processor:getFillUnitFillTypeIndex(self.fillUnitIndex)
    local fillLevel = self.processor:getFillUnitFillLevel(self.fillUnitIndex)
    local minValidLiter = g_densityMapHeightManager:getMinValidLiterValue(fillTypeIndex)

    self.litersToDrop = math.min(self.litersToDrop + emptyLiters, fillLevel)

    if self.litersToDrop < minValidLiter then
        return 0, false, false
    end

    local dischargedLiters = 0
    local minDropReached = minValidLiter < self.litersToDrop

    if minDropReached then
        local info = self.info
        local sx, sy, sz = localToWorld(info.node, -info.width, 0, info.zOffset)
        local ex, ey, ez = localToWorld(info.node, info.width, 0, info.zOffset)
        sy = sy + info.yOffset
        ey = ey + info.yOffset

        if info.limitToGround then
            sy = math.max(getTerrainHeightAtWorldPos(g_terrainNode, sx, 0, sz) + 0.1, sy)
            ey = math.max(getTerrainHeightAtWorldPos(g_terrainNode, ex, 0, ez) + 0.1, ey)
        end

        local dropped, lineOffset = DensityMapHeightUtil.tipToGroundAroundLine(self.vehicle, self.litersToDrop, fillTypeIndex, sx, sy, sz, ex, ey, ez, info.length, nil, self.lineOffset, true, nil, true)
        self.lineOffset = lineOffset
        self.litersToDrop = self.litersToDrop - dropped

        if dropped > 0 then
            local unloadInfo

            if self.vehicle.getFillVolumeUnloadInfo ~= nil then
                unloadInfo = self.vehicle:getFillVolumeUnloadInfo(self.unloadInfoIndex)
            end

            dischargedLiters = self.vehicle:addFillUnitFillLevel(self.vehicle:getOwnerFarmId(), self.fillUnitIndex, -dropped, fillTypeIndex, ToolType.UNDEFINED, unloadInfo)
        end
    end

    return dischargedLiters, minDropReached, false
end

---@param emptyLiters number
---@param object any
---@param targetFillUnitIndex number
---@return number dischargedLiters
---@nodiscard
function ProcessorDischargeNode:dischargeToObject(emptyLiters, object, targetFillUnitIndex)
    local fillTypeIndex = self.processor:getFillUnitFillTypeIndex(self.fillUnitIndex)
    local supportsFillType = object:getFillUnitSupportsFillType(targetFillUnitIndex, fillTypeIndex)
    local dischargedLiters = 0

    if supportsFillType then
        local allowFillType = object:getFillUnitAllowsFillType(targetFillUnitIndex, fillTypeIndex)

        if allowFillType then
            self.currentDischargeObject = object

            local delta = object:addFillUnitFillLevel(self.vehicle:getActiveFarm(), targetFillUnitIndex, emptyLiters, fillTypeIndex, self.toolType, self.info)
            local unloadInfo

            if self.vehicle.getFillVolumeUnloadInfo ~= nil then
                unloadInfo = self.vehicle:getFillVolumeUnloadInfo(self.unloadInfoIndex)
            end

            dischargedLiters = self.vehicle:addFillUnitFillLevel(self.vehicle:getOwnerFarmId(), self.fillUnitIndex, -delta, fillTypeIndex, ToolType.UNDEFINED, unloadInfo)
        end
    end

    return dischargedLiters
end

---@param dt number
function ProcessorDischargeNode:update(dt)
    if self.activationTrigger.numObjects > 0 or self.currentDischargeState ~= Dischargeable.DISCHARGE_STATE_OFF then
        self.vehicle:raiseActive()
    end
end

---@param dt number
---@param isActiveForInput boolean
---@param isActiveForInputIgnoreSelection boolean
---@param isSelected boolean
function ProcessorDischargeNode:updateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    if self.vehicle:getCanProcess() then
        local trigger = self.trigger

        if trigger.numObjects > 0 then
            self.dischargeObject = nil
            self.dischargeHitObject = nil
            self.dischargeHitObjectUnitIndex = nil
            self.dischargeHitTerrain = false
            self.dischargeDistance = 0
            self.dischargeFillUnitIndex = nil
            self.dischargeHit = false

            local nearestDistance = math.huge

            for object, data in pairs(trigger.objects) do
                local fillTypeIndex = self.processor:getFillUnitFillTypeIndex(self.fillUnitIndex)

                if object:getFillUnitSupportsFillType(data.fillUnitIndex, fillTypeIndex) then
                    local allowFillType = object:getFillUnitAllowsFillType(data.fillUnitIndex, fillTypeIndex)
                    local allowToolType = object:getFillUnitSupportsToolType(data.fillUnitIndex, ToolType.TRIGGER)
                    local freeSpace = object:getFillUnitFreeCapacity(data.fillUnitIndex, fillTypeIndex, self.vehicle:getActiveFarm()) > 0

                    if allowFillType and allowToolType and freeSpace then
                        local exactFillRootNode = object:getFillUnitExactFillRootNode(data.fillUnitIndex)

                        if exactFillRootNode ~= nil and entityExists(exactFillRootNode) then
                            local distance = calcDistanceFrom(self.node, exactFillRootNode)

                            if distance < nearestDistance then
                                self.dischargeObject = object
                                self.dischargeHitTerrain = false
                                self.dischargeDistance = distance
                                self.dischargeFillUnitIndex = data.fillUnitIndex
                                nearestDistance = distance
                            end
                        end
                    end

                    self.dischargeHitObject = object
                    self.dischargeHitObjectUnitIndex = data.fillUnitIndex
                end

                self.dischargeHit = true
            end
        elseif not self.isAsyncRaycastActive then
            self:updateRaycast()
        end
    end

    self:updateDischargeSound(dt)

    if self.vehicle.isServer then
        local currentDischargeState = self:getDischargeState()

        if currentDischargeState == Dischargeable.DISCHARGE_STATE_OFF then
            if self.dischargeObject ~= nil then
                self:handleFoundDischargeObject()
            end
        elseif currentDischargeState == Dischargeable.DISCHARGE_STATE_GROUND and self.dischargeObject ~= nil and self:getCanDischargeToObject() then
            self:handleFoundDischargeObject()
        elseif self.vehicle:getCanProcess() and self.processor:getIsAvailable() and self.processor:getFillUnitIsActive(self.fillUnitIndex) then
            local fillLevel = self.vehicle:getFillUnitFillLevel(self.fillUnitIndex) or 0
            local canDischargeToObject = self:getCanDischargeToObject() and currentDischargeState == Dischargeable.DISCHARGE_STATE_OBJECT
            local canDischargeToGround = self:getCanDischargeToGround() and currentDischargeState == Dischargeable.DISCHARGE_STATE_GROUND
            local canDischarge = canDischargeToObject or canDischargeToGround
            local allowedToDischarge = self.dischargeObject ~= nil or self:getCanDischargeToLand() and self:getCanDischargeAtPosition()
            local isReadyToStartDischarge = fillLevel > 0 and self.emptySpeed > 0 and allowedToDischarge and canDischarge

            self:setDischargeEffectActive(isReadyToStartDischarge)
            self:setDischargeEffectDistance(self.dischargeDistance)

            local isReadyForDischarge = self.lastEffect == nil or self.lastEffect:getIsFullyVisible()

            if isReadyForDischarge and isReadyToStartDischarge then
                local emptyLiters = math.min(fillLevel, self.emptySpeed * dt)
                local dischargedLiters, minDropReached, hasMinDropFillLevel = self:discharge(emptyLiters)

                self:handleDischarge(dischargedLiters, minDropReached, hasMinDropFillLevel)
            end
        end

        if self.isEffectActive ~= self.isEffectActiveSent or math.abs(self.dischargeDistanceSent - self.dischargeDistance) > 0.05 then
            ---@type MaterialProcessorSpecialization
            local spec = self.vehicle[MaterialProcessor.SPEC_NAME]

            self.vehicle:raiseDirtyFlags(spec.dirtyFlagDischarge)

            self.dischargeDistanceSent = self.dischargeDistance
            self.isEffectActiveSent = self.isEffectActive
        end
    end

    if self:getDischargeState() == Dischargeable.DISCHARGE_STATE_OFF then
        if self.vehicle:getIsActiveForInput() and self:getCanDischargeToObject() and self:getCanDischargeToObject() then
            g_currentMission:showTipContext(self.vehicle:getFillUnitFillType(self.fillUnitIndex))
        end
    end

    if self.stopEffectTime ~= nil then
        if self.stopEffectTime < g_time then
            self:setDischargeEffectActive(false, true)
            self.stopEffectTime = nil
        else
            self.vehicle:raiseActive()
        end
    end
end

---@param x number
---@param y number
---@param z number
function ProcessorDischargeNode:updateDischargeInfo(x, y, z)
    if self.info.useRaycastHitPosition then
        setWorldTranslation(self.info.node, x, y, z)
    end
end

---@param dt number
function ProcessorDischargeNode:updateDischargeSound(dt)
    if not self.isClient then
        return
    end

    local fillTypeIndex = self.processor:getFillUnitFillTypeIndex(self.fillUnitIndex)
    local isInDischargeState = self.currentDischargeState ~= Dischargeable.DISCHARGE_STATE_OFF
    local isEffectActive = self.isEffectActive and fillTypeIndex ~= FillType.UNKNOWN
    local lastEffectVisible = self.lastEffect == nil or self.lastEffect:getIsVisible()
    local effectsStillActive = self.lastEffect ~= nil and self.lastEffect:getIsVisible()

    if (isInDischargeState and isEffectActive or effectsStillActive) and lastEffectVisible then
        if self.playSound and fillTypeIndex ~= FillType.UNKNOWN then
            local sharedSample = g_fillTypeManager:getSampleByFillType(fillTypeIndex)

            if sharedSample ~= nil then
                if sharedSample ~= self.sharedSample then
                    if self.sample ~= nil then
                        g_soundManager:deleteSample(self.sample)
                    end

                    self.sample = g_soundManager:cloneSample(sharedSample, self.node or self.soundNode, self)
                    self.sharedSample = sharedSample

                    g_soundManager:playSample(self.sample)
                elseif not g_soundManager:getIsSamplePlaying(self.sample) then
                    g_soundManager:playSample(self.sample)
                end
            end
        end

        if self.dischargeSample ~= nil and not g_soundManager:getIsSamplePlaying(self.dischargeSample) then
            g_soundManager:playSample(self.dischargeSample)
        end

        self.turnOffSoundTimer = 250
    elseif self.turnOffSoundTimer ~= nil and self.turnOffSoundTimer > 0 then
        self.turnOffSoundTimer = self.turnOffSoundTimer - dt

        if self.turnOffSoundTimer <= 0 then
            if self.playSound and g_soundManager:getIsSamplePlaying(self.sample) then
                g_soundManager:stopSample(self.sample)
            end

            if self.dischargeSample ~= nil and g_soundManager:getIsSamplePlaying(self.dischargeSample) then
                g_soundManager:stopSample(self.dischargeSample)
            end

            self.turnOffSoundTimer = 0
        end
    end

    if self.dischargeStateSamples ~= nil and #self.dischargeStateSamples > 0 then
        for _, sample in ipairs(self.dischargeStateSamples) do
            if isInDischargeState then
                if not g_soundManager:getIsSamplePlaying(sample) then
                    g_soundManager:playSample(sample)
                end
            elseif g_soundManager:getIsSamplePlaying(sample) then
                g_soundManager:stopSample(sample)
            end
        end
    end
end

function ProcessorDischargeNode:updateRaycast()
    if self.raycast.node == nil then
        return
    end

    self.lastDischargeObject = self.dischargeObject
    self.dischargeObject = nil
    self.dischargeHitObject = nil
    self.dischargeHitObjectUnitIndex = nil
    self.dischargeHitTerrain = false
    self.dischargeDistance = math.huge
    self.dischargeFillUnitIndex = nil
    self.dischargeHit = false

    local x, y, z = getWorldTranslation(self.raycast.node)
    local dx = 0
    local dy = -1
    local dz = 0
    y = y + self.raycast.yOffset

    if not self.raycast.useWorldNegYDirection then
        dx, dy, dz = localDirectionToWorld(self.raycast.node, 0, -1, 0)
    end

    self.isAsyncRaycastActive = true

    raycastAll(x, y, z, dx, dy, dz, self.maxDistance, "raycastCallbackDischargeNode", self, ProcessorDischargeNode.RAYCAST_COLLISION_MASK)

    ---@diagnostic disable-next-line: missing-parameter
    self:raycastCallbackDischargeNode(nil)
end

---@param hitActorId number | nil
---@param x number
---@param y number
---@param z number
---@param distance number
---@param nx number
---@param ny number
---@param nz number
---@param subShapeIndex number | nil
---@param hitShapeId number | nil
---@return boolean | nil
function ProcessorDischargeNode:raycastCallbackDischargeNode(hitActorId, x, y, z, distance, nx, ny, nz, subShapeIndex, hitShapeId)
    if hitActorId == nil then
        self:finishDischargeRaycast()
        return
    end

    ---@type FillUnit
    local object = g_currentMission:getNodeObject(hitActorId)
    distance = distance - self.raycast.yOffset

    local validObject = object ~= nil and object ~= self.vehicle

    if validObject and distance < 0 and object.getFillUnitIndexFromNode ~= nil then
        validObject = validObject and object:getFillUnitIndexFromNode(hitShapeId) ~= nil
    end

    if validObject then
        if object.getFillUnitIndexFromNode ~= nil then
            ---@type number | nil
            local fillUnitIndex = object:getFillUnitIndexFromNode(hitShapeId)

            if fillUnitIndex ~= nil then
                local fillTypeIndex = self.processor:getFillUnitFillTypeIndex(self.fillUnitIndex)

                if object:getFillUnitSupportsFillType(fillUnitIndex, fillTypeIndex) then
                    local allowFillType = object:getFillUnitAllowsFillType(fillUnitIndex, fillTypeIndex)
                    local allowToolType = object:getFillUnitSupportsToolType(fillUnitIndex, self.toolType)
                    local freeSpace = object:getFillUnitFreeCapacity(fillUnitIndex, fillTypeIndex, self.vehicle:getActiveFarm()) > 0

                    if allowFillType and allowToolType and freeSpace then
                        self.dischargeObject = object
                        self.dischargeDistance = distance
                        self.dischargeFillUnitIndex = fillUnitIndex

                        if object.getFillUnitExtraDistanceFromNode ~= nil then
                            self.dischargeExtraDistance = object:getFillUnitExtraDistanceFromNode(hitShapeId)
                        end
                    end
                end

                self.dischargeHit = true
                self.dischargeHitObject = object
                self.dischargeHitObjectUnitIndex = fillUnitIndex
            elseif self.dischargeHit then
                self.dischargeDistance = distance + (self.dischargeExtraDistance or 0)
                self.dischargeExtraDistance = nil

                self:updateDischargeInfo(x, y, z)

                return false
            end
        end
    elseif hitActorId == g_terrainNode then
        self.dischargeDistance = math.min(self.dischargeDistance, distance)
        self.dischargeHitTerrain = true

        self:updateDischargeInfo(x, y, z)

        return false
    end

    return true
end

---@param triggerId number
---@param otherActorId number
---@param onEnter boolean
---@param onLeave boolean
---@param onStay boolean
---@param otherShapeId number | nil
function ProcessorDischargeNode:dischargeTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
    if onEnter or onLeave then
        local object = g_currentMission:getNodeObject(otherActorId)

        if object ~= nil and object ~= self and object.getFillUnitIndexFromNode ~= nil then
            local fillUnitIndex = object:getFillUnitIndexFromNode(otherShapeId)

            if fillUnitIndex ~= nil then
                local trigger = self.trigger

                if onEnter then
                    if trigger.objects[object] == nil then
                        trigger.objects[object] = {
                            count = 0,
                            fillUnitIndex = fillUnitIndex,
                            shape = otherShapeId
                        }
                        trigger.numObjects = trigger.numObjects + 1

                        object:addDeleteListener(self, "onDeleteDischargeTriggerObject")
                    end

                    trigger.objects[object].count = trigger.objects[object].count + 1

                    self.vehicle:raiseActive()
                elseif onLeave then
                    trigger.objects[object].count = trigger.objects[object].count - 1

                    if trigger.objects[object].count == 0 then
                        trigger.objects[object] = nil
                        trigger.numObjects = trigger.numObjects - 1

                        object:removeDeleteListener(self, "onDeleteDischargeTriggerObject")
                    end
                end
            end
        end
    end
end

---@param triggerId number
---@param otherActorId number
---@param onEnter boolean
---@param onLeave boolean
---@param onStay boolean
---@param otherShapeId number | nil
function ProcessorDischargeNode:dischargeActivationTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
    if onEnter or onLeave then
        local object = g_currentMission:getNodeObject(otherActorId)

        if object ~= nil and object ~= self and object.getFillUnitIndexFromNode ~= nil then
            local fillUnitIndex = object:getFillUnitIndexFromNode(otherShapeId)

            if fillUnitIndex ~= nil then
                local trigger = self.activationTrigger

                if onEnter then
                    if trigger.objects[object] == nil then
                        trigger.objects[object] = {
                            count = 0,
                            fillUnitIndex = fillUnitIndex,
                            shape = otherShapeId
                        }
                        trigger.numObjects = trigger.numObjects + 1

                        object:addDeleteListener(self, "onDeleteActivationTriggerObject")
                    end

                    trigger.objects[object].count = trigger.objects[object].count + 1

                    self.vehicle:raiseActive()
                elseif onLeave then
                    trigger.objects[object].count = trigger.objects[object].count - 1

                    if trigger.objects[object].count == 0 then
                        trigger.objects[object] = nil
                        trigger.numObjects = trigger.numObjects - 1

                        object:removeDeleteListener(self, "onDeleteActivationTriggerObject")
                    end
                end
            end
        end
    end
end

---@param streamId number
---@param connection Connection
function ProcessorDischargeNode:writeStream(streamId, connection)
    if streamWriteBool(streamId, self.isEffectActiveSent) then
        streamWriteUIntN(streamId, math.clamp(math.floor(self.dischargeDistanceSent / self.maxDistance * 255), 1, 255), 8)
        streamWriteUIntN(streamId, self.processor:getFillUnitFillTypeIndex(self.fillUnitIndex), FillTypeManager.SEND_NUM_BITS)
    end

    streamWriteUIntN(streamId, self.currentDischargeState, Dischargeable.SEND_NUM_BITS_DISCHARGE_STATE)
end

---@param streamId number
---@param connection Connection
function ProcessorDischargeNode:readStream(streamId, connection)
    if streamReadBool(streamId) then
        local distance = streamReadUIntN(streamId, 8) * self.maxDistance / 255
        local fillTypeIndex = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)

        self.dischargeDistance = distance

        self:setDischargeEffectActive(true, true, fillTypeIndex)
        self:setDischargeEffectDistance(distance)
    else
        self:setDischargeEffectActive(false, true)
    end

    local state = streamReadUIntN(streamId, Dischargeable.SEND_NUM_BITS_DISCHARGE_STATE)

    self:setDischargeState(state, true)
end

---@param streamId number
---@param connection Connection
function ProcessorDischargeNode:writeUpdateStream(streamId, connection)
    if streamWriteBool(streamId, self.isEffectActiveSent) then
        streamWriteUIntN(streamId, math.clamp(math.floor(self.dischargeDistanceSent / self.maxDistance * 255), 1, 255), 8)
        streamWriteUIntN(streamId, self.processor:getFillUnitFillTypeIndex(self.fillUnitIndex), FillTypeManager.SEND_NUM_BITS)
    end
end

---@param streamId number
---@param connection Connection
function ProcessorDischargeNode:readUpdateStream(streamId, connection)
    if streamReadBool(streamId) then
        self.dischargeDistance = streamReadUIntN(streamId, 8) * self.maxDistance / 255

        local fillTypeIndex = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)

        self:setDischargeEffectActive(true, true, fillTypeIndex)
        self:setDischargeEffectDistance(self.dischargeDistance)
    else
        self:setDischargeEffectActive(false, true)
    end
end
