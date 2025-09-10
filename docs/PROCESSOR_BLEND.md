# [Documentation](./INDEX.md) > Blend Processor

# Table of Contents

- [Processor](#processor)
- [Configurations](#configurations)
  - [Output](#output)
  - [Inputs](#inputs)
- [Discharge nodes](#discharge-nodes)

## Processor

```xml
<?xml version="1.0" encoding="utf-8" standalone="no"?>
<vehicle>
    <materialProcessor
        type="blend"
        needsToBePoweredOn="true"
        needsToBeTurnedOn="true"
    >
        ...
    </materialProcessor>
</vehicle>
```

### Attributes

| Name                         | Type    | Required | Default    | Description                                                                                                   |
|------------------------------|---------|----------|------------|---------------------------------------------------------------------------------------------------------------|
| type                         | string  | Yes      |            | Processor type ```blend``` |
| needsToBePoweredOn           | boolean | No       | ```true``` | Vehicle needs to be powered on |
| needsToBeTurnedOn            | boolean | No       | ```true``` | Vehicle needs to be turned on (requires turnOnVehicle specialization) [^1] |
| canToggleDischargeToGround   | boolean | No       | ```true```  | Whether player can toggle discharge to ground or not [^2] |
| defaultCanDischargeToGround  | boolean | No       | ```false``` | Default value for discharging to ground setting [^2] |
| canDischargeToGroundAnywhere | boolean | No       | ```false``` | Bypass land permissions when discharging to ground [^2] |
| canDischargeToAnyObject      | boolean | No       | ```false``` | Bypass vehicle permissions when discharging to object/vehicle [^2] |

[^1]: If the vehicle doesn't have a turn on function it will disregard this setting.
[^2]: Only applies if custom discharge node(s) are used

## Configurations

```
vehicle.materialProcessor.configurations.configuration(%)
```

```xml
<?xml version="1.0" encoding="utf-8" standalone="no"?>
<vehicle>
    <materialProcessor type="blend">
        <configurations>
            <configuration name="$l10n_myConfigurationName" litersPerSecond="500">
                <output fillType="ASPHALT" fillUnit="3">
                    <input fillType="GRAVEL" fillUnit="4" ratio="0.5" />
                    <input fillType="DIRT" fillUnit="5" ratio="0.4" />
                    <input fillType="MIXTURE" fillUnit="6" ratio="0.1" />
                </output>
            </configuration>

            ...
        </configurations>
    </materialProcessor>
</vehicle>
```

#### Attributes

| Name            | Type   | Required | Default   | Description                  |
|-----------------|--------|----------|-----------|------------------------------|
| litersPerSecond | int    | Yes      | ```400``` | Amount of liters per second produced |
| name            | string | No       |           | Display name in GUI |


### Output

```
vehicle.materialProcessor.configurations.configuration(%).output
```

#### Attributes

| Name          | Type   | Required | Default     | Description                  |
|---------------|--------|----------|-------------|------------------------------|
| fillType      | string | Yes      |             | Name of filltype used for output |
| fillUnit      | int    | Yes      |             | Output vehicle fillUnitIndex |
| displayNode   | node   | No       |             | Set custom node for HUD display position | 
| displayNodeOffsetY | float | No   |             | Y offset position for HUD display |

### Inputs

```
vehicle.materialProcessor.configurations.configuration(%).output.input(%)
```

#### Attributes

| Name          | Type    | Required | Default | Description                  |
|---------------|---------|----------|---------|------------------------------|
| ratio         | float   | Yes      |         | Ratio of input to output (50% = 0.5) |
| fillType      | string  | Yes      |         | Name of filltype used for input |
| fillUnit      | int     | Yes      |         | Input vehicle fillUnitIndex |
| displayNode   | node    | No       |         | Set custom node for HUD display position |
| displayNodeOffsetY | float | No    |         | Y offset position for HUD display |
| visible       | boolean | No       | ```true``` | Input visibility in HUD and GUI |

## Discharge nodes

```
vehicle.materialProcessor.dischargeNodes.node(%)
```

The blend processor supports using [custom discharge node(s)](./DISCHARGE_NODE.md) if desired.