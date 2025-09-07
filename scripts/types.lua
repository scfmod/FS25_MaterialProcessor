---@meta

---@class VehicleObject : Vehicle, FillUnit, FillVolume, TurnOnVehicle
---@field getIsTurnedOn fun(): boolean
---@field setDashboardsDirty fun(): boolean
---@field setMovingToolDirty fun()
---@field getMountObject fun(): Vehicle | nil
---@field getDynamicMountObject fun(): Vehicle | nil
VehicleObject = {}

---@class Parent
---@field components table
---@field i3dMappings table
---@field baseDirectory string

---@class DischargeInfo
---@field node number | nil
---@field width number
---@field length number
---@field zOffset number
---@field yOffset number
---@field limitToGround boolean
---@field useRaycastHitPosition boolean

---@class DischargeRaycast
---@field node number | nil
---@field useWorldNegYDirection boolean
---@field yOffset number

---@class DischargeTrigger
---@field node number | nil
---@field objects table<FillUnit, table>
---@field numObjects number

---@class DischargeNodeProperties
---@field effectTurnOffThreshold number
---@field lineOffset number
---@field litersToDrop number
---@field emptySpeed number
---@field toolType number
---@field maxDistance number
---@field info DischargeInfo
---@field raycast DischargeRaycast
---@field trigger DischargeTrigger
---@field activationTrigger DischargeTrigger
---@field effects table
---@field playSound boolean
---@field soundNode number | nil
---@field dischargeSample table | nil
---@field dischargeStateSamples table
---@field animationNodes table
---
---@field distanceObjectChanges table
---@field distanceObjectChangeThreshold number
---@field stateObjectChanges table
---@field nodeActiveObjectChanges table
---@field currentDischargeState number
---@field sample table | nil
---@field unloadInfoIndex number
---
---@field dischargeObject FillUnit | nil
---@field dischargeHit boolean
---@field dischargeHitObject table | nil
---@field dischargeHitObjectUnitIndex number | nil
---@field dischargeHitTerrain boolean
---@field dischargeDistance number
---@field dischargeDistanceSent number
---@field sentHitDistance number
---@field dischargeFillUnitIndex number | nil
---@field lastDischargeObject any
---@field isAsyncRaycastActive boolean | nil
---@field isEffectActive boolean
---@field isEffectActiveSent boolean
---@field stopEffectTime number | nil
---@field lastEffect table | nil
---@field currentDischargeObject table | nil
---@field stopDischargeIfNotPossible boolean

---@class TableElementRow
---@field dataRowIndex number
---@field rowElement GuiElement
---@field columnElements table<string, table>

---@class TableElementDataRow<Data>: { itemData: Data, id: number, columnNames: table<string, TableElementDataCell>, columnCells: table<string, table> }

---@class TableElementDataCell
---@field text string
---@field overrideProfileName string
---@field profileName string
---@field isVisible boolean
