
# BPD-001-Rough-Notes


Your organization's data cannot be pasted here.
## BPD-001 diagram

## BPD-001 Datastructures
- BasicProbeConfig
- IntensityLUT

### Datastructures/**BasicProbeConfig** 
``` vhdl 
  type t_probe_config is record
        -- Probe identification
        probe_name : string(1 to 16);  -- Units: string (probe identifier)
        
        -- Voltage configuration (Units: volts)
        probe_trigger_voltage : std_logic_vector(VOLTAGE_DATA_WIDTH-1 downto 0);  -- Units: volts
        probe_intensity_min   : std_logic_vector(VOLTAGE_DATA_WIDTH-1 downto 0);  -- Units: volts
        probe_intensity_max   : std_logic_vector(VOLTAGE_DATA_WIDTH-1 downto 0);  -- Units: volts
        
        -- Timing configuration (Units: clks)
        fire_duration_min     : unsigned(SYSTEM_DURATION_WIDTH-1 downto 0);         -- Units: clks
        fire_duration_max     : unsigned(SYSTEM_DURATION_WIDTH-1 downto 0);         -- Units: clks
        cooldown_duration_min : unsigned(SYSTEM_DURATION_WIDTH-1 downto 0);         -- Units: clks
        cooldown_duration_max : unsigned(SYSTEM_DURATION_WIDTH-1 downto 0);         -- Units: clks
        
        -- Safety configuration
        safety_enabled        : std_logic;                                          -- Units: signal
        max_fire_rate         : unsigned(15 downto 0);                              -- Units: clks (minimum time between fires)
    end record;

```