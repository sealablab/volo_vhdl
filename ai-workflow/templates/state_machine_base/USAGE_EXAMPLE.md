# State Machine Base - Usage Example

## Quick Start (Copy-Paste Approach)

This template is designed to be copied directly into your module and customized. Here's how to use it:

### 1. Copy the State Machine Code

Copy the entire `state_machine_base.vhd` file into your module and rename it to match your module name.

### 2. Customize the Parameters

Replace the example parameters with your actual configuration parameters:

```vhdl
-- Replace these example parameters with your actual ones
cfg_param1 : in std_logic_vector(15 downto 0);  -- Example parameter 1
cfg_param2 : in std_logic_vector(7 downto 0);   -- Example parameter 2
cfg_param3 : in std_logic;                      -- Example parameter 3
```

### 3. Customize the Validation Logic

Update the parameter validation function with your specific validation rules:

```vhdl
parameter_validation : process(cfg_param1, cfg_param2, cfg_param3)
begin
    -- TODO: Replace with your actual validation logic
    -- Example: Check parameter ranges, safety limits, etc.
    if cfg_param1 /= x"0000" and           -- param1 not zero
       cfg_param2 /= x"00" and             -- param2 not zero  
       cfg_param3 = '1' then               -- param3 must be '1'
        cfg_param_valid <= '1';
    else
        cfg_param_valid <= '0';
    end if;
end process;
```

### 4. Add Your Module Logic

Add your module-specific logic in the IDLE state or create additional states:

```vhdl
when ST_IDLE =>
    -- Your module logic goes here
    -- This is where custom module code typically begins
    if your_condition then
        next_state <= ST_YOUR_STATE;  -- Add your custom states
    end if;
```

### 5. Add Custom States (Optional)

Add your own states using the reserved encoding (0x3-0xE):

```vhdl
-- Add your custom states
constant ST_YOUR_STATE1 : std_logic_vector(3 downto 0) := "0011";  -- 0x3
constant ST_YOUR_STATE2 : std_logic_vector(3 downto 0) := "0100";  -- 0x4
```

## Example: Simple Counter Module

Here's a complete example of how to use the state machine base:

```vhdl
-- Copy the state machine base and customize it
entity simple_counter is
    port (
        clk : in std_logic;
        rst_n : in std_logic;
        ctrl_enable : in std_logic;
        ctrl_start : in std_logic;
        
        -- Your actual parameters
        cfg_max_count : in std_logic_vector(15 downto 0);
        cfg_count_step : in std_logic_vector(7 downto 0);
        cfg_count_enable : in std_logic;
        
        -- Status outputs (from state machine base)
        stat_current_state : out std_logic_vector(3 downto 0);
        stat_fault : out std_logic;
        stat_ready : out std_logic;
        stat_idle : out std_logic;
        stat_status_reg : out std_logic_vector(31 downto 0);
        
        -- Your module outputs
        count_output : out std_logic_vector(15 downto 0);
        count_done : out std_logic
    );
end entity;

architecture behavioral of simple_counter is
    -- Copy all the state machine base code here
    -- Then customize the parameter validation:
    
    parameter_validation : process(cfg_max_count, cfg_count_step, cfg_count_enable)
    begin
        -- Your validation logic
        if cfg_max_count > 0 and 
           cfg_count_step > 0 and 
           cfg_count_enable = '1' then
            cfg_param_valid <= '1';
        else
            cfg_param_valid <= '0';
        end if;
    end process;
    
    -- Add your counter logic in the IDLE state
    -- Add custom states for counting, done, etc.
end architecture;
```

## Key Benefits

1. **Safe Reset Pattern**: Automatic parameter validation on reset
2. **HARD_FAULT Protection**: Invalid parameters automatically trigger fault state
3. **Status Visibility**: Current state always visible in status register
4. **Debug Support**: Direct state output for debugging
5. **Verilog Compatible**: Easy to convert to Verilog

## What You Get

- ✅ 4-bit state encoding with clear patterns
- ✅ Automatic status register updates
- ✅ Parameter validation stub (customize for your module)
- ✅ HARD_FAULT state with reset-only exit
- ✅ Comprehensive testbench (copy and customize)
- ✅ Verilog-portable VHDL-2008 implementation

## What You Need to Do

1. **Copy the template** into your module
2. **Replace example parameters** with your actual ones
3. **Customize validation logic** for your specific requirements
4. **Add your module logic** in the IDLE state or new states
5. **Test thoroughly** using the provided testbench as a starting point

That's it! The state machine base handles all the safety-critical state management, and you focus on your module's specific functionality.