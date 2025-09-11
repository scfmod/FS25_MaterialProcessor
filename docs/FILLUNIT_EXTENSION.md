# FillUnitExtension

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

## FillUnit

```
vehicle.fillUnitExtension.fillUnit(%)
```

### Attributes
| Name      | Type  | Required | Default | Description              |
|-----------|-------|----|-----------|------------------------------|
| fillUnitIndex | integer | Yes | | |


## Fill level object changes

```
vehicle.fillUnitExtension.fillUnit(%).fillLevelObjectChanges
```

Trigger object changes based on the fill level percentage.

### Attributes
| Name      | Type  | Required | Default | Description              |
|-----------|-------|----|-----------|------------------------------|
| threshold | float | No | ```0.9```| Defines at which fillUnit fill level percentage the object changes |
| thresholdIsGreater | boolean | No  | ```true``` | If true the object changes are activated above threshold, if not then below threshold |
| requiresPoweredOn | boolean | No | ```true``` | |
| requiresTurnedOn | boolean | No | ```false``` | |

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

## Fill level sound

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
| requiresPoweredOn | boolean | No | ```true``` | |
| requiresTurnedOn | boolean | No | ```false``` | |

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