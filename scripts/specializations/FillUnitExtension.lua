---@class FillUnitEntry
---@field fillUnitIndex number
---@field soundThreshold number
---@field soundThresholdIsGreater boolean
---@field soundRequiresTurnedOn boolean
---@field soundRequiresPoweredOn boolean
---@field sample? table
---@field fillLevelObjectChangeThreshold number
---@field fillLevelObjectChangeThresholdIsGreater number
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
    schema:register(XMLValueType.FLOAT, basePath .. '.fillLevelSound#threshold', '', 0.9)
    schema:register(XMLValueType.BOOL, basePath .. '.fillLevelSound#thresholdIsGreater', '', true)
    schema:register(XMLValueType.BOOL, basePath .. '.fillLevelSound#requiresTurnedOn', '', false)
    schema:register(XMLValueType.BOOL, basePath .. '.fillLevelSound#requiresPoweredOn', '', true)

    ObjectChangeUtil.registerObjectChangeXMLPaths(schema, basePath .. ".fillLevelObjectChanges")
    schema:register(XMLValueType.FLOAT, basePath .. '.fillLevelObjectChanges#threshold', 'Defines at which fillUnit fill level percentage the object changes', 0.9)
    schema:register(XMLValueType.BOOL, basePath .. '.fillLevelObjectChanges#thresholdIsGreater', '', true)
    schema:register(XMLValueType.BOOL, basePath .. '.fillLevelObjectChanges#requiresTurnedOn', '', false)
    schema:register(XMLValueType.BOOL, basePath .. '.fillLevelObjectChanges#requiresPoweredOn', '', true)

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
            entry.soundThreshold = xmlFile:getValue(key .. '.fillLevelSound#threshold', 0.9)
            entry.soundThresholdIsGreater = xmlFile:getValue(key .. '.fillLevelSound#thresholdIsGreater', true)
            entry.sample = g_soundManager:loadSampleFromXML(xmlFile, key, "fillLevelSound", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        end

        entry.fillLevelObjectChanges = {}
        ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, key .. '.fillLevelObjectChanges', entry.fillLevelObjectChanges, self.components, self)

        if #entry.fillLevelObjectChanges == 0 then
            entry.fillLevelObjectChanges = nil
        else
            entry.fillLevelObjectChangeThreshold = xmlFile:getValue(key .. '.fillLevelObjectChanges#threshold', 0.9)
            entry.fillLevelObjectChangeThresholdIsGreater = xmlFile:getValue(key .. '.fillLevelObjectChanges#thresholdIsGreater', true)
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
        local fillLevelPct = self:getFillUnitFillLevelPercentage(entry.fillUnitIndex) or 0
        local isPowered = self:getIsPowered()
        ---@type boolean?
        local isTurnedOn

        if self.getIsTurnedOn ~= nil then
            isTurnedOn = self:getIsTurnedOn()
        end

        if entry.fillLevelObjectChanges ~= nil then
            local isActive = (entry.fillLevelObjectChangeThresholdIsGreater and fillLevelPct > entry.fillLevelObjectChangeThreshold) or (not entry.fillLevelObjectChangeThresholdIsGreater and fillLevelPct < entry.fillLevelObjectChangeThreshold)

            if entry.fillLevelObjectChangeRequiresTurnedOn and isTurnedOn == false then
                isActive = false
            elseif entry.fillLevelObjectChangeRequiresPoweredOn and not isPowered then
                isActive = false
            end

            ObjectChangeUtil.setObjectChanges(entry.fillLevelObjectChanges, isActive, self, self.setMovingToolDirty)
        end

        if self.isClient and entry.sample ~= nil then
            local playSample = (entry.soundThresholdIsGreater and fillLevelPct > entry.soundThreshold) or (not entry.soundThresholdIsGreater and fillLevelPct < entry.soundThreshold)
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
