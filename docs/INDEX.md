# Documentation

# Table of Contents

- [Add specialization to vehicle type](#add-specialization-to-vehicle-type)
- [Vehicle XML](#vehicle-xml)
- [Processor types](#processor-types)
  - [Split Processor](#split-processor)
  - [Blend Processor](#blend-processor)
- [InteractiveControl](#interactivecontrol)

Documentation files:
- 🗎 [XSD validation schema](./schema/materialProcessor.xsd)
- 🗎 [HTML schema](./schema/materialProcessor.html)

## Add specialization to vehicle type

```xml
<?xml version="1.0" encoding="utf-8" standalone="no"?>
<modDesc version="...">
    ...
    <vehicleTypes>
        <!-- Extend parent type, can be anything -->
        <type name="..." parent="..." className="..." filename="...">
            ...
            <!-- Add materialProcesor as last entry to type -->
            <specialization name="FS25_0_MaterialProcessor.materialProcessor" />
        </type>
    </vehicleTypes>
    ...
</modDesc>
```

## Vehicle XML
```xml
<?xml version="1.0" encoding="utf-8" standalone="no"?>
<vehicle ...>
    ...
    <materialProcessor type="...">
        ...
    </materialProcessor>
    ...
</vehicle>
```

## Processor types

### Split Processor

```xml
<?xml version="1.0" encoding="utf-8" standalone="no"?>
<vehicle>
    <materialProcessor type="split">
        ...
    </materialProcessor>
</vehicle>
```

Process one single input fillUnit and split the value into multiple output fillUnits. This specialization supports multiple simultaneous active discharge nodes vs base game which only supports 1.

For implementing a Split Processor [read more here](./PROCESSOR_SPLIT.md).


### Blend Processor

```xml
<?xml version="1.0" encoding="utf-8" standalone="no"?>
<vehicle>
    <materialProcessor type="blend">
        ...
    </materialProcessor>
</vehicle>
```

Process multiple input fillUnits into one output fillUnit.

For implementing a Blend Processor [read more here](./PROCESSOR_BLEND.md).

## InteractiveControl

When [FS25_interactiveControl](https://www.farming-simulator.com/mod.php?mod_id=323135) mod is active, new IC functions will be available for use:

| Function | Description |
|----------|-------------|
| PROCESSOR_CONTROL_PANEL | Open control panel dialog for changing configuration. |
| PROCESSOR_TOGGLE_DISCHARGE_GROUND | Toggle discharge to ground. Only applicable for custom discharge nodes. |
