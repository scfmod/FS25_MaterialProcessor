# [Documentation](./INDEX.md) > Split Processor

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
| canDischargeToAnyObject      | boolean | No       | ```false``` | Bypass vehicle permissions when discharging to object |

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
                <input fillType="DIRT" fillUnitIndex="3">
                    <output fillType="GRAVEL" fillUnitIndex="4" ratio="0.3" />
                    <output fillType="SAND" fillUnitIndex="5" ratio="0.7" />
                </input>
            </configuration>

            <configuration name="Filter gravel" litersPerSecond="800">
                <input fillType="GRAVEL" fillUnitIndex="3">
                    <output fillType="SAND" fillUnitIndex="4" ratio="0.1" />
                    <output fillType="STONE" fillUnitIndex="5" ratio="0.9" />
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
| name            | string | No       |           | Display name in GUI |


### Input

```
vehicle.materialProcessor.configurations.configuration(%).input
```

#### Attributes

| Name          | Type   | Required | Default | Description                  |
|---------------|--------|----------|---------|------------------------------|
| fillType      | string | Yes      |         | Name of filltype used for input |
| fillUnitIndex | int    | Yes      |         | Input vehicle fillUnitIndex |
| hudNode       | node   | No       |         | Set custom node for HUD display position | 

### Outputs

```
vehicle.materialProcessor.configurations.configuration(%).input.output(%)
```

#### Attributes

| Name          | Type    | Required | Default | Description                  |
|---------------|---------|----------|---------|------------------------------|
| ratio         | float   | Yes      |         | Ratio of output to input (50% = 0.5) |
| fillType      | string  | Yes      |         | Name of filltype used for output |
| fillUnitIndex | int     | Yes      |         | Output vehicle fillUnitIndex |
| hudNode       | node    | No       |         | Set custom node for HUD display position |
| hidden        | boolean | No       | ```false``` | Hide output from HUD and GUI |

NOTE: It's important to make sure that all output ratios adds up to ```1.0```.

Also remember to add corresponding fillUnit [discharge node](#discharge-nodes) entries if you want to enable multiple discharge nodes to function simultaneously.


## Discharge nodes
```
vehicle.materialProcessor.dischargeNodes.node(%)
```

(Optional support for multiple discharge nodes)

This element provides support for the same child elements as base game dischargeNode (Dischargeable specialization):

- info
- raycast
- trigger
- activationTrigger
- distanceObjectChanges
- stateObjectChanges
- nodeActiveObjectChanges
- effects
- dischargeSound
- dischargeStateSound
- animationNodes


For more details on these look at the official documentation files for Vehicle.

### Attributes

| Name                                 | Type      | Required | Default     | Description                  |
|--------------------------------------|-----------|----------|-------------|------------------------------|
| fillUnitIndex                        | int       | Yes      |             | Discharge node fillUnitIndex |
| node                                 | node      | Yes      |             | Discharge node index path    |
| emptySpeed                           | int       | No       | ```250```   | Empty speed in liters/second |
| stopDischargeIfNotPossible           | boolean   | No       | ```true```  | Stop discharge if not possible |
| unloadInfoIndex                      | int       | No       | ```1```     | Unload info index |
| effectTurnOffThreshold               | float     | No       | ```0.25```  | After this time has passed and nothing has been processed the effects are turned off |
| maxDistance                          | float     | No       | ```10```    | Max discharge distance |
| soundNode                            | node      | No       |             | Sound node index path |
| playSound                            | boolean   | No       | ```true```  | Whether to play sounds |


### Example
```xml
<?xml version="1.0" encoding="utf-8" standalone="no"?>
<vehicle>
    <materialProcessor type="split">
        <configurations>
            ...
        </configurations>

        <dischargeNodes>
            <node node="dischargeNodeSideR" emptySpeed="100" fillUnitIndex="4" unloadInfoIndex="1">
                <activationTrigger node="activationTriggerSideR" />
                <raycast useWorldNegYDirection="true" />
                <info width="0.5" length="0.5" />
                <effects>
                    ...
                </effects>
                <dischargeStateSound template="augerBelt" pitchScale="0.7" volumeScale="1.4" fadeIn="0.2" fadeOut="1" innerRadius="1.0" outerRadius="40.0" linkNode="dischargeNodeSideR" />
            </node>

            <node node="dischargeNodeFront" emptySpeed="1" fillUnitIndex="5" unloadInfoIndex="2">
                <activationTrigger node="activationTriggerFront" />
                <raycast useWorldNegYDirection="true" />
                <info width="0.5" length="0.5" />
                <effects>
                    ...
                </effects>
                <dischargeStateSound template="augerBelt" pitchScale="0.7" volumeScale="1.4" fadeIn="0.2" fadeOut="1" innerRadius="1.0" outerRadius="40.0" linkNode="dischargeNodeFront" />
            </node>
        </dischargeNodes>
    </materialProcessor>
</vehicle>
```