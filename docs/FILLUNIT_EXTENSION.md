# FillUnitExtension

Utilize additional features for base game FillUnit specialization, enabling playing sound effects and toggling object changes based on fill level.

# Table of Contents

- [Add specialization to vehicle type](#add-specialization-to-vehicle-type)
- [Vehicle XML](#vehicle-xml)
- [FillUnit](#fillunit)
  - [Object changes](#object-changes)
  - [Sound](#sound)


## Add specialization to vehicle type

```xml
<?xml version="1.0" encoding="utf-8" standalone="no"?>
<modDesc version="...">
    ...
    <vehicleTypes>
        <!-- Extend parent type, can be anything -->
        <type name="..." parent="..." className="..." filename="...">
            ...
            <!-- Add entry after fillUnit specialization -->
            <specialization name="FS25_0_MaterialProcessor.fillUnitExtension" />
        </type>
    </vehicleTypes>
    ...
</modDesc>
```

## Vehicle XML

```xml
<?xml version="1.0" encoding="utf-8" standalone="no"?>
<vehicle>
    <fillUnitExtension>
        <fillUnit fillUnitIndex="2">
            <!-- Play alarm sound when fill level is below 10% -->
            <fillLevelSound threshold="0.1" thresholdIsGreater="false" template="rollbeltAlarm" linkNode="alarmSoundNode2" />
        </fillUnit>
        <fillUnit fillUnitIndex="3">
            <!-- Play alarm sound and activate object changes when fill level is above 85% -->
            <fillLevelSound threshold="0.85" template="rollbeltAlarm" linkNode="alarmSoundNode" />
            <fillLevelObjectChanges threshold="0.85">
                <objectChange node="alarmBeacon" visibilityActive="true" visibilityInactive="false" />
            </fillLevelObjectChanges>
        </fillUnit>
    </fillUnitExtension>
</vehicle>
```

## FillUnit

```
vehicle.fillUnitExtension.fillUnit(%)
```

### Attributes
| Name      | Type  | Required | Default | Description              |
|-----------|-------|----|-----------|------------------------------|
| fillUnitIndex | integer | Yes | | |


## Object changes

```
vehicle.fillUnitExtension.fillUnit(%).fillLevelObjectChanges
```

Trigger object changes based on the fill level percentage.

### Attributes
| Name      | Type  | Required | Default | Description              |
|-----------|-------|----|-----------|------------------------------|
| threshold | float | No | ```0.9```| Defines at which fillUnit fill level percentage the object changes |
| thresholdIsGreater | boolean | No  | ```true``` | If true the object changes are activated above threshold, if not then below threshold |
| requiresPoweredOn | boolean | No | ```true``` | Require vehicle to be powered on in order for object changes can be active |
| requiresTurnedOn | boolean | No | ```false``` | Require vehicle to be turned on in order for object changes can be active [^1] |

### Example
```xml
<?xml version="1.0" encoding="utf-8" standalone="no"?>
<vehicle>
    <fillUnitExtension>
        <fillUnit fillUnitIndex="3">
            <fillLevelObjectChanges threshold="0.85">
                <objectChange node="alarmBeacon" visibilityActive="true" visibilityInactive="false" />
            </fillLevelObjectChanges>
        </fillUnit>
    </fillUnitExtension>
</vehicle>
```

## Sound

```
vehicle.fillUnitExtension.fillUnit(%).fillLevelSound
```

Play sound depending on the fill level percentage.
Same as a normal vehicle sample entry, but with additional attributes.

### Attributes
| Name      | Type  | Required | Default | Description              |
|-----------|-------|----|-----------|------------------------------|
| threshold | float | No | ```0.9```| Defines at which fillUnit fill level percentage the sound is triggered |
| thresholdIsGreater | boolean | No  | ```true``` | If true the sound is triggered above threshold, if not then below threshold |
| requiresPoweredOn | boolean | No | ```true``` | Require vehicle to be powered on in order for sound can be playing |
| requiresTurnedOn | boolean | No | ```false``` | Require vehicle to be turned on in order for sound can be playing [^1] |

### Example
```xml
<?xml version="1.0" encoding="utf-8" standalone="no"?>
<vehicle>
    <fillUnitExtension>
        <fillUnit fillUnitIndex="3">
            <fillLevelSound threshold="0.95" template="rollbeltAlarm" linkNode="alarmSoundNode" />
        </fillUnit>
    </fillUnitExtension>
</vehicle>
```

[^1]: If the vehicle doesn't have a turn on function it will disregard this setting.