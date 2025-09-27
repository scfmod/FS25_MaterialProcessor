# [Documentation](./INDEX.md) > Split Processor

Process one single input fillUnit and split the value into multiple output fillUnits.

# Table of Contents

- [Processor](#processor)
- [Configurations](#configurations)
  - [Input](#input)
  - [Outputs](#outputs)
- [Discharge nodes](#discharge-nodes)

## Processor

```xml
<?xml version="1.0" encoding="utf-8" standalone="no"?>
<vehicle>
    <materialProcessor
        type="split"
        needsToBePoweredOn="true"
        needsToBeTurnedOn="true"
        canToggleDischargeToGround="true"
        defaultCanDischargeToGround="false"
        canDischargeToGroundAnywhere="false"
        canDischargeToAnyObject="false"
    >
        ...
    </materialProcessor>
</vehicle>
```

### Attributes

| Name                         | Type    | Required | Default     | Description                                                                                                   |
|------------------------------|---------|----------|-------------|---------------------------------------------------------------------------------------------------------------|
| type                         | string  | Yes      |             | Processor type ```split``` |
| needsToBePoweredOn           | boolean | No       | ```true```  | Vehicle needs to be powered on |
| needsToBeTurnedOn            | boolean | No       | ```true```  | Vehicle needs to be turned on (requires turnOnVehicle specialization) [^1] |
| canToggleDischargeToGround   | boolean | No       | ```true```  | Whether player can toggle discharge to ground or not |
| defaultCanDischargeToGround  | boolean | No       | ```false``` | Default value for discharging to ground setting |
| canDischargeToGroundAnywhere | boolean | No       | ```false``` | Bypass land permissions when discharging to ground |
| canDischargeToAnyObject      | boolean | No       | ```false``` | Bypass vehicle permissions when discharging to object/vehicle |

[^1]: If the vehicle doesn't have a turn on function it will disregard this setting.

## Configurations

```
vehicle.materialProcessor.configurations.configuration(%)
```

```xml
<?xml version="1.0" encoding="utf-8" standalone="no"?>
<vehicle>
    <materialProcessor type="split">
        <configurations>
            <configuration name="$l10n_myConfigurationName" litersPerSecond="500">
                <input fillType="DIRT" fillUnit="3">
                    <output fillType="GRAVEL" fillUnit="4" ratio="0.3" />
                    <output fillType="SAND" fillUnit="5" ratio="0.7" />
                </input>
            </configuration>

            <configuration name="Filter gravel" litersPerSecond="800">
                <input fillType="GRAVEL" fillUnit="3">
                    <output fillType="SAND" fillUnit="4" ratio="0.1" />
                    <output fillType="STONE" fillUnit="5" ratio="0.9" />
                </input>
            </configuration>

            <configuration name="Screen sand" litersPerSecond="800">
                <input fillType="GRAVEL" fillUnit="3">
                    <output fillType="SAND" fillUnit="4" ratio="0.1" />
                </input>
            </configuration>
        </configurations>
    </materialProcessor>
</vehicle>
```

#### Attributes

| Name            | Type   | Required | Default   | Description                  |
|-----------------|--------|----------|-----------|------------------------------|
| litersPerSecond | int    | Yes      | ```400``` | Amount of liters per second processed by input |
| litersPerSecondText|string|No       |           | Set custom liters per second text in GUI |
| name            | string | No       |           | Display name in GUI |


### Input

```
vehicle.materialProcessor.configurations.configuration(%).input
```

#### Attributes

| Name          | Type   | Required | Default | Description                  |
|---------------|--------|----------|---------|------------------------------|
| fillType      | string | Yes      |         | Name of filltype used for input |
| fillUnit      | int    | Yes      |         | Input vehicle fillUnitIndex |
| displayNode   | node   | No       |         | Set custom node for HUD display position | 
| displayNodeOffsetY | float | No   |         | Y offset position for HUD display |

### Outputs

```
vehicle.materialProcessor.configurations.configuration(%).input.output(%)
```

#### Attributes

| Name          | Type    | Required | Default | Description                  |
|---------------|---------|----------|---------|------------------------------|
| ratio         | float   | Yes      |         | Ratio of output to input (50% = 0.5) |
| fillType      | string  | Yes      |         | Name of filltype used for output |
| fillUnit      | int     | Yes      |         | Output vehicle fillUnitIndex |
| displayNode   | node    | No       |         | Set custom node for HUD display position |
| displayNodeOffsetY | float | No    |         | Y offset position for HUD display |
| visible       | boolean | No       | ```true``` | Output visibility in HUD and GUI |

Remember to add corresponding fillUnit [discharge node](#discharge-nodes) entries if you want to enable multiple discharge nodes to function simultaneously.


## Discharge nodes

```
vehicle.materialProcessor.dischargeNodes.node(%)
```

The split processor supports using [custom discharge node(s)](./DISCHARGE_NODE.md) if desired (highly recommended to use instead of the base game Dischargeable).