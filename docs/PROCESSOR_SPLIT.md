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
| autoDetectEmptyThreshold     | float   | No       | ```20```    | Fill level (liters) at or below which a configuration unit is considered empty. Governs two things: (1) whether the input fillUnit is allowed to accept a different crop than the currently selected configuration expects, and (2) whether switching configuration is allowed to relabel a unit's fillType at all. Tune this per-vehicle to comfortably clear whatever `getMinValidLiterValue` returns for the fillTypes you use — this varies with each fillType's `fillToGroundScale` in `densityMapHeightTypes.xml` (most crop/mineral types sit around 1.0, giving a real minimum near 16L; cut crop residue/windrow types sit at 6.0–7.0, needing a threshold closer to 100L; snow sits at 2.0) |
| splitAutoSelectConfigurationEnabled | boolean | No | ```false``` | Split processor only. When enabled, the processor watches the actual fillType sitting in the input fillUnit every tick and automatically switches to whichever configuration's input matches, rather than requiring the player to manually select one. The input fillUnit also dynamically accepts any configuration's fillType while empty (so a fresh crop can be detected at all), then locks to only the currently-held fillType once non-empty (so a different crop cannot be tipped in on top and mixed). Has no effect on a Blend processor — there is no single incoming fillType for a Blend configuration to be auto-detected from. |

[^1]: If the vehicle doesn't have a turn on function it will disregard this setting.

## Automatic configuration detection

When `splitAutoSelectConfigurationEnabled="true"`, the player no longer needs to manually pick a configuration before tipping in a different crop:

- While the input fillUnit's level is at or below `autoDetectEmptyThreshold`, it will accept any fillType any configuration declares as an input — so a fresh load of any known crop is not rejected.
- Once the fillUnit rises above that threshold, `supportedFillTypes` is narrowed to only whatever fillType is actually inside it, preventing a second, different (but otherwise still "known") crop from being tipped in on top and mixed.
- Every tick, the processor compares the fillUnit's actual current fillType against the active configuration's expected input, and switches configuration automatically the moment they diverge — the same call the manual configuration-select action makes.

Regardless of this setting, switching configuration (manually or automatically) will never relabel a unit's fillType while it holds more than `autoDetectEmptyThreshold` liters. This applies to every unit the configuration touches — the input and every output — not just the primary one. In the processor-config GUI dialog, the Apply button is hidden and double-clicking a configuration entry does nothing while auto-detection is enabled, or while any of the current configuration's units still hold more than `autoDetectEmptyThreshold` liters; the dialog can still be opened to preview other configurations' outputs while a switch is blocked.

Because switching does not relabel a non-empty output, that output stays locked to its previous fillType until it is emptied out (e.g. discharged). Processing checks this: if any output cannot currently accept its configured fillType, the processor will not process at all — the input fillUnit will not drain, and no material is produced or lost — until that output is cleared. This prevents raw crop from being silently consumed with no corresponding output while an output tank is still occupied by a different fillType.

A unit that was still non-empty at the exact moment a configuration was selected (so left unlabelled) is re-checked every tick afterwards, not just at the moment of switching — once it drops to or below `autoDetectEmptyThreshold`, it is automatically relabelled to match the current configuration without needing another configuration switch to trigger it.

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
| litersPerSecond | int    | Yes      | ```400``` | Amount of liters per second processed by input. |
| litersPerSecondText|string|No       |           | Set custom liters per second text in GUI. L10N string supported. |
| name            | string | No       |           | Display name in GUI. L10N string supported. |


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