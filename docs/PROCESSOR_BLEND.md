# [Documentation](./INDEX.md) > Blend Processor

# Table of Contents

- [Processor](#processor)
- [Configurations](#configurations)
  - [Output](#output)
  - [Inputs](#inputs)

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

[^1]: If the vehicle doesn't have a turn on function it will disregard this setting.

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
                <output fillType="ASPHALT" fillUnitIndex="3">
                    <input fillType="GRAVEL" fillUnitIndex="4" ratio="0.5" />
                    <input fillType="DIRT" fillUnitIndex="5" ratio="0.4" />
                    <input fillType="MIXTURE" fillUnitIndex="6" ratio="0.1" />
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
| fillUnitIndex | int    | Yes      |             | Output vehicle fillUnitIndex |
| hudNode       | node   | No       |             | Set custom node for HUD display position | 


### Inputs

```
vehicle.materialProcessor.configurations.configuration(%).output.input(%)
```

#### Attributes

| Name          | Type    | Required | Default | Description                  |
|---------------|---------|----------|---------|------------------------------|
| ratio         | float   | Yes      |         | Ratio of input to output (50% = 0.5) |
| fillType      | string  | Yes      |         | Name of filltype used for input |
| fillUnitIndex | int     | Yes      |         | Input vehicle fillUnitIndex |
| hudNode       | node    | No       |         | Set custom node for HUD display position |
| hidden        | boolean | No       | ```false``` | Hide input from HUD and GUI |

NOTE: It's important to make sure that all input ratios adds up to ```1.0```.