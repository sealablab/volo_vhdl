# TPD-TOP

# TPD: Trivial Probe Driver
the **Trivial Probe Driver** works around the lack of moku.get_regs (aka 'StatusRegister') support with a clever work-around.

We will utilize the built-in Oscilloscope instrument to stream information back to the FI-Orchestrator.  This has the (most) robust support for streaming data in real time over the network. 



#### CRO : (31 - 24)

| bit   | type | descr                |
| ----- | ---- | -------------------- |
| 31    | -    | gDisable             |
| 20-28 | -    | Reserved             |
| 27-24 | -    | Reserved (`clk-dev`) |


#### CRO : (23 - 16)

| bit   | type | descr                |
| ----- | ---- | -------------------- |
| 23    | -    | `SOFT-TRIGGER`       |
| 22-16 |      | `IntensityLut-Index` |


#### CRO : (15- 8)

| bit   | type           | name           | descr                                             |
| ----- | -------------- | -------------- | ------------------------------------------------- |
| 15-12 | 4-bit unisgned | Probe_cooldown | n-cycles CORE module will stay in 'COOLING' state |
| 22-16 | 4-bit unsigned | Probe_fire     | n-cycles CORE module will stay in 'FIRING' state  |

### Probe_Cooldown
**Probe_Cooldown** specifies the number of cycle the CORE mode should remain in `COOLING` state
### Probe_fire
**Probe_Fire** specifies the number of cycles the CORE mode should remain in `FIRING` state



## TPD-TOP Entity
``` vhdl
entity TBD_top is
    port (
        -- System interface
		clk           : in  std_logic;
        rst_n         : in  std_logic;
        enable        : in  std_logic;
		ce            : in  std_logic;
       
		--
		TOP_trig_in            : in  std_logic;
        
        -- Configuration interface (cfg_ prefix for configuration signals)
        cfg_clk_div_sel   : in  std_logic_vector(3 downto 0);
        cfg_intensity_index_in  : in  std_logic_vector(6 downto 0);
        cfg_fire_duration_in    : in  unsigned(15 downto 0);
        cfg_cooldown_duration_in: in  unsigned(15 downto 0);
        
        -- Output interface
        trigger_out             : out signed(15 downto 0);
        intensity_out           : out signed(15 downto 0);
		stat_reg_out            : out signed(7 downto 0);
		
		-- v_mon_out is the analog voltage monitor status output trick
		
    );
end entity TBD_top;
```


### MED_Wrapper
## MED_wrapper inputs
### trig_out_lvl :  in  signed(15 downto 0)
This value will be assigned to `trigger_out` during the FIRING state
### intens_out_lvl :  in  signed(15 downto 0)
This value will be assigned to `intensity_out` during the FIRING state
### intens_out_lvl :  in  signed(15 downto 0)
This value will be assigned to `intensity_out` during the FIRING state

## MED outputs
### trigger_out             : out signed(15 downto 0);
set to `trig_out_lvl` during FIRING, else 0x00
### intensity_out           : out signed(15 downto 0);
set to `intens_out_lvl` during FIRING, else 0x00
### state_reg_out               : out signed(7 downto 0);
The `state_reg_out` should map the following (internal) state bits to the outside. Note the stickyness setting.

| bit | name     | high-when | sticky? |
| --- | -------- | --------- | ------- |
| 0   | READY    |           | Y       |
| 1   | DELAY    |           | Y       |
| 2   | FIRING   |           | Y       |
| 3   | COOLING  |           | N       |
| 4   | DONE     |           | Y       |
| 5   | RESERVED |           |         |
| 6   | RESERVED |           |         |
| 7   | RESERVED |           |         |
|     |          |           |         |
	
## Reset procedure
**on reset**: validate that `intensity_in` : CR0
## TPD-TOP Architecture
``` vhdl
architecture behavioral of TBD_top is
-- on Reset we will latch values from CR0-N into the following (internal) fields
-- the values are (maybe) then passed in to the core state-machine module 
   signal intensity_out: signed(15 downto 0);
   signal trig_out: signed(15 downto 0);


--SIG-02: Named association for all port mappings
-- Direct insantiation of core module (required for top layer)
core_inst: entity work.TPD_core
port map 
(
            -- Clock and reset
            clk                        => clk,
            rst_n                      => rst_n,
            
            -- Control signals
            enable                     => core_enable,
            clk_en                     => core_clk_en,
            trig_in                    => core_trig_in,

			-- Configuration values 
			... tbd;

```


## TPD-TOP
## TPD-TOP: Approach



