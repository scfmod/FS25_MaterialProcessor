---@class FillUnitEntry
---@field fillUnitIndex number
---@field soundThreshold number
---@field soundThresholdCondition Condition
---@field soundRequiresTurnedOn boolean
---@field soundRequiresPoweredOn boolean
---@field sample? table
---@field fillLevelObjectChangeThreshold number
---@field fillLevelObjectChangeThresholdCondition Condition
---@field fillLevelObjectChangeRequiresTurnedOn boolean
---@field fillLevelObjectChangeRequiresPoweredOn boolean
---@field fillLevelObjectChanges? table

---@class FillUnitExtension_spec
---@field fillUnitEntries FillUnitEntry[]

---@class FillUnitExtension : VehicleObject
FillUnitExtension = {}

---@type string
FillUnitExtension.SPEC_NAME = 'spec_' .. g_currentModName .. '.fillUnitExtension'
FillUnitExtension.MOD_NAME = g_currentModName

function FillUnitExtension.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(FillUnit, specializations)
end

function FillUnitExtension.initSpecialization()
    ---@type XMLSchema
    local schema = Vehicle.xmlSchema
    local basePath = 'vehicle.fillUnitExtension.fillUnit(?)'
    schema:setXMLSpecializationType('FillUnitExtension')

    schema:register(XMLValueType.INT, basePath .. '#fillUnitIndex')

    SoundManager.registerSampleXMLPaths(schema, basePath, "fillLevelSound")
    schema:register(XMLValueType.FLOAT, basePath .. '.fillLevelSound#threshold', 'Defines at which fillUnit fill level percentage the sound is triggered', 0.9)
    schema:register(XMLValueType.BOOL, basePath .. '.fillLevelSound#thresholdIsGreater', 'Deprecated', true)
    schema:register(XMLValueType.STRING, basePath .. '.fillLevelSound#thresholdCondition', 'Sound starts playing based on defined condition and threshold value. Possible values: "<", "=", ">"', '>')
    schema:register(XMLValueType.BOOL, basePath .. '.fillLevelSound#requiresTurnedOn', 'Require vehicle to be powered on in order for sound can be playing', false)
    schema:register(XMLValueType.BOOL, basePath .. '.fillLevelSound#requiresPoweredOn', 'Require vehicle to be turned on in order for sound can be playing (if vehicle has TurnOn specialization)', true)

    ObjectChangeUtil.registerObjectChangeXMLPaths(schema, basePath .. ".fillLevelObjectChanges")
    schema:register(XMLValueType.FLOAT, basePath .. '.fillLevelObjectChanges#threshold', 'Defines at which fillUnit fill level percentage the object changes', 0.9)
    schema:register(XMLValueType.BOOL, basePath .. '.fillLevelObjectChanges#thresholdIsGreater', 'Deprecated', true)
    schema:register(XMLValueType.STRING, basePath .. '.fillLevelObjectChanges#thresholdCondition', 'Object changes are activated based on defined condition and threshold value. Possible values: "<", "=", ">"', '>')
    schema:register(XMLValueType.BOOL, basePath .. '.fillLevelObjectChanges#requiresTurnedOn', 'Require vehicle to be powered on in order for object changes can be active', false)
    schema:register(XMLValueType.BOOL, basePath .. '.fillLevelObjectChanges#requiresPoweredOn', 'Require vehicle to be turned on in order for object changes can be active (if vehicle has TurnOn specialization)', true)

    schema:setXMLSpecializationType()
end

function FillUnitExtension.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, 'onLoad', FillUnitExtension)
    SpecializationUtil.registerEventListener(vehicleType, 'onDelete', FillUnitExtension)
    SpecializationUtil.registerEventListener(vehicleType, 'onUpdateTick', FillUnitExtension)
end

function FillUnitExtension:onLoad()
    ---@type FillUnitExtension_spec
    local spec = self[FillUnitExtension.SPEC_NAME]

    spec.fillUnitEntries = {}

    ---@type XMLFile
    local xmlFile = self.xmlFile

    xmlFile:iterate('vehicle.fillUnitExtension.fillUnit', function (_, key)
        local entry = {}
        ---@cast entry FillUnitEntry

        entry.fillUnitIndex = xmlFile:getValue(key .. '#fillUnitIndex')

        if not self:getFillUnitExists(entry.fillUnitIndex) then
            Logging.xmlError(xmlFile, 'Invalid fillUnitIndex (%s)', key .. '#fillUnitIndex')
            return
        end

        if self.isClient then
            entry.soundRequiresPoweredOn = xmlFile:getValue(key .. '.fillLevelSound#requiresPoweredOn', true)
            entry.soundRequiresTurnedOn = xmlFile:getValue(key .. '.fillLevelSound#requiresTurnedOn', false)
            entry.soundThreshold = MathUtil.round(xmlFile:getValue(key .. '.fillLevelSound#threshold', 0.9), 3)
            entry.soundThresholdCondition = Condition.GREATER_THAN

            if xmlFile:hasProperty(key .. '.fillLevelSound#thresholdCondition') then
                entry.soundThresholdCondition = ProcessorUtils.getXMLCondition(xmlFile, key .. '.fillLevelSound#thresholdCondition', entry.soundThresholdCondition)
            elseif xmlFile:getValue(key .. '.fillLevelSound#thresholdIsGreater') == false then
                entry.soundThresholdCondition = Condition.LESSER_THAN
            end

            entry.sample = g_soundManager:loadSampleFromXML(xmlFile, key, "fillLevelSound", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        end

        entry.fillLevelObjectChanges = {}
        ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, key .. '.fillLevelObjectChanges', entry.fillLevelObjectChanges, self.components, self)

        if #entry.fillLevelObjectChanges == 0 then
            entry.fillLevelObjectChanges = nil
        else
            entry.fillLevelObjectChangeThreshold = MathUtil.round(xmlFile:getValue(key .. '.fillLevelObjectChanges#threshold', 0.9), 3)
            entry.fillLevelObjectChangeThresholdCondition = Condition.GREATER_THAN

            if xmlFile:hasProperty(key .. '.fillLevelObjectChanges#thresholdCondition') then
                entry.fillLevelObjectChangeThresholdCondition = ProcessorUtils.getXMLCondition(xmlFile, key .. '.fillLevelObjectChanges#thresholdCondition', entry.fillLevelObjectChangeThresholdCondition)
            elseif xmlFile:getValue(key .. '.fillLevelObjectChanges#thresholdIsGreater') == false then
                entry.fillLevelObjectChangeThresholdCondition = Condition.LESSER_THAN
            end

            entry.fillLevelObjectChangeRequiresPoweredOn = xmlFile:getValue(key .. '.fillLevelObjectChanges#requiresPoweredOn', true)
            entry.fillLevelObjectChangeRequiresTurnedOn = xmlFile:getValue(key .. '.fillLevelObjectChanges#requiresTurnedOn', false)
            ObjectChangeUtil.setObjectChanges(entry.fillLevelObjectChanges, false, self, self.setMovingToolDirty)
        end

        table.insert(spec.fillUnitEntries, entry)
    end)
end

function FillUnitExtension:onDelete()
    ---@type FillUnitExtension_spec
    local spec = self[FillUnitExtension.SPEC_NAME]

    for _, entry in ipairs(spec.fillUnitEntries) do
        g_soundManager:deleteSample(entry.sample)
    end
end

function FillUnitExtension:onUpdateTick(dt)
    ---@type FillUnitExtension_spec
    local spec = self[FillUnitExtension.SPEC_NAME]

    for _, entry in ipairs(spec.fillUnitEntries) do
        local fillLevelPct = MathUtil.round(self:getFillUnitFillLevelPercentage(entry.fillUnitIndex) or 0, 3)
        local isPowered = self:getIsPowered()
        ---@type boolean?
        local isTurnedOn

        if self.getIsTurnedOn ~= nil then
            isTurnedOn = self:getIsTurnedOn()
        end

        if entry.fillLevelObjectChanges ~= nil then
            local isActive = ProcessorUtils.getIsConditionFulfilled(fillLevelPct, entry.fillLevelObjectChangeThreshold, entry.fillLevelObjectChangeThresholdCondition)

            if entry.fillLevelObjectChangeRequiresTurnedOn and isTurnedOn == false then
                isActive = false
            elseif entry.fillLevelObjectChangeRequiresPoweredOn and not isPowered then
                isActive = false
            end

            ObjectChangeUtil.setObjectChanges(entry.fillLevelObjectChanges, isActive, self, self.setMovingToolDirty)
        end

        if self.isClient and entry.sample ~= nil then
            local playSample = ProcessorUtils.getIsConditionFulfilled(fillLevelPct, entry.soundThreshold, entry.soundThresholdCondition)
            local isPlaying = g_soundManager:getIsSamplePlaying(entry.sample)

            if entry.soundRequiresTurnedOn and isTurnedOn == false then
                playSample = false
            elseif entry.soundRequiresPoweredOn and not isPowered then
                playSample = false
            end

            if playSample and not isPlaying then
                g_soundManager:playSample(entry.sample)
            elseif not playSample and isPlaying then
                g_soundManager:stopSample(entry.sample)
            end

            if g_soundManager:getIsSamplePlaying(entry.sample) then
                self:raiseActive()
            end
        end
    end
end
