---@class DischargeNode
---@field vehicle MaterialProcessor
---@field processor Processor
---@field dirtyFlag number
---@field index number
---@field isServer boolean
---@field isClient boolean
---
---@field litersToDrop number
---@field fillUnitIndex number
---@field unloadInfoIndex number
---@field node number
---@field soundNode number
---@field trigger DischargeTrigger
---@field raycast DischargeRaycast
---@field info DischargeInfo
---@field currentDischargeState number
---@field activationTrigger DischargeTrigger
---@field effects table
---@field effectAnimationNodes table
---@field animationNodes table
---@field animationName? string
---@field animationSpeed number
---@field animationResetSpeed number
---@field lastEffect? table
---@field isEffectActive boolean
---@field isEffectActiveSent boolean
---@field stopEffectTime? number
---@field effectTurnOffThreshold number
---@field dischargeObject? VehicleObject
---@field dischargeHitObject? table
---@field dischargeHitObjectUnitIndex? number
---@field dischargeShape? number
---@field dischargeFillUnitIndex? number
---@field dischargeHit boolean
---@field dischargeHitTerrain boolean
---@field dischargeDistance number
---@field dischargeDistanceSent number
---@field lastDischargeObject? table
---@field emptySpeed number
---@field sample? table
---@field sharedSample? table
---@field dischargeSample? table
---@field dischargeStateSamples table
---@field turnOffSoundTimer? number
---@field stateObjectChanges? table
---@field fillUnitObjectChanges? table
---@field fillUnitObjectChangeThreshold number
---@field isAsyncRaycastActive boolean
---@field raycastDischargeObject? table
---@field raycastDischargeHitObject? table
---@field raycastDischargeHitObjectUnitIndex? number
---@field raycastDischargeHitTerrain? boolean
---@field raycastDischargeShape? number
---@field raycastDischargeDistance number
---@field raycastDischargeFillUnitIndex? number
---@field raycastDischargeHit boolean
---@field raycastDischargeExtraDistance number
---@field raycastCollisionMask number
---@field maxDistance number
---@field toolType number
---@field distanceObjectChanges? table
---@field distanceObjectChangeThreshold number
---@field lineOffset number
---@field playSound boolean
---@field fillLevelSoundThreshold number
---@field fillLevelSoundThresholdIsGreater boolean
---@field fillLevelSample? table
---
---@field canFillOwnVehicle boolean
---@field canDischargeToVehicle boolean
---@field canStartGroundDischargeAutomatically boolean
---@field stopDischargeIfNotPossible boolean
DischargeNode = {}

DischargeNode.RAYCAST_COLLISION_MASK = CollisionFlag.FILLABLE + CollisionFlag.VEHICLE + CollisionFlag.TERRAIN
DischargeNode.SEND_NUM_BITS_INDEX = 4

local DischargeNode_mt = Class(DischargeNode)

---@param schema XMLSchema
---@param key string
function DischargeNode.registerXMLPaths(schema, key)
    schema:register(XMLValueType.NODE_INDEX, key .. '#node', 'Vehicle discharge node', nil, true)

    schema:register(XMLValueType.INT, key .. '#fillUnitIndex', 'Vehicle fillUnitIndex', nil, true)

    schema:register(XMLValueType.BOOL, key .. '#stopDischargeIfNotPossible')
    schema:register(XMLValueType.INT, key .. '#unloadInfoIndex', 'Unload info index', 1)
    schema:register(XMLValueType.FLOAT, key .. '#effectTurnOffThreshold', 'After this time has passed and nothing has been discharged the effects are turned off', 0.25)
    schema:register(XMLValueType.FLOAT, key .. '#maxDistance', 'Max discharge distance', 10)
    schema:register(XMLValueType.INT, key .. '#emptySpeed', 'Discharge speed in liters/second', 250)
    schema:register(XMLValueType.BOOL, key .. '#canFillOwnVehicle', 'Discharge node can fill other fill units of the vehicle itself', false)
    schema:register(XMLValueType.STRING, key .. '#toolType', 'Tool type', 'dischargable')
    schema:register(XMLValueType.BOOL, key .. '#allowDischargeWhenInactive', 'Allow discharging even if discharge node is not used by current configuration', false)

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
    schema:register(XMLValueType.FLOAT, key .. '.fillUnitObjectChanges#threshold', 'Defines at which fillUnit fill level percentage the object changes', 0.5)
    ObjectChangeUtil.registerObjectChangeXMLPaths(schema, key .. ".fillUnitObjectChanges")

    -- Discharge effects, animations
    schema:register(XMLValueType.NODE_INDEX, key .. '#soundNode', 'Sound node index path')
    schema:register(XMLValueType.BOOL, key .. '#playSound', 'Whether to play sounds', true)
    EffectManager.registerEffectXMLPaths(schema, key .. ".effects")
    SoundManager.registerSampleXMLPaths(schema, key, "dischargeSound")
    SoundManager.registerSampleXMLPaths(schema, key, "dischargeStateSound(?)")
    SoundManager.registerSampleXMLPaths(schema, key, 'fillLevelSound')
    schema:register(XMLValueType.FLOAT, key .. '.fillLevelSound#threshold', '', 0.5)
    schema:register(XMLValueType.BOOL, key .. '.fillLevelSound#thresholdIsGreater', '', true)
    schema:register(XMLValueType.BOOL, key .. ".dischargeSound#overwriteSharedSound", "Overwrite shared discharge sound with sound defined in discharge node", false)
    AnimationManager.registerAnimationNodesXMLPaths(schema, key .. ".animationNodes")
    AnimationManager.registerAnimationNodesXMLPaths(schema, key .. ".effectAnimationNodes")

    schema:register(XMLValueType.STRING, key .. ".animation#name", "Name of animation to play while discharging")
    schema:register(XMLValueType.FLOAT, key .. ".animation#speed", "Animation speed while discharging", 1)
    schema:register(XMLValueType.FLOAT, key .. ".animation#resetSpeed", "Animation speed while discharge has been stopped", 1)
end

---@param processor Processor
---@param index number
---@return DischargeNode
---@nodiscard
function DischargeNode.new(processor, index)
    ---@type DischargeNode
    local self = setmetatable({}, DischargeNode_mt)

    self.processor = processor
    self.vehicle = processor.vehicle
    self.dirtyFlag = processor.dirtyFlag
    self.index = index
    self.isServer = self.vehicle.isServer
    self.isClient = self.vehicle.isClient

    self.currentDischargeState = Dischargeable.DISCHARGE_STATE_OFF
    self.isEffectActive = false
    self.isEffectActiveSent = false
    self.effectTurnOffThreshold = 0.25
    self.dischargeDistance = 0
    self.dischargeDistanceSent = 0
    self.emptySpeed = 250 / 1000
    self.maxDistance = 20
    self.raycastCollisionMask = CollisionFlag.FILLABLE + CollisionFlag.VEHICLE + CollisionFlag.TERRAIN
    self.lineOffset = 0
    self.toolType = ToolType.UNDEFINED
    self.litersToDrop = 0

    self.canFillOwnVehicle = false
    self.canDischargeToVehicle = true
    self.canStartGroundDischargeAutomatically = true
    self.allowDischargeWhenInactive = false

    return self
end

function DischargeNode:delete()
    g_effectManager:deleteEffects(self.effects)
    g_soundManager:deleteSample(self.sample)
    g_soundManager:deleteSample(self.dischargeSample)
    g_soundManager:deleteSample(self.fillLevelSample)
    g_soundManager:deleteSamples(self.dischargeStateSamples)
    g_animationManager:deleteAnimations(self.animationNodes)
    g_animationManager:deleteAnimations(self.effectAnimationNodes)

    if self.trigger.node ~= nil then
        removeTrigger(self.trigger.node)

        for object, _ in pairs(self.trigger.objects) do
            if object.removeDeleteListener ~= nil then
                object:removeDeleteListener(self, "onDeleteDischargeTriggerObject")
            end
        end

        table.clear(self.trigger.objects)
        self.trigger.numObjects = 0
    end

    if self.activationTrigger.node ~= nil then
        removeTrigger(self.activationTrigger.node)

        for object, _ in pairs(self.activationTrigger.objects) do
            if object.removeDeleteListener ~= nil then
                object:removeDeleteListener(self, "onDeleteActivationTriggerObject")
            end
        end
        table.clear(self.activationTrigger.objects)
        self.activationTrigger.numObjects = 0
    end
end

---@param xmlFile XMLFile
---@param key string
---@return boolean
---@nodiscard
function DischargeNode:load(xmlFile, key)
    self.fillUnitIndex = xmlFile:getValue(key .. '#fillUnitIndex')

    if self.fillUnitIndex == nil then
        Logging.xmlError(xmlFile, 'Missing fillUnitIndex attribute (%s)', key .. '#fillUnitIndex')
        return false
    end

    if self.vehicle:getFillUnitByIndex(self.fillUnitIndex) == nil then
        Logging.xmlError(xmlFile, 'FillUnit index "%i" not found (%s)', self.fillUnitIndex, key .. '#fillUnitIndex')
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
    self.allowDischargeWhenInactive = xmlFile:getValue(key .. '#allowDischargeWhenInactive', self.allowDischargeWhenInactive)
    self.emptySpeed = xmlFile:getValue(key .. '#emptySpeed', 250) / 1000
    self.canFillOwnVehicle = xmlFile:getValue(key .. "#canFillOwnVehicle", false)

    local toolTypeStr = xmlFile:getValue(key .. "#toolType", "dischargeable")
    self.toolType = g_toolTypeManager:getToolTypeIndexByName(toolTypeStr)

    ProcessorUtils.loadDischargeInfo(self, xmlFile, key)
    ProcessorUtils.loadDischargeRaycast(self, xmlFile, key)
    ProcessorUtils.loadDischargeTriggers(self, xmlFile, key)
    ProcessorUtils.loadDischargeEffects(self, xmlFile, key)
    ProcessorUtils.loadDischargeObjectChanges(self, xmlFile, key)

    return true
end

---@return number
---@nodiscard
function DischargeNode:getDischargeFillType()
    return self.vehicle:getFillUnitFillType(self.fillUnitIndex) or FillType.UNKNOWN
end

---@return number
---@nodiscard
function DischargeNode:getFillLevel()
    return self.vehicle:getFillUnitFillLevel(self.fillUnitIndex) or 0
end

---@return number
---@nodiscard
function DischargeNode:getFillLevelPercentage()
    return self.vehicle:getFillUnitFillLevelPercentage(self.fillUnitIndex) or 0
end

---@return boolean
---@nodiscard
function DischargeNode:getCanDischargeToLand()
    if self.processor.canDischargeToGroundAnywhere then
        return true
    end

    local info = self.info
    local sx, _, sz = localToWorld(info.node, -info.width, 0, info.zOffset)
    local ex, _, ez = localToWorld(info.node, info.width, 0, info.zOffset)
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
function DischargeNode:getCanDischargeAtPosition()
    if self:getFillLevel() > 0 then
        local info = self.info
        local sx, sy, sz = localToWorld(info.node, -info.width, 0, info.zOffset)
        local ex, ey, ez = localToWorld(info.node, info.width, 0, info.zOffset)

        if self.currentDischargeState == Dischargeable.DISCHARGE_STATE_OFF or self.currentDischargeState == Dischargeable.DISCHARGE_STATE_GROUND then
            sy = sy + info.yOffset
            ey = ey + info.yOffset

            if info.limitToGround then
                sy = math.max(getTerrainHeightAtWorldPos(g_terrainNode, sx, 0, sz) + 0.1, sy)
                ey = math.max(getTerrainHeightAtWorldPos(g_terrainNode, ex, 0, ez) + 0.1, ey)
            end

            local fillType = self:getDischargeFillType()
            local testDrop = g_densityMapHeightManager:getMinValidLiterValue(fillType)
            if not DensityMapHeightUtil.getCanTipToGroundAroundLine(self.vehicle, testDrop, fillType, sx, sy, sz, ex, ey, ez, info.length, nil, self.lineOffset, true, nil, true) then
                return false
            end
        end
    end

    return true
end

---@param state number
---@param noEventSend? boolean
function DischargeNode:setDischargeState(state, noEventSend)
    if state ~= self.currentDischargeState then
        SetDischargeNodeStateEvent.sendEvent(self.vehicle, self.index, state, noEventSend)

        self.currentDischargeState = state

        if self.isServer and state == Dischargeable.DISCHARGE_STATE_OFF then
            self:setDischargeEffectActive(false)
        end

        if self.isClient then
            if state == Dischargeable.DISCHARGE_STATE_OFF then
                g_animationManager:stopAnimations(self.animationNodes)
                g_soundManager:stopSamples(self.dischargeStateSamples)
            else
                g_animationManager:startAnimations(self.animationNodes)
                g_soundManager:playSamples(self.dischargeStateSamples)
            end
        end

        if self.stateObjectChanges ~= nil then
            ObjectChangeUtil.setObjectChanges(self.stateObjectChanges, state ~= Dischargeable.DISCHARGE_STATE_OFF, self.vehicle, self.vehicle.setMovingToolDirty)
        end

        if self.animationName ~= nil then
            if state == Dischargeable.DISCHARGE_STATE_OFF then
                ---@diagnostic disable-next-line: undefined-field
                self.vehicle:playAnimation(self.animationName, -self.animationResetSpeed, self.vehicle:getAnimationTime(self.animationName), true)
            else
                ---@diagnostic disable-next-line: undefined-field
                self.vehicle:playAnimation(self.animationName, self.animationSpeed, self.vehicle:getAnimationTime(self.animationName), true)
            end
        end
    end
end

---@param isActive boolean
---@param force? boolean
---@param fillTypeIndex? number
function DischargeNode:setDischargeEffectActive(isActive, force, fillTypeIndex)
    if isActive then
        if not self.isEffectActive then
            if fillTypeIndex == nil then
                fillTypeIndex = self:getDischargeFillType()
            end
            g_effectManager:setEffectTypeInfo(self.effects, fillTypeIndex)
            g_effectManager:startEffects(self.effects)
            g_animationManager:startAnimations(self.effectAnimationNodes)
            self.isEffectActive = true
        end
        self.stopEffectTime = nil
    elseif force == nil or not force then
        if self.stopEffectTime == nil then
            self.stopEffectTime = g_time + self.effectTurnOffThreshold
            self.vehicle:raiseActive()
        end
    elseif self.isEffectActive then
        g_effectManager:stopEffects(self.effects)
        g_animationManager:stopAnimations(self.effectAnimationNodes)
        self.isEffectActive = false
    end
    if self.isServer and self.isEffectActive ~= self.isEffectActiveSent then
        self.vehicle:raiseDirtyFlags(self.dirtyFlag)
        self.isEffectActiveSent = self.isEffectActive
    end
end

---@param distance number
function DischargeNode:setDischargeEffectDistance(distance)
    if self.isEffectActive and (self.effects ~= nil and distance ~= math.huge) then
        for _, effect in pairs(self.effects) do
            if effect.setDistance ~= nil then
                effect:setDistance(distance, g_terrainNode)
            end
        end
    end
end

---@param dt number
function DischargeNode:update(dt)
    if self.activationTrigger.numObjects > 0 or self.currentDischargeState ~= Dischargeable.DISCHARGE_STATE_OFF then
        self.vehicle:raiseActive()
    end
end

---@param dt number
function DischargeNode:updateTick(dt)
    if self.vehicle:getIsProcessingEnabled() then
        if self.trigger.numObjects > 0 then
            local lastDischargeObject = self.dischargeObject

            self.dischargeObject = nil
            self.dischargeHitObject = nil
            self.dischargeHitObjectUnitIndex = nil
            self.dischargeShape = nil
            self.dischargeDistance = 0
            self.dischargeFillUnitIndex = nil
            self.dischargeHit = false

            local nearestDistance = math.huge

            for object, data in pairs(self.trigger.objects) do
                local fillType = self:getDischargeFillType()

                if object:getFillUnitSupportsFillType(data.fillUnitIndex, fillType) then
                    local allowFillType = object:getFillUnitAllowsFillType(data.fillUnitIndex, fillType)
                    local allowToolType = object:getFillUnitSupportsToolType(data.fillUnitIndex, ToolType.TRIGGER)
                    local freeSpace = object:getFillUnitFreeCapacity(data.fillUnitIndex, fillType, self.vehicle:getActiveFarm()) > 0

                    if allowFillType and allowToolType and freeSpace then
                        local exactFillRootNode = object:getFillUnitExactFillRootNode(data.fillUnitIndex)
                        if exactFillRootNode ~= nil and entityExists(exactFillRootNode) then
                            local distance = calcDistanceFrom(self.node, exactFillRootNode)
                            if distance < nearestDistance then
                                self.dischargeObject = object
                                self.dischargeHitTerrain = false
                                self.dischargeShape = data.shape
                                self.dischargeDistance = distance
                                self.dischargeFillUnitIndex = data.fillUnitIndex
                                nearestDistance = distance

                                if object ~= lastDischargeObject then
                                    self.vehicle:raiseActive()
                                end
                            end
                        end
                    end

                    self.dischargeHitObject = object
                    self.dischargeHitObjectUnitIndex = data.fillUnitIndex
                end

                self.dischargeHit = true
            end

            if lastDischargeObject ~= nil and self.dischargeObject == nil then
                self.vehicle:raiseActive()
            end
        elseif not self.isAsyncRaycastActive then
            self:updateRaycast()
        end
    else
        if self.currentDischargeState ~= Dischargeable.DISCHARGE_STATE_OFF then
            self:setDischargeState(Dischargeable.DISCHARGE_STATE_OFF, true)
        end

        self.dischargeObject = nil
        self.dischargeHitObject = nil
        self.dischargeHitObjectUnitIndex = nil
        self.dischargeHitTerrain = false
        self.dischargeShape = nil
        self.dischargeDistance = 0
        self.dischargeFillUnitIndex = nil
        self.dischargeHit = false
    end

    if self.isClient then
        self:updateDischargeSound(dt)
        self:updateFillLevelSound(dt)
    end

    if self.fillUnitObjectChanges ~= nil then
        local fillLevelPct = self:getFillLevelPercentage()
        ObjectChangeUtil.setObjectChanges(self.fillUnitObjectChanges, fillLevelPct > self.fillUnitObjectChangeThreshold, self.vehicle, self.vehicle.setMovingToolDirty)
    end

    if self.isServer then
        if self.currentDischargeState == Dischargeable.DISCHARGE_STATE_OFF then
            if self.dischargeObject ~= nil then
                self:handleFoundDischargeObject()
            end
        elseif self.currentDischargeState == Dischargeable.DISCHARGE_STATE_GROUND and self.dischargeObject ~= nil and self:getCanDischargeToObject() then
            self:handleFoundDischargeObject()
        else
            local canDischarge = false
            local fillLevel = self:getFillLevel()

            if fillLevel > 0 and self.vehicle:getIsProcessingEnabled() then
                if self.currentDischargeState == Dischargeable.DISCHARGE_STATE_GROUND then
                    canDischarge = self:getCanDischargeToGround() and self:getCanDischargeToLand() and self:getCanDischargeAtPosition()
                else
                    canDischarge = self:getCanDischargeToObject()
                end
            end

            self:setDischargeEffectActive(canDischarge)
            self:setDischargeEffectDistance(self.dischargeDistance)

            if canDischarge and (self.lastEffect == nil or self.lastEffect:getIsFullyVisible()) then
                local emptyLiters = math.min(fillLevel, self.emptySpeed * dt)
                local dischargedLiters, minDropReached, hasMinDropFillLevel = self:discharge(emptyLiters)

                self:handleDischarge(dischargedLiters, minDropReached, hasMinDropFillLevel)
            end
        end

        if math.abs(self.dischargeDistanceSent - self.dischargeDistance) > 0.05 then
            self.vehicle:raiseDirtyFlags(self.dirtyFlag)
            self.dischargeDistanceSent = self.dischargeDistance
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

    if self.isClient then
        if self.dischargeSample ~= nil and g_soundManager:getIsSamplePlaying(self.dischargeSample) then
            self.vehicle:raiseActive()
        end
        if self.sample ~= nil and g_soundManager:getIsSamplePlaying(self.sample) then
            self.vehicle:raiseActive()
        end
    end
end

---@param emptyLiters number
---@return number dischargedLiters
---@return boolean minDropReached
---@return boolean hasMinDropFillLevel
---@nodiscard
function DischargeNode:discharge(emptyLiters)
    local dischargedLiters = 0
    local minDropReached = true
    local hasMinDropFillLevel = true
    local object, fillUnitIndex = self.dischargeObject, self.dischargeFillUnitIndex

    if object ~= nil then
        if self.currentDischargeState == Dischargeable.DISCHARGE_STATE_OBJECT then
            dischargedLiters = self:dischargeToObject(emptyLiters, object, fillUnitIndex)
        end
    elseif self.dischargeHitTerrain then
        if self.currentDischargeState == Dischargeable.DISCHARGE_STATE_GROUND then
            dischargedLiters, minDropReached, hasMinDropFillLevel = self:dischargeToGround(emptyLiters)
        end
    end

    return dischargedLiters, minDropReached, hasMinDropFillLevel
end

---@param emptyLiters number
---@return number dischargedLiters
---@return boolean minDropReached
---@return boolean hasMinDropFillLevel
---@nodiscard
function DischargeNode:dischargeToGround(emptyLiters)
    if emptyLiters == 0 then
        return 0, false, false
    end

    local fillType = self:getDischargeFillType()
    local fillLevel = self:getFillLevel()
    local minLiterToDrop = g_densityMapHeightManager:getMinValidLiterValue(fillType)

    self.litersToDrop = math.min(self.litersToDrop + emptyLiters, math.max(self.emptySpeed * 250, minLiterToDrop))

    local minDropReached = self.litersToDrop > minLiterToDrop
    local hasMinDropFillLevel = fillLevel > minLiterToDrop
    local info = self.info
    local dischargedLiters = 0
    local sx, sy, sz = localToWorld(info.node, -info.width, 0, info.zOffset)
    local ex, ey, ez = localToWorld(info.node, info.width, 0, info.zOffset)

    sy = sy + info.yOffset
    ey = ey + info.yOffset

    if info.limitToGround then
        sy = math.max(getTerrainHeightAtWorldPos(g_terrainNode, sx, 0, sz) + 0.1, sy)
        ey = math.max(getTerrainHeightAtWorldPos(g_terrainNode, ex, 0, ez) + 0.1, ey)
    end

    local dropped, lineOffset = DensityMapHeightUtil.tipToGroundAroundLine(self.vehicle, self.litersToDrop, fillType, sx, sy, sz, ex, ey, ez, info.length, nil, self.lineOffset, true, nil, true)
    self.lineOffset = lineOffset
    self.litersToDrop = self.litersToDrop - dropped

    if dropped > 0 then
        local unloadInfo = self.vehicle:getFillVolumeUnloadInfo(self.unloadInfoIndex)
        dischargedLiters = self.vehicle:addFillUnitFillLevel(self.vehicle:getOwnerFarmId(), self.fillUnitIndex, -dropped, fillType, ToolType.UNDEFINED, unloadInfo)
    end

    fillLevel = self:getFillLevel()
    if fillLevel > 0 and fillLevel <= minLiterToDrop then
        self.litersToDrop = minLiterToDrop
    end

    return dischargedLiters, minDropReached, hasMinDropFillLevel
end

---@param emptyLiters number
---@param object VehicleObject
---@param targetFillUnitIndex? number
---@return number
---@nodiscard
function DischargeNode:dischargeToObject(emptyLiters, object, targetFillUnitIndex)
    local fillType = self:getDischargeFillType()
    local supportsFillType = object:getFillUnitSupportsFillType(targetFillUnitIndex, fillType)
    local dischargedLiters = 0

    if supportsFillType then
        local allowFillType = object:getFillUnitAllowsFillType(targetFillUnitIndex, fillType)
        if self.processor.canDischargeToAnyObject or allowFillType then
            self.currentDischargeObject = object

            local targetActiveFarm = self.vehicle:getActiveFarm()

            if self.processor.canDischargeToAnyObject then
                if object.getActiveFarm ~= nil then
                    targetActiveFarm = object:getActiveFarm()
                elseif object.getOwnerFarmId ~= nil then
                    targetActiveFarm = object:getOwnerFarmId()
                end
            end

            local delta = object:addFillUnitFillLevel(targetActiveFarm, targetFillUnitIndex, emptyLiters, fillType, self.toolType, self.info)
            local unloadInfo = self.vehicle:getFillVolumeUnloadInfo(self.unloadInfoIndex)

            dischargedLiters = self.vehicle:addFillUnitFillLevel(self.vehicle:getOwnerFarmId(), self.fillUnitIndex, -delta, fillType, ToolType.UNDEFINED, unloadInfo)
        end
    end

    return dischargedLiters
end

---@param dischargedLiters number
---@param minDropReached boolean
---@param hasMinDropFillLevel boolean
function DischargeNode:handleDischarge(dischargedLiters, minDropReached, hasMinDropFillLevel)
    if self.currentDischargeState == Dischargeable.DISCHARGE_STATE_GROUND then
        local canDrop = not minDropReached and hasMinDropFillLevel

        if self.stopDischargeIfNotPossible then
            if dischargedLiters == 0 and not canDrop then
                self:setDischargeState(Dischargeable.DISCHARGE_STATE_OFF)
            end
        end
    else
        if self.stopDischargeIfNotPossible then
            if dischargedLiters == 0 then
                self:setDischargeState(Dischargeable.DISCHARGE_STATE_OFF)
            end
        end
    end
end

function DischargeNode:handleFoundDischargeObject()
    if self.vehicle:getIsProcessingEnabled() then
        self:setDischargeState(Dischargeable.DISCHARGE_STATE_OBJECT)
    end
end

---@return boolean
---@nodiscard
function DischargeNode:getIsActive()
    return self.allowDischargeWhenInactive or self.processor:getFillUnitIsActive(self.fillUnitIndex)
end

---@return boolean
---@nodiscard
function DischargeNode:getCanDischargeToGround()
    if not self.processor.canDischargeToGround then
        return false
    elseif not self.dischargeHitTerrain then
        return false
    elseif not self:getIsActive() then
        return false
    end

    if self:getFillLevel() > 0 then
        local fillTypeIndex = self:getDischargeFillType()
        if not DensityMapHeightUtil.getCanTipToGround(fillTypeIndex) then
            return false
        end
    end

    return true
end

---@return boolean
---@nodiscard
function DischargeNode:getCanDischargeToObject()
    local object = self.dischargeObject

    if object == nil then
        return false
    elseif not self:getIsActive() then
        return false
    end

    local fillType = self:getDischargeFillType()

    if not object:getFillUnitSupportsFillType(self.dischargeFillUnitIndex, fillType) then
        return false
    end

    if not object:getFillUnitAllowsFillType(self.dischargeFillUnitIndex, fillType) then
        return false
    end

    if object.getFillUnitFreeCapacity ~= nil and object:getFillUnitFreeCapacity(self.dischargeFillUnitIndex, fillType, self.vehicle:getActiveFarm()) <= 0 then
        return false
    end

    if not self.processor.canDischargeToAnyObject and object.getIsFillAllowedFromFarm ~= nil and not object:getIsFillAllowedFromFarm(self.vehicle:getActiveFarm()) then
        return false
    end

    if self.vehicle.getDynamicMountObject ~= nil then
        local mounter = self.vehicle:getDynamicMountObject()

        if mounter ~= nil then
            if not self.processor.canDischargeToAnyObject and not g_currentMission.accessHandler:canFarmAccess(mounter:getActiveFarm(), self.vehicle, true) then
                return false
            end
        end
    end

    return true
end

function DischargeNode:updateRaycast()
    local raycast = self.raycast

    if raycast.node == nil then
        return
    end

    self.lastDischargeObject = self.dischargeObject
    self.raycastDischargeObject = nil
    self.raycastDischargeHitObject = nil
    self.raycastDischargeHitObjectUnitIndex = nil
    self.raycastDischargeHitTerrain = false
    self.raycastDischargeShape = nil
    self.raycastDischargeDistance = math.huge
    self.raycastDischargeFillUnitIndex = nil
    self.raycastDischargeHit = false

    local x, y, z = getWorldTranslation(raycast.node)
    local dx, dy, dz = 0, -1, 0

    y = y + raycast.yOffset

    if not raycast.useWorldNegYDirection then
        dx, dy, dz = localDirectionToWorld(raycast.node, 0, -1, 0)
    end

    self.isAsyncRaycastActive = true


    raycastAllAsync(x, y, z, dx, dy, dz, self.maxDistance, "raycastCallback", self, self.raycastCollisionMask)
end

---@param hitActorId number
---@param x number
---@param y number
---@param z number
---@param distance number
---@param nx number
---@param ny number
---@param nz number
---@param subShapeIndex? number
---@param hitShapeId? number
---@param isLast boolean
---@return boolean?
function DischargeNode:raycastCallback(hitActorId, x, y, z, distance, nx, ny, nz, subShapeIndex, hitShapeId, isLast)
    if self.vehicle.isDeleted or self.vehicle.isDeleting then
        return
    end

    if hitActorId ~= 0 then
        local object = g_currentMission:getNodeObject(hitActorId)

        distance = distance - self.raycast.yOffset

        local validObject = object ~= nil and (object ~= self.vehicle or self.canFillOwnVehicle)

        if validObject and distance < 0 then
            if object.getFillUnitIndexFromNode ~= nil then
                validObject = validObject and object:getFillUnitIndexFromNode(hitShapeId) ~= nil
            end

            if not self.canDischargeToVehicle then
                validObject = validObject and not object:isa(Vehicle)
            end
        end

        if validObject then
            if object.getFillUnitIndexFromNode ~= nil then
                local fillUnitIndex = object:getFillUnitIndexFromNode(hitShapeId)
                if fillUnitIndex ~= nil then
                    local fillType = self:getDischargeFillType()

                    if object:getFillUnitSupportsFillType(fillUnitIndex, fillType) then
                        local allowFillType = object:getFillUnitAllowsFillType(fillUnitIndex, fillType)
                        local allowToolType = object:getFillUnitSupportsToolType(fillUnitIndex, self.toolType)
                        local freeSpace = object:getFillUnitFreeCapacity(fillUnitIndex, fillType, self.vehicle:getActiveFarm()) > 0

                        if allowFillType and allowToolType and freeSpace then
                            self.raycastDischargeObject = object
                            self.raycastDischargeShape = hitShapeId
                            self.raycastDischargeDistance = distance
                            self.raycastDischargeFillUnitIndex = fillUnitIndex

                            if object.getFillUnitExtraDistanceFromNode ~= nil then
                                self.raycastDischargeExtraDistance = object:getFillUnitExtraDistanceFromNode(hitShapeId)
                            end
                        end
                    end

                    self.raycastDischargeHit = true
                    self.raycastDischargeHitObject = object
                    self.raycastDischargeHitObjectUnitIndex = fillUnitIndex
                else
                    if self.raycastDischargeHit then
                        self.raycastDischargeDistance = distance + (self.raycastDischargeExtraDistance or 0)
                        self.raycastDischargeExtraDistance = nil
                        self:updateDischargeInfo(x, y, z)

                        self:finishDischargeRaycast()

                        return false
                    end
                end
            end
        elseif hitActorId == g_terrainNode then
            self.raycastDischargeDistance = math.min(self.raycastDischargeDistance, distance)
            self.raycastDischargeHitTerrain = true
            self:updateDischargeInfo(x, y, z)
            self:finishDischargeRaycast()
            return false
        end
    end

    if isLast then
        self:finishDischargeRaycast()
        return false
    end

    return true
end

function DischargeNode:finishDischargeRaycast()
    self.dischargeObject = self.raycastDischargeObject
    self.dischargeHitObject = self.raycastDischargeHitObject
    self.dischargeHitObjectUnitIndex = self.raycastDischargeHitObjectUnitIndex
    self.dischargeHitTerrain = self.raycastDischargeHitTerrain
    self.dischargeShape = self.raycastDischargeShape
    self.dischargeDistance = self.raycastDischargeDistance
    self.dischargeFillUnitIndex = self.raycastDischargeFillUnitIndex
    self.dischargeHit = self.raycastDischargeHit

    self:handleDischargeRaycast(self.dischargeObject, self.dischargeShape, self.dischargeDistance, self.dischargeFillUnitIndex, self.dischargeHitTerrain)
    self.isAsyncRaycastActive = false

    if self.lastDischargeObject ~= self.dischargeObject then
        self.vehicle:raiseActive()
    end
end

---@param object VehicleObject
---@param shape? number
---@param distance number
---@param fillUnitIndex number
---@param hitTerrain boolean
function DischargeNode:handleDischargeRaycast(object, shape, distance, fillUnitIndex, hitTerrain)
    if self.isServer then
        if object == nil and self.currentDischargeState == Dischargeable.DISCHARGE_STATE_OBJECT then
            self:setDischargeState(Dischargeable.DISCHARGE_STATE_OFF)
        end

        if object == nil and self.canStartGroundDischargeAutomatically then
            if self:getCanDischargeToGround() and self:getCanDischargeToLand() and self:getCanDischargeAtPosition() then
                self:setDischargeState(Dischargeable.DISCHARGE_STATE_GROUND)
            end
        end
    end

    if self.distanceObjectChanges ~= nil then
        ObjectChangeUtil.setObjectChanges(self.distanceObjectChanges, distance > self.distanceObjectChangeThreshold or self.currentDischargeState ~= Dischargeable.DISCHARGE_STATE_OFF, self.vehicle, self.vehicle.setMovingToolDirty)
    end
end

---@param x number
---@param y number
---@param z number
function DischargeNode:updateDischargeInfo(x, y, z)
    if self.info.useRaycastHitPosition then
        setWorldTranslation(self.info.node, x, y, z)
    end
end

function DischargeNode:updateFillLevelSound(dt)
    if self.playSound and self.fillLevelSample == nil then
        return
    end

    local fillLevelPct = self:getFillLevelPercentage()
    local playSample = (self.fillLevelSoundThresholdIsGreater and fillLevelPct > self.fillLevelSoundThreshold) or (not self.fillLevelSoundThresholdIsGreater and fillLevelPct < self.fillLevelSoundThreshold)
    local isPlaying = g_soundManager:getIsSamplePlaying(self.fillLevelSample)

    if playSample and not isPlaying then
        g_soundManager:playSample(self.fillLevelSample)
    elseif not playSample and isPlaying then
        g_soundManager:stopSample(self.fillLevelSample)
    end
end

---@param dt number
function DischargeNode:updateDischargeSound(dt)
    local fillType = self:getDischargeFillType()
    local isInDischargeState = self.currentDischargeState ~= Dischargeable.DISCHARGE_STATE_OFF
    local isEffectActive = self.isEffectActive and fillType ~= FillType.UNKNOWN
    local lastEffectVisible = self.lastEffect == nil or self.lastEffect:getIsVisible()
    local effectsStillActive = self.lastEffect ~= nil and self.lastEffect:getIsVisible()

    if ((isInDischargeState and isEffectActive) or effectsStillActive) and lastEffectVisible then
        if self.playSound and fillType ~= FillType.UNKNOWN then
            local sharedSample = g_fillTypeManager:getSampleByFillType(fillType)
            if sharedSample ~= nil then
                if sharedSample ~= self.sharedSample then
                    if self.sample ~= nil then
                        g_soundManager:deleteSample(self.sample)
                    end

                    self.sample = g_soundManager:cloneSample(sharedSample, self.node or self.soundNode, self.vehicle)
                    self.sharedSample = sharedSample

                    g_soundManager:playSample(self.sample)
                else
                    if not g_soundManager:getIsSamplePlaying(self.sample) then
                        g_soundManager:playSample(self.sample)
                    end
                end
            end
        end

        if self.dischargeSample ~= nil then
            if not g_soundManager:getIsSamplePlaying(self.dischargeSample) then
                g_soundManager:playSample(self.dischargeSample)
            end
        end
        self.turnOffSoundTimer = 250
    else
        if self.turnOffSoundTimer ~= nil and self.turnOffSoundTimer > 0 then
            self.turnOffSoundTimer = self.turnOffSoundTimer - dt
            if self.turnOffSoundTimer <= 0 then
                if self.playSound then
                    if g_soundManager:getIsSamplePlaying(self.sample) then
                        g_soundManager:stopSample(self.sample)
                    end
                end

                if self.dischargeSample ~= nil then
                    if g_soundManager:getIsSamplePlaying(self.dischargeSample) then
                        g_soundManager:stopSample(self.dischargeSample)
                    end
                end

                self.turnOffSoundTimer = 0
            end
        end
    end
end

---@param triggerId number
---@param otherActorId number
---@param onEnter boolean
---@param onLeave boolean
---@param onStay boolean
---@param otherShapeId number
function DischargeNode:dischargeTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
    if onEnter or onLeave then
        local object = g_currentMission:getNodeObject(otherActorId)
        if object ~= nil and object ~= self.vehicle then
            if object.getFillUnitIndexFromNode ~= nil then
                local fillUnitIndex = object:getFillUnitIndexFromNode(otherShapeId)

                local validObject = fillUnitIndex ~= nil
                if not self.canDischargeToVehicle then
                    validObject = validObject and not object:isa(Vehicle)
                end

                if validObject then
                    local trigger = self.trigger
                    if onEnter then
                        if trigger.objects[object] == nil then
                            trigger.objects[object] = { count = 0, fillUnitIndex = fillUnitIndex, shape = otherShapeId }
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

                            if object == self.dischargeObject then
                                self.dischargeObject = nil
                                self.dischargeHitTerrain = false
                                self.dischargeShape = nil
                                self.dischargeDistance = 0
                                self.dischargeFillUnitIndex = nil
                            end

                            object:removeDeleteListener(self, "onDeleteDischargeTriggerObject")
                        end
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
---@param otherShapeId number
function DischargeNode:dischargeActivationTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
    if onEnter or onLeave then
        local object = g_currentMission:getNodeObject(otherActorId)
        if object ~= nil and object ~= self.vehicle then
            if object.getFillUnitIndexFromNode ~= nil then
                local fillUnitIndex = object:getFillUnitIndexFromNode(otherShapeId)

                if fillUnitIndex ~= nil then
                    local trigger = self.activationTrigger
                    if onEnter then
                        if trigger.objects[object] == nil then
                            trigger.objects[object] = { count = 0, fillUnitIndex = fillUnitIndex, shape = otherShapeId }
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
end

---@param streamId number
---@param connection Connection
function DischargeNode:writeStream(streamId, connection)
    if streamWriteBool(streamId, self.isEffectActiveSent) then
        streamWriteUIntN(streamId, math.clamp(math.floor(self.dischargeDistanceSent / self.maxDistance * 255), 1, 255), 8)
        streamWriteUIntN(streamId, self:getDischargeFillType(), FillTypeManager.SEND_NUM_BITS)
    end

    streamWriteUIntN(streamId, self.currentDischargeState, Dischargeable.SEND_NUM_BITS_DISCHARGE_STATE)
end

---@param streamId number
---@param connection Connection
function DischargeNode:readStream(streamId, connection)
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
function DischargeNode:writeUpdateStream(streamId, connection)
    if streamWriteBool(streamId, self.isEffectActiveSent) then
        streamWriteUIntN(streamId, math.clamp(math.floor(self.dischargeDistanceSent / self.maxDistance * 255), 1, 255), 8)
        streamWriteUIntN(streamId, self:getDischargeFillType(), FillTypeManager.SEND_NUM_BITS)
    end
end

---@param streamId number
---@param connection Connection
function DischargeNode:readUpdateStream(streamId, connection)
    if streamReadBool(streamId) then
        self.dischargeDistance = streamReadUIntN(streamId, 8) * self.maxDistance / 255

        local fillTypeIndex = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)

        self:setDischargeEffectActive(true, true, fillTypeIndex)
        self:setDischargeEffectDistance(self.dischargeDistance)
    else
        self:setDischargeEffectActive(false, true)
    end
end
