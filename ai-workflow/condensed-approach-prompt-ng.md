# Condensed Approach Implementation Prompt (NG)

## 🎯 Mission
Implement ProbeHero8 using the **condensed approach** with the **enhanced rules system** from main-ng branch.

## 📋 Approach Philosophy
- **Speed over comprehensiveness**: Focus on getting things done quickly
- **Essential information only**: Use only the information you need
- **Action-oriented**: Focus on "what to do" rather than "why to do it"
- **Efficiency**: Minimize cognitive overhead and context switching

## 🔧 Enhanced Rules System Integration
Apply these specific patterns from the enhanced rules system:

### SIG-02: Named Association & Explicit Conversions
```vhdl
u_core: entity work.core
  port map (
    clk   => clk,
    rst   => rst,
    a_in  => std_logic_vector(a_u),
    b_in  => std_logic_vector(b_u),
    y_out => y
  );
```

### SIG-03: Signal Priority & Truth Table
```vhdl
process(clk)
begin
  if rising_edge(clk) then
    if rst = '1' then
      y <= (others => '0');     -- highest priority
    elsif ce = '1' then
      if en = '1' then
        y <= next_y;
      end if;
    end if;
  end if;
end process;
```

### TB-05: Clock & Timing Management
```vhdl
wait until rising_edge(clk);
if ce = '1' then
  drive_inputs;
end if;
```

### TB-06: Reset & Initialization Testing
```vhdl
rst <= '1'; wait for 10*CLK_PERIOD;
rst <= '0'; wait until rising_edge(clk);
assert outputs = DEFAULTS report "post-reset defaults wrong" severity error;
```

## 📁 Implementation Plan
Follow: `TODO-PH8-implementation-plan-CONDENSED-NG.md`

## 📊 Progress Tracking
Update: `experiment-results-ng/condensed-approach/progress-log.md`

## ⏱️ Time Tracking
Update: `experiment-results-ng/condensed-approach/time-tracking.md`

## 🎯 Success Criteria
- Working ProbeHero8 implementation
- All tests pass with GHDL
- Enhanced rules system patterns applied
- Progress and time tracking completed
- Developer experience ratings provided

## 🚀 Ready to implement!
