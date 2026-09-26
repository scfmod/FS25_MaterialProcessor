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
| stopDischargeIfNotPossible           | boolean   | No       | ```true``` if a `<trigger>` element is defined for this node, otherwise ```false``` | Stop discharge if not possible |
| allowDischargeWhenInactive           | boolean   | No       | ```false``` | Allow discharging even if discharge node is not used by current configuration |
| unloadInfoIndex                      | int       | No       | ```1```     | Unload info index |
| effectTurnOffThreshold               | float     | No       | ```0.25```  | After this time has passed and nothing has been processed the effects are turned off |
| maxDistance                          | float     | No       | ```10```    | Max discharge distance |
| soundNode                            | node      | No       |             | Sound node index path |
| playSound                            | boolean   | No       | ```true``` (see note below) | Whether to play sounds |
| canFillOwnVehicle                    | boolean   | No       | ```false``` | Discharge node can fill other fill units of the vehicle itself |
| toolType                             | string    | No       | ```dischargeable``` | Tool type |

> **Note:** `canStartGroundDischargeAutomatically` and `canStartDischargeAutomatically` are **not** valid attributes on a custom discharge node, despite matching the base-game Dischargeable specialization's naming. Automatic ground discharge is always on for a custom discharge node (hardcoded, not configurable). Setting either of these in XML is silently ignored — it will not error, and will not do anything.
>
> **Note:** if a discharge node has no `<trigger>` element, `stopDischargeIfNotPossible` defaults to `false`, not `true` as the table above might suggest at a glance — read the two together carefully. A `false` value here means the fill-level check inside the per-tick discharge eligibility check is bypassed entirely (material can be considered dischargeable regardless of how little is actually in the fillUnit), which can also prevent the node from ever reverting out of `DISCHARGE_STATE_GROUND` once empty. If you rely on automatic ground discharge and don't have a `<trigger>` defined, set `stopDischargeIfNotPossible="true"` explicitly.
>
> **Note:** `playSound` has no code-level fallback despite the documented default above — the loader reads the attribute with no default value supplied, so if it is not explicitly written in XML it resolves to `nil` (falsy), and `<dischargeSound>` is never loaded into a playable sample as a result, regardless of how it is otherwise configured. If you want `<dischargeSound>` to actually play, set `playSound="true"` explicitly.
>
> **Note:** `<dischargeSound>` and `<dischargeStateSound>` are not interchangeable, despite both being valid sound child elements — pick based on what you actually want:
> - `<dischargeStateSound>` starts the instant the node enters a non-`OFF` discharge state (armed to discharge), regardless of whether material is actually flowing yet.
> - `<dischargeSound>` (singular) only plays while material is genuinely being discharged (tied to the same internal flag that gates the discharge effects), and requires `playSound="true"` per the note above. It is also gated on the last `ParticleEffect` in `<effects>` reporting itself visible — a `delay` set on that particle will delay this sound's first play by the same amount, and a discharge burst shorter than that delay may never trigger the sound at all.
>
> The same distinction applies to `<animationNodes>` (tied to discharge state, like `<dischargeStateSound>`) versus `<effectAnimationNodes>` (tied to actual discharge, like `<dischargeSound>`).

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
