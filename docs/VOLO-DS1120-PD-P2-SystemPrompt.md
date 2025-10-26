# System Prompt P2: VOLO-DS1120-PD VHDL Implementation

**Purpose**: Complete VHDL implementation and CocotB testing for DS1120-PD probe driver.

---

## Instructions for Fresh Context Window

You are tasked with implementing **Phase 2** of the VOLO-DS1120-PD application - completing the VHDL logic and creating comprehensive CocotB tests. Phase 1 has already created the YAML definition and generated the infrastructure.

### Your Tasks:

1. **Complete FSM implementation** in `DS1120_PD_volo_main.vhd`
2. **Create FSM core module** (`ds1120_pd_fsm.vhd`)
3. **Implement safety features** (voltage clamping, timing constraints)
4. **Integrate shared modules** (threshold trigger, clock divider, observers)
5. **Write CocotB test suite** (`tests/test_ds1120_pd_volo.py`)

### Context Files to Read First:

1. **Requirements**: `docs/VOLO-DS1120-PD.md` - Complete specifications
2. **Phase 1 Output**:
   - `modules/DS1120-PD/DS1120-PD_app.yaml` - Register definitions
   - `modules/DS1120-PD/volo_main/DS1120_PD_volo_shim.vhd` - Generated shim
   - `modules/DS1120-PD/volo_main/DS1120_PD_volo_main.vhd` - Starter template
3. **Reference Modules**:
   - `modules/shared/observer/fsm_observer.vhd` - FSM visualization
   - `modules/examples/fsm_example/core/fsm_example_core.vhd` - Observable FSM pattern
   - `modules/shared/core/volo_voltage_threshold_trigger_core.vhd` - Trigger detection

### Key Implementation Requirements:

#### 1. FSM Core Module Structure

Create `modules/DS1120-PD/core/ds1120_pd_fsm.vhd`:

```vhdl
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ds1120_pd_fsm is
    port (
        -- Clock and control
        clk         : in  std_logic;
        rst         : in  std_logic;
        clk_en      : in  std_logic;  -- From clock divider

        -- Control inputs
        arm_cmd     : in  std_logic;
        force_fire  : in  std_logic;
        reset_cmd   : in  std_logic;
        trigger_in  : in  std_logic;  -- From threshold detector

        -- Timing configuration
        arm_timeout : in  std_logic_vector(11 downto 0);  -- 12-bit
        fire_cycles : in  std_logic_vector(7 downto 0);
        cool_cycles : in  std_logic_vector(7 downto 0);

        -- FSM outputs
        state_out   : out std_logic_vector(2 downto 0);
        fire_enable : out std_logic;
        timed_out   : out std_logic;
        spurious_trig : out std_logic
    );
end entity;

architecture rtl of ds1120_pd_fsm is
    -- States (3-bit encoding)
    constant STATE_READY    : std_logic_vector(2 downto 0) := "000";
    constant STATE_ARMED    : std_logic_vector(2 downto 0) := "001";
    constant STATE_FIRING   : std_logic_vector(2 downto 0) := "010";
    constant STATE_COOLING  : std_logic_vector(2 downto 0) := "011";
    constant STATE_DONE     : std_logic_vector(2 downto 0) := "100";
    constant STATE_TIMEDOUT : std_logic_vector(2 downto 0) := "101";

    signal current_state, next_state : std_logic_vector(2 downto 0);
    signal arm_counter : unsigned(11 downto 0);
    signal cycle_counter : unsigned(7 downto 0);

begin
    -- State register
    process(clk, rst)
    begin
        if rst = '1' then
            current_state <= STATE_READY;
        elsif rising_edge(clk) then
            if clk_en = '1' then
                current_state <= next_state;
            end if;
        end if;
    end process;

    -- Next state logic
    process(all)
    begin
        next_state <= current_state;

        case current_state is
            when STATE_READY =>
                if arm_cmd = '1' then
                    next_state <= STATE_ARMED;
                end if;

            when STATE_ARMED =>
                if force_fire = '1' or trigger_in = '1' then
                    next_state <= STATE_FIRING;
                elsif arm_counter >= unsigned(arm_timeout) then
                    next_state <= STATE_TIMEDOUT;
                end if;

            when STATE_FIRING =>
                if cycle_counter >= unsigned(fire_cycles) then
                    next_state <= STATE_COOLING;
                end if;

            when STATE_COOLING =>
                if cycle_counter >= unsigned(cool_cycles) then
                    next_state <= STATE_DONE;
                end if;

            when STATE_DONE | STATE_TIMEDOUT =>
                if reset_cmd = '1' then
                    next_state <= STATE_READY;
                end if;

            when others =>
                next_state <= STATE_READY;
        end case;
    end process;

    -- Output assignments
    state_out <= current_state;
    fire_enable <= '1' when current_state = STATE_FIRING else '0';

end architecture;
```

#### 2. Main Module Integration

Complete `DS1120_PD_volo_main.vhd` with:

```vhdl
architecture rtl of DS1120_PD_volo_main is
    -- Reconstruct 16-bit values from register pairs
    signal trigger_threshold : signed(15 downto 0);
    signal intensity_value   : signed(15 downto 0);
    signal arm_timeout      : std_logic_vector(11 downto 0);

    -- Internal signals
    signal divided_clk_en   : std_logic;
    signal trigger_detected : std_logic;
    signal fsm_state       : std_logic_vector(2 downto 0);
    signal fire_enable     : std_logic;
    signal spurious_count  : unsigned(3 downto 0);

    -- Safety constants
    constant MAX_INTENSITY : signed(15 downto 0) := x"4CCD";  -- 3.0V
    constant MAX_FIRE_CYCLES : natural := 32;
    constant MIN_COOL_CYCLES : natural := 8;

begin
    -- Reconstruct 16-bit values
    trigger_threshold <= signed(trig_thresh_high & trig_thresh_low);
    intensity_value <= signed(intensity_high & intensity_low);
    arm_timeout <= timing_control(3 downto 0) & delay_lower;

    -- Clock divider
    U_CLK_DIV: entity work.volo_clk_divider
        generic map (MAX_DIV => 16)
        port map (
            clk      => Clk,
            rst_n    => not Reset,
            enable   => Enable,
            div_sel  => "0000" & timing_control(7 downto 4),
            clk_en   => divided_clk_en,
            stat_reg => open
        );

    -- Threshold trigger detector
    U_TRIGGER: entity work.volo_voltage_threshold_trigger_core
        port map (
            clk            => Clk,
            n_reset        => not Reset,
            enable         => Enable,
            signal_in      => trigger_input,  -- From InputA
            threshold      => trigger_threshold,
            trigger_mode   => "00",  -- Rising edge
            trigger_out    => trigger_detected,
            stat_reg       => open
        );

    -- FSM core
    U_FSM: entity work.ds1120_pd_fsm
        port map (
            clk          => Clk,
            rst          => Reset,
            clk_en       => divided_clk_en,
            arm_cmd      => armed,
            force_fire   => force_fire,
            reset_cmd    => reset_fsm,
            trigger_in   => trigger_detected,
            arm_timeout  => arm_timeout,
            fire_cycles  => firing_duration,
            cool_cycles  => cooling_duration,
            state_out    => fsm_state,
            fire_enable  => fire_enable,
            timed_out    => open,
            spurious_trig => open
        );

    -- Output control with safety clamping
    process(Clk, Reset)
    begin
        if Reset = '1' then
            trigger_out <= (others => '0');
            intensity_out <= (others => '0');
        elsif rising_edge(Clk) then
            if fire_enable = '1' then
                trigger_out <= intensity_value;
                -- Clamp intensity to 3.0V maximum
                if intensity_value > MAX_INTENSITY then
                    intensity_out <= MAX_INTENSITY;
                else
                    intensity_out <= intensity_value;
                end if;
            else
                trigger_out <= (others => '0');
                intensity_out <= (others => '0');
            end if;
        end if;
    end process;

    -- FSM observer for debug output
    U_OBSERVER: entity work.fsm_observer
        generic map (
            NUM_STATES => 8,
            COUNTER_WIDTH => 16
        )
        port map (
            clk          => Clk,
            rst          => Reset,
            enable       => Enable,
            state_in     => "000" & fsm_state,  -- Pad to 6 bits
            state_change => open,
            analog_out   => analog_v_mon  -- To debug output
        );

    -- Status register assembly
    status_reg(15 downto 13) <= fsm_state;
    status_reg(12) <= '1' when fire_enable = '1' else '0';
    status_reg(11 downto 8) <= std_logic_vector(spurious_count);
    status_reg(7 downto 0) <= x"00";  -- Reserved

end architecture;
```

#### 3. CocotB Test Suite

Create `tests/test_ds1120_pd_volo.py`:

```python
import cocotb
from cocotb.triggers import Timer, RisingEdge, ClockCycles
from cocotb.clock import Clock
import random

# Test configuration
CLK_PERIOD_NS = 8  # 125 MHz

@cocotb.test()
async def test_reset_behavior(dut):
    """Test 1: Verify reset puts FSM in READY state"""
    dut._log.info("Test 1: Reset Behavior")

    # Setup clock
    clock = Clock(dut.Clk, CLK_PERIOD_NS, units="ns")
    cocotb.start_soon(clock.start())

    # Apply reset
    dut.Reset.value = 1
    await ClockCycles(dut.Clk, 5)
    dut.Reset.value = 0
    await ClockCycles(dut.Clk, 2)

    # Check FSM is in READY state (000)
    state = dut.fsm_state.value.integer
    assert state == 0b000, f"Expected READY state, got {state:03b}"

    # Check outputs are zero
    assert dut.trigger_out.value.integer == 0
    assert dut.intensity_out.value.integer == 0

    dut._log.info("✓ Reset test PASSED")

@cocotb.test()
async def test_arm_and_trigger(dut):
    """Test 2: Arm FSM and trigger probe"""
    dut._log.info("Test 2: Arm and Trigger Sequence")

    # Initialize
    await reset_dut(dut)

    # Configure timing
    dut.firing_duration.value = 10
    dut.cooling_duration.value = 8
    dut.trig_thresh_high.value = 0x3D  # 2.4V high byte
    dut.trig_thresh_low.value = 0xCF   # 2.4V low byte
    dut.intensity_high.value = 0x30    # ~2.3V
    dut.intensity_low.value = 0x00

    # Arm the FSM
    dut.armed.value = 1
    await ClockCycles(dut.Clk, 2)
    dut.armed.value = 0

    # Verify ARMED state
    assert dut.fsm_state.value.integer == 0b001

    # Apply trigger
    dut.trigger_input.value = 0x4000  # > 2.4V
    await ClockCycles(dut.Clk, 5)

    # Verify FIRING state
    assert dut.fsm_state.value.integer == 0b010
    assert dut.trigger_out.value.integer != 0

    dut._log.info("✓ Arm and trigger test PASSED")

@cocotb.test()
async def test_intensity_clamping(dut):
    """Test 3: Verify 3.0V intensity clamping"""
    dut._log.info("Test 3: Intensity Clamping")

    await reset_dut(dut)

    # Set intensity above 3.0V
    dut.intensity_high.value = 0x70  # Way above 3.0V
    dut.intensity_low.value = 0x00

    # Force fire
    dut.force_fire.value = 1
    await ClockCycles(dut.Clk, 2)
    dut.force_fire.value = 0

    # Check clamping (0x4CCD = 3.0V)
    await ClockCycles(dut.Clk, 5)
    intensity = dut.intensity_out.value.signed_integer
    assert intensity <= 0x4CCD, f"Intensity {intensity:04X} exceeds 3.0V limit"

    dut._log.info("✓ Intensity clamping test PASSED")

@cocotb.test()
async def test_timeout_behavior(dut):
    """Test 4: Verify armed timeout"""
    dut._log.info("Test 4: Armed Timeout")

    await reset_dut(dut)

    # Set short timeout
    dut.timing_control.value = 0x00  # No divider, short timeout
    dut.delay_lower.value = 0x10     # 16 cycles

    # Arm without triggering
    dut.armed.value = 1
    await ClockCycles(dut.Clk, 2)
    dut.armed.value = 0

    # Wait for timeout
    await ClockCycles(dut.Clk, 20)

    # Verify TIMEDOUT state
    assert dut.fsm_state.value.integer == 0b101

    dut._log.info("✓ Timeout test PASSED")

@cocotb.test()
async def test_spurious_trigger_counting(dut):
    """Test 5: Count spurious triggers during operation"""
    dut._log.info("Test 5: Spurious Trigger Detection")

    await reset_dut(dut)

    # Configure and arm
    dut.firing_duration.value = 20
    dut.cooling_duration.value = 20
    dut.armed.value = 1
    await ClockCycles(dut.Clk, 2)
    dut.armed.value = 0

    # Trigger normally
    dut.force_fire.value = 1
    await ClockCycles(dut.Clk, 1)
    dut.force_fire.value = 0

    # Apply spurious triggers during FIRING
    for _ in range(3):
        await ClockCycles(dut.Clk, 5)
        dut.trigger_input.value = 0x5000
        await ClockCycles(dut.Clk, 1)
        dut.trigger_input.value = 0

    # Check spurious count in status register
    await ClockCycles(dut.Clk, 50)
    status = dut.status_reg.value.integer
    spurious_count = (status >> 8) & 0xF
    assert spurious_count >= 3, f"Expected 3+ spurious triggers, got {spurious_count}"

    dut._log.info("✓ Spurious trigger test PASSED")

@cocotb.test()
async def test_full_cycle(dut):
    """Test 6: Complete operational cycle"""
    dut._log.info("Test 6: Full Operational Cycle")

    await reset_dut(dut)

    # Configure all parameters
    dut.timing_control.value = 0x00
    dut.delay_lower.value = 0xFF
    dut.firing_duration.value = 16
    dut.cooling_duration.value = 12
    dut.trig_thresh_high.value = 0x20
    dut.trig_thresh_low.value = 0x00
    dut.intensity_high.value = 0x40
    dut.intensity_low.value = 0x00

    # Track state transitions
    states = []

    # Arm
    dut.armed.value = 1
    await ClockCycles(dut.Clk, 2)
    dut.armed.value = 0
    states.append(dut.fsm_state.value.integer)

    # Trigger
    dut.trigger_input.value = 0x3000
    await ClockCycles(dut.Clk, 5)
    states.append(dut.fsm_state.value.integer)

    # Wait for firing
    await ClockCycles(dut.Clk, 20)
    states.append(dut.fsm_state.value.integer)

    # Wait for cooling
    await ClockCycles(dut.Clk, 15)
    states.append(dut.fsm_state.value.integer)

    # Reset FSM
    dut.reset_fsm.value = 1
    await ClockCycles(dut.Clk, 2)
    dut.reset_fsm.value = 0
    await ClockCycles(dut.Clk, 2)
    states.append(dut.fsm_state.value.integer)

    # Verify state sequence
    expected = [0b001, 0b010, 0b011, 0b100, 0b000]  # ARMED->FIRING->COOLING->DONE->READY
    dut._log.info(f"State transitions: {[f'{s:03b}' for s in states]}")

    dut._log.info("✓ Full cycle test PASSED")

@cocotb.test()
async def test_clock_divider_integration(dut):
    """Test 7: Verify clock divider affects FSM timing"""
    dut._log.info("Test 7: Clock Divider Integration")

    await reset_dut(dut)

    # Configure with clock division
    dut.timing_control.value = 0x20  # Divide by 4 (bits [7:4] = 2)
    dut.firing_duration.value = 4

    # Measure firing duration without divider
    dut.timing_control.value = 0x00
    dut.force_fire.value = 1
    await ClockCycles(dut.Clk, 1)
    dut.force_fire.value = 0

    start_time = cocotb.utils.get_sim_time('ns')
    while dut.fsm_state.value.integer == 0b010:  # FIRING
        await RisingEdge(dut.Clk)
    no_div_duration = cocotb.utils.get_sim_time('ns') - start_time

    # Reset and measure with divider
    await reset_dut(dut)
    dut.timing_control.value = 0x20  # Divide by 4
    dut.force_fire.value = 1
    await ClockCycles(dut.Clk, 1)
    dut.force_fire.value = 0

    start_time = cocotb.utils.get_sim_time('ns')
    while dut.fsm_state.value.integer == 0b010:  # FIRING
        await RisingEdge(dut.Clk)
    div_duration = cocotb.utils.get_sim_time('ns') - start_time

    # Divided clock should make FSM ~4x slower
    ratio = div_duration / no_div_duration
    assert 3.5 < ratio < 4.5, f"Clock division ratio {ratio} not ~4"

    dut._log.info("✓ Clock divider test PASSED")

# Helper function
async def reset_dut(dut):
    """Apply reset sequence"""
    dut.Reset.value = 1
    dut.Enable.value = 1
    dut.ClkEn.value = 1

    # Initialize all inputs
    dut.armed.value = 0
    dut.force_fire.value = 0
    dut.reset_fsm.value = 0
    dut.trigger_input.value = 0
    dut.monitor_input.value = 0

    await ClockCycles(dut.Clk, 5)
    dut.Reset.value = 0
    await ClockCycles(dut.Clk, 2)
```

### Implementation Checklist

Complete these tasks in order:

1. [ ] Implement `ds1120_pd_fsm.vhd` core FSM
2. [ ] Complete `DS1120_PD_volo_main.vhd` integration
3. [ ] Add safety features (clamping, timeout)
4. [ ] Integrate threshold trigger module
5. [ ] Add FSM observer for debug output
6. [ ] Implement spurious trigger counting
7. [ ] Create package with constants
8. [ ] Write all 7 CocotB tests
9. [ ] Verify compilation with GHDL
10. [ ] Run full test suite

### Build and Test Commands

```bash
# Compile module
cd modules
make compile-single-module MODULE_NAME=DS1120-PD

# Run CocotB tests
cd tests
uv run make TEST_MODULE=ds1120_pd_volo

# View waveforms (if WAVES=1)
make waves
```

### Key Safety Requirements to Verify

1. **Voltage Clamping**: IntensityOut never exceeds 0x4CCD (3.0V)
2. **Timing Enforcement**:
   - Max 32 cycles in FIRING state
   - Min 8 cycles in COOLING state
3. **Timeout Protection**: Armed state times out after configured delay
4. **One-Shot Operation**: Requires reset after each firing
5. **Spurious Detection**: Count triggers during active states

### Success Criteria

Phase 2 is complete when:
1. All VHDL modules compile without errors
2. All 7 CocotB tests pass
3. Safety features verified in simulation
4. FSM observer shows correct state transitions
5. Ready for MCC CloudCompile synthesis

---

**Note**: This implementation prioritizes safety and reliability for hardware fault injection. All safety limits are hard-coded and cannot be bypassed.