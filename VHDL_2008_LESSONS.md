# VHDL-2008 Lessons Learned
**Purpose**: Platform-agnostic VHDL-2008 language rules and patterns discovered during development

**Status**: Living document - will migrate to Serena memories when mature

**Last Updated**: 2025-10-23

---

## Tier 1: Critical (Must Follow)

### ✅ DO: Use std_logic_vector for all ports (except constants)
- **Reason**: Maximum portability with CocotB and other tools
- **Example**:
  ```vhdl
  -- ✅ GOOD
  port (
      pulse_width : in std_logic_vector(7 downto 0);
  );

  -- ❌ BAD
  port (
      pulse_width : in unsigned(7 downto 0);  -- Causes CocotB issues
  );
  ```
- **Note**: Convert to unsigned/signed internally if needed

### ✅ DO: Edge Detection via Delayed Comparison
- **Pattern**: Store previous value, compare with current
- **Example** (from volo_edge_detector.vhd):
  ```vhdl
  signal input_prev : std_logic;

  rising_edge_det <= '1' when (input = '1' and input_prev = '0') else '0';

  process(clk, n_reset)
  begin
      if n_reset = '0' then
          input_prev <= '0';
      elsif rising_edge(clk) then
          if clk_en = '1' and enable = '1' then
              input_prev <= input;
          end if;
      end if;
  end process;
  ```

### ❌ DON'T: Use complex FSMs for simple counter-based logic
- **Reason**: Counters are simpler, more reliable, easier to debug
- **Lesson**: volo_pulse_generator failed with FSM approach, succeeded with edge_detector-style counter
- **Guideline**: Only use FSM if state machine is truly necessary

---

## Tier 2: Important (Strongly Recommended)

### ✅ DO: Standard Control Signal Priority
- **Order**: Reset > Clock Enable > Functional Enable
- **Pattern**:
  ```vhdl
  process(clk, n_reset)
  begin
      if n_reset = '0' then
          -- Reset logic
      elsif rising_edge(clk) then
          if clk_en = '1' and enable = '1' then
              -- Normal operation
          end if;
          -- enable='0': Hold state (freeze)
      end if;
  end process;
  ```

### ✅ DO: Use combinational outputs when appropriate
- **Example** (from volo_edge_detector.vhd):
  ```vhdl
  -- Combinational edge detection (no extra latency)
  edge_detected <= rising_edge_det when mode = MODE_RISING else
                   falling_edge_det when mode = MODE_FALLING else
                   (rising_edge_det or falling_edge_det) when mode = MODE_BOTH else
                   '0';

  edge_out <= edge_detected when enable = '1' else '0';
  ```

### ✅ DO: Separate sequential and combinational logic clearly
- **Pattern**: Sequential in process, combinational via concurrent assignments
- **Benefits**: Easier to understand, less risk of latches

---

## Tier 3: Nice to Know (Best Practices)

### ✅ DO: Use meaningful constant names
- **Example**:
  ```vhdl
  constant MODE_RISING  : std_logic_vector(1 downto 0) := "00";
  constant MODE_FALLING : std_logic_vector(1 downto 0) := "01";
  constant MODE_BOTH    : std_logic_vector(1 downto 0) := "10";
  constant MODE_OFF     : std_logic_vector(1 downto 0) := "11";
  ```

### ✅ DO: Document timing behavior in header
- **Example**: "Input changes on cycle N → edge_out pulses high on cycle N+1"
- **Benefit**: Tests and integration much easier to write

---

## Anti-Patterns to Avoid

### ❌ DON'T: Mix signal assignment strategies in FSMs
- **Problem**: Multiple assignments to same signal in different states can cause issues
- **Solution**: Use if/else structure OR default values + overrides

### ❌ DON'T: Use metavalues ('X', 'U') in arithmetic
- **Problem**: "metavalue detected, returning FALSE" warnings in GHDL
- **Lesson**: Ensure all signals properly initialized in reset

---

## Open Questions / Investigation Needed

1. **9-bit counter arithmetic**: Why did `pulse_counter : unsigned(8 downto 0)` cause metavalue warnings in pulse_generator?
   - Needs further investigation
   - May be related to type conversion (`resize`, concatenation, etc.)

2. **FSM vs Counter trade-offs**: When is FSM genuinely better than counter-based logic?
   - Counters: Simple state (idle vs active)
   - FSMs: Complex multi-state behavior (>3 states, non-sequential transitions)

---

## Success Patterns (Proven Working)

### Pattern 1: Edge Detector (10/10 tests passing)
- **File**: `volo_edge_detector.vhd`
- **Key**: Delayed comparison + combinational mode selection
- **Complexity**: Low
- **Reliability**: ✅ Excellent

---

**Next Steps**: Add lessons from volo_counter_nbit implementation
