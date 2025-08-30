# VOLO-codes workflow



The general approach is to:
* List your modules dependencies (S0) (input)
* Define your modules __interface__ (S1) (input)
-- Create a simple core entity block.  (output)

Once you have done that, you ought to be able to ask cursor to read your dependency list and generate the core __entity__ block. This will define the overall interface to your module.

NOTE: I find it helpful to __iterate__ on this interface **before** specifying the actual functional details of your module. That will come later. 

To iilustrate this process lets create a new module 'ProbeHero6'
## S0: Module dependencies
In our case we will be using
- Global_Probe_Table_pkg
-  Probe_Config_pkg.vhd

* Moku_Voltage_pkg.vhd
* PercentLut_pkg.vhd
* clk_divider_core.vhd

A brief summary of each follows



### Probe_Config_pkg
The `Trigger_Config_pkg` defines the core properties that all probes driven by 'ProbeHero6' share.  

``` vhdl
    -- Primary probe configuration using voltage values (configuration layer)

type t_probe_config is record
	probe_trigger_voltage : real; -- Voltage to output to trigger the probe
	probe_duration_min : natural; -- Duration in clock cycles
	probe_duration_max : natural; -- Duration in clock cycles
	probe_intensity_min : real; -- Minimum intensity voltage in volts
	probe_intensity_max : real; -- Maximum intensity voltage in volts
	probe_cooldown_min : natural; -- Cooldown in clock cycles
	probe_cooldown_max : natural; -- Cooldown in clock cycles
	probe_intensity_lut : percent_lut_record_t; -- Probe's own authoritative intensity LUT

end record;
```

### Global_Probe_Table_pkg
the `Global_Probe_Table` package includes a convenient table of globally supported probes. 
``` vhdl
constant GLOBAL_PROBE_TABLE : t_probe_config_array := (

-- DS1120 Configuration
PROBE_ID_DS1120 => 
(
	probe_trigger_voltage => 3.3, -- 3.3V trigger voltage
	probe_duration_min => 100, -- 100 clock cycles minimum duration
	probe_duration_max => 1000, -- 1000 clock cycles maximum duration
	probe_intensity_min => 0.5, -- 0.5V minimum intensity
	probe_intensity_max => 5.0, -- 5.0V maximum intensity
	probe_cooldown_min => 50, -- 50 clock cycles minimum cooldown
	probe_cooldown_max => 500, -- 500 clock cycles maximum cooldown
	probe_intensity_lut => DS1120_INTENSITY_LUT -- Probe's own authoritative LUT
)
```


### Moku_Voltage_pkg
the `Moku_Voltage_pkg` contains utility functions for converting voltages (expressed as real numbers) into the 16 bit signed representation used on MCC (as well as most other FPGA platforms).

``` vhdl
-- ==========================================================================
-- VOLTAGE CONVERSION FUNCTIONS
-- ==========================================================================

	-- Convert voltage (real) to digital value (signed 16-bit)
    function voltage_to_digital(voltage : real) return signed;

    -- Convert digital value (signed 16-bit) to voltage (real)
    function digital_to_voltage(digital : signed(15 downto 0)) return real;
```


### PercentLut_pkg
the `PercentLut` package defines a datatype that we use to create simple percentage based look up tables. Aside from utility functions for creating or defining your own, it provides a handful of useful pre-generated tables. For example


``` vhdl
    -- LUT for 0V to 4.99999V (0x00 to 0x7FFF)
    constant LINEAR_5V_LUT_DATA : percent_lut_data_array_t;
    constant LINEAR_5V_LUT : percent_lut_record_t;

    -- LUT for 0V to 3.3V
    constant LINEAR_3V3_LUT_DATA : percent_lut_data_array_t;
    constant LINEAR_3V3_LUT : percent_lut_record_t;
```



## S1: module core interface requirements 
![[volo_vhdl/volo_codes_workflow/ProbeHero6/ProbeHero6-Interface-reqs|!ProbeHero6]]
