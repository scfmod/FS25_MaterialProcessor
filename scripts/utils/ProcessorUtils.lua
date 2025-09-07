---@class ProcessorUtils
ProcessorUtils = {}

---@param node ProcessorDischargeNode
---@param xmlFile XMLFile
---@param key string
function ProcessorUtils.loadDischargeInfo(node, xmlFile, key)
    ---@diagnostic disable-next-line: missing-fields
    node.info = {}

    node.info.width = xmlFile:getValue(key .. '.info#width', 1) / 2
    node.info.length = xmlFile:getValue(key .. '.info#length', 1) / 2
    node.info.zOffset = xmlFile:getValue(key .. '.info#zOffset', 0)
    node.info.yOffset = xmlFile:getValue(key .. '.info#yOffset', 2)
    node.info.limitToGround = xmlFile:getValue(key .. '.info#limitToGround', true)
    node.info.useRaycastHitPosition = xmlFile:getValue(key .. '.info#useRaycastHitPosition', false)

    node.info.node = xmlFile:getValue(key .. '.info#node', node.node, node.vehicle.components, node.vehicle.i3dMappings)

    if node.info.node == node.node then
        node.info.node = createTransformGroup('dischargeInfoNode')
        link(node.node, node.info.node)
    end

    node.unloadInfoIndex = xmlFile:getValue(key .. '#unloadInfoIndex', 1)
end

---@param node ProcessorDischargeNode
---@param xmlFile XMLFile
---@param key string
function ProcessorUtils.loadDischargeRaycast(node, xmlFile, key)
    ---@diagnostic disable-next-line: missing-fields
    node.raycast = {}

    node.raycast.useWorldNegYDirection = xmlFile:getValue(key .. '.raycast#useWorldNegYDirection', false)
    node.raycast.yOffset = xmlFile:getValue(key .. '.raycast#yOffset', 0)

    node.raycast.node = xmlFile:getValue(key .. '.raycast#node', node.node, node.vehicle.components, node.vehicle.i3dMappings)

    local maxDistance = xmlFile:getValue(key .. '.raycast#maxDistance', 10)

    node.maxDistance = xmlFile:getValue(key .. '#maxDistance', maxDistance)
end

---@param node ProcessorDischargeNode
---@param xmlFile XMLFile
---@param key string
function ProcessorUtils.loadDischargeTriggers(node, xmlFile, key)
    ---@diagnostic disable-next-line: missing-fields
    node.trigger = {}

    node.trigger.node = xmlFile:getValue(key .. '.trigger#node', nil, node.vehicle.components, node.vehicle.i3dMappings)
    node.trigger.objects = {}
    node.trigger.numObjects = 0

    if node.trigger.node ~= nil then
        addTrigger(node.trigger.node, 'dischargeTriggerCallback', node)
    end

    ---@diagnostic disable-next-line: missing-fields
    node.activationTrigger = {}

    node.activationTrigger.node = xmlFile:getValue(key .. '.activationTrigger#node', nil, node.vehicle.components, node.vehicle.i3dMappings)
    node.activationTrigger.objects = {}
    node.activationTrigger.numObjects = 0

    if node.activationTrigger.node ~= nil then
        addTrigger(node.activationTrigger.node, 'dischargeActivationTriggerCallback', node)
    end
end

---@param node ProcessorDischargeNode
---@param xmlFile XMLFile
---@param key string
function ProcessorUtils.loadDischargeEffects(node, xmlFile, key)
    node.effects = g_effectManager:loadEffect(xmlFile, key .. '.effects', node.vehicle.components, node.vehicle, node.vehicle.i3dMappings)

    if node.isClient then
        node.playSound = xmlFile:getValue(key .. '#playSound')
        node.soundNode = xmlFile:getValue(key .. '#soundNode', nil, node.vehicle.components, node.vehicle.i3dMappings)

        if node.playSound then
            node.dischargeSample = g_soundManager:loadSampleFromXML(xmlFile, key, 'dischargeSound', node.vehicle.baseDirectory, node.vehicle.components, 0, AudioGroup.VEHICLE, node.vehicle.i3dMappings, node.vehicle)
        end

        if xmlFile:getValue(key .. '.dischargeSound#overwriteSharedSound', false) then
            node.playSound = false
        end

        node.dischargeStateSamples = g_soundManager:loadSamplesFromXML(xmlFile, key, "dischargeStateSound", node.vehicle.baseDirectory, node.vehicle.components, 0, AudioGroup.VEHICLE, node.vehicle.i3dMappings, node.vehicle)
        node.animationNodes = g_animationManager:loadAnimations(xmlFile, key .. ".animationNodes", node.vehicle.components, node.vehicle, node.vehicle.i3dMappings)
    end

    node.lastEffect = node.effects[#node.effects]
end

---@param node ProcessorDischargeNode
---@param xmlFile XMLFile
---@param key string
function ProcessorUtils.loadDischargeObjectChanges(node, xmlFile, key)
    node.distanceObjectChanges = {}

    ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, key .. '.distanceObjectChanges', node.distanceObjectChanges, node.vehicle.components, node.vehicle)

    if #node.distanceObjectChanges == 0 then
        node.distanceObjectChanges = nil
    else
        node.distanceObjectChangeThreshold = xmlFile:getValue(key .. '.distanceObjectChanges#threshold', 0.5)
        ObjectChangeUtil.setObjectChanges(node.distanceObjectChanges, false, node.vehicle, node.vehicle.setMovingToolDirty)
    end


    node.stateObjectChanges = {}
    ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, key .. '.stateObjectChanges', node.stateObjectChanges, node.vehicle.components, node.vehicle)

    if #node.stateObjectChanges == 0 then
        node.stateObjectChanges = nil
    else
        ObjectChangeUtil.setObjectChanges(node.stateObjectChanges, false, node.vehicle, node.vehicle.setMovingToolDirty)
    end


    node.nodeActiveObjectChanges = {}
    ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, key .. '.nodeActiveObjectChanges', node.nodeActiveObjectChanges, node.vehicle.components, node.vehicle)

    if #node.nodeActiveObjectChanges == 0 then
        node.nodeActiveObjectChanges = nil
    else
        ObjectChangeUtil.setObjectChanges(node.nodeActiveObjectChanges, false, node.vehicle, node.vehicle.setMovingToolDirty)
    end
end
