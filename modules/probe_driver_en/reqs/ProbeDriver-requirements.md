---
created: 2025-08-26
modified: 2025-08-26
ver: 0.0.1
---

## 1.  **ProbeDriver**
This document should serve as the design specification document for the ProbeDriver VHDL module

## 1.1 Purpose
The goal of the ProbeDriver module is to provide a convenient interface for driving common SCA and FI probes.  The first probe to be supported is the [[Probes/Riscure-DS1120-EM-FI-Probe|Riscure-DS1120-EM-FI-Probe]]. The next will be the [[Probes/Riscure-DS1101A-Laser-FI-Probe|Riscure-DS1101A-Laser-FI-Probe]]


## 1.2 Dependencies
The **ProbeDriver** shall only depend on the following vhdl modules / packages
* [[volo_vhdl/modules/probe_driver/tb/datadef/PercentLut_pkg_tb.vhd]]
* [[volo_vhdl/modules/clk_divider/core/clk_divider_core.vhd]]
* 


## 1.3 Conventions
The Following style/code generations guides shall be applied to ProbeDriver
* [[vhdl/reqs/NAMING-Readme|NAMING-Readme]]
* [[vhdl/reqs/REGISTERS-Readme|REGISTERS-Readme]]
* [[volo_vhdl/modules/README-RESET|README-RESET]]


## 2 Inputs (compile time)
At compile time  [[PercentLut]] shall be provided with values for the intensity_out. ``

## 3) Output (run-time)
The **ProbeDriver** shall drive __three__ outputs:
* `probe_status_register_out`: std_logic
* `trig_out`: `signed 16-bit`
* `intensity_out`: signed 16-bit

``` vhdl
    -- =============================================================================
    -- OUTPUT LOGIC - Combinational output assignments based on current state
    -- =============================================================================
    -- Trigger output: active only during FIRING state
    trig_out <= PROBE_TRIGGER_THRESHOLD when current_state = FIRING else (others => '0');

    -- Intensity output: lookup table mapping during FIRING state (0-100 maps to precise voltage values)
    probe_intensity_output <= get_intensity_output(intensity_index) when current_state = FIRING else (others => '0');

    -- Status register output
    probe_status_register <= status_reg;
```
## 4) Inputs (run-time)

The ProbeDriver shall have three inputs: 
* `trig_in`: std_logic
* `cfg_intensity_index`: 7-bit index into [[vhdl/PercentLut/common/PercentLut_pkg.vhd|PercentLut_pkg]]
* `cfg_pulse_duration`: 16-bit unsigned duration (in clk cycles) that `trig_iut` and `Intensity_Out` shall be set.
* `cfg_cooldown_duration`

``` vhdl
entity probe_driver_core is
    port (
        -- Clock and Control
        clk                    : in  std_logic;
        reset                  : in  std_logic;
        enable                 : in  std_logic; -- aka 'armed'
        clk_en                 : in  std_logic;


        -- Configuration
        cfg_intensity_index : in  probe_intensity_index_type;
        cfg_pulse_duration  : in  probe_duration_type;
        cfg_cooldown_duration : in  probe_cooldown_type;

        -- Input Signals
        trig_in    : in  std_logic;

        -- Output Signals
        trig_out   : out signed(15 downto 0);
        intensity_out : out signed(15 downto 0);
        probe_status_register  : out probe_status_type
    );
```
## Architecture
# See also
## [[volo_vhdl/modules/probe_driver/reqs/ProbeDriver-status-reg|ProbeDriver-status-reg]]
## [[volo_vhdl/modules/probe_driver/reqs/ProbeDriver-state-machine|ProbeDriver-state-machine]]

