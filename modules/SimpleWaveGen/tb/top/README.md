# SimpleWaveGen Top-Level Testbench

## Overview
The **SimpleWaveGen_top_tb** testbench provides comprehensive verification of the SimpleWaveGen top-level module. It tests all register interfaces, safety-critical parameter validation, fault aggregation, amplitude scaling, clock divider integration, and end-to-end functionality.

## Test Coverage

### Test Groups
1. **Register Access Tests**: Write/read all registers with specific test vectors
2. **Safety-Critical Parameter Validation**: Wave selection validation and fault handling
3. **Amplitude Scaling Tests**: Unity, half, and maximum amplitude scaling verification
4. **Clock Divider Integration Tests**: Frequency division and configuration verification
5. **Fault Aggregation Tests**: Core fault aggregation and global fault status
6. **Reset and Initialization Tests**: Reset behavior and initialization sequence
7. **End-to-End Functionality Tests**: Complete waveform generation verification

### Specific Test Scenarios

#### Register Access Tests
- **Test 1**: Control0 register write/read (global enable)
- **Test 2**: Config0 register write/read (wave selection)
- **Test 3**: Config1 register write/read (amplitude scaling)

#### Safety-Critical Parameter Validation
- **Test 4**: Valid wave selections (000, 001, 010)
- **Test 5**: Invalid wave selections trigger fault (011-111)
- **Test 6**: Fault recovery (write valid value to clear fault)

#### Amplitude Scaling Tests
- **Test 7**: Unity scaling (0x8000)
- **Test 8**: Half amplitude scaling (0x4000)
- **Test 9**: Maximum amplitude scaling (0xFFFF)

#### Clock Divider Integration Tests
- **Test 10**: Clock divider configuration (div_sel = 5)
- **Test 11**: Frequency division verification (div_sel = 0)

#### Fault Aggregation Tests
- **Test 12**: Core fault aggregation (invalid wave selection)
- **Test 13**: Global fault status (fault clearing)

#### Reset and Initialization Tests
- **Test 14**: Reset behavior (all registers return to defaults)
- **Test 15**: Initialization sequence (enable and configure)

#### End-to-End Functionality Tests
- **Test 16**: Square wave generation (toggles between high/low)
- **Test 17**: Triangle wave generation (ramping behavior)
- **Test 18**: Sine wave generation (sinusoidal behavior)

## Test Features

### Helper Procedures
- **`report_test()`**: Standardized test result reporting
- **`write_register()`**: Register write operation with proper timing

### Test Control
- **Clock Generation**: 10ns period (100MHz)
- **Reset Sequence**: 2 clock cycles active, then release
- **Test Timing**: Proper wait periods for signal stabilization

### Validation Criteria
- **Register Access**: Write/read operations with expected values
- **Fault Handling**: Proper fault assertion and clearing
- **Amplitude Scaling**: Output changes with different scaling factors
- **Clock Divider**: Frequency division effects on waveform output
- **Reset Behavior**: All registers return to default values
- **Waveform Generation**: Output changes appropriately for each wave type

## Compilation and Execution

### Prerequisites
- GHDL with VHDL-2008 support
- All dependency modules compiled
- Platform interface package compiled

### Compilation Commands
```bash
# Compile dependencies
ghdl -a --std=08 modules/probe_driver/datadef/Moku_Voltage_pkg.vhd
ghdl -a --std=08 modules/SimpleWaveGen/common/platform_interface_pkg.vhd
ghdl -a --std=08 modules/clk_divider/core/clk_divider_core.vhd
ghdl -a --std=08 modules/SimpleWaveGen/core/SimpleWaveGen_core.vhd

# Compile top module
ghdl -a --std=08 modules/SimpleWaveGen/top/SimpleWaveGen_top.vhd

# Compile testbench
ghdl -a --std=08 modules/SimpleWaveGen/tb/top/SimpleWaveGen_top_tb.vhd

# Elaborate testbench
ghdl -e --std=08 SimpleWaveGen_top_tb

# Run simulation
ghdl -r --std=08 SimpleWaveGen_top_tb
```

### Expected Output
```
=== SimpleWaveGen Top-Level TestBench Started ===
--- Testing Register Access ---
Test 1: Control0 register write/read - PASSED
Test 2: Config0 register write/read - PASSED
Test 3: Config1 register write/read - PASSED
--- Testing Safety-Critical Parameter Validation ---
Test 4: Valid wave selections - PASSED
Test 5: Invalid wave selections trigger fault - PASSED
Test 6: Fault recovery - PASSED
--- Testing Amplitude Scaling ---
Test 7: Unity scaling - PASSED
Test 8: Half amplitude scaling - PASSED
Test 9: Maximum amplitude scaling - PASSED
--- Testing Clock Divider Integration ---
Test 10: Clock divider configuration - PASSED
Test 11: Frequency division verification - PASSED
--- Testing Fault Aggregation ---
Test 12: Core fault aggregation - PASSED
Test 13: Global fault status - PASSED
--- Testing Reset and Initialization ---
Test 14: Reset behavior - PASSED
Test 15: Initialization sequence - PASSED
--- Testing End-to-End Functionality ---
Test 16: Square wave generation - PASSED
Test 17: Triangle wave generation - PASSED
Test 18: Sine wave generation - PASSED
=== Test Results ===
ALL TESTS PASSED
SIMULATION DONE
```

## Test Success Criteria

### Required Output Messages
- **`'ALL TESTS PASSED'`**: All test scenarios complete successfully
- **`'TEST FAILED'`**: Any test scenario fails validation
- **`'SIMULATION DONE'`**: Always printed at test completion

### Individual Test Results
- Each test reports pass/fail status with descriptive names
- Test numbers are sequential for easy tracking
- Failed tests are clearly identified

## Test Methodology

### Register Testing
- **Write Operations**: Use helper procedure with proper timing
- **Read Verification**: Check status and output registers
- **Timing**: Wait for clock cycles to ensure signal propagation

### Fault Testing
- **Fault Induction**: Write invalid configurations
- **Fault Verification**: Check fault_out and status registers
- **Recovery Testing**: Write valid configurations to clear faults

### Waveform Testing
- **Output Monitoring**: Capture waveform output values
- **Change Detection**: Verify output changes over time
- **Pattern Recognition**: Check for expected waveform characteristics

### Integration Testing
- **Clock Divider**: Verify frequency division effects
- **Amplitude Scaling**: Check scaling factor application
- **End-to-End**: Test complete functionality from configuration to output

## Debugging and Troubleshooting

### Common Issues
1. **Compilation Errors**: Check dependency compilation order
2. **Simulation Hangs**: Verify clock generation and wait statements
3. **Test Failures**: Check signal timing and expected values
4. **Fault Issues**: Verify safety-critical parameter validation

### Debug Features
- **Detailed Test Reporting**: Each test reports specific pass/fail status
- **Signal Monitoring**: All interface signals are accessible
- **Timing Verification**: Proper clock cycles between operations

## Compliance with Project Standards

### VHDL-2008 Compliance
- Uses standard libraries and types
- Implements synchronous processes
- No VHDL-only features

### Testbench Standards
- **Location**: `modules/SimpleWaveGen/tb/top/SimpleWaveGen_top_tb.vhd`
- **Direct Instantiation**: Required for all module instantiations
- **GHDL Compatibility**: Compiles and runs with GHDL VHDL-2008
- **Standard Output**: Proper success/failure messages

### Test Coverage
- **Comprehensive**: All major functionality areas tested
- **Specific**: Detailed test scenarios with expected outcomes
- **Deterministic**: Reproducible test results
- **Edge Cases**: Invalid configurations and boundary conditions

## References
- SimpleWaveGen-top-regs-r2.md: Register interface specification
- SimpleWaveGen-reqs.md: Core module requirements
- platform_interface_pkg.vhd: Register interface utilities
- Volo VHDL Project Guidelines: Testbench standards