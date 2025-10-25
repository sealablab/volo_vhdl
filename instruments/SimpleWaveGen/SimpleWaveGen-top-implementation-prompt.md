# SimpleWaveGen Top-Level Module Implementation Prompt

## Task Overview
Implement the **SimpleWaveGen top-level module** based on the `SimpleWaveGen-top-regs-r2.md` specification. This module will integrate the SimpleWaveGen core with a clock divider and provide a register-based interface for host control.

## Implementation Requirements

### 1. Module Structure
Create the following files in the `SimpleWaveGen/top/` directory:
- `SimpleWaveGen_top.vhd` - Main top-level entity and architecture
- `README.md` - Implementation documentation and compilation instructions

### 2. Entity Interface
The top-level entity must expose the following interface:

```vhdl
entity SimpleWaveGen_top is
    port (
        -- System Interface
        clk         : in  std_logic;
        rst         : in  std_logic;
        
        -- Register Interface (32-bit registers)
        ctrl0_wr    : in  std_logic;                    -- Control0 register write enable
        ctrl0_data  : in  std_logic_vector(31 downto 0); -- Control0 register data
        ctrl1_wr    : in  std_logic;                    -- Control1 register write enable  
        ctrl1_data  : in  std_logic_vector(31 downto 0); -- Control1 register data
        config0_wr  : in  std_logic;                    -- Config0 register write enable
        config0_data: in  std_logic_vector(31 downto 0); -- Config0 register data
        config1_wr  : in  std_logic;                    -- Config1 register write enable
        config1_data: in  std_logic_vector(31 downto 0); -- Config1 register data
        
        -- Register Read Interface
        status0_rd  : out std_logic_vector(31 downto 0); -- Status0 register data
        status1_rd  : out std_logic_vector(31 downto 0); -- Status1 register data
        output0_rd  : out std_logic_vector(31 downto 0); -- Output0 register data
        
        -- External Interface
        wave_out    : out std_logic_vector(15 downto 0); -- Direct waveform output
        fault_out   : out std_logic                      -- Global fault output
    );
end entity SimpleWaveGen_top;
```

### 3. Register Implementation Requirements

#### Control0 Register (32-bit)
- `[31]` - `ctrl_global_enable`: Global module enable
- `[23:20]` - `cfg_clk_div_sel`: Clock divider selection (0-15)
- `[30:24, 19:0]` - Reserved (must be ignored on write)

#### Config0 Register (32-bit) - **SAFETY CRITICAL**
- `[2:0]` - `cfg_safety_wave_select`: Wave type selection (000, 001, 010 only)
- `[31:3]` - Reserved (must be ignored on write)

#### Config1 Register (32-bit)
- `[15:0]` - `cfg_amplitude_scale`: Amplitude scaling factor (0x0000-0xFFFF)
- `[31:16]` - Reserved (must be ignored on write)

#### Status0 Register (32-bit) - Read-Only
- `[7]` - `stat_enabled`: Module enabled status
- `[2:0]` - `stat_wave_select`: Current wave selection (mirrors config)
- `[31:8, 6:3]` - Reserved (always 0)

#### Status1 Register (32-bit) - Read-Only  
- `[0]` - `stat_global_fault`: Aggregated fault status
- `[31:1]` - Reserved (always 0)

#### Output0 Register (32-bit) - Read-Only
- `[15:0]` - `wave_out`: Current 16-bit signed waveform output
- `[31:16]` - Reserved (always 0)

### 4. Safety-Critical Parameter Validation

**CRITICAL REQUIREMENT**: Implement proper safety-critical parameter validation for `cfg_safety_wave_select[2:0]`:

- **Reset Validation**: MUST validate on reset and continuously monitor
- **Valid Values**: Only 000, 001, 010 are valid
- **Invalid Response**: Set fault_out high, maintain last valid configuration
- **Status Reflection**: Invalid selections must be reflected in status register
- **Recovery**: Fault clears when valid value is written

### 5. Module Integration Requirements

#### Direct Instantiation (MANDATORY)
Use direct instantiation for all sub-modules:
```vhdl
-- Clock Divider Instance
U_clk_divider: entity WORK.clk_divider_core
    port map (
        clk => clk,
        rst => rst,
        div_sel => cfg_clk_div_sel,
        clk_en => clk_en,
        fault_out => clk_div_fault
    );

-- SimpleWaveGen Core Instance  
U_wavegen_core: entity WORK.SimpleWaveGen_core
    port map (
        clk => clk,
        clk_en => clk_en,
        rst => rst,
        en => ctrl_global_enable,
        cfg_safety_wave_select => cfg_safety_wave_select,
        wave_out => core_wave_out,
        fault_out => core_fault,
        stat => core_stat
    );
```

#### Fault Aggregation
Implement OR logic for fault aggregation:
```vhdl
fault_out <= core_fault or clk_div_fault;
stat_global_fault <= fault_out;
```

### 6. Register Access Implementation

#### Write Access
- Configuration changes take effect on next rising clock edge
- Reserved bits must be ignored (not written to internal registers)
- Safety-critical parameters must be validated immediately

#### Read Access  
- Status and output registers reflect current state immediately (no buffering)
- Reserved bits must always read as 0

#### Reset Behavior
- All registers return to default values within 1 clock cycle
- Safety-critical parameters validated immediately after reset
- All fault outputs cleared on successful validation

### 7. Clock Divider Integration

#### Configuration
- `cfg_clk_div_sel` directly controls clock divider selection
- Clock divider provides `clk_en` to SimpleWaveGen_core
- Clock divider fault output aggregated into global fault status

#### Frequency Range
- Clock divider supports division ratios 1-16 (0=no division)
- `cfg_clk_div_sel=0` means no division (clk_en always high)
- `cfg_clk_div_sel=1` means divide by 2, etc.

### 8. Amplitude Scaling Implementation

#### Scaling Logic
- Apply amplitude scaling to core waveform output
- `cfg_amplitude_scale=0x8000` = unity scaling (no change)
- `cfg_amplitude_scale=0x4000` = half amplitude
- `cfg_amplitude_scale=0xFFFF` = maximum amplitude

#### Implementation
```vhdl
-- Amplitude scaling (simplified - may need more sophisticated implementation)
scaled_wave_out <= std_logic_vector(
    (signed(core_wave_out) * signed('0' & cfg_amplitude_scale)) / 32768
);
```

### 9. VHDL-2008 Compliance Requirements

#### Coding Standards
- Use `std_logic` and `std_logic_vector` types only
- Use `unsigned` and `signed` from `numeric_std` package
- Implement synchronous processes with `rising_edge(clk)`
- Use explicit bit widths for all vectors
- No VHDL-only features (records, enums, etc.)

#### Signal Naming
- Control signals: `ctrl_*` prefix
- Configuration signals: `cfg_*` prefix  
- Safety-critical parameters: `cfg_safety_*` prefix
- Status signals: `stat_*` prefix

#### Process Structure
```vhdl
process(clk, rst)
begin
    if rst = '1' then
        -- Reset logic
    elsif rising_edge(clk) then
        -- Synchronous logic
    end if;
end process;
```

### 10. Testbench Requirements

Create `SimpleWaveGen/tb/top/SimpleWaveGen_top_tb.vhd` with:

#### Test Coverage
1. **Register Access Tests**: Write/read all registers with specific test vectors
2. **Fault Aggregation Tests**: Verify fault aggregation from all sources
3. **Output Validation Tests**: Verify waveform output and amplitude scaling
4. **Reset and Initialization Tests**: Verify reset behavior and initialization
5. **Integration Tests**: End-to-end functionality verification

#### Test Scenarios (Specific Examples)
- Write `ctrl_global_enable=1`, verify `stat_enabled=1` on next clock
- Write `cfg_safety_wave_select=011` (invalid), verify fault assertion
- Write `cfg_amplitude_scale=0x4000`, verify half amplitude scaling
- Force `core_fault=1`, verify `stat_global_fault=1`
- Set `cfg_clk_div_sel=2`, verify clock enable frequency is system_clock/4

#### Test Success Criteria
- Print `'ALL TESTS PASSED'` on success
- Print `'TEST FAILED'` on failure  
- Always print `'SIMULATION DONE'` at completion
- Report individual test results for visibility

### 11. Compilation Requirements

#### GHDL Compatibility
- Must compile with `ghdl --std=08`
- Must elaborate without errors
- Must run to completion with deterministic results

#### Compilation Order
```bash
# 1. Compile dependencies
ghdl -a --std=08 modules/probe_driver/datadef/Moku_Voltage_pkg.vhd
ghdl -a --std=08 modules/clk_divider/core/clk_divider_core.vhd

# 2. Compile core module
ghdl -a --std=08 modules/SimpleWaveGen/core/SimpleWaveGen_core.vhd

# 3. Compile top module
ghdl -a --std=08 modules/SimpleWaveGen/top/SimpleWaveGen_top.vhd

# 4. Compile testbench
ghdl -a --std=08 modules/SimpleWaveGen/tb/top/SimpleWaveGen_top_tb.vhd

# 5. Elaborate and run
ghdl -e --std=08 SimpleWaveGen_top_tb
ghdl -r --std=08 SimpleWaveGen_top_tb
```

### 12. Documentation Requirements

#### README.md Content
- Module overview and purpose
- Interface description
- Register map and field descriptions
- Safety-critical parameter validation details
- Compilation and testing instructions
- Expected test results

#### Code Comments
- Clear block structure with end markers
- Meaningful comments for complex logic
- Safety-critical validation logic clearly documented
- Register field descriptions in comments

## Success Criteria

### Implementation Checklist
- [ ] Entity interface matches specification exactly
- [ ] All register fields implemented with correct bit positions
- [ ] Safety-critical parameter validation implemented correctly
- [ ] Fault aggregation logic implemented (OR of all fault sources)
- [ ] Clock divider integration working correctly
- [ ] Amplitude scaling implemented and functional
- [ ] Direct instantiation used for all sub-modules
- [ ] VHDL-2008 compliance maintained throughout
- [ ] Proper signal naming conventions followed
- [ ] Reset behavior implemented correctly

### Verification Checklist
- [ ] Compiles with GHDL VHDL-2008 without errors
- [ ] All test scenarios pass validation
- [ ] Register access timing meets specifications
- [ ] Fault handling works for all error conditions
- [ ] Output waveforms meet specifications
- [ ] Reset and initialization sequence works correctly
- [ ] Integration with clock divider functions properly
- [ ] Testbench prints correct success/failure messages

## Validation Against Project Guidelines

### ✅ Compliance Verification
- **Module Structure**: Follows standard `top/` directory structure
- **Direct Instantiation**: Required for top layer (no component declarations)
- **Safety-Critical Validation**: Proper validation of `cfg_safety_wave_select`
- **Signal Naming**: Uses proper prefixes (`ctrl_*`, `cfg_*`, `stat_*`)
- **VHDL-2008 Compliance**: No VHDL-only features used
- **Testbench Organization**: Located in `tb/top/` with proper naming
- **GHDL Compatibility**: Designed for GHDL compilation and execution

### ✅ Project Standards Adherence
- **Top Layer Responsibilities**: External interface, register exposure, module integration
- **No MCC CustomWrapper**: Clean top-level module without platform-specific code
- **Fault Aggregation**: Standard approach for system integration
- **Register Interface**: Flat 32-bit registers compatible with standard buses
- **Clock Domain**: Single clock domain simplifies integration

## Implementation Notes

### Key Design Decisions
1. **Register Interface**: 32-bit registers with explicit write enables for each register
2. **Fault Aggregation**: Simple OR logic for all fault sources
3. **Amplitude Scaling**: Applied to core waveform output before register exposure
4. **Clock Divider**: Direct integration with fault output aggregation
5. **Safety Validation**: Continuous monitoring with immediate fault response

### Potential Implementation Challenges
1. **Amplitude Scaling**: May require careful handling of signed arithmetic
2. **Clock Divider Integration**: Ensure proper clock enable timing
3. **Fault Aggregation**: Verify all fault sources are properly connected
4. **Register Timing**: Ensure write/read timing meets specifications

### Testing Strategy
1. **Unit Tests**: Test each register interface individually
2. **Integration Tests**: Test module integration with clock divider
3. **Fault Tests**: Test all fault conditions and recovery
4. **End-to-End Tests**: Test complete functionality from configuration to output

This implementation prompt provides comprehensive guidance for creating a fully compliant SimpleWaveGen top-level module that meets all project standards and specification requirements.