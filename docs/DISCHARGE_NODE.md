# [Documentation](./INDEX.md) > Custom discharge node

```
vehicle.materialProcessor.dischargeNodes.node(%)
```

Material Processor relies on using custom discharge nodes to enchance functionality and enable discharging multiple fillUnits simultaneously. It is mainly used for the split processor, but can also be used with the blend processor. The custom discharge nodes provides support for the same child elements as the base game Dischargeable:

```
- info
- raycast
- trigger
- activationTrigger
- distanceObjectChanges
- stateObjectChanges
- effects
- dischargeSound
- dischargeStateSound
- animationNodes
- effectAnimationNodes
- animation
```

### Attributes

| Name                                 | Type      | Required | Default     | Description                  |
|--------------------------------------|-----------|----------|-------------|------------------------------|
| fillUnitIndex                        | int       | Yes      |             | Discharge node fillUnitIndex |
| node                                 | node      | Yes      |             | Discharge node index path    |
| emptySpeed                           | int       | No       | ```250```   | Empty speed in liters/second |
| stopDischargeIfNotPossible           | boolean   | No       | ```true```  | Stop discharge if not possible |
| allowDischargeWhenInactive           | boolean   | No       | ```false``` | Allow discharging even if discharge node is not used by current configuration |
| unloadInfoIndex                      | int       | No       | ```1```     | Unload info index |
| effectTurnOffThreshold               | float     | No       | ```0.25```  | After this time has passed and nothing has been processed the effects are turned off |
| maxDistance                          | float     | No       | ```10```    | Max discharge distance |
| soundNode                            | node      | No       |             | Sound node index path |
| playSound                            | boolean   | No       | ```true```  | Whether to play sounds |
| canFillOwnVehicle                    | boolean   | No       | ```false``` | Discharge node can fill other fill units of the vehicle itself |
| toolType                             | string    | No       | ```dischargeable``` | Tool type |

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
