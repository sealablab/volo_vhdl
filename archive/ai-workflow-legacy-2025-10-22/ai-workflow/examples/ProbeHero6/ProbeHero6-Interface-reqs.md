
# ProbeHero6
**ProbeHero6** is a VHDL module designed to drive various SCA and FI probes.
Conceptually ProbeHero6 is similar to a simple signal generator. 

This document describes the __interface__ requirements. Basically it functions as a blueprint defining the expected input and outputs, as well as listing any other vhdl module it depends on.


## Core module dependencies
- Probe_Config_pkg.vhd
- Global_Probe_Table_pkg.vhd
* Moku_Voltage_pkg.vhd
* PercentLut_pkg.vhd
* clk_divider_core.vhd

## Control inputs
This module will utilize the default control inputs (n_reset, enable, clk, clk_en)
## Reset behavior
this module will implement a simple syncronos reset handler
## Clocking
This module will be driven either by the platform provided clk, or from the clk_divider module. It does not need to handle multiple clock domains.

## Probe Status register
The built in status register is 8-bits wide and the bit definitions are below.
NOTE: This module follows the standard convention the utilizing the top most two bits of the status register to indicate either `FAULT` or `Alarm`.
### Probe_status_bit definitions
- bit7: FAULT
- bit6: ALARM
- bit5: reserved
- bit4: reserved
- bit3: `Cool` 
- bit2: `Fired` (note: Sticky!)
- bit1: `Firing`
- bit0: `Armed` (this reflects our 'enabled' status)

## Core module configuration inputs
the **ProbeHero6** core module will take the following inputs

### probe_selector_index_in
`probe_selector_index_in` is a 2-bit index into the globally defined __Global_Probe_Table__ 

### validation
the `probe_selector_index_in` should use the appropriate validation functions inside the `Global_Probe_Table` package



### `intensity_index_in` 
**intensity_index_in** will be a 7-bit index into a PercentLut datatype.
#### `intensity_index_in` validation
Like all PercentLut indexes it should be validated using the `PercentLut` utility functions, specifically 
``` vhdl
-- Index validation utilities
function is_valid_percent_lut_index(index : std_logic_vector) return boolean;
function is_valid_percent_lut_index(index : natural) return boolean;
```


### duration_in
`duration_in` is a sixteen-bit unsigned value. It is used to specify how long `intensity_out` and `trigger_out` should remain high when the module fires.

#### `duration_in` validation
If `duration_in` is above or below the limits specified in  selected t_probe_config type specified by  the actual duration shall be clamped to the min or max as appropriate, and the `alarm` bit in the probe_status register should be set high.
``` vhdl
    -- Primary trigger configuration using voltage values (configuration layer)
    type t_trigger_config is record
		...
        trigger_in_duration_min : natural;  -- Duration in clock cycles
        trigger_in_duration_max : natural;  -- Duration in clock cycles
    end record;
```


## Core module outputs
The module shall provide the following three outputs
## probe_status_out
`probe_status_out` should be continuously assigned to the internal `probe_status` register. 
No further validation or logic is necessary.


### `trigger_out` 
`trigger_out` is a 16-bit signed value representing the voltage that will be used to drive the attached probe.

#### trigger_out validation
The `trigger_out` value should never exceed the value specified by current probe_configs `probe_trigger_voltage`


## `intensity_out`
`intensity_out` is a 16-bit signed value representing the voltage that will be used to drive the attached probes `intensity` input. 

#### intensity_out validation
`intensity_out` should be clamped to `probe_intensity_min` or `probe_intensity_max`. The 'Alarm' bit in the status register should be set high on this condition.


---
NOTE that at this point we have said __Very little__ about the internal functionality of probedriver. 

Before we do get into those details we want to ensure we have a clearly defined interface.

Using the above requirements we __should__ be able to generate:
* the basic probe_driver_core entitiy block
* a basic set of testbenches



Next up we have the 
[[volo_vhdl/volo_codes_workflow/ProbeHero6/ProbeHero6-functional-reqs]]


# See Also
[[volo_vhdl/volo_codes_workflow/VOLO-codes-workflow|VOLO-codes-workflow]]
