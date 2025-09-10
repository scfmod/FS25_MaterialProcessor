---@class ProcessorUtils
ProcessorUtils = {}

---@param node DischargeNode
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

---@param dischargeNode DischargeNode
---@param xmlFile XMLFile
---@param key string
function ProcessorUtils.loadDischargeRaycast(dischargeNode, xmlFile, key)
    ---@diagnostic disable-next-line: missing-fields
    dischargeNode.raycast = {}

    dischargeNode.raycast.useWorldNegYDirection = xmlFile:getValue(key .. '.raycast#useWorldNegYDirection', false)
    dischargeNode.raycast.yOffset = xmlFile:getValue(key .. '.raycast#yOffset', 0)

    dischargeNode.raycast.node = xmlFile:getValue(key .. '.raycast#node', dischargeNode.node, dischargeNode.vehicle.components, dischargeNode.vehicle.i3dMappings)

    local maxDistance = xmlFile:getValue(key .. '.raycast#maxDistance', 10)

    dischargeNode.maxDistance = xmlFile:getValue(key .. '#maxDistance', maxDistance)
end

---@param dischargeNode DischargeNode
---@param xmlFile XMLFile
---@param key string
function ProcessorUtils.loadDischargeTriggers(dischargeNode, xmlFile, key)
    ---@diagnostic disable-next-line: missing-fields
    dischargeNode.trigger = {}

    dischargeNode.trigger.node = xmlFile:getValue(key .. '.trigger#node', nil, dischargeNode.vehicle.components, dischargeNode.vehicle.i3dMappings)
    dischargeNode.trigger.objects = {}
    dischargeNode.trigger.numObjects = 0

    if dischargeNode.trigger.node ~= nil then
        addTrigger(dischargeNode.trigger.node, 'dischargeTriggerCallback', dischargeNode)
        setTriggerReportStatics(dischargeNode.trigger.node, true)
    end

    ---@diagnostic disable-next-line: missing-fields
    dischargeNode.activationTrigger = {}

    dischargeNode.activationTrigger.node = xmlFile:getValue(key .. '.activationTrigger#node', nil, dischargeNode.vehicle.components, dischargeNode.vehicle.i3dMappings)
    dischargeNode.activationTrigger.objects = {}
    dischargeNode.activationTrigger.numObjects = 0

    if dischargeNode.activationTrigger.node ~= nil then
        addTrigger(dischargeNode.activationTrigger.node, 'dischargeActivationTriggerCallback', dischargeNode)
    end
end

---@param dischargeNode DischargeNode
---@param xmlFile XMLFile
---@param key string
function ProcessorUtils.loadDischargeEffects(dischargeNode, xmlFile, key)
    dischargeNode.effects = g_effectManager:loadEffect(xmlFile, key .. '.effects', dischargeNode.vehicle.components, dischargeNode.vehicle, dischargeNode.vehicle.i3dMappings, math.huge)

    dischargeNode.animationName = xmlFile:getValue(key .. ".animation#name")
    dischargeNode.animationSpeed = xmlFile:getValue(key .. ".animation#speed", 1)
    dischargeNode.animationResetSpeed = xmlFile:getValue(key .. ".animation#resetSpeed", 1)

    if dischargeNode.isClient then
        dischargeNode.playSound = xmlFile:getValue(key .. '#playSound')
        dischargeNode.soundNode = xmlFile:getValue(key .. '#soundNode', nil, dischargeNode.vehicle.components, dischargeNode.vehicle.i3dMappings)

        if dischargeNode.playSound then
            dischargeNode.dischargeSample = g_soundManager:loadSampleFromXML(xmlFile, key, 'dischargeSound', dischargeNode.vehicle.baseDirectory, dischargeNode.vehicle.components, 0, AudioGroup.VEHICLE, dischargeNode.vehicle.i3dMappings, dischargeNode.vehicle)
        end

        if xmlFile:getValue(key .. '.dischargeSound#overwriteSharedSound', false) then
            dischargeNode.playSound = false
        end

        dischargeNode.fillLevelSoundThreshold = xmlFile:getValue(key .. '.fillLevelSound#threshold', 0.5)
        dischargeNode.fillLevelSoundThresholdIsGreater = xmlFile:getValue(key .. '.fillLevelSound#thresholdIsGreater', true)
        dischargeNode.fillLevelSample = g_soundManager:loadSampleFromXML(xmlFile, key, "fillLevelSound", dischargeNode.vehicle.baseDirectory, dischargeNode.vehicle.components, 0, AudioGroup.VEHICLE, dischargeNode.vehicle.i3dMappings, dischargeNode.vehicle)

        dischargeNode.dischargeStateSamples = g_soundManager:loadSamplesFromXML(xmlFile, key, "dischargeStateSound", dischargeNode.vehicle.baseDirectory, dischargeNode.vehicle.components, 0, AudioGroup.VEHICLE, dischargeNode.vehicle.i3dMappings, dischargeNode.vehicle)
        dischargeNode.animationNodes = g_animationManager:loadAnimations(xmlFile, key .. ".animationNodes", dischargeNode.vehicle.components, dischargeNode.vehicle, dischargeNode.vehicle.i3dMappings)
        dischargeNode.effectAnimationNodes = g_animationManager:loadAnimations(xmlFile, key .. ".effectAnimationNodes", dischargeNode.vehicle.components, dischargeNode.vehicle, dischargeNode.vehicle.i3dMappings)
    end

    dischargeNode.lastEffect = dischargeNode.effects[#dischargeNode.effects]
end

---@param node DischargeNode
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

    node.fillLevelObjectChanges = {}
    ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, key .. '.fillLevelObjectChanges', node.fillLevelObjectChanges, node.vehicle.components, node.vehicle)

    if #node.fillLevelObjectChanges == 0 then
        node.fillLevelObjectChanges = nil
    else
        node.fillLevelObjectChangeThreshold = xmlFile:getValue(key .. '.fillLevelObjectChanges#threshold', 0.5)
        ObjectChangeUtil.setObjectChanges(node.fillLevelObjectChanges, false, node.vehicle, node.vehicle.setMovingToolDirty)
    end
end
