# [Documentation](./INDEX.md) > Blend Processor

Process multiple input fillUnits into one output fillUnit.

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
| autoDetectEmptyThreshold     | float   | No       | ```20```    | Fill level (liters) at or below which a configuration unit is considered empty for the purpose of allowing switching configuration to relabel it. Applies to the output and every input. See the Split Processor docs for the full explanation and tuning guidance — the value depends on the `fillToGroundScale` of the fillTypes you use. Note: `splitAutoSelectConfigurationEnabled` and the automatic fillType-detection behavior it enables are Split processor only and have no effect here — there is no single incoming fillType for a Blend configuration (which combines several simultaneous inputs) to be auto-detected from. |

[^1]: If the vehicle doesn't have a turn on function it will disregard this setting.
[^2]: Only applies if custom discharge node(s) are used

Switching configuration will never relabel a unit's fillType — output or any input — while it holds more than `autoDetectEmptyThreshold` liters. In the processor-config GUI dialog, the Apply button is hidden and double-clicking a configuration entry does nothing while any of the current configuration's units (the output and every input) still hold more than `autoDetectEmptyThreshold` liters; the dialog can still be opened to preview other configurations while a switch is blocked.

Because switching does not relabel a non-empty output, that output stays locked to its previous fillType until it is emptied out. Processing checks this: if the output cannot currently accept its configured fillType, the processor will not process at all — no inputs are consumed and no material is lost — until the output is cleared.

A unit that was still non-empty at the exact moment a configuration was selected (so left unlabelled) is re-checked every tick afterwards, not just at the moment of switching — once it drops to or below `autoDetectEmptyThreshold`, it is automatically relabelled to match the current configuration without needing another configuration switch to trigger it.

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
| litersPerSecondText|string|No       |           | Set custom liters per second text in GUI. L10N string supported. |
| name            | string | No       |           | Display name in GUI. L10N string supported. |


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