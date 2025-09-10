---@meta

---@class VehicleObject : Vehicle, FillUnit, FillVolume, TurnOnVehicle
---@field getIsTurnedOn fun(): boolean
---@field setDashboardsDirty fun(): boolean
---@field setMovingToolDirty fun()
---@field getMountObject fun(): Vehicle | nil
---@field getDynamicMountObject fun(): Vehicle | nil
VehicleObject = {}


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
---@field objects table
---@field numObjects number
